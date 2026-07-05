#!/usr/bin/env python3
"""
Manage all app copy via Python: no hardcoded text in Swift.
- Extract: scan Swift for string literals, suggest keys, add to .strings files.
- Update: read a JSON/CSV of key-value and write to Localizable.strings + all Localizable_<lang>.strings.
- Propagate: ensure every key in base exists in all language files (value = base or from translations).

Usage:
  python3 Scripts/sync_localizations.py extract [--dry-run]   # scan Swift, add missing keys
  python3 Scripts/sync_localizations.py update <file.json>    # update .strings from JSON
  python3 Scripts/sync_localizations.py propagate            # sync keys to all lang files (missing = copy from base)
  python3 Scripts/sync_localizations.py export > keys.json    # export all keys (base) to JSON for editing
"""
import os
import re
import sys
import json
import argparse
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
RESOURCES = PROJECT_ROOT / "Resources"
BASE_STRINGS = RESOURCES / "Localizable.strings"

# Languages we ship (base English + these)
LANG_CODES = ["es", "fr", "de", "it", "pt", "ja", "ko", "zh-Hans"]

# Swift dirs to scan for user-facing strings (skip Pods, Tests, some Libs)
SWIFT_SCAN_DIRS = [
    PROJECT_ROOT / "Views",
    PROJECT_ROOT / "Managers",
    PROJECT_ROOT / "Models",
    PROJECT_ROOT / "Components",
    PROJECT_ROOT / "Intents",
    PROJECT_ROOT / "Widgets",
    PROJECT_ROOT / "Extensions",
    PROJECT_ROOT / "Utilities",
]
SWIFT_EXCLUDE = {"Pods", "Tests", "ItineroUITests", "WishKit", "WishKitShared", "RevenueCat", "LanguagePicker", "CurrencyPicker"}


def parse_strings_file(path: Path) -> list[tuple[str, str]]:
    """Yield (key, value) from a .strings file."""
    if not path.exists():
        return []
    entries = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r'^"([^"]+)"\s*=\s*"(.*)"\s*;\s*$', line)
            if m:
                key, value = m.group(1), m.group(2)
                value = value.replace("\\\"", '"').replace("\\\\", "\\").replace("\\n", "\n")
                entries.append((key, value))
    return entries


