//
//  MetadataTextBuilderTests.swift
//  MyToobTests
//
//  Created by Claude Code (BMad Master) on 12/8/25.
//  Story 7.2: Metadata Text Preparation for Embeddings
//

import Foundation
import Testing
@testable import MyToob

/// Tests for MetadataTextBuilder - TDD approach
/// These tests define expected behavior before implementation
@Suite("MetadataTextBuilder Tests")
struct MetadataTextBuilderTests {

    // MARK: - Test 1: Combines all fields correctly

    @Test("buildText combines all fields in correct priority order")
    func test_buildText_combinesAllFields() {
        let result = MetadataTextBuilder.buildText(
            title: "SwiftUI Tutorial",
            channelName: "iOS Academy",
            tags: ["swiftui", "ios", "tutorial"],
            description: "Learn SwiftUI basics"
        )

        // Title should come first
        #expect(result.hasPrefix("SwiftUI Tutorial"))
        // Channel should be included
        #expect(result.contains("iOS Academy"))
        // Tags should be included
        #expect(result.contains("swiftui"))
        #expect(result.contains("ios"))
        #expect(result.contains("tutorial"))
        // Description should be included
        #expect(result.contains("Learn SwiftUI basics"))
    }

    // MARK: - Test 2: Handles missing description

    @Test("buildText handles missing description gracefully")
    func test_buildText_handlesMissingDescription() {
        let result = MetadataTextBuilder.buildText(
            title: "Video Title",
            channelName: "Channel Name",
            tags: ["tag1", "tag2"],
            description: nil
        )

        #expect(result.contains("Video Title"))
        #expect(result.contains("Channel Name"))
        #expect(result.contains("tag1"))
        #expect(!result.isEmpty)
    }

    // MARK: - Test 3: Handles missing tags

    @Test("buildText handles missing tags gracefully")
    func test_buildText_handlesMissingTags() {
        let result = MetadataTextBuilder.buildText(
            title: "Video Title",
            channelName: "Channel Name",
            tags: nil,
            description: "Some description"
        )

        #expect(result.contains("Video Title"))
        #expect(result.contains("Channel Name"))
        #expect(result.contains("Some description"))
    }

    // MARK: - Test 4: Truncates long descriptions

    @Test("buildText truncates long description to fit within max length")
    func test_buildText_truncatesLongDescription() {
        let longDescription = String(repeating: "word ", count: 300)  // ~1500 chars

        let result = MetadataTextBuilder.buildText(
            title: "Title",
            channelName: "Channel",
            tags: ["tag"],
            description: longDescription
        )

        #expect(result.count <= EmbeddingConstants.targetTextLength)
    }

    // MARK: - Test 5: Preserves full title

    @Test("buildText always preserves the full title")
    func test_buildText_preservesFullTitle() {
        let title = "This is a very long video title that should never be truncated because it's important"
        let longDescription = String(repeating: "description ", count: 200)

        let result = MetadataTextBuilder.buildText(
            title: title,
            channelName: "Channel",
            tags: nil,
            description: longDescription
        )

        #expect(result.contains(title))
    }

    // MARK: - Test 6: Removes URLs from description

    @Test("cleanDescription removes URLs")
    func test_cleanText_removesURLs() {
        let description = "Check out https://example.com for more info. Also visit http://test.com and www.site.org"

        let result = MetadataTextBuilder.cleanDescription(description)

        #expect(!result.contains("https://"))
        #expect(!result.contains("http://"))
        #expect(!result.contains("www."))
        #expect(result.contains("Check out"))
        #expect(result.contains("for more info"))
    }

    // MARK: - Test 7: Normalizes whitespace

    @Test("cleanText normalizes excessive whitespace")
    func test_cleanText_normalizesWhitespace() {
        let text = "Multiple   spaces\t\ttabs\n\n\nnewlines"

        let result = MetadataTextBuilder.cleanText(text)

        #expect(!result.contains("  "))  // No double spaces
        #expect(!result.contains("\t"))  // No tabs
        #expect(!result.contains("\n\n"))  // No multiple newlines
    }

