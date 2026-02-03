# Modus Color Migration Guide

## New Modus Color Palette

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| Deep Teal | `#0D4F4F` | 13, 79, 79 | Headlines, headers, primary |
| Cyan | `#0891B2` | 8, 145, 178 | CTAs, links, tint color |
| Teal Accent | `#14B8A6` | 20, 184, 166 | Accents, success states |
| Light Teal | `#F0FDFA` | 240, 253, 250 | Backgrounds, cards |

### Gradient
- From: `#0D4F4F` (Deep Teal, bottom-left)
- To: `#14B8A6` (Teal Accent, top-right)

---

## Files Requiring Updates

### 1. Asset Catalog Colors
**File:** `ios-app/PTPerformance/Assets.xcassets/AccentColor.colorset/Contents.json`

**Current:** `systemBlueColor`
**New:** Custom color `#0891B2` (Cyan)

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.031",
          "green": "0.569",
          "blue": "0.698",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

### 2. App Icons
**Location:** `ios-app/PTPerformance/Assets.xcassets/AppIcon.appiconset/`

**Action:** Replace with generated Modus icons from:
`modus_logo_package v1/ios_app_icons/AppIcon.appiconset/`

### 3. Swift Color Usage

| File | Line | Current | New |
|------|------|---------|-----|
| TherapistTabView.swift | 208 | `.blue` | `.accentColor` or Modus cyan |
| TodaySessionView.swift | 466, 519 | `.blue` | `.accentColor` |
| TodaySessionView.swift | 410, 414, 499 | `.green` | Teal Accent `#14B8A6` |

### 4. Recommended: Create Color Extension

**New File:** `ios-app/PTPerformance/Extensions/Color+Modus.swift`

```swift
import SwiftUI

extension Color {
    // Modus Brand Colors
    static let modusDeepTeal = Color(red: 13/255, green: 79/255, blue: 79/255)
    static let modusCyan = Color(red: 8/255, green: 145/255, blue: 178/255)
    static let modusTealAccent = Color(red: 20/255, green: 184/255, blue: 166/255)
    static let modusLightTeal = Color(red: 240/255, green: 253/255, blue: 250/255)

    // Semantic aliases
    static let modusPrimary = modusDeepTeal
    static let modusTint = modusCyan
    static let modusSuccess = modusTealAccent
    static let modusBackground = modusLightTeal

    // Gradient
    static let modusGradient = LinearGradient(
        colors: [modusDeepTeal, modusTealAccent],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
}
```

---

## Migration Steps

### Step 1: Update AccentColor
Replace `systemBlueColor` with Modus Cyan in AccentColor.colorset

### Step 2: Replace App Icons
Copy generated icons from `modus_logo_package v1/ios_app_icons/AppIcon.appiconset/` to `Assets.xcassets/AppIcon.appiconset/`

### Step 3: Add Color Extension
Create `Color+Modus.swift` with brand colors

### Step 4: Update Hardcoded Colors
Replace `.blue` → `.modusCyan` or `.accentColor`
Replace `.green` (success) → `.modusTealAccent`

### Step 5: Update Launch Screen
Add gradient background with Modus mark

### Step 6: Update Info.plist
Change app display name to "Modus"

---

## Color Mapping (Old → New)

| Old Color | New Modus Color | Hex |
|-----------|-----------------|-----|
| `.blue` (links, CTAs) | `.modusCyan` | #0891B2 |
| `.green` (success) | `.modusTealAccent` | #14B8A6 |
| `.primary` (text) | `.modusDeepTeal` | #0D4F4F |
| Background | `.modusLightTeal` | #F0FDFA |

---

## Verification Checklist

- [ ] AccentColor updated to Cyan
- [ ] App icons replaced with Modus icons
- [ ] Color extension added
- [ ] All `.blue` references updated
- [ ] Launch screen updated
- [ ] App name changed to "Modus"
- [ ] Build and test on device
- [ ] Verify dark mode appearance
