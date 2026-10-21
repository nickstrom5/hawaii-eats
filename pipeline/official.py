"""Official records for Hawaii.

Hawaii has no current list of food or liquor businesses we can read (playbook/12-sources.md, checked 2026-10-19):
- The DOH Food Safety Branch inspects every food establishment statewide and posts green/yellow/red placards (HAR 11-50), but its
  inspection search (inspections.myhealthdepartment.com/soh) answers robots.txt with 403, and no bulk permit or inspection file is
  published. A bulk extract would take a UIPA request (HRS ch. 92F), which needs Nick's yes.
- Liquor licenses are county-run: Maui posts a licensee PDF, but mauicounty.gov answers our requests with a bot check, so it is read only
  if Nick downloads it by hand into data/raw/official/maui/ (load()); Honolulu's site disallows ClaudeBot, Kauaʻi's robots.txt disallows
  its licensee inquiry, and Hawaiʻi County's answers 403.
- History only: two old DOH permit lists on opendata.hawaii.gov (license "ocd-by"): "OAHU Food Establishments" (6,095 permits, a late-2013
  snapshot; its house-number column was overwritten with the street name and a street-level point) and "Statewide Food Est List11-2011"
  (10,163 rows, end of 2011, columns shifted; the full address is in "Location 1"). load_history() reads them for calibration and
  "on DOH's 2011/2013 permit list" hints, never as proof a place is open now. The Permit Holder, Owner and Telephone columns (often a
  person) are dropped on read and never shown.

Each table: jur, lic (our id), name, dba, holder, keys (name keys), addr, city, zip, county, num, street, lat, lon, kind, active, ltype,
onprem, endorse, expires, year. kind: restaurant | bar | brewery | retail | venue | other.
"""
import os, re, glob, unicodedata
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP".split())


# Hawaii's house numbers carry a zone prefix on Oʻahu and Hawaiʻi Island: "75-5770 Aliʻi Dr", "66-215 Kamehameha Hwy" are one number,
# not a range. A one- or two-digit part, a dash and three or more digits is such a number, and so is a shorter second part below the
# first ("94-50 Farrington Hwy" is 94-050); "1500-02" and "12-14" are still ranges.
_HNUM = re.compile(r"^\s*(\d{1,2})\s*-\s*(\d{1,5})([A-Z]?)\b")


class _HMatch:
    def __init__(self, m):
        self.m = m

    def group(self, i):
        return self.m.group(i)

    def end(self):
        return self.m.end()


class HNUM:
    @staticmethod
    def match(a):
        m = _HNUM.match(a)
        if m and (len(m.group(2)) >= 3 or int(m.group(2)) < int(m.group(1))):
            return _HMatch(m)
        return None


def _fold(a):
    """ʻokina, apostrophes and kahakō out of a street ("Aliʻi" = "Ali'i" = "Alii", "Kalākaua" = "Kalakaua")."""
    a = re.sub(r"[ʻ‘’'`]", "", a)
    return unicodedata.normalize("NFKD", a).encode("ascii", "ignore").decode()


