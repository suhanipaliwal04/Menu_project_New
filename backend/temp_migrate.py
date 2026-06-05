from app.core.database import engine, Base
import app.models  # This imports __init__ and all models

print("Creating missing tables...")
Base.metadata.create_all(bind=engine)
print("Done!")
