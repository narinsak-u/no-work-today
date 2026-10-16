# Project Recap

Use this template for `docs/recap.md`; replace bracketed placeholders with verified repository evidence. Do not leave placeholders in a completed recap. Keep old dated entries unchanged when appending new ones.

## Scope

- **Repository / worktree:** [repository and worktree]
- **Branch:** [branch]
- **Committed range:** Initial window: [oldest included full commit] through [initial HEAD], inclusive, covering the latest 100 eligible commits at most. [State whether older history exists outside initial coverage; for an inherited recap preserve its verified boundary.]
- **Working-tree inclusion:** Committed and uncommitted work are reported separately.
- **Context consulted:** [optional `docs/overview.md` / `docs/backlog.md`, or `None found`]

## [YYYY-MM-DD] — [short work-group title]

- **Category:** [features | fixes | refactors | infrastructure | testing | documentation | security | performance]
- **Status:** [Completed | Partial | In progress | Blocked | Needs verification]
- **What / why:** [One or two plain-language sentences stating the outcome and who or what benefits.]
- **Impact:** [Supported user or project impact in plain language, or `Unknown`]

<details>
<summary>Technical details and commit evidence</summary>

- **Important files:**
  - `[path]` — [verified role; use `None` for an empty commit]
- **Commits:** `[full hash]` — [concise technical note; list every selected full hash exactly once on this same physical line]
- **Junior notes:** [optional next reading step or explanation]
- **Verification:** [observed command and outcome, `not run`, `unknown`, or `reported by commit`]

</details>

## Current Point

- **HEAD:** `[full commit]` on `[branch]`
- **Recap checkpoint:** `[last_commit; latest commit fully represented by the published entries]`
- **Pending committed history:** `None` when caught up; otherwise, `1 commit remains; oldest unrepresented: HASH` or `N commits remain; oldest unrepresented: HASH`.
- **Committed work:** [what is complete through the checkpoint; link to entries above]
- **Uncommitted work:** [staged, unstaged, and untracked work separately, including the skill-owned recap output]
- **Verification:** [only checks actually observed; label skipped/unknown checks]
- **Next safe point:** [evidence-backed follow-up, or `None identified`]

<!-- recap-state
branch: <current branch>
last_commit: <latest commit whose changes are fully represented by the published entries>
last_updated: YYYY-MM-DD
history_head: <HEAD pinned for continuation>
pending_commits: <unrepresented full IDs, oldest-first; or `none`>
output_sha256: <64 lowercase hexadecimal characters>
-->

Calculate `output_sha256` from the complete document after removing ONLY the entire `output_sha256: ...` line, including its line terminator; insert it immediately before `-->`. Set `history_head` to the captured `HEAD`. For existing recaps, set `pending_commits` to the complete ordered remainder after the batch, including when initializing a legacy recap; use `none` for a new initial-window recap or when caught up. Existing queue metadata may be removed only after all its hashes are represented.

For readability, group repetitive numbered records in chronological groups of at most 10 commits. Keep each hash-and-note pair on the same physical **Commits:** line; never wrap it onto continuation lines.
