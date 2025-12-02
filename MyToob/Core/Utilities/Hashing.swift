//
//  Hashing.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/1/25.
//

import CryptoKit
import Foundation

/// Utility for generating stable hashed filenames from keys/URLs.
///
/// Uses SHA256 to produce hex strings that are:
/// - Safe for filesystem (no special characters)
/// - Stable (same input always produces same output)
/// - Collision-resistant
///
/// **Usage:**
/// ```swift
/// let filename = Hashing.sha256Hex("https://example.com/api?foo=bar")
/// // Returns: "a1b2c3d4..."  (64-character hex string)
/// ```
enum Hashing {
  /// Generate a SHA256 hex string from an input string.
  /// - Parameter input: The string to hash
  /// - Returns: A 64-character lowercase hex string
  static func sha256Hex(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  /// Generate a canonical cache key string from a URL.
  ///
  /// Creates a deterministic string representation suitable for hashing:
  /// - Normalizes scheme and host to lowercase
  /// - Sorts query parameters by (name, value) for consistent ordering
  /// - Uses percent-encoded query string to avoid encoding inconsistencies
  ///
  /// - Parameter url: The URL to canonicalize
  /// - Returns: A canonical string suitable for hashing
  static func canonicalKeyString(from url: URL) -> String {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return url.absoluteString
    }

    // Sort query items by (name, value) for consistent ordering
    if let items = components.queryItems, !items.isEmpty {
      components.queryItems = items.sorted {
        if $0.name == $1.name {
          return ($0.value ?? "") < ($1.value ?? "")
        }
        return $0.name < $1.name
      }
    }

    // Build canonical string
    var canonical = ""
    if let scheme = components.scheme {
      canonical += scheme.lowercased() + "://"
    }
    if let host = components.host {
      canonical += host.lowercased()
    }
    if let port = components.port {
      canonical += ":\(port)"
    }
    canonical += components.path

    // Use percentEncodedQuery to preserve encoding consistency
    if let query = components.percentEncodedQuery, !query.isEmpty {
      canonical += "?" + query
    }

    return canonical
  }

  /// Generate a canonical cache key string from URL string and query items.
  ///
  /// Creates a deterministic string representation suitable for hashing:
  /// - Parses the URL and merges with additional query items
  /// - Sorts all query parameters by (name, value) for consistent ordering
  /// - Uses percent-encoded query string to avoid encoding inconsistencies
  ///
  /// - Parameters:
  ///   - url: The base URL string (may or may not include query string)
  ///   - queryItems: Additional query items (will be merged with URL query string)
  /// - Returns: A canonical string suitable for hashing
  static func canonicalKeyString(url: String, queryItems: [URLQueryItem]) -> String {
    // Parse the URL to properly handle existing query strings
    guard let parsedURL = URL(string: url),
          var components = URLComponents(url: parsedURL, resolvingAgainstBaseURL: false)
    else {
      // Fallback: simple concatenation if URL parsing fails
      let sortedItems = queryItems.sorted {
        if $0.name == $1.name {
          return ($0.value ?? "") < ($1.value ?? "")
        }
        return $0.name < $1.name
      }
      let queryString = sortedItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
      return queryString.isEmpty ? url : "\(url)?\(queryString)"
    }

    // Merge existing query items with additional ones
    var allItems = components.queryItems ?? []
    allItems.append(contentsOf: queryItems)

    // Sort by (name, value)
    components.queryItems = allItems.sorted {
      if $0.name == $1.name {
        return ($0.value ?? "") < ($1.value ?? "")
      }
      return $0.name < $1.name
    }

    // Build canonical string
    var canonical = ""
    if let scheme = components.scheme {
      canonical += scheme.lowercased() + "://"
    }
    if let host = components.host {
      canonical += host.lowercased()
    }
    if let port = components.port {
      canonical += ":\(port)"
    }
    canonical += components.path

    // Use percentEncodedQuery to preserve encoding consistency
    if let query = components.percentEncodedQuery, !query.isEmpty {
      canonical += "?" + query
    }

    return canonical
  }
}
