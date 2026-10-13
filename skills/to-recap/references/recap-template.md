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
- **Commits:** `[full hash]` — [concise technical note; list every selected full hash exactly once]
- **Junior notes:** [optional next reading step or explanation]
- **Verification:** [observed command and outcome, `not run`, `unknown`, or `reported by commit`]

</details>

## Current Point

- **HEAD:** `[full commit]` on `[branch]`
- **Recap checkpoint:** `[last_commit; latest commit fully represented by the published entries]`
- **Pending committed history:** `None` when caught up; otherwise, `[N] commits remain; oldest unrepresented: [full hash]`.
- **Committed work:** [what is complete through the checkpoint; link to entries above]
- **Uncommitted work:** [staged, unstaged, and untracked work separately, including the skill-owned recap output]
- **Verification:** [only checks actually observed; label skipped/unknown checks]
- **Next safe point:** [evidence-backed follow-up, or `None identified`]

<!-- recap-state
branch: <current branch>
last_commit: <latest commit whose changes are fully represented by the published entries>
last_updated: YYYY-MM-DD
output_sha256: <64 lowercase hexadecimal characters>
-->

Calculate `output_sha256` from the complete document after removing ONLY the entire `output_sha256: ...` line, including its line terminator; insert it immediately before `-->`. Never publish a draft until its full selected commit set passes validation. Existing pre-migration queue fields can be removed only after all their hashes have been accounted for.
