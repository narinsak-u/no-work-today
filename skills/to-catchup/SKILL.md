---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
disable-model-invocation: true
---

# Repository Catchup

Create or update one concise, evidence-based onboarding document at `docs/overview.md`. A junior reader should understand the project's purpose, actively used technology, major relationships, verified application workflows, confirmed HTTP routes when applicable, useful project commands, a safe reading path, and cautions. Aim for a few minutes' reading; collapse detail rather than silently omit verified workflows or endpoints.

## Boundaries

- Work from the target repository's files and history that are available in the current workspace.
- Treat `docs/recap.md` and `docs/backlog.md` as optional context when they exist; verify their claims against the repository.
- Create `docs/` when it does not exist.
- Create or update only `docs/overview.md`; preserve unrelated documentation and files.
- Never copy secret values. Record configuration names and safe placeholders only, and omit tokens, passwords, private keys, credentials, sensitive connection strings, and other secret material.
- Never guess. Mark missing, ambiguous, or unverified information as `Unknown` or `Needs verification`; for incomplete workflow or endpoint inventories, mark them `Partial` and say what remains unverified.

## Workflow

1. Establish the target repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with that root as their argument, using absolute paths resolved from this installed skill rather than paths inside the target project. These read-only helpers report bounded inventory, stack clues, and **entrypoint candidates**, not architectural conclusions. Read `docs/recap.md` and `docs/backlog.md` only if present and verify relevant claims. If a helper fails, inspect the relevant files directly; never infer facts from missing output.
2. Establish the project's purpose and Tech Stack from source, manifests, configuration, and tests. Include only actively used major languages/runtimes, frameworks, data stores, and queues. A declared or transitive dependency alone is not proof of use; include versions only when evidenced.
3. Inventory first-class application workflows by tracing observed triggers through meaningful checks and side effects to outcomes, including important user-facing, background, and admin paths. An endpoint or internal helper alone is not a workflow.
   - Name every verified workflow and give a one-line purpose in a visible list. Count exactly those names; claim `Complete` only with evidence of coverage. Otherwise mark `Partial` and describe which sources/triggers remain untraced.
   - Draw the three most user-facing or high-risk workflows inline if there are three or more, placing diagrams for every other workflow in one collapsed `<details>` block. For fewer than three, show all diagrams inline. Keep names and purposes visible outside the block.
4. If the repository registers HTTP routes, trace explicit registrations and mounted prefixes manually, checking OpenAPI declarations against implementation before relying on them. Deduplicate by `(HTTP method, full mounted route template)`; different methods on a path are different endpoints, including health/internal routes. Exclude implicit `HEAD`/`OPTIONS` unless explicitly registered, GraphQL operations, gRPC methods, entrypoint candidates, and guessed routes.
   - Include one table row with method, path, purpose, and evidenced access class for each confirmed pair. Count exactly the rows; never use blank placeholders to fill the total. If a method or mounted path cannot be established, exclude it and mark the inventory `Partial`, explaining what remains untraced. Collapse a long complete table, not rows; leave its total visible.
   - For a client-only repository or no registered HTTP routes, omit the entire `API Endpoints` section. Explain external API limitations in `Important Notes` rather than fabricating server routes.
5. Read `references/overview-template.md` and use its one ordered major heading contract: `# Project Overview`, then `## Purpose`, `## Tech Stack`, `## Project Tree`, `## Workflow`, optional `## API Endpoints`, `## Scripts`, `## Important Notes`. Do not add, rename, or reorder major sections.
6. Keep a selective project map, a junior's first reading steps, and relationships between components in `Project Tree`; explain verified workflows using one vertical stage per line with downward arrows. Cite evidence paths, distinguish candidates from observed behavior, and label uncertainties `Unknown`, `Needs verification`, or `Partial` for incomplete workflow/endpoint inventories. Do not imply shell tools prove semantic completeness.
7. In `Scripts`, list useful target-project commands with purpose, evidence, and whether exercised; warn before any command changing data. In `Important Notes`, cover security cautions, operational invariants, data/external services, configuration names with safe defaults, and evidence gaps. Never copy secret values or sensitive connection strings.
8. Before writing, validate ownership of any existing output. Keep one hidden HTML comment at the end of `docs/overview.md` in exactly this form, with LF line endings:
   ```md
   <!-- skill-state
   output_sha256: <64 lowercase hexadecimal characters>
   -->
   ```
   `output_sha256` is SHA-256 of the exact UTF-8 bytes of the entire document with only that metadata line and its line ending omitted. Retain the comment delimiters, every other metadata field, and every other byte and line ending unchanged; do not normalize content. On first write, write the completed overview followed by this comment and calculate the fingerprint by this rule.
   - If an existing output contains the `output_sha256` field, recompute the hash using that rule. If well-formed and matching, it is safe to update even when Git reports staged or unstaged changes to `docs/overview.md`. After every permitted update, recalculate and replace the fingerprint. If malformed, duplicated, or mismatched, stop without writing and ask how to preserve or merge edits.
   - If an existing output has no `output_sha256` field, adopt it only when it is a clean, tracked legacy file in a Git repository: verify it is tracked and `git status --short -- docs/overview.md` reports no staged or unstaged changes. Add the fingerprint with the next complete update. If untracked, modified, or in a non-Git repository, stop without writing and ask for direction; do not treat non-Git content as clean.
9. Write only after ownership permits it; preserve unrelated files. Re-read `docs/overview.md` and run this skill's `scripts/validate-overview.sh` on it. Fix structural and secret warnings before finishing. The validator checks exact major headings, recognizable secret patterns, and fingerprint when present; it does not prove pre-write authorization or the truth/completeness of architecture and inventory. Independently check evidence, count consistency, ownership, and unchanged unrelated files.

A catchup is complete when `docs/overview.md` follows this one concise contract, has evidence-backed purpose and technology, a selective reading path, visible verified workflows and vertical diagrams, an accurately counted HTTP endpoint inventory where applicable, useful safe commands, cautions and gaps, and a valid hidden fingerprint. The only intended repository output is `docs/overview.md` (plus `docs/` when needed).
