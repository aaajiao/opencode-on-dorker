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
| `@build` | 构建代理 | 构建专用代理（需用户手动调用） |
| `@plan` | 规划代理 | 任务规划代理（需用户手动调用） |
| `@Planner-Sisyphus` | 规划代理 | OhMyOpenCode 版本的规划代理 |
| `@github` | Git 工作流 | GitHub 分支/提交/PR/同步/清理助手 |

### 使用示例

```
@oracle 帮我分析这个架构设计的优缺点
@explore 找到所有使用 useState 的组件
@librarian 查一下 Next.js 14 的 Server Actions 用法
@frontend-ui-ux-engineer 优化这个登录页面的 UI
@document-writer 为这个项目写一份 README
@github commit              # 智能提交
@github branch feature-x    # 创建功能分支
@github pr                  # 创建 Pull Request
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

### 🐙 @github 工作流

`@github` 是专门处理 Git/GitHub 工作流的智能代理。

| 命令 | 功能 |
|------|------|
| `@github branch <name>` | 创建并切换到新功能分支 |
| `@github commit` | 分析变更并生成智能提交消息 |
| `@github sync` | 从 main/master 同步最新代码 |
| `@github pr` | 创建 Pull Request |
| `@github done` | 完成后清理分支（合并后删除本地分支） |

**工作流示例**：

```bash
# 1. 开始新功能
@github branch add-user-avatar

# 2. 编码完成后提交
@github commit

# 3. 同步主分支（可选）
@github sync

# 4. 创建 PR
@github pr

# 5. PR 合并后清理
@github done
```

---

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

# OpenCode 项目级配置指南

基于 opencode-on-docker 和 oh-my-opencode 的实际测试结果。

---

### 何时使用哪套系统？

| 场景 | 推荐系统 | 原因 |
|------|---------|------|
| 纯 OpenCode 环境 | OpenCode 原生 | 无需插件依赖 |
| 使用 oh-my-opencode | 两者皆可 | 插件同时加载两套 |
| 从 Claude Code 迁移 | Claude 兼容层 | 配置文件兼容 |
| 需要条件规则 (globs) | Claude 兼容层 | OpenCode 原生不支持 |

---

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

## 🎛️ TUI 界面设置

### 1. 显示设置开关 (通过 `ctrl+p` 命令面板访问)

| 设置 | 描述 | 快捷键 | 持久化 |
|------|------|--------|--------|
| Toggle Code Concealment | 切换代码块折叠/展开显示 | `ctrl+x h` | ✅ |
| Hide/Show Thinking | 切换 AI 思考过程的显示 | 命令面板 | ✅ |
| Toggle Diff Wrapping | 切换 diff 视图的换行模式（word/none） | 命令面板 | ✅ |
| Hide/Show Timestamps | 切换消息时间戳显示 | 命令面板 | ✅ |
| Hide/Show Username | 切换用户名显示 | 可配置 | ✅ |
| Hide/Show Tool Details | 切换工具执行详情显示 | 可配置 | ✅ |
| Hide/Show Sidebar | 切换侧边栏显示 | `ctrl+x b` | ✅ |
| Toggle Scrollbar | 切换滚动条显示 | 可配置 | ✅ |
| Enable/Disable Animations | 切换 UI 动画效果 | 命令面板 | ✅ |

### 2. Variant Cycle（变体循环）

使用 `ctrl+t` 可以在不同的模型变体（思考层级）之间切换：

**Anthropic 模型**:
- `high` - 高思考预算（默认）
- `max` - 最大思考预算

**OpenAI 模型**:
- `none` → `minimal` → `low` → `medium` → `high` → `xhigh`

**Google 模型**:
- `low` ↔ `high`

### 3. 自然语言触发思考模式

除了魔法关键词外，你也可以在提示词中使用以下词汇触发：

| 关键词 | 效果 |
|--------|------|
| `think` | 启用基础思考 |
| `think hard` | 启用较深思考（High） |
| `think harder` | 启用更深思考 |
| `ultrathink` / `megathink` | 启用最大思考（Max） |

### 4. 完整快捷键参考

**Leader Key**: `ctrl+x`

**核心操作**:
| 操作 | 快捷键 |
|------|--------|
| 退出 | `ctrl+c`, `ctrl+d`, `<leader>q` |
| 命令面板 | `ctrl+p` |
| 帮助 | `<leader>h` |
| 新会话 | `<leader>n` |
| 会话列表 | `<leader>l` |
| 导出会话 | `<leader>x` |
| 压缩会话 | `<leader>c` |
| 打开编辑器 | `<leader>e` |
| 查看状态 | `<leader>s` |
| 主题列表 | `<leader>t` |
| 模型列表 | `<leader>m` |

**消息导航**:
| 操作 | 快捷键 |
|------|--------|
| 上翻页 | `PageUp` |
| 下翻页 | `PageDown` |
| 半页上 | `ctrl+alt+u` |
| 半页下 | `ctrl+alt+d` |
| 第一条 | `ctrl+g`, `Home` |
| 最后一条 | `ctrl+alt+g`, `End` |
| 复制消息 | `<leader>y` |
| 撤销消息 | `<leader>u` |
| 重做消息 | `<leader>r` |

**模型和代理**:
| 操作 | 快捷键 |
|------|--------|
| 切换最近模型 | `F2` / `Shift+F2` |
| 切换变体 | `ctrl+t` |
| 代理列表 | `<leader>a` |
| 切换代理 | `Tab` / `Shift+Tab` |

**会话导航**:
| 操作 | 快捷键 |
|------|--------|
| 下一个子会话 | `<leader>→` |
| 上一个子会话 | `<leader>←` |
| 父会话 | `<leader>↑` |
| 会话时间线 | `<leader>g` |

**输入框（Emacs 风格）**:
| 操作 | 快捷键 |
|------|--------|
| 提交 | `Enter` |
| 换行 | `Shift+Enter`, `ctrl+Enter`, `alt+Enter`, `ctrl+j` |
| 行首 | `ctrl+a` |
| 行尾 | `ctrl+e` |
| 删除到行尾 | `ctrl+k` |
| 删除到行首 | `ctrl+u` |
| 删除前一词 | `ctrl+w` |
| 清空输入 | `ctrl+c` |
| 粘贴 | `ctrl+v` |
| 中断响应 | `Escape` |

### 6. 访问 UI 设置的方式

1. **命令面板** (`ctrl+p`) - 搜索任何设置名称
2. **快捷键** - 使用配置的快捷键
3. **斜杠命令** - `/details`, `/theme`, `/status`

> ⚠️ **注意**：所有 UI 设置现在都会持久化保存（存储在 KV store 中），重启后会保留。

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

### 取消循环

```
/cancel-ralph
```

### 使用场景

- 项目编码规范和约定
- 目录特定的上下文说明
- 技术栈和依赖说明
- 特殊注意事项

---


---

## 📊 会话管理

OpenCode 提供会话管理工具，支持跨会话引用和搜索。

| 工具 | 功能 | 搜索范围 |
|------|------|----------|
| `session_list` | 列出会话，支持日期过滤和数量限制 | ⚡ 当前项目（可通过 `project_path` 指定） |
| `session_read` | 读取特定会话的消息历史 | 指定会话 |
| `session_search` | 全文搜索会话内容 | ✅ **所有项目**（跨项目搜索） |
| `session_info` | 获取会话元数据和统计信息 | 指定会话 |

### 使用示例

**跨项目搜索（默认）：**
```
帮我搜索之前所有项目中关于 "认证" 的讨论
搜索历史会话中提到 "useEffect" 的地方
```

**只搜当前项目：**
```
# 1. 先列出当前项目的会话
session_list → 获取 session_id

