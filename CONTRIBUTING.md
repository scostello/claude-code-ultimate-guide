# Contributing to The Ultimate Claude Code Guide

Thank you for your interest in improving this guide! Every contribution helps make Claude Code more accessible to developers worldwide.

## How to Contribute

### Reporting Issues

Found an error, outdated information, or have a suggestion?

1. **Check existing issues** - Someone may have reported it already
2. **Open a new issue** with:
   - Clear description of the problem or suggestion
   - Location in the guide (section, line if applicable)
   - Your platform (macOS/Linux/Windows)
   - For Windows issues: PowerShell version

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b fix/typo-in-section-3`
3. **Make your changes**
4. **Test on your platform** (especially commands and code snippets)
5. **Submit a PR** with:
   - Clear description of changes
   - Why the change is needed
   - Any testing performed

## Content Guidelines

### Writing Style

- **Be concise** - Prefer bullet points over long paragraphs
- **Be practical** - Include examples for every concept
- **Be inclusive** - Support both macOS/Linux AND Windows users
- **Be accurate** - Test all code snippets before submitting

### Documentation Structure

```markdown
## Section Title

Brief introduction (1-2 sentences max).

### Subsection

| Column 1 | Column 2 |
|----------|----------|
| Data     | Data     |

**Example:**
```code
example here
```
```

### Code Snippets

- **Test before submitting** - All code must work
- **Include both platforms** when commands differ:

```bash
# macOS/Linux
~/.claude/settings.json

# Windows
%USERPROFILE%\.claude\settings.json
```

### Formatting

- Use tables for comparisons
- Use code blocks with language hints
- Use `**bold**` for emphasis
- Use `backticks` for inline code
- Reference sections with anchors: `[Section Name](#section-anchor)`

## Platform-Specific Contributions

### Windows Contributions (Especially Welcome!)

The author works on macOS and hasn't tested Windows commands. If you're a Windows user:

- **Test all PowerShell scripts** with PS 5.1+
- **Test batch file alternatives** when possible
- **Verify paths** work correctly
- **Report issues** with Windows-specific instructions

Your contributions are especially valuable!

### Cross-Platform Guidelines

- Use `npm` commands (cross-platform) over `curl` (Unix-only)
- Specify paths for both platforms
- Note differences in shell syntax
- Test on your platform, note what you tested

## Quality Checklist

Before submitting a PR, verify:

- [ ] Markdown renders correctly (preview in GitHub)
- [ ] All links work
- [ ] Code snippets are tested
- [ ] Windows equivalents provided (if applicable)
- [ ] No typos (run spell check)
- [ ] Follows existing style
- [ ] Adds value (not just reformatting)

## Types of Contributions

### Quick Fixes (< 5 minutes)
- Typo corrections
- Broken link fixes
- Minor clarifications

### Enhancements (5-30 minutes)
- Add missing examples
- Improve explanations
- Add Windows equivalents
- Update outdated information

### New Content (30+ minutes)
- New sections or guides
- New example templates
- Translations
- Comprehensive rewrites

## Not Accepted

- Marketing language or promotional content
- Unverified or speculative information
- Breaking changes to structure without discussion
- Large changes without prior issue discussion

## Recognition

Contributors are recognized through:

- **Git history** - Your commits are permanently attributed
- **GitHub contributors** - Visible on the repository page

For significant contributions, we may add you to a "Contributors" section.

## Questions?

- Open an issue for general questions
- Reach out on [LinkedIn](https://www.linkedin.com/in/florian-bruniaux-43408b83/) for direct contact

---

Thank you for helping improve this guide!
