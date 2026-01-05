# OpenCode Docker 环境配置指南

在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手的完整配置，集成 oh-my-opencode 插件。

## 功能特性

- ✅ 一键启动 OpenCode 容器
- ✅ 链接自动在 Mac 浏览器打开
- ✅ **macOS 桌面通知支持**（容器内任务完成时通知宿主机）
- ✅ GitHub CLI 自动认证（通过 GITHUB_TOKEN）
- ✅ OAuth 认证支持（Claude Max、Gemini Pro）
- ✅ 配置和认证信息持久化
- ✅ Web UI 可访问 (`http://localhost:4096`)
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

如需覆盖默认模型，编辑 `~/.config/opencode/oh-my-opencode.json`：

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
├── .env                # 环境变量配置（API 密钥等）
└── README.md           # 本文档

~/.config/opencode/
├── opencode.json       # OpenCode 配置（自动生成）
└── oh-my-opencode.json # oh-my-opencode 配置（自动生成）

~/.local/share/opencode/
└── auth.json           # OAuth 认证信息（自动保存）

~/.zshrc
└── opencode()          # Shell 快捷函数
```

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

### 4. 首次构建

```bash
opencode -r
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
# 在任意项目目录下启动
cd ~/my-project
opencode

# 强制重建镜像
opencode -r

# 访问 Web UI
open http://localhost:4096
```

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
| Web UI 地址 | `http://localhost:4096` |
| Quotio 地址 | `http://localhost:8317/v1` |
| OrbStack Magic Domain | ❌ 不支持 |

> **为什么用 Host 模式？**
> OAuth 认证回调使用随机端口（如 localhost:51121），Bridge 模式下容器无法接收回调。Host 模式让容器共享 Mac 网络，解决此问题。

## 配置说明

### 环境变量 (.env)

| 变量 | 说明 | 必需 |
|------|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 (用于 Oracle GPT-5.2) | 是 |
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | 否 |
| `QUOTIO_API_KEY` | Quotio Provider API 密钥 | 是 |
| `QUOTIO_BASE_URL` | Quotio Provider API 地址 | 是 |
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

如需重新生成配置：

```bash
rm ~/.config/opencode/opencode.json
rm ~/.config/opencode/oh-my-opencode.json
opencode
```

## 数据持久化

| 目录 | 说明 |
|------|------|
| `~/.config/opencode/` | OpenCode 配置文件 |
| `~/.local/share/opencode/` | OAuth 认证信息 |
| `~/.opencode_data/` | OpenCode 数据、URL 监听文件、通知文件 |

## macOS 桌面通知

由于 Docker 容器无法直接发送 macOS 桌面通知，本项目通过共享文件机制实现：

**原理**：
1. 容器内 `notify` 命令将通知写入共享文件 `~/.opencode_data/notifications`
2. 宿主机监听脚本检测到新内容后，调用 `osascript` 发送 macOS 原生通知

**使用方法**（在容器内）：
```bash
notify "标题" "通知内容"
```

**示例**：
```bash
notify "OpenCode" "后台任务已完成！"
notify "构建成功" "项目编译完成，耗时 2 分钟"
```

> 通知会带有 "Glass" 提示音，可在 macOS 系统设置中调整。

**oh-my-opencode 自动支持**：

容器内已伪造 `osascript` 和 `notify-send` 命令，oh-my-opencode 的通知 hook（`session-notification`、`background-notification`）会自动通过此机制发送 macOS 通知，无需额外配置。

## 常见问题

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
    "opencode-antigravity-auth@1.1.2"
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
2. 访问地址是 `http://localhost:4096`（不是 `opencode.orb.local`）

### Q: GitHub 登录失败？

1. 检查 `.env` 中的 `GITHUB_TOKEN` 是否正确
2. Token 需要 `repo` 权限
3. 申请地址：https://github.com/settings/tokens

## 依赖要求

- macOS
- [OrbStack](https://orbstack.dev/) 或 Docker Desktop
- [jq](https://jqlang.github.io/jq/) (可选，用于智能更新配置)

安装 jq：
```bash
brew install jq
```

## Ghostty 终端配置（可选）

如果使用 Ghostty 终端，添加以下配置以启用链接检测：

```
# ~/.config/ghostty/config
link-url = true
```

链接可通过 `Cmd + 点击` 打开。
