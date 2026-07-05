#!/usr/bin/env python3
"""
Localize all user-facing text in the project.

Scans Swift files for hardcoded strings in UI contexts (Text, Button, Label,
navigationTitle, placeholder, title, etc.), reports them, and can:
  - Add missing keys to Resources/Localizable.strings
  - Optionally run gen_all_localizations.py to propagate to other languages

Usage:
  python3 Scripts/localize_all_text.py                    # Report only
  python3 Scripts/localize_all_text.py --add-keys        # Report + add new keys to EN
  python3 Scripts/localize_all_text.py --add-keys --gen  # Add keys + regenerate all langs
  python3 Scripts/localize_all_text.py --dry-run          # Show what would be added

Excludes: Pods/, */Developer/, *Tests*, *Widget*, strings already using .localized,
systemImage names, format specifiers only (e.g. "%d"), and very short strings.
"""

import argparse
import os
import re
import sys
from pathlib import Path

# Project root (parent of Scripts/)
ROOT = Path(__file__).resolve().parent.parent
RESOURCES = ROOT / "Resources"
LOCALIZABLE_EN = RESOURCES / "Localizable.strings"

# Directories to scan (Swift app code)
INCLUDE_DIRS = ("Views", "Managers", "Extensions", "Components", "Models", "Utilities", "Libraries", "Intents", "ItineroApp.swift")
# Exclude paths containing any of these
EXCLUDE_SUBSTR = (
    "Pods", "Developer/", "UITests", "Tests", "Widgets", "TriplyWidgetExtension",
    "build", ".build", "DerivedData", "SourcePackages", "checkouts", "wishkit",
)

# Patterns: (regex to find string in context, group index for the string content, pattern name)
# Match double-quoted string (no unescaped " inside) on same line
STR_LIT = r'"([^"\\]*(?:\\.[^"\\]*)*)"'
PATTERNS = [
    (r'\bText\s*\(\s*' + STR_LIT + r'\s*\)', 1, "Text"),
    (r'\bButton\s*\(\s*' + STR_LIT + r'\s*[,\)]', 1, "Button"),
    (r'\.navigationTitle\s*\(\s*' + STR_LIT + r'\s*\)', 1, "navigationTitle"),
    (r'\bLabel\s*\(\s*' + STR_LIT + r'\s*,', 1, "Label"),
    (r'placeholder:\s*' + STR_LIT, 1, "placeholder"),
    (r'title:\s*' + STR_LIT, 1, "title"),
    (r'label:\s*' + STR_LIT, 1, "label"),
    (r'prompt:\s*' + STR_LIT, 1, "prompt"),
    (r'message:\s*' + STR_LIT, 1, "message"),
    (r'alertTitle:\s*' + STR_LIT, 1, "alertTitle"),
]

# Already localized: "some.key".localized or "key".localized(...)
ALREADY_LOCALIZED_RE = re.compile(r'"[a-zA-Z0-9_.]+"\.localized')
# Likely a key (contains a dot and no spaces)
KEY_LIKE_RE = re.compile(r'^[a-zA-Z][a-zA-Z0-9_.]*$')
# Skip: system image names, format-only, too short, debug
SKIP_IF_MATCHES = re.compile(
    r'^(systemImage|image|icon|\.|%.*|[\d\s\.\-]+|trash|doc\.|gearshape|airplane|plus|chevron|xmark|ellipsis|person|envelope|link|globe|checkmark)$',
    re.I
)
MIN_STRING_LEN = 2
MAX_STRING_LEN = 500


def should_scan_file(path: Path) -> bool:
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        return False
    rel_str = str(rel).replace("\\", "/")
    if not rel_str.endswith(".swift"):
        return False
    for exc in EXCLUDE_SUBSTR:
        if exc.lower() in rel_str.lower():
            return False
    return True


def find_swift_files() -> list[Path]:
    files = []
    for path in ROOT.rglob("*.swift"):
        if should_scan_file(path):
            files.append(path)
    return sorted(set(files))


def line_is_localized(line: str) -> bool:
    return ".localized" in line and ALREADY_LOCALIZED_RE.search(line)


def unescape(s: str) -> str:
    return s.replace("\\n", "\n").replace("\\\"", '"').replace("\\\\", "\\")


