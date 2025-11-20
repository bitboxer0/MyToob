//
//  LocalFileImportService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import AppKit
import AVFoundation
import Foundation
import SwiftData

/// Service responsible for importing local video files into the app
@MainActor
final class LocalFileImportService {
  // MARK: - Properties

  private let modelContext: ModelContext

  /// Supported video file extensions
  private let supportedVideoExtensions: [String] = ["mp4", "mov", "mkv", "avi", "m4v"]

  // MARK: - Initialization

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  // MARK: - Public API

  /// Present file picker and import selected video files
  /// - Returns: Number of files successfully imported
  @discardableResult
  func importFiles() async throws -> Int {
    // Present NSOpenPanel on main thread
    let selectedURLs = try await presentFilePicker()

    guard !selectedURLs.isEmpty else {
      return 0
    }

    // Import files and track progress
    var importedCount = 0

    for url in selectedURLs {
      do {
        try await importFile(at: url)
        importedCount += 1
      } catch {
        // Log error but continue importing other files
        print("Failed to import file at \(url.path): \(error.localizedDescription)")
      }
    }

    // Save all changes to SwiftData
    try modelContext.save()

    return importedCount
  }

  // MARK: - Private Methods

  /// Present NSOpenPanel and return selected URLs
  private func presentFilePicker() async throws -> [URL] {
    return await withCheckedContinuation { continuation in
      let openPanel = NSOpenPanel()

      // Configure panel
      openPanel.title = "Select Video Files"
      openPanel.message = "Choose video files to import into your library"
      openPanel.canChooseFiles = true
      openPanel.canChooseDirectories = false
      openPanel.allowsMultipleSelection = true
      openPanel.canCreateDirectories = false

      // Filter to video file types
      openPanel.allowedContentTypes = supportedVideoExtensions.compactMap { ext in
        UTType(filenameExtension: ext)
      }

      // Present panel
      openPanel.begin { response in
        if response == .OK {
          continuation.resume(returning: openPanel.urls)
        } else {
          continuation.resume(returning: [])
        }
      }
    }
  }

  /// Import a single video file
  private func importFile(at url: URL) async throws {
    // Check if file already exists in library
    let existingItems = try modelContext.fetch(
      FetchDescriptor<VideoItem>(
        predicate: #Predicate { item in
          item.localURL == url
        }
      )
    )

    guard existingItems.isEmpty else {
      throw ImportError.fileAlreadyExists(url: url)
    }

    // Create security-scoped bookmark
    let bookmarkData = try createSecurityScopedBookmark(for: url)

    // Extract metadata
    let metadata = try await extractMetadata(from: url)

    // Create VideoItem
    let videoItem = VideoItem(
      localURL: url,
      title: metadata.title,
      duration: metadata.duration,
      bookmarkData: bookmarkData
    )

    // Insert into SwiftData
    modelContext.insert(videoItem)
  }

  /// Create security-scoped bookmark for persistent file access
  private func createSecurityScopedBookmark(for url: URL) throws -> Data {
    guard url.startAccessingSecurityScopedResource() else {
      throw ImportError.cannotAccessFile(url: url)
    }
    defer {
      url.stopAccessingSecurityScopedResource()
    }

    do {
      let bookmarkData = try url.bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return bookmarkData
    } catch {
      throw ImportError.bookmarkCreationFailed(url: url, underlyingError: error)
    }
  }

  /// Extract metadata from video file using AVAsset
  private func extractMetadata(from url: URL) async throws -> VideoMetadata {
    let asset = AVAsset(url: url)

    // Extract duration
    let duration: TimeInterval
    do {
      duration = try await asset.load(.duration).seconds
    } catch {
      throw ImportError.metadataExtractionFailed(url: url, underlyingError: error)
    }

    // Extract title from filename (without extension)
    let title = url.deletingPathExtension().lastPathComponent

    return VideoMetadata(title: title, duration: duration)
  }
}

// MARK: - Supporting Types

extension LocalFileImportService {
  /// Metadata extracted from video file
  struct VideoMetadata {
    let title: String
    let duration: TimeInterval
  }

  /// Import-specific errors
  enum ImportError: LocalizedError {
    case fileAlreadyExists(url: URL)
    case cannotAccessFile(url: URL)
    case bookmarkCreationFailed(url: URL, underlyingError: Error)
    case metadataExtractionFailed(url: URL, underlyingError: Error)

    var errorDescription: String? {
      switch self {
      case .fileAlreadyExists(let url):
        return "File already exists in library: \(url.lastPathComponent)"
      case .cannotAccessFile(let url):
        return "Cannot access file: \(url.lastPathComponent)"
      case .bookmarkCreationFailed(let url, _):
        return "Failed to create bookmark for: \(url.lastPathComponent)"
      case .metadataExtractionFailed(let url, _):
        return "Failed to extract metadata from: \(url.lastPathComponent)"
      }
    }

    var recoverySuggestion: String? {
      switch self {
      case .fileAlreadyExists:
        return "This file is already in your library"
      case .cannotAccessFile:
        return "Please ensure the file exists and you have permission to read it"
      case .bookmarkCreationFailed:
        return "The app may not have permission to access this file location"
      case .metadataExtractionFailed:
        return "The file may be corrupted or not a valid video file"
      }
    }
  }
}
