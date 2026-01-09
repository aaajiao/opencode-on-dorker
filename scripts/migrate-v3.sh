#!/usr/bin/env bash
# scripts/migrate-v3.sh - 从 v2.x 迁移到 v3.0 的路径结构
#
# v2.0 → v3.0 路径变更:
#   ~/.opencode_data/<inst>/                    → ~/.local/state/opencode/instances/<inst>/
#   ~/.local/share/opencode/storage/<inst>/     → ~/.local/share/opencode/instances/<inst>/
#   ~/.config/opencode/<inst>/                  → ~/.config/opencode/instances/<inst>/
#   ~/opencode/global/                          → ~/.config/opencode/global/
#
# 不变的路径:
#   ~/.local/share/opencode/auth.json           (保持不变)
#   ~/.local/share/opencode/bin/                (保持不变)
#   ~/.local/state/opencode/                    (保持不变，共享状态)
#   ~/.cache/opencode/                          (保持不变)

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# v2.0 路径
V2_DATA_ROOT="$HOME/.opencode_data"
V2_STORAGE_ROOT="$HOME/.local/share/opencode/storage"
V2_CONFIG_ROOT="$HOME/.config/opencode"
V2_GLOBAL_ROOT="$HOME/opencode/global"

# v3.0 路径
V3_STATE_ROOT="$HOME/.local/state/opencode/instances"
V3_DATA_ROOT="$HOME/.local/share/opencode/instances"
V3_CONFIG_ROOT="$HOME/.config/opencode/instances"
V3_GLOBAL_ROOT="$HOME/.config/opencode/global"

# 检测是否需要迁移
needs_migration() {
  # 如果存在 v2.0 的实例目录结构，需要迁移
  # v2.0: ~/.config/opencode/<instance>/opencode.json (直接在根下)
  # v3.0: ~/.config/opencode/instances/<instance>/opencode.json

  # 检查是否有直接在 ~/.config/opencode/ 下的实例目录（非 instances/）
  local has_v2_config=0
  if [[ -d "$V2_CONFIG_ROOT" ]]; then
    for dir in "$V2_CONFIG_ROOT"/*/; do
      [[ ! -d "$dir" ]] && continue
      local name
      name=$(basename "$dir")
      # 跳过 v3.0 的 instances 目录和其他非实例目录
      [[ "$name" == "instances" || "$name" == "global" ]] && continue
      # 检查是否是实例目录（包含 opencode.json）
      if [[ -f "${dir}opencode.json" ]]; then
        has_v2_config=1
        break
      fi
    done
  fi

  # 检查是否有 v2.0 的 storage 目录
  local has_v2_storage=0
  [[ -d "$V2_STORAGE_ROOT" ]] && has_v2_storage=1

  # 检查是否有 v2.0 的 .opencode_data 目录
  local has_v2_data=0
  [[ -d "$V2_DATA_ROOT" ]] && has_v2_data=1

  # 检查是否有 v2.0 的 global 目录
  local has_v2_global=0
  [[ -d "$V2_GLOBAL_ROOT" && ! -d "$V3_GLOBAL_ROOT" ]] && has_v2_global=1

  [[ $has_v2_config -eq 1 || $has_v2_storage -eq 1 || $has_v2_data -eq 1 || $has_v2_global -eq 1 ]]
}

# 获取所有 v2.0 实例名
get_v2_instances() {
  local instances=()
  local name
  local found

  # 从 config 目录获取
  if [[ -d "$V2_CONFIG_ROOT" ]]; then
    for dir in "$V2_CONFIG_ROOT"/*/; do
      [[ ! -d "$dir" ]] && continue
      name=$(basename "$dir")
      [[ "$name" == "instances" || "$name" == "global" ]] && continue
      [[ -f "${dir}opencode.json" ]] && instances+=("$name")
    done
  fi

  # 从 storage 目录获取
  if [[ -d "$V2_STORAGE_ROOT" ]]; then
    for dir in "$V2_STORAGE_ROOT"/*/; do
      [[ ! -d "$dir" ]] && continue
      name=$(basename "$dir")
      # 检查是否已在列表中
      found=0
      for inst in "${instances[@]:-}"; do
        [[ "$inst" == "$name" ]] && found=1 && break
      done
      [[ $found -eq 0 ]] && instances+=("$name")
    done
  fi

  # 从 .opencode_data 目录获取
  if [[ -d "$V2_DATA_ROOT" ]]; then
    for dir in "$V2_DATA_ROOT"/*/; do
      [[ ! -d "$dir" ]] && continue
      name=$(basename "$dir")
      found=0
      for inst in "${instances[@]:-}"; do
        [[ "$inst" == "$name" ]] && found=1 && break
      done
      [[ $found -eq 0 ]] && instances+=("$name")
    done
  fi

  printf '%s\n' "${instances[@]:-}"
}

