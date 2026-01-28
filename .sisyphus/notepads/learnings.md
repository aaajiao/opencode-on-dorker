
## Oh-My-OpenCode Directory Naming Conventions (2026-01-28)

### Key Finding: Use PLURAL `skills` (not singular `skill`)

**Official Convention**: All skill directories must use `skills` (plural)
- `.opencode/skills/my-skill/SKILL.md` ✅
- `~/.config/opencode/skills/my-skill/SKILL.md` ✅
- `.claude/skills/my-skill/SKILL.md` ✅

**NOT**: `skill` (singular) - this was a bug that was fixed in PR #966 on 2026-01-21

### Community Context

- **Issue #930**: Users reported skills not loading with oh-my-opencode
- **Root Cause**: Documentation said `skill` but code expected `skills`
- **Fix**: PR #966 (commit 1a410612) changed all paths to use `skills`
- **Impact**: Resolved blocking issue for community skill adoption

### Directory Structure Requirements

Each skill is a **directory** (not a file):
```
~/.config/opencode/skills/my-skill/
├── SKILL.md          # Required
├── mcp.json          # Optional
└── [other files]     # Supporting files
```

Loader looks for:
1. `SKILL.md` (standard)
2. `{dirname}.md` (alternative)
3. Markdown files in root

### Best Practices

- Use kebab-case for directory names: `my-skill`, `git-helper`
- Include SKILL.md with frontmatter (name, description, license, compatibility)
- Optional: Add mcp.json for MCP server configuration
- Flat structure only (nested skills not yet supported - see issue #1208)

### Source Code Reference

From `src/features/opencode-skill-loader/loader.ts`:
- Lines 204-206: `loadOpencodeProjectSkills()` uses `.opencode/skills`
- Lines 196-200: `loadOpencodeGlobalSkills()` uses `~/.config/opencode/skills`
- Lines 144-169: Loader logic for discovering skills

### Recent Changes

- **2026-01-21**: PR #966 fixed singular/plural inconsistency
- **2026-01-28**: Issue #1208 opened requesting nested skill directory support (not yet implemented)

