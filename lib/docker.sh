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

  # 目录变量
  local share_dir="$HOME/.local/share/opencode"
  local instance_config_dir="$HOME/.config/opencode/${instance_name}"
  local instance_data_dir="$HOME/.opencode_data/${instance_name}"
  local instance_storage_dir="${share_dir}/storage/${instance_name}"
  local state_dir="$HOME/.local/state/opencode"
  local omo_bin_cache="$HOME/.cache/oh-my-opencode"
  local playwright_cache="$HOME/.cache/ms-playwright"
  local opencode_cache="$HOME/.cache/opencode"
  local global_opencode="$HOME/opencode/global/opencode"
  local global_claude="$HOME/opencode/global/claude"
  local project_dir
  project_dir=$(ocd_find_project_dir "$workspace_root")
  local project_claude="${project_dir}/.claude"

  # 确保目录存在
  mkdir -p "$playwright_cache" "$opencode_cache"
  mkdir -p "$project_claude"/{todos,transcripts} 2>/dev/null || true

  # 删除旧容器
  docker rm -f "$container_name" 2>/dev/null

  # 时区
  local tz
  tz=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo "UTC")

  docker run -it --rm \
    --name "$container_name" \
    --network host \
    --env-file "$env_file" \
    -e TERM=xterm-256color \
    -e "TZ=$tz" \
    -e BROWSER=/usr/bin/xdg-open \
    -e "EXA_API_KEY=${EXA_API_KEY:-}" \
    -e "OCD_START_DIR=${start_dir}" \
    -v "${workspace_root}:/workspace" \
    -v "${instance_data_dir}:/root/.opencode" \
    -v "${share_dir}/auth.json:/root/.local/share/opencode/auth.json" \
    -v "${share_dir}/bin:/root/.local/share/opencode/bin" \
    -v "${instance_storage_dir}:/root/.local/share/opencode/storage" \
    -v "${playwright_cache}:/root/.cache/ms-playwright" \
    -v "${opencode_cache}:/root/.cache/opencode" \
    -v "${state_dir}:/root/.local/state/opencode" \
    -v "${omo_bin_cache}:/root/.cache/oh-my-opencode" \
    -v "$HOME/.ssh:/root/.ssh:ro" \
    -v "${instance_config_dir}:/root/.config/opencode" \
    -v "${global_opencode}/skill:/root/.config/opencode/skill" \
    -v "${global_opencode}/command:/root/.config/opencode/command" \
    -v "${global_opencode}/agent:/root/.config/opencode/agent" \
    -v "${global_claude}:/root/.claude" \
    -v "${project_claude}/todos:/root/.claude/todos" \
    -v "${project_claude}/transcripts:/root/.claude/transcripts" \
    -w /workspace \
    "$image_name" "$@"
}
