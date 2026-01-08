# 远程访问 OCD（手机/iPad）

从手机或 iPad 访问 Mac 上运行的 OCD Web UI。

## 一键配置

```bash
cd ~/opencode/server
./remote-setup.sh
```

## 手动配置（3 步）

### 1. Mac 安装 Tailscale

```bash
# 安装 App 版本（推荐，更稳定）
brew install --cask tailscale
```

安装后打开应用程序里的 Tailscale，菜单栏会出现图标，点击登录即可。

### 2. 手机/iPad 安装 Tailscale

1. App Store 搜索 **Tailscale**
2. 安装并打开
3. 登录**同一账号**

### 3. 访问 OCD

Mac 上启动 OCD 后，查看启动信息：

```
🚀 OCD v1.4.0 │ myproject │ http://localhost:4096
   └─ 📱 远程: http://100.78.42.15:4096
```

在手机 Safari 中输入远程地址即可。

## 固定端口（推荐）

默认情况下 ocd 会自动分配端口，每次可能不同。固定端口后手机可以收藏地址：

```bash
# 方法一：每次手动指定
ocd -p 4096

# 方法二：设置默认端口（一劳永逸）
echo 'alias ocd="ocd -p 4096"' >> ~/.zshrc
source ~/.zshrc
```

设置后手机收藏 `http://100.x.x.x:4096`，地址永远不变。

## 常见问题

### 如何查看 Tailscale IP？

```bash
tailscale ip -4
```

### 手机连不上？

1. 确认 Mac 和手机都登录了 **同一个 Tailscale 账号**
2. 确认 Mac 上 OCD 正在运行
3. 确认 Tailscale 已连接（Mac 菜单栏图标为绑定状态）

### OCD 没显示远程地址？

确认 Tailscale 已安装并运行：

```bash
tailscale status
```

## HTTPS 模式

使用 `--https` 参数启动，自动获取 Tailscale 证书：

```bash
ocd -p 4096 --https
```

输出：
```
🚀 OCD v1.4.0 │ myproject │ http://localhost:4096
   └─ 🔒 HTTPS: https://mac-mini.tail1234.ts.net
```

手机访问 HTTPS 地址即可，更安全。退出 ocd 时自动关闭 HTTPS 服务。

## 安全说明

- Tailscale 使用端到端加密
- 只有登录你账号的设备才能访问
- 不暴露公网，无需担心安全问题
