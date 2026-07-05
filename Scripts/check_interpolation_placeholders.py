#!/usr/bin/env python3
"""
Scan .strings localization files for Swift-style interpolation that would
render literally in offline mode (e.g. '\\(Int(percentage))',
'\\(settingsManager.formatAmount(totalExpenses))', etc.).

Usage:
    python Scripts/check_interpolation_placeholders.py

Exit codes:
    0 - No suspicious interpolation-like placeholders found
    1 - At least one suspicious placeholder was found

This is intended to be used locally and in CI to prevent accidental
introduction of Swift interpolation syntax into .strings files. Dynamic
values should generally be composed in Swift code instead of being
embedded in the localized string itself.
"""

import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
RESOURCES_DIR = REPO_ROOT / "Resources"

# Patterns that look like Swift interpolation being escaped into .strings
SUSPECT_PATTERNS = [
    r"\\\(Int\(",                 # \(Int(percentage))
    r"\\\(settingsManager\.formatAmount",  # \(settingsManager.formatAmount(...))
    r"\\\(trip\.name",            # \(trip.name)
    r"\\\(",                      # any escaped \( – generic catch‑all
]

COMPILED_PATTERNS = [re.compile(p) for p in SUSPECT_PATTERNS]


def scan_strings_file(path: pathlib.Path) -> list[tuple[int, str]]:
    """Return list of (line_number, line_text) with suspicious placeholders."""
    matches: list[tuple[int, str]] = []
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        # Skip files that aren't valid UTF‑8
        return matches

    for idx, line in enumerate(text.splitlines(), start=1):
        # Ignore comments
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("/*"):
            continue

        if any(p.search(line) for p in COMPILED_PATTERNS):
            matches.append((idx, line))

    return matches


def main() -> int:
    if not RESOURCES_DIR.is_dir():
        print(f"[check-interpolation] Resources directory not found at {RESOURCES_DIR}", file=sys.stderr)
        return 0

    any_issues = False

    for strings_path in sorted(RESOURCES_DIR.rglob("*.strings")):
        file_matches = scan_strings_file(strings_path)
        if not file_matches:
            continue

        any_issues = True
        rel = strings_path.relative_to(REPO_ROOT)
        print(f"\n[check-interpolation] Suspicious interpolation markers in {rel}:")
        for line_no, line in file_matches:
            print(f"  L{line_no}: {line}")

    if any_issues:
        print(
            "\n[check-interpolation] Found Swift-style interpolation sequences in .strings files.\n"
            "These often render literally in offline mode. Consider moving the dynamic value\n"
            "composition into Swift code (e.g. '\\(Int(percentage))' → build the string in code).\n"
        )
        return 1

    print("[check-interpolation] No suspicious interpolation markers found in .strings files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

