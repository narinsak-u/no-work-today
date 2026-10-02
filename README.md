# Project Memory Skills 🧠

Small, focused Agent Skills that help your coding agent understand what a project is, remember what changed, and keep track of what still needs work.

Everything is written to the target project's `docs/` directory, so your project memory stays close to the code. The skills use the open `SKILL.md` format and do not need a runtime package, custom build system, or project-specific integration.

## Skills at a glance ✨

- **`to-catchup`** — Get oriented in an unfamiliar repository and create `docs/overview.md`.
- **`to-recap`** — Keep an incremental, evidence-based history in `docs/recap.md`.
- **`to-backlog`** — Track meaningful unfinished work in `docs/backlog.md`.

Install one skill or use all three together for a lightweight project-memory system:

```text
to-catchup  →  How does this project work?
to-recap    →  What has happened?
to-backlog  →  What still needs to be done?
```

## Install 🚀

### Install all three skills

The recommended option is the cross-agent `skills` CLI:

```bash
npx skills add narinsak-u/no-work-today
```

### Install just one skill

```bash
npx skills add narinsak-u/no-work-today --skill to-catchup
npx skills add narinsak-u/no-work-today --skill to-recap
npx skills add narinsak-u/no-work-today --skill to-backlog
```

Each skill is independently installable. `to-recap` does not require `to-catchup`, and `to-backlog` does not require either of the other skills. When available, another generated document may be used as optional, read-only context; skills never hard-depend on or edit one another's files.

### Manual installation

If the CLI is unavailable, clone the repository and copy the skill directory—including its `SKILL.md` and `references/` directory—into the skills directory supported by your agent:

```bash
git clone https://github.com/narinsak-u/no-work-today.git
cp -R no-work-today/skills/to-catchup /path/to/your/agent/skills/
```

Replace `to-catchup` with `to-recap` or `to-backlog` to install one skill, or copy all three directories for the complete set. Agent skill-directory locations vary, so use the path documented by your agent.

## Usage and outputs 🛠️

Run a skill from the root of the target project and ask your agent to use it. Each skill creates `docs/` when needed and owns exactly one generated file:

| Skill | Output | What it helps with |
| --- | --- | --- |
| `to-catchup` | `docs/overview.md` | Project purpose, architecture, application flow, modules, configuration, workflow, and cautions. |
| `to-recap` | `docs/recap.md` | Append-only, checkpointed summaries of committed work, kept separate from uncommitted changes. |
| `to-backlog` | `docs/backlog.md` | Evidence-backed unfinished work with stable IDs, statuses, priorities, dependencies, and blockers. |

Existing unrelated files in `docs/` are preserved. Install only the skill that matches your workflow, or install all three for complementary project memory.

## Safety and evidence rules 🛡️

- Never copy secrets into generated documentation. Do not include tokens, passwords, private keys, credentials, or sensitive connection strings; record configuration names and safe placeholders instead.
- Ground examples and generated claims in repository files and observed Git evidence. When evidence is missing or ambiguous, record `Unknown` or `Needs verification` instead of guessing.
- Keep responsibilities separate: `to-catchup` owns architectural understanding, `to-recap` owns completed-work history, and `to-backlog` owns unfinished work.

## Examples 📚

See the clearly fictional examples in [`examples/`](examples/):

- [`examples/overview.md`](examples/overview.md)
- [`examples/recap.md`](examples/recap.md)
- [`examples/backlog.md`](examples/backlog.md)

They demonstrate the output shapes without claiming to describe a real repository or real history.

## Versioning 🏷️

This repository uses semantic versioning for documented distribution releases. The current release is **0.1.0**, recorded in [`CHANGELOG.md`](CHANGELOG.md).

Install from a tagged repository release to pin a version. Installing from the default branch follows the latest documentation.

## License 📄

Released under the [MIT License](LICENSE). Copyright © 2026 narinsak-u.
