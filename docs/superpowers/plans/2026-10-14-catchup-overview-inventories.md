# Catchup Overview Inventories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the `subagent-driven-development` skill or the `executing-plans` skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `to-catchup` produce a readable overview with evidence-backed tech stack, a complete verified workflow inventory, and a correctly counted HTTP endpoint table when the repository is an HTTP backend.

**Architecture:** Keep the existing skill, Markdown template, and `validate-overview.sh` CLI seam. The skill guides manual evidence tracing; the validator requires the new Tech Stack section but does not try to parse application routes. No generic route parser or additional helper is introduced.

**Tech Stack:** Markdown skill/template, Bash validator and fixture suite; no runtime dependencies added.

**Spec:** Conversation-approved design, captured below under “Global Constraints”; there is no separate spec file for this bounded skill change.

## Global Constraints

- Tech Stack lists active, evidence-backed languages/runtimes, major frameworks, data stores, and queues; versions appear only when directly evidenced; omit transitive dependencies.
- Inventory every verified first-class application workflow, including important background/admin workflows; state the identified count and whether inventory is complete; give every workflow a name and one-line purpose.
- Show the three most user-facing/high-risk workflows as vertical plain-text diagrams; keep remaining diagrams collapsed rather than omitting workflow names.
- For HTTP backends, manually trace route registrations and mounted prefixes; each distinct registered HTTP method + route-template pair counts once. Include method, path, purpose, and access when verified; show the count.
- Count explicit HTTP routes, including health/internal routes with verified access labels. Exclude implicit HEAD/OPTIONS, GraphQL/gRPC operations, and entrypoint candidates. Cross-check checked-in OpenAPI against implementation.
- If route or workflow completeness cannot be proven, say Partial/Needs verification and count confirmed entries only. Never present candidates as verified behavior.
- Keep the overview about one page where complexity permits; keep the endpoint count visible and collapse a large endpoint table or additional workflow diagrams rather than silently dropping inventory rows.
- Preserve current overview ownership, secret-safety, fingerprint, and output-only rules.

---

## File Map

- `tests/test-catchup.sh` owns the fixture-based behavior checks for the existing overview validator and helper CLI seam.
- `skills/to-catchup/scripts/validate-overview.sh` enforces required overview headings and existing safety/fingerprint rules.
- `skills/to-catchup/SKILL.md` owns the evidence-gathering and output instructions.
- `skills/to-catchup/references/overview-template.md` owns the output headings and concise section shape.
- `GLOSSARY.md` owns repository terminology.
- `examples/overview.md` is the explicit fictional example of a completed catchup output.
- `CHANGELOG.md` records the user-visible skill change.
- User-local `docs/test/` artifacts are not present in this `origin/main` worktree and are not copied into the feature branch; `examples/overview.md` is the maintained fictional sample.

## Tasks

### Task 1: Add a failing required-Tech-Stack contract test

**Files:**
- Modify: `tests/test-catchup.sh`
- Test: `bash tests/test-catchup.sh`

**Interfaces:**
- Consumes: existing `validate-overview.sh` CLI, called with the overview path as its only argument.
- Produces: a test proving a valid overview is accepted and an overview missing `## Tech Stack` is rejected.

- [x] **Step 1: Update the valid fixture documents.** Add `## Tech Stack` to both existing overviews; add an `## API Endpoints` section and minimal table (`GET | /health | Liveness | Public`) to the first backend overview; update its section-count assertion from five to seven. Keep the second data-migration fixture intact. Add and validate a third client-only overview with `## Tech Stack` but no endpoint section.
- [x] **Step 2: Add a missing-Tech-Stack rejection case.** Copy a valid fixture, remove exactly its heading, and assert validator rejection without modifying the candidate:

```bash
cp "$fixture/my project/docs/overview.md" "$fixture/missing-tech-stack.md"
grep -Fv '## Tech Stack' "$fixture/missing-tech-stack.md" > "$fixture/missing-tech-stack.tmp"
mv "$fixture/missing-tech-stack.tmp" "$fixture/missing-tech-stack.md"
reject_file 'missing Tech Stack section' "$fixture/missing-tech-stack.md" ''
```

- [x] **Step 3: Run `bash tests/test-catchup.sh` and confirm RED.** Expected: it fails with `Validator accepted an overview missing Tech Stack`; current validator does not require the new heading.

### Task 2: Require Tech Stack at the existing CLI seam

**Files:**
- Modify: `skills/to-catchup/scripts/validate-overview.sh`
- Test: `tests/test-catchup.sh`

**Interfaces:**
- Consumes: overview Markdown passed to the existing validator CLI.
- Produces: validator requires `## Tech Stack`; it continues to accept overviews without an HTTP endpoint section.

- [x] **Step 1: Add `## Tech Stack` to the validator’s required heading list.** The existing heading loop should include:

```bash
for heading in '# Project Overview' '## Purpose' '## Tech Stack' '## Project Tree' '## Workflow' '## Scripts' '## Important Notes'; do
```

Preserve the existing heading checks and safety/fingerprint validation. Do not add route parsing or make `## API Endpoints` mandatory.
- [x] **Step 2: Run `bash tests/test-catchup.sh`.** Expected: PASS, including valid client-only overview and rejection of missing Tech Stack.

