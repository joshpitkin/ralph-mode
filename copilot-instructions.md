# GitHub Copilot CLI — Global Agent Instructions

## Core Behavior

- Work on **ONE task at a time**. Complete it fully before moving to the next.
- Read existing code, tests, and conventions before writing anything new.
- Prefer small, focused commits with clear imperative-mood messages ("Fix login bug" not "Fixed login bug").
- Do not refactor, clean up, or improve code that is unrelated to the current task.
- Do not add comments, docstrings, or type annotations to code you didn't change.

## Before Marking a Task Complete

- Run the project's full test suite. All tests must pass.
- Run the project's type checker (tsc, mypy, etc.) if one exists. No new errors.
- Verify the feature works as described in the PRD task.
- Only then set `passes: true` in prd.json and commit.

## Research Tools

- Use the **context7** MCP server to look up current, accurate documentation for any library or framework before writing code against its API. Prefer this over guessing from training data.
- Use the **playwright** MCP server for browser automation, UI testing, screenshot capture, and scraping tasks.
- Use the **chrome-devtools** MCP server for low-level browser inspection: JS console output, network request/response capture, performance profiling, and DevTools Protocol access. Prefer this over playwright when debugging runtime browser behavior rather than automating user flows.
- Use the **firecrawl** MCP server to scrape, crawl, or extract structured content from web pages and documentation sites. Prefer this over raw curl/fetch for research tasks that require clean text extraction from HTML.
- When a task involves a UI or web interaction, use playwright to verify it works in a real browser.

## Git Discipline

- Commit only files relevant to the current task. Do not stage unrelated changes.
- Do not amend published commits or force-push.
- If the project uses a branching convention (e.g., feature branches), follow it.

## File Operations

- Never delete files unless explicitly required by the task.
- Prefer editing existing files over creating new ones.
- When creating new files, mirror the project's existing directory structure and naming conventions.

## Error Handling

- If a command fails, read the full error message before taking action.
- Do not retry the same failing command more than twice — find the root cause or an alternative approach.
- If genuinely blocked, document the blocker clearly in progress.txt and move to the next task.

## Progress Tracking

- Append a 1–3 line summary to progress.txt after completing each task.
- Be factual: what you changed, what tests now pass, what was left incomplete and why.
- Do not pad progress entries — conciseness is preferred.
