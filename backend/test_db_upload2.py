import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from app.core.database import SessionLocal
from app.models.upload import MenuUpload

db = SessionLocal()
uploads = db.query(MenuUpload).order_by(MenuUpload.uploaded_at.desc()).limit(5).all()

for upload in uploads:
    print(f"\nUpload ID: {upload.upload_id}")
    count = 0
    if upload.structured_data and 'enriched_items' in upload.structured_data:
        count = len(upload.structured_data['enriched_items'])
    print(f"Extracted: {count} items")
