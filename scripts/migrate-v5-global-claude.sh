#!/bin/bash
set -e

GLOBAL_CLAUDE="$HOME/.claude"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OCD v5 迁移：项目级 → 全局存储"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p "$GLOBAL_CLAUDE"/{todos,transcripts,commands,skills,agents,rules}

total_transcripts=0
total_todos=0
projects_processed=0

find_project_claude_dirs() {
  local search_paths=(
    "$HOME/projects"
    "$HOME/code"
    "$HOME/workspace"
    "$HOME/dev"
    "$HOME/opencode"
    "$HOME/o_projects"
  )
  
  for base in "${search_paths[@]}"; do
    [[ -d "$base" ]] && find "$base" -maxdepth 4 -name ".claude" -type d 2>/dev/null
  done
}

echo "扫描项目..."
echo ""

for claude_dir in $(find_project_claude_dirs); do
  project_dir=$(dirname "$claude_dir")
  project_name=$(basename "$project_dir")
  local_changes=0
  
  if [[ -d "$claude_dir/transcripts" ]]; then
    count=$(find "$claude_dir/transcripts" -maxdepth 1 -name "*.jsonl" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "📦 $project_name: 迁移 $count 个 transcripts"
      mv "$claude_dir/transcripts"/*.jsonl "$GLOBAL_CLAUDE/transcripts/" 2>/dev/null || true
      total_transcripts=$((total_transcripts + count))
      local_changes=1
    fi
    rmdir "$claude_dir/transcripts" 2>/dev/null || true
  fi
  
  if [[ -d "$claude_dir/todos" ]]; then
    count=$(find "$claude_dir/todos" -maxdepth 1 -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "📦 $project_name: 迁移 $count 个 todos"
      mv "$claude_dir/todos"/*.json "$GLOBAL_CLAUDE/todos/" 2>/dev/null || true
      total_todos=$((total_todos + count))
      local_changes=1
    fi
    rmdir "$claude_dir/todos" 2>/dev/null || true
  fi
  
  if [[ -d "$claude_dir" ]]; then
    mkdir -p "$claude_dir"/{commands,skills,agents,rules} 2>/dev/null || true
  fi
  
  [[ "$local_changes" -eq 1 ]] && projects_processed=$((projects_processed + 1))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 迁移完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  处理项目数: $projects_processed"
echo "  迁移 transcripts: $total_transcripts"
echo "  迁移 todos: $total_todos"
echo ""
echo "  全局目录: $GLOBAL_CLAUDE"
echo "  - transcripts: $(find "$GLOBAL_CLAUDE/transcripts" -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ') 个"
echo "  - todos: $(find "$GLOBAL_CLAUDE/todos" -name "*.json" 2>/dev/null | wc -l | tr -d ' ') 个"
echo ""

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$CONFIG_DIR"
touch "$CONFIG_DIR/.claude-global-migrated"
echo "  已标记迁移完成，OCD 启动时不再提示。"
echo ""
