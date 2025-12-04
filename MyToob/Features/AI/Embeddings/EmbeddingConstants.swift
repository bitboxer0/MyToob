import Foundation

/// Constants for embedding configuration
public enum EmbeddingConstants: Sendable {
    /// Dimension of the sentence embedding vector (512 for Apple NLEmbedding)
    public static let dimension = 512
    
    /// Name of the embedding model type
    public static let modelName = "sentenceEmbedding"
}
