#!/bin/bash
#
# bootstrap.sh - First-time environment setup for linear-bootstrap
#
# Usage: tools/scripts/bootstrap.sh
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Bootstrapping linear-bootstrap environment${NC}"
echo ""

# Check Python 3
echo -n "Checking Python 3... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✅ Python $PYTHON_VERSION${NC}"
else
    echo -e "${RED}❌ Python 3 not found${NC}"
    echo "Install Python 3.8+ to continue"
    exit 1
fi

# Check Git
echo -n "Checking Git... "
if command -v git &> /dev/null; then
    echo -e "${GREEN}✅ Git installed${NC}"
else
    echo -e "${RED}❌ Git not found${NC}"
    exit 1
fi

# Create .env if doesn't exist
echo -n "Checking .env file... "
if [[ ! -f .env ]]; then
    if [[ -f .env.template ]]; then
        echo -e "${YELLOW}⚠️  Creating from template${NC}"
        cp .env.template .env
        echo ""
        echo -e "${YELLOW}📝 Please edit .env with your credentials:${NC}"
        echo "   - SUPABASE_URL"
        echo "   - SUPABASE_KEY"
        echo "   - SUPABASE_SERVICE_ROLE_KEY"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No template found${NC}"
        echo "Creating minimal .env"
        cat > .env << 'EOF'
# Supabase
SUPABASE_URL=
SUPABASE_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Linear (optional)
LINEAR_API_KEY=
LINEAR_TEAM_ID=

# Environment
ENVIRONMENT=dev
EOF
    fi
else
    echo -e "${GREEN}✅ .env exists${NC}"
fi

# Make scripts executable
echo -n "Making scripts executable... "
chmod +x tools/scripts/*.sh 2>/dev/null || true
chmod +x .swarms/bin/*.sh 2>/dev/null || true
echo -e "${GREEN}✅ Done${NC}"

# Install Python dependencies (if requirements.txt exists)
if [[ -f requirements.txt ]]; then
    echo -n "Installing Python dependencies... "
    if python3 -m pip install -q -r requirements.txt; then
        echo -e "${GREEN}✅ Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed (continuing anyway)${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Bootstrap complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your Supabase credentials"
echo "  2. Run: tools/scripts/validate.sh env"
echo "  3. Read: docs/architecture/repo-map.md"
echo "  4. Deploy content: tools/scripts/deploy.sh content"
echo ""
