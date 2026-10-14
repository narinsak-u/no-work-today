---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
disable-model-invocation: true
---

# Repository Catchup

<<<<<<< HEAD
Create or update one concise, evidence-based onboarding document at `docs/overview.md`. A new reader should quickly understand the project's purpose, material technologies, architecture, representative runtime flows, important modules and files, data and external services, practical project commands, a short reading order, and repository-specific cautions. Use exactly the ten numbered sections in the overview template, in order; aim for a few minutes' reading and do not pad to a line target.
=======
Create or update one concise, evidence-based onboarding document at `docs/overview.md`. A new reader should quickly understand the project's purpose, major technologies, important application workflows, project structure, and useful commands. Aim for about one page where complexity permits; collapse detail rather than silently omitting verified workflows or endpoints.
>>>>>>> d910d8d (feat: improve catchup overview inventories)

## Boundaries

- Work from the target repository's files and history that are available in the current workspace.
- Treat `docs/recap.md` and `docs/backlog.md` as optional context when they exist; verify their claims against the repository.
- Create `docs/` when it does not exist.
- Create or update only `docs/overview.md`; preserve unrelated documentation and files.
- Never copy secret values. Record configuration names and safe placeholders only, and omit tokens, passwords, private keys, credentials, sensitive connection strings, and other secret material.
- Never guess. Mark missing, ambiguous, or unverified information as `Unknown` or `Needs verification`; for incomplete workflow or endpoint inventories, mark them `Partial` and say what remains unverified.

## Workflow

<<<<<<< HEAD
1. Establish the repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with the target repository root as their argument (invoke via an absolute path resolved from this skill directory, not a path inside the target project). The scripts report bounded inventory, manifest-based stack evidence, and **entrypoint candidates**, not architectural conclusions. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist. If a helper fails, inspect relevant files directly; never infer facts from missing output.
2. Inspect only repository evidence needed to explain purpose, material technologies, architecture, representative runtime paths, security boundaries, configuration, and useful project commands. Follow entrypoints into actual callers and outputs; candidates are leads, not proof of runtime behavior. Check tests, manifests, scripts, and deployment/configuration files where they substantiate a claim.
3. Read `references/overview-template.md` and use its exact headings and order for `docs/overview.md`. The major headings are `# Project Overview`, followed by `## 1. Purpose` through `## 10. Important Notes` as listed in the template. Do not add, remove, rename, or reorder major sections.
4. Fill every template section concisely. Cite paths or exact commands where useful; distinguish observed behavior from unverified candidates and mark unknowns as `Unknown` or `Needs verification`. Trace two to five important flows when project complexity warrants them; each needs a short subheading, one-sentence purpose, and evidence-based diagram of the observed entry, meaningful stages, and output.
5. Keep the project map selective across `Core Modules` and `Important Files`; do not include a separate project-tree section. In `Core Modules`, show a selective tree of the usual three to seven functional areas with brief responsibility labels; omit irrelevant directories and keep `Important Files` a separate reading list, not another tree. Put useful target-project install, run, test, and build commands under `Development Workflow`, with purpose, evidence, whether exercised, and cautions before commands that alter data. Do not list this skill's internal helpers unless useful to the target project.
6. Use simple plain-text diagrams and consistent component terminology. For each Main Flow, state its purpose concisely, then show the verified primary path vertically from observed entry through meaningful stages to output. Use short lateral branches only for real, verified alternatives; do not substitute horizontal prose arrows or treat filenames as verified runtime paths. Use purposeful emoji only in short flow or module subheadings. Keep exact numbered headings, diagrams, paths, commands, and code emoji-free.
7. In configuration descriptions, record variable names, safe defaults and setup requirements without exposing secret values. If a file contains secrets, describe its role without reproducing contents.
8. Before writing, validate ownership of the existing output. Keep one hidden HTML comment at the end of `docs/overview.md` in this exact form, with LF line endings:
   ```md
   <!-- skill-state
   output_sha256: <64 lowercase hexadecimal characters>
   -->
   ```
   `output_sha256` is SHA-256 of the exact UTF-8 bytes of the entire document with only that metadata line and its line ending omitted. Retain the comment delimiters, every other metadata field, and every other byte and line ending unchanged; do not normalize content. On first write, write the completed overview followed by this comment and calculate the fingerprint by this rule.
   - If an existing output contains the `output_sha256` field, recompute the hash using that rule. If well-formed and matching, it is safe to update even when Git reports staged or unstaged changes to `docs/overview.md`. After every permitted update, recalculate and replace the fingerprint. If malformed, duplicated, or mismatched, stop without writing and ask how to preserve or merge edits.
   - If an existing output has no `output_sha256` field, adopt it only when it is a clean, tracked legacy file in a Git repository: verify it is tracked and `git status --short -- docs/overview.md` reports no staged or unstaged changes. Add the fingerprint with the next complete update. If untracked, modified, or in a non-Git repository, stop without writing and ask for direction; do not treat non-Git content as clean.
9. Write only after the ownership check permits it. Preserve unrelated files. Re-read the result and run this skill's `scripts/validate-overview.sh`; correct structural or obvious secret warnings before finishing. The validator checks the exact major heading set and order, secret patterns, and published fingerprint; it does not prove pre-write ownership or authorization. Separately verify repository evidence, observed flows, that the pre-write ownership decision was valid, and that unrelated files were preserved.

