-- __TITLE__
-- Built for WoW Forever (interface 16001). See CLAUDE.md for API rules.

local ADDON_NAME, ns = ...

local GetMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = GetMetadata(ADDON_NAME, "Version") or "dev"
local PREFIX = "|cff33ff99" .. ADDON_NAME .. "|r:"

-- Settings saved in __ADDON__DB. New keys added here are filled in for
-- existing users on next login without touching what they already set.
local defaults = {
    enabled = true,
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

    __ADDON__DB = __ADDON__DB or {}
    ApplyDefaults(__ADDON__DB, defaults)
    ns.db = __ADDON__DB
end

function handlers.PLAYER_LOGIN()
    ns.Print("v" .. VERSION .. " loaded. Type /__SLASH__ for commands.")
end

ns.RegisterEvent("ADDON_LOADED")
ns.RegisterEvent("PLAYER_LOGIN")

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local commands = {}

function commands.help()
    ns.Print("commands:")
    print("  /__SLASH__ help - show this list")
    print("  /__SLASH__ version - show the addon version")
    print("  /__SLASH__ reset - reset settings to defaults")
end

function commands.version()
    ns.Print("version " .. VERSION)
end

function commands.reset()
    wipe(ns.db)
    ApplyDefaults(ns.db, defaults)
    ns.Print("settings reset.")
end

SLASH___ADDON_UPPER__1 = "/__SLASH__"
SlashCmdList["__ADDON_UPPER__"] = function(msg)
    local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    local fn = commands[cmd] or commands.help
    fn(rest)
end

-- Clicking the addon in the minimap addon menu runs this.
function __ADDON__Compartment_OnClick()
    commands.help()
end
