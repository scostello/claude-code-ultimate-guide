# Choosing Your Adoption Approach

> **This guide is a springboard, not a destination.** Copy what serves you, ignore what doesn't.

---

## Quick Decision

| Your Context | Recommended Approach |
|--------------|---------------------|
| Time constraint (<1 day to setup) | **Turnkey** — copy minimal template, verify, ship |
| Solo developer wanting mastery | **Autonomous** — concepts first, config second |
| 4-10 developers | **Hybrid** — shared core + personal extensions |
| 10+ developers or high turnover | **Turnkey** — standardized setup + onboarding docs |

---

## Decision Tree

```
Starting Claude Code?
│
├─ Time constraint (<1 day)?
│   └─ YES → Turnkey Quickstart (below)
│   └─ NO ↓
│
├─ Need team consistency now?
│   └─ YES → Turnkey + document 3 conventions
│   └─ NO ↓
│
├─ Unique workflow or project?
│   └─ YES → Autonomous Learning Path (below)
│   └─ NO → Turnkey, customize later
```

---

## Turnkey Quickstart (15 minutes)

### Step 1: Create Minimal Config

```bash
mkdir -p .claude
```

Create `.claude/CLAUDE.md`:

```markdown
# Project: [your-project-name]

## Stack
- Runtime: [Node 20 / Python 3.11 / etc.]
- Framework: [Next.js / FastAPI / etc.]

## Commands
- Test: `npm test` or `pytest`
- Lint: `npm run lint` or `ruff check`

## Convention
- [One rule you care most about, e.g., "TypeScript strict mode required"]
```

### Step 2: Verify Setup

```bash
claude
```

Then ask:
```
What's this project's test command?
```

**Pass**: Returns your configured command.
**Fail**: CLAUDE.md not loaded — check path is `.claude/CLAUDE.md` or `./CLAUDE.md`

### Step 3: First Real Task

```bash
claude "Review the README and suggest improvements"
```

Claude should reference your stack and conventions automatically.

**Done.** Add more config only when you hit friction.

---

## Autonomous Learning Path

### Phase 1: Mental Model (2 hours)

**Goal**: Understand how Claude Code thinks before configuring.

1. Read [Section 5: Mental Model](./english-ultimate-claude-code-guide.md) (line 1675)
2. Key insight: Claude operates in a loop — prompt → plan → execute → verify
3. **Hands-on**: Complete 3 simple tasks with zero config. Note what friction you experience.

### Phase 2: Context Management (1 hour)

**Goal**: Learn the constraint that shapes all Claude Code usage.

1. Read [Context Management](./english-ultimate-claude-code-guide.md) (line 944)
2. Memorize the zones:
   - Green (0-50%): work freely
   - Yellow (50-70%): be selective
   - Orange (70-90%): `/compact` now
   - Red (90%+): `/clear` required
3. **Hands-on**: Run `/status` after every 3 prompts for one day. Learn your pattern.

### Phase 3: Memory Files (1 hour)

**Goal**: Configure Claude to know your project.

1. Read [Memory Files](./english-ultimate-claude-code-guide.md) (line 2218)
2. Understand precedence: project `.claude/CLAUDE.md` > global `~/.claude/CLAUDE.md`
3. **Hands-on**: Create minimal CLAUDE.md (see Turnkey Step 1), verify with test prompt.

### Phase 4: Extensions (as needed)

Only proceed when you identify specific friction:

| Friction | Solution | Reference |
|----------|----------|-----------|
| Same task repeated 5+ times | Create agent | [Agent Template](./english-ultimate-claude-code-guide.md) line 2793 |
| Security concern after incident | Add hook | [Hook Templates](./english-ultimate-claude-code-guide.md) line 4172 |
| Need external tool (DB, browser) | Configure MCP | [MCP Config](./english-ultimate-claude-code-guide.md) line 4771 |
| AI repeats same mistake | Add specific rule | One line in CLAUDE.md, not ten |

---

