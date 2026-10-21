"""Island and county outlines from the Hawaii Statewide GIS Program (public domain sources, not OSM) -> data/hi/

- hi_islands.geojson   coastlines of the main Hawaiian islands (USGS DLG, State GIS Terrestrial/MapServer/3), one feature per
                       polygon with its island name (`isle`); used for the island of each place, the in-state test and every map
- hi_counties.geojson  2020 Census county boundaries clipped to the coastline (State GIS Census/MapServer/29)
- hi_shapes.json       simplified island rings for the leaderboard, app and site maps

Both layers come from the State's ArcGIS REST service (geodata.hawaii.gov, robots.txt allows it; checked 2026-10-19), one request
per page with our honest user agent. USGS and Census data are U.S. Government works (public domain); credit "Hawaii Statewide GIS
Program" anyway.
"""
import json, os, time
import requests
from shapely.geometry import shape, mapping
from shapely.ops import unary_union

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "hi")
UA = {"User-Agent": "HawaiiEats/1.0 (+nick@eatsranked.com)"}
BASE = "https://geodata.hawaii.gov/arcgis/rest/services"


def layer(path, fields):
    feats, off = [], 0
    while True:
        r = requests.get(f"{BASE}/{path}/query", headers=UA, timeout=120, params={
            "where": "1=1", "outFields": fields, "outSR": 4326, "f": "geojson", "resultOffset": off, "resultRecordCount": 1000})
        r.raise_for_status()
        d = r.json()
        feats += d["features"]
        if not d.get("exceededTransferLimit") and len(d["features"]) < 1000:
            return feats
        off += len(d["features"])
        time.sleep(1)


# the coastline layer spells some islands without diacritics; show the official Hawaiian spelling
ISLE = {"hawaii": "Hawaiʻi", "maui": "Maui", "oahu": "Oʻahu", "kauai": "Kauaʻi", "molokai": "Molokaʻi", "lanai": "Lānaʻi",
        "niihau": "Niʻihau", "kahoolawe": "Kahoʻolawe"}
CO = {"Hawaii": "Hawaiʻi County", "Honolulu": "Honolulu County", "Kauai": "Kauaʻi County", "Maui": "Maui County", "Kalawao": "Kalawao County"}

coast = layer("Terrestrial/MapServer/3", "isle,water")
by = {}
for f in coast:
    p = f["properties"]
    if p.get("water") == 1:   # inland water (Oʻahu's Salt Lake), not land
        continue
    k = "".join(c for c in (p.get("isle") or "").lower() if c.isalpha())
    name = ISLE.get(k)
    if not name or not f.get("geometry"):
        continue
    by.setdefault(name, []).append(shape(f["geometry"]).buffer(0))
islands = {n: unary_union(gs) for n, gs in by.items()}
json.dump({"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {"island": n},
           "geometry": mapping(g.simplify(0.0002, preserve_topology=True))} for n, g in islands.items()]},
          open(f"{OUT}/hi_islands.geojson", "w"))
print("islands:", {n: round(g.area * 111 * 104, 0) for n, g in islands.items()}, "(approx km²)")

counties = layer("Census/MapServer/29", "name20,namelsad20")
json.dump({"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {"county": CO.get(f["properties"]["name20"],
           f["properties"]["namelsad20"])}, "geometry": f["geometry"]} for f in counties]}, open(f"{OUT}/hi_counties.geojson", "w"))
print("counties:", [f["properties"]["name20"] for f in counties])


def rings(geom, tol, min_area):
    geom = geom.simplify(tol, preserve_topology=True)
    polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
    return [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys]


ORDER = ["Niʻihau", "Kauaʻi", "Oʻahu", "Molokaʻi", "Lānaʻi", "Maui", "Kahoʻolawe", "Hawaiʻi"]
out = {"state": [], "counties": [], "islands": []}
for n in ORDER:
    if n in islands:
        rs = rings(islands[n], 0.002, 0.00005)
        out["islands"].append({"name": n, "c": rs})
        out["state"] += [[r] for r in rs]
json.dump(out, open(f"{OUT}/hi_shapes.json", "w"), separators=(",", ":"))
print("shapes:", {i["name"]: len(i["c"]) for i in out["islands"]}, os.path.getsize(f"{OUT}/hi_shapes.json"), "bytes")

# 2020 Census Designated Places (State GIS Census/MapServer/28): town outlines, so Kailua (Oʻahu) and Kailua-Kona, or the Lahaina
# CDP (the Aug 2023 burn area) versus Kāʻanapali and Nāpili with the same Lahaina mailing address, are told apart by where a place is
cdps = layer("Census/MapServer/28", "name20,geoid20")
json.dump({"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {"cdp": f["properties"]["name20"],
           "geoid": f["properties"]["geoid20"]}, "geometry": f["geometry"]} for f in cdps if f.get("geometry")]},
          open(f"{OUT}/hi_cdps.geojson", "w"))
print("census places:", len(cdps))
