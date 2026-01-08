# OCD 重构执行方案

> 状态：✅ 已完成 | 版本: v2.0

## 十问十答

| # | 问题 | 答案 |
|---|-----|------|
| 1 | 单文件痛点？ | 无法单独测试函数，必须启动完整流程 |
| 2 | heredoc 重复？ | 两处 70 行 JSON，修改易漏，已出过 bug |
| 3 | 测试重点？ | 端口分配、白名单验证、环境变量注入防护 |
| 4 | Docker 多阶段？ | 优先级低，用户只构建一次 |
| 5 | macOS 绑定？ | 是特性，但已抽象接口备扩展 |
| 6 | 防回归？ | 先加测试再改代码，保留旧版对比 |
| 7 | 高价值改动？ | ShellCheck > 模块提取 > 配置模板 |
| 8 | 用户影响？ | 零影响，命令参数路径全部不变 |
| 9 | 维护成本？ | 读 50 行模块 vs 873 行，估算降低 60% |
| 10 | MVP？ | ShellCheck + lib/*.sh + 配置生成 |

---

## 完成的重构

### 目录结构

```
opencode/
├── bin/ocd              # 主入口 (180行)
├── lib/
│   ├── core.sh          # 版本/日志/环境变量 (95行)
│   ├── port.sh          # 端口管理 (58行)
│   ├── workspace.sh     # 工作区检测 (85行)
│   ├── watcher.sh       # IPC 监听 (75行)
│   ├── config.sh        # 配置生成 (175行)
│   └── docker.sh        # 容器操作 (95行)
├── tests/bats/
│   ├── core.bats        # 核心模块测试
│   ├── port.bats        # 端口模块测试
│   ├── workspace.bats   # 工作区测试
│   └── config.bats      # 配置测试
├── .github/workflows/
│   └── ci.yml           # CI 流水线
├── .shellcheckrc        # ShellCheck 配置
├── opencode.sh          # [保留] 旧版单文件
├── Dockerfile
└── versions.lock
```

### 模块职责

| 模块 | 职责 | 关键函数 |
|-----|------|---------|
| `core.sh` | 基础工具 | `ocd_version`, `ocd_load_env`, `ocd_sanitize_name` |
| `port.sh` | 端口分配 | `ocd_find_free_port` (原子锁+并发安全) |
| `workspace.sh` | 工作区 | `ocd_find_workspace_root`, `ocd_validate_workspace` |
| `watcher.sh` | IPC | `ocd_start_watcher`, `ocd_handle_url/notify/clipboard` |
| `config.sh` | 配置生成 | `ocd_generate_opencode_config` (消除重复) |
| `docker.sh` | 容器 | `ocd_build_image`, `ocd_run_container` |

### CI 流水线

```yaml
jobs:
  lint:     # ShellCheck 静态分析
  test:     # bats 单元测试 (macOS)
  syntax:   # bash -n 语法检查
  docker:   # 镜像构建验证
```

---

## 测试覆盖

| 模块 | 测试项 |
|-----|--------|
| core | 名称清理、环境变量加载、危险字符拒绝 |
| port | 端口范围、连续调用不重复、文件记录 |
| workspace | git 查找、白名单验证、相对路径计算 |
| config | JSON 有效性、端口正确、Quotio 条件生成 |

---

## 使用方式

### 新版（模块化）
```bash
# 直接执行
~/opencode/bin/ocd

# 或 source 后使用
source ~/opencode/bin/ocd
```

### 旧版（兼容）
```bash
source ~/opencode/opencode.sh
ocd
```

---

## 后续可选优化

| 优化项 | 价值 | 状态 |
|-------|-----|------|
| Docker 多阶段构建 | 镜像减小 40% | 待定 |
| Linux 平台支持 | 跨平台 | 待定 |
| 插件系统 | 用户扩展 | 待定 |

---

## 验证命令

```bash
# 语法检查
for f in lib/*.sh bin/ocd; do bash -n "$f"; done

# 运行测试 (需要 bats)
bats tests/bats/*.bats

# 使用新版
~/opencode/bin/ocd -v
```
