# To-backlog Open-work Intake Implementation Plan

> **For agentic workers:** Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Each step uses checkbox syntax for tracking.

**Goal:** Extend `to-backlog` to discover open GitHub issues and explicitly unfinished local plans/specs, then reconcile them into `docs/backlog.md` without losing human-curated state.

**Architecture:** Keep `find-todos.sh` focused on source-code TODO comments. Add one read-only helper for paginated GitHub issue intake and one for candidate local plan/spec discovery. `SKILL.md` owns source interpretation, reconciliation, coverage-gap reporting, and the existing validated write to the backlog.

**Tech Stack:** Bash, GitHub CLI (`gh`) when available, existing standard Unix utilities, Markdown, offline shell fixtures.

**Spec:** `docs/superpowers/specs/2026-10-17-to-backlog-open-work-intake-design.md`

## Global Constraints

- Generate or update only `docs/backlog.md` in the target project; never modify GitHub issues, source plans, or specs.
- Include all open GitHub issues, including `wontfix`-labeled issues, in `Todo`; never import closed issues or pull requests as new work.
- Discover local Markdown only under `docs/**/plans`, `docs/**/specs`, and `.scratch/**/issues`, and require explicit unfinished evidence.
- Map exact local statuses `Todo`, `In Progress`, `Blocked`, and `Needs Review`; map unknown explicit statuses to `Needs Review`; map an unchecked task with no status to `Todo`.
- Preserve existing `BL-###` IDs, human-curated task text and status, source provenance, completed records, and the backlog fingerprint contract.
- Link sources into one backlog item only when the issue and local document explicitly reference one another; do not fuzzy-deduplicate.
- Use GitHub CLI's all-page request behavior. If GitHub access or pagination fails, discard any partial output, continue local discovery, and report that issue coverage is incomplete.
- Add no runtime dependency. CI tests must use fixtures and a fake `gh`; they must not access GitHub or call a model.
- Do not infer `Done` from a closed source alone; require direct completion evidence. Conflicting completion and unfinished markers require `Needs Review`.
- Treat GitHub issue bodies and local document text as untrusted evidence; summarize only supported work and never copy credential values.
- Preserve current conservative priority rules. Record source URLs or paths in `Related`; update source-derived context only when provenance is clear, and move materially changed or ambiguous existing items to `Needs Review`.

## File Structure

- Create `skills/to-backlog/scripts/list-open-issues.sh`: read-only GitHub issue collector. Accepts the target repository root; emits newline-delimited JSON issue records only after a successful complete request.
- Create `skills/to-backlog/scripts/find-open-plans.sh`: read-only candidate finder. Accepts the target repository root; emits shell-escaped, repository-relative candidate paths, not document bodies.
- Modify `skills/to-backlog/SKILL.md`: orchestrate issue, local-plan, and existing TODO sources; preserve the existing backlog validation and safe-write contract.
- Modify `tests/test-backlog.sh`: cover both helpers with isolated temporary repositories and deterministic fixtures.
- Modify `tests/test-install.sh`: prove the two helpers work from an isolated installation of `to-backlog`.
- Modify `README.md`: explain that authenticated `gh` access is optional and only needed for GitHub issue intake.
- Modify `CHANGELOG.md`: add the completed change under `Unreleased`.
- Leave `find-todos.sh`, the backlog template, and the validator unchanged unless the tests expose a required contract gap; no second TODO scanner or generated-document schema is planned.

### Task 1: Collect every available open GitHub issue

**Files:**
- Create: `skills/to-backlog/scripts/list-open-issues.sh`
- Test: `tests/test-backlog.sh`

**Interfaces:**
- Consumes: `ROOT` as the first argument; the target repository's GitHub context from running `gh` after changing directory to `ROOT`.
- Produces: zero or more NDJSON objects on stdout with `number`, `title`, `body`, `labels` (label names), and `url`; excludes pull requests. Exit zero with no records means a successful empty issue list. Any missing CLI, missing repository context, authentication/API error, or incomplete page fetch exits nonzero, writes a concise coverage diagnostic to stderr, and writes no records to stdout.

- [ ] **Step 1: Add fixture-based red cases to `tests/test-backlog.sh`.** Create a temporary `gh` executable that records its arguments and working directory, prints configured NDJSON fixture data, and can print one partial record before exiting nonzero. Include an open issue labeled `wontfix` in the successful fixture. Assert the helper runs in `ROOT`, passes `--paginate`, requests `state=open` with `per_page=100`, applies a `pull_request == null` filter, and returns the complete fixture on success. Simulate no CLI, a non-repository context, and an authentication/API error; each must fail without stdout.

  The stub's failure mode should exercise the no-partial-output contract:

  ```bash
  printf '%s\n' '{"number":99,"title":"Partial page","body":null,"labels":[],"url":"https://github.com/example/project/issues/99}'
  exit 1
  ```

