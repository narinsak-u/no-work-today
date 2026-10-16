Below is a concise implementation spec you can hand directly to a coding agent.

# Junior Developer Agent Skills — Implementation Spec

## Goal

Build a portable, reusable skill package for AI coding agents that helps junior developers understand an existing project quickly and continue work safely.

The package contains exactly three skills:

- `to-catchup`
- `to-recap`
- `to-backlog`

The skills must use:

- `SKILL.md` for agent reasoning and workflow
- shell scripts for deterministic repository inspection
- reference templates for generated Markdown
- validation scripts for output verification

The implementation must remain agent-agnostic and should work with coding agents that support `SKILL.md` or can read repository instructions.

---

# 1. Repository Structure

Create the following structure:

```text
junior-dev-skills/
├── README.md
├── LICENSE
├── AGENTS.md
├── CHANGELOG.md
│
├── skills/
│   ├── to-catchup/
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   ├── scan-project.sh
│   │   │   ├── detect-stack.sh
│   │   │   ├── find-entrypoints.sh
│   │   │   └── validate-overview.sh
│   │   └── references/
│   │       └── overview-template.md
│   │
│   ├── to-recap/
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   │   ├── collect-git-context.sh
│   │   │   ├── changed-files.sh
│   │   │   ├── validate-checkpoint.sh
│   │   │   └── validate-recap.sh
│   │   └── references/
│   │       └── recap-template.md
│   │
│   └── to-backlog/
│       ├── SKILL.md
│       ├── scripts/
│       │   ├── find-todos.sh
│       │   ├── working-tree.sh
│       │   └── validate-backlog.sh
│       └── references/
│           └── backlog-template.md
│
├── scripts/
│   └── lib/
│       └── common.sh
│
└── tests/
    ├── fixtures/
    └── test-scripts.sh
```

---

# 2. Design Principles

Follow these principles throughout the implementation.

## Agent vs Shell Responsibilities

Shell scripts collect deterministic facts.

Examples:

- Git history
- branch name
- current HEAD
- changed files
- repository structure
- detected languages/frameworks
- TODO/FIXME comments
- working tree state

The AI agent performs interpretation.

Examples:

- architecture understanding
- grouping commits into meaningful work
- deciding which TODOs belong in the backlog
- explaining code flow
- prioritizing important files
- summarizing work for junior developers

Do not place semantic project interpretation into shell scripts.

---

# 3. Safety Rules

All inspection scripts must be read-only.

Allowed examples:

```bash
git log
git diff
git status
git show
git rev-parse
find
grep
rg
sed
awk
```

Do not perform destructive operations such as:

```bash
git reset
git clean
git checkout
git rebase
git commit
git push
rm -rf
```

Skills must never automatically modify Git history.

Only each skill's owned generated Markdown document may be created or updated by the agent, under the target repository's `docs/` directory:

```text
docs/overview.md
docs/recap.md
docs/backlog.md
```

---

# 4. Portability

Required dependencies:

```text
sh/bash
git
grep
find
sed
awk
```

Optional dependencies:

```text
rg
jq
fd
```

If an optional command is used, provide a fallback.

Example:

```bash
if command -v rg >/dev/null 2>&1; then
  rg 'TODO|FIXME'
else
  grep -RInE 'TODO|FIXME' .
fi
```

Scripts should work on:

- Linux
- macOS
- WSL
- common coding-agent containers

Use:

```bash
set -euo pipefail
```

where Bash is required.

Handle paths containing spaces correctly.

---

# 5. Shared Shell Utilities

Create:

```text
scripts/lib/common.sh
```

Provide reusable helpers where useful.

Suggested functions:

```bash
repo_root
is_git_repo
current_branch
current_head
has_command
```

Example behavior:

```bash
repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}
```

Avoid unnecessary abstraction. Only move genuinely shared behavior into this file.

---

# 6. Skill: `to-catchup`

## Purpose

Explore an unfamiliar project and generate a concise, evidence-based `docs/overview.md` so a junior developer can understand its purpose, actively used technology, selective structure, verified application workflows, confirmed HTTP endpoints if registered, useful project commands, a safe first reading path, and cautions.

