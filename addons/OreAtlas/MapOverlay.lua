-- Ore Atlas: shade mining areas on the world map.
--
-- We don't draw hundreds of node icons (GatherMate2 already can). Instead
-- each zone is cut into a GRID x GRID grid, and every cell with nodes of an
-- ore you care about is shaded in that ore's skill color for you: orange,
-- yellow, green, or gray. More nodes in a cell = stronger shade.
--
-- The overlay is a plain frame on the map canvas. It only uses stored
-- coordinates, never the player's position, so map restrictions in
-- instances don't affect it.

local _, ns = ...

local Overlay = { textures = {}, used = 0, shown = {} }
ns.MapOverlay = Overlay

local GRID = 32
local ZONE_TYPE = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3

local function RGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

function Overlay:Init()
    if self.frame or not (WorldMapFrame and WorldMapFrame.GetCanvas) then return end
    local canvas = WorldMapFrame:GetCanvas()
    local f = CreateFrame("Frame", nil, canvas)
    f:SetAllPoints(canvas)
    -- above the map tiles, below most map pins
    f:SetFrameLevel(canvas:GetFrameLevel() + 3)
    self.frame = f

    if type(WorldMapFrame.OnMapChanged) == "function" then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function() Overlay:Refresh() end)
    end
    WorldMapFrame:HookScript("OnShow", function() Overlay:Refresh() end)
    canvas:HookScript("OnSizeChanged", function() Overlay:Refresh() end)
    self:CreateButton()
end

function Overlay:Texture()
    self.used = self.used + 1
    local tex = self.textures[self.used]
    if not tex then
        tex = self.frame:CreateTexture(nil, "OVERLAY")
        self.textures[self.used] = tex
    end
    tex:ClearAllPoints()
    tex:Show()
    return tex
end

-- Ores drawn on the current map: { { ore = ore, cells = n }, ... }
function Overlay:Draw(mapID)
    local w, h = self.frame:GetWidth(), self.frame:GetHeight()
    if w <= 0 or h <= 0 then return {} end
    local cw, ch = w / GRID, h / GRID
    local S = ns.Skill
    local skill = S.known and S.rank or nil
    local effective = S.known and S:Effective() or nil
    local shown = {}

    for key, coords in pairs(ns.Nodes:ForZone(mapID)) do
        local ore = ns.ORE_BY_KEY[key]
        if ore and ns.ShowOnMap(ore) then
            local color = ns.ColorFor(ore, skill, effective) or "orange"
            local r, g, b = RGB(ns.COLORS[color].hex)
            local cells, count = {}, 0
            for _, coord in ipairs(coords) do
                local x, y = ns.Nodes.Decode(coord)
                local cell = math.floor(y * GRID) * GRID + math.floor(x * GRID)
                if not cells[cell] then count = count + 1 end
                cells[cell] = (cells[cell] or 0) + 1
            end
            for cell, n in pairs(cells) do
                local tex = self:Texture()
                tex:SetPoint("TOPLEFT", self.frame, "TOPLEFT", (cell % GRID) * cw, -math.floor(cell / GRID) * ch)
                tex:SetSize(cw, ch)
                tex:SetColorTexture(r, g, b, math.min(0.6, 0.22 + 0.08 * n))
            end
            shown[#shown + 1] = { ore = ore, color = color, nodes = #coords }
        end
    end
    table.sort(shown, function(a, b) return a.ore.req < b.ore.req end)
    return shown
end

function Overlay:Refresh()
    if not self.frame then return end
    self.used = 0
    self.shown = {}
    if ns.db.mapOverlay and WorldMapFrame:IsShown() then
        local mapID = WorldMapFrame:GetMapID()
        local info = mapID and C_Map.GetMapInfo(mapID)
        -- zones and dungeons only; continents would be a smear of squares
        if info and info.mapType >= ZONE_TYPE then
            self.shown = self:Draw(mapID)
        end
    end
    for i = self.used + 1, #self.textures do self.textures[i]:Hide() end
    self:UpdateButton()
end

---------------------------------------------------------------------------
-- On/off button in the corner of the world map
---------------------------------------------------------------------------

function Overlay:CreateButton()
    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame
    local b = CreateFrame("Button", nil, WorldMapFrame)
    b:SetSize(130, 22)
    -- raised off the corner, where coordinate addons put their text
    b:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 8, 36)
    b:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 500)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.063, 0.047, 0.9)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.85, 0.5, 0.15)
    b.text = b:CreateFontString(nil, "OVERLAY")
    b.text:SetFont(STANDARD_TEXT_FONT, 12, "")
    b.text:SetShadowOffset(1, -1)
    b.text:SetPoint("CENTER")

    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ns.UI:Toggle()
        else
            ns.db.mapOverlay = not ns.db.mapOverlay
            Overlay:Refresh()
        end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("Ore Atlas", 0.95, 0.76, 0.31)
        if not ns.db.mapOverlay then
            GameTooltip:AddLine("Ore areas are hidden.", 1, 1, 1)
        elseif #Overlay.shown > 0 then
            for _, item in ipairs(Overlay.shown) do
                local hex = ns.COLORS[item.color].hex
                GameTooltip:AddDoubleLine("|cff" .. hex .. item.ore.name .. "|r", item.nodes .. " nodes", 1, 1, 1, 1, 1, 1)
            end
        else
            GameTooltip:AddLine("No ore areas to show on this map.", 1, 1, 1)
        end
        if ns.Nodes:HasGatherMate() then
            GameTooltip:AddLine(format("Node data: GatherMate2%s plus spots you've mined.",
                ns.Nodes:HasRawData() and " and GatherMate2_Data" or ""), 0.66, 0.6, 0.47, true)
        else
            GameTooltip:AddLine("Showing only spots you've mined. Install GatherMate2 and GatherMate2_Data for every zone.", 0.66, 0.6, 0.47, true)
        end
        GameTooltip:AddLine("Click: show or hide ore areas", 0.5, 1, 0.5)
        GameTooltip:AddLine("Right-click: open Ore Atlas", 0.5, 1, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.button = b
end

function Overlay:UpdateButton()
    local b = self.button
    if not b then return end
    if ns.db.mapOverlay then
        b.text:SetText("|cfff2c14eOre areas:|r on")
    else
        b.text:SetText("|cfff2c14eOre areas:|r off")
    end
    b:SetWidth(math.ceil(b.text:GetStringWidth()) + 20)
end
