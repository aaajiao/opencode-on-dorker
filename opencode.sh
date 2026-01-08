# OCD - OpenCode Docker (支持 oh-my-opencode + 多实例)
# 添加到 ~/.zshrc 或 ~/.bashrc
#
# 用法:
#   ocd                   # 实例名=当前目录名，自动分配端口
#   ocd -p 5000           # 指定端口
#   ocd -n myname         # 指定实例名
#   ocd -r                # 重建镜像 + 清理所有实例配置
#   ocd -r --keep         # 重建镜像 + 保留配置
#   ocd --quotio          # 启用 Quotio 代理（需配置 QUOTIO_API_KEY）
#   ocd -v                # 显示版本号

# =========================================
# 版本号
# =========================================
_ocd_version() {
  local VERSION_FILE="$HOME/opencode/VERSION"
  if [[ -f "$VERSION_FILE" ]]; then
    cat "$VERSION_FILE"
  else
    echo "unknown"
  fi
}

# =========================================
# 辅助函数：加载版本锁定文件
# =========================================
_ocd_load_versions() {
  local VERSIONS_FILE="$HOME/opencode/versions.lock"
  [[ ! -f "$VERSIONS_FILE" ]] && return 0

  local key value line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过注释和空行
    [[ -z "$line" || "$line" == \#* ]] && continue
    # 提取 KEY=VALUE
    key="${line%%=*}"
    value="${line#*=}"
    # 验证 key 格式并导出
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [[ -n "$value" ]] && export "$key=$value"
  done < "$VERSIONS_FILE"
}

# =========================================
# 辅助函数：清理实例名 ("My Project" -> "my-project")
# =========================================
_ocd_sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_'
}

# =========================================
# 辅助函数：查找工作区根目录
# 逻辑：向上查找 .git，返回其父目录的父目录
# 例如：~/projects/webapp/src → ~/projects
# =========================================
_ocd_find_workspace_root() {
  local current_dir="$1"
  local found_git=""
  local dir="$current_dir"
  
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/.git" ]]; then
      found_git="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done
  
  if [[ -n "$found_git" ]]; then
    dirname "$found_git"
  elif [[ -n "${OCD_WORKSPACE:-}" ]]; then
    echo "${OCD_WORKSPACE/#\~/$HOME}"
  else
    echo "$current_dir"
  fi
}

# =========================================
# 辅助函数：计算相对路径
# =========================================
_ocd_get_relative_path() {
  local base="$1"
  local target="$2"
  
  if [[ "$target" == "$base" ]]; then
    echo ""
  elif [[ "$target" == "$base"/* ]]; then
    echo "${target#$base/}"
  else
    echo ""
  fi
}

# =========================================
# 辅助函数：查找当前项目目录（包含 .git 的目录）
# =========================================
_ocd_find_project_dir() {
  local current_dir="$1"
  local dir="$current_dir"
  
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  
  echo "$current_dir"
}

# =========================================
# 辅助函数：首次运行依赖提示
# =========================================
_ocd_check_dependencies() {
  local hint_file="$HOME/.config/opencode/.deps-hint-shown"

  # 只提示一次
  [[ -f "$hint_file" ]] && return 0

  local missing=()

  command -v jq &>/dev/null || missing+=("jq (智能配置更新)")
  command -v fswatch &>/dev/null || missing+=("fswatch (降低 CPU 占用)")
  command -v terminal-notifier &>/dev/null || missing+=("terminal-notifier (自定义通知图标)")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "💡 可选依赖（安装后体验更好）:"
    for dep in "${missing[@]}"; do
      echo "   • $dep"
    done
    echo ""
    echo "   一键安装: brew install jq fswatch terminal-notifier"
    echo ""
  fi

  mkdir -p "$(dirname "$hint_file")"
  touch "$hint_file"
}

# =========================================
# 辅助函数：安全加载环境变量
# =========================================
_ocd_load_env() {
  local env_file="$1"
  [[ ! -f "$env_file" ]] && return 0

  local key value line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过注释和空行
    [[ -z "$line" || "$line" == \#* ]] && continue
    # 跳过包含危险字符的行
    [[ "$line" == *[\;\$\(\)\"\']* ]] && continue
    # 提取 KEY=VALUE
    key="${line%%=*}"
    value="${line#*=}"
    # 验证 key 格式
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [[ -n "$value" ]] && export "$key=$value"
  done < "$env_file"
}

# =========================================
# 辅助函数：查找空闲端口（macOS/zsh 兼容）
# =========================================
_ocd_find_free_port() {
  local base_port=${1:-4096}
  local lock_dir="$HOME/.config/opencode"
  local lock_file="${lock_dir}/.port.lock"
  local port_file="${lock_dir}/.last_port"

  mkdir -p "$lock_dir"

  # 使用 mkdir 作为原子锁（macOS 兼容）
  local max_wait=10
  local waited=0
  while ! mkdir "$lock_file" 2>/dev/null; do
    sleep 0.5
    waited=$((waited + 1))
    if [[ $waited -ge $max_wait ]]; then
      rm -rf "$lock_file"  # 强制解锁
      break
    fi
  done

  # 一次性获取所有监听端口
  local used_ports
  used_ports=$(lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1{print $9}' | grep -oE '[0-9]+$' | sort -u)

  # 从上次分配的端口+1 开始（减少冲突）
  local start_port=$base_port
  if [[ -f "$port_file" ]]; then
    start_port=$(( $(cat "$port_file") + 1 ))
    [[ $start_port -ge $((base_port + 100)) ]] && start_port=$base_port
  fi

  # 查找空闲端口
  local found_port=""
  for ((p=start_port; p<base_port+100; p++)); do
    if ! echo "$used_ports" | grep -qw "$p"; then
      found_port=$p
      break
    fi
  done

  # 回绕检查
  if [[ -z "$found_port" ]]; then
    for ((p=base_port; p<start_port; p++)); do
      if ! echo "$used_ports" | grep -qw "$p"; then
        found_port=$p
        break
      fi
    done
  fi

  # 记录并输出
  found_port=${found_port:-$base_port}
  echo "$found_port" > "$port_file"
  echo "$found_port"

  # 解锁
  rm -rf "$lock_file" 2>/dev/null
}

# =========================================
# 辅助函数：处理 URL 打开
# =========================================
_ocd_handle_url() {
  local url_file="$1"
  [[ ! -s "$url_file" ]] && return

  while IFS= read -r url; do
    [[ -n "$url" ]] && open "$url"
  done < "$url_file"
  : > "$url_file"
}

# =========================================
# 辅助函数：处理通知
# =========================================
_ocd_handle_notify() {
  local notify_file="$1"
  local icon_file="$HOME/opencode/ghostty-128.png"

  [[ ! -s "$notify_file" ]] && return

  while IFS='|' read -r title msg; do
    if [[ -n "$msg" ]]; then
      if command -v terminal-notifier &>/dev/null && [[ -f "$icon_file" ]]; then
        terminal-notifier -title "$title" -message "$msg" -contentImage "$icon_file" -sound Morse
      else
        osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
      fi
    fi
  done < "$notify_file"
  : > "$notify_file"
}

# =========================================
# 辅助函数：处理剪贴板
# =========================================
_ocd_handle_clipboard() {
  local clipboard_file="$1"
  [[ ! -s "$clipboard_file" ]] && return
  pbcopy < "$clipboard_file" 2>/dev/null || true
  : > "$clipboard_file"
}

# =========================================
# 辅助函数：获取 Tailscale IP（远程访问）
# =========================================
_ocd_get_tailscale_ip() {
  command -v tailscale &>/dev/null || return 1
  local ts_status
  ts_status=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4 || echo "")
  [[ "$ts_status" != "Running" ]] && return 1
  tailscale ip -4 2>/dev/null
}

# =========================================
# 辅助函数：启动 Watcher（自动选择最优方式）
# =========================================
_ocd_start_watcher() {
  local url_file="$1"
  local notify_file="$2"
  local clipboard_file="$3"

  (
    exec </dev/null >/dev/null 2>&1
    if command -v fswatch &>/dev/null; then
      fswatch -o --event Created --event Updated "$url_file" "$notify_file" "$clipboard_file" 2>/dev/null | \
      while IFS= read -r _; do
        _ocd_handle_url "$url_file"
        _ocd_handle_notify "$notify_file"
        _ocd_handle_clipboard "$clipboard_file"
      done
    else
      while true; do
        _ocd_handle_url "$url_file"
        _ocd_handle_notify "$notify_file"
        _ocd_handle_clipboard "$clipboard_file"
        sleep 1
      done
    fi
  ) &

  echo $!
}

# =========================================
# 全局变量：Watcher PID（用于清理）
# =========================================
_OCD_WATCHER_PID=""

# =========================================
# 辅助函数：清理 Watcher 进程和 Tailscale Serve
# =========================================
_OCD_HTTPS_ENABLED=""

_ocd_cleanup() {
  if [[ -n "$_OCD_WATCHER_PID" ]]; then
    kill -TERM -- -"$_OCD_WATCHER_PID" 2>/dev/null || kill -TERM "$_OCD_WATCHER_PID" 2>/dev/null
    _OCD_WATCHER_PID=""
  fi
  if [[ -n "$_OCD_HTTPS_ENABLED" ]]; then
    tailscale serve off &>/dev/null
    _OCD_HTTPS_ENABLED=""
  fi
}

ocd() {
  local IMAGE_NAME="opencode-bun"
  local ENV_FILE="$HOME/opencode/.env"
  local SHARE_DIR="$HOME/.local/share/opencode"

  local REBUILD=0
  local KEEP_CONFIG=0
  local INSTANCE_NAME=""
  local CUSTOM_PORT=""
  local USE_QUOTIO=0
  local CUSTOM_WORKSPACE=""
  local USE_HERE=0
  local USE_HTTPS=0

  trap '_ocd_cleanup' INT TERM HUP

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--version)
        echo "OCD v$(_ocd_version)"
        return 0
        ;;
      -r) REBUILD=1; shift ;;
      --keep) KEEP_CONFIG=1; shift ;;
      --quotio) USE_QUOTIO=1; shift ;;
      --https) USE_HTTPS=1; shift ;;
      -n) INSTANCE_NAME="$2"; shift 2 ;;
      -p) CUSTOM_PORT="$2"; shift 2 ;;
      -w|--workspace) CUSTOM_WORKSPACE="$2"; shift 2 ;;
      --here) USE_HERE=1; shift ;;
      -h|--help)
        echo "OCD v$(_ocd_version) - OpenCode Docker"
        echo ""
        echo "Usage: ocd [options]"
        echo ""
        echo "Options:"
        echo "  -v, --version     Show version"
        echo "  -r                Rebuild image (add --keep to preserve config)"
        echo "  -n <name>         Instance name"
        echo "  -p <port>         Port number"
        echo "  -w <path>         Workspace root directory"
        echo "  --here            Mount current directory only (legacy mode)"
        echo "  --https           Enable HTTPS via Tailscale Serve"
        echo "  --quotio          Enable Quotio provider"
        echo "  -h, --help        Show this help"
        echo ""
        echo "Environment:"
        echo "  OCD_WORKSPACE     Default workspace root directory"
        return 0
        ;;
      *) break ;;
    esac
  done

  local CURRENT_DIR="$(pwd)"
  local WORKSPACE_ROOT=""
  local START_DIR=""
  local PROJECT_DIR=""

  if [[ "$USE_HERE" -eq 1 ]]; then
    WORKSPACE_ROOT="$CURRENT_DIR"
    START_DIR=""
    PROJECT_DIR="$CURRENT_DIR"
  elif [[ -n "$CUSTOM_WORKSPACE" ]]; then
    WORKSPACE_ROOT="${CUSTOM_WORKSPACE/#\~/$HOME}"
    START_DIR=$(_ocd_get_relative_path "$WORKSPACE_ROOT" "$CURRENT_DIR")
    PROJECT_DIR=$(_ocd_find_project_dir "$CURRENT_DIR")
  else
    WORKSPACE_ROOT=$(_ocd_find_workspace_root "$CURRENT_DIR")
    START_DIR=$(_ocd_get_relative_path "$WORKSPACE_ROOT" "$CURRENT_DIR")
    PROJECT_DIR=$(_ocd_find_project_dir "$CURRENT_DIR")
  fi

  if [[ -z "$INSTANCE_NAME" ]]; then
    INSTANCE_NAME=$(_ocd_sanitize_name "$(basename "$WORKSPACE_ROOT")")
  fi

  # 容器名
  local CONTAINER_NAME="opencode-${INSTANCE_NAME}"

  # 实例独立目录
  local INSTANCE_CONFIG_DIR="$HOME/.config/opencode/${INSTANCE_NAME}"
  local INSTANCE_DATA_DIR="$HOME/.opencode_data/${INSTANCE_NAME}"

  # 实例独立的存储目录（session 隔离）
  local INSTANCE_STORAGE_DIR="${SHARE_DIR}/storage/${INSTANCE_NAME}"

  # 全局状态目录（KV store，UI 设置持久化）
  local STATE_DIR="$HOME/.local/state/opencode"

  # oh-my-opencode 二进制缓存（ast-grep, ripgrep）
  local OMO_BIN_CACHE="$HOME/.cache/oh-my-opencode"

  # 实例独立文件
  local URL_FILE="${INSTANCE_DATA_DIR}/open_url"
  local NOTIFY_FILE="${INSTANCE_DATA_DIR}/notifications"
  local CLIPBOARD_FILE="${INSTANCE_DATA_DIR}/clipboard"
  local CONFIG_FILE="${INSTANCE_CONFIG_DIR}/opencode.json"
  local OMO_CONFIG_FILE="${INSTANCE_CONFIG_DIR}/oh-my-opencode.json"

  # 端口分配
  local PORT
  if [[ -n "$CUSTOM_PORT" ]]; then
    PORT="$CUSTOM_PORT"
  else
    PORT=$(_ocd_find_free_port 4096)
  fi

  # 加载版本锁定文件
  _ocd_load_versions

  # 版本变量（带默认值）
  local V_BUN="${BUN_VERSION:-1.3.5}"
  local V_REQUESTS="${PIP_REQUESTS:-2.32.5}"
  local V_PANDAS="${PIP_PANDAS:-2.2.3}"
  local V_NUMPY="${PIP_NUMPY:-2.2.1}"
  local V_MATPLOTLIB="${PIP_MATPLOTLIB:-3.10.0}"
  local V_BS4="${PIP_BEAUTIFULSOUP4:-4.12.3}"
  local V_PILLOW="${PIP_PILLOW:-11.1.0}"
  local V_OPENCODE="${OPENCODE_AI_VERSION:-1.1.4}"

  if [[ "$REBUILD" -eq 1 ]]; then
    echo "🗑️  删除旧镜像..."
    docker rmi "$IMAGE_NAME" 2>/dev/null
    if [[ "$KEEP_CONFIG" -eq 0 ]]; then
      echo "🗑️  删除所有实例配置..."
      rm -rf "$HOME/.config/opencode"
      rm -rf "$HOME/.opencode_data"
    else
      echo "📦 保留现有配置..."
    fi
    echo "🗑️  清除插件缓存..."
    rm -rf "$HOME/.cache/opencode/node_modules"
    echo "🏗️  正在完全重建镜像 (无缓存)..."
    echo "📦 版本: Bun=${V_BUN} OpenCode=${V_OPENCODE}"
    docker build --no-cache \
      --build-arg "BUN_VERSION=${V_BUN}" \
      --build-arg "PIP_REQUESTS=${V_REQUESTS}" \
      --build-arg "PIP_PANDAS=${V_PANDAS}" \
      --build-arg "PIP_NUMPY=${V_NUMPY}" \
      --build-arg "PIP_MATPLOTLIB=${V_MATPLOTLIB}" \
      --build-arg "PIP_BEAUTIFULSOUP4=${V_BS4}" \
      --build-arg "PIP_PILLOW=${V_PILLOW}" \
      --build-arg "OPENCODE_AI_VERSION=${V_OPENCODE}" \
      -t "$IMAGE_NAME" "$HOME/opencode"
  elif ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "🏗️  正在构建镜像..."
    echo "📦 版本: Bun=${V_BUN} OpenCode=${V_OPENCODE}"
    docker build \
      --build-arg "BUN_VERSION=${V_BUN}" \
      --build-arg "PIP_REQUESTS=${V_REQUESTS}" \
      --build-arg "PIP_PANDAS=${V_PANDAS}" \
      --build-arg "PIP_NUMPY=${V_NUMPY}" \
      --build-arg "PIP_MATPLOTLIB=${V_MATPLOTLIB}" \
      --build-arg "PIP_BEAUTIFULSOUP4=${V_BS4}" \
      --build-arg "PIP_PILLOW=${V_PILLOW}" \
      --build-arg "OPENCODE_AI_VERSION=${V_OPENCODE}" \
      -t "$IMAGE_NAME" "$HOME/opencode"
  fi

  # 首次运行依赖提示
  _ocd_check_dependencies

  # 初始化配置
  _ocd_init_global
  _ocd_init_project "$(pwd)"
  mkdir -p "$INSTANCE_DATA_DIR"
  mkdir -p "$INSTANCE_CONFIG_DIR"
  mkdir -p "$SHARE_DIR/bin"
  mkdir -p "$INSTANCE_STORAGE_DIR"
  mkdir -p "$STATE_DIR"
  mkdir -p "$OMO_BIN_CACHE/bin"
  touch "$SHARE_DIR/auth.json" 2>/dev/null || true

  # 安全加载环境变量
  _ocd_load_env "$ENV_FILE"

  QUOTIO_API_KEY="${QUOTIO_API_KEY:-}"
  QUOTIO_BASE_URL="${QUOTIO_BASE_URL:-http://localhost:8317/v1}"

  # 设置版本变量默认值
  local OMO_VER="${OH_MY_OPENCODE_VERSION:-2.14.0}"
  local AUTH_VER="${OPENCODE_ANTIGRAVITY_AUTH_VERSION:-1.2.6}"
  local PLAYWRIGHT_VER="${PLAYWRIGHT_MCP_VERSION:-0.0.54}"
  local EXA_VER="${EXA_MCP_VERSION:-3.1.3}"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "📝 生成 opencode.json..."
    if [[ "$USE_QUOTIO" -eq 1 ]]; then
      cat > "$CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": [
    "oh-my-opencode@${OMO_VER}",
    "opencode-antigravity-auth@${AUTH_VER}"
  ],
  "server": {
    "port": ${PORT},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@${PLAYWRIGHT_VER}", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server@${EXA_VER}"],
      "timeout": 60000,
      "enabled": false,
      "environment": {
        "EXA_API_KEY": "${EXA_API_KEY}"
      }
    }
  },
  "provider": {
    "quotio": {
      "name": "Quotio",
      "npm": "@ai-sdk/anthropic",
      "options": {
        "apiKey": "${QUOTIO_API_KEY}",
        "baseURL": "${QUOTIO_BASE_URL}"
      },
      "models": {
        "gemini-claude-sonnet-4-5": {
          "name": "Claude Sonnet 4.5",
          "limit": { "context": 200000, "output": 64000 }
        },
        "gemini-claude-opus-4-5-thinking": {
          "name": "Claude Opus 4.5 Thinking",
          "limit": { "context": 200000, "output": 64000 },
          "reasoning": true,
          "options": { "thinking": { "type": "enabled", "budgetTokens": 10000 } }
        },
        "gemini-3-pro-preview": {
          "name": "Gemini 3 Pro Preview",
          "limit": { "context": 1048576, "output": 65536 }
        },
        "gemini-3-flash-preview": {
          "name": "Gemini 3 Flash Preview",
          "limit": { "context": 1048576, "output": 65536 }
        },
        "gpt-5.2": {
          "name": "GPT 5.2",
          "limit": { "context": 400000, "output": 32768 },
          "reasoning": true,
          "options": { "reasoning": { "effort": "medium" } }
        }
      }
    }
  }
}
EOF
    else
      cat > "$CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": [
    "oh-my-opencode@${OMO_VER}",
    "opencode-antigravity-auth@${AUTH_VER}"
  ],
  "server": {
    "port": ${PORT},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@${PLAYWRIGHT_VER}", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server@${EXA_VER}"],
      "timeout": 60000,
      "enabled": false,
      "environment": {
        "EXA_API_KEY": "${EXA_API_KEY}"
      }
    }
  }
}
EOF
    fi
  else
    # 更新端口配置
    if command -v jq &>/dev/null; then
      local tmp_file
      tmp_file=$(mktemp) && \
      jq --argjson port "$PORT" '.server.port = $port' "$CONFIG_FILE" > "$tmp_file" && \
      mv "$tmp_file" "$CONFIG_FILE" || rm -f "$tmp_file"
    else
      sed -i.bak -E "s|(\"port\":[[:space:]]*)([0-9]+)|\1${PORT}|g" "$CONFIG_FILE"
      rm -f "${CONFIG_FILE}.bak"
    fi
  fi

  if [[ ! -f "$OMO_CONFIG_FILE" ]]; then
    echo "📝 生成 oh-my-opencode.json..."
    if [[ "$USE_QUOTIO" -eq 1 ]]; then
      cat > "$OMO_CONFIG_FILE" << 'EOFOMOCONFIG'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "disabled_mcps": [],
  "disabled_hooks": [],
  "agents": {
    "Planner-Sisyphus": {
      "model": "anthropic/claude-opus-4-5"
    },
    "frontend-ui-ux-engineer": {
      "model": "quotio/gemini-3-pro-preview"
    },
    "document-writer": {
      "model": "quotio/gemini-3-pro-preview"
    },
    "multimodal-looker": {
      "model": "quotio/gemini-3-flash-preview"
    }
  }
}
EOFOMOCONFIG
    else
      cat > "$OMO_CONFIG_FILE" << 'EOFOMOCONFIG'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "disabled_mcps": [],
  "disabled_hooks": [],
  "agents": {
    "Planner-Sisyphus": {
      "model": "anthropic/claude-opus-4-5"
    }
  }
}
EOFOMOCONFIG
    fi
  fi

  : > "$URL_FILE"
  : > "$NOTIFY_FILE"
  : > "$CLIPBOARD_FILE"

  # 启动 Watcher（自动选择 fswatch 或轮询模式）
  _OCD_WATCHER_PID=$(_ocd_start_watcher "$URL_FILE" "$NOTIFY_FILE" "$CLIPBOARD_FILE")
  disown "$_OCD_WATCHER_PID" 2>/dev/null

  docker rm -f "$CONTAINER_NAME" 2>/dev/null

  local TAILSCALE_IP
  TAILSCALE_IP=$(_ocd_get_tailscale_ip)

  local TS_HOSTNAME=""
  if [[ "$USE_HTTPS" -eq 1 ]]; then
    if command -v tailscale &>/dev/null; then
      TS_HOSTNAME=$(tailscale status --json 2>/dev/null | grep -o '"Self":{[^}]*"DNSName":"[^"]*"' | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | sed 's/\.$//')
      if [[ -n "$TS_HOSTNAME" ]]; then
        tailscale serve --bg https / http://localhost:${PORT} &>/dev/null
        _OCD_HTTPS_ENABLED=1
      fi
    fi
  fi

  echo ""
  echo "🚀 OCD v$(_ocd_version) │ ${INSTANCE_NAME} │ http://localhost:${PORT}"
  if [[ -n "$TS_HOSTNAME" && "$USE_HTTPS" -eq 1 ]]; then
    echo "   └─ 🔒 HTTPS: https://${TS_HOSTNAME}"
  elif [[ -n "$TAILSCALE_IP" ]]; then
    echo "   └─ 📱 远程: http://${TAILSCALE_IP}:${PORT}"
  fi
  [[ "$USE_QUOTIO" -eq 1 ]] && echo "   └─ Quotio 已启用"
  [[ -n "$START_DIR" ]] && echo "   └─ 项目: ${START_DIR%%/*}"
  echo ""

  local GLOBAL_OPENCODE="$HOME/opencode/global/opencode"
  local GLOBAL_CLAUDE="$HOME/opencode/global/claude"
  local PROJECT_CLAUDE="${PROJECT_DIR}/.claude"
  local PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"

  mkdir -p "$PLAYWRIGHT_CACHE"
  mkdir -p "$PROJECT_CLAUDE"/{todos,transcripts} 2>/dev/null || true

  docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --network host \
    --env-file "$ENV_FILE" \
    -e TERM=xterm-256color \
    -e TZ=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo "UTC") \
    -e BROWSER=/usr/bin/xdg-open \
    -e EXA_API_KEY="${EXA_API_KEY:-}" \
    -e OCD_START_DIR="${START_DIR}" \
    -v "${WORKSPACE_ROOT}:/workspace" \
    -v "${INSTANCE_DATA_DIR}:/root/.opencode" \
    -v "${SHARE_DIR}/auth.json:/root/.local/share/opencode/auth.json" \
    -v "${SHARE_DIR}/bin:/root/.local/share/opencode/bin" \
    -v "${INSTANCE_STORAGE_DIR}:/root/.local/share/opencode/storage" \
    -v "${PLAYWRIGHT_CACHE}:/root/.cache/ms-playwright" \
    -v "${STATE_DIR}:/root/.local/state/opencode" \
    -v "${OMO_BIN_CACHE}:/root/.cache/oh-my-opencode" \
    -v "$HOME/.ssh:/root/.ssh:ro" \
    -v "${GLOBAL_OPENCODE}/skill:/root/.config/opencode/skill" \
    -v "${GLOBAL_OPENCODE}/command:/root/.config/opencode/command" \
    -v "${GLOBAL_OPENCODE}/agent:/root/.config/opencode/agent" \
    -v "${INSTANCE_CONFIG_DIR}/opencode.json:/root/.config/opencode/opencode.json" \
    -v "${INSTANCE_CONFIG_DIR}/oh-my-opencode.json:/root/.config/opencode/oh-my-opencode.json" \
    -v "${GLOBAL_CLAUDE}:/root/.claude" \
    -v "${PROJECT_CLAUDE}/todos:/root/.claude/todos" \
    -v "${PROJECT_CLAUDE}/transcripts:/root/.claude/transcripts" \
    -w /workspace \
    "$IMAGE_NAME" "$@"

  # 清理 Watcher 进程
  _ocd_cleanup
}

# =========================================
# 辅助函数：初始化全局配置
# =========================================
_ocd_init_global() {
  local GLOBAL_DIR="$HOME/opencode/global"
  
  # OpenCode 原生全局配置（单数目录名）
  mkdir -p "$GLOBAL_DIR/opencode"/{skill,command,agent}
  
  # Claude 兼容层全局配置（复数目录名）
  mkdir -p "$GLOBAL_DIR/claude"/{skills,commands,agents,rules}
  
  # 创建默认配置文件（如果不存在）
  if [[ ! -f "$GLOBAL_DIR/claude/settings.json" ]]; then
    echo '{}' > "$GLOBAL_DIR/claude/settings.json"
  fi
  
  if [[ ! -f "$GLOBAL_DIR/claude/.mcp.json" ]]; then
    echo '{"mcpServers":{}}' > "$GLOBAL_DIR/claude/.mcp.json"
  fi
  
  # 创建默认 remind skill（如果不存在）
  if [[ ! -f "$GLOBAL_DIR/claude/skills/remind/SKILL.md" ]]; then
    mkdir -p "$GLOBAL_DIR/claude/skills/remind"
    cat > "$GLOBAL_DIR/claude/skills/remind/SKILL.md" << 'EOF'
---
name: task-completion-notify
description: (user - Skill) 任务完成后发送 macOS 桌面通知提醒
---

# 任务完成通知

当用户要求任务完成后提醒时，在任务结束后发送 macOS 桌面通知。

## 触发方式

用户说"完成后提醒我"、"做完通知我"等类似表达。

## 行为规则

1. 记住用户请求了完成提醒
2. 正常执行用户的任务
3. 任务完成后调用：`notify "OpenCode" "任务已完成"`
4. 任务失败时通知应说明失败

## 通知命令

```bash
notify "标题" "内容"
```
EOF
  fi
}

# =========================================
# 辅助函数：初始化项目配置
# =========================================
_ocd_init_project() {
  local PROJECT_DIR="$1"
  
  # OpenCode 原生项目配置（单数目录名）
  mkdir -p "$PROJECT_DIR/.opencode"/{skill,command,agent}
  
  # Claude 兼容层项目配置 + 会话数据
  mkdir -p "$PROJECT_DIR/.claude"/{todos,transcripts}
}
