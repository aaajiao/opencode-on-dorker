# Oh-My-OpenCode Skill System: Complete Research

**Research Date**: January 12, 2026  
**Status**: ✅ Comprehensive Analysis Complete

---

## QUICK ANSWERS

### 1. How does oh-my-opencode's skill system work?

**Lazy loading on-demand:**
- OpenCode discovers all `SKILL.md` files at startup
- Agents see available skills in their context
- Agents call `skill({ name: "skill-name" })` when needed
- Full skill content loads into conversation
- Agent follows skill instructions

**Benefits:**
- ✅ Reduces context bloat
- ✅ Scales to large skill libraries
- ✅ Agents decide when to load based on task

### 2. What is the skill file format?

**SKILL.md with YAML frontmatter:**

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

Your instructions in Markdown format.
```

### 3. Where are skills stored?

**Discovery locations (priority order):**

```
1. ~/.config/opencode/skill/<name>/SKILL.md          # Global (XDG)
2. ~/.claude/skills/<name>/SKILL.md                  # Global (Claude)
3. .opencode/skill/<name>/SKILL.md                   # Project-local
4. .claude/skills/<name>/SKILL.md                    # Project-local (Claude)
```

**In this project:**
```
/workspace/dev/
├── global/claude/skills/remind/SKILL.md             # ✅ Exists
├── .opencode/skill/                                 # Empty
└── .claude/skills/                                  # Empty
```

### 4. Is there an existing playwright skill in oh-my-opencode?

**YES! ✅ Built-in Playwright Skill**

**Name**: `playwright`  
**Description**: MUST USE for any browser-related tasks. Browser automation via Playwright MCP - verification, browsing, information gathering, web scraping, testing, screenshots, and all browser interactions.

**MCP Configuration**:
```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest"]
  }
}
```

**Source**: [oh-my-opencode/src/features/builtin-skills/skills.ts](https://github.com/code-yeongyu/oh-my-opencode/blob/main/src/features/builtin-skills/skills.ts#L3-L15)

### 5. How does a skill get loaded and used?

**Skill Loading Flow:**

```
1. OpenCode Startup
   └─ Discovers SKILL.md files from all locations
   └─ Builds registry: { name, description, content }

2. Agent Context Injection
   └─ Injects <available_skills> section
   └─ Agent sees: "playwright: Browser automation..."

3. Agent Decision
   └─ Agent analyzes task
   └─ Agent decides: "I need the playwright skill"

4. Skill Loading
   └─ Agent calls: skill({ name: "playwright" })
   └─ Full skill content loaded into conversation

5. Agent Execution
   └─ Agent follows skill instructions
   └─ Agent uses MCP tools if configured
   └─ Task completed
```

**Example Usage in oh-my-opencode:**

```typescript
sisyphus_task(
  category="visual-engineering",
  skills=["playwright", "frontend-ui-ux"],
  prompt="Build a responsive dashboard and verify it looks good"
)
```

---

## BUILT-IN SKILLS IN OH-MY-OPENCODE

### 1. Playwright Skill

| Property | Value |
|----------|-------|
| **Name** | `playwright` |
| **Description** | Browser automation via Playwright MCP |
| **MCP** | `@playwright/mcp@latest` |
| **Use Cases** | UI verification, E2E testing, screenshots, web scraping |
| **Lines** | ~10 (minimal template) |

**MCP Configuration:**
```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest"]
  }
}
```

### 2. Frontend UI/UX Skill

| Property | Value |
|----------|-------|
| **Name** | `frontend-ui-ux` |
| **Description** | Designer-turned-developer who crafts stunning UI/UX |
| **MCP** | None |
| **Use Cases** | Aesthetic UI work, design guidance |
| **Lines** | 79 |

**Content Covers:**
- Typography (avoid generic fonts)
- Color theory (cohesive palettes)
- Motion (high-impact animations)
- Spatial composition (asymmetry, overlap)
- Visual details (gradients, textures, shadows)

### 3. Git Master Skill

| Property | Value |
|----------|-------|
| **Name** | `git-master` |
| **Description** | Git expert: atomic commits, rebase, history search |
| **MCP** | None |
| **Use Cases** | Commits, rebasing, history search, blame, bisect |
| **Lines** | 1133 |

**Modes:**
- **COMMIT MODE**: Atomic commits, style detection, dependency ordering
- **REBASE MODE**: Interactive rebase, autosquash, conflict resolution
- **HISTORY SEARCH MODE**: Pickaxe, regex, blame, bisect

---

## SKILL CONTENT DESIGN PATTERNS

### Pattern 1: Self-Contained (Simple Skills)

```yaml
---
name: quick-task
description: Quick task execution
---

# Quick Task Skill

## Instructions

1. Do X
2. Do Y
3. Verify Z

## Examples

\`\`\`bash
# Example 1
command --flag value
\`\`\`
```

**Use for:**
- Simple, focused tasks
- Quick reference guides
- Common patterns

### Pattern 2: Hybrid (Recommended)

