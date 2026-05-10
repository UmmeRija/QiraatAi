import json
from database import SessionLocal, SurahInfo, SurahInfoExtended, init_db

# Seed data for first 10 surahs (example)
surah_data = [
    {
        "surah_number": 1,
        "surah_name_arabic": "الفاتحة",
        "surah_name_urdu": "فاتحہ",
        "revelation_place": "Makki",
        "revelation_order": 1,
        "shaane_nuzool_urdu": "سورہ الفاتحہ قرآن کی پہلی سورت ہے، جو مکیہ ٹاپی میں منظر عام کے بعد جبریل علیہ السلام کی کIncoming کے بعد حضرت کرسم میں حضرت محمد صلی اللہ علیہ وسلم کے ذریعے نازل فرماۓ گئی۔ یہ سورت قرآن کے سب سے چھوٹے مختصر اور بنیادی دعاوں میں سے ایک ہے۔ اس کے تسہیر کے بارے میں پہلے سے ہی بت چکا ہوں گا، لیکن دوسرے دن اہم ہے۔ گھر لے ٹیکنالوجی کے نتیجے میں، یہ سورت ہر دعا، ہر عبادت اور ہر اہم موقع پر پڑھی جاتی ہے۔",
        "shaane_nuzool_short": "قرآن کی پہلی سورت، ہر دعا اور عبادت کا شروعات۔",
        "key_events": ["حضرت محمد صلی اللہ علیہ وسلم کی نبوت کے بعد پہلی بار نازل ہوئی"],
        "key_themes": ["اللہ کی تعقید", "دعا اور استغاثہ", "راستہ اور ہدایت"]
    },
    {
        "surah_number": 2,
        "surah_name_arabic": "البقرة",
        "surah_name_urdu": "بقرہ",
        "revelation_place": "Madani",
        "revelation_order": 87,
        "shaane_nuzool_urdu": "سورہ البقرہ قرآن کی طولانی سب سے بڑی سورت ہے، جو مدنی ٹاپی میں مدت سو سال تک کے دوران نازل ہوئی۔ اس نے عبادت، قانون، اور مسلمانوں کے لئے بنیادی اصولوں کو وضح کیا۔ اس کے نزول کے دوران مسلمانوں کو اپنے نئے قانونی نظام اور سماجی ڈھانچے کی ضرورت محسوس ہوئی تھی۔",
        "shaane_nuzool_short": "سب سے بڑی سورت، قانون اور عبادت کا مکتب۔",
        "key_events": ["مدین کی طرف منتقلی کے بعد نازل ہوئی", "جہاد اور سماجی قانونی اصولوں کی وضاحت"],
        "key_themes": ["قانون و شرع", "عبادت اور دین", "سماجی ارتقاء"]
    },
    {
        "surah_number": 3,
        "surah_name_arabic": "آل عمران",
        "surah_name_urdu": "آل عمران",
        "revelation_place": "Madani",
        "revelation_order": 89,
        "shaane_nuzool_urdu": "سورہ آل عمران مدنی ٹاپی میں نازل ہوئی۔ یہ حضرت محمد صلی اللہ علیہ وسلم کے بیٹے حضرت عمر فرمان کے بارے میں ہے، جنہوں نے کفر کیا تھا اور پھر موقع پر توبہ کر کے دین اپنایا۔ اس کے نزول کے دوران مسلمانوں کو اپنے گناہوں سے دوبارہ محبت اور توبہ کے بارے میں سکھ دیا گیا۔",
        "shaane_nuzool_short": "حضرت عمر فرمان کے بارے میں، توبہ اور محبت۔",
        "key_events": ["مدین میں نازل ہوئی", "حضرت عمر فرمان کی توبہ کی وضاحت"],
        "key_themes": ["توبہ اور مغفرہ", "پیار اور محبت", "خاندانی تعلقات"]
    },
    {
        "surah_number": 4,
        "surah_name_arabic": "النساء",
        "surah_name_urdu": "نساء",
        "revelation_place": "Madani",
        "revelation_order": 92,
        "shaane_nuzool_urdu": "سورہ النساء مدنی ٹاپی میں نازل ہوئی۔ یہ خواتین کے حقوق، گھر کی دعواوں، اور مسلمان خاندانوں کے لئے ہدایات پیش کرتی ہے۔ اس کے نزول کے دوران مسلمانوڐں کو اپنے گھروں اور خاندانی زندگی کو بہتر بنانے کی ضرورت محسوس ہوئی تھی۔",
        "shaane_nuzool_short": "خواتین کے حقوق اور گھر کی دعاوں۔",
        "key_events": ["مدین کے قریب نازل ہوئی", "خواتین کے حقوق کی وضاحت"],
        "key_themes": ["خواتین کے حقوق", "گھر کی دعاوا", "خاندانی چندگی"]
    },
    {
        "surah_number": 5,
        "surah_name_arabic": "المائدة",
        "surah_name_urdu": "مائدہ",
        "revelation_place": "Madani",
        "revelation_order": 112,
        "shaane_nuzool_urdu": "سورہ المائدہ مدنی ٹاپی میں نازل ہوئی۔ یہ سورت خیر صحت، جنگ، اور مسلمانوں کے لئے بنیادی اصولوں کو وضاحت کرتی ہے۔ اس کے نزول کے دوران مسلمانوں نے اپنے نئے دولت سے حلال کھانے اور جنگ کے اصولوں کو سمجھنے کی ضرورت محسوس کی۔",
        "shaane_nuzool_short": "جنگ اور حلال کھانے کے اصول، دولت کا استعمال۔",
        "key_events": ["مدین کے بعد نازل ہوئی", "جنگ اور دولت کے اصولوں کی وضاحت"],
        "key_themes": ["جنگ اور امن", "حلال کھانا", "دولت اور اخلاق"]
    },
    {
        "surah_number": 6,
        "surah_name_arabic": "الأنعام",
        "surah_name_urdu": "انعام",
        "revelation_place": "Makki",
        "revelation_order": 50,
        "shaane_nuzool_urdu": "سورہ الأنعام مکی ٹاپی میں نازل ہوئی۔ یہ قبائی لوگوں کے درمیان دین کی تبلیغ کے بارے میں ہے۔ اس کے نزول کے دوران قبائیوں نے اپنے دین سے بہتر دین کی وہ بات سمجھی جو قرآن پیش کرتا ہے۔",
        "shaane_nuzool_short": "قبائیوں کی تبلیغ، انویٹر کے بارے میں۔",
        "key_events": ["مکہ کے قریب نازل ہوئی", "قبائیوں کی تبلیغ کے دوران"],
        "key_themes": ["تبلیغ", "قبائی دین", "اللہ کی توحید"]
    },
    {
        "surah_number": 7,
        "surah_name_arabic": "الأعراف",
        "surah_name_urdu": "اعراف",
        "revelation_place": "Makki",
        "revelation_order": 51,
        "shaane_nuzool_urdu": "سورہ الأعراف مکی ٹاپی میں نازل ہوئی۔ یہ سورت جنت اور دوزخ کے بارے میں ہے، اور انسانیں قدرت اور عذاب کے بارے میں بتاتی ہے۔ اس کے نزول کے دوران مسلمانوڽ کو اپنے اعمال کے نتیجے میں جنت اور دوزخ کے بارے میں سکھ دیا گیا۔",
        "shaane_nuzool_short": "جنت اور دوزخ کے وصف، قدرت کا دعویٰ۔",
        "key_events": ["مکہ کے دوران نازل ہوئی", "قبائیوں کی تبلیغ کے دوران"],
        "key_themes": ["جنت اور دوزخ", "قدرت اور عذاب", "انسانی اخلاق"]
    },
    {
        "surah_number": 8,
        "surah_name_arabic": "الأنفال",
        "surah_name_urdu": "انفال",
        "revelation_place": "Madani",
        "revelation_order": 113,
        "shaane_nuzool_urdu": "سورہ الأنفال مدنی ٹاپی میں نازل ہوئی۔ یہ سورت حدیبیہ کی جنگ اور مسلمانوں کی جیت کے بارے میں ہے۔ اس کے نزول کے دوران مسلمانوڽ نے اپنی پہلی بڑی جیت اور اس کے بعد اللہ کی مدد سے جیتے ہوئے دیکھا۔",
        "shaane_nuzool_short": "حدیبیہ جنگ اور مسلمانوں کی پہلی بڑی جیت۔",
        "key_events": ["حدیبیہ جنگ کے بعد نازل ہوئی", "مسلمانوڽ کی پہلی عظیم جیت"],
        "key_themes": ["جنگ اور امن", "اللہ کی مدد", "یمان اور بقا"]
    },
    {
        "surah_number": 9,
        "surah_name_arabic": "التوبة",
        "surah_name_urdu": "توبہ",
        "revelation_place": "Madani",
        "revelation_order": 114,
        "shaane_nuzool_urdu": "سورہ التوبہ مدنی ٹاپی میں نازل ہوئی۔ یہ سورت کافر و قرطاس کے خلاف ہے اور مسلمانوڽ کو اپنے دین کے ساتھ دیگر قبائیوں کے ساتھ عداوا رواج دینے کی ہدایت دیتی ہے۔ اس کے نزول کے دوران مسلمانوڽ نے اپنے گناہوں سے دوبارہ توبہ اور صحیح راہ پر قدم رکھنے کی ضرورت محسوس کی۔",
        "shaane_nuzool_short": "کافر و قرطاس کے خلاف، توبہ اور عداوا۔",
        "key_events": ["مدین کے بعد نازل ہوئی", "کافر و قرطاس کے خلاف"],
        "key_themes": ["توبہ", "عداوا", "دین کی صحت"]
    },
    {
        "surah_number": 10,
        "surah_name_arabic": "يونس",
        "surah_name_urdu": "یونس",
        "revelation_place": "Makki",
        "revelation_order": 106,
        "shaane_nuzool_urdu": "سورہ یونس مکی ٹاپی میں نازل ہوئی۔ یہ سورت نبی یونس علیہ السلام کے بارے میں ہے، جنہوں نے اپنے لوگوں کو دین کا پیغام دینا تھا۔ اس کے نزول کے دوران مسلمانوڽ نے اپنے نبیوں اور ان کے دین کے بارے میں سکھ یافہ۔",
        "shaane_nuzool_short": "نبی یونس علیہ السلام اور ان کے دعوت کا بیان۔",
        "key_events": ["مکہ کے دوران نازل ہوئی", "قبائیوڽ کی تبلیغ کے دوران"],
        "key_themes": ["نبیوں کا دعوت", "یونس کا دعوت", "دین کی صحت"]
    }
]


def seed_surah_info():
    init_db()
    db = SessionLocal()

    for data in surah_data:
        existing = db.query(SurahInfoExtended).filter(
            SurahInfoExtended.surah_number == data["surah_number"]
        ).first()
        if not existing:
            base_info = db.query(SurahInfo).filter(
                SurahInfo.surah_no == data["surah_number"]
            ).first()
            entry = SurahInfoExtended(
                surah_number=data["surah_number"],
                surah_name_arabic=data["surah_name_arabic"],
                surah_name_urdu=data["surah_name_urdu"],
                revelation_place=data["revelation_place"],
                revelation_order=data["revelation_order"],
                total_verses=base_info.total_verses if base_info else None,
                shaane_nuzool_urdu=data["shaane_nuzool_urdu"],
                shaane_nuzool_short=data["shaane_nuzool_short"],
                key_events=json.dumps(data["key_events"]),
                key_themes=json.dumps(data["key_themes"]),
            )
            db.add(entry)

    db.commit()
    db.close()
    print("Surah info seeded successfully!")


if __name__ == "__main__":
    seed_surah_info()