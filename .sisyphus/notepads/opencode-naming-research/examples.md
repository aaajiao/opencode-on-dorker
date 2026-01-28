# Real-World OpenCode Project Examples

## Anthropic Skills Repository
**URL:** https://github.com/anthropics/skills
**Stars:** 56.8k
**Structure:**
```
anthropics/skills/
├── skills/
│   ├── algorithmic-art/SKILL.md
│   ├── brand-guidelines/SKILL.md
│   ├── canvas-design/SKILL.md
│   ├── doc-coauthoring/SKILL.md
│   ├── docx/SKILL.md
│   ├── frontend-design/SKILL.md
│   ├── internal-comms/SKILL.md
│   ├── mcp-builder/SKILL.md
│   ├── pdf/SKILL.md
│   ├── pptx/SKILL.md
│   ├── skill-creator/SKILL.md
│   ├── slack-gif-creator/SKILL.md
│   ├── theme-factory/SKILL.md
│   ├── web-artifacts-builder/SKILL.md
│   ├── webapp-testing/SKILL.md
│   └── xlsx/SKILL.md
├── spec/
└── template/
```
**Pattern:** PLURAL `skills/` at repository root (not `.opencode/`)

## Superpowers Project
**URL:** https://github.com/obra/superpowers
**Stars:** 38.7k
**Structure:**
```
obra/superpowers/
├── .opencode/
│   ├── INSTALL.md
│   └── plugins/
├── skills/
│   ├── brainstorming/SKILL.md
│   ├── dispatching-parallel-agents/SKILL.md
│   ├── executing-plans/SKILL.md
│   ├── finishing-a-development-branch/SKILL.md
│   ├── receiving-code-review/SKILL.md
│   ├── requesting-code-review/SKILL.md
│   ├── subagent-driven-development/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── test-driven-development/SKILL.md
│   ├── using-git-worktrees/SKILL.md
│   ├── using-superpowers/SKILL.md
│   ├── verification-before-completion/SKILL.md
│   ├── writing-plans/SKILL.md
│   └── writing-skills/SKILL.md
├── .claude-plugin/
├── .codex/
├── agents/
├── commands/
└── docs/
```
**Pattern:** PLURAL `skills/` at repository root

## Oh-My-OpenCode
**URL:** https://github.com/code-yeongyu/oh-my-opencode
**Stars:** 25.4k
**Structure:**
```
code-yeongyu/oh-my-opencode/
├── .opencode/
│   ├── background-tasks.json
│   └── command/
├── .github/
├── assets/
├── bin/
├── docs/
├── packages/
├── script/
├── signatures/
└── src/
```
**Pattern:** Uses `.opencode/command/` (not skills)

## OpenCode Skills Plugin (Archived)
**URL:** https://github.com/malhashemi/opencode-skills
**Status:** Archived Dec 23, 2025
**Migration Guide:**
```bash
# Old (plugin era)
mv .opencode/skills skill

# New (native support)
# Skills now at: skill/ (singular) or ~/.config/opencode/skill/
```
**Pattern:** Migrated from PLURAL to SINGULAR

## Consensus

**Most visible projects use PLURAL `skills/` at root level**
- Anthropic (official): `skills/`
- Superpowers: `skills/`
- OpenCode docs: `skills/`

**But OpenCode implementation uses SINGULAR `skill/`**
- Current code: `skill/` (singular)
- Migration guide: `skill/` (singular)
- GitHub issues: Confirm `skill/` works, `skills/` doesn't

**Recommendation:** Use `skill/` (singular) for reliability
