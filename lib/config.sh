#!/usr/bin/env bash
# lib/config.sh - v5 配置管理模块
# 
# v5 设计原则：
# - 配置文件首次创建后由用户管理，OCD 不再覆盖
# - 每次启动只更新端口
# - 可选：models.conf 覆盖模型设置

# =========================================
# 模型配置变量
# =========================================
MAIN_MODEL="${MAIN_MODEL:-}"
PLANNER_MODEL="${PLANNER_MODEL:-}"
ORACLE_MODEL="${ORACLE_MODEL:-}"
DOCUMENT_WRITER_MODEL="${DOCUMENT_WRITER_MODEL:-}"
FRONTEND_MODEL="${FRONTEND_MODEL:-}"
MULTIMODAL_MODEL="${MULTIMODAL_MODEL:-}"

# =========================================
# 加载模型配置 (可选)
# =========================================
ocd_load_models() {
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  local models_file=""

  # 只使用用户创建的 models.conf
  if [[ -f "$ocd_root/models.conf" ]]; then
    models_file="$ocd_root/models.conf"
  fi

  # 从配置文件加载（如果存在）
  if [[ -n "$models_file" && -f "$models_file" ]]; then
    eval "$(grep -E '^[A-Z_]+=.+' "$models_file" 2>/dev/null | grep -v '^#')" 2>/dev/null || true
  fi

  # 对未设置的变量应用硬编码默认值（兜底）
  MAIN_MODEL="${MAIN_MODEL:-anthropic/claude-sonnet-4-5}"
  PLANNER_MODEL="${PLANNER_MODEL:-anthropic/claude-opus-4-5}"
}

# =========================================
# 从模板创建配置文件
# =========================================
# 替换 {{VAR}} 格式的占位符
ocd_create_config_from_template() {
  local template="$1"
  local output="$2"
  
  local content
  content=$(cat "$template")
  
  # 替换 {{OH_MY_OPENCODE_VERSION}}
  content="${content//\{\{OH_MY_OPENCODE_VERSION\}\}/${OH_MY_OPENCODE_VERSION:-latest}}"
  
  echo "$content" > "$output"
}

# =========================================
# 确保全局配置存在
# =========================================
# 首次运行时创建，之后不再覆盖
ocd_ensure_global_config() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  local created=0
  
  # 创建目录结构
  mkdir -p "$config_dir"/{agent,command,skill,themes}
  
  # opencode.json（从模板创建，替换版本占位符）
  if [[ ! -f "$config_dir/opencode.json" ]]; then
    if [[ -f "$ocd_root/templates/global/opencode.json.tmpl" ]]; then
      ocd_create_config_from_template \
        "$ocd_root/templates/global/opencode.json.tmpl" \
        "$config_dir/opencode.json"
      ocd_info "已创建 $config_dir/opencode.json"
      created=1
    fi
  fi
  
  # oh-my-opencode.json（直接复制）
  if [[ ! -f "$config_dir/oh-my-opencode.json" ]]; then
    if [[ -f "$ocd_root/templates/global/oh-my-opencode.json" ]]; then
      cp "$ocd_root/templates/global/oh-my-opencode.json" \
         "$config_dir/oh-my-opencode.json"
      ocd_info "已创建 $config_dir/oh-my-opencode.json"
      created=1
    fi
  fi
  
  return $created
}

# =========================================
# 更新配置端口（每次启动）
# =========================================
ocd_update_port() {
  local config_file="$1"
  local port="$2"

  [[ ! -f "$config_file" ]] && return 1

  if command -v jq &>/dev/null; then
    local tmp_file
    tmp_file=$(mktemp)
    if jq --argjson port "$port" '.server.port = $port' "$config_file" > "$tmp_file"; then
      mv "$tmp_file" "$config_file"
    else
      rm -f "$tmp_file"
      return 1
    fi
  else
    sed -i.bak -E "s|(\"port\":[[:space:]]*)([0-9]+)|\1${port}|g" "$config_file"
    rm -f "${config_file}.bak"
  fi
}

