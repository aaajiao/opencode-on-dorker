#!/usr/bin/env bash
# scripts/migrate-v4.sh - 从 v3.x 迁移到 v4.0
#
# v3.0 → v4.0 路径变更:
#   ~/.config/opencode/instances/<inst>/    → ~/.config/opencode/ (合并)
#   ~/.local/share/opencode/instances/      → ~/.local/share/opencode/storage/ (合并)
#   ~/.local/state/opencode/instances/      → ~/.local/state/opencode/ipc/<port>/ (按端口)
#
# v4.0 核心变化: 去掉 instance 概念，让 OpenCode 原生管理 session (by git SHA)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

V3_CONFIG_INSTANCES="$HOME/.config/opencode/instances"
V3_DATA_INSTANCES="$HOME/.local/share/opencode/instances"
V3_STATE_INSTANCES="$HOME/.local/state/opencode/instances"

V4_CONFIG="$HOME/.config/opencode"
V4_DATA="$HOME/.local/share/opencode"
V4_STATE="$HOME/.local/state/opencode"

needs_migration() {
  [[ -d "$V3_CONFIG_INSTANCES" ]] || [[ -d "$V3_DATA_INSTANCES" ]]
}

get_v3_instances() {
  local instances=()
  local name

  if [[ -d "$V3_CONFIG_INSTANCES" ]]; then
    for dir in "$V3_CONFIG_INSTANCES"/*/; do
      [[ ! -d "$dir" ]] && continue
      name=$(basename "$dir")
      instances+=("$name")
    done
  fi

  if [[ -d "$V3_DATA_INSTANCES" ]]; then
    for dir in "$V3_DATA_INSTANCES"/*/; do
      [[ ! -d "$dir" ]] && continue
      name=$(basename "$dir")
      local found=0
      for inst in "${instances[@]:-}"; do
        [[ "$inst" == "$name" ]] && found=1 && break
      done
      [[ $found -eq 0 ]] && instances+=("$name")
    done
  fi

  printf '%s\n' "${instances[@]:-}"
}

migrate_config() {
  echo "  迁移配置文件..."
  
  local latest_config=""
  local latest_time=0
  
  for dir in "$V3_CONFIG_INSTANCES"/*/; do
    [[ ! -d "$dir" ]] && continue
    local cfg="${dir}opencode.json"
    [[ ! -f "$cfg" ]] && continue
    
    local mtime
    mtime=$(stat -f %m "$cfg" 2>/dev/null || stat -c %Y "$cfg" 2>/dev/null || echo 0)
    if [[ $mtime -gt $latest_time ]]; then
      latest_time=$mtime
      latest_config="$cfg"
    fi
  done
  
  if [[ -n "$latest_config" && ! -f "$V4_CONFIG/opencode.json" ]]; then
    cp "$latest_config" "$V4_CONFIG/opencode.json"
    log_info "    opencode.json: 使用最新配置 ($(dirname "$latest_config" | xargs basename))"
  fi
  
  latest_config=""
  latest_time=0
  for dir in "$V3_CONFIG_INSTANCES"/*/; do
    [[ ! -d "$dir" ]] && continue
    local cfg="${dir}oh-my-opencode.json"
    [[ ! -f "$cfg" ]] && continue
    
    local mtime
    mtime=$(stat -f %m "$cfg" 2>/dev/null || stat -c %Y "$cfg" 2>/dev/null || echo 0)
    if [[ $mtime -gt $latest_time ]]; then
      latest_time=$mtime
      latest_config="$cfg"
    fi
  done
  
  if [[ -n "$latest_config" && ! -f "$V4_CONFIG/oh-my-opencode.json" ]]; then
    cp "$latest_config" "$V4_CONFIG/oh-my-opencode.json"
    log_info "    oh-my-opencode.json: 使用最新配置"
  fi
}

