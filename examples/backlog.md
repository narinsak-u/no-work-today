# Project Backlog

> **Fictional example only.** This document demonstrates the `to-backlog` shape for an invented Lantern Notes project. It contains no real issue, priority, repository, or completion history.

## In Progress

<!-- Items with verified active work. -->

## Todo

### BL-001 — Export notes without losing attachments (fictional)

- **Status:** Todo
- **Priority:** Low
- **Context:** In this fictional repository, the export action drops attachment links in `src/domain/notes.ts`; impact beyond the affected action has not been established.
- **Tasks:**
  - [ ] Preserve attachment references when serializing exported notes.
  - [ ] Add an export test with an attached note.
- **Files:** `src/domain/notes.ts` — fictional export mapping

## Blocked

<!-- Work that cannot proceed because an explicit blocker is recorded below. -->

## Needs Review

### BL-002 — Decide search index retention before cleanup (fictional)

- **Status:** Needs Review
- **Priority:** Low
- **Context:** In this fictional repository, `src/workers/index-refresh.ts` leaves expired entries in the index; the retention requirement is not documented, so deletion is not yet safe to scope.
- **Tasks:**
  - [ ] Confirm the retention requirement with the product owner and record the decision.
  - [ ] Scope the index cleanup using that requirement.
- **Files:** `src/workers/index-refresh.ts` — fictional index refresh path

## Done

### BL-003 — Document local setup (fictional)

- **Status:** Done
- **Priority:** Low
- **Context:** In this fictional repository, the setup instructions were missing a local test command.
- **Tasks:**
  - [x] Add the local test command to the setup instructions.
- **Completion evidence:** Fictional reviewed diff `docs/setup.md` adds the local test command and its expected output. No real repository work is claimed here.
