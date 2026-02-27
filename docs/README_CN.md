```
  ██████╗  ██████╗██████╗
 ██╔═══██╗██╔════╝██╔══██╗
 ██║   ██║██║     ██║  ██║
 ██║   ██║██║     ██║  ██║
 ╚██████╔╝╚██████╗██████╔╝
  ╚═════╝  ╚═════╝╚═════╝
```

[![Version](https://img.shields.io/badge/version-0.7.3-blue.svg)](../CHANGELOG.md)
[![English](https://img.shields.io/badge/lang-English-blue.svg)](../README.md)

在 macOS + OrbStack 环境下运行 [OpenCode](https://opencode.ai) AI 编程助手，集成 [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) 多 Agent 编排插件。

## 功能特性

- 一键启动 OpenCode 容器（`ocd` 命令，自动检测工作区）
- 多窗口支持（自动端口分配 + 锁机制防冲突）
- macOS 集成（桌面通知、剪贴板桥接、链接自动打开）
- oh-my-opencode 多 Agent 协作（Sisyphus、Oracle、Hephaestus 等）
- MCP 服务器 & Playwright 浏览器自动化
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

详细安装说明：[GETTING_STARTED.md](./GETTING_STARTED.md)

## 使用方法

```bash
ocd                  # 在项目目录启动（自动检测工作区）
ocd -p 5000          # 指定端口
ocd --here           # 只挂载当前目录
ocd -r               # 重建镜像
ocd init             # 初始化项目配置
ocd config           # 查看配置状态
ocd scan             # 扫描并注册 git 项目
```

完整命令参考：[CLI_REFERENCE.md](./CLI_REFERENCE.md)

## 环境变量

`.env` 格式（纯 KEY=VALUE，无引号无注释）：

```
OPENAI_API_KEY=sk-proj-xxxx
ANTHROPIC_API_KEY=sk-ant-xxxx
GITHUB_TOKEN=ghp_xxxx
EXA_API_KEY=your-exa-api-key
```

## oh-my-opencode Agent

| 场景 | Agent | 示例 |
|------|-------|------|
| 复杂任务 | Sisyphus (默认) | 直接输入任务 |
| 深度自主工作 | Hephaestus | `deep:` 前缀或被委派 |
| 架构/调试 | `@oracle` | `@oracle 分析这个死锁` |
| 查文档/找示例 | `@librarian` | `@librarian React 18 并发特性` |
| 搜代码 | `@explore` | `@explore 用户认证在哪` |
| 任务规划 | `@prometheus` | `@prometheus 规划认证重构` |
| 大型重构 | `ulw:` | `ulw: 重构认证模块` |

完整指南：[OH_MY_OPENCODE.md](./OH_MY_OPENCODE.md)

## 文档

| 文档 | 说明 |
|------|------|
| [快速开始](./GETTING_STARTED.md) | 详细安装配置 |
| [CLI 参考](./CLI_REFERENCE.md) | 命令行完整参考 |
| [配置详解](./CONFIGURATION.md) | 目录结构、配置生命周期 |
| [架构说明](./ARCHITECTURE.md) | Mac/Docker 映射关系 |
| [开发者指南](./OPENCODE_CONFIG_GUIDE.md) | 扩展和定制 |
| [Agent 指南](./OH_MY_OPENCODE.md) | oh-my-opencode 多 Agent 协作 |

## 依赖要求

- macOS
- [OrbStack](https://orbstack.dev/)（推荐）或 Docker Desktop
- jq, fswatch, terminal-notifier

## 许可证

MIT
