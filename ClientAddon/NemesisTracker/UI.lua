NemesisTracker = NemesisTracker or {}
local NT = NemesisTracker

NT.UI = NT.UI or {}
local UI = NT.UI
local L = NT.L

-- ------------------------------------------------------------------ palette
-- Same palette as the Guild Hegemony and Battle Pass windows, so the three
-- addons read as one product.
local GOLD    = { 0.72, 0.58, 0.25, 0.80 }
local GOLD_HI = { 0.95, 0.78, 0.35, 1.00 }
local DARK    = { 0.04, 0.04, 0.065, 0.95 }
local CARD    = { 0.06, 0.06, 0.09, 1.00 }
local TEXT    = { 0.90, 0.90, 0.92 }
local MUTED   = { 0.55, 0.55, 0.60 }

-- A plain white 1px texture, tinted per use. The usual candidates on this client
-- render as a solid green "not loaded" rectangle.
local WHITE = "Interface\\ChatFrame\\ChatFrameBackground"

local DEFAULT_ROW_HEIGHT = 48
local COMPACT_ROW_HEIGHT = 38
local MAX_ROW_COUNT = 9
-- The "public" relation is deliberately not offered as a button; the unfiltered
-- "All" view already covers it. Dropping it here also narrows the control row.
local FILTERS = {
    { key = "all", label = L["All"] },
    { key = "own", label = L["Own"] },
    { key = "party", label = L["Party"] },
    { key = "guild", label = L["Guild"] },
}

local SCOPES = {
    { key = "all", label = L["All Zones"] },
    { key = "zone", label = L["This Map"] },
}

local MAP_VERTICAL_STRETCH = 1.14
local MAP_HORIZONTAL_STRETCH = 1.03
local MAP_MARKER_Y_LIFT = 0.08
local MAP_MARKER_X_LIFT = 0.02

-- The window is fixed-size: the control row and the map are laid out for exactly
-- this box, so resizing is disabled rather than letting the panels drift.
local WINDOW_W = 860
local WINDOW_H = 520
local CONTROL_Y = -40        -- the single row of controls, above the map
local CONTENT_Y = -68        -- list and map both start here
local LIST_W = 256

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function modulo(value, divisor)
    if math.fmod then
        return math.fmod(value, divisor)
    end

    return value - math.floor(value / divisor) * divisor
end

-- Gold 1px border with a dark interior. The two textures MUST live in separate
-- layers: on 3.3.5a two textures in one layer do not reliably draw in declaration
-- order, which renders a bordered panel as a solid gold slab.
-- borderAlpha lets a nested panel (the map, list rows) use a quieter rim.
local function createBackdrop(frame, borderAlpha)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(WHITE)
    bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], borderAlpha or 0.80)
    frame.Bg = bg

    local inner = frame:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    inner:SetTexture(WHITE)
    inner:SetVertexColor(DARK[1], DARK[2], DARK[3], DARK[4])
    frame.Inner = inner

    -- Compatibility shims: the existing call sites still use the SetBackdrop API.
    function frame:SetBackdropColor(r, g, b, a)
        self.Inner:SetVertexColor(r or 0, g or 0, b or 0, a or 1)
    end
    function frame:SetBackdropBorderColor(r, g, b, a)
        self.Bg:SetVertexColor(r or 0, g or 0, b or 0, a or 1)
    end

    return frame
end

-- A button in the shared chrome style. It carries its own SetText so every
-- existing `button:SetText(...)` call site keeps working.
--
-- Enable/Disable are overridden because the tracker uses Disable() for two very
-- different meanings: on the filter/scope rows it marks the ACTIVE choice (which
-- should read as highlighted), while on the page arrows it means "no further
-- page" (which should read as unavailable). Buttons opt into the first meaning
-- with `toggleStyle = true`.
local function makeButton(parent, text, w, h, tooltipFn)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w or 90)
    b:SetHeight(h or 22)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(WHITE)
    b.Bg = bg

    local border = b:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    border:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    border:SetTexture(WHITE)
    b.Border = border

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    fs:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
    fs:SetText(text or "")
    b.Text = fs

    local function Look(active, hover)
        if active then
            bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.40)
            border:SetVertexColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3], 0.95)
        elseif hover then
            bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.35)
            border:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.90)
        else
            bg:SetVertexColor(DARK[1], DARK[2], DARK[3], 0.95)
            border:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.65)
        end
        fs:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
    end

    local function LookUnavailable()
        bg:SetVertexColor(DARK[1], DARK[2], DARK[3], 0.55)
        border:SetVertexColor(MUTED[1], MUTED[2], MUTED[3], 0.30)
        fs:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    end

    function b:SetText(value)
        self.Text:SetText(value or "")
    end

    local baseEnable, baseDisable = b.Enable, b.Disable
    function b:Enable()
        if baseEnable then baseEnable(self) end
        Look(false, false)
    end
    function b:Disable()
        if baseDisable then baseDisable(self) end
        if self.toggleStyle then
            Look(true, false)
        else
            LookUnavailable()
        end
    end

    -- Toggle the look WITHOUT disabling. A disabled Button stops receiving mouse input
    -- on this client, so disabling a toggle made it impossible to click a second time.
    function b:SetActive(on)
        self.active = on and true or false
        Look(self.active, false)
    end

    Look(false, false)
    b:SetScript("OnEnter", function(self)
        Look(not self:IsEnabled(), true)
        if tooltipFn then
            local line = tooltipFn()
            if line then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(line)
                GameTooltip:Show()
            end
        end
    end)
    b:SetScript("OnLeave", function(self)
        Look(not self:IsEnabled(), false)
        if tooltipFn then
            GameTooltip:Hide()
        end
    end)

    return b
end

