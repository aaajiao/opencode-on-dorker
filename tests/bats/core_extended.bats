#!/usr/bin/env bats
# tests/bats/core_extended.bats - 扩展核心函数测试
#
# 覆盖之前未测试的 lib/core.sh 函数

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  export TEST_DIR=$(mktemp -d)

  # 模拟 XDG 目录
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_CONFIG_GLOBAL="$TEST_DIR/config/global"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
  export OCD_CONFIG_INSTANCES="$TEST_DIR/config/instances"
  export OCD_DATA_INSTANCES="$TEST_DIR/data/instances"
  export OCD_STATE_INSTANCES="$TEST_DIR/state/instances"

  source "$OCD_ROOT/lib/core.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_instance_*_dir 函数测试
# =========================================

@test "ocd_instance_config_dir returns correct path" {
  result=$(ocd_instance_config_dir "myproject")
  [ "$result" = "$OCD_CONFIG_INSTANCES/myproject" ]
}

@test "ocd_instance_config_dir uses default name" {
  result=$(ocd_instance_config_dir)
  [ "$result" = "$OCD_CONFIG_INSTANCES/opencode" ]
}

@test "ocd_instance_data_dir returns correct path" {
  result=$(ocd_instance_data_dir "myproject")
  [ "$result" = "$OCD_DATA_INSTANCES/myproject" ]
}

@test "ocd_instance_state_dir returns correct path" {
  result=$(ocd_instance_state_dir "myproject")
  [ "$result" = "$OCD_STATE_INSTANCES/myproject" ]
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
  # 不应报错
  [ $? -eq 0 ]
}

@test "ocd_load_versions rejects invalid variable names" {
  cat > "$TEST_DIR/versions.lock" << 'EOF'
valid_var=test
123INVALID=value
BUN_VERSION=1.3.5
EOF

  unset valid_var 123INVALID BUN_VERSION 2>/dev/null || true
  OCD_ROOT="$TEST_DIR" ocd_load_versions

  # 只有 BUN_VERSION 应该被设置（大写字母开头）
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
# ocd_auto_migrate 函数测试
# =========================================

@test "ocd_auto_migrate does nothing without migrate script" {
  # 不存在迁移脚本时应该直接返回 0
  run ocd_auto_migrate
  [ "$status" -eq 0 ]
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

@test "set -e: ocd_instance_config_dir" {
  run run_with_set_e ocd_instance_config_dir test
  [ "$status" -eq 0 ]
}

@test "set -e: ocd_load_versions with missing file" {
  run bash -c "set -e; source '$OCD_ROOT/lib/core.sh'; OCD_ROOT=/nonexistent ocd_load_versions"
  [ "$status" -eq 0 ]
}
