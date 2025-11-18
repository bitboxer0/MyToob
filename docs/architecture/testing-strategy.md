# Testing Strategy

## Testing Pyramid

```
        E2E Tests (5%)
      /                \
   Integration (15%)
  /                    \
Unit Tests (80%)
```

**Unit Tests (80% coverage target):**
- Models: SwiftData model creation, relationships, validation
- Services: YouTube API client, AI service, search service, Focus Mode manager
- Repositories: CRUD operations, query logic
- Utilities: String extensions, date formatting, configuration parsing

**Integration Tests (15% coverage):**
- SwiftData persistence: Write → read → update → delete cycles
- Core ML inference: Real model with known inputs → expected outputs
- YouTube API: Mock server with real response structures
- CloudKit sync: Conflict resolution with simulated conflicts

**E2E Tests (5% coverage):**
- Onboarding flow: Launch → OAuth → import subscriptions → first search
- Search workflow: Query → results → click video → playback
- Collection creation: New collection → add videos → export Markdown
- Focus Mode: Enable → verify distractions hidden → disable

## Test Organization

**Unit Tests Structure:**
```
MyToobTests/
├── Models/
│   ├── VideoItemTests.swift
│   └── ClusterLabelTests.swift
├── Services/
│   ├── YouTubeServiceTests.swift
│   ├── AIServiceTests.swift
│   ├── SearchServiceTests.swift
│   └── FocusModeManagerTests.swift
├── Repositories/
│   └── VideoRepositoryTests.swift
├── Utilities/
│   └── StringExtensionsTests.swift
└── Mocks/
    ├── MockYouTubeService.swift
    ├── MockVideoRepository.swift
    └── MockCoreMLModel.swift
```

**UI Tests Structure:**
```
MyToobUITests/
├── OnboardingTests.swift
├── SearchFlowTests.swift
├── CollectionFlowTests.swift
├── PlaybackTests.swift
└── FocusModeTests.swift
```

## Test Examples

**Unit Test (Service):**
```swift
@Test("YouTubeService fetches video details with ETag caching")
func testVideoDetailsFetchWithETag() async throws {
    // Arrange
    let mockNetwork = MockNetworkService()
    mockNetwork.mockResponse(
        url: "https://www.googleapis.com/youtube/v3/videos?id=abc123",
        headers: ["ETag": "xyz"],
        body: """
        {"items": [{"id": "abc123", "snippet": {"title": "Test Video"}}]}
        """
    )
    let service = YouTubeService(networkService: mockNetwork)

    // Act
    let videos = try await service.fetchVideoDetails(videoIDs: ["abc123"])

    // Assert
    #expect(videos.count == 1)
    #expect(videos[0].title == "Test Video")
    #expect(mockNetwork.lastRequest?.headers["If-None-Match"] == nil) // First request

    // Act again (should use ETag)
    _ = try await service.fetchVideoDetails(videoIDs: ["abc123"])

    // Assert
    #expect(mockNetwork.lastRequest?.headers["If-None-Match"] == "xyz") // Second request with ETag
}
```

**UI Test (E2E):**
```swift
@Test("Complete search workflow from query to playback")
func testSearchAndPlayWorkflow() async throws {
    let app = XCUIApplication()
    app.launch()

    // Search for video
    let searchBar = app.searchFields["Search videos..."]
    searchBar.tap()
    searchBar.typeText("swift concurrency")

    // Wait for results
    let resultsGrid = app.scrollViews["SearchResults"]
    #expect(resultsGrid.waitForExistence(timeout: 2))

    // Click first result
    let firstVideo = resultsGrid.cells.element(boundBy: 0)
    firstVideo.tap()

    // Verify player loaded
    let playerView = app.otherElements["VideoPlayer"]
    #expect(playerView.waitForExistence(timeout: 3))

    // Verify playback controls visible
    let playButton = app.buttons["Play"]
    #expect(playButton.exists)
}
```

---
