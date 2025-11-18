# Epic 7: On-Device AI Embeddings & Vector Index

**Goal:** Implement Core ML-powered text embeddings generation from video metadata (titles, descriptions, thumbnail OCR text) and build an HNSW vector index for fast semantic similarity search. This epic establishes the AI foundation that enables intelligent content discovery without cloud dependencies, keeping all processing on-device for privacy.

## Story 7.1: Core ML Embedding Model Integration

As a **developer**,
I want **a Core ML model that generates 384-dimensional embeddings from text**,
so that **video metadata can be converted to vectors for semantic search**.

**Acceptance Criteria:**
1. Small sentence-transformer model (e.g., all-MiniLM-L6-v2) converted to Core ML format (`.mlmodel` or `.mlpackage`)
2. Model quantized to 8-bit for performance (reduces model size, speeds up inference)
3. Model added to Xcode project as resource, loaded at app startup
4. Swift wrapper created: `EmbeddingService.generateEmbedding(text: String) async -> [Float]`
5. Input text preprocessed: lowercased, truncated to model's max length (typically 256 tokens)
6. Output: 384-element Float array (embedding vector)
7. Inference latency measured: <10ms average on M1 Mac (target met)
8. Unit tests verify embeddings are consistent (same input → same output)

## Story 7.2: Metadata Text Preparation for Embeddings

As a **developer**,
I want **to combine video title, description, and tags into a single text representation**,
so that **embeddings capture the semantic meaning of the video content**.

**Acceptance Criteria:**
1. For each `VideoItem`, concatenate: `title + " " + description + " " + tags.joined(separator: " ")`
2. Text cleaned: remove URLs, HTML tags, excessive whitespace, non-ASCII characters (optional, if they hurt model performance)
3. Text truncated to model's max input length (typically 256 tokens ≈ 1000 characters)
4. Title weighted more heavily (optional: repeat title 2-3 times in concatenated text for emphasis)
5. If metadata is minimal (e.g., local file with only filename), fall back to filename only
6. Empty or very short text (<10 characters) handled gracefully: generate default embedding or skip
7. Unit tests verify text preparation with various input scenarios (long description, missing title, etc.)

## Story 7.3: Thumbnail OCR Text Extraction

As a **developer**,
I want **to extract text from video thumbnails using Vision framework**,
so that **text visible in thumbnails (e.g., video titles, labels) enhances semantic embeddings**.

**Acceptance Criteria:**
1. `VNRecognizeTextRequest` used to extract text from thumbnail images
2. Thumbnail downloaded (or loaded from cache) as `NSImage`/`CGImage`
3. OCR runs asynchronously (doesn't block main thread)
4. Extracted text combined with metadata text before embedding generation
5. OCR failures handled gracefully (if no text found, continue without OCR text)
6. OCR text cleaned: remove low-confidence results (<0.5 confidence threshold)
7. Performance acceptable: OCR adds <100ms to embedding pipeline (measured)
8. Unit tests verify OCR extraction with sample thumbnails (text-heavy vs. text-free)

## Story 7.4: Batch Embedding Generation Pipeline

As a **user**,
I want **embeddings generated automatically for all imported videos**,
so that **semantic search works without manual intervention**.

**Acceptance Criteria:**
1. On video import (YouTube or local), trigger embedding generation in background queue
2. Batch processing: process up to 10 videos at a time (parallel inference using Core ML)
3. Progress indicator shown: "Generating embeddings: 45/120 videos..."
4. Embedding stored in `VideoItem.embedding` (transformable [Float] array in SwiftData)
5. If embedding generation fails (e.g., Core ML error), log error and retry later
6. "Re-generate Embeddings" action in Settings forces regeneration for all videos (useful after model update)
7. App usable while embeddings generate (non-blocking background task)
8. Embeddings persist across app restarts (stored in SwiftData)

## Story 7.5: HNSW Vector Index Construction

As a **developer**,
I want **an HNSW index built from all video embeddings**,
so that **vector similarity queries return results in <50ms**.

**Acceptance Criteria:**
1. HNSW index implementation integrated (use existing Swift/C++ library or implement custom)
2. Index built from all `VideoItem.embedding` vectors on app launch (if embeddings exist)
3. Index parameters tuned: M=16 (connections per layer), ef_construction=200 (construction search depth)
4. Index stored on disk for persistence: `~/Library/Application Support/MyToob/vector-index.bin`
5. Index incrementally updated when new videos added (no full rebuild required)
6. Index rebuild time measured: <5 seconds for 1,000 videos on M1 Mac (target met)
7. Query interface: `VectorIndex.search(query: [Float], k: Int) async -> [VideoItem]` returns top-k nearest neighbors
8. Unit tests verify index returns correct neighbors (known similar vectors)

## Story 7.6: Vector Similarity Search API

As a **user**,
I want **to search videos using natural language queries**,
so that **I can find relevant content even if I don't remember exact titles**.

**Acceptance Criteria:**
1. User types query in search bar: "swift concurrency tutorials"
2. Query text converted to embedding using same Core ML model
3. Query embedding used to search HNSW index for top-20 nearest neighbors
4. Results sorted by cosine similarity score (higher = more similar)
5. Search completes in <50ms (P95 latency target met)
6. Results displayed in main content area with similarity scores (optional: show % match)
7. Empty results handled: "No similar videos found. Try a different query."
8. UI test verifies search returns expected results for sample queries

---
