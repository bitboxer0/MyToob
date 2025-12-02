//
//  AppConfig.swift
//  MyToob
//
//  Created by Claude Code on 2024.
//
//  Centralized accessors for compliance-related URLs and configuration from Info.plist.
//  This allows environment-specific configuration without code changes.
//

import Foundation

/// Configuration accessor for Info.plist-driven settings.
/// Keys are prefixed with "MT" (MyToob) to avoid collisions.
enum AppConfig {

  private static var info: [String: Any] {
    Bundle.main.infoDictionary ?? [:]
  }

  // MARK: - Compliance URLs

  /// URL for the Content Policy page.
  /// Info.plist key: MTContentPolicyURL
  static var contentPolicyURL: URL? {
    guard let urlString = info["MTContentPolicyURL"] as? String else { return nil }
    return URL(string: urlString)
  }

  /// Support email address.
  /// Info.plist key: MTSupportEmail
  static var supportEmail: String? {
    info["MTSupportEmail"] as? String
  }

  /// URL for web-based support (fallback if email unavailable).
  /// Info.plist key: MTSupportWebURL
  static var supportWebURL: URL? {
    guard let urlString = info["MTSupportWebURL"] as? String else { return nil }
    return URL(string: urlString)
  }
}
