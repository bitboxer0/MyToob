//
//  CloudKitConflictResolver.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import CloudKit
import Foundation
import OSLog

// MARK: - Conflict Resolution Result

/// The result of resolving a CloudKit record conflict.
///
/// Contains the resolved record to save under the original ID, plus any
/// additional records to create (e.g., Note conflict copies).
struct CloudKitConflictResolution {
  /// The resolved record to save under the original record ID.
  /// Uses the server record's changeTag to pass CloudKit's optimistic concurrency check.
  let resolvedRecordForOriginalID: CKRecord

  /// Additional records that must be created as part of conflict resolution.
  /// For Note conflicts, this contains the "conflict copy" of the losing record.
  let additionalRecordsToCreate: [CKRecord]

  /// Human-readable description of the resolution for logging.
  let description: String

  /// The record type that was in conflict.
  let affectedRecordType: String

  /// Description of what happened to the losing record.
  let conflictLoserDescription: String
}

// MARK: - Conflict Resolver

/// Resolves CloudKit `serverRecordChanged` conflicts using a Last-Write-Wins strategy.
///
/// ## Resolution Strategy
///
/// **For all record types except Note:**
/// - Compares `modifiedAt`, `updatedAt`, or `CKRecord.modificationDate` timestamps
/// - The record with the later timestamp wins
/// - Winner's field values are merged onto the server record (to preserve changeTag)
///
/// **For Note records:**
/// - Same timestamp comparison for determining winner
/// - Winner is saved under the original record ID
/// - Loser's content is preserved in a new "conflict copy" record with content suffixed " (Conflict Copy)"
///
/// ## Usage
///
/// ```swift
/// do {
///   let savedRecord = try await database.save(record)
/// } catch let error as CKError where error.code == .serverRecordChanged {
///   let plan = try CloudKitConflictResolver().makeResolutionPlan(from: error)
///   let winner = try await database.save(plan.resolvedRecordForOriginalID)
///   for copy in plan.additionalRecordsToCreate {
///     try await database.save(copy)
///   }
/// }
/// ```
struct CloudKitConflictResolver {

  // MARK: - Cached Formatters

  /// Cached ISO8601 formatter for timestamp descriptions.
  /// Formatters are expensive to allocate; caching improves performance.
  private static let iso8601Formatter = ISO8601DateFormatter()

  // MARK: - Error Types

  /// Errors that can occur during conflict resolution.
  enum ResolutionError: Error, LocalizedError, Equatable {
    case missingServerRecord
    case missingClientRecord
    case notAConflictError
    case recordCopyFailed

    var errorDescription: String? {
      switch self {
      case .missingServerRecord:
        return "Server record not found in conflict error userInfo"
      case .missingClientRecord:
        return "Client record not found in conflict error userInfo"
      case .notAConflictError:
        return "Error is not a serverRecordChanged conflict"
      case .recordCopyFailed:
        return "Failed to copy CKRecord - NSCopying returned unexpected type"
      }
    }
  }

  // MARK: - Public API

  /// Creates a resolution plan from a `CKError.serverRecordChanged` error.
  ///
  /// - Parameter error: The CloudKit error containing conflict information
  /// - Returns: A resolution plan specifying what records to save
  /// - Throws: `ResolutionError` if the error doesn't contain required conflict data
  func makeResolutionPlan(from error: CKError) throws -> CloudKitConflictResolution {
    guard error.code == .serverRecordChanged else {
      throw ResolutionError.notAConflictError
    }

    // Extract conflict records from userInfo
    guard let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord else {
      throw ResolutionError.missingServerRecord
    }

    guard let clientRecord = error.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord else {
      throw ResolutionError.missingClientRecord
    }

    // Ancestor is optional - may not be present for new records
    let ancestorRecord = error.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord

    return try resolveConflict(
      serverRecord: serverRecord,
      clientRecord: clientRecord,
      ancestorRecord: ancestorRecord
    )
  }

  // MARK: - Resolution Logic

  /// Resolves a conflict between server and client records.
  private func resolveConflict(
    serverRecord: CKRecord,
    clientRecord: CKRecord,
    ancestorRecord: CKRecord?
  ) throws -> CloudKitConflictResolution {

    let serverTimestamp = logicalModifiedAt(from: serverRecord)
    let clientTimestamp = logicalModifiedAt(from: clientRecord)

    // Log when both timestamps are nil (server-wins fallback)
    if serverTimestamp == nil && clientTimestamp == nil {
      LoggingService.shared.sync.notice(
        "Conflict timestamps missing for recordType=\(serverRecord.recordType, privacy: .public); defaulting to server-wins strategy"
      )
    }

    // Determine winner by Last-Write-Wins
    // If timestamps are equal or both nil, server wins (conservative choice)
    let clientWins = (clientTimestamp ?? .distantPast) > (serverTimestamp ?? .distantPast)

    let winner = clientWins ? clientRecord : serverRecord
    let loser = clientWins ? serverRecord : clientRecord
    let winnerSource = clientWins ? "client" : "server"
    let winnerTimestamp = clientWins ? clientTimestamp : serverTimestamp

    let recordType = serverRecord.recordType

    // Apply winner's values onto server record (to preserve changeTag)
    let resolvedRecord = try applyWinnerValues(winner, onto: serverRecord)

    // For Note records, create a conflict copy of the loser
    var additionalRecords: [CKRecord] = []
    var loserDescription = "discarded"

    if recordType == CloudKitRecordTypes.note {
      let conflictCopy = makeNoteConflictCopy(from: loser, in: serverRecord.recordID.zoneID)
      additionalRecords.append(conflictCopy)
      loserDescription = "preserved as conflict copy (\(conflictCopy.recordID.recordName))"
    }

    let timestampDescription =
      winnerTimestamp.map { Self.iso8601Formatter.string(from: $0) } ?? "unknown"
    let description =
      "Conflict resolved for \(recordType): \(winnerSource) won (timestamp: \(timestampDescription)), loser \(loserDescription)"

    return CloudKitConflictResolution(
      resolvedRecordForOriginalID: resolvedRecord,
      additionalRecordsToCreate: additionalRecords,
      description: description,
      affectedRecordType: recordType,
      conflictLoserDescription: loserDescription
    )
  }

