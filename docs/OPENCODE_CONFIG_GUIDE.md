## 配置系统概述

OpenCode + oh-my-opencode 存在**两套配置系统**，理解它们的区别是正确配置的关键：

| 系统 | 目录命名 | 用途 | 加载器 |
|------|---------|------|--------|
| **OpenCode 原生** | 单数 (`agent/`, `skill/`, `command/`) | OpenCode 内置功能 | OpenCode 核心 |
| **Claude 兼容层** | 复数 (`agents/`, `skills/`, `commands/`, `rules/`) | Claude Code 兼容 | oh-my-opencode 插件 |

## 目录结构

```
<project>/
├── .opencode/                    # OpenCode 原生配置（单数目录名）
│   ├── agent/                    # 自定义 Agents
│   │   └── *.md
│   ├── skill/                    # 自定义 Skills
│   │   └── <skill-name>/
│   │       └── SKILL.md
│   ├── command/                  # 自定义斜杠命令
│   │   └── *.md
│   └── oh-my-opencode.json       # 可选：项目级插件配置覆盖
│
└── .claude/                      # Claude 兼容层配置（复数目录名）
    ├── agents/                   # Claude 风格 Agents
    │   └── *.md
    ├── skills/                   # Claude 风格 Skills
    │   └── <skill-name>/
    │       └── SKILL.md
    ├── commands/                 # Claude 风格斜杠命令
    │   └── *.md
    └── rules/                    # 条件规则（仅 Claude 兼容层支持）
        └── *.md
```

### 全局配置路径

| 系统 | 项目级 | 全局（宿主机） | 全局（容器内） |
|------|--------|---------------|---------------|
| **OpenCode 原生** | `.opencode/agent/` | `~/opencode/global/opencode/agent/` | `~/.config/opencode/agent/` |
| **OpenCode 原生** | `.opencode/skill/` | `~/opencode/global/opencode/skill/` | `~/.config/opencode/skill/` |
| **OpenCode 原生** | `.opencode/command/` | `~/opencode/global/opencode/command/` | `~/.config/opencode/command/` |
| **Claude 兼容层** | `.claude/agents/` | `~/opencode/global/claude/agents/` | `~/.claude/agents/` |
| **Claude 兼容层** | `.claude/skills/` | `~/opencode/global/claude/skills/` | `~/.claude/skills/` |
| **Claude 兼容层** | `.claude/commands/` | `~/opencode/global/claude/commands/` | `~/.claude/commands/` |
| **Claude 兼容层** | `.claude/rules/` | `~/opencode/global/claude/rules/` | `~/.claude/rules/` |
| **UI 设置持久化** | - | `~/.local/state/opencode/` | `~/.local/state/opencode/` |
| **插件二进制缓存** | - | `~/.cache/oh-my-opencode/` | `~/.cache/oh-my-opencode/` |

> **Docker 环境说明**：本项目中 `~/opencode/global/claude/` 是宿主机目录，容器内挂载为 `~/.claude/`。

---

## Agents 配置

### OpenCode 原生 Agent

#### 路径

| 级别 | 路径 |
|------|------|
| 项目级 | `.opencode/agent/*.md` |
| 全局 | `~/.config/opencode/agent/*.md` |

#### 文件格式

```markdown
---
name: agent-name
description: 简短描述，显示在 @ 菜单中
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  bash: true
  webfetch: true
---

系统提示词内容...
```

#### 字段说明

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `name` | 否 | string | Agent 名称（默认用文件名去掉 .md） |
| `description` | 否 | string | 描述，显示在 `@` 选择菜单 |
| `model` | 否 | string | 模型 ID，如 `anthropic/claude-sonnet-4-5` |
| `tools` | 否 | object | 允许的工具，键值对格式 `{ tool: true }` |
| `temperature` | 否 | number | 模型温度参数 |

### Claude 兼容层 Agent

#### 路径

| 级别 | 路径 |
|------|------|
| 项目级 | `.claude/agents/*.md` |
| 全局 | `~/.claude/agents/*.md` |

#### 文件格式

```markdown
---
name: agent-name
description: 简短描述，显示在 @ 菜单中
tools: read, bash, webfetch
---

系统提示词内容...
```

#### 字段说明

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `name` | 否 | string | Agent 名称（默认用文件名去掉 .md） |
| `description` | 否 | string | 描述，显示在 `@` 选择菜单 |
| `tools` | 否 | string | 允许的工具，**逗号分隔字符串** |

