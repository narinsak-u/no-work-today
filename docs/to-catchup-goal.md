# Catch-up Overview Goal

`to-catchup` creates or updates only `docs/overview.md` in the target repository. Its job is to help a junior developer understand what the project does, how its verified application workflows operate, where to begin reading, which project commands are safe, and what remains uncertain. The installed skill's `references/overview-template.md` is the format authority; this goal records why that format exists.

## Readable output

A normal overview should take a few minutes to read. Prefer a selective project map and practical reading order over a file inventory. Base the purpose and actively used technology stack on repository evidence, not names, conventional layouts, or transitive dependencies. Cite the source paths that establish important claims. Explain component relationships and the first safe files to open in Project Tree. Keep data stores, external services, configuration names, security boundaries, and deployment cautions in Important Notes without exposing credentials.

Use exactly these ordered major headings, with `API Endpoints` omitted entirely when the target repository does not register HTTP routes:

```md
# Project Overview
## Purpose
## Tech Stack
## Project Tree
## Workflow
## API Endpoints
## Scripts
## Important Notes
```

## Honest inventories

An application workflow is a verified trigger-to-outcome path, not an endpoint or internal helper. Name and give a one-line purpose for every confirmed first-class workflow, including relevant background/admin paths. Keep the entire name/purpose inventory visible. Explain the most important workflows using simple vertical diagrams with meaningful checks and side effects; if three or more are verified, show the three most user-facing or high-risk diagrams inline and collapse the others, not the visible names. Count the named workflows; mark an unproven inventory `Partial` and state which triggers remain untraced. Never label inferred runtime behavior `Complete`.

An HTTP endpoint is a distinct explicitly registered method and full mounted route-template pair. Count every confirmed pair, including health/internal routes and distinct methods on one path. Check mounted prefixes manually and exclude implicit methods and routes guessed from client calls, entrypoint filenames, or unverified OpenAPI documentation. A partial list must state what remains untraced. A client-only repository has no local server route inventory; omit the entire endpoint section and note the external API limitation in Important Notes. For long lists, collapse the full table without hiding the confirmed total.

## Safety and publication

Shell helpers collect bounded read-only leads, not architectural conclusions. Document useful target-project scripts with source evidence, purpose, and whether exercised; flag commands that modify data. Never copy secrets or sensitive connection strings. Respect ownership of an existing overview: verify the exact terminal `output_sha256` fingerprint before updates, or adopt only a clean tracked legacy file; otherwise stop without overwriting edits. Change only `docs/overview.md` and create `docs/` only if needed. Validate its ordered headings, recognizable secret patterns, and fingerprint with `scripts/validate-overview.sh`; separately review architectural evidence, workflow and endpoint coverage, and the junior reading path, because a shell validator cannot prove semantic truth.
