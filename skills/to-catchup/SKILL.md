---
name: to-catchup
description: Use when onboarding to unfamiliar repositories, documenting architecture and application flow, and creating docs/overview.md.
disable-model-invocation: true
---

# Repository Catchup

Create or update one concise, evidence-based onboarding document at `docs/overview.md`. A new reader should quickly understand the project's purpose, material technologies, architecture, representative runtime flows, important modules and files, data and external services, practical project commands, a short reading order, and repository-specific cautions. Use exactly the ten numbered sections in the overview template, in order; aim for a few minutes' reading and do not pad to a line target.

## Boundaries

- Work from the target repository's files and history that are available in the current workspace.
- Treat `docs/recap.md` and `docs/backlog.md` as optional context when they exist; verify their claims against the repository.
- Create `docs/` when it does not exist.
- Create or update only `docs/overview.md`; preserve unrelated documentation and files.
- Never copy secret values. Record configuration names and safe placeholders only, and omit tokens, passwords, private keys, credentials, sensitive connection strings, and other secret material.
- Never guess. Mark missing, ambiguous, or unverified information as `Unknown` or `Needs verification` and identify what should be checked.

## Workflow

1. Establish the repository root. Run this skill's `scripts/scan-project.sh`, `scripts/detect-stack.sh`, and `scripts/find-entrypoints.sh` with the target repository root as their argument (invoke via an absolute path resolved from this skill directory, not a path inside the target project). The scripts report bounded inventory, manifest-based stack evidence, and **entrypoint candidates**, not architectural conclusions. Look for `docs/recap.md` and `docs/backlog.md` without assuming they exist. If a helper fails, inspect relevant files directly; never infer facts from missing output.
2. Inspect only repository evidence needed to explain purpose, material technologies, architecture, representative runtime paths, security boundaries, configuration, and useful project commands. Follow entrypoints into actual callers and outputs; candidates are leads, not proof of runtime behavior. Check tests, manifests, scripts, and deployment/configuration files where they substantiate a claim.
3. Read `references/overview-template.md` and use its exact headings and order for `docs/overview.md`. The major headings are `# Project Overview`, followed by `## 1. Purpose` through `## 10. Important Notes` as listed in the template. Do not add, remove, rename, or reorder major sections.
4. Fill every template section concisely. Cite paths or exact commands where useful; distinguish observed behavior from unverified candidates and mark unknowns as `Unknown` or `Needs verification`. Trace two to five important flows when project complexity warrants them; omit unsupported claims.
5. Keep the project map selective across `Core Modules` and `Important Files`; do not include a separate project-tree section. Put useful target-project install, run, test, and build commands under `Development Workflow`, with purpose, evidence, whether exercised, and cautions before commands that alter data. Do not list this skill's internal helpers unless useful to the target project.
6. Use simple plain-text diagrams and consistent component terminology. Conceptual architecture and observed flows should not become function-by-function call stacks. Keep diagrams, headings, paths, commands, and code plain; purposeful emoji are allowed occasionally only in short labels or callouts.
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
