# Project Overview

## Purpose

This repository is the PDMS authentication API used by PDMS web portals and internal services. It manages accounts, roles and permissions, issues PDMS tokens, supports password reset, and issues authorization codes for Folio SSO (`README.md`, `src/app.ts`, `src/controllers/users/post.ts`, `src/controllers/sso/folio/post.ts`). It is a backend service, not a frontend or a Folio identity consumer.

## Project Tree

```text
src/index.ts                         server startup (verified in code)
src/app.ts                           HTTP routes and middleware
src/controllers/                     request handlers, including users and Folio SSO
src/services/  src/repositories/     business operations and persistence
prisma/schema.prisma                 PostgreSQL data model
package.json  test/  README.md       commands, checks and setup evidence
```

## Workflow

```text
Observed: HTTP request → Hono route/controller → Effect service → Prisma repository → PostgreSQL
          response ← controller ← service result
Login:    credentials → account/password check → access token + refresh cookie/token record
Folio:    bearer-authenticated issue → short-lived hashed code → client exchange → identity claims
```

The server starts through `src/index.ts` and mounts routes in `src/app.ts`. The API path and persistence components are supported by those files and the controllers/services/repositories they call. `find-entrypoints.sh` results are candidates only; verify their callers before treating any other detected file as runtime startup. Password reset can update the local password before a later external call fails; investigate before retrying (`src/controllers/users/post.ts`, `src/repositories/users/updates.ts`).

## Scripts

Commands are declared in `package.json` and documented in `README.md`; they were not exercised during this overview.

- `pnpm dev` — decrypt environment and run the development server; requires approved local environment keys.
- `pnpm test` — run the Node test suite; PostgreSQL-backed SSO tests require an isolated, migrated local database.
- `pnpm lint`, `pnpm build`, `pnpm start` — lint, create `dist/`, and run the built server.
- `pnpm prisma:migrate` / `pnpm seed` — change a database. Verify the target database and seed contents first; local seed/Compose credentials must not be reused or exposed.

## Important Notes

- Protected routes use permissions embedded in short-lived access JWTs; inspect route middleware and token lifecycle before changing authorization (`src/middleware/auth.ts`). The admin API uses a separate shared-secret header. CORS does not replace authentication.
- Folio authorization codes are hashed, short-lived and single-use. Confirm callback/client configuration and synchronized clocks (`src/controllers/sso/folio/post.ts`, `src/repositories/folio_authorization_codes/`).
- Keep signing keys, client credentials, SMTP credentials and dotenvx keys outside this document. Never copy values from `.env*`, seed files or local Compose configuration.
- Node/pnpm versions conflict across `mise.toml`, `Dockerfile` and `package.json`. Deployment secret injection, external service availability and release ownership need verification; repository configuration describes intent, not successful operation.
- Generated `dist/` and Prisma client files should not be edited directly. `migrate-user-to-k2-db.ts` is an ad-hoc outbound migration; its operational use is unknown. Review before running any data-changing or external-action script.
