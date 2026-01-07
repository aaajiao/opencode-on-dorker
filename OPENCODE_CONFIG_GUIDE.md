# OpenCode 项目级配置指南

基于 opencode-on-docker 和 oh-my-opencode 的实际测试结果。

---

## 配置系统概述

OpenCode + oh-my-opencode 存在**两套配置系统**，理解它们的区别是正确配置的关键：

| 系统 | 目录命名 | 用途 | 加载器 |
|------|---------|------|--------|
| **OpenCode 原生** | 单数 (`agent/`, `skill/`, `command/`) | OpenCode 内置功能 | OpenCode 核心 |
| **Claude 兼容层** | 复数 (`agents/`, `skills/`, `commands/`, `rules/`) | Claude Code 兼容 | oh-my-opencode 插件 |

### 何时使用哪套系统？

| 场景 | 推荐系统 | 原因 |
|------|---------|------|
| 纯 OpenCode 环境 | OpenCode 原生 | 无需插件依赖 |
| 使用 oh-my-opencode | 两者皆可 | 插件同时加载两套 |
| 从 Claude Code 迁移 | Claude 兼容层 | 配置文件兼容 |
| 需要条件规则 (globs) | Claude 兼容层 | OpenCode 原生不支持 |

---

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

### Agent 示例

**文件**: `.opencode/agent/my-assistant.md` (OpenCode 原生)

```markdown
---
name: my-assistant
description: 项目专属智能助手
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  bash: true
  webfetch: true
  grep: true
---

你是本项目的专属助手。

## 职责
- 理解项目架构
- 回答技术问题
- 协助代码编写

## 项目背景
[项目特定的上下文信息]
```

**文件**: `.claude/agents/my-assistant.md` (Claude 兼容层)

```markdown
---
name: my-assistant
description: 项目专属智能助手
tools: read, bash, webfetch, grep
---

你是本项目的专属助手。
...
```

---

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

### 示例

**文件**: `.opencode/skill/notebooklm/SKILL.md`

```markdown
---
name: notebooklm
description: 查询 NotebookLM notebooks，获取基于文档的 AI 回答
---

# NotebookLM Skill

## 何时使用

- 用户提到 NotebookLM
- 用户分享 NotebookLM URL
- 用户要求查询文档/笔记本

## 核心命令

```bash
cd .opencode/skill/notebooklm
python scripts/run.py ask_question.py --question "问题" --notebook-url "URL"
```
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

### 示例

**文件**: `.opencode/command/deploy.md`

```markdown
---
name: deploy
description: 部署项目到生产环境
---

请帮我部署项目。

部署参数: $ARGUMENTS

## 部署步骤
1. 运行测试
2. 构建项目
3. 推送到生产环境
```

---

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

### 示例

**文件**: `.claude/rules/typescript.md`

```markdown
---
globs: ["*.ts", "*.tsx"]
---

# TypeScript 代码规范

- 使用 `strict` 模式
- 优先使用 `interface` 而非 `type`
- 禁止使用 `any`，使用 `unknown` 替代
- 所有函数必须有显式返回类型
```

**文件**: `.claude/rules/testing.md`

```markdown
---
globs: ["*.test.ts", "*.spec.ts", "**/__tests__/**"]
---

# 测试规范

- 使用 describe/it 结构
- 每个测试只验证一个行为
- Mock 外部依赖
```

---

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

### 使用场景

- 团队共享一致的开发环境
- 锁定已知稳定的版本组合
- 避免自动更新导致的兼容性问题

---

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
