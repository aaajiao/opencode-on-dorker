#!/usr/bin/env bats
# tests/bats/workspace_extended.bats - 扩展工作区函数测试
#
# 覆盖 ocd_find_parent_project 和 ocd_validate_workspace

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  export TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR/home"

  mkdir -p "$HOME"

  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/workspace.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset OCD_ALLOWED_WORKSPACES
}

# =========================================
# ocd_find_parent_project 测试
# =========================================

@test "ocd_find_parent_project finds parent git repo" {
  # 创建嵌套项目结构
  # ~/workspace/parent/.git
  # ~/workspace/parent/child/.git
  mkdir -p "$HOME/workspace/parent/.git"
  mkdir -p "$HOME/workspace/parent/child/.git"

  result=$(ocd_find_parent_project "$HOME/workspace/parent/child")
  [ "$result" = "$HOME/workspace/parent" ]
}

@test "ocd_find_parent_project returns empty when no parent" {
  # 只有一层项目
  mkdir -p "$HOME/workspace/project/.git"

  result=$(ocd_find_parent_project "$HOME/workspace/project")
  [ -z "$result" ]
}

@test "ocd_find_parent_project skips current directory" {
  mkdir -p "$HOME/workspace/project/.git"
  mkdir -p "$HOME/workspace/project/subdir"

  # 从 subdir 开始，应该找到 project
  result=$(ocd_find_parent_project "$HOME/workspace/project/subdir")
  [ "$result" = "$HOME/workspace/project" ]
}

@test "ocd_find_parent_project handles deeply nested structure" {
  mkdir -p "$HOME/workspace/mono/.git"
  mkdir -p "$HOME/workspace/mono/packages/core/.git"
  mkdir -p "$HOME/workspace/mono/packages/core/src/deep/nested"

  # 从深层目录开始
  result=$(ocd_find_parent_project "$HOME/workspace/mono/packages/core/src/deep/nested")
  [ "$result" = "$HOME/workspace/mono/packages/core" ]
}

# =========================================
# ocd_validate_workspace 测试
# =========================================

@test "ocd_validate_workspace passes without whitelist" {
  mkdir -p "$HOME/workspace/project/.git"

  result=$(ocd_validate_workspace "$HOME/workspace/project")
  [ -n "$result" ]
}

@test "ocd_validate_workspace passes for whitelisted path" {
  export OCD_ALLOWED_WORKSPACES="$HOME/workspace"
  mkdir -p "$HOME/workspace/project/.git"

  result=$(ocd_validate_workspace "$HOME/workspace/project")
  [ "$result" = "$HOME/workspace" ]
}

@test "ocd_validate_workspace fails for non-whitelisted path" {
  export OCD_ALLOWED_WORKSPACES="$HOME/allowed"
  mkdir -p "$HOME/workspace/project/.git"

  run ocd_validate_workspace "$HOME/workspace/project"
  [ "$status" -eq 1 ]
}

@test "ocd_validate_workspace expands \$HOME in whitelist" {
  export OCD_ALLOWED_WORKSPACES="\$HOME/workspace"
  mkdir -p "$HOME/workspace/project/.git"

  result=$(ocd_validate_workspace "$HOME/workspace/project")
  [ "$result" = "$HOME/workspace" ]
}

@test "ocd_validate_workspace expands ~ in whitelist" {
  export OCD_ALLOWED_WORKSPACES="~/workspace"
  mkdir -p "$HOME/workspace/project/.git"

  result=$(ocd_validate_workspace "$HOME/workspace/project")
  [ "$result" = "$HOME/workspace" ]
}

# =========================================
# set -e 兼容性测试
# =========================================

@test "set -e: ocd_find_parent_project with no parent" {
  mkdir -p "$HOME/workspace/project/.git"

  run bash -c "
    set -e
    export HOME='$HOME'
    source '$OCD_ROOT/lib/core.sh'
    source '$OCD_ROOT/lib/workspace.sh'
    ocd_find_parent_project '$HOME/workspace/project'
    echo 'reached end'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"reached end"* ]]
}

@test "set -e: ocd_validate_workspace without whitelist" {
  mkdir -p "$HOME/workspace/project/.git"

  run bash -c "
    set -e
    export HOME='$HOME'
    source '$OCD_ROOT/lib/core.sh'
    source '$OCD_ROOT/lib/workspace.sh'
    ocd_validate_workspace '$HOME/workspace/project'
    echo 'reached end'
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"reached end"* ]]
}
