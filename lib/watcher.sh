#!/usr/bin/env bash
# lib/watcher.sh - IPC 文件监听器（容器与 macOS 通信）

# 防抖状态目录
_OCD_STATE_DIR="/tmp/.ocd_ipc_state"

# =========================================
# 处理 URL 打开（带防抖）
# =========================================
ocd_handle_url() {
  local url_file="$1"
  local state_file="${_OCD_STATE_DIR}/url_state"
  
  [[ ! -s "$url_file" ]] && return

  # 原子消费：先读取再立即清空，防止竞态
  local url
  url=$(cat "$url_file" 2>/dev/null)
  : > "$url_file"
  
  # 清理 URL（取第一行，去除空白）
  url=$(echo "$url" | head -1 | tr -d '\r\n' | xargs)
  [[ -z "$url" ]] && return

  # 确保状态目录存在
  mkdir -p "$_OCD_STATE_DIR" 2>/dev/null

  # 防抖：3秒内相同 URL 不重复打开
  local last_time=0 last_url="" now
  now=$(date +%s)
  
  if [[ -f "$state_file" ]]; then
    read -r last_time last_url < "$state_file" 2>/dev/null || true
  fi
  
  if [[ "$url" == "$last_url" ]] && (( now - last_time < 3 )); then
    return  # 3秒内相同 URL，跳过
  fi
  
  # 记录状态并打开
  echo "$now $url" > "$state_file"
  open "$url"
}

# =========================================
# 处理通知（带防抖）
# =========================================
ocd_handle_notify() {
  local notify_file="$1"
  local state_file="${_OCD_STATE_DIR}/notify_state"
  local icon_file="$HOME/opencode/ghostty-128.png"

  [[ ! -s "$notify_file" ]] && return

  # 原子消费：先读取再立即清空
  local content
  content=$(cat "$notify_file" 2>/dev/null)
  : > "$notify_file"
  
  [[ -z "$content" ]] && return

  mkdir -p "$_OCD_STATE_DIR" 2>/dev/null

  # 防抖：3秒内相同内容不重复通知（使用 md5 哈希比较）
  local content_hash last_hash="" last_time=0 now
  content_hash=$(echo "$content" | md5 2>/dev/null || echo "$content" | md5sum 2>/dev/null | cut -d' ' -f1)
  now=$(date +%s)
  
  if [[ -f "$state_file" ]]; then
    read -r last_time last_hash < "$state_file" 2>/dev/null || true
  fi
  
  if [[ "$content_hash" == "$last_hash" ]] && (( now - last_time < 3 )); then
    return
  fi
  
  echo "$now $content_hash" > "$state_file"

  while IFS='|' read -r title msg; do
    if [[ -n "$msg" ]]; then
      if command -v terminal-notifier &>/dev/null && [[ -f "$icon_file" ]]; then
        terminal-notifier -title "$title" -message "$msg" -contentImage "$icon_file" -sound Morse
      else
        osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
      fi
    fi
  done <<< "$content"
}

# =========================================
# 处理剪贴板
# =========================================
ocd_handle_clipboard() {
  local clipboard_file="$1"
  [[ ! -s "$clipboard_file" ]] && return
  pbcopy < "$clipboard_file" 2>/dev/null || true
  : > "$clipboard_file"
}

# =========================================
# 启动 Watcher（自动选择 fswatch 或轮询）
# 使用 job control 确保子进程成为独立进程组，便于清理
# =========================================
ocd_start_watcher() {
  local url_file="$1"
  local notify_file="$2"
  local clipboard_file="$3"

  # 启用 job control，让后台任务成为独立进程组 leader
  # 这样 kill -- -$PID 才能正确杀死整个进程组（包括 fswatch）
  set -m
  (
    exec </dev/null >/dev/null 2>&1
    if command -v fswatch &>/dev/null; then
      # 事件驱动模式（低 CPU）
      fswatch -o --event Created --event Updated "$url_file" "$notify_file" "$clipboard_file" 2>/dev/null | \
      while IFS= read -r _; do
        ocd_handle_url "$url_file"
        ocd_handle_notify "$notify_file"
        ocd_handle_clipboard "$clipboard_file"
      done
    else
      # 轮询模式（兼容）
      while true; do
        ocd_handle_url "$url_file"
        ocd_handle_notify "$notify_file"
        ocd_handle_clipboard "$clipboard_file"
        sleep 1
      done
    fi
  ) &
  local pid=$!
  set +m  # 恢复默认（禁用 job control）

  echo "$pid"
}

# =========================================
# 获取 Tailscale IP
# =========================================
ocd_get_tailscale_ip() {
  command -v tailscale &>/dev/null || return 1
  local ts_status
  ts_status=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4 || echo "")
  [[ "$ts_status" != "Running" ]] && return 1
  tailscale ip -4 2>/dev/null
}
