# Spec-First Development with Claude

> **Confidence**: Tier 2 — Validated by multiple production teams and aligns with official SDD guidance.

Define what you want in CLAUDE.md BEFORE asking Claude to build. One well-structured iteration equals 8 unstructured ones.

---

## Table of Contents

1. [TL;DR](#tldr)
2. [The Pattern](#the-pattern)
3. [CLAUDE.md Spec Templates](#claudemd-spec-templates)
4. [Step-by-Step Workflow](#step-by-step-workflow)
5. [Integration with Tools](#integration-with-tools)
6. [When to Use](#when-to-use)
7. [Anti-Patterns](#anti-patterns)
8. [See Also](#see-also)

---

## TL;DR

```
1. Write spec in CLAUDE.md
2. Claude reads spec automatically
3. Implementation follows spec exactly
4. Verify against spec
```

CLAUDE.md IS your spec file. Treat it as a contract.

---

## The Pattern

Spec-First Development inverts the typical AI coding flow:

```
Traditional:        Spec-First:
───────────         ──────────
Prompt → Code       Spec → Prompt → Code → Verify
  │                   │               │       │
  └─ Hope it's       └── Contract    └── Follows spec
     what you want        defined          └── Check against spec
```

The spec becomes the source of truth that:
- Constrains what Claude builds
- Documents decisions for the team
- Enables verification of completeness

---

## CLAUDE.md Spec Templates

### Feature Spec (Most Common)

```markdown
## Feature: [Name]

### Description
[2-3 sentences explaining the feature purpose]

### Capabilities
- MUST: [Required functionality]
- MUST: [Another requirement]
- SHOULD: [Nice to have]
- MUST NOT: [Explicit exclusions]

### Tech Stack
- Required: [lib1, lib2, lib3]
- Forbidden: [lib4, lib5]

### Acceptance Criteria
- [ ] Criterion 1: [Specific, testable condition]
- [ ] Criterion 2: [Another condition]
- [ ] Criterion 3: [Edge case handling]

### API Contract (if applicable)
- Endpoint: POST /api/[resource]
- Request: { field1: string, field2: number }
- Response: { id: string, created: timestamp }
- Errors: 400 (validation), 404 (not found), 500 (server)
```

### Architecture Spec

```markdown
## Architecture: [Component Name]

### Purpose
[Why this component exists]

### Boundaries
- Owns: [What this component is responsible for]
- Delegates to: [What other components handle]
- Does NOT: [Explicit non-responsibilities]

### Dependencies
- Upstream: [Components that call this]
- Downstream: [Components this calls]

### Data Flow
```
Input → Validation → Processing → Output
         │              │
         └─ Errors ─────┘
```

### Constraints
- Performance: [Response time, throughput]
- Security: [Auth requirements, data handling]
- Scalability: [Expected load, limits]
```

### API Spec

```markdown
## API: [Endpoint Name]

### Endpoint
`POST /api/v1/[resource]`

### Authentication
Bearer token required. Scopes: `read:resource`, `write:resource`

### Request
```json
{
  "field1": "string (required, max 255 chars)",
  "field2": "number (optional, default: 0)",
  "nested": {
    "subfield": "boolean"
  }
}
```

### Response
```json
{
  "id": "uuid",
  "created_at": "ISO 8601 timestamp",
  "data": { ... }
}
```

### Error Codes
| Code | Meaning | Response Body |
|------|---------|---------------|
| 400 | Validation failed | `{ "errors": [...] }` |
| 401 | Not authenticated | `{ "message": "..." }` |
| 403 | Not authorized | `{ "message": "..." }` |
| 404 | Resource not found | `{ "message": "..." }` |
```

---

## Step-by-Step Workflow

### Step 1: Write the Spec

Before any implementation request, add spec to CLAUDE.md:

```markdown
## Feature: User Authentication

### Capabilities
- MUST: Email/password login
- MUST: JWT token generation
- MUST: Password hashing with bcrypt
- SHOULD: Remember me functionality
- MUST NOT: Store plain text passwords

### Tech Stack
- Required: bcrypt, jsonwebtoken
- Forbidden: passport.js (too heavy for this use case)

### Acceptance Criteria
- [ ] User can login with valid credentials
- [ ] Invalid credentials return 401
- [ ] Token expires after 24h (or 7d with remember me)
- [ ] Passwords hashed with cost factor 12
```

### Step 2: Reference Spec in Prompt

```
Implement the User Authentication feature as specified in CLAUDE.md.
Follow the acceptance criteria exactly.
```

Claude automatically reads CLAUDE.md and follows the spec.

### Step 3: Verify Against Spec

After implementation, verify:

```
Review the implementation against the User Authentication spec.
Check off each acceptance criterion that's satisfied.
List any gaps.
```

### Step 4: Update Spec if Needed

If requirements change during implementation:

```
Update the User Authentication spec to include:
- MUST: Rate limiting (5 attempts per minute)
Then implement the rate limiting.
```

---

## Integration with Tools

### With Spec Kit (Greenfield)

```bash
# Install Spec Kit
npx @anthropic/spec-kit init

# Use slash commands
/speckit.constitution  # Define project guardrails
/speckit.specify       # Write feature specs
/speckit.plan          # Create implementation plan
/speckit.implement     # Build from spec
```

### With OpenSpec (Brownfield)

```bash
# Install OpenSpec
npm install -g @fission-ai/openspec@latest
openspec init

# Use slash commands
/openspec:proposal "Add dark mode"  # Create change proposal
/openspec:apply add-dark-mode       # Implement changes
/openspec:archive add-dark-mode     # Merge to specs
```

### With /plan Mode

```
/plan

I need to implement the Payment Processing feature.
Review the spec in CLAUDE.md and create an implementation plan.
```

---

## When to Use

### Use Spec-First

| Scenario | Why |
|----------|-----|
| New features | Define before building |
| API design | Contract must be explicit |
| Architecture decisions | Document constraints |
| Team collaboration | Shared understanding |
| Complex requirements | Reduce ambiguity |

### Skip Spec-First

| Scenario | Why |
|----------|-----|
| Quick fixes | Overhead not worth it |
| Exploration | Don't know what you want yet |
| Prototyping | Requirements will change |
| Single-line changes | Obvious intent |

---

## Anti-Patterns

### Vague Specs

```markdown
# Wrong
## Feature: User Management
- Handle users

# Right
## Feature: User Management
### Capabilities
- MUST: Create user with email, password, name
- MUST: Update user profile (name, avatar)
- MUST: Soft delete (mark as inactive, don't remove data)
- MUST NOT: Allow duplicate emails
```

### Spec After Code

```
# Wrong workflow
1. Ask Claude to implement feature
2. Write spec documenting what was built

# Right workflow
1. Write spec defining what should be built
2. Ask Claude to implement from spec
```

### Ignoring Forbidden

```markdown
# Don't forget exclusions
### Tech Stack
- Required: React, TypeScript
- Forbidden: jQuery, vanilla JS, class components
             ↑ These constraints prevent drift
```

---

## See Also

- [../methodologies.md](../methodologies.md) — SDD and other methodologies
- [Spec Kit Documentation](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [OpenSpec Documentation](https://github.com/Fission-AI/OpenSpec)
- [tdd-with-claude.md](./tdd-with-claude.md) — Combine with TDD
