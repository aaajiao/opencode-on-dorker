# OCD 挂载映射参考

Mac 与 Docker 容器之间的目录映射关系。

---

## 全局配置挂载

每次启动 Docker 时，Mac 文件覆盖容器内对应路径。

### OpenCode 原生（单数目录）

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.config/opencode/global/opencode/skill/` | `/root/.config/opencode/skill/` | 全局 Skills |
| `~/.config/opencode/global/opencode/command/` | `/root/.config/opencode/command/` | 全局 Commands |
| `~/.config/opencode/global/opencode/agent/` | `/root/.config/opencode/agent/` | 全局 Agents |

### Claude 兼容层（复数目录）

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.config/opencode/global/claude/` | `/root/.claude/` | 整体挂载 |
| ├─ `skills/` | `/root/.claude/skills/` | 全局 Skills |
| ├─ `commands/` | `/root/.claude/commands/` | 全局 Commands |
| ├─ `agents/` | `/root/.claude/agents/` | 全局 Agents |
| ├─ `rules/` | `/root/.claude/rules/` | 全局 Rules |
| ├─ `settings.json` | `/root/.claude/settings.json` | Hooks 配置 |
| └─ `.mcp.json` | `/root/.claude/.mcp.json` | MCP 服务器 |

---

## 实例配置挂载

| Mac | Docker |
|-----|--------|
| `~/.config/opencode/instances/<inst>/` | `/root/.config/opencode/` |
| `~/.local/share/opencode/instances/<inst>/` | `/root/.local/share/opencode/storage/` |
| `~/.local/state/opencode/instances/<inst>/` | `/root/.opencode/` |

---

## 项目挂载

### 工作区（双向同步）

| Mac | Docker |
|-----|--------|
| `<workspace>/` | `/workspace/` |
| `<project>/.opencode/` | `/workspace/<相对路径>/.opencode/` |

### 会话数据（始终覆盖全局）

| Mac | Docker |
|-----|--------|
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

## 覆盖行为说明

### 情况 1：项目没有 `.claude/agents/` 或目录为空

```
Mac 全局                          Docker 容器
~/.config/opencode/global/
  claude/agents/
    ├── Planner.md         →      /root/.claude/agents/
    ├── oracle.md                   ├── Planner.md
    └── writer.md                   ├── oracle.md
                                    └── writer.md
```

### 情况 2：项目有 `.claude/agents/` 且非空

```
Mac 全局                          Docker 容器
~/.config/opencode/global/
  claude/agents/
    ├── Planner.md         ✗      /root/.claude/agents/
    ├── oracle.md          ✗        └── project-agent.md  ← 只有项目的
    └── writer.md          ✗
                                  （全局 agents 完全不可见）
Mac 项目
<project>/.claude/agents/
    └── project-agent.md   →
```

---

## OpenCode 可读写路径

| 容器路径 | 持久化位置 | 说明 |
|----------|-----------|------|
| `/workspace/` | `<workspace>/` | 工作区文件 |
| `/workspace/.opencode/` | `<project>/.opencode/` | 项目 OpenCode 原生配置 |
| `/root/.claude/` | 全局或项目 | 取决于条件覆盖 |
| `/root/.config/opencode/skill/` | 全局 | OpenCode 原生 Skills |
| `/root/.config/opencode/command/` | 全局 | OpenCode 原生 Commands |
| `/root/.config/opencode/agent/` | 全局 | OpenCode 原生 Agents |

---

## 缓存挂载（可删除重建）

| Mac | Docker |
|-----|--------|
| `~/.cache/opencode/` | `/root/.cache/opencode/` |
| `~/.cache/opencode/ms-playwright/` | `/root/.cache/ms-playwright/` |
| `~/.cache/opencode/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` |

---

## 共享数据挂载

| Mac | Docker | 说明 |
|-----|--------|------|
| `~/.local/share/opencode/auth.json` | `/root/.local/share/opencode/auth.json` | OAuth 令牌 |
| `~/.local/share/opencode/bin/` | `/root/.local/share/opencode/bin/` | 二进制缓存 |
| `~/.ssh/` | `/root/.ssh/` (只读) | SSH 密钥 |
