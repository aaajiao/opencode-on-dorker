# OCD - OpenCode Docker

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](./CHANGELOG.md)

在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手的完整配置，集成 oh-my-opencode 插件。

## 功能特性

- ✅ 一键启动 OpenCode 容器（`ocd` 命令）
- ✅ **多实例支持**（同时编辑多个项目，自动端口分配 + 锁机制防冲突）
- ✅ 链接自动在 Mac 浏览器打开
- ✅ **macOS 桌面通知支持**
- ✅ **剪贴板桥接**（`/share` 等命令自动复制到 Mac）
- ✅ GitHub CLI 自动认证
- ✅ OAuth 认证支持（Claude Max、Gemini Pro）
- ✅ 配置和认证信息持久化
- ✅ Web UI 可访问
- ✅ **oh-my-opencode 多 Agent 协作**
- ✅ **MCP 服务器 (Playwright, Exa)**

### v1.3.1 优化

- ⚡ **UI 设置持久化**：思考过程显示、代码折叠、diff 换行等设置不再因容器重启丢失
- ⚡ **插件二进制缓存**：ast-grep 和 ripgrep 不再重复下载，大幅提升启动速度
- ⚡ **端口检测优化**：一次性获取 + 锁机制，多实例无冲突
- ⚡ **Watcher 智能降级**：有 fswatch 用事件驱动，无则轮询
- 🔒 **.env 安全加载**：防止代码注入
- 🧹 **自动清理**：trap 机制确保退出时清理进程
- 💡 **依赖提示**：首次运行提示安装可选依赖

## 架构

### 模块化设计

OCD 采用模块化架构，将 873 行单文件拆分为 6 个独立模块：

| 模块 | 职责 | 行数 |
|------|------|------|
| `lib/core.sh` | 版本、日志、环境加载、名称清理 | ~60 |
| `lib/port.sh` | 端口分配、原子锁机制 | ~50 |
| `lib/workspace.sh` | 工作区检测、白名单验证 | ~80 |
| `lib/watcher.sh` | IPC 文件监控（剪贴板/通知/URL） | ~100 |
| `lib/config.sh` | 配置文件生成（消除 heredoc 重复） | ~120 |
| `lib/docker.sh` | Docker 构建与运行 | ~80 |

**优势**：
- 单一职责，易于维护
- 可独立测试每个模块
- 新功能可作为独立模块添加

### CI/CD

项目集成 GitHub Actions 自动化流水线：

```yaml
# .github/workflows/ci.yml
jobs:
  lint:      # ShellCheck 静态分析
  test:      # Bats 单元测试
  syntax:    # Bash 语法检查
  docker:    # Docker 构建验证
```

本地运行测试：

```bash
# 安装 bats-core
brew install bats-core jq

# 运行测试
bats tests/bats/
```

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
# 添加 bin 目录到 PATH（推荐）
echo 'export PATH="$HOME/opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

> **旧版兼容**：`opencode.sh` 仍可用，但推荐使用模块化的 `bin/ocd`

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

> 首次运行 `ocd` 时会提示安装这些依赖。

## 使用方法

### 基本使用

```bash
# 在项目目录下启动（自动检测工作区）
cd ~/projects/webapp/src
ocd
# → 挂载 ~/projects 到 /workspace
# → 启动后自动在 /workspace/webapp/src
# → 可通过 OpenCode 原生 UI 切换其他项目

# 重建镜像 + 清理配置
ocd -r

# 重建镜像 + 保留配置
ocd -r --keep

# 查看帮助
ocd -h
```

### 工作区模式（v1.4.0+）

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

### 兼容旧行为

```bash
# 只挂载当前目录（不检测工作区）
ocd --here

# 指定工作区目录
ocd -w ~/work

# 环境变量方式
export OCD_WORKSPACE=~/projects
ocd
```

**启动输出：**
```
🚀 OCD v2.0.0 │ projects │ http://localhost:4096
   └─ 项目: webapp
```

### 命令参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-v` | 显示版本号 | `ocd -v` |
| `-h` | 显示帮助 | `ocd -h` |
| `-n <name>` | 指定实例名 | `ocd -n myapp` |
| `-p <port>` | 指定端口 | `ocd -p 5000` |
| `-w <path>` | 指定工作区目录 | `ocd -w ~/projects` |
| `--here` | 只挂载当前目录 | `ocd --here` |
| `-r` | 重建镜像 + 清理配置 | `ocd -r` |
| `-r --keep` | 重建镜像 + 保留配置 | `ocd -r --keep` |
| `--clean` | 清理当前实例配置和缓存 | `ocd --clean` |
| `--https` | 通过 Tailscale Serve 启用 HTTPS | `ocd --https` |
| `--awake` | 防止 Mac 进入休眠 | `ocd --awake` |
| `--quotio` | 启用 Quotio 代理 | `ocd --quotio` |

### 环境变量

| 变量 | 说明 |
|------|------|
| `OCD_WORKSPACE` | 默认工作区根目录 |

