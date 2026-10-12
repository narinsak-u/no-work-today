---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
disable-model-invocation: true
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

1. Establish the repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with the target repository root as their argument (invoke via an absolute path resolved from this skill directory, not a path inside the target project). The scripts report bounded inventory, manifest-based stack evidence, and **entrypoint candidates**, not architectural conclusions. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist. If a helper fails, inspect the relevant files directly; never turn missing script output into an inferred fact.
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
8. Before writing, validate ownership of the existing output. Keep one hidden HTML comment at the end of `docs/overview.md` in this exact form, with LF line endings:
   ```md
   <!-- skill-state
   output_sha256: <64 lowercase hexadecimal characters>
   -->
   ```
   The `output_sha256` line is SHA-256 of the exact UTF-8 bytes of the entire document with only that metadata line and its line ending omitted. Retain the comment delimiters, every other metadata field, and every other byte and line ending unchanged; do not normalize content. On first write, write the completed overview followed by this comment and calculate the fingerprint by this rule.
   - If an existing output contains the `output_sha256` field, recompute the hash using that rule. If it is well-formed and matches, it is safe for this skill to update even when Git reports staged or unstaged changes to `docs/overview.md`. After every permitted update, recalculate and replace the fingerprint. If the field is malformed, duplicated, or mismatched, stop without writing and ask how to preserve or merge the edits.
   - If an existing output has no `output_sha256` field, adopt it only when it is a clean, tracked legacy file in a Git repository: verify it is tracked and `git status --short -- docs/overview.md` reports no staged or unstaged changes. Add the fingerprint with the next complete update. If it is untracked, modified, or in a non-Git repository, stop without writing and ask for direction; do not treat non-Git content as clean.
9. Write the result to `docs/overview.md` only after the ownership check permits the update. Preserve the existing overview structure and all unrelated files; do not modify, rename, or delete unrelated documentation, source files, configuration, or generated artifacts.
10. Re-read the result, run this skill's `scripts/validate-overview.sh` on `docs/overview.md`, and correct any structural or obvious secret warning before finishing. The validator is read-only and cannot establish architectural correctness: separately check that the document explains flows before inventories, contains no unsupported claims, has a valid fingerprint, and leaves unrelated files untouched. Confirm the ownership guard passed before writing.

## Completion Criteria

A catchup is complete when `docs/overview.md` exists, follows the local template, explains how the system works before enumerating files, covers architecture, flow, modules, configuration, development workflow, reading order, and cautions, explicitly identifies evidence gaps, and has a valid hidden fingerprint. The only intended repository output is `docs/overview.md` (plus the `docs/` directory when it had to be created).
