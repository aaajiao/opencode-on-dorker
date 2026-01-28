# OCD v6.0.0: 目录命名迁移方案 (单数 → 复数)

## TL;DR

> **Quick Summary**: 将 OCD 的目录命名从单数 (`skill/`, `agent/`, `command/`, `plugin/`) 改为复数 (`skills/`, `agents/`, `commands/`, `plugins/`)，以符合 OpenCode 官方标准和 oh-my-opencode v3.1.4+ 规范。
> 
> **Deliverables**:
> - 迁移脚本 `scripts/migrate-v6-plural-dirs.sh`
> - 更新 4 个 shell 脚本中的 6 处 mkdir 命令
> - 重命名 6 个模板目录
> - 更新 8 个文档文件
> - 更新 3+ 个测试文件
> - 版本升级到 v6.0.0
> 
> **Estimated Effort**: Medium (4-6 小时)
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Migration Script → Shell Scripts → Tests

---

## Context

### Original Request
用户调研发现 OCD 的目录命名与 OpenCode 官方标准不一致，需要迁移。

### Interview Summary
**Key Discussions**:
- OpenCode 官方文档推荐复数形式 (`skills/`, `agents/`, `commands/`)
- oh-my-opencode PR #966 (2026-01-21) 已修复为复数形式
- 用户报告单数形式不工作 (Issue #810, #930, #1116)
- 社群共识：使用复数形式

**Research Findings**:
- oh-my-opencode 源码现在使用 `skills/` (复数)
- Claude 目录已经是复数，无需修改
- `themes/` 已经是复数，无需修改

**User Decisions**:
- `plugin/` 也改为 `plugins/` (保持一致性)
- 冲突处理：合并内容到复数目录
- 版本号：v6.0.0 (破坏性变更)

### Metis Review
**Identified Gaps** (addressed):
1. `plugin/` 是否改为复数 → 用户确认：改
2. 冲突处理策略 → 用户确认：合并
3. 版本号策略 → 用户确认：v6.0.0
4. Claude 目录已经是复数 → 不修改
5. `themes/` 已经是复数 → 不修改

---

## Work Objectives

### Core Objective
将 OCD 的 OpenCode 目录命名从单数改为复数，使其与 OpenCode 官方标准和 oh-my-opencode 兼容。

### Concrete Deliverables
- `scripts/migrate-v6-plural-dirs.sh` - 用户配置迁移脚本
- 更新后的 `lib/config.sh`, `lib/docker.sh`, `server/init.sh`
- 重命名后的 `templates/` 目录结构
- 更新后的所有文档
- 通过的测试套件
- `VERSION` 文件更新为 6.0.0
- `CHANGELOG.md` 更新

### Definition of Done
- [ ] `bats tests/bats/*.bats` 全部通过
- [ ] `bash -n bin/ocd lib/*.sh` 语法检查通过
- [ ] `shellcheck -S warning bin/ocd lib/*.sh` 无错误
- [ ] 新安装创建复数目录
- [ ] 旧配置自动迁移到复数目录
- [ ] oh-my-opencode 能加载 skills

### Must Have
- 自动迁移脚本
- 备份机制
- 冲突合并处理
- 文档更新
- 测试更新

### Must NOT Have (Guardrails)
- ❌ 不修改 Claude 目录引用（已经是复数）
- ❌ 不修改 `themes/` 目录（已经是复数）
- ❌ 不添加新功能或重构无关代码
- ❌ 不删除用户内容（只移动/重命名）
- ❌ 不更改运行容器内的路径
- ❌ 不添加交互式提示（除了必要的 Y/n）
- ❌ 不添加回滚功能（备份足够）

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (BATS)
- **User wants tests**: YES (Tests-after)
- **Framework**: bats

### Manual Execution Verification

**For each TODO, verify:**
1. `bash -n <modified-file>` - 语法检查
2. `shellcheck -S warning <modified-file>` - Lint 检查
3. `bats tests/bats/*.bats` - 单元测试

**Final Integration Test:**
```bash
# 测试新安装
rm -rf /tmp/ocd-test-config
OCD_CONFIG_HOME=/tmp/ocd-test-config bash -c 'source lib/config.sh && ocd_ensure_global_config /workspace/dev'
ls /tmp/ocd-test-config/  # 应显示: skills/ commands/ agents/

# 测试迁移
mkdir -p /tmp/ocd-test-migrate/{skill/test-skill,agent,command}
echo "test" > /tmp/ocd-test-migrate/skill/test-skill/SKILL.md
bash scripts/migrate-v6-plural-dirs.sh /tmp/ocd-test-migrate
ls /tmp/ocd-test-migrate/  # 应显示: skills/ commands/ agents/
cat /tmp/ocd-test-migrate/skills/test-skill/SKILL.md  # 应显示: test
```

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
├── Task 1: Create migration script (no dependencies)
└── Task 6: Update VERSION and CHANGELOG (no dependencies)

Wave 2 (After Wave 1):
├── Task 2: Rename template directories (depends: 1)
├── Task 3: Update lib/config.sh (depends: 1)
├── Task 4: Update lib/docker.sh (depends: 1)
└── Task 5: Update server/init.sh (depends: 1)

Wave 3 (After Wave 2):
├── Task 7: Update tests (depends: 2,3,4,5)
├── Task 8: Update documentation (depends: 2,3,4,5)
└── Task 9: Integration in lib/migrate.sh (depends: 1,3)

Critical Path: Task 1 → Task 3 → Task 7
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2,3,4,5,9 | 6 |
| 2 | 1 | 7,8 | 3,4,5 |
| 3 | 1 | 7,9 | 2,4,5 |
| 4 | 1 | 7 | 2,3,5 |
| 5 | 1 | 7 | 2,3,4 |
| 6 | None | None | 1 |
| 7 | 2,3,4,5 | None | 8,9 |
| 8 | 2,3,4,5 | None | 7,9 |
| 9 | 1,3 | None | 7,8 |

---

## TODOs

- [x] 1. Create migration script `scripts/migrate-v6-plural-dirs.sh`

  **What to do**:
  - 创建迁移脚本，处理单数 → 复数目录迁移
  - 支持全局配置 (`~/.config/opencode/`) 和项目配置 (`.opencode/`)
  - 创建备份到 `.backup-singular-v5/`
  - 处理冲突：合并内容到复数目录
  - 幂等设计：多次运行安全

  **Must NOT do**:
  - 不添加交互式提示（除了必要的 Y/n）
  - 不删除用户内容
  - 不修改 Claude 目录

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单文件创建，逻辑清晰
  - **Skills**: [`git-master`]
    - `git-master`: 可能需要 git mv 操作

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 6)
  - **Blocks**: Tasks 2,3,4,5,9
  - **Blocked By**: None

  **References**:
  - `scripts/migrate-v5-global-claude.sh` - 现有迁移脚本模式
  - `lib/migrate.sh` - 迁移检测逻辑模式
  - oh-my-opencode PR #966 - 官方迁移参考

  **Acceptance Criteria**:
  - [ ] 脚本语法检查通过: `bash -n scripts/migrate-v6-plural-dirs.sh`
  - [ ] ShellCheck 通过: `shellcheck -S warning scripts/migrate-v6-plural-dirs.sh`
  - [ ] 手动测试迁移逻辑（见 Verification Strategy）

  **Commit**: NO (groups with Task 9)

