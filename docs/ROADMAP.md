# 🗺️ OCD 功能路线图与改进讨论

本文档记录 OCD (OpenCode Docker) 项目的潜在改进方向和功能想法，供讨论和规划使用。

---

## 📊 当前状态 (v1.4.0+)

### 已实现功能
- ✅ 多实例支持，自动端口分配
- ✅ UI 设置持久化 (KV store)
- ✅ 二进制缓存 (ast-grep, ripgrep)
- ✅ IPC 桥接 (URL、通知、剪贴板)
- ✅ Claude Code 兼容层
- ✅ oh-my-opencode 多 Agent 协作
- ✅ MCP 服务器 (Playwright, Exa, Context7)
- ✅ 完整文档 (TOOLS.md, OPENCODE_CONFIG_GUIDE.md)

### v2.0 重构完成 ✨
- ✅ **模块化架构**：873 行单文件拆分为 6 个独立模块
  - `lib/core.sh` - 版本/日志/环境变量
  - `lib/port.sh` - 端口管理（原子锁）
  - `lib/workspace.sh` - 工作区检测
  - `lib/watcher.sh` - IPC 文件监控
  - `lib/config.sh` - 配置生成
  - `lib/docker.sh` - Docker 操作
- ✅ **CI/CD 流水线**：GitHub Actions (ShellCheck + Bats + Docker)
- ✅ **单元测试**：27 个测试覆盖核心模块
- ✅ **新入口点**：`bin/ocd`（旧版 `opencode.sh` 兼容保留）

---

## 💡 改进想法

### 1. 🎯 自定义 Skills

| Skill | 用途 | 价值 | 复杂度 |
|-------|------|------|--------|
| **code-review** | 自动代码审查，检查安全、性能、最佳实践 | 提高代码质量 | 中 |
| **test-runner** | 智能运行相关测试，失败时自动分析原因 | 节省调试时间 | 中 |
| **db-migration** | 数据库迁移助手，生成迁移文件+回滚方案 | 减少数据库操作风险 | 高 |
| **api-designer** | REST/GraphQL API 设计，自动生成文档 | 标准化 API | 中 |
| **refactor-safe** | 安全重构，自动检查影响范围+测试 | 降低重构风险 | 高 |
| **i18n-helper** | 国际化助手，提取文案、生成翻译 | 多语言支持 | 中 |
| **perf-analyzer** | 性能分析，识别瓶颈并给出优化建议 | 提升应用性能 | 高 |

#### 讨论点
- [ ] 哪些 skill 最常用？优先实现哪些？
- [ ] 是否需要项目特定的 skill？
- [ ] skill 之间如何协作？

---

### 2. 🪝 Hooks 自动化

| Hook | 触发时机 | 效果 | 复杂度 |
|------|----------|------|--------|
| **Auto ESLint/Prettier** | Write/Edit .ts/.tsx 后 | 自动格式化代码 | 低 |
| **Auto Test** | 修改测试文件后 | 自动运行相关测试 | 中 |
| **Commit Lint** | git commit 前 | 检查 commit message 格式 | 低 |
| **Type Check** | 保存 TypeScript 后 | 实时类型检查提示 | 低 |
| **Security Scan** | 修改敏感文件后 | 自动安全扫描 | 中 |
| **Import Organizer** | 保存后 | 自动整理 import 语句 | 低 |
| **Dead Code Detector** | 保存后 | 检测未使用的代码 | 中 |

#### 配置示例

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

#### 讨论点
- [ ] 哪些 hooks 对日常开发最有帮助？
- [ ] hooks 执行失败时如何处理？
- [ ] 性能影响如何？需要异步执行吗？

---

### 3. 🤖 自定义 Agents

| Agent | 角色定位 | 适用场景 | 推荐模型 |
|-------|----------|----------|----------|
| **@security-auditor** | 安全审计专家 | 代码安全审查、漏洞检测、OWASP 最佳实践 | gpt-5.2 / claude-opus |
| **@perf-optimizer** | 性能优化专家 | 性能分析、内存泄漏检测、优化建议 | claude-opus |
| **@test-writer** | 测试专家 | 自动生成单元测试、E2E 测试、边界用例 | claude-sonnet |
| **@api-reviewer** | API 专家 | API 设计审查、兼容性检查、文档生成 | claude-sonnet |
| **@devops-helper** | DevOps 助手 | CI/CD 配置、Docker 优化、部署脚本 | claude-sonnet |
| **@data-analyst** | 数据分析师 | 数据处理、SQL 优化、可视化建议 | gemini-pro |

#### Agent 配置示例

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

#### 讨论点
- [ ] 哪些专业 agent 最需要？
- [ ] agent 之间如何分工协作？
- [ ] 模型选择：成本 vs 质量如何平衡？

---

### 4. 📜 自定义 Commands

