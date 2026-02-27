# OCD 快速开始指南

详细的安装和配置说明。

---

## 前置要求

| 依赖 | 说明 | 安装 |
|------|------|------|
| macOS | 仅支持 macOS | - |
| OrbStack | Docker 运行时（推荐）| [orbstack.dev](https://orbstack.dev/) |
| jq | JSON 处理 | `brew install jq` |
| fswatch | 文件监控 | `brew install fswatch` |
| terminal-notifier | 桌面通知 | `brew install terminal-notifier` |

```bash
brew install jq fswatch terminal-notifier
```

---

## 安装步骤

### 1. 克隆项目

```bash
git clone https://github.com/aaajiao/opencode-on-dorker.git ~/opencode
cd ~/opencode
```

### 2. 配置 API Keys

```bash
cp env.example .env
nano .env
```

**.env 格式要求**（纯 KEY=VALUE，无引号无注释）：

```bash
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

| 变量 | 说明 | 必需 |
|------|------|:----:|
| `OPENAI_API_KEY` | OpenAI API 密钥 | 是 |
| `GITHUB_TOKEN` | GitHub Token | 是 |
| `ANTHROPIC_API_KEY` | Anthropic API 密钥 | 否 |
| `EXA_API_KEY` | Exa AI 密钥 | 否 |

### 3. 添加到 PATH

```bash
echo 'export PATH="$HOME/opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 4. 首次构建

```bash
ocd -r
```

首次运行时，OCD 会：
1. 构建 Docker 镜像
2. 从 `templates/global/` 创建配置文件
3. 显示欢迎信息和配置路径

---

## 验证安装

```bash
# 检查版本
ocd -v
# → OCD 0.7.3

# 查看配置状态
ocd config
```

---

## 基本使用

```bash
# 在任意项目目录启动
cd ~/projects/my-app
ocd

# 指定端口
ocd -p 5000

# 只挂载当前目录
ocd --here
```

详细命令参考：[CLI_REFERENCE.md](./CLI_REFERENCE.md)

---

## 初始化项目配置

在项目中创建 `.opencode/`、`.claude/` 等配置目录：

```bash
cd ~/projects/my-app
ocd init
```

这会创建：
- `.opencode/` - OpenCode 项目配置
- `.claude/` - Claude Code 配置
- `AGENTS.md` - AI Agent 指南

---

## 下一步

- [CLI 命令参考](./CLI_REFERENCE.md)
- [配置详解](./CONFIGURATION.md)
- [架构说明](./ARCHITECTURE.md)
