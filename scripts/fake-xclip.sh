#!/bin/bash
# ================================================
# 伪 xclip/xsel - 剪贴板桥接
# ================================================
# 将剪贴板内容写入文件，供 Mac watcher 读取并 pbcopy
#
# 支持的参数（兼容 xclip/xsel 常用用法）:
#   -i, -in      输入模式（默认）
#   -o, -out     输出模式
#   -selection   选择类型（忽略，仅为兼容）
#   -sel         同上
#
# 用法示例:
#   echo "text" | xclip
#   echo "text" | xclip -selection clipboard
#   xclip -o

CLIPBOARD_FILE="/root/.opencode/clipboard"

# 默认输入模式
mode="in"

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -selection|-sel)
      # 忽略 selection 参数值（clipboard/primary/secondary）
      shift
      ;;
    -i|-in|--input)
      mode="in"
      ;;
    -o|-out|--output)
      mode="out"
      ;;
    -version|--version)
      echo "fake-xclip 1.0.0 (OCD clipboard bridge)"
      exit 0
      ;;
    -h|--help)
      echo "Usage: xclip [-i|-o] [-selection clipboard|primary]"
      echo "Clipboard bridge for Docker -> macOS"
      exit 0
      ;;
    *)
      # 忽略其他参数
      ;;
  esac
  shift
done

# 确保目录存在
mkdir -p "$(dirname "$CLIPBOARD_FILE")"

if [[ "$mode" == "out" ]]; then
  # 输出模式：读取剪贴板内容
  cat "$CLIPBOARD_FILE" 2>/dev/null
else
  # 输入模式：写入剪贴板内容
  cat > "$CLIPBOARD_FILE"
fi
