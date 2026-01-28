---
name: task-completion-notify
description: (user - Skill) 任务完成后发送 macOS 桌面通知提醒
---

# 任务完成通知

在任务完成后自动发送 macOS 桌面通知，让用户及时知道结果。

## 自动触发场景

### 1. Subagent 任务完成
当委托给其他 agent 的任务返回结果后，**必须**发送通知：
- `@document-writer` 完成文档编写
- `@frontend-ui-ux-engineer` 完成 UI 开发
- `@oracle` 完成分析咨询
- `@librarian` / `@explore` 完成搜索研究
- 任何通过 `task` 工具调用的 subagent

### 2. 用户请求的任务完成
当用户明确要求执行某项任务，且任务已完成时：
- 代码修改并提交/推送完成
- 文件创建/修改完成
- 构建/测试运行完成
- 任何需要等待的操作完成

## 行为规则

1. **Subagent 返回后立即通知** - 不需要用户额外请求
2. **用户任务完成后通知** - 特别是涉及 git push、长时间操作
3. **失败时也要通知** - 说明失败原因
4. **通知内容简洁明了** - 标题说明是什么，内容说明结果

## 通知命令

```bash
notify "标题" "内容"
```

## 通知示例

```bash
# Subagent 完成
notify "文档更新完成 ✅" "TOOLS.md 已重新组织并推送到 GitHub"
notify "Oracle 分析完成" "架构建议已生成，请查看"

# 任务完成
notify "Git Push 完成 ✅" "3 个提交已推送到 origin/main"
notify "构建成功 ✅" "项目编译通过，无错误"

# 失败情况
notify "构建失败 ❌" "TypeScript 编译错误，请检查"
```