-- Affix bits as the server packs them into affixMask. Descriptions mirror the
-- module's default configuration; the server does not ship them per nemesis.
local AFFIX_DESCRIPTIONS = {
    { bit = 1,  key = "AFFIX_DESC_VAMPIRIC" },
    { bit = 2,  key = "AFFIX_DESC_SWIFT" },
    { bit = 4,  key = "AFFIX_DESC_JUGGERNAUT" },
    { bit = 8,  key = "AFFIX_DESC_SAVAGE" },
    { bit = 16, key = "AFFIX_DESC_SPELLWARD" },
    { bit = 32, key = "AFFIX_DESC_ENRAGED" },
    { bit = 64, key = "AFFIX_DESC_REGEN" },
}

-- 3.3.5a has the bit library, but plain arithmetic keeps this independent of it.
local function hasAffixBit(mask, bit)
    return (mask or 0) % (bit * 2) >= bit
end

-- Optional waypoint hand-off. TomTom is NOT part of the client, so this stays a
-- no-op unless the player installs it; the coordinates are printed to chat anyway.
local function TrySetWaypoint(mapId, zoneId, x, y, title)
    if not TomTom then
        return false
    end

    -- TomTom's signature differs between its WotLK releases, so try both shapes.
    if TomTom.AddZWaypoint then
        if pcall(TomTom.AddZWaypoint, TomTom, mapId, zoneId, x, y, title, false) then
            return true
        end
    end

    if TomTom.AddWaypoint then
        if pcall(TomTom.AddWaypoint, TomTom, mapId, x, y, { title = title, from = "NemesisTracker" }) then
            return true
        end
    end

    return false
end

local function AnnounceWaypoint(nemesis)
    if not nemesis then
        return
    end

    local zoneName = NT:GetLocalizedZoneName(nemesis.zoneId, nemesis.zoneName)
    local title = string.format("%s - %s", nemesis.name or L["Nemesis"], zoneName)
    local x, y, z = nemesis.x or 0, nemesis.y or 0, nemesis.z or 0

    if TrySetWaypoint(nemesis.mapId or 0, nemesis.zoneId or 0, x, y, title) then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(L["Waypoint set: %s"], title))
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(L["Nemesis waypoint: %s - %s (%.1f, %.1f, %.1f)"], nemesis.name or L["Nemesis"], zoneName, x, y, z))
end

-- Lays controls out left to right inside one row: every new frame is anchored to
-- the right of the previous one, so the row never leaves a gap when a control is
-- added or removed. lastControl is just a cursor stored on the row frame.
local function placeControl(row, frame, gap)
    if row.lastControl then
        frame:SetPoint("LEFT", row.lastControl, "RIGHT", gap, 0)
    else
        frame:SetPoint("LEFT", row, "LEFT", 0, 0)
    end
    row.lastControl = frame
end

local function relationColor(relation)
    if relation == "own" then
        return 1.0, 0.2, 0.2
    end
    if relation == "party" then
        return 0.3, 0.6, 1.0
    end
    if relation == "guild" then
        return 0.2, 0.9, 0.4
    end
    return 1.0, 0.82, 0.0
end

local function threatColor(threat)
    if threat == "extreme" then
        return 1.0, 0.1, 0.1
    end
    if threat == "high" then
        return 1.0, 0.45, 0.1
    end
    if threat == "medium" then
        return 1.0, 0.82, 0.0
    end
    return 0.4, 1.0, 0.4
end

local function rankColor(rank)
    local r = rank or 1
    if r >= 5 then return 0.6, 0.2, 1.0 end
    if r == 4 then return 1.0, 0.2, 0.2 end
    if r == 3 then return 1.0, 0.6, 0.0 end
    if r == 2 then return 1.0, 0.9, 0.0 end
    return 0.2, 0.9, 0.2
end

local function getMarkerTexCoord(rank)
    local iconIndex = math.max(0, math.min(7, (rank or 1) - 1))
    local left = iconIndex * 0.125
    return left, left + 0.125, 0, 0.125
end

function UI:GetRowHeight()
    if NT.db and NT.db.compactList then
        return COMPACT_ROW_HEIGHT
    end

    return DEFAULT_ROW_HEIGHT
end

