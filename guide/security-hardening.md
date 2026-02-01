# Security Hardening Guide

> **Confidence**: Tier 2 — Based on CVE disclosures, security research (2024-2025), and community validation
>
> **Scope**: Active threats (attacks, injection, CVE). For data retention and privacy, see [data-privacy.md](./data-privacy.md)

---

## TL;DR - Decision Matrix

| Your Situation | Immediate Action | Time |
|----------------|------------------|------|
| **Solo dev, public repos** | Install output scanner hook | 5 min |
| **Team, sensitive codebase** | + MCP vetting + injection hooks | 30 min |
| **Enterprise, production** | + ZDR + integrity verification | 2 hours |

**Right now**: Check your MCPs against the [Safe List](#mcp-safe-list-community-vetted) below.

> **NEVER**: Approve MCPs from unknown sources without version pinning.
> **NEVER**: Run database MCPs on production without read-only credentials.

---

## Part 1: Prevention (Before You Start)

### 1.1 MCP Vetting Workflow

Model Context Protocol (MCP) servers extend Claude Code's capabilities but introduce significant attack surface. Understanding the threat model is essential.

#### Attack: MCP Rug Pull

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

This attack exploits the one-time approval model: once you approve an MCP, updates execute automatically without re-consent.

#### CVE Summary (2025)

| CVE | Severity | Impact | Mitigation |
|-----|----------|--------|------------|
| **CVE-2025-53109/53110** | High | Filesystem MCP sandbox escape via prefix bypass + symlinks | Avoid Filesystem MCP or apply patch |
| **CVE-2025-54135** | High (8.6) | RCE in Cursor via prompt injection rewriting mcp.json | File integrity monitoring hook |
| **CVE-2025-54136** | High | Persistent team backdoor via post-approval config tampering | Git hooks + hash verification |
| **CVE-2025-49596** | Critical (9.4) | RCE in MCP Inspector tool | Update to patched version |

**Source**: [Cymulate EscapeRoute](https://cymulate.com/blog/cve-2025-53109-53110-escaperoute-anthropic/), [Checkpoint MCPoison](https://research.checkpoint.com/2025/cursor-vulnerability-mcpoison/), [Cato CurXecute](https://www.catonetworks.com/blog/curxecute-rce/)

#### Attack Patterns

| Pattern | Description | Detection |
|---------|-------------|-----------|
| **Tool Poisoning** | Malicious instructions in tool metadata (descriptions, schemas) influence LLM before execution | Schema diff monitoring |
| **Rug Pull** | Benign server turns malicious after gaining trust | Version pinning + hash verify |
| **Confused Deputy** | Attacker registers tool with trusted name on untrusted server | Namespace verification |

#### 5-Minute MCP Audit

Before adding any MCP server, complete this checklist:

| Step | Command/Action | Pass Criteria |
|------|----------------|---------------|
| **1. Source** | `gh repo view <mcp-repo>` | Stars >50, commits <30 days |
| **2. Permissions** | Review `mcp.json` config | No `--dangerous-*` flags |
| **3. Version** | Check version string | Pinned (not "latest" or "main") |
| **4. Hash** | `sha256sum <mcp-binary>` | Matches release checksum |
| **5. Audit** | Review recent commits | No suspicious changes |

#### MCP Safe List (Community Vetted)

| MCP Server | Status | Notes |
|------------|--------|-------|
| `@anthropic/mcp-server-*` | Safe | Official Anthropic servers |
| `context7` | Safe | Read-only documentation lookup |
| `sequential-thinking` | Safe | No external access, local reasoning |
| `memory` | Safe | Local file-based persistence |
| `filesystem` (unrestricted) | Risk | CVE-2025-53109/53110 - use with caution |
| `database` (prod credentials) | Unsafe | Exfiltration risk - use read-only |
| `browser` (full access) | Risk | Can navigate to malicious sites |

*Last updated: 2026-01-15. [Report new assessments](../../issues)*

#### Secure MCP Configuration Example

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server@1.2.3"],
      "env": {}
    },
    "database": {
      "command": "npx",
      "args": ["-y", "@company/db-mcp@2.0.1"],
      "env": {
        "DB_HOST": "readonly-replica.internal",
        "DB_USER": "readonly_user"
      }
    }
  }
}
```

**Key practices**:
- Pin exact versions (`@1.2.3`, not `@latest`)
- Use read-only database credentials
- Minimize environment variables exposed

### 1.2 Agent Skills Supply Chain Risks

Third-party Agent Skills (installed via `npx add-skill` or plugin marketplaces) introduce supply chain risks similar to npm packages. Research by [SafeDep](https://safedep.io/agent-skills-threat-model) identified vulnerabilities in **8-14% of publicly available skills**, including prompt injection, data exfiltration, and privilege escalation.

**Mitigations**:
- **Review SKILL.md before installing** — Check `allowed-tools` for unexpected access (especially `Bash`)
- **Validate with skills-ref** — `skills-ref validate ./skill-dir` checks spec compliance ([agentskills.io](https://agentskills.io))
- **Pin skill versions** — Use specific commit hashes when installing from GitHub
- **Audit scripts/** — Executable scripts bundled with skills are the highest-risk component

### 1.3 Known Limitations of permissions.deny

The `permissions.deny` setting in `.claude/settings.json` is the official method to block Claude from accessing sensitive files. However, security researchers have documented architectural limitations.

#### What permissions.deny Blocks

| Operation | Blocked? | Notes |
|-----------|----------|-------|
| `Read()` tool calls | ✅ Yes | Primary blocking mechanism |
| `Edit()` tool calls | ✅ Yes | With explicit deny rule |
| `Write()` tool calls | ✅ Yes | With explicit deny rule |
| `Bash(cat .env)` | ✅ Yes | With explicit deny rule |
| `Glob()` patterns | ✅ Yes | Handled by Read rules |
| `ls .env*` (filenames) | ⚠️ Partial | Exposes file existence, not contents |

#### Known Security Gaps

| Gap | Description | Source |
|-----|-------------|--------|
| **System reminders** | Background indexing may expose file contents via internal "system reminder" mechanism before tool permission checks | [GitHub #4160](https://github.com/anthropics/claude-code/issues/4160) |
| **Bash wildcards** | Generic bash commands without explicit deny rules may access files | Security research |
| **Indexing timing** | File watching operates at a layer below tool permissions | [GitHub #4160](https://github.com/anthropics/claude-code/issues/4160) |

#### Recommended Configuration

Block **all** access vectors, not just `Read`:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env*)",
      "Edit(./.env*)",
      "Write(./.env*)",
      "Bash(cat .env*)",
      "Bash(head .env*)",
      "Bash(tail .env*)",
      "Bash(grep .env*)",
      "Read(./secrets/**)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)"
    ]
  }
}
```

