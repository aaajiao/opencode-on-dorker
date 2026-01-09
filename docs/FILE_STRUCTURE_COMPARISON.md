# OCD / OpenCode / Claude CLI 文件结构设计对比

本文档详细对比三套系统的文件结构和配置设计差异。

## 目录

- [整体架构对比](#整体架构对比)
- [XDG 路径规范](#xdg-路径规范)
- [完整目录结构](#完整目录结构)
- [配置优先级](#配置优先级)
- [配置文件格式](#配置文件格式)
- [目录命名规则](#目录命名规则)
- [功能特性对比](#功能特性对比)
- [推荐使用策略](#推荐使用策略)

---

## 整体架构对比

| 维度 | **OCD (本项目)** | **OpenCode** | **Claude CLI** |
|------|-----------------|--------------|----------------|
| **定位** | Docker 运行环境 + 配置管理 | AI 编程助手 CLI | AI 编程助手 CLI |
| **目录命名** | 同时支持两套 | **单数优先** (`skill/`, `command/`, `agent/`) | **复数** (`skills/`, `commands/`, `agents/`) |
| **配置入口** | `bin/ocd` + Docker (模块化) | `~/.config/opencode/` | `~/.claude/` |
| **存储规范** | XDG + 多实例隔离 | XDG Base Directory | 集中存储 |
| **特殊能力** | 跨系统桥接、多实例 | 插件系统、远程配置 | Rules、Hooks、沙箱 |

---

## XDG 路径规范

OpenCode 严格遵循 **XDG Base Directory 规范**，而 Claude CLI 将所有内容集中在 `~/.claude/` 下。

| 路径类型 | **OpenCode** | **Claude CLI** | **OCD** |
|---------|-------------|----------------|---------|
| **Config** | `~/.config/opencode/` | `~/.claude/` | `~/.config/opencode/<instance>/` |
| **Data** | `~/.local/share/opencode/` | `~/.claude/` (合并) | `~/.opencode_data/<instance>/` |
| **State** | `~/.local/state/opencode/` | `~/.claude/` (合并) | `~/.local/state/opencode/` (共享) |
| **Cache** | `~/.cache/opencode/` | - | `~/.cache/oh-my-opencode/` |
| **Log** | `~/.local/share/opencode/log/` | `~/.claude/debug/` | 同 OpenCode |

---

## 完整目录结构

### OpenCode 原生

```
~/.config/opencode/                    # 全局配置
├── opencode.json                      # 主配置文件
├── skill/*/SKILL.md                   # 全局 Skills（单数）
├── command/*.md                       # 全局 Commands（单数）
├── agent/*.md                         # 全局 Agents（单数）
└── plugin/*.{ts,js}                   # 全局 Plugins

~/.local/share/opencode/               # 数据存储
├── auth.json                          # 认证信息
├── bin/                               # 二进制文件
├── log/                               # 日志
└── storage/                           # 会话数据
    └── session/
        ├── info/*.json                # 会话元数据
        ├── message/<session_id>/*.json # 消息内容
        └── part/<session_id>/<msg_id>/ # 消息分块

~/.local/state/opencode/               # UI 状态 (KV store)

~/.cache/opencode/                     # 缓存

project/.opencode/                     # 项目级配置
├── opencode.json                      # 项目配置
├── skill/                             # 项目 Skills
├── command/                           # 项目 Commands
├── agent/                             # 项目 Agents
└── oh-my-opencode.json                # oh-my-opencode 配置
```

### Claude CLI 原生

```
~/.claude/                             # 所有用户级数据
├── settings.json                      # 用户全局设置
├── .claude.json                       # 偏好、OAuth、MCP
├── CLAUDE.md                          # 全局指令
├── agents/*.md                        # 用户级 Agents（复数）
├── skills/*/SKILL.md                  # 用户级 Skills（复数）
├── history.jsonl                      # 会话元数据
├── projects/                          # 会话记录（按项目编码）
│   └── -home-user-project/            # 路径编码 (/home/user/project)
│       └── *.jsonl                    # 会话文件
├── session-env/                       # 会话环境
├── todos/                             # 任务列表
└── debug/                             # LSP 日志

project/.claude/                       # 项目级配置
├── settings.json                      # 团队共享设置 (Git 跟踪)
├── settings.local.json                # 个人覆盖 (gitignore)
├── agents/                            # 项目 Agents
├── skills/                            # 项目 Skills
├── commands/                          # 项目 Commands
├── rules/                             # 条件规则（Claude 独有）
└── CLAUDE.md                          # 项目上下文

project/.mcp.json                      # MCP 服务器（独立文件）
project/CLAUDE.md                      # 可选位置
project/CLAUDE.local.md                # 个人指令 (gitignore)
```

### OCD (本项目)

```
~/opencode/                            # 配置仓库（宿主机）
├── bin/
│   └── ocd                            # 入口脚本（添加到 PATH）
│
├── lib/                               # 模块化核心库
│   ├── core.sh                        # 版本/日志/环境变量加载
│   ├── port.sh                        # 端口管理（原子锁机制）
│   ├── workspace.sh                   # 工作区检测/白名单验证
│   ├── watcher.sh                     # IPC 监控（剪贴板/通知/URL）
│   ├── config.sh                      # 配置生成（消除 heredoc 重复）
│   └── docker.sh                      # Docker 构建与运行
│
├── tests/                             # 测试套件
│   └── bats/                          # Bats 单元测试
│       ├── core.bats
│       ├── port.bats
│       ├── workspace.bats
│       └── config.bats
│
├── opencode.sh                        # 旧版入口（兼容）
├── Dockerfile                         # 镜像定义
├── .env                               # API Keys (KEY=VALUE 格式)
├── VERSION                            # 版本号
├── global/
│   ├── opencode/                      # OpenCode 全局配置
│   │   ├── skill/
│   │   ├── command/
│   │   └── agent/
│   └── claude/                        # Claude 兼容层全局配置
│       ├── skills/
│       ├── commands/
│       ├── agents/
│       ├── rules/
│       ├── settings.json              # Hooks 配置
│       └── .mcp.json                  # MCP 服务器
│
└── .opencode/                         # 配置仓库自身的项目配置

~/.config/opencode/<instance>/         # 实例配置（容器内 /root/.config/opencode/）
├── opencode.json
└── oh-my-opencode.json

~/.opencode_data/<instance>/           # 实例运行时数据（容器内 /root/.opencode/）
├── open_url                           # URL 桥接
├── notifications                      # 通知桥接
└── clipboard                          # 剪贴板桥接

~/.local/share/opencode/               # 共享数据
└── auth.json                          # 认证（所有实例共享）

~/.local/state/opencode/               # UI 状态（共享）

~/.cache/oh-my-opencode/               # 二进制缓存（共享）
```

### OCD 容器挂载映射

| 宿主机路径 | 容器内路径 | 用途 |
|-----------|-----------|------|
| `$(pwd)` | `/workspace` | 项目文件 |
| `~/.opencode_data/<instance>` | `/root/.opencode` | 实例数据 |
| `~/.config/opencode/<instance>` | `/root/.config/opencode` | 实例配置 |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | UI 设置持久化 |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | 二进制缓存 |
| `~/opencode/global/opencode/` | `/root/.config/opencode/{skill,command,agent}` | 全局 OpenCode |
| `~/opencode/global/claude/` | `/root/.claude/` | 全局 Claude |

---

## 配置优先级

### OpenCode 配置加载顺序（6 层）

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 (最低) | **Remote config** | `.well-known/opencode` (组织默认) |
| 2 | **Global config** | `~/.config/opencode/opencode.json` |
| 3 | **Custom config** | `OPENCODE_CONFIG` 环境变量 |
| 4 | **Project config** | `opencode.json` 项目根目录 |
| 5 | **`.opencode` dirs** | agents, commands, plugins |
| 6 (最高) | **Inline config** | `OPENCODE_CONFIG_CONTENT` 环境变量 |

### Claude CLI 配置加载顺序（5 层）

| 优先级 | 范围 | 路径 | Git 跟踪 |
|--------|------|------|----------|
| 1 (最高) | **Managed** | `/Library/Application Support/ClaudeCode/` | IT 部署 |
| 2 | **CLI args** | `--arg` 命令行参数 | - |
| 3 | **Local** | `.claude/settings.local.json` | ❌ |
| 4 | **Project** | `.claude/settings.json` | ✅ |
| 5 (最低) | **User** | `~/.claude/settings.json` | ❌ |

### OCD 配置加载顺序

OCD 同时支持两套系统，实际优先级：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 (最高) | 项目 `.opencode/` | OpenCode 原生项目级 |
| 2 | 全局 `~/.config/opencode/` | OpenCode 原生全局 |
| 3 | 项目 `.claude/` | Claude 兼容层项目级 |
| 4 (最低) | 全局 `~/.claude/` | Claude 兼容层全局 |

---

## 配置文件格式

### opencode.json vs settings.json

| 字段 | **opencode.json** | **settings.json** |
|------|-------------------|-------------------|
| **Schema** | `https://opencode.ai/config.json` | `https://json.schemastore.org/claude-code-settings.json` |
| **模型配置** | `model`, `small_model` | `model` 或 `env.ANTHROPIC_MODEL` |
| **Agent 定义** | `agent: { build: {...} }` | 在 `agents/*.md` 文件中 |
| **命令定义** | `command: { name: {...} }` | 在 `commands/*.md` 文件中 |
| **权限控制** | `permission: { edit: "ask" }` | `permissions: { allow: [], deny: [] }` |
| **MCP 配置** | `mcp: {...}` 内嵌 | `.mcp.json` 独立文件 |
| **Hooks** | ❌ 不支持 | `hooks: { PreToolUse: [...] }` |
| **沙箱** | ❌ 不支持 | `sandbox: { enabled: true }` |
| **Compaction** | `compaction: { auto: true }` | ❌ |
| **Instructions** | `instructions: ["file.md"]` | `CLAUDE.md` 文件 |

### Agent 配置格式差异

**OpenCode 原生** (`.opencode/agent/*.md`):

```markdown
---
name: github
description: GitHub 工作流助手
model: anthropic/claude-sonnet-4-5      # ✅ 生效
tools:
  bash: true                            # ✅ Object 格式
  read: true
temperature: 0.7                        # ✅ 生效
---

系统提示词...
```

**Claude 兼容** (`.claude/agents/*.md`):

```markdown
---
name: github
description: GitHub 工作流助手
model: claude-sonnet-4-5                # ❌ 不生效！
tools: bash, read, edit                 # ⚠️ 逗号分隔字符串
---

系统提示词...
```

### settings.json 详细结构（Claude CLI）

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  
  "permissions": {
    "allow": ["Bash(git commit:*)"],
    "ask": ["Bash(git push:*)"],
    "deny": ["Read(./.env)"],
    "defaultMode": "acceptEdits"
  },
  
  "env": {
    "ANTHROPIC_MODEL": "claude-sonnet-4-5-20250929"
  },
  
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "echo 'Editing...'" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "prettier --write", "timeout": 5 }]
      }
    ]
  },
  
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["git", "docker"]
  },
  
  "cleanupPeriodDays": 30,
  "alwaysThinkingEnabled": true
}
```

---

## 目录命名规则

OpenCode 源码显示**同时支持单复数**：

```typescript
// skill/skill.ts
const OPENCODE_SKILL_GLOB = new Bun.Glob("{skill,skills}/**/SKILL.md")

// config/config.ts  
const COMMAND_GLOB = new Bun.Glob("{command,commands}/**/*.md")
const AGENT_GLOB = new Bun.Glob("{agent,agents}/**/*.md")
const PLUGIN_GLOB = new Bun.Glob("{plugin,plugins}/*.{ts,js}")
```

### 兼容性矩阵

| 目录类型 | OpenCode 支持 | Claude CLI 支持 | 推荐场景 |
|---------|--------------|----------------|----------|
| `skill/` | ✅ | ❌ | OpenCode 原生项目 |
| `skills/` | ✅ | ✅ | Claude 兼容、跨工具 |
| `command/` | ✅ | ❌ | OpenCode 原生项目 |
| `commands/` | ✅ | ✅ | Claude 兼容、跨工具 |
| `agent/` | ✅ | ❌ | OpenCode 原生项目 |
| `agents/` | ✅ | ✅ | Claude 兼容、跨工具 |
| `plugin/` | ✅ | ❌ | OpenCode 独有功能 |
| `rules/` | ❌ | ✅ | Claude 独有功能 |

---

## 功能特性对比

| 特性 | **OpenCode** | **Claude CLI** | **OCD** |
|------|-------------|----------------|---------|
| **多实例** | ❌ 单实例 | ❌ 单实例 | ✅ 原生支持 |
| **XDG 规范** | ✅ 严格遵循 | ❌ 集中存储 | ✅ 继承 OpenCode |
| **沙箱隔离** | ❌ | ✅ 内置 | ✅ Docker 容器 |
| **Hooks** | ❌ | ✅ Pre/Post Tool | ✅ Claude 兼容层 |
| **Rules** | ❌ | ✅ glob 匹配 | ✅ Claude 兼容层 |
| **Plugin** | ✅ `.ts/.js` | ❌ | ✅ 继承 |
| **远程配置** | ✅ `.well-known` | ❌ | ✅ 继承 |
| **macOS 集成** | ❌ | 部分 | ✅ 通知/剪贴板/URL |
| **会话编码** | 内置数据库 | 路径转横杠 | 项目内隔离 |

### 会话存储方式对比

| 系统 | 存储位置 | 编码方式 |
|------|---------|----------|
| **OpenCode** | `~/.local/share/opencode/storage/session/` | 内置数据库 |
| **Claude CLI** | `~/.claude/projects/<encoded>/` | 路径转横杠 (`/home/user/proj` → `-home-user-proj`) |
| **OCD** | 项目内 `.claude/transcripts/` | 通过挂载实现项目隔离 |

---

## 推荐使用策略

### 按场景选择配置路径

| 场景 | 推荐路径 | 原因 |
|------|---------|------|
| **需要指定模型的 Agent** | `.opencode/agent/` | model 字段生效 |
| **需要条件规则** | `.claude/rules/` | OpenCode 不支持 rules |
| **需要 Hooks** | `settings.json` | OpenCode 不支持 hooks |
| **全局 Skill** | `~/opencode/global/opencode/skill/` | 优先级更高 |
| **项目 Skill** | `.opencode/skill/` | 优先级最高 |
| **团队共享配置** | `.claude/settings.json` | Git 跟踪 |
| **个人覆盖** | `.claude/settings.local.json` | gitignore |

### 关键差异总结

| 差异点 | OpenCode 原生 | Claude CLI | OCD 处理 |
|--------|--------------|-----------|----------|
| **目录命名** | 单数优先 | 复数 | 两套都支持 |
| **model 字段** | ✅ 生效 | ❌ 不生效 | 通过 oh-my-opencode.json |
| **tools 格式** | Object `{bash: true}` | String `"bash, read"` | 各自解析 |
| **Rules 条件** | ❌ 不支持 | ✅ 支持 | 用 Claude 兼容层 |
| **Hooks** | ❌ 不支持 | ✅ 支持 | 用 Claude 兼容层 |
| **Plugins** | ✅ 支持 | ❌ 不支持 | 继承 OpenCode |

---

## IPC 机制（OCD 特有）

OCD 需要解决容器与宿主机之间的通信：

```
容器内                              宿主机
──────────────────────────────────────────────
notify "Title" "Msg"  →  /root/.opencode/notifications  →  osascript/terminal-notifier
xclip (复制)          →  /root/.opencode/clipboard       →  pbcopy
open URL              →  /root/.opencode/open_url        →  open (浏览器)
```

---

## 参考资源

- [OpenCode 官方文档](https://opencode.ai/docs/config)
- [OpenCode 配置 Schema](https://opencode.ai/config.json)
- [Claude CLI 设置文档](https://code.claude.com/docs/en/settings)
- [Claude CLI 设置 Schema](https://json.schemastore.org/claude-code-settings.json)
- [sst/opencode GitHub](https://github.com/sst/opencode)
