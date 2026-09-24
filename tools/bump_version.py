#!/usr/bin/env python3
"""Bump the add-on version (plugin.cfg, README badge, CHANGELOG) and optionally commit + tag.

Usage:
    python tools/bump_version.py --major | --minor | --patch [--dry-run] [--commit] [--any-branch]

Only edits the files by default. With --commit, asks for a commit message (pre-filled with
"Bump version to vX.Y.Z-beta "), commits only the bumped files, then offers to create the tag.
"""

import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path

# Repository root (this script lives in tools/)
ROOT = Path(__file__).resolve().parent.parent
PLUGIN_CFG = Path("addons/custom_graph_editor/plugin.cfg")
README = Path("README.md")
CHANGELOG = Path("CHANGELOG.md")
REPO_URL = "https://github.com/tehelka-gamedev/godot-custom-graph-editor"
# Bump commits are made on develop; main is then fast-forwarded to it (so the tag lands on main too)
RELEASE_BRANCH = "develop"

VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)(-[0-9A-Za-z.-]+)?$")


def fail(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bump the add-on version.")
    part = parser.add_mutually_exclusive_group(required=True)
    part.add_argument("--major", dest="part", action="store_const", const="major")
    part.add_argument("--minor", dest="part", action="store_const", const="minor")
    part.add_argument("--patch", dest="part", action="store_const", const="patch")
    parser.add_argument("--dry-run", action="store_true", help="show what would change, write nothing")
    parser.add_argument("--commit", action="store_true", help="also commit the bumped files (and offer to tag)")
    parser.add_argument("--any-branch", action="store_true", help=f"allow bumping outside '{RELEASE_BRANCH}'")
    return parser.parse_args()


def bump(version: str, part: str) -> str:
    match = VERSION_RE.match(version)
    if not match:
        fail(f"cannot parse version '{version}'")
    major, minor, patch = (int(x) for x in match.group(1, 2, 3))
    suffix = match.group(4) or ""
    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    else:
        patch += 1
    return f"{major}.{minor}.{patch}{suffix}"


def badge(version: str) -> str:
    # shields.io escapes "-" as "--"
    return f"version-{version.replace('-', '--')}-"


def replace_once(text: str, old: str, new: str, file: Path) -> str:
    count = text.count(old)
    if count != 1:
        fail(f"{file}: expected exactly one occurrence of '{old}', found {count}")
    return text.replace(old, new)


def update_changelog(text: str, old: str, new: str, today: str, dry_run: bool) -> str:
    unreleased = "## [Unreleased]\n"
    if text.count(unreleased) != 1:
        fail(f"{CHANGELOG}: expected exactly one '## [Unreleased]' heading")
    # The Unreleased section must have content, otherwise the release would be empty.
    # Only a warning in dry-run, which is just a preview.
    section = text.split(unreleased, 1)[1].split("\n## [", 1)[0]
    if not section.strip():
        if not dry_run:
            fail(f"{CHANGELOG}: the [Unreleased] section is empty, nothing to release")
        print(f"warning: {CHANGELOG}: the [Unreleased] section is empty (a real run would abort)", file=sys.stderr)

    text = text.replace(unreleased, f"{unreleased}\n## [{new}] - {today}\n", 1)
    text = replace_once(
        text,
        f"[Unreleased]: {REPO_URL}/compare/v{old}...HEAD\n",
        f"[Unreleased]: {REPO_URL}/compare/v{new}...HEAD\n"
        f"[{new}]: {REPO_URL}/compare/v{old}...v{new}\n",
        CHANGELOG,
    )
    return text


def ask_prefilled(prompt: str, prefill: str) -> str:
    """input() with editable pre-filled text (readline, Linux/macOS). Falls back to appending to the prefix."""
    try:
        import readline

        readline.set_startup_hook(lambda: readline.insert_text(prefill))
        try:
            return input(prompt)
        finally:
            readline.set_startup_hook()
    except ImportError:  # e.g. Windows without pyreadline
        return prefill + input(f"{prompt}{prefill}")


def git(*args: str) -> None:
    subprocess.run(["git", *args], cwd=ROOT, check=True)


def main() -> None:
    args = parse_args()

    # Releases are bumped (and tagged) on develop, then main is fast-forwarded to it
    branch = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.strip()

    if branch != RELEASE_BRANCH and not (args.dry_run or args.any_branch):
        fail(f"on branch '{branch}', version bumps are done on '{RELEASE_BRANCH}' (use --any-branch to override)")

    files = {path: (ROOT / path).read_text(encoding="utf-8") for path in (PLUGIN_CFG, README, CHANGELOG)}

    match = re.search(r'^version="([^"]+)"$', files[PLUGIN_CFG], re.MULTILINE)
    if not match:
        fail(f"{PLUGIN_CFG}: no version=\"...\" line found")
    old = match.group(1)
    new = bump(old, args.part)
    today = datetime.date.today().isoformat()

    print(f"{old} -> {new}")

    new_files = {
        PLUGIN_CFG: replace_once(files[PLUGIN_CFG], f'version="{old}"', f'version="{new}"', PLUGIN_CFG),
        README: replace_once(files[README], badge(old), badge(new), README),
        CHANGELOG: update_changelog(files[CHANGELOG], old, new, today, args.dry_run),
    }

    if args.dry_run:
        print(f"[dry run] would update {', '.join(str(p) for p in new_files)} (changelog date {today})")
        return

    for path, text in new_files.items():
        (ROOT / path).write_text(text, encoding="utf-8")
    print(f"Updated {', '.join(str(p) for p in new_files)}")

    if not args.commit:
        return

    try:
        message = ask_prefilled("Commit message (empty to skip): ", f"Bump version to v{new} ").strip()
    except (KeyboardInterrupt, EOFError):
        print("\nNo commit made (files are edited).")
        return
    if not message:
        print("No commit made (files are edited).")
        return

    # Commit only the bumped files, whatever else is staged or modified
    git("commit", "-m", message, "--", *(str(p) for p in new_files))

    try:
        tag = input(f"Create tag v{new}? [y/N] ").strip().lower() == "y"
    except (KeyboardInterrupt, EOFError):
        tag = False
    if tag:
        git("tag", f"v{new}")
        print(f"Tagged v{new} (not pushed).")


if __name__ == "__main__":
    main()