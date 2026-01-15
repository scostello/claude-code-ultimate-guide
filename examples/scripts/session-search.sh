#!/bin/bash
# session-search.sh - Fast Claude Code session search & resume
#
# Zero-dependency bash script to search past Claude Code conversations
# and generate ready-to-use resume commands.
#
# Usage:
#   ./session-search.sh                # List 10 most recent sessions
#   ./session-search.sh "keyword"      # Full-text search across all sessions
#   ./session-search.sh -n 20          # Show 20 results
#   ./session-search.sh --rebuild      # Force index rebuild
#
# Smart refresh:
#   Index auto-rebuilds when any session file is newer than the index.
#   No manual rebuild needed - always fresh results.
#
# Performance:
#   - List recent:    ~15ms (uses cached index + 10ms freshness check)
#   - Keyword search: ~400ms (full-text grep)
#   - Index rebuild:  ~5s for 200 sessions
#
# Installation:
#   cp session-search.sh ~/.claude/scripts/cs
#   chmod +x ~/.claude/scripts/cs
#   echo "alias cs='~/.claude/scripts/cs'" >> ~/.zshrc
#
# Comparison with alternatives:
#   | Tool                         | List    | Search | Deps    | Resume cmd |
#   |------------------------------|---------|--------|---------|------------|
#   | session-search.sh            | 15ms    | 400ms  | None    | Yes        |
#   | claude-conversation-extractor| 230ms   | 1.7s   | Python  | No         |
#   | claude-code-transcripts      | N/A     | N/A    | Python  | No         |
#   | native `claude --resume`     | 500ms+  | No     | None    | Interactive|

set -euo pipefail

INDEX="$HOME/.claude/sessions.idx"
PROJECTS="$HOME/.claude/projects"
MAX_AGE_MIN=60
LIMIT=10

# Colors
C_CYAN='\033[36m'
C_YELLOW='\033[33m'
C_DIM='\033[2m'
C_RESET='\033[0m'

build_index() {
    echo "Indexing sessions..." >&2
    : > "$INDEX"

    local count=0
    for f in "$PROJECTS"/*/*.jsonl; do
        [[ -f "$f" ]] || continue
        # Skip agent/subagent sessions
        [[ "$(basename "$f")" == agent* ]] && continue

        local id=$(basename "$f" .jsonl)
        local proj=$(basename "$(dirname "$f")" | sed 's/^-Users-[^-]*-Sites-perso-//' | sed 's/^-Users-[^-]*-Sites-//' | sed 's/^-Users-[^-]*-//')
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d: -f1-2)

        # Fast message extraction without jq
        local msg=$(grep -m1 '"type":"user"' "$f" 2>/dev/null | \
            sed 's/.*"content":"\([^"]*\).*/\1/' | \
            sed 's/\\n/ /g' | \
            cut -c1-60 | \
            tr -d '\n')

        [[ -n "$msg" ]] && {
            printf '%s\t%s\t%s\t%s\n' "$mtime" "$proj" "$id" "$msg" >> "$INDEX"
            count=$((count + 1))
        }
    done

    sort -rk1 "$INDEX" -o "$INDEX"
    echo "Indexed $count sessions" >&2
}

needs_refresh() {
    # No index = rebuild
    [[ ! -f "$INDEX" ]] && return 0

    # Any .jsonl newer than index? (fast find -newer check)
    local newer=$(find "$PROJECTS" -name "*.jsonl" -newer "$INDEX" 2>/dev/null | head -1)
    [[ -n "$newer" ]] && return 0

    return 1  # Index is fresh
}

search_fulltext() {
    local pattern="$1"
    local found=0

    echo ""
    for f in "$PROJECTS"/*/*.jsonl; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == agent* ]] && continue

        # Check if pattern exists in file
        grep -qi "$pattern" "$f" 2>/dev/null || continue

        local id=$(basename "$f" .jsonl)
        local proj=$(basename "$(dirname "$f")" | sed 's/^-Users-[^-]*-Sites-perso-//' | sed 's/^-Users-[^-]*-Sites-//' | sed 's/^-Users-[^-]*-//')
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d: -f1-2)
        local msg=$(grep -m1 '"type":"user"' "$f" 2>/dev/null | \
            sed 's/.*"content":"\([^"]*\).*/\1/' | \
            sed 's/\\n/ /g' | \
            cut -c1-50)

        printf "${C_CYAN}%s${C_RESET} │ ${C_YELLOW}%-22s${C_RESET} │ %.50s...\n" "$mtime" "$proj" "$msg"
        printf "  ${C_DIM}claude --resume %s${C_RESET}\n\n" "$id"

        found=$((found + 1))
        [[ $found -ge $LIMIT ]] && break
    done

    if [[ $found -eq 0 ]]; then
        echo "No sessions found matching '$pattern'."
    fi
}

search() {
    local pattern="$1"

    if [[ -z "$pattern" ]]; then
        # No pattern = use fast index
        needs_refresh && build_index
        local results=$(head -"$LIMIT" "$INDEX")
        if [[ -z "$results" ]]; then
            echo "No sessions found."
            return
        fi

        echo ""
        echo "$results" | while IFS=$'\t' read -r date proj id msg; do
            printf "${C_CYAN}%s${C_RESET} │ ${C_YELLOW}%-22s${C_RESET} │ %.50s...\n" "$date" "$proj" "$msg"
            printf "  ${C_DIM}claude --resume %s${C_RESET}\n\n" "$id"
        done
    else
        # Pattern = full-text search (slower but accurate)
        search_fulltext "$pattern"
    fi
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: cs [keyword]       Search sessions by keyword"
            echo "       cs                 Show 10 most recent sessions"
            echo "       cs -n 20           Show 20 results"
            echo "       cs --rebuild       Force index rebuild"
            exit 0
            ;;
        --rebuild)
            build_index
            exit 0
            ;;
        -n)
            LIMIT="$2"
            shift 2
            ;;
        *)
            search "$1"
            exit 0
            ;;
    esac
done

# No args = show recent
search ""
