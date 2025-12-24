# CONTENT UPLOAD RUNBOOK - Adding New Articles

**Purpose:** Step-by-step guide for adding new articles to the flexible content system
**Last Updated:** 2025-12-20
**System:** Flexible Content Management (Supabase + JSONB)

---

## 🚨 HARD RULE: Follow This Checklist

When adding new articles:
- ❌ Do NOT create new schemas or tables
- ❌ Do NOT modify the database structure
- ✅ DO use the existing flexible content system
- ✅ DO follow the article template structure
- ✅ DO use the upload script

---

## Quick Start (5 Minutes)

### Step 1: Create Article Markdown File

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/docs/help-articles/baseball/[category]/
```

Create new file: `NN-article-slug.md`

**Template:**
```markdown
---
id: article-slug
title: "Article Title"
category: "category-name"
subcategory: "optional-subcategory"
tags: ["tag1", "tag2", "tag3"]
author: "PT Performance Medical Team"
reviewed_by: "Sports Medicine Specialist"
last_updated: "2025-12-20"
reading_time: "5 min"
difficulty: "intermediate"
---

# Article Title

## Quick Takeaways
- Key point 1
- Key point 2
- Key point 3

## Introduction

Context and why this matters...

## Main Content

Detailed information with baseball examples...

## Key Research & Evidence

Citations from peer-reviewed sources...

## Practical Application for Baseball

Step-by-step how to apply this...

## Common Mistakes to Avoid

What NOT to do...

## When to Seek Professional Help

Red flags and warnings...

## References

1. Author A et al. (2024). Study Title. Journal Name. DOI: xxx
2. Author B et al. (2025). Study Title. Journal Name. DOI: xxx
3. Author C et al. (2024). Study Title. Journal Name. DOI: xxx
```

### Step 2: Upload to Supabase

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
python3 load_articles.py
```

**That's it!** The article is now live.

---

## Article Structure Requirements

### Frontmatter (YAML)

**Required Fields:**
```yaml
id: article-slug              # URL-friendly identifier (lowercase, hyphens)
title: "Article Title"        # Display title
category: "category-name"     # Must match existing category
difficulty: "intermediate"    # beginner, intermediate, or advanced
```

**Optional Fields:**
```yaml
subcategory: "Subcategory"    # For organization
tags: ["tag1", "tag2"]        # Search tags (array)
author: "Author Name"         # Default: PT Performance Medical Team
reviewed_by: "Reviewer"       # Default: Sports Medicine Specialist
last_updated: "YYYY-MM-DD"    # ISO date
reading_time: "N min"         # Estimated reading time
```

### Content Sections

**Required Sections:**
1. `## Quick Takeaways` - Bullet points (3-5 items)
2. `## Introduction` - Context and relevance
3. `## Main Content` - Core information (section titles can vary)
4. `## References` - Numbered list of citations (minimum 3)

**Optional Sections:**
- `## Key Research & Evidence`
- `## Practical Application`
- `## Common Mistakes to Avoid`
- `## When to Seek Professional Help`

---

## Categories

**Existing Categories** (use one of these):
- `arm-care` - Throwing mechanics, UCL health, weighted balls
- `hitting` - Bat speed, rotational power, launch angle
- `injury-prevention` - ACL, hamstrings, concussion, heat illness
- `mental` - Pre-pitch routines, slump management, visualization
- `mobility` - Resistance bands, hip/shoulder mobility, foam rolling
- `nutrition` - Pre-game fueling, hydration, supplements
- `recovery` - Sleep, cold therapy, compression gear
- `speed` - 60-yard dash, base stealing, plyometrics
- `training` - Off-season, in-season, periodization
- `warmup` - Pre-game routines, dynamic stretching, activation

**To Add New Category:**
Just create a new folder and use that category name in frontmatter. The system handles it automatically.

---

## Quality Standards

### Evidence Requirements

✅ **Minimum 3 peer-reviewed citations** from 2023-2025
✅ **Baseball-specific examples** in every article
✅ **Actionable takeaways** in Quick Takeaways section
✅ **Grade 9-10 reading level** for accessibility

### Citation Format

```markdown
## References

1. Author A, Author B, Author C. (2024). Title of Study. Journal Name, Volume(Issue), Pages. DOI: xxxxx
2. Author D et al. (2025). Title of Study. Journal Name. https://doi.org/xxxxx
```

### Word Count

- **Target:** 500-800 words
- **Minimum:** 400 words
- **Maximum:** 1,200 words (for complex topics)

### Tags