function UI:LayoutRows()
    if not self.rows or not self.list then
        return
    end

    local rowHeight = self:GetRowHeight()
    local visibleRows = NT:GetVisibleRows()
    self.list:SetHeight((rowHeight + 2) * visibleRows)

    for index, row in ipairs(self.rows) do
        row:ClearAllPoints()
        row:SetHeight(rowHeight)
        row:SetWidth(250)
        if index == 1 then
            row:SetPoint("TOPLEFT", self.list, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", self.rows[index - 1], "BOTTOMLEFT", 0, -2)
        end
    end
end

local function getDisplayedNemesis()
    local selected = NT:GetSelectedNemesis()
    if selected then
        return selected
    end

    return NT.data.ordered[1]
end

local function getDisplayedZoneInfo()
    local zoneId, zoneName = NT:EnsureDisplayedZone()
    if not zoneId and not zoneName then
        return nil, nil, nil
    end

    return zoneId, zoneName, NT.data.displayedZoneKey
end

local function isNemesisInZone(nemesis, zoneId, zoneName, zoneMapKey)
    if not nemesis then
        return false
    end

    if zoneMapKey and nemesis.zoneKey then
        return nemesis.zoneKey == zoneMapKey
    end

    if zoneId and zoneId ~= 0 then
        return nemesis.zoneId == zoneId
    end

    if zoneName and zoneName ~= "" then
        return nemesis.zoneName == zoneName
    end

    return false
end

local function getDisplayedZoneCount(zoneId, zoneName, zoneMapKey)
    local count = 0
    for _, nemesis in ipairs(NT:GetMapNemeses()) do
        if isNemesisInZone(nemesis, zoneId, zoneName, zoneMapKey) then
            count = count + 1
        end
    end

    return count
end

function UI:EnsureMapTiles()
    if self.mapTiles then
        return true
    end

    if not NT.MapData or not NT.MapData.tileCount then
        return false
    end

    self.mapTiles = {}
    for index = 1, NT.MapData.tileCount do
        local tile = self.canvas:CreateTexture(nil, "BACKGROUND")
        tile:SetTexture(nil)
        tile:Hide()
        self.mapTiles[index] = tile
    end

    return true
end

function UI:RefreshMapTiles(width, height, zoneId, zoneName)
    if not self:EnsureMapTiles() or not NT.MapData or not NT.MapData.tileColumns or
        not NT.MapData.tileRows or type(NT.MapData.GetTileTexture) ~= "function" then
        for _, tile in ipairs(self.mapTiles or {}) do
            tile:SetTexture(nil)
            tile:Hide()
        end

        if self.mapFallback then
            self.mapFallback:Show()
        end

        if self.mapZoneText then
            if zoneName and zoneName ~= "" then
                self.mapZoneText:SetText(zoneName)
            else
                self.mapZoneText:SetText(L["Map data unavailable"])
            end
        end

        return
    end

    local tileWidth = (width / NT.MapData.tileColumns) * MAP_HORIZONTAL_STRETCH
    local tileHeight = (height / NT.MapData.tileRows) * MAP_VERTICAL_STRETCH
    local hasTexture = false

    for index, tile in ipairs(self.mapTiles) do
        local texturePath = NT.MapData:GetTileTexture(zoneId, zoneName, index)
        if texturePath then
            local column = modulo(index - 1, NT.MapData.tileColumns)
            local row = math.floor((index - 1) / NT.MapData.tileColumns)
            local displayX = column * tileWidth
            local displayY = -(row * tileHeight)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", displayX, displayY)
            tile:SetWidth(tileWidth)
            tile:SetHeight(tileHeight)
            tile:SetTexture(texturePath)
            tile:SetTexCoord(0, 1, 0, 1)
            tile:Show()
            hasTexture = true
        else
            tile:SetTexture(nil)
            tile:Hide()
        end
    end

    if self.mapFallback then
        if hasTexture then
            self.mapFallback:Hide()
        else
            self.mapFallback:Show()
        end
    end

    if self.mapZoneText then
        if zoneName and zoneName ~= "" then
            self.mapZoneText:SetText(zoneName)
        else
            self.mapZoneText:SetText(L["No zone selected"])
        end
    end
end

function UI:FormatLastSeen(lastSeenAt)
    if not lastSeenAt or lastSeenAt <= 0 then
        return L["Unknown"]
    end

    local age = math.max(0, time() - lastSeenAt)
    if age < 60 then
        return string.format(L["%ds"], age)
    end
    if age < 3600 then
        return string.format(L["%dm"], math.floor(age / 60))
    end
    return string.format(L["%dh"], math.floor(age / 3600))
end

function UI:RefreshStatus()
    if not self.statusText then
        return
    end

    local total = NT.data.filteredCount or #NT.data.ordered
    local lastSync = NT.data.lastSyncAt > 0 and date("%H:%M:%S", NT.data.lastSyncAt) or L["never"]
    local state = NT.data.connectionState or "idle"
    local page = NT.data.page or 1
    local maxPage = NT:GetMaxPage()
    local filter = NT.data.currentFilter or "all"
    local scope = NT.data.currentScope or "all"
    local zoneLabel = NT.data.displayedZoneName or L["None"]
    local search = NT.data.currentSearch or ""
    if search ~= "" then
        self.statusText:SetText(string.format(L["State: %s  Filter: %s  Scope: %s  Search: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"], L[state] or state, L[filter] or filter, L[scope] or scope, search, total, page, maxPage, zoneLabel, L[lastSync] or lastSync))
    else
        self.statusText:SetText(string.format(L["State: %s  Filter: %s  Scope: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"], L[state] or state, L[filter] or filter, L[scope] or scope, total, page, maxPage, zoneLabel, L[lastSync] or lastSync))
    end

    if self.pageText then
        self.pageText:SetText(string.format(L["Page %d/%d"], page, maxPage))
    end

    if self.prevPageButton then
        if page > 1 then
            self.prevPageButton:Enable()
        else
            self.prevPageButton:Disable()
        end
    end

    if self.nextPageButton then
        if page < maxPage then
            self.nextPageButton:Enable()
        else
            self.nextPageButton:Disable()
        end
    end

    if self.filterButtons then
        for _, button in ipairs(self.filterButtons) do
            if button.key == (NT.data.currentFilter or "all") then
                button:Disable()
            else
                button:Enable()
            end
        end
    end

    if self.scopeButtons then
        for _, button in ipairs(self.scopeButtons) do
            if button.key == (NT.data.currentScope or "all") then
                button:Disable()
            else
                button:Enable()
            end
        end
    end
end

function UI:RefreshList()
    self:LayoutRows()

    for index, row in ipairs(self.rows) do
        local nemesis = NT:GetPagedNemesis(index)
        if nemesis then
            row.spawnId = nemesis.spawnId
            row.nemesis = nemesis
            row:Show()
            local r, g, b = relationColor(nemesis.relation)
            row.name:SetTextColor(r, g, b)
            row.name:SetText(nemesis.name)
            row.rank:SetText(string.format(L["R%d"], nemesis.rank or 1))
            -- The number is the rank, the colour is the computed threat: it folds in the
            -- rank, the affix count and the level difference, so it reads at a glance.
            local threatR, threatG, threatB = threatColor(nemesis.threatClass)
            row.rank:SetTextColor(threatR, threatG, threatB)
            row.zone:SetText(NT:GetLocalizedZoneName(nemesis.zoneId, nemesis.zoneName))
            row.lastSeen:SetText(self:FormatLastSeen(nemesis.lastSeenAt))
            local alpha = NT:GetVisibilityAlpha(nemesis)
            row:SetAlpha(alpha)
            if NT.data.selectedSpawnId == nemesis.spawnId then
                row:SetBackdropColor(0.21, 0.17, 0.09, 0.95)
            else
                row:SetBackdropColor(CARD[1], CARD[2], CARD[3], 0.92)
            end
        else
            row.spawnId = nil
            row.nemesis = nil
            row:SetAlpha(1.0)
            row:Hide()
        end
    end
end

function UI:RefreshDetails()
end

local TOP_ROWS = 10

-- The own line is pinned to the bottom of the pane, under a separator, so it stays put no
-- matter how many rows the top returned. `place` is 0 when the player has not killed
-- anything this month (or when the server could not work out a position).
function UI:RefreshTopSelf()
    if not self.topSelfRow then
        return
    end

    local me = NT.data.topSelf
    if not me then
        self.topSelfRow:Hide()
        self.topSelfLine:Hide()
        return
    end

    local place = tonumber(me.place) or 0
    local kills = tonumber(me.kills) or 0
    local revenge = tonumber(me.revenge) or 0
    local bounty = tonumber(me.bounty) or 0
    local best = tonumber(me.best) or 0

    if place > 0 then
        self.topSelfRow.place:SetText(place .. ".")
    else
        self.topSelfRow.place:SetText("-")
    end
    self.topSelfRow.name:SetText(me.name or "")

    if kills == 0 and revenge == 0 and bounty == 0 and best == 0 then
        self.topSelfRow.stats:SetText(L["No kills yet this month"])
    else
        self.topSelfRow.stats:SetText(string.format("%d / %d / %d / R%d", kills, revenge, bounty, best))
    end

    -- Ranked players glow gold; an unranked line stays muted so it reads as "not in the top".
    local color = place > 0 and GOLD_HI or MUTED
    self.topSelfRow.place:SetTextColor(color[1], color[2], color[3])
    self.topSelfRow.name:SetTextColor(color[1], color[2], color[3])
    self.topSelfRow.stats:SetTextColor(color[1], color[2], color[3])

    self.topSelfRow:Show()
    self.topSelfLine:Show()
end

function UI:RefreshTop()
    if not self.topPanel then
        return
    end

    local entries = NT.data.top or {}
    local playerName = UnitName("player")

    for index = 1, TOP_ROWS do
        local row = self.topRows[index]
        if not row then
            row = CreateFrame("Frame", nil, self.topPanel)
            row:SetHeight(18)
            row:SetPoint("TOPLEFT", self.topPanel, "TOPLEFT", 12, -52 - (index - 1) * 18)
            row:SetPoint("TOPRIGHT", self.topPanel, "TOPRIGHT", -12, -52 - (index - 1) * 18)

            row.place = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.place:SetPoint("LEFT", row, "LEFT", 0, 0)
            row.place:SetWidth(22)
            row.place:SetJustifyH("LEFT")

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.name:SetPoint("LEFT", row.place, "RIGHT", 4, 0)
            row.name:SetWidth(140)
            row.name:SetJustifyH("LEFT")

            row.stats = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.stats:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            row.stats:SetWidth(160)
            row.stats:SetJustifyH("RIGHT")

            -- Remember the template colours so the own-row highlight can be undone.
            row.nameR, row.nameG, row.nameB = row.name:GetTextColor()
            row.statsR, row.statsG, row.statsB = row.stats:GetTextColor()

            self.topRows[index] = row
        end

        local entry = entries[index]
        if entry then
            row.place:SetText(string.format("%d.", entry.rank or index))
            row.name:SetText(entry.name or "")
            row.stats:SetText(string.format("%d / %d / %d / R%d", entry.kills or 0, entry.revenge or 0, entry.bounty or 0, entry.best or 0))

            -- When the player is inside the top the server does not send a separate line,
            -- so mark the row here instead of duplicating it at the bottom.
            if playerName and entry.name == playerName then
                row.name:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])
                row.stats:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])
            else
                row.name:SetTextColor(row.nameR or 1, row.nameG or 1, row.nameB or 1)
                row.stats:SetTextColor(row.statsR or 1, row.statsG or 1, row.statsB or 1)
            end

            row:Show()
        else
            row:Hide()
        end
    end

    self:RefreshTopSelf()

    if #entries == 0 then
        self.topEmpty:Show()
    else
        self.topEmpty:Hide()
    end
