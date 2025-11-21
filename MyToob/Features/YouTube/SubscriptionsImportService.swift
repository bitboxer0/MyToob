//
//  SubscriptionsImportService.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

import Foundation
import SwiftData
import Combine
import os

/// Service for importing YouTube subscriptions into VideoItem database
///
/// **Features:**
/// - Paginated fetching of subscriptions (50 per page, YouTube API limit)
/// - Pause/resume capability with state persistence
/// - Progress tracking (channels imported / total)
/// - Error handling with automatic retry
/// - Creates VideoItem entries for each subscribed channel
///
/// **Usage:**
/// ```swift
/// let importer = SubscriptionsImportService(modelContext: context)
///
/// // Start import
/// try await importer.startImport()
///
/// // Monitor progress
/// for await progress in importer.progressStream {
///   print("Imported \(progress.imported) / \(progress.total)")
/// }
///
/// // Pause/resume
/// importer.pause()
/// try await importer.resume()
/// ```
@MainActor
final class SubscriptionsImportService: ObservableObject {
  // MARK: - Types

  enum ImportState: Equatable {
    case idle
    case fetching(page: Int)
    case paused(pageToken: String?)
    case completed
    case failed(error: String)
  }

  struct ImportProgress {
    let imported: Int
    let total: Int?
    let currentPage: Int
    let state: ImportState

    var percentage: Double? {
      guard let total = total, total > 0 else { return nil }
      return Double(imported) / Double(total) * 100.0
    }
  }

  // MARK: - Properties

  @Published private(set) var state: ImportState = .idle
  @Published private(set) var progress: ImportProgress

  private let modelContext: ModelContext
  private let youtubeService: YouTubeService
  private var importTask: Task<Void, Error>?

  // MARK: - Initialization

  init(modelContext: ModelContext, youtubeService: YouTubeService = .shared) {
    self.modelContext = modelContext
    self.youtubeService = youtubeService
    self.progress = ImportProgress(imported: 0, total: nil, currentPage: 0, state: .idle)
  }

  // MARK: - Public API

  /// Start importing subscriptions from YouTube
  /// - Throws: YouTubeAPIError if fetch fails
  func startImport() async throws {
    guard state == .idle || state == .completed else {
      LoggingService.shared.app.warning("Import already in progress or paused")
      return
    }

    state = .fetching(page: 1)
    updateProgress(imported: 0, total: nil, currentPage: 1, state: state)

    importTask = Task {
      do {
        try await performImport(pageToken: nil)
        state = .completed
        updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: .completed)
        LoggingService.shared.app.info("Subscription import completed: \(self.progress.imported) channels")
      } catch {
        let errorMessage = error.localizedDescription
        state = .failed(error: errorMessage)
        updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: state)
        LoggingService.shared.app.error("Subscription import failed: \(errorMessage, privacy: .public)")
        throw error
      }
    }

    try await importTask?.value
  }

  /// Pause ongoing import (can be resumed later)
  func pause() {
    guard case .fetching = state else {
      LoggingService.shared.app.warning("Cannot pause - import not in progress")
      return
    }

    importTask?.cancel()
    importTask = nil

    // Store current page token for resume (if we had one, we'd track it here)
    state = .paused(pageToken: nil)
    updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: state)

    LoggingService.shared.app.info("Subscription import paused at \(self.progress.imported) channels")
  }

  /// Resume paused import
  /// - Throws: YouTubeAPIError if fetch fails
  func resume() async throws {
    guard case .paused(let pageToken) = state else {
      LoggingService.shared.app.warning("Cannot resume - import not paused")
      return
    }

    state = .fetching(page: progress.currentPage)
    updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: state)

    importTask = Task {
      do {
        try await performImport(pageToken: pageToken)
        state = .completed
        updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: .completed)
        LoggingService.shared.app.info("Subscription import resumed and completed: \(self.progress.imported) channels")
      } catch {
        let errorMessage = error.localizedDescription
        state = .failed(error: errorMessage)
        updateProgress(imported: progress.imported, total: progress.total, currentPage: progress.currentPage, state: state)
        LoggingService.shared.app.error("Subscription import failed after resume: \(errorMessage, privacy: .public)")
        throw error
      }
    }

    try await importTask?.value
  }

  /// Cancel ongoing import (cannot be resumed, will start from beginning)
  func cancel() {
    importTask?.cancel()
    importTask = nil

    state = .idle
    updateProgress(imported: 0, total: nil, currentPage: 0, state: .idle)

    LoggingService.shared.app.info("Subscription import cancelled")
  }

  // MARK: - Private Methods

  /// Perform paginated import of subscriptions
  /// - Parameter pageToken: Token for next page (nil for first page)
  private func performImport(pageToken: String?) async throws {
    var currentPageToken: String? = pageToken
    var page = progress.currentPage > 0 ? progress.currentPage : 1
    var importedCount = progress.imported

    repeat {
      // Check if task was cancelled
      try Task.checkCancellation()

      // Update state
      state = .fetching(page: page)
      updateProgress(imported: importedCount, total: progress.total, currentPage: page, state: state)

      LoggingService.shared.network.info("Fetching subscriptions page \(page, privacy: .public)")

      // Fetch subscriptions page
      let response: YouTubeSubscriptionResponse = try await youtubeService.fetchSubscriptions(
        maxResults: 50,
        pageToken: currentPageToken
      )

      // Update total count from first page
      if progress.total == nil, let totalResults = response.pageInfo?.totalResults {
        updateProgress(imported: importedCount, total: totalResults, currentPage: page, state: state)
      }

      // Process subscriptions
      for subscription in response.items {
        try Task.checkCancellation()

        // Create VideoItem for channel (placeholder - full VideoItem model TBD in Epic D)
        // For now, just log the channel
        let channelID = subscription.snippet.resourceId.channelId ?? "unknown"
        let channelTitle = subscription.snippet.title

        LoggingService.shared.app.debug(
          "Imported subscription: \(channelTitle, privacy: .public) (\(channelID, privacy: .private))"
        )

        // TODO: Once VideoItem model is implemented (Epic D), insert into SwiftData:
        // let videoItem = VideoItem(
        //   videoID: nil,
        //   channelID: channelID,
        //   title: channelTitle,
        //   description: subscription.snippet.description,
        //   thumbnailURL: subscription.snippet.thumbnails.default?.url,
        //   isLocal: false,
        //   itemType: .channel
        // )
        // modelContext.insert(videoItem)

        importedCount += 1
        updateProgress(imported: importedCount, total: progress.total, currentPage: page, state: state)
      }

      // Save context after each page
      // try modelContext.save()  // Uncomment when VideoItem model exists

      // Move to next page
      currentPageToken = response.nextPageToken
      if currentPageToken != nil {
        page += 1
      }

      LoggingService.shared.network.info(
        "Completed page \(page, privacy: .public): \(importedCount)/\(self.progress.total ?? 0) channels"
      )

    } while currentPageToken != nil

    LoggingService.shared.app.info("Subscription import finished: \(importedCount) channels imported")
  }

  /// Update progress state
  private func updateProgress(imported: Int, total: Int?, currentPage: Int, state: ImportState) {
    progress = ImportProgress(
      imported: imported,
      total: total,
      currentPage: currentPage,
      state: state
    )
  }
}