---

- [x] 2. Rename template directories

  **What to do**:
  - 重命名 `templates/global/opencode/skill/` → `templates/global/opencode/skills/`
  - 重命名 `templates/global/opencode/command/` → `templates/global/opencode/commands/`
  - 创建 `templates/global/opencode/agents/` (当前不存在)
  - 重命名 `templates/project/.opencode/skill/` → `templates/project/.opencode/skills/`
  - 重命名 `templates/project/.opencode/agent/` → `templates/project/.opencode/agents/`
  - 重命名 `templates/project/.opencode/command/` → `templates/project/.opencode/commands/`
  - 重命名 `templates/project/.opencode/plugin/` → `templates/project/.opencode/plugins/`

  **Must NOT do**:
  - 不修改 `.claude/` 目录（已经是复数）
  - 不修改文件内容（只重命名目录）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 简单的 git mv 操作
  - **Skills**: [`git-master`]
    - `git-master`: 使用 git mv 保留历史

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3,4,5)
  - **Blocks**: Tasks 7,8
  - **Blocked By**: Task 1

  **References**:
  - `templates/` 目录结构
  - `templates/AGENTS.md` - 模板文档

  **Acceptance Criteria**:
  - [ ] `ls templates/global/opencode/` 显示 `skills/`, `commands/`, `agents/`
  - [ ] `ls templates/project/.opencode/` 显示 `skills/`, `commands/`, `agents/`, `plugins/`
  - [ ] `templates/global/opencode/skills/remind/SKILL.md` 存在
  - [ ] Git 状态显示重命名（非删除+新增）

  **Commit**: NO (groups with Task 9)

---

