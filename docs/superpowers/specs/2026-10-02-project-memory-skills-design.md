# Project Memory Skills Design

## Status

Proposed after user approval of the three-skill architecture. The generated project-memory files are explicitly stored under each target project's `docs/` directory.

## Goal

Publish three portable Agent Skills in `narinsak-u/i-need-some-coffee` so developers can install all or one skill through the open `SKILL.md` format and use them to maintain lightweight project memory.

## Repository Contract

```text
i-need-some-coffee/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── skills/
│   ├── to-catchup/
│   │   ├── SKILL.md
│   │   └── references/overview-template.md
│   ├── to-recap/
│   │   ├── SKILL.md
│   │   └── references/recap-template.md
│   └── to-backlog/
│       ├── SKILL.md
│       └── references/backlog-template.md
└── examples/
    ├── overview.md
    ├── recap.md
    └── backlog.md
```

Each skill is independently installable. A skill may recognize the other generated files when present, but it must not require another skill or repository file to operate.

## Target Project Contract

Each skill writes only its owned file under the target project's `docs/` directory:

```text
target-project/
└── docs/
    ├── overview.md
    ├── recap.md
    └── backlog.md
```

If `docs/` does not exist, the skill creates it. Existing unrelated files in `docs/` are preserved. An existing owned file is updated according to that skill's rules; it is not moved to the repository root.

## Skill Contracts

### `to-catchup`

Purpose: help a new developer understand an unfamiliar repository quickly.

Behavior:

1. Inspect structure, README/docs, dependency files, entry points, routes/controllers, services, data models, API clients, authentication, configuration, tests, deployment files, and important shared utilities.
2. Trace the main application and data flows.
3. Create or refresh `docs/overview.md` using `references/overview-template.md`.
4. Explain how the system works, prioritizing important flows and modules over exhaustive file listings.
5. Redact secrets; never copy secret values from environment or configuration files.
6. State unknowns instead of guessing.

### `to-recap`

Purpose: maintain an append-only history of meaningful repository work.

Behavior:

1. Create `docs/` and `docs/recap.md` when absent.
2. Read the machine-readable `recap-state` checkpoint when present.
3. Analyze commits after the checkpoint, using ancestry carefully around rebases and merges.
4. Inspect relevant diffs and group related commits into meaningful work units rather than mapping one commit to one entry.
5. Append categorized entries for features, fixes, refactors, infrastructure, testing, documentation, security, or performance.
6. Update `Current Point` and the checkpoint with the resulting HEAD and date.
7. Keep prior entries intact; do not rewrite history merely to improve wording.
8. Separate committed work from uncommitted work and label uncertain verification.

### `to-backlog`

Purpose: maintain the source of truth for work another developer can pick up.

Behavior:

1. Create `docs/` and `docs/backlog.md` when absent.
2. Gather meaningful unfinished work from the current context, implementation gaps, explicit TODO/FIXME comments, Git state, `docs/overview.md`, and `docs/recap.md` when available.
3. Do not turn every small TODO or speculative improvement into a backlog item.
4. Use stable IDs such as `BL-001`; never renumber existing IDs.
5. Use only these statuses: `Todo`, `In Progress`, `Blocked`, `Needs Review`, `Done`.
6. Use `High`, `Medium`, or `Low` priorities.
7. Preserve existing items and update them only when repository evidence supports the change.
8. Record context, tasks, dependencies, related files, and blockers without inventing requirements.

## Cross-Skill Boundaries

- `to-catchup` owns stable architectural understanding in `docs/overview.md`.
- `to-recap` owns chronological completed-work history in `docs/recap.md`.
- `to-backlog` owns unfinished work in `docs/backlog.md`.
- Cross-references are optional context, never hard dependencies.
- None of the skills modifies another skill's owned file.

## Distribution

README must document:

```bash
npx skills add narinsak-u/i-need-some-coffee
npx skills add narinsak-u/i-need-some-coffee --skill to-recap
```

It must also include manual installation guidance, the three output paths, the independence guarantee, and the MIT license notice. No custom CLI, build system, or runtime package is required for v1.

The repository's GitHub slug is `i-need-some-coffee`; the skill names remain `to-catchup`, `to-recap`, and `to-backlog`.

## Verification

Before release, verify:

- Every `SKILL.md` has valid `name` and `description` frontmatter.
- Each skill references only files inside its own directory or standard repository tools.
- Each skill documents `docs/` creation and its owned output path.
- Templates match the output contracts and do not expose secrets.
- README commands use the actual repository name and skill names.
- Examples represent the three output formats without pretending to be generated from a real project.
- Repository layout contains no obsolete `agents/` or root-level generated project-memory files.
