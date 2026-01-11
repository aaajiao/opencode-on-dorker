# RFC: OCD v5 全局 Claude 存储方案

> 状态: 草案  
> 日期: 2026-01-11  
> 作者: Sisyphus + Human

---

## 1. 背景

### 1.1 当前问题

OCD 当前将 `<project>/.claude/` 整个挂载到容器的 `~/.claude/`，导致：

1. **todos/transcripts 变成项目级存储**
   - oh-my-opencode 设计为全局存储 (`~/.claude/todos/`, `~/.claude/transcripts/`)
   - OCD 的挂载方式使其变成项目级，与设计不符

2. **切换项目时数据隔离**
   - 每个项目有独立的 todos/transcripts
   - 无法跨项目查看历史会话

3. **`--merge-up` 功能的存在**
   - 为了解决项目级 transcripts 的问题而引入
   - 本质是 workaround，增加了复杂性

### 1.2 oh-my-opencode v3.x 的存储架构

```
存储类型              │ 路径                                    │ 用途
─────────────────────┼─────────────────────────────────────────┼──────────────────
OpenCode 原生         │ ~/.local/share/opencode/storage/       │ session/message/part
Claude 兼容层（全局）  │ ~/.claude/                             │ todos/transcripts/commands/skills/agents
Claude 兼容层（项目）  │ <project>/.claude/                     │ commands/skills/agents/settings.json
```

**关键点**：
- `CLAUDE_CONFIG_DIR` 环境变量仍然存在，可用于重定向
- todos/transcripts 设计为全局存储
- 项目级 `.claude/` 用于配置覆盖（commands/skills/agents）

---

## 2. 目标

### 2.1 设计目标

1. **todos/transcripts 改为全局存储** - 符合 oh-my-opencode 原设计
2. **项目级 `.claude/` 保留** - 用于 commands/skills/agents/settings.json
3. **简化挂载逻辑** - 移除不必要的复杂性
4. **平滑迁移** - 现有数据不丢失

### 2.2 目标架构

```
Mac Host                              Docker Container
──────────────────────────────────────────────────────────────────────────

~/.claude/                     →      /root/.claude/
├── todos/         (全局)             ├── todos/
├── transcripts/   (全局)             ├── transcripts/
├── commands/      (用户全局)          ├── commands/      ← 可被项目覆盖
├── skills/        (用户全局)          ├── skills/        ← 可被项目覆盖
├── agents/        (用户全局)          ├── agents/        ← 可被项目覆盖
└── rules/         (用户全局)          └── rules/         ← 可被项目覆盖

<project>/.claude/             →      覆盖挂载 (条件)
├── commands/      (项目级)            /root/.claude/commands/
├── skills/        (项目级)            /root/.claude/skills/
├── agents/        (项目级)            /root/.claude/agents/
├── rules/         (项目级)            /root/.claude/rules/
├── settings.json               →      /root/.claude/settings.json
└── .mcp.json                   →      /root/.claude/.mcp.json
```

---

## 3. 详细设计

### 3.1 挂载策略

```bash
# 1. 基础挂载：全局 ~/.claude → /root/.claude
-v "$HOME/.claude:/root/.claude"

# 2. 项目级覆盖挂载（条件：目录非空或文件存在）
for subdir in commands skills agents rules; do
  if [[ -d "<project>/.claude/$subdir" ]] && [[ -n "$(ls -A ...)" ]]; then
    -v "<project>/.claude/$subdir:/root/.claude/$subdir"
  fi
done

if [[ -f "<project>/.claude/settings.json" ]]; then
  -v "<project>/.claude/settings.json:/root/.claude/settings.json:ro"
fi

if [[ -f "<project>/.claude/.mcp.json" ]]; then
  -v "<project>/.claude/.mcp.json:/root/.claude/.mcp.json:ro"
fi
```

### 3.2 目录结构

#### 3.2.1 全局目录 (`~/.claude/`)

