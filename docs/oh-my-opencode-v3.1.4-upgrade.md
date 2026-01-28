# Oh-My-OpenCode v3.1.4 Upgrade Guide

**Upgrade Path**: v2.14.0 → v3.1.4  
**Date**: 2026-01-28  
**Type**: Major Version Upgrade

---

## Overview

This document covers the upgrade of oh-my-opencode from v2.14.0 to v3.1.4 in OCD (OpenCode Docker).

| Item | Before | After |
|------|--------|-------|
| Version | 2.14.0 | 3.1.4 |
| Commits | - | +647 |
| Breaking Changes | - | 6 |

---

## Breaking Changes (v3.0.0)

### 1. Agent Keys Lowercase

All agent keys must be lowercase in v3.0+.

```diff
- "Sisyphus": { "model": "..." }
+ "sisyphus": { "model": "..." }
```

### 2. Removed Agents

The following agents were **removed** in v3.0:

| Agent | Status | Replacement |
|-------|--------|-------------|
| `frontend-ui-ux-engineer` | Removed | Use `categories.visual-engineering` |
| `document-writer` | Removed | Use `categories.writing` |

### 3. Agent Rename

| Old Name | New Name |
|----------|----------|
| `orchestrator-sisyphus` | `atlas` |

### 4. Removed Hooks

These hooks were removed (auto-filtered, no action needed):
- `preemptive-compaction`
- `empty-message-sanitizer`

### 5. Tool Parameter Changes

The `delegate_task` API was renamed. This is auto-migrated internally.

### 6. Model System Changes

v3.0+ uses fallback chains for model resolution. Direct model specification still works but the resolution algorithm changed.

---

## New Features

### New Agents (v3.0+)

| Agent | Purpose | Default Model |
|-------|---------|---------------|
| `prometheus` | Planning agent | claude-opus-4-5 |
| `metis` | Code intelligence | claude-opus-4-5 |
| `momus` | Code review | gpt-5.2 |
| `atlas` | Advanced orchestration | claude-sonnet-4-5 |
| `sisyphus-junior` | Lightweight orchestration | claude-sonnet-4-5 |

### New Configuration Options

#### Tmux Integration
Multi-pane orchestration for background agents.

```json
"tmux": {
  "enabled": false,
  "layout": "main-vertical",
  "main_pane_size": 60
}
```

#### Ralph Loop
Iterative task execution.

```json
"ralph_loop": {
  "enabled": false,
  "default_max_iterations": 100
}
```

#### Sisyphus Tasks & Swarm
Task management and multi-agent swarm systems.

```json
"sisyphus": {
  "tasks": { "enabled": false },
  "swarm": { "enabled": false }
}
```

#### Dynamic Context Pruning (Experimental)
Automatic context window optimization.

```json
"experimental": {
  "dynamic_context_pruning": { "enabled": false }
}
```

#### Browser Automation Engine
Choose browser automation provider.

```json
"browser_automation_engine": {
  "provider": "playwright"  // or "agent-browser", "dev-browser"
}
```

#### Auto Update
Enable/disable automatic update checking.

```json
"auto_update": true
```

### New Agent Features

- **Extended Thinking**: Anthropic Claude extended thinking support
- **Reasoning Effort**: OpenAI o1 reasoning levels (`low`, `medium`, `high`, `xhigh`)
- **Text Verbosity**: Control output verbosity
- **Per-command Bash Permissions**: Fine-grained bash command control
- **Category Inheritance**: Agents can inherit settings from categories

---

## Configuration Changes

### Old Template (`v2.14.0`)

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "agents": {
    "Sisyphus": { "model": "opencode/claude-opus-4-5" },
    "oracle": { "model": "opencode/gpt-5.2" },
    "librarian": { "model": "opencode/claude-haiku-4-5" },
    "explore": { "model": "opencode/grok-code" },
    "frontend-ui-ux-engineer": { "model": "opencode/gemini-3-pro" },
    "document-writer": { "model": "opencode/gemini-3-flash" },
    "multimodal-looker": { "model": "opencode/gemini-3-flash" }
  }
}
```

### New Template (`v3.1.4`)

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",

  "agents": {
    "sisyphus": { "model": "opencode/claude-opus-4-5" },
    "oracle": { "model": "opencode/gpt-5.2" },
    "librarian": { "model": "opencode/claude-haiku-4-5" },
    "explore": { "model": "opencode/grok-code" },
    "multimodal-looker": { "model": "opencode/gemini-3-flash" },
    "prometheus": { "model": "opencode/claude-opus-4-5" },
    "metis": { "model": "opencode/claude-opus-4-5" },
    "momus": { "model": "opencode/gpt-5.2" },
    "atlas": { "model": "opencode/claude-sonnet-4-5" },
    "sisyphus-junior": { "model": "opencode/claude-sonnet-4-5" }
  },

  "tmux": {
    "enabled": false,
    "layout": "main-vertical",
    "main_pane_size": 60
  },

  "ralph_loop": {
    "enabled": false,
    "default_max_iterations": 100
  },

  "sisyphus": {
    "tasks": {
      "enabled": false
    },
    "swarm": {
      "enabled": false
    }
  },

  "experimental": {
    "dynamic_context_pruning": {
      "enabled": false
    }
  },

  "browser_automation_engine": {
    "provider": "playwright"
  },

  "auto_update": true
}
```

