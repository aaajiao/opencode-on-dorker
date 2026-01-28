# Decisions - OCD Plural Migration

## [2026-01-28T15:39:24] Plan Started

### Architectural Decisions

**AD-1**: 使用复数形式目录命名
- **Rationale**: 符合 OpenCode 官方标准和 oh-my-opencode 规范
- **Trade-offs**: 需要迁移现有配置，但长期收益大于成本
- **Status**: Approved

**AD-2**: 版本号升级到 v6.0.0
- **Rationale**: 破坏性变更，符合语义化版本规范
- **Trade-offs**: 用户需要注意升级说明
- **Status**: Approved

**AD-3**: 自动迁移 + 备份
- **Rationale**: 降低用户迁移成本，同时保证数据安全
- **Trade-offs**: 增加代码复杂度
- **Status**: Approved

**AD-4**: 冲突时合并内容
- **Rationale**: 保留所有用户数据
- **Trade-offs**: 可能有重复文件
- **Status**: Approved

---
