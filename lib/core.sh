#!/usr/bin/env bash
# lib/core.sh - OCD 核心工具函数
# shellcheck disable=SC2034

OCD_ROOT="${OCD_ROOT:-$HOME/opencode}"

# =========================================
# XDG 标准路径定义 (v3.0)
# =========================================
# 配置目录 - 可版本控制
OCD_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
OCD_CONFIG_INSTANCES="$OCD_CONFIG_HOME/instances"
OCD_CONFIG_GLOBAL="$OCD_CONFIG_HOME/global"

# 数据目录 - 必须备份
OCD_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/opencode"
OCD_DATA_INSTANCES="$OCD_DATA_HOME/instances"

# 状态目录 - 可重建
OCD_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
OCD_STATE_INSTANCES="$OCD_STATE_HOME/instances"

# 缓存目录 - 可删除
OCD_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"

# =========================================
# 实例路径获取函数
# =========================================
ocd_instance_config_dir() {
  echo "$OCD_CONFIG_INSTANCES/${1:-opencode}"
}

ocd_instance_data_dir() {
  echo "$OCD_DATA_INSTANCES/${1:-opencode}"
}

ocd_instance_state_dir() {
  echo "$OCD_STATE_INSTANCES/${1:-opencode}"
}

# =========================================
# 自动迁移 v2.x → v3.0
# =========================================
ocd_auto_migrate() {
  local migrate_script="$OCD_ROOT/scripts/migrate-v3.sh"
  [[ ! -f "$migrate_script" ]] && return 0

  # 检测 v2.x 结构
  local v2_data="$HOME/.opencode_data"
  local v2_storage="$OCD_DATA_HOME/storage"

  if [[ -d "$v2_data" || -d "$v2_storage" ]]; then
    # source 迁移脚本并执行自动迁移
    # shellcheck disable=SC1090
    source "$migrate_script"
    auto_migrate
  fi
}

# =========================================
# 版本管理
# =========================================
ocd_version() {
  local version_file="$OCD_ROOT/VERSION"
  [[ -f "$version_file" ]] && cat "$version_file" || echo "unknown"
}

ocd_load_versions() {
  local versions_file="$OCD_ROOT/versions.lock"
  [[ ! -f "$versions_file" ]] && return 0

  local key value line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [[ -n "$value" ]] && export "$key=$value"
  done < "$versions_file"
}

# =========================================
# 调试模式（通过 --debug 参数启用）
# =========================================
OCD_DEBUG="${OCD_DEBUG:-0}"

ocd_debug() {
  [[ "$OCD_DEBUG" == "1" ]] && echo "[debug] $*" >&2
}

# =========================================
# 日志输出
# =========================================
ocd_log() {
  echo "$*"
}

ocd_error() {
  echo "❌ $*" >&2
  return 1
}

ocd_info() {
  echo "ℹ️  $*"
}

ocd_success() {
  echo "✅ $*"
}

# =========================================
# 字符串处理
# =========================================
ocd_sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_'
}

# =========================================
# 环境变量安全加载
# =========================================
ocd_load_env() {
  local env_file="$1"
  [[ ! -f "$env_file" ]] && return 0

  local key value line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过注释和空行
    [[ -z "$line" || "$line" == \#* ]] && continue
    # 拒绝危险字符（防止命令注入）
    [[ "$line" == *[\;\$\(\)\"\']* ]] && continue
    # 提取 KEY=VALUE
    key="${line%%=*}"
    value="${line#*=}"
    # 验证 key 格式
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [[ -n "$value" ]] && export "$key=$value"
  done < "$env_file"
}

# =========================================
# 依赖检查
# =========================================
ocd_check_dependencies() {
  local hint_file="$HOME/.config/opencode/.deps-hint-shown"
  [[ -f "$hint_file" ]] && return 0

  local missing=()
  command -v jq &>/dev/null || missing+=("jq (智能配置更新)")
  command -v fswatch &>/dev/null || missing+=("fswatch (降低 CPU 占用)")
  command -v terminal-notifier &>/dev/null || missing+=("terminal-notifier (自定义通知图标)")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "💡 可选依赖（安装后体验更好）:"
    for dep in "${missing[@]}"; do
      echo "   • $dep"
    done
    echo ""
    echo "   一键安装: brew install jq fswatch terminal-notifier"
    echo ""
  fi

  mkdir -p "$(dirname "$hint_file")"
  touch "$hint_file"
}
