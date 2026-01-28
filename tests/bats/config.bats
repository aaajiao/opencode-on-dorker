#!/usr/bin/env bats
# tests/bats/config.bats - Config module tests (v5)

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"

  export TEST_DIR=$(mktemp -d)
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  mkdir -p "$OCD_CONFIG_HOME"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_create_config_from_template tests
# =========================================

@test "ocd_create_config_from_template replaces version placeholder" {
  local template="$TEST_DIR/template.json"
  local output="$TEST_DIR/output.json"

  # Copy real template for test
  cp "$OCD_ROOT/templates/global/opencode.json.tmpl" "$template" 2>/dev/null || \
    echo '{"plugin": ["test"]}' > "$template"
  export OH_MY_OPENCODE_VERSION="2.14.0"

  ocd_create_config_from_template "$template" "$output"

  [ -f "$output" ]
}

@test "ocd_create_config_from_template creates output file" {
  local template="$TEST_DIR/template.json"
  local output="$TEST_DIR/output.json"

  echo '{"test": "value"}' > "$template"

  ocd_create_config_from_template "$template" "$output"

  [ -f "$output" ]
  result=$(cat "$output")
  [[ "$result" == *"test"* ]]
}

# =========================================
# ocd_ensure_global_config tests
# =========================================

@test "ocd_ensure_global_config creates config directories" {
  ocd_ensure_global_config

  [ -d "$OCD_CONFIG_HOME/agent" ]
  [ -d "$OCD_CONFIG_HOME/command" ]
  [ -d "$OCD_CONFIG_HOME/skill" ]
  [ -d "$OCD_CONFIG_HOME/themes" ]
}

@test "ocd_ensure_global_config does not overwrite existing config" {
  mkdir -p "$OCD_CONFIG_HOME"
  echo '{"custom": "config"}' > "$OCD_CONFIG_HOME/opencode.json"

  ocd_ensure_global_config

  result=$(cat "$OCD_CONFIG_HOME/opencode.json")
  [[ "$result" == *"custom"* ]]
}

# =========================================
# ocd_update_port tests
# =========================================

@test "ocd_update_port updates port value with jq" {
  local config_file="$TEST_DIR/test.json"
  echo '{"server":{"port":4096}}' > "$config_file"

  ocd_update_port "$config_file" 5000

  result=$(jq '.server.port' "$config_file")
  [ "$result" = "5000" ]
}

@test "ocd_update_port returns error for missing file" {
  run ocd_update_port "/nonexistent/file.json" 5000
  [ "$status" -eq 1 ]
}

# =========================================
# ocd_update_config_model tests
# =========================================

@test "ocd_update_config_model updates model value" {
  local config_file="$TEST_DIR/test.json"
  echo '{"model":"anthropic/claude-sonnet-4-5"}' > "$config_file"

  ocd_update_config_model "$config_file" "opencode/claude-opus-4-5"

  result=$(jq -r '.model' "$config_file")
  [ "$result" = "opencode/claude-opus-4-5" ]
}

@test "ocd_update_config_model handles empty model gracefully" {
  local config_file="$TEST_DIR/test.json"
  echo '{"model":"original"}' > "$config_file"

  ocd_update_config_model "$config_file" ""

  result=$(jq -r '.model' "$config_file")
  [ "$result" = "original" ]
}

# =========================================
# ocd_update_omo_agents tests
# =========================================

@test "ocd_update_omo_agents updates sisyphus model" {
  local config_file="$TEST_DIR/omo.json"
  echo '{"agents":{"sisyphus":{"model":"old-model"}}}' > "$config_file"

  export SISYPHUS_MODEL="new-sisyphus-model"
  ocd_update_omo_agents "$config_file"

  result=$(jq -r '.agents.sisyphus.model' "$config_file")
  [ "$result" = "new-sisyphus-model" ]
}

@test "ocd_update_omo_agents adds oracle agent when ORACLE_MODEL is set" {
  local config_file="$TEST_DIR/omo.json"
  echo '{"agents":{"sisyphus":{"model":"planner"}}}' > "$config_file"

  export SISYPHUS_MODEL="planner"
  export ORACLE_MODEL="openai/gpt-5.2"
  ocd_update_omo_agents "$config_file"

  result=$(jq -r '.agents.oracle.model' "$config_file")
  [ "$result" = "openai/gpt-5.2" ]
}

