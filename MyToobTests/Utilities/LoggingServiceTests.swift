//
//  LoggingServiceTests.swift
//  MyToobTests
//
//  Tests for LoggingService
//

import OSLog
import Testing

@testable import MyToob

@Suite("LoggingService Tests")
struct LoggingServiceTests {
  @Test("LoggingService initializes as singleton")
  func testSingletonInitialization() {
    let instance1 = LoggingService.shared
    let instance2 = LoggingService.shared
    
    #expect(instance1 === instance2)
  }
  
  @Test("All log categories are accessible")
  func testLogCategoriesAccessible() {
    let service = LoggingService.shared
    
    // Verify all Logger instances are accessible
    // Logger is a struct, so we can't check for nil, but we can verify they're defined
    let _ = service.app
    let _ = service.network
    let _ = service.ai
    let _ = service.player
    let _ = service.sync
    let _ = service.ui
    
    // If we get here without crashes, all categories are accessible
    #expect(true)
  }
  
  @Test("Debug level logging does not crash")
  func testDebugLogging() {
    let service = LoggingService.shared
    
    // Test debug logging on each category
    service.app.debug("Test debug message")
    service.network.debug("Test network debug")
    service.ai.debug("Test AI debug")
    service.player.debug("Test player debug")
    service.sync.debug("Test sync debug")
    service.ui.debug("Test UI debug")
    
    #expect(true)
  }
  
  @Test("Info level logging does not crash")
  func testInfoLogging() {
    let service = LoggingService.shared
    
    service.app.info("Test info message")
    service.network.info("Test network info")
    service.ai.info("Test AI info")
    service.player.info("Test player info")
    service.sync.info("Test sync info")
    service.ui.info("Test UI info")
    
    #expect(true)
  }
  
  @Test("Notice level logging does not crash")
  func testNoticeLogging() {
    let service = LoggingService.shared
    
    service.app.notice("Test notice message")
    service.network.notice("Test network notice")
    service.ai.notice("Test AI notice")
    service.player.notice("Test player notice")
    service.sync.notice("Test sync notice")
    service.ui.notice("Test UI notice")
    
    #expect(true)
  }
  
  @Test("Error level logging does not crash")
  func testErrorLogging() {
    let service = LoggingService.shared
    
    service.app.error("Test error message")
    service.network.error("Test network error")
    service.ai.error("Test AI error")
    service.player.error("Test player error")
    service.sync.error("Test sync error")
    service.ui.error("Test UI error")
    
    #expect(true)
  }
  
  @Test("Fault level logging does not crash")
  func testFaultLogging() {
    let service = LoggingService.shared
    
    service.app.fault("Test fault message")
    service.network.fault("Test network fault")
    service.ai.fault("Test AI fault")
    service.player.fault("Test player fault")
    service.sync.fault("Test sync fault")
    service.ui.fault("Test UI fault")
    
    #expect(true)
  }
  
  @Test("Privacy levels work as expected")
  func testPrivacyLevels() {
    let service = LoggingService.shared
    let sensitiveData = "secret-token-12345"
    let privateData = "video-id-abc123"
    let publicData = "error-code-404"
    
    // Test different privacy levels (should not crash)
    service.app.info("Public: \(publicData, privacy: .public)")
    service.app.info("Private: \(privateData, privacy: .private)")
    service.app.info("Sensitive: \(sensitiveData, privacy: .sensitive)")
    
    #expect(true)
  }
  
  @Test("Logging with interpolation works")
  func testLoggingWithInterpolation() {
    let service = LoggingService.shared
    let videoID = "abc123"
    let errorCode = 404
    let duration: TimeInterval = 120.5
    
    service.app.info("Processing video: \(videoID, privacy: .private)")
    service.network.error("Request failed with code: \(errorCode, privacy: .public)")
    service.player.debug("Video duration: \(duration, privacy: .public) seconds")
    
    #expect(true)
  }
}
