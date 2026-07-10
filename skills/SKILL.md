---
name: gh-issue-tdd
description: Pick up a ready-for-agent GitHub issue, clarify scope, develop with TDD in a feature branch, then open a PR with CI verification and updated docs. Use when the user references a GitHub issue number (e.g. "#42"), says "work on issue", "implement issue", "fix issue", "pick up issue", or asks to develop a feature/bug-fix tied to a specific issue tracker ticket. Only operates on issues labelled "ready-for-agent".
---

# gh-issue-tdd

## Quick start

```
User: "Work on issue #42"
→ Read issue → clarify blockers → branch → TDD loop → PR → CI → docs
```

## Workflow

### Phase 0 — Scope review (MANDATORY before any code)

- [ ] Fetch the issue: read title, body, comments, linked issues
- [ ] **Verify the issue has the `ready-for-agent` label** — if it does not, stop and inform the user; do not proceed
- [ ] Read `CONTEXT-MAP.md` / `AGENTS.md` / `CONTEXT.md` if present
- [ ] Identify: acceptance criteria, affected modules, open questions
- [ ] **Ask all clarifying questions now** — do not start coding with unresolved scope
- [ ] Get user sign-off on scope before proceeding

See [REFERENCE.md — Phase 0](REFERENCE.md#phase-0--scope-review) for question templates.

### Phase 1 — Branch

- [ ] `git fetch origin && git checkout main && git pull origin main`
- [ ] Branch name: `issue-<number>-<slug>` (e.g. `issue-42-add-login`)
- [ ] `git checkout -b issue-<number>-<slug>`

### Phase 2 — TDD development loop

Follow the TDD skill strictly (vertical slices, no horizontal slicing):

- [ ] Confirm public interface changes and priority behaviors with user
- [ ] Tracer bullet: one failing test → minimal pass
- [ ] Repeat RED → GREEN per behavior
- [ ] Refactor after GREEN, never while RED

Spawn `@fixer` sub-agents for bounded, well-defined implementation tasks.  
Spawn `@oracle` when an architectural decision is genuinely unclear.

### Phase 3 — PR creation

- [ ] `git push -u origin <branch>`
- [ ] Create PR with:
  - Title: concise summary of change
  - Body: use `closes #<number>` + description + **Manual QA section** (see [REFERENCE.md — PR template](REFERENCE.md#pr-template))
- [ ] Request Copilot review if available

### Phase 4 — CI verification (10-minute budget)

- [ ] Poll PR check runs every ~60 seconds, up to 10 minutes total
- [ ] If all required checks pass within budget → proceed
- [ ] If any check fails: diagnose, fix, push, reset the 10-minute clock, re-check
- [ ] If checks are still pending after 10 minutes: surface status to user and wait for instruction
- [ ] Do **not** declare work done until all required checks are green

### Phase 5 — Docs scan (run in parallel with Phase 4)

- [ ] **Spawn a background `@explorer`** to glob `**/*.md` and identify files relevant to the change
- [ ] While CI runs, review identified docs for stale content
- [ ] Update any stale sections (API docs, setup guides, feature flags, changelog)
- [ ] Commit docs updates to the same branch; push before finalizing PR

See [REFERENCE.md — Docs scan](REFERENCE.md#docs-scan) for patterns.

## Sub-agent routing

| Task | Agent |
|------|-------|
| Bounded implementation | `@fixer` |
| Architecture decisions | `@oracle` |
| External library/API research | `@librarian` |
| UI/UX components | `@designer` |
| Parallel file searches | `@explorer` |

## Abort conditions

Stop and ask the user if:
- Issue does **not** have the `ready-for-agent` label
- Issue has no acceptance criteria and scope cannot be inferred
- Issue is marked `needs-info` or `wontfix`
- CI failures persist after 2 fix attempts with no clear path forward
- CI checks are still pending/running after the 10-minute budget
