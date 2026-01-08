#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}================================${NC}"
echo -e "${BOLD}  OCD 远程访问配置${NC}"
echo -e "${BOLD}================================${NC}"
echo ""

check_tailscale() {
  if command -v tailscale &>/dev/null; then
    echo -e "${GREEN}✓${NC} Tailscale 已安装"
    return 0
  else
    return 1
  fi
}

install_tailscale() {
  echo -e "${BLUE}→${NC} 安装 Tailscale..."
  
  if command -v brew &>/dev/null; then
    brew install tailscale
  else
    echo -e "${YELLOW}⚠${NC} 未检测到 Homebrew"
    echo "  请手动安装: https://tailscale.com/download/mac"
    exit 1
  fi
}

start_tailscale() {
  local status
  status=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4 || echo "stopped")
  
  if [[ "$status" == "Running" ]]; then
    echo -e "${GREEN}✓${NC} Tailscale 已连接"
    return 0
  else
    echo -e "${BLUE}→${NC} 启动 Tailscale..."
    tailscale up
  fi
}

show_access_info() {
  local ts_ip
  ts_ip=$(tailscale ip -4 2>/dev/null || echo "")
  
  if [[ -z "$ts_ip" ]]; then
    echo -e "${YELLOW}⚠${NC} 无法获取 Tailscale IP"
    echo "  请运行: tailscale up"
    return 1
  fi
  
  echo ""
  echo -e "${BOLD}================================${NC}"
  echo -e "${GREEN}✓ 配置完成！${NC}"
  echo -e "${BOLD}================================${NC}"
  echo ""
  echo "下一步："
  echo ""
  echo "  1. 手机/iPad 安装 Tailscale App"
  echo "     App Store 搜索 \"Tailscale\""
  echo ""
  echo "  2. 登录同一账号"
  echo ""
  echo "  3. Mac 上启动 OCD"
  echo "     cd ~/projects/yourproject"
  echo "     ocd"
  echo ""
  echo "  4. 手机 Safari 访问："
  echo -e "     ${BOLD}http://${ts_ip}:4096${NC}"
  echo ""
}

if ! check_tailscale; then
  install_tailscale
fi

start_tailscale
show_access_info
