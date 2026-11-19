-- Wyvern Wits: saved settings, events, slash commands.
-- Built for WoW Forever (interface 16001). See CLAUDE.md for API rules.

local ADDON_NAME, ns = ...

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = GetMetadata(ADDON_NAME, "Version") or "dev"
local PREFIX = "|cff33ff99Wyvern Wits|r:"

-- Settings saved in WyvernWitsDB. New keys added here are filled in for
-- existing users on next login without touching what they already set.
local SETTINGS = {
    popup = true,       -- open the window when a flight starts
    autoStart = false,  -- skip the Start button
    sound = true,
    scale = 1,
}

local DATA = {
    routes = {},        -- ["From > To"] = { secs = flight time, best = deepest yards }
    recent = {},        -- prompt ids from recent games, oldest first
    seen = {},          -- [promptId] = { [answer] = times given }
    stats = { games = 0, deepest = 0, warchiefs = 0 },
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

function handlers.ADDON_LOADED(name)
    if name ~= ADDON_NAME then return end
    ns.UnregisterEvent("ADDON_LOADED")

    WyvernWitsDB = WyvernWitsDB or {}
    ApplyDefaults(WyvernWitsDB, SETTINGS)
    ApplyDefaults(WyvernWitsDB, DATA)
    ns.db = WyvernWitsDB
end

ns.RegisterEvent("ADDON_LOADED")

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local commands = {}

local function OnOff(value)
    return value and "|cff5fd35fon|r" or "|cffff6a5aoff|r"
end

-- "/wits auto on", "/wits auto off", or "/wits auto" to flip it.
local function Toggle(key, label, arg)
    arg = (arg or ""):lower()
    if arg == "on" then
        ns.db[key] = true
    elseif arg == "off" then
        ns.db[key] = false
    else
        ns.db[key] = not ns.db[key]
    end
    ns.Print(label .. ": " .. OnOff(ns.db[key]))
end

function commands.help()
    ns.Print("commands:")
    print("  /wits play - practice game, no flight needed")
    print("  /wits show - reopen the window")
    print("  /wits popup [on|off] - open on takeoff (" .. OnOff(ns.db.popup) .. ")")
    print("  /wits auto [on|off] - skip the Start button (" .. OnOff(ns.db.autoStart) .. ")")
    print("  /wits sound [on|off] - sounds (" .. OnOff(ns.db.sound) .. ")")
    print("  /wits scale 0.8 - window size (" .. ns.db.scale .. ")")
    print("  /wits stats - your dive records")
    print("  /wits reset - reset settings and window position")
end

function commands.play()
    ns.Game:Open(ns.Flight:Current())
end

function commands.show()
    if ns.Game.state == "idle" then
        commands.play()
    else
        ns.UI:Show()
    end
end

function commands.popup(arg) Toggle("popup", "Open on takeoff", arg) end
function commands.auto(arg) Toggle("autoStart", "Auto start", arg) end
function commands.sound(arg) Toggle("sound", "Sound", arg) end

function commands.scale(arg)
    local value = tonumber(arg)
    if not value or value < 0.5 or value > 2 then
        ns.Print("scale must be a number from 0.5 to 2, like /wits scale 0.8")
        return
    end
    ns.db.scale = value
    if ns.UI.frame then ns.UI.frame:SetScale(value) end
    ns.Print("scale: " .. value)
end

function commands.stats()
    local s = ns.db.stats
    ns.Print(format("%d games, deepest dive %d yd, %d Warchief answers.", s.games, s.deepest, s.warchiefs))
    local best, bestKey = 0, nil
    for key, route in pairs(ns.db.routes) do
        if (route.best or 0) > best then best, bestKey = route.best, key end
    end
    if bestKey then
        print(format("  Best route: %s, %d yd", bestKey, best))
    end
end

function commands.version()
    ns.Print("version " .. VERSION)
end

function commands.reset()
    for key, value in pairs(SETTINGS) do ns.db[key] = value end
    ns.db.position = nil
    if ns.UI.frame then ns.UI:RestorePosition() end
    ns.Print("settings reset. Your stats are kept.")
end

SLASH_WYVERNWITS1 = "/wits"
SLASH_WYVERNWITS2 = "/wyvernwits"
SlashCmdList["WYVERNWITS"] = function(msg)
    local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    local fn = commands[cmd] or commands.help
    fn(rest)
end

-- Clicking the addon in the minimap addon menu opens the window.
function WyvernWitsCompartment_OnClick()
    commands.show()
end
