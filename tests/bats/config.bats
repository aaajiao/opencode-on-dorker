#!/usr/bin/env bats
# tests/bats/config.bats - 配置模块测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"

  export TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_generate_opencode_config 测试
# =========================================
@test "generate_opencode_config: 生成有效 JSON" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 4096 0

  # 验证是有效 JSON
  run jq '.' "$config_file"
  [ "$status" -eq 0 ]
}

@test "generate_opencode_config: 包含正确端口" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 5000 0

  result=$(jq '.server.port' "$config_file")
  [ "$result" = "5000" ]
}

@test "generate_opencode_config: 无 Quotio 时不含 provider" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 4096 0

  result=$(jq 'has("provider")' "$config_file")
  [ "$result" = "false" ]
}

@test "generate_opencode_config: Quotio 模式包含 provider" {
  local config_file="$TEST_DIR/opencode.json"
  export QUOTIO_API_KEY="test-key"
  ocd_generate_opencode_config "$config_file" 4096 1

  result=$(jq 'has("provider")' "$config_file")
  [ "$result" = "true" ]
}

# =========================================
# ocd_generate_omo_config 测试
# =========================================
@test "generate_omo_config: 生成有效 JSON" {
  local config_file="$TEST_DIR/oh-my-opencode.json"
  ocd_generate_omo_config "$config_file" 0

  run jq '.' "$config_file"
  [ "$status" -eq 0 ]
}

@test "generate_omo_config: 包含 agents 配置" {
  local config_file="$TEST_DIR/oh-my-opencode.json"
  ocd_generate_omo_config "$config_file" 0

  result=$(jq 'has("agents")' "$config_file")
  [ "$result" = "true" ]
}

# =========================================
# ocd_update_config_port 测试
# =========================================
@test "update_config_port: 更新端口值" {
  local config_file="$TEST_DIR/test.json"
  echo '{"server":{"port":4096}}' > "$config_file"

  ocd_update_config_port "$config_file" 5000

  result=$(jq '.server.port' "$config_file")
  [ "$result" = "5000" ]
}
