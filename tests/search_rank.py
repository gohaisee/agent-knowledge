"""Mirror kb-search.sh ranking for tests. Returns note titles in final order."""
import os
import re
import sqlite3


STOP = {
    "the", "and", "for", "with", "this", "that", "have", "has", "you", "your", "can", "will", "would",
    "should", "make", "add", "fix", "please", "how", "what", "why", "does", "are", "was", "but", "not",
    "just", "also", "from", "into", "about", "when", "where", "which", "been", "being", "were", "they",
    "them", "then", "than", "some", "such", "only", "other", "more", "most", "very", "much", "like",
}


def tokenize(query: str) -> list[str]:
    q = query.lower()
    return [t for t in re.findall(r"[0-9a-zA-Z]+", q) if len(t) >= 3 and t not in STOP][:24]


def search_titles(db_path: str, query: str, size: int = 5) -> list[str]:
    toks = tokenize(query)
    if not toks:
        return []
    match = " OR ".join('"%s"' % t for t in toks)
    conn = sqlite3.connect(db_path)
    pool = max(size * 4, 12)
    try:
        rows = conn.execute(
            "SELECT title, category, severity, body, bm25(kb, 10.0, 6.0, 3.0, 1.0) AS rank "
            "FROM kb WHERE kb MATCH ? ORDER BY rank LIMIT ?",
            (match, pool),
        ).fetchall()
    except sqlite3.OperationalError:
        rows = []
    conn.close()

    def boost(row):
        title, cat, sev, body, rank = row
        bonus = 0.0
        if (sev or "").lower() == "hard":
            bonus += 1.5
        if (cat or "") in ("rules", "preferences", "playbooks"):
            bonus += 1.0
        if (cat or "") == "playbooks":
            bonus += 0.5
        return (rank - bonus, title)

    ranked = sorted(boost(r) for r in rows)[:size]
    return [title for _, title in ranked]


if __name__ == "__main__":
    import sys
    db = os.environ.get("KB_DB", "kb.db")
    q = " ".join(sys.argv[1:])
    for t in search_titles(db, q):
        print(t)