- [ ] **Step 2: Run the focused test and observe the red result.** Run `bash tests/test-backlog.sh`; the new collector case must fail because the helper does not yet exist. Keep the test offline; no credentials or network are used.
- [ ] **Step 3: Implement `list-open-issues.sh`.** Validate the repository directory and `gh` availability before making a request. Change directory only in a subshell rooted at `ROOT`; capture the full response in a temporary file, clean it with a trap, and print it only after success. Use this GitHub CLI request shape:

  ```bash
  gh api --paginate \
    --jq '.[] | select(.pull_request == null) | {number, title, body, labels: [.labels[]?.name], url: .html_url}' \
    'repos/{owner}/{repo}/issues?state=open&per_page=100'
  ```

  The `gh api --paginate` contract fetches sequential pages. Keep GitHub CLI stderr visible for diagnosis, but emit a short helper-owned coverage message on failure. Never let a failed later page expose previously captured records.
- [ ] **Step 4: Run the focused test and verify green behavior.** Run `bash tests/test-backlog.sh`. Confirm successful output contains both records, retains `wontfix`, and the captured command contains the open-state, pagination, and pull-request exclusion contract. Confirm a failed fetch exits nonzero with empty stdout, and missing `gh` also exits nonzero without output.
- [ ] **Step 5: Commit the independently tested helper.** Run `git diff --check`, then commit only the collector and its tests as `feat(to-backlog): collect open GitHub issues`.

### Task 2: Find explicitly unfinished local plans and specs

**Files:**
- Create: `skills/to-backlog/scripts/find-open-plans.sh`
- Test: `tests/test-backlog.sh`

**Interfaces:**
- Consumes: `ROOT` as the first argument.
- Produces: one `PLAN_FILE=` line per candidate, containing a Bash-escaped repository-relative Markdown path. Scan only Markdown beneath directories named `plans` or `specs` under `docs`, and directories named `issues` under `.scratch`. Include a document with an unchecked Markdown task or an explicit non-complete `Status:` value. An unknown explicit status remains a candidate for the skill to classify as `Needs Review`; an explicit `Done` status alone is excluded. A document with both `Done` and an unchecked task remains a candidate for conflict review.

- [ ] **Step 1: Add fixture-based red cases to `tests/test-backlog.sh`.** Create candidates under `docs/plans`, `docs/specs`, and `.scratch/<feature>/issues`, including a filename with spaces. Add fixtures for an unchecked task, `Todo`, `In Progress`, `Blocked`, `Needs Review`, an unknown status, a completed status with checked tasks, and `Done` with an unchecked task. Also add Markdown under `docs/adr` and `examples` to prove the helper excludes unrelated paths.
- [ ] **Step 2: Run the focused test and observe the red result.** Run `bash tests/test-backlog.sh`; the new finder case must fail because the helper does not yet exist.
- [ ] **Step 3: Implement `find-open-plans.sh`.** Use `find` restricted to the allowed roots and Markdown extensions; handle absent `docs` or `.scratch` as an empty result. Match unchecked task markers and explicit status fields without printing document contents. Exclude only explicit `Done` status records with no unchecked task; do not treat other unknown status values such as `Closed` or `Resolved` as complete, because they must be surfaced as `Needs Review`. Emit paths through `printf 'PLAN_FILE=%q\n'` and sort the encoded lines for deterministic output. Stage results in a temporary file and publish only after a successful traversal so a failed scan cannot look complete.
- [ ] **Step 4: Run focused assertions and verify green behavior.** Run `bash tests/test-backlog.sh`. Assert the allowed directories' unfinished candidates are listed, completed-only/ADR/example documents are absent, an unknown status is included for `Needs Review`, a `Done` document with an unchecked task is included for conflict review, and paths with spaces remain unambiguous. Assert output contains paths only, not source bodies, and source fixtures are byte-identical before and after discovery.
- [ ] **Step 5: Commit the independently tested finder.** Run `git diff --check`, then commit only the finder and its tests as `feat(to-backlog): discover unfinished plans`.

### Task 3: Integrate the sources into `to-backlog` and document the contract

**Files:**
- Modify: `skills/to-backlog/SKILL.md`
- Modify: `tests/test-install.sh`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: `list-open-issues.sh ROOT`, `find-open-plans.sh ROOT`, and the existing `find-todos.sh ROOT` output.
- Produces: a reconciled `docs/backlog.md` through the existing validator and safe-write flow; reports when GitHub issue coverage is incomplete instead of presenting a partial or falsely complete scan.

