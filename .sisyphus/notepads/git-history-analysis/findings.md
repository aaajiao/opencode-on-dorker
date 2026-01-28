# Git History Analysis: Directory Naming Evolution

## Key Findings

### 1. Naming Duality is Intentional
- **OpenCode system** uses **singular** naming: `agent/`, `command/`, `skill/`
- **Claude system** uses **plural** naming: `agents/`, `commands/`, `skills/`
- This duality has persisted since v2.0 (Jan 6, 2025) and continues through v5.0
- Both systems coexist and are supported simultaneously

### 2. Six Major Phases of Evolution

| Phase | Version | Date | Key Change |
|-------|---------|------|-----------|
| 1 | v1.0 | Early 2025 | Initial `claude_home/` structure |
| 2 | v1.1 | Jan 2025 | CLI renamed `opencode` → `ocd` |
| 3 | v2.0 | Jan 6, 2025 | **BREAKING**: `claude_home/` → `global/claude/` + `global/opencode/` |
| 4 | v5.0 | Jan 11, 2025 | **BREAKING**: Template system, user-owned configs |
| 5 | v5.0+ | Jan 12, 2025 | Template consolidation into `templates/global/opencode/` |
| 6 | v3.1.4 | Jan 28, 2026 | **BREAKING**: Agent keys lowercase (`Sisyphus` → `sisyphus`) |

### 3. Breaking Changes Summary

| Change | Version | Migration | Status |
|--------|---------|-----------|--------|
| `claude_home/` → `global/claude/` | v2.0 | Manual | No automation |
| Config lifecycle change | v5.0 | Automatic | `lib/migrate.sh` |
| Agent key case change | v3.1.4 | Manual | Test updates only |

### 4. Template System (v5.0+)

The `templates/` directory is now the source of truth:
- `.tmpl` files: Variable substitution from `versions.lock`
- `.example` files: User reference templates
- No suffix: Direct copy

Current structure:
```
templates/
├── global/
│   ├── opencode.json.tmpl
│   ├── oh-my-opencode.json
│   └── opencode/
│       ├── agent/
│       ├── command/
│       └── skill/
└── project/
    ├── .opencode/
    │   ├── agent/
    │   ├── command/
    │   └── skill/
    └── .claude/
        ├── agents/
        ├── commands/
        └── skills/
```

### 5. Migration Gaps

- ❌ No automated migration for agent key case changes (v3.1.4)
- ❌ No automated migration for project-level configs
- ❌ Manual migration documentation could be improved
- ✅ Global config migration automated (v5.0)

### 6. Case Convention Shift

Recent shift to lowercase for JSON keys:
- **Before (v1.x-v2.x)**: `"Sisyphus"`, `"Oracle"` (PascalCase)
- **After (v3.1.4)**: `"sisyphus"`, `"oracle"` (lowercase)
- Environment variables also changed: `PLANNER_MODEL` → `SISYPHUS_MODEL`

### 7. Backward Compatibility Status

**Maintained**:
- ✅ Both `.opencode/` and `.claude/` directories supported
- ✅ Singular and plural naming coexist
- ✅ Old config files backed up, not deleted

**Broken**:
- ❌ `claude_home/` no longer recognized (v2+)
- ❌ Uppercase agent keys not supported (v3.1.4+)
- ❌ Config regeneration on startup (v5.0+)

## Commit References

### Critical Commits
- `95d4f23` - Initial commit (v1.0)
- `2eb1249` - Config system refactor (v2.0) - BREAKING
- `510a96e` - v5.0 config architecture - BREAKING
- `816b006` - Template consolidation
- `edc9370` - oh-my-opencode v3.1.4 upgrade - BREAKING
- `989661a` - Test updates for lowercase agent keys

### Related Commits
- `8c0ead0` - Add global commands and skills
- `f0e437b` - Global Claude storage
- `323f343` - Project-level skill detection
- `aa09bdf` - Hierarchical AGENTS.md generation

## Recommendations

1. **Document Naming Duality**: Add section to AGENTS.md explaining singular vs plural
2. **Automate Agent Key Migration**: Add function to `lib/config.sh` for case conversion
3. **Standardize Template Naming**: Enforce `.tmpl` vs `.example` conventions
4. **Version Lock for Templates**: Track template schema version
5. **Migration Checklist**: Create guide for each major version

## Patterns Observed

1. **Consolidation Trend**: Movement from scattered directories to centralized `templates/`
2. **Standardization Trend**: Shift toward lowercase for JSON keys
3. **User Ownership Trend**: Configs created once, then user-managed (v5.0+)
4. **Backward Compatibility**: Old structures backed up, not deleted
