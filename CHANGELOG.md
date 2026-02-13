# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
