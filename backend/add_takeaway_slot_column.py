import asyncio
from app.core.database import SessionLocal
from sqlalchemy import text

def alter_table():
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS takeaway_slot_duration_mins INTEGER DEFAULT 15;"))
        db.commit()
        print("Successfully added takeaway_slot_duration_mins column to restaurants table")
    except Exception as e:
        print("Error:", e)
    finally:
        db.close()

if __name__ == "__main__":
    alter_table()
