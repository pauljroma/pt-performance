# iOS Articles Integration Guide

**Created:** 2025-12-20
**Status:** ✅ Complete - Ready to Build
**Feature:** Browse and search 100 baseball performance articles

---

## 📋 What Was Added

### 1. Models (`Models/ContentItem.swift`)
- `ContentItem` - Full article model with JSONB content
- `ContentSearchResult` - Lightweight search result model
- `UserProgress` - User progress tracking
- `ArticleCategory` - Category enum with icons and colors
- `ContentType` - Content type definitions

### 2. Services (`Services/SupabaseManager.swift`)
- Shared Supabase client instance
- Centralized configuration using existing `Config.swift`

### 3. ViewModels (`ViewModels/ArticlesViewModel.swift`)
- Article browsing and search logic
- Progress tracking
- Bookmark management
- Helpful/rating interactions
- Supabase integration

### 4. Views
**`Views/Articles/ArticleBrowseView.swift`**
- Main article library view
- Search with debounce
- Category filtering
- Difficulty filtering
- Featured articles section
- Category grid for browsing

**`Views/Articles/ArticleDetailView.swift`**
- Full article display
- Markdown rendering (requires MarkdownUI package)
- Progress tracking
- Helpful/Complete buttons
- Bookmark functionality
- Share sheet
- References section

### 5. Tab Bar Integration
**Modified Files:**
- `PatientTabView.swift` - Added "Learn" tab
- `TherapistTabView.swift` - Added "Learn" tab

---

## 📦 Required Dependencies

Add these Swift packages to your Xcode project:

1. **Supabase Swift** (should already be added)
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest

2. **MarkdownUI** (NEW - required for article rendering)
   - URL: `https://github.com/gonzalezreal/swift-markdown-ui`
   - Version: Latest

### How to Add MarkdownUI

1. In Xcode, go to File → Add Package Dependencies
2. Paste URL: `https://github.com/gonzalezreal/swift-markdown-ui`
3. Click "Add Package"
4. Select "MarkdownUI" library

---

## 🔨 Xcode Project Setup

### Step 1: Add Files to Xcode

All files need to be added to the Xcode project:

```
PTPerformance/
├── Models/
│   └── ContentItem.swift (NEW)
├── ViewModels/
│   └── ArticlesViewModel.swift (NEW)
├── Services/
│   └── SupabaseManager.swift (NEW)
├── Views/
│   └── Articles/ (NEW FOLDER)
│       ├── ArticleBrowseView.swift
│       └── ArticleDetailView.swift
├── PatientTabView.swift (MODIFIED)
└── TherapistTabView.swift (MODIFIED)
```

**To Add Files:**
1. Right-click on each folder in Xcode
2. Add Files to "PTPerformance"...
3. Select the new files
4. Ensure "PTPerformance" target is checked

### Step 2: Import MarkdownUI

Add this import to `ArticleDetailView.swift` if not already there:
```swift
import MarkdownUI
```

### Step 3: Build and Run

```bash
# Clean build folder
Product → Clean Build Folder (⇧⌘K)

# Build
Product → Build (⌘B)

# Run
Product → Run (⌘R)
```

---

## 🎨 Features Overview

### Article Browsing
- **Search bar** with real-time results
- **Category grid** for quick browsing
- **Featured articles** section
- **Filters** - Category and Difficulty
- **Sort** - By relevance, views, helpful count

### Article Detail
- **Markdown rendering** with proper formatting
- **Progress tracking** - Started, In Progress, Completed
- **Helpful button** - Mark articles as helpful
- **Bookmark** - Save for later
- **Share** - Share via standard iOS share sheet
- **References** - Expandable reference section
- **View count** - See how popular articles are

### User Progress
- Automatic tracking when opening article
- Progress bar showing completion status
- Complete button to mark as done
- Syncs across devices via Supabase

---

## 🧪 Testing Guide

### Test 1: Browse Articles
1. Launch app
2. Tap "Learn" tab
3. Should see featured articles and category grid
4. Tap a category card
5. Should show articles in that category

### Test 2: Search
1. In "Learn" tab, tap search bar
2. Type "pitching velocity"
3. Should see relevant articles
4. Tap an article
5. Should open detail view

### Test 3: Filters
1. In "Learn" tab, tap filter icon (top right)
2. Select a category (e.g., "Arm Care")
3. Select a difficulty (e.g., "Intermediate")
4. Tap "Done"
5. Should show filtered results

### Test 4: Article Detail
1. Open any article
2. Should see:
   - Title, category, difficulty badge
   - Markdown content with formatting
   - References section at bottom
   - Action buttons (Helpful, Complete)
3. Tap "Mark Helpful"
4. Button should change to "Marked Helpful"
5. Tap "Mark Complete"
6. Progress bar should show 100%

### Test 5: Bookmark
1. In article detail, tap bookmark icon
2. Icon should fill
3. Tap again to unbookmark
4. Icon should unfill

