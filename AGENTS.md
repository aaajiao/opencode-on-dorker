# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)** v4.0: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. `/workspace/bin/ocd` = `~/opencode/bin/ocd`.

## Build & Test Commands

```bash
# Docker
docker build -t opencode-bun .              # Build image
docker build --no-cache -t opencode-bun .   # Full rebuild
ocd -r                                      # Rebuild + clear cache

# Shell validation
bash -n bin/ocd lib/*.sh                    # Syntax check
shellcheck bin/ocd lib/*.sh                 # Lint (severity: warning)

# JSON validation
jq . ~/.config/opencode/opencode.json

# Run ALL tests
brew install bats-core jq fswatch           # Install dependencies
bats tests/bats/*.bats                      # Run all tests

# Run SINGLE test file
bats tests/bats/core.bats
bats tests/bats/workspace.bats

# Run specific test by name (regex filter)
bats tests/bats/core.bats -f "sanitize"     # Tests matching "sanitize"

# Test container manually
docker run -it --rm --network host opencode-bun bash
```

## File Structure

```
~/opencode/
├── bin/
│   ├── ocd                    # Main entry script
│   └── devocd                 # Dev mode shortcut (bypasses main ocd)
├── lib/
│   ├── core.sh                # XDG paths, version, logging, env loading
│   ├── port.sh                # Port allocation, atomic locks
│   ├── workspace.sh           # Workspace detection, whitelist
│   ├── watcher.sh             # IPC monitoring (clipboard/notify/URL)
│   ├── config.sh              # Config generation (opencode.json, oh-my-opencode.json)
│   └── docker.sh              # Docker build & run
├── scripts/
│   ├── migrate-v4.sh          # v3->v4 migration
│   └── fake-xclip.sh          # Clipboard bridge for container
├── tests/bats/*.bats          # Unit tests (bats-core)
├── Dockerfile
├── .env                       # API keys (KEY=VALUE only!)
└── .ocdrc                     # Local config (workspace whitelist)

# Runtime directories (Mac host, auto-created)
~/.config/opencode/                         # Config (shared)
~/.local/share/opencode/storage/            # Sessions (by git SHA)
~/.local/state/opencode/ipc/<port>/         # IPC files per port
~/.cache/opencode/                          # Cache
```

## Code Style Guidelines

### Shell Scripts (bin/ocd, lib/*.sh)

```bash
# Formatting
- 2-space indentation
- [[ ]] for conditionals (not [ ])
- Quote variables: "$VAR"
- $() for command substitution (not backticks)

# Variables
local VAR_NAME="value"         # Local scope in functions
CONSTANT_NAME="value"          # No 'local' for module constants
${VAR:-default}                # Default value syntax

# Functions - prefix with ocd_ (public) or _ocd_ (private)
ocd_sanitize_name() {
  local arg="$1"
  echo "$arg" | tr '[:upper:]' '[:lower:]'
}

_ocd_cleanup() {               # Private function
  local pid="$1"
}

# Error handling
command 2>/dev/null            # Suppress errors
command -v cmd &>/dev/null     # Check command exists  
cmd || true                    # Allow failure
```

**CRITICAL**: Never use `local` inside subshells `( ... ) &`

### Dockerfile

- Chinese comments: `# 第N步：描述`
- Minimize layers: chain with `&&`
- Clean in same layer: `&& rm -rf /var/lib/apt/lists/*`

### JSON Configuration

- 2-space indentation
- Use `$schema` when available
- No trailing commas

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

## IPC Architecture (v4.0)

Per-port IPC for multi-window support:

| File | Purpose |
|------|---------|
| `ipc/<port>/open_url` | URL to open in browser |
| `ipc/<port>/notifications` | Desktop notifications |
| `ipc/<port>/clipboard` | Clipboard sync |
| `ipc/<port>/.watcher.pid` | Watcher process PID (for cleanup) |

**Watcher Management**: Each port manages its own watcher via PID file. Never use global `pkill`.

## CLI Reference

```bash
# Production
ocd                      # Auto-detect workspace, auto port
ocd -p 5000              # Custom port
ocd --here               # Mount only current directory
ocd --clean              # Regenerate config
ocd --https              # Enable Tailscale HTTPS
ocd --awake              # Prevent Mac sleep
ocd --quotio             # Enable Quotio provider
ocd -r                   # Rebuild image + clear cache
ocd -v                   # Show version

# Development (testing OCD itself)
devocd                   # Direct dev mode (preferred)
devocd -r                # Rebuild dev image
ocd --dev                # Dev mode via main ocd
ocd --dev-root ~/fork    # Custom dev directory
```

**`devocd` vs `ocd --dev`**:
- `devocd`: Directly executes `dev/bin/ocd` (preferred for dev work)
- `ocd --dev`: Loads main `bin/ocd`, then sources `dev/lib/*.sh`
  - Changes to `dev/bin/ocd` WON'T take effect (uses main's bin/ocd)
  - Only useful if devocd is not in PATH (rare)

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying shell scripts
3. **Env file format**: No quotes, no export, no comments
4. **OAuth fails**: Ensure `--network host` is used
5. **Port conflict**: `rm ~/.config/opencode/.port.lock`
6. **Watcher issues**: Check `~/.local/state/opencode/ipc/<port>/.watcher.pid`

## Testing Workflow

```bash
# 1. Modify code in /workspace/dev
# 2. Syntax check: bash -n bin/ocd lib/*.sh
# 3. Run tests: bats tests/bats/*.bats
# 4. Manual test: exit container -> exec zsh -> devocd
```
