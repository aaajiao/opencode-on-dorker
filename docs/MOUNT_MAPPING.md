# OCD 挂载映射参考 (v5.0)

Mac 与 Docker 容器之间的目录映射关系。

---

## 核心挂载

| Mac | Docker | 说明 |
|-----|--------|------|
| `<workspace>/` | `/workspace/` | 工作区（双向同步） |
| `~/.config/opencode/` | `/root/.config/opencode/` | 全局配置（用户所有） |
| `~/.local/share/opencode/` | `/root/.local/share/opencode/` | 数据（会话按 git SHA 存储） |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | 状态 |
| `~/.cache/opencode/` | `/root/.cache/opencode/` | OpenCode 缓存 |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | 插件缓存 |
| `~/.ssh/` | `/root/.ssh/:ro` | SSH 密钥（只读） |
| `~/.claude/` | `/root/.claude/` | 全局 Claude 兼容层（基础挂载） |

---

## Claude 兼容层挂载 (v5 新架构)

### 全局存储 (基础层)

所有项目共享的全局存储，作为基础层挂载：

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.claude/` | `/root/.claude/` | 全局 Claude 目录 |
| `~/.claude/todos/` | `/root/.claude/todos/` | 全局 todos (所有项目共享) |
| `~/.claude/transcripts/` | `/root/.claude/transcripts/` | 全局 transcripts (所有项目共享) |
| `~/.claude/commands/` | `/root/.claude/commands/` | 用户全局 commands |
| `~/.claude/skills/` | `/root/.claude/skills/` | 用户全局 skills |
| `~/.claude/agents/` | `/root/.claude/agents/` | 用户全局 agents |
| `~/.claude/rules/` | `/root/.claude/rules/` | 用户全局 rules |

### 项目级覆盖 (条件挂载)

项目配置覆盖全局配置，**仅当目录存在且非空时**才挂载：

| Mac | Docker | 条件 |
|-----|--------|------|
| `<project>/.claude/commands/` | `/root/.claude/commands/` | 非空时覆盖 |
| `<project>/.claude/skills/` | `/root/.claude/skills/` | 非空时覆盖 |
| `<project>/.claude/agents/` | `/root/.claude/agents/` | 非空时覆盖 |
| `<project>/.claude/rules/` | `/root/.claude/rules/` | 非空时覆盖 |
| `<project>/.claude/settings.json` | `/root/.claude/settings.json` | 存在时覆盖 (只读) |
| `<project>/.claude/.mcp.json` | `/root/.claude/.mcp.json` | 存在时覆盖 (只读) |

### 目录结构总览

```
~/.claude/                          # 全局 (基础层)
├── todos/                          # 全局 todos (所有项目共享)
├── transcripts/                    # 全局 transcripts (所有项目共享)
├── commands/                       # 用户全局 commands
├── skills/                         # 用户全局 skills
├── agents/                         # 用户全局 agents
└── rules/                          # 用户全局 rules

<project>/.claude/                  # 项目级 (条件覆盖)
├── commands/                       # 覆盖全局 (非空时)
├── skills/                         # 覆盖全局 (非空时)
├── agents/                         # 覆盖全局 (非空时)
├── rules/                          # 覆盖全局 (非空时)
├── settings.json                   # Claude Code hooks
└── .mcp.json                       # 项目级 MCP
```

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

## 项目 OpenCode 配置挂载

| Mac | Docker | 说明 |
|-----|--------|------|
| `<project>/.opencode/` | `/root/.opencode-project/` | 项目级 OpenCode 配置 |

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
~/.claude/agents/
  ├── oracle.md         →    /root/.claude/agents/
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

## v5 配置特性

### 配置不会被覆盖

v5 中，`~/.config/opencode/` 下的配置文件首次创建后由用户管理：

| 文件 | 首次创建 | 每次启动 |
|------|----------|----------|
| `opencode.json` | 从模板创建 | 只更新端口 |
| `oh-my-opencode.json` | 从模板复制 | 不修改 |

### devocd 隔离

开发模式使用独立配置目录：

| 模式 | 配置目录 |
|------|----------|
| `ocd` | `~/.config/opencode/` |
| `devocd` | `~/.config/opencode-dev/` |

---

## 版本路径变更

| 说明 | v4 路径 | v5 路径 |
|------|---------|---------|
| todos/transcripts | `<project>/.claude/` (项目级) | `~/.claude/` (全局) |
| 项目配置 | - | `<project>/.opencode/` (ocd init 创建) |
| 开发配置 | 共用生产配置 | `~/.config/opencode-dev/` (隔离) |

---

## 迁移

从 v4 升级到 v5 时，运行迁移脚本将项目级 todos/transcripts 迁移到全局：

```bash
~/opencode/scripts/migrate-v5-global-claude.sh
```
