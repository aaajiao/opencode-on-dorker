# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2026-01-11

### Added
- **v5 配置架构**: 配置文件首次创建后由用户所有，OCD 不再覆盖
  - 每次启动只更新端口号
  - 用户修改的配置永久保留
- **模板系统**: `templates/` 目录
  - `templates/global/` - 全局配置模板
  - `templates/project/` - 项目配置模板
  - 支持 `{{VAR}}` 变量替换
- **新命令**: `ocd init` - 初始化项目级配置
  - 创建 `.opencode/` 目录结构
  - 创建 `.claude/` 目录结构
  - 复制示例配置文件
- **新命令**: `ocd config` - 配置管理
  - `ocd config` - 显示配置路径和状态
  - `ocd config edit` - 用编辑器打开配置
- **v4 自动迁移**: `lib/migrate.sh`
  - 首次运行检测旧配置
  - 自动备份到 `backup-v4/`
  - 从模板创建新配置
- **欢迎信息**: 首次运行显示配置说明
- **devocd 配置隔离**: 使用 `~/.config/opencode-dev/` 独立配置目录

### Changed
- **`--clean` 行为变更**: 现在会先备份再重建（不会丢失用户配置）
- **配置生成逻辑**: 从脚本硬编码改为模板文件
- **lib/config.sh**: 完全重写，实现 v5 配置管理
  - `ocd_ensure_global_config()` - 首次创建
  - `ocd_update_port()` - 端口更新
  - `ocd_reset_global_config()` - 重置（带备份）
  - `ocd_init_project()` - 项目初始化
- **versions.lock**: 简化，只保留核心依赖版本

### Removed
- 每次启动重新生成配置的行为
- `mcp.json` 独立配置文件（合并到 opencode.json）

## [4.0.0] - 2026-01-10

### Changed
- **统一配置**: 合并所有实例配置到单一共享配置
  - `~/.config/opencode/opencode.json` - 主配置
  - `~/.config/opencode/oh-my-opencode.json` - 插件配置
- **会话存储**: 按 Git SHA 存储会话
  - `~/.local/share/opencode/storage/session/<git-sha>/`

### Added
- **多窗口 IPC 隔离**: 按端口隔离 IPC 文件
  - `~/.local/state/opencode/ipc/<port>/`
- **Docker 挂载 ~/.claude**: 如果存在则挂载 Claude 配置目录

## [3.0.0] - 2026-01-09

### Changed
- **XDG Base Directory 规范**: 配置/数据/状态/缓存分离
  - `~/.config/opencode/` - 配置目录（可版本控制）
  - `~/.local/share/opencode/` - 数据目录（需备份）
  - `~/.local/state/opencode/` - 状态目录（可重建）
  - `~/.cache/opencode/` - 缓存目录（可删除）
- **项目级 Claude 兼容层配置**: 条件覆盖挂载
  - 只有当 `.claude/skills/` 等目录存在且非空时才覆盖全局配置
  - 不再自动创建项目级 Claude 配置目录

### Added
- **测试套件扩展**: 105 个测试，80% 函数覆盖率
  - `tests/bats/docker.bats` - Docker 挂载逻辑测试
  - `tests/bats/init.bats` - 初始化函数测试
  - `tests/bats/sete.bats` - set -e 兼容性测试
  - `tests/bats/watcher.bats` - IPC/进程管理测试
  - `tests/bats/core_extended.bats` - 核心函数扩展测试
  - `tests/bats/workspace_extended.bats` - 工作区函数扩展测试
- **CI 改进**
  - Homebrew 缓存加速
  - fswatch 安装（完整 watcher 测试）
  - GitHub Actions 测试摘要
  - 并发控制（取消旧运行）
  - Docker Buildx 缓存
- **文档**: `docs/MOUNT_MAPPING.md` Mac ↔ Docker 目录映射参考

### Fixed
- **fswatch 进程泄漏**: 启动时清理旧 fswatch 进程，防止多窗口 bug
- **set -e 兼容性**: 多处 `((count++))` → `$((count + 1))`
- **oh-my-opencode/bin 目录**: 预创建防止 ENOENT 错误
- **非可写目录处理**: `ocd_init_project` 静默处理错误

### Removed
- `REFACTOR_EXEC.md` - 重构执行文档（已完成）

## [2.0.0] - 2026-01-09

### Changed
- **模块化架构重构**: 将 873 行单文件 `opencode.sh` 拆分为 6 个独立模块
  - `lib/core.sh` - 版本、日志、环境变量加载、名称清理
  - `lib/port.sh` - 端口分配、原子锁机制
  - `lib/workspace.sh` - 工作区检测、白名单验证
  - `lib/watcher.sh` - IPC 文件监控（剪贴板/通知/URL）
  - `lib/config.sh` - 配置文件生成（消除 heredoc 重复）
  - `lib/docker.sh` - Docker 构建与运行
- **新入口点**: `bin/ocd` 替代旧版 `opencode.sh`（旧版保留兼容）

### Added
- **CI/CD 流水线**: GitHub Actions 自动化
  - ShellCheck 静态分析
  - Bats 单元测试
  - Bash 语法检查
  - Docker 构建验证
- **单元测试套件**: 27 个测试覆盖核心模块
  - `tests/bats/core.bats` - 核心模块测试
  - `tests/bats/port.bats` - 端口模块测试
  - `tests/bats/workspace.bats` - 工作区测试
  - `tests/bats/config.bats` - 配置测试
