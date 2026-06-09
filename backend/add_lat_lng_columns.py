import asyncio
from app.core.database import SessionLocal
from sqlalchemy import text

def alter_table():
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;"))
        db.execute(text("ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;"))
        db.commit()
        print("Successfully added latitude and longitude columns to restaurants table")
    except Exception as e:
        print("Error:", e)
    finally:
        db.close()

if __name__ == "__main__":
    alter_table()
