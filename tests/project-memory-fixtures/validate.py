#!/usr/bin/env python3
"""Assert observable outputs and Git state after manual skill invocations."""
from __future__ import annotations

import argparse
import sys
import hashlib
from pathlib import Path
import re
import subprocess

from generate import git, legacy_backlog
OUTPUTS = {"catchup": "docs/overview.md", "backlog": "docs/backlog.md", "recap": "docs/recap.md"}
OVERVIEW_HEADINGS = (
    "Purpose",
    "Stack",
    "Architecture",
    "Application Flow",
    "Important Modules",
    "Important Files",
    "Data Flow",
    "External Dependencies",
    "Environment and Configuration",
    "Development Workflow",
    "Recommended Reading Order",
    "Cautions",
)


def require_overview_headings(text: str, label: str) -> None:
    for heading in OVERVIEW_HEADINGS:
        require(f"## {heading}" in text, f"{label} lacks template section {heading}")


def git_succeeds(repo: Path, *args: str) -> bool:
    try:
        git(repo, *args)
    except subprocess.CalledProcessError:
        return False
    return True


def require(ok: bool, message: str) -> None:
    if not ok:
        raise AssertionError(message)


def has_valid_fingerprint(path: Path) -> bool:
    data = path.read_bytes()
    markers = list(re.finditer(rb"<!-- (?:skill-state|recap-state)\r?\n.*?-->", data, re.S))
    marker_starts = list(re.finditer(rb"<!-- (?:skill-state|recap-state)\r?\n", data))
    matches = list(re.finditer(rb"(?m)^output_sha256: ([0-9a-f]{64})\r?\n", data))
    if len(markers) != 1 or len(marker_starts) != 1 or len(matches) != 1:
        return False
    marker, match = markers[0], matches[0]
    if not marker.start() <= match.start() < marker.end():
        return False
    expected = match.group(1).decode("ascii")
    actual = hashlib.sha256(data[:match.start()] + data[match.end():]).hexdigest()
    return actual == expected


