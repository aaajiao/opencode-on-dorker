#!/usr/bin/env bats
# tests/bats/port.bats - Port management module tests

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/port.sh"

  # Clean test environment
  export TEST_CONFIG_DIR=$(mktemp -d)
  export HOME="$TEST_CONFIG_DIR"
  mkdir -p "$HOME/.config/opencode"
}

teardown() {
  rm -rf "$TEST_CONFIG_DIR"
}

# find_free_port tests
@test "find_free_port returns port in base range" {
  result=$(ocd_find_free_port 4096)
  [ "$result" -ge 4096 ]
  [ "$result" -lt 4196 ]
}

@test "find_free_port uses custom base port" {
  result=$(ocd_find_free_port 5000)
  [ "$result" -ge 5000 ]
  [ "$result" -lt 5100 ]
}

@test "find_free_port returns different ports on consecutive calls" {
  port1=$(ocd_find_free_port 4096)
  port2=$(ocd_find_free_port 4096)
  [ "$port1" != "$port2" ]
}

@test "find_free_port creates port record file" {
  ocd_find_free_port 4096
  [ -f "$HOME/.config/opencode/.last_port" ]
}