> ⚠️ **注意**：Claude 兼容层的 `model` 字段**不生效**，模型由 oh-my-opencode.json 配置决定。

## 📂 配置文件位置

| 配置文件 | 路径 | 用途 |
|---------|------|------|
| **OpenCode 主配置** | `~/.config/opencode/opencode.json` | 配置 Provider API Key、MCP 服务器、插件设置 |
| **OhMyOpenCode 配置** | `~/.config/opencode/oh-my-opencode.json` | 配置代理模型映射、禁用特定功能、自定义 Agent 行为 |

## 🔧 oh-my-opencode.json 配置详解

通过修改 `~/.config/opencode/oh-my-opencode.json` 文件，你可以自定义 OpenCode 的行为。

**配置示例**：

```json
{
  "$schema": "https://raw.githubusercontent.com/skns2635/oh-my-opencode/main/schema.json",
  "google_auth": {
    "client_email": "...",
    "private_key": "..."
  },
  "disabled_mcps": [
    "gdrive"
  ],
  "agents": {
    "document-writer": {
      "model": "quotio/gemini-3-pro-preview"
    },
    "frontend-ui-ux-engineer": {
      "model": "quotio/gemini-3-pro-preview"
    }
  }
}
```

| 字段 | 说明 |
|------|------|
| `google_auth` | Google 服务认证信息（如使用 Google Drive MCP） |
| `disabled_mcps` | 禁用的 MCP 服务器列表（如不需要 Google Drive 可禁用以减少启动错误） |
| `agents` | 自定义特定代理使用的模型 |
| `agents.<name>.model` | 指定该代理使用的模型 ID |

## 🎯 代理默认模型

建议将默认的 Google 模型替换为 Quotio 提供的兼容模型，以获得更稳定的体验。

| 代理 | 默认模型 | 建议替换为 |
|------|----------|------------|
| `document-writer` | `google/gemini-3-flash-preview` | `quotio/gemini-3-pro-preview` |
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-preview` | `quotio/gemini-3-pro-preview` |
| `multimodal-looker` | `google/gemini-3-flash` | `quotio/gemini-3-flash-preview` |
| `oracle` | (默认) | `openai/gpt-5.2` 或 `quotio/gemini-claude-opus-4-5-thinking` |

### 模型前缀说明

| 前缀 | 说明 |
|------|------|
| `google/` | 直接调用 Google Vertex AI / Gemini API |
| `anthropic/` | 调用 Anthropic Claude API |
| `openai/` | 调用 OpenAI GPT API |
| `quotio/` | **推荐**：通过 Quotio 中转服务调用模型（兼容性更好） |

### 5. 配置文件中自定义快捷键

你可以在 `opencode.json` 中自定义部分快捷键：

```json
{
  "keybinds": {
    "username_toggle": "<leader>u",
    "tool_details": "<leader>d",
    "scrollbar_toggle": "<leader>s"
  }
}
```

## Skills 配置

### 路径

| 系统 | 项目级 | 全局 |
|------|--------|------|
| **OpenCode 原生** | `.opencode/skill/<skill-name>/SKILL.md` | `~/.config/opencode/skill/<skill-name>/SKILL.md` |
| **Claude 兼容层** | `.claude/skills/<skill-name>/SKILL.md` | `~/.claude/skills/<skill-name>/SKILL.md` |

### 目录结构

```
<skill-name>/
├── SKILL.md              # 必需，skill 定义和使用说明
├── AGENTS.md             # 可选，给 AI Agent 的开发指南
├── mcp.json              # 可选，MCP 服务器配置
├── scripts/              # 可选，自动化脚本
│   └── ...
└── data/                 # 可选，运行时数据（应 gitignore）
```

### SKILL.md 格式

```markdown
---
name: skill-name
description: 触发条件描述 - 功能说明
---

# Skill 名称

## 何时使用

触发条件列表...

## 使用方法

具体命令和示例...
```

## 🎨 Skill 技能系统

Skill 是更高级的命令形式，可以包含 MCP 服务器配置。

### 技能文件位置

| 位置 | 说明 |
|------|------|
| `~/opencode/global/claude/skills/*/SKILL.md` | 全局 Claude 兼容技能（容器内 `~/.claude/skills/`） |
| `.claude/skills/*/SKILL.md` | 项目级 Claude 兼容技能 |
| `~/opencode/global/opencode/skill/*/SKILL.md` | 全局 OpenCode 原生技能（容器内 `~/.config/opencode/skill/`） |
| `.opencode/skill/*/SKILL.md` | 项目级 OpenCode 原生技能 |

### 技能格式示例

```markdown
---
name: "my-skill"
description: "技能描述"
model: "anthropic/claude-opus-4-5"
allowed-tools: "bash read write"
mcp:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest"]
---

