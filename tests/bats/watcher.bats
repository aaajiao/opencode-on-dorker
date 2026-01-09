#!/usr/bin/env bats
# tests/bats/watcher.bats - Watcher/IPC 进程管理测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/watcher.sh"

  export TEST_DIR=$(mktemp -d)
  export TEST_URL_FILE="$TEST_DIR/open_url"
  export TEST_NOTIFY_FILE="$TEST_DIR/notifications"
  export TEST_CLIPBOARD_FILE="$TEST_DIR/clipboard"

  : > "$TEST_URL_FILE"
  : > "$TEST_NOTIFY_FILE"
  : > "$TEST_CLIPBOARD_FILE"
}

teardown() {
  # 清理测试进程
  pkill -f "fswatch.*$TEST_DIR" 2>/dev/null || true
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_handle_url 测试
# =========================================

@test "ocd_handle_url opens URL when file has content" {
  # Mock open command
  open() { echo "OPENED: $1" >> "$TEST_DIR/opened.log"; }
  export -f open

  echo "https://example.com" > "$TEST_URL_FILE"
  ocd_handle_url "$TEST_URL_FILE"

  # URL 文件应被清空
  [ ! -s "$TEST_URL_FILE" ]
}

@test "ocd_handle_url does nothing when file is empty" {
  open() { echo "OPENED: $1" >> "$TEST_DIR/opened.log"; }
  export -f open

  : > "$TEST_URL_FILE"
  ocd_handle_url "$TEST_URL_FILE"

  # 不应有打开记录
  [ ! -f "$TEST_DIR/opened.log" ]
}

@test "ocd_handle_url only reads first line" {
  open() { echo "OPENED: $1" >> "$TEST_DIR/opened.log"; }
  export -f open

  printf "https://first.com\nhttps://second.com\n" > "$TEST_URL_FILE"
  ocd_handle_url "$TEST_URL_FILE"

  # 只打开第一个 URL
  grep -q "https://first.com" "$TEST_DIR/opened.log"
  ! grep -q "https://second.com" "$TEST_DIR/opened.log"
}

# =========================================
# ocd_handle_notify 测试
# =========================================

@test "ocd_handle_notify processes notification" {
  # Mock osascript
  osascript() { echo "NOTIFY: $*" >> "$TEST_DIR/notify.log"; }
  export -f osascript

  echo "标题|内容" > "$TEST_NOTIFY_FILE"
  ocd_handle_notify "$TEST_NOTIFY_FILE"

  # 通知文件应被清空
  [ ! -s "$TEST_NOTIFY_FILE" ]
}

# =========================================
# ocd_handle_clipboard 测试
# =========================================

@test "ocd_handle_clipboard processes clipboard content" {
  # Mock pbcopy
  pbcopy() { cat > "$TEST_DIR/clipboard_content"; }
  export -f pbcopy

  echo "测试内容" > "$TEST_CLIPBOARD_FILE"
  ocd_handle_clipboard "$TEST_CLIPBOARD_FILE"

  # 剪贴板文件应被清空
  [ ! -s "$TEST_CLIPBOARD_FILE" ]
  # 内容应被复制
  grep -q "测试内容" "$TEST_DIR/clipboard_content"
}

# =========================================
# ocd_start_watcher 测试
# =========================================

@test "ocd_start_watcher returns a PID" {
  skip_if_no_fswatch

  pid=$(ocd_start_watcher "$TEST_URL_FILE" "$TEST_NOTIFY_FILE" "$TEST_CLIPBOARD_FILE")

  # 应返回有效 PID
  [[ "$pid" =~ ^[0-9]+$ ]]

  # 进程应存在
  kill -0 "$pid" 2>/dev/null

  # 清理
  kill "$pid" 2>/dev/null || true
}

@test "watcher responds to file changes" {
  skip_if_no_fswatch

  open() { echo "OPENED: $1" >> "$TEST_DIR/opened.log"; }
  export -f open

  pid=$(ocd_start_watcher "$TEST_URL_FILE" "$TEST_NOTIFY_FILE" "$TEST_CLIPBOARD_FILE")
  sleep 0.5  # 等待 watcher 启动

  echo "https://test.com" > "$TEST_URL_FILE"
  sleep 1  # 等待 watcher 响应

  # 应该有打开记录
  [ -f "$TEST_DIR/opened.log" ]

  kill "$pid" 2>/dev/null || true
}

# =========================================
# 进程清理测试（防止泄漏）
# =========================================

@test "pkill cleans up fswatch processes" {
  skip_if_no_fswatch

  # 启动多个 watcher
  pid1=$(ocd_start_watcher "$TEST_URL_FILE" "$TEST_NOTIFY_FILE" "$TEST_CLIPBOARD_FILE")
  pid2=$(ocd_start_watcher "$TEST_URL_FILE" "$TEST_NOTIFY_FILE" "$TEST_CLIPBOARD_FILE")

  sleep 0.5

  # 确认至少有进程存在
  [ "$(pgrep -f "fswatch.*$TEST_DIR" | wc -l)" -ge 1 ]

  # 清理 - 使用 SIGKILL 确保立即终止
  pkill -9 -f "fswatch.*$TEST_DIR" 2>/dev/null || true
  sleep 1

  # 等待进程完全终止（最多重试 5 次）
  local retries=5
  while [ $retries -gt 0 ]; do
    local count
    count=$(pgrep -f "fswatch.*$TEST_DIR" 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -eq 0 ] && break
    pkill -9 -f "fswatch.*$TEST_DIR" 2>/dev/null || true
    sleep 0.5
    retries=$((retries - 1))
  done

  # 应该没有进程了
  [ "$(pgrep -f "fswatch.*$TEST_DIR" 2>/dev/null | wc -l | tr -d ' ')" -eq 0 ]
}

# =========================================
# 辅助函数
# =========================================

skip_if_no_fswatch() {
  if ! command -v fswatch &>/dev/null; then
    skip "fswatch not installed"
  fi
}
