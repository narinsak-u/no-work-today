# Project Overview

## Purpose

DGA Dashboard 2026 shows Thailand Digital Government Agency survey results. Visitors can browse national results; signed-in organization viewers see department or province scores and PDFs. Operators prepare agency reports offline (`README.md`, `report-pdf/README.md`).

## Tech Stack

- **React**: Builds the dashboard interface (`apps/web/package.json`).
- **TanStack Router**: Handles browser navigation (`apps/web/package.json`).
- **Tailwind CSS**: Styles the dashboard (`apps/web/package.json`).
- **ApexCharts**: Renders dashboard charts (`apps/web/package.json`).
- **Vite**: Builds web assets (`apps/web/package.json`).
- **Axum**: Serves the API and website (`crates/server/Cargo.toml`).
- **Tokio**: Runs asynchronous server tasks (`crates/server/Cargo.toml`).
- **SQLx**: Connects the server to SQLite (`crates/server/Cargo.toml`).
- **SQLite**: Stores authentication data and an overview snapshot (`crates/server/migrations/`).
- **docxtpl**: Fills report templates (`report-pdf/requirements.txt`).
- **python-docx**: Creates and reads report documents (`report-pdf/requirements.txt`).
- **Playwright**: Captures dashboard charts and exports PDFs (`apps/web/scripts/`).
- **LibreOffice**: Converts report documents to PDF (`report-pdf/README.md`).

## Project Tree

```text
apps/web/       Dashboard and organization views
crates/server/  API, sign-in, and PDF delivery
report-pdf/     Data preparation and agency report publishing
```

## Workflow

**Partial: 7 workflows are visible in the repository. External schedules and production deployment triggers are undocumented.**

| Workflow | Purpose | Evidence |
|---|---|---|
| Public overview | Loads generated data and renders national charts. | `apps/web/src/app.tsx` |
| Organization sign-in | Restores a session and opens the matching department or province dashboard. | `apps/web/src/hooks/use-auth-session.ts`, `apps/web/src/organization/hooks/use-organization-auth-session.ts` |
| Dashboard PDF export and download | Exports PDFs with Chromium and serves the public or identity-selected artifact. | `apps/web/scripts/export-dashboard.ts`, `crates/server/src/dashboard.rs` |
| Refresh source data | Downloads or copies source files, then regenerates report and browser data. | `report-pdf/src/integrations/`, `apps/web/package.json` |
| Publish and download agency reports | Renders and validates PDFs, updates the manifest, and serves reports to signed-in viewers. | `report-pdf/src/publication/`, `crates/server/src/report.rs` |
| Retry failed reports | Retries failed manifest records with existing inputs and chart assets. | `report-pdf/src/publication/publish_reports.py`, `report-pdf/src/publication/report_publication.py` |
| Production image | Packages the web app, API, and report artifacts in one serving image. | `Dockerfile`, `docker/entrypoint.sh`, `crates/server/src/app.rs` |

## API Endpoints

**Complete: 9 registered method and path pairs.** Routes are mounted from `crates/server/src/api.rs` at `/api` in `crates/server/src/app.rs`.

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/health` | Check server health. | Public |
| GET | `/api/dashboard/overview` | Read the overview snapshot. | Public |
| GET | `/api/dashboard/overview.pdf` | Download the public dashboard PDF. | Public |
| POST | `/api/signin` | Sign in and receive a JWT. | Public |
| GET | `/api/me` | Read the bearer token claims. | Bearer JWT |
| GET | `/api/me/report.pdf` | Download the signed-in organization report. | Bearer JWT |
| GET | `/api/me/dashboard.pdf` | Download the signed-in organization dashboard PDF. | Bearer JWT |
| GET | `/api/report/:filename` | Retired route; returns HTTP 410. | Public |
| GET | `/report-pdf/*path` | Deny direct artifact access; returns HTTP 404. | Public |

The browser routes `/`, `/department`, and `/province` are client-side routes. Unknown `/api/*` paths return JSON 404 responses.

## Scripts

Commands were not run during this catchup. Commands that write files are marked.

| Command | Purpose and source | Effects |
|---|---|---|
| `just dev` / `just dev-api` | Run web and API, or API alone (`Justfile`). | Writes local database and generated web data. |
| `bun run typecheck` / `bun run test` | Check web types and run Vitest (`package.json`). | |
| `cargo test -p dga-dashboard-server --test api` | Run API integration tests (`crates/server/tests/api.rs`). | |
| `cd report-pdf && PYTHONPATH=src .venv/bin/python -m unittest discover -s tests -t . -p 'test_*.py'` | Run report tests (`report-pdf/README.md`). | |
| `bun run build` | Regenerate browser data and build the web app (`apps/web/package.json`). | Writes generated JSON and `apps/web/dist/`. |
| `just publish-reports` / `just retry-reports` | Publish reports or retry failures (`Justfile`). | Writes PDFs and the published-report manifest. |
| `sh tests/docker-smoke.sh` | Check the production container (`tests/docker-smoke.sh`). | Creates an image and temporary container, then cleans up. |

<!-- skill-state
output_sha256: 7c933162e3357800d5245fb90c630fdab79d2d3c8121ac78f1d663e7cc87a91a
-->