## Adoption Checkpoints

### Checkpoint 1: Base Setup (Day 1)

```bash
claude --version          # Should be ≥2.x
claude /status            # Shows project context, 0% usage
claude /mcp               # Lists MCP servers (may be empty)
```

**Pass**: All commands respond correctly.
**Fail**: Installation issue — run `claude doctor`.

### Checkpoint 2: Config Active (Week 1)

**Test**: Ask Claude "What's the test command for this project?"

**Pass**: Returns your configured command exactly.
**Fail**: CLAUDE.md not loaded or wrong path.

### Checkpoint 3: Context Awareness (Week 2)

**Metric**: You've used `/compact` when context exceeded 70%.

**Pass**: You're managing context proactively.
**Fail**: Either underusing Claude or ignoring `/status` signals.

### Checkpoint 4: First Extension (Month 1)

**Metric**: Created one agent, command, or hook that you use weekly.

**Pass**: Tool matches your actual workflow.
**Fail**: Either no repetitive patterns yet, or framework friction — revisit Phase 1.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Symptoms | Solution |
|--------------|----------|----------|
| **"Copied 500-line CLAUDE.md"** | Rules get ignored, AI responses don't improve, overhead without benefit | Start with 10 lines, add only what you actually need |
| **"Rebuilt everything from scratch"** | 2 weeks tweaking config instead of coding, reinventing existing solutions | Use templates as starting point, then adapt |
| **"Team setup without documentation"** | Everyone does it differently, no shared conventions, onboarding chaos | Document 3-5 essential conventions, not more |
| **"All features enabled Day 1"** | MCP servers unused, hooks never triggered, complexity without value | Enable features when you hit the problem they solve |

---

## Team Size Guidelines

### Solo / 2-3 Developers

**Config structure**:
```
./CLAUDE.md                    # Minimal, committed
~/.claude/CLAUDE.md            # Personal preferences (model, flags)
```

**Recommended setup**:
- 10-line project CLAUDE.md (stack, commands, 1-2 conventions)
- Personal: preferred model (`/model sonnet` vs `opus`), `--think` flag preferences
- No hooks unless you've had a security incident
- No agents unless workflow repeats 5+ times weekly

**Verification**: `claude /status` shows project name, no permission warnings.

**Risk**: Over-engineering. If your CLAUDE.md exceeds 30 lines, you're probably solo-optimizing for imaginary team problems.

### 4-10 Developers

**Config structure**:
```
./CLAUDE.md                    # Team conventions (committed)
./.claude/settings.json        # Hooks for all (committed)
~/.claude/CLAUDE.md            # Individual preferences (not committed)
```

**Recommended setup**:
- Project CLAUDE.md: stack, commands, 3-5 conventions everyone follows
- One security hook: `dangerous-actions-blocker.sh` (see examples/)
- Personal extensions allowed: model preferences, custom agents, thinking flags

**Split decisions**:
| In repo (team) | In ~/.claude (personal) |
|----------------|-------------------------|
| Test/lint commands | Model preferences |
| Error handling patterns | Custom agents for your workflow |
| Commit message format | Thinking flag defaults |

**Verification**: New team member runs `claude "What conventions should I follow?"` — answer should match team docs.

### 10+ Developers / High Turnover

**Config structure**:
```
./CLAUDE.md                    # Strict, documented, committed
./.claude/settings.json        # All hooks required, committed
./.claude/agents/              # Approved agents only, committed
./.claude/commands/            # Standardized commands, committed
~/.claude/CLAUDE.md            # Minimal personal overrides
```

**Recommended setup**:
- Documented CLAUDE.md with rationale for each rule
- Security hooks: mandatory, no exceptions
- Approved agents list: new agents require review
- Onboarding: 30-minute session covering context management (`/status`, `/compact`)

**Governance**:
```bash
# Monthly audit command
claude "Review .claude/ config against our team conventions doc"
```

**Verification**: Run `/diagnose` (if available) or manual audit quarterly.

