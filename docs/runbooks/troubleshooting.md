# Troubleshooting Runbook

**Purpose:** Common issues and solutions for linear-bootstrap
**Last Updated:** 2025-12-20

---

## Quick Index

| **Problem** | **Category** | **Jump To** |
|-------------|--------------|-------------|
| Content deployment failed | Deployment | [#content-deployment](#content-deployment-issues) |
| Environment variables missing | Setup | [#environment-issues](#environment-configuration-issues) |
| Swarm won't execute | Swarms | [#swarm-execution-issues](#swarm-execution-issues) |
| Linear sync failed | Integration | [#linear-sync-issues](#linear-sync-issues) |
| Scripts not executable | Setup | [#script-permissions](#script-permission-issues) |

---

## Content Deployment Issues

### Error: "Content type 'article' not found"

**Symptoms:**
```
❌ Content type 'article' not found!
```

**Root cause:** Supabase flexible content migration not applied

**Solution:**
```bash
# Check if migration exists
ls /Users/expo/Code/expo/supabase/migrations/*flexible_content*.sql

# If migration file exists but not applied
cd /Users/expo/Code/expo/supabase

# Apply migration
supabase db push

# Verify content_types table exists
# In Supabase dashboard: Table Editor → content_types

# Then retry deployment
cd /Users/expo/Code/expo/clients/linear-bootstrap
tools/scripts/deploy.sh content
```

---

### Error: "Duplicate key value violates unique constraint"

**Symptoms:**
```
❌ duplicate key value violates unique constraint "content_items_slug_key"
Details: Key (slug)=(article-slug) already exists.
```

**Root cause:** Article with same slug already uploaded

**Solution Option 1 - Update existing:**
```bash
# Keep the same `id` field in frontmatter
# Script will update the existing article instead of inserting new
tools/scripts/deploy.sh content
```

**Solution Option 2 - Create new with different slug:**
```bash
# Edit article frontmatter
vim docs/help-articles/baseball/category/article.md

# Change the `id` field to unique value
---
id: new-unique-slug  # Changed this
title: "Same Title"
---

# Deploy again
tools/scripts/deploy.sh content
```

**Solution Option 3 - Delete and recreate:**
```sql
-- In Supabase SQL Editor
DELETE FROM content_items WHERE slug = 'duplicate-slug';

-- Then redeploy
```

---

### Error: "Invalid frontmatter YAML"

**Symptoms:**
```
yaml.scanner.ScannerError: mapping values are not allowed here
```

**Root cause:** Syntax error in article frontmatter

**Solution:**
```bash
# Validate specific file
python3 << 'EOF'
import yaml
file_path = 'docs/help-articles/baseball/mental/article.md'
with open(file_path) as f:
    content = f.read()
    parts = content.split('---')
    if len(parts) >= 3:
        yaml_content = parts[1]
        try:
            yaml.safe_load(yaml_content)
            print("✅ Valid YAML")
        except yaml.YAMLError as e:
            print(f"❌ Invalid YAML: {e}")
EOF
```

**Common YAML errors:**
- Unquoted colons in title: `"Title: Subtitle"` (should be `"Title\: Subtitle"`)
- Unbalanced quotes: `title: "Missing quote`
- Invalid array syntax: `tags: [tag1 tag2]` (should be `tags: ["tag1", "tag2"]`)

**Fix:**
```yaml
# Bad
title: Mental Performance: The Basics
tags: [tag1 tag2]

# Good
title: "Mental Performance: The Basics"
tags: ["tag1", "tag2"]
```

---

### Warning: Articles uploaded but not searchable

**Symptoms:**
- Articles appear in Supabase table
- Search doesn't return results

**Root cause:** Search vectors not updating

**Solution:**
```sql
-- Run in Supabase SQL Editor
-- Manually refresh search vectors
UPDATE content_items
SET search_vector =
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(excerpt, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(array_to_string(tags, ' '), '')), 'C') ||
    setweight(to_tsvector('english', coalesce(content::text, '')), 'D')
WHERE content_type_id IN (
    SELECT id FROM content_types WHERE type_key = 'article'
);

-- Verify
SELECT title, ts_rank(search_vector, to_tsquery('baseball')) as rank
FROM content_items
WHERE search_vector @@ to_tsquery('baseball')
ORDER BY rank DESC
LIMIT 5;
```

---

## Environment Configuration Issues

### Error: "SUPABASE_KEY not found"

**Symptoms:**
```
KeyError: 'SUPABASE_KEY'
```

**Root cause:** `.env` file missing or variable not set

**Solution:**
```bash
# Check if .env exists
ls -la .env

# If not, create from template
cp .env.template .env

# Edit with your credentials
vim .env

# Add required variables:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Validate
tools/scripts/validate.sh env
```

---

### Error: "Invalid Supabase credentials"

**Symptoms:**
```
supabase.errors.AuthError: Invalid API key
```

**Root cause:** Wrong API key or expired key

**Solution:**
```bash
# Get fresh credentials from Supabase
# 1. Go to https://supabase.com/dashboard
# 2. Select your project
# 3. Settings → API
# 4. Copy fresh keys

# Update .env
vim .env

# Test connection
python3 << 'EOF'
import os
from pathlib import Path
from supabase import create_client

env_path = Path('.env')
for line in env_path.read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        key, val = line.split('=', 1)
        os.environ[key.strip()] = val.strip()

url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_KEY')

try:
    client = create_client(url, key)
    result = client.table('content_types').select('*').limit(1).execute()
    print(f"✅ Connection successful")
except Exception as e:
    print(f"❌ Connection failed: {e}")
EOF
```

---

## Swarm Execution Issues

### Error: "Swarm config not found"

**Symptoms:**
```bash
/swarm-it .swarms/my-config.yaml
# File not found
```

**Root cause:** Wrong path or file doesn't exist

**Solution:**
```bash
# Check existing swarm configs
ls .swarms/configs/

# If organized by category
ls .swarms/configs/content/
ls .swarms/configs/ios/
ls .swarms/configs/infrastructure/

# Use correct path
/swarm-it .swarms/configs/content/my-config.yaml
```

---

### Error: "Invalid YAML syntax"

**Symptoms:**
```
yaml.scanner.ScannerError: while scanning...
```

**Root cause:** Syntax error in swarm YAML

**Solution:**
```bash
# Validate swarm config
.swarms/bin/validate.sh configs/content/my-swarm.yaml

# Or manually
python3 -c "import yaml; yaml.safe_load(open('.swarms/configs/content/my-swarm.yaml'))"

# Common issues:
# - Incorrect indentation
# - Missing quotes
# - Invalid list syntax
```

---

### Error: "Agent collision detected"

**Symptoms:**
- Multiple agents trying to edit same file
- Merge conflicts
- Overwrites

**Root cause:** Agents assigned to high-collision zones

**Solution:**
```bash
# Check collision map
cat docs/architecture/boundaries.md

# Reassign agents to zero-collision zones:
# - Different article categories
# - Different script files
# - Different config files

# Update swarm config to avoid collisions
vim .swarms/configs/content/my-swarm.yaml
```

---

## Linear Sync Issues

### Error: "Linear API authentication failed"

**Symptoms:**
```
AuthenticationError: Invalid API key
```

**Root cause:** Missing or invalid `LINEAR_API_KEY`

**Solution:**
```bash
# Get fresh API key
# 1. Go to https://linear.app/settings/api
# 2. Create new personal API key
# 3. Copy key

# Update .env
vim .env
# Add: LINEAR_API_KEY=lin_api_xxxxxxxxx

# Validate
tools/scripts/validate.sh env

# Test
python3 scripts/linear/sync_issues.py
```

---

### Error: "Rate limit exceeded"

**Symptoms:**
```
RateLimitError: Too many requests
```

**Root cause:** Too many API calls in short time

**Solution:**
```bash
# Wait 60 seconds
sleep 60

# Retry with rate limiting
# Add delays between API calls if scripting

# Or reduce batch size
python3 scripts/linear/sync_issues.py --limit 10
```

---

## Script Permission Issues

### Error: "Permission denied: ./deploy.sh"

**Symptoms:**
```bash
tools/scripts/deploy.sh content
# -bash: tools/scripts/deploy.sh: Permission denied
```

**Root cause:** Script not executable

**Solution:**
```bash
# Make specific script executable
chmod +x tools/scripts/deploy.sh

# Or all scripts
chmod +x tools/scripts/*.sh
chmod +x .swarms/bin/*.sh
```

---

## Validation Issues

### Warning: "X articles missing references"

**Symptoms:**
```
⚠️  5 articles have < 3 references
```

**Root cause:** Articles don't meet quality standards

**Solution:**
```bash
# Find articles with insufficient references
grep -r "## References" docs/help-articles/baseball/ | while read file; do
    count=$(grep -c "^[0-9]\." "$file")
    if [ $count -lt 3 ]; then
        echo "$file: only $count references"
    fi
done

# Add more references to flagged articles
```

---

## Network Issues

### Error: "Connection timeout to Supabase"

**Symptoms:**
```
requests.exceptions.ConnectionError: Max retries exceeded
```

**Root cause:** Network connectivity issue

**Solution:**
```bash
# Check internet connection
ping supabase.co

# Check Supabase status
curl -I https://status.supabase.com

# Try with different network
# Or wait and retry if Supabase is down

# Check firewall isn't blocking
# Corporate networks may block Supabase
```

---

## Performance Issues

### Issue: "Deployment very slow (> 5 minutes)"

**Symptoms:**
- Content deployment takes > 5 minutes
- Each article taking 2-3 seconds

**Root cause:** Network latency or large batch

**Solution:**
```bash
# Deploy in smaller batches
# Edit scripts/content/load_articles.py to limit files

# Or use batch inserts (if implemented)

# Check network speed
curl -w "%{time_total}\n" -o /dev/null -s https://supabase.co
```

---

## Common Error Patterns

### Pattern: "No such file or directory"

**Always check:**
1. Are you in the right directory? (`pwd` should show linear-bootstrap)
2. Does the file exist? (`ls path/to/file`)
3. Is the path correct? (use `docs/architecture/repo-map.md` for reference)

---

### Pattern: "Module not found"

**Always check:**
1. Virtual environment activated? (`source .venv/bin/activate`)
2. Dependencies installed? (`pip list`)
3. Python version correct? (`python3 --version`)

---

### Pattern: "API error"

**Always check:**
1. `.env` file has credentials
2. Credentials are valid (not expired)
3. Network connectivity works
4. API service is up (check status pages)

---

## Getting Help

**If stuck:**

1. **Check this troubleshooting guide** ← You are here
2. **Check relevant runbook:**
   - Content issues → `docs/runbooks/content.md`
   - Linear issues → `docs/runbooks/linear-sync.md`
   - Setup issues → `docs/runbooks/setup.md`
3. **Check repo-map:** `docs/architecture/repo-map.md`
4. **Search existing outcomes:** `ls .outcomes/`

---

## Debugging Tools

### Enable verbose logging

```bash
# For Python scripts
python3 -v scripts/content/load_articles.py

# For shell scripts
bash -x tools/scripts/deploy.sh content
```

### Check recent changes

```bash
# What changed recently?
git status
git diff

# Recent commits
git log --oneline -10
```

### Validate entire setup

```bash
# Run all validations
tools/scripts/validate.sh all

# Should report any issues
```

---

## See Also

- [Setup Guide](setup.md) - Initial environment setup
- [Content Deployment](content.md) - Content-specific issues
- [Linear Sync](linear-sync.md) - Linear integration issues
- [Repository Map](../architecture/repo-map.md) - Where files live

---

**If you find a new issue not listed here, please document it!**