# =========================================
# 应用 models.conf 覆盖（可选，每次启动）
# =========================================
ocd_apply_models_conf() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local opencode_json="$config_dir/opencode.json"
  local omo_json="$config_dir/oh-my-opencode.json"
  
  # 加载 models.conf（如果存在）
  ocd_load_models
  
  # 更新 opencode.json 的 model 字段
  if [[ -n "$MAIN_MODEL" && -f "$opencode_json" ]]; then
    ocd_update_config_model "$opencode_json" "$MAIN_MODEL"
  fi
  
  # 更新 oh-my-opencode.json 的 agents
  if [[ -f "$omo_json" ]]; then
    ocd_update_omo_agents "$omo_json"
  fi
}

# =========================================
# 更新配置模型 (opencode.json)
# =========================================
ocd_update_config_model() {
  local config_file="$1"
  local model="$2"

  [[ -z "$model" ]] && return 0

  if command -v jq &>/dev/null; then
    local tmp_file
    tmp_file=$(mktemp)
    if jq --arg model "$model" '.model = $model' "$config_file" > "$tmp_file"; then
      mv "$tmp_file" "$config_file"
    else
      rm -f "$tmp_file"
    fi
  else
    sed -i.bak -E "s|(\"model\":[[:space:]]*\")[^\"]+(\")|\1${model}\2|g" "$config_file"
    rm -f "${config_file}.bak"
  fi
}

# =========================================
# 更新 Agent 模型 (oh-my-opencode.json)
# =========================================
ocd_update_omo_agents() {
  local config_file="$1"

  [[ ! -f "$config_file" ]] && return 0

  # 需要 jq 才能更新
  if ! command -v jq &>/dev/null; then
    return 0
  fi

  local tmp_file
  tmp_file=$(mktemp)

  # 构建 jq 更新命令
  local jq_cmd=". "

  # 条件更新 agents
  [[ -n "$PLANNER_MODEL" ]] && jq_cmd+="| .agents.\"Sisyphus\".model = \"$PLANNER_MODEL\" "
  [[ -n "$ORACLE_MODEL" ]] && jq_cmd+="| .agents.oracle.model = \"$ORACLE_MODEL\" "
  [[ -n "$DOCUMENT_WRITER_MODEL" ]] && jq_cmd+="| .agents.\"document-writer\".model = \"$DOCUMENT_WRITER_MODEL\" "
  [[ -n "$FRONTEND_MODEL" ]] && jq_cmd+="| .agents.\"frontend-ui-ux-engineer\".model = \"$FRONTEND_MODEL\" "
  [[ -n "$MULTIMODAL_MODEL" ]] && jq_cmd+="| .agents.\"multimodal-looker\".model = \"$MULTIMODAL_MODEL\" "

  if jq "$jq_cmd" "$config_file" > "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$config_file"
  else
    rm -f "$tmp_file"
  fi
}

# =========================================
# 重置全局配置（--clean）
# =========================================
ocd_reset_global_config() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local backup_dir="$config_dir/.backup-$(date +%Y%m%d-%H%M%S)"
  
  # 备份现有配置
  if [[ -f "$config_dir/opencode.json" || -f "$config_dir/oh-my-opencode.json" ]]; then
    mkdir -p "$backup_dir"
    [[ -f "$config_dir/opencode.json" ]] && mv "$config_dir/opencode.json" "$backup_dir/"
    [[ -f "$config_dir/oh-my-opencode.json" ]] && mv "$config_dir/oh-my-opencode.json" "$backup_dir/"
    ocd_info "已备份配置到 $backup_dir"
  fi
  
  # 删除迁移标记（如果有）
  rm -f "$config_dir/.ocd-v5-migrated"
  rm -f "$config_dir/.ocd-v5-init"
  
  # 重新创建
  ocd_ensure_global_config
  ocd_info "已重置全局配置"
}

