# Localization: No Hardcoded Text, Managed via Python

All user-facing text lives in **Resources/Localizable.strings** (and **Localizable_&lt;lang&gt;.strings**). Swift code uses only keys, e.g. `Text("addTrip.getStarted".localized)`.

## Rules

1. **No hardcoded user-facing strings in Swift.** Use `"key".localized` or `"key".localized(arg1, arg2)` for formats.
2. **All copy is changed via Python** by editing the `.strings` files or using the scripts below.

## Python Scripts

### 1. `sync_localizations.py` – main tool

- **Extract** (find new strings in Swift and add keys):
  ```bash
  cd /path/to/Triply
  python3 Scripts/sync_localizations.py extract          # add new keys to base + all lang files
  python3 Scripts/sync_localizations.py extract --dry-run # preview only
  ```
- **Update** (change copy from a JSON file):
  ```bash
  # JSON format: { "key": "value" } or { "key": { "en": "English", "es": "Spanish" } }
  python3 Scripts/sync_localizations.py update Resources/translations/updates.json
  ```
- **Propagate** (ensure every key in base exists in all language files; missing = copy from base):
  ```bash
  python3 Scripts/sync_localizations.py propagate
  ```
- **Export** (dump base keys to JSON for editing):
  ```bash
  python3 Scripts/sync_localizations.py export > keys.json
  # Edit keys.json, then use update with the same file
  ```

### 2. `gen_all_localizations.py`

Generates **Localizable_es, _de, _it, _pt, _ja, _ko, _zh-Hans** from the English base and a French phrase map. Run after adding keys to base:

```bash
python3 Scripts/gen_all_localizations.py
```

### 3. `build_localizations.py`

Builds language files from **Resources/translations/&lt;lang&gt;.json**. Put key-value pairs in JSON; script writes **Localizable_&lt;lang&gt;.strings**.

## Workflow to change any text

1. **Edit base (English):**  
   Open **Resources/Localizable.strings** and change the value for the key, **or** edit a JSON and run:
   ```bash
  python3 Scripts/sync_localizations.py update my_edits.json
  ```
2. **Edit other languages:**  
   Edit **Resources/Localizable_es.strings** (etc.) or provide a JSON with per-lang values and run `update` with that JSON.
3. **Propagate:**  
   So new keys in base exist in all lang files:
   ```bash
  python3 Scripts/sync_localizations.py propagate
  ```
4. **Regenerate translations (optional):**  
   If you use the phrase map:
   ```bash
  python3 Scripts/gen_all_localizations.py
  ```

## Adding new copy from Swift

1. In Swift use a key: `Text("myFeature.title".localized)`.
2. Add the key to the base file:
   ```bash
  echo '"myFeature.title" = "My Title";' >> Resources/Localizable.strings
  ```
   Or add it to a JSON and run `sync_localizations.py update`.
3. Run **propagate** so the key exists in all language files:
   ```bash
  python3 Scripts/sync_localizations.py propagate
  ```

No hardcoded text in the app; all changes go through the `.strings` files and Python.
