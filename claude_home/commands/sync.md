---
description: 同步 main 分支到当前分支
---

同步 main 分支步骤：

## 1. 检查当前状态

```bash
git branch --show-current
git status --porcelain
```

- 如果在 main 分支，提示：你已在 main，执行 `git pull` 即可
- 如果有未提交的改动，提示先 `/commit` 或 `git stash`

## 2. 获取最新 main

```bash
git fetch origin main
```

## 3. 检查是否需要同步

```bash
git log HEAD..origin/main --oneline
```

如果没有新的 commits，提示：已是最新，无需同步。

## 4. 执行 merge

```bash
git merge origin/main -m "Merge main into $(git branch --show-current)"
```

## 5. 处理结果

### 无冲突
```
✅ 同步成功
   合并了 3 个新 commits 从 main
   
   下一步:
   - /commit  继续开发
   - /pr      创建 Pull Request
```

### 有冲突
```
⚠️ 合并时发现冲突，需要手动解决：

冲突文件:
- src/auth/login.ts
- src/utils/helper.ts

解决步骤:
1. 编辑上述文件，解决 <<<<<<< 和 >>>>>>> 之间的冲突
2. 解决后运行 /commit 提交合并结果

如果想放弃这次合并:
   git merge --abort
```

## 注意事项

- 使用 merge 而非 rebase（更简单，冲突只需解决一次）
- 保持改动已提交状态再 sync
- 冲突时会清晰列出冲突文件
