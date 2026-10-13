---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
disable-model-invocation: true
---

# Repository Catchup

Create or update one concise, evidence-based onboarding document at `docs/overview.md`. A new reader should quickly understand the project's purpose, where its important parts live, the main runtime data path, and useful project commands. Aim for about one page where complexity permits.

## Boundaries

- Work from the target repository's files and history that are available in the current workspace.
- Treat `docs/recap.md` and `docs/backlog.md` as optional context when they exist; verify their claims against the repository.
- Create `docs/` when it does not exist.
- Create or update only `docs/overview.md`; preserve unrelated documentation and files.
- Never copy secret values. Record configuration names and safe placeholders only, and omit tokens, passwords, private keys, credentials, sensitive connection strings, and other secret material.
- Never guess. Mark missing, ambiguous, or unverified information as `Unknown` or `Needs verification` and identify what should be checked.

## Workflow

1. Establish the repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with the target repository root as their argument (invoke via an absolute path resolved from this skill directory, not a path inside the target project). The scripts report bounded inventory, manifest-based stack evidence, and **entrypoint candidates**, not architectural conclusions. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist. If a helper fails, inspect relevant files directly; never infer facts from missing output.
2. Inspect only repository evidence needed to explain the primary runtime path, security boundaries, configuration and useful project commands. Follow entrypoints into actual callers and outputs; candidates are leads, not proof of runtime behavior. Check tests, manifests, scripts and deployment/configuration files where they substantiate a claim.
3. Read `references/overview-template.md` and use its headings and guidance for `docs/overview.md`. Consolidate overlapping architecture, application/data flow, module and file inventories; do not add repetitive sections.
4. Fill every template section concisely. Cite paths or exact commands where useful; distinguish observed behavior from unverified candidates and mark unknowns as `Unknown` or `Needs verification`.
5. In `Scripts`, include useful commands and runnable scripts belonging to the target project, with a brief purpose. State whether commands were exercised; warn plainly before commands that alter data. Do not list this skill's internal helpers unless useful to the target project.
6. Keep security cautions, evidence gaps and operational invariants in `Important Notes`. In `Project Tree`, show important folders and a few key files only, not an exhaustive inventory. In `Workflow`, use one simple plain-text diagram for the primary runtime data path, with minimal necessary branches.
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
9. Write only after the ownership check permits it. Preserve unrelated files. Re-read the result and run this skill's `scripts/validate-overview.sh`; correct structural or obvious secret warnings before finishing. The validator checks structure, obvious secret patterns and the published fingerprint when present; it does not prove pre-write ownership or authorization. Separately verify repository evidence, observed flows, that the pre-write ownership decision was valid, and that unrelated files were preserved.

A catchup is complete when `docs/overview.md` exists, follows the concise template, gives an evidence-based purpose, selective project tree, observed primary runtime path, useful project commands and limited important notes, preserves safety cautions and evidence gaps, and has a valid hidden fingerprint. The only intended repository output is `docs/overview.md` (plus `docs/` if it had to be created).
