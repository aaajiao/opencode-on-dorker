---
description: 用 Bun 启动开发服务器（支持多项目）
argument-hint: "<project-path> [--port PORT]"
---

启动开发服务器的步骤：

1. 用户必须提供 $ARGUMENTS（项目路径）
2. 从项目路径中提取项目名称作为 tmux 会话名的一部分
   - 例如：/workspace/vocab-tracker → 会话名 `omo-dev-vocab-tracker`
3. 检查该项目是否存在 package.json
4. 如果该项目的会话已存在，先停止旧的
5. 创建新的 tmux 会话并运行 `bun run dev`
6. 报告服务器状态

使用 interactive_bash 工具执行 tmux 命令：
- 会话命名规则：`omo-dev-{项目文件夹名}`
- 检查会话是否存在：`has-session -t {session-name}` (用 bash 运行，检查返回码)
- 停止旧会话：`kill-session -t {session-name}`
- 创建新会话：`new-session -d -s {session-name} -c {project-path}`
- 发送命令：`send-keys -t {session-name} 'bun run dev' Enter`
- 查看输出：用 bash 运行 `tmux capture-pane -t {session-name} -p`

报告格式：
- 项目名称
- 状态：🟢 运行中 / 🔴 启动失败
- 访问地址
- tmux 会话名称

示例：
- /dev /workspace/vocab-tracker → 会话 omo-dev-vocab-tracker
- /dev /workspace/my-api → 会话 omo-dev-my-api