# 2. 再在特定会话中搜索
session_search(query="xxx", session_id="ses_xxx")
```

### 使用场景

- 引用之前对话中的解决方案
- 查找历史讨论过的技术决策
- 保持跨会话的上下文连续性
- 跨项目知识复用

---

## 🛡️ 自动保护功能

oh-my-opencode 内置多种自动保护机制：

### 安装 fswatch（推荐）

```bash
brew install fswatch
```

---

### 使用场景

#### 场景 1：创建自定义 Skill（专业技能包）

**需求**：你经常需要做数据库迁移，想创建一个专门的 Skill 来辅助。

**步骤**：

1. 创建目录和文件：
```bash
mkdir -p ~/opencode/global/claude/skills/db-migration
```

2. 创建 `SKILL.md`：
```markdown
---
name: "db-migration"
description: "数据库迁移助手"
model: "anthropic/claude-sonnet-4-5"
allowed-tools: "bash read write edit"
---

你是数据库迁移专家。帮助用户：
1. 生成迁移文件
2. 检查迁移安全性
3. 执行迁移并验证

始终：
- 先备份数据库
- 使用事务包装
- 提供回滚方案
```

3. 在对话中使用：
```
/db-migration 帮我创建一个添加 user.avatar 字段的迁移
```

---

#### 场景 2：创建自定义命令（快捷操作）

**需求**：你想快速生成 React 组件模板。

**步骤**：

1. 创建命令文件：
```bash
mkdir -p ~/opencode/global/claude/commands
```

2. 创建 `react-component.md`：
```markdown
---
description: "生成 React 组件"
args:
  name:
    type: string
    description: 组件名称
---

创建一个 React 函数组件，要求：
- 名称：$ARGUMENTS
- 使用 TypeScript
- 包含 Props 类型定义
- 使用 Tailwind CSS
- 放在 src/components/ 目录下
```

3. 使用：
```
/project:react-component UserProfile
```

---

#### 场景 3：创建自定义 Agent（专家角色）

**需求**：你想要一个专门审查安全问题的代理。

**步骤**：

1. 创建 agent 文件：
```bash
mkdir -p ~/opencode/global/claude/agents
```

2. 创建 `security-auditor.md`：
```markdown
---
name: "security-auditor"
description: "安全审计专家"
model: "openai/gpt-5.2"
---

你是安全审计专家，专注于：
- SQL 注入检测
- XSS 漏洞识别
- 认证/授权缺陷
- 敏感数据泄露
- 依赖漏洞

