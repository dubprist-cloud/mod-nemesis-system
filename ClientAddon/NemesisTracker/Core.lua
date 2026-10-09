local addonName = ...

local existingNamespace = NemesisTracker or {}

NemesisTracker = LibStub("AceAddon-3.0"):NewAddon("NemesisTracker", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0")
local NT = NemesisTracker
NT.L = LibStub("AceLocale-3.0"):GetLocale("NemesisTracker")

NT.MapData = existingNamespace.MapData or NT.MapData or {}
NT.UI = existingNamespace.UI or NT.UI or {}

NT.prefix = "Nemesis"
NT.peerPrefix = "NemesisV2P"
NT.relationOrder = { own = 1, party = 2, guild = 3, public = 4 }
NT.sourceOrder = { ["peer-sync"] = 1, ["local-cache"] = 1, ["server-bootstrap"] = 2, ["rank5-broadcast"] = 3, ["server-validated"] = 4 }
NT.db = NT.db or {}
NT.data = NT.data or {
    nemeses = {},
    ordered = {},
    chunks = {},
    selectedSpawnId = nil,
    displayedZoneId = nil,
    displayedZoneName = nil,
    displayedZoneKey = nil,
    bootstrapExpected = 0,
    bootstrapActive = false,
    lastSyncAt = 0,
    lastServerTime = 0,
    connectionState = "idle",
    currentFilter = "all",
    currentScope = "zone",
    currentSearch = "",
    page = 1,
    filteredCount = 0,
    lastReportBySpawnId = {},
    top = {},
    topReceived = false,
    -- The requester's own standing, sent as V2:TOP_SELF when they are not inside the
    -- returned top. nil means "no separate line needed" (they are already in the list).
    topSelf = nil,
    -- bit -> { name, desc }, sent by the server so descriptions always match its config.
    affixCatalog = {},
}

