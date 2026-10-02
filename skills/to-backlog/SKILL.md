---
name: to-backlog
description: Use when tracking unfinished work, meaningful TODOs, blockers, priorities, or stable backlog IDs in docs/backlog.md.
---

# Project Backlog

Maintain `docs/backlog.md` as the source of truth for concrete work another developer can pick up. The skill is independent: it reads only its own `references/backlog-template.md`; `docs/overview.md` and `docs/recap.md` are optional, read-only context.

## Boundaries

- Create `docs/` and write only `docs/backlog.md`; preserve unrelated files and documentation.
- Read the local template before creating or updating the backlog. Use its five sections and item fields.
- Preserve every existing item, including `Done` items and completion records. Never renumber, recycle, delete, or silently reopen an ID.
- Use exactly these statuses: `Todo`, `In Progress`, `Blocked`, `Needs Review`, `Done`.
- Use exactly these priorities: `High`, `Medium`, `Low`.
- Do not modify `docs/overview.md`, `docs/recap.md`, source files, or Git state.

## Conservative workflow

1. Establish the repository root, branch, `HEAD`, and working-tree state. Inspect `docs/` without assuming it exists. Read existing `docs/backlog.md` if present, and consult `docs/overview.md` or `docs/recap.md` only as optional evidence.
2. Gather candidates from the current request/context, concrete implementation gaps, meaningful `TODO`/`FIXME` comments, Git state, and the optional project-memory files. A comment is a lead, not an item: create work only when it names a concrete outcome another developer could pick up. Omit trivial cleanup, stale comments, duplicates, and speculative improvements.
3. For each candidate, record the evidence-backed context, a finite task checklist, related work, files, dependencies, and blockers. Do not infer acceptance criteria, scope, urgency, dependencies, or a blocker that the repository does not support. Put unresolved uncertainty in `Needs Review` and state what evidence is missing.
4. Reconcile existing items conservatively. Update status, priority, tasks, dependencies, or blocker fields only when current repository evidence supports the change. Keep completion records intact; only mark `Done` with direct completion evidence (for example, a verified diff, commit, or command result). Do not treat an uncommitted change as completed work.
5. Allocate new IDs by scanning all existing IDs (including `Done`) and available Git history. Use the next unused `BL-###` number; never reuse a historical ID, renumber items, or fill gaps. If history is unavailable, preserve every visible ID and choose a new number above the highest visible ID.
6. Assign `High`, `Medium`, or `Low` from evidence-backed impact, urgency, or blocking effect. Never infer `High` or `Medium`; when no severity evidence exists, use conservative `Low` and state that the priority basis is unknown or needs verification. Record explicit blockers under `Blocked by` and link prerequisite backlog items under `Depends on`; use `None` when no evidence exists.
7. **Guard the owned file.** Before writing, run `git status --short -- docs/backlog.md` when the target is a Git repository. If it reports staged or unstaged changes, stop and ask how to merge them; never overwrite an in-progress backlog edit. In a non-Git repository, preserve existing content explicitly while incorporating the new evidence.
8. Write the complete result to `docs/backlog.md`, retaining all five sections even when one is empty. The template's `Item format` section is authoring guidance and must not be copied into the generated backlog.
9. Re-read and validate the result: every item has a unique stable ID, an allowed status and priority, required fields, evidence, and no unsupported requirement; every item appears under exactly one section whose heading matches its `Status`; and no path outside `docs/backlog.md` changed. Confirm the owned-file guard passed before writing.

## Evidence and update rules

- Existing backlog text is preserved by default; edits require a concrete new observation. Do not rewrite wording just for style, reorder history, or overwrite a completed item.
- Git metadata is context, not automatically backlog work. An uncommitted change, branch divergence, or failed command becomes an item only when the repository provides a concrete unfinished outcome; otherwise mention it in `Context` or omit it.
- A `TODO`/`FIXME` becomes an item only when it represents pick-up-worthy work. “Remove debug log”, formatting, vague reminders, and one-line cleanup remain out of the backlog unless the request supplies evidence of meaningful risk or scope.
- Never manufacture product requirements, tests, deadlines, priorities, dependencies, related files, or completion claims. Use `Unknown` or `Needs verification` in `Context` when evidence is missing.

## Completion check

Before finishing, confirm: output is exactly `docs/backlog.md`; `docs/` exists; old IDs and `Done` records remain; only meaningful work was promoted; statuses and priorities use the allowed values; blockers and dependencies are explicit; and all claims can be traced to repository evidence.
