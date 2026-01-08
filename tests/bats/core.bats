#!/usr/bin/env bats
# tests/bats/core.bats - 核心模块测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
}

# =========================================
# ocd_sanitize_name 测试
# =========================================
@test "sanitize_name: 转小写" {
  result=$(ocd_sanitize_name "MyProject")
  [ "$result" = "myproject" ]
}

@test "sanitize_name: 空格转连字符" {
  result=$(ocd_sanitize_name "My Project")
  [ "$result" = "my-project" ]
}

@test "sanitize_name: 移除特殊字符" {
  result=$(ocd_sanitize_name "my@project#123!")
  [ "$result" = "myproject123" ]
}

@test "sanitize_name: 保留下划线" {
  result=$(ocd_sanitize_name "my_project")
  [ "$result" = "my_project" ]
}

# =========================================
# ocd_load_env 测试
# =========================================
@test "load_env: 加载有效变量" {
  local env_file=$(mktemp)
  echo "TEST_VAR=hello" > "$env_file"
  ocd_load_env "$env_file"
  [ "$TEST_VAR" = "hello" ]
  rm "$env_file"
}

@test "load_env: 跳过注释" {
  local env_file=$(mktemp)
  echo "# COMMENT=value" > "$env_file"
  echo "VALID_VAR=yes" >> "$env_file"
  ocd_load_env "$env_file"
  [ -z "$COMMENT" ]
  [ "$VALID_VAR" = "yes" ]
  rm "$env_file"
}

@test "load_env: 拒绝危险字符" {
  local env_file=$(mktemp)
  echo 'DANGEROUS=$(whoami)' > "$env_file"
  ocd_load_env "$env_file"
  [ -z "$DANGEROUS" ]
  rm "$env_file"
}

@test "load_env: 拒绝引号" {
  local env_file=$(mktemp)
  echo 'QUOTED="value"' > "$env_file"
  ocd_load_env "$env_file"
  [ -z "$QUOTED" ]
  rm "$env_file"
}

@test "load_env: 文件不存在时不报错" {
  run ocd_load_env "/nonexistent/file"
  [ "$status" -eq 0 ]
}

# =========================================
# ocd_version 测试
# =========================================
@test "version: 读取 VERSION 文件" {
  result=$(ocd_version)
  [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [ "$result" = "unknown" ]
}
