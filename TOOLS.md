# OpenCode 工具和插件介绍

## 🛠️ 当前可用的工具和插件

### 📁 文件操作类

| 工具 | 功能 |
|------|------|
| `read` | 读取文件内容 |
| `write` | 写入文件内容 |
| `edit` | 编辑文件（精确字符串替换） |
| `glob` | 按模式匹配查找文件 |
| `grep` | 在文件中搜索正则表达式内容 |
| `ast_grep_search` | AST 感知的代码模式搜索（支持25种语言） |
| `ast_grep_replace` | AST 感知的代码替换 |

### 💻 终端与执行类

| 工具 | 功能 |
|------|------|
| `bash` | 执行 bash 命令 |
| `interactive_bash` | 通过 tmux 执行交互式/后台任务 |

### 🌐 网络与浏览器类 (Playwright)

| 工具 | 功能 |
|------|------|
| `webfetch` | 获取网页内容 |
| `playwright_browser_navigate` | 导航到指定 URL |
| `playwright_browser_click` | 点击页面元素 |
| `playwright_browser_type` | 输入文本 |
| `playwright_browser_snapshot` | 获取页面无障碍快照 |
| `playwright_browser_take_screenshot` | 截取页面截图 |
| `playwright_browser_fill_form` | 填写表单 |
| `playwright_browser_tabs` | 标签页管理（列出、新建、关闭、切换） |
| `playwright_browser_select_option` | 下拉框选择 |
| `playwright_browser_hover` | 悬停在元素上 |
| `playwright_browser_drag` | 拖拽操作 |
| `playwright_browser_press_key` | 按键操作 |
| `playwright_browser_evaluate` | 执行 JavaScript |
| `playwright_browser_file_upload` | 文件上传 |
| `playwright_browser_wait_for` | 等待文本出现/消失或指定时间 |
| `playwright_browser_network_requests` | 获取网络请求记录 |
| `playwright_browser_console_messages` | 获取控制台消息 |
| `playwright_browser_handle_dialog` | 处理对话框 |
| `playwright_browser_close` | 关闭浏览器页面 |
| `playwright_browser_resize` | 调整浏览器窗口大小 |
| `playwright_browser_navigate_back` | 返回上一页 |
| `playwright_browser_install` | 安装浏览器 |
| `playwright_browser_run_code` | 运行 Playwright 代码片段 |

### 🔍 LSP 语言服务器类

| 工具 | 功能 |
|------|------|
| `lsp_hover` | 获取符号的类型信息和文档 |
| `lsp_goto_definition` | 跳转到定义 |
| `lsp_find_references` | 查找所有引用 |
| `lsp_document_symbols` | 获取文件的符号大纲 |
| `lsp_workspace_symbols` | 在工作区搜索符号 |
| `lsp_diagnostics` | 获取代码诊断（错误、警告） |
| `lsp_rename` | 重命名符号（全工作区） |
| `lsp_prepare_rename` | 检查重命名是否可行 |
| `lsp_code_actions` | 获取代码修复建议和重构选项 |
| `lsp_code_action_resolve` | 执行代码修复 |
| `lsp_servers` | 列出可用的 LSP 服务器 |

### 🤖 智能代理类

| 代理 | 功能 |
|------|------|
| `explore` | 代码库探索，回答「X在哪里？」「哪个文件有Y？」这类问题 |
| `librarian` | 多仓库分析、远程代码搜索、获取官方文档、查找实现示例 |
| `oracle` | 高级技术顾问，深度架构分析、代码审查和工程指导 |
| `frontend-ui-ux-engineer` | UI/UX 设计与前端开发专家 |
| `document-writer` | 技术文档写作专家（README、API文档、架构文档） |
| `multimodal-looker` | 分析媒体文件（PDF、图片、图表） |
| `general` | 通用代理，处理复杂的多步骤任务 |

### 📚 外部知识库类

| 工具 | 功能 |
|------|------|
| `context7_resolve-library-id` | 查找库的 Context7 ID |
| `context7_query-docs` | 查询任何编程库的最新文档和代码示例 |
| `grep_app_searchGitHub` | 在百万级 GitHub 公开仓库中搜索真实代码示例 |

### 📋 会话与任务管理类

