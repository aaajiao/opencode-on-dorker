# OCD - OpenCode Docker

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](./CHANGELOG.md)

在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手的完整配置，集成 oh-my-opencode 插件。

## 功能特性

- ✅ 一键启动 OpenCode 容器（`ocd` 命令）
- ✅ **多窗口支持**（同时编辑多个项目，自动端口分配 + 锁机制防冲突）
- ✅ 链接自动在 Mac 浏览器打开
- ✅ **macOS 桌面通知支持**
- ✅ **剪贴板桥接**（`/share` 等命令自动复制到 Mac）
- ✅ GitHub CLI 自动认证
- ✅ OAuth 认证支持（Claude Max、Gemini Pro）
- ✅ 配置和认证信息持久化
- ✅ Web UI 可访问
- ✅ **oh-my-opencode 多 Agent 协作**
- ✅ **MCP 服务器 (Playwright, Exa)**

## 快速开始

### 1. 克隆项目

```bash
git clone <repo-url> ~/opencode
cd ~/opencode
```

### 2. 配置环境变量

```bash
cp env.example .env
nano .env  # 填写 API keys
```

```bash
# ~/opencode/.env（纯 KEY=VALUE 格式，无注释无引号）
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

### 3. 添加 Shell 函数

```bash
# 添加 bin 目录到 PATH
echo 'export PATH="$HOME/opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 4. 首次构建

```bash
ocd -r
```

### 5. 安装可选依赖（推荐）

```bash
brew install jq fswatch terminal-notifier
```

| 依赖 | 作用 | 没有会怎样 |
|------|------|-----------|
| `jq` | 智能配置更新 | fallback 到 sed |
| `fswatch` | 高效文件监控 | fallback 到轮询 |
| `terminal-notifier` | 自定义通知图标 | fallback 到 osascript |

## 使用方法

### 基本使用

```bash
# 在项目目录下启动（自动检测工作区）
cd ~/projects/webapp/src
ocd
# → 挂载 ~/projects 到 /workspace
# → 启动后自动在 /workspace/webapp/src
# → 可通过 OpenCode 原生 UI 切换其他项目

# 重建镜像（同时清理缓存）
ocd -r

# 查看帮助
ocd -h
```

### 工作区模式

OCD 会自动检测 Git 仓库，将其父目录作为工作区：

```bash
~/projects/                    # 工作区根目录（挂载到 /workspace）
├── webapp/                    # 项目 A（有 .git）
├── api-server/                # 项目 B（有 .git）
└── mobile-app/                # 项目 C（有 .git）
```

```bash
# 从任意子目录启动
cd ~/projects/webapp/src/components
ocd
# → 检测到 ~/projects/webapp/.git
# → 挂载 ~/projects（父目录）到 /workspace
# → 启动后在 /workspace/webapp/src/components
# → Web UI 可切换到 api-server、mobile-app
```

**启动输出：**

```text
🚀 OCD v4.0.0 │ http://localhost:4096
   └─ 项目: webapp
```

### 命令参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-v` | 显示版本号 | `ocd -v` |
| `-h` | 显示帮助 | `ocd -h` |
| `-p <port>` | 指定端口 | `ocd -p 5000` |
| `--here` | 只挂载当前目录 | `ocd --here` |
| `--merge-up` | 合并 transcripts 到父项目（撤销 --here） | `ocd --merge-up` |
| `-r` | 重建镜像 + 清理缓存 | `ocd -r` |
| `--clean` | 清理共享配置（保留对话） | `ocd --clean` |
| `--https` | 通过 Tailscale Serve 启用 HTTPS | `ocd --https` |
| `--awake` | 防止 Mac 进入休眠 | `ocd --awake` |
| `--quotio` | 启用 Quotio 代理 | `ocd --quotio` |
| `--dev` | 使用开发版（从 dev/ 加载） | `ocd --dev` |
| `--dev-root` | 指定开发目录 | `ocd --dev-root ~/fork` |