# 迁移单个实例
migrate_instance() {
  local inst="$1"
  echo ""
  echo "  迁移实例: $inst"

  # 1. 迁移配置 (~/.config/opencode/<inst>/ → ~/.config/opencode/instances/<inst>/)
  local v2_config="$V2_CONFIG_ROOT/$inst"
  local v3_config="$V3_CONFIG_ROOT/$inst"
  if [[ -d "$v2_config" && ! -d "$v3_config" ]]; then
    mkdir -p "$(dirname "$v3_config")"
    mv "$v2_config" "$v3_config"
    log_info "    配置: $v2_config → $v3_config"
  elif [[ -d "$v2_config" && -d "$v3_config" ]]; then
    log_warn "    配置: v3 目录已存在，跳过 (保留 v2 备份)"
  fi

  # 2. 迁移会话数据 (~/.local/share/opencode/storage/<inst>/ → ~/.local/share/opencode/instances/<inst>/)
  local v2_storage="$V2_STORAGE_ROOT/$inst"
  local v3_data="$V3_DATA_ROOT/$inst"
  if [[ -d "$v2_storage" && ! -d "$v3_data" ]]; then
    mkdir -p "$(dirname "$v3_data")"
    mv "$v2_storage" "$v3_data"
    log_info "    数据: $v2_storage → $v3_data"
  elif [[ -d "$v2_storage" && -d "$v3_data" ]]; then
    log_warn "    数据: v3 目录已存在，跳过 (保留 v2 备份)"
  fi

  # 3. 迁移 IPC 状态 (~/.opencode_data/<inst>/ → ~/.local/state/opencode/instances/<inst>/)
  local v2_data="$V2_DATA_ROOT/$inst"
  local v3_state="$V3_STATE_ROOT/$inst"
  if [[ -d "$v2_data" && ! -d "$v3_state" ]]; then
    mkdir -p "$(dirname "$v3_state")"
    mv "$v2_data" "$v3_state"
    log_info "    状态: $v2_data → $v3_state"
  elif [[ -d "$v2_data" && -d "$v3_state" ]]; then
    # IPC 文件是临时的，可以安全删除旧的
    rm -rf "$v2_data"
    log_info "    状态: 删除旧 IPC 文件 $v2_data"
  fi
}

