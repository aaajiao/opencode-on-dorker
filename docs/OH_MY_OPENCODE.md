# oh-my-opencode Agent 使用指南

oh-my-opencode v3.x 多 Agent 协作系统完整说明。

---

## 快速选择

**不知道用哪个？看这里：**

| 场景 | 推荐 Agent | 成本 | 命令示例 |
|------|-----------|------|----------|
| 复杂任务、不确定怎么做 | Sisyphus (默认) | 贵 | 直接输入任务 |
| 架构设计、技术决策 | Oracle | 贵 | `@oracle 评估是否迁移到 GraphQL` |
| 调试连续失败 2+ 次 | Oracle | 贵 | `@oracle 分析这个死锁的根因` |
| 查外部文档、找示例 | Librarian | 便宜 | `@librarian React 18 并发特性用法` |
| 快速搜索内部代码 | Explore | 免费 | `@explore 用户认证在哪` |
| 看图/PDF/设计稿 | Multimodal-Looker | 便宜 | `@multimodal-looker 分析这个设计稿` |
| 需要详细规划 | Prometheus | 贵 | `@prometheus 规划这个功能` |
| 大型重构/全栈开发 | `ultrawork` | 贵 | `ulw: 重构认证模块` |

---

## 所有 Agent 一览

oh-my-opencode 共有 **10 个 Agent**，分为四类：

| 类别 | Agent | 默认模型 | 成本 | 核心职责 |
|------|-------|---------|------|----------|
| **编排器** | Sisyphus | Claude Opus 4.5 | 贵 | 主入口，任务分解与委派 |
| | Atlas | Claude Opus 4.5 | 贵 | Todo 列表编排，多任务协调 |
| | Sisyphus-Junior | Claude Sonnet 4.5 | 便宜 | 专注执行，不委派 |
| **顾问** | Oracle | GPT-5.2 Codex | 贵 | 架构设计、调试诊断 |
| | Prometheus | Claude Opus 4.5 | 贵 | 战略规划（访谈模式） |
| | Metis | Claude Opus 4.5 | 贵 | 预规划分析，发现歧义 |
| | Momus | GPT-5.2 | 贵 | 计划审查，挑刺找问题 |
| **探索** | Librarian | Claude Haiku 4.5 | 便宜 | 外部文档、GitHub 示例 |
| | Explore | Grok Code | 免费 | 内部代码搜索 |
| **工具** | Multimodal-Looker | Gemini 3 Flash | 便宜 | 图片/PDF 分析 |

---

## Agent 详解

### Sisyphus - 主编排器

**默认 Agent**，所有任务的入口。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/claude-opus-4-5` |
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

### Oracle - 架构顾问

**只读咨询**，提供高质量推理，不直接修改代码。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/gpt-5.2-codex` |
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

**内部搜索专家**，快速定位代码。**免费**，可大量使用。

| 属性 | 值 |
|------|------|
| 模型 | `opencode/grok-code` |
| 温度 | 0.1 |
| 成本 | **免费** |
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
| 模型 | `opencode/claude-opus-4-5` |
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
| 模型 | `opencode/claude-opus-4-5` |
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
| 模型 | `opencode/claude-sonnet-4-5` |
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
| 模型 | `opencode/claude-sonnet-4-5` |
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
| **免费** | Explore | 大量使用，代码导航首选 |
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
MAIN_MODEL=opencode/claude-opus-4-5

# Agent 模型 (oh-my-opencode.json)
SISYPHUS_MODEL=opencode/claude-opus-4-5
ORACLE_MODEL=opencode/gpt-5.2-codex
LIBRARIAN_MODEL=opencode/claude-haiku-4-5
EXPLORE_MODEL=opencode/claude-haiku-4-5
MULTIMODAL_MODEL=opencode/gemini-3-flash
PROMETHEUS_MODEL=opencode/claude-opus-4-5
METIS_MODEL=opencode/claude-opus-4-5
MOMUS_MODEL=opencode/gpt-5.2
ATLAS_MODEL=opencode/claude-sonnet-4-5
SISYPHUS_JUNIOR_MODEL=opencode/claude-sonnet-4-5
```

### oh-my-opencode.json 配置

```json
{
  "agents": {
    "sisyphus": { "model": "opencode/claude-opus-4-5" },
    "oracle": { "model": "opencode/gpt-5.2-codex" },
    "librarian": { "model": "opencode/claude-haiku-4-5" },
    "explore": { "model": "opencode/grok-code" },
    "multimodal-looker": { "model": "opencode/gemini-3-flash" },
    "prometheus": { "model": "opencode/claude-opus-4-5" },
    "metis": { "model": "opencode/claude-opus-4-5" },
    "momus": { "model": "opencode/gpt-5.2" },
    "atlas": { "model": "opencode/claude-sonnet-4-5" },
    "sisyphus-junior": { "model": "opencode/claude-sonnet-4-5" }
  }
}
```

### 可用模型

```bash
# OpenCode 内置 (opencode/):
opencode/claude-opus-4-5        # 最强，默认主模型
opencode/claude-sonnet-4-5      # 快速
opencode/claude-haiku-4-5       # 便宜
opencode/gpt-5.2                # 推理
opencode/gpt-5.2-codex          # 代码推理
opencode/gemini-3-pro           # 多模态
opencode/gemini-3-flash         # 快速多模态
opencode/grok-code              # 免费

# 原始 Provider:
anthropic/claude-opus-4-5
anthropic/claude-sonnet-4-5
openai/gpt-5.2
google/gemini-3-pro-preview
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
