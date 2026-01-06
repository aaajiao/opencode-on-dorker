---
description: 创建功能分支（自动命名）
argument-hint: "[功能描述]"
---

创建功能分支的步骤：

## 1. 检查当前状态

首先检查是否已在功能分支上：
```bash
git branch --show-current
```
如果不在 main/master，提示用户当前已在分支上。

## 2. 确定分支名称

### 有改动时（git status 显示有改动）
1. 运行 `git status` 和 `git diff` 分析改动
2. 根据改动内容自动生成分支名：
   - 新功能 → `feature/xxx`
   - Bug修复 → `fix/xxx`  
   - 文档 → `docs/xxx`
   - 重构 → `refactor/xxx`
3. 分支名用英文、小写、连字符分隔

### 有 $ARGUMENTS 时
直接根据描述生成分支名（支持中文描述，翻译成英文分支名）

### 无改动且无参数时
询问用户接下来要做什么，根据回答生成分支名

## 3. 创建并切换分支

```bash
# 确保基于最新 main
git fetch origin
git checkout -b <branch-name> origin/main
```

## 4. 报告结果

```
✅ 已创建并切换到 <branch-name>
   基于: origin/main (commit abc123)
   
   现在可以开始开发，完成后使用:
   - /commit  提交改动
   - /pr      创建 Pull Request
```

## 分支命名规则

| 类型 | 前缀 | 示例 |
|------|------|------|
| 新功能 | feature/ | feature/add-user-avatar |
| 修复 | fix/ | fix/login-error |
| 文档 | docs/ | docs/update-readme |
| 重构 | refactor/ | refactor/auth-module |
| 性能 | perf/ | perf/optimize-query |
| 测试 | test/ | test/add-auth-tests |
