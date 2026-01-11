# Git Worktree Setup

Create isolated git worktrees for feature development without switching branches.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

## Process

1. **Check Existing Directories**: `.worktrees/` or `worktrees/`
2. **Verify .gitignore**: Ensure worktree dir is ignored
3. **Create Worktree**: `git worktree add`
4. **Detect Database Provider**: Check for DB branching capability
5. **Suggest Database Branch**: Remind user with exact commands
6. **Install Dependencies**: Auto-detect package manager
7. **Run Baseline Tests**: Verify clean state
8. **Report Location**: Confirm ready

## Directory Selection

### Priority Order

```bash
# 1. Check existing directories
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative

# 2. Check CLAUDE.md for preference
grep -i "worktree.*director" CLAUDE.md 2>/dev/null

# 3. Ask user if neither exists
```

**If both exist:** `.worktrees/` wins.

## Safety Verification

**For project-local directories:**

```bash
# Check if directory in .gitignore
grep -q "^\.worktrees/$" .gitignore || grep -q "^worktrees/$" .gitignore
```

**If NOT in .gitignore:**
1. Add line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents.

## Creation Steps

```bash
# 1. Detect project name
project=$(basename "$(git rev-parse --show-toplevel)")

# 2. Create worktree with new branch
git worktree add .worktrees/$BRANCH_NAME -b $BRANCH_NAME

# 3. Navigate
cd .worktrees/$BRANCH_NAME
```

## Auto-Detect Setup

```bash
# Node.js
if [ -f package.json ]; then pnpm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Baseline Verification

```bash
# Run tests to verify clean state
pnpm test        # Node.js
cargo test       # Rust
pytest           # Python
go test ./...    # Go
```

**If tests fail:** Report failures, ask whether to proceed.
**If tests pass:** Report ready.

## Final Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Database Branch Suggestion

**After worktree creation, command detects database provider and suggests isolation.**

### Quick Command Reference

| Provider | Suggested Command |
|----------|-------------------|
| **Neon** | `neonctl branches create --name <branch> --parent main` |
| **PlanetScale** | `pscale branch create <db> <branch>` |
| **Local Postgres** | `psql -c "CREATE SCHEMA <schema>;"` |
| **Other** | Manual setup or shared DB |

**Example output:**

```
✅ Worktree created at .worktrees/feature-auth

💡 DB Isolation: neonctl branches create --name feature-auth --parent main
   Then update .env with new DATABASE_URL
   Full guide: ../workflows/database-branch-setup.md
```

### .worktreeinclude Setup

**Critical for environment variables:**

```bash
# .worktreeinclude (at project root)
.env
.env.local
.env.development
**/.claude/settings.local.json
```

**Why:** Without this, `.env` files won't be copied to worktrees → Claude sessions fail.

### When to Create Database Branch

| Scenario | Create Branch? |
|----------|---------------|
| Schema migrations | ✅ Yes |
| Data model refactoring | ✅ Yes |
| Bug fix (no schema change) | ❌ No |
| Performance experiments | ✅ Yes |

**See:** [Database Branch Setup Guide](../workflows/database-branch-setup.md) for complete workflows.

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify .gitignore) |
| `worktrees/` exists | Use it (verify .gitignore) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Not in .gitignore | Add + commit immediately |
| Neon detected | Suggest `neonctl branches create` |
| PlanetScale detected | Suggest `pscale branch create` |
| No .worktreeinclude | Create with `.env` pattern |
| Tests fail | Report + ask to proceed |

## Common Mistakes

**Skipping .gitignore verification**
- Worktree contents get tracked, pollute git status

**Assuming directory location**
- Follow priority: existing > CLAUDE.md > ask

**Proceeding with failing tests**
- Can't distinguish new bugs from pre-existing

**Not copying .env to worktree**
- Symptom: Claude fails with "DATABASE_URL not found"
- Fix: Add `.env` to `.worktreeinclude`

**Using shared database for schema changes**
- Symptom: Migration conflicts, broken dev environment
- Fix: Create database branch before modifying schema

## Cleanup (After Work Complete)

```bash
# 1. Remove git worktree
git worktree remove .worktrees/$BRANCH_NAME

# Or force if uncommitted changes
git worktree remove --force .worktrees/$BRANCH_NAME

# 2. If you created a database branch, delete it
# Neon:
neonctl branches delete $BRANCH_NAME

# PlanetScale:
pscale branch delete <database-name> $BRANCH_NAME

# Local schema:
psql $DATABASE_URL -c "DROP SCHEMA ${BRANCH_NAME/\//_} CASCADE;"

# 3. Prune stale references
git worktree prune
```

## Usage

```
/git-worktree feature/auth
/git-worktree fix/session-bug
```

Branch name: $ARGUMENTS