end

function UI:ToggleLeaderboard()
    self.topShown = not self.topShown

    if self.mapPanel then
        if self.topShown then
            self.mapPanel:Hide()
        else
            self.mapPanel:Show()
        end
    end

    if self.topPanel then
        if self.topShown then
            self.topPanel:Show()
            self:RefreshTop()
        else
            self.topPanel:Hide()
        end
    end

    if self.topButton then
        -- SetActive, not Disable: the button has to stay clickable to switch back.
        self.topButton:SetActive(self.topShown)
        -- The label names the pane the click will bring up, so the button doubles as its own
        -- "back" affordance: it reads "Map" while the leaderboard is open.
        self.topButton:SetText(self.topShown and L["Map"] or L["Top"])
    end

    if self.topShown then
        NT:RequestLeaderboard()
    end
end

function UI:RefreshMap()
    if not self.canvas then
        return
    end

    local displayedZoneId, displayedZoneName, displayedZoneKey = getDisplayedZoneInfo()
    local zoneCount = getDisplayedZoneCount(displayedZoneId, displayedZoneName, displayedZoneKey)

    if self.zoomText then
        if zoneCount == 1 then
            self.zoomText:SetText(L["1 creature"])
        else
            self.zoomText:SetText(string.format(L["%d creatures"], zoneCount))
        end
    end

    if self.prevZoneButton then
        if #NT:GetAvailableZones() > 1 then
            self.prevZoneButton:Enable()
        else
            self.prevZoneButton:Disable()
        end
    end

    if self.nextZoneButton then
        if #NT:GetAvailableZones() > 1 then
            self.nextZoneButton:Enable()
        else
            self.nextZoneButton:Disable()
        end
    end

    local width = self.canvas:GetWidth()
    local height = self.canvas:GetHeight()
    if width <= 0 or height <= 0 then
        return
    end

    self:RefreshMapTiles(width, height, displayedZoneId, displayedZoneName)

    for spawnId, marker in pairs(self.markers) do
        marker:Hide()
    end

    for _, nemesis in ipairs(NT:GetMapNemeses()) do
        if isNemesisInZone(nemesis, displayedZoneId, displayedZoneName, displayedZoneKey) then
            local spawnId = nemesis.spawnId
            if spawnId then
                local marker = self.markers[spawnId]
                if not marker then
                    marker = CreateFrame("Button", nil, self.canvas)
                    marker:SetWidth(10)
                    marker:SetHeight(10)
                    marker.texture = marker:CreateTexture(nil, "ARTWORK")
                    marker.texture:SetAllPoints(marker)
                    marker:SetScript("OnClick", function(button)
                        NT:SelectNemesis(button.spawnId)
                    end)
                    marker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    marker:SetScript("OnEnter", function(button)
                        local target = NT.data.nemeses[button.spawnId]
                        if not target then
                            return
                        end
                        GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
                        GameTooltip:SetText(target.name or L["Nemesis"])
                        GameTooltip:AddLine(string.format(L["Level %d  Rank %d - %s"], target.level or 0, target.rank or 1, L[target.rankTier] or target.rankTier or L["Marked"]), 1, 1, 1)
                        GameTooltip:AddLine(NT:GetLocalizedZoneName(target.zoneId, target.zoneName), 0.8, 0.8, 0.8)
                        GameTooltip:AddLine(L["Last Seen: "] .. UI:FormatLastSeen(target.lastSeenAt), 0.7, 0.9, 0.7)
                        GameTooltip:AddLine(L["Reward: "] .. (L[target.rewardClass] or target.rewardClass or L["none"]), 0.8, 0.8, 0.2)
                        GameTooltip:AddLine(L["Threat: "] .. (L[target.threatClass] or target.threatClass or L["low"]), 1.0, 0.4, 0.2)
                        GameTooltip:AddLine(string.format(L["MapX/Y: %.3f, %.3f"], target.mapX or 0, target.mapY or 0), 0.6, 0.6, 1.0)
                        GameTooltip:Show()
                    end)
                    marker:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                    self.markers[spawnId] = marker
                end

                local x = clamp((nemesis.mapX or 0.5) - MAP_MARKER_X_LIFT, 0.03, 0.97)
                local y = clamp((nemesis.mapY or 0.5) - MAP_MARKER_Y_LIFT, 0.03, 0.97)
                marker.spawnId = spawnId
                marker:ClearAllPoints()
                marker:SetPoint("CENTER", self.canvas, "TOPLEFT", (width * MAP_HORIZONTAL_STRETCH) * x, -((height * MAP_VERTICAL_STRETCH) * y))
                marker:Show()
                marker:SetAlpha(NT:GetMapVisibilityAlpha(nemesis))

                marker.texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
                local r, g, b = rankColor(nemesis.rank or 1)
                local isGhost = NT:IsGhostNemesis(nemesis)
                if isGhost then
                    marker.texture:SetVertexColor(r * 0.6, g * 0.6, b * 0.6)
                    marker.texture:SetDesaturated(true)
                    marker:SetScale(0.85)
                else
                    marker.texture:SetVertexColor(r, g, b)
                    marker.texture:SetDesaturated(false)
                    marker:SetScale(1.0)
                end
            end
        end
    end
