#!/usr/bin/env python3
"""Build and import Fatzomat's final restaurant index."""

from __future__ import annotations

import difflib
import hashlib
import json
import math
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

try:
    import requests
except ImportError:
    print("Missing dependency: requests", file=sys.stderr)
    raise

REGIONS = {
    "lorsch_20km": (49.653888888889, 8.5675),
    "pforzheim_20km": (48.8907, 8.70245),
}
RADIUS_KM = 20.0
OVERPASS_ENDPOINTS = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
]
CUISINE_MAP = {
    "italian": "italian", "italian_restaurant": "italian",
    "greek": "greek", "greek_restaurant": "greek",
    "asian": "asian", "asian_restaurant": "asian",
    "chinese": "chinese", "chinese_restaurant": "chinese",
    "thai": "thai", "thai_restaurant": "thai",
    "vietnamese": "vietnamese", "vietnamese_restaurant": "vietnamese",
    "korean": "korean", "korean_restaurant": "korean",
    "indonesian": "indonesian", "indonesian_restaurant": "indonesian",
    "malaysian": "malaysian", "malaysian_restaurant": "malaysian",
    "japanese": "japanese", "japanese_restaurant": "japanese",
    "turkish": "turkish", "turkish_restaurant": "turkish",
    "spanish": "spanish", "spanish_restaurant": "spanish",
    "lebanese": "lebanese", "lebanese_restaurant": "lebanese",
    "portuguese": "portuguese", "portuguese_restaurant": "portuguese",
    "indian": "indian", "indian_restaurant": "indian",
    "vegan": "vegan", "vegan_restaurant": "vegan",
    "burger": "burger", "burger_restaurant": "burger",
    "mexican": "mexican", "mexican_restaurant": "mexican",
    "vegetarian": "vegetarian", "vegetarian_restaurant": "vegetarian",
    "vegan": "vegetarian", "vegan_restaurant": "vegetarian",
    "sushi": "sushi", "sushi_restaurant": "sushi",
    "pizza": "pizza", "pizza_restaurant": "pizza", "italian_pizza": "pizza",
    "kebab": "kebab", "kebab_restaurant": "kebab", "doner": "kebab",
    "doner_kebab": "kebab", "doner_kebab_restaurant": "kebab",
    "steak": "steak", "steak_restaurant": "steak",
}


def normalize_text(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().split())


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0088
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def bbox_for(lat: float, lon: float, radius_km: float):
    lat_delta = radius_km / 111.32
    lon_delta = radius_km / (111.32 * max(abs(math.cos(math.radians(lat))), 0.2))
    return lon - lon_delta, lat - lat_delta, lon + lon_delta, lat + lat_delta


def region_for(lat: float, lon: float) -> str | None:
    distance, name = min(
        (haversine_km(lat, lon, c_lat, c_lon), name)
        for name, (c_lat, c_lon) in REGIONS.items()
    )
    return name if distance <= RADIUS_KM else None


def taxonomy_values(feature: dict[str, Any]) -> set[str]:
    taxonomy = feature.get("taxonomy") or {}
    values = set()
    if isinstance(taxonomy, dict):
        values.update(str(v).lower() for v in taxonomy.get("hierarchy") or [])
        values.update(str(v).lower() for v in taxonomy.get("alternates") or [])
        if taxonomy.get("primary"):
            values.add(str(taxonomy["primary"]).lower())
    if feature.get("basic_category"):
        values.add(str(feature["basic_category"]).lower())
    return values


def categories_from_taxonomy(values: set[str]) -> list[str]:
    return list(dict.fromkeys(CUISINE_MAP[v] for v in values if v in CUISINE_MAP))