| 工具 | 功能 |
|------|------|
| `todowrite` | 创建和管理任务列表 |
| `todoread` | 读取任务列表 |
| `session_list` | 列出所有会话 |
| `session_read` | 读取会话历史 |
| `session_search` | 搜索会话内容 |
| `session_info` | 获取会话元数据 |
| `background_task` | 在后台执行代理任务 |
| `background_output` | 获取后台任务输出 |
| `background_cancel` | 取消后台任务 |
| `call_omo_agent` | 调用 explore/librarian 代理 |

### 🖼️ 多媒体类

| 工具 | 功能 |
|------|------|
| `look_at` | 分析 PDF、图片、图表等媒体文件，提取信息或描述内容 |

### 🔧 其他工具

| 工具 | 功能 |
|------|------|
| `skill` | 加载特定任务的技能指导 |
| `skill_mcp` | 调用技能嵌入的 MCP 服务器操作 |

---

## 📣 @ 提及功能

在对话中使用 `@` 可以直接召唤特定的智能代理来处理任务。

| 提及 | 代理类型 | 功能描述 |
|------|----------|----------|
| `@explore` | 代码探索 | 上下文感知的代码库搜索，回答「X在哪里？」「哪个文件有Y？」等问题 |
| `@librarian` | 文档专家 | 多仓库分析、搜索远程代码库、获取官方文档、查找开源实现示例 |
| `@oracle` | 技术顾问 | 高级架构决策、深度代码分析、工程指导（GPT-5.2 推理模型） |
| `@frontend-ui-ux-engineer` | 前端专家 | 专注 UI/UX 设计与开发，即使没有设计稿也能打造精美界面 |
| `@document-writer` | 文档写手 | 技术文档写作专家，擅长 README、API 文档、架构文档、用户指南 |
| `@multimodal-looker` | 多媒体分析 | 分析 PDF、图片、图表等媒体文件，提取信息或描述视觉内容 |
| `@general` | 通用代理 | 通用型代理，处理复杂的多步骤任务，支持并行执行 |
| `@build` | 构建代理 | 构建专用代理（需用户手动调用） |
| `@plan` | 规划代理 | 任务规划代理（需用户手动调用） |
| `@Planner-Sisyphus` | 规划代理 | OhMyOpenCode 版本的规划代理 |

### 使用示例

```
@oracle 帮我分析这个架构设计的优缺点
@explore 找到所有使用 useState 的组件
@librarian 查一下 Next.js 14 的 Server Actions 用法
@frontend-ui-ux-engineer 优化这个登录页面的 UI
@document-writer 为这个项目写一份 README
```

---

## ⚡ / 斜杠命令

使用 `/` 斜杠命令可以快速加载特定技能或执行预定义操作。

| 命令 | 功能描述 |
|------|----------|
| `/playwright` | 加载 Playwright 浏览器自动化技能，用于网页抓取、测试、截图和浏览器交互 |
| `/dev` | 启动开发服务器（支持多项目） |
| `/dev-list` | 列出所有运行中的开发服务器 |
| `/dev-stop` | 停止开发服务器 |

### 使用示例

```
/playwright 打开 https://example.com 并截图
/playwright 自动填写登录表单并提交
/dev /workspace/vocab-tracker
/dev-stop all
```

### 🛠️ 开发服务器管理

#### `/dev <project-path>`
- **功能**：用 Bun 启动开发服务器（支持多项目同时运行）
- **机制**：每个项目使用独立的 tmux 会话，命名为 `omo-dev-{项目名}`
- **示例**：`/dev /workspace/vocab-tracker`

#### `/dev-list`
- **功能**：列出所有运行中的开发服务器
- **显示**：项目名、会话名、状态、访问地址

#### `/dev-stop <project-name | all>`
- **功能**：停止开发服务器
- **说明**：可以停止单个项目或所有项目
- **示例**：`/dev-stop vocab-tracker` 或 `/dev-stop all`

### 📝 创建自定义斜杠命令

你可以创建自己的斜杠命令来扩展 OpenCode 的功能。

- **命令文件位置**：
  - 项目级：`.opencode/command/`
  - 全局级：`~/.config/opencode/command/`
- **文件格式**：Markdown 文件，包含 YAML frontmatter

**示例格式**：

