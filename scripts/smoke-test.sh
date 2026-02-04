#!/bin/bash
# Smoke test script for dev-container
# Verifies all installed tools and their versions

# Note: Not using set -e because we want to collect all failures before exiting

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Print test result
pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Check if a command exists and print its version
check_tool() {
    local tool=$1
    local version_cmd=$2

    if command -v "$tool" &> /dev/null; then
        version_output=$(eval "$version_cmd" 2>&1 || true)
        pass "$tool: $version_output"
        return 0
    else
        fail "$tool: not found"
        return 1
    fi
}

echo "=============================================="
echo "  Dev Container Smoke Test"
echo "=============================================="
echo ""

# System info
echo "--- System Information ---"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Working directory: $(pwd)"
echo ""

# Check core system tools
echo "--- Core System Tools ---"
check_tool "git" "git --version | head -1"
check_tool "curl" "curl --version | head -1"
check_tool "wget" "wget --version | head -1"
check_tool "make" "make --version | head -1"
check_tool "gcc" "gcc --version | head -1"
check_tool "jq" "jq --version"
echo ""

# Check Go
echo "--- Go ---"
check_tool "go" "go version"
echo ""

# Check Node.js ecosystem
echo "--- Node.js ---"
check_tool "node" "node --version"
check_tool "npm" "npm --version"
check_tool "pnpm" "pnpm --version"
echo ""

# Check Python ecosystem
echo "--- Python ---"
check_tool "python3" "python3 --version"
check_tool "python" "python --version"
check_tool "pip3" "pip3 --version | head -1"
check_tool "pip" "pip --version | head -1"
check_tool "uv" "uv --version"
echo ""

# Check AI agents
echo "--- AI Agents ---"
check_tool "claude" "claude --version 2>&1 | head -1"
check_tool "codex" "codex --version 2>&1 | head -1"
echo ""

# Check ralphex
echo "--- Ralphex ---"
check_tool "ralphex" "ralphex --version 2>&1 | head -1"
echo ""

# Check user permissions
echo "--- User Permissions ---"
if [ "$(whoami)" = "developer" ]; then
    pass "Running as developer user"
else
    warn "Running as $(whoami), expected developer"
fi

if [ -w "/workspace" ]; then
    pass "/workspace is writable"
else
    fail "/workspace is not writable"
fi
echo ""

# Summary
echo "=============================================="
echo "  Summary"
echo "=============================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}Smoke test FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}Smoke test PASSED${NC}"
    exit 0
fi
