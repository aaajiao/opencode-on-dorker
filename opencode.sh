# OpenCode Docker Shortcut (支持 oh-my-opencode)
# 添加到 ~/.zshrc 或 ~/.bashrc
opencode() {
  local IMAGE_NAME="opencode-bun"
  local CONTAINER_NAME="opencode"
  local REBUILD=0
  local URL_FILE="$HOME/.opencode_data/open_url"
  local NOTIFY_FILE="$HOME/.opencode_data/notifications"
  local ENV_FILE="$HOME/opencode/.env"
  local CONFIG_FILE="$HOME/.config/opencode/opencode.json"
  local OMO_CONFIG_FILE="$HOME/.config/opencode/oh-my-opencode.json"

  if [[ "$1" == "-r" ]]; then
    REBUILD=1
    shift
  fi

  if [[ "$REBUILD" -eq 1 ]]; then
    echo "🗑️  删除旧镜像..."
    docker rmi "$IMAGE_NAME" 2>/dev/null
    echo "🗑️  删除旧配置..."
    rm -f "$CONFIG_FILE"
    rm -f "$OMO_CONFIG_FILE"
    echo "🗑️  清除插件缓存..."
    rm -rf "$HOME/.cache/opencode/node_modules"
    echo "🏗️  正在完全重建镜像 (无缓存)..."
    docker build --no-cache -t "$IMAGE_NAME" "$HOME/opencode"
  elif ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "🏗️  正在构建镜像..."
    docker build -t "$IMAGE_NAME" "$HOME/opencode"
  fi

  mkdir -p "$HOME/.opencode_data"
  mkdir -p "$HOME/.config/opencode"
  mkdir -p "$HOME/.local/share/opencode"

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
    "opencode-antigravity-auth"
  ],
  "server": {
    "port": 4096,
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
    # 配置文件已存在，只更新 apiKey 和 baseURL
    if command -v jq &> /dev/null; then
      local TMP_FILE=$(mktemp)
      jq --arg key "$QUOTIO_API_KEY" --arg url "$QUOTIO_BASE_URL" \
        '.provider.quotio.options.apiKey = $key | .provider.quotio.options.baseURL = $url' \
        "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
    else
      sed -i.bak -E "s|(\"apiKey\":[[:space:]]*\")[^\"]*(\")|\1${QUOTIO_API_KEY}\2|g" "$CONFIG_FILE"
      sed -i.bak -E "s|(\"baseURL\":[[:space:]]*\")[^\"]*(\")|\1${QUOTIO_BASE_URL}\2|g" "$CONFIG_FILE"
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
  "disabled_hooks": ["session-notification"],
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
              terminal-notifier -title "$title" -message "$msg" -contentImage "$ICON_FILE" -sound Pong 
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

  docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --network host \
    --env-file "$ENV_FILE" \
    -e TERM=xterm-256color \
    -e BROWSER=/usr/bin/xdg-open \
    -e EXA_API_KEY="${EXA_API_KEY:-}" \
    -v "$(pwd):/workspace" \
    -v "$HOME/.opencode_data:/root/.opencode" \
    -v "$HOME/.config/opencode:/root/.config/opencode" \
    -v "$HOME/.local/share/opencode:/root/.local/share/opencode" \
    -v "$HOME/.ssh:/root/.ssh:ro" \
    -w /workspace \
    "$IMAGE_NAME" "$@"

  kill $WATCHER_PID 2>/dev/null
}
