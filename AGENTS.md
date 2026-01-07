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
jq . ~/.config/opencode/opencode.json             # OpenCode config

# Test container
docker run -it --rm --network host opencode-bun bash
```

## File Structure

**Two config systems** (different naming conventions):
- **OpenCode Native**: singular dirs (`skill/`, `command/`, `agent/`)
- **Claude Compat**: plural dirs (`skills/`, `commands/`, `agents/`, `rules/`)

```
~/opencode/
├── opencode.sh                       # Main shell function (ocd command)
├── Dockerfile                        # Container image
├── .env                              # API keys (KEY=VALUE only!)
├── VERSION
├── global/
│   ├── opencode/{skill,command,agent}/   # Global OpenCode config
│   └── claude/{skills,settings.json,.mcp.json}  # Global Claude compat
├── scripts/migrate-sessions.sh
└── .opencode/{skill,command,agent}/  # Project-level config

# Runtime directories (auto-created)
~/.config/opencode/<instance>/        # Instance config
~/.opencode_data/<instance>/          # Instance data
~/.local/share/opencode/              # Shared auth, bin, storage
~/.local/state/opencode/              # KV store (UI settings persistence)
~/.cache/oh-my-opencode/              # Binary cache (ast-grep, ripgrep)
```

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
# NEVER use `local` inside subshells ( ... ) &

# Functions
_ocd_function_name() {
  local ARG="$1"
}

# Error handling
2>/dev/null                    # Redirect errors
command -v cmd &>/dev/null     # Check command exists
|| true                        # Allow failure
```

### Dockerfile

- Chinese comments: `# 第N步：描述`
- Minimize layers: chain with `&&`
- Clean in same layer: `&& rm -rf /var/lib/apt/lists/*`
- `ENV DEBIAN_FRONTEND=noninteractive` early

### JSON Configuration

- 2-space indentation
- Use `$schema` when available
- No trailing commas

### Environment Variables (.env)

**CRITICAL**: Pure `KEY=VALUE` format only - no export, no quotes, no comments
```bash
# WRONG
export API_KEY="sk-xxx"
KEY=value # comment

# CORRECT
API_KEY=sk-xxx
GITHUB_TOKEN=ghp_xxxx
```

## Key Architecture

### Container Mounts

| Host | Container | Purpose |
|------|-----------|---------|
| `$(pwd)` | `/workspace` | Project files |
| `~/.opencode_data/<instance>` | `/root/.opencode` | Instance data |
| `~/.config/opencode/<instance>` | `/root/.config/opencode` | Instance config |
| `~/.local/state/opencode/` | `/root/.local/state/opencode/` | UI 设置持久化 (KV store) |
| `~/.cache/oh-my-opencode/` | `/root/.cache/oh-my-opencode/` | ast-grep/ripgrep 二进制缓存 |
| `~/opencode/global/opencode/` | `/root/.config/opencode/{skill,command,agent}` | Global config |
| `~/opencode/global/claude/` | `/root/.claude/` | Claude compat config |

### IPC (Container → Mac)
- **Notifications**: `notify "Title" "Message"` → writes to `/root/.opencode/notifications`
- **URLs**: writes to `/root/.opencode/open_url` → host watcher calls `open`

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying `opencode.sh`
3. **Env file format**: No quotes, no export, no comments
4. **OAuth fails**: Ensure `--network host` is used
5. **Skills not loading**: Check directory naming (singular vs plural)
6. **Port conflict**: `rm ~/.config/opencode/.port.lock`

## Testing Workflow

```bash
# 1. Modify files in /workspace
# 2. Exit container: exit
# 3. Reload shell: exec zsh
# 4. Restart: ocd
# 5. Verify: ls -la /root/.claude/
```

## Multi-Instance Commands

```bash
ocd                         # Auto: instance = dir name, port = auto
ocd -n myapp                # Custom instance name
ocd -p 5000                 # Custom port
ocd --quotio                # Enable Quotio provider
ocd -v                      # Show version
```
