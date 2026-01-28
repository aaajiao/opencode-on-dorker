# Skills Quick Reference Card

## 🎯 Key Findings

### 1. Loading Strategy
- **Lazy (on-demand)** - NOT pre-loaded
- Agents see available skills in tool description
- Agents call `skill({ name: "skill-name" })` when needed
- Reduces context bloat, scales to large libraries

### 2. Discovery Locations (Priority)
```
1. ~/.config/opencode/skills/<name>/SKILL.md         # Global (XDG)
2. ~/.claude/skills/<name>/SKILL.md                  # Global (Claude)
3. .opencode/skills/<name>/SKILL.md                  # Project-local
4. .claude/skills/<name>/SKILL.md                    # Project-local (Claude)
```
- All locations merged (not exclusive)
- Project-local overrides global
- Discovery at startup (no hot reload)

### 3. SKILL.md Format
```yaml
---
name: skill-name                    # Required: lowercase, hyphens, 1-64 chars
description: What it does           # Required: 1-1024 chars
license: MIT                        # Optional
compatibility: opencode            # Optional
metadata:                           # Optional
  audience: developers
---

# Skill Content

Your instructions in Markdown.
```

### 4. Naming Rules
- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`
- ✅ `git-release`, `api-integration`, `code-review`
- ❌ `Git-Release`, `git_release`, `git--release`

### 5. AGENTS.md vs Skills

| AGENTS.md | Skills |
|-----------|--------|
| Guidelines for agents | Reusable behavior definitions |
| When to use skills | What to do (instructions) |
| Project-specific rules | Domain-specific knowledge |
| Loaded once at startup | Loaded on-demand |

**Relationship:**
```
AGENTS.md (Guidelines)
    ↓ specifies when to use
Skills (Implementations)
    ↓ provides instructions
Agent execution
```

### 6. Content Design

**Self-contained (inline):**
- Core instructions
- Quick reference
- Common patterns
- Concrete examples

**External references:**
- Detailed documentation → `references/`
- Code examples → `scripts/`
- API docs → `references/`
- Templates → `assets/`

### 7. Permissions

```json
{
  "permission": {
    "skill": {
      "pr-review": "allow",
      "internal-*": "deny",
      "experimental-*": "ask",
      "*": "allow"
    }
  }
}
```

Levels: `allow`, `deny`, `ask`

### 8. Best Practices

✅ **DO:**
- Single responsibility per skill
- Clear, specific descriptions
- Inline core instructions
- Provide concrete examples
- Use consistent formatting
- Include trigger scenarios

❌ **DON'T:**
- Vague descriptions
- Force agents to read external files
- Mix multiple responsibilities
- Use uppercase in names
- Expect hot reload

### 9. Skill Lifecycle

```
1. Create SKILL.md with frontmatter
2. Place in global or project directory
3. Restart OpenCode (discovery at startup)
4. Agent sees skill in <available_skills>
5. Agent loads skill on-demand
6. Skill content persists in conversation
```

### 10. Troubleshooting

| Issue | Solution |
|-------|----------|
| Not discovered | Check `SKILL.md` (all caps) exists |
| Tool not appearing | Verify `name` + `description` in frontmatter |
| Invalid name | Use lowercase + hyphens only |
| Paths not resolving | Use relative paths, verify files exist |
| Duplicate skills | Project-local takes precedence |

---

## 📚 Real Example: Task Completion Notification

From this project (`global/claude/skills/remind/SKILL.md`):

```yaml
---
name: task-completion-notify
description: (user - Skill) 任务完成后发送 macOS 桌面通知提醒
---

# 任务完成通知

## 自动触发场景

### 1. Subagent 任务完成
- `@document-writer` 完成文档编写
- `@oracle` 完成分析咨询
- `@librarian` / `@explore` 完成搜索研究

### 2. 用户请求的任务完成
- 代码修改并提交/推送完成
- 文件创建/修改完成
- 构建/测试运行完成

## 行为规则

1. **Subagent 返回后立即通知** - 不需要用户额外请求
2. **用户任务完成后通知** - 特别是涉及 git push、长时间操作
3. **失败时也要通知** - 说明失败原因
4. **通知内容简洁明了** - 标题说明是什么，内容说明结果

## 通知命令

\`\`\`bash
notify "标题" "内容"
\`\`\`

## 通知示例

\`\`\`bash
notify "文档更新完成 ✅" "TOOLS.md 已重新组织并推送到 GitHub"
notify "Oracle 分析完成" "架构建议已生成，请查看"
notify "Git Push 完成 ✅" "3 个提交已推送到 origin/main"
\`\`\`
```

**Why this works:**
- ✅ Self-contained: All instructions inline
- ✅ Clear triggers: Specific scenarios listed
- ✅ Actionable: Concrete examples provided
- ✅ Concise: Focused on single responsibility
- ✅ Bilingual: Chinese + code examples

---

## 🔗 References

- [OpenCode Skills Docs](https://opencode.ai/docs/skills/)
- [Oh My OpenCode](https://ohmyopencode.com/)
- [Archived Plugin](https://github.com/malhashemi/opencode-skills) (historical)
- [PR #5930](https://github.com/sst/opencode/pull/5930) - Native skill tool
- [PR #6000](https://github.com/sst/opencode/pull/6000) - Per-agent filtering

