# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)**: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. `/workspace/bin/ocd` = `~/opencode/bin/ocd`.

## Design Philosophy (v4.0)

### Core Principle: Follow OpenCode Native Behavior

OCD is a **thin Docker wrapper** around OpenCode. It should NOT introduce its own concepts that conflict with OpenCode's native behavior.

**OpenCode's Project Identification**:
- Uses **git root commit SHA** as project ID
- Sessions stored in `~/.local/share/opencode/storage/session/<sha>/`
- WebUI switches projects via `?directory=` query param
- Non-git directories fall back to `"global"` project ID

**OCD's Role**:
- Containerize OpenCode with proper mounts
- Provide macOS integration (clipboard, notifications, URL opening)
- Handle port allocation for multi-window support
- **NOT** manage project/session isolation (let OpenCode do it)

### Removed Concepts (v4.0)

| Removed | Reason |
|---------|--------|
| `instance` | Conflicts with OpenCode's git-SHA-based project ID |
| `-n <name>` | No longer needed without instance concept |
| `-w <path>` | Use `--here` or cd to target directory |
| `--purge` | No instance to purge |

### Key Design Decisions

1. **Single shared storage** - All containers share `~/.local/share/opencode/storage/`
2. **OpenCode manages sessions** - By git SHA, not by OCD instance name
3. **IPC by port** - Multi-window support via `~/.local/state/opencode/ipc/<port>/`
4. **`--here` for isolation** - When you need to mount only current directory

## Build & Validation Commands

```bash
# Docker
docker build -t opencode-bun .                    # Build image
docker build --no-cache -t opencode-bun .         # Full rebuild
ocd -r                                            # Rebuild + clear cache

# Shell validation
bash -n bin/ocd lib/*.sh                          # Syntax check
shellcheck bin/ocd lib/*.sh                       # Lint (if available)

# JSON validation
jq . ~/.config/opencode/opencode.json             # Validate config

# Test container
docker run -it --rm --network host opencode-bun bash
```

## File Structure

```
~/opencode/
├── bin/
│   └── ocd                           # Main entry script
├── lib/
│   ├── core.sh                       # Core utils, XDG paths, logging
│   ├── port.sh                       # Port allocation, lock mechanism
│   ├── workspace.sh                  # Workspace detection
│   ├── watcher.sh                    # IPC monitoring (clipboard/notify/URL)
│   ├── config.sh                     # Config generation
│   └── docker.sh                     # Docker build & run
├── Dockerfile                        # Container image
├── .env                              # API keys (KEY=VALUE only!)
├── .ocdrc                            # Local config (workspace whitelist)

# Runtime directories (auto-created on Mac host)
~/.config/opencode/                   # Config (single, shared)
├── opencode.json                     # Main config
├── oh-my-opencode.json               # Plugin config
├── skill/                            # Global skills
├── command/                          # Global commands
└── agent/                            # Global agents

~/.local/share/opencode/              # Data (OpenCode native structure)
├── storage/                          # Sessions, messages (by git SHA)
│   ├── session/<git-sha>/
│   ├── message/
│   └── part/
├── auth.json                         # OAuth tokens
└── bin/                              # Binaries

~/.local/state/opencode/              # State
└── ipc/<port>/                       # IPC files per port (multi-window)
    ├── open_url
    ├── notifications
    └── clipboard

~/.cache/opencode/                    # OpenCode cache
~/.cache/oh-my-opencode/              # Plugin cache (ast-grep, ripgrep)
```

**Config naming**: OpenCode = singular (`skill/`), Claude compat = plural (`skills/`)

## Code Style Guidelines

### Shell Script (bin/ocd, lib/*.sh)

```bash
# Formatting
- 2-space indentation
- [[ ]] for conditionals (not [ ])
- Quote variables: "$VAR"
- $() for command substitution

# Variables
local VAR_NAME="value"         # Local scope
CONSTANT_NAME="value"          # No local for constants
${VAR:-default}                # Default value

# Functions
_ocd_function_name() {
  local ARG="$1"
}

# Error handling
2>/dev/null                    # Redirect errors
command -v cmd &>/dev/null     # Check command exists
|| true                        # Allow failure
```

**NEVER**: Use `local` inside subshells `( ... ) &`

### Dockerfile

- Chinese comments: `# 第N步：描述`
- Minimize layers: chain with `&&`
- Clean in same layer: `&& rm -rf /var/lib/apt/lists/*`
- `ENV DEBIAN_FRONTEND=noninteractive` early

### JSON Configuration

- 2-space indentation, use `$schema` when available, no trailing commas

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

## Container Mounts (v4.0 Simplified)

