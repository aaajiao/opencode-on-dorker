#!/usr/bin/env bats
# tests/bats/port.bats - 端口管理模块测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/port.sh"

  # 清理测试环境
  export TEST_CONFIG_DIR=$(mktemp -d)
  export HOME="$TEST_CONFIG_DIR"
  mkdir -p "$HOME/.config/opencode"
}

teardown() {
  rm -rf "$TEST_CONFIG_DIR"
}

# =========================================
# ocd_find_free_port 测试
# =========================================
@test "find_free_port: 返回基础端口范围内的端口" {
  result=$(ocd_find_free_port 4096)
  [ "$result" -ge 4096 ]
  [ "$result" -lt 4196 ]
}

@test "find_free_port: 使用自定义基础端口" {
  result=$(ocd_find_free_port 5000)
  [ "$result" -ge 5000 ]
  [ "$result" -lt 5100 ]
}

@test "find_free_port: 连续调用返回不同端口" {
  port1=$(ocd_find_free_port 4096)
  port2=$(ocd_find_free_port 4096)
  [ "$port1" != "$port2" ]
}

@test "find_free_port: 创建端口记录文件" {
  ocd_find_free_port 4096
  [ -f "$HOME/.config/opencode/.last_port" ]
}