Focus on explaining the system, not enumerating every file. Use `Partial` for workflow or endpoint inventories whose completeness is not evidenced; never invent routes for a client-only repository.

---

## Input Sources

Inspect when available:

```text
README*
AGENTS.md
package.json
Cargo.toml
go.mod
pyproject.toml
requirements.txt
Dockerfile
docker-compose*
compose*
.env.example
configuration files
source directories
routes
controllers
handlers
services
database models/schema
tests
CI configuration
deployment configuration
```

Never expose secrets from `.env` or secret files.

---

## Shell Script: `scan-project.sh`

Collect a filtered repository inventory.

Exclude noisy/generated directories such as:

```text
.git
node_modules
dist
build
target
vendor
.next
coverage
.cache
```

Do not output the entire repository if it is very large.

Limit output to a reasonable amount.

Collect:

```text
repository root
branch
top-level directories
important config files
documentation
source directories
test directories
deployment files
```

---

## Shell Script: `detect-stack.sh`

Detect common stacks using repository manifests.

Examples:

```text
package.json → JavaScript / TypeScript ecosystem
Cargo.toml → Rust
go.mod → Go
pyproject.toml → Python
requirements.txt → Python
```

Where possible, detect major frameworks from manifests.

Examples:

```text
Next.js
React
Remix
Vue
Nuxt
SvelteKit
Hono
Express
NestJS
FastAPI
Axum
Fiber
```

Do not claim a framework unless repository evidence supports it.

---

## Shell Script: `find-entrypoints.sh`

Identify likely application entry points.

Examples:

```text
src/main.*
src/index.*
app/*
pages/*
main.rs
lib.rs
main.go
cmd/*
main.py
app.py
server.*
```

The script should provide candidates only.

The agent must verify actual flow before documenting it.

---

## Output

Create or update only `docs/overview.md` (and create `docs/` when absent). Use `skills/to-catchup/references/overview-template.md` as the single format authority.

The exact ordered major headings are:

```md
# Project Overview
## Purpose
## Tech Stack
## Project Tree
## Workflow
## API Endpoints
## Scripts
## Important Notes
```

Omit `## API Endpoints` entirely for client-only projects or repositories without registered HTTP routes; explain external API limitations in Important Notes. Put architecture relationships and the first reading path in Project Tree rather than separate major sections. List every verified workflow's name and one-line purpose visibly, with concise vertical trigger-to-outcome diagrams (collapse additional diagrams when needed). Count only distinct confirmed HTTP method and full mounted route-template pairs, including health/internal routes, and state what remains untraced for Partial inventories. List useful evidenced commands and warn before any command that changes data.

## Validation

`validate-overview.sh` checks the exact ordered heading set with optional endpoint section, obvious secret patterns, and the output fingerprint when present. It cannot prove architecture, coverage, routes, or pre-write ownership; the agent checks source evidence and existing-output ownership before publishing.

---

# 7. Skill: `to-recap`

## Purpose

Maintain a chronological, append-only history of meaningful project work in:

```text
docs/recap.md
```

The skill should answer:

- what was implemented
- what was fixed
- what changed
- why it changed
- when it happened
- which files matter
- where development currently stopped

---

## Incremental Processing

`recap.md` must contain a checkpoint:

```md
<!-- recap-state
last_commit: abc1234
last_updated: YYYY-MM-DD
-->
```

On future runs:

1. read `recap.md`
2. obtain `last_commit`
3. validate that the commit exists
4. analyze only commits after the checkpoint
5. append new recap entries
6. update `Current Point`
7. update the checkpoint

Preferred Git range:

```bash
git log <last_commit>..HEAD
```

---

## Rebase / Missing Checkpoint Handling

If the checkpoint no longer exists, for example after a rebase:

- do not fail silently
- inform the agent that the checkpoint is stale
- inspect recent history
- recover the most reasonable starting point
- avoid duplicating already documented work where possible

The agent should use existing recap content to detect duplicates.

---

## Shell Script: `collect-git-context.sh`

Accept an optional previous checkpoint.

Collect:

```text
branch
HEAD
working tree state
commit hash
commit date
author
commit subject
```

