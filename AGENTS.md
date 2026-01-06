# AGENTS.md

Guidelines for AI coding agents working on this repository.

## Project Overview

OpenCode Docker environment for macOS + OrbStack. Runs OpenCode AI assistant with oh-my-opencode multi-agent collaboration plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

## ⚠️ Critical: Workspace = ~/opencode

**This repository IS the `~/opencode` folder on Mac.**

When running inside the container:
- `/workspace` = `~/opencode` (Mac host)
- Editing `/workspace/opencode.sh` = Editing `~/opencode/opencode.sh`
- Editing `/workspace/claude_home/` = Editing `~/opencode/claude_home/`

This is NOT a typical project where `/workspace` is mounted from some other directory. The workspace IS the opencode configuration folder itself.

## Build & Validation Commands

### Docker Image

```bash
docker build -t opencode-bun .                    # Build image
docker build --no-cache -t opencode-bun .         # Full rebuild
ocd -r                                            # Rebuild + reset config
ocd -r --keep                                     # Rebuild + keep config
```

### Validate Shell Script

```bash
bash -n opencode.sh                               # Syntax check
zsh -n opencode.sh                                # Zsh syntax check
shellcheck opencode.sh                            # Lint (if available)
```

### Validate JSON

```bash
jq . ~/.config/opencode/opencode.json             # OpenCode config
jq . ~/.config/opencode/oh-my-opencode.json       # Plugin config
jq . ~/opencode/claude_home/settings.json         # Hooks config
jq . ~/opencode/claude_home/.mcp.json             # MCP config
```

### Test Container

```bash
docker run -it --rm --network host opencode-bun bash
notify "Test" "Hello"                             # Test notification
```

## File Structure

**IMPORTANT**: Two config systems exist with different naming conventions:
- **OpenCode Native**: singular dirs (`skill/`, `command/`, `agent/`)
- **Claude Compatibility**: plural dirs (`skills/`, `commands/`, `agents/`, `rules/`)

```
~/opencode/
├── Dockerfile              # Docker image (oven/bun base)
├── docker-compose.yml      # Docker Compose config
├── opencode.sh             # Shell function (ocd command)
├── env.example             # Environment variable template
├── ghostty-128.png         # Notification icon
├── claude_home/            # Claude compatibility layer (plural dirs, user-level)
│   ├── skills/             # Custom skills (plural = Claude compat)
│   ├── commands/           # Slash commands (plural = Claude compat)
│   ├── agents/             # Custom agents (plural = Claude compat)
│   ├── rules/              # Conditional rules (Claude compat only)
│   ├── settings.json       # Hooks configuration
│   └── .mcp.json           # MCP servers
├── instances/<name>/claude/ # Per-instance data
│   ├── todos/              # Session todos
│   └── transcripts/        # Session history
└── README.md

~/.config/opencode/         # OpenCode native global config (singular dirs)
├── skill/                  # Global skills (singular = OpenCode native)
├── command/                # Global commands (singular = OpenCode native)
└── agent/                  # Global agents (singular = OpenCode native)

<project>/
├── .opencode/              # OpenCode native project config (singular dirs)
│   ├── skill/
│   ├── command/
│   └── agent/
└── .claude/                # Claude compatibility project config (plural dirs)
    ├── skills/
    ├── commands/
    ├── agents/
    └── rules/
```

## Code Style Guidelines

### Shell Script (opencode.sh)

**Formatting**:
- 2-space indentation
- Use `[[ ]]` for conditionals (not `[ ]`)
- Quote all variables: `"$VAR"` not `$VAR`
- Use `$()` for command substitution (not backticks)

**Variables**:
- Local variables: `local VAR_NAME="value"`
- Constants: `UPPER_CASE` (no `local`)
- Defaults: `${VAR:-default}`
- NEVER use `local` inside subshells `( ... ) &`

