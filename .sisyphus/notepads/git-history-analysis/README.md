# Git History Analysis: Directory Naming Evolution

## Overview

This analysis examines the complete git history of the OCD (OpenCode Docker) codebase to understand how directory naming conventions evolved from v1.0 to v5.0.

## Key Findings

### 1. Naming Duality is Intentional
The codebase intentionally supports two naming systems:
- **OpenCode** (`.opencode/`): Singular naming (`agent/`, `command/`, `skill/`)
- **Claude** (`.claude/`): Plural naming (`agents/`, `commands/`, `skills/`)

This duality has persisted since v2.0 and is a deliberate design choice for compatibility.

### 2. Six Major Evolution Phases
- **v1.0** (Early 2025): Initial `claude_home/` structure
- **v1.1** (Jan 2025): CLI renamed `opencode` → `ocd`
- **v2.0** (Jan 6, 2025): **BREAKING** - Config system refactor
- **v5.0** (Jan 11, 2025): **BREAKING** - Template system, user-owned configs
- **v5.0+** (Jan 12, 2025): Template consolidation
- **v3.1.4** (Jan 28, 2026): **BREAKING** - Agent keys lowercase

### 3. Three Breaking Changes
1. `claude_home/` → `global/claude/` (v2.0) - Manual migration
2. Config lifecycle change (v5.0) - Automatic migration
3. Agent key case change (v3.1.4) - No automated migration (GAP)

### 4. Template System (v5.0+)
The `templates/` directory is now the source of truth:
- `.tmpl` files: Variable substitution from `versions.lock`
- `.example` files: User reference templates
- No suffix: Direct copy

## Documents in This Analysis

### 1. **findings.md**
Summary of key findings:
- Naming duality explanation
- Six evolution phases
- Breaking changes summary
- Template system overview
- Migration gaps
- Case convention shift
- Backward compatibility status
- Commit references
- Recommendations

### 2. **issues.md**
Detailed issue tracking:
- **Critical Issues** (3):
  - No automated migration for agent key case changes
  - No automated migration for project-level configs
  - Naming duality not documented
- **Medium Issues** (2):
  - Template naming inconsistency
  - Migration documentation gaps
- **Low Issues** (2):
  - Backup naming clarity
  - No version tracking for templates
- **Gotchas** (2):
  - Agent key case sensitivity
  - Config regeneration behavior change
- **Unresolved Questions** (5)

### 3. **decisions.md**
Architectural decisions and rationales:
- 10 major decisions documented
- Rationale for each decision
- Trade-offs analyzed
- Status and future considerations
- Summary of architectural principles
- Decisions pending review

## Quick Reference

### Timeline
```
v1.0 (Early 2025)
  ↓
v1.1 (Jan 2025) - CLI renamed
  ↓
v2.0 (Jan 6, 2025) - BREAKING: Config system refactor
  ↓
v5.0 (Jan 11, 2025) - BREAKING: Template system
  ↓
v5.0+ (Jan 12, 2025) - Template consolidation
  ↓
v3.1.4 (Jan 28, 2026) - BREAKING: Lowercase agent keys
```

### Naming Convention (Current)
| System | Directory | Naming | Example |
|--------|-----------|--------|---------|
| OpenCode | `.opencode/` | Singular | `agent/`, `command/`, `skill/` |
| Claude | `.claude/` | Plural | `agents/`, `commands/`, `skills/` |
| Agent Keys | `oh-my-opencode.json` | Lowercase | `sisyphus`, `oracle` |

### Critical Commits
- `2eb1249` - Config system refactor (v2.0)
- `510a96e` - v5.0 config architecture
- `816b006` - Template consolidation
- `edc9370` - oh-my-opencode v3.1.4 upgrade
- `989661a` - Test updates for lowercase keys

## High-Priority Recommendations

1. **Add automated migration for agent key case changes**
   - Severity: HIGH
   - Impact: Users upgrading to v3.1.4 may have broken configs
   - Solution: Add `ocd_migrate_agent_keys()` function

2. **Document naming duality in AGENTS.md**
   - Severity: MEDIUM
   - Impact: User confusion about correct directory names
   - Solution: Add section explaining singular vs plural

3. **Create comprehensive migration guide**
   - Severity: MEDIUM
   - Impact: Users upgrading from old versions may miss steps
   - Solution: Create `docs/MIGRATION_GUIDE.md`

4. **Add template schema versioning**
   - Severity: LOW
   - Impact: Difficult to know when to regenerate configs
   - Solution: Add `TEMPLATE_SCHEMA_VERSION` to `versions.lock`

## How to Use This Analysis

### For Understanding the Codebase
- Read **findings.md** for overview
- Read **decisions.md** for architectural rationale
- Check **issues.md** for known problems

### For Making Changes
- Consult **decisions.md** for established patterns
- Check **issues.md** for known gotchas
- Reference commit hashes for detailed changes

### For Migrations
- See **findings.md** for migration paths
- See **issues.md** for migration gaps
- See **decisions.md** for migration rationale

## Related Files

- `/workspace/dev/AGENTS.md` - Agent guidelines
- `/workspace/dev/README.md` - Project documentation
- `/workspace/dev/lib/config.sh` - Config management
- `/workspace/dev/lib/migrate.sh` - Migration logic
- `/workspace/dev/templates/` - Config templates
- `/workspace/dev/versions.lock` - Version management

## Analysis Metadata

- **Analysis Date**: Jan 28, 2026
- **Git Commits Analyzed**: 100+
- **Versions Covered**: v1.0 → v5.0 + oh-my-opencode v3.1.4
- **Breaking Changes Found**: 3
- **Critical Issues Found**: 3
- **Architectural Decisions Documented**: 10

## Next Steps

1. **Implement automated agent key migration** (HIGH PRIORITY)
2. **Document naming duality in AGENTS.md** (MEDIUM PRIORITY)
3. **Create migration guide** (MEDIUM PRIORITY)
4. **Add template schema versioning** (LOW PRIORITY)
5. **Review pending decisions** (ONGOING)

---

For detailed information, see individual documents:
- `findings.md` - Key findings and timeline
- `issues.md` - Issues and blockers
- `decisions.md` - Architectural decisions
