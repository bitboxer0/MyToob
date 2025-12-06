import Foundation

/// Errors that can occur during embedding generation
public enum EmbeddingError: LocalizedError, Sendable, Equatable {
    /// The sentence embedding model is not available on this device
    case modelUnavailable
    /// Failed to generate embedding vector
    case generationFailed(reason: String)
    /// Input text was empty or contained only whitespace
    case emptyInput
    
    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Sentence embedding model is not available on this device."
        case .generationFailed(let reason):
            return "Failed to generate embedding: \(reason)"
        case .emptyInput:
            return "Cannot generate embedding for empty text."
        }
    }
}
