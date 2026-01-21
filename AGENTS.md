# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)** v5.0: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. `/workspace/bin/ocd` = `~/opencode/bin/ocd`.

**v5 Philosophy**: Config files created once from templates, then user-owned. OCD only updates port on startup.

## Directory Structure (CRITICAL)

This repo uses **git worktree** for development:

| Path | Purpose | Docker Mount | Image |
|------|---------|--------------|-------|
| `~/opencode/` | Production | `/workspace` | `opencode-bun` |
| `~/opencode/dev/` | Development (worktree) | `/workspace/dev` | `opencode-bun-dev` |

**Key points**:
- When working in `/workspace/dev`, you're editing the **dev branch**
- Production (`~/opencode/`) and dev (`~/opencode/dev/`) are **separate git worktrees**
- Changes in dev need `git push` → then pull in production to sync
- Each has its own `versions.lock` - keep them in sync manually

**Config isolation**:
| Environment | Global Config | State |
|-------------|---------------|-------|
| Production (`ocd`) | `~/.config/opencode/` | `~/.local/state/opencode/` |
| Development (`devocd`) | `~/.config/opencode-dev/` | `~/.local/state/opencode-dev/` |

**Typical dev workflow**:
```bash
# 1. Start dev container
devocd

# 2. Make changes in /workspace/dev
# 3. Test with: bash -n, shellcheck, bats

# 4. Exit container, commit & push
git add -A && git commit -m "feat: ..." && git push

# 5. In production ~/opencode/, pull changes
cd ~/opencode && git pull
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add CLI option | `bin/ocd` | Parse in `while` loop, add to help |
| Add shell function | `lib/*.sh` | Match module (config/docker/port/etc) |
| Fix Docker build | `Dockerfile` | Chinese comments: `# 第N步` |
| Update dependency | `versions.lock` | Then `ocd -r` to rebuild |
| Add MCP server | `templates/global/opencode.json.tmpl` | Use `{{VAR}}` for version |
| Add test | `tests/bats/*.bats` | Match module name |
| Debug container | `lib/docker.sh` → `ocd_run_container` | Check mount args |
| Debug workspace | `lib/workspace.sh` | `ocd_find_workspace_root` |
| Debug port | `lib/port.sh` | `ocd_find_free_port` |
| Debug config | `lib/config.sh` | `ocd_ensure_global_config` |

## CODE MAP

| Module | Lines | Key Functions | Purpose |
|--------|-------|---------------|---------|
| `lib/config.sh` | 430 | `ocd_ensure_global_config`, `ocd_update_port`, `ocd_init_project` | v5 config management |
| `lib/scan.sh` | 336 | `ocd_scan`, `ocd_register_project`, `ocd_touch` | Project scanning |
| `bin/ocd` | 329 | `main`, `_ocd_cleanup` | Entry point, arg parsing |
| `lib/core.sh` | 159 | `ocd_load_env`, `ocd_sanitize_name`, `ocd_version` | Core utilities |
| `lib/docker.sh` | 149 | `ocd_build_image`, `ocd_run_container` | Docker operations |
| `lib/workspace.sh` | 127 | `ocd_find_workspace_root`, `ocd_find_project_dir` | Workspace detection |
| `lib/watcher.sh` | 92 | `ocd_start_watcher`, `ocd_handle_*` | IPC file monitoring |
| `lib/migrate.sh` | 88 | `ocd_check_migration` | v4→v5 migration |
| `lib/port.sh` | 69 | `ocd_find_free_port` | Port allocation with locking |

## Build & Test Commands

```bash
# Docker
docker build -t opencode-bun .              # Build image
docker build --no-cache -t opencode-bun .   # Full rebuild
ocd -r                                      # Rebuild + clear cache

# Shell validation
bash -n bin/ocd lib/*.sh                    # Syntax check
shellcheck -S warning bin/ocd lib/*.sh      # Lint (CI standard)

# Run ALL tests
bats tests/bats/*.bats

# Run SINGLE test file
bats tests/bats/config.bats

# Run specific test by name (regex filter)
bats tests/bats/config.bats -f "template"

# Verbose mode with timing
bats -t tests/bats/core.bats

# Manual container test
docker run -it --rm --network host opencode-bun bash
```

## File Structure

```
~/opencode/
├── bin/ocd, devocd            # Entry scripts
├── lib/*.sh                   # Core modules (config, docker, port, etc.)
├── templates/global/          # Config templates (opencode.json.tmpl)
├── tests/bats/*.bats          # Unit tests
├── Dockerfile
├── .env                       # API keys (KEY=VALUE only!)
├── versions.lock              # Dependency versions
└── models.conf                # Optional model overrides

# Runtime (Mac host)
~/.config/opencode/            # Global config (user-owned)
~/.local/share/opencode/       # Sessions, auth
~/.local/state/opencode/ipc/   # Per-port IPC files
```

## Code Style Guidelines

### Shell Scripts (bin/ocd, lib/*.sh)

```bash
# Formatting
- 2-space indentation
- [[ ]] for conditionals (not [ ])
- Quote variables: "$VAR"
- $() for command substitution (not backticks)

# Variables - declare and assign separately (ShellCheck SC2155)
local var
var=$(command)                 # CORRECT
local var=$(command)           # WRONG - triggers SC2155

# Functions - prefix with ocd_ (public) or _ocd_ (private)
ocd_public_function() {
  local arg="$1"
  echo "$arg"
}

# Error handling
command 2>/dev/null            # Suppress errors
command -v cmd &>/dev/null     # Check command exists
${VAR:-default}                # Default value syntax
```

**CRITICAL**: Never use `local` inside subshells `( ... ) &`

### Dockerfile

- Chinese comments: `# 第N步：描述`
- Minimize layers: chain with `&&`
- Clean in same layer: `&& rm -rf /var/lib/apt/lists/*`

### JSON Configuration

- 2-space indentation, no trailing commas
- Use `$schema` when available

### Environment Variables (.env)

**CRITICAL**: Pure `KEY=VALUE` format only (no quotes, no export, no comments)

## Version Locking (versions.lock)

All dependency versions are centralized in `versions.lock`. Template variables use `{{VAR_NAME}}` syntax.

**Adding a new MCP server**:
1. Add version to `versions.lock`: `MY_MCP_VERSION=1.2.3`
2. Use in template: `"command": ["npx", "my-mcp@{{MY_MCP_VERSION}}"]`
3. Run `ocd --clean` to regenerate config

Key variables:
- `OPENCODE_AI_VERSION`, `OH_MY_OPENCODE_VERSION`
- `PLAYWRIGHT_MCP_VERSION`, `EXA_MCP_VERSION`
- `BUN_VERSION`, `PIP_*` versions

## MCP Configuration

Playwright MCP requires special flags for Docker:
```json
"command": ["npx", "@playwright/mcp@{{PLAYWRIGHT_MCP_VERSION}}", "--headless", "--isolated", "--no-sandbox"]
```
- `--headless`: No GUI
- `--isolated`: Memory-only profile (no disk locks)
- `--no-sandbox`: Required for root user in Docker

## CLI Reference

### Basic Usage

```bash
ocd                      # Auto-detect workspace, auto port
ocd -p 5000              # Custom port
ocd --here               # Mount only current directory
ocd -r                   # Rebuild image + clear cache
ocd --clean              # Reset global config (with backup)
```

### Subcommands

```bash
ocd init                 # Initialize project config (.opencode/, .claude/, AGENTS.md)
ocd config               # Show config paths and status
ocd config edit          # Open global config in editor
ocd scan                 # Scan and register git projects in workspace
ocd touch <project>      # Update project timestamp for WebUI visibility
```

### Development Mode

```bash
devocd                   # Run from ~/opencode/dev/, uses opencode-bun-dev image
devocd -r                # Rebuild dev image
```

### Additional Flags

| Flag | Description |
|------|-------------|
| `-v` | Show version |
| `-h` | Show help |
| `--https` | Enable HTTPS via Tailscale Serve |
| `--awake` | Prevent Mac sleep (caffeinate) |
| `--merge-up` | Merge transcripts to parent project |
| `--quotio` | Enable Quotio proxy |

## Common Pitfalls

1. **SC2155**: Declare and assign separately: `local x; x=$(cmd)`
2. **SC2034**: Remove unused variables immediately
3. **`local` in subshell**: Never use inside `( ... ) &`
4. **Env format**: No quotes, no export, no inline comments
5. **Port conflict**: `rm ~/.config/opencode/.port.lock`
6. **Shell reload**: Run `exec zsh` after modifying scripts

## Testing Workflow

```bash
# In container (/workspace/dev)
bash -n bin/ocd lib/*.sh       # 1. Syntax check
bats tests/bats/*.bats         # 2. Run tests

# On Mac (after exiting container)
exec zsh                       # Reload shell
devocd                         # Test with dev code
```

## CI Pipeline (GitHub Actions)

CI runs on every PR with these checks:
- **Syntax Check**: `bash -n` on all shell scripts
- **ShellCheck**: Lint with `-S warning`
- **Unit Tests**: `bats tests/bats/*.bats`
- **Docker Build**: Full image build + verification

All checks must pass before merging.

## Task Completion Notification

After completing the following operations, **MUST** run `notify "title" "result"` to send macOS desktop notification:

| Trigger | Example |
|---------|---------|
| Subagent task returns | `notify "Oracle Analysis Done" "Architecture suggestions ready"` |
| `git push` completes | `notify "Git Push Done ✅" "3 commits → origin/main"` |
| Long-running command (>30s) completes | `notify "Build Done ✅" "Docker image built successfully"` |
| User explicitly says "remind me when done" | Notify as requested |

**No notification needed**: Normal file read/write, simple Q&A, quick command execution.
