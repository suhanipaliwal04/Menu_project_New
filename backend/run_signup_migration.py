import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

def run_migration():
    # Load environment variables
    load_dotenv()
    database_url = os.getenv("DATABASE_URL")
    
    if not database_url:
        print("DATABASE_URL not found in .env file.")
        return

    print("Connecting to the database...")
    engine = create_engine(database_url)
    
    with engine.connect() as conn:
        print("Starting migration...")
        
        # 1. Add new columns to users table
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN full_name VARCHAR(255);"))
            print("Added full_name column to users table.")
        except Exception as e:
            print(f"Skipping full_name column: {e}")
            
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);"))
            print("Added phone_number column to users table.")
        except Exception as e:
            print(f"Skipping phone_number column: {e}")
            
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN state VARCHAR(100);"))
            print("Added state column to users table.")
        except Exception as e:
            print(f"Skipping state column: {e}")
            
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN city VARCHAR(100);"))
            print("Added city column to users table.")
        except Exception as e:
            print(f"Skipping city column: {e}")
            
        # 2. Backfill existing data in users table
        print("Updating existing users to have state 'Maharastra' and city 'Nagpur'...")
        conn.execute(text("UPDATE users SET state = 'Maharastra', city = 'Nagpur' WHERE state IS NULL OR city IS NULL;"))
        
        # 3. Backfill existing data in areas table
        print("Updating existing areas to have state 'Maharastra' and city 'Nagpur'...")
        conn.execute(text("UPDATE areas SET state = 'Maharastra', city = 'Nagpur' WHERE state IS NULL OR city IS NULL;"))
        
        conn.commit()
        print("Migration completed successfully!")

if __name__ == "__main__":
    run_migration()
