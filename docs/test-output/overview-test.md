# Project Overview

## 1. Purpose

DGA Dashboard presents Thailand public agencies' digital-government assessment results: a public national overview and sign-in-gated department/province dashboards. The repository also prepares and publishes agency report PDFs for authenticated download. Evidence: `docs/ARCHITECTURE.md`, `report-pdf/CONTEXT.md`.

## 2. Tech Stack

- Bun 1.3.14 and Turbo manage the monorepo; React, TypeScript, Vite, and TanStack Router implement the browser app (`package.json`, `apps/web/package.json`).
- Rust, Tokio, Axum, SQLx, and SQLite provide the API, authentication, snapshot storage, and static-file serving (`crates/server/Cargo.toml`).
- Python report modules prepare data and publish DOCX/PDF artifacts; Playwright captures dashboard charts and LibreOffice converts DOCX to PDF (`report-pdf/README.md`).
- Docker packages the web build and API into one Debian runtime (`Dockerfile`).

## 3. Architecture

```text
Report CSVs and generated inputs
  |
  v
Generators
  |
  +--> committed JSON --> React dashboard
  |
  +--> chart assets

Browser
  |
  v
Axum API
  |
  +--> SQLite
  |
  +--> published PDF files
```

## 4. Main Flows

### 📊 Dashboard data

The web build prepares JSON for browser rendering; the API also exposes an overview snapshot endpoint (`apps/web/package.json`, `apps/web/src/routes/index.tsx`, `crates/server/src/api.rs`).

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

The browser posts credentials to Axum, which checks the seeded SQLite user and issues a JWT; the client keeps it in session storage and requests `/api/me` to restore identity (`apps/web/src/api.ts`, `apps/web/src/hooks/use-auth-session.ts`, `crates/server/src/auth.rs`).

```text
Login form
  |
  v
/api/signin
  |
  v
Axum auth and seeded SQLite user
  |
  v
JWT returned to browser
  |
  v
Session storage
  |
  v
/api/me
  |
  v
Restored identity
```

### 📄 Report publication and download

Offline tooling validates a report batch and updates `current.json`; authenticated API download resolves an artifact from organization claims, not a client filename (`report-pdf/README.md`, `crates/server/src/report.rs`).

```text
CSV inputs, templates, chart assets
  |
  v
Report rendering and PDF conversion
  |
  v
Batch validation
  |
  v
Published manifest and current.json
  |
  v
Validated published PDF artifact
  |
  v
Offline publication complete; later request is separate
  |
  v
Authenticated /api/me/report.pdf request
  |
  v
Organization claim lookup
  |
  v
Published PDF response
```

### 🚀 Production serving

Docker packages the web build and reports alongside Axum, whose listener serves the SPA and API on port 3000 (`Dockerfile`, `crates/server/src/app.rs`, `tests/docker-smoke.sh`).

```text
Browser
  |
  v
Axum listener :3000
  |
  +--> SPA assets
  |
  +--> /api routes
  |
  v
SQLite and report files
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

- `apps/web/src/main.tsx` and `apps/web/src/router.tsx`: browser mount and route setup.
- `apps/web/src/api.ts` and `apps/web/src/hooks/use-auth-session.ts`: HTTP boundary and session lifecycle.
- `crates/server/src/main.rs`, `app.rs`, and `config.rs`: startup, router composition, and environment configuration.
- `crates/server/src/auth.rs` and `report.rs`: JWT identity and authenticated artifact delivery.
- `Justfile`, `Dockerfile`, and `tests/docker-smoke.sh`: development/report commands, production image, and one-port smoke coverage.

## 7. Data & External Services

- Browser data is generated JSON under `apps/web/src/data/`; inputs and downloaded CSV snapshots are under `report-pdf/input/` and `report-pdf/csv-sources/`. Regenerate and commit snapshots when source CSVs change.
- SQLite stores the dashboard snapshot and seeded auth users. Local server defaults: `BIND_ADDR=127.0.0.1:3000`, `DATABASE_URL=sqlite://data/dashboard.sqlite?mode=rwc`; `just dev` uses `data/dashboard-dev.sqlite`.
- Configuration also includes `JWT_SECRET` (set a real secret outside development), optional `WEB_ROOT`, `REPORT_ROOT`, `REPORT_ARTIFACT_ROOT`, and `REPORT_OUTPUT_ROOT`; paths default under the repo's `report-pdf/`. Production sets these paths and binds `0.0.0.0:3000` in the image.
- CSV download integration uses Google Sheets exports; chart capture uses local Playwright Chromium; PDF conversion requires local LibreOffice (`soffice`) and bundled Thai fonts. These tools are for data/report preparation, not required for serving the already-built production app (`report-pdf/README.md`, `Dockerfile`). No managed database or cloud storage is defined in the repository.

## 8. Development Workflow

Commands below are documented in manifests, `Justfile`, and repository guidance; **none were exercised for this catchup**.

- Install JavaScript workspace dependencies: `bun install --frozen-lockfile`.
- Start API and Vite together: `just dev` (API `127.0.0.1:3000`, web `127.0.0.1:5173`). API only: `just dev-api`; web only: `just dev-web`.
- Typecheck and test: `bun run typecheck`, `bun run test`. Build: `bun run build`; web build regenerates its JSON inputs first.
- Check Rust: `cargo check -p dga-dashboard-server`; backend integration tests: `cargo test -p dga-dashboard-server --test api`.
- API-only smoke: `env -u WEB_ROOT sh tests/smoke.sh`. Production image smoke: `sh tests/docker-smoke.sh` (requires Docker; builds/runs a container and uses a test port).
- Optional report setup: create `report-pdf/.venv`, install `report-pdf/requirements.txt`, Playwright Chromium, LibreOffice, then `just install-report-fonts`. Data downloads/generation and `just publish-reports` alter local source snapshots or report artifacts; review their output before committing. See `report-pdf/README.md` and `Justfile`.

## 9. Start Here

1. Read `docs/ARCHITECTURE.md` for system boundaries and deployment, then `docs/OVERVIEW.md` for dashboard and report user flows.
2. Follow browser startup through `apps/web/src/main.tsx`, `router.tsx`, and `apps/web/src/api.ts`.
3. Follow backend composition through `crates/server/src/main.rs`, `app.rs`, and `config.rs`; then inspect `auth.rs` and `report.rs` for identity and artifact boundaries.
4. For data/report work, read `report-pdf/README.md` and `report-pdf/CONTEXT.md`, then inspect matching modules under `report-pdf/src/`.
5. Use `Justfile`, root/web package manifests, and `crates/server/tests/api.rs` to select a command and see tested behavior.

## 10. Important Notes

- Never use the development JWT fallback in production; supply `JWT_SECRET` securely. Seed inputs include authentication data; do not copy credentials into docs or logs.
- Production serves prebuilt SPA/API and report artifacts from one Axum listener. `WEB_ROOT` controls whether SPA fallback is enabled; unknown `/api/*` routes stay JSON 404s.
- Do not edit generated `apps/web/src/routeTree.gen.ts`; update route sources and let tooling regenerate it. Web builds regenerate JSON; commit regenerated snapshots with source CSV changes.
- Report publication is a separate offline workflow. The API serves validated published files and does not generate reports during a download request. A failed publication must not be mistaken for a new current batch.
- `docs/recap.md` and `docs/backlog.md` were not present. External production hosting, secret provisioning, and persistent-volume ownership are not defined here; verify deployment configuration before operating production.

<!-- skill-state
output_sha256: 06e59c5e440d1d96d0b6ba93bc5c4a07299f72aea9527292da989d9663581546
-->