```markdown
---
description: 命令描述
args:
  arg_name:
    type: string
    description: 参数说明
---

# 这里写 bash 脚本内容
echo "Hello $1"
```

---

## ✨ 特色功能

1. **Context7 集成** - 可以实时查询各种编程库的最新官方文档
2. **GitHub 代码搜索** - 从真实开源项目中学习代码模式
3. **完整的浏览器自动化** - 基于 Playwright 的网页操作
4. **多代理协作** - 可以并行启动多个专业代理处理复杂任务
5. **LSP 支持** - 具备 IDE 级别的代码智能分析能力
6. **AST 感知搜索** - 支持 25 种语言的语法树级别代码搜索和替换
7. **会话管理** - 支持跨会话搜索和历史记录查询
8. **后台任务** - 支持并行执行多个代理任务，提高效率

---

## 🚀 使用建议

- **探索代码库**: 使用 `explore` 代理快速定位代码位置
- **查找文档**: 使用 `librarian` 代理或 `context7_query-docs` 获取库文档
- **前端开发**: 视觉相关改动交给 `frontend-ui-ux-engineer` 代理
- **架构决策**: 复杂问题咨询 `oracle` 代理
- **浏览器测试**: 使用 Playwright 系列工具进行自动化测试
- **代码重构**: 使用 LSP 工具确保安全重命名和重构

---

## ⚠️ 已知问题与解决方案

### Google 模型兼容性问题

目前已知 `google/` 前缀的模型（如 `google/gemini-pro`）在某些环境下可能出现空响应、"thinking not supported" 错误或 `ProviderModelNotFoundError`。

**解决方案**：
在 `oh-my-opencode.json` 配置文件中，将模型前缀从 `google/` 更改为 `quotio/`。

**问题现象**：
- 代理返回空响应
- 报错 "thinking not supported"
- 报错 "ProviderModelNotFoundError"

参考 GitHub Issues: #479, #471, #480

## 📂 配置文件位置

| 配置文件 | 路径 | 用途 |
|---------|------|------|
| **OpenCode 主配置** | `~/.config/opencode/opencode.json` | 配置 Provider API Key、MCP 服务器、插件设置 |
| **OhMyOpenCode 配置** | `~/.config/opencode/oh-my-opencode.json` | 配置代理模型映射、禁用特定功能、自定义 Agent 行为 |

## 🔧 oh-my-opencode.json 配置详解

通过修改 `~/.config/opencode/oh-my-opencode.json` 文件，你可以自定义 OpenCode 的行为。

**配置示例**：

```json
{
  "$schema": "https://raw.githubusercontent.com/skns2635/oh-my-opencode/main/schema.json",
  "google_auth": {
    "client_email": "...",
    "private_key": "..."
  },
  "disabled_mcps": [
    "gdrive"
  ],
  "agents": {
    "document-writer": {
      "model": "quotio/gemini-3-pro-preview"
    },
    "frontend-ui-ux-engineer": {
      "model": "quotio/gemini-3-pro-preview"
    }
  }
}
```

| 字段 | 说明 |
|------|------|
| `google_auth` | Google 服务认证信息（如使用 Google Drive MCP） |
| `disabled_mcps` | 禁用的 MCP 服务器列表（如不需要 Google Drive 可禁用以减少启动错误） |
| `agents` | 自定义特定代理使用的模型 |
| `agents.<name>.model` | 指定该代理使用的模型 ID |

## 🎯 代理默认模型

建议将默认的 Google 模型替换为 Quotio 提供的兼容模型，以获得更稳定的体验。

| 代理 | 默认模型 | 建议替换为 |
|------|----------|------------|
| `document-writer` | `google/gemini-3-flash-preview` | `quotio/gemini-3-pro-preview` |
| `frontend-ui-ux-engineer` | `google/gemini-3-pro-preview` | `quotio/gemini-3-pro-preview` |
| `multimodal-looker` | `google/gemini-3-flash` | `quotio/gemini-3-flash-preview` |
| `oracle` | (默认) | `openai/gpt-5.2` 或 `quotio/gemini-claude-opus-4-5-thinking` |

## 💡 使用技巧

### 代理选择指南

