# Project Overview

## Purpose

Explain who uses this project and what outcome it provides in one or two plain-language sentences. Cite repository evidence; mark uncertain claims `Unknown` or `Needs verification`.

## Tech Stack

List each major, actively used language/runtime, framework, data store, or queue as `- **Name**: Short role description.` Use evidence from manifests, configuration, and code; do not infer versions or include unused/transitive dependencies.

## Project Tree

Show a selective map of a handful of high-value folders and files with brief responsibility labels. Give a short first-reading order and explain only the component relationships needed to understand the system. Do not repeat a second architecture or data-flow summary.

```text
src/                 main implementation (verify responsibility)
src/main.ts          startup candidate (confirm runtime use)
tests/               automated checks
package.json         commands and dependencies
```

## Workflow

List every verified first-class application workflow, including important background and admin paths. A workflow has a trigger, meaningful checks or side effects, and an outcome; an endpoint or internal helper alone is not a workflow. State `Complete` only when coverage is supported; otherwise use `Partial` and identify what remains untraced. The stated count equals the visible workflow names and one-line purposes outside any collapsed diagrams.

**Complete — [N] verified workflows.** Or, when coverage is incomplete: **Partial — [N] confirmed workflows; [remaining scope] needs verification.**

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

**Complete — [N] registered HTTP endpoints.** Or, when coverage is incomplete: **Partial — [N] confirmed HTTP endpoints; [remaining routes] need verification.**

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/items/:itemId` | Read one item | Authenticated |
| GET | `/health` | Liveness check | Public |

For a long inventory, keep its count visible and collapse the complete table instead of omitting rows. Only claim `Complete` when evidence supports it. Access may be `Needs verification` when unknown.

## Scripts

List useful target-project commands and scripts with their purpose, source evidence, and whether they were exercised. Warn before commands that modify data (migrations, resets, seeders, deployment, cleanup). Do not present this skill's helpers as target-project commands.

## Important Notes

Keep only security cautions, operational invariants, required configuration/setup, external services, and evidence gaps that affect a reader's next action. Never expose secret values or sensitive connection strings. For client-only projects, state that server routes cannot be verified here instead of inventing endpoints.

Keep the overview to about one page and a few minutes' reading where project complexity permits. Keep descriptions short and avoid repeating facts; do not omit verified workflows, endpoint rows, or essential safety notes to meet a length target. Put the most useful project commands first and keep Important Notes limited to actionable cautions and evidence gaps. Shell validation checks structure, recognizable secrets, and fingerprint, not semantic completeness; substantiate every claim against repository evidence.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->