# 迁移全局配置
migrate_global() {
  echo ""
  echo "  迁移全局配置..."

  if [[ ! -d "$V2_GLOBAL_ROOT" ]]; then
    log_info "    全局配置: 无需迁移 (v2 目录不存在)"
    return 0
  fi

  mkdir -p "$V3_GLOBAL_ROOT"

  # 合并 claude 目录（复数目录名：skills, commands, agents, rules）
  if [[ -d "$V2_GLOBAL_ROOT/claude" ]]; then
    local v2_claude="$V2_GLOBAL_ROOT/claude"
    local v3_claude="$V3_GLOBAL_ROOT/claude"
    mkdir -p "$v3_claude"

    for subdir in skills commands agents rules; do
      if [[ -d "$v2_claude/$subdir" ]]; then
        mkdir -p "$v3_claude/$subdir"
        # 复制不存在的文件（不覆盖）
        local count=0
        for file in "$v2_claude/$subdir"/*; do
          [[ ! -e "$file" ]] && continue
          local name
          name=$(basename "$file")
          if [[ ! -e "$v3_claude/$subdir/$name" ]]; then
            cp -r "$file" "$v3_claude/$subdir/"
            ((count++))
          fi
        done
        [[ $count -gt 0 ]] && log_info "    claude/$subdir: 合并 $count 个文件"
      fi
    done

    # 复制配置文件（不覆盖）
    for cfg in settings.json .mcp.json; do
      if [[ -f "$v2_claude/$cfg" && ! -f "$v3_claude/$cfg" ]]; then
        cp "$v2_claude/$cfg" "$v3_claude/"
        log_info "    claude/$cfg: 已复制"
      fi
    done
  fi

  # 合并 opencode 目录（单数目录名：skill, command, agent）
  if [[ -d "$V2_GLOBAL_ROOT/opencode" ]]; then
    local v2_opencode="$V2_GLOBAL_ROOT/opencode"
    local v3_opencode="$V3_GLOBAL_ROOT/opencode"
    mkdir -p "$v3_opencode"

    for subdir in skill command agent; do
      if [[ -d "$v2_opencode/$subdir" ]]; then
        mkdir -p "$v3_opencode/$subdir"
        local count=0
        for file in "$v2_opencode/$subdir"/*; do
          [[ ! -e "$file" ]] && continue
          local name
          name=$(basename "$file")
          if [[ ! -e "$v3_opencode/$subdir/$name" ]]; then
            cp -r "$file" "$v3_opencode/$subdir/"
            ((count++))
          fi
        done
        [[ $count -gt 0 ]] && log_info "    opencode/$subdir: 合并 $count 个文件"
      fi
    done
  fi

  log_info "    全局配置迁移完成"
  log_info "    原位置保留作为备份: $V2_GLOBAL_ROOT"
}

# 清理空的 v2 目录
cleanup_v2_dirs() {
  echo ""
  echo "清理旧目录..."

  # 清理空的 storage 目录
  if [[ -d "$V2_STORAGE_ROOT" ]]; then
    rmdir "$V2_STORAGE_ROOT" 2>/dev/null && log_info "  删除空目录: $V2_STORAGE_ROOT" || true
  fi

  # 清理空的 .opencode_data 目录
  if [[ -d "$V2_DATA_ROOT" ]]; then
    rmdir "$V2_DATA_ROOT" 2>/dev/null && log_info "  删除空目录: $V2_DATA_ROOT" || true
  fi
}

# 主函数
main() {
  echo "═══════════════════════════════════════════════════════"
  echo "  OCD v2.x → v3.0 迁移工具"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  # 检测是否需要迁移
  if ! needs_migration; then
    log_info "无需迁移 - 未检测到 v2.x 数据结构"
    echo ""
    echo "如果这是首次安装，将自动使用 v3.0 结构。"
    return 0
  fi

  echo "检测到 v2.x 数据结构，准备迁移..."
  echo ""
  echo "路径变更:"
  echo "  ~/.opencode_data/<inst>/                  → ~/.local/state/opencode/instances/<inst>/"
  echo "  ~/.local/share/opencode/storage/<inst>/   → ~/.local/share/opencode/instances/<inst>/"
  echo "  ~/.config/opencode/<inst>/                → ~/.config/opencode/instances/<inst>/"
  echo "  ~/opencode/global/                        → ~/.config/opencode/global/"
  echo ""
  echo "保持不变:"
  echo "  ~/.local/share/opencode/auth.json         (认证令牌)"
  echo ""

  # 获取所有实例
  local instances
  instances=$(get_v2_instances)

  if [[ -z "$instances" ]]; then
    log_warn "未找到任何实例数据"
    return 0
  fi

  echo "发现以下实例:"
  for inst in $instances; do
    echo "  • $inst"
  done
  echo ""

  # 确认迁移
  read -r -p "是否开始迁移? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消"
    return 0
  fi

  echo ""
  echo "开始迁移..."

  # 创建 v3 目录结构
  mkdir -p "$V3_STATE_ROOT" "$V3_DATA_ROOT" "$V3_CONFIG_ROOT"

  # 迁移每个实例
  for inst in $instances; do
    migrate_instance "$inst"
  done

  # 迁移全局配置
  migrate_global

  # 清理空目录
  cleanup_v2_dirs

  echo ""
  echo "═══════════════════════════════════════════════════════"
  log_info "迁移完成!"
  echo ""
  echo "重要提示:"
  echo "  • auth.json 保持原位置，无需操作"
  echo "  • 如有问题，旧数据可能保留在原位置作为备份"
  echo "  • 建议运行 'ocd -r' 重建镜像以确保兼容性"
  echo "═══════════════════════════════════════════════════════"
}

# 自动迁移函数（供 ocd 调用，静默模式）
auto_migrate() {
  if ! needs_migration; then
    return 0
  fi

  echo "检测到 v2.x 数据，自动迁移中..."

  local instances
  instances=$(get_v2_instances)

  mkdir -p "$V3_STATE_ROOT" "$V3_DATA_ROOT" "$V3_CONFIG_ROOT"

  # 迁移实例
  if [[ -n "$instances" ]]; then
    for inst in $instances; do
      migrate_instance "$inst"
    done
  fi

  # 迁移全局配置
  migrate_global

  cleanup_v2_dirs

  log_info "迁移完成"
  echo ""
}

# 检查是否直接运行还是被 source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
