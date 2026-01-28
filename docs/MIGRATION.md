# OCD 迁移指南

从旧版本升级到 OCD v6.0 的完整指南。

---

## 版本历史

| 版本 | 主要变更 |
|------|----------|
| v4.x | 每次启动重新生成配置 |
| v5.0 | 配置用户所有，模板系统 |
| v6.0 | 目录名改为复数形式 (skills/, agents/, etc.) |

---

## v5.x → v6.0 迁移

### 变更内容

目录名从单数改为复数，以兼容 oh-my-opencode v3.1.4+：

| 旧名称 | 新名称 |
|--------|--------|
| `skill/` | `skills/` |
| `agent/` | `agents/` |
| `command/` | `commands/` |
| `plugin/` | `plugins/` |

### 自动迁移

OCD v6.0 首次启动时会自动检测并提示：

```
⚠️  OCD v6 Migration Required
   Singular directories detected. Migration to plural names needed.
   Run: bash /workspace/scripts/migrate-v6-plural-dirs.sh
```

### 手动迁移

```bash
# 预览变更
bash scripts/migrate-v6-plural-dirs.sh --dry-run

# 执行迁移（自动备份）
bash scripts/migrate-v6-plural-dirs.sh
```

迁移脚本会：
1. 备份现有目录到 `.backup-singular-v5/`
2. 重命名所有单数目录为复数
3. 创建 `.ocd-v6-migrated` 标记文件

### 迁移位置

| 位置 | 路径 |
|------|------|
| 全局配置 | `~/.config/opencode/` |
| 项目配置 | `<project>/.opencode/` |
| 项目配置 | `<project>/.claude/` |

---

## v4.x → v5.0 迁移

### 自动迁移

OCD v5.0 首次运行时自动检测 v4.x 配置：

1. 检测 `~/.config/opencode/opencode.json` 是否存在
2. 备份到 `~/.config/opencode/backup-v4/`
3. 从模板创建新配置
4. 显示迁移完成信息

### 手动迁移

```bash
# 备份旧配置
mv ~/.config/opencode ~/.config/opencode-v4-backup

# 重新启动
ocd
```

### v4 → v5 变更

| 方面 | v4 | v5 |
|------|-----|-----|
| 配置生成 | 每次启动重新生成 | 首次创建，之后只更新端口 |
| 用户修改 | 下次启动会丢失 | 永久保留 |
| 模板位置 | 硬编码在脚本中 | `templates/` 目录 |
| 项目初始化 | 无 | `ocd init` 命令 |

---

## 故障排除

### 迁移后技能/命令不工作

检查目录名是否为复数：

```bash
ls ~/.config/opencode/
# 应该看到: skills/ agents/ commands/ (复数)
# 不是: skill/ agent/ command/ (单数)
```

### 恢复备份

```bash
# v6 迁移备份
cp -r ~/.config/opencode/.backup-singular-v5/* ~/.config/opencode/

# v5 迁移备份
cp -r ~/.config/opencode/backup-v4/* ~/.config/opencode/
```

### 完全重置

```bash
ocd --clean
```

这会备份现有配置并重新从模板创建。

---

## 相关文档

- [配置详解](./CONFIGURATION.md)
- [CLI 命令参考](./CLI_REFERENCE.md)