Use **3-6 tags** per article. Examples:
- Position: `pitcher`, `catcher`, `infielder`, `outfielder`
- Training phase: `off-season`, `in-season`, `pre-season`
- Topic: `velocity`, `injury-prevention`, `mechanics`, `nutrition`
- Audience: `youth`, `high-school`, `college`, `professional`

---

## JSONB Structure (How Articles Are Stored)

### content_items Table Structure

```sql
{
  "content_type_id": "uuid-of-article-type",
  "slug": "article-slug",
  "title": "Article Title",
  "category": "category-name",
  "subcategory": "optional",
  "tags": ["tag1", "tag2", "tag3"],
  "difficulty": "intermediate",

  -- JSONB content field (flexible structure)
  "content": {
    "markdown": "full markdown with frontmatter",
    "reading_time": "5",
    "references": [
      {
        "citation": "Full citation text...",
        "order": 1
      }
    ]
  },

  -- JSONB metadata field (adaptive card data)
  "metadata": {
    "author": "PT Performance Medical Team",
    "reviewed_by": "Sports Medicine Specialist",
    "evidence_level": "high",
    "last_reviewed": "2025-12-20"
  },

  "excerpt": "First 150 characters...",
  "estimated_duration_minutes": 5,
  "is_published": true,
  "author": "PT Performance Medical Team",
  "reviewed_by": "Sports Medicine Specialist"
}
```

**Why JSONB?**
- ✅ No schema changes needed to add new fields
- ✅ Flexible metadata for adaptive cards
- ✅ Can store any article-specific data
- ✅ Fast querying with GIN indexes

---

## Adaptive Card Structure

### What Are Adaptive Cards?

Adaptive Cards are platform-agnostic UI templates that render content dynamically based on metadata.

**Example iOS Adaptive Card Template:**

```json
{
  "type": "AdaptiveCard",
  "version": "1.5",
  "body": [
    {
      "type": "Container",
      "items": [
        {
          "type": "TextBlock",
          "text": "${title}",
          "size": "ExtraLarge",
          "weight": "Bolder",
          "wrap": true
        },
        {
          "type": "ColumnSet",
          "columns": [
            {
              "type": "Column",
              "width": "auto",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "${category}",
                  "color": "Accent",
                  "size": "Small"
                }
              ]
            },
            {
              "type": "Column",
              "width": "auto",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "${difficulty}",
                  "size": "Small"
                }
              ]
            },
            {
              "type": "Column",
              "width": "auto",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "${estimated_duration_minutes} min",
                  "size": "Small",
                  "isSubtle": true
                }
              ]
            }
          ]
        },
        {
          "type": "TextBlock",
          "text": "${excerpt}",
          "wrap": true,
          "spacing": "Medium"
        },
        {
          "type": "Container",
          "items": [
            {
              "type": "TextBlock",
              "text": "${content.markdown}",
              "wrap": true
            }
          ]
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.OpenUrl",
      "title": "View References",
      "url": "app://references/${id}"
    },
    {
      "type": "Action.Submit",
      "title": "Mark Helpful",
      "data": {
        "action": "helpful",
        "content_item_id": "${id}"
      }
    }
  ]
}
```

### Variable Binding

Variables from content_items map to adaptive card template:

| Variable | Maps To | Example |
|----------|---------|---------|
| `${title}` | `content_items.title` | "Rotational Power: Building Bat Speed" |
| `${category}` | `content_items.category` | "hitting" |
| `${difficulty}` | `content_items.difficulty` | "intermediate" |
| `${estimated_duration_minutes}` | `content_items.estimated_duration_minutes` | 5 |
| `${excerpt}` | `content_items.excerpt` | "Learn how to..." |
| `${content.markdown}` | `content_items.content['markdown']` | Full markdown |
| `${metadata.author}` | `content_items.metadata['author']` | "PT Performance Medical Team" |
| `${content.references[0].citation}` | First reference | "Smith et al. (2024)..." |

### Adding Custom Metadata for Adaptive Cards

To add custom fields for adaptive card rendering:

**1. Add to markdown frontmatter:**
```yaml
---
custom_field: "custom_value"
badge: "New"
featured: true
---
```

**2. The loader script automatically adds it to metadata:**
```json
{
  "metadata": {
    "author": "...",
    "custom_field": "custom_value",
    "badge": "New",
    "featured": true
  }
}
```

**3. Reference in adaptive card:**
```json
{
  "type": "TextBlock",
  "text": "${metadata.badge}",
  "color": "Attention"
}
```

**No code changes needed!** The JSONB structure is fully flexible.

---

## Upload Script Walkthrough

### load_articles.py

