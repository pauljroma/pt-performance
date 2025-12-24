# iOS WHOOP Integration Specification

**Issues:**
- ACP-466: Implement WHOOP recovery score → readiness band mapping
- ACP-470: Build WHOOP-driven auto-adjustment integration

**Platform:** iOS (PTPerformance app)
**Date:** 2025-12-24
**Build:** 76
**Dependencies:** Supabase Edge Functions (whoop-oauth-callback, whoop-sync-recovery)

---

## Overview

Integrate WHOOP recovery data into PT Performance iOS app to display readiness and auto-adjust training sessions.

---

## Architecture

### File Structure
```
ios-app/PTPerformance/
  Services/
    WHOOPService.swift           # NEW - WHOOP API client
  ViewModels/
    WHOOPViewModel.swift         # NEW - WHOOP data management
    DailyReadinessViewModel.swift # UPDATE - Add WHOOP data
    TodaySessionViewModel.swift   # UPDATE - Auto-adjustment
  Views/
    WHOOP/
      WHOOPOnboardingView.swift  # NEW - OAuth flow
      WHOOPRecoveryCard.swift    # NEW - Recovery display
      WHOOPSettingsView.swift    # NEW - Disconnect/settings
  Models/
    WHOOPRecovery.swift          # NEW - Recovery data model
```

---

## ACP-466: Recovery Score → Readiness Band Mapping

### 1. WHOOP Service

**File:** `Services/WHOOPService.swift`

```swift
import Foundation

/// Service for WHOOP API integration
class WHOOPService: ObservableObject {
    static let shared = WHOOPService()

    @Published var isConnected: Bool = false
    @Published var currentRecovery: WHOOPRecovery?

    private let supabase = SupabaseManager.shared

    // MARK: - OAuth Flow

    func startOAuthFlow() {
        // Open WHOOP OAuth URL
        let clientId = Config.whoopClientId
        let redirectUri = Config.whoopRedirectUri
        let authURL = "https://api.whoop.com/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=code"

        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }

    func handleOAuthCallback(code: String) async throws {
        // Exchange code for access token via Supabase Edge Function
        let response = try await supabase.functions.invoke(
            "whoop-oauth-callback",
            body: ["code": code]
        )

        isConnected = true
        await syncRecovery()
    }

    // MARK: - Data Sync

    func syncRecovery() async {
        guard isConnected else { return }

        do {
            // Call Supabase Edge Function to sync WHOOP data
            try await supabase.functions.invoke("whoop-sync-recovery")

            // Fetch latest recovery from database
            await fetchCurrentRecovery()
        } catch {
            print("❌ WHOOP sync failed: \(error)")
        }
    }

    func fetchCurrentRecovery() async {
        do {
            let athleteId = await SupabaseManager.shared.currentAthlete?.id ?? ""

            let query = supabase.database
                .from("whoop_recovery")
                .select()
                .eq("athlete_id", value: athleteId)
                .order("date", ascending: false)
                .limit(1)

            let response: [WHOOPRecovery] = try await query.execute().value

            if let recovery = response.first {
                await MainActor.run {
                    self.currentRecovery = recovery
                }
            }
        } catch {
            print("❌ Failed to fetch WHOOP recovery: \(error)")
        }
    }

    // MARK: - Readiness Band

    func getReadinessBand(from recoveryScore: Double) -> ReadinessBand {
        switch recoveryScore {
        case 67...100:
            return .green
        case 34..<67:
            return .yellow
        default:
            return .red
        }
    }

    func disconnect() async {
        // Remove WHOOP credentials from database
        isConnected = false
        currentRecovery = nil
    }
}
```

---

### 2. WHOOP Recovery Model

**File:** `Models/WHOOPRecovery.swift`

