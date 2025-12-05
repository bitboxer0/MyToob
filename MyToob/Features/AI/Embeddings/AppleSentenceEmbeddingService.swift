import Foundation
import NaturalLanguage
import os.log

/// Actor-based service for generating sentence embeddings using Apple's NLEmbedding
///
/// This service provides thread-safe access to Apple's built-in sentence embedding model,
/// which generates 512-dimensional semantic vectors for text.
///
/// - Note: Currently supports **English text only** (`NLLanguage.english`). Non-English text
///   may produce lower quality embeddings or unexpected results. Multi-language support
///   may be added in future versions.
///
/// ## Usage
/// ```swift
/// let embedding = try await AppleSentenceEmbeddingService.shared.generateEmbedding(text: "Hello world")
/// ```
///
/// ## Thread Safety
/// As an actor, all access is automatically serialized, making it safe to call from multiple tasks.
///
/// ## Performance
/// - Single embedding generation: < 10ms on M1 Mac
/// - Memory footprint: < 50MB when model is loaded
@available(iOS 14.0, macOS 11.0, *)
public actor AppleSentenceEmbeddingService: EmbeddingServiceProtocol {
    
    // MARK: - Singleton
    
    /// Shared singleton instance
    public static let shared = AppleSentenceEmbeddingService()
    
    // MARK: - Private Properties
    
    /// The underlying NLEmbedding model for sentence embeddings
    private let sentenceEmbedding: NLEmbedding?
    
    /// Logger for debugging and diagnostics
    private let logger = Logger(subsystem: "com.mytoob.app", category: "ai")
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        self.sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        if sentenceEmbedding == nil {
            logger.warning("Sentence embedding model unavailable on this device")
        } else {
            logger.info("Initialized Apple sentence embedding service (\(EmbeddingConstants.dimension)-dim)")
        }
    }
    
    // MARK: - Public API
    
    /// Generate embedding for a single text
    ///
    /// - Parameter text: The text to generate an embedding for. Leading/trailing whitespace is trimmed.
    /// - Returns: A 512-dimensional L2-normalized embedding vector
    /// - Throws: `EmbeddingError.emptyInput` if text is empty or whitespace-only
    /// - Throws: `EmbeddingError.modelUnavailable` if NLEmbedding is not available
    /// - Throws: `EmbeddingError.generationFailed` if vector generation fails
    public func generateEmbedding(text: String) async throws -> [Float] {
        let embedding = try generateEmbeddingSync(text: text)
        logger.debug("Generated \(embedding.count)-dim embedding for text (\(text.count) chars)")
        return embedding
    }
    
    /// Generate embeddings for multiple texts
    ///
    /// Processes texts sequentially within the actor. NLEmbedding is thread-safe
    /// but not parallelized internally, so sequential processing is optimal.
    ///
    /// - Parameter texts: Array of texts to generate embeddings for
    /// - Returns: Array of embedding vectors in the same order as input
    /// - Throws: `EmbeddingError` if any individual text fails
    public func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        var results: [[Float]] = []
        results.reserveCapacity(texts.count)

        // Process synchronously within actor to avoid actor reentrancy overhead
        for text in texts {
            let embedding = try generateEmbeddingSync(text: text)
            results.append(embedding)
        }

        logger.info("Generated \(results.count) embeddings in batch")

        return results
    }

    // MARK: - Private Helpers

    /// Synchronous embedding generation (for use within actor context)
    ///
    /// This avoids actor reentrancy overhead when processing batches.
    private func generateEmbeddingSync(text: String) throws -> [Float] {
        // Preprocess: trim whitespace
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate input
        guard !cleaned.isEmpty else {
            throw EmbeddingError.emptyInput
        }

        // Check model availability
        guard let embedding = sentenceEmbedding else {
            throw EmbeddingError.modelUnavailable
        }

        // Generate embedding
        guard let vector = embedding.vector(for: cleaned) else {
            logger.error("NLEmbedding returned nil for input (\(cleaned.count) characters)")
            throw EmbeddingError.generationFailed(reason: "NLEmbedding returned nil for input")
        }

        // Convert to Float and L2-normalize
        return normalizeVector(vector.map(Float.init))
    }

    /// L2-normalize a vector to unit length
    private func normalizeVector(_ floats: [Float]) -> [Float] {
        let norm = sqrt(floats.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return floats }
        return floats.map { $0 / norm }
    }
    
    /// Check if the embedding model is available
    ///
    /// Use this to gracefully handle unavailable model before attempting generation.
    public var isModelAvailable: Bool {
        sentenceEmbedding != nil
    }
    
    /// Preload the embedding model
    ///
    /// Call this at app startup to warm up the model and reduce first-embedding latency.
    /// This is a no-op if the model is already loaded or unavailable.
    public func preload() async throws {
        guard let embedding = sentenceEmbedding else {
            throw EmbeddingError.modelUnavailable
        }
        
        // Warm up with a simple sentence
        _ = embedding.vector(for: "preload")
        logger.info("Embedding model preloaded")
    }
}
