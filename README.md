# OCD - OpenCode Docker

[![Version](https://img.shields.io/badge/version-6.0.0-blue.svg)](./CHANGELOG.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](./docs/README_EN.md)

在 macOS + OrbStack 环境下运行 [OpenCode](https://opencode.ai) AI 编程助手，集成 [oh-my-opencode](https://github.com/1msoft/oh-my-opencode) 插件。

## 功能特性

- 一键启动 OpenCode 容器 (`ocd` 命令)
- 多窗口支持（自动端口分配 + 锁机制防冲突）
- macOS 集成（桌面通知、剪贴板桥接、链接自动打开）
- oh-my-opencode 多 Agent 协作
- MCP 服务器（Playwright, Exa, Context7）
- 配置持久化（用户所有，OCD 不覆盖）

## 快速开始

### 1. 安装依赖

```bash
brew install jq fswatch terminal-notifier
```

### 2. 克隆并配置

```bash
git clone https://github.com/aaajiao/opencode-on-dorker.git ~/opencode
cd ~/opencode
cp env.example .env
nano .env  # 填写 API keys
```

### 3. 添加到 PATH

```bash
echo 'export PATH="$HOME/opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 4. 首次构建

```bash
ocd -r
```

详细安装说明：[docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)

## 使用方法

```bash
ocd                  # 在项目目录启动（自动检测工作区）
ocd -p 5000          # 指定端口
ocd --here           # 只挂载当前目录
ocd -r               # 重建镜像
ocd init             # 初始化项目配置
ocd config           # 查看配置状态
```

完整命令参考：[docs/CLI_REFERENCE.md](./docs/CLI_REFERENCE.md)

## 环境变量

`.env` 格式（纯 KEY=VALUE，无引号无注释）：

```bash
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

## 文档

| 文档 | 说明 |
|------|------|
| [快速开始](./docs/GETTING_STARTED.md) | 详细安装配置 |
| [CLI 参考](./docs/CLI_REFERENCE.md) | 命令行完整参考 |
| [配置详解](./docs/CONFIGURATION.md) | 目录结构、配置生命周期 |
| [迁移指南](./docs/MIGRATION.md) | v4→v5→v6 升级 |
| [架构说明](./docs/ARCHITECTURE.md) | Mac/Docker 映射关系 |
| [开发者指南](./docs/OPENCODE_CONFIG_GUIDE.md) | 扩展和定制 |

## oh-my-opencode Agent

| Agent | 用途 |
|-------|------|
| **Sisyphus** | 主编排器 |
| **oracle** | 架构设计、调试 |
| **librarian** | 文档研究 |
| **explore** | 快速搜索 |

常用命令：
```
ultrawork / ulw    # 最大性能模式
@oracle            # 调用调试专家
@librarian         # 查找文档
```

## 依赖要求

- macOS
- [OrbStack](https://orbstack.dev/)（推荐）或 Docker Desktop
- jq, fswatch, terminal-notifier

## 许可证

MIT