#### Defense-in-Depth Strategy

Because `permissions.deny` alone cannot guarantee complete protection:

1. **Store secrets outside project directories** — Use `~/.secrets/` or external vault
2. **Use external secrets management** — AWS Secrets Manager, 1Password, HashiCorp Vault
3. **Add PreToolUse hooks** — Secondary blocking layer (see [Section 2.3](#23-hook-stack-setup))
4. **Never commit secrets** — Even "blocked" files can leak through other vectors
5. **Review bash commands** — Manually inspect before approving execution

> **Bottom line**: `permissions.deny` is necessary but not sufficient. Treat it as one layer in a defense-in-depth strategy, not a complete solution.

### 1.4 Repository Pre-Scan

Before opening untrusted repositories, scan for injection vectors:

**High-risk files to inspect**:
- `README.md`, `SECURITY.md` — Hidden HTML comments with instructions
- `package.json`, `pyproject.toml` — Malicious scripts in hooks
- `.cursor/`, `.claude/` — Tampered configuration files
- `CONTRIBUTING.md` — Social engineering instructions

**Quick scan command**:
```bash
# Check for hidden instructions in markdown
grep -r "<!--" . --include="*.md" | head -20

# Check for suspicious npm scripts
jq '.scripts' package.json 2>/dev/null

# Check for base64 in comments
grep -rE "#.*[A-Za-z0-9+/]{20,}={0,2}" . --include="*.py" --include="*.js"
```

Use the [repo-integrity-scanner.sh](../examples/hooks/bash/repo-integrity-scanner.sh) hook for automated scanning.

---

## Part 2: Detection (While You Work)

### 2.1 Prompt Injection Detection

Coding assistants are vulnerable to indirect prompt injection through code context. Attackers embed instructions in files that Claude reads automatically.

#### Evasion Techniques

| Technique | Example | Risk | Detection |
|-----------|---------|------|-----------|
| **Zero-width chars** | `U+200B`, `U+200C`, `U+200D` | Instructions invisible to humans | Unicode regex |
| **RTL override** | `U+202E` reverses text display | Hidden command appears normal | Bidirectional scan |
| **ANSI escape** | `\x1b[` terminal sequences | Terminal manipulation | Escape filter |
| **Null byte** | `\x00` truncation attacks | Bypass string checks | Null detection |
| **Base64 comments** | `# SGlkZGVuOiBpZ25vcmU=` | LLM decodes automatically | Entropy check |
| **Nested commands** | `$(evil_command)` | Bypass denylist via substitution | Pattern block |
| **Homoglyphs** | Cyrillic `а` vs Latin `a` | Keyword filter bypass | Normalization |

#### Detection Patterns

```bash
# Zero-width + RTL + Bidirectional
[\x{200B}-\x{200D}\x{FEFF}\x{202A}-\x{202E}\x{2066}-\x{2069}]

# ANSI escape sequences (terminal injection)
\x1b\[|\x1b\]|\x1b\(

# Null bytes (truncation attacks)
\x00

# Tag characters (invisible Unicode block)
[\x{E0000}-\x{E007F}]

# Base64 in comments (high entropy)
[#;].*[A-Za-z0-9+/]{20,}={0,2}

# Nested command execution
\$\([^)]+\)|\`[^\`]+\`
```

#### Existing vs New Patterns

The [prompt-injection-detector.sh](../examples/hooks/bash/prompt-injection-detector.sh) hook includes:

| Pattern | Status | Location |
|---------|--------|----------|
| Role override (`ignore previous`) | Exists | Lines 50-72 |
| Jailbreak attempts | Exists | Lines 74-95 |
| Authority impersonation | Exists | Lines 120-145 |
| Base64 payload detection | Exists | Lines 148-160 |
| Zero-width characters | **New** | Added in v3.6.0 |
| ANSI escape sequences | **New** | Added in v3.6.0 |
| Null byte injection | **New** | Added in v3.6.0 |
| Nested command `$()` | **New** | Added in v3.6.0 |

### 2.2 Secret & Output Monitoring

#### Tool Comparison

| Tool | Recall | Precision | Speed | Best For |
|------|--------|-----------|-------|----------|
| **Gitleaks** | 88% | 46% | Fast (~2 min/100K commits) | Pre-commit hooks |
| **TruffleHog** | 52% | 85% | Slow (~15 min) | CI verification |
| **GitGuardian** | 80% | 95% | Cloud | Enterprise monitoring |
| **detect-secrets** | 60% | 98% | Fast | Baseline approach |

**Recommended stack**:
```
Pre-commit → Gitleaks (catch early, accept some FP)
CI/CD → TruffleHog (verify with API validation)
Monitoring → GitGuardian (if budget allows)
```

#### Environment Variable Leakage

58% of leaked credentials are "generic secrets" (passwords, tokens without recognizable format). Watch for:

| Vector | Example | Mitigation |
|--------|---------|------------|
| `env` / `printenv` output | Dumps all environment | Block in output scanner |
| `/proc/self/environ` access | Linux env read | Block file access pattern |
| Error messages with creds | Stack trace with DB password | Redact before display |
| Bash history exposure | Commands with inline secrets | History sanitization |

#### MCP Secret Scanner (Conceptual)

```bash
# Add Gitleaks as MCP tool for on-demand scanning
claude mcp add gitleaks-scanner -- gitleaks detect --source . --report-format json

# Usage in conversation
"Scan this repo for secrets before I commit"
```

### 2.3 Hook Stack Setup

Recommended security hook configuration for `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          "~/.claude/hooks/dangerous-actions-blocker.sh"
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          "~/.claude/hooks/prompt-injection-detector.sh",
          "~/.claude/hooks/unicode-injection-scanner.sh"
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          "~/.claude/hooks/output-secrets-scanner.sh"
        ]
      }
    ],
    "SessionStart": [
      "~/.claude/hooks/mcp-config-integrity.sh"
    ]
  }
}
```

**Hook installation**:
```bash
# Copy hooks to Claude directory
cp examples/hooks/bash/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

---

## Part 3: Response (When Things Go Wrong)

### 3.1 Secret Exposed

**First 15 minutes** (stop the bleeding):

1. **Revoke immediately**
   ```bash
   # AWS
   aws iam delete-access-key --access-key-id AKIA... --user-name <user>

   # GitHub
   # Settings → Developer settings → Personal access tokens → Revoke

   # Stripe
   # Dashboard → Developers → API keys → Roll key
   ```

2. **Confirm exposure scope**
   ```bash
   # Check if pushed to remote
   git log --oneline origin/main..HEAD

   # Search for the secret pattern
   git log -p | grep -E "(AKIA|sk_live_|ghp_|xoxb-)"

   # Full repo scan
   gitleaks detect --source . --report-format json > exposure-report.json
   ```

**First hour** (assess damage):

3. **Audit git history**
   ```bash
   # If pushed, you may need to rewrite history
   git filter-repo --invert-paths --path <file-with-secret>
   # WARNING: This rewrites history - coordinate with team
   ```

4. **Scan dependencies** for leaked keys in logs or configs

5. **Check CI/CD logs** for secret exposure in build outputs

**First 24 hours** (remediate):

6. **Rotate ALL related credentials** (assume lateral movement)

7. **Notify team/compliance** if required (GDPR, SOC2, HIPAA)

8. **Document incident timeline** for post-mortem

### 3.2 MCP Compromised

If you suspect an MCP server has been compromised:

1. **Disable immediately**
   ```bash
   # Remove from config
   jq 'del(.mcpServers.<suspect>)' ~/.claude/mcp.json > tmp && mv tmp ~/.claude/mcp.json

   # Or edit manually and restart Claude
   ```

2. **Verify config integrity**
   ```bash
   # Check for unauthorized changes
   sha256sum ~/.claude/mcp.json
   diff ~/.claude/mcp.json ~/.claude/mcp.json.backup

   # Check project-level config too
   cat .mcp.json 2>/dev/null
   ```

3. **Audit recent actions**
   - Review session logs in `~/.claude/logs/`
   - Check for unexpected file modifications
   - Scan for new files in sensitive directories

4. **Restore from known-good backup**
   ```bash
   cp ~/.claude/mcp.json.backup ~/.claude/mcp.json
   ```

### 3.3 Automated Security Audit

For comprehensive security scanning, use the [security-auditor agent](../examples/agents/security-auditor.md):

```bash
# Run OWASP-based security audit
claude -a security-auditor "Audit this project for security vulnerabilities"
```

The agent checks:
- Dependency vulnerabilities (npm audit, pip-audit)
- Code security patterns (OWASP Top 10)
- Configuration security (exposed secrets, weak permissions)
- MCP server risk assessment

---

## Appendix: Quick Reference

### Security Posture Levels

| Level | Measures | Time | For |
|-------|----------|------|-----|
| **Basic** | Output scanner + dangerous blocker | 5 min | Solo dev, experiments |
| **Standard** | + Injection hooks + MCP vetting | 30 min | Teams, sensitive code |
| **Hardened** | + Integrity verification + ZDR | 2 hours | Enterprise, production |

### Command Quick Reference

```bash
# Scan for secrets
gitleaks detect --source . --verbose

# Check MCP config
cat ~/.claude/mcp.json | jq '.mcpServers | keys'

# Verify hook installation
ls -la ~/.claude/hooks/

# Test Unicode detection
echo -e "test\u200Bhidden" | grep -P '[\x{200B}-\x{200D}]'
```

---

## See Also

- [Data Privacy Guide](./data-privacy.md) — Retention policies, compliance, what data leaves your machine
- [AI Traceability](./ai-traceability.md) — PromptPwnd vulnerability, CI/CD security, attribution policies
- [Security Checklist Skill](../examples/skills/security-checklist.md) — OWASP Top 10 patterns for code review
- [Security Auditor Agent](../examples/agents/security-auditor.md) — Automated vulnerability scanning
- [Ultimate Guide §7.4](./ultimate-guide.md#74-security-hooks) — Hook system basics
- [Ultimate Guide §8.6](./ultimate-guide.md#86-mcp-security) — MCP security overview

## References

- **CVE-2025-53109/53110** (EscapeRoute): [Cymulate Blog](https://cymulate.com/blog/cve-2025-53109-53110-escaperoute-anthropic/)
- **CVE-2025-54135** (CurXecute): [Cato Networks](https://www.catonetworks.com/blog/curxecute-rce/)
- **CVE-2025-54136** (MCPoison): [Checkpoint Research](https://research.checkpoint.com/2025/cursor-vulnerability-mcpoison/)
- **GitGuardian State of Secrets 2025**: [gitguardian.com](https://www.gitguardian.com/state-of-secrets-sprawl-report-2025)
- **Prompt Injection Research**: [Arxiv 2509.22040](https://arxiv.org/abs/2509.22040)
- **MCP Security Best Practices**: [modelcontextprotocol.io](https://modelcontextprotocol.io/specification/draft/basic/security_best_practices)

---

*Version 1.0.0 | January 2026 | Part of [Claude Code Ultimate Guide](../README.md)*
