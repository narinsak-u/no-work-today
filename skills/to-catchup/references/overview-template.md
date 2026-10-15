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

Trace two to five representative runtime workflows when project complexity warrants them. Each flow has a short subheading, a one-sentence explanation, and a simple plain-text diagram grounded in the observed entry, meaningful processing stages, and observable output. Keep the primary path vertical; use short lateral branches only for real, verified branches. Name evidence paths, mark unknown links explicitly, and omit unsupported claims.

```text
Request
  |
  v
Validated handler
  |
  v
Persisted result
  |
  v
Response
```

## 5. Core Modules

Show a selective tree of the usual three to seven important functional areas, grouped under relevant parent directories, with brief responsibility labels. Keep it to useful levels and omit irrelevant directories.

```text
src/
├── auth/       — identity and sessions
└── reports/    — report generation
```

## 6. Important Files

Give a separate, short reading list of files a developer should open first, with why each matters. Cite repository evidence; do not reproduce the module tree or turn this into a directory map.

## 7. Data & External Services

Summarize important persistent data, configuration, and external integrations that affect behavior. Record names and safe placeholders only; never include secret values or sensitive connection strings. Label unresolved details `Unknown` or `Needs verification`.

## 8. Development Workflow

Give the useful target-project install, run, test, and build commands with a short purpose and source evidence. State whether commands were exercised. Warn plainly before commands that alter data. Do not list this skill's internal helpers unless they are useful to project users.

## 9. Start Here

Give a short, practical reading order for a new developer's first 15–30 minutes, using paths and a brief reason for each step.

## 10. Important Notes

Keep this section limited to repository-specific security cautions, operational invariants, setup requirements, generated-file warnings, ownership or deployment unknowns, and evidence gaps. Use precise paths and commands where useful.
- Main Flows use concise, evidence-backed vertical diagrams with emoji only in short flow subheadings; Core Modules uses a selective three-to-seven-area tree with responsibility labels, separate from the Important Files reading list.

Keep the overview concise and useful, normally readable in a few minutes; roughly 80–150 lines only where warranted. Prefer verified facts over completeness, and do not pad. Use purposeful emoji only in short Main Flow or Core Modules subheadings. Keep the ten numbered headings exact; diagrams, paths, commands, and code remain emoji-free.

<!-- skill-state
output_sha256: <64 lowercase hexadecimal characters>
-->