Preferred commit format:

```text
full_hash|YYYY-MM-DD|author|subject
```

Do not summarize commit meaning in shell.

---

## Shell Script: `changed-files.sh`

Given a base commit, collect:

```text
git diff --stat
git diff --name-status
```

Optionally allow inspection for an individual commit.

Do not automatically dump massive diffs.

The agent should inspect detailed diffs only when required to understand a change.

---

## Commit Grouping

Do not assume:

```text
1 commit = 1 work item
```

Group related commits into meaningful logical tasks.

Example:

```text
feat: add auth middleware
fix: auth cookie
fix: login redirect
refactor: auth helpers
```

may become:

```text
Implemented shared authentication flow
```

---

## Work Item Format

Each meaningful recap entry should include:

```md
## YYYY-MM-DD

### Work Title

Type:
Status:

What changed:

Why:

Important files:

Commits:

Impact:

Junior notes:
```

Possible types:

```text
Feature
Fix
Refactor
Infrastructure
Testing
Documentation
Security
Performance
```

Do not invent reasons that cannot reasonably be inferred from code, commit messages, tests, or documentation.

---

## Current Point

`recap.md` must contain:

```md
## Current Point
```

This section should explain where development currently stands and what a future agent should consider as the starting point.

Example:

```md
## Current Point

Shared session authentication has been implemented and tested locally.

The next known work is production cross-domain session verification.

Future recap runs should inspect commits after `abc1234`.
```

---

## Validation

`validate-checkpoint.sh` should:

- receive a commit hash
- verify that it resolves to a valid commit
- return non-zero if invalid

Example:

```bash
git cat-file -e "${COMMIT}^{commit}"
```

`validate-recap.sh` should confirm:

- `recap.md` exists
- `# Project Recap` exists
- `## Current Point` exists
- exactly one active `recap-state` block exists
- `last_commit` is populated
- checkpoint exists in Git where possible

The skill must preserve historical recap entries.

Never overwrite old recap content merely because a new run occurs.

---

# 8. Skill: `to-backlog`

## Purpose

Create and maintain:

```text
docs/backlog.md
```

The file represents meaningful unfinished project work.

Potential sources include:

- current conversation/context
- `docs/overview.md`
- `docs/recap.md`
- code TODO/FIXME comments
- current Git working tree
- incomplete implementations
- tests indicating unfinished behavior
- documented follow-up work

---

## Backlog Philosophy

Do not turn every code comment into a backlog item.

Example:

```js
// TODO rename variable
```

should usually not become:

```text
BL-024 Rename variable
```

unless it represents meaningful work.

A backlog item should generally be work another developer could reasonably pick up.

---

## Stable IDs

Use stable IDs:

```text
BL-001
BL-002
BL-003
```

Never renumber existing IDs.

Determine the next ID based on the highest existing backlog ID.

---

## Statuses

Only use:

```text
Todo
In Progress
Blocked
Needs Review
Done
```

---

## Priorities

Only use:

```text
High
Medium
Low
```

Avoid unnecessary project-management complexity.

---

## Backlog Item Format

Use:

```md
### BL-001 Task title

Status: Todo
Priority: High

Context:

Why:

Tasks:
- [ ] ...
- [ ] ...

Related files:

Related recap:

Dependencies:

Blockers:
```

Only include fields that are relevant.

---

## Shell Script: `find-todos.sh`

Search source files for:

```text
TODO
FIXME
HACK
XXX
WIP
```

Exclude generated/vendor directories.

Prefer `rg` when available and `grep` as fallback.

Output discovered items as candidates.

The agent determines whether they deserve backlog entries.

---

## Shell Script: `working-tree.sh`

Collect:

```bash
git status --short
git diff --stat
git diff --name-only
```

This can help detect unfinished local work.

Do not assume every modified file represents backlog work.

---

## Validation

`validate-backlog.sh` should confirm:

- `backlog.md` exists
- backlog IDs follow `BL-[0-9]+`
-Continuing the same implementation spec:

- backlog IDs are unique
- statuses use only the allowed values
- priorities use only the allowed values
- task IDs are never renumbered
- Markdown structure remains valid

