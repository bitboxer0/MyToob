# MyToob Development Quick Start Guide

**For Teams Starting Development Today**

---

## Day 1 Checklist

### Team Alpha (Critical Path) - START HERE
- [ ] Clone repository
- [ ] **START IMMEDIATELY:** Story 1.1 - Xcode Project Setup
  - Create macOS target
  - Configure entitlements
  - Add Core ML model to resources
  - **BLOCKS EVERYONE ELSE - HIGHEST PRIORITY**
- [ ] Expected completion: End of Day 2

### Team Bravo (Infrastructure) - WAIT FOR 1.1
- [ ] Clone repository
- [ ] Review stories: 1.2, 1.3, 1.6
- [ ] Set up local development environment
- [ ] **Wait for Team Alpha to complete 1.1**
- [ ] Day 3: Start on 1.2 SwiftLint

### Team Charlie (Docs & Independent Work)
- [ ] Clone repository
- [ ] **START TODAY:** Story 12.5 - Privacy Policy draft
- [ ] **START TODAY:** Story 15.6 - Marketing assets prep
- [ ] Day 3: Start on 5.1 Local File Import (after 1.4 completes)

### Team Delta (Data Layer) - WAIT FOR 1.4
- [ ] Clone repository
- [ ] Review Epic 6 stories
- [ ] Design CloudKit schema
- [ ] **Wait for Team Alpha to complete 1.4**
- [ ] Day 4: Start on 6.1 Model Container

---

## First Week Goals (Phase 1)

### By End of Week 1, You Should Have:
- ✅ Working Xcode project that builds
- ✅ SwiftData models defined and tested
- ✅ Basic app shell with sidebar navigation
- ✅ SwiftLint enforcing code quality
- ✅ CI/CD pipeline running on every commit
- ✅ OSLog logging functional

**Stories to Complete:** 9 (1.1-1.6, plus 3 doc stories)

---

## Week-by-Week Roadmap

### Week 2-4: Core Features
**Alpha Focus:** YouTube OAuth → API Client → IFrame Player
**Bravo Focus:** Caching, quota budgeting, player features
**Charlie Focus:** Complete Epic 5 (Local Files)
**Delta Focus:** Complete Epic 6 (CloudKit Sync)

**Deliverable:** Can watch YouTube + local videos, data syncs

### Week 5-7: AI & Search
**Alpha Focus:** Epic 7 (Embeddings) → Epic 8 (Clustering)
**Bravo Focus:** Epic 9 (Search UI)
**Charlie Focus:** Epic 10 (Collections)
**Delta Focus:** Smart Collections UI (8.4-8.6)

**Deliverable:** Semantic search works, smart collections auto-generated

### Week 8-10: Polish
**Alpha Focus:** Epic 4 (Focus Mode)
**Bravo Focus:** Epic 11 (Research Tools)
**Charlie Focus:** Epic 13 (macOS Integration)
**Delta Focus:** Epic 12 (Compliance)

**Deliverable:** Full feature set, UGC safeguards

### Week 11-12: Release
**Alpha Focus:** Epic 14 (Accessibility)
**Bravo Focus:** Epic 15 (Monetization)
**Charlie Focus:** App Store submission
**Delta Focus:** Final QA

**Deliverable:** App Store approved, ready to launch

---

## Story Status Workflow

1. **Draft** - Story created by Scrum Master *(current state)*
2. **Approved** - PO reviewed and approved for development
3. **InProgress** - Developer actively working
4. **Review** - Code complete, in PR review
5. **Done** - Merged, tested, QA passed

**How to Update:**
Edit the `## Status` line in each story file:
```markdown
## Status
InProgress
```

---

## Daily Standup Template

**What did you complete yesterday?**
- Story X.Y completed, PR merged
- Story A.B blocked on dependency C.D

**What are you working on today?**
- Starting Story E.F
- Reviewing PR for Story G.H

**Any blockers?**
- Waiting for Team Alpha to finish 1.4
- Need architecture clarification on CloudKit schema

---

## Cross-Team Dependencies (Check Daily)

### If You're Waiting On:
- **1.1 Xcode Project** → Check with Team Alpha (Day 2)
- **1.4 SwiftData Models** → Check with Team Alpha (Day 4)
- **1.5 App Shell** → Check with Team Alpha (Day 5)
- **2.3 YouTube API Client** → Check with Team Alpha (Week 2)
- **3.3 Player State** → Check with Team Alpha (Week 3)
- **7.6 Vector Search** → Check with Team Alpha (Week 6)
- **8.3 Cluster Labels** → Check with Team Alpha (Week 7)

**Use Slack channel:** `#mytoob-dependencies` to coordinate handoffs

---

## Definition of Done (Every Story)

