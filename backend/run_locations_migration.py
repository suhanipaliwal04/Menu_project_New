import os
import sys
from sqlalchemy import text
from app.core.database import SessionLocal

def run_migration():
    print("Starting location tables migration...")
    
    db = SessionLocal()
    try:
        # Create location_states table
        db.execute(text("""
            CREATE TABLE IF NOT EXISTS location_states (
                state_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                state_name VARCHAR(100) UNIQUE NOT NULL
            );
        """))
        print("Created location_states table.")

        # Create location_cities table
        db.execute(text("""
            CREATE TABLE IF NOT EXISTS location_cities (
                city_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                city_name VARCHAR(100) NOT NULL,
                state_id UUID NOT NULL REFERENCES location_states(state_id) ON DELETE CASCADE,
                UNIQUE (city_name, state_id)
            );
        """))
        print("Created location_cities table.")

        # Insert default data (Maharastra -> Nagpur) if it doesn't exist
        result = db.execute(text("SELECT state_id FROM location_states WHERE state_name = 'Maharastra';"))
        row = result.fetchone()
        
        if not row:
            print("Inserting default state 'Maharastra'...")
            db.execute(text("INSERT INTO location_states (state_name) VALUES ('Maharastra');"))
            result = db.execute(text("SELECT state_id FROM location_states WHERE state_name = 'Maharastra';"))
            row = result.fetchone()

        state_id = row[0]
        
        # Check city
        city_result = db.execute(text(f"SELECT city_id FROM location_cities WHERE city_name = 'Nagpur' AND state_id = '{state_id}';"))
        city_row = city_result.fetchone()
        
        if not city_row:
            print("Inserting default city 'Nagpur'...")
            db.execute(text(f"INSERT INTO location_cities (city_name, state_id) VALUES ('Nagpur', '{state_id}');"))
            
        db.commit()
        print("Migration completed successfully!")
    except Exception as e:
        print(f"Error during migration: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    run_migration()
