# OCD 架构参考

OCD (OpenCode Docker) 文件结构与 Mac/Docker 映射关系。

---

## 项目文件结构

```
~/opencode/                        # OCD 项目根目录 (Mac)
├── bin/
│   ├── ocd                        # 主入口脚本
│   └── devocd                     # 开发模式入口
├── lib/
│   ├── core.sh                    # XDG 路径、版本、日志
│   ├── config.sh                  # 配置管理 (模板、端口)
│   ├── docker.sh                  # Docker 构建与运行
│   ├── port.sh                    # 端口分配、原子锁
│   ├── watcher.sh                 # IPC 监控 (剪贴板/通知/URL)
│   └── workspace.sh               # 工作区检测
├── templates/
│   ├── global/                    # 全局配置模板
│   │   ├── opencode.json.tmpl     # OpenCode 主配置
│   │   └── oh-my-opencode.json    # 插件配置
│   └── project/                   # ocd init 项目模板
├── tests/bats/                    # 单元测试
├── docs/                          # 文档
├── scripts/                       # 工具脚本
├── Dockerfile                     # Docker 镜像定义
├── .env                           # API Keys (KEY=VALUE)
├── versions.lock                  # 依赖版本锁定
└── models.conf                    # 模型配置覆盖 (可选)
```

---

## 运行时目录结构 (Mac)

```
~/.config/opencode/                # 全局配置 (用户所有)
├── opencode.json                  # 主配置文件
├── oh-my-opencode.json            # 插件配置
├── skills/                        # 全局 Skills
├── commands/                      # 全局 Commands
└── agents/                        # 全局 Agents

~/.local/share/opencode/           # 数据存储
├── auth.json                      # OAuth 令牌
├── bin/                           # 下载的二进制
└── storage/                       # 会话存储

~/.local/state/opencode/           # 运行状态
└── ipc/<port>/                    # 每端口 IPC 目录
    ├── open_url                   # URL 桥接
    ├── notifications              # 通知桥接
    ├── clipboard                  # 剪贴板桥接
    └── .watcher.pid               # watcher PID

~/.cache/opencode/                 # 缓存 (可删除)

~/.cache/oh-my-opencode/           # 插件缓存
└── bin/                           # ast-grep, ripgrep 等

~/.claude/                         # Claude 兼容层 (全局配置，只读挂载)
├── commands/                      # 用户 commands
├── skills/                        # 用户 skills
├── agents/                        # 用户 agents
└── rules/                         # 用户 rules

~/.local/state/opencode/claude/   # Claude 运行时数据 (可写)
├── todos/                         # 会话 todos
└── transcripts/                   # 会话 transcripts
```

---

## Mac ↔ Docker 挂载映射

### 核心挂载

| Mac | Docker | 说明 |
|-----|--------|------|
| `<workspace>/` | `/workspace/` | 工作区 (双向同步) |
| `~/.config/opencode/` | `/root/.config/opencode/` | 全局配置 |
| `~/.local/share/opencode/` | `/root/.local/share/opencode/` | 数据存储 |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | 运行状态 |
| `~/.cache/opencode/` | `/root/.cache/opencode/` | OpenCode 缓存 |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | 插件缓存 |
| `~/.ssh/` | `/root/.ssh/:ro` | SSH 密钥 (只读) |

### IPC 挂载 (每端口独立)

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.local/state/opencode/ipc/<port>/` | `/root/.opencode/` | IPC 桥接文件 |

### Claude 兼容层 (A+ 安全挂载方案)

> **安全设计**: 全局 `~/.claude/` 以只读挂载，防止容器内 prompt injection 修改 Mac 上的 Claude 配置。
> 运行时数据 (todos/transcripts) 使用独立的可写目录。

**基础层 (只读)**:

| Mac | Docker | 权限 |
|-----|--------|------|
| `~/.claude/` | `/root/.claude/` | **:ro** |

**运行时数据 (可写)**:

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.local/state/opencode/claude/todos/` | `/root/.claude/todos/` | 会话 todos |
| `~/.local/state/opencode/claude/transcripts/` | `/root/.claude/transcripts/` | 会话 transcripts |

**项目覆盖 (条件挂载，只读)** - 仅当目录存在且非空时:

| Mac | Docker | 权限 |
|-----|--------|------|
| `<project>/.claude/commands/` | `/root/.claude/commands/` | **:ro** |
| `<project>/.claude/skills/` | `/root/.claude/skills/` | **:ro** |
| `<project>/.claude/agents/` | `/root/.claude/agents/` | **:ro** |
| `<project>/.claude/rules/` | `/root/.claude/rules/` | **:ro** |
| `<project>/.claude/settings.json` | `/root/.claude/settings.json` | **:ro** |
| `<project>/.claude/.mcp.json` | `/root/.claude/.mcp.json` | **:ro** |

### 镜像内置 (不挂载)

| 路径 | 说明 |
|------|------|
| `/root/.cache/ms-playwright/` | Playwright Chromium (镜像内置) |
| `/opt/google/chrome/chrome` | Chrome symlink |

---

## 覆盖行为

### 情况 1: 项目无 `.claude/agents/`

```
全局生效:
~/.claude/agents/          →    /root/.claude/agents/
├── oracle.md                    ├── oracle.md
└── writer.md                    └── writer.md
```

### 情况 2: 项目有 `.claude/agents/` 且非空

```
项目完全覆盖 (替换，非合并):
<project>/.claude/agents/  →    /root/.claude/agents/
└── my-agent.md                  └── my-agent.md

全局 agents 不可见
```

---

## 开发模式隔离

| 模式 | 配置目录 | 镜像名 |
|------|----------|--------|
| `ocd` | `~/.config/opencode/` | `opencode-bun` |
| `devocd` | `~/.config/opencode-dev/` | `opencode-bun-dev` |

---

## 配置生命周期

| 事件 | 行为 |
|------|------|
| 首次运行 | 从 `templates/` 创建配置 |
| 每次启动 | 仅更新端口号 |
| `ocd --clean` | 备份现有配置 + 重新创建 |
| `models.conf` 存在 | 应用模型覆盖 |

---

## 版本锁定

所有依赖版本在 `versions.lock` 中管理:

```bash
# 核心
OPENCODE_AI_VERSION=1.1.60
OH_MY_OPENCODE_VERSION=3.5.3

# MCP
PLAYWRIGHT_MCP_VERSION=0.0.55

# Docker
BUN_VERSION=1.3.8
```

模板使用 `{{VAR_NAME}}` 语法引用版本变量。