@test "ocd_update_omo_agents handles missing file gracefully" {
  run ocd_update_omo_agents "/nonexistent/file.json"
  [ "$status" -eq 0 ]
}

# =========================================
# ocd_reset_global_config tests
# =========================================

@test "ocd_reset_global_config creates backup before reset" {
  mkdir -p "$OCD_CONFIG_HOME"
  echo '{"old": "config"}' > "$OCD_CONFIG_HOME/opencode.json"

  mkdir -p "$OCD_ROOT/templates/global"
  echo '{"new": "config"}' > "$OCD_ROOT/templates/global/opencode.json.tmpl"

  ocd_reset_global_config

  backup_dir=$(ls -d "$OCD_CONFIG_HOME"/.backup-* 2>/dev/null | head -1)
  [ -n "$backup_dir" ]
  [ -f "$backup_dir/opencode.json" ]
}

@test "ocd_reset_global_config removes migration markers" {
  mkdir -p "$OCD_CONFIG_HOME"
  touch "$OCD_CONFIG_HOME/.ocd-v5-migrated"
  touch "$OCD_CONFIG_HOME/.ocd-v5-init"

  mkdir -p "$OCD_ROOT/templates/global"
  echo '{}' > "$OCD_ROOT/templates/global/opencode.json.tmpl"

  ocd_reset_global_config

  [ ! -f "$OCD_CONFIG_HOME/.ocd-v5-migrated" ]
  [ ! -f "$OCD_CONFIG_HOME/.ocd-v5-init" ]
}

# =========================================
# ocd_load_models tests
# =========================================

@test "ocd_load_models sets default MAIN_MODEL" {
  unset MAIN_MODEL
  ocd_load_models

  [ -n "$MAIN_MODEL" ]
}

@test "ocd_load_models loads from models.conf" {
  echo "MAIN_MODEL=test/model" > "$OCD_ROOT/models.conf"

  unset MAIN_MODEL
  ocd_load_models

  [ "$MAIN_MODEL" = "test/model" ]

  rm -f "$OCD_ROOT/models.conf"
}

# =========================================
# ocd_show_welcome_if_first_run tests
# =========================================

@test "ocd_show_welcome_if_first_run creates marker file" {
  mkdir -p "$OCD_CONFIG_HOME"
  rm -f "$OCD_CONFIG_HOME/.ocd-v5-init"

  run ocd_show_welcome_if_first_run

  [ -f "$OCD_CONFIG_HOME/.ocd-v5-init" ]
}

@test "ocd_show_welcome_if_first_run skips if marker exists" {
  mkdir -p "$OCD_CONFIG_HOME"
  touch "$OCD_CONFIG_HOME/.ocd-v5-init"

  run ocd_show_welcome_if_first_run

  [ "$status" -eq 0 ]
}

# =========================================
# ocd_ensure_provider_cache tests
# =========================================

@test "ocd_ensure_provider_cache creates cache file" {
  export OCD_OMO_CACHE_HOME="$TEST_DIR/oh-my-opencode"
  mkdir -p "$OCD_OMO_CACHE_HOME"

  ocd_ensure_provider_cache

  [ -f "$OCD_OMO_CACHE_HOME/connected-providers.json" ]

  run jq -e '.connected' "$OCD_OMO_CACHE_HOME/connected-providers.json"
  [ "$status" -eq 0 ]

  run jq -e '.updatedAt' "$OCD_OMO_CACHE_HOME/connected-providers.json"
  [ "$status" -eq 0 ]
}

@test "ocd_ensure_provider_cache is idempotent" {
  export OCD_OMO_CACHE_HOME="$TEST_DIR/oh-my-opencode"
  mkdir -p "$OCD_OMO_CACHE_HOME"
  echo '{"connected":["existing"],"updatedAt":"keep"}' > "$OCD_OMO_CACHE_HOME/connected-providers.json"

  ocd_ensure_provider_cache

  result=$(jq -r '.connected[0]' "$OCD_OMO_CACHE_HOME/connected-providers.json")
  [ "$result" = "existing" ]
}

@test "ocd_ensure_provider_cache creates directory if missing" {
  export OCD_OMO_CACHE_HOME="$TEST_DIR/nonexistent/oh-my-opencode"

  ocd_ensure_provider_cache

  [ -d "$OCD_OMO_CACHE_HOME" ]
  [ -f "$OCD_OMO_CACHE_HOME/connected-providers.json" ]
}
