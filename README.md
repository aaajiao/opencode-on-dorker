# OCD - OpenCode Docker

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](./CHANGELOG.md)

在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手的完整配置，集成 oh-my-opencode 插件。

## 功能特性

- ✅ 一键启动 OpenCode 容器
- ✅ **多实例支持**（同时编辑多个项目，自动端口分配）
- ✅ 链接自动在 Mac 浏览器打开
- ✅ **macOS 桌面通知支持**（容器内任务完成时通知宿主机）
- ✅ GitHub CLI 自动认证（通过 GITHUB_TOKEN）
- ✅ OAuth 认证支持（Claude Max、Gemini Pro）
- ✅ 配置和认证信息持久化
- ✅ Web UI 可访问
- ✅ 环境变量动态配置
- ✅ **oh-my-opencode 多 Agent 协作**
- ✅ **MCP 服务器 (Context7, Playwright, Exa)**

## oh-my-opencode Agent 配置

### 内置 Agent

| Agent | 默认模型 | 用途 |
|-------|---------|------|
| **Sisyphus** | `anthropic/claude-opus-4-5` | 主编排器，扩展思考 |
| **oracle** | `openai/gpt-5.2` | 架构设计、调试、代码审查 |
| **librarian** | `anthropic/claude-sonnet-4-5` | 文档、开源研究、GitHub 示例 |
| **explore** | `opencode/grok-code` | 快速上下文搜索（免费） |
| **frontend-ui-ux-engineer** | `google/gemini-3-pro-preview` | UI/UX 代码生成 |
| **document-writer** | `google/gemini-3-pro-preview` | 技术文档写作 |
| **multimodal-looker** | `google/gemini-3-flash` | PDF/图像分析 |

> 插件会自动选择可用模型，无需手动配置。如果某个模型不可用，会使用 fallback。

### 模型来源

| 来源 | 认证方式 |
|------|---------|
| Claude Max | OAuth: `opencode auth login` → Anthropic |
| Gemini Pro | OAuth: `opencode auth login` → Google Antigravity |
| OpenAI API | 环境变量 `OPENAI_API_KEY` |
| OpenCode 免费 | 无需认证 |

### 自定义配置（可选）

如需覆盖默认模型，编辑实例的配置文件 `~/.config/opencode/<instance>/oh-my-opencode.json`：

```json
{
  "google_auth": false,
  "agents": {
    "frontend-ui-ux-engineer": {
      "model": "google/gemini-2.5-pro"
    }
  }
}
```

## MCP 服务器

| MCP | 来源 | 功能 |
|-----|------|------|
| context7 | oh-my-opencode 内置 | 官方文档查询 |
| exa | oh-my-opencode 内置 | 网页搜索（需 EXA_API_KEY） |
| grep_app | oh-my-opencode 内置 | GitHub 代码搜索 |
| playwright | opencode.json 配置 | 浏览器自动化 |
| exa (fallback) | opencode.json 配置 | 内置 Exa 不可用时自动启用 |

### Exa 动态检测

启动时自动检测内置 Exa 是否可用：
- ✅ **内置可用** → 使用 oh-my-opencode 内置的 Exa（默认）
- ⚠️ **内置不可用** → 自动启用 fallback MCP（exa-mcp-server）
- ℹ️ **无 API Key** → Exa 功能不可用

检测结果会在启动时显示。

## 文件结构

```
~/opencode/                           # 配置仓库（自身也是一个项目）
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
│  ── 全局配置（对所有子项目生效） ──
│
├── global/
│   ├── opencode/                     # OpenCode 原生全局配置
│   │   ├── skill/                    # 全局 Skills
│   │   ├── command/                  # 全局 Commands
│   │   └── agent/                    # 全局 Agents
│   │
│   └── claude/                       # Claude 兼容层全局配置
│       ├── skills/                   # 全局 Skills
│       ├── commands/                 # 全局 Commands
│       ├── agents/                   # 全局 Agents
│       ├── rules/                    # 全局 Rules
│       ├── settings.json             # 全局 Hooks
│       └── .mcp.json                 # 全局 MCP
│
│  ── 项目文件 ──
│
├── opencode.sh                       # Shell 函数（ocd 命令）
├── Dockerfile                        # Docker 镜像
├── docker-compose.yml                # Docker Compose
├── .env                              # 环境变量（API Keys）
├── .gitignore
├── VERSION
└── README.md

~/my-project/                         # 子项目示例
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

~/.config/opencode/<instance>/        # 实例配置
├── opencode.json
└── oh-my-opencode.json

~/.opencode_data/<instance>/          # 实例运行时数据
├── open_url
└── notifications

~/.local/share/opencode/              # 共享数据
└── auth.json                         # OAuth 认证信息
```

