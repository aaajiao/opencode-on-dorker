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
# 辅助函数：查找空闲端口
# =========================================
_ocd_find_free_port() {
  local base_port=${1:-4096}
  for ((p=base_port; p<base_port+100; p++)); do
    if ! lsof -i :"$p" &>/dev/null; then
      echo "$p"
      return
    fi
  done
  echo "$base_port"
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

  # 初始化配置
  _ocd_init_global
  _ocd_init_project "$(pwd)"
  mkdir -p "$INSTANCE_DATA_DIR"
  mkdir -p "$INSTANCE_CONFIG_DIR"
  mkdir -p "$SHARE_DIR"

  if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
  fi

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
    if command -v jq &> /dev/null; then
      local TMP_FILE=$(mktemp)
      jq --argjson port "$PORT" '.server.port = $port' \
        "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
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

  (
    while true; do
      if [[ -s "$URL_FILE" ]]; then
        while IFS= read -r url; do
          [[ -n "$url" ]] && open "$url"
        done < "$URL_FILE"
        : > "$URL_FILE"
      fi
      if [[ -s "$NOTIFY_FILE" ]]; then
        ICON_FILE="$HOME/opencode/ghostty-128.png"
        while IFS='|' read -r title msg; do
          if [[ -n "$msg" ]]; then
            if command -v terminal-notifier &>/dev/null && [[ -f "$ICON_FILE" ]]; then
              terminal-notifier -title "$title" -message "$msg" -contentImage "$ICON_FILE" -sound Morse
            else
              osascript -e "display notification \"$msg\" with title \"$title\""
            fi
          fi
        done < "$NOTIFY_FILE"
        : > "$NOTIFY_FILE"
      fi
      sleep 0.5
    done
  ) &
  local WATCHER_PID=$!
  disown $WATCHER_PID 2>/dev/null

  docker rm -f "$CONTAINER_NAME" 2>/dev/null

  echo "🚀 OCD v$(_ocd_version)"
  echo "📦 实例: ${INSTANCE_NAME}"
  echo "📂 工作目录: $(pwd)"
  echo "🌐 Web UI: http://localhost:${PORT}"
  [[ "$USE_QUOTIO" -eq 1 ]] && echo "🔌 Quotio 代理: 已启用"
  echo ""

  # 全局配置目录
  local GLOBAL_OPENCODE="$HOME/opencode/global/opencode"
  local GLOBAL_CLAUDE="$HOME/opencode/global/claude"
  
  # 项目 Claude 数据目录
  local PROJECT_CLAUDE="$(pwd)/.claude"

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
    -v "${SHARE_DIR}:/root/.local/share/opencode" \
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

  kill $WATCHER_PID 2>/dev/null
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
