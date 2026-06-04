import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

os.environ['DATABASE_URL'] = "postgresql://postgres.ryfktnbmzhbmtjrvzndy:MenuAppPassword123!@aws-0-ap-south-1.pooler.supabase.com:6543/postgres"

from app.core.database import SessionLocal
from app.models.restaurant import Restaurant

def check_restaurants():
    db = SessionLocal()
    restaurants = db.query(Restaurant).all()
    print("Restaurants in DB:")
    for r in restaurants:
        print(f" - {r.restaurant_name} (ID: {r.restaurant_id}, Owner: {r.owner_id}, Active: {r.is_active}, DineIn: {r.has_dine_in}, Takeaway: {r.has_takeaway})")

if __name__ == "__main__":
    check_restaurants()