- **ShellCheck 配置**: `.shellcheckrc` 配置文件

### Documentation
- 更新 README 添加架构章节
- 更新 docs/ 目录反映新的模块化结构

## [1.4.0] - 2026-01-08

### Added
- **远程访问**: 通过 Tailscale 从 iPhone/iPad 访问 OCD Web UI
  - 启动时自动检测 Tailscale IP 并显示远程访问 URL
  - `--https` 参数：自动通过 Tailscale Serve 启用 HTTPS
  - `--awake` 参数：防止 Mac 休眠（使用 `caffeinate`）
- **工作区白名单**: `.ocdrc` 配置文件限制允许访问的工作区
  - 阻止访问敏感目录（如 `~/.ssh`、`/etc`）
  - `--here` 和 `-w` 可绕过白名单（用于可信场景）
- 新增文档：`server/REMOTE_ACCESS.md`

### Changed
- 启动输出现在显示远程访问 URL（当 Tailscale 已连接时）：
  ```
  🚀 OCD v1.4.0 │ projects │ http://localhost:4096
     └─ 📱 远程: http://100.x.x.x:4096
  ```

## [1.3.1] - 2026-01-07

### Fixed
- UI settings (thinking visibility, timestamps, code concealment, etc.) now persist across container restarts
- ast-grep and ripgrep binaries are now cached, avoiding re-download on each startup

### Added
- Complete TUI interface settings documentation in `docs/TOOLS.md`
- New mount: `~/.local/state/opencode/` for KV store persistence
- New mount: `~/.cache/oh-my-opencode/` for binary cache

## [1.3.0] - 2026-01-07

### Added
- **剪贴板桥接**: 容器内 `/share` 命令自动同步到 Mac 剪贴板
  - 容器写入 `~/.opencode_data/<instance>/clipboard`
  - Mac watcher 检测后执行 `pbcopy`
- **版本锁定系统**: 支持 `versions.lock` 文件锁定依赖版本
  - 支持锁定: `BUN_VERSION`, `PIP_*`, `OPENCODE_AI_VERSION` 等
- **Playwright 缓存持久化**: 浏览器缓存保存在 `~/.cache/ms-playwright`
- **Per-Instance Session 隔离**: 会话数据存储在 `~/.local/share/opencode/storage/<instance>/`
- **@github Agent**: 从 Claude commands 迁移到 OpenCode agent
  - 新工作流命令: branch, commit, sync, pr, done

### Changed
- 端口检测优化：一次性获取 + 锁机制，多实例无冲突
- Watcher 智能降级：有 fswatch 用事件驱动，无则轮询
- .env 安全加载：防止代码注入
- 自动清理：trap 机制确保退出时清理进程
- 首次运行提示安装可选依赖

### Fixed
- Zsh 兼容性修复（移除 trap RETURN）
- macOS 兼容性修复（使用 mkdir 锁替代 flock）
- Watcher 子进程关闭 stdout 避免命令替换阻塞
- 移除进程替换，改用简单 while 循环读取 .env

## [1.2.0] - 2026-01-06

### Added
- **Exa 动态检测**: 启动时自动检测内置 Exa 是否可用
  - 内置可用 → 使用 oh-my-opencode 内置 Exa
  - 内置不可用 → 自动启用 fallback MCP (exa-mcp-server)
  - 检测结果在启动时显示

### Changed
- Exa MCP 默认禁用，仅作为 fallback
- Entrypoint 增加 Exa 健康检查逻辑

## [1.1.0] - 2026-01-06

### Changed
- Renamed shell command from `opencode` to `ocd` to avoid conflict with native OpenCode CLI
- Renamed helper function prefix from `_opencode_` to `_ocd_`

## [1.0.0] - 2026-01-06

### Added
- **Claude Code 兼容层**: 完整支持 oh-my-opencode 的 Claude Code 兼容功能
  - Skills (`~/opencode/claude_home/skills/`)
  - Commands (`~/opencode/claude_home/commands/`)
  - Agents (`~/opencode/claude_home/agents/`)
  - Rules (`~/opencode/claude_home/rules/`)
  - Hooks (`~/opencode/claude_home/settings.json`)
  - MCP (`~/opencode/claude_home/.mcp.json`)
- **Per-instance 数据隔离**: Todos 和 Transcripts 按实例独立存储
- **版本管理**: VERSION 文件 + Git tags
- **macOS 桌面通知**: 容器内任务完成时通知宿主机
- **多实例支持**: 同时编辑多个项目，自动端口分配

### Changed
- 重构目录结构，使用 `~/opencode/claude_home/` 替代 `~/opencode/skills/`
- Skills 迁移到新的 `claude_home/skills/` 路径

### Fixed
- Exa MCP 使用自定义 `exa-mcp-server` 替代内置 `websearch_exa`（修复 API key header 问题）

## [0.x.x] - Pre-release

### Added
- 初始 Docker 环境配置
- oh-my-opencode 插件集成
- OAuth 认证支持（Claude Max、Gemini Pro）
- URL 重定向机制（容器 → Mac）
- GitHub CLI 自动认证
- Quotio 代理支持 (`--quotio` 开关)

---

## Version Format

- **MAJOR**: 不兼容的架构变更
- **MINOR**: 新功能（向后兼容）
- **PATCH**: Bug 修复（向后兼容）
