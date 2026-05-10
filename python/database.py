from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./data/quran.db")

if DATABASE_URL.startswith("sqlite:///"):
    db_file = DATABASE_URL[len("sqlite:///"):]
    db_dir = os.path.dirname(db_file)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


# ── Table 1: Quran Words ────────────────────────────────────────────────────
class QuranWord(Base):
    __tablename__ = "quran_words"

    id            = Column(Integer, primary_key=True, index=True)
    surah_no      = Column(Integer, index=True)
    ayah_no       = Column(Integer)
    ruku_no       = Column(Integer, index=True)   # Added for portion selection
    page_no       = Column(Integer, index=True)   # Added for 15-line page concept
    line_no       = Column(Integer)               # Added for precise tracking
    word_arabic   = Column(String)
    word_position = Column(Integer)


# ── Table 2: Surah Info ─────────────────────────────────────────────────────
class SurahInfo(Base):
    __tablename__ = "surah_info"

    id             = Column(Integer, primary_key=True, index=True)
    surah_no       = Column(Integer, unique=True, index=True)
    name_arabic    = Column(String)
    name_english   = Column(String)
    name_urdu      = Column(String)
    total_verses   = Column(Integer)


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    full_name       = Column(String)
    email           = Column(String, unique=True, index=True)
    hashed_password = Column(String, nullable=True)
    google_id       = Column(String, unique=True, index=True, nullable=True)
    avatar_url      = Column(String, nullable=True)
    provider        = Column(String, default="local")
    created_at      = Column(DateTime, default=datetime.utcnow)


# ── Table 3: User Sessions (Recitation History) ─────────────────────────────
class UserSession(Base):
    __tablename__ = "user_sessions"

    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, index=True) # Linked to User.id
    surah_id       = Column(Integer, index=True)
    accuracy_score = Column(Float)
    recited_text   = Column(String)
    timestamp      = Column(DateTime, default=datetime.utcnow)


class TanzilText(Base):
    """Tanzil.net se download kiya gaya Uthmani Quran text (with full tashkeel)."""
    __tablename__ = "tanzil_text"

    id       = Column(Integer, primary_key=True, index=True)
    surah_no = Column(Integer, index=True)
    ayah_no  = Column(Integer)
    text     = Column(String)  # Full ayah text with tashkeel/harakat


class OTP(Base):
    """OTP table for Two-Factor Authentication."""
    __tablename__ = "otps"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, index=True)  # Foreign key to User.id
    otp_code    = Column(String, nullable=False)
    created_at  = Column(DateTime, default=datetime.utcnow)
    expires_at  = Column(DateTime, nullable=False)
    is_used     = Column(Boolean, default=False)


class PasswordReset(Base):
    """Password reset tokens."""
    __tablename__ = "password_resets"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, index=True)  # Foreign key to User.id
    otp_code    = Column(String, nullable=False)
    created_at  = Column(DateTime, default=datetime.utcnow)
    expires_at  = Column(DateTime, nullable=False)
    is_used     = Column(Boolean, default=False)


class KanzulImanCache(Base):
    """Cache for Kanzul Iman Urdu translation."""
    __tablename__ = "kanzuliman_cache"

    id               = Column(Integer, primary_key=True, index=True)
    surah_number     = Column(Integer, index=True)
    ayah_number      = Column(Integer)
    arabic_text      = Column(String)
    urdu_translation = Column(String)
    cached_at        = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        {"sqlite_autoincrement": True},
    )


class SurahInfoExtended(Base):
    """Extended surah information including Shaane Nuzool."""
    __tablename__ = "surah_info_extended"

    surah_number       = Column(Integer, primary_key=True)
    surah_name_arabic  = Column(String)
    surah_name_urdu    = Column(String)
    revelation_place   = Column(String)  # 'Makki' or 'Madani'
    revelation_order   = Column(Integer)
    total_verses       = Column(Integer)
    shaane_nuzool_urdu = Column(String)
    shaane_nuzool_short = Column(String)
    key_events         = Column(String)  # JSON array
    key_themes         = Column(String)  # JSON array


def init_db():
    """Database tables create karta hai agar na bani hon."""
    print("[Database] Initializing tables...")
    Base.metadata.create_all(bind=engine)

    # Ensure new user fields exist in case the SQLite users table already exists.
    inspector = inspect(engine)
    if 'users' in inspector.get_table_names():
        existing_columns = {col['name'] for col in inspector.get_columns('users')}
        with engine.begin() as conn:
            if 'google_id' not in existing_columns:
                conn.execute(text('ALTER TABLE users ADD COLUMN google_id VARCHAR'))
            if 'avatar_url' not in existing_columns:
                conn.execute(text('ALTER TABLE users ADD COLUMN avatar_url VARCHAR'))
            if 'provider' not in existing_columns:
                conn.execute(text('ALTER TABLE users ADD COLUMN provider VARCHAR DEFAULT "local"'))
            if 'hashed_password' not in existing_columns:
                conn.execute(text('ALTER TABLE users ADD COLUMN hashed_password VARCHAR'))

    if 'surah_info_extended' in inspector.get_table_names():
        surah_info_extended_columns = {
            col['name'] for col in inspector.get_columns('surah_info_extended')
        }
        with engine.begin() as conn:
            if 'total_verses' not in surah_info_extended_columns:
                conn.execute(
                    text('ALTER TABLE surah_info_extended ADD COLUMN total_verses INTEGER')
                )

    # ── Islamic Guide Tables ─────────────────────────────────────────────
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS namaz_steps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                step_number INTEGER NOT NULL,
                step_name_urdu TEXT NOT NULL,
                step_name_english TEXT NOT NULL,
                arabic_text TEXT,
                urdu_translation TEXT,
                urdu_transliteration TEXT,
                description_mard TEXT NOT NULL,
                description_aurat TEXT NOT NULL,
                has_difference BOOLEAN DEFAULT 0,
                difference_note TEXT,
                category TEXT
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS duas (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                dua_key TEXT UNIQUE NOT NULL,
                title_urdu TEXT NOT NULL,
                title_english TEXT NOT NULL,
                arabic_text TEXT NOT NULL,
                urdu_translation TEXT NOT NULL,
                urdu_transliteration TEXT,
                category TEXT NOT NULL,
                notes TEXT
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS after_namaz_adhkar (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                adhkar_order INTEGER NOT NULL,
                type TEXT NOT NULL,
                title_urdu TEXT NOT NULL,
                arabic_text TEXT NOT NULL,
                urdu_translation TEXT NOT NULL,
                repeat_count INTEGER DEFAULT 1,
                notes TEXT,
                recommended_after TEXT DEFAULT 'all'
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS juma_guide (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                item_order INTEGER NOT NULL,
                title_urdu TEXT NOT NULL,
                description_urdu TEXT NOT NULL,
                arabic_text TEXT,
                urdu_translation TEXT,
                category TEXT
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS special_surahs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                surah_number INTEGER UNIQUE NOT NULL,
                name_arabic TEXT NOT NULL,
                name_urdu TEXT NOT NULL,
                name_english TEXT NOT NULL,
                total_ayahs INTEGER NOT NULL,
                category TEXT NOT NULL,
                recommended_time TEXT,
                fazilat_urdu TEXT,
                display_order INTEGER DEFAULT 0
            )
        """))
    print("[Database] Islamic Guide tables ready.")
