//
//  MetadataTextBuilder.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 12/8/25.
//  Story 7.2: Metadata Text Preparation for Embeddings
//

import Foundation

/// Builds optimized text from video metadata for embedding generation.
///
/// Combines video title, channel name, tags, and description into a single
/// string optimized for Apple's NLEmbedding sentence model. Text is cleaned,
/// deduplicated, and truncated to the target length.
///
/// ## Priority Order
/// 1. Title (highest priority - always preserved in full)
/// 2. Channel name
/// 3. Tags (filtered and limited)
/// 4. Description (truncated if needed)
/// 5. OCR text (lowest priority - from Story 7.3)
///
/// ## Usage
/// ```swift
/// let text = MetadataTextBuilder.buildText(
///     title: video.title,
///     channelName: video.channelTitle,
///     tags: video.tags,
///     description: video.videoDescription
/// )
/// let embedding = try await embeddingService.generateEmbedding(text: text)
/// ```
///
/// - Note: This type is `Sendable` as all methods are pure functions with no mutable state.
public struct MetadataTextBuilder: Sendable {

    // MARK: - Public API

    /// Build embedding text from raw metadata components.
    ///
    /// - Parameters:
    ///   - title: Video title (required, highest priority)
    ///   - channelName: Channel name (optional, high priority)
    ///   - tags: Video tags (optional, filtered and limited)
    ///   - description: Video description (optional, lowest priority, truncated if needed)
    ///   - ocrText: OCR-extracted text from thumbnail (optional, Story 7.3 integration)
    /// - Returns: Cleaned and combined text optimized for embedding generation
    public static func buildText(
        title: String,
        channelName: String? = nil,
        tags: [String]? = nil,
        description: String? = nil,
        ocrText: String? = nil
    ) -> String {
        var components: [String] = []

        // 1. Title (highest priority - always included in full)
        let cleanedTitle = cleanText(title)
        if !cleanedTitle.isEmpty {
            components.append(cleanedTitle)
        }

        // 2. Channel name (high priority)
        if let channel = channelName {
            let cleanedChannel = cleanText(channel)
            if !cleanedChannel.isEmpty {
                components.append("by \(cleanedChannel)")
            }
        }

        // 3. Tags (medium priority, filtered and limited)
        if let tags = tags {
            let processedTags = processTags(tags)
            if !processedTags.isEmpty {
                components.append(processedTags.joined(separator: " "))
            }
        }

        // Calculate space used so far
        let currentText = components.joined(separator: "\n")
        let remainingSpace = max(0, EmbeddingConstants.targetTextLength - currentText.count - EmbeddingConstants.componentSeparatorBuffer)

        // 4. Description (lower priority, truncated to fit)
        if let description = description, remainingSpace > EmbeddingConstants.minDescriptionSpace {
            let cleanedDesc = cleanDescription(description)
            if !cleanedDesc.isEmpty {
                let truncatedDesc = truncateAtWordBoundary(cleanedDesc, maxLength: remainingSpace)
                if !truncatedDesc.isEmpty {
                    components.append(truncatedDesc)
                }
            }
        }

        // Recalculate remaining space after description
        let textAfterDesc = components.joined(separator: "\n")
        let spaceForOCR = max(0, EmbeddingConstants.targetTextLength - textAfterDesc.count - EmbeddingConstants.ocrSeparatorBuffer)

        // 5. OCR text (lowest priority - Story 7.3 integration)
        // TODO: Story 7.3 will implement OCR extraction from video thumbnails
        if let ocr = ocrText, spaceForOCR > EmbeddingConstants.minOCRSpace {
            let cleanedOCR = cleanText(ocr)
            if !cleanedOCR.isEmpty {
                let truncatedOCR = truncateAtWordBoundary(cleanedOCR, maxLength: spaceForOCR)
                if !truncatedOCR.isEmpty {
                    components.append(truncatedOCR)
                }
            }
        }

        let result = components.joined(separator: "\n")
        return String(result.prefix(EmbeddingConstants.targetTextLength))
    }

    // MARK: - Text Cleaning

