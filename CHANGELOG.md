# Changelog

All notable changes to this repository are documented here. Releases follow semantic versioning.

## [Unreleased]

- Hardened overview validation against URL user-info separator masking and bracketed credential values while preserving named redaction examples.
- Made catchup and backlog updates repeat-safe with integrity fingerprints and conservative legacy-file adoption.
- Made recap initial coverage the latest 100 commits and complete checkpoint-to-HEAD updates in bounded history batches, with no partial checkpoint advance.
- Set `disable-model-invocation: true` for all project-memory skills.
- Added portable, read-only repository inspection helpers and Markdown validators for the three independently installable skills, plus an offline fixture-based integration suite.

## [0.1.0] — 2026-10-02

Initial release of the project-memory skills:

- Added `to-catchup`, which creates or updates an evidence-based `docs/overview.md` covering repository purpose, architecture, application flow, configuration, development workflow, and cautions.
- Added `to-recap`, which maintains an append-only `docs/recap.md` with Git checkpoints and a separate view of uncommitted work.
- Added `to-backlog`, which maintains an evidence-backed `docs/backlog.md` with stable `BL-###` IDs, allowed statuses and priorities, dependencies, blockers, and completion records.
- Added local templates for each skill and documented the `docs/` output contract.
- Added fictional output examples and MIT licensing documentation.
