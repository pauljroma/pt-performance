# Content Deployment Runbook

**Purpose:** Deploy baseball performance articles to Supabase
**Time:** 2-5 minutes per deployment
**Prerequisites:** `.env` configured with Supabase credentials

---

## Quick Reference

```bash
# Deploy all articles
tools/scripts/deploy.sh content

# Or directly
python3 scripts/content/load_articles.py
```

---

## Complete Workflow

### Step 1: Create or Edit Article

**Location:** `docs/help-articles/baseball/{category}/{NN-slug}.md`

**File naming convention:**
```
{sequence-number}-{url-slug}.md

Examples:
01-pre-pitch-routine.md
02-visualization-techniques.md
24-new-topic.md
```

**Article template:**
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

Context and why this matters for baseball players...

## Main Content

Detailed information with baseball-specific examples...

## Key Research & Evidence

1. Citation 1 (include DOI/link)
2. Citation 2
3. Citation 3

## Practical Application for Baseball

Step-by-step how to apply...

## Common Mistakes to Avoid

1. Mistake 1 and correction
2. Mistake 2 and correction

## When to Seek Professional Help

Red flags and when to consult...

## References

1. Author A et al. (2024). Study Title. Journal Name. DOI: xxx
2. Author B et al. (2025). Study Title. Journal Name. DOI: xxx
3. Author C et al. (2024). Study Title. Journal Name. DOI: xxx
```

---

### Step 2: Validate Article

**Before deploying, validate frontmatter and content:**

```bash
tools/scripts/validate.sh articles
```

**What it checks:**
- ✅ Valid YAML frontmatter
- ✅ Required fields present (id, title, category, difficulty)
- ✅ Minimum 3 references
- ✅ File naming matches convention
- ✅ No duplicate slugs

**Expected output:**
```
✅ Validating articles...
✅ Found 182 articles
✅ All frontmatter valid
✅ All slugs unique
✅ All articles have 3+ references
✅ Validation complete
```

---

### Step 3: Deploy to Supabase

**Deploy via canonical interface:**

```bash
tools/scripts/deploy.sh content
```

**What happens:**
1. Connects to Supabase using `.env` credentials
2. Gets article content type ID
3. Scans `docs/help-articles/baseball/` for `.md` files
4. Parses frontmatter and content
5. Extracts references
6. Inserts/updates content_items table
7. Generates search vectors
8. Updates deployment manifest

**Expected output:**
```
======================================================================
📚 Loading Articles into Flexible Content System
======================================================================

🔗 Supabase: https://rpbxeaxlaoyoqkohytlw.supabase.co
📂 Articles: docs/help-articles/baseball

📝 Getting content type ID for 'article'...
✅ Content type ID: 7c5441ae-c954-47ad-8b87-b48db702a774

📂 Scanning articles...
✅ Found 189 articles

📊 Breakdown:
   arm-care                      :  24 articles
   hitting                       :  10 articles
   injury-prevention             :  10 articles
   mental                        :  23 articles
   mobility                      :  10 articles
   nutrition                     :  10 articles
   recovery                      :  16 articles
   speed                         :  10 articles
   training                      :  66 articles
   warmup                        :  10 articles

🚀 Inserting 5 new articles...
   ✅ Mental Toughness for Baseball Players
   ✅ Concentration Training Techniques
   ✅ Arousal Regulation Strategies
   ✅ Process vs Outcome Goals
   ✅ Imagery Training for Baseball

======================================================================
✅ Inserted: 5
❌ Errors: 0
======================================================================