| 命令 | 功能 | 参数 | 复杂度 |
|------|------|------|--------|
| `/quick-fix` | 快速修复常见问题（lint、import 排序等） | `[file]` | 低 |
| `/gen-test` | 为指定文件生成测试 | `<file>` | 中 |
| `/changelog` | 根据 git log 自动生成 CHANGELOG | `[from] [to]` | 低 |
| `/deps-update` | 智能更新依赖，检查破坏性变更 | `[package]` | 中 |
| `/health-check` | 项目健康检查（依赖、配置、安全） | 无 | 中 |
| `/doc-gen` | 为函数/类生成 JSDoc/TSDoc | `<file>` | 低 |
| `/complexity` | 分析代码复杂度，标记需要重构的地方 | `[dir]` | 中 |
| `/unused` | 查找未使用的依赖、导出、变量 | 无 | 中 |

#### Command 配置示例

```markdown
---
description: "为指定文件生成测试"
args:
  file:
    type: string
    description: 要生成测试的文件路径
---

为 $ARGUMENTS 生成完整的单元测试：
1. 分析文件中的函数和类
2. 为每个导出生成测试用例
3. 包含正常情况和边界情况
4. 使用项目现有的测试框架
5. 放在对应的 __tests__ 目录或 .test.ts 文件
```

#### 讨论点
- [ ] 哪些命令最常用？
- [ ] 命令参数如何设计更直观？
- [ ] 命令执行结果如何展示？

---

### 5. 🔧 MCP 服务器扩展

| MCP | 功能 | 使用场景 | 复杂度 |
|-----|------|----------|--------|
| **Notion MCP** | 读写 Notion 页面和数据库 | 同步文档、项目管理 | 中 |
| **Linear MCP** | 创建/更新 Linear issues | 任务追踪、Bug 管理 | 中 |
| **Slack MCP** | 发送消息到 Slack | 通知团队、自动化报告 | 低 |
| **Database MCP** | 直接查询/操作数据库 | 数据分析、调试 | 高 |
| **Figma MCP** | 读取 Figma 设计稿 | 设计还原、样式提取 | 中 |
| **Sentry MCP** | 查询错误日志 | 问题排查、错误分析 | 中 |

#### 讨论点
- [ ] 团队使用哪些工具？需要集成哪些？
- [ ] MCP 认证信息如何安全管理？
- [ ] 是否需要自建 MCP 服务器？

---

### 6. ⚡ 性能优化

| 优化项 | 效果 | 实现方式 | 优先级 |
|--------|------|----------|--------|
| **预热二进制** | 首次使用更快 | 启动时后台下载 | 中 |
| **会话智能压缩** | 减少 token 消耗 | 自动摘要历史 | 高 |
| **响应流式缓存** | 中断后可恢复 | 本地缓存流 | 低 |
| **并行 Agent** | 加速复杂任务 | 优化调度逻辑 | 中 |
| **增量文件索引** | 加速代码搜索 | 本地索引缓存 | 中 |

#### 讨论点
- [ ] 当前最大的性能瓶颈是什么？
- [ ] token 消耗如何优化？
- [ ] 哪些操作可以并行化？

---

### 7. 🎨 用户体验改进

| 改进项 | 描述 | 价值 |
|--------|------|------|
| **更好的错误提示** | 错误时给出具体修复建议 | 减少排查时间 |
| **命令自动补全** | Tab 补全 agent、command 名称 | 提高效率 |
| **历史命令搜索** | 搜索之前执行过的命令 | 快速复用 |
| **任务进度条** | 长任务显示进度 | 体验更好 |
| **快捷键自定义** | 用户可自定义快捷键 | 个性化 |
| **主题扩展** | 更多颜色主题选择 | 视觉舒适 |

---

## 🎯 优先级建议

### P0 - 立即实施
- [ ] Auto ESLint/Prettier Hook
- [ ] `/gen-test` 命令
- [ ] `@security-auditor` Agent

### P1 - 短期计划
- [ ] `code-review` Skill
- [ ] `/health-check` 命令
- [ ] 会话智能压缩

### P2 - 中期计划
- [ ] `@test-writer` Agent
- [ ] Database MCP
- [ ] 更多自定义 Commands

### P3 - 长期探索
- [ ] Notion/Linear MCP 集成
- [ ] 增量文件索引
- [ ] 自建 MCP 服务器

---

## 📝 讨论记录

### 2026-01-07
- 创建路线图文档
- 整理初步想法清单
- 待讨论：优先级排序

---

## 🔗 相关资源

- [oh-my-opencode 文档](https://github.com/code-yeongyu/oh-my-opencode)
- [OpenCode 官方文档](https://opencode.ai/docs/)
- [Claude Code 兼容性指南](./OPENCODE_CONFIG_GUIDE.md)
- [OCD 用户使用指南](./TOOLS.md)

---

> 💬 欢迎在此文档中添加评论和想法！