def overture_is_food_place(feature: dict[str, Any]) -> bool:
    """Accept current Overture restaurant/fast-food taxonomy entries from the live schema."""
    values = taxonomy_values(feature)
    basic_category = normalize_text(feature.get("basic_category"))
    # Current Overture taxonomy represents restaurants via the hierarchy,
    # e.g. food_and_drink -> restaurant -> casual_eatery -> subtype.
    # Keep the filter broad here; cuisine classification stays strict below.
    return (
        "restaurant" in values
        or "fast_food" in values
        or basic_category in {"restaurant", "fast_food"}
        or any(v.endswith("_restaurant") for v in values)
    )


def first_name(feature: dict[str, Any]) -> str:
    names = feature.get("names") or {}
    return str(names.get("primary") or names.get("common") or "").strip() if isinstance(names, dict) else ""


def first_address(feature: dict[str, Any]):
    addresses = feature.get("addresses") or []
    if not addresses or not isinstance(addresses[0], dict):
        return None, None
    address = addresses[0]
    return (
        str(address.get("freeform") or "").strip() or None,
        str(address.get("locality") or "").strip() or None,
        str(address.get("postcode") or "").strip() or None,
    )


def download_overture(bbox, output: Path) -> None:
    subprocess.run([
        "overturemaps", "download",
        f"--bbox={bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]}",
        "-f", "geojson", "--type=place", "-o", str(output),
    ], check=True)