def escape_for_strings(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def slug_from_string(s: str, prefix: str = "app") -> str:
    """Generate a valid key from a phrase: app.new_trip, addTrip.get_started, etc."""
    s = s.strip()
    if not s:
        return f"{prefix}.untitled"
    # Use prefix if passed (e.g. addTrip), else derive from words
    key = re.sub(r"[^\w\s]", "", s).lower()
    key = re.sub(r"\s+", ".", key)[:50]
    key = key or "untitled"
    return f"{prefix}.{key}" if prefix else key


def extract_string_literals_from_swift(content: str, filepath: Path) -> list[tuple[str, int]]:
    """Find user-facing string literals: Text("..."), title: "...", .navigationTitle("..."), etc."""
    found = []
    # Text("...") or Text("\(...)" - skip interpolated
    for m in re.finditer(r'Text\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', content):
        s = m.group(1)
        if not s.startswith("\\(") and ("\\(" + "%") not in s and len(s) > 1:
            found.append((s.replace("\\\"", '"').replace("\\\\", "\\"), m.start()))
    # .navigationTitle("...")
    for m in re.finditer(r'\.navigationTitle\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)', content):
        s = m.group(1).replace("\\\"", '"').replace("\\\\", "\\")
        if len(s) > 1:
            found.append((s, m.start()))
    # title: "..."
    for m in re.finditer(r'title:\s*"((?:[^"\\]|\\.)*)"', content):
        s = m.group(1).replace("\\\"", '"').replace("\\\\", "\\")
        if len(s) > 2:
            found.append((s, m.start()))
    # Label("...",
    for m in re.finditer(r'Label\s*\(\s*"((?:[^"\\]|\\.)*)"', content):
        s = m.group(1).replace("\\\"", '"').replace("\\\\", "\\")
        if len(s) > 1:
            found.append((s, m.start()))
    # Button("...") or label: "..." in Picker
    for m in re.finditer(r'(?:Button|label:)\s*\(\s*"((?:[^"\\]|\\.)*)"', content):
        s = m.group(1).replace("\\\"", '"').replace("\\\\", "\\")
        if len(s) > 1:
            found.append((s, m.start()))
    return found


def all_existing_keys_and_values() -> tuple[dict[str, str], dict[str, dict[str, str]]]:
    """Load base (key -> value) and per-lang (lang -> { key -> value })."""
    base = dict(parse_strings_file(BASE_STRINGS))
    per_lang = {}
    for lang in LANG_CODES:
        p = RESOURCES / f"Localizable_{lang}.strings"
        per_lang[lang] = dict(parse_strings_file(p))
    return base, per_lang


def extract_command(dry_run: bool) -> None:
    """Scan Swift files, find strings not yet in base, add keys."""
    base, per_lang = all_existing_keys_and_values()
    existing_values = set(base.values())
    new_entries: list[tuple[str, str]] = []
    seen_strings: set[str] = set()

    for dir_path in SWIFT_SCAN_DIRS:
        if not dir_path.exists():
            continue
        for swift_file in dir_path.rglob("*.swift"):
            if any(ex in str(swift_file) for ex in SWIFT_EXCLUDE):
                continue
            try:
                content = swift_file.read_text(encoding="utf-8")
            except Exception:
                continue
            # Skip files that only use .localized
            if '.localized' in content and 'Text("' not in content:
                continue
            prefix = swift_file.stem
            prefix = re.sub(r"View|Manager|Model|Sheet|Picker|Library", "", prefix)
            prefix = (prefix or "app").lower()[:20]
            for s, _ in extract_string_literals_from_swift(content, swift_file):
                if s in seen_strings or s in existing_values or len(s) < 2:
                    continue
                if s.startswith("common.") or s.startswith("trips.") or '"' in s:
                    continue
                seen_strings.add(s)
                key = slug_from_string(s, prefix)
                if key in base:
                    continue
                # Uniquify key if collision
                while key in base:
                    key = key + "_2"
                new_entries.append((key, s))
                existing_values.add(s)

    if not new_entries:
        print("No new strings to add.")
        return
    print(f"Found {len(new_entries)} new strings to add.")
    if dry_run:
        for k, v in new_entries[:30]:
            print(f"  {k} = {v[:60]}...")
        if len(new_entries) > 30:
            print(f"  ... and {len(new_entries) - 30} more")
        return

    # Append to base
    with open(BASE_STRINGS, "a", encoding="utf-8") as f:
        f.write("\n")
        for k, v in new_entries:
            f.write(f'"{k}" = "{escape_for_strings(v)}";\n')
    print(f"Appended {len(new_entries)} keys to {BASE_STRINGS}")

    # Propagate to other langs (same value for now; edit via update command)
    for lang in LANG_CODES:
        path = RESOURCES / f"Localizable_{lang}.strings"
        existing = dict(parse_strings_file(path))
        with open(path, "a", encoding="utf-8") as f:
            for k, v in new_entries:
                if k not in existing:
                    f.write(f'\n"{k}" = "{escape_for_strings(v)}";')
        print(f"  Updated {path.name}")


def update_command(json_path: Path) -> None:
    """Update .strings files from a JSON file. JSON format: { "key": "value" } or { "key": { "en": "...", "es": "..." } }."""
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    base, per_lang = all_existing_keys_and_values()
    base_entries = list(parse_strings_file(BASE_STRINGS))

    for key, val in data.items():
        if isinstance(val, dict):
            if "en" in val:
                base[key] = val["en"]
            for lang, v in val.items():
                if lang != "en" and lang in per_lang:
                    per_lang[lang][key] = v
        else:
            base[key] = str(val)

    # Write base
    with open(BASE_STRINGS, "w", encoding="utf-8") as f:
        f.write("/* Localizable.strings */\n/* English (Base) - managed by sync_localizations.py */\n\n")
        for k in sorted(base.keys()):
            f.write(f'"{k}" = "{escape_for_strings(base[k])}";\n')
    print(f"Wrote {BASE_STRINGS} ({len(base)} keys)")

    for lang in LANG_CODES:
        path = RESOURCES / f"Localizable_{lang}.strings"
        d = per_lang[lang]
        for k, v in base.items():
            if k not in d:
                d[k] = v
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"/* Localizable_{lang}.strings - {lang} */\n\n")
            for k in sorted(d.keys()):
                f.write(f'"{k}" = "{escape_for_strings(d[k])}";\n')
        print(f"Wrote {path.name} ({len(d)} keys)")


def propagate_command() -> None:
    """Ensure every key in base exists in all Localizable_<lang>.strings; missing = copy from base."""
    base_entries = parse_strings_file(BASE_STRINGS)
    base = dict(base_entries)
    if not base:
        print("No base keys found.")
        return
    for lang in LANG_CODES:
        path = RESOURCES / f"Localizable_{lang}.strings"
        d = dict(parse_strings_file(path))
        for k, v in base.items():
            if k not in d:
                d[k] = v
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"/* Localizable_{lang}.strings - {lang} */\n\n")
            for key in sorted(d.keys()):
                f.write(f'"{key}" = "{escape_for_strings(d[key])}";\n')
        print(f"Wrote {path.name} ({len(d)} keys)")
    print("Propagate done. All language files have the same keys as base.")


def export_command() -> None:
    """Export base keys to JSON for editing."""
    base = dict(parse_strings_file(BASE_STRINGS))
    json.dump(base, sys.stdout, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description="Manage localizations via Python; no hardcoded text in app.")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("extract", help="Scan Swift, add missing strings to .strings files").add_argument("--dry-run", action="store_true")
    sub.add_parser("propagate", help="Sync all keys from base to every language file")
    sub.add_parser("export", help="Export base keys to JSON")
    up = sub.add_parser("update", help="Update .strings from JSON file")
    up.add_argument("json_file", type=Path, help="JSON: { \"key\": \"value\" } or { \"key\": { \"en\": \"...\", \"es\": \"...\" } }")
    args = parser.parse_args()

    if args.command == "extract":
        extract_command(getattr(args, "dry_run", False))
    elif args.command == "update":
        update_command(args.json_file)
    elif args.command == "propagate":
        propagate_command()
    elif args.command == "export":
        export_command()


if __name__ == "__main__":
    main()