### 开发模式

用于测试 OCD 本身的修改（开发者使用）：

```bash
# 1. 设置开发分支（使用 git worktree）
cd ~/opencode
git worktree add dev dev

# 2. 在 dev/ 中修改代码
cd ~/opencode/dev
nano lib/docker.sh

# 3. 使用开发版启动
ocd --dev

# 4. 重建开发镜像（修改 Dockerfile 后）
ocd -r --dev

# 5. 使用自定义路径
ocd --dev-root ~/code/ocd-fork
ocd --dev-root=~/code/ocd-fork  # 等号式也可以
```

**开发模式特性**：
- 使用独立镜像 `opencode-bun-dev`（不污染生产镜像）
- 优先加载 `dev/.env`（如存在），否则使用主目录 `.env`
- 启动信息显示 `[DEV]` 标识和开发目录路径
- 对话数据独立存储（`dev/.claude/transcripts/`，不与主目录混用）

**清理开发环境**：
```bash
# 删除开发镜像
docker rmi opencode-bun-dev

# 删除 worktree
git worktree remove dev
```

## 目录结构

OCD v4.0 遵循 [XDG Base Directory 规范](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)：

```
~/.config/opencode/                    # 配置 (单副本，共享)
├── opencode.json                     # 主配置文件
├── oh-my-opencode.json               # 插件配置文件
├── skill/                            # 全局技能
├── command/                          # 全局命令
└── agent/                            # 全局 Agent

~/.local/share/opencode/               # 数据 (必须备份)
├── storage/                          # 会话和消息 (按 git SHA 存储)
│   └── session/<git-sha>/
├── auth.json                          # OAuth 认证令牌 (共享)
└── bin/                               # 二进制缓存

~/.local/state/opencode/               # 状态 (可重建)
└── ipc/<port>/                       # 跨窗口隔离的 IPC 文件
    ├── open_url
    ├── notifications
    └── clipboard

~/.cache/opencode/                     # OpenCode 缓存 (可删除)
~/.cache/oh-my-opencode/               # 插件缓存 (ast-grep, ripgrep)

<project>/.claude/                     # 项目级对话 (跟随项目)
├── todos/
└── transcripts/
```

### 目录清理对照表

| 目录 | 内容 | `-r` | `--clean` | 手动 |
|------|------|:----:|:---------:|:----:|
| `~/.cache/opencode/` | 缓存 (playwright, ast-grep) | ✅ | - | ✅ |
| `~/.config/opencode/` | 共享配置 | - | ✅ | ✅ |
| `~/.local/state/opencode/ipc/` | IPC 状态 | - | ✅ | ✅ |
| `~/.local/share/opencode/storage/` | 对话历史 | - | - | ✅ |
| `~/.local/share/opencode/auth.json` | 认证令牌 | - | - | ✅ |
| `<project>/.claude/` | 项目对话 | - | - | ✅ |

**图例**：✅ = 会删除，- = 不删除

**命令说明**：

- `ocd -r` - 重建镜像，清理缓存
- `ocd --clean` - 清理共享配置，重新生成

### 神圣不可删除

以下目录**不会被任何 ocd 命令自动删除**，只能手动清理：

- `~/.local/share/opencode/auth.json` - OAuth 认证令牌
- `~/.config/opencode/{skill,command,agent}/` - 全局自定义组件

## 从 v3.x 升级

### 自动迁移

OCD v4.0 提供了迁移脚本来合并 v3.x 的实例数据：

```bash
# 运行迁移脚本
~/opencode/scripts/migrate-v4.sh
```

该脚本会将所有 `instances/` 下的配置合并到共享配置，并移动会话数据。

### 路径变更

