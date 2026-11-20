-- Ore Atlas: saved settings, events, alerts, slash commands.
-- Built for WoW Forever (interface 16001). See CLAUDE.md for API rules.

local ADDON_NAME, ns = ...

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = GetMetadata(ADDON_NAME, "Version") or "dev"
local PREFIX = "|cfff2c14eOre Atlas|r:"

-- Settings saved in OreAtlasDB. New keys added here are filled in for
-- existing users on next login without touching what they already set.
local defaults = {
    filter = "all",     -- "all" or "useful"
    alerts = true,      -- chat message when your best ore or rank changes
    scale = 1,
    mapOverlay = true,  -- shade ore areas on the world map
    mapOres = {},       -- [oreKey] = true/false when the player pinned it on or off
    chars = {},         -- ["Name-Realm"] = { name, class, known, rank, max, updated }
    mined = {},         -- [uiMapID][oreKey] = { coord, ... } spots you've mined
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

function ns.Print(...)
    local parts = { PREFIX }
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    print(table.concat(parts, " "))
end

local function ApplyDefaults(db, defs)
    for key, value in pairs(defs) do
        if type(value) == "table" then
            if type(db[key]) ~= "table" then db[key] = {} end
            ApplyDefaults(db[key], value)
        elseif db[key] == nil then
            db[key] = value
        end
    end
end

---------------------------------------------------------------------------
-- Events: add a function to `handlers` named after the event, then
-- register it with ns.RegisterEvent("EVENT_NAME").
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {}
ns.handlers = handlers

function ns.RegisterEvent(event)
    eventFrame:RegisterEvent(event)
end

function ns.UnregisterEvent(event)
    eventFrame:UnregisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local handler = handlers[event]
    if handler then handler(...) end
end)

local function ReadSkill()
    if ns.db then ns.Skill:Read() end
end

function handlers.ADDON_LOADED(name)
    if name == ADDON_NAME then
        OreAtlasDB = OreAtlasDB or {}
        ApplyDefaults(OreAtlasDB, defaults)
        ns.db = OreAtlasDB
    elseif name == "Blizzard_WorldMap" and ns.db then
        -- in case the world map loads on demand after login
        ns.MapOverlay:Init()
    end
end

function handlers.PLAYER_LOGIN()
    ns.MapOverlay:Init()
    ns.Nodes:HookGatherMate()
    ns.loggingIn = true
    ReadSkill()
    -- profession data can arrive a moment after login
    C_Timer.After(3, function()
        ReadSkill()
        ns.loggingIn = false
    end)
end

function handlers.SKILL_LINES_CHANGED()
    ReadSkill()
end

-- "Your skill in Mining has increased to 142." We don't parse the text
-- (chat can be restricted); it's just our cue to re-read the skill.
function handlers.CHAT_MSG_SKILL()
    C_Timer.After(0.2, ReadSkill)
end

ns.RegisterEvent("ADDON_LOADED")
ns.RegisterEvent("PLAYER_LOGIN")
ns.RegisterEvent("SKILL_LINES_CHANGED")
ns.RegisterEvent("CHAT_MSG_SKILL")

---------------------------------------------------------------------------
-- Skill changes: refresh the pane and, after login, tell the player when
-- their best ore changes or they hit a trainer cap.
---------------------------------------------------------------------------

function ns.OnSkillChanged(before, now)
    if ns.UI.frame then ns.UI:Refresh() end
    ns.MapOverlay:Refresh()
    if ns.loggingIn or not ns.db.alerts or not now.known or not before.known then return end

    local oldBest = ns.BestOre(before.rank, before.rank)
    local newBest, color = ns.BestOre(now.rank, now:Effective())
    if newBest and newBest ~= oldBest then
        ns.Print(format("%s is your best ore now (%s): %s.", newBest.name,
            "|cff" .. ns.COLORS[color].hex .. color .. "|r", ns.TopZones(newBest, 3)))
    end
    if now.rank == now.max and before.rank < now.max and now.max < ns.MAX_SKILL then
        ns.Print(ns.RankHint(now.rank, now.max))
    end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local commands = {}

function commands.help()
    ns.Print("commands:")
    print("  /ore - open or close the atlas")
    print("  /ore map [on|off|auto] - ore areas on the world map; auto forgets your per-ore picks")
    print("  /ore alerts [on|off] - chat alerts when your best ore changes")
    print("  /ore scale 0.9 - window size")
    print("  /ore debug - show what the game reports for Mining and the map")
    print("  /ore reset - reset settings and window position")
end

