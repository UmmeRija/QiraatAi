from fastapi import FastAPI, Depends, File, UploadFile, HTTPException, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
import json
import httpx
from datetime import datetime, timedelta
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
from jose import JWTError, jwt
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

# Load environment variables from .env and override existing values.
load_dotenv(override=True)

EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS")
EMAIL_APP_PASSWORD = os.getenv("EMAIL_APP_PASSWORD")
DEBUG_MODE = os.getenv("DEBUG_MODE", "false").lower() == "true"
SECRET_KEY = os.getenv("SECRET_KEY", "qiraat_ai_super_secret_key_123")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))

from database import SessionLocal, QuranWord, SurahInfo, UserSession, TanzilText, User, OTP, PasswordReset, KanzulImanCache, SurahInfoExtended, init_db
from models.schemas import (
    RecitationResponse,
    SurahItem,
    QuranWordItem,
    SessionCreate,
    SessionRead,
    WordAnalysis,
    AyahAnalysis,
    UserCreate,
    UserRead,
    LoginRequest,
    Token,
    LoginResponse,
    OTPVerifyRequest,
    OTPVerifyResponse,
    OTPResendRequest,
    OTPResendResponse,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    ResetPasswordRequest,
    ResetPasswordResponse,
    GoogleVerifyRequest,
    KanzulImanResponse,
    AyahTranslation,
    SurahInfoResponse,
)
from services.asr_service import transcribe_audio, get_pipeline
from services.compare_service import compare_words, compare_ayah_text
from services.tanzil_service import store_tanzil_in_db, get_surah_text
from services.audio_reference_service import compute_pronunciation_score
from routers.islamic_guide import router as islamic_guide_router

from passlib.hash import pbkdf2_sha256

# Password hashing

def generate_otp():
    """Generate a 6-digit OTP."""
    return ''.join([str(secrets.randbelow(10)) for _ in range(6)])

def send_otp_email(email: str, otp: str):
    """Send OTP via Gmail SMTP."""
    if not EMAIL_ADDRESS or not EMAIL_APP_PASSWORD:
        raise HTTPException(status_code=500, detail="Email configuration missing")

    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = email
    msg['Subject'] = "Your QiraatAI Login OTP"

    body = f"""
    Hello!

    Your One-Time Password (OTP) for QiraatAI login is: {otp}

    This OTP will expire in 5 minutes.

    If you didn't request this, please ignore this email.

    Best regards,
    QiraatAI Team
    """
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=10)
        server.ehlo()
        server.login(EMAIL_ADDRESS, EMAIL_APP_PASSWORD)
        server.sendmail(EMAIL_ADDRESS, email, msg.as_string())
    except smtplib.SMTPAuthenticationError as e:
        raise HTTPException(status_code=500, detail=f"SMTP auth failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {e}")
    finally:
        try:
            server.quit()
        except Exception:
            pass

def create_temp_token(user_id: int):
    """Create a temporary token for 2FA flow."""
    return f"temp_token_user_{user_id}_{secrets.token_hex(16)}"


def parse_temp_token(temp_token: str) -> int:
    """Parse the user_id from a temporary token."""
    try:
        parts = temp_token.split('_')
        if len(parts) < 4 or parts[0] != 'temp' or parts[1] != 'token' or parts[2] != 'user':
            raise ValueError("Invalid temp token")
        return int(parts[3])
    except (ValueError, IndexError):
        raise HTTPException(status_code=400, detail="Invalid temporary token")


def get_password_hash(password):
    return pbkdf2_sha256.hash(password)

def verify_password(plain_password, hashed_password):
    if isinstance(hashed_password, str) and hashed_password.startswith("$pbkdf2-sha256$"):
        return pbkdf2_sha256.verify(plain_password, hashed_password)
    return plain_password == hashed_password

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> int:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        return int(user_id)
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# Dependency to get user from token
def get_current_user_id(request: Request):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authentication required.")
    token = auth_header.split(" ")[1]
    return decode_access_token(token)


# ── App Setup ────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="QiraatAI API",
    description="Quran Recitation Analysis — Tarteel AI + Tanzil + EveryAyah",
    version="2.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Islamic Guide router
app.include_router(islamic_guide_router)


