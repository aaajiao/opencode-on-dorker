#!/usr/bin/env bash
# lib/watcher.sh - IPC 文件监听器（容器与 macOS 通信）

# =========================================
# 处理 URL 打开
# =========================================
ocd_handle_url() {
  local url_file="$1"
  [[ ! -s "$url_file" ]] && return

  while IFS= read -r url; do
    [[ -n "$url" ]] && open "$url"
  done < "$url_file"
  : > "$url_file"
}

# =========================================
# 处理通知
# =========================================
ocd_handle_notify() {
  local notify_file="$1"
  local icon_file="$HOME/opencode/ghostty-128.png"

  [[ ! -s "$notify_file" ]] && return

  while IFS='|' read -r title msg; do
    if [[ -n "$msg" ]]; then
      if command -v terminal-notifier &>/dev/null && [[ -f "$icon_file" ]]; then
        terminal-notifier -title "$title" -message "$msg" -contentImage "$icon_file" -sound Morse
      else
        osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
      fi
    fi
  done < "$notify_file"
  : > "$notify_file"
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
# =========================================
ocd_start_watcher() {
  local url_file="$1"
  local notify_file="$2"
  local clipboard_file="$3"

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

  echo $!
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
