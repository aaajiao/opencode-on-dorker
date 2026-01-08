# OCD 项目重构方案

> 版本: 1.0 | 日期: 2026-01-08 | 针对版本: v1.4.0

## 目录

1. [现状分析](#现状分析)
2. [重构目标](#重构目标)
3. [Phase 1: 代码模块化](#phase-1-代码模块化)
4. [Phase 2: 配置系统重构](#phase-2-配置系统重构)
5. [Phase 3: Docker 优化](#phase-3-docker-优化)
6. [Phase 4: 测试与 CI/CD](#phase-4-测试与-cicd)
7. [Phase 5: 可扩展性设计](#phase-5-可扩展性设计)
8. [迁移策略](#迁移策略)
9. [优先级排序](#优先级排序)

---

## 现状分析

### 代码结构现状

```
opencode/
├── opencode.sh       # 873 行单文件，包含所有逻辑
├── Dockerfile        # 223 行，13 个 RUN 步骤
├── versions.lock     # 版本锁定
├── scripts/          # 辅助脚本（2个）
├── global/           # 全局配置模板
├── server/           # 服务器模式
└── docs/             # 文档
```

### 关键问题

| 问题类型 | 具体问题 | 影响程度 |
|---------|---------|---------|
| **代码组织** | 873 行单文件，职责混杂 | 🔴 高 |
| **配置重复** | Quotio/非 Quotio 配置 heredoc 重复 | 🟡 中 |
| **测试缺失** | 无自动化测试、无 CI/CD | 🔴 高 |
| **耦合度** | 深度绑定 macOS (pbcopy, osascript) | 🟡 中 |
| **镜像体积** | 无多阶段构建，包含大量依赖 | 🟡 中 |
| **错误处理** | 部分错误静默处理，缺少诊断信息 | 🟡 中 |

---

## 重构目标

### 核心目标

1. **可维护性**: 代码模块化，单一职责
2. **可测试性**: 函数可独立测试，关键路径覆盖
3. **可扩展性**: 新功能易于添加，provider 系统插件化
4. **可靠性**: 完善错误处理，提供诊断工具

### 约束条件

- 保持向后兼容（现有用户无需修改配置）
- 最小化破坏性变更
- 保持 macOS 为主要支持平台

---

## Phase 1: 代码模块化

### 1.1 目录结构重组

```
opencode/
├── bin/
│   └── ocd                      # 主入口（简化后 ~50 行）
├── lib/
│   ├── core.sh                  # 核心函数 (version, sanitize, env)
│   ├── workspace.sh             # 工作区检测与验证
│   ├── port.sh                  # 端口管理
│   ├── watcher.sh               # IPC 监听器
│   ├── config.sh                # 配置生成
│   ├── docker.sh                # Docker 操作
│   └── platform/
│       ├── macos.sh             # macOS 特定实现
│       └── linux.sh             # Linux 兼容层（未来扩展）
├── templates/
│   ├── opencode.json.tpl        # 配置模板
│   └── oh-my-opencode.json.tpl
├── Dockerfile
├── versions.lock
└── ...
```

### 1.2 模块拆分设计

#### `lib/core.sh` - 核心工具函数

```bash
# 导出以下函数:
# - ocd_version()          读取版本号
# - ocd_load_versions()    加载 versions.lock
# - ocd_sanitize_name()    清理实例名
# - ocd_load_env()         安全加载环境变量
# - ocd_log()              统一日志输出
# - ocd_error()            错误处理
```

#### `lib/workspace.sh` - 工作区管理

```bash
# 导出以下函数:
# - ocd_find_workspace_root()    查找工作区根目录
# - ocd_find_project_dir()       查找项目目录
# - ocd_get_relative_path()      计算相对路径
# - ocd_validate_whitelist()     白名单验证
```

#### `lib/config.sh` - 配置生成

```bash
# 导出以下函数:
# - ocd_generate_opencode_config()     生成 opencode.json
# - ocd_generate_omo_config()          生成 oh-my-opencode.json
# - ocd_update_port()                  更新端口配置
# - ocd_merge_provider()               合并 provider 配置

# 关键改进: 使用模板系统替代 heredoc
```

#### `lib/platform/macos.sh` - 平台特定实现

```bash
# 导出以下函数:
# - ocd_handle_url()           打开 URL
# - ocd_handle_notify()        发送通知
# - ocd_handle_clipboard()     同步剪贴板
# - ocd_get_tailscale_ip()     获取 Tailscale IP
# - ocd_start_caffeinate()     防止休眠
```

### 1.3 主入口简化

```bash
#!/usr/bin/env bash
# bin/ocd - OCD 主入口

set -euo pipefail

OCD_ROOT="${OCD_ROOT:-$HOME/opencode}"

# 加载模块
source "$OCD_ROOT/lib/core.sh"
source "$OCD_ROOT/lib/workspace.sh"
source "$OCD_ROOT/lib/port.sh"
source "$OCD_ROOT/lib/watcher.sh"
source "$OCD_ROOT/lib/config.sh"
source "$OCD_ROOT/lib/docker.sh"
source "$OCD_ROOT/lib/platform/macos.sh"

# 解析参数
ocd_parse_args "$@"

# 主流程
ocd_main
```

---

## Phase 2: 配置系统重构

### 2.1 模板系统

创建 `templates/opencode.json.tpl`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "{{MODEL}}",
  "plugin": [
    "oh-my-opencode@{{OMO_VERSION}}",
    "opencode-antigravity-auth@{{AUTH_VERSION}}"
  ],
  "server": {
    "port": {{PORT}},
    "hostname": "0.0.0.0"
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@{{PLAYWRIGHT_VERSION}}", "--headless"],
      "enabled": true
    },
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server@{{EXA_VERSION}}"],
      "timeout": 60000,
      "enabled": false,
      "environment": {
        "EXA_API_KEY": "{{EXA_API_KEY}}"
      }
    }
  }
  {{#QUOTIO}}
  ,"provider": {{QUOTIO_PROVIDER}}
  {{/QUOTIO}}
}
```

### 2.2 Provider 插件化

创建 `providers/` 目录管理第三方 provider:

```
providers/
├── quotio.json          # Quotio provider 配置
├── openrouter.json      # OpenRouter (未来)
└── custom.json          # 用户自定义模板
```

`providers/quotio.json`:

```json
{
  "quotio": {
    "name": "Quotio",
    "npm": "@ai-sdk/anthropic",
    "options": {
      "apiKey": "{{QUOTIO_API_KEY}}",
      "baseURL": "{{QUOTIO_BASE_URL}}"
    },
    "models": {
      "gemini-claude-sonnet-4-5": {
        "name": "Claude Sonnet 4.5",
        "limit": { "context": 200000, "output": 64000 }
      }
    }
  }
}
```

### 2.3 配置合并逻辑

```bash
ocd_generate_config() {
  local template="$OCD_ROOT/templates/opencode.json.tpl"
  local output="$1"
  local vars="$2"  # JSON 格式的变量

  # 使用 envsubst 或 jq 进行模板渲染
  if command -v jq &>/dev/null; then
    ocd_render_template_jq "$template" "$vars" > "$output"
  else
    ocd_render_template_sed "$template" "$vars" > "$output"
  fi

  # 合并 provider（如果启用）
  if [[ "$USE_QUOTIO" -eq 1 ]]; then
    ocd_merge_provider "$output" "$OCD_ROOT/providers/quotio.json"
  fi
}
```

---

## Phase 3: Docker 优化

### 3.1 多阶段构建

```dockerfile
# =============================================
# Stage 1: Builder - 编译依赖
# =============================================
FROM oven/bun:${BUN_VERSION} AS builder

# 安装编译工具
RUN apt-get update && apt-get install -y \
    build-essential python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 预编译 Python 依赖
COPY requirements.txt /tmp/
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# =============================================
# Stage 2: Browser - Playwright 缓存
# =============================================
FROM mcr.microsoft.com/playwright:v1.40.0-focal AS browser

# =============================================
# Stage 3: Runtime - 最终镜像
# =============================================
FROM oven/bun:${BUN_VERSION}-slim AS runtime

# 从 builder 复制 Python 虚拟环境
COPY --from=builder /opt/venv /opt/venv

# 从 browser 复制 Playwright
COPY --from=browser /ms-playwright /root/.cache/ms-playwright

# 安装运行时依赖（不含编译工具）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates jq tmux python3 \
    && rm -rf /var/lib/apt/lists/*

# ... 其余配置
```

### 3.2 依赖分层

```dockerfile
# 创建 requirements.txt 替代内联 pip install
# 这样可以利用 Docker 缓存层

COPY requirements.txt /tmp/
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /tmp/requirements.txt
```

### 3.3 Entrypoint 脚本外置

将 Dockerfile 中的 `echo '...' > entrypoint.sh` 改为独立文件：

```
scripts/
├── entrypoint.sh       # 容器入口
├── fake-xclip.sh       # 剪贴板桥接
├── check-exa.sh        # Exa 健康检查
└── notify.sh           # 通知脚本
```

好处：
- 更容易维护和测试
- 避免转义字符问题
- 支持 IDE 语法高亮

---

## Phase 4: 测试与 CI/CD

### 4.1 测试框架

采用 [bats-core](https://github.com/bats-core/bats-core) 进行 Shell 测试：

```
tests/
├── bats/                    # bats-core 测试
│   ├── test_helper/
│   │   └── common.bash      # 测试辅助函数
│   ├── core.bats            # core.sh 测试
│   ├── workspace.bats       # workspace.sh 测试
│   ├── port.bats            # port.sh 测试
│   └── config.bats          # config.sh 测试
├── integration/             # 集成测试
│   ├── docker_build.bats    # Docker 构建测试
│   └── e2e.bats             # 端到端测试
└── fixtures/                # 测试数据
    ├── mock_workspace/
    └── mock_configs/
```

### 4.2 测试示例

`tests/bats/workspace.bats`:

```bash
#!/usr/bin/env bats

load 'test_helper/common'

setup() {
  source "$BATS_TEST_DIRNAME/../../lib/workspace.sh"
  export TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/project/.git"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "find_workspace_root 返回 git 仓库父目录" {
  result=$(ocd_find_workspace_root "$TEST_DIR/project/src")
  [ "$result" = "$TEST_DIR" ]
}

@test "find_workspace_root 处理白名单" {
  export OCD_ALLOWED_WORKSPACES="$TEST_DIR"
  result=$(ocd_find_workspace_root "$TEST_DIR/project")
  [ "$result" = "$TEST_DIR" ]
}

@test "find_workspace_root 拒绝非白名单路径" {
  export OCD_ALLOWED_WORKSPACES="/allowed/path"
  run ocd_find_workspace_root "$TEST_DIR/project"
  [ "$status" -eq 1 ]
  [[ "$output" == *"BLOCKED"* ]]
}
```

### 4.3 CI/CD Pipeline

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './lib'
          additional_files: 'bin/ocd'

  test:
    runs-on: macos-latest  # 需要 macOS 特定功能
    steps:
      - uses: actions/checkout@v4
      - name: Install bats
        run: brew install bats-core
      - name: Run unit tests
        run: bats tests/bats/*.bats

  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: |
          docker build \
            --build-arg BUN_VERSION=1.3.5 \
            -t ocd-test .
      - name: Test Docker image
        run: |
          docker run --rm ocd-test opencode --version

  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [lint, test, docker]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```

### 4.4 Pre-commit Hooks

`.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks:
      - id: shellcheck
        args: ["-x"]  # 支持 source 外部文件

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-json
      - id: check-yaml
```

---

## Phase 5: 可扩展性设计

### 5.1 插件系统

支持用户自定义扩展：

```
~/.config/ocd/
├── plugins/
│   ├── my-provider.sh       # 自定义 provider
│   └── my-hook.sh           # 自定义 hook
└── hooks/
    ├── pre-start.sh         # 容器启动前
    └── post-stop.sh         # 容器停止后
```

Hook 加载机制：

```bash
# lib/hooks.sh
ocd_run_hooks() {
  local hook_type="$1"
  local hooks_dir="$HOME/.config/ocd/hooks"

  [[ -d "$hooks_dir" ]] || return 0

  for hook in "$hooks_dir/${hook_type}"*.sh; do
    [[ -x "$hook" ]] && source "$hook"
  done
}
```

### 5.2 Provider 注册机制

```bash
# lib/providers.sh

# 注册 provider
ocd_register_provider() {
  local name="$1"
  local config_file="$2"

  cp "$config_file" "$OCD_ROOT/providers/${name}.json"
  echo "✅ Provider '$name' 已注册"
}

# 列出 providers
ocd_list_providers() {
  for f in "$OCD_ROOT/providers"/*.json; do
    [[ -f "$f" ]] && basename "$f" .json
  done
}

# 启用 provider
ocd_enable_provider() {
  local name="$1"
  local config="$OCD_ROOT/providers/${name}.json"

  [[ -f "$config" ]] || { echo "Provider '$name' 不存在"; return 1; }

  # 合并到当前配置
  ocd_merge_provider "$INSTANCE_CONFIG_FILE" "$config"
}
```

### 5.3 平台抽象层

```bash
# lib/platform.sh

# 自动检测并加载平台实现
ocd_load_platform() {
  case "$(uname -s)" in
    Darwin)
      source "$OCD_ROOT/lib/platform/macos.sh"
      ;;
    Linux)
      source "$OCD_ROOT/lib/platform/linux.sh"
      ;;
    *)
      ocd_error "不支持的平台: $(uname -s)"
      ;;
  esac
}
```

---

## 迁移策略

### 向后兼容性

1. **现有命令兼容**: `ocd` 命令参数保持不变
2. **配置文件兼容**: 现有 `.env`、`.ocdrc` 继续生效
3. **目录结构兼容**: `~/.config/opencode/` 路径不变

### 迁移步骤

1. **Phase 1** (1-2 周): 代码模块化，不改变对外接口
2. **Phase 2** (1 周): 配置系统重构，同时支持旧格式
3. **Phase 3** (1 周): Docker 优化，镜像名称不变
4. **Phase 4** (持续): 添加测试，建立 CI/CD
5. **Phase 5** (按需): 扩展性功能逐步添加

### 版本规划

| 版本 | 内容 | 兼容性 |
|------|------|--------|
| v1.5.0 | Phase 1 完成 | 完全兼容 |
| v1.6.0 | Phase 2 完成 | 完全兼容 |
| v1.7.0 | Phase 3 完成 | 完全兼容 |
| v2.0.0 | 全部完成，弃用旧功能 | 主要兼容 |

---

## 优先级排序

### 高优先级 (立即执行)

1. **添加 ShellCheck**: 静态分析，发现潜在 bug
2. **基础测试框架**: 关键路径测试覆盖
3. **CI/CD 基础**: PR 自动检查

### 中优先级 (1-2 月内)

4. **代码模块化**: 拆分 opencode.sh
5. **配置模板系统**: 消除 heredoc 重复
6. **Docker 多阶段构建**: 减小镜像体积

### 低优先级 (按需)

7. **插件系统**: 用户扩展支持
8. **Linux 兼容**: 跨平台支持
9. **国际化**: 英文文档/消息

---

## 快速行动项

### 本周可完成

```bash
# 1. 添加 ShellCheck 配置
cat > .shellcheckrc << 'EOF'
external-sources=true
source-path=lib
EOF

# 2. 创建基础测试结构
mkdir -p tests/bats tests/fixtures
cat > tests/bats/smoke.bats << 'EOF'
#!/usr/bin/env bats
@test "opencode.sh 语法检查" {
  bash -n "$BATS_TEST_DIRNAME/../../opencode.sh"
}
EOF

# 3. 添加 GitHub Actions 工作流
mkdir -p .github/workflows
# 创建 ci.yml (见上文)
```

---

## 总结

本重构方案的核心理念是**渐进式改进**：

1. **不破坏现有功能**: 每个 phase 都保持向后兼容
2. **可测量的进展**: 每个 phase 都有明确的完成标准
3. **灵活的优先级**: 根据实际需求调整执行顺序
4. **务实的取舍**: 优先解决高影响问题

通过这个重构，OCD 将从一个"能用"的工具，升级为一个"好维护、易扩展、高可靠"的专业项目。