### 配置系统说明

OCD 支持两套配置系统，按优先级排列：

1. **OpenCode 原生**（基础，不依赖插件）
2. **Claude 兼容层**（oh-my-opencode 插件提供）

#### 目录命名规则

| 系统 | 目录命名 | 示例 |
|------|---------|------|
| OpenCode 原生 | **单数** | `skill/`, `command/`, `agent/` |
| Claude 兼容层 | **复数** | `skills/`, `commands/`, `agents/`, `rules/` |

> ⚠️ **写错目录名不会被加载！**

#### 全局配置

**OpenCode 原生全局**（`~/opencode/global/opencode/`）：

| 宿主机路径 | 容器内路径 |
|-----------|-----------|
| `global/opencode/skill/` | `/root/.config/opencode/skill/` |
| `global/opencode/command/` | `/root/.config/opencode/command/` |
| `global/opencode/agent/` | `/root/.config/opencode/agent/` |

**Claude 兼容层全局**（`~/opencode/global/claude/`）：

| 宿主机路径 | 容器内路径 |
|-----------|-----------|
| `global/claude/skills/` | `/root/.claude/skills/` |
| `global/claude/commands/` | `/root/.claude/commands/` |
| `global/claude/agents/` | `/root/.claude/agents/` |
| `global/claude/rules/` | `/root/.claude/rules/` |
| `global/claude/settings.json` | `/root/.claude/settings.json` |
| `global/claude/.mcp.json` | `/root/.claude/.mcp.json` |

#### 项目级配置

每个项目可以有自己的配置，会覆盖全局配置。

**OpenCode 原生**（`<project>/.opencode/`）：

| 路径 | 容器内路径 |
|------|-----------|
| `.opencode/skill/` | `/workspace/.opencode/skill/` |
| `.opencode/command/` | `/workspace/.opencode/command/` |
| `.opencode/agent/` | `/workspace/.opencode/agent/` |

**Claude 兼容层**（`<project>/.claude/`）：

| 路径 | 容器内路径 |
|------|-----------|
| `.claude/skills/` | `/workspace/.claude/skills/` |
| `.claude/commands/` | `/workspace/.claude/commands/` |
| `.claude/agents/` | `/workspace/.claude/agents/` |
| `.claude/rules/` | `/workspace/.claude/rules/` |

#### 会话数据

每个项目的会话数据（todos/transcripts）存放在项目目录下：

| 路径 | 容器内路径 | 说明 |
|------|-----------|------|
| `<project>/.claude/todos/` | `/root/.claude/todos/` | 任务列表 |
| `<project>/.claude/transcripts/` | `/root/.claude/transcripts/` | 会话记录 |

> 会话数据通过覆盖挂载实现隔离，每个项目的数据跟着项目走。

#### 自动初始化

运行 `ocd` 时会自动创建以下目录：

- `<project>/.opencode/{skill,command,agent}/`（OpenCode 原生）
- `<project>/.claude/{todos,transcripts}/`（会话数据）

#### 优先级

| 系统 | 优先级 1（高） | 优先级 2（低） |
|------|---------------|---------------|
| OpenCode 原生 | `/workspace/.opencode/` | `/root/.config/opencode/` |
| Claude 兼容层 | `/workspace/.claude/` | `/root/.claude/` |

#### 使用场景

| 场景 | 放置位置 |
|------|----------|
| 所有项目通用的命令 | `~/opencode/global/claude/commands/` |
| 特定项目的部署命令 | `<project>/.opencode/command/` 或 `<project>/.claude/commands/` |
| 通用代码规范 | `~/opencode/global/claude/rules/` |
| 项目特有的规范 | `<project>/.claude/rules/` |

> 详细配置指南请参考 [OPENCODE_CONFIG_GUIDE.md](./OPENCODE_CONFIG_GUIDE.md)。

## 安装步骤

### 1. 创建项目目录

```bash
mkdir -p ~/opencode
cd ~/opencode

# 复制文件到此目录:
# - Dockerfile
# - docker-compose.yml
# - env.example → 重命名为 .env
```

### 2. 配置环境变量

```bash
cp env.example .env
nano .env  # 填写你的 API keys
```

```bash
# ~/opencode/.env
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
QUOTIO_API_KEY=your-api-key
QUOTIO_BASE_URL=http://localhost:8317/v1
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key  # 可选，用于 websearch_exa
```

> ⚠️ **注意**：
> - `.env` 文件不能有注释和引号，必须是纯 `KEY=VALUE` 格式
> - `QUOTIO_BASE_URL` 使用 `localhost` 而非 `host.docker.internal`（因为使用 host 网络模式）

### 3. 添加 Shell 函数

在 `~/.zshrc` 中引用 `opencode.sh`（推荐，方便后续更新）：

