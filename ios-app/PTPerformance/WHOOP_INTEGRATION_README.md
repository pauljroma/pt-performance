# WHOOP Integration - Build 40 (Optional)

## Overview

The WHOOP integration allows PT Performance to automatically pull recovery and sleep data from WHOOP devices to inform the auto-regulation system. This eliminates manual data entry and provides objective readiness metrics.

## Components

### WHOOPService.swift
Main service class providing:
- OAuth 2.0 authentication flow
- Token refresh logic
- Recovery data fetching (recovery %, HRV, RHR)
- Sleep data fetching (performance %, quality duration, sleep stages)
- Integration with ReadinessService

### Data Models

#### WHOOPRecovery
- `recoveryScore`: 0-100% recovery percentage
- `hrvRmssd`: Heart rate variability in milliseconds
- `restingHeartRate`: Resting heart rate
- `spo2Percentage`: Blood oxygen saturation (optional)
- `skinTempCelsius`: Skin temperature (optional)

#### WHOOPSleep
- `sleepPerformancePercentage`: 0-100% sleep performance
- `qualityDuration`: Total quality sleep time (milliseconds)
- Sleep stages: REM, slow wave, light sleep, awake time

## Setup Instructions

### 1. Register WHOOP App

1. Go to https://developer.whoop.com
2. Create a new application
3. Set redirect URI to: `modus://whoop-callback`
4. Request scopes: `read:recovery`, `read:sleep`, `read:cycles`
5. Copy Client ID and Client Secret

### 2. Configure Credentials

Add WHOOP credentials to Config.swift (already done):

```swift
enum WHOOP {
    static let clientId = "YOUR_WHOOP_CLIENT_ID"
    static let clientSecret = "YOUR_WHOOP_CLIENT_SECRET"
}
```

Or set environment variables:
```bash
export WHOOP_CLIENT_ID="your_client_id"
export WHOOP_CLIENT_SECRET="your_client_secret"
```

### 3. Add URL Scheme to Info.plist

Add custom URL scheme for OAuth callback:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ptperformance</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.ptperformance.whoop</string>
    </dict>
</array>
```

## Usage Examples

### Example 1: OAuth Authentication Flow

```swift
import Foundation

// Initialize WHOOP service
let whoopService = WHOOPService(
    clientId: Config.WHOOP.clientId,
    clientSecret: Config.WHOOP.clientSecret
)

// Step 1: Get authorization URL
guard let authURL = whoopService.getAuthorizationURL() else {
    print("Failed to create auth URL")
    return
}

// Step 2: Open URL in browser (user logs in and authorizes)
UIApplication.shared.open(authURL)

// Step 3: Handle callback in AppDelegate/SceneDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Extract authorization code from URL
    // URL format: modus://whoop-callback?code=AUTH_CODE
    
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
        return false
    }
    
    // Step 4: Exchange code for token
    Task {
        do {
            let token = try await whoopService.exchangeCodeForToken(code: code)
            // Store token securely (Keychain recommended)
            print("Access Token: \(token.accessToken)")
            print("Refresh Token: \(token.refreshToken)")
            print("Expires In: \(token.expiresIn) seconds")
        } catch {
            print("Token exchange failed: \(error)")
        }
    }
    
    return true
}
```

### Example 2: Fetch Recovery and Sleep Data

```swift
// Assume you have stored the access token
let accessToken = "stored_access_token"

Task {
    do {
        // Fetch today's recovery
        let recovery = try await whoopService.fetchTodayRecovery(accessToken: accessToken)
        print("Recovery Score: \(recovery.score.recoveryScore)%")
        print("HRV: \(recovery.score.hrvRmssd) ms")
        print("RHR: \(recovery.score.restingHeartRate) bpm")
        
        // Fetch today's sleep
        let sleep = try await whoopService.fetchTodaySleep(accessToken: accessToken)
        print("Sleep Performance: \(sleep.score.sleepPerformancePercentage)%")
        
        let sleepHours = Double(sleep.score.qualityDuration) / (1000 * 60 * 60)
        print("Quality Sleep: \(sleepHours) hours")
        
    } catch WHOOPError.noDataAvailable {
        print("No WHOOP data available for today")
    } catch WHOOPError.authenticationFailed {
        print("Token expired, need to refresh")
    } catch {
        print("Error: \(error)")
    }
}
```

### Example 3: Token Refresh

```swift
// When access token expires (typically after 3600 seconds)
let refreshToken = "stored_refresh_token"

Task {
    do {
        let newToken = try await whoopService.refreshAccessToken(refreshToken: refreshToken)
        // Update stored tokens
        print("New Access Token: \(newToken.accessToken)")
    } catch {
        print("Refresh failed, user needs to re-authenticate")
    }
}
```

### Example 4: Integration with ReadinessService (Build 39+)

```swift
// Once ReadinessService is implemented in Build 39, you can use:

