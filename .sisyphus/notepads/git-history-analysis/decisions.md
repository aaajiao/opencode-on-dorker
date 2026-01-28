# Architectural Decisions & Rationales

## Decision 1: Naming Duality (Singular vs Plural)

**Decision**: Support both singular (OpenCode) and plural (Claude) naming conventions simultaneously

**Rationale**:
- OpenCode native system uses singular: `agent/`, `command/`, `skill/`
- Claude Code compatibility requires plural: `agents/`, `commands/`, `skills/`
- Both systems coexist in `.opencode/` and `.claude/` directories
- Allows users to choose their preferred system

**Introduced**: v2.0 (Jan 6, 2025) - Commit `2eb1249`

**Trade-offs**:
- ✅ Flexibility: Users can use either system
- ✅ Compatibility: Works with both OpenCode and Claude Code
- ❌ Confusion: New users may not understand why both exist
- ❌ Maintenance: Two naming systems to document and support

**Status**: ACCEPTED - Intentional design, not a bug

**Future Consideration**: Document this clearly in AGENTS.md to prevent confusion

---

## Decision 2: Template System as Source of Truth

**Decision**: Move from hardcoded config generation to template-based system

**Rationale**:
- Centralize config structure in `templates/` directory
- Support variable substitution via `versions.lock`
- Enable easy customization without code changes
- Separate concerns: templates vs logic

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Template Naming Convention**:
- `.tmpl` — Processed by OCD, variables replaced
- `.example` — User reference, manually copied
- No suffix — Direct copy, no processing

**Trade-offs**:
- ✅ Flexibility: Easy to customize without code changes
- ✅ Maintainability: Single source of truth
- ✅ Scalability: Easy to add new config types
- ❌ Complexity: Template processing adds overhead
- ❌ Learning curve: Users need to understand template system

**Status**: ACCEPTED - Core v5.0 architecture

**Future Consideration**: Add template schema versioning to `versions.lock`

---

## Decision 3: User-Owned Configs (v5.0)

**Decision**: Create configs once from templates, then user-managed. OCD only updates port on startup.

**Rationale**:
- v4 regenerated configs on every startup, losing user modifications
- v5 respects user customizations
- Only port number changes on each startup (necessary for multi-window support)
- Users can manually reset with `ocd --clean`

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**BREAKING CHANGE**: Config generation behavior fundamentally changed

**Trade-offs**:
- ✅ User control: Modifications persist
- ✅ Stability: Config doesn't change unexpectedly
- ✅ Flexibility: Users can customize without worrying about overwrites
- ❌ Migration: Requires migration from v4 to v5
- ❌ Reset: Users must use `--clean` to regenerate

**Status**: ACCEPTED - Core v5.0 philosophy

**Migration Path**: Automatic via `lib/migrate.sh` with backup

---

## Decision 4: Automatic Global Config Migration, Manual Project-Level

**Decision**: Automate global config migration (v4→v5), but leave project-level configs manual

**Rationale**:
- Global config is centralized, easy to migrate automatically
- Project-level configs are scattered, harder to discover
- Users may have custom project configs they don't want overwritten
- Manual migration gives users control

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Implementation**:
- `lib/migrate.sh` provides `ocd_check_migration()` function
- Detects v4.x config and backs up to `backup-v4/`
- Creates new v5.0 config from templates
- Triggered on first run

**Trade-offs**:
- ✅ Convenience: Global config auto-migrated
- ✅ Safety: Backups created before migration
- ✅ Control: Project-level configs not touched
- ❌ Inconsistency: Global and project-level handled differently
- ❌ Manual work: Users must migrate project configs themselves

**Status**: ACCEPTED - Pragmatic balance between automation and control

**Future Consideration**: Add `ocd_migrate_project_configs()` for automated project migration

---

## Decision 5: Lowercase Agent Keys (v3.1.4)

**Decision**: Standardize agent keys to lowercase in oh-my-opencode.json

**Rationale**:
- oh-my-opencode v3.1.4 requires lowercase keys
- Consistency with JSON naming conventions
- Easier to work with in shell scripts (no case sensitivity issues)

**Introduced**: v3.1.4 (Jan 28, 2026) - Commit `edc9370`

**Changes**:
- Agent keys: `"Sisyphus"` → `"sisyphus"`, `"Oracle"` → `"oracle"`
- Environment variables: `PLANNER_MODEL` → `SISYPHUS_MODEL`
- New agents added: prometheus, metis, momus, atlas, sisyphus-junior

**Trade-offs**:
- ✅ Consistency: All keys lowercase
- ✅ Compatibility: Required by oh-my-opencode v3.1.4
- ✅ Simplicity: Easier to work with in scripts
- ❌ Migration: Existing configs need updating
- ❌ Silent failures: Uppercase keys fail without error message

**Status**: ACCEPTED - Required by oh-my-opencode v3.1.4

**Migration Gap**: No automated migration provided (HIGH PRIORITY FIX)

---

## Decision 6: Template Consolidation

**Decision**: Move global extensions from `global/` to `templates/global/opencode/`

