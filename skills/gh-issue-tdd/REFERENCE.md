# gh-issue-tdd — Reference

## Phase 0 — Scope review

### What to fetch

```
github_issue_read(method="get")          # includes labels array
github_issue_read(method="get_comments")
github_issue_read(method="get_sub_issues")
```

### Label gate

Check `labels` on the issue object. If `ready-for-agent` is not present:

> "Issue #N does not have the `ready-for-agent` label (current labels: X, Y).
> Should I proceed anyway, or would you like to label it first?"

Do not touch any code until the user confirms.

### Question templates

Ask **all** of these that apply before writing a single line of code:

**Acceptance criteria**
- "The issue doesn't list explicit acceptance criteria — can you confirm the expected behavior when X?"
- "Should this work for edge case Y, or is the happy path sufficient for now?"

**Scope boundaries**
- "Should I touch `<module>` or is that out of scope for this issue?"
- "Is this a pure backend change, or does it require UI updates too?"

**Dependencies / blockers**
- "Issue mentions `<other-issue>` — is that prerequisite done, or should I implement a stub?"
- "Does this need a DB migration, and if so, is that in scope here?"

**Testing expectations**
- "Are there existing integration tests I should extend, or should I add new ones?"
- "Is E2E / manual-only testing acceptable for the UI portion?"

**Definition of done**
- "Is this complete when the PR merges, or are there follow-up deploy steps?"

---

## PR template

```markdown
## Summary

<one-paragraph description of what changed and why>

Closes #<issue-number>

## Changes

- <bullet list of significant changes>

## Manual QA

Steps a reviewer should take to manually verify this PR:

1. <step>
2. <step>
3. Expected result: <description>

## Notes

<anything unusual about the implementation, trade-offs made, follow-ups deferred>
```

---

## Docs scan

### Patterns to search

```bash
# Find all markdown files
glob("**/*.md")

# Key candidates
grep("CHANGELOG", "*.md")
grep("README", "*.md")
grep("<feature name>", "*.md")
```

### What to update

| Doc type | When to update |
|----------|----------------|
| `README.md` | New feature visible to users or new setup step |
| `CHANGELOG.md` / `HISTORY.md` | Any user-facing or API change |
| `docs/` pages | New capability, changed behavior, new config |
| `CONTEXT-MAP.md` | New module or major architectural change |
| `AGENTS.md` | New agent guidance, domain rules, or integration points |
| Inline `## Usage` sections | Changed public API or CLI flags |

Only update docs that are **stale relative to the change** — don't rewrite for its own sake.

---

## Branch naming

```
issue-<number>-<2-4-word-slug>

Examples:
  issue-42-add-login
  issue-107-fix-rebate-upload-error
  issue-203-precheck-timeout
```

---

## CI verification loop (10-minute budget)

```
deadline = now() + 10 minutes

1. git push -u origin <branch>
2. Create PR
3. Loop:
   a. github_pull_request_read(method="get_check_runs")
   b. If all required checks → "completed/success": DONE ✓
   c. If any check → "completed/failure":
      - Read failure logs
      - Fix in branch, git push
      - Reset deadline to now() + 10 minutes
      - Continue loop
   d. If now() > deadline and checks still pending/running:
      - Surface to user: "CI checks still running after 10 min: [list]"
      - Wait for user instruction
   e. Sleep ~60 seconds, repeat
```

Never declare the issue complete while required CI checks are failing.
