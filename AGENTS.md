# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)**: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. `/workspace/opencode.sh` = `~/opencode/opencode.sh`.

## Build & Validation Commands

```bash
# Docker
docker build -t opencode-bun .                    # Build image
docker build --no-cache -t opencode-bun .         # Full rebuild
ocd -r                                            # Rebuild + reset config
ocd -r --keep                                     # Rebuild + keep config

# Shell validation
bash -n opencode.sh                               # Syntax check
zsh -n opencode.sh                                # Zsh syntax check
shellcheck opencode.sh                            # Lint (if available)

# JSON validation
jq . ~/.config/opencode/opencode.json             # Validate config

# Test container
docker run -it --rm --network host opencode-bun bash
```

## File Structure

```
~/opencode/
├── opencode.sh                       # Main shell function (ocd command)
├── Dockerfile                        # Container image
├── .env                              # API keys (KEY=VALUE only!)
├── .ocdrc                            # Local config (workspace whitelist)
├── global/
│   ├── opencode/{skill,command,agent}/   # Global OpenCode config
│   └── claude/{skills,settings.json}     # Claude compat config

# Runtime directories (auto-created on Mac host)
~/.config/opencode/<instance>/        # Instance config (persisted)
~/.cache/opencode/                    # Plugin cache (shared)
```

**Config naming**: OpenCode = singular (`skill/`), Claude compat = plural (`skills/`)

## Code Style Guidelines

### Shell Script (opencode.sh)

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

## Container Mounts

| Host | Container | Purpose |
|------|-----------|---------|
| `$(pwd)` or workspace | `/workspace` | Project files |
| `~/.config/opencode/<instance>` | `/root/.config/opencode` | Instance config (full dir) |
| `~/.cache/opencode` | `/root/.cache/opencode` | Plugin cache |
| `~/.opencode_data/<instance>` | `/root/.opencode` | IPC (notifications, URLs) |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | UI settings (KV store) |
| `~/opencode/global/opencode/` | `/root/.config/opencode/{skill,command,agent}` | Global config |
| `~/opencode/global/claude/` | `/root/.claude/` | Claude compat |

**Mount order matters**: Instance config dir mounted first, then global subdirs overlay.

## IPC (Container → Mac)

- **Notifications**: `notify "Title" "Message"` → `/root/.opencode/notifications`
- **URLs**: writes to `/root/.opencode/open_url` → host watcher calls `open`
- **Clipboard**: writes to `/root/.opencode/clipboard` → host watcher calls `pbcopy`

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying `opencode.sh`
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

## CLI Reference

```bash
ocd                         # Auto: instance = dir name, port = auto
ocd -n myapp                # Custom instance name
ocd -p 5000                 # Custom port
ocd -w ~/projects           # Specify workspace directory
ocd --here                  # Mount only current directory (no workspace detection)
ocd --https                 # Enable HTTPS via Tailscale Serve
ocd --awake                 # Prevent Mac from sleeping
ocd --quotio                # Enable Quotio provider
ocd -r                      # Rebuild image + reset config
ocd -r --keep               # Rebuild image + keep config
ocd -v                      # Show version
```

## Workspace Whitelist (.ocdrc)

```bash
# ~/opencode/.ocdrc - reloaded on every ocd invocation
OCD_ALLOWED_WORKSPACES="$HOME/opencode:$HOME/projects"
```

When set, OCD blocks access to directories not in the whitelist.
Use `--here` or `-w` to bypass. Supports `$HOME` and `~` expansion.