def string_to_key(s: str, context: str, file_stem: str) -> str:
    """Suggest a localization key from string and context."""
    s_clean = unescape(s).strip()
    if not s_clean or len(s_clean) > 200:
        return ""
    # Normalize to identifier: lowercase, spaces -> dots, remove punctuation
    base = re.sub(r"[^\w\s]", "", s_clean)
    base = re.sub(r"\s+", ".", base.lower()).strip(".")
    if not base:
        return ""
    # Prefix by context (screen/section)
    prefix = file_stem.replace("-", "").replace(" ", "")
    prefix = re.sub(r"[^a-zA-Z]", "", prefix)
    if prefix:
        prefix = prefix[0].lower() + prefix[1:] if len(prefix) > 1 else prefix.lower()
    else:
        prefix = "misc"
    # Limit key length; use first few words
    parts = base.split(".")[:5]
    key_body = ".".join(parts)
    key = f"{prefix}.{key_body}" if key_body else prefix
    return key[:80]


def extract_strings_from_file(path: Path) -> list[tuple[int, str, str, str, str, int]]:
    """Returns list of (line_no, string_content, pattern_name, full_line, pat_re, group_ix)."""
    results = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return results
    for i, line in enumerate(text.splitlines(), 1):
        if line_is_localized(line):
            continue
        for pat_re, group_ix, name in PATTERNS:
            m = re.search(pat_re, line)
            if not m:
                continue
            s = m.group(group_ix)
            s_unesc = unescape(s)
            if len(s_unesc) < MIN_STRING_LEN or len(s_unesc) > MAX_STRING_LEN:
                continue
            if SKIP_IF_MATCHES.match(s_unesc.strip()):
                continue
            if re.match(r'^[\d\.\-\s%]+$', s_unesc):
                continue
            if s_unesc.startswith("%") and "%" in s_unesc and re.match(r"^[%\d\.\w\s]+$", s_unesc):
                continue
            results.append((i, s_unesc, name, line.strip(), pat_re, group_ix))
    return results


def load_existing_keys() -> set[str]:
    if not LOCALIZABLE_EN.exists():
        return set()
    keys = set()
    for line in LOCALIZABLE_EN.read_text(encoding="utf-8").splitlines():
        m = re.match(r'^"([^"]+)"\s*=', line)
        if m:
            keys.add(m.group(1))
    return keys


