# lib/ - Shell Modules

Core shell library for OCD. 8 modules, ~1,913 lines total.

*For code style and anti-patterns, see root [AGENTS.md](../AGENTS.md#code-style-guidelines).*

## Module Map

| Module | Lines | Depends On | Purpose |
|--------|-------|------------|---------|
| `core.sh` | 161 | - | Base utilities, XDG paths, logging |
| `port.sh` | 68 | core | Port allocation with file locking |
| `workspace.sh` | 127 | core | Git repo detection, path resolution |
| `config.sh` | 498 | core, workspace | v5 config lifecycle, templates |
| `docker.sh` | 153 | core, config | Image build, container run |
| `scan.sh` | 335 | core, workspace | Project discovery, registration |
| `watcher.sh` | 146 | core | IPC file monitoring (fswatch) |
| `migrate.sh` | 88 | core, config | v4→v5 migration |

## Load Order (in bin/ocd)

```bash
source "$OCD_ROOT/lib/core.sh"
source "$OCD_ROOT/lib/port.sh"
source "$OCD_ROOT/lib/workspace.sh"
source "$OCD_ROOT/lib/watcher.sh"
source "$OCD_ROOT/lib/config.sh"
source "$OCD_ROOT/lib/docker.sh"
[[ -f "$OCD_ROOT/lib/migrate.sh" ]] && source "$OCD_ROOT/lib/migrate.sh"
```

## Key Functions by Module

### core.sh (base utilities)
| Function | Purpose |
|----------|---------|
| `ocd_log`, `ocd_error`, `ocd_info`, `ocd_success` | Logging with emojis |
| `ocd_debug` | Controlled by `OCD_DEBUG=1` |
| `ocd_load_env` | Safe .env loading (rejects dangerous chars) |
| `ocd_load_versions` | Load versions.lock as env vars |
| `ocd_sanitize_name` | Clean names for container/image |
| `ocd_version` | Read VERSION file |
| `ocd_check_dependencies` | Verify jq, fswatch installed |

### config.sh (largest - v5 config lifecycle)
| Function | Purpose |
|----------|---------|
| `ocd_ensure_global_config` | Create from template (first run) or skip |
| `ocd_update_port` | Update port only (preserves user changes) |
| `ocd_init_project` | Create project-level config from templates |
| `ocd_apply_models_conf` | Apply models.conf overrides |
| `ocd_reset_global_config` | Backup + regenerate (--clean) |
| `ocd_create_config_from_template` | {{VAR}} substitution from versions.lock |
| `ocd_show_welcome_if_first_run` | Display paths on first use |

### scan.sh (project management)
| Function | Purpose |
|----------|---------|
| `ocd_scan` | Discover git repos in workspace |
| `ocd_register_project` | Write project JSON to storage |
| `ocd_touch` | Update project timestamp for WebUI |
| `ocd_cleanup_duplicates` | Remove duplicate project records |
| `ocd_get_storage_dir` | Return project storage path |

### docker.sh (container operations)
| Function | Purpose |
|----------|---------|
| `ocd_build_image` | Build with version args from versions.lock |
| `ocd_run_container` | Run with mounts, env, start dir |
| `ocd_get_mount_args` | Generate -v mount arguments |
| `ocd_image_exists` | Check if image exists |
| `ocd_remove_image` | Remove image for rebuild |

### watcher.sh (IPC monitoring)
| Function | Purpose |
|----------|---------|
| `ocd_start_watcher` | Start fswatch on IPC directory |
| `ocd_handle_url` | Open URLs in Mac browser |
| `ocd_handle_notify` | Send macOS notifications |
| `ocd_handle_clipboard` | Sync to Mac clipboard |
| `ocd_ipc_dir` | Return IPC directory for port |

### workspace.sh (git/path detection)
| Function | Purpose |
|----------|---------|
| `ocd_find_workspace_root` | Walk up to find .git parent |
| `ocd_find_project_dir` | Find current project in workspace |
| `ocd_get_relative_path` | Convert absolute to relative |
| `ocd_validate_workspace` | Check against whitelist |

### port.sh (allocation)
| Function | Purpose |
|----------|---------|
| `ocd_find_free_port` | Find available port with atomic locking |

### migrate.sh (v4→v5)
| Function | Purpose |
|----------|---------|
| `ocd_check_migration` | Detect v4 config, backup + migrate |
| `ocd_check_claude_migration` | Migrate Claude global storage |

## XDG Directories (from core.sh)

| Variable | Default | Purpose |
|----------|---------|---------|
| `OCD_CONFIG_HOME` | `~/.config/opencode` | User-owned config |
| `OCD_DATA_HOME` | `~/.local/share/opencode` | Persistent data |
| `OCD_STATE_HOME` | `~/.local/state/opencode` | Runtime state |
| `OCD_CACHE_HOME` | `~/.cache/opencode` | Ephemeral cache |
| `OCD_CLAUDE_HOME` | `~/.claude` | Global Claude (read-only) |
| `OCD_CLAUDE_RUNTIME` | `$OCD_STATE_HOME/claude` | Claude runtime (writable) |
| `OCD_IPC_HOME` | `$OCD_STATE_HOME/ipc` | Per-port IPC files |

## Module Conventions

- **Naming**: `ocd_` (public), `_ocd_` (private)
- **Globals**: Prefix with `OCD_` or `_OCD_`
- **Returns**: Use `echo` for values, return codes for status
- **Errors**: `ocd_error "msg"` then `return 1`
- **SC2155**: Always `local var; var=$(cmd)` — never `local var=$(cmd)`

## Adding a New Module

1. Create `lib/newmodule.sh`
2. Add `source` line in `bin/ocd` (respect dependency order)
3. Create `tests/bats/newmodule.bats`
4. Update CODE MAP in root `AGENTS.md`
5. Update this file's Module Map table
