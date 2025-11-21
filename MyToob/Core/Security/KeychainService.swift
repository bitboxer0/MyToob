//
//  KeychainService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import Foundation
import OSLog
import Security

/// Secure storage service for sensitive data using macOS Keychain.
///
/// **Security:** All items stored with `kSecAttrAccessibleWhenUnlocked` attribute
/// (hardware-backed encryption, only accessible when device unlocked).
///
/// Usage:
/// ```swift
/// // Save token
/// try KeychainService.shared.save(
///   value: "access_token_value",
///   forKey: "youtube_access_token"
/// )
///
/// // Retrieve token
/// let token = try KeychainService.shared.retrieve(forKey: "youtube_access_token")
///
/// // Delete token
/// try KeychainService.shared.delete(forKey: "youtube_access_token")
/// ```
final class KeychainService {
  /// Shared singleton instance
  static let shared = KeychainService()

  /// Keychain service identifier (app bundle ID)
  private let service: String

  private init() {
    self.service = Bundle.main.bundleIdentifier ?? "com.yourcompany.mytoob"
  }

  // MARK: - Public API

  /// Save a string value to Keychain
  /// - Parameters:
  ///   - value: String value to store
  ///   - key: Unique key identifier
  /// - Throws: KeychainError if save fails
  func save(value: String, forKey key: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    try save(data: data, forKey: key)
  }

  /// Save data to Keychain
  /// - Parameters:
  ///   - data: Data to store
  ///   - key: Unique key identifier
  /// - Throws: KeychainError if save fails
  func save(data: Data, forKey key: String) throws {
    // Delete existing item if present
    try? delete(forKey: key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
      LoggingService.shared.app.error(
        "Keychain save failed for key: \(key, privacy: .public), status: \(status, privacy: .public)"
      )
      throw KeychainError.saveFailed(status: status)
    }

    LoggingService.shared.app.debug("Keychain save succeeded for key: \(key, privacy: .public)")
  }

  /// Retrieve a string value from Keychain
  /// - Parameter key: Unique key identifier
  /// - Returns: Stored string value
  /// - Throws: KeychainError if retrieval fails
  func retrieve(forKey key: String) throws -> String {
    let data = try retrieveData(forKey: key)

    guard let value = String(data: data, encoding: .utf8) else {
      throw KeychainError.invalidData
    }

    return value
  }

  /// Retrieve data from Keychain
  /// - Parameter key: Unique key identifier
  /// - Returns: Stored data
  /// - Throws: KeychainError if retrieval fails
  func retrieveData(forKey key: String) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      LoggingService.shared.app.error(
        "Keychain retrieve failed for key: \(key, privacy: .public), status: \(status, privacy: .public)"
      )
      throw KeychainError.retrieveFailed(status: status)
    }

    guard let data = result as? Data else {
      throw KeychainError.invalidData
    }

    LoggingService.shared.app.debug("Keychain retrieve succeeded for key: \(key, privacy: .public)")
    return data
  }

  /// Delete an item from Keychain
  /// - Parameter key: Unique key identifier
  /// - Throws: KeychainError if deletion fails
  func delete(forKey key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]

    let status = SecItemDelete(query as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      LoggingService.shared.app.error(
        "Keychain delete failed for key: \(key, privacy: .public), status: \(status, privacy: .public)"
      )
      throw KeychainError.deleteFailed(status: status)
    }

    LoggingService.shared.app.debug("Keychain delete succeeded for key: \(key, privacy: .public)")
  }

  /// Update an existing Keychain item
  /// - Parameters:
  ///   - value: New string value
  ///   - key: Unique key identifier
  /// - Throws: KeychainError if update fails
  func update(value: String, forKey key: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]

    let attributes: [String: Any] = [
      kSecValueData as String: data
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        // Item doesn't exist, save instead
        try save(value: value, forKey: key)
        return
      }
      LoggingService.shared.app.error(
        "Keychain update failed for key: \(key, privacy: .public), status: \(status, privacy: .public)"
      )
      throw KeychainError.updateFailed(status: status)
    }

    LoggingService.shared.app.debug("Keychain update succeeded for key: \(key, privacy: .public)")
  }

  /// Check if a key exists in Keychain
  /// - Parameter key: Unique key identifier
  /// - Returns: True if key exists, false otherwise
  func exists(forKey key: String) -> Bool {
    do {
      _ = try retrieveData(forKey: key)
      return true
    } catch {
      return false
    }
  }
}

// MARK: - KeychainError

/// Errors that can occur during Keychain operations
enum KeychainError: LocalizedError {
  case saveFailed(status: OSStatus)
  case retrieveFailed(status: OSStatus)
  case deleteFailed(status: OSStatus)
  case updateFailed(status: OSStatus)
  case itemNotFound
  case invalidData

  var errorDescription: String? {
    switch self {
    case .saveFailed(let status):
      return "Failed to save to Keychain (status: \(status))"
    case .retrieveFailed(let status):
      return "Failed to retrieve from Keychain (status: \(status))"
    case .deleteFailed(let status):
      return "Failed to delete from Keychain (status: \(status))"
    case .updateFailed(let status):
      return "Failed to update Keychain (status: \(status))"
    case .itemNotFound:
      return "Item not found in Keychain"
    case .invalidData:
      return "Invalid data format in Keychain"
    }
  }
}
