# Production Safety Rules

> **Audience**: Teams deploying Claude Code in production environments.
> **For solo learners**: See [Getting Started](./ultimate-guide.md#1-getting-started) instead.

---

## TL;DR (30 seconds)

**6 non-negotiable rules for production teams**:

1. ✅ **Port Stability**: Never change backend/frontend ports
2. ✅ **Database Safety**: Always backup before destructive ops
3. ✅ **Feature Completeness**: Never ship half-implemented features
4. ✅ **Infrastructure Lock**: Docker/env changes require permission
5. ✅ **Dependency Safety**: No new dependencies without approval
6. ✅ **Pattern Following**: Conform to existing codebase conventions

---

## When to Use These Rules

| Project Type | Use These Rules? | Why |
|--------------|------------------|-----|
| Learning / Tutorials | ❌ No | Too restrictive for exploration |
| Solo prototypes | ❌ No | Overhead not worth it |
| Small teams (2-3), staging env | ⚠️ Partial | Rules 1, 3, 6 only |
| Production apps, multi-dev teams | ✅ Yes | All 6 rules |
| Regulated industries (HIPAA, SOC2) | ✅ Yes + add compliance rules | Critical safety |

---

## Rule 1: Port Stability

### The Problem

Changing ports breaks:
- Local development environments
- Docker Compose configurations
- Deployed service configs
- Team member setups

**Real incident**: Backend port changed from 3000 → 8080 during refactor. All developers lost a day re-configuring local envs. Staging deployment failed silently because nginx proxy still pointed to 3000.

### The Rule

**Never modify backend/frontend ports without explicit team permission.**

### Implementation

**Option A: Permission deny in `settings.json`**

```json
{
  "permissions": {
    "deny": [
      "Edit(docker-compose.yml:*ports*)",
      "Edit(package.json:*PORT*)",
      "Edit(.env.example:*PORT*)",
      "Edit(vite.config.ts:*port*)"
    ]
  }
}
```

**Option B: Pre-commit hook**

```bash
# .claude/hooks/PreToolUse.sh
if [[ "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool.input.file_path')
    CONTENT=$(echo "$INPUT" | jq -r '.tool.input.new_string')

    if [[ "$FILE" =~ (docker-compose|vite.config|package.json) ]] && \
       [[ "$CONTENT" =~ (port|PORT):[[:space:]]*[0-9] ]]; then
        echo "⚠️ BLOCKED: Port modification detected in $FILE"
        echo "Ports must remain stable across team. Request permission first."
        exit 2
    fi
fi
```

**Option C: CLAUDE.md constraint**

```markdown
## Port Configuration

**CRITICAL**: Ports are locked for team coordination.

Current ports:
- Frontend (Vite): 5173
- Backend (Express): 3000
- Database: 5432

To change ports:
1. Create RFC document in `/docs/rfcs/`
2. Get team approval (3+ reviewers)
3. Update all environments simultaneously
4. Notify team 48h in advance
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| Adding NEW service | OK (doesn't break existing) |
| Changing test env port | OK (isolated from dev/prod) |
| Port conflict on machine | Ask user to resolve locally (.env.local) |

---

## Rule 2: Database Safety

### The Problem

Accidental deletions in production = data loss.

**Real incidents**:
- `DELETE FROM users WHERE id = 123` → Forgot `WHERE` → All users deleted
- `DROP TABLE sessions` during cleanup → Production table dropped
- Migration rollback → Data loss because no backup

### The Rule

**Always backup before destructive operations.**

Destructive operations:
- `DELETE FROM` (without `LIMIT 1`)
- `DROP TABLE`
- `TRUNCATE`
- `ALTER TABLE ... DROP COLUMN`
- Database migrations that can't rollback

### Implementation

**Option A: Pre-tool hook with backup enforcement**

```bash
# .claude/hooks/PreToolUse.sh
#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool.name')

if [[ "$TOOL" == "Bash" ]]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool.input.command')

    # Detect destructive database operations
    if [[ "$COMMAND" =~ (DROP TABLE|DELETE FROM|TRUNCATE|ALTER.*DROP) ]]; then
        echo "🚨 BLOCKED: Destructive database operation detected"
        echo ""
        echo "Required steps:"
        echo "1. Create backup: pg_dump -U user dbname > backup_\$(date +%Y%m%d_%H%M%S).sql"
        echo "2. Verify backup size is reasonable"
        echo "3. Re-run after backup confirmation"
        exit 2
    fi
fi

exit 0
```

**Option B: Migration safety wrapper**

```bash
# scripts/safe-migrate.sh
#!/bin/bash
set -e

echo "🔍 Pre-migration checks..."

# 1. Check environment
if [[ "$NODE_ENV" == "production" ]]; then
    echo "❌ BLOCKED: Use migration service for production"
    exit 1
fi

# 2. Create backup
BACKUP_FILE="backups/pre-migration-$(date +%Y%m%d_%H%M%S).sql"
mkdir -p backups
pg_dump $DATABASE_URL > "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# 3. Run migration
echo "🚀 Running migration..."
npm run prisma:migrate:dev

# 4. Verify
echo "🔍 Verifying database state..."
npm run prisma:validate

echo "✅ Migration complete. Backup: $BACKUP_FILE"
```

**Option C: CLAUDE.md protocol**

```markdown
## Database Operations

### Destructive Operations Protocol

**NEVER run these without backup**:
- DELETE, DROP, TRUNCATE, ALTER...DROP

**Required steps**:
1. Announce in #dev-ops Slack channel
2. Create backup: `./scripts/backup-db.sh`
3. Verify backup: `ls -lh backups/` (should be >0 bytes)
4. Execute in staging FIRST
5. Wait 24h for issues
6. Execute in production with on-call engineer present

**Emergency rollback**:
```bash
psql $DATABASE_URL < backups/[latest].sql
```
```

### MCP Database Safety

If using MCP database servers (Postgres, MySQL, etc.):

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_URL": "postgres://readonly:***@dev-db.example.com:5432/appdb"
      },
      "comment": "READ-ONLY user for safety"
    }
  }
}
```

**Critical**: Use read-only database users for MCP. See [Data Privacy Guide](./data-privacy.md#risk-2-mcp-database-access).

---

## Rule 3: Feature Completeness

### The Problem

Claude Code sometimes "half-asses" features when context runs low:
- Deletes existing functionality instead of fixing bugs
- Adds `TODO` comments for core features
- Leaves error states unhandled
- Creates mock implementations

**Real incidents**:
- Payment validation "fixed" by removing validation entirely
- Error handling "added" with `throw new Error("Not implemented")`
- Feature "completed" with `// TODO: Add actual logic here`

### The Rule

**Never ship half-implemented features. If you start, you finish to working state.**

### Implementation

**Option A: CLAUDE.md constraint**

```markdown
## Feature Implementation Standards

### NON-NEGOTIABLE

1. **No TODOs for core functionality**
   - TODOs allowed ONLY for future enhancements
   - Core features must be complete and working

2. **No mock implementations**
   - No `throw new Error("Not implemented")`
   - No fake data generators in production code paths

3. **Complete error handling**
   - Every async call has try/catch
   - Every user input is validated
   - Every API call has timeout and retry logic

4. **Downgrade = Delete the feature entirely**
   - If you can't fix properly, remove the feature
   - Document why in commit message
   - Create issue for proper implementation

### Validation

Before accepting changes, verify:
- [ ] No `TODO` in modified files (except future enhancements)
- [ ] No `throw new Error("Not implemented")`
- [ ] No commented-out code without explanation
- [ ] All new functions have error handling
```

**Option B: Pre-commit git hook**

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Check staged files for "half-assing" patterns
STAGED=$(git diff --cached --name-only --diff-filter=ACM)

for FILE in $STAGED; do
    if [[ "$FILE" =~ \.(ts|tsx|js|jsx|py)$ ]]; then
        # Check for TODOs in core logic (not tests)
        if ! [[ "$FILE" =~ test|spec ]]; then
            if git diff --cached "$FILE" | grep -E "^\+.*TODO.*implement|^\+.*Not implemented"; then
                echo "❌ COMMIT BLOCKED: TODO/Not implemented in $FILE"
                echo "   Complete the feature or remove it entirely."
                exit 1
            fi
        fi

        # Check for mock placeholders
        if git diff --cached "$FILE" | grep -E "^\+.*(MOCK_DATA|fakeData|placeholder)"; then
            echo "⚠️ WARNING: Mock data detected in $FILE"
            echo "   Ensure this is intentional for staging/dev only."
        fi
    fi
done

exit 0
```

**Option C: Output evaluator command**

```bash
# Before committing
/validate-changes

# This runs the output-evaluator agent (see examples/agents/output-evaluator.md)
# which scores changes on:
# - Correctness (10/10)
# - Completeness (10/10)  ← Detects half-assing
# - Safety (10/10)
```

---

## Rule 4: Infrastructure Lock

### The Problem

Claude might modify infrastructure configs without understanding production implications:
- Changes Docker Compose volumes → data loss
- Modifies `.env.example` → breaks onboarding
- Updates Terraform → unintended resource changes
- Tweaks Kubernetes manifests → downtime

### The Rule

**Infrastructure modifications require explicit team permission.**

Files to protect:
- `docker-compose.yml`, `Dockerfile`
- `.env.example` (templates, NOT personal .env.local)
- `kubernetes/`, `k8s/`, `terraform/`, `helm/`
- CI/CD configs (`.github/workflows/`, `.gitlab-ci.yml`)
- Database schemas (requires migration review)

### Implementation

**Option A: Permission deny**

```json
{
  "permissions": {
    "deny": [
      "Edit(docker-compose.yml)",
      "Edit(Dockerfile)",
      "Edit(.env.example)",
      "Edit(terraform/**)",
      "Edit(kubernetes/**)",
      "Edit(.github/workflows/**)",
      "Edit(prisma/schema.prisma)"
    ]
  }
}
```

**Option B: CLAUDE.md rule**

```markdown
## Infrastructure Changes

You are **FORBIDDEN** from modifying these without explicit permission:

- `docker-compose.yml`, `Dockerfile`
- `.env.example` (template for new developers)
- `terraform/`, `kubernetes/` (infrastructure as code)
- `.github/workflows/` (CI/CD pipelines)
- `prisma/schema.prisma` (database schema)

**If infrastructure change is needed**:
1. Ask user: "This requires infrastructure change. Should I create an RFC?"
2. Create RFC document in `docs/rfcs/YYYYMMDD-<title>.md`
3. Do NOT modify files until RFC approved
```

**Note**: Personal `.env.local` files are OK to modify (they're gitignored).

---

## Rule 5: Dependency Safety

### The Problem

Adding dependencies without team approval:
- Increases bundle size (performance)
- Introduces security vulnerabilities
- Creates license compliance issues
- Adds maintenance burden

**Real incidents**:
- Added `moment.js` (200KB) when `date-fns` (tiny) already in project
- Installed `lodash` when project uses `ramda`
- Added GPL library → license violation for proprietary codebase

### The Rule

**No new dependencies without explicit approval.**

### Implementation

**Option A: Permission deny on package managers**

```json
{
  "permissions": {
    "deny": [
      "Bash(npm install *)",
      "Bash(npm i *)",
      "Bash(pnpm add *)",
      "Bash(yarn add *)",
      "Bash(pip install *)",
      "Bash(poetry add *)"
    ],
    "allow": [
      "Bash(npm install)",
      "Bash(pnpm install)",
      "Bash(pip install -r requirements.txt)"
    ]
  }
}
```

**Option B: CLAUDE.md protocol**

```markdown
## Dependency Management

### Immutable Stack Rule

**You are FORBIDDEN from adding new dependencies** (`npm install <package>`).

**If new dependency is needed**:
1. Check if existing dependency solves it:
   - Date manipulation? Use existing `date-fns`
   - HTTP requests? Use existing `axios`
   - State management? Use existing `zustand`
2. If genuinely needed, ASK:
   - "I need [package] for [reason]. Existing alternatives: [X, Y]. Should I add it?"
3. Wait for explicit approval
4. User will run: `npm install <package>` manually

**Allowed without asking**:
- `npm install` (installs existing package.json deps)
- Dev dependencies for testing (`-D` flag after approval)
```

**Option C: Pre-tool hook**

```bash
# .claude/hooks/PreToolUse.sh
if [[ "$TOOL" == "Bash" ]]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool.input.command')

    # Block dependency installation
    if [[ "$COMMAND" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+[a-zA-Z] ]]; then
        echo "🚨 BLOCKED: New dependency installation"
        echo ""
        echo "Dependencies must be approved by team lead."
        echo "Create PR with RFC explaining:"
        echo "1. Why this dependency is needed"
        echo "2. Alternatives considered"
        echo "3. Bundle size impact"
        echo "4. License compatibility"
        exit 2
    fi

    # Allow: npm install (no args), npm install -g, pnpm install
    if [[ "$COMMAND" =~ ^(npm|pnpm|yarn)[[:space:]]+install$ ]]; then
        exit 0
    fi
fi
```

---

## Rule 6: Pattern Following

### The Problem

Claude introduces new patterns inconsistent with codebase:
- Uses `class` components when project is functional React
- Imports `lodash` when project uses `ramda`
- Writes REST endpoints when project is GraphQL
- Uses `fetch` when project standardized on `axios`

### The Rule

**Conform to existing codebase conventions. Check before implementing.**

### Implementation

**Option A: CLAUDE.md conventions**

```markdown
## Code Conventions

### Tech Stack (DO NOT DEVIATE)

**Frontend**:
- React 18 with **function components + hooks** (NO class components)
- State: Zustand (NOT Redux, Context)
- HTTP: axios (NOT fetch)
- Styling: Tailwind CSS (NOT styled-components, emotion)
- Forms: React Hook Form + Zod

**Backend**:
- Node.js + Express
- Database: Prisma ORM (NOT raw SQL, TypeORM)
- Auth: JWT via jose library
- Validation: Zod schemas

**Testing**:
- Unit: Vitest (NOT Jest)
- E2E: Playwright (NOT Cypress)

### Import Patterns

**Always use**:
```typescript
import { useState } from 'react'           // ✅ Named imports
import axios from 'axios'                  // ✅ Default import
```

**Never use**:
```typescript
import React from 'react'                  // ❌ Deprecated pattern
import * as axios from 'axios'             // ❌ Namespace import
```

### File Structure

```
src/
  features/          ← Group by feature (NOT by type)
    auth/
      components/
      hooks/
      api/
  shared/            ← Shared utilities
    components/
    hooks/
```

### Design System

UI changes MUST use existing design system:
- Check `src/shared/components/` for existing components
- Use Tailwind utility classes from `tailwind.config.js`
- Colors from `colors.ts` palette ONLY
- Typography from `typography.config.js`

**Before creating new component**:
1. Search: `rg "Button" src/shared/components/`
2. If exists, use it
3. If doesn't exist, ask: "Should I create new Button component or use existing primitive?"
```

**Option B: Pre-implementation analysis**

```markdown
## Before Implementing

**ALWAYS** run these checks:

1. **Pattern check**:
```bash
# How does codebase handle X?
rg "import.*useState" src/  # Check React patterns
rg "axios\." src/           # Check HTTP patterns
rg "prisma\." src/          # Check DB patterns
```

2. **Existing components**:
```bash
# Does component already exist?
find src/shared/components -name "*Button*"
find src/shared/components -name "*Modal*"
```

3. **Ask user if unclear**:
   - "I see project uses [X]. Should I follow this pattern or use [Y]?"
```

**Option C: Automated validation**

```bash
# .claude/hooks/PostToolUse.sh
#!/bin/bash
if [[ "$TOOL" == "Write" ]] || [[ "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool.input.file_path')

    # Check for pattern violations
    if [[ "$FILE" =~ \.(tsx?)$ ]]; then
        CONTENT=$(cat "$FILE")

        # Violation: class components in React
        if echo "$CONTENT" | grep -q "class.*extends.*Component"; then
            echo "⚠️ WARNING: Class component detected in $FILE"
            echo "   Project uses function components. Consider refactoring."
        fi

        # Violation: wrong HTTP library
        if echo "$CONTENT" | grep -q "import.*fetch\|window.fetch"; then
            echo "⚠️ WARNING: fetch() detected in $FILE"
            echo "   Project uses axios. Use: import axios from 'axios'"
        fi
    fi
fi
```

---

## Integration with Existing Workflows

### With Plan Mode

```bash
# Before multi-file changes
/plan

# Claude enters read-only mode, explores codebase
# Identifies patterns, conventions, existing implementations
# Proposes plan following project conventions
# You review before execution
```

### With Git Hooks

These rules integrate with existing git workflows:

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Run safety checks
./.claude/hooks/production-safety-check.sh

# If blocked, commit fails
exit $?
```

### With CI/CD

Add validation step:

```yaml
# .github/workflows/pr-validation.yml
name: PR Validation
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check for half-assing
        run: |
          if git diff origin/main...HEAD | grep -E "TODO.*implement|Not implemented"; then
            echo "❌ PR contains incomplete features"
            exit 1
          fi

      - name: Check for unauthorized deps
        run: |
          git diff origin/main...HEAD -- package.json | grep -E '^\+.*"[^"]+": "[^"]+"' || exit 0
          echo "⚠️ New dependencies detected. Review required."
```

---

## Troubleshooting

### "These rules are too restrictive"

**Solution**: Adapt based on your team size and stage.

| Team Size | Recommended Rules |
|-----------|-------------------|
| 1-2 devs | Rules 1, 3, 6 only |
| 3-10 devs | Rules 1, 3, 5, 6 |
| 10+ devs or production | All 6 rules |

### "Claude keeps getting blocked"

**Solution**: Rules are working! Options:

1. **Grant temporary permission**:
   ```bash
   # In CLAUDE.md
   ## Temporary Override (expires 2026-01-25)
   For this feature only: infrastructure changes allowed.
   Reason: Setting up new microservice.
   ```

2. **Create exception**:
   ```json
   {
     "permissions": {
       "allow": ["Edit(docker-compose.dev.yml)"],
       "deny": ["Edit(docker-compose.prod.yml)"]
     }
   }
   ```

3. **Review if rule is appropriate**:
   - Solo dev blocking themselves? → Remove rule
   - Team needs flexibility? → Use "ask" instead of "deny"

### "How do I enforce rules across team?"

**Solution**: Commit to repo, not personal config.

```bash
# Shared team rules
/project/.claude/settings.json        # Committed
/project/CLAUDE.md                    # Committed

# Personal overrides
/project/.claude/settings.local.json  # Gitignored
/project/.claude/CLAUDE.md            # Gitignored
```

Team settings take precedence, but individuals can opt-in to stricter rules.

---

## See Also

- [Ultimate Guide §9.12 Git Best Practices](./ultimate-guide.md#912-git-best-practices--workflows) — Commit workflow, Plan → Act pattern
- [Security Hardening Guide](./security-hardening.md) — MCP security, secret protection, hook stack
- [Data Privacy Guide](./data-privacy.md) — MCP database risks, retention policies
- [Adoption Approaches](./adoption-approaches.md) — Team setup, shared conventions
- [Plan Mode](./ultimate-guide.md#25-plan-mode) — Safe exploration before execution
- [Permissions System](./ultimate-guide.md#33-settings--permissions) — Allow/deny rules, hooks

---

## Quick Reference

### Rule Severity

| Rule | Severity | Breaking this causes |
|------|----------|----------------------|
| 1. Port Stability | 🔴 Critical | Team downtime, deployment failures |
| 2. Database Safety | 🔴 Critical | Data loss, customer impact |
| 3. Feature Completeness | 🟡 High | Production bugs, tech debt |
| 4. Infrastructure Lock | 🟠 High | Downtime, security issues |
| 5. Dependency Safety | 🟡 Medium | Bundle bloat, license issues |
| 6. Pattern Following | 🟢 Low | Code inconsistency, maintenance burden |

### Enforcement Methods

| Method | Strictness | Setup Time | Best For |
|--------|------------|------------|----------|
| **Permission deny** | 100% (blocks) | 2 min | Critical rules (1, 2, 4) |
| **Pre-tool hooks** | 100% (blocks) | 10 min | Custom logic, team-specific |
| **CLAUDE.md rules** | ~70% (Claude respects) | 5 min | Conventions, guidelines |
| **Post-tool warnings** | ~30% (warns only) | 5 min | Best practices, suggestions |
| **Git hooks** | 100% (blocks commits) | 15 min | Final safety net before push |

### Common Patterns

**Allow staging changes, block production**:
```json
{
  "permissions": {
    "allow": ["Edit(docker-compose.dev.yml)"],
    "deny": ["Edit(docker-compose.prod.yml)"]
  }
}
```

**Require confirmation for sensitive ops**:
```json
{
  "permissions": {
    "ask": ["Bash(rm -rf *)", "Bash(DROP TABLE *)"]
  }
}
```

**Temporary override with expiry**:
```markdown
## Temporary Override (expires 2026-02-01)
Infrastructure changes allowed for migration project.
After expiry: revert to standard rules.
```

---

**Version**: 1.0.0
**Last Updated**: 2026-01-21
**Changelog**: Initial version based on community-validated production patterns
