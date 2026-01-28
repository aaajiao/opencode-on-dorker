# Learnings - OCD Plural Migration

## [2026-01-28T15:39:24] Plan Started

### Research Findings
- OpenCode 官方文档推荐复数形式 (`skills/`, `agents/`, `commands/`)
- oh-my-opencode PR #966 (2026-01-21) 已修复为复数形式
- 用户报告单数形式不工作 (Issue #810, #930, #1116)
- 社群共识：使用复数形式

### Key Decisions
- `plugin/` 也改为 `plugins/` (保持一致性)
- 冲突处理：合并内容到复数目录
- 版本号：v6.0.0 (破坏性变更)
- Claude 目录保持复数（已经正确）
- `themes/` 保持复数（已经正确）

---

## Version and Changelog Update (2026-01-28)

### Task Completed
- Updated `VERSION` file from `5.0.0` to `6.0.0`
- Added v6.0.0 section to `CHANGELOG.md` with breaking changes documentation

### CHANGELOG Format Observed
- Uses Keep a Changelog format with semantic versioning
- Date format: `YYYY-MM-DD`
- Section structure: Breaking Changes → Migration → Changed/Added/Fixed/Removed
- Chinese language used for user-facing content (consistent with existing entries)
- Code blocks use bash syntax highlighting
- Migration instructions include both automatic and manual approaches

### Key Content Added
1. **Breaking Changes section**: Documents directory naming change (singular → plural)
2. **Migration section**: 
   - Automatic migration process (3 steps)
   - Manual migration commands
   - Reference to migration script
3. **Changed section**: Lists affected components (templates, config.sh, migration logic)

### Verification
- `cat VERSION` confirms `6.0.0`
- `head -60 CHANGELOG.md` shows complete v6.0.0 section at top
- Format matches existing v5.0.0 entry structure
- All migration instructions align with implemented migration script


## Migration Script Pattern (v6-plural-dirs)

**Created**: `scripts/migrate-v6-plural-dirs.sh`

**Key Design Decisions**:
1. **Idempotent**: Uses marker file `.plural-dirs-migrated` to prevent re-running
2. **Safe backup**: Creates `.backup-singular-v5/` before any changes
3. **Conflict handling**: Merges content when both singular and plural dirs exist
4. **Dual scope**: Handles both global (`~/.config/opencode/`) and project (`.opencode/`) configs
5. **Associative array**: Uses `declare -A DIR_MAP` for clean mapping

**Directory Mappings**:
- `skill/` → `skills/`
- `agent/` → `agents/`
- `command/` → `commands/`
- `plugin/` → `plugins/`

**Merge Logic**:
- If plural dir exists: copy files from singular, skip duplicates (preserve plural version)
- If plural dir missing: simple rename
- Always backup singular dir before deletion

**Integration Points**:
- Sources `lib/core.sh` for logging functions (`ocd_log`, `ocd_info`, `ocd_success`, `ocd_error`)
- Uses `OCD_CONFIG_HOME` from core.sh
- Follows same pattern as `migrate-v5-global-claude.sh`

**Testing**:
- ✅ Syntax check: `bash -n` passed
- ⏭️ ShellCheck: Not available in container (run on Mac)
- ⏭️ Manual test: Needs real migration scenario

**Next Steps for Integration**:
- Add detection logic to `lib/migrate.sh` (similar to `ocd_check_claude_migration`)
- Call from `bin/ocd` startup sequence
- Add user prompt: "Detected singular directories, migrate now? [Y/n]"

## lib/docker.sh Line 97 Update

**Date**: 2026-01-28

**Change**: Updated directory creation from singular to plural
- Before: `mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}`
- After: `mkdir -p "$OCD_CONFIG_HOME"/{skills,commands,agents}`

**Verification**:
- ✅ Syntax check passed: `bash -n lib/docker.sh`
- ✅ No remaining singular references found
- ✅ Line 100 (Claude directories) already uses plural - no change needed
- ✅ Line 124 loop already uses plural - no change needed

**Pattern**: OpenCode config directories use plural names to match Claude convention

## server/init.sh Line 123 Update

**Date**: 2026-01-28

**Change**: Updated OpenCode directory creation from singular to plural
- Before: `mkdir -p "$GLOBAL_DIR/opencode"/{skill,command,agent}`
- After: `mkdir -p "$GLOBAL_DIR/opencode"/{skills,commands,agents}`

**Context**:
- Line 123: OpenCode directories (UPDATED)
- Line 124: Claude directories (already plural - no change needed)

**Verification**:
- ✅ Syntax check passed: `bash -n server/init.sh`
- ✅ ShellCheck: Not available in container (will run on Mac)
- ✅ Line 124 preserved: `mkdir -p "$GLOBAL_DIR/claude"/{skills,commands,agents,rules}`

**Pattern**: Server mode init script follows same plural convention as local mode

## Template Directory Rename (2026-01-28)

### Task Completed
- Renamed `templates/global/opencode/skill/` → `skills/`
- Renamed `templates/global/opencode/command/` → `commands/`
- Created `templates/global/opencode/agents/` (new empty directory)
- Renamed `templates/project/.opencode/skill/` → `skills/`
- Renamed `templates/project/.opencode/agent/` → `agents/`
- Renamed `templates/project/.opencode/command/` → `commands/`
- Renamed `templates/project/.opencode/plugin/` → `plugins/`

### Git Rename Detection Quirk
- Git's rename detection got confused with identical `.gitkeep` files
- Showed cross-directory renames (e.g., `project/.opencode/agent/.gitkeep` → `global/opencode/commands/.gitkeep`)
- This is cosmetic - actual file structure is correct
- All `.gitkeep` files are identical (0 bytes), so git matched them arbitrarily

### .gitignore Issue
- `.opencode/` is in `.gitignore` (line 8)
- Had to use `git add -f` to force-add `templates/project/.opencode/` subdirectories
- This is correct - we want to ignore user's `.opencode/` but track template `.opencode/`

### Verification
- ✅ `templates/global/opencode/` has `skills/`, `commands/`, `agents/`
- ✅ `templates/project/.opencode/` has `skills/`, `agents/`, `commands/`, `plugins/`
- ✅ `templates/global/opencode/skills/remind/SKILL.md` preserved
- ✅ All changes staged as renames (preserves git history)

### Next Steps
- Update `lib/config.sh` to reference plural directory names
- Update migration script to handle both singular and plural
- Test config generation with new directory structure

## lib/config.sh Migration (2026-01-28)

Successfully updated all directory references from singular to plural:

### Changes Made:
1. **Line 71**: `{agent,command,skill,themes}` → `{agents,commands,skills,themes}`
2. **Line 325**: `{agent,command,skill,plugin}` → `{agents,commands,skills,plugins}`
3. **Line 488**: `{skill,command,agent}` → `{skills,commands,agents}`
4. **Lines 95-128**: Updated template copy logic:
   - `template_opencode/agent` → `template_opencode/agents`
   - `template_opencode/skill` → `template_opencode/skills`
   - `template_opencode/command` → `template_opencode/commands`
   - `$config_dir/agent/` → `$config_dir/agents/`
   - `$config_dir/skill/` → `$config_dir/skills/`
   - `$config_dir/command/` → `$config_dir/commands/`
5. **Line 90**: Updated comment to reflect plural names

### Verification:
- ✅ `bash -n lib/config.sh` passes
- ✅ No remaining singular references (except in comments)
- ✅ All template paths use plural directories
- ✅ All destination paths use plural directories

### Pattern Observed:
The file had three main areas requiring updates:
1. Directory creation (`mkdir -p`)
2. Template source path checks (`if [[ -d "$template_opencode/..."]]`)
3. Destination path construction (`$config_dir/.../`)

All three areas needed consistent plural naming.

## Test Files Update (2026-01-28)

### Files Modified
- `tests/bats/config.bats` - Updated directory assertions
- `tests/bats/init.bats` - Updated directory assertions
- `tests/bats/docker.bats` - Updated setup mkdir command

### Changes Made
1. **config.bats**: Updated `ocd_ensure_global_config` test
   - `$OCD_CONFIG_HOME/agent` → `$OCD_CONFIG_HOME/agents`
   - `$OCD_CONFIG_HOME/command` → `$OCD_CONFIG_HOME/commands`
   - `$OCD_CONFIG_HOME/skill` → `$OCD_CONFIG_HOME/skills`

2. **init.bats**: Updated multiple tests
   - `ocd_init_global` test: skill/command/agent → skills/commands/agents
   - `ocd_init_project` test: .opencode subdirectories now plural
   - Added `plugins` directory (was `plugin`)

3. **docker.bats**: Updated setup function
   - `mkdir -p "$OCD_CONFIG_HOME"/{skill,command,agent}` → `{skills,commands,agents}`

### Verification
- ✅ No singular references remain: `skill/`, `agent/`, `command/`, `plugin/`
- ✅ All directory assertions use plural names
- ✅ Test descriptions unchanged (only path strings updated)
- ⚠️ BATS not available in container - tests must be run on Mac host

### Pattern Observed
Test files follow consistent pattern:
```bash
[ -d "$OCD_CONFIG_HOME/skills" ]
[ -d "$project/.opencode/agents" ]
[ -d "$project/.claude/commands" ]
```

All directory existence checks now use plural forms matching the actual implementation.

## lib/migrate.sh v6 Integration (2026-01-28)

### Task Completed
Added v6 migration detection to `ocd_check_migration()` function.

### Implementation Details:
1. **Marker file**: `$OCD_CONFIG_HOME/.ocd-v6-migrated`
2. **Detection logic**: Checks for existence of singular directories:
   - `skill/`, `agent/`, `command/`, `plugin/`
3. **User prompt**: Asks user to confirm migration (Y/n)
4. **Script invocation**: Calls `$OCD_ROOT/scripts/migrate-v6-plural-dirs.sh`
5. **Success marker**: Creates marker file only if migration succeeds (`$? -eq 0`)
6. **New install handling**: Creates marker immediately if no singular dirs found

### Integration Pattern:
- Follows same structure as `ocd_check_claude_migration()`
- Runs AFTER v5 migration check
- Non-blocking: user can skip and run manually later
- Idempotent: marker file prevents re-running

### Code Location:
- File: `lib/migrate.sh`
- Function: `ocd_check_migration()`
- Lines: 31-68 (v6 migration block)

### Verification:
- ✅ Syntax check passed: `bash -n lib/migrate.sh`
- ✅ Marker file logic: Only created after successful migration
- ✅ New install optimization: Skips detection if no singular dirs exist
- ✅ User experience: Clear prompt with directory mapping explanation

### Next Steps:
- Test with real v5 config (singular directories)
- Test with fresh install (no singular directories)
- Verify marker file prevents re-prompting
- Test manual skip flow (user chooses 'n')


## Documentation Update Patterns (2026-01-28)

### Files Updated (10 total)
1. `README.md` - Main documentation
2. `AGENTS.md` - Root agent guidelines  
3. `templates/AGENTS.md` - Template documentation
4. `docs/SKILL_DESIGN_PATTERNS.md` - Skill design guide
5. `docs/SKILL_QUICK_REFERENCE.md` - Quick reference
6. `docs/OPENCODE_CONFIG_GUIDE.md` - Config guide
7. `docs/OH_MY_OPENCODE_SKILL_SYSTEM.md` - Skill system docs
8. `docs/ARCHITECTURE.md` - Architecture docs
9. `server/README.md` - Server mode docs
10. `lib/AGENTS.md` - Lib module docs

### Common Update Patterns

**Directory structure trees:**
```markdown
# Before
├── skill/
├── agent/
├── command/
└── plugin/

# After
├── skills/
├── agents/
├── commands/
└── plugins/
```

**Path examples:**
```markdown
# Before
~/.config/opencode/skill/<name>/SKILL.md
.opencode/skill/<name>/SKILL.md
templates/global/opencode/skill/

# After
~/.config/opencode/skills/<name>/SKILL.md
.opencode/skills/<name>/SKILL.md
templates/global/opencode/skills/
```

**Code blocks and commands:**
```markdown
# Before
mkdir ~/.config/opencode/skill/my-skill
nano ~/.config/opencode/skill/my-skill/SKILL.md

# After
mkdir ~/.config/opencode/skills/my-skill
nano ~/.config/opencode/skills/my-skill/SKILL.md
```

### Verification Results

**Singular references removed:**
- `.opencode/skill/` → 0 matches
- `.opencode/agent/` → 0 matches
- `.opencode/command/` → 0 matches
- `.opencode/plugin/` → 0 matches
- `/opencode/skill/` → 0 matches
- `/opencode/agent/` → 0 matches
- `/opencode/command/` → 0 matches

**Plural references present:**
- `.opencode/skills/` → 9 matches
- `.opencode/agents/` → 2 matches
- `.opencode/commands/` → 1 match
- `config/opencode/skills/` → 12 matches
- `config/opencode/agents/` → 2 matches
- `config/opencode/commands/` → 1 match

### Unchanged References (Correct)

**Claude directories (already plural):**
- `~/.claude/skills/` ✅
- `.claude/skills/` ✅
- `.claude/agents/` ✅
- `.claude/commands/` ✅
- `.claude/rules/` ✅

**Other directories (already plural):**
- `themes/` ✅
- `templates/` ✅

### Key Insights

1. **Consistency is critical**: All documentation must use the same directory naming convention
2. **Directory trees are common**: Many docs show file structure diagrams that need updating
3. **Path examples are everywhere**: Code blocks, command examples, and inline paths all need updates
4. **Verification is essential**: Use grep to confirm all singular references are removed
5. **Preserve existing plurals**: Claude directories were already correct and should not be changed

### Tools Used

- `read` - Read each file to understand context
- `edit` - Update directory names (28 successful edits)
- `grep` - Search for remaining singular references
- `bash` - Verify changes with grep and wc

### Success Metrics

- ✅ All 10 documentation files updated
- ✅ All singular directory references removed
- ✅ All plural directory references present
- ✅ No false positives (Claude dirs unchanged)
- ✅ Verification commands return 0 matches for singular forms
