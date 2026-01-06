# OpenCode Docker Shortcut (支持 oh-my-opencode + 多实例)
# 添加到 ~/.zshrc 或 ~/.bashrc
#
# 用法:
#   opencode              # 实例名=当前目录名，自动分配端口
#   opencode -p 5000      # 指定端口
#   opencode -n myname    # 指定实例名
#   opencode -r           # 重建镜像 + 清理所有实例配置
#   opencode -r --keep    # 重建镜像 + 保留配置

# =========================================
# 辅助函数：清理实例名 ("My Project" -> "my-project")
# =========================================
_opencode_sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_'
}

# =========================================
# 辅助函数：查找空闲端口
# =========================================
_opencode_find_free_port() {
  local base_port=${1:-4096}
  for ((p=base_port; p<base_port+100; p++)); do
    if ! lsof -i :"$p" &>/dev/null; then
      echo "$p"
      return
    fi
  done
  echo "$base_port"
}

opencode() {
  local IMAGE_NAME="opencode-bun"
  local ENV_FILE="$HOME/opencode/.env"
  local SHARE_DIR="$HOME/.local/share/opencode"

  # 参数变量
  local REBUILD=0
  local KEEP_CONFIG=0
  local INSTANCE_NAME=""
  local CUSTOM_PORT=""

  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r) REBUILD=1; shift ;;
      --keep) KEEP_CONFIG=1; shift ;;
      -n) INSTANCE_NAME="$2"; shift 2 ;;
      -p) CUSTOM_PORT="$2"; shift 2 ;;
      *) break ;;
    esac
  done

  # 默认实例名 = 当前目录名（清理后）
  if [[ -z "$INSTANCE_NAME" ]]; then
    INSTANCE_NAME=$(_opencode_sanitize_name "$(basename "$(pwd)")")
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
    PORT=$(_opencode_find_free_port 4096)
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

  _opencode_init_skills
  mkdir -p "$INSTANCE_DATA_DIR"
  mkdir -p "$INSTANCE_CONFIG_DIR"
  mkdir -p "$SHARE_DIR"

  # 加载 .env 文件中的变量
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
  fi

  # 设置默认值
  QUOTIO_API_KEY="${QUOTIO_API_KEY:-sk-default}"
  QUOTIO_BASE_URL="${QUOTIO_BASE_URL:-http://localhost:8317/v1}"

  # =========================================
  # 生成 opencode.json (主配置)
  # =========================================
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "📝 生成 opencode.json..."
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
          "limit": {
            "context": 200000,
            "output": 64000
          }
        },
        "gemini-claude-opus-4-5-thinking": {
          "name": "Claude Opus 4.5 Thinking",
          "limit": {
            "context": 200000,
            "output": 64000
          },
          "reasoning": true,
          "options": {
            "thinking": {
              "type": "enabled",
              "budgetTokens": 10000
            }
          }
        },
        "gemini-3-pro-preview": {
          "name": "Gemini 3 Pro Preview",
          "limit": {
            "context": 1048576,
            "output": 65536
          }
        },
        "gemini-3-flash-preview": {
          "name": "Gemini 3 Flash Preview",
          "limit": {
            "context": 1048576,
            "output": 65536
          }
        },
        "gpt-5.2": {
          "name": "GPT 5.2",
          "limit": {
            "context": 400000,
            "output": 32768
          },
          "reasoning": true,
          "options": {
            "reasoning": {
              "effort": "medium"
            }
          }
        }
      }
    }
  }
}
EOF
  else
    if command -v jq &> /dev/null; then
      local TMP_FILE=$(mktemp)
      jq --arg key "$QUOTIO_API_KEY" --arg url "$QUOTIO_BASE_URL" --argjson port "$PORT" \
        '.provider.quotio.options.apiKey = $key | .provider.quotio.options.baseURL = $url | .server.port = $port' \
        "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
    else
      sed -i.bak -E "s|(\"apiKey\":[[:space:]]*\")[^\"]*(\")|\1${QUOTIO_API_KEY}\2|g" "$CONFIG_FILE"
      sed -i.bak -E "s|(\"baseURL\":[[:space:]]*\")[^\"]*(\")|\1${QUOTIO_BASE_URL}\2|g" "$CONFIG_FILE"
      sed -i.bak -E "s|(\"port\":[[:space:]]*)([0-9]+)|\1${PORT}|g" "$CONFIG_FILE"
      rm -f "${CONFIG_FILE}.bak"
    fi
  fi

  # =========================================
  # 生成 oh-my-opencode.json (插件配置)
  # =========================================
  if [[ ! -f "$OMO_CONFIG_FILE" ]]; then
    echo "📝 生成 oh-my-opencode.json..."
    cat > "$OMO_CONFIG_FILE" << 'EOFOMOCONFIG'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "disabled_mcps": ["websearch_exa"],
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

  echo "🚀 启动实例: ${INSTANCE_NAME}"
  echo "📂 工作目录: $(pwd)"
  echo "🌐 Web UI: http://localhost:${PORT}"
  echo ""

  docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --network host \
    --env-file "$ENV_FILE" \
    -e TERM=xterm-256color \
    -e BROWSER=/usr/bin/xdg-open \
    -e EXA_API_KEY="${EXA_API_KEY:-}" \
    -v "$(pwd):/workspace" \
    -v "${INSTANCE_DATA_DIR}:/root/.opencode" \
    -v "${INSTANCE_CONFIG_DIR}:/root/.config/opencode" \
    -v "${SHARE_DIR}:/root/.local/share/opencode" \
    -v "$HOME/.ssh:/root/.ssh:ro" \
    -v "$HOME/opencode/skills:/root/.claude/skills:ro" \
    -w /workspace \
    "$IMAGE_NAME" "$@"

  kill $WATCHER_PID 2>/dev/null
}

# =========================================
# 辅助函数：生成全局 skills
# =========================================
_opencode_init_skills() {
  local SKILLS_DIR="$HOME/opencode/skills"
  
  # remind skill
  if [[ ! -f "$SKILLS_DIR/remind/SKILL.md" ]]; then
    mkdir -p "$SKILLS_DIR/remind"
    cat > "$SKILLS_DIR/remind/SKILL.md" << 'EOF'
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
