# Issues & Blockers Found

## Critical Issues

### 1. No Automated Migration for Agent Key Case Changes (v3.1.4)
**Severity**: HIGH
**Status**: Unresolved

**Problem**:
- Agent keys changed from PascalCase to lowercase in v3.1.4
- Example: `"Sisyphus"` → `"sisyphus"`, `"Oracle"` → `"oracle"`
- No automated migration provided for existing configs
- Users with manually edited `oh-my-opencode.json` will have broken configs

**Evidence**:
- Commit `edc9370` upgraded oh-my-opencode to v3.1.4
- Commit `989661a` only updated tests, not config migration
- No function in `lib/config.sh` to handle case conversion

**Impact**:
- Users upgrading from v3.0 to v3.1.4 may have broken agent references
- Manual fix required: Update all agent keys to lowercase

**Recommendation**:
Add `ocd_migrate_agent_keys()` function to `lib/config.sh`:
```bash
ocd_migrate_agent_keys() {
  local config_file="$1"
  # Convert "Sisyphus" → "sisyphus", "Oracle" → "oracle", etc.
  jq '.agents |= with_entries(.key |= ascii_downcase)' "$config_file"
}
```

---

### 2. No Automated Migration for Project-Level Configs
**Severity**: MEDIUM
**Status**: Unresolved

**Problem**:
- `lib/migrate.sh` only handles global config migration
- Project-level `.opencode/` and `.claude/` configs are not migrated
- Users with multiple projects must manually update each one

**Evidence**:
- `ocd_check_migration()` in `lib/migrate.sh` only checks `~/.config/opencode/`
- No function to scan and migrate project-level configs
- Documentation doesn't mention project-level migration

**Impact**:
- Users with many projects face manual work
- Inconsistent state across projects

**Recommendation**:
Add `ocd_migrate_project_configs()` function:
```bash
ocd_migrate_project_configs() {
  # Scan workspace for .opencode/ and .claude/ directories
  # Apply same migrations as global config
}
```

---

### 3. Naming Duality Not Documented
**Severity**: MEDIUM
**Status**: Unresolved

**Problem**:
- Singular vs plural naming (OpenCode vs Claude) is not explained in AGENTS.md
- New users may think it's a bug or inconsistency
- No rationale provided for why both systems coexist

**Evidence**:
- AGENTS.md mentions both `.opencode/` and `.claude/` but doesn't explain naming difference
- Commit messages don't explain the design decision
- No documentation of "intentional duality"

**Impact**:
- User confusion about correct directory names
- Potential for incorrect config creation

**Recommendation**:
Add section to AGENTS.md:
```markdown
## Directory Naming Convention

### Why Singular vs Plural?

- **OpenCode system** (`.opencode/`): Uses singular naming (`agent/`, `command/`, `skill/`)
  - Represents individual extensibility points
  - Native OpenCode convention
  
- **Claude system** (`.claude/`): Uses plural naming (`agents/`, `commands/`, `skills/`)
  - Matches Claude Code conventions
  - For Claude Code compatibility

Both systems are supported simultaneously for flexibility.
```

---

## Medium Issues

### 4. Template Naming Inconsistency
**Severity**: MEDIUM
**Status**: Unresolved

**Problem**:
- `.tmpl` files use variable substitution
- `.example` files are user references
- Some files have no suffix (direct copy)
- No clear convention documented

**Evidence**:
- `templates/global/opencode.json.tmpl` - has variables
- `templates/project/opencode.json.example` - user reference
- `templates/global/oh-my-opencode.json` - direct copy (no suffix)

**Impact**:
- Unclear which files are processed vs copied
- Potential for incorrect template handling

**Recommendation**:
Document in AGENTS.md:
```markdown
### Template File Naming

- `.tmpl` — Processed by OCD, `{{VAR}}` replaced from versions.lock
- `.example` — User reference, manually copied if needed
- No suffix — Direct copy, no processing
```

