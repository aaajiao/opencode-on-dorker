# oh-my-opencode Agent 使用指南

oh-my-opencode v3.x 多 Agent 协作系统完整说明。

---

## 快速选择

**不知道用哪个？看这里：**

| 场景 | 推荐 Agent | 成本 | 命令示例 |
|------|-----------|------|----------|
| 复杂任务、不确定怎么做 | Sisyphus (默认) | 贵 | 直接输入任务 |
| 自主深度开发（给目标不给步骤） | Hephaestus | 贵 | `@hephaestus 实现用户权限系统` |
| 架构设计、技术决策 | Oracle | 贵 | `@oracle 评估是否迁移到 GraphQL` |
| 调试连续失败 2+ 次 | Oracle | 贵 | `@oracle 分析这个死锁的根因` |
| 查外部文档、找示例 | Librarian | 便宜 | `@librarian React 18 并发特性用法` |
| 快速搜索内部代码 | Explore | 免费 | `@explore 用户认证在哪` |
| 看图/PDF/设计稿 | Multimodal-Looker | 便宜 | `@multimodal-looker 分析这个设计稿` |
| 需要详细规划 | Prometheus | 贵 | `@prometheus 规划这个功能` |
| 大型重构/全栈开发 | `ultrawork` | 贵 | `ulw: 重构认证模块` |

---

## 所有 Agent 一览

oh-my-opencode 共有 **11 个 Agent**，分为四类：

| 类别 | Agent | 默认模型 | 成本 | 核心职责 |
|------|-------|---------|------|----------|
| **编排器** | Sisyphus | Claude Opus 4.6 | 贵 | 主入口，任务分解与委派 |
| | Atlas | Claude Sonnet 4.6 | 贵 | Todo 列表编排，多任务协调 |
| | Sisyphus-Junior | Claude Sonnet 4.6 | 便宜 | 专注执行，不委派 |
| **深度工作** | Hephaestus | GPT-5.3 Codex | 贵 | 自主深度开发，目标导向 |
| **顾问** | Oracle | GPT-5.3 Codex | 贵 | 架构设计、调试诊断 |
| | Prometheus | Claude Opus 4.6 | 贵 | 战略规划（访谈模式） |
| | Metis | Claude Opus 4.6 | 贵 | 预规划分析，发现歧义 |
| | Momus | GPT-5.2 | 贵 | 计划审查，挑刺找问题 |
| **探索** | Librarian | Claude Haiku 4.5 | 便宜 | 外部文档、GitHub 示例 |
| | Explore | Claude Haiku 4.5 | 便宜 | 内部代码搜索 |
| **工具** | Multimodal-Looker | Gemini 3 Flash | 便宜 | 图片/PDF 分析 |

---

## Agent 详解

### Sisyphus - 主编排器

