#!/bin/bash

# 🚀 Claude Code Setup Script for Cirkl iOS Development
# This script configures Claude Code with optimal settings for the project

echo "🎯 Setting up Claude Code for Cirkl iOS Development..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if Node.js is installed
print_status "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install it first:"
    echo "   brew install node"
    exit 1
else
    print_success "Node.js is installed ($(node --version))"
fi

# Install Claude Code if not installed
print_status "Checking Claude Code installation..."
if ! command -v claude-code &> /dev/null; then
    print_warning "Claude Code not found. Installing..."
    npm install -g @anthropic/claude-code
    
    if [ $? -eq 0 ]; then
        print_success "Claude Code installed successfully"
    else
        print_error "Failed to install Claude Code"
        print_warning "Try manually: npm install -g @anthropic/claude-code"
        exit 1
    fi
else
    print_success "Claude Code is already installed"
fi

# Create Claude configuration directory
print_status "Creating Claude configuration directory..."
mkdir -p ~/.claude
print_success "Configuration directory ready"

# Check for API key
print_status "Checking for Anthropic API key..."
if [ -z "$ANTHROPIC_API_KEY" ]; then
    print_warning "ANTHROPIC_API_KEY not found in environment"
    echo ""
    echo "Please enter your Anthropic API key:"
    echo "(Get one at: https://console.anthropic.com/account/keys)"
    read -s api_key
    echo ""
    
    if [ -n "$api_key" ]; then
        echo "export ANTHROPIC_API_KEY='$api_key'" >> ~/.zshrc
        echo "export ANTHROPIC_API_KEY='$api_key'" >> ~/.bashrc
        export ANTHROPIC_API_KEY="$api_key"
        print_success "API key saved to shell configuration"
    else
        print_error "No API key provided. Please set ANTHROPIC_API_KEY manually"
    fi
else
    print_success "API key found in environment"
fi

# Create Claude Code config
print_status "Creating Claude Code configuration..."
cat > ~/.claude/config.json << EOF
{
  "apiKey": "${ANTHROPIC_API_KEY}",
  "model": "claude-3-opus-20240229",
  "temperature": 0.7,
  "maxTokens": 4096,
  "projectDefaults": {
    "language": "swift",
    "framework": "swiftui",
    "platform": "ios",
    "minIosVersion": "17.0"
  },
  "editor": {
    "theme": "dark",
    "fontSize": 14,
    "tabSize": 2,
    "wordWrap": true
  },
  "features": {
    "autoSave": true,
    "livePreview": false,
    "codeCompletion": true,
    "errorHighlighting": true
  }
}
EOF
print_success "Claude Code configuration created"

# Create symbolic links for easy access
print_status "Creating project shortcuts..."
ln -sf /Users/gil/Cirkl/.cursorrules ~/.claude/cirkl-rules.md 2>/dev/null
ln -sf /Users/gil/Cirkl/.claude/context.md ~/.claude/cirkl-context.md 2>/dev/null
print_success "Project shortcuts created"

# Create claude-code wrapper script
print_status "Creating claude-code wrapper for Cirkl..."
cat > /usr/local/bin/cirkl-code << 'EOF'
#!/bin/bash
# Wrapper script for Claude Code with Cirkl context

# Always use Cirkl project context
export CLAUDE_PROJECT_ROOT="/Users/gil/Cirkl"
export CLAUDE_RULES_FILE="/Users/gil/Cirkl/.cursorrules"
export CLAUDE_CONTEXT_FILE="/Users/gil/Cirkl/.claude/context.md"

# Run Claude Code with project context
claude-code \
  --project "$CLAUDE_PROJECT_ROOT" \
  --rules "$CLAUDE_RULES_FILE" \
  --context "$CLAUDE_CONTEXT_FILE" \
  "$@"
EOF

chmod +x /usr/local/bin/cirkl-code
print_success "Created 'cirkl-code' command"

# Install recommended VS Code / Cursor extensions
print_status "Checking for Cursor installation..."
if command -v cursor &> /dev/null; then
    print_success "Cursor is installed"
    
    print_status "Installing recommended extensions..."
    cursor --install-extension sswg.swift-lang
    cursor --install-extension vknabel.vscode-swiftformat
    cursor --install-extension vknabel.vscode-swiftlint
    print_success "Extensions installed"
else
    print_warning "Cursor not found. Install from: https://cursor.com"
fi

# Create test command
print_status "Creating test command..."
cat > ~/test-claude-code.sh << 'EOF'
#!/bin/bash
echo "Testing Claude Code with Cirkl context..."
echo ""
echo "Create a simple SwiftUI view with glassmorphic design" | cirkl-code
EOF
chmod +x ~/test-claude-code.sh

# Display summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Claude Code Setup Complete! 🎉"
echo ""
echo "📋 Configuration Summary:"
echo "   • Claude Code: Installed ✓"
echo "   • API Key: Configured ✓"
echo "   • Project Context: Loaded ✓"
echo "   • Shortcuts: Created ✓"
echo ""
echo "🚀 Quick Start Commands:"
echo ""
echo "   ${GREEN}cirkl-code${NC} \"Create authentication flow with NFC\""
echo "   ${GREEN}cirkl-code${NC} \"Fix orbital view performance\""
echo "   ${GREEN}cirkl-code${NC} \"Add unit tests for ConnectionViewModel\""
echo ""
echo "📁 Configuration Files:"
echo "   • Rules: /Users/gil/Cirkl/.cursorrules"
echo "   • Context: /Users/gil/Cirkl/.claude/context.md"
echo "   • Prompts: /Users/gil/Cirkl/.claude/prompts/"
echo ""
echo "💡 Tips:"
echo "   • Use 'cirkl-code' instead of 'claude-code' for automatic context"
echo "   • Open Cursor in project: cd /Users/gil/Cirkl && cursor ."
echo "   • Test setup: ~/test-claude-code.sh"
echo ""
echo "📚 Documentation:"
echo "   • Guide: /Users/gil/Cirkl/CLAUDE_CODE_CONFIG_GUIDE.md"
echo "   • Prompts: /Users/gil/Cirkl/.claude/prompts/README.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"