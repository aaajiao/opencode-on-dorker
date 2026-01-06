---
description: 完成开发，清理分支
---

完成开发并清理分支步骤：

## 1. 检查当前分支

```bash
git branch --show-current
```

如果在 main/master 分支，提示：已在 main，无需清理。

## 2. 检查未提交的改动

```bash
git status --porcelain
```

如果有未提交的改动：
```
⚠️ 有未提交的改动，是否放弃这些改动？
   
   改动文件:
   - src/auth/login.ts (modified)
   - src/utils/new-file.ts (new)
   
   [y] 放弃改动并清理
   [n] 取消，先处理这些改动
```

## 3. 检查 PR 状态

```bash
gh pr view --json state,mergedAt,url 2>/dev/null
```

### 情况 A: PR 已合并
```
✅ PR #123 已合并，正在清理...
```
继续执行清理。

### 情况 B: PR 未合并
```
⚠️ PR #123 尚未合并
   https://github.com/owner/repo/pull/123
   
   确定要删除分支吗？[y/N]
```

### 情况 C: 没有 PR
```
⚠️ 该分支没有关联的 PR
   
   确定要删除分支吗？[y/N]
```

## 4. 执行清理

```bash
# 记住当前分支名
BRANCH=$(git branch --show-current)

# 切换到 main
git checkout main

# 拉取最新
git pull origin main

# 删除本地分支
git branch -D $BRANCH

# 删除远程分支（如果存在）
git push origin --delete $BRANCH 2>/dev/null || true
```

## 5. 报告结果

```
✅ 清理完成

   已删除分支: feature/add-login-captcha
   已切换到: main (最新)
   
   开始新功能:
   - /branch 创建新分支
```

## 注意事项

- 删除前会检查 PR 状态，避免误删未合并的分支
- 同时清理本地和远程分支
- 自动切换到 main 并更新到最新
