from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


# ── Word-level analysis ──────────────────────────────────────────────────────
class WordAnalysis(BaseModel):
    correct_word: str  # Original word from Quran
    user_word: Optional[str] = None # What the user said
    status: str        # "match" | "incorrect" | "missing" | "extra"
    position: int


# ── Ayah-level analysis (NEW — Tanzil comparison) ────────────────────────────
class AyahAnalysis(BaseModel):
    ayah_no: int
    text_accuracy: float
    pronunciation_score: Optional[float] = None
    missing_words: List[str] = []
    incorrect_words: List[str] = []


# ── Full recitation analysis response ────────────────────────────────────────
class RecitationResponse(BaseModel):
    status: str
    surah_id: int
    start_ayah: Optional[int] = None
    end_ayah: Optional[int] = None
    accuracy: float
    transcribed_text: str
    original_text: str
    word_analysis: List[WordAnalysis]
    # New fields for enhanced analysis
    pronunciation_score: Optional[float] = None      # 0-100 from MFCC/DTW
    ayah_analysis: Optional[List[AyahAnalysis]] = None  # Per-ayah breakdown


# ── Surah list item ───────────────────────────────────────────────────────────
class SurahItem(BaseModel):
    surah_no: int
    name_arabic: str
    name_english: str
    name_urdu: str
    total_verses: int

    class Config:
        from_attributes = True


# ── Single word row ───────────────────────────────────────────────────────────
class QuranWordItem(BaseModel):
    id: int
    surah_no: int
    ayah_no: int
    word_arabic: str
    word_position: int

    class Config:
        from_attributes = True


# ── Session (history) ─────────────────────────────────────────────────────────
class SessionCreate(BaseModel):
    surah_id: int
    accuracy_score: float
    recited_text: str


class SessionRead(BaseModel):
    id: int
    surah_id: int
    surah_name: Optional[str] = "Surah"
    accuracy_score: float
    recited_text: str
    timestamp: datetime


    class Config:
        from_attributes = True


# ── AUTH SCHEMAS ─────────────────────────────────────────────────────────────
class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str

class UserRead(BaseModel):
    id: int
    full_name: str
    email: str
    avatar_url: Optional[str] = None
    provider: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserRead

class LoginResponse(BaseModel):
    """Response for login with 2FA - returns temp token instead of final JWT."""
    requires_2fa: bool
    temp_token: Optional[str] = None
    user: UserRead
    debug_otp: Optional[str] = None  # Only present in debug mode

class OTPVerifyRequest(BaseModel):
    temp_token: str
    otp_code: str

class OTPVerifyResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserRead

class OTPResendRequest(BaseModel):
    temp_token: str

class OTPResendResponse(BaseModel):
    message: str

class ForgotPasswordRequest(BaseModel):
    email: str

class ForgotPasswordResponse(BaseModel):
    message: str

class ResetPasswordRequest(BaseModel):
    email: str
    otp_code: str
    new_password: str

class ResetPasswordResponse(BaseModel):
    message: str

class GoogleVerifyRequest(BaseModel):
    google_id_token: str


# ── Kanzul Iman Translation ─────────────────────────────────────────────────────
class AyahTranslation(BaseModel):
    surah_number: int
    ayah_number: int
    arabic_text: str
    urdu_translation: str


class KanzulImanResponse(BaseModel):
    surah_number: int
    ayahs: List[AyahTranslation]


# ── Shaane Nuzool ───────────────────────────────────────────────────────────────
class SurahInfoResponse(BaseModel):
    surah_number: int
    surah_name_arabic: str
    surah_name_urdu: str
    revelation_place: str
    revelation_order: int
    total_verses: int
    shaane_nuzool_urdu: str
    shaane_nuzool_short: str
    key_events: List[str]
    key_themes: List[str]
