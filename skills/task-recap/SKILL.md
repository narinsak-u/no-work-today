---
name: task-recap
description: Use when summarizing completed repository work across commits, branches, diffs, features, fixes, refactors, testing status, or release notes.
---

# Task Recap

Produce an evidence-based summary of development work. Connect repository evidence to user-visible outcomes without inventing intent, impact, test results, or next steps.

## Use When

- Daily, weekly, session, or milestone recap
- Commit, branch, pull request, or date-range summary
- Feature, bug-fix, refactor, documentation, or release-note summary
- Work grouped by subsystem, component, category, or affected files

If scope is missing, ask only for the missing period/branch, audience/format, or required highlights. Resolve “this week” from repository context when possible; otherwise state the timezone and date-boundary assumption.

## Workflow

1. **Define scope:** exact dates and timezone, repository/worktree, branch or commit range, paths/systems, and whether committed and working-tree changes are included.
2. **Inspect evidence:** HEAD, branch/remotes/worktrees, status, history, diffs, changed source/tests, CI configuration, and explicit TODOs or follow-ups.
3. **Classify changes:** feature, fix, refactor, documentation, test, generated artifact, formatting-only, or other.
4. **Explain impact:** claim behavior or user-facing effects only when supported by diffs or explicit repository context.
5. **Report verification:** distinguish observed command/CI results from claims in commits; mark skipped, not-run, or unknown checks.
6. **Choose the requested format:** put the highest-value facts first.

Never infer a feature from a commit title or changed-file presence alone. Never present uncommitted work as completed history.

## Required Detailed Shape

1. **Period and scope:** dates or commit range, timezone, branch/worktree, and inclusion rules.
2. **Completed work:** behavior-level entries with commit and file references when useful.
3. **Testing status:** command or CI evidence and result.
4. **Repository state and gaps:** uncommitted, ambiguous, generated, or incomplete work.
5. **Next steps:** only explicit TODOs, failing checks, incomplete changes, or stated follow-ups.

## Evidence Commands

Use the narrowest command that answers the request:

```bash
git log --oneline -n 20
git log --since="7 days ago" --oneline
git log main..HEAD --oneline
git log --oneline -- path/to/area/
```

For broad or ambiguous scopes, capture commit hashes, authors, dates, file statistics, current branch, divergence, staged/unstaged/untracked files, and relevant diff details. Separate merge, duplicate, generated, and formatting-only changes from substantive work.

## Format Reference

| Request | Organize by | Include |
| --- | --- | --- |
| Standup | Today/session | Completed work, blockers, next steps |
| Weekly recap | Date range | Features, fixes, refactors, verification |
| Commit summary | Commit/range | Intent, files, category, impact |
| Feature recap | Feature/subsystem | Behavior, files, user effect, testing |
| Release notes | Version/milestone | User-facing changes, fixes, verification |

Quick:

```text
Implemented account export and fixed empty date-range validation. Updated the export service, UI state, and tests; targeted tests pass.
```

Detailed:

```markdown
## Recent Work Summary
### Features
- **Account export:** Added CSV export to the account view.
### Fixes
- **Date validation:** Empty ranges now fail before submission.
### Verification
- Targeted export tests: passed
- Full suite: not run
```

## Common Mistakes

| Temptation | Correction |
| --- | --- |
| “This week” is obvious | State timezone and boundary. |
| Commit title explains the feature | Inspect the diff and behavior. |
| A test file proves tests passed | Find observed command or CI output. |
| User asks for a likely next step | Report only evidence-backed follow-ups. |
| Working-tree changes are completed | Separate them from committed history. |
| Generated files inflate feature count | Classify them separately. |

## Evidence Rules

- Separate observed facts, commit-author claims, and inferences.
- Use `verified`, `reported by commit`, `not run`, or `unknown`.
- Do not invent motivation, impact, coverage, performance changes, or roadmap items.
- If history or a path is unavailable, say exactly what could not be inspected.

Stop and re-check when the summary has no repository evidence, uses a broader scope than inspected, claims tests passed without output, or calls work merged/released without proof.
