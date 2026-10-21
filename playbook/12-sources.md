# Hawaii sources (checked 2026-10-19, hand-over notes from the first session)

Status 2026-10-19: pipeline built (web 4,075 restaurants, app 3,883), leaderboard published privately, Nick's brand calls made,
app ported and compiling. See CLAUDE.md for the rules and commands.

## Done
- Overture 2026-09-23.1: 74,864 HI places in the box. **8,600 eating/drinking listings** (`data/hi/overture_hi_*.parquet`).
  Overture has **no Hawaii address points**, so address placement has to use the Census geocoder.
  The Overture state and Honolulu County outlines reach the NW islands (to 178°W), so they are clipped to the main-islands box.
- State GIS (geodata.hawaii.gov, robots OK), public domain: island coastlines with an `isle` field (Terrestrial/MapServer/3),
  2020 Census county lines (Census/29) -> `data/hi/hi_islands.geojson`, `hi_counties.geojson` and `hi_shapes.json` (46 KB, used for the header and maps).
  2020 Census Designated Places are Census/28: 163 CDPs. Use them to assign towns (Kailua on Oʻahu vs Kailua-Kona, and Lahaina CDP for the fire rule).
  CDP names come without diacritics, so the official spellings still need a source.
- UCSD Google 2021 `data/ucsd/meta-Hawaii.json.gz` (web build only; mcauleylab has no robots.txt).

## Official sources: verdicts (pipeline/check_sources.py, RFC 9309)
- DOH placard rule HAR §11-50-9 (2025 text, `health.hawaii.gov/san/files/2025/09/HAR-11-50-2025-searchable.pdf`):
  - green = zero or one critical violation, corrected during the inspection (or a follow-up verified the fix)
  - yellow = a critical violation uncorrected, or two or more critical violations
  - red = imminent health hazard, closure
  - The 2018 handout still points to hi.healthinspections.us (dead).
- inspections.myhealthdepartment.com/soh: robots.txt answers 403, so it's a bot check. **Not usable.** Check per-place links by hand only.
- opendata.hawaii.gov (CKAN; `/api/` disallowed, dataset pages and resource downloads allowed), license "ocd-by" (its meaning isn't checked yet):
  - oahu-food-establishments: 6,095 permits, 1st inspections 2010–2013, expiry 2012–2014 (a late-2013 snapshot). Columns include Permit Holder and Telephone: **never show** those.
  - statewide-food-est-list11-2011: 10,163 rows with shifted, garbled columns.
  - Both are history hints only. Saved in `data/raw/src/`.
- data.honolulu.gov catalog: no food, liquor or inspection data.
- Liquor: no list can be fetched automatically.
  - mauicounty.gov: 403 bot check, so **Nick downloads the Maui FY2026-27 PDF (DocumentCenter/View/150480) by hand** if he wants it.
  - honolulu.gov: robots.txt disallows ClaudeBot for the whole site.
  - kauai.gov: robots.txt disallows the "Public-Inquiry-on-Active-Licensees" page.
  - hawaiicounty.gov: 403.
- Statewide TMKs (ParcelsZoning/25): May 2026, no values, county qPublic terms. Skip the property board.
- MICHELIN: guide.michelin.com answers 202 (bot challenge) to any page, so the 404 has to be re-checked by hand in a browser. jamesbeard.org: robots allows.

## Calibration (2026-10-19, data/hi/calibration.json)
- Share of each listing group on DOH's 2011 permit list: Meta ≥0.95 32%, Foursquare-only 28%, Meta 0.90–0.95 + web 21%, Meta <0.90 7%.
  The old list favors old listings whatever their state, so Google 2021 "open" (Meta ≥0.95 68%, Foursquare-only 23%, Meta <0.90 6.5%)
  set the rule: keep Idaho's app rule (Meta ≥0.95, Meta 0.90–0.95 with a website, brand feeds, hand-checked).
- App rule vs BLS QCEW NAICS 722 (2026 Q1): Honolulu 2,565 / 3,179; Maui 539 / 608; Hawaiʻi 617 / 593; Kauaʻi 347 / 326.
- 38% of 2011 restaurant/liquor permits and 18% of 2013 Oʻahu permits are still found among the listings (closures and gaps together).

## Next steps
1. Hand-checked research (data/research/app/*.json, jbf.json), each entry with a 2025-26 source on a robots-checked host: plate lunch
   and drive-ins, poke (fish markets yes, supermarkets no), saimin, shave ice, malasadas and bakeries, Hawaiian food and okazuya, loco
   moco and musubi, Lahaina's reopened places, oldest places, James Beard (Helena's, Hamura's, Manago Hotel, Fête, Bar Leather Apron).
2. Website link check (pipeline/check_websites.py), then the generated site (scripts/make-site.py, qa-site.py) and the web app.
3. Unit tests on our own simulator; rewrite the UI tests for Hawaii's guides; screenshots.
4. Nick: Maui licensee PDF by hand (optional), UIPA request decision, repo/Pages, Cloudflare CNAME hawaii, ASC record, USPTO check.
