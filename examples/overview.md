# Project Overview

> **Fictional example only.** This describes the invented Lantern Notes project to demonstrate `to-catchup`; it is not evidence about a real repository, deployment, or history.

## 1. Purpose

Lantern Notes is a fictional web service for organizing private reading notes and sharing selected notes with a small team. The imagined API and browser client support creating, searching, and reviewing notes.

## 2. Tech Stack

- TypeScript and Node.js; versions are intentionally unspecified.
- A fictional HTTP framework, PostgreSQL, a background worker, and a search index.
- These are illustrative choices, not evidence about any real project or dependency versions.

## 3. Architecture

The fictional browser client calls an HTTP API. Domain services enforce note and membership rules; a PostgreSQL adapter persists data; a worker refreshes the search index asynchronously.

```text
Browser client → HTTP API → Domain services → PostgreSQL
                         └→ Job queue → Index worker → Search index
```

The components and relationships above are fictional and would require repository evidence in a real overview.

## 4. Main Flows

- **Fictional note creation:** API route checks request shape and identity → note service validates content and membership → PostgreSQL adapter saves → API queues an index refresh and returns the note identifier.
- **Fictional search:** API route → search service applies membership filtering → search index → filtered results. Index freshness and failure behavior need verification in a real system.
- **Fictional refresh:** worker consumes a refresh job → reads the note through the adapter → updates the index. Retry behavior is illustrative, not verified.

## 5. Core Modules

- **API routes** (`src/routes/notes.ts`): fictional HTTP boundary.
- **Identity and membership**: fictional caller and access checks.
- **Note service** (`src/domain/notes.ts`): fictional validation and sharing rules.
- **Persistence** (`src/storage/postgres.ts`): fictional SQL boundary.
- **Index worker** (`src/workers/index-refresh.ts`): fictional asynchronous refresh handler.

These module responsibilities are invented; a real overview must establish them from code.

## 6. Important Files

- `src/server.ts` — fictional application entry point.
- `src/routes/notes.ts` — fictional note request handlers.
- `src/domain/notes.ts` — fictional domain rules.
- `src/storage/postgres.ts` and `src/workers/index-refresh.ts` — fictional data and background-work boundaries.
- `test/notes.test.ts` — fictional behavior checks.

All paths are safe illustrative placeholders, not claims that these files exist.

## 7. Data & External Services

- PostgreSQL stores fictional note content and membership records.
- A fictional job transport connects the API and worker; a fictional search index supports search.
- Configuration names might include `LANTERN_NOTES_DATABASE_URL`, `LANTERN_NOTES_INDEX_ENDPOINT`, and `LANTERN_NOTES_SESSION_SECRET`. Values are deliberately omitted; use `[REDACTED]` or another safe placeholder, never real credentials or connection strings.
- Actual defaults, providers, and data-retention behavior: **Needs verification**.

## 8. Development Workflow

Install, run, test, migration, and deployment commands are **Unknown** for this fictional project and intentionally omitted. A real overview should include only commands evidenced by target-repository manifests or scripts, note whether each was exercised, and warn before commands that alter data.

## 9. Start Here

1. `README.md` — fictional purpose and supported commands, if present.
2. `src/server.ts` — fictional startup and route registration.
3. `src/routes/notes.ts` and `src/domain/notes.ts` — fictional request and rule flow.
4. `src/storage/postgres.ts`, worker code, then tests — fictional persistence and asynchronous behavior.

The reading order is illustrative; verify actual paths and priorities in the target repository.

## 10. Important Notes

- This is not a real repository overview or operational guidance.
- Never copy credentials, tokens, private keys, or sensitive connection strings into `docs/overview.md`.
- Verify every fictional path, flow, default, command, integration, and invariant against the target repository.
- Keep unsupported behavior `Unknown` or `Needs verification`; do not infer it from conventions.
