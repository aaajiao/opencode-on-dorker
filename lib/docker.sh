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
  local v_opencode="${OPENCODE_AI_VERSION:-1.1.6}"

  local build_args=(
    --build-arg "BUN_VERSION=${v_bun}"
    --build-arg "PIP_REQUESTS=${v_requests}"
    --build-arg "PIP_PANDAS=${v_pandas}"
    --build-arg "PIP_NUMPY=${v_numpy}"
    --build-arg "PIP_MATPLOTLIB=${v_matplotlib}"
    --build-arg "PIP_BEAUTIFULSOUP4=${v_bs4}"
    --build-arg "PIP_PILLOW=${v_pillow}"
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
# 运行容器
# =========================================
ocd_run_container() {
  local container_name="$1"
  local image_name="$2"
  local workspace_root="$3"
  local instance_name="$4"
  local start_dir="$5"
  local env_file="$6"
  shift 6

  # XDG 标准目录 (v3.0)
  local instance_config_dir="$OCD_CONFIG_INSTANCES/${instance_name}"    # 配置
  local instance_data_dir="$OCD_DATA_INSTANCES/${instance_name}"        # 数据 (会话历史)
  local instance_state_dir="$OCD_STATE_INSTANCES/${instance_name}"      # 状态 (IPC 文件)
  local state_dir="$OCD_STATE_HOME"
  local omo_bin_cache="$OCD_CACHE_HOME/oh-my-opencode"
  local playwright_cache="$OCD_CACHE_HOME/ms-playwright"
  local opencode_cache="$OCD_CACHE_HOME"
  local global_opencode="$OCD_CONFIG_GLOBAL/opencode"
  local global_claude="$OCD_CONFIG_GLOBAL/claude"

  # 根据实际启动目录确定项目（确保 TUI/WebUI 看到相同的 transcripts）
  local project_dir
  if [[ -n "$start_dir" && "$start_dir" != "." ]]; then
    project_dir=$(ocd_find_project_dir "${workspace_root}/${start_dir}")
  else
    project_dir=$(ocd_find_project_dir "$workspace_root")
  fi
  local project_claude="${project_dir}/.claude"

  # 确保缓存目录变量有效（防止空变量导致挂载失败）
  if [[ -z "$OCD_CACHE_HOME" || "$OCD_CACHE_HOME" == "/" ]]; then
    ocd_error "OCD_CACHE_HOME 未正确设置 ($OCD_CACHE_HOME)"
    return 1
  fi

  # 确保目录存在（必须在 docker run 之前创建，否则 Docker 会创建 root 权限的空目录）
  ocd_debug "创建实例目录: $instance_config_dir"
  mkdir -p "$instance_config_dir" "$instance_data_dir" "$instance_state_dir"
  ocd_debug "创建缓存目录: $omo_bin_cache/bin"
  mkdir -p "$playwright_cache" "$opencode_cache" "$omo_bin_cache/bin"
  mkdir -p "$OCD_DATA_HOME/bin" "$global_opencode"/{skill,command,agent} "$global_claude"

  # 验证关键目录存在
  if [[ ! -d "$omo_bin_cache/bin" ]]; then
    ocd_debug "⚠️ 无法创建缓存目录 $omo_bin_cache/bin"
  else
    ocd_debug "缓存目录已就绪: $(ls -la "$omo_bin_cache/" 2>&1 || echo '目录不存在')"
  fi
  mkdir -p "$project_claude"/{todos,transcripts} 2>/dev/null || true
  touch "$OCD_DATA_HOME/auth.json" 2>/dev/null || true

  # 删除旧容器
  docker rm -f "$container_name" 2>/dev/null

  # 时区
  local tz
  tz=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo "UTC")

  # 构建挂载参数数组
  ocd_debug "挂载配置: $omo_bin_cache -> /root/.cache/oh-my-opencode"
  local mount_args=(
    -v "${workspace_root}:/workspace"
    -v "${instance_state_dir}:/root/.opencode"
    -v "$OCD_DATA_HOME/auth.json:/root/.local/share/opencode/auth.json"
    -v "$OCD_DATA_HOME/bin:/root/.local/share/opencode/bin"
    -v "${instance_data_dir}:/root/.local/share/opencode/storage"
    -v "${playwright_cache}:/root/.cache/ms-playwright"
    -v "${opencode_cache}:/root/.cache/opencode"
    -v "${omo_bin_cache}:/root/.cache/oh-my-opencode"
    -v "${state_dir}:/root/.local/state/opencode"
    -v "$HOME/.ssh:/root/.ssh:ro"
    -v "${instance_config_dir}:/root/.config/opencode"
    -v "${global_opencode}/skill:/root/.config/opencode/skill"
    -v "${global_opencode}/command:/root/.config/opencode/command"
    -v "${global_opencode}/agent:/root/.config/opencode/agent"
    # 全局 Claude 兼容层（基础挂载）
    -v "${global_claude}:/root/.claude"
    # 项目级会话数据（覆盖挂载）
    -v "${project_claude}/todos:/root/.claude/todos"
    -v "${project_claude}/transcripts:/root/.claude/transcripts"
  )

  # 项目级 Claude 兼容层配置（条件覆盖挂载）
  # 只有当项目目录存在且非空时才覆盖全局配置
  local subdir proj_subdir
  for subdir in skills commands agents rules; do
    proj_subdir="${project_claude}/${subdir}"
    if [[ -d "$proj_subdir" ]] && [[ -n "$(ls -A "$proj_subdir" 2>/dev/null)" ]]; then
      mount_args+=(-v "${proj_subdir}:/root/.claude/${subdir}")
    fi
  done

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
