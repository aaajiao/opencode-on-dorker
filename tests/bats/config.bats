#!/usr/bin/env bats
# tests/bats/config.bats - Config module tests

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"

  export TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}

# generate_opencode_config tests
@test "generate_opencode_config creates valid JSON" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 4096 0

  # Verify valid JSON
  run jq '.' "$config_file"
  [ "$status" -eq 0 ]
}

@test "generate_opencode_config includes correct port" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 5000 0

  result=$(jq '.server.port' "$config_file")
  [ "$result" = "5000" ]
}

@test "generate_opencode_config excludes provider without quotio" {
  local config_file="$TEST_DIR/opencode.json"
  ocd_generate_opencode_config "$config_file" 4096 0

  result=$(jq 'has("provider")' "$config_file")
  [ "$result" = "false" ]
}

@test "generate_opencode_config includes provider with quotio" {
  local config_file="$TEST_DIR/opencode.json"
  export QUOTIO_API_KEY="test-key"
  ocd_generate_opencode_config "$config_file" 4096 1

  result=$(jq 'has("provider")' "$config_file")
  [ "$result" = "true" ]
}

# generate_omo_config tests
@test "generate_omo_config creates valid JSON" {
  local config_file="$TEST_DIR/oh-my-opencode.json"
  ocd_generate_omo_config "$config_file" 0

  run jq '.' "$config_file"
  [ "$status" -eq 0 ]
}

@test "generate_omo_config includes agents config" {
  local config_file="$TEST_DIR/oh-my-opencode.json"
  ocd_generate_omo_config "$config_file" 0

  result=$(jq 'has("agents")' "$config_file")
  [ "$result" = "true" ]
}

# update_config_port tests
@test "update_config_port updates port value" {
  local config_file="$TEST_DIR/test.json"
  echo '{"server":{"port":4096}}' > "$config_file"

  ocd_update_config_port "$config_file" 5000

  result=$(jq '.server.port' "$config_file")
  [ "$result" = "5000" ]
}