**What it does:**
1. Loads SUPABASE_URL and SUPABASE_KEY from .env
2. Gets the 'article' content_type_id
3. Scans docs/help-articles/baseball/ for .md files
4. Parses YAML frontmatter
5. Extracts references from ## References section
6. Creates excerpt from first 150 characters
7. Builds JSONB content and metadata objects
8. Inserts into content_items table
9. Reports success/failures

**Key Functions:**

```python
def parse_frontmatter(content):
    """Extract YAML frontmatter from markdown"""
    # Matches ---\n...\n--- pattern
    # Returns (frontmatter_dict, markdown_content)

def extract_references(content):
    """Extract numbered references"""
    # Finds ## References section
    # Returns list of {'citation': text, 'order': number}

def create_excerpt(content):
    """Create 150-character excerpt"""
    # Removes markdown formatting
    # Truncates at word boundary

def slugify(text):
    """Convert title to URL-friendly slug"""
    # Lowercase, remove special chars, hyphens
```

### Running the Upload

```bash
# Single article or batch upload
cd /Users/expo/Code/expo/clients/linear-bootstrap
python3 load_articles.py
```

**Output:**
```
📚 Loading Articles into Flexible Content System
🔗 Supabase: https://rpbxeaxlaoyoqkohytlw.supabase.co
📝 Getting content type ID for 'article'...
✅ Content type ID: 7c5441ae-c954-47ad-8b87-b48db702a774
📂 Scanning articles...
✅ Found 5 new articles

📊 Breakdown:
   hitting: 2 articles
   nutrition: 3 articles

🚀 Inserting 5 articles...
   ✅ Exit Velocity Training
   ✅ Barrel Control Drills
   ✅ Pre-Game Meal Timing
   ✅ Protein Intake for Pitchers
   ✅ Hydration for Doubleheaders

✅ Inserted: 5
❌ Errors: 0

🎉 Articles are live!
```

---

## Common Workflows

### Adding a Single Article

```bash
# 1. Create the markdown file
cd docs/help-articles/baseball/hitting/
vim 11-exit-velocity-training.md

# 2. Write the article following template

# 3. Upload
cd /Users/expo/Code/expo/clients/linear-bootstrap
python3 load_articles.py

# Done! Article is live.
```

### Batch Upload (10+ Articles)

**Use swarm agents for parallel creation:**

```yaml
# .swarms/ADD_MORE_ARTICLES.yaml
name: Add More Baseball Articles
agents:
  - id: 1
    name: Advanced Hitting Agent
    category: hitting
    articles:
      - "Exit Velocity Training: Power Development"
      - "Barrel Control: Contact Quality Metrics"
      # ... 8 more
```

```bash
# Launch swarm
/swarm .swarms/ADD_MORE_ARTICLES.yaml

# Wait for completion

# Upload all new articles
python3 load_articles.py
```

### Updating Existing Article

```bash
# 1. Edit the markdown file
vim docs/help-articles/baseball/arm-care/01-j-band-routine.md

# 2. Re-run upload (it will update by slug)
python3 load_articles.py
```

**Note:** The slug must match for updates. If you change the slug, it creates a new article.

---

## Verification

### After Upload, Verify:

```bash
# 1. Check article count
source .env
python3 << 'EOF'
from supabase import create_client
import os
env = dict(line.strip().split('=', 1) for line in open('.env') if '=' in line and not line.startswith('#'))
supabase = create_client(env['SUPABASE_URL'], env['SUPABASE_KEY'])
count = supabase.table('content_items').select('*', count='exact').execute()
print(f"Total articles: {count.count}")
EOF

# 2. Test search
python3 << 'EOF'
from supabase import create_client
import os
env = dict(line.strip().split('=', 1) for line in open('.env') if '=' in line and not line.startswith('#'))
supabase = create_client(env['SUPABASE_URL'], env['SUPABASE_KEY'])
results = supabase.rpc('search_content', {
    'p_query': 'your search term',
    'p_content_type': 'article',
    'p_limit': 5
}).execute()
for r in results.data:
    print(f"- {r['title']} ({r['category']})")
EOF

# 3. Check in Supabase Dashboard
# https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/editor
# Table: content_items
```

---

## Troubleshooting

### "Content type 'article' not found"

**Problem:** Migration wasn't applied or content_types table is empty.

