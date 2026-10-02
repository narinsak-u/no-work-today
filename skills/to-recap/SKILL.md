---
name: to-recap
description: Use when updating project recaps from Git history and checkpoints, or documenting completed work, fixes, refactors, and their impact in docs/recap.md.
---

# Incremental Project Recap

Maintain one evidence-based, append-only project memory at `docs/recap.md`. Summarize completed repository work without rereading or rewriting history that a prior checkpoint already covers, and keep current uncommitted work visibly separate from committed work.

## Boundaries

- The only generated output is `docs/recap.md`; create `docs/` when it does not exist.
- Read `references/recap-template.md` from this skill before creating or updating the recap. Use its headings and exact checkpoint shape; do not depend on another skill or an external template.
- Preserve all existing recap entries and unrelated files. Append new dated entries; do not rewrite, reorder, delete, or deduplicate historical entries.
- The mutable parts are the `Current Point` section and the final `recap-state` checkpoint. Update only those blocks plus newly appended entries.
- Never present staged, unstaged, or untracked work as completed history. Never stage, commit, reset, discard, or amend repository work while producing the recap.
- Use repository evidence. Distinguish observed facts from commit-author claims and inferences. Mark unsupported or unavailable information as `Unknown`, `Needs verification`, `not run`, or `reported by commit` rather than guessing.

## Incremental workflow

1. **Establish the repository state.** Confirm the repository root, current branch, current `HEAD`, and working-tree status. Inspect the existing `docs/` directory without assuming it exists. Check for `docs/overview.md` and `docs/backlog.md` as optional context; verify their claims against Git evidence and do not edit them.
2. **Read the existing recap and checkpoint.** If `docs/recap.md` exists, read its prior entries and locate the exact HTML checkpoint at its end:

   ```md
   <!-- recap-state
   last_commit: <full-or-short-commit>
   last_updated: YYYY-MM-DD
   -->
   ```

   Treat `last_commit` as the committed-history boundary, not as a date guess. Preserve all entries before adding new work.
3. **Choose a safe boundary.**
   - When the checkpoint commit exists and is an ancestor of `HEAD`, inspect only descendants in `<last_commit>..HEAD` and the current worktree diff. If it equals `HEAD`, there is no new committed range.
   - If the checkpoint is missing, ambiguous, or no longer an ancestor because of a rebase, force-push, or branch switch, do not silently reread and summarize all history. Inspect available refs and graph context to determine whether the checkpoint can be matched; otherwise record the discontinuity as `Needs verification`, preserve the old recap, and establish a conservative new baseline at the current `HEAD`.
   - For merges, inspect the graph and relevant diffs rather than treating every parent or merge commit as a separate feature. For rebases, do not claim old commit hashes are descendants merely because subjects look similar; call out the rewritten boundary and use verified new hashes.
4. **Inspect only the scoped evidence.** Use the narrowest Git history and diff commands that answer the boundary question, then inspect changed files, tests, configuration, and explicit follow-ups needed to explain behavior. Group related commits that implement one coherent change. Do not make one recap item per commit when several commits belong to the same feature, fix, refactor, or documentation change. Keep merge, generated, formatting-only, and unrelated changes distinct when they have different meaning.
5. **Separate committed and uncommitted work.** Build dated entries only from the verified committed range. Inspect staged, unstaged, and untracked changes separately and list them under `Current Point` as `Uncommitted work`, with their status and verification limits. If a worktree change is relevant to a committed entry, state the distinction explicitly; do not fold it into the completed impact.
6. **Write from the local template.** Include the template's `Scope`, dated work entries, categories, status, what/why, important files, commits, impact, junior notes, verification, and `Current Point`. For each entry, choose one of the template categories: `features`, `fixes`, `refactors`, `infrastructure`, `testing`, `documentation`, `security`, or `performance`. Explain impact only when supported by the diff or explicit repository context. Record exact observed verification commands and outcomes; use `not run`, `unknown`, or `reported by commit` when no result was observed.
7. **Guard the owned file.** Before writing, run `git status --short -- docs/recap.md` when the target is a Git repository. If it reports staged or unstaged changes, stop and ask how to merge them; never overwrite an in-progress recap edit. In a non-Git repository, preserve existing content explicitly while incorporating the new evidence.
8. **Append and checkpoint.** Add new dated grouped entries before the mutable `Current Point` block. Update `Current Point` with the new `HEAD`, branch, committed summary, separately listed worktree changes, verification, and a safe next point. Replace the checkpoint values with the new `HEAD` (full or short hash) and today's date in `YYYY-MM-DD` format. The checkpoint must remain the exact HTML comment shape shown above.
9. **Re-read and audit the result.** Confirm old entries remain intact, every new entry maps to scoped evidence, related commits are grouped, committed and uncommitted work are distinct, no test result is invented, `Current Point` reflects the actual state, and the checkpoint records the `HEAD` that was inspected. Confirm that only `docs/recap.md` (and possibly `docs/`) was intended to change and that the owned-file guard passed before writing.

## Evidence rules

- A commit title is a lead, not proof of behavior. Inspect the relevant diff before stating what changed or why.
- A test file, script, or CI configuration does not prove a check passed. Claim `verified` only for a command or CI result actually observed in the scoped work; otherwise say `not run`, `unknown`, or `reported by commit`.
- Do not infer motivation, user impact, performance, coverage, release state, or roadmap items from filenames, commit counts, or conventional project patterns.
- If history was rewritten, the branch changed, or a checkpoint cannot be resolved, preserve continuity and make the boundary uncertainty visible instead of manufacturing a complete timeline.

## Completion criteria

A recap update is complete when `docs/recap.md` exists, uses the local template, preserves all earlier entries, appends grouped evidence-backed work after the prior checkpoint, updates `Current Point`, records a valid `recap-state` checkpoint for the inspected `HEAD`, and labels uncommitted or unverified information explicitly. No unrelated file is modified.
