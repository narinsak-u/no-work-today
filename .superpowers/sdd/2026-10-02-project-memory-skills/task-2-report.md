# Task 2 Implementation Report

## Files changed

- `skills/to-recap/SKILL.md`
  - Added the `to-recap` skill with the required frontmatter and discovery description.
  - Defined an incremental, checkpoint-based workflow for `docs/recap.md`.
  - Required scoped descendant history analysis, merge/rebase boundary handling, grouped commits, append-only updates, `Current Point`, and committed/uncommitted separation.
  - Added evidence rules that prohibit invented behavior, impact, and test results.
- `skills/to-recap/references/recap-template.md`
  - Added the skill-local recap template with scope, dated work entries, categories, status, what/why, important files, commits, impact, junior notes, verification, `Current Point`, and the exact HTML checkpoint shape.
- `.superpowers/sdd/2026-10-02-project-memory-skills/task-2-report.md`
  - This implementation report.

No unrelated repository files were modified.

## RED pressure scenario

I ran a read-only dry run before writing the skill using an unconstrained fresh-agent prompt:

```text
You are a fresh agent with no skills loaded. Fulfill this request in a read-only dry run: "Update the project recap from the last checkpoint." The repository only exposes README.md and a small skills/ directory; no recap file, checkpoint syntax, or output path is specified. Do not ask questions. Show the exact filename, headings, and workflow you would use, and state what you would do with commits, old entries, uncommitted work, and test status. You may choose conventional defaults where the request is silent.
```

The concrete output selected a root-level file instead of the required target:

```text
### Target filename

`PROJECT_RECAP.md`
```

It also invented a heading scheme (`Current Checkpoint`, `Completed Since Previous Checkpoint`, `Change History`, etc.) rather than the required `Current Point` and exact `recap-state` checkpoint. It proposed a broad fallback based on the “latest available project state” when no checkpoint was found, without a rule to create a conservative baseline and preserve an unresolved boundary. It did preserve old entries and separated uncommitted work in this particular sample, and it did not claim tests passed; those safeguards were not guaranteed by the request, however.

The baseline risks used to shape the skill were therefore:

| Pressure risk | RED observation / consequence |
| --- | --- |
| Ad hoc or root-level output | The agent chose `PROJECT_RECAP.md` because no output contract was supplied. |
| Rereading history | The fallback plan allowed scanning repository history from a latest available state when no checkpoint was known, with no descendant-only contract. |
| One entry per commit | No required grouping rule or category model was present in the request; the agent could have mapped commits directly to entries. |
| Rewriting old entries | No append-only or immutable-history rule was supplied; preservation was an agent choice rather than a contract. |
| Missing `Current Point` / checkpoint | The draft used `Current Checkpoint` and omitted the exact HTML checkpoint shape and `last_commit` / `last_updated` fields. |
| Invented verification | This sample correctly said tests were not run, but no evidence vocabulary or prohibition prevented a different baseline from claiming test success. |

## Implementation decisions

- Kept the skill self-contained: it reads only its own `references/recap-template.md` and does not depend on `to-catchup`, `task-recap`, or target-project files.
- Made `docs/recap.md` the only generated output and explicitly allowed creating `docs/` when absent.
- Made existing dated entries immutable. New entries are appended, while only the mutable `Current Point` and final checkpoint are updated.
- Used `last_commit` as the history boundary. When it is an ancestor of `HEAD`, the workflow limits committed-history inspection to `<last_commit>..HEAD`; when the boundary is missing after a rebase, force-push, or branch switch, it requires visible uncertainty instead of silently summarizing all history.
- Added explicit merge and rebase guidance so merge topology is inspected and rewritten hashes are not treated as descendants merely because commit subjects match.
- Required related commits to be grouped by coherent work rather than creating one recap item per commit; generated, formatting-only, merge, and unrelated changes remain distinguishable where their meaning differs.
- Required staged, unstaged, and untracked work to remain separate from completed committed entries.
- Required exact observed verification commands and outcomes, using `not run`, `unknown`, `Needs verification`, or `reported by commit` when evidence is unavailable.
- Included `docs/overview.md` and `docs/backlog.md` as optional, read-only context and required their claims to be checked against Git evidence.
- Used the exact required checkpoint:

  ```md
  <!-- recap-state
  last_commit: <full-or-short-commit>
  last_updated: YYYY-MM-DD
  -->
  ```

## GREEN pressure scenario

After writing both skill files, I ran the same request as a read-only dry run with `SKILL.md` and `recap-template.md` loaded. The supplied scenario had an existing `abc1234` checkpoint, `def5678` as `HEAD`, three related fix commits, one unrelated documentation commit, unstaged `src/local.ts`, and no tests run.

The observable response selected `docs/recap.md`, preserved old entries, scoped committed work to `abc1234..def5678`, grouped the three fix commits, kept the documentation commit separate, listed `src/local.ts` as uncommitted, and updated the checkpoint to `def5678`. Its verification wording was:

```text
No tests or CI commands were run in this dry run. Any checks not directly observed would be labeled `not run` or `unknown`.
```

It also reproduced the required checkpoint shape with `last_commit: def5678` and a date placeholder for the actual execution date, and explicitly stated that no historical entries would be reordered, rewritten, or deduplicated.

## Exact checks run and outputs

1. Required files:

   ```text
   $ test -f skills/to-recap/SKILL.md && test -f skills/to-recap/references/recap-template.md && printf 'required files present\n'
   required files present
   ```

2. Scoped contract assertions over both new files:

   ```text
   $ Python assertions for frontmatter, docs/recap.md, checkpoint fields, Current Point, merge/rebase, append-only, committed/uncommitted wording, and all template fields
   contract assertions passed
   ```

3. Whitespace and status check before the skill commit:

   ```text
   $ git diff --check && git status --short
   ?? skills/to-recap/
   ```

   `git diff --check` produced no output and exited successfully. The only status entry was the intended new skill directory.

4. New-file line count:

   ```text
   $ wc -l skills/to-recap/SKILL.md skills/to-recap/references/recap-template.md
         51 skills/to-recap/SKILL.md
         36 skills/to-recap/references/recap-template.md
         87 total
   ```

5. Skill implementation commit:

   ```text
   $ git add skills/to-recap && git commit -m "feat: add incremental project recap skill"
   [feat/project-memory-skills f2c1693] feat: add incremental project recap skill
    2 files changed, 87 insertions(+)
    create mode 100644 skills/to-recap/SKILL.md
    create mode 100644 skills/to-recap/references/recap-template.md
   ```

## Self-review findings

- Frontmatter uses exactly `name: to-recap`.
- The description begins with `Use when...` and mentions Git history, checkpoints, completed work, fixes, refactors, and `docs/recap.md`.
- The skill names both optional context files and reads only its own reference file.
- The template includes every required field and the exact multiline HTML checkpoint.
- The workflow explicitly addresses missing checkpoints, descendants, merges, rebases, grouping, append-only preservation, `Current Point`, `HEAD`, and separate uncommitted state.
- Verification language is conservative and evidence-based; no test status is asserted without observed output.
- The RED and GREEN dry runs exercised the target pressure scenario without writing a target `docs/recap.md`.
- The only implementation changes in the first commit are the two Task 2 skill files.

## Commit hash

`f2c1693` — `feat: add incremental project recap skill`

## Concerns

None. The skill intentionally does not create a sample `docs/recap.md`; its contract is to guide an agent operating in a target project, while this distribution repository contains only the skill and its local template.
