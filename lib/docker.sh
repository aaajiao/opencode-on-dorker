#!/usr/bin/env bash
# lib/docker.sh - Docker 容器操作

# =========================================
# 构建 Docker 镜像
# =========================================
ocd_build_image() {
  local image_name="$1"
  local no_cache="${2:-0}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"

  # 版本变量
  local v_bun="${BUN_VERSION:-1.3.5}"
  local v_requests="${PIP_REQUESTS:-2.32.5}"
  local v_pandas="${PIP_PANDAS:-2.2.3}"
  local v_numpy="${PIP_NUMPY:-2.2.1}"
  local v_matplotlib="${PIP_MATPLOTLIB:-3.10.0}"
  local v_bs4="${PIP_BEAUTIFULSOUP4:-4.12.3}"
  local v_pillow="${PIP_PILLOW:-11.1.0}"
  local v_notebooklm="${PIP_NOTEBOOKLM_PY:-0.1.4}"
  local v_opencode="${OPENCODE_AI_VERSION:-1.1.6}"

  local build_args=(
    --build-arg "BUN_VERSION=${v_bun}"
    --build-arg "PIP_REQUESTS=${v_requests}"
    --build-arg "PIP_PANDAS=${v_pandas}"
    --build-arg "PIP_NUMPY=${v_numpy}"
    --build-arg "PIP_MATPLOTLIB=${v_matplotlib}"
    --build-arg "PIP_BEAUTIFULSOUP4=${v_bs4}"
    --build-arg "PIP_PILLOW=${v_pillow}"
    --build-arg "PIP_NOTEBOOKLM_PY=${v_notebooklm}"
    --build-arg "OPENCODE_AI_VERSION=${v_opencode}"
  )

  echo "📦 版本: Bun=${v_bun} OpenCode=${v_opencode}"

  if [[ "$no_cache" -eq 1 ]]; then
    echo "🏗️  正在完全重建镜像 (无缓存)..."
    docker build --no-cache "${build_args[@]}" -t "$image_name" "$ocd_root"
  else
    echo "🏗️  正在构建镜像..."
    docker build "${build_args[@]}" -t "$image_name" "$ocd_root"
  fi
}

# =========================================
# 检查镜像是否存在
# =========================================
ocd_image_exists() {
  local image_name="$1"
  docker image inspect "$image_name" &>/dev/null
}

# =========================================
# 删除镜像
# =========================================
ocd_remove_image() {
  local image_name="$1"
  echo "🗑️  删除旧镜像..."
  docker rmi "$image_name" 2>/dev/null || true
}

# =========================================
# 运行容器 (v5: 全局 ~/.claude + 项目级覆盖)
# =========================================
ocd_run_container() {
  local container_name="$1"
  local image_name="$2"
  local workspace_root="$3"
  local port="$4"
  local start_dir="$5"
  local env_file="$6"
  shift 6

  local ipc_dir
  ipc_dir=$(ocd_ipc_dir "$port")

  local project_dir
  if [[ "${OCD_DEV_MODE:-0}" -eq 1 ]]; then
    project_dir="${OCD_ROOT:-$HOME/opencode/dev}"
  else
    if [[ -n "$start_dir" && "$start_dir" != "." ]]; then
      project_dir=$(ocd_find_project_dir "${workspace_root}/${start_dir}")
    else
      project_dir=$(ocd_find_project_dir "$workspace_root")
    fi
  fi

  local global_claude="$OCD_CLAUDE_HOME"
  local project_claude="${project_dir}/.claude"

  if [[ -z "$OCD_CACHE_HOME" || "$OCD_CACHE_HOME" == "/" ]]; then
    ocd_error "OCD_CACHE_HOME 未正确设置 ($OCD_CACHE_HOME)"
    return 1
  fi

  mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}
  mkdir -p "$OCD_DATA_HOME"/{bin,storage}
  mkdir -p "$OCD_OMO_CACHE_HOME/bin"
  mkdir -p "$global_claude"/{commands,skills,agents,rules}
  mkdir -p "$OCD_CLAUDE_RUNTIME"/{todos,transcripts}
  touch "$OCD_DATA_HOME/auth.json" 2>/dev/null || true

  docker rm -f "$container_name" 2>/dev/null

  local tz
  tz=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo "UTC")

  local mount_args=(
    -v "${workspace_root}:/workspace"
    -v "${ipc_dir}:/root/.opencode"
    -v "$OCD_CONFIG_HOME:/root/.config/opencode"
    -v "$OCD_DATA_HOME:/root/.local/share/opencode"
    -v "$OCD_STATE_HOME:/root/.local/state/opencode"
    -v "$OCD_CACHE_HOME:/root/.cache/opencode"
    -v "$OCD_OMO_CACHE_HOME:/root/.cache/oh-my-opencode"
    -v "$HOME/.ssh:/root/.ssh:ro"
    -v "$global_claude:/root/.claude:ro"
    -v "$OCD_CLAUDE_RUNTIME/todos:/root/.claude/todos"
    -v "$OCD_CLAUDE_RUNTIME/transcripts:/root/.claude/transcripts"
  )

  local subdir proj_subdir
  for subdir in commands skills agents rules; do
    proj_subdir="${project_claude}/${subdir}"
    if [[ -d "$proj_subdir" ]] && [[ -n "$(ls -A "$proj_subdir" 2>/dev/null)" ]]; then
      mount_args+=(-v "${proj_subdir}:/root/.claude/${subdir}:ro")
    fi
  done

  if [[ -f "${project_claude}/settings.json" ]]; then
    mount_args+=(-v "${project_claude}/settings.json:/root/.claude/settings.json:ro")
  fi

  if [[ -f "${project_claude}/.mcp.json" ]]; then
    mount_args+=(-v "${project_claude}/.mcp.json:/root/.claude/.mcp.json:ro")
  fi

  ocd_debug "启动容器: $container_name"
  docker run -it --rm \
    --name "$container_name" \
    --network host \
    --env-file "$env_file" \
    -e TERM=xterm-256color \
    -e "TZ=$tz" \
    -e BROWSER=/usr/bin/xdg-open \
    -e "EXA_API_KEY=${EXA_API_KEY:-}" \
    -e "OCD_START_DIR=${start_dir}" \
    -e "OCD_DEBUG=${OCD_DEBUG:-0}" \
    "${mount_args[@]}" \
    -w /workspace \
    "$image_name" "$@"
}
