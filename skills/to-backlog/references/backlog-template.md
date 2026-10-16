# Project Backlog

Use this file as the complete shape for `docs/backlog.md`. Keep all five status sections, even when one is empty. Only promote evidenced, pick-up-worthy work with a concrete outcome and a finite task list; omit fields that do not apply instead of filling them with `None`, `—`, or `Not completed`.

**Allowed statuses:** `Todo` · `In Progress` · `Blocked` · `Needs Review` · `Done`

**Allowed priorities:** `High` · `Medium` · `Low`

**ID rule:** Every item has a stable `BL-###` ID. IDs are never renumbered or reused, including IDs of completed items.

**Section invariant:** Place each item under exactly one heading matching its `Status`. When a status changes, move the complete item block to the matching section before saving.

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

Place each item under the heading matching its `Status`. The four core fields are required:

### BL-### — [Concrete outcome]

- **Status:** [Todo | In Progress | Blocked | Needs Review | Done]
- **Priority:** [High | Medium | Low; explain uncertain priority in Context]
- **Context:** [Specific repository evidence for this outcome, not a vague reminder]
- **Tasks:**
  - [ ] [Finite next action supported by the evidence]

Add `Related`, `Files`, `Depends on`, and `Blocked by` only when supported and useful; do not write placeholder fields. A `Blocked` item names its actual blocker. Do not add completion fields to unfinished items. For `Done`, check off completed tasks and include direct, verified evidence:

- **Completion evidence:** [Verified diff, commit, command result, or review evidence]

Include `Completed on`, `Completion commit`, and `Completion notes` only when known and useful. Existing completion fields and the whole completed item must be retained exactly on later updates, including older `Completion: Completed` records.
