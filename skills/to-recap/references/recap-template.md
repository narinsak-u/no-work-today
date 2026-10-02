# Project Recap

Use this template for `docs/recap.md`. Replace every bracketed placeholder with repository evidence; do not leave placeholders in a completed recap.

## Scope

- **Repository / worktree:** [repository and worktree]
- **Branch:** [branch]
- **Committed range:** [last checkpoint commit]..[new HEAD], or `Initial baseline; no prior checkpoint`
- **Working-tree inclusion:** [state explicitly that committed and uncommitted work are separate]
- **Context consulted:** [optional `docs/overview.md` / `docs/backlog.md`, or `None found`]

## [YYYY-MM-DD] — [short work-group title]

- **Category:** [Feature | Fix | Refactor | Documentation | Test | Tooling | Other]
- **Status:** [Completed | Partial | In progress | Blocked | Needs verification]
- **What / why:** [what changed and the evidence-backed reason; use `Unknown` when intent is not supported]
- **Important files:**
  - `[path]` — [role of the change]
- **Commits:** `[short or full hash]` — [commit subject or grouped related commits]
- **Impact:** [observable behavior or developer impact supported by the diff; otherwise `Unknown`]
- **Junior notes:** [plain-language explanation, relevant dependencies, cautions, or a safe next reading step]
- **Verification:** [exact command and observed result, `not run`, `unknown`, or `reported by commit`]

## Current Point

- **HEAD:** `[full or short commit]` on `[branch]`
- **Committed work:** [what is complete through HEAD; refer to dated entries above]
- **Uncommitted work:** [staged, unstaged, and untracked changes listed separately; `None` when clean]
- **Verification:** [only checks actually observed; label skipped or unknown checks]
- **Next safe point:** [evidence-backed follow-up, or `None identified`]

<!-- recap-state
last_commit: <full-or-short-commit>
last_updated: YYYY-MM-DD
-->