| 场景 | 推荐代理 |
|------|----------|
| 代码库探索、查找文件 | `@explore` |
| 查找第三方库文档、最佳实践 | `@librarian` |
| 前端界面开发、CSS/Tailwind 调整 | `@frontend-ui-ux-engineer` |
| 复杂架构设计、代码审查 | `@oracle` |
| 编写 README、API 文档 | `@document-writer` |

### 并行任务

OpenCode 支持同时运行多个代理。例如，你可以让 `@explore` 搜索代码，同时让 `@librarian` 查找文档。

### 检查代理状态

如果代理响应缓慢，可以检查后台任务状态：
1. 使用 `background_output` 查看输出
2. 确保没有被防火墙或网络问题阻塞

### 模型前缀说明

| 前缀 | 说明 |
|------|------|
| `google/` | 直接调用 Google Vertex AI / Gemini API |
| `anthropic/` | 调用 Anthropic Claude API |
| `openai/` | 调用 OpenAI GPT API |
| `quotio/` | **推荐**：通过 Quotio 中转服务调用模型（兼容性更好） |

## 🐛 故障排除

### 代理返回空响应

1. 检查 `oh-my-opencode.json` 中的模型配置
2. 尝试将 `google/` 前缀改为 `quotio/`
3. 检查 API Key 是否有效或额度是否耗尽

### ProviderModelNotFoundError

原因：请求的模型 ID 不存在或当前 Provider 不支持。
解决方法：
- 确认模型名称拼写正确
- 切换到 `quotio/` 前缀，通常支持更多模型变体

### 代理很慢或超时

- 复杂任务（如 Oracle 深度思考）可能需要较长时间，请耐心等待
- 检查网络连接，特别是连接到 API 端点的延迟
- 尝试使用更轻量级的模型（如 `flash` 系列）进行简单任务

---

## 🪄 魔法关键词

在提示词中包含这些关键词，可以激活特殊模式：

| 关键词 | 功能 |
|--------|------|
| `ultrawork` / `ulw` | **最大性能模式**：并行代理协作、后台任务、持续执行直到完成 |
| `ultrathink` | **深度思考模式**：自动切换到扩展推理模型，适合复杂架构决策 |
| `search` / `find` / `찾아` / `検索` | **最大化搜索**：并行启动 explore + librarian 代理全面搜索 |
| `analyze` / `investigate` / `分析` / `調査` | **深度分析模式**：多阶段专家咨询，适合调试和架构分析 |

### 使用示例

```
ultrawork 重构整个认证系统
ultrathink 设计一个可扩展的微服务架构
search 找到所有使用 deprecated API 的地方
analyze 为什么这个测试会随机失败
```

**提示**：关键词可以放在提示词的任意位置，系统会自动识别并激活对应模式。

---

## 🔄 Ralph Loop（自循环开发）

Ralph Loop 是一个自动循环执行任务的功能，让代理持续工作直到任务完成。

### 使用方法

```
/ralph-loop "Build a REST API with authentication"
```

### 工作原理

1. 代理开始执行任务
2. 如果代理中途停止，Ralph Loop 自动继续
3. 检测到 `<promise>DONE</promise>` 时自动结束
4. 达到最大迭代次数（默认 100）时结束

### 取消循环

```
/cancel-ralph
```

### 配置

在 `oh-my-opencode.json` 中配置：

```json
{
  "ralph_loop": {
    "enabled": true,
    "default_max_iterations": 100
  }
}
```

---

## 📁 AGENTS.md 自动注入

在目录中创建 `AGENTS.md` 文件，当读取该目录下的文件时，会自动将 AGENTS.md 的内容注入到上下文中。

### 目录结构示例

```
project/
├── AGENTS.md              # 项目级上下文（最先注入）
├── src/
│   ├── AGENTS.md          # src 特定上下文
│   └── components/
│       ├── AGENTS.md      # 组件特定上下文（最后注入）
│       └── Button.tsx     # 读取此文件时，注入所有 3 个 AGENTS.md
```

### 注入顺序

从项目根目录到文件所在目录，依次注入所有 AGENTS.md 文件。

### 使用场景

- 项目编码规范和约定
- 目录特定的上下文说明
- 技术栈和依赖说明
- 特殊注意事项

---

## 🪝 Hooks 系统

Hooks 允许在特定事件发生时运行自定义脚本。

