//
//  IntentError.swift
//  MyToob
//
//  Created by Claude Code on 12/8/25.
//

import AppIntents
import Foundation

/// Error types for App Intents operations
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
  /// The requested video was not found in the library
  case videoNotFound

  /// The requested collection was not found
  case collectionNotFound

  /// No videos available in the library or matching the criteria
  case noVideosFound

  /// A database operation failed
  case databaseError(String)

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .videoNotFound:
      return "Video not found in library"
    case .collectionNotFound:
      return "Collection not found"
    case .noVideosFound:
      return "No videos available"
    case .databaseError(let message):
      return "Database error: \(message)"
    }
  }
}
