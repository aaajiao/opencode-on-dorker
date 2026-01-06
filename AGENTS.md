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
- Editing `/workspace/global/` = Editing `~/opencode/global/`

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
jq . ~/opencode/global/claude/settings.json       # Hooks config
jq . ~/opencode/global/claude/.mcp.json           # MCP config
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
~/opencode/                           # Config repo (also a project itself)
│
│  ── This project's own config ──
│
├── .opencode/                        # OpenCode native (this project)
│   ├── skill/
│   ├── command/
│   └── agent/
│
├── .claude/                          # Claude compat (this project)
│   ├── todos/                        # Session data for opencode instance
│   └── transcripts/
│
│  ── Global config (applies to all projects) ──
│
├── global/
│   ├── opencode/                     # OpenCode native global config
│   │   ├── skill/
│   │   ├── command/
│   │   └── agent/
│   │
│   └── claude/                       # Claude compat global config
│       ├── skills/
│       ├── commands/
│       ├── agents/
│       ├── rules/
│       ├── settings.json             # Hooks
│       └── .mcp.json                 # MCP servers
│
│  ── Project files ──
│
├── Dockerfile
├── docker-compose.yml
├── opencode.sh
├── .env
└── README.md

~/my-project/                         # Other projects
├── .opencode/                        # OpenCode native (this project)
│   ├── skill/
│   ├── command/
│   └── agent/
│
├── .claude/                          # Claude compat (this project)
│   ├── todos/                        # Session data for this project
│   └── transcripts/
│
└── ... (source code)
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

**Global config mounts:**

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `~/opencode/global/opencode/skill/` | `/root/.config/opencode/skill/` | Global skills (OpenCode native) |
| `~/opencode/global/opencode/command/` | `/root/.config/opencode/command/` | Global commands (OpenCode native) |
| `~/opencode/global/opencode/agent/` | `/root/.config/opencode/agent/` | Global agents (OpenCode native) |
| `~/opencode/global/claude/` | `/root/.claude/` | Claude compat global config |

**Session data mounts (overlay on `/root/.claude/`):**

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `<project>/.claude/todos/` | `/root/.claude/todos/` | Project's todo list |
| `<project>/.claude/transcripts/` | `/root/.claude/transcripts/` | Project's session history |

> **Note**: Session data is isolated per project. Each project's `.claude/todos/` and `.claude/transcripts/` are mounted as overlays on `/root/.claude/`.

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
   - Claude compat: `~/opencode/global/claude/skills/` (plural)
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