**Risk**: Config drift. Without governance, 10 developers = 10 different setups in 3 months.

---

## Scenario Decisions

### "I'm a CTO evaluating Claude Code"

**Fast evaluation path (2 hours)**:
1. Install: `npm i -g @anthropic-ai/claude-code`
2. Run in existing project: `claude`
3. Test with real task: `claude "Analyze this codebase architecture"`
4. Use Plan Mode for safety: `Shift+Tab` twice before risky operations
5. Check cost: `/status` shows token usage

**Evaluation criteria**:
- Does Claude understand your stack without config? (baseline)
- Does it improve with minimal CLAUDE.md? (config value)
- Can your team adopt context management? (`/compact` discipline)

**Skip for now**: MCP servers, hooks, agents — evaluate core workflow first.

### "My team disagrees on configuration"

**Resolution hierarchy**:

| Layer | Who decides | What goes there |
|-------|-------------|-----------------|
| Repo CLAUDE.md | Tech lead | Stack, test commands, 3 conventions |
| Repo hooks | Security team | Dangerous action blockers |
| Personal ~/.claude | Individual | Model preferences, custom agents |

**Conflict resolution**:
- Security hooks: non-negotiable, everyone uses
- Conventions: majority vote, documented in CLAUDE.md
- Preferences: personal, never in repo config

### "Claude keeps making the same mistake"

**Don't**: Add 50 lines of rules.

**Do**: Add exactly one rule:
```markdown
## Anti-Pattern: [specific issue]
When implementing [X], NEVER [specific mistake].
Instead: [correct approach with 1-line example]
```

**Verify**: Run the exact prompt that triggered the mistake. Fixed? Keep rule. Not fixed? Rule is too vague — make it more specific.

### "I inherited a 300-line CLAUDE.md"

**Audit process**:
1. Ask Claude: `"Summarize the key conventions from CLAUDE.md"`
2. Compare summary to what team actually follows
3. Delete rules Claude doesn't reference or team doesn't follow
4. Target: under 50 lines with clear purpose for each section

**Quick test**: If you can't explain why a rule exists in 10 words, delete it.

### "When should I upgrade from Turnkey to custom?"

**Triggers for customization**:

| Signal | Action |
|--------|--------|
| Same prompt copy-pasted 5+ times | Create command |
| Security incident | Add hook immediately |
| External tool needed weekly | Configure MCP server |
| Team asks same questions | Add to CLAUDE.md FAQ section |
| Context hits 90% regularly | Review what's being loaded, use `--add-dir` selectively |

---

## Quick Reference

### Commands You'll Use Daily

| Command | When | Why |
|---------|------|-----|
| `/status` | Every 5-10 prompts | Check context percentage |
| `/compact` | Context >70% | Compress before degradation |
| `/clear` | Context >90% or confusion | Hard reset |
| `/plan` | Before risky changes | Safe exploration mode |
| `/model` | Switching task complexity | sonnet (normal), opus (hard) |

### Cost-Conscious Adoption

| Model | Cost | Use for |
|-------|------|---------|
| Haiku | $ | Simple reviews, formatting |
| Sonnet | $$ | Daily development (default) |
| Opus | $$$ | Architecture, complex debugging |

**Tip**: Start with Sonnet. Upgrade to Opus only when Sonnet demonstrably fails.

---

## Related Resources

- [Personalized Onboarding](./personalized-onboarding-prompt.md) — Interactive setup for your context
- [Setup Audit](./claude-setup-audit-prompt.md) — Diagnose existing configuration issues
- [Examples Library](./examples/README.md) — Templates to copy selectively
- [Main Guide](./english-ultimate-claude-code-guide.md) — Full reference (use line numbers from this doc)
- [Reference YAML](./claude-code-reference.yaml) — Condensed lookup for quick answers

---

*Addresses community feedback on adoption approaches. Contributions: [CONTRIBUTING.md](./CONTRIBUTING.md)*
