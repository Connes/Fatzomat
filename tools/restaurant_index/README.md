# Fatzomat restaurant index importer

This importer builds the final Fatzomat restaurant index for exactly two areas:

- Lorsch + 20 km
- Pforzheim + 20 km

It combines Overture Places with OpenStreetMap/Overpass, merges likely duplicates, maps only explicitly supported cuisine categories, and uploads the compact result to Supabase.

Requirements:
- Python 3.11+
- pip install requests
- pip install overturemaps
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY

Run:
python tools/restaurant_index/import_restaurants.py

The service-role key is only used by the import job. It must never be shipped in the Flutter app.
