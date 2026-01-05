# AGENTS.md

Guidelines for AI coding agents working on this repository.

## Project Overview

OpenCode Docker environment for macOS + OrbStack. Runs OpenCode AI assistant with oh-my-opencode multi-agent collaboration plugin.

**Tech Stack**: Docker, Shell (bash/zsh), JSON configuration

## Build & Validation Commands

### Docker Image

```bash
# Build image
docker build -t opencode-bun .

# Build with no cache (full rebuild)
docker build --no-cache -t opencode-bun .

# Using opencode.sh function
opencode -r  # Rebuild image + reset config
```

### Validate Shell Script

```bash
# Syntax check
zsh -n opencode.sh
bash -n opencode.sh

# ShellCheck (if available)
shellcheck opencode.sh
```

### Validate Dockerfile

```bash
# Lint with hadolint (if available)
hadolint Dockerfile

# Test build
docker build -t opencode-bun:test .
```

### Validate JSON Config

```bash
# Check JSON syntax
jq . ~/.config/opencode/opencode.json
jq . ~/.config/opencode/oh-my-opencode.json
```

### Test Container

```bash
# Run container interactively
docker run -it --rm --network host opencode-bun bash

# Test notification mechanism
echo "Test|Hello" >> ~/.opencode_data/notifications
```

## File Structure

```
├── Dockerfile           # Docker image (oven/bun base)
├── docker-compose.yml   # Docker Compose config (host network)
├── opencode.sh          # Shell function for ~/.zshrc
├── env.example          # Environment variable template
├── ghostty-128.png      # Notification icon
├── README.md            # User documentation
├── CLAUDE.md            # Claude Code guidance
└── AGENTS.md            # This file
```

## Code Style Guidelines

### Shell Script (opencode.sh)

**Formatting**:
- 2-space indentation
- Use `[[ ]]` for conditionals (not `[ ]`)
- Quote all variable expansions: `"$VAR"` not `$VAR`
- Use `$()` for command substitution (not backticks)

**Variables**:
- Local variables: `local VAR_NAME="value"`
- Constants: `UPPER_CASE` (no `local`)
- Use `:-` for defaults: `${VAR:-default}`
- NEVER use `local` inside subshells `( ... ) &`

**Error Handling**:
- Redirect errors: `2>/dev/null` or `2>&1`
- Check command existence: `command -v cmd &>/dev/null`
- Use `|| true` for optional failures

**Comments**:
- Chinese comments are acceptable (project is bilingual)
- Use `# ===` separators for major sections

**Example**:
```bash
local CONFIG_FILE="$HOME/.config/opencode/opencode.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Generating config..."
fi
```

### Dockerfile

**Structure**:
- Group related commands with comments
- Use numbered steps: `# Step N:` or `# 第N步：`
- Minimize layers: chain commands with `&&`
- Clean up in same layer: `&& rm -rf /var/lib/apt/lists/*`

**Environment**:
- Set `ENV DEBIAN_FRONTEND=noninteractive` early
- Define PATH incrementally: `ENV PATH="/new/path:$PATH"`

**Scripts**:
- Use `echo '...' > /path/script` for inline scripts
- Always `chmod +x` after creating scripts

### JSON Configuration

**Format**:
- 2-space indentation
- Use `$schema` when available
- No trailing commas
- Double quotes for all strings

### Environment Variables (.env)

**CRITICAL**: Must be pure `KEY=VALUE` format
- NO `export` keyword
- NO quotes around values
- NO inline comments
- NO spaces around `=`

```bash
# WRONG
export API_KEY="sk-xxx"

# CORRECT
API_KEY=sk-xxx
```

## Key Implementation Details

### URL Redirection (Container to Mac)
- Container writes to `/root/.opencode/open_url`
- Host's `opencode.sh` watches file, calls `open` command
- Custom `xdg-open` script in Dockerfile handles this

### Notification System
- Container writes to `/root/.opencode/notifications`
- Format: `TITLE|MESSAGE`
- Host uses `terminal-notifier` (with fallback to `osascript`)
- Icon displayed via `-contentImage` (right side small image)

### Background Process Pattern
```bash
(
    while true; do
        # ... watch files ...
        sleep 0.5
    done
) &
local WATCHER_PID=$!
disown $WATCHER_PID 2>/dev/null  # Prevent SIGHUP on shell exit
```

### Network Mode
- Uses `--network host` for OAuth callback support
- Container shares Mac's localhost
- Access Web UI at `http://localhost:4096`

## Common Pitfalls

1. **`local` in subshell**: Don't use `local` inside `( ... ) &`
2. **Function not updating**: Run `exec zsh` after modifying `opencode.sh`
3. **Env file format**: No quotes, no export, no comments
4. **terminal-notifier `-sender`**: May cause notifications to hang
5. **OAuth fails**: Ensure `--network host` is used

## Git Workflow

```bash
# Sync local after remote changes
cd ~/opencode
git pull
exec zsh  # Reload shell function

# Create PR for changes
git checkout -b feature/my-change
git add -A
git commit -m "feat: description"
git push -u origin feature/my-change
gh pr create --title "feat: ..." --body "..."
```

## Testing Changes

1. Modify files locally
2. Exit container: `exit`
3. Reload shell: `exec zsh`
4. Restart: `opencode`
5. Test notification: Container sends `notify "Title" "Message"`
