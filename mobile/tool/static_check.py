#!/usr/bin/env python3
"""Source-level checks for environments without the Flutter/Dart SDK.

This is not a replacement for `flutter analyze`; it catches missing local imports,
obvious delimiter errors, stale old CRM hosts, and unmapped legacy endpoint literals.
"""
from __future__ import annotations
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
errors: list[str] = []

# 1. Local import resolution.
import_re = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]", re.M)
for path in LIB.rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    for target in import_re.findall(text):
        if target.startswith("dart:") or target.startswith("package:flutter") or target.startswith("package:flutter_"):
            continue
        if target.startswith("package:"):
            if not target.startswith("package:dart_crm/"):
                continue
            candidate = LIB / target.split("package:dart_crm/", 1)[1]
        else:
            candidate = (path.parent / target).resolve()
        if not candidate.exists():
            errors.append(f"Missing import: {path.relative_to(ROOT)} -> {target}")

# 2. Delimiter balance with a small string/comment-aware scanner.
def delimiter_error(text: str):
    pairs = {')': '(', ']': '[', '}': '{'}
    opens = set(pairs.values())
    stack: list[tuple[str, int]] = []
    i = 0
    line = 1
    state = 'code'
    quote = ''
    triple = False
    while i < len(text):
        c = text[i]
        n = text[i + 1] if i + 1 < len(text) else ''
        if c == '\n': line += 1
        if state == 'line_comment':
            if c == '\n': state = 'code'
            i += 1; continue
        if state == 'block_comment':
            if c == '*' and n == '/': state = 'code'; i += 2; continue
            i += 1; continue
        if state == 'string':
            if c == '\\': i += 2; continue
            if triple:
                if text[i:i+3] == quote * 3: state='code'; i += 3; continue
            elif c == quote:
                state='code'; i += 1; continue
            i += 1; continue
        if c == '/' and n == '/': state='line_comment'; i += 2; continue
        if c == '/' and n == '*': state='block_comment'; i += 2; continue
        if c in "'\"":
            quote=c; triple=text[i:i+3] == c*3; state='string'; i += 3 if triple else 1; continue
        if c in opens: stack.append((c,line))
        elif c in pairs:
            if not stack or stack[-1][0] != pairs[c]: return f"line {line}: unmatched {c}"
            stack.pop()
        i += 1
    if stack: return f"line {stack[-1][1]}: unclosed {stack[-1][0]}"
    return None

for path in LIB.rglob("*.dart"):
    err = delimiter_error(path.read_text(encoding="utf-8", errors="ignore"))
    if err: errors.append(f"Delimiter: {path.relative_to(ROOT)}: {err}")

# 3. No stale original remote host.
for path in LIB.rglob("*.dart"):
    text=path.read_text(encoding="utf-8",errors="ignore").lower()
    if 'demo.dartcrm.net' in text or '/api/api/' in text:
        errors.append(f"Stale legacy host/path: {path.relative_to(ROOT)}")

# 4. All literal BASE_URL legacy calls must have a compatibility switch case.
adapter=(LIB/'core/api/legacy_api_adapter.dart').read_text(encoding='utf-8',errors='ignore')
cases=set(re.findall(r"case\s+'([^']+)'",adapter))
legacy=set()
for path in LIB.rglob('*.dart'):
    text=path.read_text(encoding='utf-8',errors='ignore')
    legacy.update(m.group(1) for m in re.finditer(r"\$BASE_URL/([A-Za-z0-9_]+)",text))
for endpoint in sorted(legacy,key=str.lower):
    if endpoint.lower() not in cases:
        errors.append(f"Unmapped legacy endpoint: {endpoint}")

if errors:
    print("Static checks FAILED")
    for error in errors: print(" -",error)
    sys.exit(1)
print(f"Static checks OK: {len(list(LIB.rglob('*.dart')))} Dart files; {len(legacy)} legacy endpoint literals mapped")
