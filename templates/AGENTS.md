# templates/ - Configuration Templates

Template system for OCD v5. First-run config generation + project initialization.

## Directory Structure

```
templates/
├── global/                 # Applied on first ocd run
│   ├── opencode.json.tmpl  # .tmpl = {{VAR}} substitution
│   ├── oh-my-opencode.json # Direct copy (no processing)
│   └── opencode/           # Global extensions
│       ├── agents/github.md # @github agent
│       ├── commands/        # Global commands
│       └── skills/remind/   # Notification skill
└── project/                # Reference for ocd init
    ├── AGENTS.md.example   # .example = user reference
    ├── opencode.json.example
    ├── .mcp.json.example.claude
    ├── .opencode/          # Project OpenCode config
    └── .claude/            # Project Claude Code config
```

## File Naming Convention (CRITICAL)

| Extension | Processing | Purpose |
|-----------|-----------|---------|
| `.tmpl` | OCD substitutes `{{VAR}}` from `versions.lock` | Version-locked configs |
| `.example` | No processing, user copies manually | Reference templates |
| (none) | Direct copy, no modification | Static configs |

## Template Variable Substitution

**In template** (`opencode.json.tmpl`):
```json
"plugin": ["oh-my-opencode@{{OH_MY_OPENCODE_VERSION}}"]
```

**In versions.lock**:
```bash
OH_MY_OPENCODE_VERSION=2.14.0
```

**After substitution**:
```json
"plugin": ["oh-my-opencode@2.14.0"]
```

**Fallback**: If variable not found → replaced with `"latest"`

## Configuration Lifecycle

### First Run (`ocd` with no existing config)

1. `ocd_ensure_global_config()` detects missing config
2. Creates `~/.config/opencode/opencode.json` from `global/opencode.json.tmpl`
3. Copies `global/oh-my-opencode.json` directly
4. Copies `global/opencode/` extensions to `~/.config/opencode/`
5. Shows welcome message with config paths

### Subsequent Runs

1. Config already exists → skip template creation
2. Only updates port number via `ocd_update_port()`
3. User modifications are **preserved forever**

### Reset (`ocd --clean`)

1. Backs up to `~/.config/opencode/backup-v5-TIMESTAMP/`
2. Deletes current config
3. Regenerates from templates (fresh start)

## Global Templates (templates/global/)

### opencode.json.tmpl
Main OpenCode configuration. Variables used:
- `{{OH_MY_OPENCODE_VERSION}}` - oh-my-opencode plugin version
- `{{PLAYWRIGHT_MCP_VERSION}}` - Playwright MCP server version

### oh-my-opencode.json
Plugin configuration with agent models. Copied directly (no variables).

### opencode/agents/github.md
Global `@github` agent for Git workflow automation.

### opencode/skills/remind/SKILL.md
Notification skill for macOS desktop notifications.

## Project Templates (templates/project/)

Used by `ocd init` command. All are `.example` files for user reference.

### Directory Structure Created by `ocd init`

```
<project>/
├── AGENTS.md              # From AGENTS.md.example
├── opencode.json.example  # Reference (user copies to opencode.json)
├── .mcp.json.example.claude
├── .opencode/
│   ├── oh-my-opencode.json.example
│   ├── agents/
│   ├── commands/
│   ├── skills/
│   └── plugins/
└── .claude/
    ├── settings.json.example
    ├── agents/
    ├── commands/
    ├── skills/
    └── rules/
```

## Adding a New MCP Server

1. Add version to `versions.lock`:
   ```bash
   MY_MCP_VERSION=1.2.3
   ```

2. Add to `templates/global/opencode.json.tmpl`:
   ```json
   "my-mcp": {
     "command": ["npx", "my-mcp@{{MY_MCP_VERSION}}"],
     "enabled": true
   }
   ```

3. Run `ocd --clean` to regenerate config

## Adding a Global Agent

1. Create `templates/global/opencode/agents/myagent.md`
2. Agent will be copied to `~/.config/opencode/agents/` on next `ocd --clean`

## Adding a Global Skill

1. Create `templates/global/opencode/skills/myskill/SKILL.md`
2. Skill will be copied to `~/.config/opencode/skills/` on next `ocd --clean`

## Anti-Patterns

- **DON'T** edit `~/.config/opencode/` files via templates (user-owned)
- **DON'T** add `.tmpl` extension to files that don't need substitution
- **DON'T** hardcode versions in templates (use `{{VAR}}` + versions.lock)