A catchup is complete when `docs/overview.md` uses exactly the required ordered ten sections, gives concise repository-evidenced onboarding guidance, explains representative observed flows where warranted, preserves safety cautions and evidence gaps, and has a valid hidden fingerprint.
=======
1. Establish the repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with the target repository root as their argument (invoke via an absolute path resolved from this skill directory, not a path inside the target project). The scripts report bounded inventory, stack clues, and **entrypoint candidates**, not architectural conclusions. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist. If a helper fails, inspect relevant files directly; never infer facts from missing output.
2. Establish the repository purpose and Tech Stack from evidence. Include only major languages/runtimes, frameworks, data stores, and queues that are actively used. Verify helper clues against manifests, imports, configuration, and runtime code; a declared or transitive dependency alone is not proof. Include a version only when directly evidenced.
3. Inventory all first-class application workflows by tracing verified triggers to outcomes, including meaningful checks and side effects. Include user-facing and important background/admin paths; an individual endpoint or internal helper is not a workflow.
   - Name every verified workflow and give it a one-line purpose. State the count and whether the inventory is Complete or Partial. The count must equal the number of visible workflow names; for Partial inventories, say which triggers or sources remain untraced.
   - Use vertical plain-text diagrams. If there are three or more workflows, show the three most user-facing/high-risk diagrams inline and put diagrams for every other workflow in one collapsed `<details>` block. If there are fewer than three, show all diagrams inline. Keep every workflow name and purpose visible outside the collapsed block.
4. If the repository registers HTTP routes, trace route registrations and mounted prefixes manually; combine each mounted prefix with its route template exactly as registered.
   - Add one table row per distinct explicitly registered HTTP method + full route-template pair. Different methods on the same path count separately; a dynamic route template counts once. Include purpose and access class when verified, including health/internal routes.
   - Exclude implicit `HEAD`/`OPTIONS`, GraphQL operations, gRPC methods, entrypoint candidates, and guessed routes. Count `HEAD`/`OPTIONS` only if explicitly registered. Cross-check checked-in OpenAPI against implementation before using it as route evidence.
   - Treat the table as a set keyed by `(HTTP method, full mounted path)`: repeated discoveries of the same pair produce one row; different methods produce separate rows. Every row must have a method, path, and purpose.
   - Count the deduplicated rows and make the visible total equal that count. Never add a blank or placeholder row to fill a total. If a route's method or path cannot be established, omit it from the confirmed rows and describe the gap; mark the inventory `Partial`.
   - For a long inventory, keep the count visible and collapse the complete table if it would push the overview past about one page.
   - If the repository is only a client or has no HTTP route registrations, omit the entire `API Endpoints` section. Put the external API limitation in `Important Notes`; do not create an empty or prose-only endpoint section and do not infer server routes from a remote API URL.
5. Read `references/overview-template.md` and use its headings and guidance for `docs/overview.md`. Keep the order: Purpose, Tech Stack, Project Tree, Workflow, optional API Endpoints, Scripts, Important Notes. Keep GraphQL/gRPC transport notes separate from the HTTP endpoint table.
6. Fill every applicable template section concisely. Cite paths or exact commands where useful; distinguish observed behavior from candidates and mark unknowns or incomplete inventories clearly. Use vertical, simple, plain-text workflow diagrams with one stage per line and downward arrows.
7. In `Scripts`, include useful commands and runnable scripts belonging to the target project, with a brief purpose. State whether commands were exercised; warn plainly before commands that alter data. Do not list this skill's internal helpers unless useful to the target project.
8. Keep security cautions, evidence gaps, and operational invariants in `Important Notes`. In `Project Tree`, show important folders and a few key files only, not an exhaustive inventory. In Tech Stack, omit transitive dependencies and unsupported versions.
9. In configuration descriptions, record variable names, safe defaults, and setup requirements without exposing secret values. If a file contains secrets, describe its role without reproducing contents.
10. Before writing, validate ownership of the existing output. Keep one hidden HTML comment at the end of `docs/overview.md` in this exact form, with LF line endings:
    ```md
    <!-- skill-state
    output_sha256: <64 lowercase hexadecimal characters>
    -->
    ```
    `output_sha256` is SHA-256 of the exact UTF-8 bytes of the entire document with only that metadata line and its line ending omitted. Retain the comment delimiters, every other metadata field, and every other byte and line ending unchanged; do not normalize content. On first write, write the completed overview followed by this comment and calculate the fingerprint by this rule.
    - If an existing output contains the `output_sha256` field, recompute the hash using that rule. If well-formed and matching, it is safe to update even when Git reports staged or unstaged changes to `docs/overview.md`. After every permitted update, recalculate and replace the fingerprint. If malformed, duplicated, or mismatched, stop without writing and ask how to preserve or merge edits.
    - If an existing output has no `output_sha256` field, adopt it only when it is a clean, tracked legacy file in a Git repository: verify it is tracked and `git status --short -- docs/overview.md` reports no staged or unstaged changes. Add the fingerprint with the next complete update. If untracked, modified, or in a non-Git repository, stop without writing and ask for direction; do not treat non-Git content as clean.
11. Write only after the ownership check permits it. Re-read the result and run this skill's `scripts/validate-overview.sh`; correct structural or obvious secret warnings before finishing. The validator checks structure, obvious secret patterns, and the published fingerprint when present; it does not prove pre-write ownership or architectural correctness. Separately verify repository evidence, workflow/route coverage, endpoint and workflow count consistency, that the pre-write ownership decision was valid, and that unrelated files were preserved.

A catchup is complete when `docs/overview.md` exists, follows the concise template, gives an evidence-based purpose and Tech Stack, selectively presents the project tree, names all verified workflows with appropriately vertical diagrams, includes a correctly counted HTTP endpoint table when applicable, lists useful project commands, preserves safety cautions and evidence gaps, and has a valid hidden fingerprint. The only intended repository output is `docs/overview.md` (plus `docs/` if it had to be created).
>>>>>>> d910d8d (feat: improve catchup overview inventories)