```yaml
---
name: api-integration
description: Integrate with REST APIs using best practices
---

# API Integration Skill

## Quick Reference
- Use `fetch()` for HTTP requests
- Always validate responses
- Implement exponential backoff

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

**Use for:**
- Complex skills with supporting files
- Inline core instructions + external references
- Scalable skill libraries

### Pattern 3: With MCP Integration

```yaml
---
name: browser-testing
description: E2E testing with browser automation
mcp:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest"]
---

# Browser Testing Skill

## Setup

The Playwright MCP is automatically configured.

## Usage

1. Use browser automation tools
2. Write E2E tests
3. Verify results

## Examples

\`\`\`typescript
// Playwright will be available
await page.goto('https://example.com');
\`\`\`
```

---

## RELATIONSHIP: AGENTS.MD vs SKILLS

### AGENTS.md (This Project)

**Purpose**: Project-specific agent guidelines

**Contains:**
- Agent behavior expectations
- When agents should use skills
- Notification triggers
- Code style guidelines

**Example from this project:**
```markdown
## Task Completion Notification

完成以下操作后，**必须**执行 `notify "标题" "结果"` 发送 macOS 桌面通知：

| 触发场景 | 示例 |
|----------|------|
| Subagent 任务返回 | `notify "Oracle 分析完成" "架构建议已生成"` |
| `git push` 完成 | `notify "Git Push 完成 ✅" "3 commits → origin/main"` |
```

### Skills (Reusable Implementations)

**Purpose**: Domain-specific instructions

**Contains:**
- What to do (instructions)
- How to do it (steps)
- Examples (concrete usage)
- Supporting files (scripts, docs)

**Example from this project:**
```yaml
---
name: task-completion-notify
description: 任务完成后发送 macOS 桌面通知提醒
---

# 任务完成通知

## 自动触发场景

### 1. Subagent 任务完成
- `@document-writer` 完成文档编写
- `@oracle` 完成分析咨询

## 行为规则

1. **Subagent 返回后立即通知**
2. **用户任务完成后通知**
3. **失败时也要通知**

## 通知命令

\`\`\`bash
notify "标题" "内容"
\`\`\`
```

### Relationship Flow

```
AGENTS.md (Guidelines)
    ↓
    "When agents should use skills"
    ↓
Skills (Implementations)
    ↓
    "What to do and how to do it"
    ↓
Agent Execution
    ↓
    "Agent loads skill on-demand"
    ↓
Task Completed
```

---

## SKILL NAMING RULES

### Valid Names

```
✅ git-release
✅ api-integration
✅ code-review
✅ playwright
✅ frontend-ui-ux
✅ task-completion-notify
```

### Invalid Names

```
❌ Git-Release          (uppercase)
❌ git_release          (underscore)
❌ git--release         (double hyphen)
❌ -git-release         (starts with hyphen)
❌ git-release-         (ends with hyphen)
```

### Naming Rules

| Rule | Example |
|------|---------|
| Lowercase only | `my-skill` not `My-Skill` |
| Hyphens for separation | `my-skill` not `my_skill` |
| Single hyphens | `my-skill` not `my--skill` |
| 1-64 characters | - |
| Alphanumeric + hyphens | `my-skill-123` ✅ |
| Regex | `^[a-z0-9]+(-[a-z0-9]+)*$` |

---

## SKILL DISCOVERY & VALIDATION

### Discovery Process

```
1. OpenCode starts
2. Scans all discovery locations:
   - ~/.config/opencode/skill/*/SKILL.md
   - ~/.claude/skills/*/SKILL.md
   - .opencode/skill/*/SKILL.md
   - .claude/skills/*/SKILL.md
3. Validates each SKILL.md:
   - File exists (case-sensitive)
   - YAML frontmatter valid
   - name field present
   - description field present
   - name matches directory
   - name matches regex
4. Builds registry
5. Injects into agent context
```

### Validation Rules

OpenCode validates:
- ✅ `SKILL.md` file exists (case-sensitive)
- ✅ Frontmatter is valid YAML
- ✅ `name` field present and matches directory
- ✅ `description` field present (1-1024 chars)
- ✅ Name matches regex: `^[a-z0-9]+(-[a-z0-9]+)*$`
- ✅ No duplicate skill names (warning logged)

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Skill not discovered | Verify `SKILL.md` (all caps) exists in discovery path |
| Tool not appearing | Check frontmatter has `name` and `description` |
| Invalid name error | Ensure name matches directory, uses lowercase + hyphens |
| Paths not resolving | Verify supporting files exist, use relative paths |
| Duplicate skills | Project-local version takes precedence |

---

## SKILL LIFECYCLE

### Creating a Skill

```
1. Create directory
   mkdir ~/.config/opencode/skill/my-skill

2. Create SKILL.md
   cat > ~/.config/opencode/skill/my-skill/SKILL.md << 'EOF'
   ---
   name: my-skill
   description: What this skill does
   ---
   
   # My Skill
   
   Instructions here...
   EOF

3. Restart OpenCode
   (Discovery happens at startup)

4. Agent sees skill
   <available_skills>
     - my-skill: What this skill does

5. Agent loads skill on-demand
   skill({ name: "my-skill" })

6. Skill content persists in conversation
```

