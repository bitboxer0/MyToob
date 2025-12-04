import XCTest
@testable import MyToob

/// TDD tests for AppleSentenceEmbeddingService
/// Tests written FIRST per Story 7.1 requirements
@available(iOS 14.0, macOS 11.0, *)
final class AppleSentenceEmbeddingServiceTests: XCTestCase {
    
    // MARK: - Test 1: Singleton Accessibility
    
    func test_shared_returnsSameInstance() async {
        // Given
        let instance1 = AppleSentenceEmbeddingService.shared
        let instance2 = AppleSentenceEmbeddingService.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "Shared instance should return the same object")
    }
    
    // MARK: - Test 2: Embedding Generation Returns Correct Dimension
    
    func test_generateEmbedding_returns512Dimensions() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let text = "This is a sample sentence for embedding."
        
        // When
        let embedding = try await service.generateEmbedding(text: text)
        
        // Then
        XCTAssertEqual(embedding.count, EmbeddingConstants.dimension, "Embedding should have \(EmbeddingConstants.dimension) dimensions")
        XCTAssertEqual(embedding.count, 512, "Embedding should have exactly 512 dimensions")
    }
    
    // MARK: - Test 3: Output is Normalized (L2 Normalization)
    
    func test_generateEmbedding_returnsNormalizedVector() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let text = "Test sentence for normalization check."
        
        // When
        let embedding = try await service.generateEmbedding(text: text)
        
        // Then
        // L2 norm should be approximately 1.0 (unit vector)
        let norm = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        XCTAssertEqual(norm, 1.0, accuracy: 0.0001, "Embedding should be L2-normalized (unit length)")
    }
    
    // MARK: - Test 4: Empty Input Handling
    
    func test_generateEmbedding_throwsOnEmptyInput() async {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let emptyText = ""
        
        // When/Then
        do {
            _ = try await service.generateEmbedding(text: emptyText)
            XCTFail("Should throw EmbeddingError.emptyInput for empty string")
        } catch let error as EmbeddingError {
            XCTAssertEqual(error, EmbeddingError.emptyInput, "Should throw emptyInput error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test 5: Whitespace-Only Input Handling
    
    func test_generateEmbedding_throwsOnWhitespaceOnlyInput() async {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let whitespaceText = "   \n\t  "
        
        // When/Then
        do {
            _ = try await service.generateEmbedding(text: whitespaceText)
            XCTFail("Should throw EmbeddingError.emptyInput for whitespace-only string")
        } catch let error as EmbeddingError {
            XCTAssertEqual(error, EmbeddingError.emptyInput, "Should throw emptyInput error for whitespace-only input")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test 6: Consistent Embeddings for Same Input
    
    func test_generateEmbedding_sameInputProducesSameOutput() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let text = "Consistent embedding test sentence."
        
        // When
        let embedding1 = try await service.generateEmbedding(text: text)
        let embedding2 = try await service.generateEmbedding(text: text)
        
        // Then
        XCTAssertEqual(embedding1.count, embedding2.count, "Embeddings should have same dimension")
        
        for i in 0..<embedding1.count {
            XCTAssertEqual(embedding1[i], embedding2[i], accuracy: 0.0001, "Embedding values should be identical at index \(i)")
        }
    }
    
    // MARK: - Test 7: Different Inputs Produce Different Embeddings
    
    func test_generateEmbedding_differentInputsProduceDifferentOutputs() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let text1 = "The quick brown fox jumps over the lazy dog."
        let text2 = "Machine learning enables computers to learn from data."
        
        // When
        let embedding1 = try await service.generateEmbedding(text: text1)
        let embedding2 = try await service.generateEmbedding(text: text2)
        
        // Then
        // Calculate cosine similarity (dot product of normalized vectors)
        var dotProduct: Float = 0
        for i in 0..<embedding1.count {
            dotProduct += embedding1[i] * embedding2[i]
        }
        
        // Different sentences should have cosine similarity < 1.0
        XCTAssertLessThan(dotProduct, 0.99, "Different sentences should produce different embeddings (cosine similarity < 0.99)")
        XCTAssertGreaterThan(dotProduct, -1.0, "Cosine similarity should be valid")
    }
    
    // MARK: - Test 8: Batch Embedding Preserves Order
    
    func test_generateEmbeddings_preservesInputOrder() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let texts = [
            "First sentence about apples.",
            "Second sentence about oranges.",
            "Third sentence about bananas."
        ]
        
        // When
        let batchEmbeddings = try await service.generateEmbeddings(texts: texts)
        
        // Also generate individually for comparison
        var individualEmbeddings: [[Float]] = []
        for text in texts {
            let embedding = try await service.generateEmbedding(text: text)
            individualEmbeddings.append(embedding)
        }
        
        // Then
        XCTAssertEqual(batchEmbeddings.count, texts.count, "Batch should return same number of embeddings as inputs")
        
        for i in 0..<texts.count {
            XCTAssertEqual(batchEmbeddings[i].count, individualEmbeddings[i].count, "Dimensions should match at index \(i)")
            
            // Verify values match (same text should produce same embedding)
            for j in 0..<batchEmbeddings[i].count {
                XCTAssertEqual(batchEmbeddings[i][j], individualEmbeddings[i][j], accuracy: 0.0001, "Values should match at [\(i)][\(j)]")
            }
        }
    }
    
    // MARK: - Test 9: Performance Under 10ms
    
    func test_generateEmbedding_performanceUnder10ms() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let text = "Performance test sentence for embedding generation timing."
        
        // Warm up the model
        _ = try await service.generateEmbedding(text: "Warmup sentence.")
        
        // When
        let iterations = 10
        var totalTime: Double = 0
        
        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await service.generateEmbedding(text: text)
            let end = CFAbsoluteTimeGetCurrent()
            totalTime += (end - start)
        }
        
        let averageTime = totalTime / Double(iterations)
        let averageTimeMs = averageTime * 1000
        
        // Then
        XCTAssertLessThan(averageTimeMs, 10.0, "Average embedding generation should be under 10ms (was \(averageTimeMs)ms)")
    }
    
    // MARK: - Test 10: Thread Safety with Concurrent Calls
    
    func test_generateEmbedding_threadSafeWithConcurrentCalls() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let texts = [
            "Concurrent test sentence one.",
            "Concurrent test sentence two.",
            "Concurrent test sentence three.",
            "Concurrent test sentence four.",
            "Concurrent test sentence five."
        ]
        
        // When - Run all concurrently
        let embeddings = try await withThrowingTaskGroup(of: (Int, [Float]).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let embedding = try await service.generateEmbedding(text: text)
                    return (index, embedding)
                }
            }
            
            var results: [(Int, [Float])] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        // Then
        XCTAssertEqual(embeddings.count, texts.count, "Should have embedding for each input")
        
        for embedding in embeddings {
            XCTAssertEqual(embedding.count, EmbeddingConstants.dimension, "Each embedding should have correct dimension")
            
            // Verify normalized
            let norm = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
            XCTAssertEqual(norm, 1.0, accuracy: 0.0001, "Each embedding should be normalized")
        }
    }
    
    // MARK: - Additional Test: Error Descriptions are Localized
    
    func test_embeddingError_hasLocalizedDescriptions() {
        // Given
        let errors: [EmbeddingError] = [
            .emptyInput,
            .modelUnavailable,
            .generationFailed(reason: "Test reason")
        ]
        
        // Then
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
        
        XCTAssertTrue(EmbeddingError.emptyInput.errorDescription?.contains("empty") ?? false)
        XCTAssertTrue(EmbeddingError.modelUnavailable.errorDescription?.contains("not available") ?? false)
        XCTAssertTrue(EmbeddingError.generationFailed(reason: "Test").errorDescription?.contains("Test") ?? false)
    }
    
    // MARK: - Additional Test: Constants Are Correct
    
    func test_embeddingConstants_areCorrect() {
        XCTAssertEqual(EmbeddingConstants.dimension, 512, "Dimension should be 512")
        XCTAssertEqual(EmbeddingConstants.modelName, "sentenceEmbedding", "Model name should be sentenceEmbedding")
    }
    
    // MARK: - Additional Test: Cosine Similarity Monotonicity (Semantic Similarity)
    
    func test_generateEmbedding_semanticallySimilarTextHasHigherSimilarity() async throws {
        // Given
        let service = AppleSentenceEmbeddingService.shared
        let baseText = "I love programming in Swift."
        let similarText = "Swift programming is my favorite."
        let dissimilarText = "The weather is sunny today."
        
        // When
        let baseEmbedding = try await service.generateEmbedding(text: baseText)
        let similarEmbedding = try await service.generateEmbedding(text: similarText)
        let dissimilarEmbedding = try await service.generateEmbedding(text: dissimilarText)
        
        // Calculate cosine similarities
        func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
            var dot: Float = 0
            for i in 0..<a.count {
                dot += a[i] * b[i]
            }
            return dot
        }
        
        let similarityToSimilar = cosineSimilarity(baseEmbedding, similarEmbedding)
        let similarityToDissimilar = cosineSimilarity(baseEmbedding, dissimilarEmbedding)
        
        // Then
        XCTAssertGreaterThan(similarityToSimilar, similarityToDissimilar, 
            "Similar text should have higher cosine similarity than dissimilar text")
    }
}
