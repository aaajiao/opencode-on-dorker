# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)** v5.0: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. `/workspace/bin/ocd` = `~/opencode/bin/ocd`.

**v5 Philosophy**: Config files created once from templates, then user-owned. OCD only updates port on startup.

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

```bash
ocd                      # Auto-detect workspace, auto port
ocd -p 5000              # Custom port
ocd --here               # Mount only current directory
ocd -r                   # Rebuild image + clear cache
ocd init                 # Initialize project config
ocd config               # Show config status
ocd --clean              # Reset global config (with backup)
devocd                   # Dev mode (isolated from production)
```

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
