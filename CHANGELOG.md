# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.4] - 2026-03-07

### Changed

- **依赖升级**: OpenCode 1.2.17 → 1.2.21, oh-my-opencode 3.10.0 → 3.11.1
- **模型升级 (GPT-5.4)**: 跟进 oh-my-openagent v3.11.0 大版本模型更新，Oracle/Momus/Metis/Prometheus/Multimodal-Looker 全面切换到 `gpt-5.4`
  - Oracle: `gpt-5.3-codex` → `gpt-5.4` (reasoningEffort: high)
  - Momus: `gpt-5.2` → `gpt-5.4` (reasoningEffort: xhigh)
  - Metis: `claude-opus-4-6` → `gpt-5.4` (reasoningEffort: high)
  - Prometheus: `claude-opus-4-6` → `gpt-5.4` (reasoningEffort: high)
  - Multimodal-Looker: `gemini-3-flash` → `gpt-5.4`
  - Hephaestus 保持 `gpt-5.3-codex`（深度自主工作最优）
- **可用模型列表刷新**: 新增 `gpt-5.4`，精简旧模型（gpt-5.2-codex、gpt-5.1-codex）

## [0.7.3] - 2026-02-27

### Changed

- **依赖升级**: OpenCode 1.2.10 → 1.2.17, oh-my-opencode 3.8.3 → 3.10.0, Bun 1.3.9 → 1.3.10
- **模型升级**: 模板全面切换到 `gpt-5.3-codex`（Hephaestus、Oracle、ultrabrain、deep 四处），explore 改为 `claude-haiku-4-5`
- **新增 Categories 配置**: 模板和文档新增 8 个任务类别（visual-engineering、ultrabrain、deep、artistry、quick、unspecified-low、unspecified-high、writing）
- **新增 git-master 配置**: 模板新增 `commit_footer`、`include_co_authored_by` 选项
- **配置示例全面扩充**: `oh-my-opencode.example.jsonc` 从 115 行扩展到 235 行，新增 categories、skills、background_tasks、git-master、comment-checker、LSP、agent permissions、实验性功能等完整参考
- **models.conf.example 刷新**: 全面对齐 models.conf（4-5 → 4-6 系列，5.2-codex → 5.3-codex，补全新模型列表）
- **README 语言切换**: 主 README 改为英文（GitHub 首页），中文移至 `docs/README_CN.md`
- **Agent 表格更新**: 新增 Hephaestus、Prometheus 等 v3.x agents

### Added

- **OH_MY_OPENCODE.md 新增章节**: Categories 配置、Hooks（35+ 内置 hook 一览）、Background Tasks 配置、Comment Checker 配置、Agent 权限控制、LSP 配置、实验性功能总览（aggressive_truncation、auto_resume、preemptive_compaction、truncate_all_tool_outputs）
- **Git Master 配置文档**: 在 Skill 详解中新增配置选项说明

---

## [0.7.2] - 2026-02-27

### Changed

- **依赖升级**: OpenCode 1.2.10→1.2.15, oh-my-opencode 3.8.3→3.9.0, Bun 1.3.9→1.3.10
- **模型升级**: Hephaestus/Oracle 从 gpt-5.2-codex 升级到 gpt-5.3-codex
- **可用模型列表刷新**: 按 Zen 最新端点重写，新增 gpt-5.3-codex、gemini-3.1-pro、minimax-m2.5、glm-5、kimi-k2.5、qwen3-coder 等

---

## [0.7.1] - 2026-02-23

### Changed

- **依赖升级**: OpenCode 1.2.5→1.2.10, oh-my-opencode 3.6.0→3.8.3
- **模型更新**: Atlas/Sisyphus-Junior 升级到 claude-sonnet-4-6, Oracle 切换到 gpt-5.2-codex
- **Playwright CLI 模式**: 从 MCP server 切换到 CLI+SKILL 模式（token 节省 4-10x）
- 新增可用模型: claude-sonnet-4-6, gemini-3.1, minimax-m2.1, big-pickle

### Removed

- **Quotio**: 移除全部 Quotio 相关配置（--quotio flag、env vars、docs）
- **Playwright MCP**: 移除 opencode.json 中的 MCP server 配置，改用 @playwright/cli

---

## [0.7.0] - 2026-02-13

全新版本。不兼容 v1.x ~ v6.x，不提供迁移路径。

旧版本用户请 `ocd --clean` 重新生成配置。

### Breaking Changes

- **移除所有迁移代码**: 删除 `lib/migrate.sh` 及 `scripts/migrate-*.sh`
- **不再兼容 v4/v5/v6 旧配置**: 无自动迁移，需 `ocd --clean` 重置
- **版本号重置为 0.x**: 反映项目尚在快速迭代的实际状态

### Removed

- `lib/migrate.sh` — v4→v5→v6 迁移模块
- `scripts/migrate-v4.sh` — v3→v4 迁移脚本
- `scripts/migrate-v5-global-claude.sh` — Claude 全局存储迁移
- `scripts/migrate-v6-plural-dirs.sh` — 单数→复数目录迁移
- `ocd_auto_migrate()` — core.sh 中的自动迁移函数
- 所有 `.ocd-v5-migrated`、`.ocd-v6-migrated` 标记文件引用

---

<details>
<summary>历史版本 (v1.0.0 ~ v6.0.0)</summary>

旧版本历史已归档。完整记录见 git history。

</details>
