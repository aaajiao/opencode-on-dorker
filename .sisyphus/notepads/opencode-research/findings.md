# OpenCode Directory Naming Standards - Research Findings

## Key Discoveries

### 1. Directory Naming Conventions

**Skills**:
- Project: `.opencode/skill/<name>/SKILL.md` or `.opencode/skills/<name>/SKILL.md`
- Global: `~/.config/opencode/skill/` or `~/.config/opencode/skills/`
- Claude-compatible: `.claude/skills/<name>/SKILL.md`

**Agents**:
- Project: `.opencode/agent/<name>.md` or `.opencode/agents/<name>.md`
- Also: `agent/<name>.md` or `agents/<name>.md` at project root
- Global: `~/.config/opencode/agent/` or `~/.config/opencode/agents/`

### 2. Skill Naming Rules

- **Length**: 1-64 characters
- **Format**: Lowercase alphanumeric with hyphens only
- **Regex**: `^[a-z0-9]+(-[a-z0-9]+)*$`
- **Directory match**: Name must match directory name
- **Examples**: `git-release`, `bun-file-io`, `frontend-ui-ux`

### 3. Discovery Mechanism

Skills are discovered via:
1. Walk-up from current directory to git worktree root
2. Scan `.opencode/skill/` and `.opencode/skills/`
3. Scan `.claude/skills/` (Claude-compatible)
4. Global scan of `~/.config/opencode/` and `~/.claude/`

Agents discovered from markdown files in `.opencode/agent/` or `.opencode/agents/`

### 4. Version Status (2025-2026)

- ✅ Both singular and plural forms supported
- ✅ No breaking changes detected
- ✅ Full backward compatibility
- ✅ Claude Code migration support

### 5. Best Practices

- Use singular forms: `.opencode/skill/` and `.opencode/agent/`
- Keep skill names short (1-3 words)
- Use hyphens for word separation
- Match directory name to skill name exactly
- Include required frontmatter (name, description)

## Evidence Sources

- Official OpenCode docs: https://opencode.ai/docs/skills/
- Source code: https://github.com/anomalyco/opencode/blob/57ad181/packages/opencode/src/skill/skill.ts
- oh-my-opencode: https://github.com/code-yeongyu/oh-my-opencode/blob/dev/docs/category-skill-guide.md

## Recommendations

1. **For new projects**: Use `.opencode/skill/` and `.opencode/agent/` (singular)
2. **Naming**: Follow regex pattern strictly
3. **Frontmatter**: Always include name and description
4. **Permissions**: Use pattern-based access control for sensitive skills
5. **Testing**: Verify discovery with `opencode skill` command

