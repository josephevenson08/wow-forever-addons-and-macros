-- Wyvern Wits: game flow.
--
-- States: idle -> ready (Start button) -> asking <-> reveal -> done.
-- Every point is 10 yards of depth.

local _, ns = ...

local Game = { state = "idle", score = 0 }
ns.Game = Game

local ROUND_TIME = 20
local REVEAL_TIME = 3.2
local YARDS_PER_POINT = 10
local RED = "|cffff6a5a"

local function Sound(name)
    if ns.db.sound and SOUNDKIT and SOUNDKIT[name] then
        PlaySound(SOUNDKIT[name])
    end
end

local function Tier(index, text)
    local tier = ns.TIERS[index]
    return "|cff" .. tier.color .. (text or tier.name) .. "|r"
end

local function Yards(n)
    n = math.floor(n + 0.5)
    return (BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)) .. " yd"
end

local function RouteText(flight)
    if not flight then return "Practice flight" end
    if flight.landed then return "Landed at " .. (flight.to or "your destination") end
    if flight.from and flight.to then return flight.from .. " to " .. flight.to end
    if flight.to then return "Flying to " .. flight.to end
    return "In flight"
end

function Game:IsPlaying()
    return self.state == "asking" or self.state == "reveal"
end

-- How many prompts fit this flight. Unknown routes get 5.
function Game:PromptCount()
    local key = ns.Flight.RouteKey(self.flight)
    local route = key and ns.db.routes[key]
    if route and route.secs then
        return math.max(3, math.min(10, math.floor((route.secs - 6) / 24)))
    end
    return 5
end

-- Show the window in its ready state. flight is nil for practice.
function Game:Open(flight)
    if self:IsPlaying() then
        ns.UI:Show()
        return
    end
    self.flight = flight
    self.state = "ready"
    self.score = 0
    self.count = self:PromptCount()
    ns.UI:Create()
    ns.Scene:Reset()
    ns.UI:SetRoute(RouteText(flight))
    ns.UI:SetCount("")
    ns.UI:SetPrompt(format("Answer %d prompts before you land.", self.count))
    ns.UI:SetMessage("Any valid answer counts, but rarer ones\nsend Thrall deeper. Press Start or Enter.")
    ns.UI:SetButton("Start")
    ns.UI:SetTimer(1)
    ns.UI:ClearInput()
    ns.UI:Show()
    if ns.db.autoStart then self:Start() end
end

function Game:Start()
    self.queue = ns.Prompts:Pick(self.count)
    self.count = #self.queue
    self.index = 0
    self.score = 0
    self.results = {}
    ns.Scene:Reset()
    ns.UI:SetButton("Answer")
    Sound("IG_CHARACTER_INFO_TAB")
    self:Next()
end

function Game:Next()
    self.index = self.index + 1
    if self.index > self.count then
        self:Finish()
        return
    end
    self.prompt = self.queue[self.index]
    self.state = "asking"
    self.timeLeft = ROUND_TIME
    ns.UI:SetCount(format("%d/%d", self.index, self.count))
    ns.UI:SetPrompt(self.prompt.text)
    ns.UI:SetMessage(nil)
    ns.UI:ClearInput()
    ns.UI:FocusInput()
end

