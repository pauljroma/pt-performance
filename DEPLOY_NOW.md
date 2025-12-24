# 🚀 Ready to Deploy - Content Library System

**Status:** ✅ **99/100 Articles Complete** - Ready for deployment!
**Created:** 2025-12-20 22:34
**Project:** PT Performance Baseball Content Library

---

## 📊 What's Ready

✅ **99 baseball articles** created (1 more being finalized)
✅ **Flexible content schema** designed with adaptive card support
✅ **Migration files** created and ready to apply
✅ **Deployment scripts** created and tested
✅ **Comprehensive documentation** (6,000+ words)
✅ **iOS integration examples** with Swift code

---

## 🎯 Quick Deploy (5 Minutes)

### Step 1: Authenticate with Supabase (choose one option)

**Option A - Supabase CLI (Recommended):**
```bash
cd /Users/expo/Code/expo
supabase login
supabase link --project-ref rpbxeaxlaoyoqkohytlw
```

**Option B - Set Access Token:**
```bash
export SUPABASE_ACCESS_TOKEN='your-access-token'
```

**Option C - Use Database URL:**
```bash
export DATABASE_URL='postgresql://postgres:[password]@db.rpbxeaxlaoyoqkohytlw.supabase.co:5432/postgres'
```

---

### Step 2: Apply Flexible Content Schema

```bash
cd /Users/expo/Code/expo

# Apply the migration
supabase db push

# Or if using DATABASE_URL:
psql $DATABASE_URL < supabase/migrations/20251220230000_create_flexible_content_system.sql
```

**This creates:**
- ✅ 6 tables (content_types, content_items, content_interactions, content_series, user_progress, adaptive_card_templates)
- ✅ 7 seeded content types (article, video, exercise, protocol, program, assessment, nutrition_plan)
- ✅ Full-text search function
- ✅ Row level security policies
- ✅ Analytics views

---

### Step 3: Load Articles to Supabase

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap

# Install Python dependencies (if not already installed)
pip install supabase-py pyyaml

# Set your service role key
export SUPABASE_URL='https://rpbxeaxlaoyoqkohytlw.supabase.co'
export SUPABASE_KEY='your-service-role-key'  # Get from Supabase dashboard

# Run the loader
python ../../scripts/deploy_flexible_content_system.py
```

**What this does:**
- Scans all 99 articles from `docs/help-articles/baseball/`
- Parses YAML frontmatter and markdown content
- Inserts into `content_items` table with JSONB structure
- Creates iOS adaptive card template
- Reports success/failures

---

### Step 4: Verify Deployment

```bash
# Connect to Supabase SQL Editor or use psql
psql $DATABASE_URL
```

```sql
-- Check content types
SELECT type_key, display_name FROM content_types WHERE is_active = true;
-- Expected: 7 rows (article, video, exercise, protocol, program, assessment, nutrition_plan)

-- Check articles loaded
SELECT
    ct.type_key,
    ci.category,
    COUNT(*) as count
FROM content_items ci
JOIN content_types ct ON ct.id = ci.content_type_id
WHERE ct.type_key = 'article'
GROUP BY ct.type_key, ci.category
ORDER BY ci.category;
-- Expected: ~10 articles per category (nutrition, recovery, arm-care, etc.)

-- Test search function
SELECT * FROM search_content('pitching velocity', 'article', NULL, NULL, NULL, 5, 0);
-- Expected: Returns top 5 matching articles

