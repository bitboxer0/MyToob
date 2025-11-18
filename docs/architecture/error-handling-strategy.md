# Error Handling Strategy

## Error Types

```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case youtube(YouTubeError)
    case ai(AIError)
    case storage(StorageError)
    case authentication(AuthError)

    var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .youtube(let error): return error.localizedDescription
        case .ai(let error): return error.localizedDescription
        case .storage(let error): return error.localizedDescription
        case .authentication(let error): return error.localizedDescription
        }
    }
}

enum YouTubeError: LocalizedError {
    case quotaExceeded
    case invalidVideoID
    case authenticationFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .quotaExceeded: return "YouTube API quota exceeded. Try again tomorrow."
        case .invalidVideoID: return "Video not found or unavailable."
        case .authenticationFailed: return "YouTube sign-in failed. Please try again."
        case .networkUnavailable: return "Network connection unavailable."
        }
    }
}
```

## Error Handling Pattern

**Service Layer:**
```swift
class YouTubeService {
    func fetchVideoDetails(videoIDs: [String]) async throws -> [YouTubeVideo] {
        guard !videoIDs.isEmpty else {
            throw YouTubeError.invalidVideoID
        }

        guard quotaTracker.canMakeRequest(cost: 1) else {
            throw YouTubeError.quotaExceeded
        }

        do {
            let response = try await networkService.get(endpoint: "/videos", params: ["id": videoIDs.joined(separator: ",")])
            return try JSONDecoder().decode(YouTubeVideosResponse.self, from: response).items
        } catch let error as NetworkError {
            throw AppError.youtube(.networkUnavailable)
        } catch {
            OSLog.error("Video fetch failed: \(error.localizedDescription)")
            throw AppError.youtube(.invalidVideoID)
        }
    }
}
```

**ViewModel Layer:**
```swift
@Observable
class LibraryViewModel {
    var videos: [VideoItem] = []
    var errorMessage: String?

    func importSubscriptions() async {
        do {
            let subscriptions = try await youtubeService.fetchSubscriptions()
            // Process subscriptions...
        } catch let error as AppError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "An unexpected error occurred."
            }
        }
    }
}
```

**View Layer:**
```swift
struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()

    var body: some View {
        VStack {
            // UI content
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

---
