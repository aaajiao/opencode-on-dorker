#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

CONTAINER_NAME="opencode-server"
PORT=4096
VERSION_FILE="$HOME/opencode/VERSION"
VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")

echo ""
echo -e "${BOLD}================================${NC}"
echo -e "${BOLD}  OCD Server Status v${VERSION}${NC}"
echo -e "${BOLD}================================${NC}"
echo ""

check_docker() {
  if ! command -v docker &>/dev/null; then
    echo -e "${RED}✗${NC} Docker not installed"
    return 1
  fi
  
  if ! docker info &>/dev/null; then
    echo -e "${RED}✗${NC} Docker not running"
    return 1
  fi
  
  echo -e "${GREEN}✓${NC} Docker running"
  return 0
}

check_container() {
  local status
  status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not_found")
  
  case "$status" in
    running)
      echo -e "${GREEN}✓${NC} Container running"
      return 0
      ;;
    exited)
      echo -e "${YELLOW}⚠${NC} Container stopped"
      return 1
      ;;
    *)
      echo -e "${RED}✗${NC} Container not found"
      return 1
      ;;
  esac
}

check_port() {
  if lsof -i ":$PORT" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Port $PORT listening"
    return 0
  else
    echo -e "${RED}✗${NC} Port $PORT not listening"
    return 1
  fi
}

check_tailscale() {
  if ! command -v tailscale &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Tailscale not installed"
    echo "    Install: brew install tailscale"
    return 1
  fi
  
  local status
  status=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4 || echo "stopped")
  
  if [[ "$status" == "Running" ]]; then
    echo -e "${GREEN}✓${NC} Tailscale connected"
    return 0
  else
    echo -e "${YELLOW}⚠${NC} Tailscale not connected"
    echo "    Connect: tailscale up"
    return 1
  fi
}

get_local_ip() {
  local ip
  ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
  echo "$ip"
}

get_tailscale_ip() {
  tailscale ip -4 2>/dev/null || echo ""
}

get_hostname() {
  scutil --get ComputerName 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || hostname -s
}

echo -e "${BLUE}[Services]${NC}"
check_docker
DOCKER_OK=$?

if [[ $DOCKER_OK -eq 0 ]]; then
  check_container
fi

check_port
check_tailscale

echo ""
echo -e "${BLUE}[Access URLs]${NC}"

LOCAL_IP=$(get_local_ip)
TAILSCALE_IP=$(get_tailscale_ip)
HOSTNAME=$(get_hostname)

echo -e "  Local:     ${BOLD}http://localhost:${PORT}${NC}"

if [[ -n "$LOCAL_IP" ]]; then
  echo -e "  LAN:       ${BOLD}http://${LOCAL_IP}:${PORT}${NC}"
fi

if [[ -n "$TAILSCALE_IP" ]]; then
  echo -e "  Tailscale: ${BOLD}http://${TAILSCALE_IP}:${PORT}${NC}"
  echo -e "  MagicDNS:  ${BOLD}http://${HOSTNAME}:${PORT}${NC} (if enabled)"
fi

echo ""
echo -e "${BLUE}[Quick Commands]${NC}"
echo "  Start:   cd ~/opencode/server && docker-compose up -d"
echo "  Stop:    cd ~/opencode/server && docker-compose down"
echo "  Logs:    cd ~/opencode/server && docker-compose logs -f"
echo "  Restart: cd ~/opencode/server && docker-compose restart"
echo ""
