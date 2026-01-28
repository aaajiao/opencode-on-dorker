# Oh-My-OpenCode Skills: Design Patterns & Best Practices

## Executive Summary

Skills in OpenCode have evolved from a **plugin-based system** (archived Dec 2025) to **native support** (v1.0.190+). This document synthesizes findings about skill design patterns, loading mechanisms, and best practices.

---

## 1. SKILL LOADING ARCHITECTURE

### 1.1 Loading Strategy: Lazy (On-Demand)

**Native OpenCode (v1.0.190+):**
- Skills are **NOT pre-loaded** into context
- Skills are loaded **on-demand** when agents explicitly request them
- The `skill` tool provides a semantic router for agent decision-making

**Benefits:**
- ✅ Reduces context bloat (critical for long conversations)
- ✅ Scales to large skill libraries
- ✅ Agents see available skills in tool description
- ✅ Agents decide when to load based on task requirements

**How it works:**
```
1. OpenCode discovers all SKILL.md files at startup
2. Builds a registry with name + description
3. Injects <available_skills> section into agent context
4. Agent calls skill({ name: "skill-name" }) when needed
5. Full skill content loaded into conversation
```

### 1.2 Historical Context: Plugin-Based (Archived)

The `opencode-skills` plugin (archived Dec 23, 2025) used:
- **Eager loading**: All skills loaded at startup
- **Tool-per-skill**: Each skill became `skills_my_skill` tool
- **Message insertion pattern**: Used Anthropic's message insertion to persist skills

