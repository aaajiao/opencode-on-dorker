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
bats tests/bats/workspace.bats

# Run specific test by name (regex filter)
bats tests/bats/config.bats -f "template"   # Tests matching "template"

# Verbose mode with timing
bats -t tests/bats/core.bats

# Manual container test
docker run -it --rm --network host opencode-bun bash
```

## File Structure

```
~/opencode/
├── bin/
│   ├── ocd                    # Main entry script
│   └── devocd                 # Dev mode (uses ~/.config/opencode-dev/)
├── lib/
│   ├── core.sh                # XDG paths, version, logging, env loading
│   ├── config.sh              # v5: Config creation & port updates
│   ├── docker.sh              # Docker build & run
│   ├── migrate.sh             # v4→v5 migration
│   ├── port.sh                # Port allocation, atomic locks
│   ├── watcher.sh             # IPC monitoring (clipboard/notify/URL)
│   └── workspace.sh           # Workspace detection, whitelist
├── templates/
│   ├── global/                # First-run config templates
│   │   ├── opencode.json.tmpl
│   │   └── oh-my-opencode.json
│   └── project/               # `ocd init` templates
├── tests/bats/*.bats          # Unit tests (11 files)
├── Dockerfile
├── .env                       # API keys (KEY=VALUE only!)
├── models.conf                # Optional model overrides
└── versions.lock              # Dependency versions

# Runtime directories (Mac host)
~/.config/opencode/            # Global config (user-owned after first run)
~/.local/share/opencode/       # Sessions, auth
~/.local/state/opencode/ipc/   # Per-port IPC files
~/.cache/opencode/             # Cache (safe to delete)
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

# Remove unused variables (ShellCheck SC2034)
local used_var="value"
echo "$used_var"               # Must be used or removed

# Functions - prefix with ocd_ (public) or _ocd_ (private)
ocd_public_function() {
  local arg="$1"
  echo "$arg"
}

_ocd_private_helper() {        # Private function
  local pid="$1"
}

# Error handling
command 2>/dev/null            # Suppress errors
command -v cmd &>/dev/null     # Check command exists
cmd || true                    # Allow failure
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

**CRITICAL**: Pure `KEY=VALUE` format only
```bash
# WRONG
export API_KEY="sk-xxx"
KEY=value # comment

# CORRECT
API_KEY=sk-xxx
GITHUB_TOKEN=ghp_xxxx
```

## CLI Reference

```bash
# Standard usage
ocd                      # Auto-detect workspace, auto port
ocd -p 5000              # Custom port
ocd --here               # Mount only current directory
ocd -r                   # Rebuild image + clear cache
ocd -v                   # Show version

# v5 subcommands
ocd init                 # Initialize project config
ocd config               # Show config status
ocd config edit          # Open config in editor
ocd --clean              # Reset global config (with backup)

# Development (isolated from production)
devocd                   # Uses dev/ code + opencode-bun-dev image
devocd -r                # Rebuild dev image
```

## v5 Config Architecture

| Event | Action |
|-------|--------|
| First run | Create config from templates |
| Each startup | Update port only |
| `--clean` | Backup existing + recreate |
| `models.conf` exists | Apply model overrides |

Key functions in `lib/config.sh`:
- `ocd_ensure_global_config()` - First-time creation
- `ocd_update_port()` - Port-only updates  
- `ocd_reset_global_config()` - `--clean` handler
- `ocd_init_project()` - Project initialization

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

# Manual testing (on Mac, after exiting container)
exec zsh                       # Reload shell
devocd                         # Test with dev code
```
