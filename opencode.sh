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
# 辅助函数：清理实例名 ("My Project" -> "my-project")
# =========================================
_ocd_sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_'
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

  while IFS='=' read -r key value; do
    # 验证 key: 大写字母/数字/下划线，以字母或下划线开头
    if [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && [[ -n "$value" ]]; then
      # 移除可能的引号
      value="${value#\"}" && value="${value%\"}"
      value="${value#\'}" && value="${value%\'}"
      export "$key=$value"
    fi
  done < <(grep -E '^[A-Z_][A-Z0-9_]*=' "$env_file" 2>/dev/null | grep -v '[;`$()]')
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
# 辅助函数：启动 Watcher（自动选择最优方式）
# =========================================
_ocd_start_watcher() {
  local url_file="$1"
  local notify_file="$2"

  (
    if command -v fswatch &>/dev/null; then
      # 高效模式：fswatch 事件驱动
      fswatch -0 --event Created --event Updated "$url_file" "$notify_file" 2>/dev/null | \
      while IFS= read -r -d '' _; do
        _ocd_handle_url "$url_file"
        _ocd_handle_notify "$notify_file"
      done
    else
      # 兼容模式：轮询（1 秒间隔）
      while true; do
        _ocd_handle_url "$url_file"
        _ocd_handle_notify "$notify_file"
        sleep 1
      done
    fi
  ) &

  echo $!
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

  # Watcher 进程 ID 和清理函数
  local WATCHER_PID=""

  _ocd_cleanup() {
    [[ -n "$WATCHER_PID" ]] && kill "$WATCHER_PID" 2>/dev/null
  }
  trap '_ocd_cleanup' EXIT INT TERM HUP

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--version)
        echo "OCD v$(_ocd_version)"
        return 0
        ;;
      -r) REBUILD=1; shift ;;
      --keep) KEEP_CONFIG=1; shift ;;
      --quotio) USE_QUOTIO=1; shift ;;
      -n) INSTANCE_NAME="$2"; shift 2 ;;
      -p) CUSTOM_PORT="$2"; shift 2 ;;
      *) break ;;
    esac
  done

  # 默认实例名 = 当前目录名（清理后）
  if [[ -z "$INSTANCE_NAME" ]]; then
    INSTANCE_NAME=$(_ocd_sanitize_name "$(basename "$(pwd)")")
  fi

  # 容器名
  local CONTAINER_NAME="opencode-${INSTANCE_NAME}"

  # 实例独立目录
  local INSTANCE_CONFIG_DIR="$HOME/.config/opencode/${INSTANCE_NAME}"
  local INSTANCE_DATA_DIR="$HOME/.opencode_data/${INSTANCE_NAME}"

  # 实例独立的存储目录（session 隔离）
  local INSTANCE_STORAGE_DIR="${SHARE_DIR}/storage/${INSTANCE_NAME}"

  # 实例独立文件
  local URL_FILE="${INSTANCE_DATA_DIR}/open_url"
  local NOTIFY_FILE="${INSTANCE_DATA_DIR}/notifications"
  local CONFIG_FILE="${INSTANCE_CONFIG_DIR}/opencode.json"
  local OMO_CONFIG_FILE="${INSTANCE_CONFIG_DIR}/oh-my-opencode.json"

  # 端口分配
  local PORT
  if [[ -n "$CUSTOM_PORT" ]]; then
    PORT="$CUSTOM_PORT"
  else
    PORT=$(_ocd_find_free_port 4096)
  fi

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
    docker build --no-cache -t "$IMAGE_NAME" "$HOME/opencode"
  elif ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "🏗️  正在构建镜像..."
    docker build -t "$IMAGE_NAME" "$HOME/opencode"
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
  touch "$SHARE_DIR/auth.json" 2>/dev/null || true

  # 安全加载环境变量
  _ocd_load_env "$ENV_FILE"

  QUOTIO_API_KEY="${QUOTIO_API_KEY:-}"
  QUOTIO_BASE_URL="${QUOTIO_BASE_URL:-http://localhost:8317/v1}"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "📝 生成 opencode.json..."
    if [[ "$USE_QUOTIO" -eq 1 ]]; then
      cat > "$CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": [
    "oh-my-opencode",
    "opencode-antigravity-auth@1.2.6"
  ],
  "server": {
    "port": ${PORT},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server"],
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
    "oh-my-opencode",
    "opencode-antigravity-auth@1.2.6"
  ],
  "server": {
    "port": ${PORT},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server"],
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

  # 启动 Watcher（自动选择 fswatch 或轮询模式）
  WATCHER_PID=$(_ocd_start_watcher "$URL_FILE" "$NOTIFY_FILE")
  disown "$WATCHER_PID" 2>/dev/null

  docker rm -f "$CONTAINER_NAME" 2>/dev/null

  echo ""
  echo "🚀 OCD v$(_ocd_version) │ ${INSTANCE_NAME} │ http://localhost:${PORT}"
  [[ "$USE_QUOTIO" -eq 1 ]] && echo "   └─ Quotio 已启用"
  echo ""

  # 全局配置目录
  local GLOBAL_OPENCODE="$HOME/opencode/global/opencode"
  local GLOBAL_CLAUDE="$HOME/opencode/global/claude"
  
  # 项目 Claude 数据目录
  local PROJECT_CLAUDE="$(pwd)/.claude"

  # Playwright/Patchright 缓存目录（持久化浏览器）
  local PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
  mkdir -p "$PLAYWRIGHT_CACHE"

  # Docker 挂载运行
  docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --network host \
    --env-file "$ENV_FILE" \
    -e TERM=xterm-256color \
    -e BROWSER=/usr/bin/xdg-open \
    -e EXA_API_KEY="${EXA_API_KEY:-}" \
    -v "$(pwd):/workspace" \
    -v "${INSTANCE_DATA_DIR}:/root/.opencode" \
    -v "${SHARE_DIR}/auth.json:/root/.local/share/opencode/auth.json" \
    -v "${SHARE_DIR}/bin:/root/.local/share/opencode/bin" \
    -v "${INSTANCE_STORAGE_DIR}:/root/.local/share/opencode/storage" \
    -v "${PLAYWRIGHT_CACHE}:/root/.cache/ms-playwright" \
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

  # trap 会自动清理 WATCHER_PID
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
