#!/bin/bash
# sync-version.sh - Sync version from VERSION file to all documentation
# Usage: ./scripts/sync-version.sh [--check]
#   --check : Only check, don't modify (exit 1 if mismatch)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Read source of truth
if [[ ! -f VERSION ]]; then
  echo "❌ VERSION file not found"
  exit 1
fi

VERSION=$(cat VERSION | tr -d '[:space:]')
CHECK_ONLY=false
ERRORS=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

echo "=== Version Sync ==="
echo "Source: VERSION → $VERSION"
echo ""

# Function to check/update a file
check_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "⚠️  $file not found"
    return
  fi

  # Find version numbers in file (3.x.x pattern only)
  local old_versions=$(grep -oE '3\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | sort -u | grep -v "^${VERSION}$" || true)

  if [[ -n "$old_versions" ]]; then
    echo "📍 $file: found outdated versions"
    for v in $old_versions; do
      echo "   - $v → $VERSION"
    done

    if $CHECK_ONLY; then
      ERRORS=$((ERRORS + 1))
    else
      # Replace all old 3.x.x versions with current version
      for v in $old_versions; do
        # macOS compatible sed
        sed -i '' "s/$v/$VERSION/g" "$file"
      done
      echo "✅ $file: updated"
    fi
  else
    # Check if file contains current version
    if grep -q "$VERSION" "$file" 2>/dev/null; then
      echo "✅ $file: OK ($VERSION)"
    else
      echo "⚠️  $file: no version found"
    fi
  fi
}

# Check main files
check_file "README.md"
check_file "guide/cheatsheet.md"
check_file "guide/ultimate-guide.md"
check_file "machine-readable/reference.yaml"

echo ""

if $CHECK_ONLY && [[ $ERRORS -gt 0 ]]; then
  echo "❌ $ERRORS file(s) need version update"
  echo "Run: ./scripts/sync-version.sh"
  exit 1
fi

echo "✅ Done"
