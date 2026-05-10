-- Sync `surahs` data into API table `surah_info_extended`
-- Run this against python/data/quran.db
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
    key_themes = excluded.key_themes;