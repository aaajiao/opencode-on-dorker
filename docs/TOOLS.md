# OCD 用户指南

本文档面向日常使用 OCD (OpenCode Docker) 的**用户**。

---

## 1. 快速开始

### 启动 OCD

```bash
# 在项目目录下启动
cd ~/projects/myapp
ocd

# 重建镜像（首次使用或更新后）
ocd -r

# 查看帮助
ocd -h
```

### 基本操作

| 操作 | 快捷键 |
|------|--------|
| 打开命令面板 | `Ctrl+P` |
| 退出 | `Ctrl+C` / `Ctrl+D` |
| 中断当前响应 | `Escape` |
| 换行（不发送） | `Shift+Enter` |

---

## 2. 内置工具

### 文件操作

| 工具 | 功能 | 示例 |
|------|------|------|
| `read` | 读取文件 | "读取 src/index.ts" |
| `write` | 写入文件 | "创建 config.json" |
| `edit` | 编辑文件 | "把函数名改为 handleClick" |
| `glob` | 按模式查找文件 | "找到所有 .tsx 文件" |
| `grep` | 搜索文件内容 | "搜索包含 useState 的文件" |
| `ast_grep_search` | AST 语法搜索 | "找到所有 async 函数" |

### 终端操作

| 工具 | 功能 | 示例 |
|------|------|------|
| `bash` | 执行命令 | "运行 npm install" |
| `interactive_bash` | 交互式/后台任务 | "启动开发服务器" |

### 网络操作

| 工具 | 功能 | 示例 |
|------|------|------|
| `webfetch` | 获取网页内容 | "抓取这个网页的内容" |
| `playwright_*` | 浏览器自动化 | "截图这个页面" |

### 代码智能

| 工具 | 功能 | 示例 |
|------|------|------|
| `lsp_hover` | 获取类型信息 | "这个变量是什么类型" |
| `lsp_goto_definition` | 跳转定义 | "找到这个函数的定义" |
| `lsp_find_references` | 查找引用 | "哪里用到了这个函数" |
| `lsp_rename` | 重命名符号 | "重命名 foo 为 bar" |

---

## 3. @ 提及功能

使用 `@` 召唤专业代理处理任务：

| 代理 | 用途 | 示例 |
|------|------|------|
| `@explore` | 代码库搜索 | "@explore 找到认证相关的代码" |
| `@librarian` | 文档查询 | "@librarian 查一下 Next.js 14 的用法" |
| `@oracle` | 深度分析 | "@oracle 分析这个架构设计" |
| `@frontend-ui-ux-engineer` | UI/UX 开发 | "@frontend 优化这个页面的样式" |
| `@document-writer` | 文档写作 | "@document-writer 写一份 README" |
| `@multimodal-looker` | 媒体分析 | "@multimodal 分析这张截图" |
| `@github` | Git 工作流 | "@github commit" |

### @github 工作流

```
@github branch feature-x   # 创建分支
@github commit             # 智能提交
@github sync               # 同步主分支
@github pr                 # 创建 PR
@github done               # 清理分支
```

---

## 4. / 斜杠命令

| 命令 | 功能 |
|------|------|
| `/playwright` | 加载浏览器自动化技能 |
| `/dev <path>` | 启动开发服务器 |
| `/dev-list` | 列出运行中的服务器 |
| `/dev-stop` | 停止开发服务器 |

### 使用示例

```
/playwright 打开 https://example.com 并截图
/dev /workspace/myapp
/dev-stop all
```

---

## 5. 魔法关键词

在提示词中包含这些关键词激活特殊模式：

| 关键词 | 效果 |
|--------|------|
| `ultrawork` / `ulw` | 最大性能模式（并行代理、后台任务） |
| `ultrathink` | 深度思考模式（扩展推理） |
| `search` / `find` | 最大化搜索（explore + librarian 并行） |
| `analyze` / `investigate` | 深度分析模式 |
| `think hard` | 启用较深思考 |
| `megathink` | 启用最大思考 |

### 示例

```
ultrawork 重构整个认证系统
ultrathink 设计可扩展的微服务架构
search 找到所有使用 deprecated API 的地方
```

---

## 6. 快捷键参考

**Leader Key**: `Ctrl+X`

### 核心操作

| 操作 | 快捷键 |
|------|--------|
| 命令面板 | `Ctrl+P` |
| 退出 | `Ctrl+C` / `Ctrl+D` / `<leader>q` |
| 帮助 | `<leader>h` |
| 新会话 | `<leader>n` |
| 会话列表 | `<leader>l` |
| 压缩会话 | `<leader>c` |
| 打开编辑器 | `<leader>e` |

