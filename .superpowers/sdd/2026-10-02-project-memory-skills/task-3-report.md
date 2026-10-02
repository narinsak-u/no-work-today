# Task 3 Implementation Report

## Files changed

- `skills/to-backlog/SKILL.md`
  - Added the independently installable `to-backlog` skill with required frontmatter and discovery description.
  - Constrained output to `docs/backlog.md`, with `docs/` creation when absent and no modification of unrelated files or Git state.
  - Defined the five allowed statuses (`Todo`, `In Progress`, `Blocked`, `Needs Review`, `Done`) and three allowed priorities (`High`, `Medium`, `Low`).
  - Added conservative candidate filtering, stable never-reused `BL-###` allocation, evidence-backed updates, explicit blocker/dependency handling, and completion-record preservation.
- `skills/to-backlog/references/backlog-template.md`
  - Added the local template for `docs/backlog.md`.
  - Defines all five status sections, stable IDs, statuses, priorities, context, tasks, related work, files, dependencies, blockers, and completion fields.
  - Labels the item block as authoring guidance so it is not copied as an extra section into generated backlog files.
- `.superpowers/sdd/2026-10-02-project-memory-skills/task-3-report.md`
  - This implementation report.

No unrelated repository files were modified.

## RED pressure scenario (before writing)

I ran a fresh-context, read-only dry run without the skill using this request:

```text
Create a backlog from this repository.
```

The fixture included existing `BL-001` (Done) and `BL-004` (Todo), a trivial debug-log TODO, a nested-expression TODO, a malformed-input FIXME, optional overview evidence, an uncommitted parser change, and no issue tickets or acceptance criteria.

Concrete baseline output proposed:

```text
Proposed additions:
BL-005 [Todo] [P1] Support nested expressions
BL-006 [Todo] [P1] Handle malformed input
BL-007 [Todo] [P3] Remove debug log before release
```

It preserved the visible IDs and completed item in this run and chose `docs/backlog.md`, but it still promoted every TODO, including explicitly trivial cleanup, and invented unsupported `P1`/`P3` priorities. It also proposed a scope of “defining or implementing malformed-input handling” despite no acceptance criteria. The baseline did not renumber IDs, overwrite the completed item, or write outside `docs/` in this particular response. The pressure risks were therefore: blanket TODO promotion; unsupported priority scheme; scope inferred beyond evidence; no required status/priority/output contract that would constrain future runs.

## Implementation decisions

- Kept the skill self-contained: it reads only its own `references/backlog-template.md`; `docs/overview.md` and `docs/recap.md` are optional, read-only evidence and are never modified.
- Made `docs/backlog.md` the only generated output and required creating `docs/` when absent.
- Required preserving all existing items, including `Done` items and completion records. Existing IDs are never renumbered, deleted, reopened silently, or reused.
- Required candidates to represent concrete, pick-up-worthy outcomes. Trivial cleanup, stale comments, duplicates, and speculative improvements are filtered out; TODO/FIXME comments are treated as leads rather than automatic work.
- Required exactly the five statuses and three priorities from the approved design. High and Medium require evidence; when no severity evidence exists, Low is the conservative default and the missing priority basis is recorded.
- Required explicit `Context`, finite `Tasks`, `Related`, `Files`, `Depends on`, `Blocked by`, and completion fields. Unknowns use `Unknown` or `Needs verification`; unsupported requirements, deadlines, dependencies, blockers, and completion claims are prohibited.
- Kept Git state contextual: uncommitted changes and branch position are not completion evidence or automatic backlog items.
- Made the template’s five status sections complete and stable while explicitly excluding its authoring-only item-format instructions from generated output.

## GREEN pressure scenario (after writing)

I repeated the request with the skill and local template loaded in a fresh-context, read-only dry run. The fixture also stated that nested-expression support was explicitly blocked by a missing grammar fixture.

The final run preserved `BL-001` and `BL-004` unchanged, filtered the trivial debug-log TODO, promoted only the nested-expression and malformed-input gaps, and assigned new IDs `BL-005` and `BL-006`. It used only allowed statuses (`Blocked` for the missing grammar fixture and `Needs Review` for unspecified malformed-input behavior) and used conservative `Low` priorities because no urgency or impact evidence supported `High` or `Medium`. It recorded the missing grammar fixture under `Blocked by`, used `None` for unsupported dependencies, and did not treat the uncommitted parser change or branch-ahead state as completed work. It confirmed the only intended output path was `docs/backlog.md` and did not include the template’s authoring guidance section.

The first GREEN run exposed two wording loopholes: it selected unsupported `Medium` priorities and copied the template’s authoring section into the proposed output. I closed both by adding the conservative `Low` fallback and explicitly marking `Item format` as authoring guidance that must not be copied, then reran the GREEN scenario successfully.

## Exact checks run and outputs

1. Required files:

   ```text
   $ test -f skills/to-backlog/SKILL.md && test -f skills/to-backlog/references/backlog-template.md && printf 'required files present\n'
   required files present
   ```

2. Contract assertions over both new skill files (frontmatter, discovery keywords, output path, five statuses, three priorities, required template fields, evidence rules, optional context, and authoring-guidance exclusion):

   ```text
   $ Python contract assertions (functions.eval)
   backlog contract assertions passed
   ```

3. Whitespace check:

   ```text
   $ git diff --check -- skills/to-backlog/SKILL.md skills/to-backlog/references/backlog-template.md
   [no output; exit 0]
   ```

4. Line count:

   ```text
   $ wc -l skills/to-backlog/SKILL.md skills/to-backlog/references/backlog-template.md
         38 skills/to-backlog/SKILL.md
         50 skills/to-backlog/references/backlog-template.md
         88 total
   ```

5. Skill implementation commit:

   ```text
   $ git add skills/to-backlog && git commit -m "feat: add project backlog skill"
   [feat/project-memory-skills 2d575c4] feat: add project backlog skill
    2 files changed, 88 insertions(+)
    create mode 100644 skills/to-backlog/SKILL.md
    create mode 100644 skills/to-backlog/references/backlog-template.md
   ```

## Self-review findings

- Frontmatter uses exactly `name: to-backlog`.
- The description begins with `Use when...` and mentions unfinished work, TODOs, blockers, priorities, stable backlog IDs, and `docs/backlog.md`.
- The skill owns only `docs/backlog.md` and depends only on its own local reference file; optional project-memory files are read-only context.
- The template and workflow agree on all five statuses, all three priorities, stable IDs, required item fields, and completion records.
- The RED scenario demonstrated the concrete failure modes required by the brief: trivial TODO promotion and unsupported priority/scope choices. It did not renumber or overwrite in that sample, so the skill explicitly prohibits those risks rather than claiming the baseline did so.
- The first GREEN scenario found and closed two loopholes before the final GREEN run: copying authoring guidance into output and choosing unsupported `Medium` priorities.
- No target-project `docs/backlog.md` was created during dry runs because both pressure scenarios were explicitly read-only; this leaves the target repository untouched while testing the skill’s instructions.
- The implementation commit contains only the two Task 3 skill files. The report is the only additional Task 3 deliverable.

## Commit hash

`2d575c4` — `feat: add project backlog skill`

## Concerns

None. The skill intentionally does not create a sample `docs/backlog.md` in this distribution repository; it guides an agent operating in a target project and keeps the distribution worktree limited to the Task 3 skill, local template, and required report.