### Task 3: Update glossary, template, and skill rules

**Files:**
- Modify: `GLOSSARY.md`
- Modify: `skills/to-catchup/references/overview-template.md`
- Modify: `skills/to-catchup/SKILL.md`

**Interfaces:**
- Consumes: confirmed output contract in Global Constraints.
- Produces: consistent terminology and instructions; no new executable API.

- [x] **Step 1: Add glossary entries.** Define `Technology stack` as major languages/runtimes, frameworks, data stores, and queues evidenced as actively used; `Application workflow` as an end-to-end runtime path from trigger to outcome with meaningful checks/side effects; and `API endpoint` as one registered HTTP method + route path, with distinct method/path pairs counted separately.
- [x] **Step 2: Reorder the template to the concise output contract:** Purpose, Tech Stack, Project Tree, Workflow, optional API Endpoints, Scripts, Important Notes. State the evidence/completeness rule in each relevant section.
- [x] **Step 3: Update workflow instructions.** Require inventorying all verified first-class workflows (including important background/admin paths), naming/counting all of them, placing one-line purposes next to names, showing up to three most user-facing/high-risk diagrams vertically, and collapsing additional diagrams in `<details>`.
- [x] **Step 4: Add HTTP endpoint discovery rules.** Manually follow router registrations and mounted prefixes; use OpenAPI only after implementation cross-check; count unique explicit method + route-template pairs; include verified access class; exclude implicit HEAD/OPTIONS, GraphQL/gRPC operations, and entrypoint candidates. Mark Partial/Needs verification and state the confirmed count when completeness is not provable. Keep the count visible and collapse a long table when it would exceed about one page.
- [x] **Step 5: Preserve existing constraints.** Keep ownership fingerprints, secret safety, only-write-`docs/overview.md`, helper use, and existing purpose/tree/scripts/important-notes rules unchanged except where the new headings require an update.
- [x] **Step 6: Review both updated files against Global Constraints.** Every constraint must map to explicit guidance; no duplicate inventory sections or second route-discovery mechanism.

### Task 4: Replace the fictional example with the new output shape

**Files:**
- Modify: `examples/overview.md`
- Test: `bash skills/to-catchup/scripts/validate-overview.sh examples/overview.md`

**Interfaces:**
- Consumes: the template and skill rules from Task 3.
- Produces: one clearly fictional example that demonstrates all required output decisions without implying evidence about a real deployment.

- [x] **Step 1: Keep the fictional-example warning and use only the standard overview headings.** Remove repetitive architecture/data-flow/module/file-inventory sections.
- [x] **Step 2: Demonstrate Tech Stack with versions omitted unless directly evidenced.** Mark every stack statement fictional.
- [x] **Step 3: Demonstrate a complete fictional workflow inventory.** Use five named workflows: create and index a note, search notes, open a shared note, change note access, and retry a failed index refresh. Give each a one-line purpose; show vertical diagrams for create/index, change access, and failed-index retry; put search and shared-note diagrams in one collapsed `<details>` block. Keep the five-workflow count consistent.
- [x] **Step 4: Demonstrate a fictional HTTP endpoint table.** Show exactly seven unique method/path pairs: `GET /api/v1/notes`, `POST /api/v1/notes`, `GET /api/v1/notes/:noteId`, `PATCH /api/v1/notes/:noteId`, `POST /api/v1/notes/:noteId/shares`, `DELETE /api/v1/notes/:noteId/shares/:memberId`, and `GET /health`. Include purpose and clearly fictional access labels; state the count as seven; do not count implicit methods or duplicate a path-method pair.
- [x] **Step 5: Keep scripts concise and warn before the fictional migration command.** Preserve the explicit warning not to use example commands operationally.
- [x] **Step 6: Run the validator on the example.** Expected: PASS.

### Task 5: Record and verify the change

**Files:**
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: completed skill/template/example changes.
- Produces: concise Unreleased entry and demonstrated output behavior.

- [x] **Step 1: Add one Unreleased changelog bullet** describing stack evidence, complete workflow diagrams, and backend endpoint inventories.
- [x] **Step 2: Re-run the three baseline evaluation prompts** using the updated skill and fixture evidence. Confirm the Ledger API count is exactly 11 unique endpoints, all five workflows are named, the three selected workflows have vertical diagrams and remaining diagrams are collapsed; confirm the client output has no fabricated server endpoints/table and marks the external API implementation as unavailable.
- [x] **Step 3: Run `bash tests/test-scripts.sh` from the feature worktree.** Expected: all backlog, catchup, recap, and standalone-installation shell scenarios pass.
- [x] **Step 4: Run `bash skills/to-catchup/scripts/validate-overview.sh examples/overview.md`.** Expected: PASS.
- [x] **Step 5: Inspect the final change set** for unrelated edits, broken docs, stale duplicate sections, and mismatch between the fictional workflow/endpoint counts and their rows.

## Risks

- Endpoint totals can drift from table rows or mounted prefixes; evaluation checks exact method/path pairs and count consistency.
- Concision can cause silent omissions; the skill requires a visible inventory count and collapsed details.
- The shell validator can enforce headings, not prove source-derived completeness; evaluation checks the documented evidence discipline.
- The example is fictional and must remain explicitly labeled as such.
