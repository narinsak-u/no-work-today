# Project Overview

## Purpose

In a few plain-language sentences, explain what the repository does and who it serves. Cite evidence; label unresolved purpose `Unknown` or `Needs verification`.

## Project Tree

Show only important folders and a few key files, with a short note on why they matter. Keep this selective, not an exhaustive inventory.

```text
src/                 main implementation
src/main.ts          startup (candidate until runtime use is confirmed)
tests/               automated checks
package.json         commands and dependencies
```

Use paths supported by repository evidence. Do not treat a detected entrypoint candidate as proven runtime behavior.

## Workflow

Use one simple plain-text diagram for the primary runtime data path. Identify what was observed in code and distinguish candidates or unresolved links explicitly. Include only necessary branches and side effects.

```text
Observed: input → validated handler → persisted result → response
Needs verification: detected candidate → runtime startup
```

Name the source path(s) that support important workflow claims. Do not repeat the diagram as separate architecture, application-flow, module, data-flow, or file-inventory sections.

## Scripts

List useful commands and runnable scripts that belong to the target project. Give each a concise purpose, cite the manifest/script/readme evidence, and say whether it was exercised. Warn before commands that alter data (for example migrations, resets, seeders, deployment, or destructive cleanup). Do not list this skill's internal helpers unless they are genuinely useful to project users.

## Important Notes

Keep this section limited to essential security cautions, operational invariants, configuration/setup requirements, generated-file warnings, ownership or deployment unknowns, and evidence gaps. Record configuration names and safe placeholders only; never copy secrets. Use paths and exact commands where they help a reader verify or act safely.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->
