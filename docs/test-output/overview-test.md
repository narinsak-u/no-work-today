# Project Overview

## 1. Purpose

DGA Dashboard presents Thailand public agencies' digital-government assessment results: a public national overview and sign-in-gated department/province dashboards. The repository also prepares and publishes agency report PDFs for authenticated download. Evidence: `docs/ARCHITECTURE.md`, `report-pdf/CONTEXT.md`.

## 2. Tech Stack

- Bun 1.3.14, Turbo, React, TypeScript, Vite, and TanStack Router power the web workspace (`package.json`, `apps/web/package.json`).
- Rust, Tokio, Axum, SQLx, and SQLite power the API and storage (`crates/server/Cargo.toml`).
- Python, Playwright, and LibreOffice prepare report PDFs; Docker packages the web build and API (`report-pdf/README.md`, `Dockerfile`).

## 3. Architecture

```text
Report CSVs and generated inputs
  |
  v
Generators
  +--> committed JSON --> React dashboard
  +--> chart assets

Browser
  |
  v
Axum API
  +--> SQLite
  +--> published PDF files
```

## 4. Main Flows

### 📊 Dashboard data

The web build prepares JSON for browser rendering (`apps/web/package.json`, `apps/web/src/routes/index.tsx`).

```text
Report inputs and CSV snapshots
  |
  v
Web build scripts
  |
  v
Generated browser JSON
  |
  v
Overview and organization routes
```

### 🔐 Sign-in and session restore

Axum verifies the seeded SQLite user, returns a JWT, and `/api/me` restores identity (`apps/web/src/api.ts`, `apps/web/src/hooks/use-auth-session.ts`, `crates/server/src/auth.rs`).

```text
Login form
  |
  v
POST /api/signin
  |
  v
Axum auth and seeded SQLite user
  |
  v
JWT stored in session storage
  |
  v
GET /api/me
  |
  v
Restored identity
```

### 📄 Report publication and download

Offline jobs validate a batch and update `current.json`; the authenticated API selects the PDF by organization claim (`report-pdf/README.md`, `crates/server/src/report.rs`).

```text
CSV inputs and templates
  |
  v
Render charts and convert PDF
  |
  v
Validate batch and update current.json
  |
  v
Authenticated /api/me/report.pdf request
  |
  v
Organization claim selects artifact
  |
  v
Published PDF response
```

## 5. Core Modules

Selective map of functional areas; `Important Files` below is a separate reading list.

```text
apps/
└── web/
    ├── src/       — dashboard routes, UI, and client
    └── scripts/   — data generation and chart capture
crates/
└── server/
    └── src/       — Axum API, auth, and storage
report-pdf/
└── src/           — report preparation and publication
```

## 6. Important Files

- `apps/web/src/main.tsx`, `router.tsx`, `api.ts`, and `use-auth-session.ts`: browser startup, routes, and session requests.
- `crates/server/src/main.rs`, `app.rs`, `config.rs`, `auth.rs`, and `report.rs`: API setup, configuration, authentication, and report delivery.
- `Justfile`, `Dockerfile`, and `tests/docker-smoke.sh`: development commands, runtime packaging, and production smoke test.

## 7. Data & External Services

- Browser data is generated JSON under `apps/web/src/data/`; inputs and downloaded CSV snapshots are under `report-pdf/input/` and `report-pdf/csv-sources/`. Regenerate and commit snapshots when source CSVs change.
- SQLite stores the dashboard snapshot and seeded auth users. Local server defaults: `BIND_ADDR=127.0.0.1:3000`, `DATABASE_URL=sqlite://data/dashboard.sqlite?mode=rwc`; `just dev` uses `data/dashboard-dev.sqlite`.
- Configuration also includes `JWT_SECRET` (set a real secret outside development), optional `WEB_ROOT`, `REPORT_ROOT`, `REPORT_ARTIFACT_ROOT`, and `REPORT_OUTPUT_ROOT`; paths default under the repo's `report-pdf/`. Production sets these paths and binds `0.0.0.0:3000` in the image.
- CSV download integration uses Google Sheets exports; chart capture uses local Playwright Chromium; PDF conversion requires local LibreOffice (`soffice`) and bundled Thai fonts. These tools are for data/report preparation, not required for serving the already-built production app (`report-pdf/README.md`, `Dockerfile`). No managed database or cloud storage is defined in the repository.

## 8. Development Workflow

Commands are documented in manifests and `Justfile`; none were exercised during catch-up.

- Install and run: `bun install --frozen-lockfile`, `just dev` (API `127.0.0.1:3000`, web `127.0.0.1:5173`); use `just dev-api` or `just dev-web` for one service.
- Typecheck, test, and build: `bun run typecheck`, `bun run test`, `bun run build`; web builds regenerate JSON inputs.
- Check and smoke-test Rust/API: `cargo check -p dga-dashboard-server`, `cargo test -p dga-dashboard-server --test api`, `env -u WEB_ROOT sh tests/smoke.sh`, `sh tests/docker-smoke.sh` (requires Docker and a test port).
- Optional report setup: create `.venv`, install `requirements.txt`, Playwright Chromium, and LibreOffice, then run `just install-report-fonts`. Downloads and `just publish-reports` change snapshots or artifacts; review them before committing.

## 9. Start Here

1. Read `docs/ARCHITECTURE.md` and `docs/OVERVIEW.md`, then trace browser startup through `main.tsx`, `router.tsx`, and `api.ts`.
2. Trace backend setup through `main.rs`, `app.rs`, and `config.rs`; inspect `auth.rs` and `report.rs` for identity and artifact boundaries.
3. For data/report work, read `report-pdf/README.md` and `CONTEXT.md`; use `Justfile`, manifests, and API tests to choose a command.

## 10. Important Notes

- Never use the development JWT fallback in production; supply `JWT_SECRET` securely. Seed inputs include authentication data; do not copy credentials into docs or logs.
- Production serves prebuilt SPA/API and report artifacts from one Axum listener. `WEB_ROOT` controls whether SPA fallback is enabled; unknown `/api/*` routes stay JSON 404s.
- Do not edit generated `apps/web/src/routeTree.gen.ts`; update route sources and let tooling regenerate it. Web builds regenerate JSON; commit regenerated snapshots with source CSV changes.
- Report publication is a separate offline workflow. The API serves validated published files and does not generate reports during a download request. A failed publication must not be mistaken for a new current batch.
- `docs/recap.md` and `docs/backlog.md` were not present. External production hosting, secret provisioning, and persistent-volume ownership are not defined here; verify deployment configuration before operating production.

<!-- skill-state
output_sha256: 70be5476f26b6fd04e0461840371228fab8427e7d1e8d3a7bddb8baefc091130
-->