| Host | Container | Purpose |
|------|-----------|---------|
| Workspace (detected or `--here`) | `/workspace` | Project files |
| `~/.config/opencode/` | `/root/.config/opencode/` | Config (shared) |
| `~/.local/share/opencode/` | `/root/.local/share/opencode/` | Data (shared) |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | State |
| `~/.cache/opencode/` | `/root/.cache/opencode/` | OpenCode cache |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | Plugin cache |
| `~/.ssh/` | `/root/.ssh/:ro` | SSH keys (read-only) |
| Project `.claude/` | `/root/.claude/` | Claude compat |

## IPC (Container → Mac)

IPC files are stored per-port for multi-window support:
- **Path**: `~/.local/state/opencode/ipc/<port>/`
- **Notifications**: `notify "Title" "Message"` → `notifications` file
- **URLs**: writes to `open_url` → host watcher calls `open`
- **Clipboard**: writes to `clipboard` → host watcher calls `pbcopy`

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying shell scripts
3. **Env file format**: No quotes, no export, no comments
4. **OAuth fails**: Ensure `--network host` is used
5. **Skills not loading**: Check directory naming (singular vs plural)
6. **Port conflict**: `rm ~/.config/opencode/.port.lock`
7. **MCP connection issues**: Check `~/.cache/opencode/` is mounted (plugin cache)

## Testing Workflow

```bash
# 1. Modify files in /workspace
# 2. Exit container: exit
# 3. Reload shell: exec zsh
# 4. Restart: ocd
# 5. Verify: ls -la /root/.config/opencode/
```

## CLI Reference (v4.0)

```bash
ocd                         # Auto-detect workspace, auto port
ocd -p 5000                 # Custom port
ocd --here                  # Mount only current directory (no workspace detection)
ocd --https                 # Enable HTTPS via Tailscale Serve
ocd --awake                 # Prevent Mac from sleeping
ocd --quotio                # Enable Quotio provider
ocd -r                      # Rebuild image + clear cache
ocd -v                      # Show version
ocd --clean                 # Clear config (regenerate on next run)
ocd --dev                   # Development mode (from dev/ directory)
ocd -r --dev                # Rebuild development image
ocd --dev-root ~/fork       # Use custom development directory
```

### Removed Parameters (v4.0)

| Parameter | Replacement |
|-----------|-------------|
| `-n <name>` | Removed - OpenCode uses git SHA |
| `-w <path>` | Use `cd <path> && ocd` or `--here` |
| `--purge` | Removed - use `rm -rf ~/.local/share/opencode/storage/` manually |
| `--keep` | Removed - config is always preserved |

### Development Mode

Used for testing OCD itself (developer use):

```bash
# 1. Set up dev branch (using git worktree)
cd ~/opencode
git worktree add dev dev

# 2. Modify code in dev/
cd ~/opencode/dev
nano lib/docker.sh

# 3. Launch with dev version
ocd --dev

# 4. Rebuild dev image (after Dockerfile changes)
ocd -r --dev

# 5. Use custom path
ocd --dev-root ~/code/ocd-fork
ocd --dev-root=~/code/ocd-fork  # equals style also works
```

**Dev mode features**:
- Uses separate image `opencode-bun-dev` (doesn't pollute production image)
- Loads `dev/.env` first (if exists), otherwise falls back to main `.env`
- Startup shows `[DEV]` label and dev directory path

## Workspace Detection

OCD automatically detects workspace by walking up from current directory:

1. Find `.git` directory → use its **parent** as workspace
2. If no `.git` found → use current directory
3. With `--here` → always use current directory (skip detection)

**Example**:
```bash
cd ~/projects/webapp/src/components
ocd
# Detects ~/projects/webapp/.git
# Mounts ~/projects/ as /workspace
# Starts in /workspace/webapp/src/components
```

## Workspace Whitelist (.ocdrc)

```bash
# ~/opencode/.ocdrc - reloaded on every ocd invocation
OCD_ALLOWED_WORKSPACES="$HOME/opencode:$HOME/projects"
```

When set, OCD blocks access to directories not in the whitelist.
Use `--here` to bypass. Supports `$HOME` and `~` expansion.

## Migration from v3.x

If you have existing v3.x instance data:

```bash
# Run migration script
~/opencode/scripts/migrate-v4.sh

# Or manually merge (sessions will be accessible after migration)
# The migration merges all instance storage into shared storage
```

## OpenCode + oh-my-opencode Compatibility

OCD is fully compatible with:
- **OpenCode** - Native project detection via git SHA
- **oh-my-opencode** - Plugin uses directory markers, not OCD instances
- **WebUI** - Project switching via `?directory=` works correctly

| Component | Project Detection | Storage |
|-----------|-------------------|---------|
| OpenCode TUI | git root commit SHA | `storage/session/<sha>/` |
| OpenCode WebUI | Same (via header/query) | Same |
| oh-my-opencode | Directory markers (.git, package.json) | User-level config |
| OCD | Delegates to OpenCode | Shared storage |
