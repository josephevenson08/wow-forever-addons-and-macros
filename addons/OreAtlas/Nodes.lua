-- Ore Atlas: where mining nodes actually are.
--
-- Two sources, merged:
--   GatherMate2 (optional). If GatherMate2 and its Forever data are
--     installed, we read its Mining nodes from the player's own install while
--     they play. Ore Atlas never copies or ships that data.
--   Your own mining. Every node you mine, we save the spot you mined it from.
-- Coordinates use GatherMate2's encoding so the two merge cleanly.

local _, ns = ...

local Nodes = {}
ns.Nodes = Nodes

local MINING = "Mining"
local CACHE_SECONDS = 60
local SAME_SPOT = 0.006          -- two recordings this close are one node

local function Secret(value)
    return issecretvalue and issecretvalue(value)
end

-- GatherMate2's coordinate format: x and y are 0..1 fractions of the zone.
function Nodes.Encode(x, y)
    x, y = math.min(x, 0.9999), math.min(y, 0.9999)
    return math.floor(x * 10000 + 0.5) * 1000000 + math.floor(y * 10000 + 0.5) * 100
end

function Nodes.Decode(coord)
    return math.floor(coord / 1000000) / 10000, math.floor(coord % 1000000 / 100) / 10000
end

---------------------------------------------------------------------------
-- GatherMate2
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

local oreForNodeID = {}   -- GatherMate2 node ID -> ore key, or false

local function OreKeyForNodeID(gm, nodeID)
    local cached = oreForNodeID[nodeID]
    if cached ~= nil then return cached end
    local ok, name = pcall(gm.GetNameForNode, gm, MINING, nodeID)
    local ore = ok and ns.OreForNodeName(name)
    oreForNodeID[nodeID] = ore and ore.key or false
    return oreForNodeID[nodeID]
end

local function EachGatherMateNode(mapID, fn)
    local gm = GatherMate()
    if not gm then return end
    local ok, iter, state, init = pcall(gm.GetNodesForZone, gm, mapID, MINING, true)
    if not ok or type(iter) ~= "function" then return end
    for coord, nodeID in iter, state, init do
        local key = type(coord) == "number" and OreKeyForNodeID(gm, nodeID)
        if key then fn(key, coord) end
    end
end

-- Mark the cache stale when GatherMate2 adds or removes nodes. Bulk imports
-- don't send these messages; the cache also expires after a minute.
function Nodes:HookGatherMate()
    if self.hooked or not GatherMate() then return end
    local AceEvent = LibStub and LibStub("AceEvent-3.0", true)
    if not AceEvent then return end
    AceEvent:Embed(self)
    local function Changed()
        Nodes.dirty = true
        ns.MapOverlay:Refresh()
    end
    for _, message in ipairs({ "GatherMate2NodeAdded", "GatherMate2NodeDeleted",
                               "GatherMate2Cleanup", "GatherMate2ConfigChanged" }) do
        self:RegisterMessage(message, Changed)
    end
    self.hooked = true
end

---------------------------------------------------------------------------
-- Your own mining
---------------------------------------------------------------------------

local function EachOwnNode(mapID, fn)
    local zone = ns.db.mined[mapID]
    if not zone then return end
    for key, coords in pairs(zone) do
        for _, coord in ipairs(coords) do fn(key, coord) end
    end
end

-- Save where the player is standing as a node of this ore.
function Nodes:Record(oreKey)
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or type(mapID) ~= "number" or Secret(mapID) then return end
    local okPos, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not okPos or not pos then return end
    local x, y = pos:GetXY()
    if type(x) ~= "number" or Secret(x) or Secret(y) or x <= 0 or y <= 0 then return end

    local zone = ns.db.mined[mapID] or {}
    ns.db.mined[mapID] = zone
    local list = zone[oreKey] or {}
    zone[oreKey] = list
    for _, coord in ipairs(list) do
        local cx, cy = Nodes.Decode(coord)
        if math.abs(cx - x) < SAME_SPOT and math.abs(cy - y) < SAME_SPOT then return end
    end
    list[#list + 1] = Nodes.Encode(x, y)
    self.dirty = true
    ns.MapOverlay:Refresh()
end

-- Mining a node is a spell cast on it: UNIT_SPELLCAST_SENT names the node,
-- UNIT_SPELLCAST_SUCCEEDED says it worked.
local pending = {}   -- castGUID -> ore key

function ns.handlers.UNIT_SPELLCAST_SENT(unit, target, castGUID)
    if unit ~= "player" or not castGUID or Secret(castGUID) then return end
    local ore = ns.OreForNodeName(target)
    if ore then pending[castGUID] = ore.key end
end

function ns.handlers.UNIT_SPELLCAST_SUCCEEDED(unit, castGUID)
    if unit ~= "player" or not castGUID or Secret(castGUID) then return end
    local key = pending[castGUID]
    if key then
        pending[castGUID] = nil
        Nodes:Record(key)
    end
end

local function Forget(unit, castGUID)
    if unit == "player" and castGUID and not Secret(castGUID) then pending[castGUID] = nil end
end
ns.handlers.UNIT_SPELLCAST_FAILED = Forget
ns.handlers.UNIT_SPELLCAST_INTERRUPTED = Forget

ns.RegisterEvent("UNIT_SPELLCAST_SENT")
ns.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
ns.RegisterEvent("UNIT_SPELLCAST_FAILED")
ns.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------

-- Every known node in one zone: { [oreKey] = { coord, ... } }
function Nodes:ForZone(mapID)
    local out = {}
    local function Add(key, coord)
        local list = out[key]
        if not list then
            list = {}
            out[key] = list
        end
        list[#list + 1] = coord
    end
    EachGatherMateNode(mapID, Add)
    EachOwnNode(mapID, Add)
    return out
end

-- Zones worth scanning: everything in GatherMate2's Mining data, everywhere
-- you've mined, and the zones in our own data.
local function ZoneIDs()
    local ids = {}
    local db = _G.GatherMate2MineDB
    if type(db) == "table" then
        for mapID in pairs(db) do
            if type(mapID) == "number" then ids[mapID] = true end
        end
    end
    for mapID in pairs(ns.db.mined) do ids[mapID] = true end
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
        for key, coords in pairs(self:ForZone(mapID)) do
            counts[key] = counts[key] or {}
            counts[key][mapID] = #coords
            total = total + #coords
        end
    end
    self.counts, self.total, self.dirty, self.builtAt = counts, total, false, GetTime()
    return counts
end

-- Zones for an ore from node data, busiest first:
-- { { mapID, name, count }, ... }, or nil when there's no data for it.
function Nodes:ZonesFor(oreKey)
    local byZone = self:Counts()[oreKey]
    if not byZone then return nil end
    local list = {}
    for mapID, count in pairs(byZone) do
        if count > 0 then
            local info = C_Map.GetMapInfo(mapID)
            list[#list + 1] = { mapID = mapID, name = info and info.name or ("Map " .. mapID), count = count }
        end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list
end

-- How many nodes you've recorded yourself.
function Nodes:OwnTotal()
    local n = 0
    for _, zone in pairs(ns.db.mined) do
        for _, coords in pairs(zone) do n = n + #coords end
    end
    return n
end
