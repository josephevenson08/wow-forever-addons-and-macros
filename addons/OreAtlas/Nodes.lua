-- Ore Atlas: real node counts per zone, from GatherMate2.
--
-- GatherMate2 shows where every node is on the map. Ore Atlas only counts
-- them, so each ore card can list the zones where that ore really spawns,
-- busiest first. Two places to read, merged (duplicates dropped):
--   GatherMate2's own database: nodes it has recorded, plus anything the
--     player imported into it.
--   GatherMate2_Data (Retail & Forever): if installed but never imported, we
--     load it on demand and read its Forever Mining table directly. Its
--     importer deletes that table after an import, at which point the nodes
--     live in GatherMate2's database instead.
-- Everything is read from the player's own install while they play. Ore
-- Atlas never copies or ships GatherMate2 data.
--
-- Forever uses classic-era uiMapIDs (Tanaris is 1446).

local _, ns = ...

local Nodes = {}
ns.Nodes = Nodes

local MINING = "Mining"
local CACHE_SECONDS = 60
Nodes.TRUST = 20    -- with this many known nodes, trust the data over our zone list

---------------------------------------------------------------------------
-- GatherMate2 and GatherMate2_Data
---------------------------------------------------------------------------

-- The GatherMate2 addon object, if it's loaded and has the API we use.
local function GatherMate()
    local gm = _G.GatherMate2
    if type(gm) == "table" and type(gm.GetNodesForZone) == "function"
        and type(gm.GetNameForNode) == "function" then
        return gm
    end
end

function Nodes:HasGatherMate()
    return GatherMate() ~= nil
end

-- GatherMate2_Data's raw Forever Mining table: { [uiMapID] = { [coord] = nodeID } }.
-- It's load-on-demand, so load it once (out of combat) if it isn't yet.
local function RawData()
    if _G.GatherMateData2MineDB == nil and not Nodes.triedDataLoad and GatherMate()
        and C_AddOns and C_AddOns.LoadAddOn and not InCombatLockdown() then
        Nodes.triedDataLoad = true
        local loaded = C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("GatherMate2_Data")
        if not loaded then
            local ok, result = pcall(C_AddOns.LoadAddOn, "GatherMate2_Data")
            Nodes.dataLoadResult = ok and tostring(result) or "error"
        end
    end
    local db = _G.GatherMateData2MineDB
    return type(db) == "table" and db or nil
end

function Nodes:HasRawData()
    return RawData() ~= nil
end

local oreForNodeID = {}   -- GatherMate2 node ID -> ore key, or false

local function OreKeyForNodeID(gm, nodeID)
    local cached = oreForNodeID[nodeID]
    if cached ~= nil then return cached end
    local ok, name = pcall(gm.GetNameForNode, gm, MINING, nodeID)
    local ore = ok and ns.OreForNodeName(name)
    oreForNodeID[nodeID] = ore and ore.key or false
    return oreForNodeID[nodeID]
end

-- Calls fn(oreKey, coord) once per mining node GatherMate2 knows in a zone.
local function EachNode(mapID, fn)
    local gm = GatherMate()
    if not gm then return end
    local seen = {}
    local function Visit(coord, nodeID)
        if type(coord) ~= "number" or seen[coord] then return end
        seen[coord] = true
        local key = OreKeyForNodeID(gm, nodeID)
        if key then fn(key, coord) end
    end

    local ok, iter, state, init = pcall(gm.GetNodesForZone, gm, mapID, MINING, true)
    if ok and type(iter) == "function" then
        for coord, nodeID in iter, state, init do Visit(coord, nodeID) end
    end

    local raw = RawData()
    local zone = raw and raw[mapID]
    if type(zone) == "table" then
        for coord, nodeID in pairs(zone) do Visit(coord, nodeID) end
    end
end

-- Mark the cache stale when GatherMate2's data changes. Bulk imports
-- don't always send messages; the cache also expires after a minute.
function Nodes:HookGatherMate()
    if self.hooked or not GatherMate() then return end
    local AceEvent = LibStub and LibStub("AceEvent-3.0", true)
    if not AceEvent then return end
    AceEvent:Embed(self)
    local function Changed()
        Nodes.dirty = true
    end
    for _, message in ipairs({ "GatherMate2NodeAdded", "GatherMate2NodeDeleted", "GatherMate2Cleanup",
                               "GatherMate2ConfigChanged", "GatherMateData2Import" }) do
        self:RegisterMessage(message, Changed)
    end
    self.hooked = true
end

---------------------------------------------------------------------------
-- Counts
---------------------------------------------------------------------------

-- Zones worth counting: every zone in GatherMate2's and GatherMate2_Data's
-- Mining tables, plus the zones in our own data.
local function ZoneIDs()
    local ids = {}
    for _, db in ipairs({ _G.GatherMate2MineDB or false, RawData() or false }) do
        if type(db) == "table" then
            for mapID in pairs(db) do
                if type(mapID) == "number" then ids[mapID] = true end
            end
        end
    end
    for name in pairs(ns.ZONES) do
        local mapID = ns.Maps:Find(name)
        if mapID then ids[mapID] = true end
    end
    return ids
end

-- Node counts: counts[oreKey][mapID] = n. Cached for a minute.
function Nodes:Counts()
    if self.counts and not self.dirty and GetTime() - self.builtAt < CACHE_SECONDS then
        return self.counts
    end
    local counts, total = {}, 0
    for mapID in pairs(ZoneIDs()) do
        EachNode(mapID, function(key)
            counts[key] = counts[key] or {}
            counts[key][mapID] = (counts[key][mapID] or 0) + 1
            total = total + 1
        end)
    end
    self.counts, self.total, self.dirty, self.builtAt = counts, total, false, GetTime()
    return counts
end

-- Zones for an ore from node data, busiest first, and the node total:
-- { { mapID, name, count }, ... }, total. nil when there's no data.
function Nodes:ZonesFor(oreKey)
    local byZone = self:Counts()[oreKey]
    if not byZone then return nil, 0 end
    local list, total = {}, 0
    for mapID, count in pairs(byZone) do
        local info = C_Map.GetMapInfo(mapID)
        list[#list + 1] = { mapID = mapID, name = info and info.name or ("Map " .. mapID), count = count }
        total = total + count
    end
    if #list == 0 then return nil, 0 end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list, total
end

-- The zone list to show for an ore. Zones with real node counts come first.
-- Until there are TRUST nodes for the ore, the researched zones from
-- Data.lua fill in after them, so a few known nodes can't hide the rest.
-- Entries: { name, mapID?, count?, forever?, dense? }
function Nodes:ZoneList(ore)
    local data, total = self:ZonesFor(ore.key)
    local list, have = {}, {}
    for _, zone in ipairs(data or {}) do
        list[#list + 1] = zone
        have[zone.name] = true
    end
    if total < self.TRUST then
        for _, zone in ipairs(ore.zones) do
            if not have[zone.name] then list[#list + 1] = zone end
        end
    end
    return list
end