# â”€â”€ Startup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@app.on_event("startup")
async def startup_event():
    print("=" * 60)
    print("  QiraatAI Backend v2.1 Starting...")
    print("  [Tarteel AI ASR + Tanzil + EveryAyah]")
    print("=" * 60)
    init_db()
    try:
        store_tanzil_in_db()
        print("[Startup] Tanzil reference text ready.")
    except Exception as e:
        print(f"[Startup] Tanzil setup warning: {e}")
    get_pipeline()
    print("[Server] Ready to receive recitations!")
    print("=" * 60)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  ENDPOINTS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

@app.get("/", tags=["Health"])
def home():
    return {
        "app": "QiraatAI",
        "version": "2.1.0",
        "engine": "Tarteel AI (whisper-base-ar-quran)",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/api/v1/surahs", response_model=List[SurahItem], tags=["Quran Data"])
def get_surahs(db: Session = Depends(get_db)):
    surahs = db.query(SurahInfo).order_by(SurahInfo.surah_no).all()
    if not surahs:
        raise HTTPException(status_code=404, detail="Surah metadata nahi mili.")
    return surahs


@app.get("/api/v1/surah/{surah_id}", tags=["Quran Data"])
def get_surah_words(surah_id: int, db: Session = Depends(get_db)):
    if surah_id < 1 or surah_id > 114:
        raise HTTPException(status_code=400, detail="Sirf Surah 1-114 available hain.")

    words = (
        db.query(QuranWord)
        .filter(QuranWord.surah_no == surah_id)
        .order_by(QuranWord.ayah_no, QuranWord.word_position)
        .all()
    )
    if not words:
        raise HTTPException(status_code=404, detail=f"Surah {surah_id} database mein nahi mili.")

    ayahs = {}
    for w in words:
        if w.ayah_no not in ayahs:
            ayahs[w.ayah_no] = []
        ayahs[w.ayah_no].append({"word": w.word_arabic, "position": w.word_position})

    return {"surah_id": surah_id, "total_words": len(words), "ayahs": ayahs}


# ── AUTH ENDPOINTS ───────────────────────────────────────────────────────────

@app.post("/api/v1/auth/signup", response_model=Token, tags=["Auth"])
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="This email address is already registered.")

    # Create new user
    hashed_pass = get_password_hash(user_data.password)
    new_user = User(
        full_name=user_data.full_name,
        email=user_data.email,
        hashed_password=hashed_pass
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Generate token
    token = create_access_token({"user_id": new_user.id})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": new_user
    }


@app.post("/api/v1/auth/login", response_model=LoginResponse, tags=["Auth"])
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password. Please try again.")

    # Generate OTP
    otp_code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    # Create temp token for 2FA flow
    temp_token = create_temp_token(user.id)

    # Save OTP to database
    otp_entry = OTP(
        user_id=user.id,
        otp_code=otp_code,
        expires_at=expires_at,
        is_used=False
    )
    db.add(otp_entry)
    db.commit()

    # Send OTP via email
    try:
        send_otp_email(user.email, otp_code)
        print(f"[OTP] Sent to {user.email}: {otp_code}")  # For debugging
    except Exception as e:
        print(f"[OTP] Email failed: {e}")
        # For development: return OTP in response if email fails
        if DEBUG_MODE:
            return LoginResponse(
                requires_2fa=True,
                temp_token=temp_token,
                user=user,
                debug_otp=otp_code  # Only in debug mode
            )
        else:
            db.delete(otp_entry)
            db.commit()
            raise HTTPException(status_code=500, detail="Failed to send OTP email")

    # Return temp token for 2FA
    return LoginResponse(
        requires_2fa=True,
        temp_token=temp_token,
        user=user
    )


@app.post("/api/v1/auth/verify-otp", response_model=OTPVerifyResponse, tags=["Auth"])
def verify_otp(verify_data: OTPVerifyRequest, db: Session = Depends(get_db)):
    user_id = parse_temp_token(verify_data.temp_token)

    # Find valid OTP for this user
    otp_entry = db.query(OTP).filter(
        OTP.user_id == user_id,
        OTP.otp_code == verify_data.otp_code,
        OTP.is_used == False,
        OTP.expires_at > datetime.utcnow()
    ).first()

    if not otp_entry:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    # Mark OTP as used
    otp_entry.is_used = True
    db.commit()

    # Get user
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Generate final JWT token
    token = create_access_token({"user_id": user.id})
    return OTPVerifyResponse(
        access_token=token,
        token_type="bearer",
        user=user
    )


