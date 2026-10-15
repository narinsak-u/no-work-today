Here’s a prompt you can give directly to the AI coding agent to update the `to-catchup` skill exactly as discussed.

Update the existing `to-catchup` skill to make its generated `overview.md` more precise, concise, comprehensive, and easy for a new/junior developer to read.

## Goal

`overview.md` should answer:

> What does a new developer need to know to understand this project and start making safe changes?

Do not try to document the entire repository.

Focus on:

1. What is this project?
2. How does it work?
3. Where is the important logic?
4. How do I run and modify it?
5. What should I be careful about?

The overview should normally be readable within a few minutes.

Target approximately **80–150 lines for a normal project**, but do not pad content to reach this size.

For small projects, shorter is better.

---

# Required `overview.md` Structure

Use exactly these major sections:

```md
# Project Overview

## 1. Purpose

## 2. Tech Stack

## 3. Architecture

## 4. Main Flows

## 5. Core Modules

## 6. Important Files

## 7. Data & External Services

## 8. Development Workflow

## 9. Start Here

## 10. Important Notes
```

Do not add extra major sections unless the project genuinely requires one.

---

# 1. Purpose

Explain:

- what the system does
- who or what uses it
- its primary responsibility

Keep this section to approximately 3–5 sentences.

Do not include implementation details here.

Example:

```md
## 1. Purpose

This service provides authentication and user management for three
frontend applications. It is responsible for login, session validation,
authorization, and user identity management.

Frontend applications communicate with this service through HTTP APIs.
```

---

# 2. Tech Stack

Include only technologies that materially help understand the project.

Use a compact format.

Example:

```md
## 2. Tech Stack

- Frontend: React, TypeScript, TanStack Router
- Backend: Hono
- Database: PostgreSQL
- ORM: Drizzle
- Authentication: Session cookies
- Runtime: Bun
- Testing: Vitest
- Deployment: Docker
```

Do not list every dependency from `package.json`, `Cargo.toml`, etc.

---

# 3. Architecture

Explain the system at a high level.

Prefer a simple plain-text diagram.

Example:

```text
Browser
   |
   v
React Frontend
   |
   | HTTP
   v
Hono API
   |
   +--> Authentication
   |
   +--> Business Services
   |
   v
PostgreSQL

External:
   +--> S3
   +--> Third-party API
```

The diagram should show only important architectural components.

After the diagram, provide a short explanation if needed.

Do not create large or highly detailed architecture diagrams.

---

For every representative flow, require a concise explanation and a short subheading with purposeful emoji. Draw its verified primary path vertically from observed entry through meaningful stages to observable output; add only short lateral branches for genuine runtime branches. A filename-only candidate is not an observed path. Keep numbered headings, diagrams, paths, commands, and code emoji-free.

# 4. Main Flows

This section is especially important.

Identify the project's **main runtime workflows** and explain how data moves through the system.

Examples:

- authentication/login
- loading application data
- creating/updating an entity
- file upload
- report generation
- payment flow
- background processing

Do NOT document every feature.

Usually identify approximately **2–5 important flows**, depending on project size.

Each flow should contain:

1. a short title
2. a one-sentence explanation
3. a simple plain-text data-flow diagram
4. a short numbered explanation only if necessary

Example:

```md
## 4. Main Flows

### Login Flow

Authenticates a user and creates a shared session.

```text
User
  |
  v
Login Page
  |
  | POST /auth/login
  v
Auth Route
  |
  v
Auth Service
  |
  +--> Validate Credentials
  |
  v
User Repository
  |
  v
PostgreSQL
  |
  v
Session Created
  |
  v
Set-Cookie
  |
  v
Frontend
```

1. The frontend sends credentials to the authentication API.
2. The auth service validates the credentials.
3. User data is loaded from PostgreSQL.
4. A session is created and returned through an HTTP-only cookie.
```

Another example:

```md
### Dashboard Data Flow

Loads dashboard information after authentication.

```text
Dashboard
   |
   | GET /api/dashboard
   v
Auth Middleware
   |
   | valid session
   v
Dashboard Route
   |
   v
