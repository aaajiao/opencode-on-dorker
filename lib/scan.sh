#!/usr/bin/env bash
# lib/scan.sh - 项目扫描与注册模块
#
# 功能：扫描目录下的 git 仓库并注册到 OpenCode 存储
# 用法：ocd scan [目录]

# =========================================
# 存储路径
# =========================================
OCD_SCAN_STORAGE_DIR="${OCD_DATA_HOME:-$HOME/.local/share/opencode}/storage/project"

# =========================================
# 获取 git 仓库的项目 ID
# 基于第一个 root commit SHA（与 OpenCode 逻辑一致）
# =========================================
ocd_get_project_id() {
  local dir="$1"

  [[ ! -d "$dir/.git" ]] && return 1

  local project_id
  project_id=$(git -C "$dir" rev-list --max-parents=0 --all 2>/dev/null | sort | head -1)

  [[ -z "$project_id" ]] && return 1

  echo "$project_id"
}

# =========================================
# 注册/更新单个项目
# =========================================
ocd_register_project() {
  local project_name="$1"
  local project_id="$2"

  mkdir -p "$OCD_SCAN_STORAGE_DIR"

  local container_path="/workspace/${project_name}"
  local now
  now=$(($(date +%s) * 1000))

  local storage_file="${OCD_SCAN_STORAGE_DIR}/${project_id}.json"

  # 检查是否已存在，保留 created 时间
  local created_time="$now"
  if [[ -f "$storage_file" ]]; then
    local existing_created
    existing_created=$(grep -o '"created":[0-9]*' "$storage_file" 2>/dev/null | grep -o '[0-9]*')
    [[ -n "$existing_created" ]] && created_time="$existing_created"
  fi

  cat > "$storage_file" << EOF
{
  "id": "${project_id}",
  "worktree": "${container_path}",
  "vcs": "git",
  "sandboxes": [],
  "time": {
    "created": ${created_time},
    "updated": ${now}
  }
}
EOF

  return 0
}

# =========================================
# 清理重复记录（同一个 worktree 多个 ID）
# =========================================
ocd_cleanup_duplicates() {
  local cleaned=0
  local tmp_file
  tmp_file=$(mktemp)

  for f in "$OCD_SCAN_STORAGE_DIR"/*.json; do
    [[ ! -f "$f" ]] && continue
    [[ "$(basename "$f")" == "global.json" ]] && continue

    local worktree updated
    worktree=$(grep -o '"worktree":"[^"]*"' "$f" 2>/dev/null | sed 's/"worktree":"\([^"]*\)"/\1/')
    updated=$(grep -o '"updated":[0-9]*' "$f" 2>/dev/null | grep -o '[0-9]*')

    [[ -z "$worktree" ]] && continue
    [[ "$worktree" == "/" ]] && continue

    echo "${worktree}|${updated}|${f}" >> "$tmp_file"
  done

  local worktree_list
  worktree_list=$(cut -d'|' -f1 "$tmp_file" | sort -u)

  for wt in $worktree_list; do
    local count
    count=$(grep -c "^${wt}|" "$tmp_file" 2>/dev/null || echo 0)
    
    if [[ "$count" -gt 1 ]]; then
      local keep_file
      keep_file=$(grep "^${wt}|" "$tmp_file" | sort -t'|' -k2 -rn | head -1 | cut -d'|' -f3)
      
      grep "^${wt}|" "$tmp_file" | cut -d'|' -f3 | while read -r dup_file; do
        if [[ "$dup_file" != "$keep_file" ]]; then
          rm -f "$dup_file"
          ((cleaned++))
        fi
      done
    fi
  done

  rm -f "$tmp_file"
  echo "$cleaned"
}

# =========================================
# 扫描目录
# =========================================
ocd_scan_directory() {
  local workspace_root="$1"

  local total=0 registered=0 updated=0 skipped=0

  # 扫描一级子目录
  local dir
  for dir in "$workspace_root"/*/; do
    [[ ! -d "$dir" ]] && continue
    [[ ! -d "$dir/.git" ]] && continue

    dir="${dir%/}"
    local project_name
    project_name=$(basename "$dir")

    ((total++))

    local project_id
    project_id=$(ocd_get_project_id "$dir")

    if [[ -z "$project_id" ]]; then
      echo "  ⚠️  跳过 (无提交): $project_name"
      ((skipped++))
      continue
    fi

    local storage_file="${OCD_SCAN_STORAGE_DIR}/${project_id}.json"
    local action="注册"
    [[ -f "$storage_file" ]] && action="更新"

    if ocd_register_project "$project_name" "$project_id"; then
      local id_short="${project_id:0:8}"
      if [[ "$action" == "注册" ]]; then
        echo "  ✅ 新增: $project_name ($id_short...)"
        ((registered++))
      else
        echo "  🔄 更新: $project_name ($id_short...)"
        ((updated++))
      fi
    else
      echo "  ❌ 失败: $project_name"
      ((skipped++))
    fi
  done

  # 设置全局变量供调用者使用
  OCD_SCAN_TOTAL=$total
  OCD_SCAN_REGISTERED=$registered
  OCD_SCAN_UPDATED=$updated
  OCD_SCAN_SKIPPED=$skipped
}

# =========================================
# 主扫描入口
# =========================================
ocd_scan() {
  local target_dir="${1:-}"

  # 如果没有指定目录，使用工作区检测逻辑
  if [[ -z "$target_dir" ]]; then
    local current_dir
    current_dir=$(pwd)

    # 复用 workspace.sh 的逻辑检测工作区
    if type ocd_find_workspace_root &>/dev/null; then
      target_dir=$(ocd_find_workspace_root "$current_dir")
      # 处理 BLOCKED 情况
      if [[ "$target_dir" == BLOCKED:* ]]; then
        target_dir="${target_dir#BLOCKED:}"
      fi
    else
      target_dir="$current_dir"
    fi
  fi

  # 展开 ~ 路径
  target_dir="${target_dir/#\~/$HOME}"

  # 验证目录存在
  if [[ ! -d "$target_dir" ]]; then
    ocd_error "目录不存在: $target_dir"
    return 1
  fi

  # 获取绝对路径
  target_dir=$(cd "$target_dir" && pwd)

  echo ""
  echo "🔍 OCD 项目扫描"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📁 工作区: $target_dir"
  echo "💾 存储: $OCD_SCAN_STORAGE_DIR"
  echo ""

  ocd_scan_directory "$target_dir"

  local duplicates_cleaned
  duplicates_cleaned=$(ocd_cleanup_duplicates)

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 扫描完成:"
  echo "   发现: ${OCD_SCAN_TOTAL} 个 git 项目"
  [[ "${OCD_SCAN_REGISTERED:-0}" -gt 0 ]] && echo "   ✅ 新增: ${OCD_SCAN_REGISTERED}"
  [[ "${OCD_SCAN_UPDATED:-0}" -gt 0 ]] && echo "   🔄 更新: ${OCD_SCAN_UPDATED}"
  [[ "${OCD_SCAN_SKIPPED:-0}" -gt 0 ]] && echo "   ⏭️  跳过: ${OCD_SCAN_SKIPPED}"
  [[ "$duplicates_cleaned" -gt 0 ]] && echo "   🧹 清理重复: ${duplicates_cleaned}"
  echo ""

  if [[ "${OCD_SCAN_REGISTERED:-0}" -gt 0 || "${OCD_SCAN_UPDATED:-0}" -gt 0 ]]; then
    echo "💡 提示: 刷新 WebUI 或重启 OpenCode 以查看更新"
    echo ""
  fi

  return 0
}
