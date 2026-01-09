#!/usr/bin/env bats
# tests/bats/workspace.bats - Workspace module tests

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/workspace.sh"

  # Create test directories
  export TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/workspace/project/.git"
  mkdir -p "$TEST_DIR/workspace/project/src"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset OCD_ALLOWED_WORKSPACES
}

# find_workspace_root tests
@test "find_workspace_root returns parent of git repo" {
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project/src")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root from project root" {
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root allows whitelisted path" {
  export OCD_ALLOWED_WORKSPACES="$TEST_DIR/workspace"
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root blocks non-whitelisted path" {
  export OCD_ALLOWED_WORKSPACES="/allowed/path"
  run ocd_find_workspace_root "$TEST_DIR/workspace/project"
  [ "$status" -eq 1 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# get_relative_path tests
@test "get_relative_path calculates relative path" {
  result=$(ocd_get_relative_path "/base" "/base/sub/dir")
  [ "$result" = "sub/dir" ]
}

@test "get_relative_path returns empty for same path" {
  result=$(ocd_get_relative_path "/base" "/base")
  [ "$result" = "" ]
}

@test "get_relative_path returns empty for unrelated path" {
  result=$(ocd_get_relative_path "/base" "/other/path")
  [ "$result" = "" ]
}

# find_project_dir tests
@test "find_project_dir finds directory with git" {
  result=$(ocd_find_project_dir "$TEST_DIR/workspace/project/src")
  [ "$result" = "$TEST_DIR/workspace/project" ]
}

@test "find_project_dir returns current dir without git" {
  mkdir -p "$TEST_DIR/no_git/sub"
  result=$(ocd_find_project_dir "$TEST_DIR/no_git/sub")
  [ "$result" = "$TEST_DIR/no_git/sub" ]
}