end

function UI:RefreshAll()
    self:RefreshStatus()
    self:RefreshList()
    self:RefreshDetails()
    self:RefreshMap()
    self:RefreshPlayerMarker()
    self:RefreshGrid()
end

function UI:RefreshPlayerMarker()
    if not self.canvas then
        return
    end

    if not self.playerArrow then
        self.playerArrow = self.canvas:CreateTexture(nil, "OVERLAY")
        self.playerArrow:SetSize(4, 4)
        self.playerArrow:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        self.playerArrow:SetVertexColor(1.0, 1.0, 1.0)
    end

    local _, displayedZoneName = getDisplayedZoneInfo()
    if not displayedZoneName then
        self.playerArrow:Hide()
        return
    end

    if GetRealZoneText() ~= displayedZoneName then
        self.playerArrow:Hide()
        return
    end

    local px, py = GetPlayerMapPosition("player")
    if not px or (px == 0 and py == 0) then
        self.playerArrow:Hide()
        return
    end

    local w = self.canvas:GetWidth()
    local h = self.canvas:GetHeight()
    if w <= 0 or h <= 0 then
        self.playerArrow:Hide()
        return
    end

    self.playerArrow:ClearAllPoints()
    local adjustedPx = clamp(px - MAP_MARKER_X_LIFT, 0, 1)
    local adjustedPy = clamp(py - MAP_MARKER_Y_LIFT, 0, 1)
    self.playerArrow:SetPoint("CENTER", self.canvas, "TOPLEFT", (w * MAP_HORIZONTAL_STRETCH) * adjustedPx, -((h * MAP_VERTICAL_STRETCH) * adjustedPy))
    self.playerArrow:Show()
end

function UI:EnsureGridLines()
    if self.gridLines then
        return
    end

    self.gridLines = {}
    for i = 1, 18 do
        local line = self.canvas:CreateTexture(nil, "BACKGROUND", nil, -5)
        line:Hide()
        self.gridLines[i] = line
    end
end

function UI:RefreshGrid()
    if not self.canvas then
        return
    end

    self:EnsureGridLines()

    local w = self.canvas:GetWidth()
    local h = self.canvas:GetHeight()
    if w <= 0 or h <= 0 then
        for _, line in ipairs(self.gridLines) do
            line:Hide()
        end
        return
    end

    local index = 1
    for row = 1, 9 do
        local line = self.gridLines[index]
        if line then
            local y = -(h * (row / 10))
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", 0, y)
            line:SetPoint("TOPRIGHT", self.canvas, "TOPRIGHT", 0, y)
            line:SetHeight(1)
            line:SetTexture(1, 1, 1)
            line:SetAlpha(0.12)
            line:Show()
            index = index + 1
        end
    end

    for col = 1, 9 do
        local line = self.gridLines[index]
        if line then
            local x = w * (col / 10)
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", x, 0)
            line:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, 0)
            line:SetWidth(1)
            line:SetTexture(1, 1, 1)
            line:SetAlpha(0.12)
            line:Show()
            index = index + 1
        end
    end

    for i = index, #self.gridLines do
        self.gridLines[i]:Hide()
    end
