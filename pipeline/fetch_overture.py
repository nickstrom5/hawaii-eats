"""Download the Overture Maps extracts that hawaii.py reads -> data/id/

- overture_hi_bbox.parquet     every place in Hawaii's bounding box (name, category, address, point)
- overture_hi_sources.parquet  which datasets each Hawaii eating/drinking listing came from (Meta, Foursquare, ...)
- hi_shapes.json               simplified state and county outlines for the map
- hi_state_detail.geojson      the state outline at full detail, for the in-state test (drops rows geocoded into the sea)
- hi_counties_detail.geojson   county polygons for assigning each place to a county (not shipped)
- addresses_hi.parquet         Overture address points statewide, to place county liquor licenses (they have no coordinates)
- localities_hi.json           city outlines (Honolulu, Hilo, ...) for calibration areas

Reads the public Overture bucket over S3 with DuckDB (no account needed). Adapted from co-eats/pipeline/fetch_overture.py and
fetch_extras.py.
"""
import os, json, time
import duckdb
from shapely import wkb
from shapely.geometry import mapping, box

# Honolulu County and the state reach the Northwestern Hawaiian Islands (to 178°W): keep the main islands only
MAIN = box(-160.8, 18.7, -154.6, 22.4)

RELEASE = "2026-09-23.1"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "hi")
# the main Hawaiian islands, Niʻihau to Hawaiʻi Island (18.9°N–22.3°N, 154.8°W–160.3°W); the Northwestern islands have no restaurants
BBOX = "bbox.xmin BETWEEN -160.8 AND -154.6 AND bbox.ymin BETWEEN 18.7 AND 22.4"
EAT = "('restaurant','casual_eatery','bar','fast_food_restaurant','coffee_shop','cafe','smoothie_juice_bar','brewery','food_court')"
os.makedirs(OUT, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial; SET s3_region='us-west-2'; SET enable_progress_bar=false;")
places = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=places/type=place/*.parquet"

t = time.time()
if not os.path.exists(f"{OUT}/overture_hi_bbox.parquet"):
    con.execute(f"""
COPY (
  SELECT id, names.primary AS name, basic_category AS cat, taxonomy.primary AS tax, taxonomy.hierarchy AS hier, confidence,
         operating_status AS status, brand.names.primary AS brand, addresses[1].freeform AS street, addresses[1].locality AS city,
         addresses[1].postcode AS zip, addresses[1].region AS region, ST_Y(geometry) AS lat, ST_X(geometry) AS lon, websites[1] AS web,
         phones[1] AS phone
  FROM read_parquet('{places}', hive_partitioning=1) WHERE {BBOX}
) TO '{OUT}/overture_hi_bbox.parquet' (FORMAT PARQUET)""")
    print("places in bbox", round(time.time() - t), "s", flush=True)
if not os.path.exists(f"{OUT}/overture_hi_sources.parquet"):
    con.execute(f"""
COPY (
  SELECT id, list_transform(sources, x -> x.dataset) AS ds, list_transform(sources, x -> x.update_time) AS ut,
         list_transform(sources, x -> x.record_id) AS rid,
         len(socials) AS n_soc, len(websites) AS n_web, len(phones) AS n_ph
  FROM read_parquet('{places}', hive_partitioning=1)
  WHERE {BBOX} AND basic_category IN {EAT}
) TO '{OUT}/overture_hi_sources.parquet' (FORMAT PARQUET)""")
    print("sources", round(time.time() - t), "s", flush=True)

areas = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=divisions/type=division_area/*.parquet"
rows = con.execute(f"""
  SELECT subtype, class, names.primary AS name, ST_AsWKB(geometry) AS g
  FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region = 'US-HI' AND subtype IN ('region', 'county', 'locality')
    AND bbox.xmax > -161 AND bbox.ymin > 18.5""").fetchall()


def rings(geom, tol, min_area):
    geom = geom.simplify(tol, preserve_topology=True)
    polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
    return [[[round(x, 3), round(y, 3)] for x, y in p.exterior.coords] for p in polys]


out = {"state": None, "counties": []}
for sub, cls, name, g in rows:
    if cls != "land" or sub == "locality":
        continue
    geom = wkb.loads(bytes(g)).buffer(0).intersection(MAIN)
    if sub == "region":
        json.dump(mapping(geom.simplify(0.0005, preserve_topology=True)), open(f"{OUT}/hi_state_detail.geojson", "w"))
        out["state"] = [[r] for r in rings(geom, 0.002, 0.0002)]
    else:
        out["counties"].append({"name": name, "c": rings(geom, 0.004, 0.0005)})
json.dump({name: mapping(wkb.loads(bytes(g)).buffer(0).intersection(MAIN).simplify(0.0003, preserve_topology=True))
           for sub, cls, name, g in rows if sub == "county" and cls == "land"}, open(f"{OUT}/hi_counties_detail.geojson", "w"))
json.dump(out, open(f"{OUT}/hi_shapes.json", "w"), separators=(",", ":"))
json.dump({name: mapping(wkb.loads(bytes(g)).buffer(0).simplify(0.0002, preserve_topology=True))
           for sub, cls, name, g in rows if sub == "locality" and cls == "land"}, open(f"{OUT}/localities_hi.json", "w"))
print("outlines: state", len(out["state"] or []), "rings +", len(out["counties"]), "counties;",
      sum(1 for r in rows if r[0] == "locality"), "localities;", round(time.time() - t), "s", flush=True)

# Overture's address theme has no Hawaii points (2026-09-23.1: 0 in the box), so liquor licenses are placed by the Census geocoder