def road(a):
    """One spelling for numbered roads: 'STATE HIGHWAY 19' = 'HI-19' = 'Hwy 19'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", _fold(a).upper())
    a = re.sub(r"\b(HI|SH|I)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:STATE (?:HIGHWAY|HWY|ROAD|RD|ROUTE)|SH|HAWAII (?:HIGHWAY|HWY|BELT ROAD)|HI (?:HIGHWAY|HWY|ROUTE)|HI|ROUTE)\b(?=\s+\d)", "HWY", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return a


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'2505 Monroe St' -> ('2505', 'MONROE'); '1000 OSAGE STREET' -> ('1000', 'OSAGE'); 'E Sherman Ave' keeps 'SHERMAN'."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    h = HNUM.match(a)
    if h:
        a = f"{h.group(1)}-{h.group(2).zfill(3)}{h.group(3)}" + a[h.end():]   # "94-50" = "94-050"; "75-5770 ALII DR" stays one number
    m = re.match(r"^\s*(\d+(?:-\d{3,5}(?=[A-Z]?\s))?)[A-Z]?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if w in TYPES and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core]
    return m.group(1), " ".join(core[:3]) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def street_nums(a):
    """'157-159 W Main St' -> {'157', '159'}; '2505 Monroe St' -> {'2505'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    h = HNUM.match(a)
    if h:
        return {h.group(1) + "-" + h.group(2).zfill(3)}
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|CATERING|SPECIAL EVENT|TEMP(?:ORARY)? EVENT|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out


def _col(df, *pats):
    """The first column whose name matches one of the patterns (the export's headers aren't documented)."""
    for p in pats:
        for c in df.columns:
            if re.fullmatch(p, str(c).strip(), flags=re.I):
                return c
    return None


def liq_kind(ltype, endorse, onprem, name=""):
    """An ABC license -> kind. Liquor by the drink and on-premises beer or wine mean a bar or restaurant serving alcohol; off-premises
    beer and wine is a store (groceries, gas stations); manufacturers (breweries, wineries, distilleries) count as makers."""
    t = f"{ltype or ''} {endorse or ''}".upper()
    if re.search(r"BREW|WINERY|WINE MAKER|DISTILL|MANUFACTUR", t):
        return "brewery"
    if re.search(r"WHOLESAL|DISTRIBUT|IMPORT|DIRECT SHIP|CARRIER|WAREHOUSE", t):
        return "other"
    if onprem is True or re.search(r"LIQUOR BY THE DRINK|BY THE DRINK|ON[- ]PREM|RESTAURANT", t):
        return "restaurant" if re.search(r"RESTAURANT", t) else "bar"
    if onprem is False:
        return "retail"
    return None


COLS = ["jur", "lic", "name", "dba", "holder", "keys", "addr", "city", "zip", "county", "num", "street", "lat", "lon", "kind", "active",
        "ltype", "onprem", "endorse", "expires", "year"]


def load_licenses():
    """Current licenses: none can be fetched automatically. A Maui licensee PDF Nick saves by hand would be parsed here (not written
    until one exists, so its layout is read, not guessed)."""
    files = sorted(glob.glob(f"{OFF}/maui/*.pdf"))
    if files:
        print("Maui licensee PDF present but its parser isn't written yet:", files)
    return pd.DataFrame(columns=COLS)


def _kind11(t):
    t = (t or "").upper()
    if re.search(r"LIQUOR", t):
        return "bar"
    if re.search(r"RESTAURANT|SIT DOWN|TAKE OUT|LIMITED MENU|FROZEN DESSERT|BAKERY", t):
        return "restaurant"
    if re.search(r"GROCERY|SUPERMARKET|MARKET|RETAIL", t):
        return "retail"
    if re.search(r"LUNCHWAGON|CART|MOBILE|SCHOOL|DAY CARE|HOSPITAL|COMMISSARY|CATERING|MANUFACTUR|WAREHOUSE|MEAL SITE|SERVICE AREA|INSTITUTIONAL", t):
        return "other"
    return "other"


def load_history():
    """The 2011 statewide and 2013 Oʻahu DOH permit lists (see above). Read-only history; never 'active'."""
    rows = []
    p11 = os.path.join(RAW, "src", "state11.csv")
    if os.path.exists(p11):
        d = pd.read_csv(p11, dtype=str, keep_default_na=False)
        for i, r in d.iterrows():
            loc = [x.strip() for x in (r.get("Location 1") or "").split("\n") if x.strip()]
            if len(loc) < 2:
                continue
            addr = loc[0]
            m = re.match(r"^(.*?),\s*(?:HAWAII\s+)?(\d{5})?", loc[1])
            city, z = (m.group(1).strip(), m.group(2) or "") if m else (loc[1], "")
            ll = re.search(r"\(([-\d.]+),\s*([-\d.]+)\)", loc[2]) if len(loc) > 2 else None
            num, st = street_key(addr)
            nm = (r.get("EstName") or "").strip()
            rows.append({"jur": "doh11", "lic": f"DOH11-{i}", "name": nm, "dba": nm, "holder": None, "keys": _names(nm), "addr": addr,
                         "city": city.title(), "zip": z, "county": None, "num": num, "street": st,
                         "lat": float(ll.group(1)) if ll else np.nan, "lon": float(ll.group(2)) if ll else np.nan,
                         "kind": _kind11(r.get("EstType1")), "active": False, "ltype": (r.get("EstType1") or "").strip(), "onprem": None,
                         "endorse": "", "expires": None, "year": 2011})
    p13 = os.path.join(RAW, "src", "oahu_food.csv")
    if os.path.exists(p13):
        d = pd.read_csv(p13, dtype=str, keep_default_na=False).drop(columns=["Permit Holder", "Telephone", "Mailing Care Of"], errors="ignore")
        for _, r in d.iterrows():
            st_name = (r.get("Establishment Address Street Name") or "").strip()
            ll = re.search(r"\(([-\d.]+),\s*([-\d.]+)\)", r.get("Establishment Address Street #") or "")
            nm = re.sub(r",?\s+(?:LLC|INC|CORP|LTD)\.?$", "", (r.get("Establishment") or "").strip(), flags=re.I)
            _, st = street_key("1 " + st_name)
            rows.append({"jur": "doh13", "lic": "DOH13-" + (r.get("Establishment Permit #") or "").strip(), "name": nm, "dba": nm, "holder": None,
                         "keys": _names(nm), "addr": st_name, "city": (r.get("Establishment Address City") or "").title(),
                         "zip": (r.get("Establishment Address Zip Code") or "")[:5], "county": "Honolulu County", "num": None, "street": st,
                         # a street-level point (the house number was lost), good to about a street's length
                         "lat": float(ll.group(1)) if ll else np.nan, "lon": float(ll.group(2)) if ll else np.nan,
                         "kind": "restaurant", "active": False, "ltype": (r.get("Risk Category") or "").strip(), "onprem": None, "endorse": "",
                         "expires": (r.get("Permit Expire Date") or "")[:10] or None, "year": 2013})
    return pd.DataFrame(rows, columns=COLS)


def load():
    df = load_licenses().reset_index(drop=True)
    # one business can hold several licenses (beer, wine and liquor; a restaurant and its bar): same address and a name in common
    df["biz"] = np.arange(len(df))
    town = df.city.fillna("").str.upper().str.strip()
    for num, g in df[df.num.notna() & df.street.notna()].groupby("num"):
        idx = list(g.index)
        if len(idx) < 2:
            continue
        for x in range(len(idx)):
            for y in range(x + 1, len(idx)):
                a, b = idx[x], idx[y]
                if not street_compat(df.at[a, "street"], df.at[b, "street"]):
                    continue
                if not ((df.at[a, "zip"] and df.at[a, "zip"] == df.at[b, "zip"]) or (town[a] and town[a] == town[b])):
                    continue
                ka, kb = df.at[a, "keys"], df.at[b, "keys"]
                if not ka or not kb:
                    continue
                if any(name_sim(p, q) >= 85 or ((_stems(p) - GENERIC) & (_stems(q) - GENERIC)) for p in ka for q in kb):
                    old, new = df.at[b, "biz"], df.at[a, "biz"]
                    df.loc[df.biz == old, "biz"] = new
    return df
