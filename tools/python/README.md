# Python Tools

**Purpose:** Python utilities for validation, testing, and build automation

---

## Tools

### validate_articles.py

**Purpose:** Validate article structure, frontmatter, and content

**Usage:**
```bash
# Validate all articles
python3 tools/python/validate_articles.py

# Validate specific directory
python3 tools/python/validate_articles.py docs/help-articles/baseball/

# Validate single file
python3 tools/python/validate_articles.py docs/help-articles/baseball/hitting/bat-speed.md

# Verbose mode
python3 tools/python/validate_articles.py -v
```

**Features:**
- YAML frontmatter validation
- Required field checking (title, category, subcategory, sport, difficulty)
- Category validation by sport
- Content structure validation
- Link validation (basic)
- Comprehensive error reporting

**Exit codes:**
- `0` - All validations passed
- `1` - Validation errors found

---

### build.sh

**Purpose:** Build/compile Python modules

**Usage:**
```bash
# Build all modules
tools/python/build.sh

# Check syntax only
tools/python/build.sh --check

# Clean build artifacts
tools/python/build.sh --clean
```

**Features:**
- Python syntax checking
- Bytecode compilation
- Build artifact cleanup
- Import verification

---

### test.sh

**Purpose:** Run Python test suites

**Usage:**
```bash
# Run all tests
tools/python/test.sh

# Run unit tests only
tools/python/test.sh --unit

# Run integration tests only
tools/python/test.sh --integration

# Run with coverage report
tools/python/test.sh --coverage
```

**Requirements:**
```bash
pip install pytest pytest-cov
```

**Features:**
- Unit test execution
- Integration test execution
- Coverage reporting (HTML + terminal)
- Validation tests

---

### lint.sh

**Purpose:** Run Python linters and formatters

**Usage:**
```bash
# Run all linters
tools/python/lint.sh

# Auto-fix issues
tools/python/lint.sh --fix

# Check mode (CI)
tools/python/lint.sh --check
```

**Requirements:**
```bash
pip install black flake8 pylint mypy
```

**Features:**
- Code formatting (black)
- Style checking (flake8)
- Code quality (pylint)
- Type checking (mypy)
- Auto-fix support

---

## Quick Start

### First-Time Setup

```bash
# Install dependencies
pip install pytest pytest-cov black flake8 pylint mypy pyyaml

# Make scripts executable (if not already)
chmod +x tools/python/*.sh

# Verify setup
tools/python/build.sh --check
```

### Typical Workflow

```bash
# 1. Validate articles
python3 tools/python/validate_articles.py

# 2. Run linters
tools/python/lint.sh

# 3. Run tests
tools/python/test.sh --all

# 4. Build
tools/python/build.sh
```

---

## Integration with Canonical Wrappers

These tools are called by canonical wrapper scripts:

```bash
# tools/scripts/validate.sh articles
# → calls validate_articles.py

# tools/scripts/test.sh --quick
# → calls test.sh --unit

# tools/scripts/deploy.sh content
# → calls build.sh --check first
```

See: [`docs/architecture/repo-map.md`](../../docs/architecture/repo-map.md)

---

## Configuration

### Article Validation

Edit `validate_articles.py` to customize:

```python
REQUIRED_FIELDS = ["title", "category", "subcategory", "sport", "difficulty"]
VALID_DIFFICULTIES = ["beginner", "intermediate", "advanced", "expert"]
VALID_SPORTS = ["baseball", "general"]

VALID_CATEGORIES = {
    "baseball": ["hitting", "pitching", "fielding", ...],
    "general": ["getting-started", "features", ...],
}
```

### Linters

Edit `lint.sh` to customize:

```bash
# Black
--max-line-length=100

# Flake8
--max-line-length=100 --ignore=E203,W503

# Pylint
--disable=missing-docstring,too-few-public-methods
```

---

## Troubleshooting

### "pytest not found"

```bash
pip install pytest pytest-cov
```

### "black not found"

```bash
pip install black flake8 pylint mypy
```

### "Validation failed"

Run with verbose mode to see details:
```bash
python3 tools/python/validate_articles.py -v
```

### "Import errors"

Ensure you're running from repository root:
```bash
cd /path/to/linear-bootstrap
python3 tools/python/validate_articles.py
```

---

## See Also

- [Canonical Wrappers ADR](../../docs/architecture/decisions/001-canonical-wrappers.md)
- [Content Runbook](../../docs/runbooks/content.md)
- [Troubleshooting Guide](../../docs/runbooks/troubleshooting.md)
