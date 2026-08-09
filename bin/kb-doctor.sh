#!/usr/bin/env bash
# Knowledge base health report (READ-ONLY — changes nothing).
# Finds: near-duplicates (merge candidates), category skew, notes that are too
# short or too long, oldest entries. Run manually every so often:
#   .knowledge/bin/kb-doctor.sh            # report
#   .knowledge/bin/kb-doctor.sh --sim 0.5  # similarity threshold (default 0.6)
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_ROOT="${KB_ROOT:-$(cd "$SELF_DIR/.." && pwd)}"

SIM="0.6"
if [ "${1:-}" = "--sim" ] && [ -n "${2:-}" ]; then SIM="$2"; fi

command -v python3 >/dev/null 2>&1 || { echo "[kb-doctor] need python3" >&2; exit 1; }

KB_DIR="$KB_ROOT/kb" SIM="$SIM" python3 - <<'PY'
import os, re, glob

KB   = os.environ["KB_DIR"]
SIM  = float(os.environ.get("SIM", "0.6"))

STOP = set("""the and for with this that have has you your can will would should make add fix not are was
but from into about when where which been being were they them then than some such only other more
most very much like just also what how why does please could would about through between before after
service services because therefore however
""".split())

def parse(path):
    txt = open(path, encoding="utf-8").read()
    fm = {}
    body = txt
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", txt, re.S)
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1); fm[k.strip()] = v.strip()
        body = m.group(2)
    return fm, body

def toks(s):
    return {t for t in re.findall(r"[0-9a-zA-Z]+", s.lower())
            if len(t) >= 5 and t not in STOP}

notes = []
for path in glob.glob(os.path.join(KB, "**", "*.md"), recursive=True):
    base = os.path.basename(path)
    if base.startswith("_"):  # _TEMPLATE etc.
        continue
    fm, body = parse(path)
    rel = os.path.relpath(path, KB)
    notes.append({
        "rel": rel, "cat": rel.split(os.sep)[0],
        "created": fm.get("created", "?"),
        "len": len(body.strip()),
        "tok": toks(body),
    })

n = len(notes)
print(f"# kb-doctor — {n} notes\n")

from collections import Counter
cats = Counter(x["cat"] for x in notes)
print("## Categories")
for c, k in cats.most_common():
    print(f"  {k:3d}  {c}")
print()

# Near-duplicates (overlap = |A∩B| / min(|A|,|B|))
# Umbrella index notes overlap with everything on purpose — skip them for dedup.
UMBRELLA = ("architecture/services-map.md", "architecture/task-router.md")
print(f"## Near-duplicates (overlap ≥ {SIM:.2f}) — merge candidates")
pairs = []
for i in range(n):
    if notes[i]["rel"] in UMBRELLA: continue
    a = notes[i]["tok"]
    if len(a) < 5: continue
    for j in range(i + 1, n):
        if notes[j]["rel"] in UMBRELLA: continue
        b = notes[j]["tok"]
        if len(b) < 5: continue
        inter = len(a & b)
        if inter < 4: continue
        ov = inter / min(len(a), len(b))
        if ov >= SIM:
            pairs.append((ov, notes[i]["rel"], notes[j]["rel"]))
pairs.sort(reverse=True)
if pairs:
    for ov, x, y in pairs[:40]:
        print(f"  {ov:.2f}  {x}")
        print(f"        ↕ {y}")
else:
    print("  (no pairs above threshold — base looks clean)")
print(f"  total pairs: {len(pairs)}\n")

short = sorted([x for x in notes if x["len"] < 140], key=lambda x: x["len"])
long_ = sorted([x for x in notes if x["len"] > 2800], key=lambda x: -x["len"])
print(f"## Too short (<140 chars, {len(short)}) — low value or noise")
for x in short[:12]:
    print(f"  {x['len']:4d}  {x['rel']}")
print(f"\n## Too long (>2800 chars, {len(long_)}) — candidates to split")
for x in long_[:12]:
    print(f"  {x['len']:5d}  {x['rel']}")
print()

dated = sorted([x for x in notes if x["created"] != "?"], key=lambda x: x["created"])
print("## Oldest (created) — check if stale")
for x in dated[:10]:
    print(f"  {x['created']}  {x['rel']}")
PY