### Test 6: Share
1. In article detail, tap share icon
2. Should show iOS share sheet
3. Can share to Messages, Mail, etc.

---

## 🐛 Common Issues & Fixes

### Issue: "Cannot find 'MarkdownUI' in scope"
**Fix:** Install MarkdownUI package (see Dependencies section above)

### Issue: "Cannot find type 'ContentItem' in scope"
**Fix:** Ensure `ContentItem.swift` is added to Xcode project target

### Issue: "Value of type 'AppState' has no member 'userId'"
**Fix:** `AppState` should already have `userId` (check PTPerformanceApp.swift)

### Issue: Articles not loading
**Fix:**
1. Check Supabase credentials in `Config.swift`
2. Verify migrations were applied (see main deployment guide)
3. Check console for error messages

### Issue: Search returns no results
**Fix:**
1. Verify 100 articles are in database
2. Test search function directly in Supabase SQL Editor:
   ```sql
   SELECT * FROM search_content('arm care', 'article', NULL, NULL, NULL, 10, 0);
   ```

---

## 📱 UI/UX Details

### Colors
- **Categories:** Color-coded by type (blue, orange, red, etc.)
- **Difficulty Badges:**
  - Beginner: Green
  - Intermediate: Orange
  - Advanced: Red
- **Progress Status:**
  - Not Started: Gray
  - In Progress: Blue
  - Completed: Green

### Icons (SF Symbols)
- **Arm Care:** `figure.baseball`
- **Hitting:** `figure.batting`
- **Injury Prevention:** `cross.case.fill`
- **Mental:** `brain.head.profile`
- **Mobility:** `figure.flexibility`
- **Nutrition:** `fork.knife`
- **Recovery:** `bed.double.fill`
- **Speed:** `figure.run`
- **Training:** `dumbbell.fill`
- **Warm-up:** `flame.fill`

### Typography
- **Article Title:** `.title` + `.bold`
- **Section Headers:** `.headline`
- **Body Text:** Rendered via MarkdownUI
- **Meta Info:** `.caption`

---

## 🔗 Integration Points

### Existing App Components Used
- ✅ `AppState` - For user authentication
- ✅ `Config` - For Supabase credentials
- ✅ `SupabaseClient` - Via new `SupabaseManager`
- ✅ Tab bar pattern - Matches existing navigation
- ✅ NavigationStack - Consistent with app structure

### New Dependencies
- ✅ MarkdownUI - For article rendering

---

## 📊 Analytics Integration (Future)

The system tracks:
- Article views (via `content_interactions` table)
- Helpful ratings
- Bookmarks
- Completion status
- Search queries

**To add analytics:**
```swift
// In ArticlesViewModel
func trackView() {
    // Send to analytics service
    AnalyticsService.shared.logEvent("article_viewed", parameters: [
        "article_id": articleId,
        "category": category,
        "search_query": searchQuery
    ])
}
```

---

## 🚀 Launch Checklist

Before releasing to TestFlight:

- [ ] MarkdownUI package installed
- [ ] All new files added to Xcode project
- [ ] Both tab bars show "Learn" tab
- [ ] Search returns results
- [ ] Article detail displays content
- [ ] Progress tracking works
- [ ] Helpful button works
- [ ] Bookmark button works
- [ ] Share sheet works
- [ ] No console errors
- [ ] Tested on both patient and therapist accounts

---

## 📈 Success Metrics

Track these metrics post-launch:

**Week 1:**
- Total article views
- Most popular articles
- Search queries performed
- Helpful ratings given
- Completion rate

**Month 1:**
- Average articles per user
- Most searched terms
- Category popularity
- User retention with articles feature

---

## 🔮 Future Enhancements

Potential improvements:
1. **Offline Reading** - Download articles for offline access
2. **Related Articles** - Show related content at bottom
3. **Video Content** - Support for video articles
4. **Adaptive Cards** - Dynamic UI rendering from metadata
5. **Push Notifications** - "New article in your category"
6. **Personalization** - Recommend based on viewing history
7. **Notes** - Let users add personal notes to articles
8. **Highlights** - Text highlighting and annotations

---

## 📞 Support

**Issues?**
1. Check this guide's troubleshooting section
2. Review console logs for errors
3. Verify database migrations applied
4. Test Supabase connection directly

**Questions about content?**
- See: `CONTENT_UPLOAD_RUNBOOK.md`
- See: `FLEXIBLE_CONTENT_SYSTEM_GUIDE.md`

---

## ✅ Summary

**What you get:**
- 100 evidence-based baseball articles
- Full-text search
- Category browsing
- Progress tracking
- Bookmark system
- Share functionality
- Seamless tab bar integration

**Build time:** ~10 minutes (with MarkdownUI installed)
**User value:** Immediate access to performance education

**🎉 Ready to ship!**
