# Search Tools Mastery: Combining rg, grepai, Serena & ast-grep

> **Master the art of code search by combining the right tools for maximum efficiency**

**Author**: Florian BRUNIAUX | Contributions from Claude (Anthropic)
**Reading time**: ~20 minutes
**Last updated**: January 2026

---

## Table of Contents

1. [Quick Reference Matrix](#quick-reference-matrix)
2. [Tool Comparison](#tool-comparison)
3. [Decision Tree](#decision-tree)
4. [Combined Workflows](#combined-workflows)
5. [Real-World Scenarios](#real-world-scenarios)
6. [Performance Optimization](#performance-optimization)
7. [Common Pitfalls](#common-pitfalls)

---

## Quick Reference Matrix

| I need to... | Use This Tool | Command Example |
|--------------|---------------|-----------------|
| Find exact text | `rg` (Grep tool) | `rg "authenticate" --type ts` |
| Find by meaning | `grepai` | `grepai search "user login flow"` |
| Find function definition | `Serena` | `serena find_symbol --name "login"` |
| Find structural pattern | `ast-grep` | `ast-grep "async function $F"` |
| See who calls function | `grepai` | `grepai trace callers "login"` |
| Get file structure | `Serena` | `serena get_symbols_overview` |
| Refactor across files | `Serena + ast-grep` | Combined workflow |
| Explore unknown codebase | `grepai → Serena` | Discovery pattern |

---

## Tool Comparison

### Complete Feature Matrix

| Feature | rg (ripgrep) | grepai | Serena | ast-grep |
|---------|--------------|--------|--------|----------|
| **Search Type** | Regex/text | Semantic (meaning) | Symbol-aware | AST structure |
| **Technology** | Pattern matching | Embeddings (Ollama) | Symbol parsing | Abstract Syntax Tree |
| **Speed** | ⚡ ~20ms | 🐢 ~500ms | ⚡ ~100ms | 🕐 ~200ms |
| **Setup** | ✅ None (built-in) | ⚠️ Ollama + install | ⚠️ MCP config | ⚠️ npm install |
| **Integration** | ✅ Native (`Grep`) | ⚠️ MCP server | ⚠️ MCP server | ⚠️ Plugin |
| **Privacy** | ✅ 100% local | ✅ 100% local | ✅ 100% local | ✅ 100% local |
| **Context needed** | None | None | Project indexation | None |
| **Languages** | All (text) | All | TS/JS/Py/Rust/Go | TS/JS/Py/Rust/Go/C++ |
| **Call graph** | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Symbol tracking** | ❌ No | ❌ No | ✅ Yes | ❌ No |
| **Session memory** | ❌ No | ❌ No | ✅ Yes | ❌ No |
| **False positives** | Medium | Low | Very low | Very low |
| **Learning curve** | Low | Medium | Low | High |

### Token Cost Comparison

| Tool | Typical Query | Tokens Consumed | Results Returned |
|------|---------------|-----------------|------------------|
| **rg** | "authenticate" | ~500 | Exact matches only |
| **grepai** | "auth flow" | ~2000 | Intent-based matches |
| **Serena** | find_symbol | ~1000 | Symbol + context |
| **ast-grep** | AST pattern | ~1500 | Structural matches |

**Key insight**: rg is 4x more token-efficient but 10x less intelligent than semantic tools.

---

## Decision Tree

### Level 1: What Do You Know?

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

### Level 2: What Are You Looking For?

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

### Level 3: Optimization

```
Found too many results?
│
├─ rg → Add --type filter or narrow path
├─ grepai → Add --path filter or use trace
├─ Serena → Filter by symbol type (function/class)
└─ ast-grep → Add constraints to pattern
```

---

## Combined Workflows

### Workflow 1: Exploring Unknown Codebase

**Goal**: Understand a new project quickly

**Step-by-step**:

```bash
# 1. SEMANTIC DISCOVERY (grepai)
# Find files related to authentication
grepai search "user authentication and session management"
# → Output: auth.service.ts, session.middleware.ts, user.controller.ts

# 2. STRUCTURAL OVERVIEW (Serena)
# Understand each file's structure
serena get_symbols_overview --file auth.service.ts
# → Output:
#   - class AuthService
#     - login(email, password)
#     - logout(sessionId)
#     - validateSession(token)

# 3. DEPENDENCY MAPPING (grepai trace)
# See how login is used
grepai trace callers "login"
# → Output: Called by UserController, ApiGateway, AdminPanel

# 4. EXACT SEARCH (rg)
# Find specific implementation details
rg "validateSession" --type ts -A 5
# → Output: Full function with 5 lines of context
```

**Result**: Complete understanding in 4 commands (vs 30+ file reads)

---

### Workflow 2: Large-Scale Refactoring

**Goal**: Rename `createSession` → `initializeUserSession` across 50+ files

**Step-by-step**:

```bash
# 1. IMPACT ANALYSIS (grepai trace)
# Understand full scope
grepai trace callers "createSession"
# → Output: 47 callers across 23 files
grepai trace callees "createSession"
# → Output: Calls validateUser, createToken, storeSession

# 2. STRUCTURAL VALIDATION (ast-grep)
# Ensure consistent usage pattern
ast-grep "createSession($$$ARGS)"
# → Output: All invocations with their argument patterns

# 3. SYMBOL-AWARE REFACTORING (Serena)
# Precise renaming
serena find_symbol --name "createSession" --include-body true
# → Get exact definition + all references

serena replace_symbol_body \
  --name "createSession" \
  --new-name "initializeUserSession"
# → Rename across all files maintaining structure

# 4. VERIFICATION (rg)
# Confirm no old references remain
rg "createSession" --type ts
# → Should return 0 results
```

**Result**: Safe refactoring with full dependency awareness

---

### Workflow 3: Security Audit

**Goal**: Find security vulnerabilities

**Step-by-step**:

```bash
# 1. SEMANTIC DISCOVERY (grepai)
# Find security-sensitive code
grepai search "SQL query construction"
grepai search "user input validation"
grepai search "password handling"

# 2. STRUCTURAL PATTERNS (ast-grep)
# Find specific vulnerability patterns

# SQL injection risks
ast-grep 'db.query(`${$VAR}`)'

# XSS risks
ast-grep 'innerHTML = $VAR'

# Missing error handling
ast-grep -p 'async function $F($$$) { $$$BODY }' \
  --without 'try { $$$TRY } catch'

# 3. DEPENDENCY TRACING (grepai)
# See where vulnerable code is called
grepai trace callers "executeQuery"
# → Identify all entry points

# 4. EXACT VERIFICATION (rg)
# Confirm findings
rg "innerHTML\s*=" --type ts
rg "password" --type ts | rg -v "hashed"
```

**Result**: Comprehensive security audit in minutes

---

## Real-World Benchmarks

### grepai vs grep (Janvier 2026)

**Contexte**: Benchmark sur Excalidraw (155k lignes TypeScript)
**Auteur**: YoanDev (mainteneur de grepai - biais potentiel)
**Méthodologie**: 5 questions de découverte de code identiques

| Métrique | grep | grepai | Différence |
|----------|------|--------|------------|
| Tool calls | 139 | 62 | **-55%** |
| Input tokens | 51k | 1.3k | **-97%** |

**À retenir**: Recherche sémantique réduit drastiquement les tokens en identifiant les fichiers pertinents dès la première tentative, évitant l'exploration itérative.

**Limitations**:
- Benchmark par le mainteneur de l'outil
- Single-project validation (TypeScript only)
- Pas de validation indépendante à ce jour

**Source**: [yoandev.co/grepai-benchmark](https://yoandev.co/grepai-benchmark)

> **Note**: Ce benchmark reflète l'état de janvier 2026. Les performances peuvent évoluer avec les mises à jour de Claude Code et grepai.

---

### Workflow 4: Framework Migration

**Goal**: Migrate React class components → hooks

**Step-by-step**:

```bash
# 1. INVENTORY (ast-grep)
# Find all class components
ast-grep 'class $C extends React.Component'
# → Output: 34 components to migrate

# 2. DEPENDENCY ANALYSIS (grepai)
# Understand component relationships
for component in $(ast-grep 'class $C extends' --json | jq -r '.[].name'); do
  grepai trace callers "$component"
done
# → Build migration order (leaf components first)

# 3. PATTERN DETECTION (ast-grep)
# Identify lifecycle methods used
ast-grep 'componentDidMount() { $$$BODY }'
ast-grep 'componentWillReceiveProps($$$) { $$$BODY }'
# → Map to equivalent hooks

# 4. INCREMENTAL MIGRATION (Serena + ast-grep)
# Migrate one component at a time
serena find_symbol --name "UserProfile" --include-body true
# → Get full component code

# Use ast-grep to transform
ast-grep --rewrite \
  --from 'class $C extends React.Component' \
  --to 'const $C = () => { }'

# 5. VERIFICATION (rg + grepai)
# Ensure migration successful
rg "React.Component" --type tsx  # Should decrease
grepai search "component lifecycle methods"  # Find any missed
```

**Result**: Systematic migration with minimal breakage

---

### Workflow 5: Performance Optimization

**Goal**: Identify and fix performance bottlenecks

**Step-by-step**:

```bash
# 1. HOTSPOT DISCOVERY (grepai)
# Find performance-critical code
grepai search "heavy computation or loops"
grepai search "database queries in loops"

# 2. PATTERN DETECTION (ast-grep)
# Find N+1 query patterns
ast-grep 'for ($$$) { await db.query($$$) }'

# Find missing memoization
ast-grep 'useMemo' --invert-match \
  --in 'const $VAR = $$$'

# 3. CALL GRAPH ANALYSIS (grepai trace)
# Find hot paths
grepai trace graph "renderUserList" --depth 3
# → Visualize dependency tree

# 4. SYMBOL TRACKING (Serena)
# Track function changes
serena write_memory "perf_baseline" \
  "renderUserList: 450ms avg"

# After optimization
serena write_memory "perf_optimized" \
  "renderUserList: 45ms avg (10x improvement)"

# 5. VERIFICATION (rg)
# Confirm optimizations applied
rg "useMemo|useCallback" --type tsx
```

**Result**: Data-driven performance improvements

---

## Real-World Scenarios

### Scenario 1: "I Don't Know What I'm Looking For"

**Problem**: New project, no documentation, need to add feature

**Solution**: Semantic-first discovery

```bash
# Start broad with meaning
grepai search "user profile management"
# → Discover relevant files

# Then narrow with structure
serena get_symbols_overview --file user-profile.service.ts
# → Understand available functions

# Finally, exact search for details
rg "updateProfile" --type ts -C 3
```

---

### Scenario 2: "This Function is Called from Everywhere"

**Problem**: Need to modify a function but worried about breaking things

**Solution**: Dependency mapping first

```bash
# 1. See all callers
grepai trace callers "calculateTotal"
# → 47 callers found

# 2. Analyze caller contexts
for file in $(grepai trace callers "calculateTotal" --json | jq -r '.[].file'); do
  serena get_symbols_overview --file "$file"
done

# 3. Identify safe vs risky call sites
ast-grep 'calculateTotal($ARGS)' --json
# → Group by argument patterns

# 4. Make change with confidence
# Now you know all impact points
```

---

### Scenario 3: "Find All Code Doing X"

**Problem**: Need to apply consistent pattern across codebase

**Solution**: Combine semantic + structural

```bash
# Example: Find all error handling code

# 1. Semantic discovery
grepai search "error handling and exception management"

# 2. Structural patterns
ast-grep 'try { $$$TRY } catch ($ERR) { $$$CATCH }'
ast-grep 'throw new Error($MSG)'

# 3. Verify consistency
rg "catch\s*\(" --type ts | wc -l
# Compare with ast-grep count to find anomalies
```

---

### Scenario 4: "I Need to Understand This Module"

**Problem**: Complex module with unclear responsibilities

**Solution**: Multi-tool analysis

```bash
# 1. Get symbol overview (Serena)
serena get_symbols_overview --file payment.module.ts
# → See all exports, classes, functions

# 2. Understand dependencies (grepai)
grepai trace callees "PaymentModule"
# → What does this module use?

grepai trace callers "PaymentModule"
# → Who uses this module?

# 3. Find implementation patterns (ast-grep)
ast-grep 'export class $C' --file payment.module.ts
ast-grep 'async $METHOD($$$)' --file payment.module.ts

# 4. Read specific implementations (rg)
rg "processPayment" --type ts -A 20
```

---

## Performance Optimization

### Choosing the Fastest Tool

**General Rules**:

1. **Known exact text** → Always use rg first
2. **Unknown exact text** → Use grepai, then rg for verification
3. **Refactoring** → Serena for symbol safety
4. **Large migrations** → ast-grep for structural precision

### Performance Benchmarks

**Test**: Find authentication code in 500k line codebase

| Strategy | Time | Results Quality |
|----------|------|-----------------|
| rg "auth" only | 0.2s | 5000+ false positives |
| grepai "auth" only | 2.5s | 50 relevant results |
| grepai → rg (combined) | 2.7s | 50 relevant, verified |
| Serena symbols only | 1.5s | 12 auth functions |
| ast-grep patterns | 3.0s | 8 auth flows |

**Winner**: Serena symbols (fastest + high quality) for known function names

### Parallelization Strategy

**For large codebases (>100k lines)**:

```bash
# Run searches in parallel

# Terminal 1: Semantic discovery
grepai search "authentication flow" > /tmp/grepai-results.json &

# Terminal 2: Symbol indexing
serena get_symbols_overview --file src/**/*.ts > /tmp/symbols.json &

# Terminal 3: Pattern detection
ast-grep 'async function $F' --json > /tmp/ast-results.json &

# Wait for all, then combine results
wait
jq -s '.[0] + .[1] + .[2]' \
  /tmp/grepai-results.json \
  /tmp/symbols.json \
  /tmp/ast-results.json
```

---

## Common Pitfalls

### Pitfall 1: Using Semantic Search for Exact Matches

❌ **Wrong**:
```bash
grepai search "createSession"  # Slow, overkill
```

✅ **Right**:
```bash
rg "createSession" --type ts  # Fast, precise
```

**Rule**: If you know the exact text, never use semantic search.

---

### Pitfall 2: Using rg for Conceptual Search

❌ **Wrong**:
```bash
rg "auth.*login.*session" --type ts  # Misses variations
```

✅ **Right**:
```bash
grepai search "authentication and session management"
```

**Rule**: Regex doesn't understand meaning, use semantic tools.

---

### Pitfall 3: Ignoring Call Graph Before Refactoring

❌ **Wrong**:
```bash
# Directly refactor without checking callers
rg "oldFunction" --type ts | sed 's/oldFunction/newFunction/g'
```

✅ **Right**:
```bash
# Check impact first
grepai trace callers "oldFunction"
# See 47 callers across 23 files
# Then plan refactoring strategy
```

**Rule**: Always trace dependencies before modifying shared code.

---

### Pitfall 4: Not Combining Tools

❌ **Wrong**:
```bash
# Use only one tool for complex task
ast-grep 'async function $F' --json | jq '.[].file' | xargs -I {} vim {}
# Blindly edit without understanding context
```

✅ **Right**:
```bash
# Combine for full understanding
ast-grep 'async function $F' --json > /tmp/async.json
for file in $(jq -r '.[].file' /tmp/async.json); do
  serena get_symbols_overview --file "$file"  # Context
  grepai trace callers "$(jq -r '.[].name' /tmp/async.json)"  # Usage
done
```

**Rule**: Complex tasks need multiple perspectives.

---

### Pitfall 5: Over-Engineering Simple Searches

❌ **Wrong**:
```bash
# Setup grepai + Ollama just to find a TODO comment
grepai search "TODO comments in the code"
```

✅ **Right**:
```bash
rg "TODO" --type ts
```

**Rule**: Use the simplest tool that works.

---

## Tool Selection Cheatsheet

### Quick Decision Matrix

| Your Situation | Use This | Not This |
|----------------|----------|----------|
| "Find function `login`" | rg "login" | grepai search "login" |
| "Find login-related code" | grepai "login flow" | rg "login.*" |
| "Rename function safely" | Serena find_symbol | rg + sed |
| "Who calls this function?" | grepai trace callers | rg + grep |
| "Get file structure" | Serena overview | rg "class\|function" |
| "Find async without try/catch" | ast-grep | rg "async.*{" |
| "Migrate React classes" | ast-grep | rg + manual |
| "Find TODOs" | rg "TODO" | Any other tool |

---

## Setup Priority

**Recommended Setup Order**:

1. **Start**: rg (already built-in with Grep tool) ✅
2. **Next**: Serena MCP (symbol awareness, session memory)
3. **Then**: grepai (semantic search + call graph)
4. **Finally**: ast-grep (structural patterns, large refactoring)

**Rationale**: 90% of searches work with rg + Serena. Add grepai for semantic needs. Only add ast-grep if doing large-scale refactoring/migration.

---

## Summary: The 4-Tool Symphony

```
┌─────────────────────────────────────────────────────────┐
│                   SEARCH TOOL MASTERY                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  rg (ripgrep)     →  Fast, exact text matching         │
│  ├─ Use: 90% of searches                               │
│  └─ Speed: ⚡ ~20ms                                     │
│                                                         │
│  grepai           →  Semantic + Call graph             │
│  ├─ Use: Concept discovery, dependency tracing         │
│  └─ Speed: 🐢 ~500ms (but finds what rg can't)        │
│                                                         │
│  Serena           →  Symbol-aware + Session memory     │
│  ├─ Use: Refactoring, structure understanding          │
│  └─ Speed: ⚡ ~100ms                                    │
│                                                         │
│  ast-grep         →  AST structural patterns           │
│  ├─ Use: Large migrations, complex patterns            │
│  └─ Speed: 🕐 ~200ms                                   │
│                                                         │
│  ═══════════════════════════════════════════════════   │
│                                                         │
│  Master the combination, not individual tools.          │
│  Each tool has a sweet spot — use the right one.       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Further Reading

- [Serena MCP Guide](../ultimate-guide.md#serena-semantic-code-analysis)
- [grepai Documentation](../ultimate-guide.md#grepai-recommended-semantic-search)
- [ast-grep Patterns Skill](../../examples/skills/ast-grep-patterns.md)
- [Architecture: Grep vs RAG History](../architecture.md#search-strategy-evolution)

---

**Last updated**: January 2026
**Compatible with**: Claude Code 2.1.7+
