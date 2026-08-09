#!/usr/bin/env bash
# Validate kb/ notes: frontmatter, unique ids, slug match, min body. Exit 1 on errors.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"

command -v python3 >/dev/null 2>&1 || { echo "[kb-validate] need python3" >&2; exit 1; }

KB_DIR="$KB_ROOT/kb" python3 - <<'PY'
import glob, os, re, sys

KB = os.environ["KB_DIR"]
MIN_BODY = 80
CATEGORIES = {
    "rules", "preferences", "best-practices", "anti-patterns",
    "architecture", "business-logic", "errors", "code-reviews", "playbooks",
}

errors = []
ids = {}

for path in glob.glob(os.path.join(KB, "**", "*.md"), recursive=True):
    base = os.path.basename(path)
    if base.startswith("_"):
        continue
    rel = os.path.relpath(path, KB).replace("\\", "/")
    if rel.startswith("templates/"):
        continue

    slug = os.path.splitext(base)[0]
    try:
        text = open(path, encoding="utf-8").read()
    except OSError as e:
        errors.append(f"{rel}: cannot read ({e})")
        continue

    if not text.startswith("---"):
        errors.append(f"{rel}: missing frontmatter")
        continue

    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        errors.append(f"{rel}: frontmatter not closed with ---")
        continue

    fm_raw, body = m.group(1), m.group(2).strip()
    fm = {}
    for line in fm_raw.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()

    for key in ("id", "category"):
        if key not in fm:
            errors.append(f"{rel}: missing {key}")

    id_ = fm.get("id", "")
    cat = fm.get("category", "")
    if id_ in ids:
        errors.append(f"{rel}: duplicate id '{id_}' (also in {ids[id_]})")
    else:
        ids[id_] = rel

    if id_ != slug:
        errors.append(f"{rel}: id '{id_}' != filename slug '{slug}'")

    if cat and cat not in CATEGORIES:
        errors.append(f"{rel}: unknown category '{cat}'")

    top_folder = rel.split("/")[0]
    if cat and top_folder != "templates" and cat != top_folder and not rel.startswith("architecture/stubs/"):
        # stubs live under architecture/ but may use architecture category
        if top_folder == "architecture" and cat == "architecture":
            pass
        elif top_folder != cat:
            errors.append(f"{rel}: folder '{top_folder}' != category '{cat}'")

    if len(body) < MIN_BODY:
        errors.append(f"{rel}: body too short ({len(body)} chars, min {MIN_BODY})")

if errors:
    print("[kb-validate] failed:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"[kb-validate] ok — {len(ids)} notes")
PY