**Functions**:
```bash
_ocd_function_name() {
  local ARG="$1"
  # implementation
}
```

**Error Handling**:
- Redirect errors: `2>/dev/null` or `2>&1`
- Check existence: `command -v cmd &>/dev/null`
- Optional failures: `|| true`

### Dockerfile

- Group commands with Chinese comments: `# 第N步：描述`
- Minimize layers: chain with `&&`
- Clean up in same layer: `&& rm -rf /var/lib/apt/lists/*`
- Set `ENV DEBIAN_FRONTEND=noninteractive` early

### JSON Configuration

- 2-space indentation
- Use `$schema` when available
- No trailing commas
- Double quotes for all strings

### Environment Variables (.env)

**CRITICAL**: Pure `KEY=VALUE` format only
```bash
# WRONG
export API_KEY="sk-xxx"

# CORRECT
API_KEY=sk-xxx
```

## Key Architecture

### Mount Points (Container ↔ Host)

**Common mounts (all instances):**

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `$(pwd)` | `/workspace` | Project files |
| `~/.opencode_data/<instance>` | `/root/.opencode` | Instance data |
| `~/.config/opencode/<instance>` | `/root/.config/opencode` | Instance config |
| `~/opencode/claude_home` | `/root/.claude` | Claude compatibility |

**Todos/Transcripts mounts (differ by directory):**

| Running From | Host Path | Container Path |
|--------------|-----------|----------------|
| `~/opencode/` | `~/opencode/claude_home/todos/` | `/root/.claude/todos/` |
| `~/opencode/` | `~/opencode/claude_home/transcripts/` | `/root/.claude/transcripts/` |
| Other dirs | `~/opencode/instances/<name>/claude/todos/` | `/root/.claude/todos/` |
| Other dirs | `~/opencode/instances/<name>/claude/transcripts/` | `/root/.claude/transcripts/` |

> **Note**: When running from `~/opencode/`, there is NO separate `instances/opencode/` directory - it uses `claude_home/` directly.

### URL Redirection (Container → Mac)
- Container writes to `/root/.opencode/open_url`
- Host watcher calls `open` command

### Notification System
- Container: `notify "Title" "Message"`
- Writes to `/root/.opencode/notifications` (format: `TITLE|MSG`)
- Host uses `terminal-notifier` or `osascript`

### Background Watcher Pattern
```bash
(
    while true; do
        # watch files
        sleep 0.5
    done
) &
WATCHER_PID=$!
disown $WATCHER_PID 2>/dev/null
```

## Common Pitfalls

1. **`local` in subshell**: Never use inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying `opencode.sh`
3. **Env file format**: No quotes, no export, no comments
4. **OAuth fails**: Ensure `--network host` is used
5. **Skills not loading**: Check directory naming (singular vs plural)
   - OpenCode native: `~/.config/opencode/skill/` (singular)
   - Claude compat: `~/opencode/claude_home/skills/` (plural)
6. **Wrong directory name**: OpenCode native uses singular, Claude compat uses plural

## Testing Workflow

1. Modify files in `/workspace`
2. Exit container: `exit`
3. Reload shell: `exec zsh`
4. Restart: `ocd`
5. Verify: `ls -la /root/.claude/`

## Git Workflow

```bash
git checkout -b feature/description
git add -A
git commit -m "feat: description"
git push -u origin feature/description
gh pr create --title "feat: ..." --body "..."
```

## Multi-Instance Support

```bash
ocd                         # Instance = current dir name, auto port
ocd -n myapp                # Custom instance name
ocd -p 5000                 # Custom port
ocd --quotio                # Enable Quotio provider
```

## /remind - Task Completion Notification

Send macOS notification when task completes:
```
/remind              # Default notification
/remind 部署完成      # Custom message
```

Rules:
1. Remember user requested reminder
2. Execute task normally
3. On completion: `notify "OpenCode" "任务已完成"`
4. On failure: notify with error reason
