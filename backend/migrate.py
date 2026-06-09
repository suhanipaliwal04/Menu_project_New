import os
import sys
sys.path.insert(0, 'd:/Users/Pranil/Github_Repos/Menu_project_New/backend')
from app.core.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    # Check if column already exists
    result = db.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='menu_items' AND column_name='original_health_score'")).fetchone()
    if not result:
        print('Adding original_health_score column...')
        db.execute(text("ALTER TABLE menu_items ADD COLUMN original_health_score INTEGER;"))
        db.execute(text("UPDATE menu_items SET original_health_score = health_score WHERE original_health_score IS NULL;"))
        db.commit()
        print('Successfully added and backfilled original_health_score.')
    else:
        print('Column already exists.')
except Exception as e:
    print('Error:', e)
    db.rollback()
finally:
    db.close()