    // MARK: - Test 8: Filters spam patterns

    @Test("cleanDescription filters spam patterns")
    func test_cleanText_filtersSpamPatterns() {
        let description = "Great video!!! Subscribe to my channel!!! Like and share!!!"

        let result = MetadataTextBuilder.cleanDescription(description)

        // Excessive punctuation should be reduced
        #expect(!result.contains("!!!"))
    }

    // MARK: - Test 9: Limits tag count

    @Test("buildText limits number of tags")
    func test_buildText_limitsTags() {
        let manyTags = (1...20).map { "tag\($0)" }

        let result = MetadataTextBuilder.buildText(
            title: "Title",
            channelName: nil,
            tags: manyTags,
            description: nil
        )

        // Count occurrences of "tag" in result
        let tagCount = result.components(separatedBy: "tag").count - 1
        #expect(tagCount <= EmbeddingConstants.maxTagsForEmbedding)
    }

    // MARK: - Test 10: Filters generic tags

    @Test("processTags filters out generic/spam tags")
    func test_processTags_filtersGenericTags() {
        let tags = ["swiftui", "shorts", "viral", "ios", "trending", "tutorial"]

        let result = MetadataTextBuilder.processTags(tags)

        #expect(result.contains("swiftui"))
        #expect(result.contains("ios"))
        #expect(result.contains("tutorial"))
        #expect(!result.contains("shorts"))
        #expect(!result.contains("viral"))
        #expect(!result.contains("trending"))
    }

    // MARK: - Test 11: Handles completely empty input

    @Test("buildText handles empty input gracefully")
    func test_buildText_handlesEmptyInput() {
        let result = MetadataTextBuilder.buildText(
            title: "",
            channelName: nil,
            tags: nil,
            description: nil
        )

        // Should return empty or minimal string, not crash
        #expect(result.isEmpty || result.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - Test 12: Output length within bounds

    @Test("buildText output is always within max length")
    func test_buildText_outputWithinMaxLength() {
        let result = MetadataTextBuilder.buildText(
            title: String(repeating: "title ", count: 100),
            channelName: String(repeating: "channel ", count: 50),
            tags: (1...50).map { "tag\($0)" },
            description: String(repeating: "description ", count: 200)
        )

        #expect(result.count <= EmbeddingConstants.targetTextLength)
    }

    // MARK: - Test 13: Works with OCR text parameter

    @Test("buildText includes OCR text when provided")
    func test_buildText_includesOCRText() {
        let result = MetadataTextBuilder.buildText(
            title: "Video Title",
            channelName: "Channel",
            tags: nil,
            description: nil,
            ocrText: "Text from thumbnail"
        )

        #expect(result.contains("Text from thumbnail"))
    }

    // MARK: - Test 14: OCR text is lowest priority

    @Test("buildText places OCR text at lowest priority")
    func test_buildText_ocrTextIsLowestPriority() {
        let result = MetadataTextBuilder.buildText(
            title: "Title",
            channelName: "Channel",
            tags: ["tag1"],
            description: "Description",
            ocrText: "OCR"
        )

        // OCR should appear after description
        if let descIndex = result.range(of: "Description")?.lowerBound,
           let ocrIndex = result.range(of: "OCR")?.lowerBound {
            #expect(descIndex < ocrIndex)
        }
    }

    // MARK: - Test 15: Performance test

    @Test("buildText completes quickly")
    func test_buildText_performance() async throws {
        let iterations = 100
        let startTime = Date()

        // Build text multiple times to measure average performance
        for _ in 0..<iterations {
            _ = MetadataTextBuilder.buildText(
                title: "Performance Test Title",
                channelName: "Test Channel",
                tags: ["swift", "ios", "macos", "tutorial", "programming"],
                description: "This is a test description for performance testing purposes."
            )
        }

        let elapsed = Date().timeIntervalSince(startTime)
        // Threshold: 1 second for 100 iterations (10ms per call average).
        // This is generous to handle CI variability, parallel tests, and system load.
        // In isolation on M-series Macs, typical execution is < 10ms total.
        let threshold: TimeInterval = 1.0
        #expect(elapsed < threshold, "Expected \(iterations) calls to complete in < \(threshold)s, took \(elapsed)s")
    }

    // MARK: - Test 16: Removes excessive emoji

    @Test("cleanText limits excessive emoji")
    func test_cleanText_limitsExcessiveEmoji() {
        let text = "🔥🔥🔥🔥🔥🔥🔥🔥 Hot Video 🎉🎉🎉🎉🎉"

        let result = MetadataTextBuilder.cleanText(text)

        // Should contain "Hot Video" and some emoji, but not excessive
        #expect(result.contains("Hot Video"))
        // Count emoji - should be limited
        let emojiCount = result.unicodeScalars.filter { $0.properties.isEmoji }.count
        #expect(emojiCount <= 6)  // Allow up to 3 emoji per "group"
    }

    // MARK: - Test 17: Tag deduplication

    @Test("processTags deduplicates tags")
    func test_processTags_deduplicatesTags() {
        let tags = ["Swift", "swift", "SWIFT", "ios", "iOS"]

        let result = MetadataTextBuilder.processTags(tags)

        // Should have only unique tags (case-insensitive)
        let uniqueLowercased = Set(result.map { $0.lowercased() })
        #expect(uniqueLowercased.count == result.count)
    }

    // MARK: - Test 18: Single character tag filtering

    @Test("processTags filters single character tags")
    func test_processTags_filtersSingleCharacterTags() {
        let tags = ["a", "b", "swift", "x", "ios"]

        let result = MetadataTextBuilder.processTags(tags)

        #expect(!result.contains("a"))
        #expect(!result.contains("b"))
        #expect(!result.contains("x"))
        #expect(result.contains("swift"))
        #expect(result.contains("ios"))
    }
}

// MARK: - VideoItem Extension Tests

/// Tests for VideoItem.embeddingText() extension
/// Requires SwiftData model context for VideoItem creation
@Suite("VideoItem Embedding Text Tests")
struct VideoItemEmbeddingTextTests {

