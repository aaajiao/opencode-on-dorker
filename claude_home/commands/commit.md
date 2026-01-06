---
description: 智能提交（自动生成 commit message）
---

智能提交步骤：

## 1. 检查是否有改动

```bash
git status --porcelain
```

如果没有改动，提示用户没有可提交的内容。

## 2. 检查当前分支

```bash
git branch --show-current
```

如果在 main/master 分支，警告用户：
```
⚠️ 你正在 main 分支上，建议先用 /branch 创建功能分支
   继续在 main 提交吗？[y/N]
```

## 3. 分析改动

```bash
# 查看所有改动（已暂存 + 未暂存）
git diff HEAD
git status
```

分析：
- 修改了哪些文件
- 新增/删除/修改的内容
- 代码变更的目的

## 4. 生成 Commit Message

使用 Conventional Commits 格式：
```
<type>(<scope>): <description>

[optional body]
```

类型判断：
| 改动特征 | type |
|----------|------|
| 新功能/新文件 | feat |
| 修复问题 | fix |
| 文档变更 | docs |
| 重构代码 | refactor |
| 添加测试 | test |
| 构建/配置 | chore |
| 性能优化 | perf |

## 5. 执行提交

```bash
# 暂存所有改动
git add -A

# 提交
git commit -m "<generated message>"
```

## 6. 报告结果

```
✅ 已提交: <commit message>
   
   文件: 3 个修改, 1 个新增
   分支: feature/xxx
   
   下一步:
   - /commit  继续提交更多改动
   - /pr      创建 Pull Request
```

## 注意事项

- 不要提交 .env、credentials.json 等敏感文件
- 如果检测到敏感文件，警告用户并排除
- 自动将敏感文件加入 .gitignore（如果没有的话）
