#!/bin/bash
# RTK Benchmark Script for T3 Stack Projects
# Usage: bash .claude/scripts/rtk-benchmark.sh

set -e

echo "🚀 RTK Benchmark - T3 Stack Edition"
echo "===================================="
echo ""

# Check RTK installation
if ! command -v rtk &> /dev/null; then
    echo "❌ RTK not found. Install from: https://github.com/pszymkowiak/rtk"
    exit 1
fi

RTK_VERSION=$(rtk --version 2>&1 | head -1)
echo "RTK Version: $RTK_VERSION"
echo ""

# Create results directory
RESULTS_DIR=".claude/docs/rtk-benchmarks"
mkdir -p "$RESULTS_DIR"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
RESULTS_FILE="$RESULTS_DIR/benchmark-$TIMESTAMP.md"

echo "# RTK Benchmark Results" > "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "**Date**: $(date +%Y-%m-%d)" >> "$RESULTS_FILE"
echo "**RTK Version**: $RTK_VERSION" >> "$RESULTS_FILE"
echo "**Project**: $(basename $PWD)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "---" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Benchmark function
benchmark() {
    local name="$1"
    local cmd="$2"
    local rtk_cmd="$3"

    echo "Testing: $name"

    # Baseline
    baseline_chars=$(eval "$cmd" 2>&1 | wc -c | awk '{print $1}')
    baseline_tokens=$((baseline_chars / 4))

    # RTK (if supported)
    if [ -n "$rtk_cmd" ]; then
        rtk_chars=$(eval "$rtk_cmd" 2>&1 | wc -c | awk '{print $1}')
        rtk_tokens=$((rtk_chars / 4))

        if [ $baseline_chars -gt 0 ]; then
            reduction=$(awk "BEGIN {printf \"%.1f\", (1 - $rtk_chars / $baseline_chars) * 100}")
        else
            reduction="N/A"
        fi

        status="✅"
        if [ "$rtk_chars" -eq 0 ] || [ "$reduction" = "N/A" ]; then
            status="❌"
            reduction="N/A"
        fi
    else
        rtk_chars="N/A"
        rtk_tokens="N/A"
        reduction="N/A"
        status="🚫 Not supported"
    fi

    # Write to results file
    echo "| $name | $baseline_chars | $baseline_tokens | $rtk_chars | $rtk_tokens | $reduction% | $status |" >> "$RESULTS_FILE"
}

# Header
echo "| Command | Baseline (chars) | Baseline (tokens) | RTK (chars) | RTK (tokens) | Reduction | Status |" >> "$RESULTS_FILE"
echo "|---------|------------------|-------------------|-------------|--------------|-----------|--------|" >> "$RESULTS_FILE"

# Git commands
echo ""
echo "📊 Git Commands"
echo "==============="
benchmark "git log -20" "git log -20" "rtk git log -- -20"
benchmark "git status" "git status" "rtk git status"
benchmark "git diff HEAD~1" "git diff HEAD~1" "rtk git diff HEAD~1"

# Find commands
echo ""
echo "📊 Find Commands"
echo "================"
benchmark "find src/ -name '*.ts'" "find src/ -name '*.ts' 2>/dev/null || echo ''" "rtk find '*.ts' src/ 2>/dev/null || echo ''"
benchmark "find src/ -name '*.tsx'" "find src/ -name '*.tsx' 2>/dev/null || echo ''" "rtk find '*.tsx' src/ 2>/dev/null || echo ''"

# pnpm commands
echo ""
echo "📊 pnpm Commands (unsupported)"
echo "=============================="
benchmark "pnpm list --depth=0" "pnpm list --depth=0 2>&1" ""
benchmark "pnpm outdated" "pnpm outdated 2>&1 || echo 'All packages up-to-date'" ""

# Test framework
echo ""
echo "📊 Test Framework (unsupported)"
echo "==============================="
benchmark "pnpm test (first 50 lines)" "pnpm test 2>&1 | head -50" ""

# TypeScript
echo ""
echo "📊 TypeScript Compiler (unsupported)"
echo "===================================="
benchmark "pnpm tsc --noEmit" "pnpm tsc --noEmit 2>&1 || echo 'No errors'" ""

# Prisma
echo ""
echo "📊 Prisma (unsupported)"
echo "======================="
benchmark "pnpm prisma migrate status" "pnpm prisma migrate status 2>&1" ""

# Build
echo ""
echo "📊 Build Tools (unsupported)"
echo "============================"
benchmark "pnpm build (first 30 lines)" "pnpm build 2>&1 | head -30" ""

echo "" >> "$RESULTS_FILE"
echo "---" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "**Legend**:" >> "$RESULTS_FILE"
echo "- ✅ Works: RTK filtering successful" >> "$RESULTS_FILE"
echo "- ❌ Broken: RTK returned error or 0 bytes" >> "$RESULTS_FILE"
echo "- 🚫 Not supported: RTK doesn't handle this command" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "**Token estimation**: chars / 4 ≈ tokens (rough approximation)" >> "$RESULTS_FILE"

echo ""
echo "✅ Benchmark complete!"
echo "📄 Results saved to: $RESULTS_FILE"
echo ""
echo "📊 Summary:"
cat "$RESULTS_FILE" | grep "^|" | tail -n +2
