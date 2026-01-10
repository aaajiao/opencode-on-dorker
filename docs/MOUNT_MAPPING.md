# OCD 挂载映射参考 (v4.0)

Mac 与 Docker 容器之间的目录映射关系。

---

## 核心挂载 (v4.0 简化架构)

v4.0 移除了 instance 概念，所有配置和数据共享：

| Mac | Docker | 说明 |
|-----|--------|------|
| `<workspace>/` | `/workspace/` | 工作区（双向同步） |
| `~/.config/opencode/` | `/root/.config/opencode/` | 共享配置 |
| `~/.local/share/opencode/` | `/root/.local/share/opencode/` | 共享数据（会话按 git SHA 存储） |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | 状态 |
| `~/.cache/opencode/` | `/root/.cache/opencode/` | OpenCode 缓存 |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | 插件缓存 |
| `~/.ssh/` | `/root/.ssh/:ro` | SSH 密钥（只读） |

---

## IPC 挂载 (多窗口支持)

每个端口有独立的 IPC 目录：

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.local/state/opencode/ipc/<port>/` | `/root/.opencode/` | IPC 文件 |

IPC 目录内容：

| 文件 | 用途 |
|------|------|
| `open_url` | 写入 URL，Mac watcher 打开浏览器 |
| `notifications` | 写入 `标题\|内容`，Mac watcher 发送通知 |
| `clipboard` | 写入内容，Mac watcher 执行 pbcopy |
| `.watcher.pid` | watcher 进程 PID（用于清理） |

---

## 项目级配置挂载

### 会话数据（始终挂载）

| Mac | Docker |
|-----|--------|
| `<project>/.claude/` | `/root/.claude/` |
| `<project>/.claude/todos/` | `/root/.claude/todos/` |
| `<project>/.claude/transcripts/` | `/root/.claude/transcripts/` |

### 项目配置（条件覆盖）

**仅当目录存在且非空时**，项目配置覆盖全局配置：

| Mac | Docker | 条件 |
|-----|--------|------|
| `<project>/.claude/skills/` | `/root/.claude/skills/` | 非空时覆盖 |
| `<project>/.claude/commands/` | `/root/.claude/commands/` | 非空时覆盖 |
| `<project>/.claude/agents/` | `/root/.claude/agents/` | 非空时覆盖 |
| `<project>/.claude/rules/` | `/root/.claude/rules/` | 非空时覆盖 |

---

## 全局配置目录

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.config/opencode/skill/` | `/root/.config/opencode/skill/` | 全局 Skills |
| `~/.config/opencode/command/` | `/root/.config/opencode/command/` | 全局 Commands |
| `~/.config/opencode/agent/` | `/root/.config/opencode/agent/` | 全局 Agents |

---

## 覆盖行为说明

### 情况 1：项目没有 `.claude/agents/` 或目录为空

```
全局配置生效：
~/.config/opencode/agent/
  ├── oracle.md         →    /root/.config/opencode/agent/
  └── writer.md               ├── oracle.md
                              └── writer.md
```

### 情况 2：项目有 `.claude/agents/` 且非空

```
项目配置完全覆盖全局：
<project>/.claude/agents/
  └── my-agent.md       →    /root/.claude/agents/
                              └── my-agent.md
                              
全局 agents 完全不可见（替换，非合并）
```

---

## 缓存挂载

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.cache/opencode/` | `/root/.cache/opencode/` | OpenCode 缓存 |
| `~/.cache/opencode/ms-playwright/` | `/root/.cache/ms-playwright/` | Playwright 浏览器 |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | 插件缓存 (ast-grep, ripgrep) |

---

## v3.x → v4.0 路径变更

| 说明 | v3.x 路径 | v4.0 路径 |
|------|-----------|-----------|
| 配置 | `~/.config/opencode/instances/<inst>/` | `~/.config/opencode/` |
| 会话 | `~/.local/share/opencode/instances/<inst>/` | `~/.local/share/opencode/storage/` |
| IPC | `~/.local/state/opencode/instances/<inst>/` | `~/.local/state/opencode/ipc/<port>/` |
