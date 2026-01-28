# OpenCode Directory Naming Research - Complete Documentation

**Research Date:** January 28, 2026  
**Status:** ✅ COMPLETE  
**Researcher:** OpenCode Librarian Agent

---

## 📚 Documentation Index

This research folder contains comprehensive analysis of OpenCode project configuration directory naming conventions.

### Files in This Folder

1. **SUMMARY.md** ⭐ START HERE
   - Complete overview of all findings
   - Key recommendations
   - Critical discovery summary
   - Best for: Quick understanding of the research

2. **findings.md**
   - Detailed key findings
   - Critical discovery explanation
   - Timeline of evolution
   - Consistency analysis
   - Best for: Understanding the problem in depth

3. **examples.md**
   - Real-world project structures
   - Directory layouts from 4 major projects
   - Consensus analysis
   - Best for: Seeing actual examples

4. **github-issues.md**
   - Detailed GitHub issue analysis
   - Issue #9819 (open) - Documentation mismatch
   - Issue #8054 (closed) - Bug fix details
   - Best for: Understanding the technical problem

---

## 🎯 Quick Summary

### The Problem
- **Documentation says:** `.opencode/skills/` (PLURAL)
- **Implementation does:** `.opencode/skill/` (SINGULAR)
- **Result:** Silent failures for users following official docs

### The Evidence
- GitHub Issue #9819 (OPEN): User reports skills don't load from documented path
- GitHub Issue #8054 (CLOSED): Root cause identified and fixed
- Both confirmed by OpenCode maintainers

### The Recommendation
**Use `.opencode/skill/` (SINGULAR)** for maximum compatibility with OpenCode v1.0.190+

---

## 📊 Research Scope

### Projects Analyzed
1. Anthropic Skills (56.8k ⭐) - Official reference
2. Superpowers (38.7k ⭐) - Popular OpenCode project
3. Oh-My-OpenCode (25.4k ⭐) - OpenCode plugin ecosystem
4. OpenCode Skills Plugin (441 ⭐, archived) - Historical
5. OpenCode Documentation - Official specification
6. OpenCode Implementation - Actual code

### Data Sources
- GitHub repositories and directory structures
- Official OpenCode documentation
- GitHub issues and pull requests
- Migration guides and release notes
- Real-world project configurations

---

## 🔍 Key Findings

### Finding 1: Documentation-Implementation Mismatch ⚠️
The official documentation specifies PLURAL `skills/` paths, but the actual implementation loads from SINGULAR `skill/` paths. This is a critical usability issue causing silent failures.

### Finding 2: Real-World Projects Use Plural ✓
The most visible, well-maintained projects (Anthropic, Superpowers) use PLURAL `skills/` at the repository root. However, these are NOT using OpenCode's native skill discovery system.

### Finding 3: OpenCode Native Uses Singular ✓
The current OpenCode implementation (v1.0.190+) uses SINGULAR `skill/` paths. This is confirmed by the source code, migration guide, and GitHub issue #8054 fix.

### Finding 4: Clear Evolution Timeline ✓
The inconsistency stems from the transition from plugin-based to native skills support:
- Plugin era (Oct 2025): Used `.opencode/skills/` (plural)
- Native support (Oct 2025): Uses `.opencode/skill/` (singular)
- Documentation: Still shows plural (not updated)

### Finding 5: No Community Consensus ⚠️
Different projects use different conventions. No single standard has emerged across the OpenCode ecosystem.

---

## 💡 Recommendations

### For OpenCode Maintainers
1. Update documentation to reflect actual implementation (`skill/` singular)
2. Ensure both paths are supported (already done in code)
3. Add migration guide for plugin → native transition
4. Clarify precedence when skills exist in multiple locations

### For Project Creators
1. Use `skill/` (singular) at project root for maximum compatibility
2. Avoid `.opencode/skills/` (plural) - unreliable
3. Test skill discovery after placement
4. Reference Anthropic's repository for patterns

### For This Project (OCD)
1. Use `.opencode/skill/` (singular) for consistency with OpenCode v1.0.190+
2. Document the actual working path in AGENTS.md
3. Add validation to verify skills are discoverable
4. Consider supporting both for forward compatibility

---

## 🔗 References

### Official Documentation
- [OpenCode Skills Documentation](https://opencode.ai/docs/skills/)
- [OpenCode Config Documentation](https://opencode.ai/docs/config/)

### Real-World Examples
- [Anthropic Skills Repository](https://github.com/anthropics/skills) (56.8k ⭐)
- [Superpowers Project](https://github.com/obra/superpowers) (38.7k ⭐)
- [Oh-My-OpenCode](https://github.com/code-yeongyu/oh-my-opencode) (25.4k ⭐)

### GitHub Issues
- [Issue #9819: Docs: Skill path mismatch](https://github.com/anomalyco/opencode/issues/9819) - OPEN
- [Issue #8054: Skill Discovery Only Checks skills/ Directory](https://github.com/anomalyco/opencode/issues/8054) - CLOSED

### Historical References
- [OpenCode Skills Plugin (Archived)](https://github.com/malhashemi/opencode-skills)
- [PR #5930: Native skill tool](https://github.com/sst/opencode/pull/5930)
- [PR #6000: Per-agent skill filtering](https://github.com/sst/opencode/pull/6000)

---

## 📋 How to Use This Research

### For Understanding the Problem
1. Start with **SUMMARY.md** for overview
2. Read **findings.md** for detailed analysis
3. Check **github-issues.md** for technical details

### For Implementation Decisions
1. Review **examples.md** for real-world patterns
2. Check **findings.md** for recommendations
3. Reference GitHub issues for context

### For Documentation Updates
1. Use **SUMMARY.md** as reference
2. Include links from **github-issues.md**
3. Reference **examples.md** for patterns

---

## ✅ Conclusion

While real-world projects and official documentation favor PLURAL `skills/`, the current OpenCode implementation uses SINGULAR `skill/`.

**Safe Approach:**
- Use `skill/` (singular) until documentation is updated
- Test skill discovery after placement to verify loading
- Reference GitHub issues #9819 and #8054 for context

---

**Research completed:** January 28, 2026  
**Status:** ✅ COMPLETE  
**Next steps:** Implement recommendations in OCD project