**Migration to native:**
- Plugin functionality graduated to OpenCode core (PR #5930, #6000)
- Directory changed: `.opencode/skills/` → `skills/`
- Tool changed: `skills_my_skill` → single `skill` tool
- Loading changed: Eager → Lazy

---

## 2. SKILL DISCOVERY & LOCATIONS

### 2.1 Discovery Paths (Priority Order)

OpenCode searches these locations (lowest to highest priority):

```
1. ~/.config/opencode/skills/<name>/SKILL.md         # Global (XDG)
2. ~/.claude/skills/<name>/SKILL.md                  # Global (Claude-compatible)
3. .opencode/skills/<name>/SKILL.md                  # Project-local
4. .claude/skills/<name>/SKILL.md                    # Project-local (Claude-compatible)
```

**Key behaviors:**
- All locations are **merged** (not exclusive)
- Project-local skills **override** global ones
- Duplicate names logged as warnings
- Discovery happens at startup (no hot reload)

### 2.2 Directory Structure

```
my-skill/
├── SKILL.md                    # Required (all caps)
├── scripts/                    # Optional: executable code
│   └── helper.py
├── references/                 # Optional: documentation
│   └── api-docs.md
└── assets/                     # Optional: output templates
    └── template.html
```

---

## 3. SKILL DEFINITION FORMAT

### 3.1 SKILL.md Structure

Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: git-release                          # Required: 1-64 chars, lowercase, hyphens
description: Create consistent releases    # Required: 1-1024 chars
license: MIT                               # Optional
compatibility: opencode                   # Optional
metadata:                                  # Optional: key-value pairs
  audience: maintainers
  workflow: github
---

# Skill Content

Your instructions in Markdown format.
```

### 3.2 Naming Rules

| Aspect | Rule | Example |
|--------|------|---------|
| Directory name | lowercase with hyphens | `git-release/` |
| Frontmatter `name` | must match directory exactly | `git-release` |
| Tool name | auto-generated with underscores | `skill` (single tool) |
| Regex validation | `^[a-z0-9]+(-[a-z0-9]+)*$` | ✅ `my-skill`, ❌ `My-Skill` |

**Constraints:**
- 1–64 characters
- Lowercase alphanumeric with single hyphen separators
- Cannot start/end with `-`
- Cannot contain consecutive `--`

### 3.3 Description Best Practices

```markdown
# ✅ GOOD: Specific, action-oriented
description: Create consistent releases and changelogs

# ❌ BAD: Too vague
description: Release helper

# ❌ BAD: Too long
description: This skill helps you create releases by analyzing merged PRs, proposing version bumps, and generating changelog entries
```

**Why it matters:**
- Description appears in `<available_skills>` section
- Agents use it to decide whether to load the skill
- Should be 1-1024 characters (keep under 100 for clarity)

---

## 4. RELATIONSHIP: AGENTS.MD vs SKILLS

### 4.1 AGENTS.md Purpose

`AGENTS.md` (in this project) is a **project-specific agent guidelines document** that:
- Documents agent behavior expectations
- Specifies when agents should use skills
- Defines notification triggers
- Provides code style guidelines

**Example from this project:**
```markdown
## Task Completion Notification

完成以下操作后，**必须**执行 `notify "标题" "结果"` 发送 macOS 桌面通知：

| 触发场景 | 示例 |
|----------|------|
| Subagent 任务返回 | `notify "Oracle 分析完成" "架构建议已生成"` |
| `git push` 完成 | `notify "Git Push 完成 ✅" "3 commits → origin/main"` |
```

### 4.2 Skills Purpose

Skills are **reusable behavior definitions** that:
- Encapsulate domain-specific instructions
- Are discovered and loaded on-demand
- Provide semantic routing for agent decisions
- Can reference supporting files (scripts, docs)

### 4.3 Relationship

```
AGENTS.md (Guidelines)
    ↓
    Specifies when agents should use skills
    ↓
Skills (Implementations)
    ↓
    Provide the actual instructions
    ↓
Agents load skills on-demand via skill tool
```

**Example workflow:**
1. AGENTS.md says: "After subagent completes, send notification"
2. Agent reads AGENTS.md guidelines
3. Agent sees `task-completion-notify` skill available
4. Agent calls `skill({ name: "task-completion-notify" })`
5. Skill content loaded, agent follows instructions

---

## 5. SKILL CONTENT DESIGN PATTERNS

### 5.1 Self-Contained vs External References

**Recommendation: Hybrid approach**

```markdown
---
name: api-integration
description: Integrate with REST APIs using best practices
---

# API Integration Skill

## Quick Reference
- Use `fetch()` for HTTP requests
- Always validate responses
- Implement exponential backoff for retries

## Detailed Guide
See `references/api-patterns.md` for:
- Authentication strategies
- Error handling patterns
- Rate limiting approaches

## Code Examples
Run `scripts/generate-client.sh` to:
- Generate TypeScript client
- Create type definitions
- Set up error handling
```

**When to include inline:**
- Core instructions (what to do)
- Quick reference (key points)
- Common patterns (most frequent use cases)

**When to reference external files:**
- Detailed documentation (too long for skill)
- Code examples (scripts/ directory)
- API references (references/ directory)
- Templates (assets/ directory)

### 5.2 Example: Task Completion Notification Skill

From this project (`global/claude/skills/remind/SKILL.md`):

```yaml
---
name: task-completion-notify
description: (user - Skill) 任务完成后发送 macOS 桌面通知提醒
---

# 任务完成通知

在任务完成后自动发送 macOS 桌面通知，让用户及时知道结果。

## 自动触发场景

### 1. Subagent 任务完成
当委托给其他 agent 的任务返回结果后，**必须**发送通知：
- `@document-writer` 完成文档编写
- `@frontend-ui-ux-engineer` 完成 UI 开发
- `@oracle` 完成分析咨询
- `@librarian` / `@explore` 完成搜索研究

### 2. 用户请求的任务完成
当用户明确要求执行某项任务，且任务已完成时：
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
# Subagent 完成
notify "文档更新完成 ✅" "TOOLS.md 已重新组织并推送到 GitHub"
notify "Oracle 分析完成" "架构建议已生成，请查看"

# 任务完成
notify "Git Push 完成 ✅" "3 个提交已推送到 origin/main"
notify "构建成功 ✅" "项目编译通过，无错误"

# 失败情况
notify "构建失败 ❌" "TypeScript 编译错误，请检查"
\`\`\`
```

**Design analysis:**
- ✅ Self-contained: All instructions inline
- ✅ Clear triggers: Specific scenarios listed
- ✅ Actionable: Concrete examples provided
- ✅ Concise: Focused on single responsibility
- ✅ Bilingual: Chinese + code examples

---

## 6. PERMISSION & ACCESS CONTROL

### 6.1 Pattern-Based Permissions

Native OpenCode uses pattern-based permissions in `opencode.json`:

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

**Permission levels:**
- `allow`: Skill loads immediately
- `deny`: Skill hidden from agent, access rejected
- `ask`: User prompted for approval before loading

### 6.2 Per-Agent Overrides

**For custom agents** (in agent frontmatter):
```yaml
---
permission:
  skill:
    "documents-*": "allow"
---
```

**For built-in agents** (in `opencode.json`):
```json
{
  "agent": {
    "plan": {
      "permission": {
        "skill": {
          "internal-*": "allow"
        }
      }
    }
  }
}
```

### 6.3 Disabling Skills

**For custom agents:**
```yaml
---
tools:
  skill: false
---
```

**For built-in agents:**
```json
{
  "agent": {
    "plan": {
      "tools": {
        "skill": false
      }
    }
  }
}
```

---

## 7. BEST PRACTICES

### 7.1 Skill Design

| Practice | Rationale |
|----------|-----------|
| **Single responsibility** | Each skill does one thing well |
| **Clear description** | Agents use it to decide when to load |
| **Inline core instructions** | Don't force agents to read external files |
| **Reference supporting docs** | For detailed/optional information |
| **Provide examples** | Concrete usage patterns help agents |
| **Use consistent formatting** | Markdown with clear sections |
| **Include trigger scenarios** | When should this skill be used? |

### 7.2 Skill Organization

```
~/.config/opencode/skills/         # Global skills (all projects)
├── code-review/
├── documentation/
└── deployment/

<project>/.opencode/skills/        # Project-specific skills
├── project-standards/
├── internal-tools/
└── custom-workflows/
```

**Guideline:**
- Global skills: Reusable across projects
- Project skills: Project-specific workflows

### 7.3 Documentation

**In AGENTS.md:**
- Document when agents should use skills
- Specify skill loading triggers
- Provide context for skill decisions

**In SKILL.md:**
- Document what the skill does
- Provide clear instructions
- Include concrete examples
- Reference supporting files

### 7.4 Skill Lifecycle

```
1. Create SKILL.md with frontmatter
2. Add to appropriate directory (global or project)
3. Restart OpenCode (discovery happens at startup)
4. Agent sees skill in <available_skills>
5. Agent loads skill when needed
6. Skill content persists in conversation
```

**No hot reload:** Skills are discovered at startup. Adding/modifying skills requires restarting OpenCode.

---

## 8. DISCOVERY & VALIDATION

### 8.1 Troubleshooting

| Issue | Solution |
|-------|----------|
| Skill not discovered | Verify `SKILL.md` (all caps) exists in discovery path |
| Tool not appearing | Check frontmatter has `name` and `description` |
| Invalid name error | Ensure name matches directory, uses lowercase + hyphens |
| Paths not resolving | Verify supporting files exist, use relative paths |
| Duplicate skills | Project-local version takes precedence |

### 8.2 Validation Rules

OpenCode validates:
- ✅ `SKILL.md` file exists (case-sensitive)
- ✅ Frontmatter is valid YAML
- ✅ `name` field present and matches directory
- ✅ `description` field present (1-1024 chars)
- ✅ Name matches regex: `^[a-z0-9]+(-[a-z0-9]+)*$`
- ✅ No duplicate skill names (warning logged)

---

## 9. INTEGRATION WITH OH-MY-OPENCODE

### 9.1 How Skills Fit

Oh-my-opencode is an **agent harness** that:
- Manages multiple specialized agents
- Provides hooks for workflow automation
- Integrates MCP servers (context7, grep.app)
- Supports LSP for code analysis

**Skills complement oh-my-opencode by:**
- Providing domain-specific instructions to agents
- Enabling agents to follow project-specific workflows
- Reducing need for agent configuration
- Supporting reusable behavior patterns

### 9.2 Agent + Skill Workflow

```
User request
    ↓
Agent (from oh-my-opencode)
    ↓
Agent sees <available_skills> in context
    ↓
Agent decides: "I need the 'git-release' skill"
    ↓
Agent calls skill({ name: "git-release" })
    ↓
Skill content loaded into conversation
    ↓
Agent follows skill instructions
    ↓
Task completed
```

---

## 10. SUMMARY TABLE

| Aspect | Details |
|--------|---------|
| **Loading** | Lazy (on-demand), not eager |
| **Discovery** | At startup, no hot reload |
| **Locations** | Global + project-local, merged |
| **Format** | SKILL.md with YAML frontmatter |
| **Naming** | Lowercase, hyphens, 1-64 chars |
| **Content** | Self-contained + optional references |
| **Permissions** | Pattern-based, per-agent overrides |
| **Relationship to AGENTS.md** | Guidelines → Skills → Agent execution |
| **Best practice** | Single responsibility, clear descriptions |
| **Integration** | Works with oh-my-opencode agents |

---

## 11. REFERENCES

### Official Documentation
- [OpenCode Skills Docs](https://opencode.ai/docs/skills/)
- [Oh My OpenCode](https://ohmyopencode.com/)
- [Archived Plugin](https://github.com/malhashemi/opencode-skills) (for historical context)

### Key PRs
- [PR #5930](https://github.com/sst/opencode/pull/5930) - Native skill tool
- [PR #6000](https://github.com/sst/opencode/pull/6000) - Per-agent filtering

### Related Plugins
- [opencode-skillful](https://github.com/zenobi-us/opencode-skillful) - Lazy loading variant
- [opencode-sessions](https://github.com/malhashemi/opencode-sessions) - Multi-agent collaboration