If duplicate IDs are detected, validation must fail.

Example logic:

```bash
IDS="$(
  grep -oE 'BL-[0-9]+' docs/backlog.md |
  sort
)"

DUPLICATES="$(
  printf '%s\n' "$IDS" |
  uniq -d
)"

if [[ -n "$DUPLICATES" ]]; then
  echo "Duplicate backlog IDs detected:"
  echo "$DUPLICATES"
  exit 1
fi
```

The validator should also detect invalid status values.

---

# 9. Skill Interaction

The three skills should know about each other's generated files, but they must remain independently usable.

Relationship:

```text
to-catchup
    ↓
docs/overview.md
    ↓
provides architecture context

to-recap
    ↓
docs/recap.md
    ↓
provides development history

to-backlog
    ↓
docs/backlog.md
    ↓
provides unfinished work
```

`to-catchup` may read:

```text
docs/recap.md
docs/backlog.md
```

if they already exist, but they should not be required.

`to-recap` may read:

```text
docs/overview.md
docs/backlog.md
```

to improve context.

`to-backlog` should preferably read:

```text
docs/overview.md
docs/recap.md
```

when available.

However:

```text
to-catchup
to-recap
to-backlog
```

must each work when installed alone.

Do not create hard dependencies between skill directories.

---

# 10. `AGENTS.md`

Create a small root-level `AGENTS.md` explaining skill discovery.

Example:

```md
# Agent Instructions

Reusable development workflows are available under:

`skills/`

Available skills:

## to-catchup

Use when a developer needs to quickly understand an unfamiliar codebase.

Read:

`skills/to-catchup/SKILL.md`

Output:

`docs/overview.md`

## to-recap

Use when a developer needs to understand recent implementation work,
fixes, refactors, Git history, or where previous development stopped.

Read:

`skills/to-recap/SKILL.md`

Output:

`docs/recap.md`

## to-backlog

Use when unfinished work, follow-ups, blockers, TODOs, or future work
need to be tracked.

Read:

`skills/to-backlog/SKILL.md`

Output:

`docs/backlog.md`
```

Keep this file concise.

Do not duplicate complete skill instructions inside `AGENTS.md`.

---

# 11. SKILL.md Requirements

Each skill must include YAML frontmatter.

Example:

```yaml
---
name: to-recap
description: >
  Analyze recent Git history and maintain a concise chronological project
  recap. Use when a developer needs to understand recently completed work,
  fixes, refactors, architecture changes, or where previous development
  stopped.
---
```

The description must clearly communicate when the skill should be used.

Avoid vague descriptions such as:

```yaml
description: Recap the project.
```

Each `SKILL.md` should contain:

```text
Purpose
When to Use
Inputs
Workflow
Shell Helpers
Output
Validation
Rules
Failure Handling
```

Do not make the file unnecessarily verbose.

The goal is to give the agent enough structure to behave consistently.

---

# 12. Shell Output Design

Shell scripts should prefer structured, predictable output.

Avoid noisy prose.

Good:

```text
REPO_ROOT=/home/user/project
BRANCH=feat/auth
HEAD=abc123
DIRTY_FILES=3
```

Or:

```text
## Branch
feat/auth

## HEAD
abc123

## Working Tree
M src/auth.ts
M src/session.ts
```

For lists, prefer simple line-based formats.

Example:

```text
abc123|2026-10-12|John Doe|feat: add shared session
def456|2026-10-11|John Doe|fix: expired session handling
```

Do not make shell scripts generate human-facing recap prose.

---

# 13. Context Efficiency

The skills should minimize unnecessary context usage.

Do not automatically send:

- entire repository trees
- entire Git history
- huge diffs
- generated code
- vendor dependencies
- lockfiles
- build outputs

Use a staged exploration strategy.

Example for `to-catchup`:

```text
1. inspect repository structure
2. detect stack
3. inspect manifests
4. locate entrypoints
5. identify major modules
6. inspect only files needed to understand flow
```

Example for `to-recap`:

```text
1. locate checkpoint
2. list commits after checkpoint
3. group likely related commits
4. inspect changed-file summaries
5. inspect detailed diffs only when needed
```

