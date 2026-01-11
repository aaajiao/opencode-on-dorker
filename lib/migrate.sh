#!/usr/bin/env bash
# lib/migrate.sh - v4 → v5 迁移模块

ocd_check_migration() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  
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
  
  if [[ -f "$ocd_root/mcp.json" ]]; then
    echo "  ⚠️  检测到 ~/opencode/mcp.json"
    echo "     v5 的 MCP 配置已移至 opencode.json 的 mcp 字段"
    echo "     请手动迁移后删除 mcp.json"
    echo ""
  fi
}

ocd_check_claude_migration() {
  local config_dir="${OCD_CONFIG_HOME:-$HOME/.config/opencode}"
  local ocd_root="${OCD_ROOT:-$HOME/opencode}"
  local marker="$config_dir/.claude-global-migrated"
  
  [[ -f "$marker" ]] && return 0
  
  local needs_migration=0
  local search_paths=(
    "$HOME/projects"
    "$HOME/code"
    "$HOME/workspace"
    "$HOME/dev"
    "$HOME/opencode"
    "$HOME/o_projects"
  )
  
  for base in "${search_paths[@]}"; do
    if [[ -d "$base" ]]; then
      while IFS= read -r -d '' claude_dir; do
        local todos_dir="${claude_dir}/todos"
        local transcripts_dir="${claude_dir}/transcripts"
        
        if [[ -d "$todos_dir" ]] && [[ -n "$(ls -A "$todos_dir" 2>/dev/null)" ]]; then
          needs_migration=1
          break 2
        fi
        if [[ -d "$transcripts_dir" ]] && [[ -n "$(ls -A "$transcripts_dir" 2>/dev/null)" ]]; then
          needs_migration=1
          break 2
        fi
      done < <(find "$base" -maxdepth 4 -name ".claude" -type d -print0 2>/dev/null)
    fi
  done
  
  if [[ "$needs_migration" -eq 1 ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠️  检测到项目级会话数据需要迁移"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  v5 将 todos/transcripts 改为全局存储。"
    echo ""
    read -r -p "  是否立即迁移？[Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
      echo ""
      "$ocd_root/scripts/migrate-v5-global-claude.sh"
    else
      echo ""
      echo "  跳过迁移。下次启动时会再次提示。"
      echo "  手动运行: $ocd_root/scripts/migrate-v5-global-claude.sh"
      echo ""
    fi
  else
    touch "$marker"
  fi
}
