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
brew install tailscale
tailscale up
```

首次运行会打开浏览器登录，使用 Google/GitHub/Apple 账号即可。

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

## 安全说明

- Tailscale 使用端到端加密
- 只有登录你账号的设备才能访问
- 不暴露公网，无需担心安全问题