migrate_storage() {
  echo "  迁移会话数据..."
  
  mkdir -p "$V4_DATA/storage"
  
  for inst_dir in "$V3_DATA_INSTANCES"/*/; do
    [[ ! -d "$inst_dir" ]] && continue
    local inst
    inst=$(basename "$inst_dir")
    
    for subdir in session message part project session_diff todo; do
      local src="${inst_dir}${subdir}"
      local dst="$V4_DATA/storage/${subdir}"
      
      [[ ! -d "$src" ]] && continue
      mkdir -p "$dst"
      
      local count=0
      for item in "$src"/*; do
        [[ ! -e "$item" ]] && continue
        local name
        name=$(basename "$item")
        if [[ ! -e "$dst/$name" ]]; then
          cp -r "$item" "$dst/"
          ((count++))
        fi
      done
      [[ $count -gt 0 ]] && log_info "    $inst/$subdir: 合并 $count 项"
    done
  done
}

cleanup_v3_dirs() {
  echo ""
  echo "清理旧目录..."
  
  if [[ -d "$V3_CONFIG_INSTANCES" ]]; then
    local backup
    backup="$V3_CONFIG_INSTANCES.bak.$(date +%Y%m%d)"
    mv "$V3_CONFIG_INSTANCES" "$backup"
    log_info "  备份: $V3_CONFIG_INSTANCES → $backup"
  fi
  
  if [[ -d "$V3_DATA_INSTANCES" ]]; then
    local backup
    backup="$V3_DATA_INSTANCES.bak.$(date +%Y%m%d)"
    mv "$V3_DATA_INSTANCES" "$backup"
    log_info "  备份: $V3_DATA_INSTANCES → $backup"
  fi
  
  if [[ -d "$V3_STATE_INSTANCES" ]]; then
    rm -rf "$V3_STATE_INSTANCES"
    log_info "  删除: $V3_STATE_INSTANCES (IPC 文件可重建)"
  fi
}

main() {
  echo "═══════════════════════════════════════════════════════"
  echo "  OCD v3.x → v4.0 迁移工具"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  if ! needs_migration; then
    log_info "无需迁移 - 未检测到 v3.x instance 数据结构"
    return 0
  fi

  echo "检测到 v3.x instance 数据结构，准备迁移..."
  echo ""
  echo "v4.0 核心变化:"
  echo "  • 去掉 instance 概念"
  echo "  • 配置文件合并到 ~/.config/opencode/"
  echo "  • Session 数据合并到 ~/.local/share/opencode/storage/"
  echo "  • 让 OpenCode 原生管理 session (by git SHA)"
  echo ""

  local instances
  instances=$(get_v3_instances)

  if [[ -z "$instances" ]]; then
    log_warn "未找到任何 instance 数据"
    return 0
  fi

  echo "发现以下 instance:"
  for inst in $instances; do
    echo "  • $inst"
  done
  echo ""

  read -r -p "是否开始迁移? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消"
    return 0
  fi

  echo ""
  echo "开始迁移..."

  mkdir -p "$V4_CONFIG" "$V4_DATA/storage" "$V4_STATE/ipc"

  migrate_config
  migrate_storage
  cleanup_v3_dirs

  echo ""
  echo "═══════════════════════════════════════════════════════"
  log_info "迁移完成!"
  echo ""
  echo "重要提示:"
  echo "  • 旧数据已备份到 *.bak.$(date +%Y%m%d) 目录"
  echo "  • Session 已合并，OpenCode 将按 git SHA 管理"
  echo "  • 建议运行 'ocd -r' 重建镜像"
  echo "═══════════════════════════════════════════════════════"
}

auto_migrate() {
  if ! needs_migration; then
    return 0
  fi

  echo "检测到 v3.x instance 数据，自动迁移中..."

  mkdir -p "$V4_CONFIG" "$V4_DATA/storage" "$V4_STATE/ipc"

  migrate_config
  migrate_storage
  
  if [[ -d "$V3_STATE_INSTANCES" ]]; then
    rm -rf "$V3_STATE_INSTANCES"
  fi

  log_info "迁移完成 (旧 instance 目录保留作为备份)"
  echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
