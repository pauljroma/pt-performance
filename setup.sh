#!/bin/bash
# Linear Integration Setup Script

set -e

echo "🚀 Linear Integration Setup"
echo "=============================="
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi
echo "✅ Python 3 found: $(python3 --version)"

# Check LINEAR_API_KEY
if [ -z "$LINEAR_API_KEY" ]; then
    echo "⚠️  LINEAR_API_KEY not set"
    echo ""
    echo "Please set your Linear API key:"
    echo "  export LINEAR_API_KEY=lin_api_..."
    echo ""
    echo "Get your API key from: https://linear.app/settings/api"
    echo ""
    read -p "Enter your Linear API key now (or press Enter to skip): " key
    if [ -n "$key" ]; then
        export LINEAR_API_KEY="$key"
        echo ""
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "  export LINEAR_API_KEY=$key"
        echo ""
    else
        echo "⚠️  Skipping API key setup. Set it later before using the tools."
    fi
else
    echo "✅ LINEAR_API_KEY is set"
fi

# Install dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip3 install -q -r requirements.txt
echo "✅ Dependencies installed"

# Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x linear_bootstrap.py
chmod +x linear_bootstrap.js
chmod +x linear_client.py
chmod +x mcp_server.py
chmod +x .claude/hooks/on-start.sh
echo "✅ Scripts are now executable"

# Test connection
if [ -n "$LINEAR_API_KEY" ]; then
    echo ""
    echo "🧪 Testing Linear connection..."
    if python3 linear_client.py export-md > /dev/null 2>&1; then
        echo "✅ Successfully connected to Linear!"
        echo ""
        echo "📋 Current plan:"
        python3 linear_client.py export-md | head -n 15
        echo "..."
    else
        echo "⚠️  Could not connect to Linear. Check your API key."
    fi
fi

# MCP setup instructions
echo ""
echo "=============================="
echo "📝 Optional: MCP Server Setup"
echo "=============================="
echo ""
echo "To enable Linear tools in Claude Code:"
echo ""
echo "1. Add to ~/.config/claude/mcp.json:"
echo ""
cat mcp_config.json | sed "s|\${LINEAR_API_KEY}|$LINEAR_API_KEY|g"
echo ""
echo "2. Restart Claude Code"
echo ""

# Hook setup
echo "=============================="
echo "📝 Optional: Auto-Sync Hook"
echo "=============================="
echo ""
echo "The on-start hook will automatically sync Linear plan at session start."
echo "It's already set up in .claude/hooks/on-start.sh"
echo ""
echo "To enable in your Claude Code workspace:"
echo "1. Copy .claude/ folder to your workspace root"
echo "2. Ensure hook is executable (already done)"
echo "3. Hook will run automatically on session start"
echo ""

echo "=============================="
echo "✅ Setup Complete!"
echo "=============================="
echo ""
echo "Next steps:"
echo "  1. Review INTEGRATION_GUIDE.md for full documentation"
echo "  2. Try: python3 linear_client.py export-md"
echo "  3. Try: /sync-linear (in Claude Code with slash command)"
echo "  4. Configure MCP server (optional but recommended)"
echo ""
echo "Happy planning! 🎉"
