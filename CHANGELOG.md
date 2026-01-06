# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
