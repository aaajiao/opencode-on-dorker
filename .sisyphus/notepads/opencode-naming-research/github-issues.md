# GitHub Issues - Skill Directory Naming

## Issue #9819: Docs: Skill path mismatch - 'skills' (plural) vs 'skill' (singular)
**Status:** OPEN
**Date:** Jan 21, 2026
**Reporter:** @bjesuiter
**URL:** https://github.com/anomalyco/opencode/issues/9819

### Problem
Documentation specifies PLURAL paths, but implementation uses SINGULAR paths.

### Reproduction
```bash
# DOES NOT WORK (documented)
mkdir -p ~/.config/opencode/skills/my-skill
echo "---\nname: my-skill\ndescription: test\n---" > ~/.config/opencode/skills/my-skill/SKILL.md

# WORKS (actual)
mkdir -p ~/.config/opencode/skill/my-skill
echo "---\nname: my-skill\ndescription: test\n---" > ~/.config/opencode/skill/my-skill/SKILL.md
```

### Expected Behavior
Either:
1. Update docs to reflect actual path (`skill/` singular)
2. Update code to match docs (`skills/` plural)
3. Support both paths

---

## Issue #8054: Skill Discovery Only Checks `skills/` Directory, Ignoring `skill/` Path
**Status:** CLOSED
**Date:** Jan 12, 2026
**Reporter:** @aforthwith
**URL:** https://github.com/anomalyco/opencode/issues/8054

### Root Cause
Glob pattern in `packages/opencode/src/skill/skill.ts:39`:
```typescript
const OPENCODE_SKILL_GLOB = new Bun.Glob("{skill,skills}/**/SKILL.md")
```

This pattern was NOT correctly matching `skill/` (singular) directory.

### Fix Applied
Changed to iterate both patterns separately:
```typescript
const OPENCODE_SKILL_GLOB = [
  new Bun.Glob("skill/**/SKILL.md"),
  new Bun.Glob("skills/**/SKILL.md")
]
```

### Impact
- Users following docs (plural) had silent failures
- Users using singular path had success
- No error messages to guide users

---

## Summary

Both issues confirm the same problem:
- **Documented:** `skills/` (plural)
- **Implemented:** `skill/` (singular)
- **User Impact:** Silent failures, confusion

The fix in #8054 supports both, but documentation in #9819 still needs updating.
