#!/usr/bin/env bash
# scripts/run-tests.sh - 运行所有测试
#
# 使用方法:
#   ./scripts/run-tests.sh          # 运行所有测试
#   ./scripts/run-tests.sh watcher  # 只运行 watcher 测试
#   ./scripts/run-tests.sh --quick  # 快速模式（跳过慢速测试）

set -euo pipefail

OCD_ROOT="${OCD_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TESTS_DIR="$OCD_ROOT/tests/bats"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查依赖
check_dependencies() {
  local missing=()

  if ! command -v bats &>/dev/null; then
    missing+=("bats-core")
  fi

  if ! command -v jq &>/dev/null; then
    missing+=("jq")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}缺少依赖:${NC} ${missing[*]}"
    echo ""
    echo "安装方法 (macOS):"
    echo "  brew install bats-core jq"
    echo ""
    echo "安装方法 (Ubuntu):"
    echo "  sudo apt-get install bats jq"
    exit 1
  fi
}

# 运行测试
run_tests() {
  local test_filter="$1"
  local quick_mode="$2"

  echo -e "${GREEN}🧪 OCD 测试套件${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  local test_files=()

  if [[ -n "$test_filter" ]]; then
    # 运行指定测试
    if [[ -f "$TESTS_DIR/${test_filter}.bats" ]]; then
      test_files=("$TESTS_DIR/${test_filter}.bats")
    else
      echo -e "${RED}找不到测试文件:${NC} ${test_filter}.bats"
      exit 1
    fi
  else
    # 运行所有测试
    test_files=("$TESTS_DIR"/*.bats)
  fi

  local total=0
  local passed=0
  local failed=0

  for test_file in "${test_files[@]}"; do
    local name
    name=$(basename "$test_file" .bats)
    echo -e "${YELLOW}▶ $name${NC}"

    if bats "$test_file"; then
      ((passed++))
    else
      ((failed++))
    fi
    ((total++))
    echo ""
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✅ 所有测试通过${NC} ($passed/$total)"
  else
    echo -e "${RED}❌ 测试失败${NC} ($failed/$total 失败)"
    exit 1
  fi
}

# 主函数
main() {
  local test_filter=""
  local quick_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick|-q)
        quick_mode=true
        export BATS_QUICK_MODE=1
        shift
        ;;
      --help|-h)
        echo "使用方法: $0 [options] [test_name]"
        echo ""
        echo "Options:"
        echo "  --quick, -q  快速模式（跳过慢速测试）"
        echo "  --help, -h   显示帮助"
        echo ""
        echo "Examples:"
        echo "  $0              # 运行所有测试"
        echo "  $0 watcher      # 只运行 watcher.bats"
        echo "  $0 --quick      # 快速模式"
        exit 0
        ;;
      *)
        test_filter="$1"
        shift
        ;;
    esac
  done

  check_dependencies
  run_tests "$test_filter" "$quick_mode"
}

main "$@"