```
~/.claude/
├── todos/                      # 全局 todos (所有项目共享)
│   └── {sessionId}.json
├── transcripts/                # 全局 transcripts (所有项目共享)
│   └── {sessionId}.jsonl
├── commands/                   # 用户全局 commands
├── skills/                     # 用户全局 skills
├── agents/                     # 用户全局 agents
└── rules/                      # 用户全局 rules
```

#### 3.2.2 项目目录 (`<project>/.claude/`)

```
<project>/.claude/
├── commands/                   # 项目级 commands (覆盖全局)
├── skills/                     # 项目级 skills (覆盖全局)
├── agents/                     # 项目级 agents (覆盖全局)
├── rules/                      # 项目级 rules (覆盖全局)
├── settings.json               # Claude Code hooks 配置
└── .mcp.json                   # 项目级 MCP 配置
```

#### 3.2.3 完整目录结构总览

```
~/.claude/                          # 全局 Claude 兼容层 (oh-my-opencode)
├── todos/                          # 全局 todos
├── transcripts/                    # 全局 transcripts
├── commands/                       # 用户全局 commands
├── skills/                         # 用户全局 skills
├── agents/                         # 用户全局 agents
└── rules/                          # 用户全局 rules

~/.config/opencode/                 # OpenCode 配置 (XDG)
├── opencode.json                   # 主配置
├── oh-my-opencode.json             # oh-my-opencode 插件配置
└── {agent,command,skill}/          # OpenCode 全局配置

~/.local/share/opencode/            # OpenCode 数据 (XDG)
├── storage/                        # OpenCode 原生会话数据
│   ├── session/{git-sha}/          # Session 元数据
│   ├── message/                    # 消息元数据
│   ├── part/                       # 消息内容
│   └── todo/                       # OpenCode 原生 todo
└── auth.json                       # 认证数据

<project>/.claude/                  # 项目级 Claude 兼容层
├── commands/                       # 项目级 commands
├── skills/                         # 项目级 skills
├── agents/                         # 项目级 agents
├── rules/                          # 项目级 rules
├── settings.json                   # Claude Code hooks
└── .mcp.json                       # 项目级 MCP

<project>/.opencode/                # 项目级 OpenCode 配置
├── oh-my-opencode.json             # 项目级插件配置
└── {agent,command,skill,plugin}/   # OpenCode 项目配置
```

---

## 4. 实施方案

### 4.1 文件修改清单

| 文件 | 修改内容 |
|------|----------|
| `lib/core.sh` | 新增 `OCD_CLAUDE_HOME` 常量 |
| `lib/docker.sh` | 重构挂载逻辑，支持全局 + 项目覆盖 |
| `lib/config.sh` | 更新 `ocd_init_project()`，补全目录结构 |
| `bin/ocd` | 删除 `--merge-up` 相关代码 |
| `templates/project/.claude/` | 新增 `rules/.gitkeep` |
| `docs/MOUNT_MAPPING.md` | 更新挂载映射文档 |
| 新增 | `scripts/migrate-v5-global-claude.sh` |

### 4.2 代码变更

#### 4.2.1 `lib/core.sh`

```bash
# 新增：全局 Claude 兼容层目录
OCD_CLAUDE_HOME="$HOME/.claude"
```

#### 4.2.2 `lib/docker.sh`

