#!/usr/bin/env bats
# tests/bats/sete.bats - set -e 兼容性测试 (v4.0)
#
# 确保所有函数在 set -e 模式下正确工作，
# 不会因为条件判断返回 false 而导致脚本退出

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  export TEST_DIR=$(mktemp -d)

  # 模拟 XDG 目录 (v4.0 - 无 instance 概念)
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
  export OCD_OMO_CACHE_HOME="$TEST_DIR/cache/oh-my-opencode"
  export OCD_IPC_HOME="$TEST_DIR/state/ipc"

  # 创建必要目录
  mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}

  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"
  source "$OCD_ROOT/lib/watcher.sh"
  source "$OCD_ROOT/lib/workspace.sh"
  source "$OCD_ROOT/lib/port.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# 核心测试：在 set -e 下运行函数
# =========================================

run_with_set_e() {
  local func="$1"
  shift
  (
    set -e
    "$func" "$@"
  )
}

# =========================================
# lib/config.sh 函数测试
# =========================================

@test "set -e: ocd_init_global with existing directories" {
  # 预创建目录（模拟已存在的情况）
  mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}

  # 在 set -e 下运行应该成功
  run run_with_set_e ocd_init_global
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_init_global without existing directories" {
  rm -rf "$OCD_CONFIG_HOME"
  run run_with_set_e ocd_init_global
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_init_project with valid directory" {
  mkdir -p "$TEST_DIR/project"
  run run_with_set_e ocd_init_project "$TEST_DIR/project"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_generate_opencode_config" {
  run run_with_set_e ocd_generate_opencode_config "$TEST_DIR/opencode.json" 4096 0
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_generate_omo_config" {
  run run_with_set_e ocd_generate_omo_config "$TEST_DIR/omo.json" 0
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_update_config_port" {
  echo '{"server":{"port":4096}}' > "$TEST_DIR/config.json"
  run run_with_set_e ocd_update_config_port "$TEST_DIR/config.json" 5000
  [ "$status" -eq 0 ]
}

# =========================================
# lib/core.sh 函数测试
# =========================================

@test "set -e: ocd_sanitize_name" {
  run run_with_set_e ocd_sanitize_name "Test Project"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_load_env with missing file" {
  run run_with_set_e ocd_load_env "/nonexistent/file"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_load_env with empty file" {
  : > "$TEST_DIR/empty.env"
  run run_with_set_e ocd_load_env "$TEST_DIR/empty.env"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_version" {
  run run_with_set_e ocd_version
  [ "$status" -eq 0 ]
}

# =========================================
# lib/watcher.sh 函数测试
# =========================================

@test "set -e: ocd_handle_url with empty file" {
  : > "$TEST_DIR/open_url"
  run run_with_set_e ocd_handle_url "$TEST_DIR/open_url"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_handle_notify with empty file" {
  : > "$TEST_DIR/notifications"
  run run_with_set_e ocd_handle_notify "$TEST_DIR/notifications"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_handle_clipboard with empty file" {
  : > "$TEST_DIR/clipboard"
  run run_with_set_e ocd_handle_clipboard "$TEST_DIR/clipboard"
  [ "$status" -eq 0 ]
}

# =========================================
# lib/workspace.sh 函数测试
# =========================================

@test "set -e: ocd_find_workspace_root" {
  run run_with_set_e ocd_find_workspace_root "$HOME"
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_find_project_dir" {
  run run_with_set_e ocd_find_project_dir "$HOME"
  [ "$status" -eq 0 ]
}

# =========================================
# lib/port.sh 函数测试
# =========================================

@test "set -e: ocd_find_free_port" {
  run run_with_set_e ocd_find_free_port 4096
  [ "$status" -eq 0 ]
  # 应返回一个端口号
  [[ "$output" =~ ^[0-9]+$ ]]
}

# =========================================
# 边界情况测试
# =========================================

@test "set -e: multiple conditional expressions" {
  # 测试 [[ ]] && cmd 模式在文件存在时的行为
  local test_file="$TEST_DIR/test_file"
  touch "$test_file"

  run bash -c '
    set -e
    [[ -f "'"$test_file"'" ]] && echo "exists"
    [[ ! -f "/nonexistent" ]] && echo "not exists"
    echo "reached end"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"reached end"* ]]
}

@test "set -e: function with [[ ]] && at end must return 0" {
  # 这个测试验证函数末尾的 [[ ]] && 模式
  run bash -c '
    set -e
    test_func() {
      local file="/nonexistent"
      [[ -f "$file" ]] && echo "exists"
      return 0  # 必须显式返回 0
    }
    test_func
    echo "script continued"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"script continued"* ]]
}
