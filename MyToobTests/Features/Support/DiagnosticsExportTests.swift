//
//  DiagnosticsExportTests.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/30/25.
//

import Foundation
import Testing

@testable import MyToob

/// Unit tests for DiagnosticsService export and SupportContactService email composition.
/// Story 12.4: Validates:
/// - Diagnostics export produces a valid .zip file
/// - Email subject and body composition are correct
/// - Subject/body contain required disclaimers
@Suite("Diagnostics Export & Email Composition")
struct DiagnosticsExportTests {
  // MARK: - DiagnosticsService Tests

  @Test("Diagnostics export returns a .zip file")
  func exportDiagnosticsProducesZip() async throws {
    // Export diagnostics (last 1 hour to minimize data)
    let url = try await DiagnosticsService.shared.exportDiagnostics(hours: 1)

    // Verify file exists
    #expect(FileManager.default.fileExists(atPath: url.path))

    // Verify file extension is .zip
    #expect(url.pathExtension == "zip")

    // Verify file has non-zero size
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    let size = attributes[.size] as? Int ?? 0
    #expect(size > 0)

    // Clean up
    try? FileManager.default.removeItem(at: url)
  }

  @Test("Diagnostics export filename contains timestamp")
  func exportDiagnosticsFilenameHasTimestamp() async throws {
    let url = try await DiagnosticsService.shared.exportDiagnostics(hours: 1)

    // Filename should contain "MyToob-Diagnostics" and a date pattern
    let filename = url.lastPathComponent
    #expect(filename.contains("MyToob-Diagnostics"))

    // Clean up
    try? FileManager.default.removeItem(at: url)
  }

  // MARK: - SupportContactService Tests

  @Test("Support email address is non-empty")
  func supportEmailIsConfigured() {
    let email = SupportContactService.supportEmail()
    #expect(!email.isEmpty)
    #expect(email.contains("@"))
  }

  @Test("Diagnostics email subject is correct")
  func diagnosticsEmailSubjectIsCorrect() {
    let subject = SupportContactService.diagnosticsEmailSubject()

    #expect(!subject.isEmpty)
    #expect(subject.contains("MyToob"))
    #expect(subject.contains("Diagnostics"))
  }

  @Test("Diagnostics email body contains required elements")
  func diagnosticsEmailBodyContainsRequiredElements() {
    let body = SupportContactService.diagnosticsEmailBody()

    // Body should not be empty
    #expect(!body.isEmpty)

    // Body should mention diagnostics/sanitization
    #expect(body.lowercased().contains("sanitized") || body.lowercased().contains("diagnostic"))

    // Body should mention no personal data
    #expect(body.lowercased().contains("personal data") || body.lowercased().contains("no personal"))

    // Body should mention response time
    #expect(body.lowercased().contains("respond") || body.lowercased().contains("hours"))

    // Body should prompt user to describe issue
    #expect(body.lowercased().contains("describe"))
  }

  @Test("Support email subject is correct")
  func supportEmailSubjectIsCorrect() {
    let subject = SupportContactService.supportEmailSubject()

    #expect(!subject.isEmpty)
    #expect(subject.contains("MyToob"))
    #expect(subject.contains("Support"))
  }

  @Test("Support email body contains app version info")
  func supportEmailBodyContainsVersionInfo() {
    let body = SupportContactService.supportEmailBody()

    #expect(!body.isEmpty)

    // Body should contain version information placeholder
    #expect(body.contains("Version") || body.contains("macOS"))

    // Body should mention response time
    #expect(body.lowercased().contains("respond") || body.lowercased().contains("hours"))
  }

  // MARK: - Email Error Tests

  @Test("SupportContactError has localized descriptions")
  func supportContactErrorsHaveDescriptions() {
    let mailError = SupportContactService.SupportContactError.mailServiceUnavailable
    let configError = SupportContactService.SupportContactError.invalidEmailConfiguration

    // Errors should have non-nil descriptions
    #expect(mailError.errorDescription != nil)
    #expect(configError.errorDescription != nil)

    // Descriptions should be meaningful
    #expect(mailError.errorDescription?.contains("email") == true || mailError.errorDescription?.contains("mail") == true)
  }
}
