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

# update_config_model tests
@test "update_config_model updates model value" {
  local config_file="$TEST_DIR/test.json"
  echo '{"model":"anthropic/claude-sonnet-4-5"}' > "$config_file"

  ocd_update_config_model "$config_file" "opencode/claude-opus-4-5"

  result=$(jq -r '.model' "$config_file")
  [ "$result" = "opencode/claude-opus-4-5" ]
}

@test "update_config_model handles empty model gracefully" {
  local config_file="$TEST_DIR/test.json"
  echo '{"model":"original"}' > "$config_file"

  ocd_update_config_model "$config_file" ""

  # Should not change when empty
  result=$(jq -r '.model' "$config_file")
  [ "$result" = "original" ]
}

# update_omo_agents tests
@test "update_omo_agents updates Planner-Sisyphus model" {
  local config_file="$TEST_DIR/omo.json"
  echo '{"agents":{"Planner-Sisyphus":{"model":"old-model"}}}' > "$config_file"

  export PLANNER_MODEL="new-planner-model"
  ocd_update_omo_agents "$config_file"

  result=$(jq -r '.agents."Planner-Sisyphus".model' "$config_file")
  [ "$result" = "new-planner-model" ]
}

@test "update_omo_agents adds oracle agent when ORACLE_MODEL is set" {
  local config_file="$TEST_DIR/omo.json"
  echo '{"agents":{"Planner-Sisyphus":{"model":"planner"}}}' > "$config_file"

  export PLANNER_MODEL="planner"
  export ORACLE_MODEL="openai/gpt-5.2"
  ocd_update_omo_agents "$config_file"

  result=$(jq -r '.agents.oracle.model' "$config_file")
  [ "$result" = "openai/gpt-5.2" ]
}