Example for `to-backlog`:

```text
1. read existing backlog
2. read recap current point
3. scan TODO candidates
4. inspect working tree
5. inspect relevant incomplete implementation
6. decide which items deserve backlog entries
```

The agent should progressively gather more information instead of loading everything upfront.

---

# 14. Large Repository Handling

All skills must work reasonably on large repositories.

For directory scans:

- use depth limits initially
- ignore common generated directories
- inspect specific modules only after initial discovery

For Git:

- avoid unbounded `git log`
- use checkpoint ranges
- use recent-history limits when no checkpoint exists

For TODO search:

- ignore binary files
- ignore dependencies
- ignore generated directories

For diffs:

- inspect stats first
- inspect specific files only when necessary

---

# 15. Monorepo Support

The skills should handle monorepos without assuming a single application.

Detect common workspace structures such as:

```text
apps/
packages/
services/
libs/
crates/
cmd/
internal/
```

When a monorepo is detected, describe its relevant structure in `docs/overview.md` under `## Project Tree`:

```text
repository purpose
workspace/package layout
major applications/services
shared packages
relationships between components
```

Example:

```md
## Project Tree

### apps/web

Main customer-facing frontend.

### apps/admin

Internal administration frontend.

### services/auth

Authentication service.

### packages/ui

Shared React component library.
```

Do not deeply inspect every package unless necessary.

Prioritize application entrypoints and shared infrastructure.

---

# 16. Git Edge Cases

`to-recap` must handle the following gracefully.

## No Git repository

If no Git repository is available:

- do not crash
- report that recap cannot use Git history
- use existing `recap.md` only if appropriate
- do not invent commit history

## Empty repository

If no commits exist:

- create a valid empty recap structure if requested
- state that no committed work exists yet
- do not create a fake checkpoint

## Detached HEAD

Detect detached HEAD and record it accurately.

Do not assume a branch name exists.

## Shallow clone

Detect shallow repositories when possible:

```bash
git rev-parse --is-shallow-repository
```

If history may be incomplete, communicate this limitation to the agent.

## Rebase / rewritten history

If the previous checkpoint does not resolve:

- mark checkpoint as stale
- use recap content and recent Git history to recover
- avoid deleting historical recap entries
- establish a new checkpoint only after analysis

---

# 17. Existing Output Files

Generated files may already exist.

The agent must preserve useful human-written content when reasonable.

## `docs/overview.md`

This file may be refreshed because architecture can evolve, but existing edits must pass the output fingerprint check (or be a clean, tracked legacy file) before writing. Retain useful project-specific warnings in Important Notes; fit any useful older content into the exact ordered major headings rather than adding incompatible sections.

## `docs/recap.md`

Treat historical entries as append-only.

Do not rewrite or reorder previous history unless correcting an obvious structural issue.

## `docs/backlog.md`

May be updated actively.

Allowed changes:

- change status
- add new items
- mark work Done
- update blockers
- update task checkboxes
- add context

Do not delete completed items just because they are finished.

Keep them under a `Done` section where practical.

---

# 18. Idempotency

Running a skill twice without repository changes should produce little or no change.

Examples:

Running:

```text
to-recap
```

twice with the same HEAD should not duplicate recap entries.

Running:

```text
to-backlog
```

twice should not create duplicate backlog tasks.

Running:

```text
to-catchup
```

twice should not randomly rewrite terminology or reorder sections without meaningful repository changes.

Stable output is preferred.

---

# 19. Failure Handling

Shell scripts must:

- print useful error messages to stderr
- return non-zero on actual validation failures
- avoid partial destructive behavior

Agent instructions must explain what to do if a script fails.

Example:

```text
If detect-stack.sh fails:
- continue using repository manifests directly
- do not stop the entire skill unless stack detection is essential
```

For validation failures:

```text
agent writes file
    ↓
validator runs
    ↓
validator fails
    ↓
agent inspects failure
    ↓
agent corrects generated file
    ↓
validator runs again
```

Validation scripts must not rewrite files themselves.

---

# 20. Testing

Create:

```text
tests/test-scripts.sh
```

Test important shell behavior.

