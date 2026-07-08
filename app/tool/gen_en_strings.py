#!/usr/bin/env python3
"""Regenerate lib/l10n/en_strings.g.dart from assets/i18n/en.json.

English is the app's base + fallback locale. Embedding it as a Dart const lets
`AppLocalizations` resolve English synchronously (no rootBundle await) — so the
first frame is already translated and widget tests need no extra pump for the
localization future to land. Run this after editing assets/i18n/en.json:

    python3 tool/gen_en_strings.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets/i18n/en.json")
OUT = os.path.join(ROOT, "lib/l10n/en_strings.g.dart")

en = json.load(open(SRC, encoding="utf-8"))
lines = [
    "// GENERATED — do not edit by hand.",
    "// Regenerate after changing assets/i18n/en.json:",
    "//   python3 tool/gen_en_strings.py",
    "//",
    "// The English base table, embedded as Dart so it loads synchronously:",
    "// English is the default + fallback locale, so resolving it without an",
    "// async asset read means no first-frame flash and no extra pump in tests.",
    "library;",
    "",
    "const Map<String, String> kEnStrings = {",
]
for k in sorted(en):
    lines.append(f"  {json.dumps(k, ensure_ascii=False)}: "
                 f"{json.dumps(en[k], ensure_ascii=False)},")
lines.append("};")
open(OUT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(f"wrote {OUT} with {len(en)} entries")
