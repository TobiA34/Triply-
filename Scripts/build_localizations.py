#!/usr/bin/env python3
"""
Generate Localizable_<lang>.strings from English base and translation maps.
Reads Resources/Localizable.strings and writes Resources/Localizable_<lang>.strings
for each language in LANGUAGES. Uses translation dict; missing keys keep English.
"""
import os
import re
import json

BASE = os.path.join(os.path.dirname(__file__), "..", "Resources")
EN_FILE = os.path.join(BASE, "Localizable.strings")

def parse_entries(path):
    """Yield (key, value) for each "key" = "value"; line, preserving order."""
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r'^"([^"]+)"\s*=\s*"(.*)"\s*;\s*$', line)
            if m:
                key, value = m.group(1), m.group(2)
                value = value.replace("\\\"", '"').replace("\\\\", "\\")
                yield key, value

def escape_string(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

def load_translations():
    """Load translation JSON files: Resources/translations/<lang>.json -> { key: value }."""
    trans_dir = os.path.join(BASE, "translations")
    if not os.path.isdir(trans_dir):
        return {}
    out = {}
    for name in os.listdir(trans_dir):
        if name.endswith(".json"):
            lang = name[:-5]
            path = os.path.join(trans_dir, name)
            with open(path, "r", encoding="utf-8") as f:
                out[lang] = json.load(f)
    return out

def main():
    en_entries = list(parse_entries(EN_FILE))
    translations = load_translations()
    if not translations:
        print("No Resources/translations/*.json found. Create e.g. es.json with { \"key\": \"value\" }.")
        return
    for lang, trans_map in translations.items():
        out_path = os.path.join(BASE, f"Localizable_{lang}.strings")
        lines = [f"/* Localizable_{lang}.strings - {lang} */", ""]
        for key, en_val in en_entries:
            val = trans_map.get(key, en_val)
            val_esc = escape_string(val)
            lines.append(f'"{key}" = "{val_esc}";')
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        print(f"Wrote {out_path} ({len(en_entries)} keys)")

if __name__ == "__main__":
    main()
