# Project Recap

Use this template for `docs/recap.md`. Replace every bracketed placeholder with repository evidence; do not leave placeholders in a completed recap.

## Scope

- **Repository / worktree:** [repository and worktree]
- **Branch:** [branch]
- **Committed range:** Initial selected window: [oldest selected commit] through [initial HEAD], inclusive, covering at most the latest 1,000 unique commits; state whether older history is outside scope. For a legacy recap, preserve its verified committed range.
- **Working-tree inclusion:** [state explicitly that committed and uncommitted work are separate]
- **Context consulted:** [optional `docs/overview.md` / `docs/backlog.md`, or `None found`]

## [YYYY-MM-DD] — [short work-group title]

- **Category:** [features | fixes | refactors | infrastructure | testing | documentation | security | performance]
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
- **Recap checkpoint:** `[last_commit; latest commit fully represented by dated entries above; may lag HEAD]`
- **Pending committed history:** `[count in the exact pending queue; show the next up-to-100 oldest-first full hashes, or None only when the queue is empty and checkpoint equals HEAD]`
- **Committed work:** [what is complete through the recap checkpoint; refer to dated entries above]
- **Uncommitted work:** [staged, unstaged, and untracked changes listed separately; keep separate from committed work and distinguish the skill-owned recap output]
- **Verification:** [only checks actually observed; label skipped or unknown checks]
- **Next safe point:** [evidence-backed follow-up, or `None identified`]

<!-- recap-state
branch: <current branch>
history_head: <full commit whose reachable additions have been reconciled into pending_commits>
pending_commits: <none or space-separated full commit hashes in oldest-first topological order>
last_commit: <full-or-short commit fully represented by recap entries>
last_updated: YYYY-MM-DD
output_sha256: <64 lowercase hexadecimal characters>
-->
