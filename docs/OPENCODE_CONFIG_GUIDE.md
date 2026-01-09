# OCD 开发者指南

本文档面向想要扩展或定制 OCD (OpenCode Docker) 的**开发者**。

---

## 1. 架构概述

### 1.1 模块化设计

OCD v3.0 采用模块化架构，各模块职责分离：

| 模块 | 文件 | 职责 |
|------|------|------|
| Core | `lib/core.sh` | XDG 路径定义、版本管理、日志、环境变量加载 |
| Port | `lib/port.sh` | 端口分配、原子锁机制（防多实例冲突） |
| Workspace | `lib/workspace.sh` | 工作区检测、项目识别、白名单验证 |
| Watcher | `lib/watcher.sh` | IPC 文件监控（剪贴板/通知/URL） |
| Config | `lib/config.sh` | 配置文件生成（opencode.json, oh-my-opencode.json） |
| Docker | `lib/docker.sh` | Docker 镜像构建与容器运行 |

### 1.2 入口流程

```
bin/ocd
   │
   ├─ 加载模块 (lib/*.sh)
   ├─ 自动迁移 v2.x → v3.0
   ├─ 解析参数
   ├─ 工作区检测
   ├─ 端口分配（原子锁）
   ├─ 初始化配置目录
   ├─ 生成配置文件
   ├─ 启动 Watcher
   └─ 运行 Docker 容器
```

---

## 2. 目录结构（XDG 规范）

OCD v3.0 遵循 [XDG Base Directory 规范](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)：

### 2.1 路径定义

| 变量 | 默认路径 | 用途 | 备份策略 |
|------|----------|------|----------|
| `OCD_CONFIG_HOME` | `~/.config/opencode/` | 配置文件 | 可版本控制 |
| `OCD_DATA_HOME` | `~/.local/share/opencode/` | 对话历史、认证 | **必须备份** |
| `OCD_STATE_HOME` | `~/.local/state/opencode/` | IPC 文件、临时状态 | 可重建 |
| `OCD_CACHE_HOME` | `~/.cache/opencode/` | 二进制缓存 | 可删除 |

### 2.2 完整目录结构

```
~/.config/opencode/                    # 配置 (OCD_CONFIG_HOME)
├── global/                            # 全局配置
│   ├── opencode/{skill,command,agent} # OpenCode 原生（单数）
│   └── claude/{skills,commands,agents,rules,settings.json,.mcp.json}
│                                      # Claude 兼容层（复数）
└── instances/<instance>/              # 实例配置
    ├── opencode.json                  # OpenCode 主配置
    └── oh-my-opencode.json            # 插件配置

~/.local/share/opencode/               # 数据 (OCD_DATA_HOME)
├── auth.json                          # OAuth 认证令牌（共享）
├── bin/                               # 二进制缓存
└── instances/<instance>/              # 对话历史
    ├── session/
    ├── message/
    └── part/

~/.local/state/opencode/               # 状态 (OCD_STATE_HOME)
└── instances/<instance>/              # IPC 文件
    ├── open_url                       # 浏览器打开
    ├── notifications                  # 桌面通知
    └── clipboard                      # 剪贴板同步

~/.cache/opencode/                     # 缓存 (OCD_CACHE_HOME)
├── oh-my-opencode/                    # ast-grep, ripgrep
└── ms-playwright/                     # 浏览器

<project>/.opencode/                   # 项目级配置（OpenCode 原生）
├── skill/                             # 项目 Skills
├── command/                           # 项目 Commands
└── agent/                             # 项目 Agents

<project>/.claude/                     # 项目级对话 + Claude 兼容层
├── todos/                             # 任务列表
├── transcripts/                       # 会话记录
├── skills/                            # 项目 Skills（手动创建）
├── commands/                          # 项目 Commands（手动创建）
├── agents/                            # 项目 Agents（手动创建）
└── rules/                             # 项目 Rules（手动创建）
```

### 2.3 容器内映射

