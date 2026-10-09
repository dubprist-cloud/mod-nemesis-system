#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Headless harness: run the REAL Data.lua + MapData.lua and exercise zone cycling."""
import io
import sys

try:
    import lupa
except ImportError:
    print("lupa missing")
    sys.exit(2)

ADDON = r"E:/SERVER/Core/azerothcore-wotlk/modules/mod-nemesis-system/ClientAddon/NemesisTracker/"

rt = lupa.LuaRuntime(unpack_returned_tuples=True)
lua = rt


def run(code):
    return lua.execute(code)


def load(path):
    src = io.open(path, "r", encoding="utf-8").read()
    return lua.execute(src)


# ------------------------------------------------------------------ WoW stubs
run("""
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
time = os.time
GetRealZoneText = function() return "Ashenvale" end
GetAreaInfo = function() return nil end
date = os.date
""")

# NT namespace pieces that live in Core.lua / Lifecycle.lua
run("""
NemesisTracker = {}
NT = NemesisTracker
NT.L = setmetatable({}, { __index = function(_, k) return k end })
NT.relationOrder = { own = 1, party = 2, guild = 3, public = 4 }
NT.sourceOrder = { ["peer-sync"] = 1, ["local-cache"] = 1, ["server-bootstrap"] = 2,
                   ["rank5-broadcast"] = 3, ["server-validated"] = 4 }
NT.db = { fadeAfterSeconds = 600, staleAfterSeconds = 1800, hideAfterSeconds = 7200 }
NT.UI = nil
NT.data = {
    nemeses = {}, ordered = {}, chunks = {}, page = 1,
    currentFilter = "all", currentScope = "all", currentSearch = "",
    displayedZoneId = nil, displayedZoneName = nil, displayedZoneKey = nil,
    selectedSpawnId = nil, filteredCount = 0, lastReportBySpawnId = {},
}
""")

# ------------------------------------------------------------------ real files
load(ADDON + "MapData.lua")
load(ADDON + "Data.lua")
print("Data.lua + MapData.lua loaded OK")

# ------------------------------------------------------------------ sample data
run("""
local now = time()
local samples = {
    { spawnId = 1, name = "A", zoneId = 331,  zoneName = "Ashenvale",            lastSeenAt = now - 120,  relation = "public", rank = 1 },
    { spawnId = 2, name = "B", zoneName = "Ashenvale",            zoneId = 331,  lastSeenAt = now - 300,  relation = "own",    rank = 5 },
    { spawnId = 3, name = "C", zoneName = "Winterspring",         zoneId = 618,  lastSeenAt = now - 480,  relation = "public", rank = 2 },
    { spawnId = 4, name = "D", zoneName = "Nagrand",              zoneId = 3519, lastSeenAt = now - 420,  relation = "public", rank = 1 },
    { spawnId = 5, name = "E", zoneName = "Dragonblight",         zoneId = 65,   lastSeenAt = now - 480,  relation = "party",  rank = 1 },
    { spawnId = 6, name = "F", zoneName = "Netherstorm",          zoneId = 3523, lastSeenAt = now - 480,  relation = "public", rank = 1 },
}
for _, n in ipairs(samples) do
    n.zoneKey = NT:GetZoneKey(n.zoneId, n.zoneName)
    n.lastSeenSource = "server-bootstrap"
    NT.data.nemeses[n.spawnId] = n
end
""")

count = run("return #NT:GetAvailableZones()")
print("zone count:", count)

for i in range(1, int(count) + 1):
    z = run("local t = NT:GetAvailableZones(); return t[%d].zoneName" % i)
    print("   %d. %s" % (i, z))

# ------------------------------------------------------------------ cycle
run("NT:SelectDisplayedZone(NT:GetAvailableZones()[1].zoneId, NT:GetAvailableZones()[1].zoneName, NT:GetAvailableZones()[1].zoneKey)")
print("\nstart zone:", run("return tostring(NT.data.displayedZoneName)"))

for step in range(1, int(count) + 2):
    run("NT:ChangeDisplayedZone(1)")
    print("  after > (%d): %s" % (step, run("return tostring(NT.data.displayedZoneName)")))

run("NT:ChangeDisplayedZone(-1)")
print("  after <    :", run("return tostring(NT.data.displayedZoneName)"))