def load_value_to_key() -> dict[str, str]:
    """Map existing Localizable string value (unescaped) -> key, for reusing keys."""
    if not LOCALIZABLE_EN.exists():
        return {}
    value_to_key = {}
    for line in LOCALIZABLE_EN.read_text(encoding="utf-8").splitlines():
        m = re.match(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$', line)
        if m:
            key, raw_val = m.group(1), m.group(2)
            val = raw_val.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
            if val and val not in value_to_key:
                value_to_key[val] = key
    return value_to_key


def replace_one_line(line: str, pat_re: str, group_ix: int, string_content: str, key: str) -> str:
    """Replace one string literal on the line with \"key\".localized. Keeps prefix/suffix (e.g. Text( ))."""
    m = re.search(pat_re, line)
    if not m:
        return line
    if unescape(m.group(group_ix)) != string_content:
        return line
    # Keep everything before the opening quote of the string, then "key".localized, then everything after the closing quote
    prefix = line[m.start(0) : m.start(group_ix) - 1]  # e.g. Text( or Button(
    suffix = line[m.end(group_ix) + 1 : m.end(0)]   # +1 to skip closing quote; e.g. ) or ,
    repl = prefix + '"' + key + '".localized' + suffix
    return line[: m.start(0)] + repl + line[m.end(0) :]


def main():
    ap = argparse.ArgumentParser(description="Scan and localize user-facing text")
    ap.add_argument("--add-keys", action="store_true", help="Append new keys to Localizable.strings (EN)")
    ap.add_argument("--gen", action="store_true", help="Run gen_all_localizations.py after adding keys")
    ap.add_argument("--dry-run", action="store_true", help="Only print what would be added")
    ap.add_argument("--replace", action="store_true", help="Replace hardcoded strings with .localized in Swift files")
    args = ap.parse_args()

    existing_keys = load_existing_keys()
    value_to_key = load_value_to_key()
    files = find_swift_files()
    reported = []  # (path, line_no, s_content, pattern_name, key_to_use, full_line, pat_re, group_ix)
    new_entries = []  # (key, value) to add
    seen_new_keys = set()

    for path in files:
        for line_no, s_content, pattern_name, full_line, pat_re, group_ix in extract_strings_from_file(path):
            key_suggestion = string_to_key(s_content, pattern_name, path.stem)
            key_to_use = value_to_key.get(s_content) or key_suggestion
            if not key_to_use:
                continue
            if key_to_use == key_suggestion and key_suggestion not in existing_keys:
                if key_suggestion not in seen_new_keys:
                    seen_new_keys.add(key_suggestion)
                    new_entries.append((key_suggestion, s_content))
            reported.append((path, line_no, s_content, pattern_name, key_to_use, full_line, pat_re, group_ix))

    # Dedupe new_entries by key
    unique_new = []
    seen = set()
    for k, v in new_entries:
        if k in seen or k in existing_keys:
            continue
        seen.add(k)
        unique_new.append((k, v))

    # Add keys first so they exist when we replace
    if args.add_keys and unique_new and not args.dry_run:
        block = ["", "/* Added by localize_all_text.py */"]
        for k, v in unique_new:
            v_esc = v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
            block.append(f'"{k}" = "{v_esc}";')
        with open(LOCALIZABLE_EN, "a", encoding="utf-8") as f:
            f.write("\n".join(block) + "\n")
        print(f"Added {len(unique_new)} new key(s) to {LOCALIZABLE_EN}.")

    # --replace: apply replacements per file
    if args.replace and reported and not args.dry_run:
        from collections import defaultdict
        by_file = defaultdict(list)
        for path, line_no, s_content, _pn, key_to_use, _fl, pat_re, group_ix in reported:
            by_file[path].append((line_no, pat_re, group_ix, s_content, key_to_use))
        replaced_count = 0
        for path in by_file:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
            # Group by line_no
            by_line = defaultdict(list)
            for line_no, pat_re, group_ix, s_content, key_to_use in by_file[path]:
                by_line[line_no].append((pat_re, group_ix, s_content, key_to_use))
            for line_no, repl_list in by_line.items():
                if line_no > len(lines):
                    continue
                idx = line_no - 1
                line = lines[idx]
                for pat_re, group_ix, s_content, key_to_use in repl_list:
                    new_line = replace_one_line(line, pat_re, group_ix, s_content, key_to_use)
                    if new_line != line:
                        line = new_line
                        replaced_count += 1
                lines[idx] = line
            path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"Replaced {replaced_count} hardcoded string(s) in Swift files.")

    # Report
    print(f"Scanned {len(files)} Swift files.")
    print(f"Found {len(reported)} hardcoded string(s) in UI context.")
    if reported:
        print("\n--- Hardcoded strings (candidate for localization) ---\n")
        for path, line_no, s_content, pattern_name, key_to_use, full_line in [(r[0], r[1], r[2], r[3], r[4], r[5]) for r in reported[:80]]:
            short_path = path.relative_to(ROOT) if ROOT in path.parents else path
            preview = (s_content[:60] + "…") if len(s_content) > 60 else s_content
            print(f"  {short_path}:{line_no}  [{pattern_name}]  {preview!r}")
            print(f"    → key: \"{key_to_use}\"")
        if len(reported) > 80:
            print(f"  ... and {len(reported) - 80} more.")
    else:
        print("No hardcoded UI strings found (or all already use .localized).")
        return 0

    if args.dry_run and unique_new:
        print("\n--- Would add to Localizable.strings ---\n")
        for k, v in unique_new[:30]:
            print(f'  "{k}" = "{v[:50]}{"…" if len(v) > 50 else ""}";')
        if len(unique_new) > 30:
            print(f"  ... and {len(unique_new) - 30} more.")

    if args.gen and not args.dry_run and (args.add_keys and unique_new):
        import subprocess
        gen_script = ROOT / "Scripts" / "gen_all_localizations.py"
        if gen_script.exists():
            subprocess.run([sys.executable, str(gen_script)], cwd=ROOT, check=True)
            print("Ran gen_all_localizations.py to update all language files.")
        else:
            print("gen_all_localizations.py not found; skip --gen.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
