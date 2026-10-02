# Project Memory Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish three independently installable skills that maintain `docs/overview.md`, `docs/recap.md`, and `docs/backlog.md` in a target project.

**Architecture:** Each skill is a self-contained `skills/<name>/SKILL.md` with a local reference template. Skills share a project-memory convention but never require or modify another skill's owned file. The repository contains only Markdown documentation, examples, and an MIT license; no runtime package or custom installer.

**Tech Stack:** Markdown, YAML frontmatter, Git command guidance, `npx skills add` installation.

**Spec:** `docs/superpowers/specs/2026-10-02-project-memory-skills-design.md`

## Global Constraints

- Generated files are always under the target project's `docs/` directory.
- Each skill creates `docs/` when absent and preserves unrelated documentation.
- Each skill is independently installable and operational without the other two.
- `to-catchup` owns `docs/overview.md`; `to-recap` owns `docs/recap.md`; `to-backlog` owns `docs/backlog.md`.
- Skills must not expose secrets from environment or configuration files.
- `to-recap` preserves prior entries and uses a machine-readable checkpoint.
- `to-backlog` uses stable `BL-###` IDs and only the five specified statuses.
- Verification must distinguish observed command/CI results from claims or assumptions.

---

### Task 1: Build `to-catchup`

**Files:**
- Create: `skills/to-catchup/SKILL.md`
- Create: `skills/to-catchup/references/overview-template.md`

**Interfaces:**
- Consumes: target repository files and optional `docs/recap.md` / `docs/backlog.md` context.
- Produces: `docs/overview.md` with architecture, flow, important modules/files, configuration, development workflow, reading order, and cautions.

- [ ] **Step 1: Run the RED pressure scenario before writing the skill.**

  Give a fresh agent this request without the skill: “A new developer starts in this repository. Explore it and create an overview.” Record whether it lists files without explaining flows, omits configuration/tests/deployment, writes outside `docs/`, or copies secrets.

- [ ] **Step 2: Write `overview-template.md`.**

  Include sections for purpose, stack, architecture, application flow, important modules, important files, data flow, external dependencies, environment/configuration, development workflow, recommended reading order, and cautions. State that secret values must never be copied.

- [ ] **Step 3: Write `SKILL.md` frontmatter and discovery description.**

  Use `name: to-catchup` and a description beginning with `Use when...` that mentions unfamiliar repositories, onboarding, architecture, application flow, and `overview.md`.

- [ ] **Step 4: Write the minimal workflow.**

  Require creating `docs/` when absent, inspecting the listed repository areas, explaining flows before file inventories, using the local template, preserving unrelated docs, and marking unknowns instead of guessing.

- [ ] **Step 5: Run the GREEN pressure scenario.**

  Repeat the RED request with the skill loaded. Confirm the response writes only `docs/overview.md`, explains system flow, covers the required inspection areas, and explicitly avoids secret values and unsupported claims.

- [ ] **Step 6: Commit the skill.**

  ```bash
  git add skills/to-catchup
  git commit -m "feat: add repository catchup skill"
  ```

### Task 2: Build `to-recap`

**Files:**
- Create: `skills/to-recap/SKILL.md`
- Create: `skills/to-recap/references/recap-template.md`

**Interfaces:**
- Consumes: Git history, diffs, current repository state, and optional `docs/overview.md` / `docs/backlog.md` context.
- Produces: append-only `docs/recap.md` with `Current Point` and a `recap-state` checkpoint containing `last_commit` and `last_updated`.

- [ ] **Step 1: Run the RED pressure scenario before writing the skill.**

  Give a fresh agent this request without the skill: “Update the project recap from the last checkpoint.” Record whether it rereads all history, writes a root-level file, maps every commit to a separate item, rewrites old entries, or claims tests passed without evidence.

- [ ] **Step 2: Write `recap-template.md`.**

  Define the header, dated work entries, categories, status, what/why, important files, commits, impact, junior notes, `Current Point`, and the exact HTML checkpoint shape:

  ```md
  <!-- recap-state
  last_commit: <full-or-short-commit>
  last_updated: YYYY-MM-DD
  -->
  ```

- [ ] **Step 3: Write `SKILL.md` frontmatter and discovery description.**

  Use `name: to-recap` and a description beginning with `Use when...` that mentions Git history, checkpoints, completed work, fixes, refactors, and `docs/recap.md`.

- [ ] **Step 4: Write the incremental workflow.**

  Require creating `docs/`, reading the checkpoint, analyzing only descendants after it, handling merges/rebases carefully, grouping related commits, appending rather than rewriting, updating `Current Point`, recording the new HEAD, and separating committed from uncommitted work.

- [ ] **Step 5: Run the GREEN pressure scenario.**

  Repeat the RED request with the skill loaded. Confirm that the response uses `docs/recap.md`, preserves old entries, groups related commits, updates the checkpoint, and labels unknown verification rather than inventing it.

- [ ] **Step 6: Commit the skill.**

  ```bash
  git add skills/to-recap
  git commit -m "feat: add incremental project recap skill"
  ```