### 配置位置

- `~/.claude/settings.json`（用户级）
- `.claude/settings.json`（项目级）
- `.claude/settings.local.json`（本地，git 忽略）

### 支持的 Hook 事件

| 事件 | 触发时机 | 用途 |
|------|----------|------|
| `PreToolUse` | 工具执行前 | 阻止或修改工具输入 |
| `PostToolUse` | 工具执行后 | 添加警告或上下文 |
| `UserPromptSubmit` | 用户提交提示时 | 阻止或注入消息 |
| `Stop` | 会话空闲时 | 注入后续提示 |

### 配置示例

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "eslint --fix $FILE" }
        ]
      }
    ]
  }
}
```

---

## 📊 会话管理

OpenCode 提供会话管理工具，支持跨会话引用和搜索。

| 工具 | 功能 |
|------|------|
| `session_list` | 列出所有会话，支持日期过滤和数量限制 |
| `session_read` | 读取特定会话的消息历史 |
| `session_search` | 全文搜索所有会话内容 |
| `session_info` | 获取会话元数据和统计信息 |

### 使用场景

- 引用之前对话中的解决方案
- 查找历史讨论过的技术决策
- 保持跨会话的上下文连续性

---

## 🛡️ 自动保护功能

oh-my-opencode 内置多种自动保护机制：

| 功能 | 说明 |
|------|------|
| **Todo Continuation Enforcer** | 强制代理完成所有 TODO，防止半途而废 |
| **Comment Checker** | 防止 AI 添加过多注释，保持代码整洁 |
| **Context Window Monitor** | 上下文使用 70%+ 时提醒，防止仓促完成 |
| **Preemptive Compaction** | 上下文使用 85% 时主动压缩会话 |
| **Session Recovery** | 自动从错误中恢复（缺失工具结果、思考块问题等） |
| **Empty Task Response Detector** | 检测空任务响应，警告潜在的代理失败 |
| **Anthropic Auto Compact** | Claude 模型超限时自动压缩会话 |
| **Thinking Block Validator** | 验证思考块格式，防止 API 错误 |

### 禁用特定保护功能

在 `oh-my-opencode.json` 中配置：

```json
{
  "disabled_hooks": ["preemptive-compaction", "comment-checker"]
}
```

---

## 🔔 通知系统

### 后台任务完成通知

当后台代理任务完成时，系统会发送通知。

### 会话空闲通知

当代理需要输入时，发送操作系统通知，防止错过交互。

**支持平台**：macOS、Linux、Windows

---

## 🎨 Skill 技能系统

Skill 是更高级的命令形式，可以包含 MCP 服务器配置。

### 技能文件位置

| 位置 | 说明 |
|------|------|
| `~/.claude/skills/*/SKILL.md` | 用户级技能 |
| `.claude/skills/*/SKILL.md` | 项目级技能 |
| `~/.config/opencode/skill/*/SKILL.md` | OpenCode 全局技能 |
| `.opencode/skill/*/SKILL.md` | OpenCode 项目级技能 |

### 技能格式示例

```markdown
---
name: "my-skill"
description: "技能描述"
model: "anthropic/claude-opus-4-5"
allowed-tools: "bash read write"
mcp:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest"]
---

技能指令内容...
```

### 内置技能

- **playwright**：浏览器自动化、网页抓取、测试、截图

### 禁用内置技能

```json
{
  "disabled_skills": ["playwright"]
}
```

---

## 🔗 Claude Code 兼容性

oh-my-opencode 完全兼容 Claude Code 的配置和命令格式。

### 兼容的功能

| 功能 | 说明 |
|------|------|
| Commands | `~/.claude/commands/` 和 `.claude/commands/` |
| Skills | `~/.claude/skills/` 和 `.claude/skills/` |
| Agents | `~/.claude/agents/` 和 `.claude/agents/` |
| MCP | `.mcp.json` 配置文件 |
| Hooks | `settings.json` 钩子配置 |
| Todos | `~/.claude/todos/` 任务存储 |
| Transcripts | `~/.claude/transcripts/` 会话日志 |

### 禁用兼容性功能

```json
{
  "claude_code": {
    "mcp": false,
    "commands": false,
    "skills": false,
    "agents": false,
    "hooks": false
  }
}
```
