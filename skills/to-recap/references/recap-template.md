# Project Recap

Use this template for `docs/recap.md`; replace bracketed placeholders with verified repository evidence. Do not leave placeholders in a completed recap. Keep old dated entries unchanged when appending new ones.

## Scope

- **Repository / worktree:** [repository and worktree]
- **Branch:** [branch]
- **Committed range:** Initial window: [oldest included full commit] through [initial HEAD], inclusive, covering at most the latest 100 unique reachable commits. [State explicitly whether older history exists outside this initial coverage; for an inherited recap preserve its previously verified boundary.]
- **Working-tree inclusion:** Committed and uncommitted work are reported separately.
- **Context consulted:** [optional `docs/overview.md` / `docs/backlog.md`, or `None found`]

## [YYYY-MM-DD] — [short work-group title]

- **Category:** [features | fixes | refactors | infrastructure | testing | documentation | security | performance]
- **Status:** [Completed | Partial | In progress | Blocked | Needs verification]
- **What / why:** [evidence-backed change and reason, or `Unknown`]
- **Important files:**
  - `[path]` — [role of the change; use `None` for an empty commit]
- **Commits:** `[full hash]` — [subject or grouped related commits; list EVERY selected full hash exactly once in a work entry]
- **Impact:** [supported result or `Unknown`]
- **Junior notes:** [plain-language context and safe next reading step]
- **Verification:** [observed command and outcome, `not run`, `unknown`, or `reported by commit`]

## Current Point

- **HEAD:** `[full commit]` on `[branch]`
- **Recap checkpoint:** `[last_commit; full HEAD only after every selected commit is represented]`
- **Pending committed history:** None [only when checkpoint equals HEAD; otherwise report the bounded collection still pending without advancing state]
- **Committed work:** [what is complete through the checkpoint; link to entries above]
- **Uncommitted work:** [staged, unstaged, and untracked work separately, including the skill-owned recap output]
- **Verification:** [only checks actually observed; label skipped/unknown checks]
- **Next safe point:** [evidence-backed follow-up, or `None identified`]

<!-- recap-state
branch: <current branch>
last_commit: <full commit represented by every dated entry through the complete range>
last_updated: YYYY-MM-DD
output_sha256: <64 lowercase hexadecimal characters>
-->

Calculate `output_sha256` from the complete document after removing ONLY the entire `output_sha256: ...` line, including its line terminator; insert it immediately before `-->`. Never publish a draft until its full selected commit set passes validation. Existing pre-migration queue fields can be removed only after all their hashes have been accounted for.