def load_geojson(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return [f for f in payload.get("features", []) if isinstance(f, dict)]


def query_overpass(bbox) -> list[dict[str, Any]]:
    """Best-effort OSM enrichment. Overture remains the primary source."""
    west, south, east, north = bbox
    query = f"""
[out:json][timeout:45];
(
  nwr["amenity"="restaurant"]({south},{west},{north},{east});
  nwr["amenity"="fast_food"]({south},{west},{north},{east});
);
out center tags;
""".strip()
    errors = []
    for endpoint in OVERPASS_ENDPOINTS:
        try:
            response = requests.post(
                endpoint,
                data=query.encode("utf-8"),
                headers={"User-Agent": "Fatzomat restaurant-index importer"},
                timeout=45,
            )
            response.raise_for_status()
            return response.json().get("elements", [])
        except Exception as exc:
            errors.append(f"{endpoint}: {exc}")
    print(
        "Warning: all Overpass endpoints failed; continuing with Overture only. "
        + " | ".join(errors),
        file=sys.stderr,
    )
    return []


def osm_point(element):
    if element.get("lat") is not None and element.get("lon") is not None:
        return float(element["lat"]), float(element["lon"])
    center = element.get("center") or {}
    if center.get("lat") is not None and center.get("lon") is not None:
        return float(center["lat"]), float(center["lon"])
    return None


def osm_record(element, region):
    point = osm_point(element)
    tags = element.get("tags") or {}
    name = str(tags.get("name") or "").strip()
    if not point or not name:
        return None

    cuisines = []
    for token in str(tags.get("cuisine") or "").replace(",", ";").split(";"):
        category = CUISINE_MAP.get(normalize_text(token))
        if category and category not in cuisines:
            cuisines.append(category)

    delivery = normalize_text(tags.get("delivery"))
    return {
        "name": name, "latitude": point[0], "longitude": point[1],
        "address": " ".join(
            part for part in [str(tags.get("addr:street") or "").strip(),
                              str(tags.get("addr:housenumber") or "").strip()] if part
        ) or None,
        "postal_code": str(tags.get("addr:postcode") or "").strip() or None,
        "postal_code": str(tags.get("addr:postcode") or "").strip() or None,
        "city": str(tags.get("addr:city") or "").strip() or None,
        "area": region, "cuisine": cuisines,
        "phone": tags.get("phone") or tags.get("contact:phone"),
        "website": tags.get("website") or tags.get("contact:website"),
        "order_url": tags.get("delivery:website"),
        "opening_hours": tags.get("opening_hours"),
        "delivery_available": delivery in {"yes", "only"} or bool(tags.get("delivery:website")),
        "source_ids": {"osm": f"{element.get('type')}/{element.get('id')}"},
        "metadata": {"osm_tags": tags},
    }


def overture_record(feature, region):
    geometry = feature.get("geometry") or {}
    coords = geometry.get("coordinates") or []
    name = first_name(feature)
    if geometry.get("type") != "Point" or len(coords) < 2 or not name or not overture_is_food_place(feature):
        return None
    lon, lat = float(coords[0]), float(coords[1])
    address, city, postal_code = first_address(feature)
    phones, websites = feature.get("phones") or [], feature.get("websites") or []
    return {
        "name": name, "latitude": lat, "longitude": lon,
        "address": address, "postal_code": postal_code, "city": city, "area": region,
        "cuisine": categories_from_taxonomy(taxonomy_values(feature)),
        "phone": phones[0] if phones else None,
        "website": websites[0] if websites else None,
        "order_url": None, "opening_hours": None, "delivery_available": False,
        "source_ids": {"overture": str(feature.get("id") or "")},
        "metadata": {
            "overture_postcode": postal_code,
            "overture_basic_category": feature.get("basic_category"),
            "overture_taxonomy": feature.get("taxonomy"),
            "overture_confidence": feature.get("confidence"),
        },
    }


def merge_records(records):
    merged = []
    for record in records:
        match = None
        name = normalize_text(record["name"])
        for existing in merged:
            if haversine_km(record["latitude"], record["longitude"],
                            existing["latitude"], existing["longitude"]) > 0.075:
                continue
            if difflib.SequenceMatcher(None, name, normalize_text(existing["name"])).ratio() >= 0.82:
                match = existing
                break
        if match is None:
            merged.append(record)
            continue
        match["cuisine"] = sorted(set(match["cuisine"]) | set(record["cuisine"]))
        for key in ("phone", "website", "order_url", "opening_hours", "address", "postal_code", "city"):
            match[key] = match[key] or record[key]
        match["delivery_available"] |= record["delivery_available"]
        match["source_ids"].update(record["source_ids"])
        match["metadata"]["sources_merged"] = True

    for record in merged:
        material = "|".join([
            normalize_text(record["name"]),
            str(round(record["latitude"], 5)),
            str(round(record["longitude"], 5)),
        ])
        record["dedupe_key"] = hashlib.sha256(material.encode()).hexdigest()
    return merged


def upload(records):
    supabase_url = os.environ["SUPABASE_URL"].rstrip("/")
    service_role_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    endpoint = f"{supabase_url}/rest/v1/restaurant_index"
    headers = {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }
    rows = []
    for record in records:
        row = dict(record)
        row["location"] = f"POINT({record['longitude']} {record['latitude']})"
        rows.append(row)
    for start in range(0, len(rows), 500):
        response = requests.post(
            endpoint, params={"on_conflict": "dedupe_key"},
            headers=headers, json=rows[start:start + 500], timeout=60,
        )
        response.raise_for_status()


def main():
    with tempfile.TemporaryDirectory(prefix="fatzomat-restaurant-index-") as temp_dir:
        temp = Path(temp_dir)
        all_records = []
        for region, (lat, lon) in REGIONS.items():
            bbox = bbox_for(lat, lon, RADIUS_KM)
            overture_file = temp / f"{region}-overture.geojson"
            print(f"Downloading Overture Places for {region}: {bbox}")
            download_overture(bbox, overture_file)
            region_records = [
                record for feature in load_geojson(overture_file)
                if (record := overture_record(feature, region))
            ]
            print(f"Querying OpenStreetMap for {region}")
            for element in query_overpass(bbox):
                record = osm_record(element, region)
                if record and region_for(record["latitude"], record["longitude"]) == region:
                    region_records.append(record)
            print(f"{region}: {len(region_records)} source records")
            all_records.extend(region_records)
            time.sleep(2)
        merged = merge_records(all_records)
        print(f"Merged final records: {len(merged)}")
        upload(merged)
        print("Import complete.")


if __name__ == "__main__":
    main()
