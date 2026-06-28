local L = LibStub("AceLocale-3.0"):NewLocale("NemesisTracker", "enUS", true, true)
if not L then return end

-- Filter buttons
L["All"] = true
L["Own"] = true
L["Party"] = true
L["Guild"] = true
L["Public"] = true

-- Scope buttons
L["All Zones"] = true
L["This Map"] = true

-- Button labels
L["Refresh"] = true
L["Waypoint"] = true
L["Select Zone"] = true
L["Select zone"] = true

-- Minimap button / window title
L["N"] = true
L["Nemesis Tracker"] = true
L["Left-click to toggle"] = true
L["Drag to move"] = true

-- Zone menu
L["No zones available"] = true

-- Map display
L["Map data unavailable"] = true
L["No zone selected"] = true

-- Zoom / creature count
L["1 creature"] = true
L["%d creatures"] = true

-- Format strings
L["%ds ago"] = true
L["%dm ago"] = true
L["%dh ago"] = true
L["R%d"] = true
L["Page %d/%d"] = true
L["Page 1/1"] = true

-- Status bar
L["State: %s  Filter: %s  Scope: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"] = true
L["State: %s  Filter: %s  Scope: %s  Search: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"] = true

-- Waypoint chat message
L["Nemesis waypoint: %s - %s (%.1f, %.1f, %.1f)"] = true

-- Tooltip lines
L["Level %d  Rank %d - %s"] = true
L["Last Seen: "] = true
L["Reward: "] = true
L["Threat: "] = true
L["MapX/Y: %.3f, %.3f"] = true
L["Relation: %s"] = true
L["Reward: %s  Threat: %s"] = true
L["Zone: %s"] = true
L["Status: %s  Source: %s"] = true

-- Fallback display values
L["Unknown"] = true
L["Nemesis"] = true
L["Marked"] = true
L["none"] = true
L["low"] = true
L["medium"] = true
L["high"] = true
L["extreme"] = true
L["public"] = true
L["unknown"] = true
L["fresh"] = true
L["fading"] = true
L["stale"] = true
L["hidden"] = true
L["idle"] = true
L["connected"] = true
L["requesting"] = true
L["bootstrap"] = true
L["live"] = true
L["never"] = true
L["None"] = true
L["all"] = true
L["own"] = true
L["party"] = true
L["guild"] = true
L["zone"] = true
-- Source values
L["peer-sync"] = true
L["local-cache"] = true
L["server-bootstrap"] = true
L["rank5-broadcast"] = true
L["server-validated"] = true
