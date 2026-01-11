#!/usr/bin/env bats
# tests/bats/migrate.bats - Migration module tests (v5)

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  [[ -f "$OCD_ROOT/lib/migrate.sh" ]] && source "$OCD_ROOT/lib/migrate.sh"

  export TEST_DIR=$(mktemp -d)
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  mkdir -p "$OCD_CONFIG_HOME"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_check_migration tests
# =========================================

@test "ocd_check_migration creates marker when v4 config exists" {
  echo '{}' > "$OCD_CONFIG_HOME/opencode.json"
  rm -f "$OCD_CONFIG_HOME/.ocd-v5-migrated"

  run ocd_check_migration

  [ -f "$OCD_CONFIG_HOME/.ocd-v5-migrated" ]
}

@test "ocd_check_migration skips when already migrated" {
  echo '{}' > "$OCD_CONFIG_HOME/opencode.json"
  touch "$OCD_CONFIG_HOME/.ocd-v5-migrated"

  run ocd_check_migration

  # Should not output migration message
  [[ ! "$output" =~ "OCD v5" ]]
}

@test "ocd_check_migration skips when no config exists" {
  rm -f "$OCD_CONFIG_HOME/opencode.json"
  rm -f "$OCD_CONFIG_HOME/.ocd-v5-migrated"

  run ocd_check_migration

  [ ! -f "$OCD_CONFIG_HOME/.ocd-v5-migrated" ]
}

@test "ocd_check_migration warns about deprecated mcp.json" {
  echo '{}' > "$OCD_CONFIG_HOME/opencode.json"
  touch "$OCD_CONFIG_HOME/.ocd-v5-migrated"
  echo '{}' > "$OCD_ROOT/mcp.json"

  run ocd_check_migration

  [[ "$output" =~ "mcp.json" ]]

  rm -f "$OCD_ROOT/mcp.json"
}
