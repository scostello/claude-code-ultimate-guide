# Claude Code — Visual Reference

All diagrams in one place. Quick visual overview of Claude Code's key concepts.
For detailed docs → [Ultimate Guide](./ultimate-guide.md) | [Cheatsheet](./cheatsheet.md)

> **20 diagrams**: 8 new (this file) + 12 from existing guides, all consolidated here.

---

## Table of Contents

**New diagrams:**
1. [Context Management Zones](#1-context-management-zones)
2. [Permission Modes Cycle](#2-permission-modes-cycle)
3. [Workflow Pipeline (9 Steps)](#3-workflow-pipeline-9-steps)
4. [Quick Decision Tree](#4-quick-decision-tree)

**Architecture & Internals:**
5. [Master Loop](#5-master-loop)
6. [Hook Event Flow](#6-hook-event-flow)
7. [Data Privacy Flow](#7-data-privacy-flow)

**Security:**
8. [MCP Rug Pull Attack](#8-mcp-rug-pull-attack)
9. [Docker Sandbox Architecture](#9-docker-sandbox-architecture)

**Decision Trees:**
10. [Search Tool Selection](#10-search-tool-selection)
11. [Trust Calibration Flow](#11-trust-calibration-flow)
12. [Adoption Decision Tree](#12-adoption-decision-tree)
13. [Methodology Selection](#13-methodology-selection)

**Workflows:**
14. [Research → Spec → Code](#14-research--spec--code)
15. [Review Auto-Correction Loop](#15-review-auto-correction-loop)
16. [PDF Pipeline Stack](#16-pdf-pipeline-stack)

**Development & Learning:**
17. [TDD Red-Green-Refactor Cycle](#17-tdd-red-green-refactor-cycle)
18. [UVAL Protocol Flow](#18-uval-protocol-flow)

**Security (extended):**
19. [Security 3-Layer Defense](#19-security-3-layer-defense)
20. [Secret Exposure Timeline](#20-secret-exposure-timeline)

---

## 1. Context Management Zones

How to react based on context window usage (check with `/status`):

```
Context Usage
0%          50%         70%         90%       100%
├───────────┼───────────┼───────────┼──────────┤
│   GREEN   │  YELLOW   │  ORANGE   │   RED    │
│  work     │ selective │ /compact  │  /clear  │
│  freely   │ with care │   NOW     │ required │
└───────────┴───────────┴───────────┴──────────┘
              ▲                       ▲
              │                       │
         Be selective            Risk: forgetting
         about reads             instructions,
         and tool use            hallucinations
```

**Actions by zone:**
- **Green (0-50%)** — Full speed. Read files, explore freely.
- **Yellow (50-70%)** — Be selective. Avoid unnecessary file reads.
- **Orange (70-90%)** — Run `/compact` immediately. Context is degrading.
- **Red (90%+)** — Run `/clear` and restart. Responses are unreliable.

→ Source: [ultimate-guide.md:1335](./ultimate-guide.md)

---

## 2. Permission Modes Cycle

Cycle through modes with `Shift+Tab`:

```
                 Shift+Tab              Shift+Tab
  ┌──────────┐ ────────────→ ┌───────────────┐ ────────────→ ┌───────────┐
  │ DEFAULT  │               │  AUTO-ACCEPT   │               │ PLAN MODE │
  │          │               │                │               │           │
  │ edit=ask │               │ edit=auto      │               │ edit=no   │
  │ exec=ask │               │ exec=ask       │               │ exec=no   │
  └──────────┘ ←──────────── └───────────────┘ ←──────────── └───────────┘
                 Shift+Tab              Shift+Tab
```

**When to use each mode:**

| Mode | Use when... | Risk level |
|------|-------------|------------|
| **Default** | Normal development — review each change | Low |
| **Auto-accept** | Trusted tasks (formatting, refactoring) | Medium |
| **Plan mode** | Complex/risky operations — explore safely first | None |

**Shortcuts:**
- `Shift+Tab` — Cycle to next mode
- `Shift+Tab × 2` — Jump to plan mode from default
- `/plan` — Enter plan mode directly
- `/execute` — Exit plan mode

→ Source: [ultimate-guide.md:760](./ultimate-guide.md)

---

## 3. Workflow Pipeline (9 Steps)

The recommended workflow for every task:

```
  ┌─────────┐    ┌──────────┐    ┌────────────┐    ┌─────────────┐
  │ 1.START │───→│ 2./status│───→│ 3. plan?   │───→│ 4. describe │
  │ claude  │    │ check ctx│    │ Shift+Tab×2│    │ WHAT/WHERE  │
  └─────────┘    └──────────┘    │ (if risky) │    │ HOW/VERIFY  │
                                 └────────────┘    └──────┬──────┘
                                                          │
      ┌───────────────────────────────────────────────────┘
      │
      ▼
  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ 5.review │───→│ 6. y/n   │───→│ 7. test  │───→│ 8.commit │───→│9./compact│
  │   diff   │    │ accept?  │    │   run    │    │ when done│    │ when >70%│
  └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

**Key principles:**
- **Step 2**: Always check context before starting. If >70%, `/compact` first.
- **Step 3**: Use plan mode for anything risky, complex, or multi-file.
- **Step 4**: Be specific — vague prompts produce vague results.
- **Step 5**: Read every diff. Never blindly accept.
- **Step 9**: Compact after each task to stay in the green zone.

→ Source: [ultimate-guide.md:277](./ultimate-guide.md)

---

## 4. Quick Decision Tree

What to do based on your situation:

```
What do you need?
│
├─ Simple task ─────────────────→ Just ask Claude
│
├─ Complex task
│  ├─ Single session ───────────→ /plan + Tasks API
│  └─ Multi-session ────────────→ Tasks API + CLAUDE_CODE_TASK_LIST_ID
│
├─ Repeating task ──────────────→ Create agent or command
│
├─ Context >70% ────────────────→ /compact
│
├─ Context >90% ────────────────→ /clear (restart conversation)
│
├─ Need library docs ───────────→ Context7 MCP
│
├─ Deep debugging ──────────────→ Opus model + Alt+T (thinking)
│
├─ UI from design ──────────────→ Figma MCP or screenshot input
│
└─ Team rollout ────────────────→ Read adoption-approaches.md
```

→ Source: [reference.yaml](../machine-readable/reference.yaml) (decide section)

---

## 5. Master Loop

The entire architecture is a simple `while` loop — no DAG, no classifier, no RAG.

```
┌─────────────────────────────────────────────────────────────┐
│                    CLAUDE CODE MASTER LOOP                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐                                          │
│   │  Your Prompt │                                          │
│   └──────┬───────┘                                          │
│          │                                                  │
│          ▼                                                  │
│   ┌──────────────────────────────────────────────────────┐  │
│   │                                                      │  │
│   │                  CLAUDE REASONS                      │  │
│   │        (No classifier, no routing layer)             │  │
│   │                                                      │  │
│   └────────────────────────┬─────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│                   ┌────────────────┐                        │
│                   │  Tool Call?    │                        │
│                   └───────┬────────┘                        │
│                           │                                 │
│              YES          │           NO                    │
│         ┌─────────────────┴─────────────────┐               │
│         │                                   │               │
│         ▼                                   ▼               │
│  ┌────────────┐                      ┌────────────┐         │
│  │  Execute   │                      │   Text     │         │
│  │   Tool     │                      │  Response  │         │
│  │            │                      │   (DONE)   │         │
│  └─────┬──────┘                      └────────────┘         │
│        │                                                    │
│        ▼                                                    │
│  ┌─────────────┐                                            │
│  │ Feed Result │                                            │
│  │  to Claude  │──────────────────┐                         │
│  └─────────────┘                  │                         │
│                                   │                         │
│                                   ▼                         │
│                          ┌────────────────┐                 │
│                          │   LOOP BACK    │                 │
│                          │  (Next turn)   │                 │
│                          └────────────────┘                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

→ Source: [architecture.md:84](./architecture.md)

---

## 6. Hook Event Flow

How hooks intercept Claude Code's execution pipeline:

```
┌─────────────────────────────────────────────────────────┐
│                      EVENT FLOW                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   User types message                                    │
│        │                                                │
│        ▼                                                │
│   ┌────────────────────┐                                │
│   │ UserPromptSubmit   │  ← Add context (git status)    │
│   └────────────────────┘                                │
│        │                                                │
│        ▼                                                │
│   Claude decides to run tool (e.g., Edit)               │
│        │                                                │
│        ▼                                                │
│   ┌────────────────────┐                                │
│   │ PreToolUse         │  ← Security check              │
│   └────────────────────┘                                │
│        │                                                │
│        ▼ (if allowed)                                   │
│   Tool executes                                         │
│        │                                                │
│        ▼                                                │
│   ┌────────────────────┐                                │
│   │ PostToolUse        │  ← Auto-format                 │
│   └────────────────────┘                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

→ Source: [ultimate-guide.md:6327](./ultimate-guide.md)

---

## 7. Data Privacy Flow

What data leaves your machine when using Claude Code:

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR LOCAL MACHINE                       │
├─────────────────────────────────────────────────────────────┤
│  • Prompts you type                                         │
│  • Files Claude reads (including .env if not excluded!)     │
│  • MCP server results (SQL queries, API responses)          │
│  • Bash command outputs                                     │
│  • Error messages and stack traces                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                    ANTHROPIC API                            │
├─────────────────────────────────────────────────────────────┤
│  • Processes your request                                   │
│  • Stores conversation based on retention policy            │
│  • May use data for model training (if not opted out)       │
└─────────────────────────────────────────────────────────────┘
```

→ Source: [data-privacy.md:24](./data-privacy.md)

---

## 8. MCP Rug Pull Attack

How a malicious MCP server can exploit the one-time approval model:

```
┌─────────────────────────────────────────────────────────────┐
│  1. Attacker publishes benign MCP "code-formatter"          │
│                         ↓                                    │
│  2. User adds to ~/.claude/mcp.json, approves once          │
│                         ↓                                    │
│  3. MCP works normally for 2 weeks (builds trust)           │
│                         ↓                                    │
│  4. Attacker pushes malicious update (no re-approval!)      │
│                         ↓                                    │
│  5. MCP exfiltrates ~/.ssh/*, .env, credentials             │
└─────────────────────────────────────────────────────────────┘
MITIGATION: Version pinning + hash verification + monitoring
```

→ Source: [security-hardening.md:33](./security-hardening.md)

---

## 9. Docker Sandbox Architecture

Full isolation for autonomous Claude Code sessions:

```
┌──────────────────────────────────────────────────────────┐
│                     HOST MACHINE                          │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              DOCKER SANDBOX (microVM)               │  │
│  │                                                    │  │
│  │  ┌──────────────┐  ┌───────────────────────────┐  │  │
│  │  │ Claude Code   │  │ Private Docker daemon     │  │  │
│  │  │ (--dsp mode)  │  │ (isolated from host)      │  │  │
│  │  └──────────────┘  └───────────────────────────┘  │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │ Workspace: ~/my-project (synced with host)   │  │  │
│  │  │ Same absolute path as host                   │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  │                                                    │  │
│  │  Base: Ubuntu, Node.js, Python 3, Go, Git,        │  │
│  │        Docker CLI, GitHub CLI, ripgrep, jq         │  │
│  │  User: non-root 'agent' with sudo                 │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  Host Docker daemon: NOT accessible from sandbox          │
│  Host filesystem: NOT accessible (except workspace)       │
└──────────────────────────────────────────────────────────┘
```

→ Source: [sandbox-isolation.md:87](./sandbox-isolation.md)

---

## 10. Search Tool Selection

3-level decision tree for choosing the right search tool:

**Level 1: What Do You Know?**

```
Do you know the EXACT text/pattern?
│
├─ YES → Use rg (ripgrep)
│  ├─ Known function name: rg "createSession"
│  ├─ Known import: rg "import.*React"
│  └─ Known pattern: rg "async function"
│
└─ NO → Go to Level 2
```

**Level 2: What Are You Looking For?**

```
What's your search intent?
│
├─ "Find by MEANING/CONCEPT"
│  → Use grepai
│  └─ Example: grepai search "payment validation logic"
│
├─ "Find FUNCTION/CLASS definition"
│  → Use Serena
│  └─ Example: serena find_symbol --name "UserController"
│
├─ "Find by CODE STRUCTURE"
│  → Use ast-grep
│  └─ Example: async without error handling
│
└─ "Understand DEPENDENCIES"
   → Use grepai trace
   └─ Example: grepai trace callers "validatePayment"
```

**Level 3: Optimization**

```
Found too many results?
│
├─ rg → Add --type filter or narrow path
├─ grepai → Add --path filter or use trace
├─ Serena → Filter by symbol type (function/class)
└─ ast-grep → Add constraints to pattern
```

→ Source: [search-tools-mastery.md:75](./workflows/search-tools-mastery.md)

---

## 11. Trust Calibration Flow

How much to review AI-generated code based on risk level:

```
┌─────────────────────────────────────────────────────────┐
│                 TRUST CALIBRATION FLOW                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  AI generates code                                      │
│         │                                               │
│         ▼                                               │
│  ┌──────────────┐                                       │
│  │ What type?   │                                       │
│  └──────────────┘                                       │
│    │    │    │                                          │
│    ▼    ▼    ▼                                          │
│  Boiler Business Security                               │
│  -plate  logic   critical                               │
│    │      │        │                                    │
│    ▼      ▼        ▼                                    │
│  Skim   Test +   Full review                            │
│  only   review   + tools                                │
│    │      │        │                                    │
│    └──────┴────────┘                                    │
│            │                                            │
│            ▼                                            │
│    Tests pass? ──No──► Debug & fix                      │
│            │                                            │
│           Yes                                           │
│            │                                            │
│            ▼                                            │
│        Ship it                                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

→ Source: [ultimate-guide.md:1182](./ultimate-guide.md)

---

## 12. Adoption Decision Tree

How to choose your Claude Code adoption strategy:

```
Starting Claude Code?
│
├─ Need to ship today?
│   └─ YES → Turnkey Quickstart
│   └─ NO ↓
│
├─ Team needs shared conventions?
│   └─ YES → Turnkey + document what matters to you
│   └─ NO ↓
│
├─ Want to understand before configuring?
│   └─ YES → Autonomous Learning Path
│   └─ NO → Turnkey, adjust as you go
```

→ Source: [adoption-approaches.md:51](./adoption-approaches.md)

---

## 13. Methodology Selection

Which development methodology to use:

```
┌─ "I want quality code" ────────────→ workflows/tdd-with-claude.md
│
├─ "I want to spec before code" ─────→ workflows/spec-first.md
│
├─ "I need to plan architecture" ────→ workflows/plan-driven.md
│
├─ "I'm iterating on something" ─────→ workflows/iterative-refinement.md
│
└─ "I need methodology theory" ──────→ methodologies.md
```

→ Source: [methodologies.md:24](./methodologies.md)

---

## 14. Research → Spec → Code

Using Perplexity for research, then Claude Code for implementation:

```
┌─────────────────────────────────────────────────────────┐
│ 1. PERPLEXITY (Deep Research)                           │
│    "Research best practices for JWT refresh tokens      │
│     in Next.js 15. Include security considerations,     │
│     common pitfalls, and library recommendations."      │
│                                                         │
│    → Output: 2000-word spec with sources               │
└───────────────────────────┬─────────────────────────────┘
                            ↓ Export as spec.md
┌─────────────────────────────────────────────────────────┐
│ 2. CLAUDE CODE                                          │
│    > claude                                             │
│    "Implement JWT refresh tokens following spec.md.     │
│     Use the jose library as recommended."               │
│                                                         │
│    → Output: Working implementation with tests         │
└─────────────────────────────────────────────────────────┘
```

→ Source: [ai-ecosystem.md:155](./ai-ecosystem.md)

---

## 15. Review Auto-Correction Loop

Iterative code review pattern where Claude reviews, fixes, and re-reviews:

```
┌─────────────────────────────────────────┐
│   Review Auto-Correction Loop           │
│                                          │
│   Review (identify issues)               │
│        ↓                                 │
│   Fix (apply corrections)                │
│        ↓                                 │
│   Re-Review (verify fixes)               │
│        ↓                                 │
│   Converge (minimal changes) → Done      │
│        ↑                                 │
│        └──── Repeat (max iterations)     │
└─────────────────────────────────────────┘
```

→ Source: [iterative-refinement.md:354](./workflows/iterative-refinement.md)

---

## 16. PDF Pipeline Stack

Quarto + Typst stack for generating professional PDFs:

```
┌─────────────────────────────────────────────────┐
│                  Your .qmd File                 │
│         (Markdown + YAML frontmatter)           │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                    Quarto                       │
│           (Document rendering engine)           │
│         • Processes YAML metadata               │
│         • Handles extensions                    │
│         • Manages output formats                │
└─────────────────────────────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
┌─────────────────────┐    ┌─────────────────────┐
│       Pandoc        │    │       Typst         │
│   (MD → AST → ?)    │    │  (Typography/PDF)   │
│  • Markdown parser  │    │  • Modern engine    │
│  • AST transforms   │    │  • Fast compilation │
│  • Format bridges   │    │  • No LaTeX needed  │
└─────────────────────┘    └─────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                  document.pdf                   │
│        (Professional typography output)         │
└─────────────────────────────────────────────────┘
```

→ Source: [pdf-generation.md:58](./workflows/pdf-generation.md)

---

## 17. TDD Red-Green-Refactor Cycle

The iterative loop at the heart of Test-Driven Development:

```
                    ┌──────────────────────────┐
                    │                          │
                    ▼                          │
            ┌──────────────┐                   │
            │   🔴 RED      │                   │
            │              │                   │
            │  Write a     │                   │
            │  failing     │                   │
            │  test        │                   │
            └──────┬───────┘                   │
                   │                           │
                   │ Tests FAIL                │
                   │ (expected)                │
                   ▼                           │
            ┌──────────────┐                   │
            │   🟢 GREEN   │                   │
            │              │                   │
            │  Write       │                   │
            │  minimal     │                   │
            │  code to     │                   │
            │  pass        │                   │
            └──────┬───────┘                   │
                   │                           │
                   │ Tests PASS                │
                   │ (minimal)                 │
                   ▼                           │
            ┌──────────────┐                   │
            │   🔵 REFACTOR│                   │
            │              │                   │
            │  Clean up    │                   │
            │  while tests │                   │
            │  stay green  │                   │
            └──────┬───────┘                   │
                   │                           │
                   │ Next feature              │
                   └───────────────────────────┘

Key rules:
  RED    → Test must FAIL before writing implementation
  GREEN  → Write ONLY enough code to pass (no more)
  REFACTOR → Improve structure, tests must stay green
  REPEAT → One feature at a time, always in this order
```

> Source: [workflows/tdd-with-claude.md:78](./workflows/tdd-with-claude.md)

---

## 18. UVAL Protocol Flow

Systematic framework for learning with AI without losing your edge:

```
  ┌────────────────────────────────────────────────────────────┐
  │                    UVAL PROTOCOL                           │
  │         (Use AI without losing your edge)                  │
  └────────────────────────────────────────────────────────────┘

  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
  │    U     │     │    V     │     │    A     │     │    L     │
  │UNDERSTAND│────→│  VERIFY  │────→│  APPLY   │────→│  LEARN   │
  │          │     │          │     │          │     │          │
  │ 15-min   │     │ Can you  │     │ Modify   │     │ Capture  │
  │ rule:    │     │ explain  │     │ the code │     │ insights │
  │          │     │ it back? │     │ yourself │     │ for long │
  │ 1.State  │     │          │     │          │     │ term     │
  │   problem│     │ Test:    │     │ Tasks:   │     │          │
  │ 2.Brain- │     │ explain  │     │ • Extend │     │ Methods: │
  │   storm  │     │ to a     │     │ • Modify │     │ • Notes  │
  │ 3.Find   │     │ colleague│     │ • Debug  │     │ • Teach  │
  │   gaps   │     │ without  │     │ • Adapt  │     │ • Blog   │
  │ 4.Ask    │     │ looking  │     │   to new │     │ • Review │
  │   smart  │     │ at code  │     │   context│     │   later  │
  └──────────┘     └──────────┘     └──────────┘     └──────────┘
       │                                                   │
       │              ◄── Repeat per concept ──►           │
       └───────────────────────────────────────────────────┘

  If VERIFY fails → go back to UNDERSTAND (you copied, didn't learn)
  If APPLY fails  → go back to VERIFY (you memorized, didn't understand)
```

> Source: [learning-with-ai.md:208](./learning-with-ai.md)

---

## 19. Security 3-Layer Defense

The full security document (security-hardening.md) organized as 3 defense layers:

```
  ┌─────────────────────────────────────────────────────────────┐
  │                  SECURITY 3-LAYER DEFENSE                   │
  ├─────────────────────────────────────────────────────────────┤
  │                                                             │
  │  TIME ──────────────────────────────────────────────────►   │
  │         Before              During             After        │
  │                                                             │
  │  ┌─────────────────┐ ┌─────────────────┐ ┌───────────────┐ │
  │  │ LAYER 1         │ │ LAYER 2         │ │ LAYER 3       │ │
  │  │ PREVENTION      │ │ DETECTION       │ │ RESPONSE      │ │
  │  │                 │ │                 │ │               │ │
  │  │ • MCP vetting   │ │ • Prompt inject │ │ • Secret      │ │
  │  │   workflow      │ │   detection     │ │   rotation    │ │
  │  │ • Version       │ │ • Output        │ │ • MCP         │ │
  │  │   pinning       │ │   scanning      │ │   isolation   │ │
  │  │ • .claudeignore │ │ • Anomaly       │ │ • History     │ │
  │  │ • Input hooks   │ │   monitoring    │ │   rewriting   │ │
  │  │ • Safe MCP list │ │ • Secret leak   │ │ • Incident    │ │
  │  │ • Permissions   │ │   detection     │ │   reporting   │ │
  │  │ • Integrity     │ │ • Unicode/ANSI  │ │ • Post-mortem │ │
  │  │   scanning      │ │   filtering     │ │   & rotation  │ │
  │  │                 │ │                 │ │               │ │
  │  │  GOAL: Block    │ │  GOAL: Catch    │ │  GOAL: Limit  │ │
  │  │  threats at     │ │  attacks in     │ │  damage and   │ │
  │  │  entry points   │ │  real-time      │ │  recover fast │ │
  │  └─────────────────┘ └─────────────────┘ └───────────────┘ │
  │                                                             │
  │  Adoption path:                                             │
  │  Solo dev    → Layer 1 basics (output scanner)              │
  │  Team        → Layer 1 + 2 (+ injection hooks)              │
  │  Enterprise  → All 3 layers (+ ZDR + verification)          │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
```

> Source: [security-hardening.md:24/205/345](./security-hardening.md)

---

## 20. Secret Exposure Timeline

Emergency response when a secret (API key, token, password) is exposed:

```
  SECRET EXPOSED — Emergency Response Timeline
  ═══════════════════════════════════════════════════════════

  0 min                15 min              1 hour             24 hours
  │                    │                   │                  │
  ▼                    ▼                   ▼                  ▼
  ┌──────────────────┐ ┌─────────────────┐ ┌────────────────┐
  │ ⏱️ FIRST 15 MIN   │ │ ⏱️ FIRST HOUR    │ │ ⏱️ FIRST 24H    │
  │ Stop the         │ │ Assess damage   │ │ Remediate      │
  │ bleeding         │ │                 │ │                │
  │                  │ │ 3. Audit git    │ │ 6. Rotate ALL  │
  │ 1. REVOKE key    │ │    history      │ │    related     │
  │    immediately   │ │    (rewrite if  │ │    credentials │
  │    (AWS/GH/      │ │     pushed)     │ │                │
  │     Stripe)      │ │                 │ │ 7. Notify team │
  │                  │ │ 4. Scan deps    │ │    /compliance │
  │ 2. Confirm       │ │    for leaked   │ │    (GDPR/SOC2) │
  │    exposure      │ │    keys         │ │                │
  │    scope         │ │                 │ │ 8. Document    │
  │    (local or     │ │ 5. Check CI/CD  │ │    incident    │
  │     pushed?)     │ │    logs         │ │    timeline    │
  │                  │ │                 │ │                │
  └──────────────────┘ └─────────────────┘ └────────────────┘

  SEVERITY GUIDE:
  ┌─────────────────────────────────────────────────────────┐
  │ Local only (not pushed)  → Revoke + rotate (steps 1-2) │
  │ Pushed to remote         → Full timeline (steps 1-8)   │
  │ Public repo exposure     → Assume compromised, rotate  │
  │                            EVERYTHING, check for abuse  │
  └─────────────────────────────────────────────────────────┘
```

> Source: [security-hardening.md:347](./security-hardening.md)

---

*Back to [Guide README](./README.md) | [Cheatsheet](./cheatsheet.md) | [Main README](../README.md)*