| 宿主机路径 | 容器内路径 |
|------------|-----------|
| `~/.config/opencode/global/opencode/` | `/root/.config/opencode/` |
| `~/.config/opencode/global/claude/` | `/root/.claude/` |
| `~/.config/opencode/instances/<inst>/` | `/root/.config/opencode/` |
| `~/.local/share/opencode/instances/<inst>/` | `/root/.local/share/opencode/storage/` |
| `~/.local/state/opencode/instances/<inst>/` | `/root/.opencode/` |
| `<project>/.claude/todos/` | `/root/.claude/todos/` |
| `<project>/.claude/transcripts/` | `/root/.claude/transcripts/` |
| `<workspace>/` | `/workspace/` |

---

## 3. 配置系统

### 3.1 双配置系统

OCD 支持**两套配置系统**，目录命名规则不同：

| 系统 | 目录命名 | 用途 | 加载器 |
|------|---------|------|--------|
| **OpenCode 原生** | 单数 (`skill/`, `command/`, `agent/`) | OpenCode 内置功能 | OpenCode 核心 |
| **Claude 兼容层** | 复数 (`skills/`, `commands/`, `agents/`, `rules/`) | Claude Code 兼容 | oh-my-opencode 插件 |

> **重要**：目录名写错不会被加载！

### 3.2 配置文件

| 文件 | 路径 | 用途 |
|------|------|------|
| `opencode.json` | `~/.config/opencode/instances/<inst>/` | 主配置（模型、端口、MCP） |
| `oh-my-opencode.json` | `~/.config/opencode/instances/<inst>/` | 插件配置（Agent 模型映射） |
| `settings.json` | `~/.config/opencode/global/claude/` | Hooks 配置 |
| `.mcp.json` | `~/.config/opencode/global/claude/` | 全局 MCP 服务器 |

### 3.3 opencode.json 结构

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": [
    "oh-my-opencode@2.14.0",
    "opencode-antigravity-auth@1.2.6"
  ],
  "server": {
    "port": 4096,
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@0.0.54", "--headless"],
      "enabled": true
    }
  }
}
```

### 3.4 oh-my-opencode.json 结构

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "disabled_mcps": [],
  "disabled_hooks": [],
  "agents": {
    "Planner-Sisyphus": { "model": "anthropic/claude-opus-4-5" },
    "oracle": { "model": "openai/gpt-5.2" }
  }
}
```

### 3.5 models.conf（可选）

通过 `~/opencode/models.conf` 自定义默认模型：

```bash
# 主模型
MAIN_MODEL=anthropic/claude-opus-4-5

# Agent 模型
PLANNER_MODEL=anthropic/claude-opus-4-5
ORACLE_MODEL=openai/gpt-5.2
DOCUMENT_WRITER_MODEL=quotio/gemini-3-pro-preview
```

修改后需重新生成配置：`ocd --clean && ocd`

---

## 4. 扩展点

### 4.1 Agent（智能代理）

#### OpenCode 原生 Agent

**路径**：
- 项目级：`<project>/.opencode/agent/*.md`
- 全局：`~/.config/opencode/global/opencode/agent/*.md`