@app.post("/api/v1/auth/google/verify", response_model=Token, tags=["Auth"])
def google_verify(request: GoogleVerifyRequest, db: Session = Depends(get_db)):
    if not request.google_id_token:
        raise HTTPException(status_code=400, detail="Missing Google ID token")

    if not GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Google client ID is not configured")

    try:
        idinfo = id_token.verify_oauth2_token(
            request.google_id_token,
            google_requests.Request(),
            GOOGLE_CLIENT_ID,
        )
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=f"Invalid Google token: {exc}")

    email = idinfo.get("email")
    google_user_id = idinfo.get("sub")
    full_name = idinfo.get("name")
    avatar_url = idinfo.get("picture")

    if not email or not google_user_id:
        raise HTTPException(status_code=400, detail="Google token did not contain required user info")

    user = db.query(User).filter(
        (User.google_id == google_user_id) | (User.email == email)
    ).first()

    if user:
        user.google_id = google_user_id
        user.full_name = full_name or user.full_name
        user.email = email
        user.avatar_url = avatar_url
        user.provider = "google"
        db.commit()
        db.refresh(user)
    else:
        user = User(
            full_name=full_name or email.split("@")[0],
            email=email,
            hashed_password=None,
            google_id=google_user_id,
            avatar_url=avatar_url,
            provider="google",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token({"user_id": user.id})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user,
    }


@app.post("/api/v1/auth/resend-otp", response_model=OTPResendResponse, tags=["Auth"])
def resend_otp(resend_data: OTPResendRequest, db: Session = Depends(get_db)):
    user_id = parse_temp_token(resend_data.temp_token)

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    otp_code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=5)
    otp_entry = OTP(
        user_id=user.id,
        otp_code=otp_code,
        expires_at=expires_at,
        is_used=False
    )
    db.add(otp_entry)
    db.commit()

    try:
        send_otp_email(user.email, otp_code)
    except Exception as e:
        db.delete(otp_entry)
        db.commit()
        raise HTTPException(status_code=500, detail=f"Failed to resend OTP email: {str(e)}")

    return OTPResendResponse(message="OTP resent successfully")


@app.post("/api/v1/auth/logout", tags=["Auth"])
def logout(request: Request):
    """Logout endpoint - client should clear local session"""
    # In a stateless JWT system, logout is handled client-side
    # by removing the token from local storage
    return {"message": "Logged out successfully"}


@app.post("/api/v1/auth/forgot-password", response_model=ForgotPasswordResponse, tags=["Auth"])
def forgot_password(request: ForgotPasswordRequest, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        # For security, don't reveal if email exists
        return ForgotPasswordResponse(message="If the email exists, a reset code has been sent.")

    # Generate 6-digit OTP
    otp_code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=15)

    # Save to password_resets table
    reset_entry = PasswordReset(
        user_id=user.id,
        otp_code=otp_code,
        expires_at=expires_at,
        is_used=False
    )
    db.add(reset_entry)
    db.commit()

    # Send email
    try:
        send_reset_email(user.email, otp_code)
        print(f"[Password Reset] Sent to {user.email}: {otp_code}")  # For debugging
    except Exception as e:
        print(f"[Password Reset] Email failed: {e}")
        db.delete(reset_entry)
        db.commit()
        raise HTTPException(status_code=500, detail="Failed to send reset email")

    return ForgotPasswordResponse(message="If the email exists, a reset code has been sent.")


@app.post("/api/v1/auth/reset-password", response_model=ResetPasswordResponse, tags=["Auth"])
def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    # Find user by email
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or reset code")

    # Find valid reset entry
    reset_entry = db.query(PasswordReset).filter(
        PasswordReset.user_id == user.id,
        PasswordReset.otp_code == request.otp_code,
        PasswordReset.is_used == False,
        PasswordReset.expires_at > datetime.utcnow()
    ).first()

    if not reset_entry:
        raise HTTPException(status_code=400, detail="Invalid or expired reset code")

    # Hash new password
    hashed_password = get_password_hash(request.new_password)

    # Update user's password
    user.hashed_password = hashed_password
    reset_entry.is_used = True
    db.commit()

    return ResetPasswordResponse(message="Password reset successfully")


