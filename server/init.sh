#!/bin/bash
# OCD Server Mode - 首次设置脚本
#
# 用法：./init.sh
#
# 此脚本会：
# 1. 创建必要的目录结构
# 2. 生成默认配置文件
# 3. 构建 Docker 镜像
# 4. 提示下一步操作

set -e

echo "=================================="
echo "  OCD Server Mode - 首次设置"
echo "=================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =========================================
# 第一步：创建目录结构
# =========================================
echo "📁 创建目录结构..."

mkdir -p ~/.config/opencode/server
mkdir -p ~/.opencode_data/server
mkdir -p ~/.local/share/opencode
mkdir -p ~/.local/state/opencode
mkdir -p ~/.cache/ms-playwright
mkdir -p ~/.cache/oh-my-opencode
mkdir -p ~/projects

echo -e "   ${GREEN}✓${NC} 目录创建完成"

# =========================================
# 第二步：生成配置文件
# =========================================
CONFIG_FILE="$HOME/.config/opencode/server/opencode.json"
OMO_CONFIG_FILE="$HOME/.config/opencode/server/oh-my-opencode.json"

# 版本号（可从 versions.lock 读取）
VERSIONS_FILE="$HOME/opencode/versions.lock"
if [[ -f "$VERSIONS_FILE" ]]; then
  source <(grep -E '^[A-Z_]+=' "$VERSIONS_FILE" 2>/dev/null || true)
fi

OMO_VER="${OH_MY_OPENCODE_VERSION:-2.14.0}"
AUTH_VER="${OPENCODE_ANTIGRAVITY_AUTH_VERSION:-1.2.6}"
PLAYWRIGHT_VER="${PLAYWRIGHT_MCP_VERSION:-0.0.54}"
EXA_VER="${EXA_MCP_VERSION:-3.1.3}"

# 读取 EXA_API_KEY（如果存在）
ENV_FILE="$HOME/opencode/.env"
if [[ -f "$ENV_FILE" ]]; then
  EXA_API_KEY=$(grep -E '^EXA_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "📝 生成 opencode.json..."
  cat > "$CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": [
    "oh-my-opencode@${OMO_VER}",
    "opencode-antigravity-auth@${AUTH_VER}"
  ],
  "server": {
    "port": 4096,
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
  echo -e "   ${GREEN}✓${NC} opencode.json 已生成"
else
  echo -e "   ${YELLOW}⚠${NC} opencode.json 已存在，跳过"
fi

if [[ ! -f "$OMO_CONFIG_FILE" ]]; then
  echo "📝 生成 oh-my-opencode.json..."
  cat > "$OMO_CONFIG_FILE" << 'EOF'
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
EOF
  echo -e "   ${GREEN}✓${NC} oh-my-opencode.json 已生成"
else
  echo -e "   ${YELLOW}⚠${NC} oh-my-opencode.json 已存在，跳过"
fi

# =========================================
# 第三步：初始化全局配置目录
# =========================================
echo "📁 初始化全局配置..."

GLOBAL_DIR="$HOME/opencode/global"
mkdir -p "$GLOBAL_DIR/opencode"/{skill,command,agent}
mkdir -p "$GLOBAL_DIR/claude"/{skills,commands,agents,rules}

# 创建默认配置文件
[[ ! -f "$GLOBAL_DIR/claude/settings.json" ]] && echo '{}' > "$GLOBAL_DIR/claude/settings.json"
[[ ! -f "$GLOBAL_DIR/claude/.mcp.json" ]] && echo '{"mcpServers":{}}' > "$GLOBAL_DIR/claude/.mcp.json"

echo -e "   ${GREEN}✓${NC} 全局配置初始化完成"

# =========================================
# 第四步：构建 Docker 镜像
# =========================================
echo ""
echo "🏗️  构建 Docker 镜像..."
cd "$(dirname "$0")"
docker-compose build

echo -e "   ${GREEN}✓${NC} 镜像构建完成"

# =========================================
# 完成提示
# =========================================
echo ""
echo "=================================="
echo -e "  ${GREEN}✓ 设置完成！${NC}"
echo "=================================="
echo ""
echo "下一步："
echo ""
echo "  1. 编辑 API Keys（如果还没配置）:"
echo "     nano ~/opencode/.env"
echo ""
echo "  2. 启动服务:"
echo "     cd ~/opencode/server"
echo "     docker-compose up -d"
echo ""
echo "  3. 查看日志:"
echo "     docker-compose logs -f"
echo ""
echo "  4. 访问 Web UI:"
echo "     http://localhost:4096"
echo "     http://<your-ip>:4096"
echo ""
echo "  5. 安装 Tailscale（公网访问）:"
echo "     brew install tailscale"
echo "     tailscale up"
echo ""
