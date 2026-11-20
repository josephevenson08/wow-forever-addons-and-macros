-- Ore Atlas: saved settings, events, alerts, slash commands.
-- Built for WoW Forever (interface 16001). See CLAUDE.md for API rules.

local ADDON_NAME, ns = ...

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = GetMetadata(ADDON_NAME, "Version") or "dev"
local PREFIX = "|cfff2c14eOre Atlas|r:"

-- Settings saved in OreAtlasDB. New keys added here are filled in for
-- existing users on next login without touching what they already set.
local defaults = {
    alerts = true,      -- chat message when your best ore or rank changes
    scale = 1,
    chars = {},         -- ["Name-Realm"] = { name, class, known, rank, max, updated }
}

-- Settings from 0.2.x (map shading, ore filter) that no longer exist.
local RETIRED = { "filter", "mapOverlay", "mapOres", "mined" }

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
    if name ~= ADDON_NAME then return end
    ns.UnregisterEvent("ADDON_LOADED")

    OreAtlasDB = OreAtlasDB or {}
    for _, key in ipairs(RETIRED) do OreAtlasDB[key] = nil end
    ApplyDefaults(OreAtlasDB, defaults)
    ns.db = OreAtlasDB
end

function handlers.PLAYER_LOGIN()
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
    print("  /ore alerts [on|off] - chat alerts when your best ore changes")
    print("  /ore scale 0.9 - window size")
    print("  /ore debug - show what the game reports for Mining, the map and GatherMate2")
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
    print(format("  GatherMate2: %s. GatherMate2_Data table: %s%s. Mining nodes known: %d.",
        ns.Nodes:HasGatherMate() and "found" or "not loaded",
        ns.Nodes:HasRawData() and "read" or "not loaded (fine if you imported it)",
        ns.Nodes.dataLoadResult and (" (load: " .. ns.Nodes.dataLoadResult .. ")") or "",
        ns.Nodes.total or 0))
    local perOre = {}
    for _, ore in ipairs(ns.ORES) do
        local n = 0
        for _, count in pairs(counts[ore.key] or {}) do n = n + count end
        if n > 0 then perOre[#perOre + 1] = ore.name .. " " .. n end
    end
    if #perOre > 0 then print("  By ore: " .. table.concat(perOre, ", ")) end
end

function commands.reset()
    ns.db.alerts, ns.db.scale, ns.db.position = true, 1, nil
    if ns.UI.frame then
        ns.UI.frame:SetScale(1)
        ns.UI.frame:ClearAllPoints()
        ns.UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
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
