"""How often is a map listing a real restaurant? Hawaii's measurements -> data/hi/calibration.json and calibration_app.json

Adapted from id-eats/pipeline/calibrate.py. Hawaii publishes no current list of food or liquor businesses we can read (official.py), so:
- DOH's end-of-2011 statewide permit list: the share of each listing-source group that matches a 2011 restaurant, take-out or liquor
  permit (same name at the same address or within 150 m). Places that opened after 2011 can't match, so this is a lower bound that
  compares sources; it doesn't measure them. The other direction (2011 permits still found among 2026 listings) mixes closures with
  coverage gaps and is reported as such.
- DOH's late-2013 Oʻahu list, whose house numbers were lost: a near-exact name on the same street within 2 km.
- BLS QCEW 2026 Q1 private eating and drinking places (NAICS 722) per county, as given in HAWAII_PROMPT.md (data.bls.gov disallows
  automated agents, so the numbers are not re-fetched): listings kept by the app rule against those counts.
- Web build only: the share of each source group that Google's Sep 2021 snapshot also lists as open (corroboration, not proof).
- For reference, Colorado's full-list measurement (Denver's food licenses, same Overture release), read from
  ../co-eats/data/co/calibration_app.json when it exists. Nothing in co-eats is modified.
"""
import json, math, os
import numpy as np, pandas as pd
from common import HI, ROOT, name_sim, norm_name
from listings_util import official_match
from official import load_history, street_compat

o = pd.read_pickle(f"{HI}/stage1.pkl")
H = load_history()
base = ~o.j_junk & ~o.j_outside & ~o.ov_closed & ~o.j_closedname & ~o.lahaina_cdp
L = o[base].reset_index(drop=True)
QCEW = {"Honolulu County": 3179, "Maui County": 608, "Hawaiʻi County": 593, "Kauaʻi County": 326}   # NAICS 722, 2026 Q1 (prompt)


def groups(L):
    s, conf = L.src.fillna("none"), L.confidence.fillna(0)
    web = L.n_web.fillna(0) > 0
    return np.select([(s == "meta") & (conf >= 0.95), (s == "meta") & (conf >= 0.9) & web, (s == "meta") & (conf >= 0.9),
                      s.isin(["AllThePlaces", "DAC"]), (s == "BrightQuery") & (conf >= 0.95), s == "meta", s == "Foursquare", s == "BrightQuery",
                      s == "Microsoft"],
                     ["meta >= 0.95", "meta 0.90-0.95 + website", "meta 0.90-0.95, no website", "brand feed", "BrightQuery >= 0.95",
                      "meta < 0.90", "Foursquare only", "BrightQuery < 0.95", "Microsoft only"], "other")


L["grp"] = groups(L)
APP_KEEP = {"meta >= 0.95", "meta 0.90-0.95 + website", "brand feed"}
out = {"listings": int(len(L)), "groups": {}, "per_county": {}, "lahaina_cdp_dropped": int(o.lahaina_cdp.sum())}
g21 = L.groupby("grp").agg(n=("id", "size"), google21_open=("in21", lambda s_: float((s_ & ~L.loc[s_.index, "closed21"]).mean())))
for g, r in g21.iterrows():
    out["groups"][g] = {"n": int(r.n), "google21_open": round(float(r.google21_open), 3), "app_keep": g in APP_KEEP}
print(f"== {len(L)} cleaned, open listings (Lahaina CDP excluded); share Google 2021 also lists as open, by source group")
print(g21.assign(google21_open=(g21.google21_open * 100).round(1)).sort_values("n", ascending=False).to_string())

# ---------------------------------------------------------------- DOH 2011 statewide permits (restaurants, take-out, liquor dispensers)
R11 = H[(H.jur == "doh11") & H.kind.isin(["restaurant", "bar"])].reset_index(drop=True)
m11 = official_match(L, R11)
L["doh11"] = L.index.map(lambda i: i in m11)
found11 = set(m11.values())
# ---------------------------------------------------------------- DOH 2013 Oʻahu permits: same street, near-exact name, within 2 km
R13 = H[H.jur == "doh13"].reset_index(drop=True)
by_st = {}
for j, st in enumerate(R13.street):
    if isinstance(st, str) and st:
        by_st.setdefault(st.split()[0], []).append(j)