**格式**：
```markdown
---
name: my-agent
description: 显示在 @ 菜单中的描述
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  bash: true
  webfetch: true
temperature: 0.7
---

系统提示词内容...
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | Agent 名称（默认用文件名） |
| `description` | string | 描述文字 |
| `model` | string | 模型 ID（**生效**） |
| `tools` | object | 允许的工具 `{ tool: true }` |
| `temperature` | number | 模型温度 |

#### Claude 兼容层 Agent

**路径**：
- 项目级：`<project>/.claude/agents/*.md`
- 全局：`~/.config/opencode/global/claude/agents/*.md`

**格式**：
```markdown
---
name: my-agent
description: 描述
tools: read, bash, webfetch
---

系统提示词内容...
```

> **注意**：Claude 兼容层的 `model` 字段**不生效**，需在 `oh-my-opencode.json` 中配置。

### 4.2 Skill（技能包）

**路径**：
- 项目级：`<project>/.opencode/skill/<name>/SKILL.md`
- 全局：`~/.config/opencode/global/opencode/skill/<name>/SKILL.md`

**目录结构**：
```
<skill-name>/
├── SKILL.md              # 必需，技能定义
├── AGENTS.md             # 可选，AI 开发指南
├── mcp.json              # 可选，MCP 服务器配置
├── scripts/              # 可选，脚本
└── data/                 # 可选，运行时数据（应 gitignore）
```

**SKILL.md 格式**：
```markdown
---
name: my-skill
description: 触发条件描述
model: anthropic/claude-opus-4-5
allowed-tools: bash read write
mcp:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest"]
---

# 技能名称

## 何时使用
触发条件列表...

## 使用方法
具体命令和示例...
```

### 4.3 Command（斜杠命令）

**路径**：
- 项目级：`<project>/.opencode/command/*.md`
- 全局：`~/.config/opencode/global/opencode/command/*.md`

**格式**：
```markdown
---
name: deploy
description: 部署项目
---

请帮我部署项目。

参数: $ARGUMENTS

## 步骤
1. 运行测试
2. 构建项目
3. 推送到生产环境
```

使用：`/deploy production`

### 4.4 Rules（条件规则，仅 Claude 兼容层）

**路径**：
- 项目级：`<project>/.claude/rules/*.md`
- 全局：`~/.config/opencode/global/claude/rules/*.md`

**格式**：
```markdown
---
globs: ["*.ts", "*.tsx"]
---

TypeScript 代码规范：
- 使用严格模式
- 优先使用 interface 而非 type
- 禁止使用 any
```

当读取/编辑匹配 glob 的文件时，规则内容自动注入上下文。

### 4.5 Hooks（生命周期钩子）

**配置位置**：`~/.config/opencode/global/claude/settings.json`

**支持的事件**：

| 事件 | 触发时机 | 用途 |
|------|----------|------|
| `PreToolUse` | 工具执行前 | 阻止或修改工具输入 |
| `PostToolUse` | 工具执行后 | 添加警告或上下文 |
| `UserPromptSubmit` | 用户提交提示时 | 阻止或注入消息 |
| `Stop` | 会话空闲时 | 注入后续提示 |

**配置示例**：
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "if [[ \"$FILE\" == *.ts ]]; then npx eslint --fix \"$FILE\"; fi"
          }
        ]
      }
    ]
  }
}
```

### 4.6 优先级规则

当同名配置存在于多个位置时，按以下优先级（高 → 低）：

**Commands / Skills**：
1. 项目 OpenCode 原生 (`.opencode/`)
2. 全局 OpenCode 原生 (`~/.config/opencode/global/opencode/`)
3. 项目 Claude 兼容 (`.claude/`)
4. 全局 Claude 兼容 (`~/.config/opencode/global/claude/`)

**Agents / Rules**：
1. 项目级
2. 全局级

---

## 5. Docker 集成

### 5.1 环境变量

**必需**：
| 变量 | 说明 |
|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 |
| `GITHUB_TOKEN` | GitHub Token |

**可选**：
| 变量 | 说明 |
|------|------|
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 |
| `EXA_API_KEY` | Exa AI 密钥 |
| `QUOTIO_API_KEY` | Quotio 密钥 |
| `QUOTIO_BASE_URL` | Quotio 地址 |
| `OCD_WORKSPACE` | 默认工作区根目录 |
| `OCD_ALLOWED_WORKSPACES` | 工作区白名单（逗号分隔） |

**.env 格式**（纯 KEY=VALUE，无 export/引号/注释）：
```bash
OPENAI_API_KEY=sk-proj-xxxx
GITHUB_TOKEN=ghp_xxxx
```

### 5.2 挂载点

```bash
# 配置挂载
-v "$INSTANCE_CONFIG_DIR:/root/.config/opencode"
-v "$GLOBAL_OPENCODE:/root/.config/opencode"      # 合并
-v "$GLOBAL_CLAUDE:/root/.claude"

# 数据挂载
-v "$INSTANCE_DATA_DIR:/root/.local/share/opencode/storage"
-v "$AUTH_FILE:/root/.local/share/opencode/auth.json"

# 项目数据挂载（覆盖全局 .claude）
-v "$PROJECT/.claude/todos:/root/.claude/todos"
-v "$PROJECT/.claude/transcripts:/root/.claude/transcripts"

# 状态挂载
-v "$INSTANCE_STATE_DIR:/root/.opencode"

# 工作区挂载
-v "$WORKSPACE:/workspace"
```

### 5.3 版本锁定

创建 `~/opencode/versions.lock` 锁定依赖版本：

```bash
BUN_VERSION=1.3.5
OPENCODE_AI_VERSION=1.1.4
OH_MY_OPENCODE_VERSION=2.14.0
PLAYWRIGHT_MCP_VERSION=0.0.54
```

---

## 6. IPC 通信机制

OCD 通过文件 IPC 实现容器与宿主机通信。

### 6.1 IPC 文件

| 文件 | 路径 | 用途 |
|------|------|------|
| `open_url` | `~/.local/state/opencode/instances/<inst>/` | 浏览器打开 URL |
| `notifications` | 同上 | 桌面通知 |
| `clipboard` | 同上 | 剪贴板同步 |

### 6.2 Watcher 机制

**fswatch 模式**（推荐，需安装 fswatch）：
```bash
fswatch -o --event Created --event Updated "$URL_FILE" "$NOTIFY_FILE" "$CLIPBOARD_FILE" | \
while IFS= read -r _; do
  ocd_handle_url "$url_file"
  ocd_handle_notify "$notify_file"
  ocd_handle_clipboard "$clipboard_file"
done
```

**轮询模式**（兼容，CPU 略高）：
```bash
while true; do
  ocd_handle_url "$url_file"
  ocd_handle_notify "$notify_file"
  ocd_handle_clipboard "$clipboard_file"
  sleep 1
done
```

### 6.3 容器内写入

```bash
# 打开 URL
echo "https://example.com" > /root/.opencode/open_url

# 发送通知
echo "标题|内容" >> /root/.opencode/notifications

# 写入剪贴板
echo "复制内容" > /root/.opencode/clipboard
```

---

## 7. 调试与开发

### 7.1 日志位置

- 容器日志：`docker logs opencode-<instance>`
- OCD 脚本日志：直接输出到终端

### 7.2 调试技巧

```bash
# 查看当前实例配置
cat ~/.config/opencode/instances/<inst>/opencode.json | jq .

# 查看 IPC 文件状态
ls -la ~/.local/state/opencode/instances/<inst>/

# 查看 Watcher 进程
ps aux | grep fswatch

# 强制重新生成配置
ocd --clean && ocd

# 完全清理实例
ocd --purge
```

### 7.3 运行测试

```bash
brew install bats-core jq
bats tests/bats/
```

### 7.4 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 配置不生效 | 目录名单复数错误 | 检查 `.opencode/` vs `.claude/` |
| Agent model 不生效 | Claude 兼容层不支持 | 在 `oh-my-opencode.json` 中配置 |
| 端口冲突 | 锁文件残留 | `rm ~/.config/opencode/.port.lock` |
| fswatch 不工作 | 未安装 | `brew install fswatch` |
| 浏览器不打开 | IPC 文件为空 | 检查容器内 `/root/.opencode/open_url` |

---

## 8. .gitignore 建议

```gitignore
# 会话数据
.claude/todos/
.claude/transcripts/

# Skill 运行时数据
.opencode/skill/*/data/
.claude/skills/*/data/

# Python 虚拟环境
.opencode/skill/*/.venv/
.claude/skills/*/.venv/

# macOS
.DS_Store

# Node
node_modules/
```
