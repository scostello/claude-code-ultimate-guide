# Claude Cowork Documentation

> **Complete guide for Claude's agentic desktop feature for knowledge workers**

[![Status: Research Preview](https://img.shields.io/badge/Status-Research%20Preview-yellow)](https://claude.ai/cowork)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue)]()
[![Subscription: Pro & Max](https://img.shields.io/badge/Subscription-Pro%20%26%20Max-purple)]()

---

## What is Cowork?

**Cowork** is Claude's desktop-native autonomous assistant that manipulates local files, generates documents, and organizes your digital workspace—without writing code.

Think of it as **Claude Code for everyone**: same agentic capabilities, but through a visual interface with file-only operations.

```
┌─────────────────────────────────────────────────┐
│              CLAUDE DESKTOP APP                 │
│  ┌───────────────────────────────────────────┐  │
│  │              COWORK                       │  │
│  │   "Organize my Downloads folder by type"  │  │
│  │                    ↓                      │  │
│  │   [Analysis] → [Planning] → [Execution]   │  │
│  │                    ↓                      │  │
│  │   ~/Downloads/ → Organized structure      │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## Quick Start

### 1. Access Requirements

| Requirement | Details |
|-------------|---------|
| **Subscription** | Pro ($20/mo) or Max ($100-200/mo) |
| **Platform** | macOS only (Windows planned, no ETA) |
| **App** | Claude Desktop (latest version) |

### 2. Enable Cowork

1. Open **Claude Desktop** app
2. Go to **Settings** → **Features**
3. Enable **Cowork** toggle
4. Grant folder access when prompted

### 3. Your First Task

```
Create a folder: ~/Cowork-Workspace/
Add some files to organize
Prompt: "Organize the files in ~/Cowork-Workspace/ by type"
```

→ [Complete Getting Started Guide](guide/01-getting-started.md)

---

## Documentation Map

### Core Guides

| Guide | Description | Reading Time |
|-------|-------------|--------------|
| [Overview](guide/00-overview.md) | What is Cowork, architecture, who should use it | 5 min |
| [Getting Started](guide/01-getting-started.md) | Installation, setup, first workflow | 10 min |
| [Capabilities](guide/02-capabilities.md) | What Cowork can and cannot do | 8 min |
| [Security](guide/03-security.md) | Best practices, risk mitigation, safe usage | 12 min |
| [Troubleshooting](guide/04-troubleshooting.md) | Common issues, decision tree, recovery | 8 min |

### Workflows

| Workflow | Use Case | Complexity |
|----------|----------|------------|
| [File Organization](workflows/file-organization.md) | Downloads → structured folders | Beginner |
| [Expense Tracking](workflows/expense-tracking.md) | Receipts → Excel report | Intermediate |
| [Report Synthesis](workflows/report-synthesis.md) | Multi-doc → structured report | Intermediate |
| [Meeting Prep](workflows/meeting-prep.md) | Research → briefing document | Intermediate |
| [Team Handoff](workflows/team-handoff.md) | Dev ↔ Non-dev patterns | Advanced |

### Ready-to-Use Prompts

| Collection | Count | Description |
|------------|-------|-------------|
| [File Operations](prompts/file-ops.md) | 15+ | Organization, renaming, cleanup |
| [Document Creation](prompts/document-creation.md) | 15+ | Reports, summaries, presentations |
| [Data Extraction](prompts/data-extraction.md) | 15+ | Images → data, PDF parsing |
| [Research](prompts/research.md) | 10+ | Web research, synthesis |

### Reference

| Resource | Description |
|----------|-------------|
| [Cheatsheet](reference/cheatsheet.md) | 1-page printable quick reference |
| [Comparison](reference/comparison.md) | Code vs Cowork vs Projects decision matrix |
| [FAQ](reference/faq.md) | 20+ frequently asked questions |
| [Glossary](reference/glossary.md) | Cowork-specific terminology |

### Templates

| Template | Use Case |
|----------|----------|
| [CLAUDE.md for Cowork](examples/CLAUDE.md) | Project context file template |

---

## Key Differences: Code vs Cowork

| Aspect | Claude Code | Cowork |
|--------|-------------|--------|
| **User** | Developers | Knowledge workers |
| **Interface** | Terminal/CLI | Desktop app |
| **Execute code** | Yes | No |
| **File access** | Full filesystem | Sandboxed folder |
| **Outputs** | Any file type | Office docs, Excel, PDF |
| **Maturity** | Production-ready | Research preview |

→ [Full Comparison](reference/comparison.md)

---

## Safety First

Cowork has no official security documentation yet. Follow these practices:

1. **Dedicated workspace** — Never grant access to Documents or Desktop
2. **Review plans** — Check each step before execution
3. **No sensitive data** — Keep credentials out of workspace
4. **Backup first** — Before destructive operations

→ [Complete Security Guide](guide/03-security.md)

---

## Current Limitations (January 2026)

- macOS only (Windows planned, Linux not announced)
- Pro ($20/mo) or Max ($100-200/mo) subscription required
- Usage limits: resets every 5 hours, heavy tasks consume quota fast
- No cloud storage connectors confirmed
- Research preview = expect bugs
- No official security documentation

> ⚠️ **Usage Warning**: File organization and document processing tasks consume tokens rapidly. Pro tier may exhaust quota in 1-1.5 hours of intensive use. Max tier recommended for heavy workflows.

---

## Contributing

Found an issue or have a workflow to share?

1. Open an issue in the main [claude-code-ultimate-guide](https://github.com/your-repo) repo
2. Tag with `[cowork]` prefix
3. Include platform, subscription tier, and reproduction steps

---

## Navigation

```
cowork/
├── README.md                    ← You are here
├── guide/
│   ├── 00-overview.md
│   ├── 01-getting-started.md
│   ├── 02-capabilities.md
│   ├── 03-security.md
│   └── 04-troubleshooting.md
├── workflows/
│   ├── file-organization.md
│   ├── expense-tracking.md
│   ├── report-synthesis.md
│   ├── meeting-prep.md
│   └── team-handoff.md
├── prompts/
│   ├── file-ops.md
│   ├── document-creation.md
│   ├── data-extraction.md
│   └── research.md
├── reference/
│   ├── cheatsheet.md
│   ├── comparison.md
│   ├── faq.md
│   └── glossary.md
└── examples/
    └── CLAUDE.md
```

---

*Part of [Claude Code Ultimate Guide](../README.md) | [Main Guide](../guide/ultimate-guide.md)*