end

function UI:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    local b = CreateFrame("Button", "NemesisTrackerMiniButton", Minimap)
    b:SetSize(32, 32)
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetTexture(WHITE)
    bg:SetVertexColor(DARK[1], DARK[2], DARK[3], 0.95)

    local rim = b:CreateTexture(nil, "BORDER")
    rim:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    rim:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    rim:SetTexture(WHITE)
    rim:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.75)

    local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER")
    text:SetText(L["N"])
    text:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("CENTER")

    local function SetPosition(angleDeg)
        local angleRad = math.rad(angleDeg)
        b:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angleRad), 80 * math.sin(angleRad))
    end
    SetPosition(NT.db.minimapAngle or 315)

    b:SetScript("OnClick", function()
        NT:ToggleWindow()
    end)

    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function()
        b:StartMoving()
    end)
    b:SetScript("OnDragStop", function()
        b:StopMovingOrSizing()
        b:ClearAllPoints()
        local cx, cy = Minimap:GetCenter()
        local bx, by = b:GetCenter()
        local angleDeg = (math.deg(math.atan2(by - cy, bx - cx)) + 360) % 360
        NT.db.minimapAngle = angleDeg
        SetPosition(angleDeg)
    end)

    b:SetScript("OnEnter", function()
        GameTooltip:SetOwner(b, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Nemesis Tracker"])
        GameTooltip:AddLine(L["Left-click to toggle"])
        GameTooltip:AddLine(L["Drag to move"])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.minimapButton = b
end

function UI:CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(self:GetRowHeight())
    row:SetWidth(250)
    createBackdrop(row, 0.22)
    row:SetBackdropColor(CARD[1], CARD[2], CARD[3], 0.92)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 6, 10)
    row.name:SetWidth(200)
    row.name:SetJustifyH("LEFT")

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rank:SetPoint("RIGHT", row, "RIGHT", -6, 10)
    row.rank:SetWidth(28)

    row.zone = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.zone:SetPoint("LEFT", row, "LEFT", 6, -10)
    row.zone:SetWidth(180)
    row.zone:SetJustifyH("LEFT")

    row.lastSeen = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.lastSeen:SetPoint("RIGHT", row, "RIGHT", -6, -10)
    row.lastSeen:SetWidth(60)
    row.lastSeen:SetJustifyH("RIGHT")

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(button)
        if button.spawnId then
            NT:SelectNemesis(button.spawnId)
        end
    end)

    row:SetScript("OnDoubleClick", function(button)
        if not button.nemesis then
            return
        end

        AnnounceWaypoint(button.nemesis)
    end)

    row:SetScript("OnEnter", function(button)
        button.Bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.55)

        if not button.nemesis then
            return
        end

        local nemesis = button.nemesis
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(nemesis.name or L["Nemesis"])
        GameTooltip:AddLine(string.format(L["Level %d  Rank %d - %s"], nemesis.level or 0, nemesis.rank or 1, L[nemesis.rankTier] or nemesis.rankTier or L["Marked"]), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["Affixes: %s"], nemesis.affixText or L["None"]), 0.95, 0.82, 0.35)
        for _, affix in ipairs(AFFIX_DESCRIPTIONS) do
            if hasAffixBit(nemesis.affixMask, affix.bit) then
                -- The server builds these from its live configuration; the local locale
                -- string is only a fallback for the moment before the catalogue arrives.
                local catalog = NT.data.affixCatalog and NT.data.affixCatalog[affix.bit]
                GameTooltip:AddLine("  " .. ((catalog and catalog.desc) or L[affix.key]), 0.75, 0.75, 0.82, true)
            end
        end
        GameTooltip:AddLine(string.format(L["Relation: %s"], L[nemesis.relation] or nemesis.relation or L["public"]), 0.7, 0.9, 1)
        GameTooltip:AddLine(string.format(L["Reward: %s  Threat: %s"], L[nemesis.rewardClass] or nemesis.rewardClass or L["none"], L[nemesis.threatClass] or nemesis.threatClass or L["low"]), 1, 0.82, 0.2)
        GameTooltip:AddLine(string.format(L["Zone: %s"], NT:GetLocalizedZoneName(nemesis.zoneId, nemesis.zoneName)), 0.85, 0.85, 0.85)
        GameTooltip:AddLine(L["Last Seen: "] .. self:FormatLastSeen(nemesis.lastSeenAt), 0.7, 0.9, 0.7)
        GameTooltip:AddLine(string.format(L["Status: %s  Source: %s"], (L[NT:GetStalenessState(nemesis)] or NT:GetStalenessState(nemesis)), L[nemesis.lastSeenSource] or nemesis.lastSeenSource or L["unknown"]), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function(button)
        button.Bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.22)
        GameTooltip:Hide()
    end)

    self.rows[index] = row
end

function UI:CreateFilterButton(parent, index, filterDef)
    local button = makeButton(parent, nil, 54, 20)
    -- Disable() marks the ACTIVE filter here, so it must read as highlighted.
    button.toggleStyle = true
    placeControl(parent, button, index == 1 and 14 or 4)
    button:SetText(filterDef.label)
    button.key = filterDef.key
    button:SetScript("OnClick", function()
        NT:SetFilter(filterDef.key)
    end)
    self.filterButtons[index] = button
end