| 路径描述 | v3.x 路径 | v4.0 路径 |
|-----------|-----------|-----------|
| 实例配置 | `~/.config/opencode/instances/<inst>/` | `~/.config/opencode/` (合并) |
| 会话数据 | `~/.local/share/opencode/instances/<inst>/` | `~/.local/share/opencode/storage/` |
| IPC 状态 | `~/.local/state/opencode/instances/<inst>/` | `~/.local/state/opencode/ipc/<port>/` |
| 全局配置 | `~/.config/opencode/global/` | `~/.config/opencode/` |

### 清理 v3.x 残留

确认 v4.0 运行正常后，可以清理旧的实例目录：

```bash
rm -rf ~/.config/opencode/instances
rm -rf ~/.local/share/opencode/instances
rm -rf ~/.local/state/opencode/instances
```

## 架构

### 模块化设计

OCD 采用模块化架构：

| 模块 | 职责 |
|------|------|
| `lib/core.sh` | XDG 路径、版本、日志、环境加载 |
| `lib/port.sh` | 端口分配、原子锁机制 |
| `lib/workspace.sh` | 工作区检测、项目识别、白名单验证 |
| `lib/watcher.sh` | IPC 文件监控（剪贴板/通知/URL） |
| `lib/config.sh` | 配置文件生成 |
| `lib/docker.sh` | Docker 构建与运行 |

### CI/CD

项目集成 GitHub Actions 自动化流水线：

```yaml
jobs:
  lint:      # ShellCheck 静态分析
  test:      # Bats 单元测试
  syntax:    # Bash 语法检查
  docker:    # Docker 构建验证
```

本地运行测试：

```bash
brew install bats-core jq
bats tests/bats/
```

## oh-my-opencode Agent

### 内置 Agent

| Agent | 默认模型 | 用途 |
|-------|---------|------|
| **Sisyphus** | `claude-opus-4-5` | 主编排器 |
| **oracle** | `gpt-5.2` | 架构设计、调试 |
| **librarian** | `claude-sonnet-4-5` | 文档研究 |
| **explore** | `grok-code` | 快速搜索（免费） |
| **github** | `claude-sonnet-4-5` | Git 工作流 |

### 常用命令

```
ultrawork / ulw    # 最大性能模式
@oracle            # 调用调试专家
@librarian         # 查找文档
@github commit     # 智能提交
ultrathink         # 深度思考
```

### @github 工作流

```
@github branch 功能名   # 创建分支
@github commit         # 智能提交
@github sync           # 同步 main
@github pr             # 创建 PR
@github done           # 清理分支
```

## MCP 服务器

### 内置 MCP

| MCP | 来源 | 功能 |
|-----|------|------|
| context7 | oh-my-opencode | 文档查询 |
| exa | 配置 | 网页搜索 |
| grep_app | oh-my-opencode | 代码搜索 |
| playwright | 配置 | 浏览器自动化 |

### MCP 配置

通过 `mcp.json` 配置文件管理 MCP 服务器：

```bash
cp mcp.json.example ~/opencode/mcp.json
nano ~/opencode/mcp.json
```

**配置格式**：

```json
{
  "playwright": {
    "type": "local",
    "command": ["npx", "@playwright/mcp@${PLAYWRIGHT_MCP_VERSION:-0.0.54}", "--headless"],
    "enabled": true
  },
  "exa": {
    "type": "local",
    "command": ["npx", "-y", "exa-mcp-server@${EXA_MCP_VERSION:-3.1.3}"],
    "timeout": 60000,
    "enabled": false,
    "environment": {
      "EXA_API_KEY": "${EXA_API_KEY}"
    }
  }
}
```

**变量替换**：
- `${VAR}` - 从 `.env` 或 `versions.lock` 读取
- `${VAR:-default}` - 带默认值

**添加新 MCP**：

```json
{
  "filesystem": {
    "type": "local",
    "command": ["npx", "-y", "@anthropics/mcp-filesystem@latest", "/workspace"],
    "enabled": true
  }
}
```

> **注意**：修改后需重新生成配置：`ocd --clean && ocd`

## 模型配置