**默认 Agent**，所有任务的入口。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-opus-4-6` |
| 温度 | 0.1 |
| 思考预算 | 32,000 tokens |
| 成本 | 贵 |

**设计理念**：
- 身份：SF Bay Area 工程师，代码应与高级工程师无异
- 核心原则：**永远不单独工作**，有专家就委派
- 默认偏向：**委派优先**，只在超简单时才自己做

**职责**：
1. 解析请求意图（隐性需求）
2. 判断代码库成熟度（规范 vs 混乱）
3. 委派专业工作给合适的 Agent
4. 并行执行最大化吞吐

**委派策略**：

| 情况 | 委派给 | 原因 |
|------|--------|------|
| "这个库怎么用？" | Librarian | 外部库专家 |
| "认证在哪实现？" | Explore | 代码导航 |
| "架构合理吗？" | Oracle | 战略推理 |
| "规划这个功能" | Prometheus | 规划专家 |
| "审查这个计划" | Momus | 质量把关 |
| "分析这个 PDF" | Multimodal-Looker | 媒体处理 |
| 执行具体任务 | Sisyphus-Junior | 专注执行 |

**使用方式**：直接输入任务，无需 `@` 调用。

---

### Hephaestus - 自主深度工作者

**v3.2.0 新增**。给目标，不给步骤，自主完成端到端开发。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/gpt-5.3-codex` |
| 温度 | 0.1 |
| 成本 | 贵 |
| 灵感来源 | [AmpCode deep mode](https://ampcode.com) |

**命名来源**：希腊神话中的锻造之神，为众神打造武器的神匠。

**关键特性**：
- **目标导向**：给他目标，不是菜谱。他自己决定步骤。
- **先探索后行动**：写代码前先并发启动 2-5 个 explore/librarian agent。
- **端到端完成**：任务不做完不停手，包含验证证据。
- **模式匹配**：搜索现有代码库，匹配项目风格——不写 AI 味代码。
- **精准手艺**：像铁匠一样精确、最小化、刚刚好。

**与 Sisyphus 的区别**：

| 特性 | Sisyphus | Hephaestus |
|------|----------|------------|
| 工作模式 | 分解任务并委派 | 自己干到底 |
| 适合场景 | 需要多 Agent 协作 | 单一复杂目标 |
| 探索深度 | 按需探索 | 强制深度探索 |
| 完成标准 | 可中途交接 | 必须端到端验证 |

**何时使用**：
- 明确的功能目标，但实现路径不确定
- 需要深度研究后才能动手的任务
- 希望 AI 完全自主、不想微观管理

**何时不用**：
- 需要多 Agent 并行协作（用 Sisyphus）
- 简单明确的修改（用 Sisyphus-Junior）
- 只需咨询不需实现（用 Oracle）

**使用示例**：
```bash
@hephaestus 实现一个带 JWT 认证的用户系统
@hephaestus 给项目添加完整的 CI/CD 流水线
@hephaestus 重构支付模块，保持 API 兼容
```

---

### Oracle - 架构顾问

**只读咨询**，提供高质量推理，不直接修改代码。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/gpt-5.3-codex` |
| 温度 | 0.1 |
| 推理强度 | medium |
| 成本 | 贵 |
| 工具限制 | **只读**（禁止 write, edit, task, delegate_task） |

**决策框架**（务实极简主义）：
- 偏向简单：最简方案满足需求即可
- 利用现有：优先修改现有代码，而非新建组件
- 开发体验：可读性 > 理论性能
- 一条路：给出单一主要推荐
- 投入标签：Quick(<1h) / Short(1-4h) / Medium(1-2d) / Large(3d+)

**响应结构**：
```
**结论**：2-3 句核心建议
**行动计划**：编号步骤
**投入预估**：Quick/Short/Medium/Large

（如需要）
**原因**：关键权衡
**注意**：风险和边缘情况
```

**何时使用**：
- 架构设计和技术选型
- 调试连续失败 2+ 次的问题
- 完成重要实现后自我审查
- 性能优化策略
- 多系统权衡

**何时不用**：
- 简单文件操作（用直接工具）
- 第一次尝试修复（先自己试）
- 能从已读代码推断的问题
- 琐碎决定（变量名、格式）

**使用示例**：
```bash
@oracle 评估 REST vs GraphQL 的取舍
@oracle 分析这个死锁问题的根因
@oracle 评审当前 PR 的架构合理性
```

---

### Librarian - 外部研究员

**外部资源专家**，擅长查找文档和开源示例。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-haiku-4-5` |
| 温度 | 0.1 |
| 成本 | 便宜 |
| 工具 | Context7、GitHub CLI、Web 搜索 |
| 工具限制 | **只读**（禁止 write, edit, task, delegate_task, call_omo_agent） |

**核心能力**：
- 查找官方文档和 API 参考
- 搜索 GitHub 上的实现示例
- 研究最佳实践和设计模式
- 解释库的内部工作原理

**触发短语**（遇到这些就用 Librarian）：
- "这个库怎么用？"
- "[框架特性] 的最佳实践是什么？"
- "为什么 [外部依赖] 这样表现？"
- "找 [库] 使用示例"
- 遇到不熟悉的 npm/pip/cargo 包

**何时不用**：
- 内部代码库问题（用 Explore）
- 已知文件位置

**使用示例**：
```bash
@librarian 查找 Playwright MCP 的配置方法
@librarian 找 React Query 缓存失效的示例
@librarian Prisma 事务处理的最佳实践
```

---

### Explore - 代码导航员

**内部搜索专家**，快速定位代码。**便宜**，可大量使用。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-haiku-4-5` |
| 温度 | 0.1 |
| 成本 | 便宜 |
| 工具限制 | **只读**（禁止 write, edit, task, delegate_task, call_omo_agent） |

**核心能力**：
- 回答 "X 在哪里实现？"
- 回答 "哪些文件包含 Y？"
- 回答 "找到做 Z 的代码"
- 提供绝对路径的可操作结果

**关键要求**：
1. 并行启动 3+ 工具搜索
2. 所有路径必须是绝对路径
3. 找到所有相关匹配，不只是第一个
4. 结果结构化，调用者无需追问

**工具策略**：

| 搜索类型 | 使用工具 |
|----------|----------|
| 语义搜索（定义、引用） | LSP 工具 |
| 结构模式（函数形状、类结构） | ast_grep_search |
| 文本模式（字符串、注释、日志） | grep |
| 文件模式（按名称/扩展名查找） | glob |
| 历史/演变（何时添加、谁改的） | git 命令 |

**何时使用**：
- 需要多角度搜索
- 不熟悉模块结构
- 跨层模式发现

**何时不用**：
- 你确切知道要搜什么
- 单个关键词/模式就够
- 已知文件位置

**使用示例**：
```bash
@explore 找到用户登录的实现
@explore 分析 UserService 的依赖关系
@explore 这个项目的目录结构是怎样的
```

---

### Multimodal-Looker - 视觉分析

**图像和文档分析**专家。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/gemini-3-flash` |
| 温度 | 0.1 |
| 成本 | 便宜 |
| 工具限制 | **只有 read**（只能读取文件） |

**核心能力**：
- **PDF**：提取文本、结构、表格、特定章节数据
- **图片**：描述布局、UI 元素、文本、图表
- **图表**：解释关系、流程、架构

**何时使用**：
- 分析 UI 设计稿
- 从 PDF 提取信息
- 理解架构图
- 截图分析

**何时不用**：
- 需要精确内容的源码或纯文本（用 Read）
- 之后需要编辑的文件（需要 Read 的字面内容）
- 简单文件读取，无需解释

**使用示例**：
```bash
@multimodal-looker 分析这个设计稿的布局
@multimodal-looker 从 API 文档 PDF 提取端点列表
```

---

### 规划三人组

用于复杂任务的规划和审查。一般由 Sisyphus 自动调用，也可手动使用。

#### Prometheus - 战略规划师

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-opus-4-6` |
| 温度 | 0.1 |
| 成本 | 贵 |
| 工具限制 | 只能写 Markdown（禁止写代码文件） |

**关键约束**：
- **是规划者，不是实现者，不写代码**
- 当用户说 "做 X"、"实现 X"、"修复 X" 时，解释为 "为 X 制定工作计划"

**工作模式**：

1. **访谈/咨询模式**（默认）
   - 访谈用户理解需求
   - 使用 Librarian/Explore 收集上下文
   - 基于上下文提出建议和问题
   - 需求明确后自动转入计划生成

2. **计划生成模式**
   - 触发：用户说 "做成工作计划！" 或 "保存为文件"
   - 生成前：咨询 Metis 发现遗漏问题
   - 可选：通过 Momus 进行高精度验证
   - 输出：`.sisyphus/plans/*.md`

**使用示例**：
```bash
@prometheus 规划用户权限系统的实现
```

#### Metis - 预规划顾问

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-opus-4-6` |
| 温度 | 0.3（略高，用于创意分析） |
| 成本 | 贵 |
| 工具限制 | **只读**（只能分析） |

**命名来源**：希腊智慧女神，以审慎和深谋著称。

**核心职责**：
- 识别隐藏意图和未说明的需求
- 检测可能导致实现失败的歧义
- 标记潜在的 AI 过度设计模式
- 为用户生成澄清问题
- 为 Prometheus 准备指令

**意图分类**（必须首先执行）：

| 意图 | 信号 | 主要关注 |
|------|------|----------|
| **重构** | "重构"、"重组"、"清理" | 安全：防止回归 |
| **从零构建** | "创建新"、"添加功能"、绿地项目 | 发现：先探索模式 |
| **中等任务** | 有范围的功能、具体交付物 | 边界：精确定义交付物 |
| **协作式** | "帮我规划"、"一起想想" | 交互：增量澄清 |
| **架构** | "应该怎么组织"、系统设计 | 战略：长期影响 |
| **研究** | 需要调查、目标存在但路径不清 | 调查：退出标准 |

#### Momus - 计划审查员

| 属性 | 值 |
|------|------|
| 模型 | `opencode/gpt-5.2` |
| 温度 | 0.1 |
| 成本 | 贵 |
| 工具限制 | **只读**（只能审查） |

**命名来源**：希腊讽刺和批评之神，以在一切（甚至神的作品）中找茬著称。

**核心原则**：
- **绝对约束：尊重实现方向**
- 是审查者，不是设计者
- 计划中的实现方向**不可协商**
- 职责：评估计划是否足够清晰可执行
- **不是**评估方向本身是否正确

**审查标准**：
- **拒绝**：当按照既定方法模拟实际工作时，无法获取实现所需的明确信息
- **接受**：能直接从计划或通过计划提供的引用获取必要信息

**常见作者遗漏**：
1. 参考材料：未指向现有代码、文档或模式
2. 业务需求：未解释功能应该做什么或为什么
3. 架构决策：未指定状态管理、集成方式、API 端点
4. 关键上下文：引用的文件不存在或未记录

---

### Atlas - 高级编排器

管理 Todo 列表，协调多 Agent 并行执行。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-sonnet-4-6` |
| 温度 | 0.1 |
| 成本 | 贵 |
| 工具限制 | 无（完全访问） |

**职责**：
- 持有和管理 Todo 列表状态
- 协调多 Agent 并行执行
- 验证任务完成后再进入下一个
- 处理基于类别的委派和技能加载

**委派选项**：
- **选项 A**：使用 CATEGORY（生成 `Sisyphus-Junior-{category}` 带优化设置）
- **选项 B**：直接使用 AGENT（用于 Oracle、Librarian 等专家）

---

### Sisyphus-Junior - 任务执行器

轻量版 Sisyphus，专注执行，不委派。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-sonnet-4-6` |
| 温度 | 0.1 |
| 最大 tokens | 64,000 |
| 思考预算 | 32,000 tokens |
| 成本 | 便宜 |
| 工具限制 | 禁止 task, delegate_task |

**关键约束**：
- **禁止**委派实现任务
- **允许**调用 explore/librarian 做研究

**Todo 纪律（不可协商）**：
- 2+ 步骤 → 先 `todowrite`，原子分解
- 开始前标记 `in_progress`（一次只能一个）
- 完成后**立即**标记 `completed`（不要批量）
- **多步骤工作没有 todo = 未完成工作**

**通过 `delegate_task(category=...)` 调用**：

| 类别 | 用途 |
|------|------|
| `quick` | 快速简单任务 |
| `visual-engineering` | 前端/UI/UX |
| `ultrabrain` | 复杂分析 |
| `writing` | 文档写作 |
| `unspecified-low` | 不属于其他类别，低工作量 |
| `unspecified-high` | 不属于其他类别，高工作量 |

---

## 工具限制矩阵

| Agent | 禁止的工具 | 允许的工具 | 说明 |
|-------|-----------|-----------|------|
| **Sisyphus** | 无 | 全部 | 主编排器，完全访问 |
| **Hephaestus** | 无 | 全部 | 自主深度工作，完全访问 |
| **Atlas** | 无 | 全部 | 编排器，完全访问 |
| **Prometheus** | write(代码), edit, task, delegate_task | read, markdown 操作, 研究工具 | 只规划，不实现 |
| **Metis** | 除 read 外全部 | 只有 read | 只分析 |
| **Momus** | 除 read 外全部 | 只有 read | 只审查 |
| **Oracle** | write, edit, task, delegate_task | read, 分析工具 | 只顾问，不实现 |
| **Librarian** | write, edit, task, delegate_task, call_omo_agent | read, GitHub CLI, Context7, web 搜索 | 研究专家 |
| **Explore** | write, edit, task, delegate_task, call_omo_agent | read, grep, glob, LSP, ast_grep, git | 导航专家 |
| **Multimodal-Looker** | 除 read 外全部 | 只有 read | 只分析媒体 |
| **Sisyphus-Junior** | task, delegate_task | 其他全部（包括 call_omo_agent） | 执行器，不委派 |

---

## 内置 MCPs

oh-my-opencode 内置 3 个远程 MCP 服务，自动启用：

| MCP | 用途 | 认证 |
|-----|------|------|
| **websearch** (Exa AI) | 实时网页搜索，获取最新信息 | `EXA_API_KEY` |
| **context7** | 查询库/框架的官方文档和代码示例 | `CONTEXT7_API_KEY` |
| **grep_app** | 在 GitHub 上搜索真实代码模式 | 无需认证 |

### 禁用 MCP

如需禁用特定 MCP，在 `oh-my-opencode.json` 中配置：

```json
{
  "disabled_mcps": ["websearch", "grep_app"]
}
```

---

## 内置 Skills

oh-my-opencode 提供 4 个内置 Skill，无需额外配置即可使用。

### Skills 一览

| Skill | 用途 | 加载命令 |
|-------|------|----------|
| **playwright** | 浏览器自动化（截图、表单、爬虫） | `/playwright` |
| **frontend-ui-ux** | UI/UX 设计视角开发，无设计稿也能做出精美界面 | `/frontend-ui-ux` |
| **git-master** | Git 操作专家（atomic commit、rebase、history 搜索） | `/git-master` |
| **dev-browser** | 持久化页面状态的浏览器自动化，可连接已有 Chrome | `/dev-browser` |

### Skill 详解

#### playwright

**浏览器自动化**，基于 Playwright MCP。

- 截图、表单填写、点击交互
- 无头浏览器模式
- 适合自动化测试和网页爬取

```bash
# 加载后可用的工具
browser_navigate, browser_click, browser_fill_form,
browser_screenshot, browser_snapshot, browser_evaluate...
```

#### frontend-ui-ux

**设计师视角的前端开发**，即使没有设计稿也能创建精美 UI。

核心理念：
- 承诺大胆的美学方向（极简、复古、奢华等）
- 避免通用字体（Inter、Roboto、Arial）
- 色彩要有张力，布局要打破常规
- 动效要精心编排，不是随处点缀

适用场景：
- 从零开始的 UI 开发
- 需要视觉冲击力的项目
- 设计师资源不足时

#### git-master

**Git 操作专家**，三合一：

| 模式 | 触发词 | 能力 |
|------|--------|------|
| **COMMIT** | "commit"、"提交" | 原子提交、风格检测、多提交拆分 |
| **REBASE** | "rebase"、"squash" | 交互式 rebase、冲突解决、历史清理 |
| **HISTORY** | "谁写的"、"什么时候加的" | git blame、bisect、pickaxe 搜索 |

**核心规则**：
- 3+ 文件 → 必须 2+ commits
- 自动检测项目 commit 风格（semantic/plain/short）
- 测试文件必须和实现同一个 commit

**配置选项**：

```json
{
  "git-master": {
    "commit_footer": "Signed-off-by: Your Name <email@example.com>",
    "include_co_authored_by": true
  }
}
```

| 选项 | 类型 | 说明 |
|------|------|------|
| `commit_footer` | string | 附加到每个 commit message 末尾的文本 |
| `include_co_authored_by` | boolean | 是否添加 Co-authored-by trailer |

#### dev-browser

**持久化浏览器自动化**，可连接用户已有的 Chrome。

与 playwright 的区别：
- 可复用已登录状态
- 页面状态跨脚本执行保持
- 支持 Extension 模式连接已有浏览器

适用场景：
- 需要登录态的自动化操作
- 多步骤交互工作流
- 调试网页应用

### 禁用 Skill

如需禁用特定 skill，在 `oh-my-opencode.json` 中配置：

```json
{
  "disabled_skills": ["playwright", "frontend-ui-ux"]
}
```

---

## Categories 配置

Categories 定义任务委派时使用的模型配置。当 Sisyphus 通过 `task(category=...)` 委派任务时，自动使用对应 category 的模型。

### 默认 Categories

| Category | 默认模型 | 说明 |
|----------|---------|------|
| `visual-engineering` | Gemini 3 Pro | 前端、UI/UX、设计、样式、动画 |
| `ultrabrain` | GPT-5.2 Codex (xhigh) | 仅用于真正困难的逻辑密集型任务 |
| `deep` | GPT-5.2 Codex (high) | 目标导向的自主问题解决，深度研究后行动 |
| `artistry` | Gemini 3 Pro (max) | 创造性问题解决，突破常规模式 |
| `quick` | Claude Haiku 4.5 | 简单任务：单文件修改、typo 修复 |
| `unspecified-low` | Claude Sonnet 4.6 | 不属于其他类别的低工作量任务 |
| `unspecified-high` | Claude Opus 4.6 (max) | 不属于其他类别的高工作量任务 |
| `writing` | Gemini 3 Flash | 文档、技术写作 |

### 自定义 Category 配置

```json
{
  "categories": {
    "visual-engineering": {
      "model": "opencode/gemini-3-pro",
      "temperature": 0.3,
      "prompt_append": "Always use Tailwind CSS"
    },
    "quick": {
      "model": "opencode/claude-haiku-4-5",
      "maxTokens": 16000
    }
  }
}
```

### 可用选项

`model`、`variant`、`temperature`、`top_p`、`maxTokens`、`thinking`、`reasoningEffort`、`textVerbosity`、`tools`、`prompt_append`、`is_unstable_agent`

---

## Hooks

Hooks 在各种生命周期节点扩展功能。oh-my-opencode 内置 35+ 个 hook，大多数开箱即用无需配置。

### 内置 Hooks 一览

| Hook | 用途 |
|------|------|
| `agent-usage-reminder` | 提醒使用专业 agent 而非直接工具 |
| `anthropic-context-window-limit-recovery` | Anthropic 上下文窗口超限自动恢复 |
| `anthropic-effort` | Anthropic 模型推理强度控制 |
| `atlas` | Atlas 编排器生命周期管理 |
| `auto-slash-command` | 自动斜杠命令检测 |
| `auto-update-checker` | 插件自动更新检查 |
| `background-notification` | 后台任务完成通知 |
| `category-skill-reminder` | 提醒加载相关 skills |
| `claude-code-hooks` | Claude Code 兼容层 |
| `comment-checker` | 代码注释质量检查 |
| `compaction-context-injector` | 压缩时注入关键上下文 |
| `compaction-todo-preserver` | 压缩时保留 todo 状态 |
| `delegate-task-retry` | 委派任务失败自动重试 |
| `directory-agents-injector` | 目录级 agent 自动注入 |
| `directory-readme-injector` | 目录 README 自动注入 |
| `edit-error-recovery` | 编辑操作错误恢复 |
| `interactive-bash-session` | 交互式 bash 会话管理 |
| `keyword-detector` | 关键词检测和触发 |
| `non-interactive-env` | 非交互环境适配 |
| `prometheus-md-only` | Prometheus 仅 Markdown 输出 |
| `question-label-truncator` | 问题标签截断 |
| `ralph-loop` | Ralph Loop 自主循环 |
| `rules-injector` | 规则文件自动注入 |
| `session-recovery` | 会话恢复机制 |
| `sisyphus-junior-notepad` | Sisyphus-Junior 笔记本 |
| `start-work` | 工作启动流程 |
| `stop-continuation-guard` | 停止继续机制 |
| `subagent-question-blocker` | 阻止子 agent 向用户提问 |
| `task-reminder` | 任务提醒 |
| `task-resume-info` | 任务恢复信息 |
| `tasks-todowrite-disabler` | Tasks 模式下禁用 todowrite |
| `think-mode` | 深度思考模式 |
| `thinking-block-validator` | 思考块验证 |
| `unstable-agent-babysitter` | 不稳定 agent 监控 |
| `write-existing-file-guard` | 已有文件写入保护 |

大多数 hooks 自动运行，无需手动配置。

---

## Background Tasks 配置

控制后台任务（explore、librarian 等并行任务）的并发限制。

```json
{
  "background_tasks": {
    "defaultConcurrency": 5,
    "staleTimeoutMs": 300000,
    "providerConcurrency": 3,
    "modelConcurrency": 2
  }
}
```

| 选项 | 类型 | 说明 |
|------|------|------|
| `defaultConcurrency` | number | 默认最大并发任务数 |
| `staleTimeoutMs` | number | 过期任务超时时间（毫秒） |
| `providerConcurrency` | number | 每个 provider 的并发限制 |
| `modelConcurrency` | number | 每个模型的并发限制 |

**优先级**：`modelConcurrency` > `providerConcurrency` > `defaultConcurrency`

---

## Comment Checker 配置

验证代码中的注释质量。使用 `{{comments}}` 占位符在自定义提示中插入待检查的注释。

```json
{
  "comment-checker": {
    "custom_prompt": "检查以下注释是否准确、有用、符合项目风格：{{comments}}"
  }
}
```

---

## ultrawork 模式

`ultrawork`（缩写 `ulw`）自动启用所有高级功能。

### 自动启用

- 所有专家 Agent 协作
- 后台任务并行执行
- 完整 LSP 工具集成
- AST-Grep 代码搜索
- 智能上下文管理
- 自动任务分解和协调

### 何时使用

| 使用 ultrawork | 不需要 ultrawork |
|----------------|------------------|
| 大型重构 | 简单查询 |
| 全栈功能开发 | 小范围修改 |
| 复杂问题分析 | 单文件编辑 |
| 多步骤实现 | 问答类请求 |

### 使用示例

```bash
# 完整形式
ultrawork: 重构用户认证系统，添加 OAuth2 支持

# 简写
ulw: 给整个项目添加 TypeScript 类型

# 结合特定 Agent
ultrawork: @oracle 设计微服务架构
```

---

## 协作流程

### 主编排流程

```
用户请求
    ↓
[SISYPHUS] - 意图判断 (Phase 0)
    ├─ 简单/明确 → 直接工具
    ├─ 探索性 → 并行启动 explore (1-3) + 工具
    ├─ 开放式 → 先评估代码库
    ├─ 模糊 → 提出澄清问题
    └─ 复杂 → 委派给专家
        ├─ 架构 → [ORACLE]
        ├─ 规划 → [PROMETHEUS] → [METIS] → [MOMUS]
        ├─ 研究 → [LIBRARIAN] + [EXPLORE] (并行)
        ├─ 媒体 → [MULTIMODAL-LOOKER]
        └─ 执行 → [ATLAS] → [SISYPHUS-JUNIOR-{category}]
```

### 规划工作流

```
用户: "构建功能 X"
    ↓
[PROMETHEUS] - 访谈/咨询模式
    ├─ 提出澄清问题
    ├─ 启动 [LIBRARIAN] + [EXPLORE] 收集上下文
    └─ 需求明确后：
        ↓
    [METIS] - 预规划分析
        ├─ 识别隐藏意图
        ├─ 检测歧义
        └─ 准备指令
        ↓
    [PROMETHEUS] - 计划生成
        └─ 写入 .sisyphus/plans/{name}.md
        ↓
    [MOMUS] - 计划审查 (可选)
        ├─ 无情挑刺
        ├─ 捕获漏洞和歧义
        └─ 拒绝或接受
        ↓
    [ATLAS] - 执行编排
        └─ 委派给 [SISYPHUS-JUNIOR-{category}]
```

---

## 最佳实践

### 1. 成本优化

| 成本 | Agent | 使用策略 |
|------|-------|----------|
| **便宜** | Explore, Librarian, Multimodal-Looker, Sisyphus-Junior | 代码导航、外部研究、媒体分析、执行 |
| **便宜** | Librarian, Multimodal-Looker, Sisyphus-Junior | 外部研究、媒体分析、执行 |
| **贵** | Sisyphus, Atlas, Prometheus, Metis, Momus, Oracle | 只用于复杂推理、规划、编排 |

### 2. 避免常见错误

**错误：过度使用 ultrawork**
```bash
# 不好（浪费资源）
ulw: 查看 package.json 内容

# 好
查看 package.json
```

**错误：Librarian 用于内部代码**
```bash
# 不好（工具选错）
@librarian 找到认证实现

# 好
@explore 找到认证实现  # 内部代码用 Explore
```

**错误：简单问题用 Oracle**
```bash
# 不好（浪费贵的模型）
@oracle 这个变量是什么类型

# 好
@explore 找到这个变量的定义
```

**错误：让 Librarian 写代码**
```bash
# 不好（Librarian 只能研究）
@librarian 实现一个 React 组件

# 好
实现一个 React 组件  # 让 Sisyphus 处理
```

### 3. 并行执行

```bash
# Explore 和 Librarian 可以并行后台运行
# Sisyphus 会自动协调
ulw: 开发用户仪表板
# → 自动并行：前端 UI + 后端 API + 研究最佳实践
```

### 4. 任务描述清晰

```bash
# 模糊
改进代码

# 清晰
@explore 分析 UserService.ts 的性能瓶颈，然后优化数据库查询
```

---

## 配置参考

### 环境变量覆盖

在 `models.conf` 中配置（参见 `models.conf.example`）：

```bash
# 主模型 (opencode.json)
MAIN_MODEL=opencode/claude-opus-4-6

# Agent 模型 (oh-my-opencode.json)
SISYPHUS_MODEL=opencode/claude-opus-4-6
HEPHAESTUS_MODEL=opencode/gpt-5.3-codex
ORACLE_MODEL=opencode/gpt-5.3-codex
LIBRARIAN_MODEL=opencode/claude-haiku-4-5
EXPLORE_MODEL=opencode/claude-haiku-4-5
MULTIMODAL_MODEL=opencode/gemini-3-flash
PROMETHEUS_MODEL=opencode/claude-opus-4-6
METIS_MODEL=opencode/claude-opus-4-6
MOMUS_MODEL=opencode/gpt-5.2
ATLAS_MODEL=opencode/claude-sonnet-4-6
SISYPHUS_JUNIOR_MODEL=opencode/claude-sonnet-4-6
```

### oh-my-opencode.json 配置

```json
{
  "agents": {
    "sisyphus": { "model": "opencode/claude-opus-4-6" },
    "hephaestus": { "model": "opencode/gpt-5.3-codex" },
    "oracle": { "model": "opencode/gpt-5.3-codex" },
    "librarian": { "model": "opencode/claude-haiku-4-5" },
    "explore": { "model": "opencode/claude-haiku-4-5" },
    "multimodal-looker": { "model": "opencode/gemini-3-flash" },
    "prometheus": { "model": "opencode/claude-opus-4-6" },
    "metis": { "model": "opencode/claude-opus-4-6" },
    "momus": { "model": "opencode/gpt-5.2" },
    "atlas": { "model": "opencode/claude-sonnet-4-6" },
    "sisyphus-junior": { "model": "opencode/claude-sonnet-4-6" }
  },
  "browser_automation_engine": {
    "provider": "playwright"
  }
}
```

### 浏览器自动化引擎

oh-my-opencode 支持两种浏览器自动化引擎：

| Provider | 说明 | 安装 |
|----------|------|------|
| `playwright` | 默认，使用 Playwright MCP | 无需额外安装 |
| `agent-browser` | 替代方案，支持连接已有浏览器 | 需安装 `bun add -g agent-browser && agent-browser install` |

**切换方法**：编辑 `~/.config/opencode/oh-my-opencode.json`

```json
"browser_automation_engine": {
  "provider": "agent-browser"
}
```

**两者区别**：

| 特性 | playwright | agent-browser |
|------|------------|---------------|
| 启动方式 | 新建无头浏览器 | 可连接已有 Chrome |
| 登录态 | 每次重新登录 | 可复用已登录状态 |
| 适用场景 | 自动化测试、爬虫 | 需要登录态的操作 |
| 配套 Skill | `/playwright` | `/dev-browser` |

> 完整配置选项参见 `~/opencode/templates/global/oh-my-opencode.example.jsonc`

### 高级功能

#### Tmux 集成

可视化多 Agent 执行，每个 subagent 在独立 tmux pane 中运行，实时显示输出。

| 属性 | 说明 |
|------|------|
| 状态 | ✅ 稳定 |
| 默认 | 禁用 |
| 要求 | 必须在 tmux 会话内运行，且 OpenCode 使用 `--port` 模式 |

**配置**：

```json
{
  "tmux": {
    "enabled": true,
    "layout": "main-vertical",
    "main_pane_min_width": 120,
    "agent_pane_min_width": 40
  }
}
```

**布局选项**：`main-vertical`、`main-horizontal`、`tiled`、`even-horizontal`、`even-vertical`

**适用场景**：
- 需要可视化监控多个并行 Agent
- 调试复杂的 Agent 协作流程
- 想看 subagent 实时输出

---

#### Ralph Loop

自主开发循环，Agent 持续工作直到任务完成，自动检测完成状态。

| 属性 | 说明 |
|------|------|
| 状态 | ✅ 稳定 |
| 默认 | 禁用 (opt-in) |
| 完成信号 | Agent 输出 `<promise>DONE</promise>` |

**配置**：

```json
{
  "ralph_loop": {
    "enabled": true,
    "default_max_iterations": 100
  }
}
```

**使用**：

```bash
/ralph-loop "构建一个带认证的 REST API"
/ralph-loop "重构支付模块" --max-iterations=50
/cancel-ralph   # 取消当前循环
```

**退出条件**：
- Agent 发出完成信号
- 达到最大迭代次数
- 用户执行 `/cancel-ralph`

**适用场景**：
- 复杂多步骤任务
- 需要保证完成的工作
- 想要无人值守执行

---

#### Sisyphus Tasks

结构化任务管理，支持依赖关系、状态跟踪和持久化存储。

| 属性 | 说明 |
|------|------|
| 状态 | ✅ 稳定 |
| 默认 | 禁用 |
| 存储 | `.sisyphus/tasks/{listId}/{taskId}.json` |

**配置**：

```json
{
  "sisyphus": {
    "tasks": {
      "enabled": true,
      "storage_path": ".sisyphus/tasks",
      "claude_code_compat": false
    }
  }
}
```

**任务属性**：
- `id`、`subject`、`description`、`owner`
- `status`: pending | in_progress | completed
- `blocks[]`、`blockedBy[]`（依赖追踪）
- `metadata`（自定义数据）

**适用场景**：
- 需要结构化任务跟踪
- 管理任务依赖关系
- 跨会话持久化状态

---

#### Sisyphus Swarm

多 Agent 协调系统，基于 mailbox 协议的 Agent 间通信。

| 属性 | 说明 |
|------|------|
| 状态 | 🔧 Wave 1（基础架构） |
| 默认 | 禁用 |
| 存储 | `.sisyphus/teams/{teamName}/inboxes/{agentName}.json` |

**配置**：

```json
{
  "sisyphus": {
    "swarm": {
      "enabled": true,
      "storage_path": ".sisyphus/teams",
      "ui_mode": "both"
    }
  }
}
```

**消息类型**（14 种）：
- `permission_request/response`
- `task_assignment/completed`
- `join_request/approved`
- `plan_approval_request/response`
- 等...

**注意**：此功能仍在早期阶段，API 可能变化。

---

#### 实验性功能总览

| 选项 | 类型 | 说明 |
|------|------|------|
| `aggressive_truncation` | boolean | 积极截断输出 |
| `auto_resume` | boolean | 自动恢复中断的任务 |
| `preemptive_compaction` | boolean | 提前压缩上下文（在达到限制前） |
| `truncate_all_tool_outputs` | boolean | 截断所有工具输出 |
| `dynamic_context_pruning` | object | 动态上下文裁剪（详见下方） |

```json
{
  "experimental": {
    "aggressive_truncation": false,
    "auto_resume": false,
    "preemptive_compaction": false,
    "truncate_all_tool_outputs": false,
    "dynamic_context_pruning": {}
  }
}
```

---

#### 动态上下文裁剪（实验性）

自动移除冗余/过时的工具调用，防止长会话中 token 膨胀。

| 属性 | 说明 |
|------|------|
| 状态 | 🧪 实验性 |
| 默认 | 禁用 |
| 策略 | 去重、写入替代、错误清除 |

**配置**：

```json
{
  "experimental": {
    "dynamic_context_pruning": {
      "enabled": true,
      "notification": "detailed",
      "turn_protection": { "enabled": true, "turns": 3 },
      "protected_tools": ["task", "todowrite", "todoread", "lsp_rename"],
      "strategies": {
        "deduplication": { "enabled": true },
        "supersede_writes": { "enabled": true, "aggressive": false },
        "purge_errors": { "enabled": true, "turns": 5 }
      }
    }
  }
}
```

**策略说明**：
- **deduplication**: 移除重复的工具调用
- **supersede_writes**: 文件被重新读取后，裁剪之前的写入输入
- **purge_errors**: N 轮后移除报错的工具输入

**注意**：`turn_protection` 保护最近 N 轮的调用不被裁剪，禁用可能丢失当前工作上下文。

---

#### 禁用特定组件

按需禁用 MCP、Agent 或 Skill：

```json
{
  "disabled_mcps": ["websearch", "context7", "grep_app"],
  "disabled_agents": ["metis", "momus"],
  "disabled_skills": ["playwright", "frontend-ui-ux", "git-master"]
}
```

---

### Agent 权限控制

可以为每个 agent 设置工具权限：

```json
{
  "agents": {
    "sisyphus": {
      "model": "opencode/claude-opus-4-6",
      "permissions": {
        "edit": "allow",
        "bash": "allow",
        "webfetch": "allow",
        "doom_loop": "ask",
        "external_directory": "ask"
      }
    }
  }
}
```

| 权限 | 可选值 | 说明 |
|------|--------|------|
| `edit` | ask / allow / deny | 文件编辑能力 |
| `bash` | ask / allow / deny | Bash 命令执行 |
| `webfetch` | ask / allow / deny | 网络请求能力 |
| `doom_loop` | ask / allow / deny | 无限循环覆盖 |
| `external_directory` | ask / allow / deny | 项目外文件访问 |

### LSP 配置

自定义 LSP (Language Server Protocol) 服务器配置：

```json
{
  "lsp": {
    "typescript": {
      "command": "typescript-language-server --stdio",
      "extensions": [".ts", ".tsx"],
      "priority": 1,
      "env": {},
      "initialization": {},
      "disabled": false
    }
  }
}
```

| 选项 | 类型 | 说明 |
|------|------|------|
| `command` | string | LSP 服务器启动命令 |
| `extensions` | array | 匹配的文件扩展名 |
| `priority` | number | 服务器优先级 |
| `env` | object | 环境变量 |
| `initialization` | object | 初始化选项 |
| `disabled` | boolean | 是否禁用此 LSP |

### 可用模型

```bash
# OpenCode Zen (opencode/):
#
#   Anthropic:
opencode/claude-opus-4-6        # 最强，默认主模型
opencode/claude-opus-4-5        # 上代旗舰
opencode/claude-sonnet-4-6      # 快速，adaptive thinking
opencode/claude-sonnet-4-5      # 快速
opencode/claude-haiku-4-5       # 便宜
#
#   OpenAI:
opencode/gpt-5.3-codex          # 最新代码推理，25% 更快
opencode/gpt-5.2                # 推理
opencode/gpt-5.2-codex          # 代码推理
#
#   Google:
opencode/gemini-3.1-pro         # 多模态，medium reasoning
opencode/gemini-3-pro           # 多模态
opencode/gemini-3-flash         # 快速多模态
#
#   其他:
opencode/minimax-m2.5           # 快速
opencode/big-pickle             # 免费限时

# 原始 Provider:
anthropic/claude-opus-4-6
anthropic/claude-sonnet-4-6
openai/gpt-5.3-codex
openai/gpt-5.2
google/gemini-3.1-pro
google/gemini-3-pro
google/gemini-3-flash
```

### 配置文件位置

| 位置 | 用途 |
|------|------|
| `~/.config/opencode/oh-my-opencode.json` | 全局配置 |
| `.opencode/oh-my-opencode.json` | 项目配置 |
| `~/opencode/models.conf` | 模型覆盖（OCD 专用） |

---

## 相关文档

- [配置详解](./CONFIGURATION.md) - 目录结构、配置生命周期
- [CLI 参考](./CLI_REFERENCE.md) - 命令行完整参考
- [oh-my-opencode 官方文档](https://ohmyopencode.com/agents/)
- [社区最佳实践](https://www.opencode.live/ecosystem/oh-my-opencode/best-practices/)
