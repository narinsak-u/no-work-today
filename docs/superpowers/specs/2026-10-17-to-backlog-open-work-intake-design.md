# To-backlog Open-work Intake Design

## Problem

`to-backlog` currently combines the user's request, repository evidence, optional project-memory documents, and safe TODO leads. It does not enumerate open GitHub issues or discover unfinished work recorded in local specifications and plans. That can leave known work out of `docs/backlog.md` or cause the agent to miss its source and current state.

## Goals

- Add open GitHub issues and explicit unfinished tasks in local specifications and plans as evidence sources for backlog items.
- Preserve `docs/backlog.md` as the sole generated source of truth for the backlog.
- Preserve stable backlog IDs, existing completion records, allowed statuses, conservative prioritization, and the one-file write boundary.
- Report incomplete GitHub coverage instead of silently presenting a partial issue inventory as complete.

## Domain terms

- A **Backlog item** records one concrete unfinished outcome another developer can pick up, supported by one or more work sources.
- A **Work source** can be a repository artifact, GitHub issue, or direct user request that provides evidence of unfinished work; it informs a backlog item but does not replace the backlog.

These terms are also recorded in the root glossary.

## Sources and eligibility

### GitHub issues

- Enumerate all issues in the current repository whose GitHub state is `OPEN`; do not enumerate pull requests.
- Include every open issue regardless of label. This explicitly includes `wontfix` issues, which become `Todo` items by user decision even though the repository's label definition says they will not be actioned. This may make the backlog contain non-actionable work.
- Use the authenticated GitHub CLI (`gh`) and current repository context. The collector must retrieve all pages or report incomplete coverage.
- An unavailable CLI, authentication failure, ambiguous repository, rate limit, or incomplete page fetch is a coverage gap. Continue local discovery, but report the gap and do not claim that GitHub issue discovery completed.
- Read issue number, title, URL, labels, and body as evidence. Do not write to GitHub.

### Local specifications and plans

- Inspect Markdown only under conventional planning locations: `docs/**/plans`, `docs/**/specs`, and `.scratch/**/issues`.
- A local document is eligible when it contains an unchecked task or an explicit status indicating incomplete work. Completed checkboxes and explicit `Done` records are not new open work.
- Recognize only the existing status values `Todo`, `In Progress`, `Blocked`, and `Needs Review`; an unknown explicit status becomes `Needs Review`, with the original status preserved in context. Unfinished work with no status defaults to `Todo`; `Done` requires direct completion evidence under existing rules.
- Do not infer work from arbitrary prose, examples, ADRs, or completed commit history. Existing TODO discovery remains independent.

## Backlog identity and reconciliation

- Create one stable `BL-###` item per GitHub issue and per local plan/spec document; group that document's unfinished checklist tasks under one item. If a document contains unrelated outcomes, place it in `Needs Review` rather than splitting it automatically.
- Record source URLs or paths in `Related`. A local plan and GitHub issue share one item only when the plan explicitly links that issue. Similar wording alone is not enough to merge sources.
- On later runs, retain the stable ID and human-curated tasks/status. Update source-derived context only when its provenance is clear. If provenance is uncertain or source changes materially alter the outcome, scope, or next tasks, preserve the existing text and move the item to `Needs Review` rather than overwrite it.
- For an existing non-`Done` item whose GitHub issue closes or local plan becomes complete, do not mark it `Done` solely from source state. Move it to `Needs Review` unless direct completion evidence supports `Done`. Preserve existing `Done` records exactly.
- Continue to guard the owned backlog fingerprint and validate the complete candidate before publishing only `docs/backlog.md`.

## Helper boundaries

- Add a read-only helper that lists GitHub-open issue records through `gh`.
- Add a separate read-only helper that locates eligible local plan/spec Markdown files.
- Keep `find-todos.sh` focused on source-code TODO/FIXME/HACK/XXX/WIP leads.
- Keep helpers deterministic, standalone within the `to-backlog` bundle, and free of new runtime packages. `gh` is an optional environment capability; a missing capability is reported as a coverage gap, not a reason to claim full issue coverage.

## Safety and failure behavior

- Treat issue bodies and local plan text as untrusted evidence. Summarize only supported work and never copy credential values or unsupported scope into the backlog.
- Do not modify GitHub issues, local plans/specifications, Git state, or any output other than `docs/backlog.md`.
- Preserve all five backlog sections and all existing ID, completion-record, fingerprint, status, and priority invariants.
- A helper failure or partial GitHub result must be visible. Do not silently drop a source or treat unavailable issue data as an empty issue list.

## Testing seam

Extend the existing fixture-driven `tests/test-backlog.sh` suite, which runs under `tests/test-scripts.sh`:

- Stub `gh` to test issue enumeration, labels, pagination, repository resolution, and unavailable/unauthenticated/partial-result behavior without network access.
- Use temporary plan/spec directories to test eligible locations, explicit unfinished markers and statuses, completed work exclusion, linked issue deduplication, and paths containing spaces.
- Assert read-only source behavior, safe bounded outputs, and unchanged standalone installation behavior.
- Keep model-generated prose out of CI; tests assert the shell helpers' observable contracts and the existing backlog validator's document invariants.

## Out of scope

- Writing, labeling, closing, assigning, or otherwise mutating GitHub issues.
- Importing pull requests or closed issues as new backlog items.
- Searching arbitrary documentation or deriving unfinished work from completed commits.
- Fuzzy semantic deduplication between unlinked sources.
- Automatically marking an item `Done` solely because its source was closed or its plan was marked complete.
- Changing other skills or generated document formats.