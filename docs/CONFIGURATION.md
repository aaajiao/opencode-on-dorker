# OCD 配置详解

OCD 配置架构和目录结构说明。

---

## 设计原则

| 原则 | 说明 |
|------|------|
| **用户拥有配置** | 首次创建后由用户管理，OCD 不覆盖 |
| **最小化干预** | 每次启动只更新端口，其他配置不动 |
| **模板驱动** | 从 `templates/` 生成，支持变量替换 |
| **复数目录名** | 使用 `skills/`、`agents/`、`commands/`、`plugins/` |

---

## 目录结构

### OCD 安装目录

```
~/opencode/
├── .env                    # API Keys（必需）
├── models.conf             # 模型配置（可选）
├── versions.lock           # 版本锁定
├── templates/
│   ├── global/             # 全局配置模板
│   │   ├── opencode.json.tmpl
│   │   ├── oh-my-opencode.json
│   │   └── opencode/
│   │       ├── agents/
│   │       ├── commands/
│   │       └── skills/
│   │           └── remind/SKILL.md
│   └── project/            # 项目模板 (ocd init)
│       ├── AGENTS.md.example
│       ├── .opencode/
│       └── .claude/
├── bin/
│   ├── ocd                 # 主程序
│   └── devocd              # 开发模式
└── lib/*.sh                # 核心模块
```

### 运行时目录 (Mac)

```
~/.config/opencode/         # 全局配置（用户所有）
├── opencode.json           # OpenCode 主配置
├── oh-my-opencode.json     # 插件配置
├── skills/                 # 全局技能
├── commands/               # 全局命令
└── agents/                 # 全局 Agent

~/.local/share/opencode/    # 数据目录（需备份）
├── storage/                # 会话数据
└── auth.json               # OAuth 令牌

~/.local/state/opencode/    # 状态目录
├── ipc/<port>/             # IPC 文件
└── claude/                 # Claude 运行时

~/.cache/opencode/          # 缓存（可删除）
```

### 项目目录

```
<project>/
├── AGENTS.md               # AI Agent 指南
├── .opencode/
│   ├── oh-my-opencode.json
│   ├── agents/
│   ├── commands/
│   ├── skills/
│   └── plugins/
└── .claude/
    ├── settings.json
    ├── agents/
    ├── commands/
    ├── skills/
    └── rules/
```

---

## 模板文件命名规则

| 后缀 | 处理方式 |
|------|----------|
| `.tmpl` | OCD 处理，`{{VAR}}` 从 versions.lock 替换 |
| `.example` | 用户参考，手动复制使用 |
| 无后缀 | 直接复制，不做处理 |

---

## 配置生命周期

| 事件 | OCD 行为 |
|------|----------|
| 首次运行 | 从模板创建配置，显示欢迎信息 |
| 每次启动 | 只更新端口号 |
| `--clean` | 备份现有配置，重新从模板创建 |
| `models.conf` 存在 | 应用模型覆盖设置 |

---

## 模型配置

通过 `models.conf` 自定义默认模型：

```bash
cp models.conf.example ~/opencode/models.conf
```

```bash
# ~/opencode/models.conf

# 主模型 (opencode.json)
MAIN_MODEL=opencode/claude-opus-4-6

# Agent 模型 (oh-my-opencode.json)
SISYPHUS_MODEL=opencode/claude-opus-4-6
ORACLE_MODEL=opencode/gpt-5.4
EXPLORE_MODEL=opencode/claude-haiku-4-5
```

> 修改后需运行 `ocd --clean` 重新生成配置。

---

## 目录清理对照表

| 目录 | 内容 | `-r` | `--clean` | 手动 |
|------|------|:----:|:---------:|:----:|
| `~/.cache/opencode/` | 缓存 | ✅ | - | ✅ |
| `~/.config/opencode/` | 全局配置 | - | ✅ (备份) | ✅ |
| `~/.local/state/opencode/ipc/` | IPC 状态 | - | ✅ | ✅ |
| `~/.local/share/opencode/storage/` | 对话历史 | - | - | ✅ |
| `~/.local/share/opencode/auth.json` | 认证令牌 | - | - | ✅ |

✅ = 会删除/备份，- = 不删除

---

## 环境变量 (.env)

**格式要求**：纯 `KEY=VALUE`，无引号无注释无 export

```bash
# 正确
OPENAI_API_KEY=sk-proj-xxxx
GITHUB_TOKEN=ghp_xxxx

# 错误
export KEY=value      # 不要 export
KEY="value"           # 不要引号
KEY=value # comment   # 不要注释
```

---

## 相关文档

- [架构说明](./ARCHITECTURE.md)
- [开发者指南](./OPENCODE_CONFIG_GUIDE.md)

