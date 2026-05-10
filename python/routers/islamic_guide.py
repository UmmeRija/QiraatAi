"""
Islamic Guide Router — Namaz, Duas, Adhkar, Juma, Special Surahs, Manzil
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
import httpx

router = APIRouter(prefix="/islamic-guide", tags=["Islamic Guide"])

# Import database session from main app
from database import SessionLocal, KanzulImanCache
from datetime import datetime

ALQURAN_API_BASE = "https://api.alquran.cloud/v1"


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ══════════════════════════════════════════════════════════════════════════════
#  NAMAZ ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/namaz-steps")
def get_namaz_steps(gender: str = Query("mard", pattern="^(mard|aurat)$"), db: Session = Depends(get_db)):
    """Get all namaz steps sorted by step_number, with gender-specific descriptions."""
    result = db.execute(text("SELECT * FROM namaz_steps ORDER BY step_number")).mappings().all()
    if not result:
        raise HTTPException(status_code=404, detail="Namaz steps not found")

    steps = []
    for row in result:
        description = row["description_mard"] if gender == "mard" else row["description_aurat"]
        steps.append({
            "id": row["id"],
            "step_number": row["step_number"],
            "step_name_urdu": row["step_name_urdu"],
            "step_name_english": row["step_name_english"],
            "arabic_text": row["arabic_text"],
            "urdu_translation": row["urdu_translation"],
            "urdu_transliteration": row["urdu_transliteration"],
            "description": description,
            "has_difference": bool(row["has_difference"]),
            "difference_note": row["difference_note"],
            "category": row["category"],
        })
    return steps


# ══════════════════════════════════════════════════════════════════════════════
#  DUA ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/duas")
def get_duas(category: str = Query("all"), db: Session = Depends(get_db)):
    """Get duas filtered by category."""
    if category == "all":
        result = db.execute(text("SELECT * FROM duas ORDER BY id")).mappings().all()
    else:
        result = db.execute(
            text("SELECT * FROM duas WHERE category = :cat ORDER BY id"),
            {"cat": category}
        ).mappings().all()

    return [dict(row) for row in result]


@router.get("/dua/{dua_key}")
def get_dua(dua_key: str, db: Session = Depends(get_db)):
    """Get a single dua by key."""
    result = db.execute(
        text("SELECT * FROM duas WHERE dua_key = :key"),
        {"key": dua_key}
    ).mappings().first()

    if not result:
        raise HTTPException(status_code=404, detail=f"Dua '{dua_key}' not found")
    return dict(result)


# ══════════════════════════════════════════════════════════════════════════════
#  ADHKAR ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/after-namaz-adhkar")
def get_after_namaz_adhkar(after: str = Query("all"), db: Session = Depends(get_db)):
    """Get after-namaz adhkar filtered by recommended_after."""
    if after == "all":
        result = db.execute(
            text("SELECT * FROM after_namaz_adhkar ORDER BY adhkar_order")
        ).mappings().all()
    else:
        result = db.execute(
            text("""SELECT * FROM after_namaz_adhkar 
                    WHERE recommended_after = :after OR recommended_after = 'all' 
                    ORDER BY adhkar_order"""),
            {"after": after}
        ).mappings().all()

    return [dict(row) for row in result]


# ══════════════════════════════════════════════════════════════════════════════
#  JUMA ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/juma-guide")
def get_juma_guide(db: Session = Depends(get_db)):
    """Get all juma guide items sorted by item_order."""
    result = db.execute(text("SELECT * FROM juma_guide ORDER BY item_order")).mappings().all()
    return [dict(row) for row in result]


# ══════════════════════════════════════════════════════════════════════════════
#  SPECIAL SURAHS ROUTES
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/special-surahs")
def get_special_surahs(category: str = Query("all"), db: Session = Depends(get_db)):
    """Get list of special surahs (metadata only, no ayahs)."""
    if category == "all":
        result = db.execute(
            text("SELECT * FROM special_surahs ORDER BY display_order")
        ).mappings().all()
    else:
        result = db.execute(
            text("SELECT * FROM special_surahs WHERE category = :cat ORDER BY display_order"),
            {"cat": category}
        ).mappings().all()

    return [dict(row) for row in result]


@router.get("/special-surahs/{surah_number}")
async def get_special_surah_detail(surah_number: int, db: Session = Depends(get_db)):
    """
    Get special surah detail with full ayahs.
    1. Get metadata from special_surahs table
    2. Check kanzuliman_cache for ayahs
    3. If not cached → fetch from AlQuran.cloud and cache
    """
    # 1. Get metadata
    meta = db.execute(
        text("SELECT * FROM special_surahs WHERE surah_number = :sn"),
        {"sn": surah_number}
    ).mappings().first()

    if not meta:
        raise HTTPException(status_code=404, detail=f"Special surah {surah_number} not found")

    surah_info = dict(meta)

    # 2. Check cache
    cached = db.query(KanzulImanCache).filter(
        KanzulImanCache.surah_number == surah_number
    ).order_by(KanzulImanCache.ayah_number).all()

    if cached and len(cached) >= surah_info["total_ayahs"]:
        ayahs = [
            {
                "ayah_number": a.ayah_number,
                "arabic_text": a.arabic_text,
                "urdu_translation": a.urdu_translation,
            }
            for a in cached
        ]
        return {"surah_info": surah_info, "ayahs": ayahs}

    # 3. Fetch from AlQuran.cloud
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            url = f"{ALQURAN_API_BASE}/surah/{surah_number}/editions/quran-uthmani,ur.kanzuliman"
            response = await client.get(url)

            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Failed to fetch from AlQuran.cloud")

            data = response.json()
            if data.get("code") != 200:
                raise HTTPException(status_code=502, detail="AlQuran.cloud returned error")

            editions = data.get("data", [])
            if len(editions) < 2:
                raise HTTPException(status_code=502, detail="Incomplete data from AlQuran.cloud")

            arabic_ayahs = editions[0].get("ayahs", [])
            urdu_ayahs = editions[1].get("ayahs", [])

            ayahs = []
            for i in range(len(arabic_ayahs)):
                ayah_num = arabic_ayahs[i].get("numberInSurah", i + 1)
                arabic_text = arabic_ayahs[i].get("text", "")
                urdu_translation = urdu_ayahs[i].get("text", "") if i < len(urdu_ayahs) else ""

                # Cache (INSERT OR IGNORE pattern)
                existing = db.query(KanzulImanCache).filter(
                    KanzulImanCache.surah_number == surah_number,
                    KanzulImanCache.ayah_number == ayah_num,
                ).first()

                if not existing:
                    cache_entry = KanzulImanCache(
                        surah_number=surah_number,
                        ayah_number=ayah_num,
                        arabic_text=arabic_text,
                        urdu_translation=urdu_translation,
                    )
                    db.add(cache_entry)

                ayahs.append({
                    "ayah_number": ayah_num,
                    "arabic_text": arabic_text,
                    "urdu_translation": urdu_translation,
                })

            db.commit()
            return {"surah_info": surah_info, "ayahs": ayahs}

    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
#  MANZIL ROUTE
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/manzil")
async def get_manzil(db: Session = Depends(get_db)):
    """
    Fetch all 7 Manzil sections from AlQuran.cloud for ruqyah/protection.
    Cache all fetched ayahs in kanzuliman_cache.
    """
    sections = []
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            for manzil_num in range(1, 8):
                url = f"{ALQURAN_API_BASE}/manzil/{manzil_num}/editions/quran-uthmani,ur.kanzuliman"
                response = await client.get(url)

                if response.status_code != 200:
                    raise HTTPException(
                        status_code=502,
                        detail=f"Failed to fetch manzil {manzil_num} from AlQuran.cloud"
                    )

                data = response.json()
                if data.get("code") != 200:
                    continue

                editions = data.get("data", [])
                if len(editions) < 2:
                    continue

                arabic_ayahs = editions[0].get("ayahs", [])
                urdu_ayahs = editions[1].get("ayahs", [])

                manzil_ayahs = []
                for i in range(len(arabic_ayahs)):
                    arabic_text = arabic_ayahs[i].get("text", "")
                    urdu_translation = urdu_ayahs[i].get("text", "") if i < len(urdu_ayahs) else ""
                    surah_num = arabic_ayahs[i].get("surah", {}).get("number", 0)
                    ayah_num = arabic_ayahs[i].get("numberInSurah", 0)

                    # Cache
                    existing = db.query(KanzulImanCache).filter(
                        KanzulImanCache.surah_number == surah_num,
                        KanzulImanCache.ayah_number == ayah_num,
                    ).first()

                    if not existing:
                        cache_entry = KanzulImanCache(
                            surah_number=surah_num,
                            ayah_number=ayah_num,
                            arabic_text=arabic_text,
                            urdu_translation=urdu_translation,
                        )
                        db.add(cache_entry)

                    manzil_ayahs.append({
                        "surah_number": surah_num,
                        "ayah_number": ayah_num,
                        "arabic_text": arabic_text,
                        "urdu_translation": urdu_translation,
                    })

                db.commit()
                sections.append({
                    "manzil_number": manzil_num,
                    "ayahs": manzil_ayahs,
                })

    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

    return {
        "title": "منزل",
        "description": "منزل قرآن کریم کی مخصوص آیات کا مجموعہ ہے جو حفاظت اور شفاء کے لیے پڑھی جاتی ہیں",
        "sections": sections,
    }


# ══════════════════════════════════════════════════════════════════════════════
#  SUMMARY ROUTE
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/summary")
def get_summary(db: Session = Depends(get_db)):
    """Returns summary counts for all Islamic guide sections."""
    namaz_count = db.execute(text("SELECT COUNT(*) FROM namaz_steps")).scalar() or 0
    duas_count = db.execute(text("SELECT COUNT(*) FROM duas")).scalar() or 0
    adhkar_count = db.execute(text("SELECT COUNT(*) FROM after_namaz_adhkar")).scalar() or 0
    juma_count = db.execute(text("SELECT COUNT(*) FROM juma_guide")).scalar() or 0

    special_surahs = db.execute(
        text("SELECT * FROM special_surahs ORDER BY display_order")
    ).mappings().all()

    return {
        "namaz_steps_count": namaz_count,
        "duas_count": duas_count,
        "adhkar_count": adhkar_count,
        "juma_items_count": juma_count,
        "special_surahs": [dict(s) for s in special_surahs],
    }
