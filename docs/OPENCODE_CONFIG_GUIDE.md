# OCD 开发者指南

本文档面向想要扩展或定制 OCD (OpenCode Docker) 的**开发者**。

---

## 1. 架构概述

### 1.1 设计原则

OCD 是 OpenCode 的**薄 Docker 包装器**，遵循以下原则：

| 原则 | 说明 |
|------|------|
| **用户拥有配置** | 配置文件首次创建后由用户管理，OCD 不再覆盖 |
| **最小化干预** | 每次启动只更新端口，其他配置不动 |
| **模板驱动** | 从 `templates/` 生成配置，支持变量替换 |
| **遵循原生设计** | 完全遵循 OpenCode + oh-my-opencode 的目录结构 |
| **复数目录名** | 使用 `skills/`、`agents/`、`commands/`、`plugins/` |

### 1.2 模块化设计

| 模块 | 文件 | 职责 |
|------|------|------|
| Core | `lib/core.sh` | XDG 路径、版本、日志、环境加载 |
| Port | `lib/port.sh` | 端口分配、原子锁机制 |
| Workspace | `lib/workspace.sh` | 工作区检测、白名单验证 |
| Watcher | `lib/watcher.sh` | IPC 文件监控（剪贴板/通知/URL） |
| Config | `lib/config.sh` | 配置管理（模板、端口更新、重置） |
| Docker | `lib/docker.sh` | Docker 镜像构建与容器运行 |

### 1.3 入口流程

```
bin/ocd
   │
   ├─ 加载模块 (lib/*.sh)
   ├─ 解析参数 / 子命令 (init, config)
   ├─ 工作区检测
   ├─ 端口分配（原子锁）
   ├─ 配置流程：
   │   ├─ 检测是否首次运行
   │   ├─ 首次：从模板创建配置 + 显示欢迎信息
   │   └─ 非首次：只更新端口号
   ├─ 应用 models.conf（如存在）
   ├─ 启动 Watcher（按端口隔离）
   └─ 运行 Docker 容器
```

---

## 2. 目录结构

### 2.1 OCD 安装目录

```
~/opencode/
├── .env                               # API Keys（必需）
├── models.conf                        # 模型配置（可选）
├── versions.lock                      # 版本锁定
├── templates/
│   ├── global/                        # 全局配置模板
│   │   ├── opencode.json.tmpl         # 支持 {{VAR}} 替换
│   │   └── oh-my-opencode.json
│   └── project/                       # 项目配置模板
│       ├── AGENTS.md.example
│       ├── .mcp.json.example
│       ├── .opencode/
│       └── .claude/
├── bin/
│   ├── ocd                            # 主程序
│   └── devocd                         # 开发模式
├── scripts/
└── lib/
    ├── core.sh
    ├── config.sh
    ├── scan.sh
    └── ...
```

### 2.2 运行时目录 (XDG 规范)

| 变量 | 默认路径 | 用途 | 备份策略 |
|------|----------|------|----------|
| `OCD_CONFIG_HOME` | `~/.config/opencode/` | 配置文件 | 可版本控制 |
| `OCD_DATA_HOME` | `~/.local/share/opencode/` | 会话历史、认证 | **必须备份** |
| `OCD_STATE_HOME` | `~/.local/state/opencode/` | IPC 文件 | 可重建 |
| `OCD_CACHE_HOME` | `~/.cache/opencode/` | 缓存 | 可删除 |

### 2.3 完整目录结构

```
~/.config/opencode/                    # 配置 (用户所有)
├── opencode.json                      # 主配置文件
├── oh-my-opencode.json                # 插件配置
├── skills/                            # 全局 Skills
├── commands/                          # 全局 Commands
└── agents/                            # 全局 Agents

~/.local/share/opencode/               # 数据 (OpenCode 原生管理)
├── storage/                           # 会话数据 (按 git SHA)
│   └── session/<git-sha>/
├── auth.json                          # OAuth 认证令牌
└── bin/                               # 二进制缓存

~/.local/state/opencode/               # 状态
└── ipc/<port>/                        # IPC 文件 (按端口)
    ├── open_url
    ├── notifications
    ├── clipboard
    └── .watcher.pid                   # Watcher PID

~/.cache/opencode/                     # OpenCode 缓存
~/.cache/oh-my-opencode/               # 插件缓存 (ast-grep, ripgrep)

<project>/.opencode/                   # 项目级配置 (ocd init 创建)
├── oh-my-opencode.json
├── agents/
├── commands/
└── skills/

<project>/.claude/                     # 项目级对话
├── settings.json
├── todos/
└── transcripts/
```

---

## 3. 配置系统

### 3.1 配置生命周期

| 事件 | OCD 行为 |
|------|----------|
| 首次运行 | 从 `templates/global/` 创建配置，显示欢迎信息 |
| 每次启动 | 只更新 `opencode.json` 中的端口号 |
| `--clean` | 备份到 `backup-<timestamp>/`，重新从模板创建 |
| `models.conf` 存在 | 应用模型覆盖设置 |