function commands.toggle()
    ns.UI:Toggle()
end

function commands.alerts(arg)
    arg = (arg or ""):lower()
    if arg == "on" then
        ns.db.alerts = true
    elseif arg == "off" then
        ns.db.alerts = false
    else
        ns.db.alerts = not ns.db.alerts
    end
    ns.Print("alerts " .. (ns.db.alerts and "on" or "off"))
end

function commands.map(arg)
    arg = (arg or ""):lower()
    if arg == "auto" then
        wipe(ns.db.mapOres)
        ns.Print("map shows ores that still give you skill-ups again.")
    else
        if arg == "on" then
            ns.db.mapOverlay = true
        elseif arg == "off" then
            ns.db.mapOverlay = false
        else
            ns.db.mapOverlay = not ns.db.mapOverlay
        end
        ns.Print("ore areas on the world map " .. (ns.db.mapOverlay and "on" or "off"))
    end
    ns.MapOverlay:Refresh()
    if ns.UI.frame then ns.UI:Refresh() end
end

function commands.scale(arg)
    local value = tonumber(arg)
    if not value or value < 0.5 or value > 2 then
        ns.Print("scale must be a number from 0.5 to 2, like /ore scale 0.9")
        return
    end
    ns.db.scale = value
    if ns.UI.frame then ns.UI.frame:SetScale(value) end
    ns.Print("scale " .. value)
end

-- Raw API output, so a first in-game run can tell us what Forever returns.
function commands.debug()
    ns.Print("version " .. VERSION)
    if not GetProfessions then
        print("  GetProfessions is missing")
    else
        local list = { GetProfessions() }
        print("  GetProfessions: " .. table.concat({ tostring(list[1]), tostring(list[2]), tostring(list[3]),
            tostring(list[4]), tostring(list[5]) }, ", "))
        for i = 1, 5 do
            local index = list[i]
            if index then
                local name, icon, rank, maxRank, _, _, skillLine, modifier, _, _, lineName = GetProfessionInfo(index)
                print(format("  [%d] %s icon=%s rank=%s/%s mod=%s line=%s (%s)", index, tostring(name),
                    tostring(icon), tostring(rank), tostring(maxRank), tostring(modifier), tostring(skillLine),
                    tostring(lineName)))
            end
        end
    end
    local S = ns.Skill
    print(format("  Mining: known=%s rank=%d max=%d mod=%d", tostring(S.known), S.rank, S.max, S.modifier or 0))
    ns.Maps:Index()
    print(format("  Map zones indexed: %d", ns.Maps.count or 0))
    local missing = ns.Maps:Unresolved()
    print("  Zones not found on the map: " .. (#missing > 0 and table.concat(missing, ", ") or "none"))

    ns.Nodes.dirty = true
    local counts = ns.Nodes:Counts()
    print(format("  GatherMate2: %s. Nodes known: %d (you mined %d).",
        ns.Nodes:HasGatherMate() and "found" or "not loaded", ns.Nodes.total or 0, ns.Nodes:OwnTotal()))
    local perOre = {}
    for _, ore in ipairs(ns.ORES) do
        local n = 0
        for _, count in pairs(counts[ore.key] or {}) do n = n + count end
        if n > 0 then perOre[#perOre + 1] = ore.name .. " " .. n end
    end
    if #perOre > 0 then print("  By ore: " .. table.concat(perOre, ", ")) end
    if WorldMapFrame and WorldMapFrame:IsShown() then
        print(format("  World map: uiMapID %s, %d ore types drawn.", tostring(WorldMapFrame:GetMapID()),
            #ns.MapOverlay.shown))
    end
end

function commands.reset()
    ns.db.filter, ns.db.alerts, ns.db.scale, ns.db.position = "all", true, 1, nil
    ns.db.mapOverlay = true
    wipe(ns.db.mapOres)
    ns.MapOverlay:Refresh()
    if ns.UI.frame then
        ns.UI.frame:SetScale(1)
        ns.UI.frame:ClearAllPoints()
        ns.UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        ns.UI.filter = "all"
        ns.UI:Refresh()
    end
    ns.Print("settings reset.")
end

SLASH_OREATLAS1 = "/ore"
SLASH_OREATLAS2 = "/oreatlas"
SlashCmdList["OREATLAS"] = function(msg)
    local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "" then cmd = "toggle" end
    local fn = commands[cmd] or commands.help
    fn(rest)
end

-- Clicking the addon in the minimap addon menu opens the atlas.
function OreAtlasCompartment_OnClick()
    ns.UI:Toggle()
end
