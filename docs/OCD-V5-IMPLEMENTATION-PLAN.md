# OCD v5 实施方案

> 版本：1.0  
> 日期：2026-01-11  
> 状态：✅ 已实施

---

## 目录

1. [设计原则](#1-设计原则)
2. [目录结构](#2-目录结构)
3. [配置文件详解](#3-配置文件详解)
4. [版本控制](#4-版本控制)
5. [命令列表](#5-命令列表)
6. [核心流程](#6-核心流程)
7. [模板文件](#7-模板文件)
8. [迁移方案](#8-迁移方案)
9. [实施检查清单](#9-实施检查清单)

---

## 1. 设计原则

### 1.1 核心理念

| 原则 | 说明 |
|------|------|
| **用户拥有配置** | 配置文件首次创建后由用户管理，OCD 不再覆盖 |
| **遵循原生设计** | 完全遵循 OpenCode + oh-my-opencode 的目录结构 |
| **Docker 只是包装层** | OCD 只负责 Docker 环境，不发明新的配置格式 |
| **最小化干预** | 每次启动只更新端口，其他不动 |

### 1.2 OCD 职责边界

```
✅ OCD 做的事：
├── 提供 Docker 环境
├── 传递环境变量（API Keys）
├── 首次运行创建全局配置
├── 每次启动更新端口
├── 提供项目初始化模板
└── macOS 集成（通知、剪贴板、URL）

❌ OCD 不做的事：
├── 每次启动重新生成配置
├── 发明新的配置格式
├── 把 API Keys 写入配置文件
└── 管理项目级配置（由用户/OpenCode 处理）
```

---

## 2. 目录结构

### 2.1 OCD 安装目录

```
~/opencode/
├── .env.example                         # API Keys 示例
├── .env                                 # 用户创建（必需）
├── models.conf.example                  # 模型配置示例
├── models.conf                          # 用户可选创建
├── versions.lock                        # 版本锁定（核心依赖）
├── versions.lock.example                # 版本锁定示例
├── Dockerfile
├── VERSION                              # OCD 版本号
├── bin/
│   ├── ocd                              # 主程序
│   └── devocd                           # 开发模式
├── lib/
│   ├── core.sh                          # 核心函数、环境变量、版本
│   ├── config.sh                        # 配置管理
│   ├── docker.sh                        # Docker 构建和运行
│   ├── port.sh                          # 端口分配
│   ├── workspace.sh                     # 工作目录检测
│   ├── watcher.sh                       # IPC 监控
│   └── migrate.sh                       # v4 → v5 迁移（新增）
├── templates/
│   ├── global/                          # 全局配置模板
│   │   ├── opencode.json.tmpl
│   │   └── oh-my-opencode.json
│   └── project/                         # 项目配置模板
│       ├── opencode.json.example
│       ├── AGENTS.md.example
│       ├── .mcp.json.example
│       ├── .opencode/
│       │   ├── oh-my-opencode.json.example
│       │   ├── agent/
│       │   ├── command/
│       │   ├── skill/
│       │   └── plugin/
│       └── .claude/
│           ├── settings.json.example
│           ├── agents/
│           ├── commands/
│           └── skills/
└── docs/
    └── OCD-V5-IMPLEMENTATION-PLAN.md    # 本文档
```

### 2.2 全局配置目录

```
~/.config/opencode/                      # OCD 首次运行时创建
├── opencode.json                        # 从模板复制（替换版本占位符）
├── oh-my-opencode.json                  # 从模板复制
├── agent/                               # 空目录
├── command/                             # 空目录
├── skill/                               # 空目录
├── themes/                              # 空目录
├── .ocd-v5-init                         # 标记：已显示欢迎信息
└── .ocd-v5-migrated                     # 标记：已从 v4 迁移
```

### 2.3 Claude Code 目录

```
~/.claude/                               # Claude Code CLI 创建
├── settings.json                        # Claude Code 配置（含 hooks）
├── CLAUDE.md                            # User scope 指令
├── agents/                              # User scope subagents
├── commands/                            # User scope commands
├── skills/                              # User scope skills
└── .mcp.json                            # User scope MCP

注意：OCD 不创建此目录，只在存在时挂载到容器
```

### 2.4 项目配置结构

```
<project>/
├── .git/                                # Git 仓库（ocd init 可选创建）
├── opencode.json                        # 项目级 OpenCode 配置
├── AGENTS.md                            # 项目规则（OpenCode 原生）
├── CLAUDE.md                            # 项目规则（Claude Code 兼容）
├── .mcp.json                            # 项目 MCP（Claude Code 兼容）
├── .gitignore                           # ocd init 添加忽略规则
├── .opencode/                           # OpenCode 原生目录
│   ├── oh-my-opencode.json             # 项目级插件配置
│   ├── agent/
│   │   └── *.md
│   ├── command/
│   │   └── *.md
│   ├── skill/
│   │   └── */SKILL.md
│   └── plugin/
│       └── *.ts
└── .claude/                             # Claude Code 兼容目录
    ├── settings.json                    # Claude Code 配置（含 hooks）
    ├── settings.local.json              # 本地配置（gitignored）
    ├── CLAUDE.md                        # Project scope 指令
    ├── agents/
    │   └── *.md
    ├── commands/
    │   └── *.md
    └── skills/
        └── */SKILL.md
```

---

## 3. 配置文件详解

### 3.1 配置文件职责

| 文件 | 位置 | 创建者 | 用途 |
|------|------|--------|------|
| `.env` | `~/opencode/` | 用户从示例复制 | API Keys（必需） |
| `models.conf` | `~/opencode/` | 用户从示例复制 | 快速切换模型（可选） |
| `versions.lock` | `~/opencode/` | 仓库自带 | 核心依赖版本锁定 |
| `opencode.json` | `~/.config/opencode/` | OCD 首次运行 | OpenCode 全局配置 |
| `oh-my-opencode.json` | `~/.config/opencode/` | OCD 首次运行 | oh-my-opencode 全局配置 |
| `~/.claude/*` | `~/.claude/` | Claude Code CLI | Claude Code 配置（OCD 不创建） |
| 项目 `opencode.json` | `<project>/` | `ocd init` / 用户 | 项目 OpenCode 配置 |
| 项目 `.opencode/` | `<project>/.opencode/` | `ocd init` / 用户 | 项目 oh-my-opencode 配置 |
| 项目 `.claude/` | `<project>/.claude/` | `ocd init` / 用户 | 项目 Claude Code 配置 |

### 3.2 配置优先级

#### OpenCode 配置合并

```
1. ~/.config/opencode/opencode.json      (全局)
2. <project>/opencode.json                (项目) → 合并覆盖
```

#### oh-my-opencode 配置合并

```
1. ~/.config/opencode/oh-my-opencode.json (全局)
2. <project>/.opencode/oh-my-opencode.json (项目) → 合并覆盖
```

#### Claude Code 配置合并

```
1. ~/.claude/settings.json                (User scope)
2. <project>/.claude/settings.json        (Project scope) → 合并
3. <project>/.claude/settings.local.json  (Local scope) → 合并
```

#### OCD 配置覆盖顺序

```
1. 模板默认值
2. versions.lock 版本替换（首次创建时）
3. 用户编辑的 JSON
4. models.conf 覆盖（只覆盖模型字段，每次启动）
5. 端口更新（只更新 server.port，每次启动）
```

### 3.3 Hooks 机制

#### oh-my-opencode 内置 Hooks

在 `oh-my-opencode.json` 中通过 `disabled_hooks` 控制：

```json
{
  "disabled_hooks": [
    "comment-checker",
    "todo-continuation-enforcer"
  ]
}
```

#### Claude Code Hooks

在 `.claude/settings.json` 中配置，oh-my-opencode 的 `claude-code-hooks` 功能会读取并执行：

```json
{
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "UserPromptSubmit": [...],
    "Stop": [...]
  }
}
```

---

## 4. 版本控制

### 4.1 versions.lock 内容

只控制 **Docker 构建** + **核心插件**：

```bash
# ================================================
# OCD (OpenCode Docker) 版本锁定文件
# ================================================
# 只控制 Docker 构建依赖和核心插件
# 其他插件/MCP 在 opencode.json 中配置
# ================================================

# ------------------------------------------------
# Docker 基础镜像
# ------------------------------------------------
BUN_VERSION=1.3.5

# ------------------------------------------------
# OpenCode 核心
# ------------------------------------------------
OPENCODE_AI_VERSION=1.1.12

# ------------------------------------------------
# 核心插件
# ------------------------------------------------
OH_MY_OPENCODE_VERSION=2.14.0

# ------------------------------------------------
# Python 依赖 (Dockerfile)
# ------------------------------------------------
PIP_REQUESTS=2.32.5
PIP_PANDAS=2.2.3
PIP_NUMPY=2.2.1
PIP_MATPLOTLIB=3.10.0
PIP_BEAUTIFULSOUP4=4.12.3
PIP_PILLOW=11.1.0
```

### 4.2 版本控制分层

| 版本 | 控制位置 | 说明 |
|------|----------|------|
| BUN | versions.lock | Docker 基础镜像 |
| OpenCode | versions.lock | Docker 构建时安装 |
| oh-my-opencode | versions.lock | 核心插件，写入 opencode.json |
| Python 包 | versions.lock | Docker 构建时安装 |
| 其他插件 | opencode.json | 用户控制（`@latest` 或指定版本） |
| MCP 服务器 | opencode.json | 用户控制（`@latest` 或指定版本） |

---

## 5. 命令列表

### 5.1 主要命令

| 命令 | 说明 |
|------|------|
| `ocd` | 启动 OpenCode |
| `ocd -r` | 重建 Docker 镜像 |
| `ocd -p <port>` | 指定端口 |
| `ocd --here` | 只挂载当前目录（跳过 git 查找） |
| `ocd --clean` | 重置全局配置（备份后从模板复制） |
| `ocd --https` | 启用 Tailscale HTTPS |
| `ocd --awake` | 阻止 Mac 睡眠 |
| `ocd -v` | 显示版本 |
| `ocd init` | 初始化项目配置（完整） |
| `ocd init --minimal` | 只创建 AGENTS.md |
| `ocd config` | 显示配置路径 |
| `ocd config edit` | 编辑全局 opencode.json |
| `ocd config edit --plugin` | 编辑全局 oh-my-opencode.json |
| `devocd` | 开发模式（使用 dev/ 目录） |
| `devocd -r` | 开发模式重建镜像 |

---

## 6. 核心流程

### 6.1 主启动流程

```bash
ocd_main() {
  # 1. 解析参数
  ocd_parse_args "$@"
  
  # 2. 检查 .env（必需）
  if [[ ! -f "$OCD_ROOT/.env" ]]; then
    ocd_error "缺少 .env 文件"
    ocd_info "请先创建："
    ocd_info "  cp ~/opencode/.env.example ~/opencode/.env"
    ocd_info "  nano ~/opencode/.env"
    exit 1
  fi
  ocd_load_env
  
  # 3. 加载版本
  ocd_load_versions
  
  # 4. 检查 Docker 镜像
  ocd_ensure_image
  
  # 5. 确保全局配置目录和文件
  ocd_ensure_global_config
  
  # 6. v4 迁移检查
  ocd_check_migration
  
  # 7. 首次运行显示欢迎
  ocd_show_welcome_if_first_run
  
  # 8. 可选：应用 models.conf
  ocd_apply_models_conf_if_exists
  
  # 9. 分配端口
  local port=$(ocd_allocate_port)
  
  # 10. 更新配置中的端口
  ocd_update_port "$port"
  
  # 11. 确定挂载目录
  local mount_dir=$(ocd_find_mount_dir "$PWD" "$OCD_HERE_MODE")
  
  # 12. 启动 watcher
  ocd_start_watcher "$port"
  
  # 13. 启动 Docker 容器
  ocd_run_container "$port" "$mount_dir"
  
  # 14. 清理
  ocd_cleanup "$port"
}
```

### 6.2 全局配置创建流程

```bash
ocd_ensure_global_config() {
  local config_dir="$HOME/.config/opencode"
  
  # 创建目录结构
  mkdir -p "$config_dir"/{agent,command,skill,themes}
  
  # opencode.json（从模板创建，替换版本占位符）
  if [[ ! -f "$config_dir/opencode.json" ]]; then
    ocd_create_config_from_template \
      "$OCD_ROOT/templates/global/opencode.json.tmpl" \
      "$config_dir/opencode.json"
    ocd_info "已创建 ~/.config/opencode/opencode.json"
  fi
  
  # oh-my-opencode.json（直接复制）
  if [[ ! -f "$config_dir/oh-my-opencode.json" ]]; then
    cp "$OCD_ROOT/templates/global/oh-my-opencode.json" \
       "$config_dir/oh-my-opencode.json"
    ocd_info "已创建 ~/.config/opencode/oh-my-opencode.json"
  fi
}

ocd_create_config_from_template() {
  local template="$1"
  local output="$2"
  
  local content=$(cat "$template")
  content="${content//\{\{OH_MY_OPENCODE_VERSION\}\}/${OH_MY_OPENCODE_VERSION:-latest}}"
  
  echo "$content" > "$output"
}
```

### 6.3 项目初始化流程

```bash
ocd_init_project() {
  local mode="${1:-full}"
  local project_dir="$PWD"
  local template_dir="$OCD_ROOT/templates/project"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  📦 初始化项目配置"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # 1. 检查 Git
  if [[ ! -d "$project_dir/.git" ]]; then
    echo "⚠️  当前目录不是 Git 仓库"
    echo ""
    read -p "是否初始化 Git 仓库？[y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      git init
      echo "✅ Git 仓库已初始化"
    else
      echo "⏭️  跳过 Git 初始化"
      echo "   提示：OpenCode 使用 .git 识别项目边界"
    fi
    echo ""
  fi
  
  # 2. 创建配置文件
  echo "创建配置文件："
  echo ""
  
  # AGENTS.md（始终创建）
  ocd_copy_if_not_exists "$template_dir/AGENTS.md.example" \
                         "$project_dir/AGENTS.md"
  
  if [[ "$mode" != "--minimal" ]]; then
    # OpenCode 配置
    ocd_copy_if_not_exists "$template_dir/opencode.json.example" \
                           "$project_dir/opencode.json"
    
    # 项目 MCP
    ocd_copy_if_not_exists "$template_dir/.mcp.json.example" \
                           "$project_dir/.mcp.json"
    
    # .opencode/ 目录
    mkdir -p "$project_dir/.opencode"/{agent,command,skill,plugin}
    ocd_copy_if_not_exists "$template_dir/.opencode/oh-my-opencode.json.example" \
                           "$project_dir/.opencode/oh-my-opencode.json"
    
    # .claude/ 目录
    mkdir -p "$project_dir/.claude"/{agents,commands,skills}
    ocd_copy_if_not_exists "$template_dir/.claude/settings.json.example" \
                           "$project_dir/.claude/settings.json"
  fi
  
  # 3. 更新 .gitignore
  if [[ -d "$project_dir/.git" ]]; then
    local gitignore="$project_dir/.gitignore"
    local patterns=(
      ".claude/settings.local.json"
      ".claude/*.local.*"
    )
    
    for pattern in "${patterns[@]}"; do
      if ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
        echo "$pattern" >> "$gitignore"
        echo "  📝 添加到 .gitignore: $pattern"
      fi
    done
  fi
  
  # 4. 完成提示
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ✅ 初始化完成"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  下一步："
  echo "  1. 编辑 AGENTS.md 描述你的项目"
  echo "  2. 或在 OpenCode 内运行 /init 自动生成"
  echo ""
  echo "  启动 OpenCode："
  echo "    ocd"
  echo ""
}
```

### 6.4 Docker 运行

```bash
ocd_run_container() {
  local port="$1"
  local mount_dir="$2"
  local config_dir="$HOME/.config/opencode"
  
  # 准备 ~/.claude 挂载（如果存在）
  local claude_mount=""
  [[ -d "$HOME/.claude" ]] && claude_mount="-v $HOME/.claude:/root/.claude"
  
  docker run -it --rm \
    --name "opencode-$port" \
    -e ANTHROPIC_API_KEY \
    -e OPENAI_API_KEY \
    -e GEMINI_API_KEY \
    -e GITHUB_TOKEN \
    -e EXA_API_KEY \
    -p "$port:$port" \
    -v "$config_dir:/root/.config/opencode" \
    $claude_mount \
    -v "$mount_dir:/workspace" \
    -w "/workspace" \
    --network host \
    opencode-bun
}
```

### 6.5 挂载目录逻辑

```bash
ocd_find_mount_dir() {
  local current_dir="$1"
  local here_mode="${2:-0}"
  
  # --here 模式：直接返回当前目录
  if [[ "$here_mode" == "1" ]]; then
    echo "$current_dir"
    return
  fi
  
  # 向上查找 .git
  local dir="$current_dir"
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
  
  # 没找到 .git，返回当前目录
  echo "$current_dir"
}
```

### 6.6 devocd 开发模式

```bash
#!/usr/bin/env bash
# ~/opencode/bin/devocd

set -euo pipefail

# 设置开发模式
export OCD_DEV_MODE=1
export OCD_ROOT="${OCD_DEV_ROOT:-$HOME/opencode/dev}"
export OCD_CONFIG_HOME="${OCD_DEV_CONFIG:-$HOME/.config/opencode-dev}"

# 检查 dev 目录是否存在
if [[ ! -d "$OCD_ROOT" ]]; then
  echo "❌ 开发目录不存在: $OCD_ROOT"
  exit 1
fi

# 执行开发版本
exec "$OCD_ROOT/bin/ocd" "$@"
```

---

## 7. 模板文件

### 7.1 templates/global/opencode.json.tmpl

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "plugin": [
    "oh-my-opencode@{{OH_MY_OPENCODE_VERSION}}",
    "opencode-antigravity-auth@latest"
  ],
  "server": {
    "port": 4096,
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server@latest"],
      "enabled": false,
      "environment": {
        "EXA_API_KEY": "{env:EXA_API_KEY}"
      }
    }
  }
}
```

### 7.2 templates/global/oh-my-opencode.json

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "agents": {
    "Sisyphus": { "model": "anthropic/claude-opus-4-5" },
    "oracle": { "model": "openai/gpt-5.2" },
    "librarian": { "model": "anthropic/claude-haiku-4-5" },
    "explore": { "model": "opencode/grok-code" },
    "frontend-ui-ux-engineer": { "model": "google/gemini-3-pro-preview" },
    "document-writer": { "model": "google/gemini-3-flash" },
    "multimodal-looker": { "model": "google/gemini-3-flash" }
  }
}
```

### 7.3 templates/project/opencode.json.example

```json
{
  "$schema": "https://opencode.ai/config.json",
  
  "model": "anthropic/claude-opus-4-5",
  
  "mcp": {
    "project-server": {
      "type": "local",
      "command": ["npx", "-y", "some-mcp-server"],
      "enabled": true
    }
  },
  
  "agent": {
    "project-expert": {
      "description": "了解本项目架构的专家",
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-5"
    }
  },
  
  "instructions": [
    "CONTRIBUTING.md",
    "docs/architecture.md"
  ]
}
```

### 7.4 templates/project/AGENTS.md.example

```markdown
# 项目名称

简要描述...

## 技术栈

- 主要框架
- 语言版本
- 包管理器

## 项目结构

- `src/` - 源代码
- `tests/` - 测试
- `docs/` - 文档

## 开发规范

- 代码风格
- 命名约定
- 提交规范

## 常用命令

\`\`\`bash
npm run dev      # 开发服务器
npm run test     # 运行测试
npm run build    # 构建
\`\`\`

## 提示

在 OpenCode 内运行 /init 可以自动生成更详细的项目描述
```

### 7.5 templates/project/.mcp.json.example

```json
{
  "mcpServers": {
    "project-server": {
      "command": "npx",
      "args": ["-y", "some-mcp-server"],
      "env": {
        "API_KEY": "${PROJECT_API_KEY}"
      }
    }
  }
}
```

### 7.6 templates/project/.opencode/oh-my-opencode.json.example

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  
  "agents": {
    "frontend-ui-ux-engineer": {
      "model": "google/gemini-3-pro-preview",
      "prompt_append": "本项目使用特定框架..."
    }
  },
  
  "disabled_hooks": [],
  "disabled_mcps": [],
  
  "claude_code": {
    "mcp": true,
    "commands": true,
    "skills": true,
    "agents": true,
    "hooks": true
  }
}
```

### 7.7 templates/project/.claude/settings.json.example

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File modified'"
          }
        ]
      }
    ]
  }
}
```

---

## 8. 迁移方案

### 8.1 v4 → v5 迁移检查

```bash
ocd_check_migration() {
  local config_dir="$HOME/.config/opencode"
  
  # 检测 v4 配置
  if [[ -f "$config_dir/opencode.json" ]] && \
     [[ ! -f "$config_dir/.ocd-v5-migrated" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔄 OCD v5 配置说明"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  从 v5 开始，配置文件由你管理，OCD 只更新端口。"
    echo ""
    echo "  你的配置文件已保留："
    echo "    - ~/.config/opencode/opencode.json"
    echo "    - ~/.config/opencode/oh-my-opencode.json"
    echo ""
    
    # 标记已迁移
    touch "$config_dir/.ocd-v5-migrated"
  fi
  
  # 提示 mcp.json 已废弃
  if [[ -f "$OCD_ROOT/mcp.json" ]]; then
    echo "  ⚠️  检测到 ~/opencode/mcp.json"
    echo "     v5 的 MCP 配置已移至 opencode.json 的 mcp 字段"
    echo "     请手动迁移后删除 mcp.json"
    echo ""
  fi
}
```

### 8.2 废弃项

| v4 文件 | v5 处理 |
|---------|---------|
| `~/.config/opencode/opencode.json` | 保留，不再覆盖 |
| `~/.config/opencode/oh-my-opencode.json` | 保留，不再覆盖 |
| `~/opencode/models.conf` | 继续支持（可选覆盖模型） |
| `~/opencode/mcp.json` | 废弃，提示迁移到 opencode.json |
| `~/opencode/versions.lock` | 简化，只保留核心依赖 |

---

## 9. 实施检查清单

### 9.1 文件创建

- [ ] `templates/global/opencode.json.tmpl` - 添加 `{{OH_MY_OPENCODE_VERSION}}` 占位符
- [ ] `templates/global/oh-my-opencode.json` - 无占位符，直接复制
- [ ] `templates/project/opencode.json.example`
- [ ] `templates/project/AGENTS.md.example`
- [ ] `templates/project/.mcp.json.example`
- [ ] `templates/project/.opencode/oh-my-opencode.json.example`
- [ ] `templates/project/.opencode/agent/` (空目录)
- [ ] `templates/project/.opencode/command/` (空目录)
- [ ] `templates/project/.opencode/skill/` (空目录)
- [ ] `templates/project/.opencode/plugin/` (空目录)
- [ ] `templates/project/.claude/settings.json.example`
- [ ] `templates/project/.claude/agents/` (空目录)
- [ ] `templates/project/.claude/commands/` (空目录)
- [ ] `templates/project/.claude/skills/` (空目录)
- [ ] `.env.example` 更新
- [ ] `models.conf.example` 更新
- [ ] `versions.lock` 简化（移除 MCP 版本、其他插件版本）

### 9.2 lib/ 修改

- [ ] `lib/core.sh` - 更新 `ocd_load_versions()` 如需
- [ ] `lib/config.sh` - 重写配置生成逻辑
  - [ ] `ocd_ensure_global_config()` - 首次创建配置
  - [ ] `ocd_create_config_from_template()` - 模板替换
  - [ ] `ocd_update_port()` - 只更新端口
  - [ ] `ocd_apply_models_conf()` - models.conf 覆盖逻辑
  - [ ] 删除 `ocd_generate_opencode_config()` (v4)
  - [ ] 删除 `ocd_generate_omo_config()` (v4)
  - [ ] 删除 `ocd_load_mcp()` (v4)
- [ ] `lib/migrate.sh` (新增) - v4 迁移逻辑
  - [ ] `ocd_check_migration()`
- [ ] `lib/docker.sh` - 更新挂载逻辑
  - [ ] 添加 `~/.claude` 挂载（如果存在）
- [ ] `lib/workspace.sh` - 更新 `--here` 逻辑

### 9.3 bin/ 修改

- [ ] `bin/ocd` - 添加新命令
  - [ ] `ocd init` / `ocd init --minimal`
  - [ ] `ocd config` / `ocd config edit` / `ocd config edit --plugin`
  - [ ] `ocd --clean` 重置逻辑
- [ ] `bin/devocd` - 更新开发模式
  - [ ] 独立配置目录 `~/.config/opencode-dev/`

### 9.4 欢迎信息

- [ ] 更新首次运行欢迎信息
- [ ] 说明配置文件位置
- [ ] 说明 models.conf 作用
- [ ] 说明 ocd init 用法

### 9.5 测试

- [ ] 首次安装测试（无配置）
- [ ] v4 迁移测试（有旧配置）
- [ ] `ocd init` 测试（有 git / 无 git）
- [ ] `ocd --here` 测试
- [ ] `ocd --clean` 测试
- [ ] `devocd` 开发模式测试
- [ ] models.conf 覆盖测试
- [ ] 多窗口端口分配测试

### 9.6 文档

- [ ] 更新 README.md
- [ ] 更新 AGENTS.md
- [ ] 更新 CHANGELOG.md

---

## 附录：关键决策记录

| 决策 | 理由 |
|------|------|
| 配置首次创建后不覆盖 | 用户拥有配置，OCD 不应干预 |
| MCP 版本不放 versions.lock | MCP 是运行时依赖，用户应自己控制 |
| 只有 oh-my-opencode 放 versions.lock | 核心插件由 OCD 维护，其他用户控制 |
| 保留 models.conf 作为可选 | 便捷的模型切换方式 |
| `~/.claude/` 不由 OCD 创建 | Claude Code CLI 自己创建，OCD 只挂载 |
| `ocd init` 提示 git 初始化 | OpenCode 用 .git 识别项目边界 |
| devocd 使用独立配置目录 | 开发不影响生产配置 |