🎉 Articles are live!
```

---

### Step 4: Verify Deployment

**Check 1: Deployment manifest updated**

```bash
cat deployment_manifest.json | jq '.total_articles'
# Should show new count
```

**Check 2: Search works**

```bash
# Test in Supabase SQL editor or via psql
SELECT * FROM search_content('your new article topic', 'article');
```

**Check 3: Article visible in app (optional)**

Open iOS app → Articles tab → Search for new article

---

## Categories

**Existing categories** (use one of these):

| **Category** | **Description** | **Article Count** |
|--------------|-----------------|-------------------|
| `mental` | Mental performance, visualization, focus | 23 |
| `training` | Periodization, strength, conditioning | 66 |
| `arm-care` | Throwing mechanics, UCL health, recovery | 24 |
| `recovery` | Sleep, cold therapy, rest protocols | 16 |
| `hitting` | Bat speed, launch angle, rotational power | 10 |
| `injury-prevention` | ACL, hamstrings, concussion protocols | 10 |
| `mobility` | Band work, hip/shoulder mobility | 10 |
| `nutrition` | Pre-game meals, hydration, supplements | 10 |
| `speed` | Sprint mechanics, base stealing, agility | 10 |
| `warmup` | Dynamic stretching, activation | 10 |

**To add new category:**
1. Create directory: `mkdir docs/help-articles/baseball/{new-category}`
2. Add articles with `category: "{new-category}"` in frontmatter
3. Deploy (system handles new categories automatically)

---

## Content Standards

### Required Fields

**Frontmatter (YAML):**
- `id` - URL-friendly slug
- `title` - Display title
- `category` - Must match existing category
- `difficulty` - beginner, intermediate, or advanced

**Content sections:**
- Quick Takeaways (3-5 bullets)
- Introduction
- Main content
- References (minimum 3)

### Quality Guidelines

✅ **Evidence-based:**
- Minimum 3 peer-reviewed citations
- Published 2023-2025 (current research)
- From reputable journals (PubMed, sports science)

✅ **Baseball-specific:**
- Every article includes baseball examples
- Applies to pitchers, position players, or both
- Actionable for high school → professional levels

✅ **Accessible:**
- Grade 9-10 reading level
- 500-800 words target
- Clear, concise language
- Active voice

✅ **Structured:**
- Consistent markdown formatting
- Proper heading hierarchy (H2 → H3)
- Bulleted/numbered lists where appropriate

---

## Troubleshooting

### Error: "Content type 'article' not found"

**Problem:** Supabase migration not applied

**Solution:**
```bash
# Check if migration exists
ls ../../supabase/migrations/*flexible_content*

# If not applied
cd ../../supabase
supabase db push

# Then retry deployment
cd ../clients/linear-bootstrap
tools/scripts/deploy.sh content
```

---

### Error: "Duplicate key value violates unique constraint"

**Problem:** Article with same slug already exists

**Solution 1: Update existing article**
- Keep same `id` in frontmatter
- Script will update instead of insert

**Solution 2: Create new article with unique slug**
- Change `id` field to unique value
- Example: `pre-pitch-routine-v2`

---

### Error: "SUPABASE_KEY not found"

**Problem:** `.env` not configured

**Solution:**
```bash
# Copy template
cp .env.template .env

# Edit with your credentials
vim .env

# Add:
SUPABASE_URL=https://{your-project}.supabase.co
SUPABASE_KEY={your-anon-key}
SUPABASE_SERVICE_ROLE_KEY={your-service-role-key}
```

---

### Error: "Invalid frontmatter YAML"

**Problem:** Syntax error in frontmatter

**Solution:**
```bash
# Validate specific file
python3 << 'EOF'
import yaml
with open('docs/help-articles/baseball/mental/24-new.md') as f:
    content = f.read()
    yaml_match = content.split('---')[1]
    yaml.safe_load(yaml_match)
EOF

# Common issues:
# - Unquoted colons in title: "Title: Subtitle" (should be "Title\: Subtitle")
# - Unbalanced quotes
# - Invalid tag array syntax
```

---

### Warning: Article uploads but search doesn't work

**Problem:** Search vectors not updating (rare)

**Solution:**
```sql
-- Manually refresh search vectors (in Supabase SQL editor)
UPDATE content_items
SET search_vector =
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(excerpt, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(array_to_string(tags, ' '), '')), 'C') ||
    setweight(to_tsvector('english', coalesce(content::text, '')), 'D')
WHERE content_type_id IN (SELECT id FROM content_types WHERE type_key = 'article');
```

---

### Articles deployed but not visible in app

**Problem:** iOS app cache or RLS policy

**Solution:**
1. Force quit iOS app
2. Relaunch
3. Pull to refresh on Articles tab

**If still not visible:**
Check RLS policy in Supabase:
```sql
-- Should allow read for all authenticated users
SELECT * FROM content_items WHERE is_published = true LIMIT 5;
```

---

## Advanced Usage

### Deploy Specific Category Only

```python
# Create custom script or modify load_articles.py
# Filter by category in the scanning loop
for category_dir in ARTICLES_DIR.iterdir():
    if category_dir.name != 'mental':  # Only mental category
        continue
    # ... rest of logic
```

### Batch Create from Swarm

**Workflow:**
1. Swarm creates 50 articles → `docs/help-articles/baseball/{categories}/`
2. Validate: `tools/scripts/validate.sh articles`
3. Deploy all at once: `tools/scripts/deploy.sh content`
4. Verify in manifest: `cat deployment_manifest.json`

**Expected time:** ~2 minutes for 50 articles

### Update Existing Articles

**To update content:**
1. Edit markdown file (keep same `id` in frontmatter)
2. Update `last_updated` date
3. Run deployment (script detects duplicate slug and updates)

**What gets updated:**
- content JSONB field (markdown, references)
- metadata JSONB field (last_updated, etc.)
- excerpt
- search_vector (auto-triggered)

**What doesn't change:**
- slug
- created_at timestamp
- content_type_id

---

## Performance

**Deployment speed:**
- 1-10 articles: < 30 seconds
- 50 articles: ~2 minutes
- 189 articles: ~3 minutes

**Bottleneck:** Network latency to Supabase

**Optimization:**
- Deploy only changed articles (not implemented yet)
- Batch inserts (currently one-by-one)
- Use connection pooling

---

## See Also

- [Validation Runbook](validation.md) - Pre-deployment checks
- [Content Upload Runbook](../../.claude/CONTENT_UPLOAD_RUNBOOK.md) - Legacy detailed guide
- [Troubleshooting](troubleshooting.md) - More error solutions
- [Repo Map](../architecture/repo-map.md) - Where content lives

---

## Checklist

**Before deploying:**
- [ ] Article has valid frontmatter
- [ ] Minimum 3 references included
- [ ] Baseball-specific examples present
- [ ] Reading level appropriate (grade 9-10)
- [ ] Ran `tools/scripts/validate.sh articles`
- [ ] `.env` configured with Supabase credentials

**After deploying:**
- [ ] Checked deployment output for errors
- [ ] Verified `deployment_manifest.json` updated
- [ ] Tested search in Supabase SQL editor
- [ ] (Optional) Verified in iOS app

---

**Total time:** 2-5 minutes per deployment cycle
