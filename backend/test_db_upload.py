import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

from app.core.database import SessionLocal
from app.models.upload import MenuUpload

db = SessionLocal()
upload = db.query(MenuUpload).order_by(MenuUpload.uploaded_at.desc()).first()

if upload:
    print(f"Upload ID: {upload.upload_id}")
    print(f"Status: {upload.ocr_status}")
    print(f"Error: {upload.error_message}")
    
    # print the length of enriched items
    if upload.structured_data and 'enriched_items' in upload.structured_data:
        items = upload.structured_data['enriched_items']
        print(f"Enriched Items Count: {len(items)}")
        for i, item in enumerate(items[:5]):
            print(f"  {i+1}: {item}")
else:
    print("No uploads found.")