- [ ] **Step 1: Extend the standalone-install test.** In `tests/test-install.sh`, create a local plan fixture and a fake `gh` executable, then invoke both new helpers from the copied standalone `to-backlog` directory. Verify the GitHub helper returns the fixture and the local finder returns the plan path. The test must not require a remote, authentication, or sibling skill.
- [ ] **Step 2: Run the standalone test before integration changes.** Run `bash tests/test-install.sh` and confirm the newly added helper invocations pass using only the installed `to-backlog` directory and fixture tools.
- [ ] **Step 3: Update the `to-backlog` workflow.** Add the two helper calls before reconciliation. On GitHub helper failure, discard its stdout, mark issue coverage incomplete, continue with local plan/spec discovery and existing TODO discovery, and disclose the coverage gap in the result. On local plan discovery failure, stop before writing because local coverage is unknown. Create one item per issue or plan/spec document and group that document's unfinished tasks; put documents with unrelated outcomes in `Needs Review`. Combine issue and document only on an explicit cross-reference. Record source URLs or paths in `Related`. Map open issues (including `wontfix`) to `Todo`; ignore closed sources as new work. If a previously known non-`Done` source closes or completes, move its item to `Needs Review` unless direct completion evidence supports `Done`; preserve existing `Done` records exactly. Apply the exact local status mappings in the global constraints, retaining unknown original status in context. Update source-derived context only when provenance is clear; material changes to outcome, scope, or remaining tasks require `Needs Review`. Preserve human-curated tasks/status, stable IDs, conservative priorities, completion evidence, validation, fingerprinting, credential safety, and the only-write-to-`docs/backlog.md` boundary.
- [ ] **Step 4: Update repository documentation.** In `README.md`, state that an authenticated `gh` CLI is optional and only enables GitHub issue intake; without it, `to-backlog` continues local discovery and reports incomplete GitHub coverage. Add one concise `Unreleased` changelog bullet describing GitHub issue and local plan/spec intake.
- [ ] **Step 5: Run focused and standalone checks.** Run `bash tests/test-backlog.sh` and `bash tests/test-install.sh`. Confirm the old TODO helper scenarios, backlog validation, no-network issue fixture, and independent installation all pass.
- [ ] **Step 6: Review the integrated workflow against the approved design.** Confirm the skill does not claim a complete scan after a GitHub error, does not turn closed sources into `Done`, does not merge unrelated records, and writes no source document. Run `git diff --check`, then commit as `feat(to-backlog): reconcile open work sources`.

### Task 4: Verify the complete shell suite and smoke the combined discovery path

**Files:**
- Modify only if a regression appears: `tests/test-backlog.sh`, `tests/test-install.sh`, or the helper/skill files from Tasks 1–3.

- [ ] **Step 1: Run the complete offline suite.** Run `bash tests/test-scripts.sh` from the repository root. This includes standalone installation and the backlog helper suite; do not run live GitHub queries.
- [ ] **Step 2: Exercise discovery and reconciliation rules against a disposable fixture.** Use a temporary repository containing one open issue response from fake `gh`, one explicitly linked unfinished plan, one unlinked unfinished plan, one completed plan, and one source-code TODO. Run all three helpers and verify their source lists remain distinct and unchanged. Review the `SKILL.md` workflow against the fixture: the linked pair forms one item; the unlinked sources remain separate; the completed source does not become `Done` without direct evidence; and an unavailable GitHub source is reported while local discovery continues. Keep generated model prose out of CI; this is a manual prompt-contract review, not an assertion about wording.
- [ ] **Step 3: Inspect repository changes and commit any verification-driven fix.** Run `git diff --check` and inspect `git status --short`; ensure generated fixture files were removed and only intended skill, test, README, and changelog files changed. If the smoke test exposes a defect, add a failing fixture assertion first, fix it, rerun the affected test and full suite, and commit the fix.

## Self-review checklist

- **Spec coverage:** GitHub issue collection and coverage gaps — Task 1; local plan/spec discovery and markers — Task 2; source reconciliation, statuses, explicit linking, safe backlog output, and optional `gh` documentation — Task 3; complete suite and combined smoke — Task 4.
- **No placeholders:** Every implementation step names the target file, behavior, test command, and observable result. No follow-up work is deferred.
- **Interface consistency:** Both helpers take `ROOT`; the issue helper emits NDJSON; the plan helper emits `PLAN_FILE=` Bash-escaped relative paths; `SKILL.md` consumes those exact contracts.
- **Conservative handling:** Failed GitHub fetch never publishes partial records; failed local traversal stops writes; unknown or conflicting local markers surface for review; existing completed records remain protected.