技能指令内容...
```

### 内置技能

- **playwright**：浏览器自动化、网页抓取、测试、截图

### 禁用内置技能

```json
{
  "disabled_skills": ["playwright"]
}
```

---

## Commands 配置

### 路径

| 系统 | 项目级 | 全局 |
|------|--------|------|
| **OpenCode 原生** | `.opencode/command/*.md` | `~/.config/opencode/command/*.md` |
| **Claude 兼容层** | `.claude/commands/*.md` | `~/.claude/commands/*.md` |

### 文件格式

```markdown
---
name: command-name
description: 命令描述，显示在 / 菜单中
---

命令执行时的提示词内容...
可以包含 $ARGUMENTS 占位符接收用户参数。
```

## Rules 配置（仅 Claude 兼容层）

条件规则允许根据文件 glob 模式自动注入上下文。

> ⚠️ **注意**：这是 Claude 兼容层独有功能，OpenCode 原生不支持 `.opencode/rules/`。

### 路径

| 级别 | 路径 |
|------|------|
| 项目级 | `.claude/rules/*.md` |
| 全局 | `~/.claude/rules/*.md` |

### 文件格式

```markdown
---
globs: ["*.ts", "*.tsx"]
---

TypeScript 代码规范：
- 使用严格模式
- 优先使用 interface 而非 type
- ...
```

### 字段说明

| 字段 | 必需 | 类型 | 说明 |
|------|------|------|------|
| `globs` | 是 | string[] | 文件匹配模式，匹配时自动注入规则内容 |

## 优先级规则

当同名配置存在于多个位置时，按以下优先级加载（高优先级覆盖低优先级）：

### Commands 优先级（4 层）

| 优先级 | 项目路径 | 全局路径（容器内） | 说明 |
|--------|---------|-----------------|------|
| 1 (最高) | `.opencode/command/` | - | 项目 OpenCode 原生 |
| 2 | - | `~/.config/opencode/command/` | 全局 OpenCode 原生 |
| 3 | `.claude/commands/` | - | 项目 Claude 兼容 |
| 4 (最低) | - | `~/.claude/commands/` | 全局 Claude 兼容 |

### Skills 优先级（4 层）

| 优先级 | 项目路径 | 全局路径（容器内） | 说明 |
|--------|---------|-----------------|------|
| 1 (最高) | `.opencode/skill/` | - | 项目 OpenCode 原生 |
| 2 | - | `~/.config/opencode/skill/` | 全局 OpenCode 原生 |
| 3 | `.claude/skills/` | - | 项目 Claude 兼容 |
| 4 (最低) | - | `~/.claude/skills/` | 全局 Claude 兼容 |

### Agents 优先级

**OpenCode 原生 Agents（2 层）**

| 优先级 | 路径（容器内） |
|--------|--------------|
| 1 (最高) | `/workspace/.opencode/agent/` |
| 2 (最低) | `~/.config/opencode/agent/` |

**Claude 兼容 Agents（2 层）**

| 优先级 | 路径（容器内） |
|--------|--------------|
| 1 (最高) | `/workspace/.claude/agents/` |
| 2 (最低) | `~/.claude/agents/` |

### Rules 优先级（2 层，仅 Claude 兼容）

| 优先级 | 路径（容器内） |
|--------|--------------|
| 1 (最高) | `/workspace/.claude/rules/` |
| 2 (最低) | `~/.claude/rules/` |

---

## .gitignore 建议

```gitignore
# 会话数据（每个项目的 todos 和 transcripts）
.claude/todos/
.claude/transcripts/

# Skill 运行时数据（可能包含认证信息）
.opencode/skill/*/data/
.claude/skills/*/data/

# Python 虚拟环境（如有）
.opencode/skill/*/.venv/
.claude/skills/*/.venv/

# macOS
.DS_Store

# Node
node_modules/
bun.lock
```

---

## 🪝 Hooks 系统

Hooks 允许在特定事件发生时运行自定义脚本。

### 配置位置

- `~/opencode/global/claude/settings.json`（全局级，容器内 `~/.claude/settings.json`）
- `.claude/settings.json`（项目级）
- `.claude/settings.local.json`（本地，git 忽略）

### 支持的 Hook 事件

| 事件 | 触发时机 | 用途 |
|------|----------|------|
| `PreToolUse` | 工具执行前 | 阻止或修改工具输入 |
| `PostToolUse` | 工具执行后 | 添加警告或上下文 |
| `UserPromptSubmit` | 用户提交提示时 | 阻止或注入消息 |
| `Stop` | 会话空闲时 | 注入后续提示 |

### 配置示例

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "eslint --fix $FILE" }
        ]
      }
    ]
  }
}
```
### 工作原理

1. 代理开始执行任务
2. 如果代理中途停止，Ralph Loop 自动继续
3. 检测到 `<promise>DONE</promise>` 时自动结束
4. 达到最大迭代次数（默认 100）时结束

### 配置

在 `oh-my-opencode.json` 中配置：

```json
{
  "ralph_loop": {
    "enabled": true,
    "default_max_iterations": 100
  }
}
```

---

## 📁 AGENTS.md 自动注入

在目录中创建 `AGENTS.md` 文件，当读取该目录下的文件时，会自动将 AGENTS.md 的内容注入到上下文中。

### 目录结构示例

```
project/
├── AGENTS.md              # 项目级上下文（最先注入）
├── src/
│   ├── AGENTS.md          # src 特定上下文
│   └── components/
│       ├── AGENTS.md      # 组件特定上下文（最后注入）
│       └── Button.tsx     # 读取此文件时，注入所有 3 个 AGENTS.md
```

### 注入顺序

从项目根目录到文件所在目录，依次注入所有 AGENTS.md 文件。

### 搜索范围说明

`session_search` 会搜索 **所有项目/实例** 的会话历史，存储在 `~/.local/share/opencode/storage/message` 目录下。

这意味着你可以：
- 🔍 找回之前**任何项目**中讨论过的解决方案
- 📚 查找跨项目的技术决策历史
- 🔗 建立不同项目之间的知识联系

### session_search 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `query` | string | ✅ | 搜索关键词 |
| `session_id` | string | ❌ | 限定在某个会话内搜索（不填则搜索所有会话） |
| `case_sensitive` | boolean | ❌ | 是否区分大小写（默认 false） |
| `limit` | number | ❌ | 返回结果数量限制（默认 20） |

| 功能 | 说明 |
|------|------|
| **Todo Continuation Enforcer** | 强制代理完成所有 TODO，防止半途而废 |
| **Comment Checker** | 防止 AI 添加过多注释，保持代码整洁 |
| **Context Window Monitor** | 上下文使用 70%+ 时提醒，防止仓促完成 |
| **Preemptive Compaction** | 上下文使用 85% 时主动压缩会话 |
| **Session Recovery** | 自动从错误中恢复（缺失工具结果、思考块问题等） |
| **Empty Task Response Detector** | 检测空任务响应，警告潜在的代理失败 |
| **Anthropic Auto Compact** | Claude 模型超限时自动压缩会话 |
| **Thinking Block Validator** | 验证思考块格式，防止 API 错误 |

### 禁用特定保护功能

在 `oh-my-opencode.json` 中配置：

```json
{
  "disabled_hooks": ["preemptive-compaction", "comment-checker"]
}
```

---

## 📋 剪贴板桥接

容器内的剪贴板操作会自动同步到 Mac 剪贴板。

### 工作原理

1. 容器内使用 `xclip` 或 `/share` 命令
2. 内容写入 `~/.opencode_data/<instance>/clipboard`
3. Mac watcher 检测到变化后执行 `pbcopy`

### 延迟

- **fswatch 模式**：即时（需要安装 fswatch）
- **轮询模式**：约 1 秒

## 🔔 通知系统

### 后台任务完成通知

当后台代理任务完成时，系统会发送通知。

### 会话空闲通知

当代理需要输入时，发送操作系统通知，防止错过交互。

**支持平台**：macOS、Linux、Windows

---

## 🔗 Claude Code 兼容性

oh-my-opencode 完全兼容 Claude Code 的配置和命令格式，让你可以复用 Claude Code 社区的资源。

### ⚠️ 两套配置系统

OpenCode 支持**两套配置系统**，目录命名规则不同：

| 系统 | 目录命名 | 用途 |
|------|---------|------|
| **OpenCode 原生** | **单数** (`skill/`, `command/`, `agent/`) | OpenCode 内置功能 |
| **Claude 兼容层** | **复数** (`skills/`, `commands/`, `agents/`, `rules/`) | Claude Code 兼容 |

> ⚠️ **写错目录名不会被加载！** OpenCode 原生用单数，Claude 兼容层用复数。

### 目录结构（OCD Docker 版）

在 OCD（OpenCode Docker）环境中，配置目录结构如下：

```
~/opencode/                           # 配置仓库（自身也是一个项目）
│
│  ── 核心脚本（模块化架构 v2.0）──
│
├── bin/
│   └── ocd                           # 入口脚本（添加到 PATH）
│
├── lib/                              # 模块化核心库
│   ├── core.sh                       # 版本/日志/环境变量
│   ├── port.sh                       # 端口管理（原子锁）
│   ├── workspace.sh                  # 工作区检测
│   ├── watcher.sh                    # IPC 文件监控
│   ├── config.sh                     # 配置生成
│   └── docker.sh                     # Docker 操作
│
├── tests/bats/                       # 单元测试（Bats）
│
├── opencode.sh                       # 旧版入口（兼容）
│
│  ── 这个项目自身的配置 ──
│
├── .opencode/                        # OpenCode 原生配置（这个项目）
│   ├── skill/
│   ├── command/
│   └── agent/
│
├── .claude/                          # Claude 兼容层（这个项目）
│   ├── todos/                        # opencode 实例的会话数据
│   └── transcripts/
│
│  ── 全局配置（对所有项目生效） ──
│
├── global/
│   ├── opencode/                     # OpenCode 原生全局配置
│   │   ├── skill/                    # 全局 Skills（单数）
│   │   ├── command/                  # 全局 Commands（单数）
│   │   └── agent/                    # 全局 Agents（单数）
│   │
│   └── claude/                       # Claude 兼容层全局配置
│       ├── skills/                   # 全局 Skills（复数）
│       ├── commands/                 # 全局 Commands（复数）
│       ├── agents/                   # 全局 Agents（复数）
│       ├── rules/                    # 全局 Rules（复数）
│       ├── settings.json             # 全局 Hooks
│       └── .mcp.json                 # 全局 MCP 服务器
│
└── ...

~/my-project/                         # 其他项目
├── .opencode/                        # OpenCode 原生配置（这个项目）
│   ├── skill/
│   ├── command/
│   └── agent/
│
├── .claude/                          # Claude 兼容层（这个项目）
│   ├── todos/                        # 这个项目的会话数据
│   └── transcripts/
│
└── ... (项目源码)
```

**挂载映射**（容器内路径）：

**全局配置挂载**：
| 宿主机路径 | 容器内路径 | 说明 |
|------------|-----------|------|
| `~/opencode/global/opencode/skill/` | `/root/.config/opencode/skill/` | OpenCode 原生全局 Skills |
| `~/opencode/global/opencode/command/` | `/root/.config/opencode/command/` | OpenCode 原生全局 Commands |
| `~/opencode/global/opencode/agent/` | `/root/.config/opencode/agent/` | OpenCode 原生全局 Agents |
| `~/opencode/global/claude/` | `/root/.claude/` | Claude 兼容层全局配置 |

**会话数据挂载**（覆盖挂载到 `/root/.claude/`）：
| 宿主机路径 | 容器内路径 | 说明 |
|----------|-----------|------|
| `<project>/.claude/todos/` | `/root/.claude/todos/` | 项目的任务列表 |
| `<project>/.claude/transcripts/` | `/root/.claude/transcripts/` | 项目的会话记录 |

> **注意**：每个项目的会话数据存放在项目自己的 `.claude/` 目录下，通过覆盖挂载实现隔离。

### 兼容的功能

| 功能 | 宿主机路径 | 用途 |
|------|-----------|------|
| **Skills** | `~/opencode/global/claude/skills/` | 高级技能，可包含 MCP 配置 |
| **Commands** | `~/opencode/global/claude/commands/` | 自定义斜杠命令 |
| **Agents** | `~/opencode/global/claude/agents/` | 自定义代理角色 |
| **Rules** | `~/opencode/global/claude/rules/` | 条件规则（按文件类型等触发） |
| **Hooks** | `~/opencode/global/claude/settings.json` | 工具执行前后的钩子 |
| **MCP** | `~/opencode/global/claude/.mcp.json` | 额外的 MCP 服务器 |
| **Todos** | `<project>/.claude/todos/` | 任务列表（项目隔离） |
| **Transcripts** | `<project>/.claude/transcripts/` | 会话日志（项目隔离） |

---

### 禁用兼容性功能

如需禁用特定功能，在 `oh-my-opencode.json` 中配置：

```json
{
  "claude_code": {
    "mcp": false,
    "commands": false,
    "skills": false,
    "agents": false,
    "hooks": false
  }
}
```
## `ocd` 自动初始化行为

### 全局配置初始化

首次运行任意项目时，会自动创建全局配置目录：

```
~/opencode/global/
├── opencode/                     # OpenCode 原生全局配置
│   ├── skill/
│   ├── command/
│   └── agent/
│
└── claude/                       # Claude 兼容层全局配置
    ├── skills/
    ├── commands/
    ├── agents/
    ├── rules/
    ├── settings.json             # 自动生成（如果不存在）
    └── .mcp.json                 # 自动生成（如果不存在）
```

### 项目初始化

每次运行 `ocd` 时，会自动创建项目级配置目录：

**OpenCode 原生配置**（在项目目录下）：
```
.opencode/
├── skill/      # 项目专属 Skills
├── command/    # 项目专属斜杠命令
└── agent/      # 项目专属 Agents
```

**会话数据**（在项目目录下）：
```
.claude/
├── todos/        # 项目的任务列表
└── transcripts/  # 项目的会话日志
```

> **注意**：会话数据（todos/transcripts）现在存放在每个项目自己的 `.claude/` 目录下，不再使用 `instances/` 目录。

> **注意**：UI 设置（如思考过程可见性、代码折叠等）持久化存储在 `~/.local/state/opencode/` 中。插件二进制文件（ast-grep, ripgrep）缓存存储在 `~/.cache/oh-my-opencode/` 中。

> ⚠️ **注意**：`.claude/skills/`、`.claude/commands/`、`.claude/agents/`、`.claude/rules/` 不会自动创建，需要手动创建。如需项目级配置，推荐使用 OpenCode 原生的 `.opencode/` 目录。

---

## 版本锁定 (versions.lock)

可以创建 `~/opencode/versions.lock` 文件来锁定依赖版本，确保构建可复现。

### 文件格式

```bash
# ~/opencode/versions.lock
# 纯 KEY=VALUE 格式，支持注释

# Bun 运行时版本
BUN_VERSION=1.3.5

# Python 包版本
PIP_REQUESTS=2.32.5
PIP_PANDAS=2.2.3
PIP_NUMPY=2.2.1
PIP_MATPLOTLIB=3.10.0
PIP_BEAUTIFULSOUP4=4.12.3
PIP_PILLOW=11.1.0

# OpenCode 版本
OPENCODE_AI_VERSION=1.1.4

# oh-my-opencode 插件版本
OH_MY_OPENCODE_VERSION=2.14.0
OPENCODE_ANTIGRAVITY_AUTH_VERSION=1.2.6

# MCP 服务器版本
PLAYWRIGHT_MCP_VERSION=0.0.54
EXA_MCP_VERSION=3.1.3
```

### 支持的变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `BUN_VERSION` | Bun 运行时 | 1.3.5 |
| `OPENCODE_AI_VERSION` | OpenCode CLI | 1.1.4 |
| `OH_MY_OPENCODE_VERSION` | oh-my-opencode 插件 | 2.14.0 |
| `OPENCODE_ANTIGRAVITY_AUTH_VERSION` | 认证插件 | 1.2.6 |
| `PLAYWRIGHT_MCP_VERSION` | Playwright MCP | 0.0.54 |
| `EXA_MCP_VERSION` | Exa MCP | 3.1.3 |
| `PIP_*` | Python 包版本 | 见上表 |

## 注意事项

1. **目录命名很重要**：OpenCode 原生用单数 (`agent/`)，Claude 兼容用复数 (`agents/`)，写错不会被加载

2. **Agent 配置生效范围**：
   - OpenCode 原生：`model`, `tools` (object), `temperature` 都生效
   - Claude 兼容：仅 `name`, `description`, `tools` (string) 生效，`model` 不生效

3. **重启生效**：创建/修改配置后可能需要重启 session 才能在菜单显示

4. **tools 字段格式差异**：
   - OpenCode 原生：`tools: { read: true, bash: true }`
   - Claude 兼容：`tools: read, bash, webfetch`

5. **敏感数据**：`data/` 目录可能包含认证信息，不要提交到 git

6. **Skill 运行环境**：如果 skill 需要 Python 依赖，需要**自行**在 skill 目录管理 venv，不会自动创建

7. **条件规则仅 Claude 兼容层支持**：如需根据文件类型注入规则，必须使用 `.claude/rules/`