Before marking a story "Done", verify:
- [ ] All acceptance criteria met
- [ ] Unit tests written and passing (80% coverage target)
- [ ] Code follows SwiftLint rules (no errors)
- [ ] PR reviewed and approved
- [ ] CI/CD pipeline green
- [ ] Documentation updated (if public API)
- [ ] Dev Notes section populated in story file
- [ ] File List recorded in story file

---

## Common Questions

**Q: Can I start Epic 5 (Local Files) before Epic 2 (YouTube)?**
A: Yes! Epic 5 is independent. Wait for 1.4 SwiftData Models (Day 4), then start 5.1.

**Q: When can we work on Search (Epic 9)?**
A: Not until Week 6 after Epic 7 (Embeddings) completes. Focus on Epics 1-6 first.

**Q: Can we parallelize stories within an epic?**
A: Yes, if they're not sequential! Example: 3.4, 3.5, 3.6 can all run in parallel after 3.3.

**Q: What if a story is blocked?**
A: Update status in story file, notify in Slack, pick another story from parallel stream.

**Q: How do we handle story dependencies across teams?**
A: Daily cross-team sync at 10am. Use dependency graph to know what's blocked.

---

## File Locations Cheat Sheet

**Architecture Docs:**
- Tech stack: `docs/architecture/tech-stack.md`
- Coding standards: `docs/architecture/coding-standards.md`
- Data models: `docs/architecture/data-models.md`
- Project structure: `docs/architecture/unified-project-structure.md`

**Story Files:**
- All stories: `docs/stories/*.md`
- Epic source: `docs/prd/epic-*.md`

**Code Locations:**
- Models: `MyToob/Core/Models/`
- Services: `MyToob/Features/{YouTube,LocalFiles,AI,etc.}/`
- Utilities: `MyToob/Core/Utilities/`
- Tests: `MyToobTests/`

---

## Sprint Planning Quick Reference

### Sprint 1 (Week 1) - Foundation
**Team Alpha:** 1.1, 1.4, 1.5 (critical path)
**Team Bravo:** 1.2, 1.3, 1.6
**Team Charlie:** 12.5, 12.4 (docs)

### Sprint 2 (Week 2-3) - YouTube Core
**Team Alpha:** 2.1, 2.2, 2.3, 3.1, 3.2, 3.3
**Team Bravo:** 2.4, 2.5, 2.6
**Team Charlie:** 5.1, 5.2, 5.3, 5.4
**Team Delta:** 6.1, 6.2, 6.3

### Sprint 3 (Week 4-5) - Playback Complete
**Team Alpha:** 3.4, 3.5, 3.6, 7.1, 7.2, 7.3
**Team Bravo:** (backlog)
**Team Charlie:** 5.5, 5.6, 10.1, 10.2
**Team Delta:** 6.4, 6.5, 6.6

---

## Success Metrics by Phase

**Phase 1 (Week 1):** ✅ App builds and runs
**Phase 2 (Week 4):** ✅ Can watch videos (YouTube + local)
**Phase 3 (Week 7):** ✅ Semantic search finds relevant results
**Phase 4 (Week 10):** ✅ Focus Mode hides distractions
**Phase 5 (Week 12):** ✅ App Store approved

---

## Emergency Contacts

**Scrum Master:** Bob (for process questions)
**Product Owner:** [Name] (for requirement clarification)
**Tech Lead:** [Name] (for architecture decisions)

**Escalation Path:**
1. Ask in team channel
2. Ask in #mytoob-dependencies
3. Bring to daily standup
4. Escalate to Scrum Master if blocking >1 day

---

## Tools & Access

**Required Day 1:**
- [ ] GitHub repository access
- [ ] Xcode 15+ installed
- [ ] Homebrew installed (`brew install swiftlint swift-format`)
- [ ] Slack workspace access
- [ ] Story tracking board access (Jira/Linear/GitHub Projects)

**Required Week 2:**
- [ ] Apple Developer account (for signing)
- [ ] Google Cloud Console (for YouTube API credentials)
- [ ] CloudKit dashboard access

---

## Quick Wins (For Motivation)

**Day 1:** App icon appears in Xcode
**Week 1:** App launches with window
**Week 2:** First YouTube video plays
**Week 3:** Local file plays
**Week 4:** Videos sync across devices
**Week 6:** Semantic search works
**Week 7:** Smart collections auto-generated
**Week 10:** Focus Mode hides all distractions
**Week 12:** App Store submission complete

---

**Ready to code? Start with Team Alpha on Story 1.1!** 🚀

**Questions?** Check `DEVELOPMENT-PRIORITIZATION-PLAN.md` for detailed phase breakdown
or `DEPENDENCY-GRAPH.md` for visual dependency map.
