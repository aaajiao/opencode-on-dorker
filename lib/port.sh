#!/usr/bin/env bash
# lib/port.sh - 端口管理模块

# =========================================
# 查找空闲端口（macOS/zsh 兼容，支持并发）
# =========================================
ocd_find_free_port() {
  local base_port=${1:-4096}
  local lock_dir="$HOME/.config/opencode"
  local lock_file="${lock_dir}/.port.lock"
  local port_file="${lock_dir}/.last_port"

  mkdir -p "$lock_dir"

  # 使用 mkdir 作为原子锁（macOS 兼容）
  local max_wait=10
  local waited=0
  while ! mkdir "$lock_file" 2>/dev/null; do
    sleep 0.5
    waited=$((waited + 1))
    if [[ $waited -ge $max_wait ]]; then
      rm -rf "$lock_file"  # 强制解锁（超时）
      break
    fi
  done

  # 一次性获取所有监听端口
  local used_ports
  used_ports=$(lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1{print $9}' | grep -oE '[0-9]+$' | sort -u || true)

  # 从上次分配的端口+1 开始（减少冲突）
  local start_port=$base_port
  if [[ -f "$port_file" ]]; then
    local saved_port
    saved_port=$(cat "$port_file" 2>/dev/null || echo "")
    if [[ "$saved_port" =~ ^[0-9]+$ ]]; then
      start_port=$(( saved_port + 1 ))
      [[ $start_port -ge $((base_port + 100)) ]] && start_port=$base_port
    fi
  fi

  # 查找空闲端口
  local found_port=""
  for ((p=start_port; p<base_port+100; p++)); do
    if ! echo "$used_ports" | grep -qw "$p"; then
      found_port=$p
      break
    fi
  done

  # 回绕检查
  if [[ -z "$found_port" ]]; then
    for ((p=base_port; p<start_port; p++)); do
      if ! echo "$used_ports" | grep -qw "$p"; then
        found_port=$p
        break
      fi
    done
  fi

  # 记录并输出
  found_port=${found_port:-$base_port}
  echo "$found_port" > "$port_file"
  echo "$found_port"

  # 解锁
  rm -rf "$lock_file" 2>/dev/null
}
