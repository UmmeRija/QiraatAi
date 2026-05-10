from database import SessionLocal, QuranWord
db = SessionLocal()
words = db.query(QuranWord).filter(QuranWord.surah_no == 1, QuranWord.ayah_no <= 1).order_by(QuranWord.ayah_no, QuranWord.word_position).all()
for w in words:
    print(f"Ayah {w.ayah_no}, Pos {w.word_position}: {w.word_arabic}")
db.close()
