import os
import sys
from sqlalchemy import create_engine, text
from app.core.config import settings

def run_migration():
    print("Running migration...")
    engine = create_engine(settings.DATABASE_URL, echo=False)
    
    with open('add_orders_tables.sql', 'r') as f:
        sql = f.read()
        
    with engine.begin() as conn:
        conn.execute(text(sql))
        
    print("Migration completed successfully!")

if __name__ == "__main__":
    run_migration()
