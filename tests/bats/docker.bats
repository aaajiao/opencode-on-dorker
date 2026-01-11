#!/usr/bin/env bats
# tests/bats/docker.bats - Docker 挂载和目录创建测试 (v4.0)
#
# 注意：这些测试不需要真正运行 Docker，只测试挂载参数构建逻辑

setup() {
  export OCD_ROOT="$BATS_TEST_DIRNAME/../.."
  export TEST_DIR=$(mktemp -d)

  # 模拟 XDG 目录 (v4.0 - 无 instance 概念)
  export OCD_CONFIG_HOME="$TEST_DIR/config"
  export OCD_DATA_HOME="$TEST_DIR/data"
  export OCD_STATE_HOME="$TEST_DIR/state"
  export OCD_CACHE_HOME="$TEST_DIR/cache"
  export OCD_OMO_CACHE_HOME="$TEST_DIR/cache/oh-my-opencode"
  export OCD_IPC_HOME="$TEST_DIR/state/ipc"
  export HOME="$TEST_DIR/home"

  mkdir -p "$HOME"
  mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}

  source "$OCD_ROOT/lib/core.sh"
  source "$OCD_ROOT/lib/workspace.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =========================================
# 目录创建测试（docker.sh 中的 mkdir 逻辑）
# =========================================

@test "docker mkdir creates oh-my-opencode/bin directory" {
  local omo_bin_cache="$OCD_CACHE_HOME/oh-my-opencode"

  # 模拟 docker.sh 中的目录创建
  mkdir -p "$omo_bin_cache/bin"

  [ -d "$omo_bin_cache/bin" ]
}

@test "docker mkdir creates all required cache directories" {
  local playwright_cache="$OCD_CACHE_HOME/ms-playwright"
  local opencode_cache="$OCD_CACHE_HOME"
  local omo_bin_cache="$OCD_CACHE_HOME/oh-my-opencode"

  mkdir -p "$playwright_cache" "$opencode_cache" "$omo_bin_cache/bin"

  [ -d "$playwright_cache" ]
  [ -d "$opencode_cache" ]
  [ -d "$omo_bin_cache/bin" ]
}

@test "docker mkdir creates global .claude directories" {
  local global_claude="$HOME/.claude"

  mkdir -p "$global_claude"/{todos,transcripts,commands,skills,agents,rules}

  [ -d "$global_claude/todos" ]
  [ -d "$global_claude/transcripts" ]
  [ -d "$global_claude/commands" ]
  [ -d "$global_claude/rules" ]
}

@test "project .claude only has config dirs not todos/transcripts" {
  local project="$TEST_DIR/workspace/myproject"
  local project_claude="$project/.claude"

  mkdir -p "$project_claude"/{commands,skills,agents,rules}

  [ -d "$project_claude/commands" ]
  [ -d "$project_claude/rules" ]
  [ ! -d "$project_claude/todos" ]
  [ ! -d "$project_claude/transcripts" ]
}

# =========================================
# 条件挂载逻辑测试
# =========================================

@test "conditional mount: empty project dir uses global" {
  local project="$TEST_DIR/workspace/myproject"
  local project_claude="$project/.claude"

  mkdir -p "$project_claude/agents"  # 创建但为空

  # 检查目录是否为空
  local is_empty=true
  if [[ -d "$project_claude/agents" ]] && [[ -n "$(ls -A "$project_claude/agents" 2>/dev/null)" ]]; then
    is_empty=false
  fi

  [ "$is_empty" = "true" ]
}

@test "conditional mount: non-empty project dir overrides global" {
  local project="$TEST_DIR/workspace/myproject"
  local project_claude="$project/.claude"

  mkdir -p "$project_claude/agents"
  echo "test agent" > "$project_claude/agents/test.md"

  # 检查目录是否非空
  local should_mount=false
  if [[ -d "$project_claude/agents" ]] && [[ -n "$(ls -A "$project_claude/agents" 2>/dev/null)" ]]; then
    should_mount=true
  fi

  [ "$should_mount" = "true" ]
}

