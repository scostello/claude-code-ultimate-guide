# Ideas to Dig

> Research topics for future guide improvements. Curated and validated.

## High Priority

### MCP Security Hardening
Unified security research covering MCP vulnerabilities, prompt injection, and secret detection.

**Topics:**
- Real-world Tool Shadowing and Confused Deputy incidents
- Prompt injection bypass techniques (Unicode, encoding, obfuscation)
- Secret detection regex patterns (compare GitHub, Gitleaks, TruffleHog)
- Supply chain risks in MCP server ecosystem

**Perplexity Query:**
```
MCP Model Context Protocol security vulnerabilities 2024-2025:
- Tool shadowing attacks
- Prompt injection bypass techniques for coding assistants
- Secret detection regex patterns comparison (GitHub vs Gitleaks vs TruffleHog)
Include real incidents if documented.
```

---

## Medium Priority

### CI/CD Workflows Gallery
Concrete GitHub Actions examples for Claude Code integration.

**Topics:**
- Automated PR review workflows
- Test generation pipelines
- Cost optimization patterns for API calls in CI
- Pre-commit hooks integration

**Perplexity Query:**
```
GitHub Actions workflows for AI coding assistants 2024-2025:
- Automated code review with Claude/GPT
- Cost optimization for API calls in CI/CD
- Real examples from open source projects
```

### MCP Server Catalog
Exhaustive list of MCP servers with real-world use cases.

**Topics:**
- Available servers by category (dev tools, databases, APIs)
- Performance benchmarks vs native tools
- Security trust levels per server
- Custom server development patterns

**Perplexity Query:**
```
MCP Model Context Protocol servers catalog 2024-2025:
- Most useful servers for developers
- Performance comparison MCP vs native tools
- How to build custom MCP servers
```

---

## Lower Priority

### CLAUDE.md Patterns Library
Stack-specific templates for common project types.

**Topics:**
- React/Next.js optimized configurations
- Python/FastAPI patterns
- Go project conventions
- Monorepo configurations

**Perplexity Query:**
```
CLAUDE.md configuration examples by framework:
- React, Next.js, Vue patterns
- Python, FastAPI, Django patterns
- Best practices from GitHub repositories
```

---

## Discarded Ideas

| Idea | Reason Discarded |
|------|------------------|
| LLM Fine-tuning guide | Out of scope - users don't control model training |
| Model architecture internals | Too theoretical, not actionable |
| Token pricing optimization | Changes too frequently, use official docs |
| A2A Protocol (Agent-to-Agent) | Claude Code is single-agent with sub-agents, not true multi-agent |
| AgentOps Enterprise Dashboard | Infrastructure doesn't exist for CLI tool |
| LLM-as-a-Judge evaluation | Overkill for CLI, adds latency without proportional value |
| Decision Trajectory logging | No access to internal traces (black box) |
| 4 Pillars formal framework | Too academic - guide already covers symptoms pragmatically |
| Canary/Blue-Green deployments | Infrastructure patterns, not relevant for CLI |
| Memory Poisoning defenses | Theoretical risk requiring prior system compromise |
| Prompt Engineering for Code Gen | Already well covered (xml_prompting, prompt_formula) |
| Context Window Optimization | Already well covered (context_management, context_triage) |
| Task Decomposition Patterns | Covered via plan_mode, interaction_loop |
| Agent Architecture Comparisons | Out of scope - not multi-agent theory |
| Real-World Case Studies | Non-verifiable metrics, marketing-prone |
| Comparison with Other Tools | Out of scope, rapid obsolescence |

---

## Contributing

Found something interesting? Add it with:
1. Topic name and why it matters
2. Specific research questions
3. Perplexity query to start
