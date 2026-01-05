# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenCode Docker 环境配置项目 - 在 macOS + OrbStack 环境下运行 OpenCode AI 编程助手，集成 oh-my-opencode 多 Agent 协作插件。

## Architecture

```
├── Dockerfile           # 基于 oven/bun 的 Docker 镜像，包含:
│                        #   - Node.js 22 + Bun + Python3 虚拟环境
│                        #   - Playwright (chromium)、GitHub CLI、uv
│                        #   - 自定义 xdg-open 将 URL 写入文件供 Mac 打开
│
├── docker-compose.yml   # Host 网络模式配置，支持 OAuth 回调
│                        # 挂载: ~/.config/opencode, ~/.local/share/opencode, ~/.ssh
│
├── opencode.sh          # Shell 函数，添加到 ~/.zshrc 使用
│                        # 功能: 镜像构建、配置生成、URL 监听、容器启动
│
├── env.example          # 环境变量模板 (复制为 .env)
└── README.md            # 完整安装和使用文档
```

## Commands

```bash
# 启动 OpenCode (在任意项目目录)
opencode

# 强制重建镜像 (清除缓存和配置)
opencode -r

# Docker Compose 方式
docker-compose run --rm opencode
docker-compose build --no-cache
```

## Configuration Files (运行时生成)

| 文件 | 位置 | 用途 |
|------|------|------|
| `opencode.json` | `~/.config/opencode/` | 主配置: model, provider, mcp, plugin |
| `oh-my-opencode.json` | `~/.config/opencode/` | Agent 模型分配、禁用的 MCP |
| `auth.json` | `~/.local/share/opencode/` | OAuth 认证信息 |

## Key Implementation Details

### xdg-open 重定向机制
容器内 xdg-open 被替换为自定义脚本，将 URL 写入 `/root/.opencode/open_url`。
`opencode.sh` 中的后台进程监听该文件，调用 Mac 的 `open` 命令打开浏览器。

### 网络模式
使用 `--network host` 让容器共享 Mac 网络，解决 OAuth 回调端口问题。

### 环境变量格式
`.env` 文件必须是纯 `KEY=VALUE` 格式，不能有 `export`、引号或注释。
