"""
Run migration via Supabase REST API using httpx (HTTPS only - port 443, never blocked).
Uses the service_role key to execute raw SQL via the Supabase management endpoint.
"""
import httpx

SUPABASE_URL = "https://pirxrfkrjgskjjacrnkr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpcnhyZmtyamdza2pqYWNybmtyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTM4NzQ1OCwiZXhwIjoyMDg0OTYzNDU4fQ.w6-WBmBLg0DZxXEUWhSlAGRwR8cqp3d-Ge0tPawPLCQ"

headers = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}

migrations = [
    "ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION",
    "ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION",
]

print("Running migrations via Supabase REST API (HTTPS)...")

with httpx.Client(timeout=30.0) as client:
    for sql in migrations:
        try:
            resp = client.post(
                f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
                headers=headers,
                json={"query": sql},
            )
            if resp.status_code == 200:
                print(f"  OK: {sql[:70]}...")
            else:
                # Try raw SQL via the pg endpoint
                resp2 = client.post(
                    f"{SUPABASE_URL}/rest/v1/",
                    headers={**headers, "Prefer": "return=minimal"},
                    content=sql.encode(),
                )
                print(f"  [{resp2.status_code}] {sql[:60]}... -> {resp2.text[:80]}")
        except Exception as e:
            print(f"  ERROR: {e}")

    # Verify restaurants
    resp = client.get(
        f"{SUPABASE_URL}/rest/v1/restaurants",
        headers=headers,
        params={"select": "restaurant_name,owner_id,has_dine_in,has_takeaway,is_open_manually,latitude,longitude"},
    )
    if resp.status_code == 200:
        rows = resp.json()
        print(f"\nRestaurants ({len(rows)} found):")
        for r in rows:
            print(f"  {r.get('restaurant_name')} | Owner: {r.get('owner_id')} | Lat: {r.get('latitude')} | Lng: {r.get('longitude')}")
    else:
        print(f"\nVerification failed: {resp.status_code} {resp.text}")
