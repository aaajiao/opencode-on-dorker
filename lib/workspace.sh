#!/usr/bin/env bash
# lib/workspace.sh - 工作区检测与验证

# =========================================
# 查找工作区根目录
# 逻辑：向上查找 .git，返回其父目录的父目录
# 例如：~/projects/webapp/src → ~/projects
# =========================================
ocd_find_workspace_root() {
  local current_dir="$1"
  local found_git=""
  local dir="$current_dir"

  # 向上查找 .git 目录
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/.git" ]]; then
      found_git="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done

  # 确定工作区根目录
  local workspace_root=""
  if [[ -n "$found_git" ]]; then
    local parent_dir
    parent_dir="$(dirname "$found_git")"
    if [[ "$parent_dir" == "$HOME" ]]; then
      workspace_root="$found_git"
    else
      workspace_root="$parent_dir"
    fi
  elif [[ -n "${OCD_WORKSPACE:-}" ]]; then
    workspace_root="${OCD_WORKSPACE/#\~/$HOME}"
  else
    workspace_root="$current_dir"
  fi

  # 白名单验证
  if [[ -n "${OCD_ALLOWED_WORKSPACES:-}" ]]; then
    local expanded_whitelist="${OCD_ALLOWED_WORKSPACES//\$HOME/$HOME}"
    expanded_whitelist="${expanded_whitelist//\~/$HOME}"
    if [[ ":${expanded_whitelist}:" == *":${workspace_root}:"* ]]; then
      echo "$workspace_root"
      return 0
    else
      echo "BLOCKED:$workspace_root"
      return 1
    fi
  fi

  echo "$workspace_root"
}

# =========================================
# 计算相对路径
# =========================================
ocd_get_relative_path() {
  local base="$1"
  local target="$2"

  if [[ "$target" == "$base" ]]; then
    echo ""
  elif [[ "$target" == "$base"/* ]]; then
    echo "${target#"$base"/}"
  else
    echo ""
  fi
}

# =========================================
# 查找当前项目目录（包含 .git 的目录）
# =========================================
ocd_find_project_dir() {
  local current_dir="$1"
  local dir="$current_dir"

  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  echo "$current_dir"
}

# =========================================
# 验证工作区是否在白名单
# =========================================
ocd_validate_workspace() {
  local workspace="$1"
  local result

  result=$(ocd_find_workspace_root "$workspace")

  if [[ "$result" == BLOCKED:* ]]; then
    local blocked_path="${result#BLOCKED:}"
    ocd_error "工作区 $blocked_path 不在白名单内"
    ocd_info "允许的工作区: $OCD_ALLOWED_WORKSPACES"
    return 1
  fi

  echo "$result"
}
