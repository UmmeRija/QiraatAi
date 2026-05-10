import sqlite3
import re
from pathlib import Path


VALUES_FILE = Path(__file__).with_name("surah_values.sql")
DB_FILE = Path(__file__).with_name("data").joinpath("quran.db")


def _extract_values_block(raw_sql: str) -> str:
    text = raw_sql.strip()
    if not text:
        raise ValueError("surah_values.sql is empty.")

    lower = text.lower()
    insert_match = re.search(
        r"insert\s+(?:or\s+replace\s+)?into\s+surahs\b[\s\S]*?\bvalues\b",
        lower,
    )
    if insert_match:
        text = text[insert_match.end() :].strip()
        text = _take_until_first_statement_end(text)

    if text.endswith(";"):
        text = text[:-1].strip()

    # Remove full-line SQL comments.
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("--"):
            continue
        lines.append(line)
    text = "\n".join(lines).strip()

    # Common copy/paste variant from JSON-like escaped apostrophes.
    text = text.replace("\\'", "''")

    # Allow optional trailing comma after the last tuple.
    while text.endswith(","):
        text = text[:-1].rstrip()

    # If there is leading text before the first tuple, trim to first '('.
    first_paren = text.find("(")
    if first_paren > 0:
        text = text[first_paren:].lstrip()

    if not text.startswith("("):
        raise ValueError(
            "surah_values.sql must start with tuples like: (1, 'Al-Fatihah', ...)"
        )

    return _normalize_sql_string_quotes(text)


def _normalize_sql_string_quotes(text: str) -> str:
    """
    Fix unescaped apostrophes inside SQL single-quoted strings.
    Example: 'Al-A'raf' -> 'Al-A''raf'
    """
    out = []
    in_string = False
    i = 0

    while i < len(text):
        ch = text[i]

        if ch != "'":
            out.append(ch)
            i += 1
            continue

        if not in_string:
            in_string = True
            out.append(ch)
            i += 1
            continue

        # in_string and current char is apostrophe
        nxt = text[i + 1] if i + 1 < len(text) else ""

        # Proper escaped apostrophe ('') -> keep as-is
        if nxt == "'":
            out.append("''")
            i += 2
            continue

        # Valid closing apostrophe before tuple separators/whitespace
        if nxt in [",", ")", "\n", "\r", "\t", " "]:
            in_string = False
            out.append("'")
            i += 1
            continue

        # Otherwise treat as internal apostrophe and escape it.
        out.append("''")
        i += 1

    return "".join(out)


def _take_until_first_statement_end(text: str) -> str:
    """Take content up to first semicolon outside single-quoted strings."""
    in_string = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            nxt = text[i + 1] if i + 1 < len(text) else ""
            if in_string and nxt == "'":
                i += 2
                continue
            in_string = not in_string
            i += 1
            continue
        if ch == ";" and not in_string:
            return text[:i].strip()
        i += 1
    return text.strip()


def main() -> None:
    if not VALUES_FILE.exists():
        raise FileNotFoundError(
            f"Missing file: {VALUES_FILE}. Paste your full tuple list into this file."
        )

    raw_sql = VALUES_FILE.read_text(encoding="utf-8")
    values_sql = _extract_values_block(raw_sql)

    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()

    cur.execute("DELETE FROM surahs")
    try:
        cur.execute(
            """
            INSERT INTO surahs (
                surahNumber, name, urduName, type, revelationOrder, ayatCount,
                background, context, themes
            ) VALUES
            """
            + values_sql
        )
    except sqlite3.OperationalError as exc:
        raise sqlite3.OperationalError(
            f"{exc}. Check `surah_values.sql` for a missing quote/comma/parenthesis."
        ) from exc

    cur.execute(
        """
        INSERT INTO surah_info_extended (
            surah_number,
            surah_name_arabic,
            surah_name_urdu,
            revelation_place,
            revelation_order,
            total_verses,
            shaane_nuzool_urdu,
            shaane_nuzool_short,
            key_events,
            key_themes
        )
        SELECT
            s.surahNumber,
            COALESCE(si.name_arabic, 'سورہ ' || s.surahNumber),
            s.urduName,
            s.type,
            s.revelationOrder,
            s.ayatCount,
            s.background,
            s.context,
            '[]',
            s.themes
        FROM surahs s
        LEFT JOIN surah_info si ON si.surah_no = s.surahNumber
        ON CONFLICT(surah_number) DO UPDATE SET
            surah_name_arabic = excluded.surah_name_arabic,
            surah_name_urdu = excluded.surah_name_urdu,
            revelation_place = excluded.revelation_place,
            revelation_order = excluded.revelation_order,
            total_verses = excluded.total_verses,
            shaane_nuzool_urdu = excluded.shaane_nuzool_urdu,
            shaane_nuzool_short = excluded.shaane_nuzool_short,
            key_themes = excluded.key_themes
        """
    )

    conn.commit()
    total = cur.execute("SELECT COUNT(*) FROM surahs").fetchone()[0]
    conn.close()
    print(f"Imported successfully. Total surahs: {total}")


if __name__ == "__main__":
    main()
