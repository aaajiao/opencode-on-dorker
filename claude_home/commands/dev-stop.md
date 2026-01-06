---
description: 停止开发服务器
argument-hint: "<project-name | all>"
---

停止开发服务器：

$ARGUMENTS 可以是：
- 项目名称（如 vocab-tracker）→ 停止 omo-dev-vocab-tracker 会话
- "all" → 停止所有 omo-dev-* 会话

步骤：
1. 如果 $ARGUMENTS 是 "all"：
   - 用 bash 运行 `tmux list-sessions 2>/dev/null | grep "omo-dev-" | cut -d: -f1`
   - 对每个会话执行 `kill-session -t {session-name}`
2. 否则：
   - 停止 `omo-dev-{$ARGUMENTS}` 会话
   - 使用 interactive_bash: `kill-session -t omo-dev-{project-name}`

报告已停止的会话列表。
