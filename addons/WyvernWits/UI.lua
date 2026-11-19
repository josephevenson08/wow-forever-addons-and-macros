-- Wyvern Wits: the game window (scene, prompt panel, answer box).

local _, ns = ...

local UI = {}
ns.UI = UI

local PAD = 4            -- border around the scene
local CONTROLS = 36      -- answer box strip under the scene
local INK = { 0.106, 0.078, 0.125 }
local GOLD = { 0.95, 0.76, 0.31 }

local function Font(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    return fs
end

-- Dark panel with a 2px gold pixel border.
local function Panel(parent)
    local box = CreateFrame("Frame", nil, parent)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(INK[1], INK[2], INK[3], 0.88)
    local function Edge(p1, p2, w, h)
        local e = box:CreateTexture(nil, "BORDER")
        e:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
        e:SetPoint(p1)
        e:SetPoint(p2)
        if w then e:SetWidth(w) else e:SetHeight(h) end
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 2)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    Edge("TOPLEFT", "BOTTOMLEFT", 2)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 2)
    return box
end

function UI:Create()
    if self.frame then return self.frame end
    local Scene = ns.Scene
    local sceneW, sceneH = Scene.W * Scene.PX, Scene.H * Scene.PX

    local f = CreateFrame("Frame", "WyvernWitsFrame", UIParent)
    f:SetSize(sceneW + PAD * 2, sceneH + PAD * 2 + CONTROLS)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        UI:SavePosition()
    end)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(INK[1], INK[2], INK[3], 0.97)

    Scene:Create(f):SetPoint("TOPLEFT", PAD, -PAD)

    local hud = CreateFrame("Frame", nil, f)
    hud:SetAllPoints(Scene.frame)
    hud:SetFrameLevel(Scene.frame:GetFrameLevel() + 10)

    -- prompt panel across the top
    local top = Panel(hud)
    top:SetPoint("TOPLEFT", 10, -10)
    top:SetPoint("TOPRIGHT", -40, -10)
    top:SetHeight(70)
    self.route = Font(top, 11)
    self.route:SetPoint("TOPLEFT", 10, -9)
    self.route:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    self.count = Font(top, 11)
    self.count:SetPoint("TOPRIGHT", -10, -9)
    self.count:SetTextColor(0.8, 0.8, 0.8)
    self.prompt = Font(top, 15)
    self.prompt:SetPoint("TOPLEFT", 10, -26)
    self.prompt:SetPoint("TOPRIGHT", -10, -26)
    self.prompt:SetJustifyH("LEFT")
    self.prompt:SetTextColor(0.96, 0.94, 0.85)
    local timerBg = top:CreateTexture(nil, "ARTWORK")
    timerBg:SetPoint("BOTTOMLEFT", 10, 9)
    timerBg:SetPoint("BOTTOMRIGHT", -10, 9)
    timerBg:SetHeight(6)
    timerBg:SetColorTexture(0.23, 0.17, 0.25)
    local timer = top:CreateTexture(nil, "OVERLAY")
    timer:SetPoint("TOPLEFT", timerBg)
    timer:SetPoint("BOTTOMLEFT", timerBg)
    self.timer, self.timerWidth = timer, sceneW - 50 - 20

    -- message panel near the bottom
    local msg = Panel(hud)
    msg:SetSize(310, 58)
    msg:SetPoint("BOTTOM", -10, 10)
    self.msgText = Font(msg, 12)
    self.msgText:SetPoint("CENTER")
    self.msgText:SetWidth(294)
    self.msgText:SetJustifyH("CENTER")
    self.msgText:SetSpacing(4)
    self.msg = msg

    self.depthText = Font(hud, 11)
    self.depthText:SetPoint("BOTTOMRIGHT", -8, 12)
    self.depthText:SetJustifyH("RIGHT")
    self.depthText:SetSpacing(3)

    local close = CreateFrame("Button", nil, hud, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() f:Hide() end)

    -- answer box and button under the scene
    local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    edit:SetSize(sceneW - 140, 24)
    edit:SetPoint("BOTTOMLEFT", PAD + 12, 6)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(48)
    edit:SetScript("OnEnterPressed", function(box) ns.Game:Submit(box:GetText()) end)
    edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    self.edit = edit

    local button = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    button:SetSize(116, 24)
    button:SetPoint("BOTTOMRIGHT", -PAD - 4, 6)
    button:SetScript("OnClick", function() ns.Game:Submit(edit:GetText()) end)
    self.button = button

    f:SetScript("OnUpdate", function(_, elapsed) ns.Game:OnUpdate(elapsed) end)
    f:SetScript("OnHide", function() edit:ClearFocus() end)
    f:Hide()
    -- Escape closes the window like other panels
    tinsert(UISpecialFrames, "WyvernWitsFrame")

    self.frame = f
    self:RestorePosition()
    return f
end

function UI:SavePosition()
    local point, _, relPoint, x, y = self.frame:GetPoint(1)
    ns.db.position = { point, relPoint, x, y }
end

function UI:RestorePosition()
    local f = self.frame
    f:ClearAllPoints()
    local pos = ns.db.position
    if pos then
        f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
    f:SetScale(ns.db.scale or 1)
end

function UI:Show()
    self:Create():Show()
end

function UI:Hide()
    if self.frame then self.frame:Hide() end
end

function UI:IsShown()
    return self.frame and self.frame:IsShown()
end

function UI:SetRoute(text) self.route:SetText(text or "") end
function UI:SetCount(text) self.count:SetText(text or "") end
function UI:SetPrompt(text) self.prompt:SetText(text or "") end
function UI:SetButton(text) self.button:SetText(text) end

function UI:SetMessage(text)
    if text and text ~= "" then
        self.msgText:SetText(text)
        self.msg:Show()
    else
        self.msg:Hide()
    end
end

-- frac 0..1 of the round left; turns red in the last quarter.
function UI:SetTimer(frac)
    frac = math.max(0, math.min(1, frac))
    self.timer:SetWidth(math.max(0.1, self.timerWidth * frac))
    if frac < 0.25 then
        self.timer:SetColorTexture(0.75, 0.22, 0.17)
    else
        self.timer:SetColorTexture(0.37, 0.66, 0.24)
    end
end

function UI:SetDepth(yards, layerName)
    local n = math.floor(yards + 0.5)
    local text = BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)
    self.depthText:SetText(text .. " yd\n|cfff2c14e" .. layerName .. "|r")
end

function UI:ClearInput()
    self.edit:SetText("")
end

function UI:FocusInput()
    self.edit:SetFocus()
end

function UI:SelectInput()
    self.edit:HighlightText()
    self.edit:SetFocus()
end
