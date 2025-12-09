import Foundation

/// Constants for embedding configuration
public enum EmbeddingConstants: Sendable {
    /// Dimension of the sentence embedding vector (512 for Apple NLEmbedding)
    public static let dimension = 512

    /// Name of the embedding model type
    public static let modelName = "sentenceEmbedding"

    // MARK: - Text Builder Constants (Story 7.2)

    /// Target character length for embedding input text.
    /// NLEmbedding performs well up to ~1500 tokens; 1000 chars ≈ 250 tokens.
    public static let targetTextLength = 1000

    /// Maximum number of tags to include in embedding text
    public static let maxTagsForEmbedding = 10

    // MARK: - Text Builder Buffer Constants

    /// Buffer space reserved for component separators (newlines between sections).
    /// Used when calculating remaining space after title/channel/tags.
    public static let componentSeparatorBuffer = 20

    /// Buffer space reserved for OCR text separator.
    /// Slightly smaller since OCR is the last component.
    public static let ocrSeparatorBuffer = 10

    /// Minimum remaining space required to include description text.
    /// Below this threshold, description is omitted to avoid truncated fragments.
    public static let minDescriptionSpace = 50

    /// Minimum remaining space required to include OCR text.
    /// Below this threshold, OCR is omitted to avoid truncated fragments.
    public static let minOCRSpace = 30

    // MARK: - Emoji Limiting Constants

    /// Maximum consecutive emoji characters to keep per "run".
    /// Prevents emoji spam from diluting embedding quality.
    public static let maxConsecutiveEmoji = 3

    /// Maximum total emoji to keep in cleaned text.
    /// Preserves some emoji for semantic context while limiting spam.
    public static let maxTotalEmoji = 6

    // MARK: - Tag Filtering

    /// Generic/spam tags to filter out during embedding text generation.
    /// These tags have low semantic value and dilute embedding quality.
    /// Note: Year values are dynamically generated - see `genericTagFilter` computed property.
    private static let staticGenericTags: Set<String> = [
        "shorts", "#shorts", "viral", "trending", "subscribe", "like",
        "comment", "share", "new", "latest", "youtube", "video",
        "fyp", "foryou", "foryoupage"
    ]

    /// Years to filter as generic tags (current year and ±1 year).
    /// Computed dynamically to avoid stale hardcoded values.
    private static var yearTags: Set<String> {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Set((currentYear - 1...currentYear + 1).map(String.init))
    }

    /// Combined set of generic/spam tags including dynamic year values.
    public static var genericTagFilter: Set<String> {
        staticGenericTags.union(yearTags)
    }
}
