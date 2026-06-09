import asyncio
from app.core.database import SessionLocal
from sqlalchemy import text

def alter_table():
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS slot_duration_mins INTEGER DEFAULT 30;"))
        db.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS max_dine_in_per_slot INTEGER DEFAULT 5;"))
        db.commit()
        print("Successfully added slot_duration_mins and max_dine_in_per_slot")
    except Exception as e:
        print("Error:", e)
    finally:
        db.close()

alter_table()