def send_reset_email(email: str, otp: str):
    """Send password reset OTP via Gmail SMTP."""
    if not EMAIL_ADDRESS or not EMAIL_APP_PASSWORD:
        raise HTTPException(status_code=500, detail="Email configuration missing")

    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = email
    msg['Subject'] = "QiraatAI Password Reset Code"

    body = f"""
    Hello!

    Your password reset code for QiraatAI is: {otp}

    This code will expire in 15 minutes.

    If you didn't request this password reset, please ignore this email.

    Best regards,
    QiraatAI Team
    """
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=10)
        server.ehlo()
        server.login(EMAIL_ADDRESS, EMAIL_APP_PASSWORD)
        server.sendmail(EMAIL_ADDRESS, email, msg.as_string())
    except smtplib.SMTPAuthenticationError as e:
        raise HTTPException(status_code=500, detail=f"SMTP auth failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {e}")
    finally:
        try:
            server.quit()
        except Exception:
            pass


# â”€â”€ MAIN ENDPOINT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@app.post("/api/v1/analyze-recitation", response_model=RecitationResponse, tags=["Analysis"])
async def analyze_recitation(
    surah_id: int = Form(...),
    ayah_no: Optional[int] = Form(None),
    start_ayah: Optional[int] = Form(None),
    end_ayah: Optional[int] = Form(None),
    include_pronunciation: Optional[bool] = Form(False),
    save_session: Optional[bool] = Form(True),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """
    Main Endpoint â€” Flutter app audio bhejti hai, word-by-word analysis wapis aata hai.

    KEY FIX (v2.1):
    - ayah_no=1 bhejne par sirf ayah 1 nahi, PURI SURAH check hoti hai
    - Flutter ko ab start_ayah + end_ayah dono dene ki zaroorat nahi
    - Agar sirf ayah_no bheja toh bhi poori surah ka context milta hai
    """
    if surah_id < 1 or surah_id > 114:
        raise HTTPException(status_code=400, detail="Sirf Surah 1-114 available hain.")

    # â”€â”€ Range Resolution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    # Flutter sirf ayah_no=1 bhejta hai â€” hum isko surah ki last ayah tak extend karte hain
    # Agar Flutter ne explicit start+end diya toh woh use karo

    if start_ayah is None and ayah_no is not None:
        start_ayah = ayah_no

    # â­  KEY FIX: Agar end_ayah nahi diya â€” puri surah lo
    if end_ayah is None:
        # DB se is surah ki last ayah number nikaalo
        last_word = (
            db.query(QuranWord)
            .filter(QuranWord.surah_no == surah_id, QuranWord.ayah_no > 0)
            .order_by(QuranWord.ayah_no.desc())
            .first()
        )
        end_ayah = last_word.ayah_no if last_word else (start_ayah or 7)
        print(f"[Route] end_ayah not provided â€” using surah last ayah: {end_ayah}")

    if start_ayah is None:
        start_ayah = 1

    print(f"[Route] Surah {surah_id}, Ayaat {start_ayah}â€“{end_ayah}")

    # â”€â”€ DB se correct words nikaalo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    # Ayah 0 = Bismillah/Intro â€” start_ayah==1 ke liye include karo
    fetch_start = 0 if start_ayah == 1 else start_ayah

    db_words = (
        db.query(QuranWord)
        .filter(
            QuranWord.surah_no == surah_id,
            QuranWord.ayah_no >= fetch_start,
            QuranWord.ayah_no <= end_ayah,
        )
        .order_by(QuranWord.ayah_no, QuranWord.word_position)
        .all()
    )

    if not db_words:
        raise HTTPException(
            status_code=404,
            detail=f"Surah {surah_id} ayaat {start_ayah}-{end_ayah} database mein nahi mili."
        )

    correct_words = [w.word_arabic for w in db_words]
    correct_text = " ".join(correct_words)
    intro_word_count = len([w for w in db_words if w.ayah_no == 0])

    print(f"[Route] Total correct words loaded: {len(correct_words)} (intro: {intro_word_count})")

    # â”€â”€ Audio Save â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    ext = os.path.splitext(file.filename or "audio.wav")[1] or ".wav"
    temp_filename = f"temp_{uuid.uuid4().hex}{ext}"

    try:
        with open(temp_filename, "wb") as buffer:
            buffer.write(await file.read())

        # â”€â”€ Step 1: ASR Transcription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        print(f"[ASR] Transcribing Surah {surah_id} ({start_ayah}-{end_ayah})...")
        transcribed_text = transcribe_audio(temp_filename)
        print(f"[ASR] Result: '{transcribed_text[:100]}...'")

        if not transcribed_text:
            # ASR ne kuch nahi pakda â€” empty result handle karo
            print("[ASR] WARNING: Empty transcription!")
            return RecitationResponse(
                status="error",
                surah_id=surah_id,
                start_ayah=start_ayah,
                end_ayah=end_ayah,
                accuracy=0.0,
                transcribed_text="",
                original_text=correct_text,
                word_analysis=[
                    WordAnalysis(
                        correct_word=w,
                        user_word=None,
                        status="missing",
                        position=i + 1,
                    )
                    for i, w in enumerate(correct_words)
                ],
                pronunciation_score=None,
                ayah_analysis=None,
            )

        user_words = transcribed_text.split()

        # â”€â”€ Step 2: Word-by-Word Comparison â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        word_analysis, accuracy = compare_words(
            correct_words,
            user_words,
            intro_word_count=intro_word_count,
        )
        print(f"[Compare] Accuracy: {accuracy}% ({len(user_words)} recited vs {len(correct_words)} expected)")

        # â”€â”€ Step 3: Ayah-level Analysis â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        ayah_analysis_list = []
        tanzil_texts = get_surah_text(surah_id, start_ayah, end_ayah, db)

        if tanzil_texts:
            for ayah_num, ref_text in tanzil_texts.items():
                ayah_result = compare_ayah_text(ref_text, transcribed_text)

                ayah_pron_score = None
                if include_pronunciation:
                    try:
                        pron_result = compute_pronunciation_score(temp_filename, surah_id, ayah_num)
                        ayah_pron_score = pron_result.get("score")
                    except Exception as e:
                        print(f"[Pronunciation] Error for {surah_id}:{ayah_num}: {e}")

                ayah_analysis_list.append(AyahAnalysis(
                    ayah_no=ayah_num,
                    text_accuracy=ayah_result["accuracy"],
                    pronunciation_score=ayah_pron_score,
                    missing_words=ayah_result["missing_words"],
                    incorrect_words=ayah_result["incorrect_words"],
                ))

        # â”€â”€ Step 4: Overall Pronunciation Score â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        overall_pron_score = None
        if include_pronunciation:
            try:
                pron = compute_pronunciation_score(temp_filename, surah_id, start_ayah)
                overall_pron_score = pron.get("score")
            except Exception as e:
                print(f"[Pronunciation] Overall error: {e}")

        # ── Step 5: Session Save ─────────────────────────────────────────────
        if save_session:
            new_session = UserSession(
                user_id=user_id,
                surah_id=surah_id,
                accuracy_score=accuracy / 100.0,
                recited_text=transcribed_text,
                timestamp=datetime.utcnow(),
            )
            db.add(new_session)
            db.commit()

        return RecitationResponse(
            status="success",
            surah_id=surah_id,
            start_ayah=start_ayah,
            end_ayah=end_ayah,
            accuracy=accuracy,
            transcribed_text=transcribed_text,
            original_text=correct_text,
            word_analysis=word_analysis,
            pronunciation_score=overall_pron_score,
            ayah_analysis=ayah_analysis_list,
        )

    except Exception as e:
        print(f"[Analyze] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        if os.path.exists(temp_filename):
            os.remove(temp_filename)


# â”€â”€ Session History â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@app.get("/api/v1/sessions", response_model=List[SessionRead], tags=["History"])
def get_sessions(limit: int = 20, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    results = (
        db.query(UserSession, SurahInfo.name_english)
        .outerjoin(SurahInfo, UserSession.surah_id == SurahInfo.surah_no)
        .filter(UserSession.user_id == user_id)
        .order_by(UserSession.timestamp.desc())
        .limit(limit)
        .all()
    )
    
    sessions = []
    for s, name in results:
        s.surah_name = name or f"Surah {s.surah_id}"
        sessions.append(s)
    return sessions


@app.post("/api/v1/sessions", response_model=SessionRead, tags=["History"])
def save_session(session_data: SessionCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    session = UserSession(
        user_id=user_id,
        surah_id=session_data.surah_id,
        accuracy_score=session_data.accuracy_score,
        recited_text=session_data.recited_text,
        timestamp=datetime.utcnow(),
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@app.delete("/api/v1/sessions/{session_id}", tags=["History"])
def delete_session(session_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    session = db.query(UserSession).filter(UserSession.id == session_id, UserSession.user_id == user_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session nahi mili.")
    db.delete(session)
    db.commit()
    return {"message": f"Session {session_id} delete ho gayi."}


@app.get("/api/v1/stats", tags=["History"])
def get_stats(db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    sessions = db.query(UserSession).filter(UserSession.user_id == user_id).order_by(UserSession.timestamp.desc()).all()
    
    if not sessions:
        return {
            "total_sessions": 0,
            "average_accuracy": 0,
            "best_accuracy": 0,
            "streak": 0,
            "last_session": None,
            "weekly_progress": [0] * 7,
            "total_words": 0,
            "total_surahs": 0,
            "velocity_data": []
        }

    scores = [s.accuracy_score for s in sessions]
    
    # Calculate Streak
    streak = 0
    if sessions:
        # Get unique dates in descending order
        unique_dates = sorted(list(set(s.timestamp.date() for s in sessions)), reverse=True)
        
        if unique_dates:
            today = datetime.utcnow().date()
            yesterday = today - timedelta(days=1)
            
            # A streak is active if the latest session was today or yesterday
            if unique_dates[0] == today or unique_dates[0] == yesterday:
                streak = 1
                for i in range(len(unique_dates) - 1):
                    # Check if the next date is exactly one day before the current date
                    if (unique_dates[i] - unique_dates[i+1]).days == 1:
                        streak += 1
                    else:
                        break
            else:
                streak = 0

    # Last Session details
    last_s = sessions[0]
    surah = db.query(SurahInfo).filter(SurahInfo.surah_no == last_s.surah_id).first()
    last_session_data = {
        "surah_name": surah.name_english if surah else f"Surah {last_s.surah_id}",
        "surah_id": last_s.surah_id,
        "accuracy": last_s.accuracy_score,
        "timestamp": last_s.timestamp.isoformat()
    }

    # Detailed Stats for Progress Screen
    total_words = 0
    for s in sessions:
        if s.recited_text:
            total_words += len(s.recited_text.split())

    unique_surahs = len(set(s.surah_id for s in sessions))

    weekly_progress = []
    velocity_data = []
    for i in range(6, -1, -1):
        target_date = today - timedelta(days=i)
        day_sessions = [s.accuracy_score for s in sessions if s.timestamp.date() == target_date]
        avg_acc = sum(day_sessions) / len(day_sessions) if day_sessions else 0
        weekly_progress.append(round(avg_acc, 2))
        velocity_data.append({
            "day": target_date.strftime("%a"),
            "accuracy": round(avg_acc, 2),
            "sessions": len(day_sessions)
        })

    return {
        "total_sessions": len(sessions),
        "total_words": total_words,
        "total_surahs": unique_surahs,
        "average_accuracy": round(sum(scores) / len(scores), 2),
        "best_accuracy": round(max(scores), 2),
        "streak": streak,
        "last_session": last_session_data,
        "weekly_progress": weekly_progress,
        "velocity_data": velocity_data,
    }


# ── Quran Translation Endpoints ───────────────────────────────────────────────
ALQURAN_API_BASE = "https://api.alquran.cloud/v1"


@app.get("/quran/surah/{surah_number}/kanzuliman", response_model=KanzulImanResponse, tags=["Quran Translation"])
async def get_kanzuliman_surah(surah_number: int, db: Session = Depends(get_db)):
    if surah_number < 1 or surah_number > 114:
        raise HTTPException(status_code=400, detail="Surah number must be between 1 and 114")

    # Check cache first
    cached_ayahs = db.query(KanzulImanCache).filter(
        KanzulImanCache.surah_number == surah_number
    ).order_by(KanzulImanCache.ayah_number).all()

    if cached_ayahs and len(cached_ayahs) > 0:
        ayahs = [
            AyahTranslation(
                surah_number=a.surah_number,
                ayah_number=a.ayah_number,
                arabic_text=a.arabic_text,
                urdu_translation=a.urdu_translation,
            )
            for a in cached_ayahs
        ]
        return KanzulImanResponse(surah_number=surah_number, ayahs=ayahs)

    # Fetch from AlQuran.cloud API
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{ALQURAN_API_BASE}/surah/{surah_number}/ur.kanzuliman")
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch from AlQuran.cloud")

        data = response.json()
        if data.get("code") != 200:
            raise HTTPException(status_code=404, detail="Surah not found in translation")

        api_ayahs = data.get("data", {}).get("ayahs", [])

    # Cache and prepare response
    ayahs = []
    for ayah in api_ayahs:
        arabic = ayah.get("text", "")
        urdu = ayah.get("translation", "")
        ayah_num = ayah.get("numberInSurah", 0)

        # Cache to database
        cache_entry = KanzulImanCache(
            surah_number=surah_number,
            ayah_number=ayah_num,
            arabic_text=arabic,
            urdu_translation=urdu,
        )
        db.add(cache_entry)
        db.commit()

        ayahs.append(AyahTranslation(
            surah_number=surah_number,
            ayah_number=ayah_num,
            arabic_text=arabic,
            urdu_translation=urdu,
        ))

    return KanzulImanResponse(surah_number=surah_number, ayahs=ayahs)


@app.get("/quran/ayah/{surah_number}/{ayah_number}/kanzuliman", response_model=AyahTranslation, tags=["Quran Translation"])
async def get_kanzuliman_ayah(surah_number: int, ayah_number: int, db: Session = Depends(get_db)):
    if surah_number < 1 or surah_number > 114:
        raise HTTPException(status_code=400, detail="Surah number must be between 1 and 114")

    # Check cache first
    cached = db.query(KanzulImanCache).filter(
        KanzulImanCache.surah_number == surah_number,
        KanzulImanCache.ayah_number == ayah_number,
    ).first()

    if cached:
        return AyahTranslation(
            surah_number=cached.surah_number,
            ayah_number=cached.ayah_number,
            arabic_text=cached.arabic_text,
            urdu_translation=cached.urdu_translation,
        )

    # Fetch from API
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{ALQURAN_API_BASE}/surah/{surah_number}/ur.kanzuliman")
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch from AlQuran.cloud")

        data = response.json()
        api_ayahs = data.get("data", {}).get("ayahs", [])

    # Find the specific ayah
    for ayah in api_ayahs:
        if ayah.get("numberInSurah") == ayah_number:
            arabic = ayah.get("text", "")
            urdu = ayah.get("translation", "")

            # Cache it
            cache_entry = KanzulImanCache(
                surah_number=surah_number,
                ayah_number=ayah_number,
                arabic_text=arabic,
                urdu_translation=urdu,
            )
            db.add(cache_entry)
            db.commit()

            return AyahTranslation(
                surah_number=surah_number,
                ayah_number=ayah_number,
                arabic_text=arabic,
                urdu_translation=urdu,
            )

    raise HTTPException(status_code=404, detail="Ayah not found")


@app.get("/quran/surah/{surah_number}/info", response_model=SurahInfoResponse, tags=["Quran Info"])
async def get_surah_info(surah_number: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user_id)):
    if surah_number < 1 or surah_number > 114:
        raise HTTPException(status_code=400, detail="Surah number must be between 1 and 114")

    info = db.query(SurahInfoExtended).filter(
        SurahInfoExtended.surah_number == surah_number
    ).first()

    if not info:
        raise HTTPException(status_code=404, detail="Surah info not found")

    base_surah_info = db.query(SurahInfo).filter(SurahInfo.surah_no == surah_number).first()

    key_events = json.loads(info.key_events) if info.key_events else []
    key_themes = json.loads(info.key_themes) if info.key_themes else []

    return SurahInfoResponse(
        surah_number=info.surah_number,
        surah_name_arabic=info.surah_name_arabic or (base_surah_info.name_arabic if base_surah_info else ""),
        surah_name_urdu=info.surah_name_urdu or (base_surah_info.name_urdu if base_surah_info else ""),
        revelation_place=info.revelation_place,
        revelation_order=info.revelation_order,
        total_verses=info.total_verses or (base_surah_info.total_verses if base_surah_info else 0),
        shaane_nuzool_urdu=info.shaane_nuzool_urdu,
        shaane_nuzool_short=info.shaane_nuzool_short,
        key_events=key_events,
        key_themes=key_themes,
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