```bash
ocd_run_container() {
  local container_name="$1"
  local image_name="$2"
  local workspace_root="$3"
  local port="$4"
  local start_dir="$5"
  local env_file="$6"
  shift 6

  local ipc_dir
  ipc_dir=$(ocd_ipc_dir "$port")
  local playwright_cache="$OCD_CACHE_HOME/ms-playwright"

  # 项目目录检测
  local project_dir
  if [[ "${OCD_DEV_MODE:-0}" -eq 1 ]]; then
    project_dir="${OCD_ROOT:-$HOME/opencode/dev}"
  else
    if [[ -n "$start_dir" && "$start_dir" != "." ]]; then
      project_dir=$(ocd_find_project_dir "${workspace_root}/${start_dir}")
    else
      project_dir=$(ocd_find_project_dir "$workspace_root")
    fi
  fi
  
  # 全局和项目 Claude 目录
  local global_claude="$OCD_CLAUDE_HOME"
  local project_claude="${project_dir}/.claude"

  # 安全检查
  if [[ -z "$OCD_CACHE_HOME" || "$OCD_CACHE_HOME" == "/" ]]; then
    ocd_error "OCD_CACHE_HOME 未正确设置 ($OCD_CACHE_HOME)"
    return 1
  fi

  # 创建必要目录
  mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}
  mkdir -p "$OCD_DATA_HOME"/{bin,storage}
  mkdir -p "$OCD_OMO_CACHE_HOME/bin" "$playwright_cache"
  mkdir -p "$global_claude"/{todos,transcripts,commands,skills,agents,rules}
  touch "$OCD_DATA_HOME/auth.json" 2>/dev/null || true

  # 清理旧容器
  docker rm -f "$container_name" 2>/dev/null

  # 时区
  local tz
  tz=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo "UTC")

  # 基础挂载
  local mount_args=(
    -v "${workspace_root}:/workspace"
    -v "${ipc_dir}:/root/.opencode"
    -v "$OCD_CONFIG_HOME:/root/.config/opencode"
    -v "$OCD_DATA_HOME:/root/.local/share/opencode"
    -v "$OCD_STATE_HOME:/root/.local/state/opencode"
    -v "$OCD_CACHE_HOME:/root/.cache/opencode"
    -v "$OCD_OMO_CACHE_HOME:/root/.cache/oh-my-opencode"
    -v "${playwright_cache}:/root/.cache/ms-playwright"
    -v "$HOME/.ssh:/root/.ssh:ro"
    # 全局 Claude 目录（基础层）
    -v "$global_claude:/root/.claude"
  )

  # 项目级 Claude 配置覆盖挂载
  local subdir proj_subdir
  for subdir in commands skills agents rules; do
    proj_subdir="${project_claude}/${subdir}"
    if [[ -d "$proj_subdir" ]] && [[ -n "$(ls -A "$proj_subdir" 2>/dev/null)" ]]; then
      mount_args+=(-v "${proj_subdir}:/root/.claude/${subdir}")
    fi
  done

  # 项目级配置文件覆盖
  if [[ -f "${project_claude}/settings.json" ]]; then
    mount_args+=(-v "${project_claude}/settings.json:/root/.claude/settings.json:ro")
  fi
  
  if [[ -f "${project_claude}/.mcp.json" ]]; then
    mount_args+=(-v "${project_claude}/.mcp.json:/root/.claude/.mcp.json:ro")
  fi

  ocd_debug "启动容器: $container_name"
  docker run -it --rm \
    --name "$container_name" \
    --network host \
    --env-file "$env_file" \
    -e TERM=xterm-256color \
    -e "TZ=$tz" \
    -e BROWSER=/usr/bin/xdg-open \
    -e "EXA_API_KEY=${EXA_API_KEY:-}" \
    -e "OCD_START_DIR=${start_dir}" \
    -e "OCD_DEBUG=${OCD_DEBUG:-0}" \
    "${mount_args[@]}" \
    -w /workspace \
    "$image_name" "$@"
}
```

#### 4.2.3 `lib/config.sh` - `ocd_init_project()`

