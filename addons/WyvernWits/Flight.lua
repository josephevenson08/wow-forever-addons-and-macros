-- Wyvern Wits: detect taking off from and landing at a flight master.
--
-- There's no "taxi started" event. We hook TakeTaxiNode to learn the
-- destination, then wait for UnitOnTaxi to turn true (it can lag
-- PLAYER_CONTROL_LOST a little). While flying we poll once a second for
-- landing, and PLAYER_CONTROL_GAINED checks right away.

local _, ns = ...

local Flight = {}
ns.Flight = Flight

local handlers = ns.handlers
local pending      -- { from, to } between clicking a node and lifting off
local current      -- { from, to, started, landed } while in the air
local takeoffTicker, landingTicker

local function OnTaxi()
    local onTaxi = UnitOnTaxi("player")
    if issecretvalue and issecretvalue(onTaxi) then return false end
    return onTaxi and true or false
end

-- "Orgrimmar, Durotar" -> "Orgrimmar"
local function ShortName(name)
    if type(name) ~= "string" or name == "" then return nil end
    return name:match("^([^,]+)") or name
end

local function CurrentNodeName()
    if not (NumTaxiNodes and TaxiNodeGetType) then return nil end
    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then return TaxiNodeName(i) end
    end
end

function Flight.RouteKey(flight)
    if flight and flight.from and flight.to then
        return flight.from .. " > " .. flight.to
    end
end

function Flight:Current()
    return current
end

function Flight:Begin(from, to)
    if current then return end
    current = { from = from, to = to, started = GetTime() }
    if landingTicker then landingTicker:Cancel() end
    landingTicker = C_Timer.NewTicker(1, function()
        if not OnTaxi() then Flight:End() end
    end)
    ns.Game:OnTakeoff(current)
end

function Flight:End()
    if not current then return end
    local flight = current
    current = nil
    if landingTicker then landingTicker:Cancel(); landingTicker = nil end
    flight.landed = true

    -- Remember how long this route takes so games can fit the flight.
    local key = Flight.RouteKey(flight)
    local secs = GetTime() - flight.started
    if key and secs > 10 then
        local route = ns.db.routes[key] or {}
        ns.db.routes[key] = route
        route.secs = route.secs and math.floor((route.secs + secs) / 2) or math.floor(secs)
    end

    ns.Game:OnLanded(flight)
end

local function TryTakeoff()
    if pending and OnTaxi() then
        local p = pending
        pending = nil
        if takeoffTicker then takeoffTicker:Cancel(); takeoffTicker = nil end
        Flight:Begin(p.from, p.to)
        return true
    end
end

if TakeTaxiNode then
    hooksecurefunc("TakeTaxiNode", function(slot)
        pending = { from = ShortName(CurrentNodeName()), to = ShortName(TaxiNodeName(slot)) }
        if takeoffTicker then takeoffTicker:Cancel() end
        local tries = 0
        takeoffTicker = C_Timer.NewTicker(0.25, function()
            tries = tries + 1
            if not TryTakeoff() and tries >= 20 then
                pending = nil
                if takeoffTicker then takeoffTicker:Cancel() end
                takeoffTicker = nil
            end
        end, 20)
    end)
end

function handlers.PLAYER_CONTROL_LOST()
    TryTakeoff()
end

function handlers.PLAYER_CONTROL_GAINED()
    if current and not OnTaxi() then Flight:End() end
end

-- After a /reload mid-flight, pick the flight back up (route unknown).
function handlers.PLAYER_ENTERING_WORLD()
    if not current and OnTaxi() then
        Flight:Begin(nil, nil)
    elseif current and not OnTaxi() then
        Flight:End()
    end
end

ns.RegisterEvent("PLAYER_CONTROL_LOST")
ns.RegisterEvent("PLAYER_CONTROL_GAINED")
ns.RegisterEvent("PLAYER_ENTERING_WORLD")
