# Project Memory Skills

Portable Agent Skills for keeping lightweight, evidence-based memory in a target project's `docs/` directory. The repository distributes three independent skills:

- **`to-catchup`** — explains an unfamiliar repository in `docs/overview.md`.
- **`to-recap`** — records meaningful completed work incrementally in `docs/recap.md`.
- **`to-backlog`** — tracks concrete unfinished work in `docs/backlog.md`.

The skills use the open `SKILL.md` format and do not require a runtime package, custom build system, or project-specific integration.

## Install

The recommended installer is the cross-agent `skills` CLI. Install all three skills from the distribution repository:

```bash
npx skills add narinsak-u/i-need-some-coffee
```

Install only one skill when that is all you need:

```bash
npx skills add narinsak-u/i-need-some-coffee --skill to-catchup
npx skills add narinsak-u/i-need-some-coffee --skill to-recap
npx skills add narinsak-u/i-need-some-coffee --skill to-backlog
```

Each skill is independently installable. `to-recap` does not require `to-catchup`, and `to-backlog` does not require either of the other skills. When present, a skill may use another generated document as optional, read-only context; cross-skill files are never hard dependencies and a skill never edits another skill's owned file.

### Manual fallback

If the CLI is unavailable, clone the repository and copy the skill directory (including its `SKILL.md` and `references/` directory) into the skills directory supported by your agent:

```bash
git clone https://github.com/narinsak-u/i-need-some-coffee.git
cp -R i-need-some-coffee/skills/to-catchup /path/to/your/agent/skills/
```

Replace `to-catchup` with `to-recap` or `to-backlog` for a single skill, or copy all three directories for the complete set. The destination is agent-specific; use the skills directory documented by your agent rather than assuming a universal path.

## Usage and outputs

Run a skill from the root of the target project and ask your agent to use the installed skill. Each skill creates `docs/` when needed and owns exactly one generated file:

| Skill | Output | Purpose |
| --- | --- | --- |
| `to-catchup` | `docs/overview.md` | Repository purpose, architecture, application flow, modules, configuration, workflow, and cautions. |
| `to-recap` | `docs/recap.md` | Append-only, checkpointed summaries of committed work, kept separate from uncommitted changes. |
| `to-backlog` | `docs/backlog.md` | Evidence-backed unfinished work with stable IDs, statuses, priorities, dependencies, and blockers. |

Existing unrelated files in `docs/` are preserved. The skills are deliberately narrow: install only the one that matches your workflow, or install all three for complementary project memory.

## Safety and evidence rules

- Never copy secrets into generated documentation. Do not include tokens, passwords, private keys, credentials, or sensitive connection strings; record configuration names and safe placeholders instead.
- Examples and generated claims should be grounded in repository files and observed Git evidence. When evidence is missing or ambiguous, record `Unknown` or `Needs verification` rather than guessing.
- `to-catchup` owns stable architectural understanding, `to-recap` owns chronological completed-work history, and `to-backlog` owns unfinished work. Optional cross-references do not change those boundaries.

## Examples

See the clearly fictional examples in [`examples/`](examples/):

- [`examples/overview.md`](examples/overview.md)
- [`examples/recap.md`](examples/recap.md)
- [`examples/backlog.md`](examples/backlog.md)

They illustrate the output shapes without claiming to describe a real repository or real history.

## Versioning

This repository uses semantic versioning for documented distribution releases. The current release is **0.1.0**, recorded in [`CHANGELOG.md`](CHANGELOG.md). Release notes describe changes to skill behavior, templates, documentation, and output contracts. Because these are portable Markdown skills rather than a runtime package, installing from a tagged repository release is the way to pin a version; installing from the default branch follows its latest documentation.

## License

Released under the [MIT License](LICENSE). Copyright © 2026 narinsak-u.
