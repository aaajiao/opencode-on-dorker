# OCD CLI 命令参考

OCD 命令行接口完整参考。

---

## 基本语法

```bash
ocd [选项] [子命令]
```

---

## 全局选项

| 选项 | 说明 |
|------|------|
| `-v` | 显示版本号 |
| `-h` | 显示帮助 |
| `-p <port>` | 指定端口（默认自动分配） |
| `-r` | 重建 Docker 镜像 + 清理缓存 |
| `--here` | 只挂载当前目录（不检测工作区） |
| `--clean` | 重置配置（备份现有 + 重新创建） |
| `--https` | 通过 Tailscale Serve 启用 HTTPS |
| `--awake` | 防止 Mac 进入休眠 (caffeinate) |
| `--merge-up` | 合并 transcripts 到父项目 |
| `--quotio` | 启用 Quotio 代理 |

---

## 子命令

### `ocd init`

初始化项目配置，创建 `.opencode/`、`.claude/`、`AGENTS.md`。

```bash
cd ~/projects/my-app
ocd init
```

### `ocd config`

显示配置路径和状态。

```bash
ocd config
```

输出示例：
```
OCD 配置状态
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
全局配置: ~/.config/opencode/
  ├─ opencode.json ✓
  ├─ oh-my-opencode.json ✓
  └─ skills/ (1 个)
```

### `ocd config edit`

用编辑器打开全局配置文件。

```bash
ocd config edit
```

### `ocd scan`

扫描工作区内的 git 项目并注册到 OpenCode。

```bash
cd ~/projects
ocd scan
```

### `ocd touch <项目名>`

更新项目时间戳，使其出现在 WebUI 的 "Recent projects" 列表。

```bash
ocd touch my-app
```

---

## 工作区模式

OCD 自动检测 Git 仓库并将其父目录作为工作区：

```
~/projects/              # 工作区（挂载到 /workspace）
├── webapp/              # 项目 A (.git)
├── api-server/          # 项目 B (.git)
└── mobile-app/          # 项目 C (.git)
```

```bash
cd ~/projects/webapp/src/components
ocd
# → 检测到 ~/projects/webapp/.git
# → 挂载 ~/projects 到 /workspace
# → 启动后在 /workspace/webapp/src/components
```

使用 `--here` 跳过工作区检测：

```bash
ocd --here  # 只挂载当前目录
```

---

## 开发模式

用于测试 OCD 本身的修改：

```bash
# 使用 git worktree 设置开发环境
cd ~/opencode
git worktree add dev dev

# 使用开发版启动
devocd

# 重建开发镜像
devocd -r
```

开发模式特性：
- 独立镜像 `opencode-bun-dev`
- 独立配置 `~/.config/opencode-dev/`
- 启动信息显示 `[DEV]` 标识

---

## 常见操作

### 重建镜像

```bash
ocd -r
```

### 重置配置

```bash
ocd --clean  # 备份现有配置后重新创建
```

### 端口冲突

```bash
rm ~/.config/opencode/.port.lock
```

### OAuth 认证

```bash
# 在容器内执行
opencode auth login
```
