# Changelog

All notable changes to this repository are documented here. Releases follow semantic versioning.

## [Unreleased]
- Safely adopt clean tracked legacy recaps by preserving old entries byte-for-byte, validating new entries, and refusing ambiguous or modified history.
- Recorded manual scenarios and exploratory outputs; valid paired comparisons remain unavailable because the runtime exposed skill resources to no-skill controls; trimmed the catchup example to the documented 150-line ceiling.
- Added a no-skill isolation preflight to prevent contaminated skill comparisons.
- Clarified that each recap entry keeps selected commit IDs inline on its single **Commits:** field line, based on 100-commit wording micro-tests.
- Required every recap publication, including caught-up updates, to pin `history_head` to captured `HEAD`; preserved the exact pending queue and rejected partial publications without the required continuation boundary.
- Distinguished the recap helper directory from the target Git root in skill instructions and validator calls.
- Clarified recap shell-state and helper-root handling, evidence-backed groups of at most ten commits, single-line commit evidence, fail-closed publication, optional Junior notes, and singular/plural pending-history grammar.
- Added truthful empty-repository recaps and a validated empty-to-first-commit transition that preserves the prior state; subsequent caught-up runs leave the recap unchanged.
- Fixed the recap shell regression loop under `set -e` when its remaining-commit counter reaches zero.
- Reworked catchup overviews around ten evidence-based sections, tightened exact ordered-heading validation, and updated the fictional example and regression coverage.
- Improved catchup Main Flows with concise vertical diagrams and selective Core Modules trees while preserving the ten-heading and safety contracts.
- Bound each recap invocation to 100 commits, preserve an oldest-first continuation checkpoint, and put new plain-language summaries ahead of collapsed technical evidence.
- Restored catchup protection for credential-bearing URL user-info and prefixed credential assignments, including short secret values, while allowing recognized redaction placeholders.
- Updated the catchup shell seam coverage and added a readable recap example with explicit checkpoint and pending-history state.
- Expanded catchup overviews with evidence-backed Tech Stack sections, named workflow inventories with vertical diagrams, and correctly counted HTTP endpoint tables when applicable.
- Catchup validation now checks a single terminal `output_sha256` fingerprint against the exact document bytes, including files without a final newline, while allowing clean legacy files without fingerprints.

- Fixed credential guards for quoted redaction markers, comma/semicolon-adjacent values, and percent-encoded URL hosts; restored safe recap rejection diagnostics and bounded credential validation loops.
- Suppressed standalone credential tokens in backlog TODO helper output while retaining safe lead locations, and accepted only recognized multiword redaction labels in credential assignments.
- Hardened overview validation against URL user-info separator masking, bracketed credentials with appended values, and comma-delimited credential tails while preserving named redaction examples.
- Recognize indented Cargo dependency tables and mixed-case Poetry dependency names when deriving catchup framework hints, without treating unrelated manifest fields as dependencies.
- Reject recap drafts that advance the checkpoint unless every selected commit appears exactly once in dated work entries.
- Report per-file and global omissions of safe backlog TODO leads separately from suppressed credential-bearing leads.
- Include nested App Router page/layout entrypoint candidates under `app` or `src/app` while excluding private folders and non-route extensions.
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
