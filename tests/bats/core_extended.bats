#!/usr/bin/env bats
# tests/bats/core_extended.bats - 扩展核心函数测试 (v4.0)

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  export TEST_DIR=$(mktemp -d)

  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
  export OCD_OMO_CACHE_HOME="$TEST_DIR/cache/oh-my-opencode"
  export OCD_IPC_HOME="$TEST_DIR/state/ipc"

  source "$OCD_ROOT/lib/core.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_ipc_dir 函数测试 (v4.0 新增)
# =========================================

@test "ocd_ipc_dir returns correct path for port" {
  result=$(ocd_ipc_dir "5000")
  [ "$result" = "$OCD_IPC_HOME/5000" ]
}

@test "ocd_ipc_dir uses default port 4096" {
  result=$(ocd_ipc_dir)
  [ "$result" = "$OCD_IPC_HOME/4096" ]
}

@test "ocd_ipc_dir handles various port numbers" {
  result1=$(ocd_ipc_dir "8080")
  result2=$(ocd_ipc_dir "3000")
  result3=$(ocd_ipc_dir "443")

  [ "$result1" = "$OCD_IPC_HOME/8080" ]
  [ "$result2" = "$OCD_IPC_HOME/3000" ]
  [ "$result3" = "$OCD_IPC_HOME/443" ]
}

# =========================================
# ocd_load_versions 函数测试
# =========================================

@test "ocd_load_versions loads valid versions" {
  cat > "$TEST_DIR/versions.lock" << 'EOF'
BUN_VERSION=1.3.5
OPENCODE_AI_VERSION=1.1.6
EOF

  OCD_ROOT="$TEST_DIR" ocd_load_versions

  [ "$BUN_VERSION" = "1.3.5" ]
  [ "$OPENCODE_AI_VERSION" = "1.1.6" ]
}

@test "ocd_load_versions skips comments" {
  cat > "$TEST_DIR/versions.lock" << 'EOF'
# This is a comment
BUN_VERSION=1.3.5
# Another comment
EOF

  OCD_ROOT="$TEST_DIR" ocd_load_versions

  [ "$BUN_VERSION" = "1.3.5" ]
}

@test "ocd_load_versions skips empty lines" {
  cat > "$TEST_DIR/versions.lock" << 'EOF'
BUN_VERSION=1.3.5

OPENCODE_AI_VERSION=1.1.6
EOF

  OCD_ROOT="$TEST_DIR" ocd_load_versions

  [ "$BUN_VERSION" = "1.3.5" ]
  [ "$OPENCODE_AI_VERSION" = "1.1.6" ]
}

@test "ocd_load_versions handles missing file" {
  OCD_ROOT="$TEST_DIR" ocd_load_versions
  [ $? -eq 0 ]
}

@test "ocd_load_versions rejects invalid variable names" {
  cat > "$TEST_DIR/versions.lock" << 'EOF'
valid_var=test
123INVALID=value
BUN_VERSION=1.3.5
EOF

  unset valid_var BUN_VERSION 2>/dev/null || true
  OCD_ROOT="$TEST_DIR" ocd_load_versions

  [ "$BUN_VERSION" = "1.3.5" ]
}

# =========================================
# 日志函数测试
# =========================================

@test "ocd_log outputs message" {
  result=$(ocd_log "test message")
  [ "$result" = "test message" ]
}

@test "ocd_error outputs to stderr and returns 1" {
  run ocd_error "error message"
  [ "$status" -eq 1 ]
  [[ "$output" == *"error message"* ]]
}

@test "ocd_info outputs with emoji" {
  result=$(ocd_info "info message")
  [[ "$result" == *"info message"* ]]
}

@test "ocd_success outputs with emoji" {
  result=$(ocd_success "success message")
  [[ "$result" == *"success message"* ]]
}

# =========================================
# XDG 路径变量测试
# =========================================

@test "OCD_IPC_HOME is correctly derived from STATE_HOME" {
  [ "$OCD_IPC_HOME" = "$OCD_STATE_HOME/ipc" ]
}

@test "OCD_OMO_CACHE_HOME is set" {
  [ -n "$OCD_OMO_CACHE_HOME" ]
}

# =========================================
# set -e 兼容性测试
# =========================================

run_with_set_e() {
  local func="$1"
  shift
  (
    set -e
    "$func" "$@"
  )
}

@test "set -e: ocd_ipc_dir" {
  run run_with_set_e ocd_ipc_dir 5000
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_load_versions with missing file" {
  run bash -c "set -e; source '$OCD_ROOT/lib/core.sh'; OCD_ROOT=/nonexistent ocd_load_versions"
  [ "$status" -eq 0 ]
}
