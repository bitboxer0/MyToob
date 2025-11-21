//
//  QuotaDashboardView.swift
//  MyToob
//
//  Created by Claude Code (BMad Master) on 11/21/25.
//

#if DEBUG
import SwiftUI

/// Dev-only quota monitoring dashboard
///
/// **Features:**
/// - Real-time quota consumption tracking with progress bar
/// - Circuit breaker state indicator
/// - Per-endpoint quota breakdown
/// - Next reset time countdown
/// - Color-coded status (green/orange/red)
///
/// **Usage:**
/// ```swift
/// // Add to dev menu or debug settings
/// QuotaDashboardView()
/// ```
struct QuotaDashboardView: View {
  // MARK: - Properties

  @StateObject private var tracker = QuotaBudgetTracker.shared
  @State private var stats: QuotaBudgetTracker.QuotaStats
  @State private var refreshTimer: Timer?

  // MARK: - Initialization

  init() {
    let initialStats = QuotaBudgetTracker.shared.getQuotaStats()
    _stats = State(initialValue: initialStats)
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Header
      HStack {
        Image(systemName: "chart.bar.fill")
          .font(.title2)
          .foregroundColor(.blue)

        Text("YouTube API Quota Dashboard")
          .font(.title2)
          .fontWeight(.bold)

        Spacer()

        // Circuit breaker indicator
        circuitBreakerBadge
      }

      Divider()

      // Overall quota usage
      quotaUsageSection

      Divider()

      // Per-endpoint breakdown
      endpointBreakdownSection

      Divider()

      // Reset information
      resetInfoSection

      Spacer()

      // Manual controls
      controlsSection
    }
    .padding()
    .frame(minWidth: 500, minHeight: 500)
    .onAppear {
      startAutoRefresh()
    }
    .onDisappear {
      stopAutoRefresh()
    }
  }

  // MARK: - Subviews

  private var circuitBreakerBadge: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(circuitStateColor)
        .frame(width: 12, height: 12)

      Text(tracker.circuitState.description)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(circuitStateColor.opacity(0.1))
    )
  }

  private var quotaUsageSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Total Quota Consumption")
          .font(.headline)

        Spacer()

        Text("\(stats.totalConsumed) / \(stats.dailyLimit) units")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(quotaUsageColor)
      }

      // Progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Background track
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 24)

          // Progress fill
          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                colors: [quotaUsageColor, quotaUsageColor.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: progressWidth(containerWidth: geometry.size.width), height: 24)

          // Percentage label
          HStack {
            Spacer()
            Text(quotaUsagePercentageText)
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.white)
              .padding(.horizontal, 8)
          }
          .frame(width: max(progressWidth(containerWidth: geometry.size.width), 60), height: 24)
        }
      }
      .frame(height: 24)
    }
  }

  private var endpointBreakdownSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Endpoint Breakdown")
        .font(.headline)

      if stats.endpointBreakdown.isEmpty {
        Text("No API requests made yet")
          .font(.body)
          .foregroundColor(.secondary)
          .padding(.vertical, 8)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(Array(stats.endpointBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { endpoint, units in
            HStack {
              Text(endpoint)
                .font(.body)
                .foregroundColor(.primary)

              Spacer()

              Text("\(units) units")
                .font(.body)
                .foregroundColor(.secondary)
                .monospacedDigit()

              // Cost indicator
              if let endpointEnum = QuotaBudgetTracker.Endpoint(rawValue: endpoint) {
                Text("(\(endpointEnum.quotaCost) per call)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
            .padding(.vertical, 4)
          }
        }
      }
    }
  }

  private var resetInfoSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Reset Information")
        .font(.headline)

      HStack {
        Image(systemName: "clock.fill")
          .foregroundColor(.blue)

        Text("Next reset: \(formattedResetTime)")
          .font(.body)

        Spacer()

        Text(timeUntilReset)
          .font(.body)
          .foregroundColor(.secondary)
      }

      Text("Quota resets daily at midnight Pacific Time (PT)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var controlsSection: some View {
    HStack {
      Button(action: manualReset) {
        Label("Reset Quota", systemImage: "arrow.counterclockwise")
      }
      .buttonStyle(.borderedProminent)

      Button(action: refreshStats) {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
      .buttonStyle(.bordered)

      Spacer()

      Text("Auto-refresh: 1s")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  // MARK: - Computed Properties

  private var quotaUsagePercentage: Double {
    guard stats.dailyLimit > 0 else { return 0.0 }
    return Double(stats.totalConsumed) / Double(stats.dailyLimit) * 100.0
  }

  private var quotaUsagePercentageText: String {
    return String(format: "%.1f%%", quotaUsagePercentage)
  }

  private var quotaUsageColor: Color {
    if quotaUsagePercentage >= 90.0 {
      return .red
    } else if quotaUsagePercentage >= 70.0 {
      return .orange
    } else {
      return .green
    }
  }

  private var circuitStateColor: Color {
    switch tracker.circuitState {
    case .closed:
      return .green
    case .halfOpen:
      return .orange
    case .open:
      return .red
    }
  }

  private var formattedResetTime: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: stats.resetTime)
  }

  private var timeUntilReset: String {
    let now = Date()
    let interval = stats.resetTime.timeIntervalSince(now)

    guard interval > 0 else {
      return "Resetting now..."
    }

    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60

    if hours > 0 {
      return "\(hours)h \(minutes)m remaining"
    } else {
      return "\(minutes)m remaining"
    }
  }

  // MARK: - Helper Methods

  private func progressWidth(containerWidth: CGFloat) -> CGFloat {
    return containerWidth * CGFloat(quotaUsagePercentage / 100.0)
  }

  private func refreshStats() {
    stats = QuotaBudgetTracker.shared.getQuotaStats()
  }

  private func manualReset() {
    QuotaBudgetTracker.shared.resetQuota()
    refreshStats()
  }

  private func startAutoRefresh() {
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      refreshStats()
    }
  }

  private func stopAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }
}

// MARK: - Previews

struct QuotaDashboardView_Previews: PreviewProvider {
  static var previews: some View {
    QuotaDashboardView()
      .frame(width: 600, height: 600)
  }
}

#endif