### Task 3: Build `to-backlog`

**Files:**
- Create: `skills/to-backlog/SKILL.md`
- Create: `skills/to-backlog/references/backlog-template.md`

**Interfaces:**
- Consumes: current context, implementation gaps, meaningful TODO/FIXME comments, Git state, and optional `docs/overview.md` / `docs/recap.md` context.
- Produces: `docs/backlog.md` with stable `BL-###` items, statuses, priorities, tasks, dependencies, related files, blockers, and completion records.

- [ ] **Step 1: Run the RED pressure scenario before writing the skill.**

  Give a fresh agent this request without the skill: “Create a backlog from this repository.” Record whether it turns every TODO into work, invents requirements, renumbers existing IDs, overwrites completed items, or writes outside `docs/`.

- [ ] **Step 2: Write `backlog-template.md`.**

  Define sections for `In Progress`, `Todo`, `Blocked`, `Needs Review`, and `Done`. Define stable IDs, `Status`, `Priority`, `Context`, `Tasks`, `Related`, `Files`, `Depends on`, `Blocked by`, and completion fields.

- [ ] **Step 3: Write `SKILL.md` frontmatter and discovery description.**

  Use `name: to-backlog` and a description beginning with `Use when...` that mentions unfinished work, TODOs, blockers, priorities, stable backlog IDs, and `docs/backlog.md`.

- [ ] **Step 4: Write the conservative backlog workflow.**

  Require creating `docs/`, preserving existing items, using only the five statuses and three priorities, creating items only for pick-up-worthy work, assigning never-reused IDs, and requiring evidence for updates.

- [ ] **Step 5: Run the GREEN pressure scenario.**

  Repeat the RED request with the skill loaded. Confirm that the response writes `docs/backlog.md`, filters trivial TODOs, preserves IDs, avoids invented requirements, and records blockers explicitly.

- [ ] **Step 6: Commit the skill.**

  ```bash
  git add skills/to-backlog
  git commit -m "feat: add project backlog skill"
  ```

### Task 4: Add Repository Documentation and Examples

**Files:**
- Create or modify: `README.md`
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `examples/overview.md`
- Create: `examples/recap.md`
- Create: `examples/backlog.md`

**Interfaces:**
- Consumes: the three skill names, output contracts, and actual GitHub repository URL.
- Produces: installation, manual-copy, independence, output-path, license, and versioning documentation plus clearly fictional examples.

- [ ] **Step 1: Write README installation and usage.**

  Document all-skills and single-skill commands using `narinsak-u/my-personal-agent-skills`, manual installation fallback, the three `docs/` outputs, optional cross-skill context, and the no-secret rule.

- [ ] **Step 2: Write the MIT license.**

  Use the standard MIT text with copyright holder `narinsak-u` and year `2026`.

- [ ] **Step 3: Write the changelog.**

  Add a `0.1.0` entry describing the initial `to-catchup`, `to-recap`, and `to-backlog` skills and their `docs/` outputs.

- [ ] **Step 4: Write representative fictional examples.**

  Use a clearly labeled fictional project and make each example match its local template without exposing credentials or claiming real repository history.

- [ ] **Step 5: Commit repository documentation.**

  ```bash
  git add README.md LICENSE CHANGELOG.md examples
  git commit -m "docs: document and exemplify project memory skills"
  ```

### Task 5: Verify the Published Skill Set

**Files:**
- Inspect: `skills/*/SKILL.md`
- Inspect: `skills/*/references/*`
- Inspect: `README.md`, `LICENSE`, `CHANGELOG.md`, `examples/*`

- [ ] **Step 1: Verify file layout.**

  Run:

  ```bash
  test -f skills/to-catchup/SKILL.md
  test -f skills/to-catchup/references/overview-template.md
  test -f skills/to-recap/SKILL.md
  test -f skills/to-recap/references/recap-template.md
  test -f skills/to-backlog/SKILL.md
  test -f skills/to-backlog/references/backlog-template.md
  test ! -d agents
  ```

  Expected: every command succeeds.

- [ ] **Step 2: Verify metadata and isolation.**

  Check each `SKILL.md` has exactly one valid `name` and `description` frontmatter pair, a `Use when...` description, its own output path under `docs/`, and no references to another skill's internal files.

- [ ] **Step 3: Verify output contracts.**

  Check templates and skill instructions agree on `docs/overview.md`, `docs/recap.md`, `docs/backlog.md`, checkpoint syntax, status values, priority values, stable IDs, and secret handling.

- [ ] **Step 4: Verify README commands.**

  Confirm the documented repository URL is `narinsak-u/my-personal-agent-skills`, skill names match directory names, and both all-skills and single-skill install commands are present.

- [ ] **Step 5: Review the final tree and change set.**

  Run:

  ```bash
  find skills examples -maxdepth 3 -type f | sort
  git status --short
  ```

  Confirm there are no obsolete agents, root-level generated project-memory files, or untracked files outside the intended deliverables.
