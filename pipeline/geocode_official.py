"""Current official records -> data/hi/official.pkl (official.load() with lat/lon/geo columns).

Hawaii has none today (official.py), and Overture has no Hawaii address points, so a license list Nick saves by hand would be placed
by geocode_census.py. This step only writes the (possibly empty) table hawaii.py reads.
"""
import numpy as np
from common import HI
import official

F = official.load()
F["geo"] = np.where(F.lat.notna(), "source", None) if len(F) else []
F.to_pickle(f"{HI}/official.pkl")
print("official records:", len(F))