### Modifying a Skill

```
1. Edit SKILL.md
   nano ~/.config/opencode/skill/my-skill/SKILL.md

2. Restart OpenCode
   (No hot reload - must restart)

3. Changes take effect
```

### Deleting a Skill

```
1. Remove directory
   rm -rf ~/.config/opencode/skill/my-skill

2. Restart OpenCode
   (Skill no longer available)
```

---

## BEST PRACTICES

### ✅ DO

- **Single responsibility**: Each skill does one thing well
- **Clear description**: Agents use it to decide when to load
- **Inline core instructions**: Don't force agents to read external files
- **Reference supporting docs**: For detailed/optional information
- **Provide examples**: Concrete usage patterns help agents
- **Use consistent formatting**: Markdown with clear sections
- **Include trigger scenarios**: When should this skill be used?

### ❌ DON'T

- **Vague descriptions**: "Helper skill" is not helpful
- **Force external files**: Agents prefer inline content
- **Mix multiple responsibilities**: One skill = one purpose
- **Use uppercase in names**: Always lowercase
- **Expect hot reload**: Must restart OpenCode
- **Duplicate skills**: Use project-local overrides instead
- **Forget examples**: Concrete examples are essential

---

## SKILL ORGANIZATION

### Global Skills (Reusable)

```
~/.config/opencode/skill/
├── code-review/
│   ├── SKILL.md
│   └── references/
├── documentation/
│   ├── SKILL.md
│   └── templates/
└── deployment/
    ├── SKILL.md
    └── scripts/
```

**Use for:**
- Reusable across projects
- Common workflows
- Standard practices

### Project-Local Skills (Specific)

```
<project>/.opencode/skill/
├── project-standards/
│   ├── SKILL.md
│   └── references/
├── internal-tools/
│   ├── SKILL.md
│   └── scripts/
└── custom-workflows/
    ├── SKILL.md
    └── assets/
```

**Use for:**
- Project-specific workflows
- Internal tools
- Custom conventions

---

## PERMISSION & ACCESS CONTROL

### Pattern-Based Permissions

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

### Per-Agent Overrides

**For custom agents:**
```yaml
---
permission:
  skill:
    "documents-*": "allow"
---
```

**For built-in agents:**
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

---

## SKILL + CATEGORY COMBINATIONS

### Available Categories

| Category | Model | Temp | Use Case |
|----------|-------|------|----------|
| `visual-engineering` | `gemini-3-pro` | 0.7 | Frontend, UI/UX |
| `ultrabrain` | `gpt-5.2` | 0.1 | Architecture, debugging |
| `artistry` | `gemini-3-pro` | 0.9 | Creative ideation |
| `quick` | `claude-haiku` | 0.3 | Simple tasks |
| `writing` | `gemini-3-flash` | 0.5 | Documentation |
| `most-capable` | `claude-opus` | 0.1 | Complex tasks |

### Example Combinations

**The Designer (UI Implementation)**
```typescript
sisyphus_task(
  category="visual-engineering",
  skills=["frontend-ui-ux", "playwright"],
  prompt="Build a responsive dashboard"
)
```

**The Architect (Design Review)**
```typescript
sisyphus_task(
  category="ultrabrain",
  skills=[],
  prompt="Review system architecture"
)
```

**The Maintainer (Quick Fixes)**
```typescript
sisyphus_task(
  category="quick",
  skills=["git-master"],
  prompt="Fix this bug and commit"
)
```

---

## REFERENCES

### Official Documentation
- [OpenCode Skills Docs](https://opencode.ai/docs/skills/)
- [Oh My OpenCode](https://ohmyopencode.com/)
- [Archived Plugin](https://github.com/malhashemi/opencode-skills)

### Key PRs
- [PR #5930](https://github.com/sst/opencode/pull/5930) - Native skill tool
- [PR #6000](https://github.com/sst/opencode/pull/6000) - Per-agent filtering

### Related Projects
- [opencode-skillful](https://github.com/zenobi-us/opencode-skillful) - Lazy loading variant
- [opencode-sessions](https://github.com/malhashemi/opencode-sessions) - Multi-agent collaboration

### Oh-My-OpenCode Repository
- [code-yeongyu/oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- Latest version: v3.0.0-beta.5 (as of Jan 2026)

---

## SUMMARY TABLE

| Aspect | Details |
|--------|---------|
| **Loading** | Lazy (on-demand), not eager |
| **Discovery** | At startup, no hot reload |
| **Locations** | Global + project-local, merged |
| **Format** | SKILL.md with YAML frontmatter |
| **Naming** | Lowercase, hyphens, 1-64 chars |
| **Content** | Self-contained + optional references |
| **Permissions** | Pattern-based, per-agent overrides |
| **Built-in Skills** | playwright, frontend-ui-ux, git-master |
| **MCP Integration** | Playwright MCP for browser automation |
| **Relationship to AGENTS.md** | Guidelines → Skills → Agent execution |
| **Best practice** | Single responsibility, clear descriptions |
| **Integration** | Works with oh-my-opencode agents |

