# Project Overview

## 1. Purpose

In a few plain-language sentences, explain what the repository does and who it serves. Cite evidence; label unresolved purpose `Unknown` or `Needs verification`.

<<<<<<< HEAD
## 2. Tech Stack
=======
## Tech Stack

List only major technologies evidenced as actively used: languages/runtimes, frameworks, data stores, and queues. Use stack-helper output as a lead, then verify active use in manifests, configuration, and code. Include versions only when directly evidenced; omit transitive dependencies and unused declarations.

## Project Tree
>>>>>>> d910d8d (feat: improve catchup overview inventories)

List only technologies that materially explain the system. Cite manifests/configuration; avoid dependency inventories. Mark uncertain roles `Needs verification`.

## 3. Architecture

Describe the main conceptual components and their relationships. Use consistent component names and a small plain-text diagram where useful; do not infer runtime behavior from filenames alone.

```text
<<<<<<< HEAD
Client → Application → Data store
```

## 4. Main Flows

Trace two to five representative runtime workflows when project complexity warrants them. Each flow has a short subheading, a one-sentence explanation, and a simple plain-text diagram grounded in the observed entry, meaningful processing stages, and observable output. Keep the primary path vertical; use short lateral branches only for real, verified branches. Name evidence paths, mark unknown links explicitly, and omit unsupported claims.

```text
Request
  |
  v
Validated handler
  |
  v
Persisted result
  |
  v
Response
```

## 5. Core Modules
=======
src/                 main implementation
src/main.ts          startup candidate (confirm runtime use)
tests/               automated checks
package.json         commands and dependencies
```

Use paths supported by repository evidence. Do not treat an entrypoint candidate as proven runtime behavior.

## Workflow

Name every verified first-class application workflow, including important background and admin workflows, and give each a one-line purpose. State the total and whether the inventory is complete; the total must match the visible workflow names. For a partial inventory, say what remains untraced. Do not list internal helpers as workflows.

- **Complete — [N] verified workflows** or **Partial — [N] confirmed; [remaining scope] needs verification**.
- Keep the complete workflow-name/purpose list visible, even when diagrams are collapsed.
- If there are three or more workflows, show the three most user-facing or high-risk diagrams inline and put diagrams for every remaining workflow in one collapsed `<details>` block. If there are fewer than three, show all diagrams inline.
- Use a separate line per stage with downward arrows. Keep the diagram simple and show only important checks, side effects, and outcomes.

```text
User submits a request
  ↓
Authenticate and validate
  ↓
Save the result
  ↓
Queue background work
  ↓
Return confirmation
```

Identify the evidence paths for important claims. Mark uncertain triggers, branches, or outcomes `Needs verification` rather than inferring them from filenames.

## API Endpoints

Include this section only when the repository registers HTTP routes. If it is a client-only repository or has no HTTP route registrations, omit the entire section and mention any unavailable remote API in Important Notes; do not add a prose-only endpoint section. If the project uses GraphQL or gRPC without HTTP routes, describe that transport separately; do not count its operations as HTTP endpoints.

- Show one row per distinct explicitly registered HTTP method + full mounted route-template pair. Different methods on the same path count separately; a dynamic route template counts once.
- Include health/internal routes and label access (`Public`, `Authenticated`, `Internal`, or `Needs verification`) when evidence supports it. Count implicit `HEAD`/`OPTIONS` only when explicitly registered; exclude entrypoint candidates.
- Treat the table as a set keyed by `(HTTP method, full mounted path)`: repeated discoveries of the same pair produce one row; different methods produce separate rows.
- Every row must have a method, path, and purpose. The visible total must equal the number of unique rows; never add blank or placeholder rows.
- If a route's method or path cannot be established, omit it from confirmed rows, mark the inventory Partial, and state what remains untraced.

**Complete — [N] HTTP endpoints** or **Partial — [N] confirmed; [remaining routes] need verification**.

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/items/:itemId` | Read one item | Authenticated |
| GET | `/health` | Liveness check | Public |

Trace router registration and mounted prefixes manually. A checked-in OpenAPI document is supporting evidence only after it has been checked against the implementation. If completeness cannot be proven, mark the inventory `Partial` or `Needs verification`, count confirmed pairs only, and state what remains untraced.

If the full table would make the overview longer than about one page, keep the count visible and put the complete table in a collapsed `<details>` block. Never omit rows to make it shorter.
>>>>>>> d910d8d (feat: improve catchup overview inventories)

Show a selective tree of the usual three to seven important functional areas, grouped under relevant parent directories, with brief responsibility labels. Keep it to useful levels and omit irrelevant directories.

<<<<<<< HEAD
```text
src/
├── auth/       — identity and sessions
└── reports/    — report generation
```
=======
List useful commands and runnable scripts belonging to the target project. Give each a concise purpose, cite the manifest/script/readme evidence, and say whether it was exercised. Warn before commands that alter data (for example migrations, resets, seeders, deployment, or destructive cleanup). Do not list this skill's internal helpers unless they are genuinely useful to project users.
>>>>>>> d910d8d (feat: improve catchup overview inventories)

## 6. Important Files

Give a separate, short reading list of files a developer should open first, with why each matters. Cite repository evidence; do not reproduce the module tree or turn this into a directory map.

## 7. Data & External Services

Summarize important persistent data, configuration, and external integrations that affect behavior. Record names and safe placeholders only; never include secret values or sensitive connection strings. Label unresolved details `Unknown` or `Needs verification`.

## 8. Development Workflow

Give the useful target-project install, run, test, and build commands with a short purpose and source evidence. State whether commands were exercised. Warn plainly before commands that alter data. Do not list this skill's internal helpers unless they are useful to project users.

## 9. Start Here

Give a short, practical reading order for a new developer's first 15–30 minutes, using paths and a brief reason for each step.

## 10. Important Notes

Keep this section limited to repository-specific security cautions, operational invariants, setup requirements, generated-file warnings, ownership or deployment unknowns, and evidence gaps. Use precise paths and commands where useful.

Keep the overview concise and useful, normally readable in a few minutes; roughly 80–150 lines only where warranted. Prefer verified facts over completeness, and do not pad. Use purposeful emoji only in short Main Flow or Core Modules subheadings. Keep the ten numbered headings exact; diagrams, paths, commands, and code remain emoji-free.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->