### 消息导航

| 操作 | 快捷键 |
|------|--------|
| 上翻页 | `PageUp` |
| 下翻页 | `PageDown` |
| 半页上 | `Ctrl+Alt+U` |
| 半页下 | `Ctrl+Alt+D` |
| 第一条 | `Ctrl+G` / `Home` |
| 最后一条 | `Ctrl+Alt+G` / `End` |
| 复制消息 | `<leader>y` |

### 模型和代理

| 操作 | 快捷键 |
|------|--------|
| 切换最近模型 | `F2` / `Shift+F2` |
| 切换变体（思考深度） | `Ctrl+T` |
| 代理列表 | `<leader>a` |
| 切换代理 | `Tab` / `Shift+Tab` |

### 输入框（Emacs 风格）

| 操作 | 快捷键 |
|------|--------|
| 提交 | `Enter` |
| 换行 | `Shift+Enter` / `Ctrl+J` |
| 行首 | `Ctrl+A` |
| 行尾 | `Ctrl+E` |
| 删除到行尾 | `Ctrl+K` |
| 清空输入 | `Ctrl+C` |
| 粘贴 | `Ctrl+V` |

### 显示设置

| 设置 | 快捷键 |
|------|--------|
| 切换代码折叠 | `Ctrl+X H` |
| 切换侧边栏 | `Ctrl+X B` |
| 其他设置 | 通过 `Ctrl+P` 命令面板 |

---

## 7. TUI 界面

### 思考变体（Ctrl+T 循环）

**Anthropic 模型**：`high` → `max`

**OpenAI 模型**：`none` → `minimal` → `low` → `medium` → `high` → `xhigh`

**Google 模型**：`low` ↔ `high`

### 设置持久化

所有 UI 设置会自动保存，重启后保留：
- 代码折叠状态
- 思考过程显示
- 时间戳显示
- 侧边栏状态

---

## 8. 会话管理

| 工具 | 功能 |
|------|------|
| `session_list` | 列出会话 |
| `session_read` | 读取会话历史 |
| `session_search` | 跨项目搜索（全局） |
| `session_info` | 获取会话元数据 |

### 跨项目搜索

```
搜索之前所有项目中关于 "认证" 的讨论
搜索历史会话中提到 "useEffect" 的地方
```

---

## 9. macOS 集成

### 桌面通知

```bash
notify "标题" "内容"
```

oh-my-opencode 会在任务完成时自动发送通知。

### 剪贴板同步

容器内的 `/share` 命令会自动同步到 Mac 剪贴板。

### 浏览器打开

链接会自动在 Mac 浏览器打开。

---

## 10. 常见问题

### 代理返回空响应

1. 检查 `oh-my-opencode.json` 中的模型配置
2. 将 `google/` 前缀改为 `quotio/`
3. 检查 API Key 是否有效

### 代理响应很慢

- 复杂任务（如 Oracle 深度思考）需要较长时间
- 检查网络连接
- 尝试使用 `flash` 系列模型处理简单任务

### TUI 和 WebUI 对话不同步

从正确的目录启动 OCD。项目级对话存储在 `<project>/.claude/transcripts/`。

### 浏览器不打开

```bash
# 检查 fswatch 是否安装
brew install fswatch

# 检查 watcher 进程
ps aux | grep fswatch
```

### 端口冲突

```bash
rm ~/.config/opencode/.port.lock
```

### 重新显示依赖提示

```bash
rm ~/.config/opencode/.deps-hint-shown
ocd
```

---

## 11. 代理选择指南

| 场景 | 推荐代理 |
|------|----------|
| 代码库探索、查找文件 | `@explore` |
| 查找第三方库文档、最佳实践 | `@librarian` |
| 前端界面开发、CSS/Tailwind | `@frontend-ui-ux-engineer` |
| 复杂架构设计、代码审查 | `@oracle` |
| 编写 README、API 文档 | `@document-writer` |
| Git 工作流 | `@github` |

---

## 12. 外部知识库

| 工具 | 功能 |
|------|------|
| `context7_query-docs` | 查询任何编程库的最新文档 |
| `grep_app_searchGitHub` | 在 GitHub 公开仓库中搜索代码 |

### 示例

```
查一下 React 19 的 use hook 用法
在 GitHub 上找一个 OAuth2 实现的例子
```