```bash
ocd_init_project() {
  local mode="${1:-full}"
  local project_dir="$PWD"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  local template_dir="$ocd_root/templates/project"
  
  # 检测是否为已有项目
  local is_existing=0
  [[ -d "$project_dir/.claude" || -d "$project_dir/.opencode" ]] && is_existing=1
  
  if [[ "$is_existing" -eq 1 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔄 同步项目配置（补全缺失项）"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📦 初始化项目配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
  echo ""
  
  # 1. Git 检查（仅新项目）
  if [[ "$is_existing" -eq 0 && ! -d "$project_dir/.git" ]]; then
    echo "⚠️  当前目录不是 Git 仓库"
    read -p "是否初始化 Git 仓库？[y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] && git init && echo "✅ Git 仓库已初始化"
    echo ""
  fi
  
  # 2. 创建/补全目录结构
  echo "检查目录结构："
  echo ""
  
  # .claude/ 目录
  _ocd_ensure_dir "$project_dir/.claude/commands"
  _ocd_ensure_dir "$project_dir/.claude/skills"
  _ocd_ensure_dir "$project_dir/.claude/agents"
  _ocd_ensure_dir "$project_dir/.claude/rules"
  
  # .opencode/ 目录
  _ocd_ensure_dir "$project_dir/.opencode/agent"
  _ocd_ensure_dir "$project_dir/.opencode/command"
  _ocd_ensure_dir "$project_dir/.opencode/skill"
  _ocd_ensure_dir "$project_dir/.opencode/plugin"
  
  # 3. 创建/补全配置文件
  echo ""
  echo "检查配置文件："
  echo ""
  
  _ocd_copy_if_not_exists "$template_dir/AGENTS.md.example" \
                         "$project_dir/AGENTS.md"
  
  if [[ "$mode" != "--minimal" ]]; then
    _ocd_copy_if_not_exists "$template_dir/opencode.json.example" \
                           "$project_dir/opencode.json"
    
    _ocd_copy_if_not_exists "$template_dir/.mcp.json.example" \
                           "$project_dir/.mcp.json"
    
    _ocd_copy_if_not_exists "$template_dir/.opencode/oh-my-opencode.json.example" \
                           "$project_dir/.opencode/oh-my-opencode.json"
    
    _ocd_copy_if_not_exists "$template_dir/.claude/settings.json.example" \
                           "$project_dir/.claude/settings.json"
  fi
  
  # 4. 更新 .gitignore
  _ocd_update_gitignore "$project_dir"
  
  # 5. 完成提示
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  [[ "$is_existing" -eq 1 ]] && echo "  ✅ 同步完成" || echo "  ✅ 初始化完成"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  _ocd_show_project_structure
}

# 确保目录存在（带反馈）
_ocd_ensure_dir() {
  local dir="$1"
  local rel_dir="${dir#$PWD/}"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    echo "  ✅ 创建: $rel_dir"
  else
    echo "  ⏭️  已存在: $rel_dir"
  fi
}

# 显示项目结构
_ocd_show_project_structure() {
  echo ""
  echo "  项目结构："
  echo ""
  echo "  .claude/                      # Claude Code 兼容层"
  echo "  ├── commands/                 # 项目级命令"
  echo "  ├── skills/                   # 项目级技能"
  echo "  ├── agents/                   # 项目级 agents"
  echo "  ├── rules/                    # 项目级规则"
  echo "  └── settings.json             # Claude Code hooks"
  echo ""
  echo "  .opencode/                    # OpenCode 原生配置"
  echo "  └── oh-my-opencode.json"
  echo ""
}

# 更新 .gitignore
_ocd_update_gitignore() {
  local project_dir="$1"
  [[ ! -d "$project_dir/.git" ]] && return 0
  
  local gitignore="$project_dir/.gitignore"
  local patterns=(
    "# OCD / oh-my-opencode"
    ".claude/settings.local.json"
    ".claude/*.local.*"
    ".opencode/*.local.*"
  )
  
  local added=0
  for pattern in "${patterns[@]}"; do
    if ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
      echo "$pattern" >> "$gitignore"
      added=1
    fi
  done
  
  [[ "$added" -eq 1 ]] && echo "  📝 更新 .gitignore"
}
```

#### 4.2.4 `bin/ocd` - 删除 `--merge-up`

删除以下代码块：
- 参数解析中的 `--merge-up) MERGE_UP=1; shift ;;`
- 帮助信息中的 `--merge-up` 说明
- `if [[ "$MERGE_UP" -eq 1 ]]; then ... fi` 整个分支

---

## 5. 迁移方案

### 5.1 迁移脚本

**文件**: `scripts/migrate-v5-global-claude.sh`