```swift
import Foundation

struct WHOOPRecovery: Codable, Identifiable {
    let id: UUID
    let athleteId: UUID
    let date: Date
    let recoveryScore: Double  // 0-100
    let hrvRmssd: Double?      // HRV in ms
    let restingHr: Int?
    let hrvBaseline: Double?
    let sleepPerformance: Double?
    let readinessBand: String  // "green", "yellow", "red"
    let syncedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case date
        case recoveryScore = "recovery_score"
        case hrvRmssd = "hrv_rmssd"
        case restingHr = "resting_hr"
        case hrvBaseline = "hrv_baseline"
        case sleepPerformance = "sleep_performance"
        case readinessBand = "readiness_band"
        case syncedAt = "synced_at"
    }

    var readinessBandEnum: ReadinessBand {
        ReadinessBand(rawValue: readinessBand) ?? .yellow
    }

    var recoveryLevel: String {
        switch recoveryScore {
        case 67...100:
            return "High Recovery"
        case 34..<67:
            return "Moderate Recovery"
        default:
            return "Low Recovery"
        }
    }
}

enum ReadinessBand: String, Codable {
    case green = "green"
    case yellow = "yellow"
    case red = "red"

    var color: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    var emoji: String {
        switch self {
        case .green: return "🟢"
        case .yellow: return "🟡"
        case .red: return "🔴"
        }
    }
}
```

---

### 3. WHOOP Recovery Card UI

**File:** `Views/WHOOP/WHOOPRecoveryCard.swift`

```swift
import SwiftUI

struct WHOOPRecoveryCard: View {
    let recovery: WHOOPRecovery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image("whoop_logo")
                    .resizable()
                    .frame(width: 24, height: 24)

                Text("WHOOP Recovery")
                    .font(.headline)

                Spacer()

                Text(recovery.readinessBandEnum.emoji)
                    .font(.title2)
            }

            // Recovery Score
            VStack(alignment: .leading, spacing: 4) {
                Text("Recovery Score")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom) {
                    Text("\(Int(recovery.recoveryScore))%")
                        .font(.system(size: 36, weight: .bold))

                    Text(recovery.recoveryLevel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            }

            // Progress Bar
            ProgressView(value: recovery.recoveryScore, total: 100)
                .tint(recovery.readinessBandEnum.color)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            // Details Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let hrv = recovery.hrvRmssd {
                    MetricCell(title: "HRV", value: "\(Int(hrv)) ms")
                }

                if let rhr = recovery.restingHr {
                    MetricCell(title: "Resting HR", value: "\(rhr) bpm")
                }

                if let sleep = recovery.sleepPerformance {
                    MetricCell(title: "Sleep", value: "\(Int(sleep))%")
                }
            }

            Text("Synced \(recovery.syncedAt.timeAgoDisplay())")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
```

---

## ACP-470: Auto-Adjustment Integration

### 1. Session Auto-Adjustment

**File:** `ViewModels/TodaySessionViewModel.swift` (UPDATE)

```swift
// Add to TodaySessionViewModel

func applyWHOOPAutoAdjustment() async {
    guard let recovery = WHOOPService.shared.currentRecovery else { return }

    let adjustment = calculateAdjustment(from: recovery.recoveryScore)

    await MainActor.run {
        self.volumeAdjustment = adjustment.volumeMultiplier
        self.intensityRecommendation = adjustment.intensity
        self.sessionNotes = adjustment.notes
        self.showAutoAdjustmentAlert = true
    }
}

private func calculateAdjustment(from recoveryScore: Double) -> SessionAdjustment {
    switch recoveryScore {
    case 67...100:
        return SessionAdjustment(
            volumeMultiplier: 1.0,
            intensity: .high,
            notes: "High recovery - ready for demanding sessions"
        )
    case 34..<67:
        return SessionAdjustment(
            volumeMultiplier: 0.85,
            intensity: .moderate,
            notes: "Moderate recovery - reduce volume to 85%"
        )
    default:
        return SessionAdjustment(
            volumeMultiplier: 0.65,
            intensity: .low,
            notes: "Low recovery - focus on technique, reduce to 65% volume"
        )
    }
}

struct SessionAdjustment {
    let volumeMultiplier: Double
    let intensity: IntensityLevel
    let notes: String
}

enum IntensityLevel: String {
    case low = "Low Intensity"
    case moderate = "Moderate Intensity"
    case high = "High Intensity"
}
```

