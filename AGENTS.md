# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

**OCD (OpenCode Docker)**: macOS + OrbStack environment for OpenCode AI with oh-my-opencode plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

**CRITICAL**: This repo IS `~/opencode` on Mac. Editing `/workspace/opencode.sh` = editing `~/opencode/opencode.sh`.

## Build & Validation Commands

```bash
# Docker
docker build -t opencode-bun .                    # Build image
docker build --no-cache -t opencode-bun .         # Full rebuild
ocd -r                                            # Rebuild + reset config
ocd -r --keep                                     # Rebuild + keep config

# Shell script validation
bash -n opencode.sh                               # Syntax check
zsh -n opencode.sh                                # Zsh syntax check
shellcheck opencode.sh                            # Lint (if available)

# JSON validation
jq . ~/.config/opencode/opencode.json             # OpenCode config
jq . ~/.config/opencode/oh-my-opencode.json       # Plugin config

# Test container
docker run -it --rm --network host opencode-bun bash
notify "Test" "Hello"                             # Test notification
```

## File Structure

**Two config systems with different naming**:
- **OpenCode Native**: singular (`skill/`, `command/`, `agent/`)
- **Claude Compat**: plural (`skills/`, `commands/`, `agents/`, `rules/`)

```
~/opencode/                           # This repo
├── opencode.sh                       # Main shell function (ocd command)
├── Dockerfile                        # Container image
├── .env                              # API keys (KEY=VALUE only)
├── VERSION                           # Version number
│
├── global/
│   ├── opencode/                     # Global config (singular dirs)
│   │   ├── skill/
│   │   ├── command/
│   │   └── agent/                    # github.md, opencode-config.md
│   │
│   └── claude/                       # Claude compat (plural dirs)
│       ├── skills/remind/SKILL.md
│       ├── settings.json
│       └── .mcp.json
│
├── scripts/
│   └── migrate-sessions.sh           # Session migration utility
│
└── .opencode/                        # This project's config
    ├── skill/
    ├── command/
    └── agent/

~/.config/opencode/<instance>/        # Runtime: instance config
~/.opencode_data/<instance>/          # Runtime: instance data (notifications, URLs)
~/.local/share/opencode/              # Runtime: shared auth, bin, storage
```

## Code Style Guidelines

### Shell Script (opencode.sh)

**Formatting**:
- 2-space indentation
- `[[ ]]` for conditionals (not `[ ]`)
- Quote all variables: `"$VAR"`
- `$()` for command substitution (not backticks)

**Variables**:
```bash
local VAR_NAME="value"         # Local scope
CONSTANT_NAME="value"          # No local for constants
${VAR:-default}                # Default value syntax
# NEVER use `local` inside subshells ( ... ) &
```

**Functions**:
```bash
_ocd_function_name() {
  local ARG="$1"
  # implementation
}
```

**Error Handling**:
```bash
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
- Double quotes for strings

### Environment Variables (.env)

**CRITICAL**: Pure `KEY=VALUE` format only
```bash
# WRONG
export API_KEY="sk-xxx"        # No export
API_KEY="value"                # No quotes
KEY=value # comment            # No comments

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
| `~/opencode/global/opencode/` | `/root/.config/opencode/{skill,command,agent}` | Global OpenCode config |
| `~/opencode/global/claude/` | `/root/.claude/` | Global Claude config |
| `<project>/.claude/{todos,transcripts}` | `/root/.claude/{todos,transcripts}` | Session data overlay |

### Notification System
```bash
# Container side
notify "Title" "Message"       # Writes to /root/.opencode/notifications

# Host side watches file and calls terminal-notifier or osascript
```

### URL Redirection
- Container writes to `/root/.opencode/open_url`
- Host watcher calls `open` command

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying `opencode.sh`
3. **Env file format**: No quotes, no export, no comments
4. **OAuth fails**: Ensure `--network host` is used
5. **Skills not loading**: Check directory naming (singular vs plural)
6. **Port conflict**: Lock mechanism handles this, but if stuck: `rm ~/.config/opencode/.port.lock`

## Testing Workflow

```bash
# 1. Modify files in /workspace
# 2. Exit container
exit
# 3. Reload shell
exec zsh
# 4. Restart
ocd
# 5. Verify
ls -la /root/.claude/
```

## Multi-Instance Commands

```bash
ocd                         # Auto: instance = dir name, port = auto
ocd -n myapp                # Custom instance name
ocd -p 5000                 # Custom port
ocd --quotio                # Enable Quotio provider
ocd -v                      # Show version
```