---

### 5. Migration Documentation Gaps
**Severity**: MEDIUM
**Status**: Unresolved

**Problem**:
- No comprehensive migration guide for v1 → v2
- v2 → v5 migration documented but scattered
- v3.x → v3.1.4 migration not documented

**Evidence**:
- Commit `2eb1249` says "Run migration manually: move claude_home/* to global/claude/"
- No migration guide in docs/
- README mentions v4→v5 migration but not earlier versions

**Impact**:
- Users upgrading from old versions may miss steps
- Potential for broken configs

**Recommendation**:
Create `docs/MIGRATION_GUIDE.md` with:
- v1 → v2: Move `claude_home/` to `global/claude/`
- v2 → v5: Automatic via `lib/migrate.sh`
- v3.x → v3.1.4: Update agent keys to lowercase

---

## Low Issues

### 6. Backup Naming Could Be Clearer
**Severity**: LOW
**Status**: Unresolved

**Problem**:
- Backups created as `backup-v4/` but naming is inconsistent
- No clear pattern for future backups (v5, v6, etc.)

**Evidence**:
- Commit `510a96e` creates `~/.config/opencode/backup-v4/`
- No function to handle versioned backups

**Impact**:
- Multiple backups could accumulate
- Unclear which backup is which

**Recommendation**:
Use timestamp-based backups:
```bash
backup_dir="$config_dir/backup-$(date +%Y%m%d-%H%M%S)"
```

---

### 7. No Version Tracking for Templates
**Severity**: LOW
**Status**: Unresolved

**Problem**:
- No way to track template schema version
- Can't detect when templates need updating

**Evidence**:
- `versions.lock` tracks dependency versions, not template versions
- No schema version field in config files

**Impact**:
- Difficult to know when to regenerate configs
- No clear upgrade path for template changes

**Recommendation**:
Add `TEMPLATE_SCHEMA_VERSION` to `versions.lock`:
```
TEMPLATE_SCHEMA_VERSION=5.0.0
```

---

## Gotchas & Surprises

### 8. Agent Key Case Sensitivity
**Severity**: MEDIUM
**Status**: Known

**Problem**:
- oh-my-opencode v3.1.4 requires lowercase agent keys
- Uppercase keys silently fail (no error message)

**Evidence**:
- Commit `edc9370` changed all agent keys to lowercase
- Commit `989661a` updated tests but no error handling

**Impact**:
- Users with uppercase keys get silent failures
- Difficult to debug

**Recommendation**:
Add validation in `ocd_update_omo_agents()`:
```bash
# Validate agent keys are lowercase
jq '.agents | keys[] | select(. != ascii_downcase)' "$config_file" && \
  echo "ERROR: Agent keys must be lowercase" && return 1
```

---

### 9. Config Regeneration Behavior Changed
**Severity**: MEDIUM
**Status**: Known

**Problem**:
- v4 regenerated config on every startup
- v5 creates once, only updates port
- Users expecting old behavior may be confused

**Evidence**:
- Commit `510a96e` explicitly changed this behavior
- BREAKING CHANGE noted in commit message

**Impact**:
- User modifications now persist (good)
- But users can't easily reset to defaults (need `--clean`)

**Recommendation**:
Document in AGENTS.md:
```markdown
### Config Lifecycle (v5.0+)

- **First run**: Config created from templates
- **Subsequent runs**: Only port number updated
- **Reset**: Use `ocd --clean` to regenerate from templates
```

---

## Unresolved Questions

1. **Should agent keys be validated on startup?**
   - Currently no validation, silent failures possible

2. **Should project-level configs auto-migrate?**
   - Currently manual, could be automated

3. **Should template schema version be tracked?**
   - Currently no version tracking

4. **Should backups be timestamped or versioned?**
   - Currently versioned (backup-v4), could be timestamped

5. **Should `.example` files be auto-copied on `ocd init`?**
   - Currently user must manually copy