```bash
echo 'source ~/opencode/opencode.sh' >> ~/.zshrc
source ~/.zshrc
```

> **更新 opencode.sh 后生效方法**：
> 如果更新了 `opencode.sh` 文件，需要：
> 1. `exit` 退出容器
> 2. `exec zsh` 重新加载 shell
> 3. `ocd` 重新启动
>
> 仅 `source ~/.zshrc` 可能无法覆盖已加载的函数。

### 4. 首次构建

```bash
ocd -r
```

### 5. 认证（在 OpenCode TUI 中）

启动后在 TUI 输入框中输入命令：

```bash
# Claude Max 认证
opencode auth login
# → 选择 Anthropic → Claude Pro/Max
# → 浏览器自动打开，完成认证

# Gemini Pro 认证
opencode auth login
# → 选择 Google → OAuth with Google (Antigravity)
# → 浏览器自动打开，完成认证
```

## 使用方法

### 基本使用

```bash
# 在任意项目目录下启动（实例名自动取目录名）
cd ~/my-project
ocd

# 重建镜像 + 清理所有实例配置
ocd -r

# 重建镜像 + 保留配置
ocd -r --keep

# 查看版本
ocd -v

# 访问 Web UI（端口会在启动时显示）
open http://localhost:4096
```

### 多实例运行

支持同时编辑多个不相关的项目：

```bash
# 终端 1：编辑项目 A
cd ~/project-a
ocd                   # 实例: project-a, 端口: 4096

# 终端 2：编辑项目 B
cd ~/project-b
ocd                   # 实例: project-b, 端口: 4097（自动分配）
```

**启动时显示：**
```
🚀 OCD v1.1.0
📦 实例: project-a
📂 工作目录: /Users/xxx/project-a
🌐 Web UI: http://localhost:4096
```

**可选参数：**

| 参数 | 说明 | 示例 |
|------|------|------|
| `-v` | 显示版本号 | `ocd -v` |
| `-n <name>` | 指定实例名（覆盖目录名） | `ocd -n myapp` |
| `-p <port>` | 指定端口（覆盖自动分配） | `ocd -p 5000` |
| `-r` | 重建镜像 + 清理所有实例配置 | `ocd -r` |
| `-r --keep` | 重建镜像 + 保留配置 | `ocd -r --keep` |
| `--quotio` | 启用 Quotio 代理（仅限新配置生成时） | `ocd --quotio` |

**查看运行中的实例：**
```bash
docker ps | grep opencode
```

### Quotio 代理支持

项目内置了对 Quotio 代理的可选支持，允许通过自定义代理使用更多模型。

- **默认状态**：已禁用。
- **启用方式**：在启动时添加 `--quotio` 开关。
- **生效范围**：仅在生成**新配置**时生效（即新实例首次启动，或执行 `opencode -r` 后）。

```bash
# 启用 Quotio 代理启动新项目
cd ~/new-project
ocd --quotio
```

启用后，`frontend-ui-ux-engineer` 等 Agent 会默认使用通过 Quotio 代理提供的模型。

### oh-my-opencode 常用命令

```
ultrawork / ulw    # 最大性能模式
@oracle            # 调用调试专家
@librarian         # 查找文档/实现
@explore           # 快速代码搜索
ultrathink         # 深度思考模式
```

### Docker Compose 方式

```bash
cd ~/opencode
docker-compose run --rm opencode

# 重建镜像
docker-compose build --no-cache
```

## 网络模式说明

本配置使用 `--network host` 模式：

| 特性 | 说明 |
|------|------|
| OAuth 回调 | ✅ 支持（容器与 Mac 共享 localhost） |
| Web UI 地址 | `http://localhost:<port>`（启动时显示） |
| Quotio 地址 | `http://localhost:8317/v1`（仅在启用 --quotio 时使用） |
| OrbStack Magic Domain | ❌ 不支持 |

> **为什么用 Host 模式？**
> OAuth 认证回调使用随机端口（如 localhost:51121），Bridge 模式下容器无法接收回调。Host 模式让容器共享 Mac 网络，解决此问题。

## 配置说明

### 环境变量 (.env)

| 变量 | 说明 | 必需 |
|------|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 (用于 Oracle GPT-5.2) | 是 |
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | 否 |
| `QUOTIO_API_KEY` | Quotio Provider API 密钥 | 否 (若用 --quotio 则必需) |
| `QUOTIO_BASE_URL` | Quotio Provider API 地址 | 否 (若用 --quotio 则必需) |
| `GITHUB_TOKEN` | GitHub Personal Access Token | 是 |
| `EXA_API_KEY` | Exa AI API 密钥（用于 websearch_exa） | 否 |

### 获取 API Keys

