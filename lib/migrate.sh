#!/usr/bin/env bash
# lib/migrate.sh - v4 → v5 迁移模块

ocd_check_migration() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  
  # 检测 v4 配置（存在配置但无 v5 标记）
  if [[ -f "$config_dir/opencode.json" ]] && \
     [[ ! -f "$config_dir/.ocd-v5-migrated" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔄 OCD v5 配置说明"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  从 v5 开始，配置文件由你管理，OCD 只更新端口。"
    echo ""
    echo "  你的配置文件已保留："
    echo "    - $config_dir/opencode.json"
    echo "    - $config_dir/oh-my-opencode.json"
    echo ""
    
    touch "$config_dir/.ocd-v5-migrated"
  fi
  
  # 提示 mcp.json 已废弃
  if [[ -f "$ocd_root/mcp.json" ]]; then
    echo "  ⚠️  检测到 ~/opencode/mcp.json"
    echo "     v5 的 MCP 配置已移至 opencode.json 的 mcp 字段"
    echo "     请手动迁移后删除 mcp.json"
    echo ""
  fi
}