Dashboard Service
   |
   +------> PostgreSQL
   |
   +------> Analytics API
   |
   v
Response DTO
   |
   v
Frontend
   |
   v
TanStack Query Cache
   |
   v
UI
```
```

Another example for mutation:

```md
### Update Profile Flow

```text
Profile Form
    |
    | PATCH /api/users/:id
    v
User Route
    |
    v
Input Validation
    |
    v
User Service
    |
    v
User Repository
    |
    v
PostgreSQL
    |
    v
Updated User
    |
    v
API Response
    |
    v
Frontend Cache Refresh
```
```

---

# Main Flow Diagram Rules
- Put the primary path vertically, from observed entry through meaningful stages to the observable output. Use a short lateral branch only when the runtime flow genuinely branches; never replace a diagram with horizontal prose arrows or present filename-only candidates as observed behavior.
- Give each flow a concise one-sentence explanation and a short subheading with purposeful emoji. Keep the ten numbered headings, diagrams, paths, commands, and code emoji-free.


The diagrams must be:

- plain text / ASCII
- readable directly inside Markdown
- simple
- vertical when possible
- focused on data movement
- based on actual repository evidence

Prefer:

```text
Client
  |
  v
Route
  |
  v
Service
  |
  v
Database
```

For branching flows:

```text
Service
   |
   +------> Database
   |
   +------> Redis
   |
   +------> External API
```

For middleware:

```text
Request
   |
   v
Auth Middleware
   |
   | valid
   v
Route Handler
```

For asynchronous flows:

```text
API
 |
 v
Queue
 |
 v
Worker
 |
 v
Database
```

Avoid complicated box drawings such as:

```text
+---------------------+
|                     |
|     Huge Box        |
|                     |
+---------------------+
```

unless they substantially improve clarity.

Prefer simple arrows:

```text
|
v
+-->
```

The objective is understanding, not visual decoration.

---

# How to Discover Main Flows

Do not guess workflows from filenames alone.

Use repository evidence.

Inspect:

- application entrypoints
- routers/routes
- controllers/handlers
- middleware
- services/use-cases
- repositories/data-access
- database schema/models
- frontend API clients
- hooks/query functions
- tests
- README/docs

Trace representative paths through the code.

For example:

```text
frontend action
→ API client
→ route
→ middleware
→ handler
→ service
→ repository
→ database
```

Then summarize that path.

Do not include every implementation function.

---

# Keep Flows High-Level

Bad:

```text
LoginButton.tsx
→ handleClick()
→ onSubmit()
→ mutateAsync()
→ apiClient.post()
→ request()
→ fetch()
→ router.post()
→ validator()
→ loginHandler()
→ loginService()
→ passwordCompare()
→ repository.findByEmail()
...
```

Too implementation-heavy.

Better:

```text
Login Form
   |
   v
Auth API
   |
   v
Auth Service
   |
   +--> Credential Validation
   |
   v
User Repository
   |
   v
Database
   |
   v
Session
```

The overview explains the system, not the call stack.
Show Core Modules as a selective tree of the usual three to seven relevant functional areas with brief responsibility labels. Keep only useful levels; `Important Files` is a separate reading list and must not repeat the tree.

---

# 5. Core Modules

Include only major functional areas.

Usually limit this to approximately **3–7 modules**.

Example:

```md
## 5. Core Modules

### Authentication

Handles login, logout, session validation, and authorization.

Main code:
- `src/auth/`
- `src/middleware/auth.ts`

### Users

Handles user profiles and account management.

Main code:
- `src/users/`
- `src/db/schema/users.ts`

### Reports

Builds dashboard and reporting data.

Main code:
- `src/reports/`
```

Do not create one module entry for every directory.

---

# 6. Important Files

Include only files/directories that help a new developer navigate the project.

Example:

```md
## 6. Important Files

| Path | Purpose |
|---|---|
| `src/index.ts` | Application entry point |
| `src/routes/` | HTTP API definitions |
| `src/services/` | Core business logic |
| `src/db/schema.ts` | Database schema |
| `src/middleware/auth.ts` | Authentication middleware |
```

