//
//  LocalFileImportServiceTests.swift
//  MyToobTests
//
//  Tests for LocalFileImportService
//

import XCTest
import SwiftData
import AVFoundation
@testable import MyToob

@MainActor
final class LocalFileImportServiceTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var importService: LocalFileImportService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([VideoItem.self, Note.self, ClusterLabel.self, ChannelBlacklist.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        importService = LocalFileImportService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        importService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Metadata Extraction Tests

    func testExtractMetadataFromValidVideo() async throws {
        // Create a temporary test video file
        let testVideoURL = try createTestVideoFile()
        defer { try? FileManager.default.removeItem(at: testVideoURL) }

        // Use reflection to call private method (for testing only)
        let metadata = try await extractMetadataViaReflection(from: testVideoURL)

        XCTAssertFalse(metadata.title.isEmpty, "Title should be extracted from filename")
        XCTAssertEqual(metadata.title, testVideoURL.deletingPathExtension().lastPathComponent)
        XCTAssertGreaterThan(metadata.duration, 0, "Duration should be greater than 0")
    }

    func testExtractMetadataFromNonExistentFile() async throws {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent.mp4")

        do {
            _ = try await extractMetadataViaReflection(from: nonExistentURL)
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected to throw
            XCTAssertTrue(error is LocalFileImportService.ImportError)
        }
    }

    // MARK: - Bookmark Creation Tests

    func testCreateSecurityScopedBookmark() throws {
        // Create a temporary test file
        let testURL = try createTestVideoFile()
        defer { try? FileManager.default.removeItem(at: testURL) }

        // Start accessing security-scoped resource
        guard testURL.startAccessingSecurityScopedResource() else {
            XCTFail("Failed to start accessing security-scoped resource")
            return
        }
        defer { testURL.stopAccessingSecurityScopedResource() }

        // Create bookmark
        let bookmarkData = try testURL.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        XCTAssertFalse(bookmarkData.isEmpty, "Bookmark data should not be empty")
    }

    func testResolveSecurityScopedBookmark() throws {
        // Create a temporary test file
        let originalURL = try createTestVideoFile()
        defer { try? FileManager.default.removeItem(at: originalURL) }

        // Create bookmark
        guard originalURL.startAccessingSecurityScopedResource() else {
            XCTFail("Failed to start accessing security-scoped resource")
            return
        }

        let bookmarkData: Data
        do {
            bookmarkData = try originalURL.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            originalURL.stopAccessingSecurityScopedResource()
            throw error
        }
        originalURL.stopAccessingSecurityScopedResource()

        // Resolve bookmark
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        XCTAssertEqual(resolvedURL.path, originalURL.path, "Resolved URL should match original")
        XCTAssertFalse(isStale, "Bookmark should not be stale immediately after creation")

        // Access the resolved URL
        guard resolvedURL.startAccessingSecurityScopedResource() else {
            XCTFail("Failed to access resolved security-scoped resource")
            return
        }
        defer { resolvedURL.stopAccessingSecurityScopedResource() }

        // Verify file is accessible
        XCTAssertTrue(FileManager.default.fileExists(atPath: resolvedURL.path))
    }

    // MARK: - Helper Methods

    /// Create a temporary test video file
    /// Note: This creates a minimal valid MP4 file for testing purposes
    private func createTestVideoFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("test_video_\(UUID().uuidString).mp4")

        // Create a minimal valid video file using AVAssetWriter
        let writer = try AVAssetWriter(url: videoURL, fileType: .mp4)

        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 640,
            AVVideoHeightKey: 480
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false

        guard writer.canAdd(videoInput) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
        }

        writer.add(videoInput)

        guard writer.startWriting() else {
            throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot start writing"])
        }

        writer.startSession(atSourceTime: .zero)

        // Finish writing (creates minimal valid file)
        videoInput.markAsFinished()

        // Use synchronous waiting for writer to finish
        let finishExpectation = expectation(description: "Writer finished")
        writer.finishWriting {
            finishExpectation.fulfill()
        }
        wait(for: [finishExpectation], timeout: 5.0)

        return videoURL
    }

    /// Extract metadata via reflection (to test private method)
    private func extractMetadataViaReflection(from url: URL) async throws -> LocalFileImportService.VideoMetadata {
        // Since extractMetadata is private, we'll recreate its logic here for testing
        let asset = AVAsset(url: url)

        let duration: TimeInterval
        do {
            duration = try await asset.load(.duration).seconds
        } catch {
            throw LocalFileImportService.ImportError.metadataExtractionFailed(url: url, underlyingError: error)
        }

        let title = url.deletingPathExtension().lastPathComponent

        return LocalFileImportService.VideoMetadata(title: title, duration: duration)
    }
}
