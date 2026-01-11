#!/usr/bin/env bats
# tests/bats/core.bats - Core module tests

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
}

# sanitize_name tests
@test "sanitize_name converts to lowercase" {
  result=$(ocd_sanitize_name "MyProject")
  [ "$result" = "myproject" ]
}

@test "sanitize_name converts spaces to hyphens" {
  result=$(ocd_sanitize_name "My Project")
  [ "$result" = "my-project" ]
}

@test "sanitize_name removes special characters" {
  result=$(ocd_sanitize_name "my@project#123!")
  [ "$result" = "myproject123" ]
}

@test "sanitize_name preserves underscores" {
  result=$(ocd_sanitize_name "my_project")
  [ "$result" = "my_project" ]
}

# load_env tests
@test "load_env loads valid variables" {
  local env_file=$(mktemp)
  echo "TEST_VAR=hello" > "$env_file"
  ocd_load_env "$env_file"
  [ "$TEST_VAR" = "hello" ]
  rm "$env_file"
}

@test "load_env skips comments" {
  local env_file=$(mktemp)
  echo "# COMMENT=value" > "$env_file"
  echo "VALID_VAR=yes" >> "$env_file"
  ocd_load_env "$env_file"
  [ -z "$COMMENT" ]
  [ "$VALID_VAR" = "yes" ]
  rm "$env_file"
}

@test "load_env rejects dangerous characters" {
  local env_file=$(mktemp)
  echo 'DANGEROUS=$(whoami)' > "$env_file"
  ocd_load_env "$env_file"
  [ -z "$DANGEROUS" ]
  rm "$env_file"
}

@test "load_env rejects quotes" {
  local env_file=$(mktemp)
  echo 'QUOTED="value"' > "$env_file"
  ocd_load_env "$env_file"
  [ -z "$QUOTED" ]
  rm "$env_file"
}

@test "load_env handles missing file" {
  run ocd_load_env "/nonexistent/file"
  [ "$status" -eq 0 ]
}

# version tests
@test "version reads VERSION file" {
  result=$(ocd_version)
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [ "$result" = "unknown" ]
}

# OCD_CLAUDE_HOME tests
@test "OCD_CLAUDE_HOME is set to ~/.claude" {
  [ "$OCD_CLAUDE_HOME" = "$HOME/.claude" ]
}