# =========================================
# 初始化项目配置 (ocd init)
# =========================================
ocd_init_project() {
  local mode="${1:-full}"
  local project_dir="$PWD"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  local template_dir="$ocd_root/templates/project"
  
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
  _ocd_copy_if_not_exists "$template_dir/AGENTS.md.example" \
                         "$project_dir/AGENTS.md"
  
  if [[ "$mode" != "--minimal" ]]; then
    # OpenCode 配置
    _ocd_copy_if_not_exists "$template_dir/opencode.json.example" \
                           "$project_dir/opencode.json"
    
    # 项目 MCP
    _ocd_copy_if_not_exists "$template_dir/.mcp.json.example" \
                           "$project_dir/.mcp.json"
    
    # .opencode/ 目录
    mkdir -p "$project_dir/.opencode"/{agent,command,skill,plugin}
    _ocd_copy_if_not_exists "$template_dir/.opencode/oh-my-opencode.json.example" \
                           "$project_dir/.opencode/oh-my-opencode.json"
    
    # .claude/ 目录
    mkdir -p "$project_dir/.claude"/{agents,commands,skills}
    _ocd_copy_if_not_exists "$template_dir/.claude/settings.json.example" \
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

# =========================================
# 辅助函数：如果目标不存在则复制
# =========================================
_ocd_copy_if_not_exists() {
  local src="$1"
  local dst="$2"
  
  if [[ ! -f "$dst" ]]; then
    if [[ -f "$src" ]]; then
      cp "$src" "$dst"
      echo "  ✅ 创建: $dst"
    else
      echo "  ⚠️  模板不存在: $src"
    fi
  else
    echo "  ⏭️  已存在: $dst"
  fi
}

# =========================================
# 显示配置信息 (ocd config)
# =========================================
ocd_show_config() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  📁 OCD 配置路径"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  OCD 安装目录:"
  echo "    $ocd_root"
  echo ""
  echo "  全局配置目录:"
  echo "    $config_dir"
  echo ""
  echo "  配置文件:"
  [[ -f "$config_dir/opencode.json" ]] && echo "    ✅ opencode.json" || echo "    ❌ opencode.json (未创建)"
  [[ -f "$config_dir/oh-my-opencode.json" ]] && echo "    ✅ oh-my-opencode.json" || echo "    ❌ oh-my-opencode.json (未创建)"
  echo ""
  echo "  可选配置:"
  [[ -f "$ocd_root/.env" ]] && echo "    ✅ .env" || echo "    ❌ .env (必需)"
  [[ -f "$ocd_root/models.conf" ]] && echo "    ✅ models.conf" || echo "    ⬜ models.conf (可选)"
  echo ""
  
  # 显示 Claude 目录状态
  if [[ -d "$HOME/.claude" ]]; then
    echo "  Claude Code 目录:"
    echo "    ✅ ~/.claude (将挂载到容器)"
  fi
  echo ""
}

# =========================================
# 编辑配置文件 (ocd config edit)
# =========================================
ocd_edit_config() {
  local target="${1:-opencode}"
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local file=""
  
  case "$target" in
    opencode|main)
      file="$config_dir/opencode.json"
      ;;
    plugin|omo|oh-my-opencode)
      file="$config_dir/oh-my-opencode.json"
      ;;
    *)
      echo "❌ 未知配置: $target"
      echo "   可用: opencode, plugin"
      return 1
      ;;
  esac
  
  if [[ ! -f "$file" ]]; then
    echo "❌ 配置文件不存在: $file"
    echo "   运行 ocd 首次创建配置"
    return 1
  fi
  
  ${EDITOR:-nano} "$file"
}

# =========================================
# 初始化全局目录（兼容旧版调用）
# =========================================
ocd_init_global() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  mkdir -p "$config_dir"/{skill,command,agent}
  return 0
}

# =========================================
# 显示首次运行欢迎信息
# =========================================
ocd_show_welcome_if_first_run() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local marker="$config_dir/.ocd-v5-init"
  
  [[ -f "$marker" ]] && return 0
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🎉 欢迎使用 OCD v5"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  配置文件位置："
  echo "    $config_dir/opencode.json"
  echo "    $config_dir/oh-my-opencode.json"
  echo ""
  echo "  从 v5 开始，这些配置由你管理。"
  echo "  OCD 只会在每次启动时更新端口。"
  echo ""
  echo "  快速切换模型：创建 ~/opencode/models.conf"
  echo "  初始化项目：ocd init"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  touch "$marker"
}