### 查看运行中的实例

```bash
docker ps | grep opencode
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

| MCP | 来源 | 功能 |
|-----|------|------|
| context7 | 内置 | 文档查询 |
| exa | 内置 | 网页搜索 |
| grep_app | 内置 | 代码搜索 |
| playwright | 配置 | 浏览器自动化 |

## 文件结构

```
~/opencode/                           # 配置仓库
├── bin/
│   └── ocd                           # 入口脚本（添加到 PATH）
│
├── lib/                              # 模块化核心库
│   ├── core.sh                       # 核心工具（日志、env加载、sanitize）
│   ├── port.sh                       # 端口管理（原子锁机制）
│   ├── workspace.sh                  # 工作区检测（git仓库遍历）
│   ├── watcher.sh                    # IPC监控（剪贴板、通知、URL）
│   ├── config.sh                     # 配置生成（opencode.json等）
│   └── docker.sh                     # Docker构建与运行
│
├── tests/                            # 测试套件
│   └── bats/                         # Bats 单元测试
│       ├── core.bats
│       ├── port.bats
│       ├── workspace.bats
│       └── config.bats
│
├── opencode.sh                       # 旧版入口（兼容）
├── Dockerfile                        # Docker 镜像
├── .env                              # 环境变量
├── VERSION                           # 版本号
├── models.conf.example               # 模型配置模板
├── versions.lock                     # 版本锁定（可选）
│
├── global/
│   ├── opencode/                     # OpenCode 全局配置
│   │   ├── skill/
│   │   ├── command/
│   │   └── agent/
│   │
│   └── claude/                       # Claude 兼容层配置
│       ├── skills/
│       ├── commands/
│       ├── agents/
│       └── rules/
│
└── .opencode/                        # 项目级配置
    └── ...

~/.config/opencode/<instance>/        # 实例配置
├── opencode.json
└── oh-my-opencode.json

~/.opencode_data/<instance>/          # 实例运行时数据
├── open_url
├── notifications
└── clipboard

~/.local/share/opencode/              # 共享数据
└── auth.json                         # OAuth 认证

~/.local/state/opencode/              # KV store (UI 设置持久化)

~/.cache/oh-my-opencode/              # oh-my-opencode 二进制缓存
```

### 配置目录命名规则

| 系统 | 目录命名 |
|------|---------|
| OpenCode 原生 | **单数**：`skill/`, `command/`, `agent/` |
| Claude 兼容层 | **复数**：`skills/`, `commands/`, `agents/` |

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

## 模型配置

通过 `models.conf` 配置文件自定义默认模型，无需修改代码：

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
| `anthropic/` | Anthropic Claude | `anthropic/claude-opus-4-5`, `anthropic/claude-sonnet-4-5` |
| `openai/` | OpenAI GPT | `openai/gpt-5.2`, `openai/gpt-4.1` |
| `quotio/` | Quotio 代理 | `quotio/gemini-3-pro-preview`, `quotio/gemini-claude-opus-4-5-thinking` |

> **注意**：修改后需删除实例配置重新生成：`ocd --clean && ocd`

## macOS 桌面通知

容器内使用 `notify` 命令发送通知：

```bash
notify "标题" "内容"
```

oh-my-opencode 的通知 hook 会自动使用此机制。

**获取自定义图标**：将 `ghostty-128.png` 放在 `~/opencode/` 目录。

## 剪贴板桥接

容器内的剪贴板操作（如 `/share` 命令）会自动同步到 Mac 剪贴板。

**工作原理**：
1. 容器内 `xclip` 命令写入 `~/.opencode_data/<instance>/clipboard`
2. Mac watcher 检测到变化后执行 `pbcopy`

**延迟**：约 1 秒（轮询模式）或即时（fswatch 模式）

## 网络模式

使用 `--network host` 模式（OAuth 回调需要）：

| 特性 | 说明 |
|------|------|
| OAuth 回调 | ✅ 支持 |
| Web UI | `http://localhost:<port>` |
| Quotio | `http://localhost:8317/v1` |

## 常见问题

### Q: 环境变量没有加载？

确保 `.env` 格式正确：不能有 `export`、引号、注释。

### Q: 多实例端口冲突？

v1.3.1 已添加锁机制，正常情况不会冲突。如遇问题：

```bash
rm ~/.config/opencode/.port.lock
```

### Q: Watcher 进程残留？

v1.3.1 已添加 trap 清理机制。如仍有残留：

```bash
pkill -f "fswatch.*opencode"
pkill -f "sleep.*opencode"
```

### Q: 想重新看依赖提示？

```bash
rm ~/.config/opencode/.deps-hint-shown
ocd
```

### Q: OAuth 认证失败？

1. 运行 `opencode auth login`
2. 选择对应的认证方式
3. 浏览器会自动打开

### Q: 更新 opencode.sh 后生效？

```bash
exit          # 退出容器
exec zsh      # 重载 shell
ocd           # 重新启动
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
