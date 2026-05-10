import json
import sqlite3


def main() -> None:
    db = sqlite3.connect("data/quran.db")
    cursor = db.cursor()

    cursor.execute(
        """
        UPDATE surahs
        SET
            name = ?,
            urduName = ?,
            type = ?,
            revelationOrder = ?,
            ayatCount = ?,
            background = ?,
            context = ?,
            themes = ?
        WHERE surahNumber = 1
        """,
        (
            "Al-Fatihah",
            "الفاتحہ — کتابِ ہدایت کا افتتاح",
            "Makki",
            5,
            7,
            "یہ سورت اسلام کی پہلی مکمل سورت ہے جو نبی کریم صلی اللہ علیہ وسلم پر نازل ہوئی۔ ابتدائی مکی دور میں جب نماز فرض ہوئی تو یہ تعلیم دی گئی۔ حضرت علی رضی اللہ عنہ کی روایت کے مطابق یہ سورت مکہ میں دو بار نازل ہوئی - ایک بار مکی دور میں اور ایک بار مدنی دور میں۔ اسے \"ام القرآن\" اور \"سبع المثانی\" بھی کہا جاتا ہے۔",
            "سب سے پہلی مکمل سورت جو نماز کی بنیاد اور ہدایت کی دعا سکھاتی ہے۔",
            json.dumps(
                ["حمد و ثنا", "اللہ کی ربوبیت", "ہدایت کی دعا", "صراط مستقیم", "توحید"],
                ensure_ascii=False,
            ),
        ),
    )

    cursor.execute(
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
        WHERE s.surahNumber = 1
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

    db.commit()
    db.close()
    print("Surah 1 updated and synced successfully.")


if __name__ == "__main__":
    main()
