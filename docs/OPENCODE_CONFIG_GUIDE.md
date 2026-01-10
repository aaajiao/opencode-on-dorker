# OCD 开发者指南 (v4.0)

本文档面向想要扩展或定制 OCD (OpenCode Docker) 的**开发者**。

---

## 1. 架构概述

### 1.1 设计原则

OCD v4.0 是 OpenCode 的**薄 Docker 包装器**，遵循 OpenCode 原生行为：

- **OpenCode 的项目识别**：使用 git root commit SHA 作为项目 ID
- **OCD 的职责**：容器化、macOS 集成（剪贴板/通知/URL）、端口分配
- **不做**：项目/会话隔离（让 OpenCode 处理）

### 1.2 模块化设计

| 模块 | 文件 | 职责 |
|------|------|------|
| Core | `lib/core.sh` | XDG 路径、版本、日志、环境加载 |
| Port | `lib/port.sh` | 端口分配、原子锁机制 |
| Workspace | `lib/workspace.sh` | 工作区检测、白名单验证 |
| Watcher | `lib/watcher.sh` | IPC 文件监控（剪贴板/通知/URL） |
| Config | `lib/config.sh` | 配置文件生成 |
| Docker | `lib/docker.sh` | Docker 镜像构建与容器运行 |

### 1.3 入口流程

```
bin/ocd
   │
   ├─ 加载模块 (lib/*.sh)
   ├─ 自动迁移 v3.x → v4.0
   ├─ 解析参数
   ├─ 工作区检测
   ├─ 端口分配（原子锁）
   ├─ 初始化配置目录
   ├─ 生成配置文件
   ├─ 启动 Watcher（按端口隔离）
   └─ 运行 Docker 容器
```

---

## 2. 目录结构 (XDG 规范)

### 2.1 路径定义

| 变量 | 默认路径 | 用途 | 备份策略 |
|------|----------|------|----------|
| `OCD_CONFIG_HOME` | `~/.config/opencode/` | 配置文件 | 可版本控制 |
| `OCD_DATA_HOME` | `~/.local/share/opencode/` | 会话历史、认证 | **必须备份** |
| `OCD_STATE_HOME` | `~/.local/state/opencode/` | IPC 文件 | 可重建 |
| `OCD_CACHE_HOME` | `~/.cache/opencode/` | 缓存 | 可删除 |

### 2.2 完整目录结构

```
~/.config/opencode/                    # 配置 (共享)
├── opencode.json                      # 主配置文件
├── oh-my-opencode.json                # 插件配置
├── skill/                             # 全局 Skills
├── command/                           # 全局 Commands
└── agent/                             # 全局 Agents

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

<project>/.claude/                     # 项目级配置
├── todos/
├── transcripts/
├── skills/                            # 项目 Skills (可选)
├── commands/                          # 项目 Commands (可选)
├── agents/                            # 项目 Agents (可选)
└── rules/                             # 项目 Rules (可选)
```

---

## 3. 配置系统

### 3.1 配置文件

| 文件 | 路径 | 用途 |
|------|------|------|
| `opencode.json` | `~/.config/opencode/` | 主配置（模型、端口、MCP） |
| `oh-my-opencode.json` | `~/.config/opencode/` | 插件配置（Agent 模型映射） |
| `mcp.json` | `~/opencode/` | MCP 服务器源配置 |
| `models.conf` | `~/opencode/` | 模型覆盖配置 |

### 3.2 opencode.json 结构

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": ["oh-my-opencode@2.14.0"],
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

### 3.3 models.conf（可选）

自定义默认模型：

```bash
# ~/opencode/models.conf
MAIN_MODEL=anthropic/claude-opus-4-5
PLANNER_MODEL=anthropic/claude-opus-4-5
ORACLE_MODEL=openai/gpt-5.2
```

修改后需重新生成配置：`ocd --clean && ocd`

---

## 4. IPC 通信机制

### 4.1 架构

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

### 4.2 Watcher 管理 (v4.0)

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

### 4.3 容器内写入

```bash
# 打开 URL
echo "https://example.com" > /root/.opencode/open_url

# 发送通知
echo "标题|内容" >> /root/.opencode/notifications

# 写入剪贴板
echo "复制内容" > /root/.opencode/clipboard
```

---

## 5. 扩展点

### 5.1 Agent

**路径**：
- 全局：`~/.config/opencode/agent/*.md`
- 项目：`<project>/.claude/agents/*.md`

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

### 5.2 Skill

**路径**：`~/.config/opencode/skill/<name>/SKILL.md`

**目录结构**：
```
<skill-name>/
├── SKILL.md              # 必需
├── AGENTS.md             # 可选，AI 开发指南
├── mcp.json              # 可选，MCP 配置
└── scripts/              # 可选
```

### 5.3 Command

**路径**：`~/.config/opencode/command/*.md`

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

## 6. 开发模式

### 6.1 设置

```bash
# 创建 dev worktree
cd ~/opencode
git worktree add dev dev

# 使用开发版
devocd                    # 推荐：直接执行 dev/bin/ocd
ocd --dev                 # 备选：通过 main 的 ocd 切换
```

### 6.2 测试

```bash
# 语法检查
bash -n bin/ocd lib/*.sh

# 单元测试
bats tests/bats/*.bats              # 全部
bats tests/bats/core.bats           # 单个文件
bats tests/bats/core.bats -f "xxx"  # 匹配名称

# 手动测试
devocd -r    # 重建开发镜像
devocd       # 启动
```

---

## 7. 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 配置不生效 | 目录名错误 | 检查 `skill/` vs `skills/` |
| 端口冲突 | 锁文件残留 | `rm ~/.config/opencode/.port.lock` |
| Watcher 不工作 | 进程残留 | 检查 `.watcher.pid`，手动 kill |
| 浏览器不打开 | IPC 文件未写入 | 检查容器内 `/root/.opencode/open_url` |

---

## 8. v3.x 迁移

```bash
# 运行迁移脚本
~/opencode/scripts/migrate-v4.sh

# 确认后清理旧目录
rm -rf ~/.config/opencode/instances
rm -rf ~/.local/share/opencode/instances
rm -rf ~/.local/state/opencode/instances
```