审查代码时：
1. 逐文件扫描安全风险
2. 按严重程度分类（Critical/High/Medium/Low）
3. 提供修复建议和代码示例
4. 引用 OWASP 最佳实践
```

3. 使用：
```
@security-auditor 审查 src/auth/ 目录的安全性
```

---

#### 场景 4：配置 Hooks（自动化工作流）

**需求**：每次编辑 TypeScript 文件后自动运行 ESLint。

**步骤**：

1. 编辑 `~/opencode/global/claude/settings.json`：
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "if [[ \"$FILE\" == *.ts || \"$FILE\" == *.tsx ]]; then npx eslint --fix \"$FILE\" 2>/dev/null || true; fi"
          }
        ]
      }
    ]
  }
}
```

**效果**：每次 AI 编辑 `.ts` 或 `.tsx` 文件后，自动运行 ESLint 修复。

---

#### 场景 5：添加额外 MCP 服务器

**需求**：添加一个自定义 MCP 服务器来访问内部 API。

**步骤**：

1. 编辑 `~/opencode/global/claude/.mcp.json`：
```json
{
  "mcpServers": {
    "internal-api": {
      "command": "npx",
      "args": ["-y", "@mycompany/internal-mcp-server"],
      "env": {
        "API_TOKEN": "${INTERNAL_API_TOKEN}"
      }
    }
  }
}
```

2. 确保环境变量在 `.env` 中配置：
```bash
INTERNAL_API_TOKEN=your-token
```

---

#### 场景 6：配置条件规则（按上下文应用）

**需求**：处理测试文件时自动应用测试最佳实践。

**步骤**：

1. 创建规则文件：
```bash
mkdir -p ~/opencode/global/claude/rules
```

2. 创建 `test-files.md`：
```markdown
---
globs: ["**/*.test.ts", "**/*.spec.ts", "**/__tests__/**"]
---

处理测试文件时，遵循：
1. 使用 AAA 模式（Arrange-Act-Assert）
2. 每个测试只验证一个行为
3. 使用清晰的测试描述
4. Mock 外部依赖
5. 避免测试实现细节
```

**效果**：当 AI 读取或编辑匹配 glob 的文件时，自动注入这些规则。

---

### 复用 Claude Code 社区资源

由于完全兼容 Claude Code 格式，你可以直接复用社区资源：

1. **从 GitHub 复制 Skills**：
```bash
# 示例：复制某个开源 Skill
git clone https://github.com/someone/claude-skills.git /tmp/skills
cp -r /tmp/skills/some-skill ~/opencode/global/claude/skills/
```

2. **分享你的配置**：
```bash
# 将你的自定义配置打包分享
cd ~/opencode/global/claude
zip -r my-claude-config.zip skills/ commands/ agents/
```

---

### Agent 示例

**文件**: `.opencode/agent/my-assistant.md` (OpenCode 原生)

```markdown
---
name: my-assistant
description: 项目专属智能助手
model: anthropic/claude-sonnet-4-5
tools:
  read: true
  bash: true
  webfetch: true
  grep: true
---

你是本项目的专属助手。

## 职责
- 理解项目架构
- 回答技术问题
- 协助代码编写

## 项目背景
[项目特定的上下文信息]
```

**文件**: `.claude/agents/my-assistant.md` (Claude 兼容层)

```markdown
---
name: my-assistant
description: 项目专属智能助手
tools: read, bash, webfetch, grep
---

你是本项目的专属助手。
...
```

---

### 示例

**文件**: `.opencode/skill/notebooklm/SKILL.md`

```markdown
---
name: notebooklm
description: 查询 NotebookLM notebooks，获取基于文档的 AI 回答
---

# NotebookLM Skill

## 何时使用

- 用户提到 NotebookLM
- 用户分享 NotebookLM URL
- 用户要求查询文档/笔记本

## 核心命令

```bash
cd .opencode/skill/notebooklm
python scripts/run.py ask_question.py --question "问题" --notebook-url "URL"
```
```

---

### 示例

**文件**: `.opencode/command/deploy.md`

```markdown
---
name: deploy
description: 部署项目到生产环境
---

请帮我部署项目。

部署参数: $ARGUMENTS

## 部署步骤
1. 运行测试
2. 构建项目
3. 推送到生产环境
```

---

### 示例

**文件**: `.claude/rules/typescript.md`

```markdown
---
globs: ["*.ts", "*.tsx"]
---

# TypeScript 代码规范

- 使用 `strict` 模式
- 优先使用 `interface` 而非 `type`
- 禁止使用 `any`，使用 `unknown` 替代
- 所有函数必须有显式返回类型
```

**文件**: `.claude/rules/testing.md`

```markdown
---
globs: ["*.test.ts", "*.spec.ts", "**/__tests__/**"]
---

# 测试规范

- 使用 describe/it 结构
- 每个测试只验证一个行为
- Mock 外部依赖
```

---

### 使用场景

- 团队共享一致的开发环境
- 锁定已知稳定的版本组合
- 避免自动更新导致的兼容性问题

---

