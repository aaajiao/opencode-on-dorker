#!/usr/bin/env bash
# scripts/migrate-v6-plural-dirs.sh
# v6 迁移：单数目录 → 复数目录 (skill/ → skills/, agent/ → agents/, etc.)
set -euo pipefail

# =========================================
# 加载核心函数
# =========================================
OCD_ROOT="${OCD_ROOT:-$HOME/opencode}"
# shellcheck disable=SC1091
source "$OCD_ROOT/lib/core.sh" 2>/dev/null || {
  echo "❌ 无法加载 lib/core.sh"
  exit 1
}

# =========================================
# 配置
# =========================================
GLOBAL_CONFIG="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
BACKUP_DIR=".backup-singular-v5"
MARKER_FILE="$GLOBAL_CONFIG/.plural-dirs-migrated"
PROJECT_DIR="${1:-$(pwd)}"

# 需要迁移的目录映射 (单数 → 复数)
# 用普通数组兼容 macOS 自带的 bash 3.2
SINGULAR_DIRS=("skill" "agent" "command" "plugin")
PLURAL_DIRS=("skills" "agents" "commands" "plugins")

# =========================================
# 迁移单个目录
# =========================================
migrate_directory() {
  local base_dir="$1"
  local singular="$2"
  local plural="$3"
  local singular_path="$base_dir/$singular"
  local plural_path="$base_dir/$plural"
  local backup_path="$base_dir/$BACKUP_DIR/$singular"
  
  # 如果单数目录不存在，跳过
  [[ ! -d "$singular_path" ]] && return 0
  
  # 创建备份目录
  mkdir -p "$base_dir/$BACKUP_DIR"
  
  # 备份单数目录
  ocd_info "备份 $singular_path → $backup_path"
  cp -r "$singular_path" "$backup_path"
  
  # 处理冲突：如果复数目录已存在，合并内容
  if [[ -d "$plural_path" ]]; then
    ocd_info "合并 $singular/ → $plural/ (复数目录已存在)"
    
    # 复制所有文件到复数目录
    local file
    while IFS= read -r -d '' file; do
      local relative_path="${file#$singular_path/}"
      local target_file="$plural_path/$relative_path"
      
      # 如果目标文件已存在，跳过（保留复数目录中的版本）
      if [[ -f "$target_file" ]]; then
        ocd_info "  跳过 $relative_path (已存在)"
      else
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
        ocd_info "  复制 $relative_path"
      fi
    done < <(find "$singular_path" -type f -print0)
  else
    # 直接重命名
    ocd_info "重命名 $singular/ → $plural/"
    mv "$singular_path" "$plural_path"
  fi
  
  # 删除单数目录（已备份）
  if [[ -d "$singular_path" ]]; then
    rm -rf "$singular_path"
  fi
}

# =========================================
# 迁移全局配置
# =========================================
migrate_global_config() {
  ocd_log ""
  ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ocd_log "  迁移全局配置: $GLOBAL_CONFIG"
  ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local migrated=0
  local i
  
  for i in "${!SINGULAR_DIRS[@]}"; do
    local singular="${SINGULAR_DIRS[$i]}"
    local plural="${PLURAL_DIRS[$i]}"
    if [[ -d "$GLOBAL_CONFIG/$singular" ]]; then
      migrate_directory "$GLOBAL_CONFIG" "$singular" "$plural"
      migrated=1
    fi
  done
  
  if [[ $migrated -eq 0 ]]; then
    ocd_info "无需迁移（未发现单数目录）"
  fi
}

# =========================================
# 迁移项目配置
# =========================================
migrate_project_config() {
  [[ ! -d "$PROJECT_DIR/.opencode" ]] && return 0
  
  ocd_log ""
  ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ocd_log "  迁移项目配置: $PROJECT_DIR/.opencode"
  ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local migrated=0
  local i
  
  for i in "${!SINGULAR_DIRS[@]}"; do
    local singular="${SINGULAR_DIRS[$i]}"
    local plural="${PLURAL_DIRS[$i]}"
    if [[ -d "$PROJECT_DIR/.opencode/$singular" ]]; then
      migrate_directory "$PROJECT_DIR/.opencode" "$singular" "$plural"
      migrated=1
    fi
  done
  
  if [[ $migrated -eq 0 ]]; then
    ocd_info "无需迁移（未发现单数目录）"
  fi
}

# =========================================
# 主函数
# =========================================
check_global_needs_migration() {
  local i
  for i in "${!SINGULAR_DIRS[@]}"; do
    local singular="${SINGULAR_DIRS[$i]}"
    if [[ -d "$GLOBAL_CONFIG/$singular" ]]; then
      return 0
    fi
  done
  return 1
}

check_project_needs_migration() {
  [[ ! -d "$PROJECT_DIR/.opencode" ]] && return 1
  local i
  for i in "${!SINGULAR_DIRS[@]}"; do
    local singular="${SINGULAR_DIRS[$i]}"
    if [[ -d "$PROJECT_DIR/.opencode/$singular" ]]; then
      return 0
    fi
  done
  return 1
}

main() {
  local did_migrate=0
  
  # 全局迁移（只做一次，用标记文件）
  if [[ ! -f "$MARKER_FILE" ]] && check_global_needs_migration; then
    ocd_log ""
    ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ocd_log "  OCD v6 迁移：单数 → 复数目录"
    ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    migrate_global_config
    mkdir -p "$GLOBAL_CONFIG"
    touch "$MARKER_FILE"
    did_migrate=1
  fi
  
  # 项目迁移（每次都检查，因为可能是新项目）
  if check_project_needs_migration; then
    ocd_log ""
    ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ocd_log "  OCD v6 迁移：项目目录"
    ocd_log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    migrate_project_config
    did_migrate=1
  fi
  
  if [[ "$did_migrate" -eq 1 ]]; then
    ocd_log ""
    ocd_success "迁移完成"
    [[ -d "$GLOBAL_CONFIG/$BACKUP_DIR" ]] && ocd_info "全局备份: $GLOBAL_CONFIG/$BACKUP_DIR/"
    [[ -d "$PROJECT_DIR/.opencode/$BACKUP_DIR" ]] && ocd_info "项目备份: $PROJECT_DIR/.opencode/$BACKUP_DIR/"
    ocd_log ""
  fi
  
  # 确保全局标记存在
  mkdir -p "$GLOBAL_CONFIG"
  touch "$MARKER_FILE"
}

main "$@"