from official import street_key
m13 = {}
for i, (k, a, la, lo, isl) in enumerate(zip(L.k, L.street, L.lat, L.lon, L.island)):
    if isl != "Oʻahu" or not k:
        continue
    _, st = street_key(a)
    if not st:
        continue
    best = None
    for j in by_st.get(st.split()[0], []):
        if not street_compat(st, R13.street.iat[j]):
            continue
        rl, ro = R13.lat.iat[j], R13.lon.iat[j]
        if rl == rl and math.hypot((rl - la) * 111000, (ro - lo) * 104000) > 2000:
            continue
        s = max((name_sim(k, rk) for rk in R13["keys"].iat[j]), default=0)
        if s >= 88 and (best is None or s > best[0]):
            best = (s, j)
    if best:
        m13[i] = best[1]
L["doh13"] = L.index.map(lambda i: i in m13)
bygrp = L.groupby("grp").agg(n=("id", "size"), doh11=("doh11", "mean"))
oahu = L[L.island == "Oʻahu"].groupby("grp").doh13.mean()
print("\n== matched to a DOH permit: statewide 2011 list (any island) and the 2013 Oʻahu list (Oʻahu listings only); lower bounds")
print(bygrp.assign(doh11=(bygrp.doh11 * 100).round(1), doh13_oahu=(oahu * 100).round(1)).sort_values("n", ascending=False).to_string())
for g, r in bygrp.iterrows():
    out["groups"][g]["doh2011"] = round(float(r.doh11), 3)
    if g in oahu.index:
        out["groups"][g]["doh2013_oahu"] = round(float(oahu[g]), 3)
out["doh2011_food_permits"] = int(len(R11))
out["doh2011_found_in_listings"] = round(len(found11) / max(1, len(R11)), 3)
out["doh2013_oahu_permits"] = int(len(R13))
out["doh2013_found_in_listings"] = round(len(set(m13.values())) / max(1, len(R13)), 3)
print("2011 restaurant/liquor permits still found among the listings:", out["doh2011_found_in_listings"], "of", len(R11),
      "| 2013 Oʻahu permits found:", out["doh2013_found_in_listings"], "of", len(R13), "(closures and coverage gaps together)")

per = L.groupby("county").agg(listings=("id", "size"), app_rule=("grp", lambda s_: int(s_.isin(APP_KEEP).sum())), doh2011=("doh11", "mean"))
per["qcew_722"] = [QCEW.get(c) for c in per.index]
print("\n== per county (QCEW counts private eating and drinking employers, including caterers and food-service contractors)\n" + per.round(3).to_string())
out["per_county"] = {c: {k: (round(float(v), 3) if isinstance(v, float) else (int(v) if v == v and v is not None else None)) for k, v in r.items()}
                     for c, r in per.iterrows()}
out["per_island"] = {k: int(v) for k, v in L.groupby("island").size().items()}
out["qcew_note"] = "BLS QCEW 2026 Q1, NAICS 722, private, as given in HAWAII_PROMPT.md (data.bls.gov disallows automated agents)"

co = os.path.join(ROOT, "..", "co-eats", "data", "co", "calibration_app.json")
if os.path.exists(co):
    den = json.load(open(co)).get("Denver", {})
    out["reference_colorado_denver"] = {"note": "Colorado's measurement against Denver's full food-license list, same Overture release",
                                        "groups": den.get("groups"), "listings": den.get("listings")}
json.dump(out, open(f"{HI}/calibration.json", "w"), indent=1, ensure_ascii=False)
app = {**out, "groups": {g: {k: v for k, v in d.items() if k != "google21_open"} for g, d in out["groups"].items()}}
assert "google" not in json.dumps(app).lower()
json.dump(app, open(f"{HI}/calibration_app.json", "w"), indent=1, ensure_ascii=False)
L[["id", "doh11", "doh13"]].to_pickle(f"{HI}/doh_match.pkl")
