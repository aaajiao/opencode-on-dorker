# OCD - OpenCode Docker

[![Version](https://img.shields.io/badge/version-5.0.0-blue.svg)](./CHANGELOG.md)

在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手的完整配置，集成 oh-my-opencode 插件。

## v5 新特性

- ✅ **配置文件用户所有**：首次创建后由用户管理，OCD 不再覆盖
- ✅ **每次启动只更新端口**：配置保持稳定，用户修改不会丢失
- ✅ **`ocd init` 项目初始化**：一键创建项目级配置模板
- ✅ **`ocd config` 配置管理**：查看和编辑配置文件
- ✅ **模板系统**：从 `templates/` 生成配置，支持变量替换
- ✅ **v4 自动迁移**：首次运行时自动检测并迁移旧配置

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

首次运行时，OCD 会：
1. 从 `templates/global/` 创建配置文件
2. 显示欢迎信息和配置路径
3. 配置文件之后由你管理，OCD 只更新端口

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

### v5 新命令

```bash
# 初始化项目配置（创建 .opencode/, .claude/ 等）
ocd init

# 查看配置状态
ocd config

# 编辑全局配置
ocd config edit

# 重置配置（备份现有 + 重新创建）
ocd --clean
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
🚀 OCD v5.0.0 │ http://localhost:4096
   └─ 项目: webapp
```

### 命令参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-v` | 显示版本号 | `ocd -v` |
| `-h` | 显示帮助 | `ocd -h` |
| `-p <port>` | 指定端口 | `ocd -p 5000` |
| `--here` | 只挂载当前目录 | `ocd --here` |
| `--merge-up` | 合并 transcripts 到父项目 | `ocd --merge-up` |
| `-r` | 重建镜像 + 清理缓存 | `ocd -r` |
| `--clean` | 重置配置（备份 + 重建） | `ocd --clean` |
| `--https` | 通过 Tailscale Serve 启用 HTTPS | `ocd --https` |
| `--awake` | 防止 Mac 进入休眠 | `ocd --awake` |
| `--quotio` | 启用 Quotio 代理 | `ocd --quotio` |

### v5 子命令

| 子命令 | 说明 |
|--------|------|
| `ocd init` | 初始化项目配置（.opencode/, .claude/） |
| `ocd config` | 显示配置路径和状态 |
| `ocd config edit` | 用编辑器打开配置文件 |

### 开发模式

用于测试 OCD 本身的修改（开发者使用）：

```bash
# 1. 设置开发分支（使用 git worktree）
cd ~/opencode
git worktree add dev dev

# 2. 在 dev/ 中修改代码
cd ~/opencode/dev
nano lib/docker.sh

# 3. 使用开发版启动（推荐 devocd）
devocd                   # 直接执行 dev/bin/ocd（推荐）

# 4. 重建开发镜像（修改 Dockerfile 后）
devocd -r
```

**开发模式特性**：
- 使用独立镜像 `opencode-bun-dev`（不污染生产镜像）
- 使用独立配置目录 `~/.config/opencode-dev/`（不影响生产配置）
- 启动信息显示 `[DEV]` 标识

**清理开发环境**：
```bash
docker rmi opencode-bun-dev
git worktree remove dev
```

## v5 配置架构

### 设计原则

| 原则 | 说明 |
|------|------|
| **用户拥有配置** | 首次创建后由用户管理，OCD 不覆盖 |
| **最小化干预** | 每次启动只更新端口，其他不动 |
| **模板驱动** | 从 `templates/` 生成，支持变量替换 |

### 配置生命周期

| 事件 | OCD 行为 |
|------|----------|
| 首次运行 | 从模板创建配置，显示欢迎信息 |
| 每次启动 | 只更新端口号 |
| `--clean` | 备份现有配置，重新从模板创建 |
| `models.conf` 存在 | 应用模型覆盖设置 |

### 目录结构

```
~/opencode/                            # OCD 安装目录
├── .env                               # API Keys（必需）
├── models.conf                        # 模型配置（可选）
├── versions.lock                      # 版本锁定
├── templates/
│   ├── global/                        # 全局配置模板
│   │   ├── opencode.json.tmpl         # 主配置（支持 {{VAR}} 替换）
│   │   └── oh-my-opencode.json        # 插件配置
│   └── project/                       # 项目配置模板（ocd init 使用）
│       ├── AGENTS.md.example
│       ├── .mcp.json.example
│       ├── .opencode/
│       └── .claude/
├── bin/
│   ├── ocd                            # 主程序
│   └── devocd                         # 开发模式
└── lib/
    ├── core.sh                        # 核心函数
    ├── config.sh                      # v5 配置管理
    ├── migrate.sh                     # v4→v5 迁移
    ├── docker.sh                      # Docker 操作
    ├── port.sh                        # 端口分配
    ├── workspace.sh                   # 工作区检测
    └── watcher.sh                     # IPC 监控

~/.config/opencode/                    # 全局配置（用户所有）
├── opencode.json                      # 主配置文件
├── oh-my-opencode.json                # 插件配置
├── skill/                             # 全局技能
├── command/                           # 全局命令
└── agent/                             # 全局 Agent

~/.local/share/opencode/               # 数据目录（需备份）
├── storage/                           # 会话数据
└── auth.json                          # OAuth 令牌

~/.local/state/opencode/               # 状态目录
└── ipc/<port>/                        # IPC 文件

~/.cache/opencode/                     # 缓存（可删除）

<project>/.opencode/                   # 项目级配置（ocd init 创建）
├── oh-my-opencode.json
├── agent/
├── command/
└── skill/

<project>/.claude/                     # 项目级对话
├── settings.json
└── transcripts/
```

### 目录清理对照表

| 目录 | 内容 | `-r` | `--clean` | 手动 |
|------|------|:----:|:---------:|:----:|
| `~/.cache/opencode/` | 缓存 | ✅ | - | ✅ |
| `~/.config/opencode/` | 全局配置 | - | ✅ (备份) | ✅ |
| `~/.local/state/opencode/ipc/` | IPC 状态 | - | ✅ | ✅ |
| `~/.local/share/opencode/storage/` | 对话历史 | - | - | ✅ |
| `~/.local/share/opencode/auth.json` | 认证令牌 | - | - | ✅ |

**图例**：✅ = 会删除/备份，- = 不删除

## 模型配置

通过 `models.conf` 配置文件自定义默认模型：

```bash
cp models.conf.example ~/opencode/models.conf
nano ~/opencode/models.conf
```

```bash
# ~/opencode/models.conf

# 主模型 (opencode.json)
MAIN_MODEL=anthropic/claude-opus-4-5

# Agent 模型 (oh-my-opencode.json)
PLANNER_MODEL=anthropic/claude-opus-4-5
ORACLE_MODEL=openai/gpt-5.2
DOCUMENT_WRITER_MODEL=quotio/gemini-3-pro-preview
```

> **注意**：修改 `models.conf` 后需运行 `ocd --clean` 重新生成配置。

## 从 v4.x 升级

### 自动迁移

OCD v5.0 首次运行时会自动检测 v4.x 配置并迁移：

1. 检测 `~/.config/opencode/opencode.json` 是否存在
2. 如果是旧格式，备份到 `~/.config/opencode/backup-v4/`
3. 从模板创建新配置
4. 显示迁移完成信息

### 手动迁移

如果自动迁移失败，可以手动操作：

```bash
# 备份旧配置
mv ~/.config/opencode ~/.config/opencode-v4-backup

# 重新启动（会创建新配置）
ocd
```

### v4 → v5 变更

| 方面 | v4 | v5 |
|------|-----|-----|
| 配置生成 | 每次启动重新生成 | 首次创建，之后只更新端口 |
| 用户修改 | 下次启动会丢失 | 永久保留 |
| 模板位置 | 硬编码在脚本中 | `templates/` 目录 |
| 项目初始化 | 无 | `ocd init` 命令 |
| 配置管理 | 无 | `ocd config` 命令 |

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
```

### 变量说明

| 变量 | 说明 | 必需 |
|------|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 | 是 |
| `GITHUB_TOKEN` | GitHub Token | 是 |
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | 否 |
| `EXA_API_KEY` | Exa AI 密钥 | 否 |
| `QUOTIO_API_KEY` | Quotio 密钥 | 否 |

## macOS 集成

### 桌面通知

容器内使用 `notify` 命令发送通知：

```bash
notify "标题" "内容"
```

### 剪贴板桥接

容器内的剪贴板操作（如 `/share` 命令）会自动同步到 Mac 剪贴板。

## 常见问题

### Q: 配置文件被覆盖了？

v5 不会覆盖配置。如果需要重置，使用 `ocd --clean`（会先备份）。

### Q: 如何查看当前配置？

```bash
ocd config
```

### Q: 端口冲突？

```bash
rm ~/.config/opencode/.port.lock
```

### Q: OAuth 认证失败？

```bash
opencode auth login
```

### Q: 如何初始化项目配置？

```bash
cd your-project
ocd init
```

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
