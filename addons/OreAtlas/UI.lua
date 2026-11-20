-- Ore Atlas: the pane. A Mining skill header, then one card per ore with
-- its skill-color bar and clickable zones.

local _, ns = ...

local UI = { filter = "all", cards = {} }
ns.UI = UI

local W, H = 410, 580
local SCROLL_TOP = 172
local CARD_W = W - 42          -- scroll area width (scrollbar sits to the right)
local BAR_W = CARD_W - 16
local GOLD = { 0.95, 0.76, 0.31 }
local TAN = { 0.91, 0.86, 0.75 }
local MUTED = { 0.66, 0.60, 0.47 }
local INK = { 0.08, 0.063, 0.047 }

local function Font(parent, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    local c = color or TAN
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH("LEFT")
    return fs
end

local function Solid(parent, layer, r, g, b, a)
    local tex = parent:CreateTexture(nil, layer)
    tex:SetColorTexture(r, g, b, a or 1)
    return tex
end

local function Border(frame, r, g, b)
    local edges = {
        { "TOPLEFT", "TOPRIGHT", "h" }, { "BOTTOMLEFT", "BOTTOMRIGHT", "h" },
        { "TOPLEFT", "BOTTOMLEFT", "w" }, { "TOPRIGHT", "BOTTOMRIGHT", "w" },
    }
    for _, e in ipairs(edges) do
        local tex = Solid(frame, "BORDER", r, g, b)
        tex:SetPoint(e[1])
        tex:SetPoint(e[2])
        if e[3] == "h" then tex:SetHeight(1) else tex:SetWidth(1) end
    end
end

local function Colored(hex, text)
    return "|cff" .. hex .. text .. "|r"
end

local function SkillX(skill)
    return math.max(0, math.min(1, skill / ns.MAX_SKILL)) * BAR_W
end

---------------------------------------------------------------------------
-- Ore cards
---------------------------------------------------------------------------

local function ZoneLabel(zone)
    local data = ns.ZONES[zone.name]
    local label = zone.name
    if data and data.inside then label = label .. " (" .. data.inside .. ")" end
    if data and data.levels and not data.inside then label = label .. " " .. data.levels end
    if zone.dense then label = label .. " *" end
    return label
end

local function ZoneButton(card, zone)
    local button = CreateFrame("Button", nil, card)
    button:SetHeight(18)
    local bg = Solid(button, "BACKGROUND", 0.16, 0.125, 0.086)
    bg:SetAllPoints()
    Border(button, 0.35, 0.27, 0.19)
    local hl = Solid(button, "HIGHLIGHT", 1, 0.85, 0.5, 0.15)
    hl:SetAllPoints()
    local text = Font(button, 11, zone.forever and GOLD or TAN)
    text:SetPoint("LEFT", 6, 0)
    text:SetText(ZoneLabel(zone))
    button:SetWidth(math.ceil(text:GetStringWidth()) + 12)

    button:SetScript("OnClick", function() ns.Maps:Open(zone.name) end)
    button:SetScript("OnEnter", function(self)
        local data = ns.ZONES[zone.name] or {}
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(zone.name)
        if data.inside then
            GameTooltip:AddLine("Inside " .. data.inside, 1, 1, 1)
        elseif data.new then
            GameTooltip:AddLine("New WoW Forever zone", 1, 1, 1)
        elseif data.levels then
            GameTooltip:AddLine("Levels " .. data.levels, 1, 1, 1)
        end
        if zone.forever then
            GameTooltip:AddLine("Named by WoW Forever mining guides", GOLD[1], GOLD[2], GOLD[3])
        else
            GameTooltip:AddLine("From classic spawn data", MUTED[1], MUTED[2], MUTED[3])
        end
        if zone.dense then GameTooltip:AddLine("One of the densest zones for this ore", 1, 1, 1) end
        GameTooltip:AddLine("Click to open the map", 0.5, 1, 0.5)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function CreateCard(parent, ore)
    local card = CreateFrame("Frame", nil, parent)
    card:SetWidth(CARD_W)
    card.ore = ore
    local bg = Solid(card, "BACKGROUND", 0.11, 0.086, 0.063)
    bg:SetAllPoints()
    Border(card, 0.23, 0.18, 0.125)

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", 8, -8)
    local iconID = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(ore.item)
    icon:SetTexture(iconID or "Interface\\Icons\\Trade_Mining")
    card.icon = icon

    card.title = Font(card, 13)
    card.title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
    card.sub = Font(card, 11, MUTED)
    card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -2)

    -- skill bar: dark red below the requirement, then orange/yellow/green/gray
    local bar = CreateFrame("Frame", nil, card)
    bar:SetSize(BAR_W, 10)
    bar:SetPoint("TOPLEFT", 8, -44)
    Solid(bar, "BACKGROUND", 0.24, 0.07, 0.07):SetAllPoints()
    local bands = {
        { ore.req, ore.yellow, "orange" }, { ore.yellow, ore.green, "yellow" },
        { ore.green, ore.gray, "green" }, { ore.gray, ns.MAX_SKILL, "gray" },
    }
    for _, band in ipairs(bands) do
        local from, to = SkillX(band[1]), SkillX(band[2])
        if to > from then
            local hex = ns.COLORS[band[3]].hex
            local seg = Solid(bar, "ARTWORK", tonumber(hex:sub(1, 2), 16) / 255,
                tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255)
            seg:SetPoint("TOPLEFT", from, 0)
            seg:SetSize(to - from, 10)
        end
    end
    local marker = Solid(bar, "OVERLAY", 1, 1, 1)
    marker:SetSize(2, 16)
    card.marker = marker

    local thresholds = Font(card, 11, MUTED)
    thresholds:SetPoint("TOPLEFT", 8, -58)
    if ore.req > ns.MAX_SKILL then
        thresholds:SetText(format("Needs %d: above the %d cap", ore.req, ns.MAX_SKILL))
    elseif ore.gray == ore.req then
        thresholds:SetText(format("Needs %d", ore.req))
    else
        thresholds:SetText(format("%d orange, %d yellow, %d green, %d gray",
            ore.req, ore.yellow, ore.green, ore.gray))
    end

    local y = -76
    if ore.notes then
        local notes = Font(card, 11, TAN)
        notes:SetPoint("TOPLEFT", 8, y)
        notes:SetWidth(CARD_W - 16)
        notes:SetWordWrap(true)
        notes:SetText(ore.notes)
        y = y - math.ceil(notes:GetStringHeight()) - 6
    end

    -- zone buttons, wrapped into rows
    local x = 8
    for _, zone in ipairs(ore.zones) do
        local button = ZoneButton(card, zone)
        local w = button:GetWidth()
        if x + w > CARD_W - 8 and x > 8 then
            x = 8
            y = y - 22
        end
        button:SetPoint("TOPLEFT", x, y)
        x = x + w + 4
    end
    card:SetHeight(-y + 18 + 8)
    return card
end

function UI:UpdateCard(card, skill, effective)
    local ore = card.ore
    local color = ns.ColorFor(ore, skill, effective)
    local status = ""
    if color == "red" then
        status = Colored(ns.COLORS.red.hex, "need " .. ore.req)
    elseif color then
        status = Colored(ns.COLORS[color].hex, ns.COLORS[color].label)
    end
    card.title:SetText(ore.name .. "  " .. status)
    card.sub:SetText(ore.ore .. (ore.minor and ", quest ore" or ""))

    if skill then
        card.marker:ClearAllPoints()
        card.marker:SetPoint("CENTER", card.marker:GetParent(), "LEFT", SkillX(skill), 0)
        card.marker:Show()
    else
        card.marker:Hide()
    end
    card:SetAlpha((color == "red" or color == "gray") and 0.6 or 1)
    return color
end

---------------------------------------------------------------------------
-- The pane
---------------------------------------------------------------------------

local function FilterButton(parent, label, key)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(20)
    local bg = Solid(button, "BACKGROUND", 0.16, 0.125, 0.086)
    bg:SetAllPoints()
    Border(button, 0.35, 0.27, 0.19)
    local hl = Solid(button, "HIGHLIGHT", 1, 0.85, 0.5, 0.15)
    hl:SetAllPoints()
    button.text = Font(button, 12)
    button.text:SetPoint("CENTER")
    button.text:SetText(label)
    button:SetWidth(math.ceil(button.text:GetStringWidth()) + 20)
    button.key = key
    button:SetScript("OnClick", function()
        UI.filter = key
        ns.db.filter = key
        UI:Refresh()
    end)
    return button
end

function UI:Create()
    if self.frame then return self.frame end
    self.filter = ns.db.filter or "all"

    local f = CreateFrame("Frame", "OreAtlasFrame", UIParent)
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint(1)
        ns.db.position = { point, relPoint, x, y }
    end)
    Solid(f, "BACKGROUND", INK[1], INK[2], INK[3], 0.97):SetAllPoints()
    Border(f, 0.54, 0.42, 0.23)
    self.frame = f

    local title = Font(f, 16, GOLD)
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Ore Atlas")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)

    -- skill header
    self.skillLabel = Font(f, 13)
    self.skillLabel:SetPoint("TOPLEFT", 14, -40)
    self.skillValue = Font(f, 13)
    self.skillValue:SetPoint("TOPRIGHT", -14, -40)
    self.skillValue:SetJustifyH("RIGHT")
    local barBg = Solid(f, "ARTWORK", 0.16, 0.13, 0.09)
    barBg:SetPoint("TOPLEFT", 14, -58)
    barBg:SetSize(W - 28, 10)
    self.skillFill = Solid(f, "OVERLAY", 0.29, 0.54, 0.16)
    self.skillFill:SetPoint("TOPLEFT", barBg)
    self.skillFill:SetHeight(10)
    self.skillBarWidth = W - 28

    self.hint = Font(f, 12, { 1, 0.69, 0.38 })
    self.hint:SetPoint("TOPLEFT", 14, -74)
    self.hint:SetWidth(W - 28)
    self.hint:SetWordWrap(true)

    local best = CreateFrame("Button", nil, f)
    best:SetPoint("TOPLEFT", 14, -104)
    best:SetSize(W - 28, 16)
    best.text = Font(best, 12)
    best.text:SetAllPoints()
    best.text:SetWordWrap(false)
    best:SetScript("OnClick", function() UI:ScrollToBest() end)
    self.best = best

    self.alts = Font(f, 11, MUTED)
    self.alts:SetPoint("TOPLEFT", 14, -124)
    self.alts:SetWidth(W - 28)
    self.alts:SetWordWrap(false)

    self.filterAll = FilterButton(f, "All ores", "all")
    self.filterAll:SetPoint("TOPLEFT", 14, -144)
    self.filterUseful = FilterButton(f, "Useful for me", "useful")
    self.filterUseful:SetPoint("LEFT", self.filterAll, "RIGHT", 6, 0)

    -- scrolling ore list
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", "OreAtlasScroll", f, "UIPanelScrollFrameTemplate")
    if not ok then scroll = CreateFrame("ScrollFrame", "OreAtlasScroll", f) end
    scroll:SetPoint("TOPLEFT", 12, -SCROLL_TOP)
    scroll:SetPoint("BOTTOMRIGHT", -30, 30)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(CARD_W, 10)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(frame, delta)
        UI:ScrollTo(frame:GetVerticalScroll() - delta * 60)
    end)
    self.scroll, self.content = scroll, content

    for _, ore in ipairs(ns.ORES) do
        self.cards[#self.cards + 1] = CreateCard(content, ore)
    end

    local legend = Font(f, 11, MUTED)
    legend:SetPoint("BOTTOMLEFT", 14, 10)
    legend:SetText(Colored("f2c14e", "Gold") .. " = named by Forever guides    * = densest (classic data)")

    f:SetScript("OnShow", function() UI:Refresh() end)
    f:Hide()
    tinsert(UISpecialFrames, "OreAtlasFrame")

    f:ClearAllPoints()
    local pos = ns.db.position
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
    f:SetScale(ns.db.scale or 1)
    return f
end

function UI:ScrollTo(offset)
    local max = math.max(0, self.content:GetHeight() - self.scroll:GetHeight())
    self.scroll:SetVerticalScroll(math.max(0, math.min(max, offset)))
end

function UI:ScrollToBest()
    local S = ns.Skill
    local ore = S.known and ns.BestOre(S.rank, S:Effective())
    if not ore then return end
    for _, card in ipairs(self.cards) do
        if card.ore == ore and card:IsShown() and card.offset then
            self:ScrollTo(card.offset)
            return
        end
    end
end

function UI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    local S = ns.Skill
    local skill = S.known and S.rank or nil
    local effective = S.known and S:Effective() or nil

    -- header
    self.skillLabel:SetText("Mining")
    if S.known then
        local value = format("%d / %d", S.rank, S.max)
        if (S.modifier or 0) > 0 then value = value .. Colored("40c040", " (+" .. S.modifier .. ")") end
        self.skillValue:SetText(value .. "  " .. Colored("a89878", ns.RankName(S.max)))
        self.skillFill:SetWidth(math.max(0.1, self.skillBarWidth * (S.max > 0 and S.rank / S.max or 0)))
    else
        self.skillValue:SetText(Colored("a89878", "not learned"))
        self.skillFill:SetWidth(0.1)
    end
    local hint = ns.RankHint(skill, S.max)
    local gain = S:SessionGain()
    if gain > 0 then hint = (hint and hint .. "  " or "") .. Colored("40c040", "+" .. gain .. " this session") end
    self.hint:SetText(hint or "")

    local best, color = ns.BestOre(skill, effective)
    if best then
        self.best.text:SetText(format("Best now: %s %s in %s", best.name,
            Colored(ns.COLORS[color].hex, color), ns.TopZones(best, 3)))
        self.best:Show()
    else
        self.best:Hide()
    end

    local alts = {}
    for _, char in ipairs(S:Alts()) do
        alts[#alts + 1] = char.name .. " " .. char.rank
        if #alts == 4 then break end
    end
    self.alts:SetText(#alts > 0 and ("Other miners: " .. table.concat(alts, ", ")) or "")

    for _, button in ipairs({ self.filterAll, self.filterUseful }) do
        local on = button.key == self.filter
        button.text:SetTextColor(on and GOLD[1] or MUTED[1], on and GOLD[2] or MUTED[2], on and GOLD[3] or MUTED[3])
    end

    -- cards
    local y = 0
    for _, card in ipairs(self.cards) do
        local c = self:UpdateCard(card, skill, effective)
        local show = self.filter ~= "useful" or not skill or card.ore.always
            or c == "orange" or c == "yellow" or c == "green"
        if show then
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
            card.offset = y
            card:Show()
            y = y + card:GetHeight() + 6
        else
            card:Hide()
            card.offset = nil
        end
    end
    self.content:SetHeight(math.max(1, y))
    self:ScrollTo(self.scroll:GetVerticalScroll())
end

function UI:Toggle()
    local f = self:Create()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        self:ScrollToBest()
    end
end
