import asyncio
from app.core.database import SessionLocal
from app.models.restaurant import Restaurant

def delete_orphaned_restaurants():
    db = SessionLocal()
    try:
        orphans = db.query(Restaurant).filter(Restaurant.owner_id == None).all()
        print(f"Found {len(orphans)} orphaned restaurants.")
        for r in orphans:
            print(f"Deleting '{r.restaurant_name}' (ID: {r.restaurant_id})...")
            db.delete(r)
        db.commit()
        print("Deletion complete.")
    finally:
        db.close()

if __name__ == "__main__":
    delete_orphaned_restaurants()