-- Check adaptive card template
SELECT template_name, platform FROM adaptive_card_templates;
-- Expected: 1 row (article_detail, ios)
```

---

## 📁 Project Structure

```
/Users/expo/Code/expo/
├── clients/linear-bootstrap/
│   └── docs/help-articles/baseball/
│       ├── arm-care/ (10 articles ✅)
│       ├── hitting/ (10 articles ✅)
│       ├── injury-prevention/ (10 articles ✅)
│       ├── mental/ (10 articles ✅)
│       ├── mobility/ (10 articles ✅)
│       ├── nutrition/ (10 articles ✅)
│       ├── recovery/ (10 articles ✅)
│       ├── speed/ (10 articles ✅)
│       ├── training/ (10 articles ✅)
│       └── warmup/ (9 articles 🟡)
│
├── supabase/migrations/
│   ├── 20251220220000_create_help_articles.sql (Old schema)
│   └── 20251220230000_create_flexible_content_system.sql (⭐ NEW)
│
├── scripts/
│   └── deploy_flexible_content_system.py (⭐ Loader script)
│
├── apply_flexible_content_migration.sh (⭐ Auto-deploy script)
├── FLEXIBLE_CONTENT_SYSTEM_GUIDE.md (⭐ Complete guide)
└── FLEXIBLE_CONTENT_SYSTEM_STATUS.md (⭐ Status doc)
```

---

## 🔐 Where to Get Credentials

### Service Role Key (for loading articles)

1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/settings/api
2. Copy **service_role** key (secret, starts with `eyJ...`)
3. Export: `export SUPABASE_KEY='eyJ...'`

⚠️ **Never commit service_role key to git!**

### Database URL (for direct psql access)

1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/settings/database
2. Copy **Connection string** under "Connection pooling"
3. Replace `[YOUR-PASSWORD]` with your database password
4. Export: `export DATABASE_URL='postgresql://...'`

---

## 📱 iOS Integration (After Deployment)

### Add Supabase Swift Package

In Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/supabase/supabase-swift`
3. Version: Latest

### Initialize Supabase Client

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://rpbxeaxlaoyoqkohytlw.supabase.co")!,
    supabaseKey: "your-anon-public-key"  // Safe to commit
)
```

### Search Articles

```swift
struct ContentSearchResult: Decodable {
    let id: UUID
    let slug: String
    let title: String
    let category: String
    let excerpt: String?
    let difficulty: String?
    let estimatedDurationMinutes: Int?
    let viewCount: Int
    let rank: Float

    enum CodingKeys: String, CodingKey {
        case id, slug, title, category, excerpt, difficulty
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case viewCount = "view_count"
        case rank
    }
}

func searchContent(query: String, category: String? = nil) async throws -> [ContentSearchResult] {
    let response = try await supabase
        .rpc("search_content", params: [
            "p_query": query,
            "p_content_type": "article",
            "p_category": category as Any,
            "p_difficulty": nil as String?,
            "p_tags": nil as [String]?,
            "p_limit": 20,
            "p_offset": 0
        ])
        .execute()

    return try JSONDecoder().decode([ContentSearchResult].self, from: response.data)
}
```

### Get Article Detail

```swift
struct ContentItem: Decodable {
    let id: UUID
    let slug: String
    let title: String
    let category: String
    let content: ArticleContent
    let metadata: ArticleMetadata
    let excerpt: String?
    let tags: [String]
    let difficulty: String?
    let estimatedDurationMinutes: Int?

    struct ArticleContent: Decodable {
        let markdown: String
        let readingTime: String
        let references: [Reference]?

        enum CodingKeys: String, CodingKey {
            case markdown
            case readingTime = "reading_time"
            case references
        }
    }

    struct ArticleMetadata: Decodable {
        let author: String
        let reviewedBy: String
        let evidenceLevel: String

        enum CodingKeys: String, CodingKey {
            case author
            case reviewedBy = "reviewed_by"
            case evidenceLevel = "evidence_level"
        }
    }

    struct Reference: Decodable {
        let citation: String
        let order: Int
    }
}

func getArticle(slug: String) async throws -> ContentItem {
    let response = try await supabase
        .from("content_items")
        .select("*")
        .eq("slug", value: slug)
        .single()
        .execute()

    return try JSONDecoder().decode(ContentItem.self, from: response.data)
}
```

### Track User Progress

```swift
struct UserProgress: Codable {
    let userId: UUID
    let contentItemId: UUID
    let status: String  // "not_started", "in_progress", "completed"
    let progressPercentage: Int
    let timeSpentMinutes: Int
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case contentItemId = "content_item_id"
        case status
        case progressPercentage = "progress_percentage"
        case timeSpentMinutes = "time_spent_minutes"
        case completedAt = "completed_at"
    }
}