| 服务 | 获取地址 |
|------|----------|
| OpenAI | https://platform.openai.com/api-keys |
| GitHub Token | https://github.com/settings/tokens |
| Exa AI | https://dashboard.exa.ai/api-keys |

### 配置文件说明

| 文件 | 说明 |
|------|------|
| `opencode.json` | 主配置：server、provider、model、mcp、plugin |
| `oh-my-opencode.json` | 插件配置：agent 模型分配、禁用的 MCP |

### 配置重置

```bash
# 重建镜像 + 清理所有实例配置（推荐）
ocd -r

# 重建镜像 + 保留配置（仅更新 OpenCode 版本）
ocd -r --keep

# 手动删除特定实例配置
rm -rf ~/.config/opencode/my-project/
rm -rf ~/.opencode_data/my-project/
ocd
```

## 数据持久化

| 目录 | 说明 |
|------|------|
| `~/.config/opencode/<instance>/` | 实例配置文件（隔离） |
| `~/.opencode_data/<instance>/` | 实例数据、URL 监听、通知文件（隔离） |
| `~/.local/share/opencode/` | OAuth 认证信息（所有实例共享） |

## macOS 桌面通知

由于 Docker 容器无法直接发送 macOS 桌面通知，本项目通过共享文件机制实现：

**原理**：
1. 容器内 `notify` 命令将通知写入共享文件 `~/.opencode_data/notifications`
2. 宿主机监听脚本检测到新内容后，使用 `terminal-notifier` 发送带自定义图标的 macOS 通知

**自定义图标**：

通知右侧会显示 `~/opencode/ghostty-128.png` 自定义图标。

**使用方法**（在容器内）：
```bash
notify "标题" "通知内容"
```

**示例**：
```bash
notify "OpenCode" "后台任务已完成！"
notify "构建成功" "项目编译完成，耗时 2 分钟"
```

> 如果未安装 `terminal-notifier` 或图标文件不存在，会自动回退到 `osascript` 发送通知。

**oh-my-opencode 自动支持**：

容器内已伪造 `osascript` 和 `notify-send` 命令，oh-my-opencode 的通知 hook（`session-notification`、`background-notification`）会自动通过此机制发送 macOS 通知，无需额外配置。

## 常见问题

### 任务完成通知

当你希望任务完成后收到 macOS 桌面通知时，可以说：

- "完成后提醒我"
- "做完通知我"
- "帮我xxx，然后提醒我"

AI 会在任务结束后调用 `notify` 命令发送桌面通知。


### Q: 环境变量没有加载？

确保 `.env` 文件格式正确：
- 不能有 `export` 关键字
- 不能有引号
- 不能有注释

### Q: oh-my-opencode 没有加载？

检查 `~/.config/opencode/opencode.json` 中是否有 plugin 配置：

```json
{
  "plugin": [
    "oh-my-opencode",
    "opencode-antigravity-auth"
  ]
}
```

### Q: MCP 加载很慢或报错？

可能是 `websearch_exa` 缺少 API key。两种解决方案：

**方案一**：添加 Exa API key
```bash
echo "EXA_API_KEY=your-key" >> ~/opencode/.env
```

**方案二**：禁用 websearch_exa
```bash
# 编辑 ~/.config/opencode/oh-my-opencode.json
# 添加 "disabled_mcps": ["websearch_exa"]
```

### Q: OAuth 认证失败？

确保使用 `--network host` 模式。如果 URL 没有自动打开：
- Ghostty: `Cmd + 点击` URL 手动打开

### Q: Agent 认证失败？

1. Claude Max: 运行 `opencode auth login` → Anthropic
2. Gemini Pro: 运行 `opencode auth login` → Google (Antigravity)
3. OpenAI API: 确保 `.env` 中 `OPENAI_API_KEY` 正确

### Q: Web UI 无法访问？

确保：
1. `opencode.json` 中 server 配置正确
2. 访问启动时显示的端口地址（如 `http://localhost:4096`）
3. 多实例时每个实例端口不同，查看启动时的输出

### Q: GitHub 登录失败？

1. 检查 `.env` 中的 `GITHUB_TOKEN` 是否正确
2. Token 需要 `repo` 权限
3. 申请地址：https://github.com/settings/tokens

## 依赖要求

- macOS
- [OrbStack](https://orbstack.dev/) 或 Docker Desktop
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) (推荐，用于自定义图标通知)
- [jq](https://jqlang.github.io/jq/) (可选，用于智能更新配置)

安装依赖：
```bash
brew install terminal-notifier jq
```

## Ghostty 终端配置（可选）

如果使用 Ghostty 终端，添加以下配置以启用链接检测：

```
# ~/.config/ghostty/config
link-url = true
```

链接可通过 `Cmd + 点击` 打开。
