---
description: 创建 Pull Request（自动生成标题和描述）
---

创建 Pull Request 步骤：

## 1. 检查前置条件

```bash
git branch --show-current
git status --porcelain
```

- 如果在 main/master 分支，报错：不能从 main 创建 PR
- 如果有未提交的改动，提示先 `/commit`

## 2. 检查远程状态

```bash
# 检查是否已推送
git log origin/$(git branch --show-current)..HEAD --oneline 2>/dev/null
```

如果有未推送的 commits，先推送：
```bash
git push -u origin $(git branch --show-current)
```

## 3. 检查是否已有 PR

```bash
gh pr view --json state 2>/dev/null
```

如果已有 PR，显示链接并询问是否要更新。

## 4. 分析分支改动

```bash
# 获取所有 commits（从分叉点开始）
git log origin/main..HEAD --oneline
git diff origin/main...HEAD --stat
```

分析：
- 所有 commit messages
- 改动的文件和内容
- 整体变更的目的

## 5. 生成 PR 标题和描述

**标题**: 基于分支名和 commits 总结（Conventional Commits 格式）
```
feat(auth): add login validation with captcha
```

**描述**: 使用 Markdown 格式
```markdown
## Summary
- Add captcha verification to login flow
- Implement rate limiting for failed attempts
- Add unit tests for validation logic

## Changes
- `src/auth/captcha.ts` - New captcha service
- `src/auth/login.ts` - Integrate captcha check
- `tests/auth.test.ts` - Add test cases
```

## 6. 创建 PR

```bash
gh pr create --title "<title>" --body "<body>"
```

## 7. 报告结果

```
✅ PR 已创建

   #123: feat(auth): add login validation with captcha
   https://github.com/owner/repo/pull/123
   
   状态: Open, 等待 Review
   
   下一步:
   - 等待 Review
   - 如需修改: /commit 后 git push
   - 合并后: /done 清理分支
```

## 注意事项

- 自动检测 base 分支（通常是 main 或 master）
- PR 描述自动包含改动摘要
- 如果有关联的 Issue，自动添加 "Closes #xxx"
