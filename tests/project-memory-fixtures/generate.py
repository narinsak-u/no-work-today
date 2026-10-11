#!/usr/bin/env python3
"""Create disposable Git repositories for manual black-box skill tests."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import subprocess


def git(repo: Path, *args: str, env: dict[str, str] | None = None) -> str:
    return subprocess.run(["git", *args], cwd=repo, check=True, text=True,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env).stdout.strip()


def write(repo: Path, path: str, text: str) -> None:
    target = repo / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def init_repo(repo: Path, branch: str = "fixture-main") -> None:
    repo.mkdir(parents=True)
    git(repo, "init", "-q", "-b", branch)
    git(repo, "config", "user.name", "Fixture User")
    git(repo, "config", "user.email", "fixture@example.invalid")


def commit(repo: Path, message: str) -> None:
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", message, env={**os.environ, "GIT_AUTHOR_DATE": "2001-01-01T00:00:00Z", "GIT_COMMITTER_DATE": "2001-01-01T00:00:00Z"})


def seed_common_project_files(repo: Path) -> None:
    write(repo, "README.md", "# Fixture application\n\nA tiny service that accepts a name and returns a greeting.\n")
    write(repo, "src/app.py", 'def greet(name):\n    return f"hello, {name}"\n')
    write(repo, "pyproject.toml", '[project]\nname = "fixture-app"\nversion = "0.1.0"\n')
    write(repo, "tests/test_app.py", "def test_greeting():\n    assert True\n")


def seed_project(repo: Path) -> None:
    seed_common_project_files(repo)
    write(repo, "config/example.env", "APP_MODE=development\nAPI_TOKEN=fixture-secret-do-not-copy\n")
    write(repo, "notes/unrelated.txt", "Preserve this file byte-for-byte.\n")
    commit(repo, "Create small documented service")


def seed_project_nogit(repo: Path) -> None:
    seed_common_project_files(repo)


def seed_catchup(root: Path) -> None:
    for name in ("catchup-valid", "catchup-invalid", "catchup-legacy-tracked", "catchup-legacy-untracked", "catchup-legacy-modified", "catchup-legacy-nongit"):
        repo = root / name
        if name == "catchup-legacy-nongit":
            repo.mkdir(parents=True)
            seed_project_nogit(repo)
            write(repo, "docs/overview.md", "# Legacy overview\n\nKeep this unmarked content.\n")
            continue
        init_repo(repo)
        seed_project(repo)
        if name.startswith("catchup-legacy"):
            overview = "# Legacy overview\n\nA tiny service that accepts a name and returns a greeting.\n" if name == "catchup-legacy-tracked" else "# Legacy overview\n\nKeep this unmarked content.\n"
            write(repo, "docs/overview.md", overview)
            if name in ("catchup-legacy-tracked", "catchup-legacy-modified"):
                commit(repo, "Add legacy overview")
            if name == "catchup-legacy-modified":
                write(repo, "docs/overview.md", "# Legacy overview\n\nUser modification.\n")


def seed_backlog(root: Path) -> None:
    for name in ("backlog-valid", "backlog-invalid", "backlog-legacy-tracked", "backlog-legacy-untracked", "backlog-legacy-modified", "backlog-legacy-nongit"):
        repo = root / name
        init_repo(repo) if not name.endswith("nongit") else repo.mkdir(parents=True)
        seed_project(repo) if not name.endswith("nongit") else seed_project_nogit(repo)
        write(repo, "src/app.py", 'def greet(name):\n    return f"hello, {name}"\n\n# TODO: Reject empty names with a documented error.\n')
        if not name.endswith("nongit"):
            commit(repo, "Add concrete empty-name follow-up")
        if name == "backlog-valid":
            write(repo, "docs/backlog.md", legacy_backlog())
            commit(repo, "Seed clean tracked backlog with reserved Done ID")
        elif name.startswith("backlog-legacy"):
            write(repo, "docs/backlog.md", legacy_backlog())
            if name in ("backlog-legacy-tracked", "backlog-legacy-modified"):
                commit(repo, "Add legacy backlog")
            if name == "backlog-legacy-modified":
                with (repo / "docs/backlog.md").open("a", encoding="utf-8") as f:
                    f.write("\nUser edit to legacy backlog.\n")


def legacy_backlog() -> str:
    return """# Project Backlog

## In Progress

## Todo

## Blocked

## Needs Review

## Done

### BL-014 — Preserve this completed record

- **Status:** Done
- **Priority:** Low
- **Context:** Fixture record proving completed IDs remain reserved.
- **Tasks:**
  - [x] Keep the existing completion record.
- **Related:** None
- **Files:** None
- **Depends on:** None
- **Blocked by:** None
- **Completion:** Completed
  - **Completed on:** 2026-10-01
  - **Completion commit:** abcdef1
  - **Completion evidence:** Fixture verification.
  - **Completion notes:** Preserve this record exactly.