    @Test("VideoItem.embeddingText generates correct text")
    func test_videoItem_embeddingText_generatesCorrectText() {
        // Create a VideoItem with test data
        let video = VideoItem(
            videoID: "test123",
            title: "SwiftUI Tutorial",
            channelID: "UC123",
            channelTitle: "iOS Academy",
            videoDescription: "Learn SwiftUI basics",
            tags: ["swiftui", "ios", "tutorial"],
            duration: 600
        )

        let result = video.embeddingText()

        #expect(result.contains("SwiftUI Tutorial"))
        #expect(result.contains("iOS Academy"))
        #expect(result.contains("swiftui"))
        #expect(result.contains("Learn SwiftUI"))
    }

    @Test("VideoItem.embeddingText handles local video")
    func test_videoItem_embeddingText_handlesLocalVideo() {
        // Local videos have no channel or description
        let video = VideoItem(
            localURL: URL(fileURLWithPath: "/tmp/test.mp4"),
            title: "Local Video File",
            duration: 300
        )

        let result = video.embeddingText()

        #expect(result.contains("Local Video File"))
        #expect(!result.isEmpty)
    }

    @Test("VideoItem.embeddingText includes OCR text")
    func test_videoItem_embeddingText_includesOCRText() {
        let video = VideoItem(
            videoID: "test456",
            title: "Test Video",
            channelID: "UC456",
            duration: 120
        )

        let result = video.embeddingText(ocrText: "Thumbnail Text Here")

        #expect(result.contains("Test Video"))
        #expect(result.contains("Thumbnail Text Here"))
    }

    @Test("VideoItem.embeddingText handles empty tags")
    func test_videoItem_embeddingText_handlesEmptyTags() {
        let video = VideoItem(
            videoID: "test789",
            title: "Video With No Tags",
            channelID: "UC789",
            channelTitle: "Test Channel",
            videoDescription: "A description",
            tags: [],  // Empty tags
            duration: 180
        )

        let result = video.embeddingText()

        #expect(result.contains("Video With No Tags"))
        #expect(result.contains("Test Channel"))
        #expect(result.contains("A description"))
    }
}
