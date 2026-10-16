# Project Overview

## Purpose

Explain who uses this project and what outcome it provides in plain language. Cite repository evidence; mark uncertain claims `Unknown` or `Needs verification`.

## Tech Stack

Name only major, actively used languages/runtimes, frameworks, data stores, and queues. Check helper clues against manifests, configuration, and code. Cite evidence; do not infer versions or include unused/transitive dependencies.

## Project Tree

Show a selective map of important functional areas and a few key files with responsibility labels. Give a short reading order here: what a junior developer should open first and why. Explain how the major parts relate; a filename or entrypoint candidate alone does not prove a runtime relationship.

```text
src/                 main implementation (verify responsibility)
src/main.ts          startup candidate (confirm runtime use)
tests/               automated checks
package.json         commands and dependencies
```

## Workflow

List every verified first-class application workflow, including important background and admin paths. A workflow has a trigger, meaningful checks or side effects, and an outcome; an endpoint or internal helper alone is not a workflow. State `Complete` only when coverage is supported; otherwise use `Partial` and identify what remains untraced. The stated count equals the visible workflow names and one-line purposes outside any collapsed diagrams.

**Partial — [N] confirmed workflows; [remaining scope] needs verification.**

| Workflow | Purpose |
|---|---|
| [Name] | [One-line purpose] |

For three or more workflows, show the three most user-facing or high-risk diagrams inline and put each remaining diagram in one collapsed `<details>` block. For fewer than three, show all diagrams inline. Put one stage per line with downward arrows; show verified checks, side effects, and outcomes, not guessed runtime paths. Cite evidence paths and mark unresolved links `Needs verification`.

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

## API Endpoints

Include this section only if the project registers HTTP routes. For a client-only repository or one without HTTP route registrations, omit it completely and explain any external API limitation in Important Notes. GraphQL/gRPC operations are not HTTP route-template pairs.

Show one row per distinct explicitly registered HTTP method and full mounted route-template pair, including health/internal routes. Different methods on one path count separately; a dynamic path template counts once. Exclude implicit `HEAD`/`OPTIONS` unless explicitly registered, entrypoint candidates, guessed routes, and OpenAPI declarations not checked against registration. Count the unique rows; never add blank rows to fill a total. Unknown method or path means the pair is not confirmed: use `Partial` and explain the gap.

**Partial — [N] confirmed HTTP endpoints; [remaining routes] need verification.**

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/items/:itemId` | Read one item | Authenticated |
| GET | `/health` | Liveness check | Public |

For a long inventory, keep its count visible and collapse the complete table instead of omitting rows. Only claim `Complete` when evidence supports it. Access may be `Needs verification` when unknown.

## Scripts

List useful target-project commands and scripts with their purpose, source evidence, and whether they were exercised. Warn before commands that modify data (migrations, resets, seeders, deployment, cleanup). Do not present this skill's helpers as target-project commands.

## Important Notes

Capture repository-specific security cautions, operational invariants, external services and data stores, configuration names and setup requirements, deployment unknowns, and evidence gaps. Never expose secret values or sensitive connection strings. For client-only projects, note that server routes cannot be verified here rather than inventing an endpoint list.

Keep the overview readable in a few minutes. Do not pad it or let a collapsed diagram hide a workflow name or purpose. Shell validation checks structure, recognizable secrets, and fingerprint, not semantic completeness; substantiate every claim against repository evidence.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->
