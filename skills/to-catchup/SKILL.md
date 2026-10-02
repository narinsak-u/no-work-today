---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
---

# Repository Catchup

Create or update one evidence-based onboarding document at `docs/overview.md`. The document should help a new developer understand the repository's purpose, architecture, application flow, important modules and files, configuration, development workflow, and safe next steps without reading the entire codebase first.

## Boundaries

- Work from the target repository's files and history that are available in the current workspace.
- Treat `docs/recap.md` and `docs/backlog.md` as optional context when they exist; verify their claims against the repository.
- Create `docs/` when it does not exist.
- Create or update only `docs/overview.md`; preserve unrelated documentation and files.
- Never copy secret values. Record configuration names and safe placeholders only, and omit tokens, passwords, private keys, credentials, sensitive connection strings, and other secret material.
- Never guess. Mark missing, ambiguous, or unverified information as `Unknown` or `Needs verification` and identify what should be checked.

## Workflow

1. Establish the repository root and inspect the top-level layout, package or dependency manifests, and existing documentation. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist.
2. Inspect the repository areas that establish behavior and day-to-day work:
   - application entry points, startup/bootstrap code, and executable commands;
   - authentication and authorization boundaries, session or identity handling, and security-sensitive middleware;
   - core modules, shared utilities, routes or handlers, jobs or workers, persistence, schemas, and integration boundaries;
   - API clients, adapters, external-service wrappers, and other integration boundaries;
   - tests, fixtures, examples, and test commands;
   - environment examples, configuration loaders, CI, deployment, migration, and release scripts;
   - generated artifacts or files that developers must not edit directly.
3. Explain the system architecture and important runtime flows before writing a file inventory. Trace inputs through meaningful components to outputs or side effects; include failure or background paths only when supported by evidence.
4. Read `references/overview-template.md` from this skill and use its headings and guidance for `docs/overview.md`. Do not replace the template with an unrelated format.
5. Fill every template section with concise, repository-backed guidance. Distinguish observed facts from inferences, cite relevant paths and commands, and mark unknowns instead of filling gaps from convention or intuition.
6. In `Environment and Configuration`, document variable names, loading locations, safe defaults, and setup requirements without exposing secret values. If a file contains secrets, describe its role without reproducing its contents.
7. In `Development Workflow`, include only commands supported by repository evidence. State when testing, deployment, or another workflow could not be verified.
8. Before writing, inspect the owned file's Git state. In a Git repository, run `git status --short -- docs/overview.md`; if it reports staged or unstaged changes, stop and ask how to merge them rather than overwrite them. In a non-Git repository, preserve existing content explicitly while incorporating the new evidence.
9. Write the result to `docs/overview.md`. Do not modify, rename, or delete unrelated documentation, source files, configuration, or generated artifacts.
10. Re-read the result and check that it explains flows before inventories, covers all template sections, contains no secret values or unsupported claims, and leaves unrelated files untouched. Confirm the owned-file guard passed before writing.

## Completion Criteria

A catchup is complete when `docs/overview.md` exists, follows the local template, explains how the system works before enumerating files, covers architecture, flow, modules, configuration, development workflow, reading order, and cautions, and explicitly identifies evidence gaps. The only intended repository output is `docs/overview.md` (plus the `docs/` directory when it had to be created).