Usually keep this below approximately 10–15 entries.

Do not reproduce the directory tree.

---

# 7. Data & External Services

Summarize important persistent data and system integrations.

Example:

```md
## 7. Data & External Services

### PostgreSQL

Stores:
- users
- sessions
- organizations
- reports

Database access is centralized under `src/db/`.

### S3

Used for uploaded documents.

Upload flow:

Frontend → API → S3

### Analytics API

Used by the reporting service to retrieve external metrics.
```

Only include services that materially affect system behavior.

---

# 8. Development Workflow

Keep this practical and short.

Include the commands a developer actually needs.

Example:

```md
## 8. Development Workflow

Install dependencies:

```bash
bun install
```

Run locally:

```bash
bun dev
```

Run tests:

```bash
bun test
```

Build:

```bash
bun run build
```
```

Add database migration or environment setup only when necessary.

Do not copy every script from `package.json`.

---

# 9. Start Here

Give the new developer a recommended reading order.

Example:

```md
## 9. Start Here

Recommended reading order:

1. `README.md` — project purpose and setup
2. `src/index.ts` — application bootstrap
3. `src/routes/index.ts` — available API routes
4. `src/auth/` — authentication flow
5. `src/services/` — main business logic
6. `src/db/schema.ts` — core data model
```

Limit this to the most important files.

The goal is:

> If I have 15–30 minutes, what should I read first?

---

# 10. Important Notes

Include only things a new developer could easily get wrong or should know before changing code.

Examples:

```md
## 10. Important Notes

- Authentication is centralized in `src/auth/`; avoid implementing
  independent authentication checks inside routes.

- Database schema changes require a migration.

- Files under `src/generated/` are generated and should not be edited manually.

- `legacy-reports/` is still used by production and cannot currently be removed.
```

Do not fill this section with generic advice.

Every note should be supported by repository evidence.

---

# Conciseness Rules

The skill must aggressively avoid unnecessary detail.

Do not:

- document every directory
- document every API endpoint
- list every dependency
- explain obvious framework concepts
- dump large repository trees
- dump implementation-level call stacks
- repeat the same information across sections
- write long prose paragraphs
- create diagrams for trivial flows
- guess architecture or intent

Prefer concise statements and diagrams.

---

# Precision Rules

Every important claim should come from repository evidence.

If something cannot be determined confidently, either:

- omit it, or
- explicitly state that it could not be confirmed

Do not invent architecture.

Do not infer business behavior solely from naming.

Inspect enough implementation to confirm the main flow.

---

# Diagram Consistency

Use consistent terminology across diagrams.

If the overview calls a layer:

```text
Auth Service
```

do not later call the same component:

```text
Authentication Manager
```

unless these are actually different components.

Use conceptual component names rather than unnecessarily exposing function names.

---

# Diagram Size

A single flow diagram should usually stay around:

```text
5–12 nodes
```

If a diagram becomes much larger, simplify it.

For example, turn:

```text
Route
→ validator
→ controller
→ helper
→ use case
→ service
→ adapter
→ repository
→ ORM
→ driver
→ database
```

into:

```text
Route
  |
  v
Validation
  |
  v
Business Service
  |
  v
Repository
  |
  v
Database
```

The goal is to give the developer a mental model.

---

# Output Quality Test

Before finishing `overview.md`, verify that a new developer can answer these questions after reading it:

1. What does this project do?
2. What technologies does it use?
3. What are the major system components?
4. How does a request/data move through the system?
5. What are the main application workflows?
6. Where is the important business logic?
7. Where is data stored?
8. Which external systems matter?
9. How do I run and test the project?
10. Which files should I read first?
11. What should I avoid changing incorrectly?

If the answer to these is clear, the overview is sufficient.

Do not add more content simply for completeness.

---

# Guiding Principle

The most important rule for `to-catchup` is:

> **Do not document the repository. Explain the system.**

And for Main Flows:

> **Show how data travels through the system, not every function it passes through.**

Optimize the generated `overview.md` for a junior developer who needs a reliable mental model of an unfamiliar project within a few minutes.