At minimum test:

## Shared utilities

- detects Git repository
- gets repository root
- gets current HEAD
- handles non-Git directory

## `to-catchup`

- detects Node project
- detects Rust project
- detects Go project
- ignores `node_modules`
- ignores build output
- finds likely entrypoints

## `to-recap`

- collects commits
- handles checkpoint range
- detects invalid checkpoint
- handles no previous checkpoint
- validates a correct recap
- rejects recap without Current Point

## `to-backlog`

- finds TODO candidates
- ignores dependency folders
- detects duplicate IDs
- accepts valid statuses
- rejects invalid statuses

---

# 21. Test Fixtures

Use small generated repositories under:

```text
tests/fixtures/
```

Avoid storing large real projects.

Suggested fixtures:

```text
node-app/
rust-app/
go-app/
monorepo/
empty-git-repo/
```

Tests may initialize temporary Git repositories as needed.

Do not rely on network access.

---

# 22. Shell Coding Quality

Follow these conventions:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Quote variables:

```bash
"$FILE"
"$REPO_ROOT"
```

Not:

```bash
$FILE
$REPO_ROOT
```

Prefer:

```bash
while IFS= read -r line; do
  ...
done
```

over unsafe word splitting.

Use temporary files safely if needed:

```bash
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
```

Avoid unnecessarily complex shell logic.

The scripts should remain easy for junior developers to read.

---

# 23. Documentation

Create a root `README.md`.

It should include:

## Project purpose

Explain that these are portable coding-agent skills designed to help junior developers understand and continue existing projects.

## Skills

Explain:

```text
to-catchup → docs/overview.md
to-recap   → docs/recap.md
to-backlog → docs/backlog.md
```

## Installation

Document installation using a generic skill installer if supported.

Example:

```bash
npx skills add <owner>/<repository>
```

Also document manual installation.

## Usage

Examples:

```text
Run to-catchup.

Use to-recap to summarize everything implemented since the previous checkpoint.

Update the project backlog using to-backlog.
```

## Requirements

Document:

```text
Git
Bash
standard Unix utilities
```

and optional tools:

```text
ripgrep
jq
fd
```

## Supported environments

Document expected compatibility:

```text
Linux
macOS
WSL
AI coding-agent containers
```

---

# 24. License

Use the MIT License unless an existing repository license should be preserved.

Create:

```text
LICENSE
```

---

# 25. CHANGELOG

Create:

```text
CHANGELOG.md
```

Initial version:

```md
# Changelog

## 0.1.0

Initial release.

### Added

- `to-catchup`
- `to-recap`
- `to-backlog`
- repository inspection shell helpers
- Markdown templates
- output validation
```

---

# 26. Skill-Specific Acceptance Criteria

## `to-catchup`

Consider complete when:

- [ ] `SKILL.md` exists
- [ ] project scanning works
- [ ] stack detection works
- [ ] entrypoint candidate detection works
- [ ] generated `docs/overview.md` follows the one ordered template, with optional confirmed HTTP endpoints
- [ ] output focuses on system flow
- [ ] noisy directories are excluded
- [ ] validator verifies required structure
- [ ] secrets are not intentionally exposed

---

## `to-recap`

Consider complete when:

- [ ] `SKILL.md` exists
- [ ] Git context collector works
- [ ] previous checkpoint can be read
- [ ] only newer commits are inspected during incremental runs
- [ ] related commits can be grouped by the agent
- [ ] recap entries include dates
- [ ] `Current Point` is mandatory
- [ ] checkpoint is updated
- [ ] repeated runs do not duplicate work
- [ ] stale checkpoint handling is documented
- [ ] validation works

---

## `to-backlog`

Consider complete when:

- [ ] `SKILL.md` exists
- [ ] TODO candidate scanning works
- [ ] working-tree inspection works
- [ ] stable `BL-*` IDs are defined
- [ ] allowed statuses are enforced
- [ ] allowed priorities are enforced
- [ ] duplicate IDs fail validation
- [ ] insignificant TODO comments are not automatically promoted
- [ ] existing backlog entries are preserved
- [ ] completed items can move to Done
- [ ] repeated runs do not duplicate tasks

