from app.core.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("ALTER TABLE bookings ADD COLUMN IF NOT EXISTS booking_date VARCHAR(50);"))
    db.commit()
    print("Migration successful")
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
