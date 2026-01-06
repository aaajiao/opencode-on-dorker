---
description: 列出所有运行中的开发服务器
---

列出所有 omo-dev-* 开头的 tmux 会话：

1. 使用 bash 运行 `tmux list-sessions 2>/dev/null | grep "omo-dev-"` 
2. 对于每个会话，用 `tmux capture-pane -t {session-name} -p | grep -E "(http://|https://)"` 提取访问地址
3. 以表格形式展示：

| 项目 | 会话名 | 状态 | 访问地址 |
|------|--------|------|----------|

如果没有运行中的开发服务器，告知用户。
