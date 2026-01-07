# Tailscale 远程访问配置

通过 Tailscale 从任何地方安全访问 Mac Mini 上的 OCD 服务。

## 为什么用 Tailscale

| 对比项 | Tailscale | 端口转发 | VPN 服务器 |
|--------|-----------|---------|-----------|
| 安全性 | 端到端加密 | 暴露端口 | 依赖配置 |
| NAT 穿透 | 自动 | 需要路由器配置 | 需要公网 IP |
| 速度 | P2P 直连 | 直连 | 可能绕路 |
| 配置难度 | 极简 | 中等 | 复杂 |
| 费用 | 个人免费 | 免费 | 取决于方案 |

## Mac Mini 设置（服务器端）

### 1. 安装 Tailscale

```bash
brew install tailscale
```

### 2. 启动服务

```bash
brew services start tailscale
```

### 3. 登录账号

```bash
tailscale up
```

浏览器会自动打开登录页面。支持：
- Google 账号
- Microsoft 账号
- GitHub 账号
- 其他 SSO

### 4. 获取 Tailscale IP

```bash
tailscale ip -4
```

输出类似：`100.64.1.23`

### 5. 验证状态

```bash
tailscale status
```

## 客户端设置

在你要访问 OCD 的设备上安装 Tailscale，并登录**同一账号**。

### macOS

```bash
brew install tailscale
brew services start tailscale
tailscale up
```

### iPhone / iPad

1. App Store 搜索 "Tailscale"
2. 安装并打开
3. 登录同一账号
4. 开启 VPN 连接

### Windows

1. 下载：https://tailscale.com/download/windows
2. 安装并登录

### Linux

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Android

1. Google Play 搜索 "Tailscale"
2. 安装并登录

## 访问 OCD

客户端连接 Tailscale 后：

```
http://100.64.1.23:4096
```

替换为你的 Mac Mini 的 Tailscale IP。

## MagicDNS（推荐）

MagicDNS 让你用主机名代替 IP 访问。

### 开启方法

1. 打开 https://login.tailscale.com/admin/dns
2. 找到 "MagicDNS"
3. 点击 "Enable MagicDNS"

### 使用

开启后，可以用主机名访问：

```
http://mac-mini:4096
```

主机名 = Mac Mini 的电脑名（系统偏好设置 → 共享 → 电脑名称）

### 自定义主机名

```bash
# 在 Mac Mini 上执行
sudo tailscale set --hostname=ocd-server
```

然后访问：
```
http://ocd-server:4096
```

## HTTPS 证书（可选）

Tailscale 可以自动签发 HTTPS 证书。

### 前提条件

1. MagicDNS 已开启
2. HTTPS 证书功能已启用（Tailscale 后台 → DNS → HTTPS Certificates）

### 获取证书

```bash
# 在 Mac Mini 上执行
tailscale cert ocd-server.your-tailnet.ts.net
```

这会生成：
- `ocd-server.your-tailnet.ts.net.crt`
- `ocd-server.your-tailnet.ts.net.key`

### 使用 HTTPS

需要在 OCD 前面加一个反向代理（如 nginx/caddy）来使用证书。对于个人使用，HTTP 在 Tailscale 网络内已经足够安全（流量已加密）。

## 子网路由（高级）

让其他设备通过 Mac Mini 访问你的家庭局域网。

### 开启子网路由

```bash
# 在 Mac Mini 上执行
tailscale up --advertise-routes=192.168.1.0/24
```

### 批准路由

1. 打开 https://login.tailscale.com/admin/machines
2. 找到 Mac Mini
3. 点击 "..." → "Edit route settings"
4. 启用 advertised routes

### 使用场景

- 从外网访问家里的 NAS
- 访问局域网内的其他开发服务器
- 远程打印

## 常用命令

```bash
# 查看状态
tailscale status

# 查看 IP
tailscale ip -4

# 查看所有设备
tailscale status --peers

# 测试连接
tailscale ping <设备名或IP>

# 断开连接
tailscale down

# 重新连接
tailscale up

# 查看网络诊断
tailscale netcheck
```

## 故障排除

### 无法连接

```bash
# 检查 Tailscale 状态
tailscale status

# 检查网络
tailscale netcheck

# 重启服务
brew services restart tailscale
```

### 速度慢

```bash
# 检查是否 P2P 直连
tailscale status

# 如果显示 "relay"，说明在中继，可能是：
# 1. 防火墙阻止 UDP
# 2. 网络 NAT 类型严格
```

### MagicDNS 不工作

1. 确认 MagicDNS 已开启
2. 确认两端都在线
3. 尝试用 IP 访问确认服务正常
4. 检查 DNS 设置：`tailscale dns status`

## 安全建议

1. **启用 2FA**：Tailscale 账号开启两步验证
2. **定期检查设备**：移除不再使用的设备
3. **使用 ACL**：限制设备间的访问权限（高级用户）
4. **保持更新**：定期更新 Tailscale 客户端

## 更多资源

- 官方文档：https://tailscale.com/kb/
- 下载页面：https://tailscale.com/download
- 管理后台：https://login.tailscale.com/admin
