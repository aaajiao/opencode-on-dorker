#!/usr/bin/env bats
# tests/bats/workspace.bats - 工作区模块测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/workspace.sh"

  # 创建测试目录
  export TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/workspace/project/.git"
  mkdir -p "$TEST_DIR/workspace/project/src"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset OCD_ALLOWED_WORKSPACES
}

# =========================================
# ocd_find_workspace_root 测试
# =========================================
@test "find_workspace_root: 找到 git 仓库的父目录" {
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project/src")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root: 从项目根目录" {
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root: 白名单允许" {
  export OCD_ALLOWED_WORKSPACES="$TEST_DIR/workspace"
  result=$(ocd_find_workspace_root "$TEST_DIR/workspace/project")
  [ "$result" = "$TEST_DIR/workspace" ]
}

@test "find_workspace_root: 白名单拒绝" {
  export OCD_ALLOWED_WORKSPACES="/allowed/path"
  run ocd_find_workspace_root "$TEST_DIR/workspace/project"
  [ "$status" -eq 1 ]
  [[ "$output" == *"BLOCKED"* ]]
}

# =========================================
# ocd_get_relative_path 测试
# =========================================
@test "get_relative_path: 计算相对路径" {
  result=$(ocd_get_relative_path "/base" "/base/sub/dir")
  [ "$result" = "sub/dir" ]
}

@test "get_relative_path: 相同路径返回空" {
  result=$(ocd_get_relative_path "/base" "/base")
  [ "$result" = "" ]
}

@test "get_relative_path: 不相关路径返回空" {
  result=$(ocd_get_relative_path "/base" "/other/path")
  [ "$result" = "" ]
}

# =========================================
# ocd_find_project_dir 测试
# =========================================
@test "find_project_dir: 找到包含 .git 的目录" {
  result=$(ocd_find_project_dir "$TEST_DIR/workspace/project/src")
  [ "$result" = "$TEST_DIR/workspace/project" ]
}

@test "find_project_dir: 没有 .git 返回当前目录" {
  mkdir -p "$TEST_DIR/no_git/sub"
  result=$(ocd_find_project_dir "$TEST_DIR/no_git/sub")
  [ "$result" = "$TEST_DIR/no_git/sub" ]
}
