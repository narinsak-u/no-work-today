# Project Overview

> **Fictional example only.** Lantern Notes, its files, commands, technologies, workflows, and routes are invented to show the required format; none is evidence about a real repository or deployment.

## Purpose

Lantern Notes is an imagined service for private reading notes and small-team sharing. Members save, search, and share notes in the browser.

## Tech Stack

- **TypeScript**: Adds types to the browser client.
- **React**: Builds the dashboard interfaces.
- **Node.js**: Runs the HTTP service.
- **Express**: Registers note routes and access checks.
- **PostgreSQL**: Stores notes and sharing records.
- **Background queue**: Delivers index-refresh jobs to workers.
- **Search index**: Powers note search.

## Project Tree

```text
src/server.ts                 starts the service and mounts routes
src/routes/notes.ts           handles note and sharing requests
src/domain/notes.ts            validates content and membership
src/storage/postgres.ts       stores notes and members
src/workers/index-refresh.ts  refreshes the search index
package.json                  lists project commands and dependencies
```

The browser calls the router; domain rules protect storage, and queued changes reach the index worker. Start with `README.md`, then the server, routes and domain rules, storage and workers, and tests.

## Workflow

**Complete — 5 verified workflows.**

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

**Complete — 7 registered HTTP endpoints.**

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

Fictional commands below were not exercised; verify commands and target environment before use.

- `npm run dev` — start the service locally; not exercised.
- `npm test` — run behavior checks; not exercised.
- `npm run build` — prepare a build; not exercised.
- `npm run db:migrate` — **changes the database**; confirm the target before running; not exercised.

## Important Notes

- Membership checks protect private notes; verify these boundaries before changing access behavior.
- Never copy credential values or sensitive connection strings. Deployment and search-index settings are **Needs verification**.

<!-- skill-state
output_sha256: a14fe76203f4463b9af50c0ac95438d3ae358f1bc358580950b2709a92876c18
-->
