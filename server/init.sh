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

VERSION_FILE="$HOME/opencode/VERSION"
VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")

echo "=================================="
echo "  OCD Server Mode v${VERSION} - 首次设置"
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

PROVIDER_CACHE="$HOME/.cache/oh-my-opencode/connected-providers.json"
if [[ ! -f "$PROVIDER_CACHE" ]]; then
  printf '{"connected":[],"updatedAt":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$PROVIDER_CACHE"
fi

echo -e "   ${GREEN}✓${NC} 目录创建完成"

# =========================================
# 第二步：生成配置文件（从模板）
# =========================================
CONFIG_FILE="$HOME/.config/opencode/server/opencode.json"
OMO_CONFIG_FILE="$HOME/.config/opencode/server/oh-my-opencode.json"

# 模板路径
TEMPLATE_DIR="$HOME/opencode/templates/global"
OPENCODE_TEMPLATE="$TEMPLATE_DIR/opencode.json.tmpl"
OMO_TEMPLATE="$TEMPLATE_DIR/oh-my-opencode.json"

# 版本号（从 versions.lock 读取）
VERSIONS_FILE="$HOME/opencode/versions.lock"
if [[ -f "$VERSIONS_FILE" ]]; then
  # shellcheck disable=SC1090
  source <(grep -E '^[A-Z_]+=' "$VERSIONS_FILE" 2>/dev/null || true)
fi

OMO_VER="${OH_MY_OPENCODE_VERSION:-2.14.0}"

# 从模板创建配置（替换 {{VAR}} 变量）
create_from_template() {
  local template="$1"
  local output="$2"
  
  if [[ ! -f "$template" ]]; then
    return 1
  fi
  
  local content
  content=$(cat "$template")
  
  # 替换 {{VAR}} 格式的变量
  content="${content//\{\{OH_MY_OPENCODE_VERSION\}\}/$OMO_VER}"
  
  echo "$content" > "$output"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "📝 生成 opencode.json..."
  if create_from_template "$OPENCODE_TEMPLATE" "$CONFIG_FILE"; then
    echo -e "   ${GREEN}✓${NC} opencode.json 已从模板生成"
  else
    echo -e "   ${YELLOW}⚠${NC} 模板不存在，使用默认配置"
    cat > "$CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "plugin": ["oh-my-opencode@${OMO_VER}"],
  "server": {"port": 4096, "hostname": "0.0.0.0"}
}
EOF
  fi
else
  echo -e "   ${YELLOW}⚠${NC} opencode.json 已存在，跳过"
fi

if [[ ! -f "$OMO_CONFIG_FILE" ]]; then
  echo "📝 生成 oh-my-opencode.json..."
  if [[ -f "$OMO_TEMPLATE" ]]; then
    cp "$OMO_TEMPLATE" "$OMO_CONFIG_FILE"
    echo -e "   ${GREEN}✓${NC} oh-my-opencode.json 已从模板复制"
  else
    echo -e "   ${YELLOW}⚠${NC} 模板不存在，使用默认配置"
    echo '{"google_auth": false}' > "$OMO_CONFIG_FILE"
  fi
else
  echo -e "   ${YELLOW}⚠${NC} oh-my-opencode.json 已存在，跳过"
fi

# =========================================
# 第三步：初始化全局配置目录
# =========================================
echo "📁 初始化全局配置..."

GLOBAL_DIR="$HOME/opencode/global"
mkdir -p "$GLOBAL_DIR/opencode"/{skills,commands,agents}
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
echo "  2. 确保项目在 ~/projects 目录下:"
echo "     mkdir -p ~/projects"
echo "     # 服务器模式挂载整个 ~/projects 到 /workspace"
echo "     # 支持多项目切换，每个 Git 仓库独立隔离"
echo ""
echo "  3. 启动服务:"
echo "     cd ~/opencode/server"
echo "     docker-compose up -d"
echo ""
echo "  4. 查看日志:"
echo "     docker-compose logs -f"
echo ""
echo "  5. 访问 Web UI:"
echo "     http://localhost:4096"
echo "     http://<your-ip>:4096"
echo ""
echo "  6. 安装 Tailscale（公网访问）:"
echo "     brew install tailscale"
echo "     tailscale up"
echo ""
