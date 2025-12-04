import Foundation

/// Protocol for embedding generation services
/// Enables dependency injection and mocking for testing
public protocol EmbeddingServiceProtocol: Sendable {
    /// Generate embedding for a single text
    /// - Parameter text: The text to generate an embedding for
    /// - Returns: A normalized embedding vector
    /// - Throws: EmbeddingError if generation fails
    func generateEmbedding(text: String) async throws -> [Float]
    
    /// Generate embeddings for multiple texts
    /// - Parameter texts: Array of texts to generate embeddings for
    /// - Returns: Array of normalized embedding vectors in the same order as input
    /// - Throws: EmbeddingError if any generation fails
    func generateEmbeddings(texts: [String]) async throws -> [[Float]]
}
