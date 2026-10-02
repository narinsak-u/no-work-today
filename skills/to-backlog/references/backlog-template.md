# Project Backlog

Use this file as the complete shape for `docs/backlog.md`. Keep all five status sections, even when a section has no items. Replace bracketed placeholders with repository evidence; use `Unknown`, `Needs verification`, or `None` rather than guessing.

**Allowed statuses:** `Todo` · `In Progress` · `Blocked` · `Needs Review` · `Done`

**Allowed priorities:** `High` · `Medium` · `Low`

**ID rule:** Every item has a stable `BL-###` ID. IDs are never renumbered or reused, including IDs of completed items.

## In Progress

<!-- Items with verified active work. -->

## Todo

<!-- Concrete, pick-up-worthy work not yet started. -->

## Blocked

<!-- Work that cannot proceed because an explicit blocker is recorded below. -->

## Needs Review

<!-- Evidence-backed candidates whose scope, priority, or next decision is unresolved. -->

## Done

<!-- Completed items; preserve their completion records. -->

## Item format (authoring guidance; do not copy this section into `docs/backlog.md`)

Copy this block for each item and place it under the section matching its `Status`. The generated backlog contains item blocks under the five status sections, not this instructional heading.

### BL-### — [Short outcome]

- **Status:** [Todo | In Progress | Blocked | Needs Review | Done]
- **Priority:** [High | Medium | Low]
- **Context:** [Evidence-backed reason this work exists; include `Unknown` or `Needs verification` when necessary.]
- **Tasks:**
  - [ ] [Finite, pick-up-worthy task supported by evidence]
- **Related:** [Related issue, commit, document, or backlog item; `None` when absent]
- **Files:** [`path/to/relevant/file` — why it matters; `None` when no file is supported]
- **Depends on:** [BL-### prerequisite(s), or `None`]
- **Blocked by:** [Explicit blocker and evidence, or `None`]
- **Completion:** [Not completed | Completed]
  - **Completed on:** [YYYY-MM-DD, or `—`]
  - **Completion commit:** [commit hash, or `—`]
  - **Completion evidence:** [Verified command, diff, or review evidence; `—` until done]
  - **Completion notes:** [What was completed; `—` until done]
