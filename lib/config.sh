#!/usr/bin/env bash
# lib/config.sh - 配置生成模块

# =========================================
# 模型配置变量（可被 models.conf 覆盖）
# =========================================
MAIN_MODEL="${MAIN_MODEL:-anthropic/claude-opus-4-5}"
PLANNER_MODEL="${PLANNER_MODEL:-anthropic/claude-opus-4-5}"
ORACLE_MODEL="${ORACLE_MODEL:-}"
DOCUMENT_WRITER_MODEL="${DOCUMENT_WRITER_MODEL:-}"
FRONTEND_MODEL="${FRONTEND_MODEL:-}"
MULTIMODAL_MODEL="${MULTIMODAL_MODEL:-}"

# =========================================
# 加载模型配置
# =========================================
ocd_load_models() {
  local models_file="${OCD_ROOT:-$HOME/opencode}/models.conf"

  if [[ -f "$models_file" ]]; then
    # shellcheck disable=SC1090
    source <(grep -E '^[A-Z_]+=.+' "$models_file" 2>/dev/null | grep -v '^#' || true)
  fi
}

# =========================================
# 渲染模板（替换占位符）
# =========================================
ocd_render_template() {
  local template="$1"
  shift
  local content
  content=$(cat "$template")

  # 替换所有传入的变量
  while [[ $# -gt 0 ]]; do
    local key="$1"
    local value="$2"
    content="${content//__${key}__/$value}"
    shift 2
  done

  echo "$content"
}

# =========================================
# 生成 opencode.json
# =========================================
ocd_generate_opencode_config() {
  local output_file="$1"
  local port="$2"
  local use_quotio="${3:-0}"

  # 版本变量
  local omo_ver="${OH_MY_OPENCODE_VERSION:-2.14.0}"
  local auth_ver="${OPENCODE_ANTIGRAVITY_AUTH_VERSION:-1.2.6}"
  local pw_ver="${PLAYWRIGHT_MCP_VERSION:-0.0.54}"
  local exa_ver="${EXA_MCP_VERSION:-3.1.3}"
  local exa_key="${EXA_API_KEY:-}"

  # 基础配置
  local config
  config=$(cat << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${MAIN_MODEL}",
  "plugin": [
    "oh-my-opencode@${omo_ver}",
    "opencode-antigravity-auth@${auth_ver}"
  ],
  "server": {
    "port": ${port},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@${pw_ver}", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server@${exa_ver}"],
      "timeout": 60000,
      "enabled": false,
      "environment": {
        "EXA_API_KEY": "${exa_key}"
      }
    }
  }
EOF
)

  # Quotio provider（条件添加）
  if [[ "$use_quotio" -eq 1 ]]; then
    local quotio_key="${QUOTIO_API_KEY:-}"
    local quotio_url="${QUOTIO_BASE_URL:-http://localhost:8317/v1}"
    config+=$(cat << EOF
,
  "provider": {
    "quotio": {
      "name": "Quotio",
      "npm": "@ai-sdk/anthropic",
      "options": {
        "apiKey": "${quotio_key}",
        "baseURL": "${quotio_url}"
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
EOF
)
  fi

  config+=$'\n}'

  echo "$config" > "$output_file"
}

# =========================================
# 生成 oh-my-opencode.json
# =========================================
ocd_generate_omo_config() {
  local output_file="$1"
  local use_quotio="${2:-0}"

  # 设置默认模型（Quotio 模式下使用 quotio 前缀）
  local doc_model="${DOCUMENT_WRITER_MODEL:-}"
  local frontend_model="${FRONTEND_MODEL:-}"
  local multimodal_model="${MULTIMODAL_MODEL:-}"

  if [[ "$use_quotio" -eq 1 ]]; then
    [[ -z "$doc_model" ]] && doc_model="quotio/gemini-3-pro-preview"
    [[ -z "$frontend_model" ]] && frontend_model="quotio/gemini-3-pro-preview"
    [[ -z "$multimodal_model" ]] && multimodal_model="quotio/gemini-3-flash-preview"
  fi

  # 构建 agents 配置
  local agents_entries=()
  agents_entries+=("\"Planner-Sisyphus\": { \"model\": \"${PLANNER_MODEL}\" }")

  [[ -n "$ORACLE_MODEL" ]] && agents_entries+=("\"oracle\": { \"model\": \"${ORACLE_MODEL}\" }")
  [[ -n "$doc_model" ]] && agents_entries+=("\"document-writer\": { \"model\": \"${doc_model}\" }")
  [[ -n "$frontend_model" ]] && agents_entries+=("\"frontend-ui-ux-engineer\": { \"model\": \"${frontend_model}\" }")
  [[ -n "$multimodal_model" ]] && agents_entries+=("\"multimodal-looker\": { \"model\": \"${multimodal_model}\" }")

  # 用逗号连接
  local agents_json
  agents_json=$(IFS=','; echo "${agents_entries[*]}" | sed 's/,/,\n    /g')

  cat > "$output_file" << EOF
{
  "\$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "disabled_mcps": [],
  "disabled_hooks": [],
  "agents": {
    ${agents_json}
  }
}
EOF
}

# =========================================
# 更新配置端口
# =========================================
ocd_update_config_port() {
  local config_file="$1"
  local port="$2"

  if command -v jq &>/dev/null; then
    local tmp_file
    tmp_file=$(mktemp)
    if jq --argjson port "$port" '.server.port = $port' "$config_file" > "$tmp_file"; then
      mv "$tmp_file" "$config_file"
    else
      rm -f "$tmp_file"
    fi
  else
    sed -i.bak -E "s|(\"port\":[[:space:]]*)([0-9]+)|\1${port}|g" "$config_file"
    rm -f "${config_file}.bak"
  fi
}

# =========================================
# 初始化全局配置目录
# =========================================
ocd_init_global() {
  # v3.0: 使用 XDG 标准路径
  local global_dir="$OCD_CONFIG_GLOBAL"

  # OpenCode 原生全局配置（单数目录名）
  mkdir -p "$global_dir/opencode"/{skill,command,agent}

  # Claude 兼容层全局配置（复数目录名）
  mkdir -p "$global_dir/claude"/{skills,commands,agents,rules}

  # 默认配置文件（空）
  [[ ! -f "$global_dir/claude/settings.json" ]] && echo '{}' > "$global_dir/claude/settings.json"
  [[ ! -f "$global_dir/claude/.mcp.json" ]] && echo '{"mcpServers":{}}' > "$global_dir/claude/.mcp.json"
}

# =========================================
# 初始化项目配置目录
# =========================================
ocd_init_project() {
  local project_dir="$1"

  # OpenCode 原生项目配置（单数目录名）
  mkdir -p "$project_dir/.opencode"/{skill,command,agent}

  # Claude 兼容层会话数据目录
  # 注意：不自动创建 skills/commands/agents/rules/
  # 用户需手动创建才会启用项目级覆盖（覆盖全局配置）
  mkdir -p "$project_dir/.claude"/{todos,transcripts}
}
