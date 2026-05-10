"""Seed remaining Islamic Guide tables: duas, after_namaz_adhkar, juma_guide, special_surahs."""
import sqlite3, os

DB_PATH = os.path.join(os.path.dirname(__file__), "data", "quran.db")
conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

# 1. Seed DUAS
duas = [
    ("qunoot", "دعائے قنوت", "Dua-e-Qunoot",
     "اَللَّهُمَّ إِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ وَنَشْكُرُكَ وَلَا نَكْفُرُكَ وَنَخْلَعُ وَنَتْرُكُ مَنْ يَفْجُرُكَ۔ اَللَّهُمَّ إِيَّاكَ نَعْبُدُ وَلَكَ نُصَلِّي وَنَسْجُدُ وَإِلَيْكَ نَسْعَىٰ وَنَحْفِدُ وَنَرْجُو رَحْمَتَكَ وَنَخْشَىٰ عَذَابَكَ إِنَّ عَذَابَكَ بِالْكُفَّارِ مُلْحِقٌ",
     "اے اللہ! ہم تجھ سے مدد چاہتے ہیں اور تجھ سے معافی مانگتے ہیں...",
     "Allahumma inna nasta'inuka wa nastaghfiruka...",
     "qunoot", "نمازِ وتر کے تیسرے رکعت میں رکوع سے پہلے پڑھی جاتی ہے"),
    
    ("janaza_adult", "بالغ مرد و عورت کی دعا", "Dua for Adult (Janaza)",
     "اَللَّهُمَّ اغْفِرْ لِحَيِّنَا وَمَيِّتِنَا وَشَاهِدِنَا وَغَائِبِنَا وَصَغِيْرِنَا وَكَبِيْرِنَا وَذَكَرِنَا وَأُنْثَانَا۔ اَللَّهُمَّ مَنْ أَحْيَيْتَهُ مِنَّا فَأَحْيِهِ عَلَى الْإِسْلَامِ وَمَنْ تَوَفَّيْتَهُ مِنَّا فَتَوَفَّهُ عَلَى الْإِيْمَانِ",
     "اے اللہ! بخش دے ہمارے ہر زندہ کو اور ہمارے ہر فوت شدہ کو...",
     "Allahummaghfir li-hayyina wa mayyitina...",
     "janaza", None),

    ("janaza_boy", "نابالغ لڑکے کی دعا", "Dua for Minor Boy (Janaza)",
     "اَللَّهُمَّ اجْعَلْهُ لَنَا فَرَطًا وَّاجْعَلْهُ لَنَا أَجْرًا وَّذُخْرًا وَّاجْعَلْهُ لَنَا شَافِعًا وَّمُشَفَّعًا",
     "اے اللہ! اسے ہمارے لیے آگے جا کر انتظام کرنے والا بنا دے...",
     "Allahummaj'alhu lana faratan...",
     "janaza", None),

    ("janaza_girl", "نابالغ لڑکی کی دعا", "Dua for Minor Girl (Janaza)",
     "اَللَّهُمَّ اجْعَلْهَا لَنَا فَرَطًا وَّاجْعَلْهَا لَنَا أَجْرًا وَّذُخْرًا وَّاجْعَلْهَا لَنَا شَافِعَةً وَّمُشَفَّعَةً",
     "اے اللہ! اسے ہمارے لیے آگے جا کر انتظام کرنے والی بنا دے...",
     "Allahummaj'alha lana faratan...",
     "janaza", None),
]

for d in duas:
    c.execute("""INSERT OR IGNORE INTO duas 
        (dua_key, title_urdu, title_english, arabic_text, urdu_translation, urdu_transliteration, category, notes) 
        VALUES (?,?,?,?,?,?,?,?)""", d)

# 2. Seed AFTER_NAMAZ_ADHKAR
adhkar = [
    (1, "tasbih", "آیت الکرسی", "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...", "اللہ کے سوا کوئی معبود نہیں وہ خود زندہ ہے اور دوسروں کو قائم رکھنے والا ہے...", 1, "ہر فرض نماز کے بعد پڑھنے کی بڑی فضیلت ہے", "all"),
    (2, "tasbih", "تسبیح فاطمہ (سبحان اللہ)", "سُبْحَانَ الله", "اللہ پاک ہے", 33, None, "all"),
    (3, "tasbih", "تسبیح فاطمہ (الحمد للہ)", "اَلْحَمْدُ لِلّٰہ", "تمام تعریفیں اللہ کے لیے ہیں", 33, None, "all"),
    (4, "tasbih", "تسبیح فاطمہ (اللہ اکبر)", "اَللهُ أَكْبَر", "اللہ سب سے بڑا ہے", 34, None, "all"),
]

for a in adhkar:
    c.execute("""INSERT OR IGNORE INTO after_namaz_adhkar 
        (adhkar_order, type, title_urdu, arabic_text, urdu_translation, repeat_count, notes, recommended_after) 
        VALUES (?,?,?,?,?,?,?,?)""", a)

# 3. Seed JUMA_GUIDE
juma = [
    (1, "غسل کرنا", "جمعہ کے دن غسل کرنا سنتِ مؤکدہ ہے", None, None, "sunnah"),
    (2, "صاف کپڑے پہننا", "صاف ستھرے کپڑے پہننا اور خوشبو لگانا", None, None, "sunnah"),
    (3, "سورۃ الکہف کی تلاوت", "جمعہ کے دن سورۃ الکہف پڑھنے سے پورے ہفتے کے لیے نور حاصل ہوتا ہے", None, None, "amal"),
    (4, "درود شریف کی کثرت", "جمعہ کے دن نبی کریم ﷺ پر کثرت سے درود بھیجنا", None, None, "amal"),
]

for j in juma:
    c.execute("""INSERT OR IGNORE INTO juma_guide 
        (item_order, title_urdu, description_urdu, arabic_text, urdu_translation, category) 
        VALUES (?,?,?,?,?,?)""", j)

# 4. Seed SPECIAL_SURAHS
surahs = [
    (18, "الكهف", "الکہف", "Al-Kahf", 110, "friday", "Friday", "جمعہ کے دن پڑھنے والے کے لیے دو جمعوں کے درمیان نور روشن ہو جاتا ہے", 1),
    (36, "يس", "یسین", "Ya-Sin", 83, "daily", "Anytime", "یسین قرآن کا دل ہے۔ جو اسے اللہ کی رضا کے لیے پڑھے گا اس کی بخشش ہو جائے گی", 2),
    (67, "الملك", "الملک", "Al-Mulk", 30, "night", "Before Sleep", "یہ سورت عذابِ قبر سے بچانے والی ہے", 3),
    (56, "الواقعة", "الواقعہ", "Al-Waqi'a", 96, "daily", "Evening", "جو شخص روزانہ رات کو سورہ واقعہ پڑھے گا اسے کبھی فاقہ نہیں ہوگا", 4),
]

for s in surahs:
    c.execute("""INSERT OR IGNORE INTO special_surahs 
        (surah_number, name_arabic, name_urdu, name_english, total_ayahs, category, recommended_time, fazilat_urdu, display_order) 
        VALUES (?,?,?,?,?,?,?,?,?)""", s)

conn.commit()
print(f"[Seed] Finished seeding all guide tables.")
conn.close()