### Change Summary

| Item | Old | New |
|------|-----|-----|
| `Sisyphus` | Uppercase | `sisyphus` lowercase |
| `frontend-ui-ux-engineer` | Present | Removed |
| `document-writer` | Present | Removed |
| `prometheus` | - | Added |
| `metis` | - | Added |
| `momus` | - | Added |
| `atlas` | - | Added |
| `sisyphus-junior` | - | Added |
| `tmux` | - | Added (disabled) |
| `ralph_loop` | - | Added (disabled) |
| `sisyphus.tasks/swarm` | - | Added (disabled) |
| `experimental` | - | Added (disabled) |
| `browser_automation_engine` | - | Added (playwright) |
| `auto_update` | - | Added (true) |

---

## Files Modified

### 1. `versions.lock`

```diff
- OH_MY_OPENCODE_VERSION=2.14.0
+ OH_MY_OPENCODE_VERSION=3.1.4
```

### 2. `templates/global/oh-my-opencode.json`

Replaced with new v3.1.4 template (see Configuration Changes section).

### 3. `models.conf` and `models.conf.example`

- Renamed `PLANNER_MODEL` → `SISYPHUS_MODEL`
- Removed `DOCUMENT_WRITER_MODEL`, `FRONTEND_MODEL` (agents removed in v3.0)
- Added new agent models: `PROMETHEUS_MODEL`, `METIS_MODEL`, `MOMUS_MODEL`, `ATLAS_MODEL`, `SISYPHUS_JUNIOR_MODEL`

### 4. `lib/config.sh`

- Updated `ocd_update_omo_agents()` to use lowercase agent keys
- Removed references to removed agents
- Added `ocd_ensure_provider_cache()` for Docker cache seeding

### 5. `bin/ocd`

- Added `ocd_ensure_provider_cache` call during startup

### 6. `server/init.sh`

- Added provider cache seeding for server mode

### 7. `tests/bats/config.bats`

- Added tests for `ocd_ensure_provider_cache()`

---

## OCD-Specific Fixes

### Provider Cache Auto-Seeding

v3.1.4 added a "Provider Cache Missing" warning that appears when `~/.cache/oh-my-opencode/connected-providers.json` doesn't exist. In Docker environments, this cache file is never auto-created by oh-my-opencode.

**OCD Fix**: OCD now auto-creates this cache file on startup:
- `lib/config.sh`: Added `ocd_ensure_provider_cache()` function
- `bin/ocd`: Calls the function during startup
- `server/init.sh`: Seeds cache for server mode

This fix is transparent - users won't see the warning anymore.

---

## User Upgrade Instructions

### For Existing Users

After pulling the updated OCD:

```bash
# Step 1: Clear npm/bun cache
rm -rf ~/.cache/opencode/node_modules ~/.cache/opencode/bun.lock

# Step 2: Reset config (backup + regenerate)
ocd --clean

# Step 3: Start OCD (downloads new plugin version)
ocd
```

### For New Users

No special action needed. Just run `ocd` as normal.

---

## Verification

After upgrade, verify:

1. **Plugin version**: Check startup message shows `oh-my-opencode@3.1.4`
2. **Agents available**: All 10 agents should be accessible
3. **No config errors**: No schema validation warnings

---

## Rollback

If issues occur, rollback by:

1. Revert `versions.lock`:
   ```bash
   OH_MY_OPENCODE_VERSION=2.14.0
   ```

2. Reset config:
   ```bash
   ocd --clean
   ```

---

## References

- [oh-my-opencode v3.1.4 Release](https://github.com/code-yeongyu/oh-my-opencode/releases/tag/v3.1.4)
- [oh-my-opencode Repository](https://github.com/code-yeongyu/oh-my-opencode)
- [Configuration Schema](https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json)

---

## Changelog

### v3.1.4 (2026-01-28)
- Provider Cache Warning Toast
- npm global install version detection fix
- Model Resolver fallback chain fix
- Config Schema: added `dev-browser` provider

### v3.1.0 - v3.1.3
- Browser automation (agent-browser, dev-browser)
- Tmux integration
- Enhanced plan agent
- Server mode with custom port/hostname
- Parallel delegation support

### v3.0.0
- **BREAKING**: Agent keys lowercase
- **BREAKING**: Removed `frontend-ui-ux-engineer`, `document-writer`
- **BREAKING**: Renamed `orchestrator-sisyphus` to `atlas`
- New: Prometheus agent
- New: Model fallback chains
- New: Background task cancellation
- New: Case-insensitive agent matching