---

# 27. Overall Acceptance Criteria

The implementation is complete when this workflow works:

```text
fresh repository
    ↓
run to-catchup
    ↓
docs/overview.md created
    ↓
developer makes several commits
    ↓
run to-recap
    ↓
docs/recap.md created with checkpoint
    ↓
developer makes more commits
    ↓
run to-recap again
    ↓
only new work appended
    ↓
run to-backlog
    ↓
docs/backlog.md created from meaningful remaining work
```

A future developer should then be able to enter the project and understand:

```text
docs/overview.md
→ how the project works

docs/recap.md
→ what happened

docs/backlog.md
→ what remains
```

---

# 28. Desired Developer Experience

The final experience should be as simple as:

```text
> Run to-catchup
```

Agent:

```text
Explores repository
→ runs deterministic helper scripts
→ inspects important source files
→ creates docs/overview.md
→ validates docs/overview.md
```

Then:

```text
> Run to-recap
```

Agent:

```text
Reads recap checkpoint
→ gathers new Git history
→ investigates relevant changes
→ appends docs/recap.md
→ records Current Point
→ validates checkpoint
```

Then:

```text
> Run to-backlog
```

Agent:

```text
Reads existing project memory
→ scans unfinished-work candidates
→ inspects repository state
→ determines meaningful remaining work
→ updates docs/backlog.md
→ validates IDs/statuses
```

The user should not have to know or manually run the underlying shell commands.

---

# 29. Important Implementation Principle

Do not build these skills as large prompts that simply tell the model to "inspect everything."

Build them as small engineering workflows:

```text
SKILL.md
    │
    ├── decides what should happen
    │
    ▼
shell helpers
    │
    ├── collect deterministic facts
    │
    ▼
AI reasoning
    │
    ├── understands meaning and relationships
    │
    ▼
Markdown output
    │
    ▼
validator
```

The shell layer should reduce model guesswork.

The agent layer should reduce shell complexity.

Neither should attempt to completely replace the other.

---

# 30. Implementation Order

Implement in this order.

## Phase 1 — Foundation

1. Create repository structure.
2. Add `common.sh`.
3. Add README, AGENTS.md, LICENSE, CHANGELOG.
4. Add reference templates.

## Phase 2 — `to-catchup`

1. Implement `scan-project.sh`.
2. Implement `detect-stack.sh`.
3. Implement `find-entrypoints.sh`.
4. Implement `validate-overview.sh`.
5. Write `SKILL.md`.
6. Add tests.

## Phase 3 — `to-recap`

1. Implement Git context collection.
2. Implement changed-file inspection.
3. Implement checkpoint validation.
4. Implement recap validation.
5. Write incremental recap workflow.
6. Add tests for initial and subsequent runs.

## Phase 4 — `to-backlog`

1. Implement TODO scanner.
2. Implement working-tree scanner.
3. Implement backlog validator.
4. Write backlog workflow.
5. Add duplicate-prevention logic to instructions.
6. Add tests.

## Phase 5 — Integration

Test all three skills against:

```text
small frontend repository
backend repository
mixed/monorepo repository
```

Verify that generated files remain concise and useful for a junior developer.

---

# 31. Do Not Overengineer v1

Do not add unless genuinely required:

```text
database
web server
API
Node.js runtime dependency
Python runtime dependency
custom package manager
vector database
embeddings
background daemon
complex configuration system
```

This project should primarily consist of:

```text
Markdown
Shell
Git
```

Keep the first version easy to inspect, fork, install, and modify.

---

# Final Objective

Build three small, portable AI coding-agent skills that provide lightweight project memory:

```text
to-catchup
    ↓
"How does this project work?"

to-recap
    ↓
"What has happened?"

to-backlog
    ↓
"What remains?"
```

The result should be especially useful for junior developers joining an existing project, switching branches, resuming work after time away, or taking over work from another developer.

Optimize for:

```text
conciseness
reliability
portability
incremental updates
low context usage
junior-friendly explanations
safe repository inspection
```

Do not optimize for maximum documentation volume.

The best result is the smallest amount of accurate project context needed for a developer to confidently continue working.
