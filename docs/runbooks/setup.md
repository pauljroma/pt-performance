# Setup & Bootstrap Runbook

**Purpose:** First-time environment setup for linear-bootstrap
**Time:** 10-15 minutes
**Prerequisites:** macOS/Linux, Python 3.8+, Git

---

## Quick Start

```bash
# One-command setup
cd /Users/expo/Code/expo/clients/linear-bootstrap
tools/scripts/bootstrap.sh
```

---

## Complete Setup Guide

### Step 1: Prerequisites Check

**Required software:**
- Python 3.8 or higher
- Git
- (Optional) Supabase CLI for database work
- (Optional) Node.js for Linear API work

**Check versions:**
```bash
python3 --version  # Should be 3.8+
git --version      # Any recent version
```

**Install missing dependencies:**

**macOS:**
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python 3
brew install python@3.11

# Install Supabase CLI (optional)
brew install supabase/tap/supabase
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3.11 python3-pip git

# Supabase CLI (optional)
curl -fsSL https://supabase.com/install.sh | sh
```

---

### Step 2: Clone Repository (If Needed)

```bash
# If you don't have the repo yet
cd ~/Code
git clone <repo-url>
cd expo/clients/linear-bootstrap
```

**Verify you're in the right place:**
```bash
ls docs/architecture/repo-map.md
# Should exist
```

---

### Step 3: Environment Configuration

**Create `.env` file:**
```bash
# Copy template
cp .env.template .env

# Edit with your credentials
vim .env  # or nano, code, etc.
```

**Required environment variables:**
```bash
# Supabase (required for content deployment)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Linear (optional - only if using Linear sync)
LINEAR_API_KEY=lin_api_xxxxxxxxx
LINEAR_TEAM_ID=your-team-id

# Environment
ENVIRONMENT=dev  # or staging, prod
```

**Get Supabase credentials:**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings → API
4. Copy:
   - Project URL → `SUPABASE_URL`
   - anon/public key → `SUPABASE_KEY`
   - service_role key → `SUPABASE_SERVICE_ROLE_KEY`

**Get Linear credentials (optional):**
1. Go to https://linear.app/settings/api
2. Create new API key
3. Copy key → `LINEAR_API_KEY`
4. Get team ID from Linear URL → `LINEAR_TEAM_ID`

---

### Step 4: Install Python Dependencies

**If using pip:**
```bash
# Create virtual environment (recommended)
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt  # if exists
pip install supabase python-dotenv pyyaml
```

**If using poetry:**
```bash
# Install poetry if needed
curl -sSL https://install.python-poetry.org | python3 -

# Install dependencies
poetry install
```

---

### Step 5: Validate Setup

**Run validation script:**
```bash
tools/scripts/validate.sh all
```

**Expected output:**
```
⚙️  Validating environment configuration...
✅ SUPABASE_URL is set
✅ SUPABASE_KEY is set
✅ All required environment variables are set

📚 Validating articles...
Found 189 articles in docs/help-articles/baseball
✅ All articles have frontmatter

🤖 Validating swarm configurations...
Found 1 swarm configs in .swarms/configs
✅ All swarm configs have valid YAML

✅ All validations passed
```

---

### Step 6: Test Deployment (Dry Run)

**Test content deployment:**
```bash
# Dry run - check what would be deployed
python3 -c "
from pathlib import Path
articles = list(Path('docs/help-articles/baseball').rglob('*.md'))
print(f'Would deploy {len(articles)} articles')
"
```

**Test actual deployment (small batch):**
```bash
# Deploy just to verify connection
tools/scripts/deploy.sh content
# Should connect to Supabase and upload articles
```

---

## Directory Structure After Setup

```
linear-bootstrap/
├── .env                    # ✅ Your credentials (gitignored)
├── .venv/                  # ✅ Python virtual environment (optional)
├── docs/
│   ├── architecture/       # ✅ Read these for orientation
│   └── runbooks/           # ✅ Operational guides
├── tools/scripts/          # ✅ Your command interface
├── .swarms/                # ✅ Swarm coordination
└── deployment_manifest.json # ✅ Created after first deployment
```

---

## Troubleshooting Setup

### "Python 3 not found"

**Problem:** Python not installed or wrong version

**Solution:**
```bash
# Check what you have
which python3
python3 --version

# Install correct version
# macOS: brew install python@3.11
# Linux: sudo apt install python3.11
```

---

### "Module 'supabase' not found"

**Problem:** Python dependencies not installed

**Solution:**
```bash
# Activate virtual environment if using one
source .venv/bin/activate

# Install dependencies
pip install supabase python-dotenv pyyaml
```

---

### "SUPABASE_URL not found"

**Problem:** `.env` file missing or not loaded

**Solution:**
```bash
# Check if .env exists
ls -la .env

# If not, create it
cp .env.template .env

# Edit with your credentials
vim .env

# Validate
tools/scripts/validate.sh env
```

---

### "Permission denied: tools/scripts/deploy.sh"

**Problem:** Scripts not executable

**Solution:**
```bash
# Make all scripts executable
chmod +x tools/scripts/*.sh
```

---

### "Supabase connection failed"

**Problem:** Invalid credentials or network issue

**Solution:**
```bash
# Test credentials manually
python3 << 'EOF'
import os
from pathlib import Path
from supabase import create_client

# Load .env
env_path = Path('.env')
for line in env_path.read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        key, val = line.split('=', 1)
        os.environ[key.strip()] = val.strip()

# Test connection
url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_KEY')
print(f"Testing connection to {url}")

client = create_client(url, key)
result = client.table('content_types').select('*').limit(1).execute()
print(f"✅ Connected! Found {len(result.data)} content types")
EOF
```

---

## Next Steps After Setup

**1. Read the documentation:**
```bash
# Start here
cat docs/index.md

# Then read THE MAP
cat docs/architecture/repo-map.md

# Pick your task runbook
ls docs/runbooks/
```

**2. Try a deployment:**
```bash
# Deploy content
tools/scripts/deploy.sh content

# Check results
cat deployment_manifest.json
```

**3. Validate everything works:**
```bash
# Run all validations
tools/scripts/validate.sh all
```

**4. (Optional) Set up Linear sync:**
```bash
# If you added Linear credentials
tools/scripts/sync.sh linear
```

---

## Uninstall / Cleanup

**Remove virtual environment:**
```bash
rm -rf .venv
```

**Remove credentials:**
```bash
rm .env
```

**Clean deployment artifacts:**
```bash
rm deployment_manifest.json
rm -rf .workspace/
```

---

## See Also

- [Repository Map](../architecture/repo-map.md) - Where everything is
- [Content Deployment](content.md) - Deploy articles
- [Troubleshooting](troubleshooting.md) - Fix common issues
- [Linear Sync](linear-sync.md) - Linear integration setup

---

## Setup Checklist

- [ ] Python 3.8+ installed
- [ ] Git installed
- [ ] Repository cloned
- [ ] `.env` file created from template
- [ ] Supabase credentials added to `.env`
- [ ] (Optional) Linear credentials added
- [ ] Dependencies installed
- [ ] `tools/scripts/validate.sh all` passes
- [ ] Test deployment successful
- [ ] Read `docs/architecture/repo-map.md`

**Setup time:** 10-15 minutes