```bash
#!/bin/bash
# OCD v5 迁移：项目级 todos/transcripts → 全局 ~/.claude/
set -e

GLOBAL_CLAUDE="$HOME/.claude"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OCD v5 迁移：项目级 → 全局存储"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 确保全局目录存在
mkdir -p "$GLOBAL_CLAUDE"/{todos,transcripts,commands,skills,agents,rules}

# 统计
total_transcripts=0
total_todos=0
projects_processed=0

# 查找项目 .claude 目录
find_project_claude_dirs() {
  local search_paths=(
    "$HOME/projects"
    "$HOME/code"
    "$HOME/workspace"
    "$HOME/dev"
    "$HOME/opencode"
  )
  
  for base in "${search_paths[@]}"; do
    [[ -d "$base" ]] && find "$base" -maxdepth 4 -name ".claude" -type d 2>/dev/null
  done
}

echo "扫描项目..."
echo ""

for claude_dir in $(find_project_claude_dirs); do
  project_dir=$(dirname "$claude_dir")
  project_name=$(basename "$project_dir")
  local_changes=0
  
  # 迁移 transcripts
  if [[ -d "$claude_dir/transcripts" ]]; then
    count=$(find "$claude_dir/transcripts" -maxdepth 1 -name "*.jsonl" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "📦 $project_name: 迁移 $count 个 transcripts"
      mv "$claude_dir/transcripts"/*.jsonl "$GLOBAL_CLAUDE/transcripts/" 2>/dev/null || true
      total_transcripts=$((total_transcripts + count))
      local_changes=1
    fi
    rmdir "$claude_dir/transcripts" 2>/dev/null || true
  fi
  
  # 迁移 todos
  if [[ -d "$claude_dir/todos" ]]; then
    count=$(find "$claude_dir/todos" -maxdepth 1 -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "📦 $project_name: 迁移 $count 个 todos"
      mv "$claude_dir/todos"/*.json "$GLOBAL_CLAUDE/todos/" 2>/dev/null || true
      total_todos=$((total_todos + count))
      local_changes=1
    fi
    rmdir "$claude_dir/todos" 2>/dev/null || true
  fi
  
  # 补全项目 .claude 结构
  if [[ -d "$claude_dir" ]]; then
    mkdir -p "$claude_dir"/{commands,skills,agents,rules} 2>/dev/null || true
  fi
  
  [[ "$local_changes" -eq 1 ]] && projects_processed=$((projects_processed + 1))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 迁移完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  处理项目数: $projects_processed"
echo "  迁移 transcripts: $total_transcripts"
echo "  迁移 todos: $total_todos"
echo ""
echo "  全局目录: $GLOBAL_CLAUDE"
echo "  - transcripts: $(find "$GLOBAL_CLAUDE/transcripts" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ') 个"
echo "  - todos: $(find "$GLOBAL_CLAUDE/todos" -name "*.json" 2>/dev/null | wc -l | tr -d ' ') 个"
echo ""
```

### 5.2 迁移流程

```bash
# 1. 在 Mac 上运行迁移脚本（容器外）
~/opencode/scripts/migrate-v5-global-claude.sh

# 2. 更新 OCD 代码
cd ~/opencode && git pull

# 3. 重建镜像
ocd -r

# 4. 验证
ocd
# 在容器内检查：ls -la ~/.claude/
```

---

## 6. 挂载映射表（更新后）

| Mac Host | Docker Container | 说明 |
|----------|------------------|------|
| `~/.claude/` | `/root/.claude/` | 全局 Claude 兼容层 (基础) |
| `~/.claude/todos/` | `/root/.claude/todos/` | 全局 todos |
| `~/.claude/transcripts/` | `/root/.claude/transcripts/` | 全局 transcripts |
| `<project>/.claude/commands/` | `/root/.claude/commands/` | 项目级覆盖 (非空时) |
| `<project>/.claude/skills/` | `/root/.claude/skills/` | 项目级覆盖 (非空时) |
| `<project>/.claude/agents/` | `/root/.claude/agents/` | 项目级覆盖 (非空时) |
| `<project>/.claude/rules/` | `/root/.claude/rules/` | 项目级覆盖 (非空时) |
| `<project>/.claude/settings.json` | `/root/.claude/settings.json` | 项目级覆盖 (存在时) |
| `<project>/.claude/.mcp.json` | `/root/.claude/.mcp.json` | 项目级覆盖 (存在时) |