  // MARK: - Timestamp Extraction

  /// Extracts the logical "modified at" timestamp from a record.
  ///
  /// Order of precedence:
  /// 1. Custom `modifiedAt` field (if present)
  /// 2. Custom `updatedAt` field (if present)
  /// 3. System `modificationDate` property
  /// 4. Custom `createdAt` field (fallback)
  ///
  /// - Parameter record: The CloudKit record
  /// - Returns: The best available timestamp, or nil if none found
  func logicalModifiedAt(from record: CKRecord) -> Date? {
    // Check custom modifiedAt field first (explicit sync timestamp)
    if let modifiedAt = record["modifiedAt"] as? Date {
      return modifiedAt
    }

    // Check updatedAt field (used by Note model)
    if let updatedAt = record["updatedAt"] as? Date {
      return updatedAt
    }

    // Fall back to system modification date
    if let modificationDate = record.modificationDate {
      return modificationDate
    }

    // Last resort: creation date
    if let createdAt = record["createdAt"] as? Date {
      return createdAt
    }

    return nil
  }

  // MARK: - Record Merging

  /// Applies the winner's user-defined field values onto a copy of the base record.
  ///
  /// The base record (typically serverRecord) provides the correct changeTag
  /// for CloudKit's optimistic concurrency. A copy is made to preserve the
  /// changeTag metadata, then the winner's field values are applied.
  ///
  /// - Parameters:
  ///   - winner: The record whose field values should be used
  ///   - base: The record providing the correct changeTag (usually serverRecord)
  /// - Returns: A new record with winner's values and base's changeTag
  func applyWinnerValues(_ winner: CKRecord, onto base: CKRecord) throws -> CKRecord {
    // CKRecord conforms to NSCopying; copy preserves changeTag metadata.
    // Use guard for better diagnostics instead of force cast.
    guard let resolved = base.copy() as? CKRecord else {
      throw ResolutionError.recordCopyFailed
    }
    for key in winner.allKeys() {
      resolved[key] = winner[key]
    }
    return resolved
  }

  // MARK: - Note Conflict Copy

  /// Creates a conflict copy of a Note record.
  ///
  /// The copy:
  /// - Has a new unique record ID (UUID-based)
  /// - Contains all fields from the original
  /// - Has " (Conflict Copy)" appended to the content field
  /// - Has `updatedAt` set to the current time
  /// - Uses the same UUID for both recordName and noteID for traceability
  ///
  /// - Parameters:
  ///   - loser: The losing Note record to copy
  ///   - zoneID: The zone to create the copy in (should match original)
  /// - Returns: A new CKRecord representing the conflict copy
  func makeNoteConflictCopy(from loser: CKRecord, in zoneID: CKRecordZone.ID?) -> CKRecord {
    // Use a single UUID for both recordName and noteID for traceability
    let copyUUID = UUID().uuidString

    // Create new record ID in the same zone
    let copyRecordID: CKRecord.ID
    if let zoneID = zoneID {
      copyRecordID = CKRecord.ID(
        recordName: "NoteConflictCopy_\(copyUUID)",
        zoneID: zoneID
      )
    } else {
      copyRecordID = CKRecord.ID(recordName: "NoteConflictCopy_\(copyUUID)")
    }

    let copy = CKRecord(recordType: CloudKitRecordTypes.note, recordID: copyRecordID)

    // Copy all fields from loser
    for key in loser.allKeys() {
      copy[key] = loser[key]
    }

    // Use the same UUID for noteID as recordName for traceability
    copy["noteID"] = copyUUID as CKRecordValue

    // Append conflict marker to content
    // Ensure marker is present even if original content is nil
    if let content = loser["content"] as? String {
      copy["content"] = "\(content) (Conflict Copy)" as CKRecordValue
    } else {
      copy["content"] = "(Conflict Copy)" as CKRecordValue
    }

    // Update timestamp to mark when the copy was created
    copy["updatedAt"] = Date() as CKRecordValue

    return copy
  }
}
