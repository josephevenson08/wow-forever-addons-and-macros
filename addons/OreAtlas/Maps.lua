-- Ore Atlas: find a zone's map and open the world map to it.
--
-- Forever may number zones differently from retail (retail splits the
-- Barrens, for one), so we look zones up by name in the live map tree first
-- and only fall back to known retail uiMapIDs when the name matches.

local _, ns = ...

local Maps = {}
ns.Maps = Maps

local ZONE_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local WORLD_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.World) or 1
local AZEROTH = 947

local function Secret(value)
    return issecretvalue and issecretvalue(value)
end

-- The world map above wherever the player is standing.
local function PlayerWorld()
    local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or type(id) ~= "number" or Secret(id) then return nil end
    for _ = 1, 10 do
        local info = C_Map.GetMapInfo(id)
        if not info then return nil end
        if info.mapType <= WORLD_TYPE then return id end
        if not info.parentMapID or info.parentMapID == 0 then return nil end
        id = info.parentMapID
    end
end

function Maps:Index()
    -- an empty index (map data not loaded yet) is retried next time
    if self.byName and self.count > 0 then return end
    self.byName, self.count = {}, 0
    if not (C_Map and C_Map.GetMapChildrenInfo) then return end
    for _, root in ipairs({ AZEROTH, PlayerWorld() or AZEROTH }) do
        local ok, children = pcall(C_Map.GetMapChildrenInfo, root, ZONE_TYPE, true)
        if ok and children then
            for _, info in ipairs(children) do
                if info.name and not self.byName[info.name] then
                    self.byName[info.name] = info.mapID
                    self.count = self.count + 1
                end
            end
        end
    end
end

-- uiMapID for one of our zone names, or nil.
function Maps:Find(zoneName)
    self:Index()
    local zone = ns.ZONES[zoneName]
    local target = (zone and zone.inside) or zoneName
    if self.byName[target] then return self.byName[target] end

    local outdoor = ns.ZONES[target]
    if not outdoor then return nil end
    local names = { [target] = true }
    for _, alt in ipairs(outdoor.alt or {}) do
        if self.byName[alt] then return self.byName[alt] end
        names[alt] = true
    end
    for _, id in ipairs(outdoor.ids or {}) do
        local info = C_Map.GetMapInfo(id)
        if info and names[info.name] then return id end
    end
end

function Maps:OpenID(id)
    if InCombatLockdown() then
        ns.Print("Can't open the map in combat.")
        return
    end
    if C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(id)
    elseif WorldMapFrame then
        if not WorldMapFrame:IsShown() then ToggleWorldMap() end
        WorldMapFrame:SetMapID(id)
    end
end

function Maps:Open(zoneName)
    local id = self:Find(zoneName)
    if not id then
        ns.Print("Couldn't find " .. zoneName .. " on the world map.")
        return
    end
    self:OpenID(id)
end

-- Zone names from our data that the map lookup can't resolve.
function Maps:Unresolved()
    local missing = {}
    for name in pairs(ns.ZONES) do
        if not self:Find(name) then missing[#missing + 1] = name end
    end
    table.sort(missing)
    return missing
end