### 3.2 核心函数 (lib/config.sh)

| 函数 | 用途 |
|------|------|
| `ocd_ensure_global_config()` | 首次运行时创建配置 |
| `ocd_update_port()` | 更新 opencode.json 中的端口 |
| `ocd_reset_global_config()` | `--clean` 处理：备份 + 重建 |
| `ocd_init_project()` | `ocd init` 处理：创建项目配置 |
| `ocd_create_config_from_template()` | 模板变量替换 |

### 3.3 模板变量替换

`templates/global/opencode.json.tmpl` 支持 `{{VAR}}` 格式：

```json
{
  "plugin": ["oh-my-opencode@{{OH_MY_OPENCODE_VERSION}}"]
}
```

替换源：
1. `versions.lock` 中的版本号
2. 环境变量

### 3.4 models.conf（可选）

```bash
# ~/opencode/models.conf
MAIN_MODEL=anthropic/claude-opus-4-5
PLANNER_MODEL=anthropic/claude-opus-4-5
ORACLE_MODEL=opencode/gpt-5.2-codex
```

修改后需运行 `ocd --clean` 重新生成配置。

---

## 4. 子命令

### 4.1 ocd init

初始化项目级配置：

```bash
cd your-project
ocd init
```

创建内容：
- `.opencode/oh-my-opencode.json.example`
- `.opencode/agents/`, `.opencode/commands/`, `.opencode/skills/`
- `.claude/settings.json.example`
- `.claude/agents/`, `.claude/commands/`, `.claude/skills/`
- `AGENTS.md.example`
- `.mcp.json.example`

### 4.2 ocd config

配置管理：

```bash
ocd config           # 显示配置路径和状态
ocd config edit      # 用编辑器打开配置
```

---

## 5. IPC 通信机制

### 5.1 架构

```
Mac (watcher)                    Docker 容器
     │                                │
     │  ←── open_url ←────────────   xdg-open "URL"
     │  ←── notifications ←───────   notify "标题" "内容"
     │  ←── clipboard ←───────────   xclip
     │                                │
     ▼                                │
  open URL                            │
  osascript notification              │
  pbcopy                              │
```

### 5.2 Watcher 管理

每个端口独立管理 watcher，使用 PID 文件：

```bash
# 启动时：只杀同端口的旧 watcher
if [[ -f "${IPC_DIR}/.watcher.pid" ]]; then
  kill "$(cat "${IPC_DIR}/.watcher.pid")" 2>/dev/null
fi

# 启动新 watcher 后记录 PID
echo "$WATCHER_PID" > "${IPC_DIR}/.watcher.pid"
```

**重要**：不使用全局 `pkill`，避免误杀其他窗口的 watcher。

---

## 6. 扩展点

### 6.1 Agent

**路径**：
- 全局：`~/.config/opencode/agents/*.md`
- 项目：`<project>/.opencode/agents/*.md`

**格式**：
```markdown
---
name: my-agent
description: 描述
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  bash: true
---

系统提示词...
```

### 6.2 Skill

**路径**：`~/.config/opencode/skills/<name>/SKILL.md`

**目录结构**：
```
<skill-name>/
├── SKILL.md              # 必需
├── AGENTS.md             # 可选，AI 开发指南
├── mcp.json              # 可选，MCP 配置
└── scripts/              # 可选
```

### 6.3 Command

**路径**：`~/.config/opencode/commands/*.md`

**格式**：
```markdown
---
name: deploy
description: 部署项目
---

请帮我部署项目。参数: $ARGUMENTS
```

使用：`/deploy production`

---

## 7. 开发模式

### 7.1 设置

```bash
# 创建 dev worktree
cd ~/opencode
git worktree add dev dev

# 使用开发版
devocd                    # 推荐：直接执行 dev/bin/ocd
```

**devocd 隔离**：
- 镜像：`opencode-bun-dev`
- 配置：`~/.config/opencode-dev/`

### 7.2 测试

```bash
# 语法检查
bash -n bin/ocd lib/*.sh

# ShellCheck
shellcheck -S warning bin/ocd lib/*.sh

# 单元测试
bats tests/bats/*.bats              # 全部
bats tests/bats/config.bats         # 单个文件
bats tests/bats/config.bats -f "template"  # 匹配名称

# 手动测试
devocd -r    # 重建开发镜像
devocd       # 启动
```

---

## 8. 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 配置被覆盖 | 不应该发生（OCD 不覆盖） | 检查是否运行了 `--clean` |
| 端口冲突 | 锁文件残留 | `rm ~/.config/opencode/.port.lock` |
| Watcher 不工作 | 进程残留 | 检查 `.watcher.pid`，手动 kill |
| 首次启动没创建配置 | 模板文件缺失 | 检查 `templates/global/` |

---


