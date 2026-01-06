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
| websearch_exa | oh-my-opencode 内置 | 网页搜索（需 EXA_API_KEY） |
| grep_app | oh-my-opencode 内置 | GitHub 代码搜索 |
| playwright | opencode.json 配置 | 浏览器自动化 |

## 文件结构

```
~/opencode/
├── Dockerfile          # Docker 镜像构建文件
├── docker-compose.yml  # Docker Compose 配置（可选）
├── opencode.sh         # Shell 快捷函数 (ocd 命令)
├── ghostty-128.png     # 通知自定义图标
├── .env                # 环境变量配置（API 密钥等）
│
├── claude_home/        # Claude Code 兼容层（全局共享）
│   ├── skills/         # 自定义 Skills
│   ├── commands/       # 自定义斜杠命令
│   ├── agents/         # 自定义 Agents
│   ├── rules/          # 条件规则
│   ├── todos/          # 任务列表（仅 opencode 实例使用）
│   ├── transcripts/    # 会话日志（仅 opencode 实例使用）
│   ├── settings.json   # Hooks 配置
│   └── .mcp.json       # 额外 MCP 服务器
│
├── instances/          # 其他项目的实例数据
│   └── <project-name>/ # （注意：不会创建 instances/opencode/）
│       └── claude/
│           ├── todos/       # 该项目的任务列表
│           └── transcripts/ # 该项目的会话日志
│
└── README.md           # 本文档

~/.config/opencode/
├── <instance-name>/    # 每个实例独立配置目录
│   ├── opencode.json
│   └── oh-my-opencode.json
└── ...

~/.opencode_data/
├── <instance-name>/    # 每个实例独立数据目录
│   ├── open_url
│   └── notifications
└── ...

~/.local/share/opencode/
└── auth.json           # OAuth 认证信息（所有实例共享）

~/.zshrc
└── source ~/opencode/opencode.sh
```

### Claude Code 兼容层说明

配置支持两个层级：**全局**（所有项目共享）和 **项目级**（仅当前项目）。

#### 全局配置（宿主机 `~/opencode/claude_home/`）

| 目录 | 容器内路径 | 说明 |
|------|-----------|------|
| `claude_home/skills/` | `/root/.claude/skills/` | 自定义 Skills |
| `claude_home/commands/` | `/root/.claude/commands/` | 自定义斜杠命令 |
| `claude_home/agents/` | `/root/.claude/agents/` | 自定义 Agents |
| `claude_home/rules/` | `/root/.claude/rules/` | 条件规则 |
| `claude_home/settings.json` | `/root/.claude/settings.json` | Hooks 配置 |
| `claude_home/.mcp.json` | `/root/.claude/.mcp.json` | 额外 MCP 服务器 |

#### 项目级配置

项目级配置支持两套系统：**OpenCode 原生**（单数目录名）和 **Claude 兼容层**（复数目录名）。

**OpenCode 原生配置**（推荐，无插件依赖）：

| 目录 | 容器内路径 | 说明 |
|------|-----------|------|
| `<project>/.opencode/skill/` | `/workspace/.opencode/skill/` | 项目专属 Skills |
| `<project>/.opencode/command/` | `/workspace/.opencode/command/` | 项目专属斜杠命令 |
| `<project>/.opencode/agent/` | `/workspace/.opencode/agent/` | 项目专属 Agents |

**Claude 兼容层配置**（oh-my-opencode 加载）：

| 目录 | 容器内路径 | 说明 |
|------|-----------|------|
| `<project>/.claude/skills/` | `/workspace/.claude/skills/` | 项目专属 Skills |
| `<project>/.claude/commands/` | `/workspace/.claude/commands/` | 项目专属斜杠命令 |
| `<project>/.claude/agents/` | `/workspace/.claude/agents/` | 项目专属 Agents |
| `<project>/.claude/rules/` | `/workspace/.claude/rules/` | 项目专属规则（仅 Claude 兼容层支持）|

> ⚠️ **注意**：OpenCode 原生使用**单数**目录名，Claude 兼容层使用**复数**目录名，写错不会被加载！

**自动初始化**：在其他项目目录运行 `ocd` 时，会自动创建：
- `.opencode/skill/`、`.opencode/command/`、`.opencode/agent/`（OpenCode 原生）
- `.claude/rules/`（Claude 兼容层，仅 rules 目录）

> 在 `~/opencode/` 目录下运行时，不会创建项目级配置（因为全局配置已在 `claude_home/` 中）。

#### 实例数据（每实例隔离）

**在 `~/opencode/` 目录下运行时（opencode 实例）**：

| 目录 | 容器内路径 | 说明 |
|------|-----------|------|
| `claude_home/todos/` | `/root/.claude/todos/` | 任务列表 |
| `claude_home/transcripts/` | `/root/.claude/transcripts/` | 会话日志 |

> `~/opencode/` 目录下运行时，todos 和 transcripts 直接使用 `claude_home/` 目录，不会创建 `instances/opencode/`。

**在其他项目目录下运行时**：

| 目录 | 容器内路径 | 说明 |
|------|-----------|------|
| `instances/<name>/claude/todos/` | `/root/.claude/todos/` | 任务列表 |
| `instances/<name>/claude/transcripts/` | `/root/.claude/transcripts/` | 会话日志 |

#### 优先级

当全局和项目级存在同名配置时，**项目级优先**。

#### 使用场景

| 场景 | 放置位置 | 示例 |
|------|----------|------|
| 所有项目通用的命令 | `~/opencode/claude_home/commands/` | `/dev`、`/dev-stop` |
| 特定项目的部署命令（OpenCode 原生） | `<project>/.opencode/command/` | `/deploy`、`/migrate` |
| 特定项目的部署命令（Claude 兼容） | `<project>/.claude/commands/` | `/deploy`、`/migrate` |
| 通用代码规范 | `~/opencode/claude_home/rules/` | TypeScript 规范 |
| 项目特有的规范 | `<project>/.claude/rules/` | 项目 API 约定 |

> 详细使用场景和示例请参考 [TOOLS.md](./TOOLS.md#-claude-code-兼容性)。

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
