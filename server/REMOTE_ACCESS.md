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

## HTTPS 模式（可选）

HTTPS 让浏览器不显示安全警告。Tailscale 本身已加密，HTTP 也是安全的。

### 启用 HTTPS

#### 1. Tailscale 后台启用证书

1. 打开 https://login.tailscale.com/admin/dns
2. 确保 **MagicDNS** 已启用
3. 在 **HTTPS Certificates** 下点击 **Enable HTTPS**

#### 2. 获取证书

```bash
# 查看你的机器名
tailscale status

# 获取证书（替换为你的机器名）
tailscale cert 你的机器名.tail****.ts.net

# 桌面版用完整路径
/Applications/Tailscale.app/Contents/MacOS/Tailscale cert 你的机器名.tail****.ts.net
```

成功输出：
```
Wrote public cert to xxx.crt
Wrote private key to xxx.key
```

#### 3. 启动 Tailscale Serve

```bash
# 启动 HTTPS 代理（端口号改成你用的，比如 4096 或 4111）
tailscale serve --bg 4096

# 桌面版用完整路径
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --bg 4096
```

#### 4. 访问

```
https://你的机器名.tail****.ts.net
```

**注意**：使用 Tailscale Serve 后**不需要端口号**，它会自动代理到你指定的端口。

### Tailscale Serve 命令参考

```bash
# 启动（后台运行）
tailscale serve --bg <端口>
tailscale serve --bg 4096

# 查看状态
tailscale serve status

# 关闭
tailscale serve --https=443 off

# 桌面版需要用完整路径
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --bg 4096
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve status
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve off
```

### Tailscale Cert 命令参考

```bash
# 获取证书
tailscale cert <域名>

# 查看现有证书状态
# 在 Tailscale Admin Console 查看：
# https://login.tailscale.com/admin/machines → 点击机器 → TLS certificate

# 桌面版完整路径
/Applications/Tailscale.app/Contents/MacOS/Tailscale cert <域名>
```

## 常见问题

### 如何查看 Tailscale IP？

```bash
tailscale ip -4
```

### 如何查看机器名和域名？

```bash
tailscale status
# 输出示例：
# 100.78.42.15  aaajiao-m4-max-16  macOS  -
# 域名就是：aaajiao-m4-max-16.tail****.ts.net
```

### 手机连不上？

1. 确认 Mac 和手机都登录了 **同一个 Tailscale 账号**
2. 确认 Mac 上 OCD 正在运行
3. 确认 Tailscale 已连接（Mac 菜单栏图标为连接状态）

### OCD 没显示远程地址？

确认 Tailscale 已安装并运行：

```bash
tailscale status
```

### 证书获取失败 (404 error)？

1. 确认 https://login.tailscale.com/admin/dns 里 HTTPS Certificates 显示 **Enabled**
2. 等几分钟再试
3. 检查域名是否正确拼写

### Tailscale Serve 不工作？

```bash
# 检查状态
tailscale serve status

# 如果显示 "No certificate found"，先获取证书
tailscale cert 你的机器名.tail****.ts.net

# 然后重新启动 serve
tailscale serve --bg 4096
```

## 安全说明

- Tailscale 使用端到端加密
- 只有登录你账号的设备才能访问
- 不暴露公网，无需担心安全问题
- HTTP 在 Tailscale 内部也是安全的，HTTPS 只是避免浏览器警告

## 工作区白名单

可以限制 ocd 只在特定目录下运行，防止误操作。

### 配置

编辑 `~/opencode/.ocdrc`：

```bash
# 允许的工作区目录（用冒号分隔）
OCD_ALLOWED_WORKSPACES="/Users/你的用户名/opencode:/Users/你的用户名/o_projects"
```

### 效果

```bash
# 在白名单目录 ✅
cd ~/o_projects/myapp
ocd
# → 正常启动

# 在其他目录 ❌
cd ~/Downloads/random
ocd
# → ❌ 工作区 /Users/xxx/Downloads 不在白名单内
```

### 绕过白名单

以下方式可以绕过白名单限制：

```bash
# 只挂载当前目录（不检测工作区）
ocd --here

# 手动指定工作区目录
ocd -w ~/any/path

# 环境变量方式
export OCD_WORKSPACE=~/any/path
ocd
```

这是为了兼容性设计，允许在特殊情况下手动覆盖限制。

## 防止 Mac 休眠

远程访问时，Mac 休眠会导致连接断开。使用 `--awake` 参数防止休眠：

```bash
ocd -p 4096 --awake
```

可以和其他参数组合：

```bash
ocd -p 4096 --https --awake
```

输出：
```
🚀 OCD v1.4.0 │ myproject │ http://localhost:4096
   └─ 🔒 HTTPS: https://xxx.tail****.ts.net
   └─ ☕ 防休眠已启用
```

退出 ocd 时自动恢复正常休眠行为。
