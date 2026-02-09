# Agent Teams Workflow

> **Multi-agent parallel coordination for complex tasks**
> **Status**: Experimental (v2.1.32+) | **Model**: Opus 4.6+ required | **Flag**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

**What**: Multiple Claude instances work in parallel on a shared codebase, coordinating autonomously without active human intervention. One session acts as team lead to break down tasks and synthesize findings from teammates.

**When introduced**: v2.1.32 (2026-02-05) as research preview
**Reading time**: ~30 min
**Prerequisites**: Opus 4.6 model, understanding of [Sub-Agents](../ultimate-guide.md#sub-agents), familiarity with [Task Tool](../ultimate-guide.md#task-tool)

**🚀 Want to get started fast?** See **[Agent Teams Quick Start Guide](./agent-teams-quick-start.md)** (8-10 min, copy-paste patterns for your projects)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture Deep-Dive](#2-architecture-deep-dive)
3. [Setup & Configuration](#3-setup--configuration)
4. [Production Use Cases](#4-production-use-cases)
5. [Workflow Impact Analysis](#5-workflow-impact-analysis)
6. [Limitations & Gotchas](#6-limitations--gotchas)
7. [Decision Framework](#7-decision-framework)
8. [Best Practices](#8-best-practices)
9. [Troubleshooting](#9-troubleshooting)
10. [Sources](#10-sources)

---

## 1. Overview

### What Are Agent Teams?

Agent teams enable **multiple Claude instances to work in parallel** on different subtasks while coordinating through a git-based system. Unlike manual multi-instance workflows where you orchestrate separate Claude sessions yourself, agent teams provide built-in coordination where agents claim tasks, merge changes continuously, and resolve conflicts automatically.

**Key characteristics**:
- ✅ **Autonomous coordination** — Team lead delegates, teammates communicate via mailbox
- ✅ **Peer-to-peer messaging** — Direct communication between agents (not just hierarchical)
- ✅ **Git-based locking** — Agents claim tasks by writing to shared directory
- ✅ **Continuous merge** — Changes pulled/pushed without manual intervention
- ✅ **Independent context** — Each agent has own 1M token context window (isolated)
- ⚠️ **Experimental** — Research preview, stability not guaranteed
- ⚠️ **Token-intensive** — Multiple simultaneous model calls = high cost

### When Introduced

**Version**: v2.1.32 (2026-02-05)
**Model**: Opus 4.6 minimum
**Status**: Research preview (experimental feature flag required)

**Official announcement**:
> "We've introduced agent teams in Claude Code as a research preview. You can now spin up multiple agents that work in parallel as a team and coordinate autonomously on shared codebases."
> — [Anthropic, Introducing Claude Opus 4.6](https://www.anthropic.com/news/claude-opus-4-6)

> **📝 Documentation Update (2026-02-09)**: Architecture section corrected based on [Addy Osmani's research](https://addyosmani.com/blog/claude-code-agent-teams/). Key clarification: Agents communicate via **peer-to-peer messaging** through a mailbox system, not only through team lead synthesis. Context windows remain isolated (1M tokens per agent), but explicit messaging enables direct coordination between teammates.

### Agent Teams vs Other Patterns

| Pattern | Coordination | Setup | Best For |
|---------|--------------|-------|----------|
| **Agent Teams** | Automatic (built-in) | Experimental flag | Complex read-heavy tasks requiring coordination |
| **Multi-Instance** | Manual (human orchestration) | Multiple terminals | Independent parallel tasks, no coordination needed |
| **Dual-Instance** | Manual (human oversight) | 2 terminals | Quality assurance, plan-execute separation |
| **Task Tool** | Automatic (sub-agents) | Native feature | Single-agent task delegation, sequential work |

**Key distinction**:
- **Multi-Instance** = You manage coordination (separate projects, no shared state)
- **Agent Teams** = Claude manages coordination (shared codebase, git-based communication)

---

## 2. Architecture Deep-Dive

### Lead-Teammate Architecture

```
┌─────────────────────────────────────────────────┐
│         Team Lead (Main Session)                │
│  - Breaks tasks into subtasks                   │
│  - Spawns teammate sessions                     │
│  - Synthesizes findings from all agents         │
│  - Coordinates via shared task list + mailbox   │
└─────────────────┬───────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌───────▼────────┐
│  Teammate 1    │◄─┼────────────────►│  Teammate 2    │
│                │  │ Peer-to-peer    │                │
│ - Own context  │  │ messaging via   │ - Own context  │
│   (1M tokens)  │  │ mailbox system  │   (1M tokens)  │
│ - Claims tasks │  │                 │ - Claims tasks │
│ - Messages     │  │                 │ - Messages     │
│   team/peers   │  │                 │   team/peers   │
└────────────────┘  └─────────────────┘────────────────┘
```

### Git-Based Coordination

**How it works**:

1. **Task claiming**: Agents write lock files to shared directory (`.claude/tasks/`)
2. **Work execution**: Each agent works independently in its context
3. **Continuous merge**: Agents pull/push changes to shared git repository
4. **Conflict resolution**: Automatic merge (with limitations, see [§6](#6-limitations--gotchas))
5. **Result synthesis**: Team lead collects findings and presents unified response

**Example lock file structure**:
```
.claude/tasks/
├── task-1.lock        # Agent A claimed
├── task-2.lock        # Agent B claimed
└── task-3.pending     # Not yet claimed
```

### Communication Architecture

**Key distinction from sub-agents**: Agent teams implement **true peer-to-peer messaging** via a mailbox system, not just hierarchical reporting.

**Architecture components** (Source: [Addy Osmani](https://addyosmani.com/blog/claude-code-agent-teams/), Feb 2026):

1. **Team lead**: Creates team, spawns teammates, coordinates work
2. **Teammates**: Independent Claude Code instances with own context (1M tokens each)
3. **Task list**: Shared work items with dependency tracking and auto-unblocking
4. **Mailbox**: Inbox-based messaging system enabling direct communication between agents

**Communication patterns**:
- **Lead → Teammate**: Direct messages or broadcasts to all
- **Teammate → Lead**: Progress updates, questions, findings
- **Teammate ↔ Teammate**: Direct peer-to-peer messaging (challenge approaches, debate solutions)
- **Final synthesis**: Team lead aggregates all findings for user

**Example messaging flow**:
```
Team Lead: "Review this PR for security issues"
├─ Teammate 1 (Security): Analyzes → Messages Teammate 2: "Found auth issue in line 45"
├─ Teammate 2 (Code Quality): Reviews → Messages back: "Confirmed, also see OWASP violation"
└─ Team Lead: Synthesizes findings → Presents unified response to user
```

**What this enables**:
- ✅ Agents actively challenge each other's approaches
- ✅ Debate solutions without human intervention
- ✅ Coordinate independently (self-organization)
- ✅ Share discoveries mid-workflow (via messages, not context)

**Limitation**: Context isolation remains—agents don't share their full context window, only explicit messages.

### Navigation Between Agents

**Built-in navigation**:
- **Shift+Up/Down**: Switch between sub-agents in Claude Code interface
- **tmux**: Use tmux commands if running in tmux session
- **Direct takeover**: You can take control of any agent's work when needed

**Example**:
```bash
# Terminal 1: Team lead
claude --experimental-agent-teams

# Claude spawns teammates automatically
# You can navigate with Shift+Up/Down to inspect each agent
```

### Context Management

**Per-agent context**:
- Each agent has **1M token context window** (Opus 4.6)
- ~30,000 lines of code per session
- **Context isolation**: Agents don't share their full context window
- **Communication**: Via mailbox system (peer-to-peer + team lead synthesis)

**Total context capacity** (3 agents example):
- Team lead: 1M tokens
- Teammate 1: 1M tokens
- Teammate 2: 1M tokens
- **Total**: 3M tokens across team (context isolated, but communicating via messages)

**Important distinction**:
- ❌ **Context NOT shared**: Agent 1's full 1M token context invisible to Agent 2
- ✅ **Messages ARE shared**: Agents send explicit messages via mailbox (findings, questions, debates)

---

## 3. Setup & Configuration

### Prerequisites

**Required**:
- ✅ Claude Code v2.1.32 or later
- ✅ Opus 4.6 model (`/model opus`)
- ✅ Git repository (for coordination)

**Recommended**:
- ✅ Understanding of [Sub-Agents](../ultimate-guide.md#sub-agents)
- ✅ Familiarity with git workflows
- ✅ Budget awareness (token-intensive feature)

### Method 1: Environment Variable

**Simplest approach** — Set env var before starting Claude Code:

```bash
# Enable agent teams for this session
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Start Claude Code
claude
```

**Persistent setup** (bash/zsh):
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> ~/.bashrc
source ~/.bashrc
```

### Method 2: Settings File

**Persistent configuration** — Edit `~/.claude/settings.json`:

```json
{
  "experimental": {
    "agentTeams": true
  }
}
```

**Advantages**:
- ✅ Persistent across sessions
- ✅ No need to remember env var
- ✅ Can be version-controlled in dotfiles

**After editing**, restart Claude Code for changes to take effect.

### Verification

**Check if enabled**:

```bash
# In Claude Code session
> Are agent teams enabled?
```

Claude should confirm:
> "Yes, agent teams are enabled (experimental feature). I can spawn multiple agents to work in parallel when appropriate."

**Alternative verification** (check settings):
```bash
cat ~/.claude/settings.json | grep agentTeams
```

### Multi-Terminal Setup

**Pattern** (from practitioner reports):

```bash
# Terminal 1: Research + bugfix
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude --session research-bugfix

# Terminal 2: Business ops
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude --session business-ops

# Terminal 3: Infrastructure
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
claude --session infra-setup
```

**Benefits**:
- Isolation of contexts (research vs execution vs setup)
- Parallel progress on independent workstreams
- Reduced context switching cognitive load

**Note**: This is different from automatic teammate spawning — here you're manually creating multiple team lead sessions. Each can spawn its own teammates.

---

## 4. Production Use Cases

### Overview of Validated Cases

| Use Case | Source | Metrics | Best For |
|----------|--------|---------|----------|
| **Multi-layer code review** | Fountain (Anthropic Report) | 50% faster screening | Security + API + Frontend simultaneous review |
| **Full dev lifecycle** | CRED (Anthropic Report) | 2x execution speed | 15M users, financial services compliance |
| **Autonomous C compiler** | Anthropic Research | Project completion | Complex multi-phase projects |
| **Job search app** | Paul Rayner (LinkedIn) | "Pretty impressive" | Design research + bug fixing |
| **Business ops automation** | Paul Rayner (LinkedIn) | N/A | Operating system + conference planning |

### 4.1 Multi-Layer Code Review (Fountain)

**Organization**: Fountain (frontline workforce management platform)
**Challenge**: Comprehensive codebase review across multiple concerns (security, API design, frontend)
**Solution**: Deployed hierarchical multi-agent orchestration with scope-focused sub-agents

**Agent scopes** (Fountain's approach):
- **Scope 1 (Security)**: Scan for vulnerabilities, auth issues, data exposure
- **Scope 2 (API)**: Review endpoint design, request/response validation, error handling
- **Scope 3 (Frontend)**: Check UI patterns, accessibility, performance

**Results**:
- ✅ **50% faster** candidate screening
- ✅ **40% quicker** onboarding
- ✅ **2x candidate conversions**

**Why it worked**:
- **Read-heavy task**: Code review = primarily reading/analyzing (no write conflicts)
- **Clear domain separation**: Security, API, Frontend have minimal overlap
- **Independent analysis**: Each agent can work without waiting for others

**Example prompt** (team lead):
```
Review this PR comprehensively with scope-focused analysis:
- Security Scope: Check for vulnerabilities and auth issues (context: auth code, input validation)
- API Design Scope: Review endpoint design and error handling (context: API routes, controllers)
- Frontend Scope: Check UI patterns and accessibility (context: components, styles)

PR: https://github.com/company/repo/pull/123
```

**Source**: [2026 Agentic Coding Trends Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf), Anthropic, Jan 2026

### 4.2 Full Development Lifecycle (CRED)

**Organization**: CRED (15M+ users, financial services, India)
**Challenge**: Accelerate delivery while maintaining quality standards essential for financial services
**Solution**: Implemented Claude Code across entire development lifecycle with agent teams for complex tasks

**Results**:
- ✅ **2x execution speed** across development lifecycle
- ✅ Maintained compliance (financial services standards)
- ✅ Quality assurance preserved

**Why it worked**:
- **Large codebase**: 15M users = complex system requiring parallel analysis
- **Quality critical**: Financial services = need multiple validation layers
- **Tight deadlines**: Speed requirement justified token cost

**Workflow pattern**:
1. **Planning phase**: Team lead breaks down feature
2. **Implementation**: Teammate 1 = backend, Teammate 2 = frontend, Teammate 3 = tests
3. **Quality assurance**: Team lead synthesizes + runs validation
4. **Compliance check**: Final review against financial standards

**Source**: [2026 Agentic Coding Trends Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf), Anthropic, Jan 2026

### 4.3 Autonomous C Compiler (Anthropic Research)

**Project**: Build an entire C compiler autonomously
**Challenge**: Multi-phase project (lexer, parser, AST, code generation, optimization) requiring coordination
**Solution**: Agent teams with task decomposition and progress tracking

**Phases completed**:
1. **Lexer**: Tokenization logic
2. **Parser**: Syntax tree construction
3. **AST**: Abstract syntax tree implementation
4. **Code generation**: Assembly output
5. **Optimization**: Performance improvements
6. **Testing**: Compiler test suite

**Results**:
- ✅ **Project completed** without human intervention
- ✅ All phases coordinated successfully
- ✅ Tests passing at completion

**Why it worked**:
- **Clear phases**: Each compiler phase is well-defined (lexer → parser → codegen)
- **Minimal dependencies**: Phases have clear interfaces (tokens → AST → assembly)
- **Testable milestones**: Each phase verifiable independently

**Architecture insight**:
> "Individual agents break the project into small pieces, track progress, and determine next steps until completion."
> — [Building a C compiler with agent teams](https://www.anthropic.com/engineering/building-c-compiler), Anthropic Engineering, Feb 2026

**Key learnings**:
- ⚠️ **Tests passing ≠ correctness**: Human oversight still important for quality assurance
- ⚠️ **Verification required**: Automated success doesn't guarantee error-free code
- ✅ **Feasibility proven**: Complex multi-phase projects achievable with agent teams

**Source**: [Building a C compiler with agent teams](https://www.anthropic.com/engineering/building-c-compiler), Anthropic Engineering, Feb 2026

### 4.4 Job Search App Development (Paul Rayner)

**Practitioner**: Paul Rayner (CEO Virtual Genius, EventStorming Handbook author, Explore DDD founder)
**Setup**: 3 concurrent agent team sessions across separate terminals
**Date**: Feb 2026 (v2.1.32 release day)

**Workflow 1 - Job Search App**:
- **Context**: Custom job search application development
- **Tasks**:
  - Design options research (explore UI/UX patterns)
  - Bug fixing in existing codebase
- **Pattern**: Research + execution in same workflow

**Workflow 2 - Business Operations**:
- **Context**: Operating system development + conference planning
- **Tasks**:
  - Business operating system automation
  - Conference planning resources (Explore DDD)
- **Pattern**: Multi-domain business tooling

**Workflow 3 - Infrastructure + Framework**:
- **Context**: Testing infrastructure + framework integration
- **Tasks**:
  - Playwright MCP instances setup
  - Beads framework management (Steve Yegge)
- **Pattern**: Infrastructure + framework coordination

**Results**:
- ✅ "Pretty impressive" (subjective, no metrics)
- ✅ Better than previous multi-terminal workflows without coordination
- ✅ 3 independent contexts running simultaneously

**Why notable**:
- **Real-world validation**: Production usage by experienced practitioner
- **Multi-context**: 3 different domains (product, business, infra) simultaneously
- **Early adoption**: Posted same day as v2.1.32 release (early adopter signal)

**Open question raised**:
> "I'm not sure about Claude's guidance on when to use beads versus agent team sessions. Any thoughts?"
> — Paul Rayner, LinkedIn, Feb 2026

**Source**: [Paul Rayner LinkedIn](https://www.linkedin.com/posts/thepaulrayner_this-is-wild-i-just-upgraded-claude-code-activity-7425635159678414850-MNyv), Feb 2026

### 4.5 Parallel Hypothesis Testing (Pattern)

**Scenario**: Debugging a complex production issue with multiple potential root causes

**Setup**:
```
Team lead prompt:
"Production API is slow. Test these hypotheses in parallel:
- Hypothesis 1 (DB): Query performance issue
- Hypothesis 2 (Network): Latency spikes
- Hypothesis 3 (Cache): Invalidation problem
Each agent: profile, reproduce, report findings"
```

**Agent assignments**:
- **Agent 1**: Database profiling (slow query log, explain plans)
- **Agent 2**: Network analysis (latency metrics, trace routes)
- **Agent 3**: Cache behavior (hit rates, invalidation patterns)

**Benefits**:
- ✅ **Parallel investigation**: 3 hypotheses tested simultaneously (vs sequential)
- ✅ **Time savings**: 1/3 of sequential debugging time
- ✅ **Comprehensive**: No hypothesis ignored due to time constraints

**When to use**:
- Multiple plausible explanations for observed behavior
- Each hypothesis testable independently
- Time-critical debugging (production issues)

### 4.6 Large-Scale Refactoring (Pattern)

**Scenario**: Refactor authentication system across 47 files (frontend + backend + tests)

**Setup**:
```
Team lead prompt:
"Refactor auth system from JWT to OAuth2:
- Agent 1: Backend endpoints (/api/auth/*)
- Agent 2: Frontend components (src/components/auth/*)
- Agent 3: Integration tests (tests/auth/)
Coordinate changes via shared interfaces"
```

**Agent assignments**:
- **Agent 1**: Backend implementation (15 files)
- **Agent 2**: Frontend UI update (20 files)
- **Agent 3**: Test suite update (12 files)

**Benefits**:
- ✅ **Context preservation**: All 47 files in one coordinated session (vs losing context after ~15)
- ✅ **Interface consistency**: Shared contracts enforced across agents
- ✅ **Atomic migration**: All layers updated in coordination

**Gotcha**:
- ⚠️ **Merge conflicts**: If agents modify same files (e.g., shared types)
- ⚠️ **Mitigation**: Clear interface boundaries, minimize shared file modifications

---

## 5. Workflow Impact Analysis

### Before/After Comparison

**Context**: What changes when using agent teams vs single-agent sessions?

| Task | Single Agent (Before) | Agent Teams (After) |
|------|-----------------------|---------------------|
| **Bug tracing** | Feed files one by one, re-explain architecture each time | See entire codebase at once, trace full data flow across all layers |
| **Code review** | Manually summarize PR yourself, explain context in prompt | Feed entire diff + surrounding code, agents read directly |
| **New feature** | Describe codebase structure in prompt (limited by your understanding) | Let agents read codebase directly, discover patterns themselves |
| **Refactoring** | Lose context after ~15 files, split into multiple sessions | All 47+ files live in one coordinated session |
| **Multi-service debugging** | Debug one service at a time, manually track cross-service flows | Parallel investigation across all involved services |

**Source**: [Claude Opus 4.6 for Developers](https://dev.to/thegdsks/claude-opus-46-for-developers-agent-teams-1m-context-and-what-actually-matters-4h8c), dev.to, Feb 2026

### Context Management Improvements

**Single agent limitations**:
- ~15 files before context management becomes challenging
- Manual summarization required for large codebases
- Sequential analysis of independent components

**Agent teams capabilities**:
- **1M tokens per agent** = ~30,000 lines of code
- **3 agents** = effectively 90,000 lines across team (isolated contexts)
- **Parallel reading**: Agents consume codebase sections simultaneously
- **Synthesis**: Team lead combines findings without context loss

**Example**:
```
Scenario: Analyze 28,000-line TypeScript service

Single agent:
- Read files sequentially
- Context pressure at ~15 files
- Manual summarization
- ~2-3 hours

Agent teams:
- Agent 1: Controllers layer (10K lines)
- Agent 2: Services layer (10K lines)
- Agent 3: Data layer (8K lines)
- Team lead: Synthesize architecture
- ~45 minutes
```

### Coordination Benefits

**Built-in vs manual coordination**:

| Aspect | Manual Multi-Instance | Agent Teams |
|--------|----------------------|-------------|
| **Task delegation** | You decide splits | Team lead decides |
| **Progress tracking** | Manual check-ins | Automatic reporting |
| **Merge conflicts** | You resolve | Automatic (with limitations) |
| **Context sharing** | Copy-paste findings | Git-based coordination |
| **Cognitive load** | High (orchestrator role) | Low (observer role) |

**When coordination matters**:
- ✅ Tasks with dependencies (Feature A needs API from Feature B)
- ✅ Shared interfaces (multiple agents modify same contract)
- ✅ Quality gates (all agents must pass before merge)

**When coordination unnecessary**:
- ❌ Completely independent tasks (separate projects)
- ❌ No shared state (different repositories)
- ❌ Simple parallelization (run same script on different data)

### Cost Trade-offs

**Token consumption comparison** (estimated):

| Workflow | Single Agent | Agent Teams (3) | Multiplier |
|----------|-------------|-----------------|------------|
| **Code review (small PR)** | 10K tokens | 25K tokens | 2.5x |
| **Code review (large PR)** | 50K tokens | 90K tokens | 1.8x |
| **Bug investigation** | 30K tokens | 70K tokens | 2.3x |
| **Feature implementation** | 100K tokens | 200K tokens | 2x |
| **Refactoring (large)** | 150K tokens | 250K tokens | 1.7x |

**Cost justification scenarios**:
- ✅ **Time-critical**: Production issues requiring fast resolution
- ✅ **Complexity**: Multi-layer analysis (security + performance + architecture)
- ✅ **Quality**: High-stakes changes requiring multiple verification layers
- ❌ **Simple tasks**: Straightforward implementations (overkill)
- ❌ **Budget-constrained**: Personal projects with tight token limits

**Rule of thumb**: Agent teams justified when time saved > 2x token cost increase.

---

## 6. Limitations & Gotchas

### Read-Heavy vs Write-Heavy Trade-off

**Core limitation**: Agent teams excel at read-heavy tasks but struggle with write-heavy tasks where multiple agents modify the same files.

**Why this matters**:
```
Read-heavy (✅ Good for teams):
- Code review: Agents read code, provide analysis
- Bug tracing: Agents read logs, trace execution
- Architecture analysis: Agents read structure, identify patterns

Write-heavy (⚠️ Risky for teams):
- Refactoring shared types: Multiple agents modify same file → merge conflicts
- Database schema changes: Coordinated migrations across files
- API contract updates: Interface changes require synchronization
```

**Mitigation strategies**:
1. **Clear boundaries**: Assign non-overlapping file sets to agents
2. **Interface-first**: Define contracts before parallel implementation
3. **Single-writer pattern**: One agent writes shared files, others read only
4. **Human review**: Manually resolve merge conflicts when they occur

### Merge Conflict Scenarios

**Automatic resolution works**:
- ✅ Different files modified by different agents
- ✅ Different functions in same file (clean git merges)
- ✅ Additive changes (new functions, no edits)

**Automatic resolution struggles**:
- ❌ Same lines modified (classic merge conflict)
- ❌ Conflicting logic (Agent A removes validation, Agent B adds it)
- ❌ Circular dependencies (Agent A needs Agent B's output, vice versa)

**Example conflict**:
```typescript
// Agent 1 changes:
function processUser(user: User) {
  validateEmail(user.email); // Added validation
  return save(user);
}

// Agent 2 changes (same time):
function processUser(user: User) {
  return save(sanitize(user)); // Added sanitization
}

// Conflict: Both modified same function
// Resolution: Human decides order (validate → sanitize → save)
```

### Token Intensity Implications

**Why token-intensive**:
- Each agent runs **separate model inference** (3 agents = 3x base cost)
- Context loading for each agent (1M tokens × 3 = 3M token capacity)
- Coordination overhead (team lead synthesis)

**Budget impact example** (Opus 4.6 pricing):
```
Single agent session:
- Input: 50K tokens @ $15/M = $0.75
- Output: 5K tokens @ $75/M = $0.38
- Total: $1.13

Agent teams (3 agents):
- Input: 150K tokens @ $15/M = $2.25
- Output: 15K tokens @ $75/M = $1.13
- Total: $3.38

Cost multiplier: 3x
```

**Justification required**:
- ✅ Time saved > cost increase (production issues)
- ✅ Quality critical (financial services, healthcare)
- ✅ Complexity justifies parallelization (multi-layer analysis)
- ❌ Simple tasks (use single agent)
- ❌ Personal learning projects (budget-constrained)

### Experimental Status Caveats

**What "experimental" means**:
- ⚠️ **No stability guarantee**: Feature may change or be removed
- ⚠️ **Bugs expected**: Report issues to Anthropic (GitHub Issues)
- ⚠️ **Performance variability**: Coordination speed may fluctuate
- ⚠️ **Documentation evolving**: Official docs still minimal

**Production usage considerations**:
1. **Fallback plan**: Be ready to revert to single-agent if issues arise
2. **Monitoring**: Track token costs carefully (can escalate quickly)
3. **Validation**: Human review of agent team outputs (don't trust blindly)
4. **Feedback**: Report bugs/experiences to help Anthropic improve feature

**Practitioner reports** (as of Feb 2026):
- ✅ Paul Rayner: "Pretty impressive" (production usage validated)
- ✅ Fountain: 50% faster (deployed in production)
- ✅ CRED: 2x speed (15M users, financial services)
- ⚠️ Community: Mixed reports (some merge conflict issues)

### Context Isolation

**What agents can't do**:
- ❌ **Share context windows**: Agent 1's full context (1M tokens) not visible to Agent 2
- ❌ **Auto-sync discoveries**: Agent 2 won't see Agent 1's findings unless explicitly messaged
- ❌ **Coordinate timing**: Agents work independently, may finish at different times

**What agents CAN do**:
- ✅ **Send messages**: Via mailbox system (peer-to-peer or via team lead)
- ✅ **Challenge approaches**: Debate solutions, ask questions to each other
- ✅ **Share findings**: Explicit messaging (not automatic context sharing)

**Implications**:
```
Scenario: Agent 1 discovers critical bug that affects Agent 2's work

Without messaging:
- Agent 2 doesn't see Agent 1's discovery automatically
- Agent 2 may continue with flawed assumption

With messaging (built-in):
- Agent 1 messages Agent 2: "Found auth issue in line 45"
- Agent 2 adjusts approach based on message
- Team lead synthesizes all findings at end

Mitigation:
- Agents can message each other via mailbox system
- Team lead synthesizes findings after all agents complete
- Human can interrupt and redirect agents mid-workflow (Shift+Up/Down)
- Design tasks with minimal inter-agent dependencies
```

### When NOT to Use Agent Teams

**Single agent is better for**:
- ❌ **Simple tasks**: Straightforward implementations (overkill)
- ❌ **Small codebases**: <5 files affected (coordination overhead not justified)
- ❌ **Write-heavy tasks**: Lots of shared file modifications (merge conflict risk)
- ❌ **Sequential dependencies**: Task B requires Task A completion (no parallelization benefit)
- ❌ **Budget constraints**: Personal projects, learning (token cost multiplier)
- ❌ **Tight interdependencies**: Circular dependencies between tasks

**Example of poor fit**:
```
Task: Update authentication logic in shared auth.ts file

Why single agent better:
- One file modified (no parallelization benefit)
- Write-heavy (multiple changes to same file)
- No clear subtask boundaries (logic intertwined)
- Sequential flow (test after each change)

Result: Agent teams would create merge conflicts, no time savings
```

---

## 7. Decision Framework

### Teams vs Multi-Instance vs Dual-Instance

**Comparison table**:

| Criterion | Agent Teams | Multi-Instance | Dual-Instance |
|-----------|-------------|----------------|---------------|
| **Coordination** | Automatic (git-based + mailbox) | Manual (human) | Manual (human) |
| **Setup** | Experimental flag | Multiple terminals | 2 terminals |
| **Best for** | Read-heavy tasks needing coordination | Independent parallel tasks | Quality assurance (plan-execute split) |
| **Communication** | Peer-to-peer messaging + team lead synthesis | Manual copy-paste | Manual synchronization |
| **Context sharing** | Isolated (1M per agent, no auto-sync) | Isolated (separate sessions) | Isolated (2 sessions) |
| **Cost** | High (3x+ tokens) | Medium (2x tokens) | Medium (2x tokens) |
| **Cognitive load** | Low (observer) | High (orchestrator) | Medium (reviewer) |
| **Merge conflicts** | Automatic resolution (limited) | N/A (separate repos) | Manual resolution |
| **Maturity** | Experimental (v2.1.32+) | Stable | Stable |

### Decision Tree: When to Use Agent Teams

```
Start
  │
  ├─ Task is simple (<5 files)? ──YES──> Single agent
  │
  ├─ NO
  │
  ├─ Tasks completely independent? ──YES──> Multi-Instance
  │
  ├─ NO
  │
  ├─ Need quality assurance split? ──YES──> Dual-Instance
  │
  ├─ NO
  │
  ├─ Read-heavy (analysis, review)? ──YES──> Agent Teams ✓
  │
  ├─ NO
  │
  ├─ Write-heavy (many file mods)? ──YES──> Single agent
  │
  ├─ NO
  │
  ├─ Budget-constrained? ──YES──> Single agent
  │
  ├─ NO
  │
  └─ Complex coordination needed? ──YES──> Agent Teams ✓
                                   ──NO──> Single agent
```

### Use Case Mapping

**Agent Teams (✅ Use)**:
- Multi-layer code review (security + API + frontend)
- Parallel hypothesis testing (debugging)
- Large-scale refactoring (clear boundaries)
- Full codebase analysis (architecture review)
- Complex feature research (explore multiple approaches)

**Multi-Instance (✅ Use)**:
- Separate projects (frontend repo + backend repo)
- Independent features (no shared state)
- Different technologies (Python microservice + React app)
- Parallel experimentation (try 3 different architectures)

**Dual-Instance (✅ Use)**:
- Plan-execute pattern (planning session + execution session)
- Quality review (implementation + code review)
- Test-first development (write tests + implement)

**Single Agent (✅ Use)**:
- Simple implementations (<5 files)
- Write-heavy tasks (shared file modifications)
- Sequential workflows (step-by-step tutorials)
- Budget-constrained projects

### Teams vs Beads Framework

**Beads Framework** (Steve Yegge):
- **Architecture**: Event-sourced MCP server (Gas Town) + SQLite database (beads.db)
- **Coordination**: Persistent message storage, historical replay
- **Maturity**: Community-maintained, experimental
- **Setup**: Requires Gas Town installation + agent-chat UI
- **Use case**: On-prem/airgap environments, full control over orchestration

**Agent Teams** (Anthropic):
- **Architecture**: Native Claude Code feature, git-based coordination
- **Coordination**: Real-time git locking, automatic merge
- **Maturity**: Official Anthropic feature (experimental)
- **Setup**: Feature flag only (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- **Use case**: Rapid prototyping, cloud-based development

**Comparison**:

| Aspect | Beads Framework | Agent Teams |
|--------|----------------|-------------|
| **Control** | Full (event sourcing, replay) | Limited (black-box coordination) |
| **Setup** | Complex (Gas Town + agent-chat) | Simple (feature flag) |
| **Persistence** | SQLite (beads.db) | Git commits |
| **Visibility** | agent-chat UI (Slack-like) | Native Claude Code interface |
| **Environment** | On-prem friendly | Cloud-first |
| **Maturity** | Community-driven | Anthropic official |

**When to use Beads**:
- ✅ On-prem/airgap requirements (no cloud API calls)
- ✅ Need event replay (debugging orchestration)
- ✅ Custom orchestration logic (beyond git-based)
- ✅ Persistent agent communications (audit trail)

**When to use Agent Teams**:
- ✅ Cloud development (Anthropic API access)
- ✅ Rapid setup (no infrastructure required)
- ✅ Git-native workflows (already using git)
- ✅ Official support path (Anthropic-maintained)

**Open question** (as of Feb 2026):
> "I'm not sure about Claude's guidance on when to use beads versus agent team sessions."
> — Paul Rayner, Feb 2026

**Community feedback needed**: Anthropic has not published official guidance on this choice. Practitioners are invited to share experiences in [GitHub Discussions](https://github.com/anthropics/claude-code/discussions).

---

## 8. Best Practices

### Task Decomposition Strategies

**Clear boundaries principle**:
```
Good decomposition:
- Agent 1: Backend API endpoints (/api/users/*)
- Agent 2: Frontend components (src/components/users/*)
- Agent 3: Database migrations (db/migrations/users/)

Why good:
- Non-overlapping file sets (no merge conflicts)
- Clear interfaces (API contracts)
- Independent testing (each layer testable)
```

```
Bad decomposition:
- Agent 1: User authentication
- Agent 2: User authorization
- Agent 3: User session management

Why bad:
- Overlapping files (auth.ts touched by all 3)
- Interdependencies (auth needs sessions, sessions need auth)
- Sequential coupling (can't parallelize effectively)
```

**Interface-first approach**:
1. **Define contracts**: Agree on function signatures, API schemas before parallel work
2. **Type stubs**: Create TypeScript types/interfaces first, implement separately
3. **Mock boundaries**: Each agent works with mocked dependencies initially
4. **Integration phase**: Team lead coordinates final integration

**Example**:
```typescript
// Team lead defines interface first
interface UserService {
  authenticate(email: string, password: string): Promise<User>;
  authorize(user: User, resource: string): Promise<boolean>;
}

// Agent 1 implements authenticate
// Agent 2 implements authorize
// No merge conflicts (different functions)
```

### Coordination Patterns

**Fan-out, fan-in**:
```
Team lead
  │
  ├─ Agent 1: Task A ──┐
  ├─ Agent 2: Task B ──┼──> Team lead synthesizes
  └─ Agent 3: Task C ──┘
```

**Sequential phases with parallelization**:
```
Phase 1 (Sequential):
  Team lead: Define architecture

Phase 2 (Parallel):
  ├─ Agent 1: Implement backend
  ├─ Agent 2: Implement frontend
  └─ Agent 3: Write tests

Phase 3 (Sequential):
  Team lead: Integration + validation
```

**Hierarchical delegation**:
```
Team lead
  │
  ├─ Agent 1 (Backend lead)
  │   ├─ Agent 1a: Controllers
  │   └─ Agent 1b: Services
  │
  └─ Agent 2 (Frontend lead)
      ├─ Agent 2a: Components
      └─ Agent 2b: State management
```

### Git Worktree Management

**Why worktrees matter**:
- Each agent works in separate git worktree (isolated file system)
- Prevents file locking conflicts
- Enables parallel file modifications

**Setup**:
```bash
# Main repository
git worktree add ../project-agent1 main

# Agent 1 works in project-agent1/
# Agent 2 works in project-agent2/
# Team lead works in project/

# All sync via git commits
```

**Best practices**:
- ✅ One worktree per agent
- ✅ Frequent commits (continuous merge)
- ✅ Descriptive branch names (`agent1-backend-api`, `agent2-frontend-ui`)
- ❌ Don't modify same files across worktrees without coordination

### Cost Optimization

**Token-saving strategies**:

1. **Lazy spawning**: Only spawn agents when parallelization clearly benefits
   ```
   Bad: "Spawn 3 agents to implement this button"
   Good: "Spawn agents for multi-layer security review"
   ```

2. **Context pruning**: Remove irrelevant files from agent context
   ```
   # Tell agent what to ignore
   "Review backend API, ignore frontend files"
   ```

3. **Progressive escalation**: Start with single agent, escalate to teams if needed
   ```
   Step 1: Single agent attempts task
   Step 2: If complexity high, spawn team
   ```

4. **Result caching**: Reuse agent findings across similar tasks
   ```
   "Agent 1 found security issues in auth.ts.
   Agent 2, check if user.ts has same patterns."
   ```

### Quality Assurance

**Validation checklist**:
- [ ] **All agents completed**: No hanging tasks
- [ ] **Merge conflicts resolved**: Clean git history
- [ ] **Tests passing**: Automated test suite green
- [ ] **Human review**: Code inspection (don't trust blindly)
- [ ] **Cross-agent consistency**: Naming, patterns aligned

**Red flags**:
- ⚠️ Agents finished at very different times (imbalanced load)
- ⚠️ Many merge conflicts (poor task decomposition)
- ⚠️ Tests failing after merge (integration issues)
- ⚠️ Inconsistent code style (agents didn't follow shared standards)

**Mitigation**:
```bash
# After agent teams complete
git diff main..agent-teams-branch  # Review all changes
npm test                           # Run full test suite
npm run lint                       # Check code style
```

---

## 9. Troubleshooting

### Common Issues

#### Issue: Agents not spawning

**Symptoms**:
- Agent teams prompt accepted but no teammates created
- Only team lead session running

**Causes**:
1. Feature flag not set correctly
2. Model not Opus 4.6 (teams require Opus)
3. Task not complex enough (Claude decided single agent sufficient)

**Solutions**:
```bash
# Verify flag
echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS  # Should output "1" or "true"

# Check settings
cat ~/.claude/settings.json | grep agentTeams  # Should be true

# Force model
/model opus

# Explicit request
"Spawn 3 agents for this task (team lead + 2 teammates)"
```

#### Issue: Merge conflicts overwhelming

**Symptoms**:
- Many git conflicts after agents complete
- Manual resolution required frequently

**Causes**:
- Poor task decomposition (overlapping file sets)
- Write-heavy task (multiple agents modifying shared files)

**Solutions**:
```
Prevention:
1. Clear boundaries: Non-overlapping file assignments
2. Interface-first: Define contracts before implementation
3. Single-writer: One agent writes shared files, others read

Recovery:
1. Revert: git reset --hard before-agent-teams
2. Sequential: Re-implement with single agent
3. Human merge: Manually resolve conflicts (git mergetool)
```

#### Issue: High token costs

**Symptoms**:
- Token usage 3x+ higher than expected
- Budget exhausted quickly

**Causes**:
- Over-spawning agents (3+ agents for simple tasks)
- Long-running sessions (agents idle)
- Large context per agent (1M tokens × 3)

**Solutions**:
```
Immediate:
1. Kill extra agents: Shift+Down, exit agent session
2. Reduce scope: Narrow task boundaries
3. Switch to single agent: /model sonnet (cheaper)

Long-term:
1. Cost monitoring: Track token usage per session
2. Lazy spawning: Only spawn when needed
3. Progressive escalation: Start small, scale up if needed
```

#### Issue: Agents stuck/hanging

**Symptoms**:
- One agent finishes, others still processing for long time
- No progress updates

**Causes**:
- Imbalanced task distribution (one agent has 80% of work)
- Agent waiting for dependency (sequential coupling)
- Bug in git coordination (rare)

**Solutions**:
```bash
# Navigate to stuck agent
Shift+Down  # Switch to agent

# Check status
"What are you working on? Progress update?"

# Manual takeover if needed
"Stop current task, report findings so far"

# Kill and redistribute
Exit agent → Team lead redistributes task
```

#### Issue: Inconsistent results across agents

**Symptoms**:
- Agent 1 says "No issues", Agent 2 finds 10 bugs (same codebase)
- Conflicting recommendations

**Causes**:
- Different context windows (agents saw different files)
- Ambiguous instructions (agents interpreted differently)
- Model variability (stochastic outputs)

**Solutions**:
```
Prevention:
1. Explicit instructions: "All agents: Check for SQL injection"
2. Shared context: Point all agents to same reference docs
3. Validation: Human reviews all agent outputs

Recovery:
1. Reconciliation: "Compare Agent 1 and Agent 2 findings, resolve conflicts"
2. Third opinion: Spawn Agent 3 to arbitrate
3. Human decision: You choose which agent's recommendation to follow
```

### Navigation Problems

**Can't find agent sessions**:
```bash
# List all sessions
claude --list

# Filter for agent sessions
claude --list | grep agent

# Resume specific agent
claude --resume <session-id>
```

**Lost track of which agent is which**:
```
Solution: Name agents explicitly in team lead prompt

Good:
"Spawn 3 agents:
- Agent Security: Check vulnerabilities
- Agent Performance: Profile bottlenecks
- Agent Tests: Write test suite"

Bad:
"Spawn 3 agents for this codebase review"
```

**tmux navigation not working**:
```bash
# Verify tmux session
tmux list-sessions

# Attach to session
tmux attach -t claude-agents

# Navigate
Ctrl+b, n  # Next window
Ctrl+b, p  # Previous window
```

### Performance Optimization

**Slow coordination**:
```bash
# Check git repo size
du -sh .git/  # If >1GB, consider cleanup

# Clean up git objects
git gc --aggressive --prune=now

# Use shallow clone for agents
git clone --depth 1 <repo>
```

**Context loading delays**:
```
# Reduce context per agent
"Agent 1: Only load src/backend/* files"
"Agent 2: Only load src/frontend/* files"

# Prune irrelevant files
echo "node_modules/" >> .gitignore
echo "dist/" >> .gitignore
```

---

## 10. Sources

### Official Anthropic Sources

1. **[Introducing Claude Opus 4.6](https://www.anthropic.com/news/claude-opus-4-6)**
   Anthropic, Feb 2026
   Official announcement of Opus 4.6 and agent teams research preview

2. **[Building a C compiler with agent teams](https://www.anthropic.com/engineering/building-c-compiler)**
   Anthropic Engineering, Feb 2026
   Technical deep-dive: git-based coordination, autonomous C compiler case study

3. **[2026 Agentic Coding Trends Report](https://resources.anthropic.com/hubfs/2026%20Agentic%20Coding%20Trends%20Report.pdf)**
   Anthropic, Jan 2026
   Production metrics: Fountain (50% faster), CRED (2x speed)

### Community Sources

4. **[Claude Opus 4.6 for Developers: Agent Teams, 1M Context](https://dev.to/thegdsks/claude-opus-46-for-developers-agent-teams-1m-context-and-what-actually-matters-4h8c)**
   dev.to, Feb 2026
   Setup instructions, workflow impact table, read/write trade-offs

5. **[The best way to do agentic development in 2026](https://dev.to/chand1012/the-best-way-to-do-agentic-development-in-2026-14mn)**
   dev.to, Jan 2026
   Integration patterns: Claude Code + plugins (Conductor, Superpowers, Context7)

### Practitioner Testimonials

6. **[Paul Rayner LinkedIn Post](https://www.linkedin.com/posts/thepaulrayner_this-is-wild-i-just-upgraded-claude-code-activity-7425635159678414850-MNyv)**
   Paul Rayner (CEO Virtual Genius, EventStorming Handbook author), Feb 2026
   Production usage: 3 concurrent workflows (job search app, business ops, infrastructure)

### Related Documentation

- [Claude Code Releases](../claude-code-releases.md) — v2.1.32, v2.1.33 release notes
- [Sub-Agents](../ultimate-guide.md#sub-agents) — Single-agent task delegation
- [Multi-Instance Workflows](../ultimate-guide.md#multi-instance-workflows) — Manual parallel coordination
- [Dual-Instance Pattern](../ultimate-guide.md#dual-instance-pattern) — Plan-execute split
- [AI Ecosystem: Beads Framework](../ai-ecosystem.md#beads-framework) — Alternative orchestration (Gas Town)

---

## Feedback & Contributions

**Experiencing issues?** Report to [Anthropic GitHub Issues](https://github.com/anthropics/claude-code/issues)

**Production learnings?** Share in [GitHub Discussions](https://github.com/anthropics/claude-code/discussions)

**Questions?** Ask in [Dev With AI Community](https://www.devw.ai/) (1500+ devs, Slack)

---

*Version 1.0.0 | Created: 2026-02-07 | Agent Teams (v2.1.32+, Experimental)*
