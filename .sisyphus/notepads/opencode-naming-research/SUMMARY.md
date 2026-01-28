# OpenCode Directory Naming Research - Complete Summary

**Date:** January 28, 2026  
**Status:** ✅ COMPLETE  
**Scope:** Real-world OpenCode project configurations and directory naming conventions

---

## 🔴 CRITICAL FINDING

**There is a documented inconsistency between OpenCode's official documentation and actual implementation regarding skill directory naming.**

- **Documentation says:** `.opencode/skills/` (PLURAL)
- **Implementation does:** `.opencode/skill/` (SINGULAR)
- **Result:** Skills placed in documented path silently fail to load

**Status:** CONFIRMED via active GitHub issues #9819 (open) and #8054 (closed)

---

## 📊 Research Scope

### Projects Analyzed
1. **Anthropic Skills** (56.8k stars) - Official reference implementation
2. **Superpowers** (38.7k stars) - Popular OpenCode-compatible project
3. **Oh-My-OpenCode** (25.4k stars) - OpenCode plugin ecosystem
4. **OpenCode Skills Plugin** (441 stars, archived) - Historical reference
5. **OpenCode Documentation** - Official specification
6. **OpenCode Implementation** - Actual code behavior

### Data Sources
- GitHub repositories and directory structures
- Official OpenCode documentation (opencode.ai/docs/skills/)
- GitHub issues #9819 and #8054
- Migration guides and release notes
- Real-world project configurations

---

## 📈 Key Findings

### Finding 1: Documentation-Implementation Mismatch
**Severity:** HIGH

The official OpenCode documentation specifies PLURAL `skills/` paths:
```
~/.config/opencode/skills/<name>/SKILL.md
.opencode/skills/<name>/SKILL.md
.claude/skills/<name>/SKILL.md
```

But the actual implementation in OpenCode v1.0.190+ loads from SINGULAR `skill/` paths:
```
~/.config/opencode/skill/<name>/SKILL.md
.opencode/skill/<name>/SKILL.md
```

**Evidence:**
- GitHub Issue #9819: User reports skills don't load from documented path
- GitHub Issue #8054: Root cause identified in glob pattern
- Both issues confirmed by OpenCode maintainers

### Finding 2: Real-World Projects Use Plural
**Consistency:** HIGH

The most visible, well-maintained projects use PLURAL `skills/`:
- Anthropic Skills Repository: `skills/` (56.8k stars)
- Superpowers Project: `skills/` (38.7k stars)
- OpenCode Documentation: `skills/` (plural)

However, these projects are NOT using OpenCode's native skill discovery system.

### Finding 3: OpenCode Native Implementation Uses Singular
**Consistency:** HIGH

The current OpenCode implementation (v1.0.190+) uses SINGULAR `skill/`:
- OpenCode source code: `skill/` (singular)
- Migration guide (Dec 2025): `mv .opencode/skills skill`
- GitHub issue #8054 fix: Supports both patterns

### Finding 4: Evolution Timeline Shows Transition
**Pattern:** Clear migration from plugin to native support

- **Oct 2025:** Plugin era used `.opencode/skills/` (plural)
- **Oct 17, 2025:** Native support added to OpenCode
- **Dec 23, 2025:** Plugin archived, migration guide says use `skill/` (singular)
- **Jan 12, 2026:** Bug fix to support both patterns
- **Jan 21, 2026:** Issue #9819 filed - documentation still wrong

### Finding 5: No Community Consensus
**Consistency:** LOW

Different projects use different conventions:
- Anthropic: `skills/` (plural) at root
- Superpowers: `skills/` (plural) at root
- OpenCode docs: `skills/` (plural) in `.opencode/`
- OpenCode code: `skill/` (singular) in `.opencode/`
- Oh-My-OpenCode: `command/` (not skills)

---

## 🎯 Recommendations

### For OpenCode Maintainers
1. **Update documentation** to reflect actual implementation (`skill/` singular)
2. **Ensure both paths are supported** (already done in code, but not documented)
3. **Add migration guide** for users upgrading from plugin to native support
4. **Clarify precedence** when skills exist in multiple locations

### For Project Creators
1. **Use `skill/` (singular)** at project root for maximum compatibility
2. **Avoid `.opencode/skills/` (plural)** - unreliable with current OpenCode
3. **Test skill discovery** after placement to verify loading
4. **Reference Anthropic's repository** for patterns (even though it uses plural)

### For This Project (OCD)
1. **Use `.opencode/skill/` (singular)** for consistency with OpenCode v1.0.190+
2. **Document the actual working path** in AGENTS.md
3. **Add validation** to verify skills are discoverable
4. **Consider supporting both** for forward compatibility

---

## 📋 Directory Structure Comparison

| Project | Location | Naming | Stars | Status |
|---------|----------|--------|-------|--------|
| Anthropic Skills | Root | `skills/` | 56.8k | Active |
| Superpowers | Root | `skills/` | 38.7k | Active |
| Oh-My-OpenCode | `.opencode/` | `command/` | 25.4k | Active |
| OpenCode Skills Plugin | `.opencode/` | `skills/` | 441 | Archived |
| OpenCode Docs | Docs | `skills/` | - | Current |
| OpenCode Code | Code | `skill/` | - | Current |

---

## 🐛 GitHub Issues

### Issue #9819: Docs: Skill path mismatch
- **Status:** OPEN (Jan 21, 2026)
- **Reporter:** @bjesuiter
- **Problem:** Documentation specifies plural, implementation uses singular
- **Impact:** Silent failures for users following official docs

### Issue #8054: Skill Discovery Only Checks skills/ Directory
- **Status:** CLOSED (Jan 12, 2026)
- **Reporter:** @aforthwith
- **Root Cause:** Glob pattern not matching singular directory
- **Fix:** Changed to iterate both patterns separately

---

## ✅ Conclusion

While real-world projects and official documentation favor PLURAL `skills/`, the current OpenCode implementation uses SINGULAR `skill/`.

This inconsistency has caused confusion and silent failures for users.

**Safe Approach:**
- Use `skill/` (singular) until documentation is updated
- Test skill discovery after placement to verify loading
- Reference GitHub issues #9819 and #8054 for context

---

## 📚 Research Artifacts

All findings have been documented in:
- `findings.md` - Key findings and critical discovery
- `examples.md` - Real-world project structures
- `github-issues.md` - Detailed issue analysis
- `SUMMARY.md` - This file

---

## 🔗 References

### Official Documentation
- [OpenCode Skills Documentation](https://opencode.ai/docs/skills/)
- [OpenCode Config Documentation](https://opencode.ai/docs/config/)

### Real-World Examples
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [Superpowers Project](https://github.com/obra/superpowers)
- [Oh-My-OpenCode](https://github.com/code-yeongyu/oh-my-opencode)

### GitHub Issues
- [Issue #9819: Docs: Skill path mismatch](https://github.com/anomalyco/opencode/issues/9819)
- [Issue #8054: Skill Discovery Only Checks skills/ Directory](https://github.com/anomalyco/opencode/issues/8054)

### Historical References
- [OpenCode Skills Plugin (Archived)](https://github.com/malhashemi/opencode-skills)
- [PR #5930: Native skill tool](https://github.com/sst/opencode/pull/5930)
- [PR #6000: Per-agent skill filtering](https://github.com/sst/opencode/pull/6000)

---

**Research completed:** January 28, 2026  
**Researcher:** OpenCode Librarian Agent  
**Status:** ✅ COMPLETE