---

## 7. 兼容性

### 7.1 向后兼容

- 现有项目的 `.claude/` 配置目录继续工作
- 项目级 commands/skills/agents 覆盖逻辑不变
- 迁移脚本自动处理 todos/transcripts

### 7.2 Breaking Changes

- `--merge-up` 命令移除
- 项目级 todos/transcripts 不再支持（迁移到全局）

### 7.3 oh-my-opencode 版本兼容性

本方案已验证与以下版本兼容：

| 版本 | 状态 | 兼容性 |
|------|------|--------|
| v2.14.0+ (stable) | 生产可用 | ✅ 完全兼容 |
| v3.0.0-beta.x | Beta 测试 | ✅ 完全兼容 |

#### 7.3.1 存储路径兼容性

| 路径 | v2.x | v3.x | 说明 |
|------|------|------|------|
| `~/.claude/todos/` | ✅ | ✅ | 全局 todos |
| `~/.claude/transcripts/` | ✅ | ✅ | 全局 transcripts |
| `CLAUDE_CONFIG_DIR` 环境变量 | ✅ | ✅ | 支持自定义路径 |
| `getClaudeConfigDir()` | ✅ (v2.14.0+) | ✅ | 内部函数 |
| Claude Code 兼容层 | ✅ | ✅ | .claude/ 目录结构 |

#### 7.3.2 v2.x vs v3.x 主要差异（不影响本方案）

1. **工具 API 变化**（不影响存储）
   - v2.x: `background_task` 工具
   - v3.x: `sisyphus_task` 工具（参数重命名）

2. **新功能**（仅 v3.x）
   - Orchestrator 系统
   - 分类任务委派
   - 多账号 Google 认证

3. **配置变化**
   - v3.x 新增 `sisyphus_agent` 和 `categories` 配置节

#### 7.3.3 结论

**本 RFC 方案的存储架构与 oh-my-opencode v2.x 和 v3.x 均兼容**，用户可以自由选择使用稳定版 (v2.x) 或 Beta 版 (v3.x)。

---

## 8. 测试计划

### 8.1 单元测试

- [ ] `tests/bats/docker.bats` - 挂载逻辑测试
- [ ] `tests/bats/config.bats` - `ocd_init_project()` 测试

### 8.2 集成测试

- [ ] 新项目初始化
- [ ] 已有项目同步/补全
- [ ] 项目级配置覆盖
- [ ] transcripts/todos 全局存储验证
- [ ] 迁移脚本测试

---

## 9. Checklist

### 9.1 代码修改

- [ ] `lib/core.sh` - 新增 `OCD_CLAUDE_HOME`
- [ ] `lib/docker.sh` - 重构挂载逻辑
- [ ] `lib/config.sh` - 更新 `ocd_init_project()`
- [ ] `bin/ocd` - 删除 `--merge-up`
- [ ] `templates/project/.claude/rules/.gitkeep` - 新增

### 9.2 新增文件

- [ ] `scripts/migrate-v5-global-claude.sh`

### 9.3 文档更新

- [ ] `docs/MOUNT_MAPPING.md`
- [ ] `README.md`
- [ ] `CHANGELOG.md`

### 9.4 测试

- [ ] 更新 `tests/bats/docker.bats`
- [ ] 更新 `tests/bats/config.bats`
- [ ] 手动测试迁移流程

---

## 10. 决策记录

| 决策 | 理由 |
|------|------|
| todos/transcripts 改为全局 | 符合 oh-my-opencode 原设计，session ID 已包含项目关联 |
| 项目级 .claude/ 保留 | Claude Code 兼容层特性，支持项目级配置覆盖 |
| 删除 --merge-up | 不再需要，全局存储解决了跨项目问题 |
| 使用覆盖挂载而非环境变量 | 更直观，兼容性更好 |
| 支持 v2.x 和 v3.x | 存储路径在两个版本中一致，用户可自由选择版本 |
