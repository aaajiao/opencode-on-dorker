# AI 编程测试指南

让 AI 在提交代码前自动运行测试并确保测试覆盖率的最佳实践。

## 1. Claude Code Hooks（推荐）

在 `~/.claude/settings.json` 中配置 Pre-commit 钩子：

```json
{
  "hooks": {
    "PreCommit": [
      {
        "type": "command",
        "command": "bats tests/bats/*.bats",
        "description": "运行所有单元测试"
      }
    ]
  }
}
```

### 支持的钩子类型

| 钩子 | 触发时机 |
|------|---------|
| `PreCommit` | git commit 前 |
| `PostCommit` | git commit 后 |
| `PrePush` | git push 前 |

## 2. Git Pre-commit Hook

创建 `.git/hooks/pre-commit`：

```bash
#!/bin/bash
set -e

echo "🧪 Running tests before commit..."

# 运行测试
if ! bats tests/bats/*.bats; then
  echo "❌ Tests failed. Commit aborted."
  exit 1
fi

# 检查覆盖率（可选）
total=$(grep -ch "^ocd_.*() {" lib/*.sh | paste -sd+ | bc)
tested=$(grep -hE "ocd_[a-z_]+" tests/bats/*.bats | grep -oE "ocd_[a-z_]+" | sort -u | wc -l | tr -d ' ')
coverage=$((tested * 100 / total))

if [ $coverage -lt 80 ]; then
  echo "❌ Coverage $coverage% < 80%. Commit aborted."
  exit 1
fi

echo "✅ All tests passed (coverage: $coverage%)"
```

激活钩子：

```bash
chmod +x .git/hooks/pre-commit
```

## 3. 通过 Rules 要求 AI

创建 `.claude/rules/testing.md`：

```markdown
# 测试要求

## 提交前必须

1. 运行 `bats tests/bats/*.bats` 确保所有测试通过
2. 如果修改了 `lib/*.sh`，确保对应的测试文件也更新
3. 新功能必须有对应的测试
4. 测试覆盖率不得低于 80%

## 测试命名规范

- 测试文件：`tests/bats/<module>.bats`
- 测试函数：`@test "<功能>: <描述>"`

## 示例

修改 `lib/port.sh` 后：

\`\`\`bash
# 1. 运行相关测试
bats tests/bats/port.bats

# 2. 运行完整测试
bats tests/bats/*.bats

# 3. 确认覆盖率
./scripts/run-tests.sh
\`\`\`
```

## 4. GitHub Actions 强制检查

### 4.1 CI 配置

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Unit Tests
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: brew install bats-core jq fswatch

      - name: Run tests
        run: bats tests/bats/*.bats

      - name: Check coverage
        run: |
          total=$(grep -ch "^ocd_.*() {" lib/*.sh | paste -sd+ | bc)
          tested=$(grep -hE "ocd_[a-z_]+" tests/bats/*.bats | grep -oE "ocd_[a-z_]+" | sort -u | wc -l)
          coverage=$((tested * 100 / total))
          echo "Coverage: $coverage%"
          echo "coverage=$coverage" >> $GITHUB_OUTPUT
          [ $coverage -ge 80 ] || exit 1
```

### 4.2 Branch Protection Rules

在 GitHub 仓库设置中：

1. **Settings** → **Branches** → **Add rule**
2. 勾选 **Require status checks to pass before merging**
3. 选择必须通过的检查：
   - `Unit Tests`
   - `ShellCheck`
   - `Syntax Check`

## 5. 覆盖率检查脚本

创建 `scripts/check-coverage.sh`：

```bash
#!/bin/bash
# scripts/check-coverage.sh - 检查测试覆盖率

set -euo pipefail

MIN_COVERAGE=${1:-80}

# 统计函数
total=$(grep -h "^ocd_[a-z_]*() {" lib/*.sh | wc -l | tr -d ' ')
tested=$(grep -hE "ocd_[a-z_]+" tests/bats/*.bats | grep -oE "ocd_[a-z_]+" | sort -u | wc -l | tr -d ' ')
coverage=$((tested * 100 / total))

echo "📊 测试覆盖率报告"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "总函数数: $total"
echo "已测试数: $tested"
echo "覆盖率:   $coverage%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 列出未测试的函数
echo ""
echo "未测试的函数："
comm -23 \
  <(grep -h "^ocd_[a-z_]*() {" lib/*.sh | sed 's/() {//' | sort) \
  <(grep -hE "ocd_[a-z_]+" tests/bats/*.bats | grep -oE "ocd_[a-z_]+" | sort -u)

# 检查是否达标
echo ""
if [ $coverage -ge $MIN_COVERAGE ]; then
  echo "✅ 覆盖率 $coverage% >= $MIN_COVERAGE% (通过)"
  exit 0
else
  echo "❌ 覆盖率 $coverage% < $MIN_COVERAGE% (不通过)"
  exit 1
fi
```

## 6. 最佳实践总结

| 方法 | 适用场景 | 强制程度 |
|------|---------|---------|
| Claude Rules | AI 编程时的软约束 | 低（依赖 AI 遵守） |
| Git Hooks | 本地开发 | 中（可被绕过） |
| Claude Hooks | Claude Code 用户 | 中 |
| GitHub Actions | 团队协作 | 高（无法绕过） |
| Branch Protection | 生产分支保护 | 最高 |

### 推荐组合

```
开发时：Claude Rules + Git Hooks
└─ 提醒 AI 运行测试
└─ 本地提交前自动检查

合并时：GitHub Actions + Branch Protection
└─ CI 自动运行测试
└─ 未通过测试无法合并
```

## 7. 常见问题

### Q: AI 忘记运行测试怎么办？

在项目的 `.claude/rules/` 中添加明确规则，或使用 Claude Hooks 自动触发。

### Q: 如何处理耗时很长的测试？

```bash
# 快速测试（跳过慢速测试）
./scripts/run-tests.sh --quick

# 完整测试（CI 中运行）
./scripts/run-tests.sh
```

### Q: 测试失败但需要紧急提交？

```bash
# 绕过 pre-commit hook（不推荐）
git commit --no-verify -m "emergency fix"
```

但 GitHub Actions 仍会运行，需要后续修复。