**Rationale**:
- Centralize all templates in `templates/` directory
- Simplify directory structure
- Make it clear what's a template vs runtime config
- Easier to manage and version

**Introduced**: v5.0+ (Jan 12, 2025) - Commit `816b006`

**Changes**:
- Move `agent/`, `skill/` from `global/` to `templates/global/opencode/`
- Delete unused `global/claude/` directory
- Update `ocd_ensure_global_config()` to copy from templates

**Trade-offs**:
- ✅ Organization: All templates in one place
- ✅ Clarity: Clear distinction between templates and runtime
- ✅ Maintainability: Easier to manage
- ❌ Complexity: More nested directory structure
- ❌ Migration: Requires updating config generation logic

**Status**: ACCEPTED - Improves organization

---

## Decision 7: Separate Dev Config Directory

**Decision**: Use `~/.config/opencode-dev/` for development mode instead of `~/.config/opencode/`

**Rationale**:
- Prevent dev changes from affecting production
- Allow testing without impacting user's main setup
- Enable parallel dev and production instances

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Implementation**:
- `devocd` uses `~/.config/opencode-dev/`
- `devocd` uses `opencode-bun-dev` image
- Separate state directory: `~/.local/state/opencode-dev/`

**Trade-offs**:
- ✅ Isolation: Dev doesn't affect production
- ✅ Testing: Can test changes safely
- ✅ Parallel: Can run dev and production simultaneously
- ❌ Duplication: Two config directories to manage
- ❌ Complexity: More setup for developers

**Status**: ACCEPTED - Essential for development workflow

---

## Decision 8: Port-Only Updates on Startup

**Decision**: Only update port number on each startup, leave other config unchanged

**Rationale**:
- Supports multi-window mode (different ports for different instances)
- Respects user customizations
- Minimal startup overhead
- Clear separation of concerns

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Implementation**:
- `ocd_update_port()` function in `lib/config.sh`
- Called on every startup
- Only modifies port field in config

**Trade-offs**:
- ✅ Efficiency: Minimal startup work
- ✅ Stability: Config doesn't change unexpectedly
- ✅ Multi-window: Supports multiple instances
- ❌ Complexity: Port management logic needed
- ❌ Locking: Requires port locking mechanism

**Status**: ACCEPTED - Core to multi-window support

---

## Decision 9: Backup Before Reset

**Decision**: Create backup before resetting config with `--clean`

**Rationale**:
- Prevent accidental data loss
- Allow recovery if reset goes wrong
- Give users confidence to use `--clean`

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Implementation**:
- `ocd_reset_global_config()` creates `backup-v4/` directory
- Backs up entire `~/.config/opencode/` directory
- Then regenerates from templates

**Trade-offs**:
- ✅ Safety: Prevents data loss
- ✅ Recovery: Users can restore if needed
- ✅ Confidence: Users feel safe using `--clean`
- ❌ Disk space: Backups accumulate over time
- ❌ Cleanup: Users must manually delete old backups

**Status**: ACCEPTED - Good safety practice

**Future Consideration**: Implement backup rotation (keep only last N backups)

---

## Decision 10: Template Variable Substitution

**Decision**: Use `{{VAR}}` syntax for template variables, sourced from `versions.lock`

**Rationale**:
- Centralize version management in `versions.lock`
- Support dynamic config generation
- Easy to update versions without editing templates
- Clear syntax that's easy to understand

**Introduced**: v5.0 (Jan 11, 2025) - Commit `510a96e`

**Implementation**:
- `.tmpl` files contain `{{VAR_NAME}}` placeholders
- `ocd_ensure_global_config()` reads `versions.lock`
- Substitutes variables before writing config

**Trade-offs**:
- ✅ Flexibility: Easy to update versions
- ✅ Centralization: Single source of truth for versions
- ✅ Clarity: Clear syntax
- ❌ Complexity: Template processing logic needed
- ❌ Debugging: Harder to debug template issues

**Status**: ACCEPTED - Core to template system

---

## Summary of Architectural Principles

1. **User Ownership**: Configs created once, then user-managed
2. **Minimal Intervention**: OCD only updates what's necessary (port)
3. **Template-Driven**: All config structure defined in templates
4. **Backward Compatibility**: Old configs backed up, not deleted
5. **Flexibility**: Support both OpenCode and Claude systems
6. **Safety**: Backups created before destructive operations
7. **Isolation**: Dev and production configs separate
8. **Centralization**: Versions and templates in one place

---

## Decisions Pending Review

1. **Should agent keys be validated on startup?**
   - Currently no validation, silent failures possible
   - Recommendation: Add validation to catch misconfigured keys

2. **Should project-level configs auto-migrate?**
   - Currently manual, could be automated
   - Recommendation: Add `ocd_migrate_project_configs()` function

3. **Should template schema version be tracked?**
   - Currently no version tracking
   - Recommendation: Add `TEMPLATE_SCHEMA_VERSION` to `versions.lock`

4. **Should backups be timestamped or versioned?**
   - Currently versioned (backup-v4), could be timestamped
   - Recommendation: Use timestamp-based backups for clarity
