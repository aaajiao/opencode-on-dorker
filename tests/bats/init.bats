#!/usr/bin/env bats
# tests/bats/init.bats - 目录初始化测试

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"

  export TEST_DIR=$(mktemp -d)

  # 模拟 XDG 目录
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_CONFIG_GLOBAL="$TEST_DIR/config/global"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_init_global 测试
# =========================================

@test "ocd_init_global creates OpenCode native directories" {
  ocd_init_global

  [ -d "$OCD_CONFIG_GLOBAL/opencode/skill" ]
  [ -d "$OCD_CONFIG_GLOBAL/opencode/command" ]
  [ -d "$OCD_CONFIG_GLOBAL/opencode/agent" ]
}

@test "ocd_init_global creates Claude compat directories" {
  ocd_init_global

  [ -d "$OCD_CONFIG_GLOBAL/claude/skills" ]
  [ -d "$OCD_CONFIG_GLOBAL/claude/commands" ]
  [ -d "$OCD_CONFIG_GLOBAL/claude/agents" ]
  [ -d "$OCD_CONFIG_GLOBAL/claude/rules" ]
}

@test "ocd_init_global creates settings.json if not exists" {
  ocd_init_global

  [ -f "$OCD_CONFIG_GLOBAL/claude/settings.json" ]
  # 应该是空 JSON 对象
  result=$(cat "$OCD_CONFIG_GLOBAL/claude/settings.json")
  [ "$result" = "{}" ]
}

@test "ocd_init_global creates .mcp.json if not exists" {
  ocd_init_global

  [ -f "$OCD_CONFIG_GLOBAL/claude/.mcp.json" ]
  # 应该包含 mcpServers
  run jq '.mcpServers' "$OCD_CONFIG_GLOBAL/claude/.mcp.json"
  [ "$status" -eq 0 ]
}

@test "ocd_init_global does not overwrite existing files" {
  mkdir -p "$OCD_CONFIG_GLOBAL/claude"
  echo '{"custom": true}' > "$OCD_CONFIG_GLOBAL/claude/settings.json"

  ocd_init_global

  # 应保留原内容
  result=$(jq '.custom' "$OCD_CONFIG_GLOBAL/claude/settings.json")
  [ "$result" = "true" ]
}

@test "ocd_init_global returns 0 (set -e compatible)" {
  # 这个测试确保函数在 set -e 下不会导致脚本退出
  set -e
  ocd_init_global
  result=$?
  set +e

  [ "$result" -eq 0 ]
}

@test "ocd_init_global idempotent - can run multiple times" {
  ocd_init_global
  ocd_init_global
  ocd_init_global

  # 目录应该存在
  [ -d "$OCD_CONFIG_GLOBAL/opencode/skill" ]
  [ -d "$OCD_CONFIG_GLOBAL/claude/skills" ]
}

# =========================================
# ocd_init_project 测试
# =========================================

@test "ocd_init_project creates OpenCode native directories" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"

  ocd_init_project "$project"

  [ -d "$project/.opencode/skill" ]
  [ -d "$project/.opencode/command" ]
  [ -d "$project/.opencode/agent" ]
}

@test "ocd_init_project creates Claude session directories" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"

  ocd_init_project "$project"

  [ -d "$project/.claude/todos" ]
  [ -d "$project/.claude/transcripts" ]
}

@test "ocd_init_project does NOT create Claude config directories" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"

  ocd_init_project "$project"

  # 不应自动创建这些目录（用户手动创建才启用覆盖）
  [ ! -d "$project/.claude/skills" ]
  [ ! -d "$project/.claude/commands" ]
  [ ! -d "$project/.claude/agents" ]
  [ ! -d "$project/.claude/rules" ]
}

@test "ocd_init_project handles non-writable directory gracefully" {
  local project="/nonexistent/path"

  # 应该静默失败（不报错）
  run ocd_init_project "$project"
  # 由于使用了 2>/dev/null || true，应该成功
  [ "$status" -eq 0 ]
}
