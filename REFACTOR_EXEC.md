# OCD 重构执行方案

## 十问十答

### Q1: 873行单文件的真正痛点是什么？
**A:** 不是行数本身，而是**无法单独测试函数**。`_ocd_find_free_port()` 有 bug 时，必须启动完整流程才能发现。拆分后可以 `source lib/port.sh && 单独测试`。

### Q2: 配置 heredoc 重复（Quotio/非Quotio）有多严重？
**A:** 两处 ~70 行近乎相同的 JSON。问题在于：修改一处忘改另一处。已发生过（端口配置只改了一边）。**模板化是必要的**。

### Q3: 测试应该覆盖什么？ROI 最高的测试点？
**A:**
- ✅ 端口分配（并发安全）
- ✅ 工作区白名单验证（安全相关）
- ✅ 环境变量加载（拒绝注入）
- ❌ Docker 构建（慢，收益低）
- ❌ 通知/剪贴板（需 macOS 环境）

### Q4: Docker 多阶段构建值得吗？
**A:** 当前镜像约 **2.5GB**（Playwright + Python + Node）。多阶段可压缩至 ~1.5GB。但用户只构建一次，**优先级低**。

### Q5: macOS 深度绑定是问题还是特性？
**A:** 是**特性**。项目定位就是 macOS 开发环境。但应抽象成接口：
```bash
platform_open_url()     # macOS: open / Linux: xdg-open
platform_notify()       # macOS: osascript / Linux: notify-send
```
这样未来扩展 Linux 时只需添加实现。

### Q6: 重构期间如何防止回归？
**A:**
1. **先加测试，再改代码**（测试现有行为）
2. 每个 PR 只做一件事
3. 保留 `opencode.sh` 旧版，新版 `bin/ocd` 并行运行对比

### Q7: 高价值低风险的改动是什么？
**A:**
| 改动 | 价值 | 风险 |
|-----|-----|-----|
| 添加 ShellCheck | 高（发现隐藏bug） | 零 |
| 提取 `lib/port.sh` | 高（可测试） | 低 |
| 配置模板化 | 高（消除重复） | 中 |
| 多阶段 Docker | 中 | 中 |

### Q8: 用户会受到什么影响？
**A:** 目标是**零影响**。`ocd` 命令、参数、配置文件路径全部保持不变。只有内部实现改变。

### Q9: 维护成本会降低多少？
**A:**
- 修 bug：从"读 873 行找问题" → "读 50 行模块"
- 加功能：从"插入到巨型函数" → "新增模块文件"
- 估算：**维护时间减少 60%**

### Q10: MVP（最小可行重构）是什么？
**A:** 只做三件事：
1. ShellCheck + CI（发现问题）
2. 提取 `lib/core.sh`（证明模式可行）
3. 配置模板化（解决最痛的重复问题）

---

## 执行计划

### Week 1: 基础设施

```bash
# Day 1: ShellCheck
echo 'external-sources=true' > .shellcheckrc
shellcheck opencode.sh  # 修复所有警告

# Day 2: CI
mkdir -p .github/workflows
# 创建 ci.yml（见下文）

# Day 3-5: 基础测试
mkdir -p tests/bats
brew install bats-core  # 本地测试环境
```

`.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ludeeus/action-shellcheck@master
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: brew install bats-core
      - run: bats tests/bats/*.bats
```

### Week 2: 核心模块提取

提取顺序（依赖关系）：
```
1. lib/core.sh      # 无依赖
2. lib/port.sh      # 依赖 core
3. lib/workspace.sh # 依赖 core
4. lib/config.sh    # 依赖 core
```

`lib/core.sh` 示例：
```bash
#!/usr/bin/env bash
OCD_ROOT="${OCD_ROOT:-$HOME/opencode}"

ocd_version() { cat "$OCD_ROOT/VERSION" 2>/dev/null || echo "unknown"; }

ocd_log() { echo "[ocd] $*"; }
ocd_error() { echo "[ocd] ERROR: $*" >&2; return 1; }

ocd_sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_'
}

ocd_load_env() {
  local env_file="$1"
  [[ ! -f "$env_file" ]] && return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" == *[\;\$\(\)\"\']* ]] && continue
    local key="${line%%=*}" value="${line#*=}"
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] && export "$key=$value"
  done < "$env_file"
}
```

### Week 3: 配置模板化

`templates/opencode.base.json`:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-5",
  "plugin": ["oh-my-opencode@__OMO_VER__", "opencode-antigravity-auth@__AUTH_VER__"],
  "server": { "port": __PORT__, "hostname": "0.0.0.0" },
  "mcp": {
    "playwright": { "type": "local", "command": ["npx", "@playwright/mcp@__PW_VER__", "--headless"], "enabled": true },
    "exa": { "type": "local", "command": ["npx", "-y", "exa-mcp-server@__EXA_VER__"], "enabled": false }
  }
}
```

`templates/provider.quotio.json`:
```json
{
  "provider": {
    "quotio": {
      "name": "Quotio",
      "npm": "@ai-sdk/anthropic",
      "options": { "apiKey": "__QUOTIO_KEY__", "baseURL": "__QUOTIO_URL__" },
      "models": { ... }
    }
  }
}
```

生成逻辑：
```bash
ocd_gen_config() {
  local out="$1" port="$2" quotio="$3"

  # 渲染基础模板
  sed -e "s/__PORT__/$port/" \
      -e "s/__OMO_VER__/$OMO_VER/" \
      "$OCD_ROOT/templates/opencode.base.json" > "$out"

  # 合并 provider（如需要）
  if [[ "$quotio" -eq 1 ]]; then
    jq -s '.[0] * .[1]' "$out" "$OCD_ROOT/templates/provider.quotio.json" > "$out.tmp"
    mv "$out.tmp" "$out"
  fi
}
```

---

## 文件结构（目标态）

```
opencode/
├── bin/ocd                    # 入口 (~60行)
├── lib/
│   ├── core.sh                # 工具函数 (~50行)
│   ├── port.sh                # 端口管理 (~60行)
│   ├── workspace.sh           # 工作区 (~80行)
│   ├── config.sh              # 配置生成 (~100行)
│   ├── watcher.sh             # IPC (~50行)
│   └── docker.sh              # 容器操作 (~80行)
├── templates/
│   ├── opencode.base.json
│   └── provider.quotio.json
├── tests/bats/
│   ├── core.bats
│   ├── port.bats
│   └── workspace.bats
├── .github/workflows/ci.yml
├── Dockerfile
└── versions.lock
```

---

## 验收标准

| 阶段 | 完成标志 |
|-----|---------|
| Week 1 | CI 绿灯，ShellCheck 0 警告 |
| Week 2 | `lib/*.sh` 可独立 source，测试通过 |
| Week 3 | 配置生成走模板，`ocd` 功能不变 |

---

## 风险控制

1. **每次只改一个模块**，单独 PR
2. **保留 opencode.sh 备份**，出问题可回滚
3. **CI 必须绑定 PR**，不绿不合并
4. **用户可见行为不变**：命令、参数、输出格式

---

## 不做的事

- ❌ Linux 支持（当前用户都是 macOS）
- ❌ Docker 多阶段（收益不够大）
- ❌ 英文文档（主要用户是中文）
- ❌ 插件系统（没有用户需求）

---

## 下一步行动

```bash
# 立即执行
shellcheck opencode.sh > shellcheck_report.txt
# 根据报告修复问题
```
