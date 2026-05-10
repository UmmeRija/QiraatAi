"""Add Surah Fajr, Muzzammil, and Naba to special_surahs table."""
import sqlite3, os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "quran.db")
conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

new_surahs = [
    (89, "الفجر", "الفجر", "Al-Fajr", 30, "daily", "Morning", "فجر کی نماز کے بعد پڑھنے کی بڑی فضیلت ہے", 5),
    (73, "المزمل", "المزمل", "Al-Muzzammil", 20, "daily", "Anytime", "جو شخص تنگی کے وقت اسے پڑھے گا اللہ اس کی تنگی دور فرمائے گا", 6),
    (78, "النبأ", "النبأ", "An-Naba", 40, "daily", "After Asr", "اس سورت کی تلاوت سے علم اور معرفت میں اضافہ ہوتا ہے", 7),
]

for s in new_surahs:
    c.execute("""INSERT OR REPLACE INTO special_surahs 
        (surah_number, name_arabic, name_urdu, name_english, total_ayahs, category, recommended_time, fazilat_urdu, display_order) 
        VALUES (?,?,?,?,?,?,?,?,?)""", s)

conn.commit()
print(f"[Update] Added {len(new_surahs)} more surahs to the guide.")
conn.close()