function UI:CreateScopeButton(parent, index, scopeDef)
    local button = makeButton(parent, nil, 78, 20)
    button.toggleStyle = true
    placeControl(parent, button, index == 1 and 14 or 4)
    button:SetText(scopeDef.label)
    button.key = scopeDef.key
    button:SetScript("OnClick", function()
        NT:SetScope(scopeDef.key)
    end)
    self.scopeButtons[index] = button
end

function UI:ShowZoneMenu()
    if not self.zoneMenu then
        self.zoneMenu = CreateFrame("Frame", "NemesisTrackerZoneMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = {}
    local zones = NT:GetAvailableZones()
    if #zones == 0 then
        table.insert(menu, {
            text = L["No zones available"],
            isTitle = true,
            notCheckable = true,
        })
    else
        table.insert(menu, {
            text = L["Select zone"],
            isTitle = true,
            notCheckable = true,
        })

        for _, zone in ipairs(zones) do
            table.insert(menu, {
                text = NT:GetLocalizedZoneName(zone.zoneId, zone.zoneName),
                checked = zone.zoneKey == NT.data.displayedZoneKey,
                func = function()
                    NT:SelectDisplayedZone(zone.zoneId, zone.zoneName, zone.zoneKey)
                end,
            })
        end
    end

    EasyMenu(menu, self.zoneMenu, self.zoneMenuButton, 0, 0, "MENU")
end

function UI:Create()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "NemesisTrackerFrame", UIParent)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    -- Keeps the tracker above peer DIALOG-level windows (Guild Hegemony, Battle
    -- Pass) instead of z-fighting with them where they overlap.
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    createBackdrop(frame)
    frame:SetWidth(WINDOW_W)
    frame:SetHeight(WINDOW_H)
    frame:SetPoint(NT.db.window.point or "CENTER", UIParent, NT.db.window.relativePoint or "CENTER", NT.db.window.x or 0, NT.db.window.y or 0)
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        NT.db.window.point = point
        NT.db.window.relativePoint = relativePoint
        NT.db.window.x = x
        NT.db.window.y = y
    end)
    -- ESC closes the window: UISpecialFrames resolves the entry through _G, so
    -- the frame must keep its GLOBAL name.
    tinsert(UISpecialFrames, "NemesisTrackerFrame")

    frame:Hide()
    self.frame = frame

    -- Title strip: a darker band plus a 1px gold rule, matching the other windows.
    -- ARTWORK, because the interior texture of createBackdrop sits in BORDER.
    local titleBand = frame:CreateTexture(nil, "ARTWORK")
    titleBand:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    titleBand:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    titleBand:SetHeight(31)
    titleBand:SetTexture(WHITE)
    titleBand:SetVertexColor(0.10, 0.09, 0.13, 0.85)

    local titleRule = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    titleRule:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -32)
    titleRule:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -32)
    titleRule:SetHeight(1)
    titleRule:SetTexture(WHITE)
    titleRule:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.45)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12)
    title:SetText(L["Nemesis Tracker"])
    title:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])

    self.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -44, -16)
    self.statusText:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    local close = makeButton(frame, "X", 20, 20)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    close:SetFrameLevel(frame:GetFrameLevel() + 5)

    -- Every control lives in this one row, above the map.
    local controls = CreateFrame("Frame", nil, frame)
    controls:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, CONTROL_Y)
    controls:SetWidth(WINDOW_W - 24)
    controls:SetHeight(22)
    self.controls = controls

    local sync = makeButton(controls, nil, 90, 22)
    sync:SetText(L["Refresh"])
    sync:SetScript("OnClick", function()
        NT:RefreshFromSources()
    end)
    placeControl(controls, sync, 0)

    local waypoint = makeButton(controls, nil, 110, 22)
    waypoint:SetText(L["Waypoint"])
    waypoint:SetScript("OnClick", function()
        AnnounceWaypoint(NT:GetSelectedNemesis())
    end)
    placeControl(controls, waypoint, 8)

    self.filterButtons = {}
    for index, filterDef in ipairs(FILTERS) do
        self:CreateFilterButton(controls, index, filterDef)
    end

    self.scopeButtons = {}
    for index, scopeDef in ipairs(SCOPES) do
        self:CreateScopeButton(controls, index, scopeDef)
    end

    -- The list starts directly under the control row now that the buttons no
    -- longer occupy the left column.
    local list = CreateFrame("Frame", nil, frame)
    list:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, CONTENT_Y)
    list:SetWidth(LIST_W)
    list:SetHeight((self:GetRowHeight() + 2) * NT:GetVisibleRows())
    self.list = list

    self.rows = {}
    for index = 1, MAX_ROW_COUNT do
        self:CreateRow(list, index)
    end
    self:LayoutRows()

    local mapPanel = CreateFrame("Frame", nil, frame)
    mapPanel:SetPoint("TOPLEFT", list, "TOPRIGHT", 12, 0)
    mapPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 14)
    createBackdrop(mapPanel, 0.55)
    self.mapPanel = mapPanel

    local canvas = CreateFrame("Frame", nil, mapPanel)
    canvas:SetAllPoints(mapPanel)
    canvas:EnableMouse(true)
    self.canvas = canvas

    self.zoomText = mapPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.zoomText:SetPoint("TOPRIGHT", mapPanel, "TOPRIGHT", -8, -8)
    self.zoomText:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    -- The map markers are children of the canvas, which puts them one frame level ABOVE
    -- anything parented to mapPanel. A marker landing on the strip where these controls
    -- sit would therefore swallow the click and the arrows looked dead. Force them up.
    local mapControlLevel = mapPanel:GetFrameLevel() + 3

    self.prevZoneButton = makeButton(mapPanel, nil, 22, 20, function()
        local index, zones = NT:GetDisplayedZoneIndex(-1)
        if index and zones and #zones > 1 then
            return string.format(L["Previous zone: %s"], zones[index].zoneName or L["Unknown"])
        end
        return nil
    end)
    self.prevZoneButton:SetPoint("TOPLEFT", mapPanel, "TOPLEFT", 8, -6)
    self.prevZoneButton:SetFrameLevel(mapControlLevel)
    self.prevZoneButton:SetText("<")
    self.prevZoneButton:SetScript("OnClick", function()
        NT:ChangeDisplayedZone(-1)
    end)

    self.nextZoneButton = makeButton(mapPanel, nil, 22, 20, function()
        local index, zones = NT:GetDisplayedZoneIndex(1)
        if index and zones and #zones > 1 then
            return string.format(L["Next zone: %s"], zones[index].zoneName or L["Unknown"])
        end
        return nil
    end)
    self.nextZoneButton:SetPoint("LEFT", self.prevZoneButton, "RIGHT", 196, 0)
    self.nextZoneButton:SetFrameLevel(mapControlLevel)
    self.nextZoneButton:SetText(">")
    self.nextZoneButton:SetScript("OnClick", function()
        NT:ChangeDisplayedZone(1)
    end)

    self.zoneMenuButton = makeButton(mapPanel, nil, 188, 20)
    self.zoneMenuButton:SetPoint("LEFT", self.prevZoneButton, "RIGHT", 8, 0)
    self.zoneMenuButton:SetFrameLevel(mapControlLevel)
    self.zoneMenuButton:SetText(L["Select zone"])
    self.zoneMenuButton:SetScript("OnClick", function()
        UI:ShowZoneMenu()
    end)
    self.mapZoneText = self.zoneMenuButton

    -- Leaderboard panel. It shares the map's rect, and only one of the two is shown,
    -- so the window keeps its fixed size.
    local topPanel = CreateFrame("Frame", nil, frame)
    topPanel:SetPoint("TOPLEFT", list, "TOPRIGHT", 12, 0)
    topPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 14)
    createBackdrop(topPanel, 0.55)
    topPanel:Hide()
    self.topPanel = topPanel

    self.topTitle = topPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.topTitle:SetPoint("TOPLEFT", topPanel, "TOPLEFT", 12, -10)
    self.topTitle:SetTextColor(GOLD_HI[1], GOLD_HI[2], GOLD_HI[3])
    self.topTitle:SetText(L["Top killers this month"])

    self.topHeader = topPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.topHeader:SetPoint("TOPLEFT", topPanel, "TOPLEFT", 12, -30)
    self.topHeader:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    self.topHeader:SetText(L["Place  Character  Kills / Revenge / Bounty / Best"])

    self.topEmpty = topPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.topEmpty:SetPoint("TOPLEFT", topPanel, "TOPLEFT", 12, -54)
    self.topEmpty:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    self.topEmpty:SetText(L["No kills recorded this month."])

    self.topRows = {}

    -- Own line: a separator plus one row, anchored to the bottom of the pane so it is
    -- always visible regardless of how many leaderboard rows arrived.
    self.topSelfLine = topPanel:CreateTexture(nil, "ARTWORK")
    self.topSelfLine:SetHeight(1)
    self.topSelfLine:SetPoint("BOTTOMLEFT", topPanel, "BOTTOMLEFT", 12, 34)
    self.topSelfLine:SetPoint("BOTTOMRIGHT", topPanel, "BOTTOMRIGHT", -12, 34)
    self.topSelfLine:SetTexture(GOLD[1], GOLD[2], GOLD[3], 0.45)
    self.topSelfLine:Hide()

    self.topSelfRow = CreateFrame("Frame", nil, topPanel)
    self.topSelfRow:SetHeight(18)
    self.topSelfRow:SetPoint("BOTTOMLEFT", topPanel, "BOTTOMLEFT", 12, 12)
    self.topSelfRow:SetPoint("BOTTOMRIGHT", topPanel, "BOTTOMRIGHT", -12, 12)

    self.topSelfRow.place = self.topSelfRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.topSelfRow.place:SetPoint("LEFT", self.topSelfRow, "LEFT", 0, 0)
    self.topSelfRow.place:SetWidth(22)
    self.topSelfRow.place:SetJustifyH("LEFT")

    self.topSelfRow.name = self.topSelfRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.topSelfRow.name:SetPoint("LEFT", self.topSelfRow.place, "RIGHT", 4, 0)
    self.topSelfRow.name:SetWidth(140)
    self.topSelfRow.name:SetJustifyH("LEFT")

    self.topSelfRow.stats = self.topSelfRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.topSelfRow.stats:SetPoint("RIGHT", self.topSelfRow, "RIGHT", 0, 0)
    self.topSelfRow.stats:SetWidth(160)
    self.topSelfRow.stats:SetJustifyH("RIGHT")

    self.topSelfRow:Hide()

    self.mapFallback = canvas:CreateTexture(nil, "BACKGROUND")
    self.mapFallback:SetAllPoints(canvas)
    self.mapFallback:SetTexture(CARD[1], CARD[2], CARD[3], 0.95)

    self.markers = {}

    -- Leaderboard toggle, sitting before the pager in the same row.
    self.topButton = makeButton(controls, nil, 46, 20)
    self.topButton.toggleStyle = true
    self.topButton:SetText(L["Top"])
    self.topButton:SetScript("OnClick", function()
        UI:ToggleLeaderboard()
    end)
    placeControl(controls, self.topButton, 10)

    self.prevPageButton = makeButton(controls, nil, 26, 20)
    self.prevPageButton:SetText("<")
    self.prevPageButton:SetScript("OnClick", function()
        NT:ChangePage(-1)
    end)
    placeControl(controls, self.prevPageButton, 14)

    self.pageText = controls:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.pageText:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    self.pageText:SetText(L["Page 1/1"])
    placeControl(controls, self.pageText, 6)

    self.nextPageButton = makeButton(controls, nil, 26, 20)
    self.nextPageButton:SetText(">")
    self.nextPageButton:SetScript("OnClick", function()
        NT:ChangePage(1)
    end)
    placeControl(controls, self.nextPageButton, 6)

    -- No resize grabbers: the window is fixed-size by design.
end











