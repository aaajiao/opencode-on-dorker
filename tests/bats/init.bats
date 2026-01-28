#!/usr/bin/env bats
# tests/bats/init.bats - 目录初始化测试 (v5)

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/config.sh"

  export TEST_DIR=$(mktemp -d)

  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
  export OCD_OMO_CACHE_HOME="$TEST_DIR/cache/oh-my-opencode"
  export OCD_IPC_HOME="$TEST_DIR/state/ipc"

  mkdir -p "$OCD_ROOT/templates/project/.opencode"
  mkdir -p "$OCD_ROOT/templates/project/.claude"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# ocd_init_global tests (v5)
# =========================================

@test "ocd_init_global creates OpenCode native directories" {
  ocd_init_global

  [ -d "$OCD_CONFIG_HOME/skills" ]
  [ -d "$OCD_CONFIG_HOME/commands" ]
  [ -d "$OCD_CONFIG_HOME/agents" ]
}

@test "ocd_init_global returns 0 (set -e compatible)" {
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

  [ -d "$OCD_CONFIG_HOME/skills" ]
  [ -d "$OCD_CONFIG_HOME/commands" ]
  [ -d "$OCD_CONFIG_HOME/agents" ]
}

# =========================================
# ocd_init_project tests (v5 - user command)
# =========================================

@test "ocd_init_project creates AGENTS.md from template" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"

  echo "# Test AGENTS.md" > "$OCD_ROOT/templates/project/AGENTS.md.example"

  # Run in non-interactive mode (skip git prompt)
  echo "n" | ocd_init_project "full" 2>/dev/null || true

  [ -f "$project/AGENTS.md" ]
}

@test "ocd_init_project creates .opencode directory structure" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"
  echo "{}" > "$OCD_ROOT/templates/project/.opencode/oh-my-opencode.json.example"

  ocd_init_project "full"

  [ -d "$project/.opencode/agents" ]
  [ -d "$project/.opencode/commands" ]
  [ -d "$project/.opencode/skills" ]
  [ -d "$project/.opencode/plugins" ]
}

@test "ocd_init_project creates .claude directory structure" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"
  echo "{}" > "$OCD_ROOT/templates/project/.claude/settings.json.example"

  ocd_init_project "full"

  [ -d "$project/.claude/agents" ]
  [ -d "$project/.claude/commands" ]
  [ -d "$project/.claude/skills" ]
  [ -d "$project/.claude/rules" ]
  [ ! -d "$project/.claude/todos" ]
  [ ! -d "$project/.claude/transcripts" ]
}

@test "ocd_init_project --minimal only creates AGENTS.md" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"
  echo "{}" > "$OCD_ROOT/templates/project/opencode.json.example"

  ocd_init_project "--minimal"

  [ -f "$project/AGENTS.md" ]
  [ ! -f "$project/opencode.json" ]
  [ ! -d "$project/.opencode" ]
}

@test "ocd_init_project does not overwrite existing files" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Original" > "$project/AGENTS.md"
  echo "# Template" > "$OCD_ROOT/templates/project/AGENTS.md.example"

  ocd_init_project "full"

  result=$(cat "$project/AGENTS.md")
  [[ "$result" == "# Original" ]]
}

@test "ocd_init_project updates .gitignore with local patterns" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet
  touch "$project/.gitignore"

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"

  ocd_init_project "full"

  grep -q ".claude/settings.local.json" "$project/.gitignore"
}

# =========================================
# _ocd_copy_if_not_exists tests
# =========================================

@test "_ocd_copy_if_not_exists copies file when target missing" {
  local src="$TEST_DIR/source.txt"
  local dst="$TEST_DIR/dest.txt"

  echo "content" > "$src"

  run _ocd_copy_if_not_exists "$src" "$dst"

  [ -f "$dst" ]
  [ "$(cat "$dst")" = "content" ]
}

@test "_ocd_copy_if_not_exists skips when target exists" {
  local src="$TEST_DIR/source.txt"
  local dst="$TEST_DIR/dest.txt"

  echo "source" > "$src"
  echo "existing" > "$dst"

  run _ocd_copy_if_not_exists "$src" "$dst"

  [ "$(cat "$dst")" = "existing" ]
}

@test "_ocd_copy_if_not_exists handles missing source" {
  local src="$TEST_DIR/nonexistent.txt"
  local dst="$TEST_DIR/dest.txt"

  run _ocd_copy_if_not_exists "$src" "$dst"

  [ ! -f "$dst" ]
}

# =========================================
# .example file tests (v5.1)
# =========================================

@test "ocd_init_project creates .example reference files" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"
  echo "{}" > "$OCD_ROOT/templates/project/opencode.json.example"
  echo "{}" > "$OCD_ROOT/templates/project/.mcp.json.example.claude"
  echo "{}" > "$OCD_ROOT/templates/project/.opencode/oh-my-opencode.json.example"
  echo "{}" > "$OCD_ROOT/templates/project/.claude/settings.json.example"

  ocd_init_project "full"

  [ -f "$project/opencode.json.example" ]
  [ -f "$project/.mcp.json.example.claude" ]
  [ -f "$project/.opencode/oh-my-opencode.json.example" ]
  [ -f "$project/.claude/settings.json.example" ]
}

@test "ocd_init_project does not create actual config files" {
  local project="$TEST_DIR/myproject"
  mkdir -p "$project"
  cd "$project"
  git init --quiet

  echo "# Test" > "$OCD_ROOT/templates/project/AGENTS.md.example"
  echo "{}" > "$OCD_ROOT/templates/project/opencode.json.example"
  echo "{}" > "$OCD_ROOT/templates/project/.opencode/oh-my-opencode.json.example"

  ocd_init_project "full"

  [ ! -f "$project/opencode.json" ]
  [ ! -f "$project/.opencode/oh-my-opencode.json" ]
  [ ! -f "$project/.claude/settings.json" ]
}

@test "_ocd_copy_example always overwrites existing file" {
  local src="$TEST_DIR/source.txt"
  local dst="$TEST_DIR/dest.txt"

  echo "new content" > "$src"
  echo "old content" > "$dst"

  run _ocd_copy_example "$src" "$dst"

  [ "$(cat "$dst")" = "new content" ]
}
