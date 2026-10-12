# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Make an issue a sub-issue of a parent**: use `gh issue create --parent <parent> ...`, or `gh issue edit <parent> --add-sub-issue <child>` when supported. If unavailable, add `Part of #<parent>` to the child body.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repository from `git remote -v`; `gh` does this automatically inside the clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** Set to `yes` only if this repo treats external PRs as feature requests.

When set to `yes`, PRs use the same labels and states as issues, via `gh pr` equivalents. GitHub shares one number space across issues and PRs, so resolve a bare `#42` by trying `gh pr view 42` and falling back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Conventions** above.

## Wayfinding operations

- **Map**: one issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: link as a GitHub sub-issue when supported. Otherwise use a task list in the map and add `Part of #<map>` to the child body.
- **Blocking**: use GitHub native issue dependencies when available; otherwise add a `Blocked by: #<n>` line to the issue body.
- **Frontier**: an open child is ready when it has no open blockers and no assignee.
- **Claim**: `gh issue edit <n> --add-assignee @me`.
- **Resolve**: comment with the answer, close the issue, then append a context pointer to the map’s Decisions-so-far.