"""


def seed_recap(root: Path, control: Path) -> None:
    repo = root / "recap-large-history"
    init_repo(repo)
    write(repo, "README.md", "# History fixture\n\nEach commit records one numbered event.\n")
    commit(repo, "Add history fixture baseline")
    for index in range(1, 1105):
        with (repo / "README.md").open("a", encoding="utf-8") as f:
            f.write(f"\nHistory event {index:04d}.\n")
        commit(repo, f"Record history event {index:04d}")
    seed_legacy_recap(root, control, "recap-legacy-branch-match", "fixture-main")
    seed_legacy_recap(root, control, "recap-legacy-branch-mismatch", "fixture-old")
    seed_legacy_recap(root, control, "recap-legacy-branch-missing", "")
    seed_legacy_recap(root, control, "recap-legacy-branch-ambiguous", "fixture-main\n- **HEAD:** `fixture-old` on fixture-old")
    seed_legacy_recap(root, control, "recap-rewritten-checkpoint", "fixture-main", rewritten=True)

    seed_recap_ownership(root, control)
    seed_legacy_recap_nongit(root, control)


def seed_legacy_recap_nongit(root: Path, control: Path) -> None:
    repo = root / "recap-legacy-nongit"
    repo.mkdir(parents=True)
    content = "# Legacy recap\n\nPreserve these exact unmarked non-Git bytes.\n"
    write(repo, "docs/recap.md", content)
    (control / "recap-legacy-nongit.sha256").write_text(
        hashlib.sha256((repo / "docs/recap.md").read_bytes()).hexdigest() + "\n", encoding="ascii"
    )

def seed_recap_ownership(root: Path, control: Path) -> None:
    invalid = root / "recap-invalid"
    init_repo(invalid)
    write(invalid, "README.md", "# Invalid fingerprint ownership fixture\n")
    commit(invalid, "Create invalid fingerprint fixture")

    for name in ("recap-legacy-untracked", "recap-legacy-modified"):
        repo = root / name
        init_repo(repo)
        write(repo, "README.md", f"# {name}\n")
        content = "# Legacy recap\n\nPreserve these exact unmarked bytes.\n"
        write(repo, "docs/recap.md", content)
        if name.endswith("-modified"):
            commit(repo, "Add tracked legacy recap")
            write(repo, "docs/recap.md", "# Legacy recap\n\nUser modification; preserve exact bytes.\n")
        (control / f"{name}.sha256").write_text(
            hashlib.sha256((repo / "docs/recap.md").read_bytes()).hexdigest() + "\n", encoding="ascii"
        )
        if name.endswith("-modified"):
            (control / f"{name}.dirty.txt").write_text(
                git(repo, "status", "--porcelain", "--", "docs/recap.md") + "\n", encoding="utf-8"
            )


def seed_legacy_recap(root: Path, control: Path, name: str, branch_line: str, rewritten: bool = False) -> None:
    repo = root / name
    init_repo(repo)
    write(repo, "README.md", f"# {name}\n")
    commit(repo, "Create legacy recap fixture baseline")
    checkpoint = git(repo, "rev-parse", "HEAD")
    if rewritten:
        git(repo, "switch", "-c", "fixture-rewritten")
        write(repo, "rewritten-only.txt", "This checkpoint is on another branch.\n")
        commit(repo, "Create non-ancestor checkpoint")
        checkpoint = git(repo, "rev-parse", "HEAD")
        git(repo, "switch", "fixture-main")
        write(repo, "current-only.txt", "Current branch continues independently.\n")
        commit(repo, "Advance current branch past rewritten boundary")
    head = git(repo, "rev-parse", "HEAD")
    head_line = f"- **HEAD:** `{head}` on {branch_line}"
    content = f"""# Project Recap

## Scope

- **Repository / worktree:** {name}
- **Branch:** fixture-main
- **Committed range:** Existing legacy checkpoint
- **Working-tree inclusion:** Committed and uncommitted work are separate.
- **Context consulted:** None

## 2026-10-01 — Legacy checkpoint entry

- **Category:** documentation
- **Status:** Completed
- **What / why:** Existing legacy recap entry.
- **Important files:**
  - `README.md` — fixture evidence.
- **Commits:** `{checkpoint}` — legacy checkpoint
- **Impact:** Existing fixture history.
- **Junior notes:** Preserve this entry.
- **Verification:** not run

## Current Point

{head_line}
- **Recap checkpoint:** `{checkpoint}`
- **Pending committed history:** None
- **Committed work:** Existing legacy history.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** Continue from checkpoint.

<!-- recap-state
last_commit: {checkpoint}
last_updated: 2026-10-01
-->
"""
    write(repo, "docs/recap.md", content)
    commit(repo, "Seed clean tracked legacy recap")
    (control / f"{name}.sha256").write_text(hashlib.sha256((repo / "docs/recap.md").read_bytes()).hexdigest() + "\n", encoding="ascii")
    history_end = content.find("## Current Point")
    (control / f"{name}.history.txt").write_text(content[:history_end], encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workspace", type=Path, help="new disposable workspace; never point at a user project")
    args = parser.parse_args()
    root = args.workspace.expanduser().resolve()
    if root.exists() and any(root.iterdir()):
        parser.error(f"workspace must be absent or empty: {root}")
    root.mkdir(parents=True, exist_ok=True)
    control = root / ".control"
    control.mkdir()
    seed_catchup(root)
    seed_backlog(root)
    seed_recap(root, control)
    (control / "README.txt").write_text("Fixture evidence and byte snapshots belong here, outside all Git repositories.\n", encoding="utf-8")
    print(root)


if __name__ == "__main__":
    main()
