# Project Overview

## 1. Purpose

In a few plain-language sentences, explain what the repository does and who it serves. Cite evidence; label unresolved purpose `Unknown` or `Needs verification`.

## 2. Tech Stack

List only technologies that materially explain the system. Cite manifests/configuration; avoid dependency inventories. Mark uncertain roles `Needs verification`.

## 3. Architecture

Describe the main conceptual components and their relationships. Use consistent component names and a small plain-text diagram where useful; do not infer runtime behavior from filenames alone.

```text
Client → Application → Data store
```

## 4. Main Flows

Trace two to five representative runtime workflows when project complexity warrants them. Follow actual entrypoints through callers and observable outputs; name supporting paths. Keep diagrams simple (normally five to twelve nodes), with minimal necessary branches. Mark candidate or unknown links explicitly; omit unsupported claims.

```text
Observed: request → validated handler → persisted result → response
Needs verification: detected candidate → runtime startup
```

## 5. Core Modules

Group the important functional modules by responsibility and give their repository locations. Put the selective project map here rather than reproducing a full tree.

## 6. Important Files

Select a few files a developer should open first and explain why each matters. Include paths supported by repository evidence; avoid duplicating the full module map.

## 7. Data & External Services

Summarize important persistent data, configuration, and external integrations that affect behavior. Record names and safe placeholders only; never include secret values or sensitive connection strings. Label unresolved details `Unknown` or `Needs verification`.

## 8. Development Workflow

Give the useful target-project install, run, test, and build commands with a short purpose and source evidence. State whether commands were exercised. Warn plainly before commands that alter data. Do not list this skill's internal helpers unless they are useful to project users.

## 9. Start Here

Give a short, practical reading order for a new developer's first 15–30 minutes, using paths and a brief reason for each step.

## 10. Important Notes

Keep this section limited to repository-specific security cautions, operational invariants, setup requirements, generated-file warnings, ownership or deployment unknowns, and evidence gaps. Use precise paths and commands where useful.

Keep the overview concise and useful, normally readable in a few minutes; roughly 80–150 lines only where warranted. Prefer verified facts over completeness, and do not pad. Use occasional purposeful emoji only in short labels or callouts. Keep headings, diagrams, paths, commands, and code plain.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->
