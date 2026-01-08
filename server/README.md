# OCD Server Mode (v1.4.0+)

在 Mac Mini 等服务器上后台运行 OCD，从其他设备通过 Web UI 远程访问。

## 多项目工作区

服务器模式天然支持 OCD v1.4.0 的多项目管理：

```
~/projects/                    # 工作区根目录（挂载到 /workspace）
├── webapp/                    # 项目 A（有 .git）
├── api-server/                # 项目 B（有 .git）
└── mobile-app/                # 项目 C（有 .git）
```

- 所有 Git 仓库在 Web UI 可见
- 每个项目的会话独立隔离
- 项目级 `.claude/todos` 和 `.claude/transcripts` 保留

## 与本地模式 (ocd) 的区别

| 特性 | 本地模式 (ocd) | 服务器模式 (docker-compose) |
|------|---------------|---------------------------|
| 运行方式 | 交互式终端 | 后台守护进程 |
| 多项目支持 | ✅ 自动检测工作区 | ✅ 挂载整个 ~/projects |
| 多实例 | ✅ 支持 | ❌ 单实例 |
| 自动重启 | ❌ | ✅ |
| URL/通知桥接 | ✅ | ❌ |
| 剪贴板同步 | ✅ | ❌ |
| 适用场景 | 本地开发 | 远程访问 |

## 快速开始

### 1. 首次设置

```bash
cd ~/opencode/server
chmod +x init.sh
./init.sh
```

这会自动：
- 创建必要目录
- 生成配置文件
- 构建 Docker 镜像

### 2. 配置 API Keys

确保 `~/opencode/.env` 已配置：

```bash
OPENAI_API_KEY=sk-xxx
ANTHROPIC_API_KEY=sk-ant-xxx
GITHUB_TOKEN=ghp_xxx
```

### 3. 启动服务

```bash
cd ~/opencode/server
docker-compose up -d
```

### 4. 访问

```bash
# 本地
http://localhost:4096

# 局域网（替换为 Mac Mini 的 IP）
http://192.168.1.100:4096

# Tailscale（替换为 Tailscale IP）
http://100.64.1.23:4096
```

## 目录结构

```
~/
├── opencode/                           # OCD 配置仓库
│   ├── server/                         # 服务器模式配置（本目录）
│   │   ├── docker-compose.yml
│   │   ├── init.sh
│   │   ├── status.sh                   # 状态检测脚本
│   │   ├── tailscale.md                # Tailscale 详细配置指南
│   │   └── README.md
│   ├── global/                         # 全局 skill/command/agent
│   ├── Dockerfile
│   ├── opencode.sh                     # 本地模式
│   └── .env                            # API Keys
│
├── projects/                           # 项目根目录（挂载到容器 /workspace）
│   ├── project-a/
│   ├── project-b/
│   └── ...
│
├── .config/opencode/
│   └── server/                         # 服务器实例配置
│       ├── opencode.json
│       └── oh-my-opencode.json
│
├── .opencode_data/
│   └── server/                         # 服务器实例运行时数据
│
├── .local/
│   ├── share/opencode/                 # 共享数据（认证等）
│   └── state/opencode/                 # UI 状态持久化
│
└── .cache/
    ├── ms-playwright/                  # Playwright 浏览器缓存
    └── oh-my-opencode/                 # oh-my-opencode 二进制缓存
```

## 日常管理

### 查看状态

```bash
# 快速状态检测（显示所有访问地址）
./status.sh

# Docker 容器状态
docker-compose ps
```

### 查看日志

```bash
# 实时日志
docker-compose logs -f

# 最近 100 行
docker-compose logs --tail=100
```

### 重启服务

```bash
docker-compose restart
```

### 停止服务

```bash
docker-compose down
```

### 更新镜像

```bash
# 重新构建（代码更新后）
docker-compose build --no-cache
docker-compose up -d

# 或者拉取最新基础镜像
docker-compose pull
docker-compose up -d
```

### 进入容器调试

```bash
docker exec -it opencode-server bash
```

## 远程访问配置

### 方式一：局域网访问

直接使用 Mac Mini 的局域网 IP：

```bash
# 查看 IP
ipconfig getifaddr en0

# 访问
http://192.168.1.100:4096
```

### 方式二：Tailscale（推荐）

Tailscale 提供安全的点对点加密连接，无需开放端口。

> 详细配置指南见 [tailscale.md](./tailscale.md)，包含 MagicDNS、HTTPS 证书、子网路由等高级功能。

#### Mac Mini 端

```bash
# 安装
brew install tailscale

# 启动并登录
tailscale up

# 获取 Tailscale IP
tailscale ip -4
# 输出类似：100.64.1.23
```

#### 客户端

1. 在其他设备安装 Tailscale 并登录同一账号
2. 访问 `http://100.64.1.23:4096`

#### 优点

- 端到端加密
- 无需公网 IP
- 无需配置路由器/防火墙
- 支持 macOS、Windows、Linux、iOS、Android
- 个人使用免费

### 方式三：Cloudflare Tunnel（公网域名）

如果需要通过自定义域名访问：

```bash
# 安装
brew install cloudflared

# 登录
cloudflared tunnel login

# 创建隧道
cloudflared tunnel create ocd

# 配置路由
cloudflared tunnel route dns ocd ocd.yourdomain.com

# 运行
cloudflared tunnel run --url http://localhost:4096 ocd
```

## 切换项目

服务器模式挂载整个 `~/projects` 目录，在 Web UI 中可以切换不同项目：

1. 使用 OpenCode 原生项目切换（左上角项目选择器）
2. 或使用命令 `cd /workspace/project-name`

每个项目自动识别为独立 Git 仓库，会话和 todos 按项目隔离。

## 与本地模式共存

服务器模式和本地模式可以同时运行：

```bash
# Mac Mini 上运行服务器模式
cd ~/opencode/server
docker-compose up -d
# 端口：4096，实例名：opencode-server

# 本地 MacBook 上运行本地模式
cd ~/my-project
ocd
# 端口：4096（或自动分配），实例名：opencode-my-project
```

两者使用不同的容器名和数据目录，互不干扰。

## 故障排除

### 容器启动失败

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
lsof -i :4096
```

### 无法远程访问

1. 检查防火墙：系统偏好设置 → 安全性与隐私 → 防火墙
2. 检查 Docker 是否正常运行
3. 确认 IP 地址正确

### 配置不生效

```bash
# 重建容器（不重建镜像）
docker-compose up -d --force-recreate

# 完全重建
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 健康检查失败

```bash
# 查看健康状态
docker inspect opencode-server | grep -A 10 Health

# 手动测试
curl http://localhost:4096/health
```

## 安全建议

1. **不要暴露到公网**：使用 Tailscale 或 VPN，而非直接端口转发
2. **定期更新**：保持 Docker 镜像和依赖更新
3. **API Key 保护**：确保 `.env` 文件权限正确 (`chmod 600`)
4. **网络隔离**：如果可能，使用独立的 VLAN