- [x] 3. Update `lib/config.sh`

  **What to do**:
  - Line 71: `{agent,command,skill,themes}` → `{agents,commands,skills,themes}`
  - Line 325: `{agent,command,skill,plugin}` → `{agents,commands,skills,plugins}`
  - Line 488: `{skill,command,agent}` → `{skills,commands,agents}`
  - Lines 95-128: 更新复制逻辑中的路径引用
    - `template_opencode/agent` → `template_opencode/agents`
    - `template_opencode/skill` → `template_opencode/skills`
    - `template_opencode/command` → `template_opencode/commands`
    - `$config_dir/skill/` → `$config_dir/skills/`
    - `$config_dir/agent/` → `$config_dir/agents/`
    - `$config_dir/command/` → `$config_dir/commands/`

  **Must NOT do**:
  - 不修改 Line 326 (Claude 目录已经是复数)
  - 不重构代码结构
  - 不添加新功能

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 明确的字符串替换
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2,4,5)
  - **Blocks**: Tasks 7,9
  - **Blocked By**: Task 1

  **References**:
  - `lib/config.sh:71` - 全局配置目录创建
  - `lib/config.sh:95-128` - 模板复制逻辑
  - `lib/config.sh:325-326` - 项目配置目录创建
  - `lib/config.sh:488` - 重置时目录创建

  **Acceptance Criteria**:
  - [ ] `bash -n lib/config.sh` 通过
  - [ ] `shellcheck -S warning lib/config.sh` 无错误
  - [ ] `grep -n "skill/" lib/config.sh` 无结果（除了注释）
  - [ ] `grep -n "skills/" lib/config.sh` 有结果

  **Commit**: NO (groups with Task 9)

---

- [x] 4. Update `lib/docker.sh`

  **What to do**:
  - Line 97: `{skill,command,agent}` → `{skills,commands,agents}`
  - 检查是否有其他路径引用需要更新

  **Must NOT do**:
  - 不修改 Line 100 (Claude 目录已经是复数)
  - 不修改 Line 124 的循环（处理 Claude 目录）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单行修改
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2,3,5)
  - **Blocks**: Task 7
  - **Blocked By**: Task 1

  **References**:
  - `lib/docker.sh:97` - OpenCode 目录创建
  - `lib/docker.sh:100` - Claude 目录创建（不修改）
  - `lib/docker.sh:124-128` - 挂载逻辑（检查是否需要更新）

  **Acceptance Criteria**:
  - [ ] `bash -n lib/docker.sh` 通过
  - [ ] `shellcheck -S warning lib/docker.sh` 无错误
  - [ ] `grep -n "{skill,command,agent}" lib/docker.sh` 无结果

  **Commit**: NO (groups with Task 9)

---

- [x] 5. Update `server/init.sh`

  **What to do**:
  - Line 123: `{skill,command,agent}` → `{skills,commands,agents}`

  **Must NOT do**:
  - 不修改 Line 124 (Claude 目录已经是复数)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单行修改
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 2,3,4)
  - **Blocks**: Task 7
  - **Blocked By**: Task 1

  **References**:
  - `server/init.sh:123-124` - 服务器模式目录创建

  **Acceptance Criteria**:
  - [ ] `bash -n server/init.sh` 通过
  - [ ] `shellcheck -S warning server/init.sh` 无错误

  **Commit**: NO (groups with Task 9)

---

- [x] 6. Update VERSION and CHANGELOG

  **What to do**:
  - 更新 `VERSION` 文件为 `6.0.0`
  - 在 `CHANGELOG.md` 顶部添加 v6.0.0 section
  - 记录破坏性变更和迁移说明

  **Must NOT do**:
  - 不修改历史版本记录
  - 不添加未实现的功能

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 简单文件编辑
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `VERSION` - 当前版本文件
  - `CHANGELOG.md` - 变更日志格式

  **Acceptance Criteria**:
  - [ ] `cat VERSION` 显示 `6.0.0`
  - [ ] `head -50 CHANGELOG.md` 包含 v6.0.0 section
  - [ ] CHANGELOG 包含迁移说明

  **Commit**: NO (groups with final commit)

---