let whoopService = WHOOPService(
    clientId: Config.WHOOP.clientId,
    clientSecret: Config.WHOOP.clientSecret
)

let readinessService = ReadinessService(supabase: .shared)

Task {
    do {
        // Convert WHOOP data to ReadinessInput
        let readinessInput = try await whoopService.toReadinessInput(
            accessToken: accessToken
        )
        
        // Submit to ReadinessService
        let dailyReadiness = try await readinessService.submitDailyReadiness(
            patientId: patientId,
            input: readinessInput
        )
        
        print("Readiness Band: \(dailyReadiness.readinessBand)")
        print("Readiness Score: \(dailyReadiness.readinessScore ?? 0)/100")
        
    } catch {
        print("Error: \(error)")
    }
}
```

## Data Mapping to Readiness System

### Recovery Score → WHOOP Recovery %
Direct mapping: WHOOP recovery % (0-100) is used as-is in readiness calculation.

- **Green** (85-100%): Full training prescription
- **Yellow** (70-84%): Reduce top set load 5-8%
- **Orange** (50-69%): Skip top set, back-off work only
- **Red** (<50%): Technique + arm care only

### HRV → Baseline Tracking
HRV values are tracked against a 7-day rolling baseline:
- Store `hrvRmssd` value in `daily_readiness.hrv_value`
- Calculate delta from baseline
- Large negative deltas (>10% below baseline) contribute to lower readiness

### Sleep Performance → Sleep Quality (1-5)
WHOOP sleep performance % mapped to 1-5 scale:
- **5 (Excellent)**: 85-100%
- **4 (Good)**: 70-84%
- **3 (Fair)**: 50-69%
- **2 (Poor)**: 30-49%
- **1 (Very Poor)**: 0-29%

### Quality Duration → Sleep Hours
Convert milliseconds to hours for readiness input:
```swift
let sleepHours = Double(sleep.score.qualityDuration) / (1000 * 60 * 60)
```

## Token Storage Best Practices

**DO NOT** store tokens in UserDefaults or plain files. Use Keychain:

```swift
import Security

class WHOOPTokenStorage {
    static func save(accessToken: String, refreshToken: String) {
        // Save to Keychain
        let accessData = accessToken.data(using: .utf8)!
        let refreshData = refreshToken.data(using: .utf8)!
        
        let accessQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "whoop_access_token",
            kSecValueData as String: accessData
        ]
        
        SecItemDelete(accessQuery as CFDictionary)
        SecItemAdd(accessQuery as CFDictionary, nil)
        
        // Repeat for refresh token...
    }
    
    static func load() -> (accessToken: String?, refreshToken: String?) {
        // Load from Keychain
        // Implementation left as exercise
        return (nil, nil)
    }
}
```

## Error Handling

### WHOOPError Cases

1. **noDataAvailable**: User has no recovery/sleep data for today
   - Show prompt: "No WHOOP data available. Sync your device and try again."

2. **authenticationFailed**: Token expired or invalid
   - Attempt token refresh
   - If refresh fails, prompt re-authentication

3. **apiError(String)**: HTTP error or network issue
   - Show error message
   - Fallback to manual readiness input

## Testing Without WHOOP Device

For development/testing without a real WHOOP account:

```swift
// Mock WHOOP data
extension WHOOPService {
    static func mockRecovery() -> WHOOPRecovery {
        WHOOPRecovery(
            cycleId: 12345,
            sleepId: 67890,
            userId: 1,
            createdAt: Date().ISO8601Format(),
            updatedAt: Date().ISO8601Format(),
            scoreState: "SCORED",
            score: WHOOPRecoveryScore(
                recoveryScore: 75,
                restingHeartRate: 55,
                hrvRmssd: 65.0,
                spo2Percentage: 97.5,
                skinTempCelsius: 36.5
            )
        )
    }
    
    static func mockSleep() -> WHOOPSleep {
        // Similar implementation
    }
}
```

## Future Enhancements (Post-Build 40)

1. **Auto-sync**: Background fetch to update readiness daily
2. **Historical trends**: Track recovery/HRV over time
3. **Strain integration**: Use WHOOP strain score for load planning
4. **Notifications**: Alert when recovery drops below threshold
5. **Multi-device support**: Support multiple wearables (Oura, Apple Watch)

## Related Files

- `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/Services/WHOOPService.swift`
- `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/Services/ReadinessService.swift` (Build 39)
- `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/Config.swift`

## References

- WHOOP API Documentation: https://developer.whoop.com/docs/overview
- OAuth 2.0 Flow: https://oauth.net/2/
- Plan File: `/Users/expo/.claude/plans/swirling-dreaming-lecun.md` (Section 4.1)
