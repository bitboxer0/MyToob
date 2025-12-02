//
//  ContentView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/20/25.
//

import SwiftData
import SwiftUI

/// Placeholder content view
/// Will be replaced with full YouTube + local file UI in later stories (Epic F)
struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var syncViewModel: SyncStatusViewModel
  @Query private var videoItems: [VideoItem]
  @Query private var hiddenChannels: [ChannelBlacklist]

  @StateObject private var oauth = OAuth2Handler.shared

  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showImportError = false
  @State private var showOAuthConsent = false
  @State private var showSubscriptionsImport = false

  // Hide channel state
  @State private var showHideChannelDialog = false
  @State private var channelToHide: (id: String, name: String?)? = nil
  @State private var hideChannelReason = ""
  @State private var hideChannelError: Error?
  @State private var showHideChannelError = false

  // Report content state
  @State private var showReportContentDialog = false
  @State private var videoToReport: String? = nil

  // Cache management state
  @State private var showClearCacheConfirmation = false
  @State private var showCacheClearedAlert = false

  // Compliance export state (developer-only)
  @State private var exportError: Error?
  @State private var showExportError = false
  @State private var showExportSuccess = false
  @State private var exportedURL: URL?

  // MARK: - Computed Properties

  /// Filtered video items excluding hidden channels
  private var visibleVideoItems: [VideoItem] {
    let hiddenChannelIDs = Set(hiddenChannels.map(\.channelID))
    return videoItems.filter { item in
      // Always show local files
      guard let channelID = item.channelID else { return true }
      // Filter out hidden channels
      return !hiddenChannelIDs.contains(channelID)
    }
  }

  /// Display name for the channel being hidden
  private var channelDisplayName: String {
    if let name = channelToHide?.name, !name.isEmpty {
      return name
    }
    if let id = channelToHide?.id {
      return "Channel \(String(id.prefix(8)))"
    }
    return "this channel"
  }

  // MARK: - Sidebar Sections (extracted to help type checker)

  @ViewBuilder
  private var collectionsSection: some View {
    Section {
      Label("All Videos", systemImage: "play.rectangle.on.rectangle")
      Label("Recently Watched", systemImage: "clock")
      Label("Favorites", systemImage: "star")
    } header: {
      Text("Collections")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("CollectionsSection")
    }
  }

  @ViewBuilder
  private var youTubeSection: some View {
    Section {
      if oauth.isAuthenticated {
        youTubeAuthenticatedContent
      } else {
        youTubeUnauthenticatedContent
      }
    } header: {
      youTubeSectionHeader
    }
  }

  @ViewBuilder
  private var youTubeAuthenticatedContent: some View {
    Label("Subscriptions", systemImage: "person.2")
    Label("Playlists", systemImage: "list.bullet")

    Button {
      showSubscriptionsImport = true
    } label: {
      Label("Import Subscriptions", systemImage: "arrow.down.circle")
    }
    .accessibilityLabel("Import Subscriptions")
    .accessibilityHint("Opens dialog to import YouTube subscriptions")

    NavigationLink {
      HiddenChannelsView()
    } label: {
      Label("Manage Hidden Channels", systemImage: "eye.slash.fill")
    }
    .accessibilityIdentifier("ManageHiddenChannels")
    .accessibilityLabel("Manage Hidden Channels")
    .accessibilityHint("View and unhide blocked YouTube channels")

    Button {
      Task {
        try? oauth.signOut()
      }
    } label: {
      Label("Sign Out", systemImage: "person.crop.circle.badge.xmark")
    }
    .foregroundStyle(.red)
  }

  @ViewBuilder
  private var youTubeUnauthenticatedContent: some View {
    Button {
      showOAuthConsent = true
    } label: {
      Label("Connect YouTube Account", systemImage: "person.crop.circle.badge.plus")
    }
    .accessibilityLabel("Connect YouTube Account")
    .accessibilityHint("Opens consent screen to authorize YouTube access")
  }

  @ViewBuilder
  private var youTubeSectionHeader: some View {
    HStack(spacing: 6) {
      if let _ = NSImage(named: "YouTube/Logo") {
        Image("YouTube/Logo")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 14)
          .accessibilityIdentifier("YouTubeSidebarLogo")
      } else {
        Image(systemName: "play.rectangle.fill")
          .foregroundStyle(.red)
          .accessibilityIdentifier("YouTubeSidebarLogo")
      }
      Text("YouTube")
    }
    .accessibilityAddTraits(.isHeader)
    .accessibilityIdentifier("YouTubeSection")
  }

  @ViewBuilder
  private var localFilesSection: some View {
    Section {
      Label("All Local Videos", systemImage: "folder")
        .accessibilityIdentifier("AllLocalVideos")

      Button(action: importLocalFiles) {
        Label("Import Local Files", systemImage: "plus.circle")
      }
      .disabled(isImporting)
      .accessibilityLabel("Import Local Files")
      .accessibilityIdentifier("ImportLocalFilesButton")
      .accessibilityHint("Opens file picker to select video files to import")
    } header: {
      Text("Local Files")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("LocalFilesSection")
    }
  }

  @ViewBuilder
  private var cacheManagementSection: some View {
    Section {
      Button(role: .destructive) {
        showClearCacheConfirmation = true
      } label: {
        Label("Clear Caches", systemImage: "trash")
      }
      .accessibilityIdentifier("ClearCachesButton")
      .accessibilityLabel("Clear Caches")
      .accessibilityHint("Removes cached metadata and thumbnails to free up disk space")
    } header: {
      Text("Cache Management")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("CacheManagementSection")
    }
  }

  @ViewBuilder
  private var aboutAndSupportSection: some View {
    Section {
      contentPolicyButton
      contactSupportButton
    } header: {
      Text("About & Support")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("AboutSupportSection")
    }
  }

  @ViewBuilder
  private var contentPolicyButton: some View {
    Button {
      if let url = AppConfig.contentPolicyURL {
        NSWorkspace.shared.open(url)
        ComplianceLogger.shared.logContentPolicyAccess(context: "sidebar")
      }
    } label: {
      Label("Content Policy", systemImage: "doc.text.magnifyingglass")
    }
    .disabled(AppConfig.contentPolicyURL == nil)
    .accessibilityIdentifier("ContentPolicyLink")
    .accessibilityLabel("Open Content Policy")
  }

  @ViewBuilder
  private var contactSupportButton: some View {
    Button {
      if let email = AppConfig.supportEmail,
        let url = URL(string: "mailto:\(email)?subject=MyToob%20Support")
      {
        NSWorkspace.shared.open(url)
        ComplianceLogger.shared.logSupportContact(method: "email")
      } else if let url = AppConfig.supportWebURL {
        NSWorkspace.shared.open(url)
        ComplianceLogger.shared.logSupportContact(method: "web")
      }
    } label: {
      Label("Contact Support", systemImage: "envelope")
    }
    .disabled(AppConfig.supportEmail == nil && AppConfig.supportWebURL == nil)
    .accessibilityIdentifier("ContactSupportLink")
    .accessibilityLabel("Contact Support")
  }

  #if DEBUG
    @ViewBuilder
    private var developerToolsSection: some View {
      Section("Developer Tools") {
        Button {
          do {
            let url = try ComplianceLogger.shared.exportComplianceLogs(sinceDays: 90)
            exportedURL = url
            NSWorkspace.shared.activateFileViewerSelecting([url])
            showExportSuccess = true
          } catch {
            exportError = error
            showExportError = true
          }
        } label: {
          Label("Export Compliance Logs", systemImage: "square.and.arrow.up")
        }
        .accessibilityIdentifier("ExportComplianceLogs")
        .accessibilityLabel("Export Compliance Logs (Developer)")
      }
    }
  #endif

  @ViewBuilder
  private var librarySection: some View {
    if !visibleVideoItems.isEmpty {
      Section("Library (\(visibleVideoItems.count) items)") {
        ForEach(visibleVideoItems, id: \.identifier) { item in
          videoItemRow(item)
        }
      }
    }
  }

  @ViewBuilder
  private func videoItemRow(_ item: VideoItem) -> some View {
    HStack {
      Image(systemName: item.isLocal ? "film" : "play.rectangle")
      VStack(alignment: .leading) {
        Text(item.title)
          .font(.headline)
        if let channelID = item.channelID {
          Text("Channel: \(channelID)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .accessibilityIdentifier("VideoItem_\(item.identifier)")
    .contextMenu {
      videoItemContextMenu(item)
    }
  }

  @ViewBuilder
  private func videoItemContextMenu(_ item: VideoItem) -> some View {
    // Hide Channel action (YouTube videos only)
    if !item.isLocal, let channelID = item.channelID {
      Button {
        initiateHideChannel(channelID: channelID, channelName: nil)
      } label: {
        Label("Hide Channel", systemImage: "eye.slash")
      }
      .accessibilityIdentifier("HideChannelAction")
    }

    // Report Content action (YouTube videos only)
    if !item.isLocal, let videoID = item.videoID {
      Button {
        initiateReportContent(videoID: videoID)
      } label: {
        Label("Report Content", systemImage: "exclamationmark.triangle")
      }
      .accessibilityIdentifier("ReportContentAction")
    }
  }

  @ViewBuilder
  private var detailView: some View {
    VStack {
      Image(systemName: "play.rectangle.on.rectangle.fill")
        .font(.system(size: 72))
        .foregroundStyle(.secondary)
      Text("Select an item from the sidebar")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("Full UI coming in Epic F")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }

  // MARK: - Body

  var body: some View {
    mainContent
      .modifier(ContentViewAlerts(
        showImportError: $showImportError,
        importError: importError,
        showHideChannelDialog: $showHideChannelDialog,
        hideChannelReason: $hideChannelReason,
        channelDisplayName: channelDisplayName,
        performHideChannel: performHideChannel,
        resetHideChannelState: resetHideChannelState,
        showHideChannelError: $showHideChannelError,
        hideChannelError: hideChannelError,
        showReportContentDialog: $showReportContentDialog,
        performReportContent: performReportContent,
        clearVideoToReport: { videoToReport = nil },
        showOAuthConsent: $showOAuthConsent,
        showSubscriptionsImport: $showSubscriptionsImport,
        modelContext: modelContext,
        showClearCacheConfirmation: $showClearCacheConfirmation,
        showCacheClearedAlert: $showCacheClearedAlert,
        showExportSuccess: $showExportSuccess,
        showExportError: $showExportError,
        exportError: exportError
      ))
  }

  // MARK: - Main Content

  @ViewBuilder
  private var mainContent: some View {
    NavigationSplitView {
      sidebarList
    } detail: {
      detailView
    }
    .toolbar {
      ToolbarItem(placement: .automatic) {
        SyncStatusIndicatorView()
          .environmentObject(syncViewModel)
      }
    }
  }

  @ViewBuilder
  private var sidebarList: some View {
    List {
      collectionsSection
      youTubeSection
      localFilesSection
      cacheManagementSection
      aboutAndSupportSection
      #if DEBUG
        developerToolsSection
      #endif
      librarySection
    }
    .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    .navigationTitle("MyToob")
  }

  // MARK: - Actions

  private func importLocalFiles() {
    Task {
      isImporting = true
      defer { isImporting = false }

      do {
        let importService = LocalFileImportService(modelContext: modelContext)
        let count = try await importService.importFiles()
        print("Successfully imported \(count) file(s)")
      } catch {
        importError = error
        showImportError = true
        print("Import failed: \(error.localizedDescription)")
      }
    }
  }

  /// Initiate the hide channel flow with confirmation
  private func initiateHideChannel(channelID: String, channelName: String?) {
    channelToHide = (id: channelID, name: channelName)
    hideChannelReason = ""
    showHideChannelDialog = true
  }

  /// Perform the actual channel hide operation
  private func performHideChannel() {
    guard let channel = channelToHide else { return }

    Task {
      do {
        let service = ChannelBlacklistService(modelContext: modelContext)
        try await service.hideChannel(
          channelID: channel.id,
          channelName: channel.name,
          reason: hideChannelReason.isEmpty ? nil : hideChannelReason,
          requiresConfirmation: false
        )
        resetHideChannelState()
      } catch {
        hideChannelError = error
        showHideChannelError = true
      }
    }
  }

  /// Reset hide channel state
  private func resetHideChannelState() {
    channelToHide = nil
    hideChannelReason = ""
  }

  /// Initiate the report content flow with confirmation dialog
  private func initiateReportContent(videoID: String) {
    videoToReport = videoID
    showReportContentDialog = true
  }

  /// Perform the actual report content action after user confirmation
  private func performReportContent() {
    guard let videoID = videoToReport else { return }
    let reportURLString = "https://www.youtube.com/watch?v=\(videoID)&report=1"
    if let url = URL(string: reportURLString) {
      NSWorkspace.shared.open(url)
      ComplianceLogger.shared.logContentReport(videoID: videoID)
    }
    videoToReport = nil
  }
}

// MARK: - ViewModifier for Alerts/Sheets

/// A ViewModifier that encapsulates all alerts and sheets for ContentView
/// This helps break up the complex view body to avoid Swift compiler type-check timeout
private struct ContentViewAlerts: ViewModifier {
  @Binding var showImportError: Bool
  let importError: Error?
  @Binding var showHideChannelDialog: Bool
  @Binding var hideChannelReason: String
  let channelDisplayName: String
  let performHideChannel: () -> Void
  let resetHideChannelState: () -> Void
  @Binding var showHideChannelError: Bool
  let hideChannelError: Error?
  @Binding var showReportContentDialog: Bool
  let performReportContent: () -> Void
  let clearVideoToReport: () -> Void
  @Binding var showOAuthConsent: Bool
  @Binding var showSubscriptionsImport: Bool
  let modelContext: ModelContext
  @Binding var showClearCacheConfirmation: Bool
  @Binding var showCacheClearedAlert: Bool
  @Binding var showExportSuccess: Bool
  @Binding var showExportError: Bool
  let exportError: Error?

  func body(content: Content) -> some View {
    content
      .modifier(ImportErrorAlert(showImportError: $showImportError, importError: importError))
      .modifier(HideChannelAlerts(
        showHideChannelDialog: $showHideChannelDialog,
        hideChannelReason: $hideChannelReason,
        channelDisplayName: channelDisplayName,
        performHideChannel: performHideChannel,
        resetHideChannelState: resetHideChannelState,
        showHideChannelError: $showHideChannelError,
        hideChannelError: hideChannelError
      ))
      .modifier(ReportContentAlert(
        showReportContentDialog: $showReportContentDialog,
        performReportContent: performReportContent,
        clearVideoToReport: clearVideoToReport
      ))
      .sheet(isPresented: $showOAuthConsent) {
        OAuthConsentView()
      }
      .sheet(isPresented: $showSubscriptionsImport) {
        SubscriptionsImportView(modelContext: modelContext)
      }
      .modifier(CacheManagementAlerts(
        showClearCacheConfirmation: $showClearCacheConfirmation,
        showCacheClearedAlert: $showCacheClearedAlert
      ))
      .modifier(ExportAlerts(
        showExportSuccess: $showExportSuccess,
        showExportError: $showExportError,
        exportError: exportError
      ))
  }
}

private struct ImportErrorAlert: ViewModifier {
  @Binding var showImportError: Bool
  let importError: Error?

  func body(content: Content) -> some View {
    content
      .alert("Import Error", isPresented: $showImportError, presenting: importError) { _ in
        Button("OK") {}
      } message: { error in
        Text(error.localizedDescription)
      }
  }
}

private struct HideChannelAlerts: ViewModifier {
  @Binding var showHideChannelDialog: Bool
  @Binding var hideChannelReason: String
  let channelDisplayName: String
  let performHideChannel: () -> Void
  let resetHideChannelState: () -> Void
  @Binding var showHideChannelError: Bool
  let hideChannelError: Error?

  func body(content: Content) -> some View {
    content
      .alert("Hide Channel?", isPresented: $showHideChannelDialog) {
        TextField("Reason (optional)", text: $hideChannelReason)
          .accessibilityIdentifier("HideChannelReasonField")
        Button("Hide", role: .destructive) {
          performHideChannel()
        }
        Button("Cancel", role: .cancel) {
          resetHideChannelState()
        }
      } message: {
        Text("Videos from \(channelDisplayName) will no longer appear in your library.")
      }
      .alert("Error", isPresented: $showHideChannelError, presenting: hideChannelError) { _ in
        Button("OK") {}
      } message: { error in
        Text(error.localizedDescription)
      }
  }
}

private struct ReportContentAlert: ViewModifier {
  @Binding var showReportContentDialog: Bool
  let performReportContent: () -> Void
  let clearVideoToReport: () -> Void

  func body(content: Content) -> some View {
    content
      .alert("Report Content?", isPresented: $showReportContentDialog) {
        Button("Report on YouTube", role: .destructive) {
          performReportContent()
        }
        Button("Cancel", role: .cancel) {
          clearVideoToReport()
        }
      } message: {
        Text("This will open YouTube in your browser where you can report this video for violating community guidelines.")
      }
  }
}

private struct CacheManagementAlerts: ViewModifier {
  @Binding var showClearCacheConfirmation: Bool
  @Binding var showCacheClearedAlert: Bool

  func body(content: Content) -> some View {
    content
      .confirmationDialog("Clear all caches?", isPresented: $showClearCacheConfirmation) {
        Button("Clear Caches", role: .destructive) {
          Task {
            await CacheController.shared.clearAllCachesAsync()
            showCacheClearedAlert = true
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This removes cached metadata and thumbnails. Does not affect your library.")
      }
      .alert("Caches Cleared", isPresented: $showCacheClearedAlert) {
        Button("OK") {}
      } message: {
        Text("Metadata and thumbnail caches have been cleared.")
      }
  }
}

private struct ExportAlerts: ViewModifier {
  @Binding var showExportSuccess: Bool
  @Binding var showExportError: Bool
  let exportError: Error?

  func body(content: Content) -> some View {
    content
      .alert("Export Complete", isPresented: $showExportSuccess) {
        Button("OK") {}
      } message: {
        Text("Compliance logs were exported to a JSON file.")
      }
      .alert("Export Error", isPresented: $showExportError, presenting: exportError) { _ in
        Button("OK") {}
      } message: { error in
        Text(error.localizedDescription)
      }
  }
}

#Preview {
  ContentView()
    .environmentObject(SyncStatusViewModel(settings: SyncSettingsStore.shared))
    .modelContainer(for: [VideoItem.self, ChannelBlacklist.self], inMemory: true)
}