**Solution:**
```bash
# Check if migration was applied
ls supabase/migrations/*.applied | grep flexible_content

# If not applied, apply it:
cd /Users/expo/Code/expo
source clients/linear-bootstrap/.env
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

### "Duplicate key value violates unique constraint"

**Problem:** Article with same slug already exists.

**Solution:**
1. Change the `id` field in frontmatter to a unique slug
2. Or delete the existing article first:
   ```sql
   DELETE FROM content_items WHERE slug = 'duplicate-slug';
   ```

### "No articles found"

**Problem:** Script can't find the markdown files.

**Solution:**
```bash
# Check directory structure
ls docs/help-articles/baseball/*/

# Make sure you're running from correct directory
cd /Users/expo/Code/expo/clients/linear-bootstrap
```

### Articles not searchable

**Problem:** Search vector not updating (rare).

**Solution:** The trigger should auto-update. If not:
```sql
-- Manually refresh search vectors
UPDATE content_items
SET search_vector = setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
                    setweight(to_tsvector('english', coalesce(excerpt, '')), 'B') ||
                    setweight(to_tsvector('english', coalesce(array_to_string(tags, ' '), '')), 'C') ||
                    setweight(to_tsvector('english', coalesce(content::text, '')), 'D')
WHERE content_type_id IN (SELECT id FROM content_types WHERE type_key = 'article');
```

---

## Best Practices

### Content Creation

✅ **DO:**
- Use evidence from peer-reviewed journals (2023-2025)
- Include baseball-specific examples
- Write at grade 9-10 reading level
- Test readability with Hemingway Editor
- Add 3-6 relevant tags
- Keep articles focused (500-800 words)
- Link to related content in your writing

❌ **DON'T:**
- Copy content without citations
- Use outdated research (pre-2023)
- Write in technical jargon
- Exceed 1,200 words (split into multiple articles)
- Use generic examples (apply to baseball specifically)

### File Naming

✅ **Good:**
- `01-j-band-routine.md`
- `05-weighted-ball-programs.md`
- `10-return-to-throwing.md`

❌ **Bad:**
- `article1.md` (not descriptive)
- `J Band Routine.md` (spaces, capitals)
- `01_j_band_routine.md` (underscores)

### Slug Creation

✅ **Good slugs:**
- `j-band-routine`
- `weighted-ball-programs`
- `ucl-injury-prevention`

❌ **Bad slugs:**
- `j_band_routine` (underscores)
- `JBandRoutine` (capitals)
- `j band routine` (spaces)

---

## Future: Adding Other Content Types

### Example: Adding Video Content

```sql
-- 1. Video content type already exists! Just insert video.

INSERT INTO content_items (
  content_type_id,
  slug,
  title,
  category,
  content,
  assets,
  estimated_duration_minutes
) VALUES (
  (SELECT id FROM content_types WHERE type_key = 'video'),
  'proper-j-band-technique',
  'Proper J-Band Technique Demonstration',
  'arm-care',
  '{
    "duration_seconds": 180,
    "transcript": "In this video...",
    "chapters": [
      {"time": 0, "title": "Introduction"},
      {"time": 30, "title": "Setup"},
      {"time": 90, "title": "Execution"}
    ]
  }',
  '{
    "video_url": "https://cdn.example.com/videos/j-band.mp4",
    "thumbnail_url": "https://cdn.example.com/thumbnails/j-band.jpg"
  }',
  3
);
```

**No schema changes needed!** The flexible system handles it.

### Example: Adding Training Programs

```sql
-- 1. Create a program series
INSERT INTO content_series (title, series_type, description, total_duration_minutes)
VALUES (
  'Pitcher Velocity Development - 12 Weeks',
  'program',
  'Comprehensive velocity training program',
  720
);

-- 2. Link content items to the series
UPDATE content_items
SET
  part_of_series = (SELECT id FROM content_series WHERE title LIKE 'Pitcher Velocity%'),
  sequence_number = 1
WHERE slug = 'velocity-week-1-assessment';
```

---

## Summary Checklist

When adding new articles:

- [ ] Create markdown file in `docs/help-articles/baseball/[category]/`
- [ ] Include required frontmatter (id, title, category, difficulty)
- [ ] Add Quick Takeaways section
- [ ] Include 3+ peer-reviewed references (2023-2025)
- [ ] Use baseball-specific examples
- [ ] Keep 500-800 words
- [ ] Run `python3 load_articles.py` from linear-bootstrap directory
- [ ] Verify article appears in search
- [ ] Test in iOS app (if integrated)

---

**Total time per article:** 20-30 minutes (writing) + 1 minute (upload)

**System handles automatically:**
- JSONB structure creation
- Search vector indexing
- Slug generation
- Excerpt creation
- Reference parsing
- Adaptive card metadata

**No code changes ever needed for new articles!**