通过 `models.conf` 配置文件自定义默认模型：

```bash
cp models.conf.example ~/opencode/models.conf
nano ~/opencode/models.conf
```

### 配置格式

```bash
# ~/opencode/models.conf

# 主模型 (opencode.json)
MAIN_MODEL=anthropic/claude-opus-4-5

# Agent 模型 (oh-my-opencode.json)
PLANNER_MODEL=anthropic/claude-opus-4-5
ORACLE_MODEL=openai/gpt-5.2
DOCUMENT_WRITER_MODEL=quotio/gemini-3-pro-preview
FRONTEND_MODEL=quotio/gemini-3-pro-preview
MULTIMODAL_MODEL=quotio/gemini-3-flash-preview
```

### 可用模型

| 前缀 | 来源 | 示例 |
|------|------|------|
| `anthropic/` | Anthropic Claude | `anthropic/claude-opus-4-5` |
| `openai/` | OpenAI GPT | `openai/gpt-5.2` |
| `quotio/` | Quotio 代理 | `quotio/gemini-3-pro-preview` |

> **注意**：修改后需重新生成配置：`ocd --clean && ocd`（对话历史会保留）

## 环境变量

### .env 文件格式

```bash
# 正确格式：纯 KEY=VALUE
OPENAI_API_KEY=sk-proj-xxxx
GITHUB_TOKEN=ghp_xxxx

# 错误格式（会被忽略）
export KEY=value      # 不要 export
KEY="value"           # 不要引号
KEY=value # comment   # 不要注释
KEY=$(cmd)            # 不要命令替换
```

### 变量说明

| 变量 | 说明 | 必需 |
|------|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 | 是 |
| `GITHUB_TOKEN` | GitHub Token | 是 |
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | 否 |
| `EXA_API_KEY` | Exa AI 密钥 | 否 |
| `QUOTIO_API_KEY` | Quotio 密钥 | 否 |
| `QUOTIO_BASE_URL` | Quotio 地址 | 否 |
| `OCD_WORKSPACE` | 默认工作区根目录 | 否 |

## macOS 集成

### 桌面通知

容器内使用 `notify` 命令发送通知：

```bash
notify "标题" "内容"
```

oh-my-opencode 的通知 hook 会自动使用此机制。

### 剪贴板桥接

容器内的剪贴板操作（如 `/share` 命令）会自动同步到 Mac 剪贴板。

**工作原理**：
1. 容器内 `xclip` 命令写入 IPC 文件
2. Mac watcher 检测到变化后执行 `pbcopy`

**延迟**：约 1 秒（轮询模式）或即时（fswatch 模式）

## 常见问题

### Q: 环境变量没有加载？

确保 `.env` 格式正确：不能有 `export`、引号、注释。

### Q: 多窗口端口冲突？

OCD 使用锁机制防止冲突。如遇问题：

```bash
rm ~/.config/opencode/.port.lock
```

### Q: OAuth 认证失败？

1. 运行 `opencode auth login`
2. 选择对应的认证方式
3. 浏览器会自动打开

### Q: 想重新看依赖提示？

```bash
rm ~/.config/opencode/.deps-hint-shown
ocd
```

### Q: TUI 和 WebUI 对话不同步？

确保从正确的目录启动。OCD 根据启动目录确定项目，项目级对话存储在 `<project>/.claude/transcripts/`。

## 依赖要求

- macOS
- [OrbStack](https://orbstack.dev/)（推荐）或 Docker Desktop
- [jq](https://jqlang.github.io/jq/)（可选）
- [fswatch](https://emcrisostomo.github.io/fswatch/)（可选）
- [terminal-notifier](https://github.com/julienXX/terminal-notifier)（可选）

```bash
brew install jq fswatch terminal-notifier
```

## Ghostty 终端配置

```
# ~/.config/ghostty/config
link-url = true
```

链接可通过 `Cmd + 点击` 打开。