@test "conditional mount: all subdirs checked" {
  local project="$TEST_DIR/workspace/myproject"
  local project_claude="$project/.claude"

  # 创建一些空的，一些非空的
  mkdir -p "$project_claude/skills"
  mkdir -p "$project_claude/commands"
  mkdir -p "$project_claude/agents"
  mkdir -p "$project_claude/rules"

  echo "test" > "$project_claude/agents/test.md"  # 只有 agents 非空

  local mount_count=0
  for subdir in skills commands agents rules; do
    local proj_subdir="$project_claude/$subdir"
    if [[ -d "$proj_subdir" ]] && [[ -n "$(ls -A "$proj_subdir" 2>/dev/null)" ]]; then
      mount_count=$((mount_count + 1))
    fi
  done

  [ "$mount_count" -eq 1 ]  # 只有 agents 应该挂载
}

# =========================================
# 挂载参数数组构建测试
# =========================================

@test "mount_args array can be extended" {
  local mount_args=(
    -v "/path/a:/container/a"
    -v "/path/b:/container/b"
  )

  # 模拟条件添加
  mount_args+=(-v "/path/c:/container/c")

  [ "${#mount_args[@]}" -eq 6 ]  # 3 个 -v 参数对
}

@test "mount_args handles paths with spaces" {
  local path_with_space="$TEST_DIR/path with spaces"
  mkdir -p "$path_with_space"

  local mount_args=()
  mount_args+=(-v "${path_with_space}:/container/path")

  # 数组应该正确保留带空格的路径
  [[ "${mount_args[1]}" == *"path with spaces"* ]]
}

# =========================================
# IPC 文件创建测试 (v4.0 - 按端口区分)
# =========================================

@test "IPC files created and empty" {
  local port="4096"
  local ipc_dir="$OCD_IPC_HOME/$port"
  mkdir -p "$ipc_dir"

  local url_file="$ipc_dir/open_url"
  local notify_file="$ipc_dir/notifications"
  local clipboard_file="$ipc_dir/clipboard"

  : > "$url_file" && : > "$notify_file" && : > "$clipboard_file"

  [ -f "$url_file" ]
  [ -f "$notify_file" ]
  [ -f "$clipboard_file" ]
  [ ! -s "$url_file" ]  # 应该为空
}

@test "IPC directories isolated by port" {
  local port1="4096"
  local port2="5000"
  local ipc_dir1="$OCD_IPC_HOME/$port1"
  local ipc_dir2="$OCD_IPC_HOME/$port2"

  mkdir -p "$ipc_dir1" "$ipc_dir2"
  echo "test1" > "$ipc_dir1/clipboard"
  echo "test2" > "$ipc_dir2/clipboard"

  # 两个端口的 IPC 文件应该独立
  [ "$(cat "$ipc_dir1/clipboard")" = "test1" ]
  [ "$(cat "$ipc_dir2/clipboard")" = "test2" ]
}

@test "ocd_ipc_dir returns correct path" {
  result=$(ocd_ipc_dir "5000")
  [ "$result" = "$OCD_IPC_HOME/5000" ]
}

# =========================================
# 项目检测测试
# =========================================

@test "ocd_find_project_dir finds git project" {
  local workspace="$TEST_DIR/workspace"
  local project="$workspace/myproject"

  mkdir -p "$project/.git"

  result=$(ocd_find_project_dir "$project/src/deep/nested")

  [ "$result" = "$project" ]
}

@test "ocd_find_project_dir returns input if no git found" {
  local workspace="$TEST_DIR/workspace"
  local dir="$workspace/random/path"

  mkdir -p "$dir"

  result=$(ocd_find_project_dir "$dir")

  [ "$result" = "$dir" ]
}