    /// Clean general text (title, channel name, OCR text).
    ///
    /// - Normalizes whitespace (multiple spaces, tabs, newlines → single space)
    /// - Limits excessive emoji
    /// - Trims leading/trailing whitespace
    ///
    /// - Parameter text: The text to clean
    /// - Returns: Cleaned text
    public static func cleanText(_ text: String) -> String {
        var cleaned = text

        // Normalize whitespace: multiple spaces, tabs, newlines → single space
        cleaned = cleaned.replacingOccurrences(
            of: "[\\s]+",
            with: " ",
            options: .regularExpression
        )

        // Remove excessive emoji (keep first 3 per "group")
        cleaned = removeExcessiveEmoji(cleaned)

        // Trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    /// Clean description text with more aggressive cleaning.
    ///
    /// - Removes URLs
    /// - Removes spam patterns (excessive punctuation, "subscribe" phrases)
    /// - Applies general text cleaning
    ///
    /// - Parameter text: The description text to clean
    /// - Returns: Cleaned description
    public static func cleanDescription(_ text: String) -> String {
        var cleaned = text

        // Remove URLs (https://, http://, www.)
        cleaned = cleaned.replacingOccurrences(
            of: "https?://[^\\s]+",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "www\\.[^\\s]+",
            with: "",
            options: .regularExpression
        )

        // Remove excessive punctuation (3+ of same punctuation → single)
        cleaned = cleaned.replacingOccurrences(
            of: "([!?.]){3,}",
            with: "$1",
            options: .regularExpression
        )

        // Remove "follow/subscribe/like" spam phrases
        cleaned = cleaned.replacingOccurrences(
            of: "(?i)(follow|subscribe|like|share|comment)\\s+(me|us|for|to|and|if|the|my|our)[^.!?]*[.!?]?",
            with: "",
            options: .regularExpression
        )

        // Apply general cleaning
        cleaned = cleanText(cleaned)

        return cleaned
    }

    // MARK: - Tag Processing

    /// Process tags: filter generic tags, deduplicate, clean, and limit count.
    ///
    /// - Converts to lowercase for consistency
    /// - Removes generic/spam tags (shorts, viral, trending, etc.)
    /// - Removes single-character tags
    /// - Deduplicates (case-insensitive)
    /// - Limits to `EmbeddingConstants.maxTagsForEmbedding`
    ///
    /// - Parameter tags: Array of tag strings
    /// - Returns: Filtered and cleaned tag array
    public static func processTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for tag in tags {
            let cleaned = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty, single-character, or already seen tags
            guard cleaned.count > 1, !seen.contains(cleaned) else { continue }

            // Skip generic/spam tags
            guard !EmbeddingConstants.genericTagFilter.contains(cleaned) else { continue }

            seen.insert(cleaned)
            result.append(cleaned)

            // Stop at max count
            if result.count >= EmbeddingConstants.maxTagsForEmbedding {
                break
            }
        }

        return result
    }

    // MARK: - Private Helpers

    /// Remove excessive emoji while preserving some for semantic context.
    ///
    /// Keeps up to `maxConsecutiveEmoji` per "run" to prevent emoji spam from diluting embeddings.
    /// Total emoji capped at `maxTotalEmoji`.
    ///
    /// - Note: This detection may miss some emoji (e.g., multi-scalar sequences, skin tone modifiers).
    ///   For embedding purposes, this simple heuristic is sufficient since we only need to limit
    ///   excessive emoji, not detect them all perfectly.
    ///
    /// - Parameter text: Text potentially containing emoji
    /// - Returns: Text with limited emoji
    private static func removeExcessiveEmoji(_ text: String) -> String {
        var emojiCount = 0
        var consecutiveEmoji = 0
        var result = ""
        var lastWasEmoji = false

        for char in text {
            // Simple emoji detection: checks if first scalar has emoji properties.
            // May miss complex emoji sequences, but sufficient for spam limiting.
            let isEmoji = char.unicodeScalars.first?.properties.isEmoji == true &&
                          char.unicodeScalars.first?.properties.isEmojiPresentation == true

            if isEmoji {
                consecutiveEmoji += 1
                if consecutiveEmoji <= EmbeddingConstants.maxConsecutiveEmoji &&
                   emojiCount < EmbeddingConstants.maxTotalEmoji {
                    result.append(char)
                    emojiCount += 1
                }
                lastWasEmoji = true
            } else {
                if lastWasEmoji {
                    consecutiveEmoji = 0
                }
                result.append(char)
                lastWasEmoji = false
            }
        }

        return result
    }

    /// Truncate text at a word boundary near the target length.
    ///
    /// - Parameters:
    ///   - text: Text to truncate
    ///   - maxLength: Maximum character length
    /// - Returns: Truncated text ending at a word boundary
    private static func truncateAtWordBoundary(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }

        let truncated = String(text.prefix(maxLength))

        // Find last space to avoid cutting mid-word
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace])
        }

        return truncated
    }
}
