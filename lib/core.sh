#!/usr/bin/env bash
# lib/core.sh - OCD 核心工具函数
# shellcheck disable=SC2034

OCD_ROOT="${OCD_ROOT:-$HOME/opencode}"

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
