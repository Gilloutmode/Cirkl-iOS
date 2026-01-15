#!/bin/bash

# 🚀 Cirkl MCP Setup Script for Cursor
# This script sets up all MCP servers for iOS development

echo "🎯 Setting up MCP servers for Cirkl iOS Development..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install it first:"
    echo "   brew install node"
    exit 1
fi

# Check if Cursor config directory exists
if [ ! -d ".cursor" ]; then
    mkdir -p .cursor
    echo "✅ Created .cursor directory"
fi

# Check if npm is initialized
if [ ! -f "package.json" ]; then
    npm init -y > /dev/null 2>&1
    echo "✅ Initialized npm project"
fi

# Install global npx if needed
echo "📦 Ensuring npx is available..."
npm install -g npx > /dev/null 2>&1

# Test MCP servers (they auto-install on first run)
echo "🔧 Testing MCP servers..."

echo "  → Testing Apple Docs MCP..."
npx @jc_builds/apple-doc-mcp --version > /dev/null 2>&1 || echo "    ⚠️  Will install on first use"

echo "  → Testing GitHub MCP..."
npx @modelcontextprotocol/server-github --version > /dev/null 2>&1 || echo "    ⚠️  Will install on first use"

echo "  → Testing Filesystem MCP..."
npx @modelcontextprotocol/server-filesystem --version > /dev/null 2>&1 || echo "    ⚠️  Will install on first use"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ Created .env file - Please add your API keys!"
else
    echo "✅ .env file already exists"
fi

# Install additional recommended tools
echo "📚 Installing recommended iOS dev tools..."

# SwiftLint for code quality
if ! command -v swiftlint &> /dev/null; then
    echo "  → Installing SwiftLint..."
    brew install swiftlint
else
    echo "  ✅ SwiftLint already installed"
fi

# SwiftFormat for code formatting
if ! command -v swiftformat &> /dev/null; then
    echo "  → Installing SwiftFormat..."
    brew install swiftformat
else
    echo "  ✅ SwiftFormat already installed"
fi

echo ""
echo "✨ Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Add your API keys to .env file:"
echo "   nano .env"
echo ""
echo "2. Open Cursor and enable MCP:"
echo "   - Go to Settings (⌘,)"
echo "   - Navigate to Features → Labs"
echo "   - Enable 'Model Context Protocol'"
echo "   - Restart Cursor"
echo ""
echo "3. Start developing:"
echo "   cursor ."
echo ""
echo "💡 Pro tip: Ask Cursor AI to 'Search Apple docs for SwiftUI' to test MCP!"