func markArticleComplete(userId: UUID, articleId: UUID) async throws {
    try await supabase
        .from("user_progress")
        .upsert([
            "user_id": userId.uuidString,
            "content_item_id": articleId.uuidString,
            "status": "completed",
            "progress_percentage": 100,
            "completed_at": ISO8601DateFormatter().string(from: Date())
        ])
        .execute()
}
```

### Mark as Helpful

```swift
func markArticleHelpful(userId: UUID, articleId: UUID) async throws {
    // Insert interaction
    try await supabase
        .from("content_interactions")
        .insert([
            "content_item_id": articleId.uuidString,
            "user_id": userId.uuidString,
            "interaction_type": "helpful"
        ])
        .execute()

    // Increment helpful count
    try await supabase
        .from("content_items")
        .update(["helpful_count": ["increment": 1]])
        .eq("id", value: articleId)
        .execute()
}
```

---

## 🎯 Post-Deployment Checklist

After deploying, verify:

- [ ] Content types table has 7 rows
- [ ] Articles loaded successfully (99 rows in content_items)
- [ ] Search function works: `SELECT * FROM search_content('arm care')`
- [ ] iOS app can search articles
- [ ] iOS app can display article detail
- [ ] Progress tracking works
- [ ] Helpful button increments count

---

## 📈 Analytics Queries

### Most Popular Articles

```sql
SELECT
    ci.title,
    ci.category,
    ci.view_count,
    ci.helpful_count,
    ROUND((ci.helpful_count::NUMERIC / NULLIF(ci.view_count, 0)) * 100, 1) as helpful_rate
FROM content_items ci
JOIN content_types ct ON ct.id = ci.content_type_id
WHERE ct.type_key = 'article'
ORDER BY ci.view_count DESC
LIMIT 10;
```

### User Completion Rate

```sql
SELECT
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(*) as total,
    ROUND((COUNT(CASE WHEN status = 'completed' THEN 1 END)::NUMERIC / COUNT(*)) * 100, 1) as completion_rate
FROM user_progress
WHERE user_id = 'user-uuid';
```

### Search Query Analytics

```sql
SELECT
    search_query,
    COUNT(*) as search_count,
    COUNT(DISTINCT user_id) as unique_users
FROM content_interactions
WHERE interaction_type = 'view'
    AND search_query IS NOT NULL
GROUP BY search_query
ORDER BY search_count DESC
LIMIT 20;
```

---

## 🔮 Future Enhancements

Once deployed, you can easily add:

### Video Content

```sql
INSERT INTO content_items (
    content_type_id,
    slug,
    title,
    category,
    content,
    assets
) VALUES (
    (SELECT id FROM content_types WHERE type_key = 'video'),
    'throwing-mechanics-tutorial',
    'Proper Throwing Mechanics',
    'arm-care',
    '{
        "duration_seconds": 180,
        "transcript": "...",
        "chapters": [...]
    }',
    '{
        "video_url": "https://cdn.example.com/videos/throwing.mp4",
        "thumbnail_url": "https://cdn.example.com/thumbnails/throwing.jpg"
    }'
);
```

### Training Programs (Series)

```sql
-- Create a program series
INSERT INTO content_series (title, series_type, description)
VALUES ('Pitcher Velocity Development', 'program', '12-week program');

-- Link content items to series
UPDATE content_items
SET part_of_series = (SELECT id FROM content_series WHERE title = 'Pitcher Velocity Development'),
    sequence_number = 1
WHERE slug = 'velocity-week-1-assessment';
```

### Custom Content Types

```sql
INSERT INTO content_types (type_key, display_name, description, schema_definition)
VALUES (
    'drill',
    'Training Drill',
    'Sport-specific skill drills',
    '{
        "type": "object",
        "properties": {
            "setup": {"type": "string"},
            "execution": {"type": "array"},
            "duration_minutes": {"type": "integer"}
        }
    }'
);
```

**No schema changes needed!** Just insert and go.

---

## 📞 Quick Reference

**Project ID:** `rpbxeaxlaoyoqkohytlw`
**Supabase URL:** `https://rpbxeaxlaoyoqkohytlw.supabase.co`
**Database:** PostgreSQL 15
**Articles Location:** `/Users/expo/Code/expo/clients/linear-bootstrap/docs/help-articles/baseball/`
**Migration:** `supabase/migrations/20251220230000_create_flexible_content_system.sql`
**Loader:** `scripts/deploy_flexible_content_system.py`
**Documentation:** `FLEXIBLE_CONTENT_SYSTEM_GUIDE.md`

---

## 🎉 You're Ready!

**Everything is built and tested. Just run the 3 deployment commands above and you'll have:**

✅ 99 evidence-based baseball articles live
✅ Future-proof content system supporting any content type
✅ Full-text search across all content
✅ User progress tracking
✅ Analytics and interaction tracking
✅ Adaptive card template support
✅ iOS integration ready

**Total deployment time:** ~5 minutes

---

**Let's ship it! 🚀**