- [x] 7. Update test files

  **What to do**:
  - 更新 `tests/bats/config.bats` 中的路径断言
  - 更新 `tests/bats/init.bats` 中的路径断言
  - 更新 `tests/bats/docker.bats` 中的路径断言
  - 添加迁移脚本测试（可选）

  **Must NOT do**:
  - 不重构测试结构
  - 不添加新测试场景（除了迁移测试）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 字符串替换
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8,9)
  - **Blocks**: None
  - **Blocked By**: Tasks 2,3,4,5

  **References**:
  - `tests/bats/config.bats` - 配置测试
  - `tests/bats/init.bats` - 初始化测试
  - `tests/bats/docker.bats` - Docker 测试
  - `tests/AGENTS.md` - 测试文档

  **Acceptance Criteria**:
  - [ ] `bats tests/bats/config.bats` 通过
  - [ ] `bats tests/bats/init.bats` 通过
  - [ ] `bats tests/bats/docker.bats` 通过
  - [ ] `grep -r "skill/" tests/bats/*.bats` 无结果（除了迁移测试）

  **Commit**: NO (groups with final commit)

---

- [x] 8. Update documentation files

  **What to do**:
  - 更新 `README.md` 中的目录结构示意图
  - 更新 `AGENTS.md` 中的目录引用
  - 更新 `templates/AGENTS.md`
  - 更新 `docs/SKILL_DESIGN_PATTERNS.md`
  - 更新 `docs/SKILL_QUICK_REFERENCE.md`
  - 更新 `docs/OPENCODE_CONFIG_GUIDE.md`
  - 更新 `docs/OH_MY_OPENCODE_SKILL_SYSTEM.md`
  - 更新 `docs/ARCHITECTURE.md`
  - 更新 `server/README.md`
  - 更新 `lib/AGENTS.md`

  **Must NOT do**:
  - 不重写文档
  - 不添加新章节
  - 只更新目录名称

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: 文档更新
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7,9)
  - **Blocks**: None
  - **Blocked By**: Tasks 2,3,4,5

  **References**:
  - 所有 .md 文件中的 `skill/`, `agent/`, `command/`, `plugin/` 引用

  **Acceptance Criteria**:
  - [ ] `grep -r "\.opencode/skill/" docs/ README.md AGENTS.md templates/` 无结果
  - [ ] `grep -r "opencode/skill/" docs/ README.md AGENTS.md templates/` 无结果
  - [ ] 文档中的示例路径都使用复数形式

  **Commit**: NO (groups with final commit)

---

- [x] 9. Integrate migration into `lib/migrate.sh`

  **What to do**:
  - 在 `ocd_check_migration()` 中添加 v6 迁移检测
  - 检测是否存在旧的单数目录
  - 调用 `scripts/migrate-v6-plural-dirs.sh`
  - 添加标记文件 `.ocd-v6-migrated`

  **Must NOT do**:
  - 不修改 v4→v5 迁移逻辑
  - 不强制迁移（提供选项）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 小幅代码添加
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7,8)
  - **Blocks**: None
  - **Blocked By**: Tasks 1,3

  **References**:
  - `lib/migrate.sh` - 现有迁移逻辑
  - `lib/migrate.sh:ocd_check_migration()` - 迁移入口点

  **Acceptance Criteria**:
  - [ ] `bash -n lib/migrate.sh` 通过
  - [ ] `shellcheck -S warning lib/migrate.sh` 无错误
  - [ ] 新安装不触发迁移
  - [ ] 旧配置触发迁移

  **Commit**: YES
  - Message: `feat!: migrate directory naming from singular to plural (v6.0.0)`
  - Files: 所有修改的文件
  - Pre-commit: `bash -n bin/ocd lib/*.sh && bats tests/bats/*.bats`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 9 (final) | `feat!: migrate directory naming from singular to plural (v6.0.0)` | All modified files | `bats tests/bats/*.bats` |

---

## Success Criteria

### Verification Commands
```bash
# 语法检查
bash -n bin/ocd lib/*.sh scripts/*.sh server/*.sh

# Lint 检查
shellcheck -S warning bin/ocd lib/*.sh

# 单元测试
bats tests/bats/*.bats

# 手动验证：新安装
rm -rf /tmp/ocd-test && OCD_CONFIG_HOME=/tmp/ocd-test bash -c 'source lib/core.sh && source lib/config.sh && ocd_ensure_global_config /workspace/dev'
ls /tmp/ocd-test/  # Expected: skills/ commands/ agents/ themes/

# 手动验证：迁移
mkdir -p /tmp/ocd-migrate-test/{skill/test,agent,command}
echo "test" > /tmp/ocd-migrate-test/skill/test/SKILL.md
bash scripts/migrate-v6-plural-dirs.sh /tmp/ocd-migrate-test
ls /tmp/ocd-migrate-test/  # Expected: skills/ commands/ agents/ (no skill/ agent/ command/)
```

### Final Checklist
- [ ] 所有 "Must Have" 已实现
- [ ] 所有 "Must NOT Have" 未违反
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] VERSION 为 6.0.0
- [ ] CHANGELOG 已更新