def snapshot(repo: Path, exclude: str) -> dict[str, str]:
    result = {}
    for path in repo.rglob("*"):
        if not path.is_file() or ".git" in path.parts or path.relative_to(repo).as_posix() == exclude:
            continue
        result[path.relative_to(repo).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result


def arm_invalid(workspace: Path, name: str) -> None:
    skill = name.split("-", 1)[0]
    rel = OUTPUTS[skill]
    repo = workspace / name
    path = repo / rel
    require(path.is_file(), f"Invoke {skill} once before arming invalid fingerprint case {name}")
    with path.open("ab") as output:
        output.write(b"\n<!-- fixture user edit: preserve these exact bytes -->\n")
    evidence = workspace / ".control" / f"{name}.sha256"
    evidence.write_text(hashlib.sha256(path.read_bytes()).hexdigest() + "\n", encoding="ascii")
    print(f"Edited {rel}; now invoke the skill and run check {name}")


def check_repeat(workspace: Path, name: str) -> None:
    skill = name.split("-", 1)[0]
    rel = OUTPUTS[skill]
    repo = workspace / name
    path = repo / rel
    require(path.is_file(), f"Missing owned output {rel}; invoke the skill")
    require(has_valid_fingerprint(path), f"{rel} has no valid single fingerprint")
    state = git(repo, "status", "--porcelain", "--", rel)
    require(bool(state), f"{rel} is not dirty; fixture must prove repeat update while uncommitted")
    print(f"PASS: valid fingerprint, dirty owned output, {rel} present")


def check_invalid(workspace: Path, name: str) -> None:
    skill = name.split("-", 1)[0]
    rel = OUTPUTS[skill]
    repo = workspace / name
    path = repo / rel
    expected = (workspace / ".control" / f"{name}.sha256").read_text(encoding="ascii").strip()
    require(hashlib.sha256(path.read_bytes()).hexdigest() == expected, f"{rel} changed after invalid fingerprint; user bytes must remain exact")
    require(not has_valid_fingerprint(path), f"{rel} unexpectedly validates despite deliberate edit")
    print(f"PASS: invalid fingerprint preserved all bytes in {rel}")




def check_legacy(workspace: Path, name: str) -> None:
    skill = name.split("-", 1)[0]
    rel = OUTPUTS[skill]
    repo = workspace / name
    path = repo / rel
    if name.endswith("-tracked"):
        require(path.is_file() and has_valid_fingerprint(path), f"clean tracked legacy {rel} was not adopted with a valid fingerprint")
        text = path.read_text(encoding="utf-8")
        if skill == "catchup":
            require_overview_headings(text, "adopted overview")
            require("accepts a name and returns a greeting" in text, "adopted overview lost the existing project purpose")
            require("fixture-secret-do-not-copy" not in text, "secret fixture value was copied into adopted overview")
        else:
            done = "### BL-014" + legacy_backlog_expected().split("### BL-014", 1)[1].rstrip()
            require(done in text, "adopted backlog did not preserve BL-014 and its completion record byte-for-byte")
    else:
        expected = "# Legacy overview\n\nKeep this unmarked content.\n" if skill == "catchup" else legacy_backlog_expected()
        if name == "catchup-legacy-modified":
            expected = "# Legacy overview\n\nUser modification.\n"
        if name == "backlog-legacy-modified":
            expected += "\nUser edit to legacy backlog.\n"
        require(path.read_text(encoding="utf-8") == expected, f"refused legacy {rel} was overwritten or changed")
    if name.endswith("-untracked"):
        require(not git_succeeds(repo, "ls-files", "--error-unmatch", rel), "untracked legacy output became tracked")
    print(f"PASS: legacy adoption/refusal behavior for {name}")


def legacy_backlog_expected() -> str:
    return legacy_backlog()



def check_catchup(workspace: Path) -> None:
    repo = workspace / "catchup-valid"
    rel = OUTPUTS["catchup"]
    path = repo / rel
    require(path.is_file() and has_valid_fingerprint(path), "overview missing or fingerprint invalid")
    text = path.read_text(encoding="utf-8")
    require_overview_headings(text, "overview")
    require("accepts a name and returns a greeting" in text, "overview omits the README-supported service purpose")
    require("greet(name)" in text and "hello" in text, "overview omits the source-supported greeting implementation")
    require("APP_MODE" in text and "API_TOKEN" in text, "overview omits the fixture configuration variable names")
    require("fixture-secret-do-not-copy" not in text, "secret fixture value was copied")
    require(set(snapshot(repo, rel)) == {"README.md", "src/app.py", "pyproject.toml", "tests/test_app.py", "config/example.env", "notes/unrelated.txt"}, "catchup wrote a path besides docs/overview.md")
    print("PASS: catchup evidence-shaped output, secret redaction, fingerprint and one-output ownership")


def check_backlog(workspace: Path) -> None:
    repo = workspace / "backlog-valid"
    rel = OUTPUTS["backlog"]
    path = repo / rel
    require(path.is_file() and has_valid_fingerprint(path), "backlog missing or fingerprint invalid")
    text = path.read_text(encoding="utf-8")
    sections = ["In Progress", "Todo", "Blocked", "Needs Review", "Done"]
    positions = [text.find(f"## {section}") for section in sections]
    require(all(position >= 0 for position in positions), "backlog must retain all five sections")
    require("## Item format" not in text, "authoring guidance leaked into generated backlog")
    items = list(re.finditer(r"(?m)^### (BL-\d{3}) — .+$", text))
    ids = [match.group(1) for match in items]
    require(len(ids) == len(set(ids)), "backlog IDs are not unique")
    require(all(int(identifier[3:]) > 14 for identifier in ids if identifier != "BL-014"), "new backlog ID recycled or precedes reserved Done ID BL-014")
    done = "### BL-014" + legacy_backlog_expected().split("### BL-014", 1)[1].rstrip()
    new_ids = [identifier for identifier in ids if identifier != "BL-014"]
    require(len(new_ids) == 1, "backlog must create exactly one item for the sole fixture TODO")
    item_start = next(match.start() for match in items if match.group(1) == new_ids[0])
    next_item = next((match.start() for match in items if match.start() > item_start), len(text))
    item = text[item_start:next_item]
    new_status = re.search(r"(?m)^- \*\*Status:\*\* (.+)$", item)
    require(new_status is not None and new_status.group(1) == "Todo", "the sole new item for the unstarted empty-name TODO must remain Todo")
    require(done in text, "Done item or its completion record was not preserved byte-for-byte")
    allowed = {"Todo", "In Progress", "Blocked", "Needs Review", "Done"}
    for index, match in enumerate(items):
        end = items[index + 1].start() if index + 1 < len(items) else len(text)
        block = text[match.start():end]
        status = re.search(r"(?m)^- \*\*Status:\*\* (.+)$", block)
        require(status is not None and status.group(1) in allowed, f"{match.group(1)} has invalid status")
        section = max((p, s) for p, s in zip(positions, sections) if p < match.start())[1]
        require(section == status.group(1), f"{match.group(1)} status does not match its section")
        require(re.search(r"(?m)^- \*\*Priority:\*\* (High|Medium|Low)$", block), f"{match.group(1)} has invalid/missing priority")
    require(set(snapshot(repo, rel)) == {"README.md", "src/app.py", "pyproject.toml", "tests/test_app.py", "config/example.env", "notes/unrelated.txt"}, "backlog wrote a path besides docs/backlog.md")
    print("PASS: stable unique IDs, preserved Done record, five sections, valid status placement, one-output ownership")


def state_value(text: str, name: str) -> str:
    match = re.search(rf"(?m)^{re.escape(name)}: (.*)$", text)
    require(match is not None, f"recap state lacks {name}")
    return match.group(1)


def selected_hashes(repo: Path) -> list[str]:
    all_hashes = git(repo, "rev-list", "--topo-order", "--reverse", "HEAD").splitlines()
    return all_hashes[-1000:]


def recap_entry_hash_lines(text: str) -> list[str]:
    current = text.find("## Current Point")
    history = text[:current if current >= 0 else len(text)]
    return re.findall(r"(?m)^- \*\*Commits:\*\* (.+)$", history)


def resolve_entry_hashes(lines: list[str], selected: list[str]) -> list[str]:
    resolved = []
    for line in lines:
        for token in re.findall(r"\b[0-9a-f]{7,40}\b", line):
            matches = [commit_id for commit_id in selected if commit_id.startswith(token)]
            if len(matches) == 1:
                resolved.append(matches[0])
    return resolved


def check_recap(workspace: Path, expected_count: int) -> None:
    repo = workspace / "recap-large-history"
    path = repo / OUTPUTS["recap"]
    require(path.is_file() and has_valid_fingerprint(path), "recap missing or fingerprint invalid")
    text = path.read_text(encoding="utf-8")
    selected = selected_hashes(repo)
    require(int(git(repo, "rev-list", "--count", "HEAD")) > 1000, "fixture must exceed 1,000 commits")
    require(1 <= expected_count <= 1000 and expected_count % 100 == 0, "progress checkpoints must be a multiple of 100 from 100 through 1,000")
    processed = selected[:expected_count]
    pending = selected[expected_count:]
    state_pending = state_value(text, "pending_commits")
    require(state_pending == (" ".join(pending) if pending else "none"), "pending_commits is not the exact oldest-first remaining hash queue")
    last = state_value(text, "last_commit")
    require(processed[-1].startswith(last) and len(last) >= 7, "checkpoint does not resolve to the final represented batch hash")
    require(state_value(text, "history_head") == git(repo, "rev-parse", "HEAD"), "history_head not reconciled to pinned HEAD")
    require(state_value(text, "branch") == "fixture-main", "recap state branch binding is wrong")
    entry_hashes = resolve_entry_hashes(recap_entry_hash_lines(text), selected)
    require(entry_hashes == processed, "dated entries do not represent exactly the processed commits once, oldest-first")
    require("Pending committed history" in text, "Current Point does not expose pending history")
    current = text[text.find("## Current Point"):]
    pending_field = re.search(r"(?ms)^- \*\*Pending committed history:\*\* (.*?)(?=^- \*\*|\Z)", current)
    require(pending_field is not None, "Current Point lacks pending-history details")
    require(re.search(rf"(?<!\d){len(pending)}(?!\d)", pending_field.group(1)), "Current Point pending count is wrong")
    visible = re.findall(r"\b[0-9a-f]{40}\b", pending_field.group(1))
    require(visible == pending[:100], "Current Point does not list the exact next up-to-100 full pending hashes")
    require("older" in text.lower() and ("outside" in text.lower() or "omitted" in text.lower()), "older-than-1,000 history omission is invisible")
    if expected_count == 100:
        require(re.search(r"(?<!\d)1,?000(?!\d)", text) is not None, "initial selected-window size is not visible")
        (workspace / ".control" / "recap-initial.sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest() + "\n", encoding="ascii")
    if expected_count == 1000:
        history_end = text.find("## Current Point")
        (workspace / ".control" / "recap-history.sha256").write_text(hashlib.sha256(text[:history_end].encode("utf-8")).hexdigest() + "\n", encoding="ascii")
    print(f"PASS: recap checkpoint {expected_count}/1000; {len(pending)} exact pending hashes; no gap/duplicate; branch and omission visible")


def check_recap_no_new(workspace: Path) -> None:
    repo = workspace / "recap-large-history"
    path = repo / OUTPUTS["recap"]
    require(path.is_file() and has_valid_fingerprint(path), "recap missing or fingerprint invalid after no-new run")
    text = path.read_text(encoding="utf-8")
    expected_history = (workspace / ".control" / "recap-history.sha256").read_text(encoding="ascii").strip()
    history_end = text.find("## Current Point")
    require(history_end >= 0 and hashlib.sha256(text[:history_end].encode("utf-8")).hexdigest() == expected_history, "no-new run changed or duplicated historical entries")
    last = state_value(text, "last_commit")
    require(re.fullmatch(r"[0-9a-f]{7,40}", last) is not None, "no-new checkpoint is not a full or abbreviated commit hash")
    checkpoint = git(repo, "rev-parse", "--verify", f"{last}^{{commit}}")
    require(checkpoint == git(repo, "rev-parse", "HEAD"), "no-new run changed the completed checkpoint")
    require(state_value(text, "pending_commits") == "none", "no-new run has unexpected pending commits")
    require(state_value(text, "branch") == "fixture-main", "no-new run changed branch binding")
    print("PASS: no-new-commit run preserved history/checkpoint with empty queue and valid fingerprint")


def check_legacy_recap(workspace: Path, name: str) -> None:
    repo = workspace / name
    rel = OUTPUTS["recap"]
    path = repo / rel
    if name in ("recap-legacy-untracked", "recap-legacy-modified"):
        expected = (workspace / ".control" / f"{name}.sha256").read_text(encoding="ascii").strip()
        require(hashlib.sha256(path.read_bytes()).hexdigest() == expected, f"{name} refusal changed recap bytes")
        require(not has_valid_fingerprint(path), f"{name} unmarked legacy recap unexpectedly gained a fingerprint")
        status = git(repo, "status", "--porcelain", "--", rel)
        if name.endswith("-untracked"):
            require(status.startswith("?? "), "untracked legacy recap became tracked or otherwise changed")
        else:
            expected_status = (workspace / ".control" / f"{name}.dirty.txt").read_text(encoding="utf-8").strip()
            require(status == expected_status and bool(status), "modified tracked legacy recap lost its dirty state")
        print(f"PASS: {name} refusal preserved recap bytes and Git ownership state")
        return
    text = path.read_text(encoding="utf-8")
    if name == "recap-legacy-branch-match":
        require(has_valid_fingerprint(path), "matching legacy branch was not adopted with a valid fingerprint")
        require(state_value(text, "branch") == "fixture-main", "legacy branch was not inferred from Current Point")
        require(state_value(text, "pending_commits") == "none", "matching legacy checkpoint should have no pending work")
        require(state_value(text, "last_commit") == git(repo, "rev-parse", "HEAD"), "matching legacy checkpoint should equal the post-adoption HEAD")
        expected_history = (workspace / ".control" / f"{name}.history.txt").read_text(encoding="utf-8")
        seed_commit = git(repo, "log", "-1", "--format=%H", "--", rel)
        entries = resolve_entry_hashes(recap_entry_hash_lines(text), [seed_commit])
        require(entries.count(seed_commit) == 1, "dated recap entries must contain the exact legacy recap seed commit exactly once")
        require(text.startswith(expected_history), "legacy history entry changed during migration")
        require(set(snapshot(repo, rel)) == {"README.md"}, "legacy recap migration wrote outside its one owned output")
        print("PASS: matching legacy branch inferred, adopted and fingerprinted")
        return
    if name == "recap-legacy-nongit":
        require(not git_succeeds(repo, "rev-parse", "--is-inside-work-tree"), "non-Git recap fixture unexpectedly belongs to a Git worktree")
        expected = (workspace / ".control" / f"{name}.sha256").read_text(encoding="ascii").strip()
        require(hashlib.sha256(path.read_bytes()).hexdigest() == expected, f"{name} refusal changed recap bytes")
        require(not has_valid_fingerprint(path), f"{name} unmarked recap unexpectedly gained a fingerprint")
        print("PASS: non-Git recap refusal preserved exact bytes and remains outside Git")
        return
    expected = (workspace / ".control" / f"{name}.sha256").read_text(encoding="ascii").strip()
    require(hashlib.sha256(path.read_bytes()).hexdigest() == expected, f"{name} refusal changed recap bytes")
    require(not git(repo, "status", "--porcelain", "--", rel), f"{name} refusal dirtied the legacy recap")
    if name == "recap-legacy-branch-ambiguous":
        require(text.count("- **HEAD:**") == 2, "ambiguous fixture must contain competing legacy branch metadata")
    elif name == "recap-legacy-branch-mismatch":
        require(git(repo, "branch", "--show-current") == "fixture-main" and "on fixture-old" in text, "legacy mismatch fixture is not branch-bound to another branch")
    elif name == "recap-legacy-branch-missing":
        require(text.count("- **HEAD:**") == 1 and " on fixture-main" not in text, "missing-branch fixture unexpectedly identifies a unique branch")
    elif name == "recap-rewritten-checkpoint":
        checkpoint = state_value(text, "last_commit")
        require(git_succeeds(repo, "rev-parse", "--verify", f"{checkpoint}^{{commit}}"), "rewritten checkpoint fixture commit is unavailable")
        require(not git_succeeds(repo, "merge-base", "--is-ancestor", checkpoint, "HEAD"), "rewritten checkpoint must not be an ancestor of current HEAD")
    print(f"PASS: {name} refusal preserved legacy recap bytes")


def check_branch_mismatch(workspace: Path) -> None:
    repo = workspace / "recap-large-history"
    path = repo / OUTPUTS["recap"]
    before = (workspace / ".control" / "recap-initial.sha256").read_text(encoding="ascii").strip()
    require(hashlib.sha256(path.read_bytes()).hexdigest() == before, "recap changed after branch mismatch; preserve bytes and baseline")
    require(git(repo, "branch", "--show-current") == "fixture-other", "run branch mismatch check while on fixture-other")
    print("PASS: recap bytes unchanged on branch mismatch")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    arm = sub.add_parser("arm-invalid"); arm.add_argument("workspace", type=Path); arm.add_argument("scenario")
    check = sub.add_parser("check"); check.add_argument("workspace", type=Path); check.add_argument("scenario")
    args = parser.parse_args()
    workspace = args.workspace.expanduser().resolve()
    if args.command == "arm-invalid":
        arm_invalid(workspace, args.scenario)
        return
    name = args.scenario
    if name in ("catchup-valid", "backlog-valid"):
        check_repeat(workspace, name)
        (check_catchup if name.startswith("catchup") else check_backlog)(workspace)
    elif name.endswith("invalid"):
        check_invalid(workspace, name)
    elif name.startswith(("catchup-legacy", "backlog-legacy")):
        check_legacy(workspace, name)
    elif name.startswith("recap-legacy-") or name == "recap-rewritten-checkpoint":
        check_legacy_recap(workspace, name)
    elif name.startswith("recap-progress-"):
        try:
            check_recap(workspace, int(name.removeprefix("recap-progress-")))
        except ValueError:
            parser.error("recap progress scenario must end in a number")
    elif name == "recap-no-new":
        check_recap_no_new(workspace)
    elif name == "recap-branch-mismatch":
        check_branch_mismatch(workspace)
    else:
        parser.error(f"unknown scenario: {name}")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
