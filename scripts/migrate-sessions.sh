#!/bin/bash
set -e

STORAGE_DIR="$HOME/.local/share/opencode/storage"

declare -A MAPPING=(
  ["745f3723c3c9c27d56d00ea57d3e133aa0fc821c"]="opencode"
  ["global"]="opencode"
  ["b1442060305f379106ecc4bf2e750ba60379f8ad"]="opencode"
  ["9ae79eb5d957fd5dc2d3ecb1e4500bcf0566450a"]="opencode"
  ["541a9ca1b2a5613f105cde97dff63e9601bd9e82"]="rsi"
  ["a_aaajiao"]="a_aaajiao"
)

echo "=== Session 迁移脚本 ==="
echo "源目录: $STORAGE_DIR"
echo ""

for OLD_ID in "${!MAPPING[@]}"; do
  TARGET="${MAPPING[$OLD_ID]}"
  OLD_DIR="$STORAGE_DIR/session/$OLD_ID"
  NEW_DIR="$STORAGE_DIR/$TARGET/session/$OLD_ID"
  
  if [[ -d "$OLD_DIR" ]]; then
    SESSION_COUNT=$(ls "$OLD_DIR"/*.json 2>/dev/null | wc -l)
    echo "📦 $OLD_ID → $TARGET ($SESSION_COUNT sessions)"
    
    mkdir -p "$STORAGE_DIR/$TARGET/session"
    mkdir -p "$STORAGE_DIR/$TARGET/project"
    mkdir -p "$STORAGE_DIR/$TARGET/message"
    mkdir -p "$STORAGE_DIR/$TARGET/part"
    
    if [[ -d "$NEW_DIR" ]]; then
      echo "   ⚠️  目标已存在，合并中..."
      cp -rn "$OLD_DIR"/* "$NEW_DIR"/ 2>/dev/null || true
    else
      mv "$OLD_DIR" "$NEW_DIR"
    fi
    
    OLD_PROJECT="$STORAGE_DIR/project/$OLD_ID.json"
    if [[ -f "$OLD_PROJECT" ]]; then
      cp "$OLD_PROJECT" "$STORAGE_DIR/$TARGET/project/$OLD_ID.json"
    fi
    
    echo "   ✅ 完成"
  else
    echo "⏭️  $OLD_ID 不存在，跳过"
  fi
done

echo ""
echo "=== 迁移完成 ==="
echo ""
echo "新目录结构:"
for TARGET in opencode rsi a_aaajiao; do
  if [[ -d "$STORAGE_DIR/$TARGET" ]]; then
    COUNT=$(find "$STORAGE_DIR/$TARGET/session" -name "*.json" 2>/dev/null | wc -l)
    echo "  $TARGET/: $COUNT sessions"
  fi
done