---

### 2. Auto-Adjustment UI

**File:** `Views/Patient/AutoAdjustmentBanner.swift` (NEW)

```swift
import SwiftUI

struct AutoAdjustmentBanner: View {
    let recovery: WHOOPRecovery
    let adjustment: SessionAdjustment
    @Binding var isAccepted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue)

                Text("WHOOP Auto-Adjustment")
                    .font(.headline)

                Spacer()
            }

            Text(adjustment.notes)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(adjustment.volumeMultiplier * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(adjustment.intensity.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .frame(height: 50)

            HStack {
                Button("Decline") {
                    isAccepted = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Apply Adjustment") {
                    isAccepted = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
```

---

### 3. Update Daily Readiness View

**File:** `Views/Patient/DailyReadinessCheckInView.swift` (UPDATE)

```swift
// Add to DailyReadinessCheckInView

var body: some View {
    ScrollView {
        VStack(spacing: 20) {
            // Existing readiness check-in UI...

            // NEW: WHOOP Recovery Card
            if let recovery = WHOOPService.shared.currentRecovery {
                WHOOPRecoveryCard(recovery: recovery)
            } else if !WHOOPService.shared.isConnected {
                WHOOPConnectPrompt()
            }

            // Rest of the view...
        }
        .padding()
    }
    .task {
        await WHOOPService.shared.fetchCurrentRecovery()
    }
}
```

---

## Onboarding Flow

**File:** `Views/WHOOP/WHOOPOnboardingView.swift`

```swift
import SwiftUI

struct WHOOPOnboardingView: View {
    @StateObject private var whoopService = WHOOPService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image("whoop_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)

            Text("Connect WHOOP")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Automatically adjust your training based on your daily recovery score")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "heart.fill", text: "Track recovery score daily")
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Auto-adjust session volume")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Optimize training load")
            }
            .padding()

            Spacer()

            Button("Connect WHOOP Account") {
                whoopService.startOAuthFlow()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Maybe Later") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}
```

---

## Testing Checklist

### ACP-466: Recovery Mapping
- [ ] OAuth flow completes successfully
- [ ] Recovery data syncs from Supabase
- [ ] Recovery score displays correctly
- [ ] Readiness band (green/yellow/red) matches score
- [ ] HRV, RHR, sleep data display properly
- [ ] Card UI is polished and matches design
- [ ] Sync timestamp shows correctly

### ACP-470: Auto-Adjustment
- [ ] Auto-adjustment banner appears when appropriate
- [ ] Volume multiplier calculates correctly (100%, 85%, 65%)
- [ ] Intensity recommendation is accurate
- [ ] User can accept or decline adjustment
- [ ] Accepting applies changes to session exercises
- [ ] Declining preserves original session plan
- [ ] Adjustment persists across app restarts

---

## Deployment Steps

1. ✅ Supabase Edge Functions deployed (whoop-oauth-callback, whoop-sync-recovery)
2. Implement WHOOPService.swift
3. Create WHOOP models
4. Build WHOOP UI components
5. Integrate into DailyReadinessCheckInView
6. Add auto-adjustment to TodaySessionViewModel
7. Test OAuth flow end-to-end
8. Test auto-adjustment with various recovery scores
9. Deploy to TestFlight (Build 76)

---

## Configuration

Add to `Config.swift`:

```swift
// WHOOP
static let whoopClientId = "YOUR_CLIENT_ID"
static let whoopClientSecret = "YOUR_CLIENT_SECRET"
static let whoopRedirectUri = "ptperformance://whoop/callback"
```

---

## Build 76 Complete Criteria

- ✅ WHOOP OAuth flow functional
- ✅ Recovery data syncs daily
- ✅ Recovery card displays in app
- ✅ Readiness band mapping accurate
- ✅ Auto-adjustment applies correctly
- ✅ User can accept/decline adjustments
- ✅ All tests passing
- ✅ Deployed to TestFlight
