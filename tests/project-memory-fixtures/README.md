# Project-memory black-box fixtures

This is a **manual model-invocation test kit**, not a skill runner. Invoke each natural-language skill in a capable assistant session with the repository skill installed/selected, pointed at the named disposable fixture. Ask it to create/update the project overview, backlog, or recap from repository evidence. Do not ask it to inspect or test skill source. The validator reads generated documents, exact bytes, fixture files, and Git state—not prompt wording.

## Setup

Requires Python 3.10 or newer (the scripts use built-in generic annotations and `|` union types).

From the repository root, create a new workspace outside any project checkout. Its `.control/` evidence directory is a sibling of all fixture repos, never inside them:

```sh
python3 tests/project-memory-fixtures/generate.py /tmp/project-memory-skill-fixtures
```

The workspace must be absent or empty. Generation creates isolated catchup/backlog repositories and a recap repository with 1,105 commits. Use only these disposable repositories as targets. Run validator commands from the source repository root.

## Repeatable fingerprints and owned outputs

For `catchup-valid` and `backlog-valid`, invoke the relevant skill once and then a second time without staging or committing its owned document. After **each** invocation run:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures catchup-valid
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures backlog-valid
```

The check requires a valid fingerprint and dirty owned output, all expected content invariants, and no other fixture paths written. Backlog begins with a clean tracked legacy file containing completed `BL-014`; catchup begins without an output.

For an invalid fingerprint, first invoke catchup in `catchup-invalid` or backlog in `backlog-invalid`, then arm an intentional user edit:

```sh
python3 tests/project-memory-fixtures/validate.py arm-invalid /tmp/project-memory-skill-fixtures catchup-invalid
# or backlog-invalid
```

Invoke that skill again against its edited fixture, then validate preservation:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures catchup-invalid
# or backlog-invalid
```

The byte digest is saved only in `.control/`. The edit must remain invalid and byte-for-byte unchanged after the skill stops.

## Legacy behavior

Invoke the applicable skill once in each named fixture, then run `check` for it:

- `catchup-legacy-tracked`, `backlog-legacy-tracked`: clean tracked, unmarked output; adopt and fingerprint it.
- `catchup-legacy-untracked`, `backlog-legacy-untracked`: untracked, unmarked output; preserve its bytes.
- `catchup-legacy-modified`, `backlog-legacy-modified`: tracked but modified, unmarked output; preserve its bytes.
- `catchup-legacy-nongit`, `backlog-legacy-nongit`: existing unmarked output outside Git; preserve its bytes.

Example: `python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures catchup-legacy-tracked`.

## Backlog assertions

The `backlog-valid` check asserts all five status sections, unique IDs above the existing completed `BL-014`, the unchanged Done completion record, allowed priorities/statuses, and section/status placement. It also verifies one-output ownership.

## Recap: bounded history, resume, and branch binding

Invoke recap in `recap-large-history`, then check its first batch:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-progress-100
```

The checker derives the latest 1,000 of 1,105 commits from Git. It asserts the first 100 are represented oldest-first exactly once; exact pending queue and `Current Point` full hashes; matching checkpoint and branch; and visible omission of older history.

Before progressing, exercise branch mismatch. In the fixture directory:

```sh
cd /tmp/project-memory-skill-fixtures/recap-large-history
git switch -c fixture-other
git commit --allow-empty -m 'branch mismatch probe'
```

Invoke recap on `fixture-other`; it must stop without changing `docs/recap.md`. Run the assertion at the source repository root, then return to the original branch:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-branch-mismatch
cd /tmp/project-memory-skill-fixtures/recap-large-history
git switch fixture-main
```

Invoke recap nine more times on `fixture-main`, without changing project history. After each invocation check the corresponding 100-commit checkpoint:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-progress-200
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-progress-300
# Continue through recap-progress-1000.
```

Each check requires an exact full-hash queue shrinking by 100 and every processed selected commit represented exactly once in order. At 1,000 the queue is empty and checkpoint equals `HEAD`. Invoke recap once more with no new commits and assert idempotent history/checkpoint:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-no-new
```

## Recap ownership guards

### Invalid fingerprint and legacy ownership

Run the `recap-invalid` scenario in this order: invoke recap once to create a managed output, arm an intentional user edit, invoke recap again, then assert preservation:

```sh

# Invoke recap once in recap-invalid first.
python3 tests/project-memory-fixtures/validate.py arm-invalid /tmp/project-memory-skill-fixtures recap-invalid
# Invoke recap again after arming.
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-invalid
```

The arm command records the edited output digest in `.control`; the final check requires those exact bytes to remain and the fingerprint to remain invalid.

Invoke recap once in each unmarked legacy fixture, then check it:

```sh
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-legacy-untracked
python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-legacy-modified
```

Both checks require byte-for-byte preservation and no fingerprint adoption. The first additionally requires the output to remain untracked; the second requires its tracked output to remain dirty. Expected digests and the original dirty-state snapshot are stored in `.control`, outside the disposable repositories.

## Legacy recap branch and checkpoint boundaries

Invoke recap once in each fixture below, then run its matching validator command from the source repository root:

- `recap-legacy-branch-match`: infer `fixture-main` from the single `Current Point` HEAD line, adopt the clean tracked legacy recap, and preserve its existing history entry.
- `recap-legacy-branch-missing`: the legacy HEAD line has no branch; preserve the output bytes and ask for direction.
- `recap-legacy-branch-ambiguous`: competing legacy HEAD lines name different branches; preserve the output bytes.
- `recap-legacy-branch-mismatch`: an unambiguous legacy branch differs from the current branch; preserve the output bytes.
- `recap-rewritten-checkpoint`: its saved checkpoint exists on `fixture-rewritten` but is not an ancestor of `fixture-main`; preserve the output bytes and cursor.

Example command: `python3 tests/project-memory-fixtures/validate.py check /tmp/project-memory-skill-fixtures recap-legacy-branch-match`. Substitute each scenario name above. The control hashes are outside the Git fixtures.

## Scope

The scripts generate fixtures and inspect post-invocation behavior; they do not execute the natural-language skill, mutate skills, or write into user projects. `arm-invalid` is the intentional user-edit simulation; the only other fixture Git mutation is the documented branch probe. No build, lint, test, or format command is needed to execute the skills.