function Game:Submit(text)
    if self.state == "ready" or self.state == "done" or self.state == "idle" then
        if self.state ~= "ready" then self.count = self:PromptCount() end
        self:Start()
        return
    end
    if self.state ~= "asking" then return end

    text = strtrim(text or "")
    if text == "" then
        ns.UI:SetMessage(RED .. "Type an answer first.|r")
        return
    end

    local hit = ns.Matcher.Lookup(self.prompt, text)
    if not hit then
        ns.UI:SetMessage(RED .. "Not on the list. Keep trying.|r")
        ns.UI:SelectInput()
        Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF")
        return
    end

    self.score = self.score + ns.TIERS[hit.tier].points
    self.results[self.index] = hit
    local isNew = self:Remember(hit)
    Sound(hit.tier == #ns.TIERS and "READY_CHECK" or "IG_QUEST_LIST_COMPLETE")
    self:Reveal(hit, isNew)
end

-- Count each answer the player gives; returns true the first time.
function Game:Remember(hit)
    local seen = ns.db.seen
    seen[self.prompt.id] = seen[self.prompt.id] or {}
    local bucket = seen[self.prompt.id]
    local first = not bucket[hit.name]
    bucket[hit.name] = (bucket[hit.name] or 0) + 1
    if hit.tier == #ns.TIERS then
        ns.db.stats.warchiefs = ns.db.stats.warchiefs + 1
    end
    return first
end

function Game:Reveal(hit, isNew)
    self.state = "reveal"
    self.revealLeft = REVEAL_TIME
    ns.UI:SetTimer(0)

    local line1
    if hit then
        local tier = ns.TIERS[hit.tier]
        line1 = format("%s  +%d  %s", Tier(hit.tier), tier.points, hit.name)
        if isNew then line1 = line1 .. "  |cff5fd35f(new)|r" end
    else
        line1 = "|cffaaaaaaTime's up. No answer, +0|r"
    end

    local best = ns.Matcher.Best(self.prompt)
    local line2
    if hit and hit.tier == best.tier then
        line2 = "As deep as this one goes."
    else
        line2 = "Deepest: " .. Tier(best.tier) .. " " .. best.name
    end
    ns.UI:SetMessage(line1 .. "\n" .. line2)
end

function Game:Finish()
    self.state = "done"
    local depth = self.score * YARDS_PER_POINT
    local db = ns.db
    db.stats.games = db.stats.games + 1

    local notes = {}
    if depth > db.stats.deepest then
        db.stats.deepest = depth
        notes[#notes + 1] = "New deepest dive!"
    end
    local key = ns.Flight.RouteKey(self.flight)
    if key then
        local route = db.routes[key] or {}
        db.routes[key] = route
        if depth > (route.best or 0) then
            if route.best then notes[#notes + 1] = "New best on this route!" end
            route.best = depth
        end
    end

    local marks = {}
    for i = 1, self.count do
        local hit = self.results[i]
        marks[#marks + 1] = hit and Tier(hit.tier, "+" .. ns.TIERS[hit.tier].points) or "|cff888888miss|r"
    end

    ns.UI:SetCount("")
    ns.UI:SetPrompt(format("Final depth: %s, %s", Yards(depth), ns.Scene.LayerAt(depth).name))
    local summary = table.concat(marks, "  ")
    if #notes > 0 then summary = summary .. "\n" .. table.concat(notes, " ") end
    ns.UI:SetMessage(summary)
    ns.UI:SetButton("Play again")
    ns.UI:SetTimer(0)
    Sound("IG_QUEST_LIST_OPEN")
end

-- Runs every frame while the window is shown, so closing it pauses the game.
function Game:OnUpdate(elapsed)
    if self.state == "asking" then
        self.timeLeft = self.timeLeft - elapsed
        if self.timeLeft <= 0 then
            self.results[self.index] = false
            self:Reveal(nil)
        else
            ns.UI:SetTimer(self.timeLeft / ROUND_TIME)
        end
    elseif self.state == "reveal" then
        self.revealLeft = self.revealLeft - elapsed
        if self.revealLeft <= 0 then self:Next() end
    end

    local depth = ns.Scene:Update(elapsed, self.score * YARDS_PER_POINT)
    ns.UI:SetDepth(depth, ns.Scene.LayerAt(depth).name)
end

function Game:OnTakeoff(flight)
    if self:IsPlaying() then
        self.flight = flight
        ns.UI:SetRoute(RouteText(flight))
        return
    end
    if ns.db.popup then self:Open(flight) end
end

function Game:OnLanded(flight)
    if self.flight ~= flight or not ns.UI.frame then return end
    if self.state == "ready" then
        -- never started: get out of the way
        self.state = "idle"
        ns.UI:Hide()
        return
    end
    ns.UI:SetRoute(RouteText(flight))
end
