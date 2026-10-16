# Project Overview

> **Fictional example only.** Lantern Notes, its files, commands, technologies, workflows, and routes are invented to show the required format; none is evidence about a real repository or deployment.

## Purpose

Lantern Notes is an imagined web service for organizing private reading notes and sharing selected notes with a small team. The browser client lets a member save, search, and share notes.

## Tech Stack

- Fictional TypeScript and Node.js HTTP application with a browser client.
- Fictional PostgreSQL store, background queue, and search index. Versions are deliberately unspecified.

## Project Tree

```text
src/server.ts                 fictional startup and HTTP router mounting
src/routes/notes.ts           fictional note and sharing handlers
src/domain/notes.ts           fictional validation and membership rules
src/storage/postgres.ts       fictional persistent note and member records
src/workers/index-refresh.ts  fictional asynchronous search indexing
package.json                  fictional project scripts and dependencies
```

The browser calls the HTTP router, the domain rules guard reads/writes to PostgreSQL, and queued note changes reach the indexing worker. To start reading, open `README.md` for setup, `src/server.ts` for mounts, `src/routes/notes.ts` with `src/domain/notes.ts` for behavior, then storage, worker, and tests. Every link and path in a real overview needs repository evidence.

## Workflow

**Complete — 5 fictional workflows.** Completeness here describes only the invented scenario, never an uninspected real repository.

| Workflow | Purpose |
|---|---|
| Save and index a note | Validate a create or update, persist the note, and queue an index refresh. |
| Search notes | Restrict indexed results to the caller's accessible notes. |
| Open a shared note | Check membership before returning the note. |
| Change note access | Grant or revoke a team member's access. |
| Retry failed index refresh | Retry a transient indexing failure until search catches up. |

### Save and index a note

```text
Authenticated create or update request
  ↓
Validate content and membership
  ↓
Persist note in PostgreSQL
  ↓
Queue index refresh
  ↓
Return note identifier
```

### Change note access

```text
Owner requests grant or revoke
  ↓
Verify owner and target member
  ↓
Update sharing records
  ↓
Confirm permission change
```

### Retry failed index refresh

```text
Index update fails temporarily
  ↓
Worker recognizes retryable failure
  ↓
Queue another attempt
  ↓
Update search index
```

<details>
<summary>Other workflow diagrams (2)</summary>

#### Search notes

```text
Search request
  ↓
Apply membership filter
  ↓
Query index
  ↓
Return matching notes
```

#### Open a shared note

```text
Shared-note request
  ↓
Check caller membership
  ↓
Load note from PostgreSQL
  ↓
Return note if access is allowed
```

</details>

## API Endpoints

**Complete — 7 fictional HTTP endpoints.** Imagined router registrations mount note routes at `/api/v1`; the health route is registered at `/health`. A real overview must confirm every pair in source before asserting this count.

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/v1/notes` | Search notes | Authenticated |
| POST | `/api/v1/notes` | Create a note and queue indexing | Authenticated |
| GET | `/api/v1/notes/:noteId` | Read a shared note | Authenticated |
| PATCH | `/api/v1/notes/:noteId` | Update and reindex a note | Authenticated |
| POST | `/api/v1/notes/:noteId/shares` | Grant a member access | Authenticated |
| DELETE | `/api/v1/notes/:noteId/shares/:memberId` | Revoke access | Authenticated |
| GET | `/health` | Liveness check | Public |

## Scripts

These fictional `package.json` commands were **not exercised**; inspect the real project's manifest and target environment before using any commands.

- `npm run dev` — start the fictional service locally; not exercised.
- `npm test` — run fictional behavior checks; not exercised.
- `npm run build` — prepare a fictional build; not exercised.
- `npm run db:migrate` — **changes the database**; confirm the target before running, never run based on this example.

## Important Notes

- Authentication and membership checks protect private notes; a real overview must verify these boundaries before recommending changes.
- Store and queue configuration names may be documented, but never copy credential values or sensitive connection strings. Deployment and search-index service settings are **Needs verification**.
- These examples are not evidence. Confirm every path, workflow, route, command, and invariant against the target repository.

<!-- skill-state
output_sha256: 7148538c5f096f6573e76c52c83ed01a0b8c969bec46a1cfa57f174070891e46
-->
