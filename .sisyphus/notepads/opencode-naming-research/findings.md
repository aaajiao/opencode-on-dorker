# OpenCode Directory Naming Research - Key Findings

## Critical Discovery: Singular vs. Plural Inconsistency

**Status:** CONFIRMED - Active GitHub issues (#9819, #8054)

### The Problem
- **Documentation says:** `.opencode/skills/` (PLURAL)
- **Implementation does:** `.opencode/skill/` (SINGULAR)
- **Result:** Skills placed in documented path silently fail to load

### Evidence
1. **GitHub Issue #9819** (Open, Jan 21, 2026): "Docs: Skill path mismatch"
   - User reports skills don't load from `~/.config/opencode/skills/`
   - Skills DO load from `~/.config/opencode/skill/`
   
2. **GitHub Issue #8054** (Closed, Jan 12, 2026): "Skill Discovery Only Checks skills/ Directory"
   - Root cause: Glob pattern `{skill,skills}/**/SKILL.md` not matching correctly
   - Fix: Changed to iterate both patterns separately

### Real-World Project Patterns

| Project | Path | Naming | Stars |
|---------|------|--------|-------|
| Anthropic Skills | `skills/` (root) | PLURAL | 56.8k |
| Superpowers | `skills/` (root) | PLURAL | 38.7k |
| OpenCode Docs | `.opencode/skills/` | PLURAL | - |
| OpenCode Code | `.opencode/skill/` | SINGULAR | - |

### Recommendation for OCD
**Use `.opencode/skill/` (SINGULAR)** - matches current OpenCode implementation

This is the only path that reliably works with OpenCode v1.0.190+

## Timeline of Evolution

- **Oct 2025:** Plugin era used `.opencode/skills/` (plural)
- **Oct 17, 2025:** Native support added to OpenCode
- **Dec 23, 2025:** Plugin archived, migration guide says `mv .opencode/skills skill`
- **Jan 12, 2026:** Bug fix to support both patterns
- **Jan 21, 2026:** Issue #9819 filed - docs still wrong

## Key Insight

The inconsistency stems from the transition from plugin-based to native skills support. The plugin used plural, but native implementation uses singular. Documentation wasn't updated.

**Safe approach:** Use singular `skill/` and test discovery after placement.
