-- Wyvern Wits: the 8-bit dive scene.
--
-- Everything is drawn on a 160x100 grid of "art pixels", each PX screen units
-- wide. The background is horizontal bands of flat color picked by depth;
-- props (clouds, rocks, crystals, embers, stars) come from a texture pool and
-- are placed by world depth, so they scroll up as Thrall dives.

local ADDON_NAME, ns = ...

local Scene = {}
ns.Scene = Scene

local PX = 3                 -- screen units per art pixel
local W, H = 160, 100        -- scene size in art pixels
local BAND = 2               -- art pixels per background band
local YPP = 6                -- yards of depth per art pixel
local SLOT = 40              -- yards between prop slots
local MID = H / 2            -- the row Thrall's depth maps to
local RIDER_X, RIDER_Y = 60, 38
local MEDIA = "Interface\\AddOns\\" .. ADDON_NAME .. "\\media\\"

Scene.PX, Scene.W, Scene.H = PX, W, H

local function Hex(h)
    return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 }
end

local LAYERS = {
    { at = 0,    name = "Open sky",        color = Hex("6ec6ff"), clouds = 0.4 },
    { at = 400,  name = "Cloud bank",      color = Hex("c4e2f5"), clouds = 0.8 },
    { at = 1000, name = "Over Durotar",    color = Hex("e8935a"), mesas = true },
    { at = 1800, name = "Canyon walls",    color = Hex("a4502d"), walls = "rock" },
    { at = 2600, name = "Deep caverns",    color = Hex("3e3048"), walls = "rock", crystals = true },
    { at = 3400, name = "Ragefire",        color = Hex("7a2414"), walls = "hot", embers = true },
    { at = 4200, name = "Molten core",     color = Hex("ff8a1a"), walls = "hot", embers = true },
    { at = 6000, name = "Elemental Plane", color = Hex("2a1240"), stars = true },
}
Scene.LAYERS = LAYERS

local WALL = {
    rock = { body = { 0.23, 0.11, 0.08 }, edge = { 0.77, 0.42, 0.24 } },
    hot  = { body = { 0.23, 0.07, 0.04 }, edge = { 1.00, 0.48, 0.10 } },
}

local function LayerIndex(yd)
    local i = 1
    while LAYERS[i + 1] and LAYERS[i + 1].at <= yd do i = i + 1 end
    return i
end

function Scene.LayerAt(yd)
    return LAYERS[LayerIndex(math.max(0, yd))]
end

-- Flat color for most of a layer, then four hard steps toward the next
-- layer's color near the boundary (posterized, not blended).
local function ColorAt(yd)
    if yd < 0 then
        local c = LAYERS[1].color
        return c[1], c[2], c[3]
    end
    local i = LayerIndex(yd)
    local cur, nxt = LAYERS[i], LAYERS[i + 1]
    local a = cur.color
    if not nxt then return a[1], a[2], a[3] end
    local t = (yd - cur.at) / (nxt.at - cur.at)
    local s = math.floor(math.max(0, math.min(1, (t - 0.6) / 0.4)) * 4) / 4
    local b = nxt.color
    return a[1] + (b[1] - a[1]) * s, a[2] + (b[2] - a[2]) * s, a[3] + (b[3] - a[3]) * s
end

-- Cheap repeatable pseudo-random number in [0, 1) for slot k.
local function Hash(k)
    local v = math.sin(k * 12.9898) * 43758.5453
    return v - math.floor(v)
end

function Scene:Create(parent)
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(W * PX, H * PX)
    f:SetClipsChildren(true)
    self.frame = f

    self.bands = {}
    for i = 0, H / BAND - 1 do
        local y = -i * BAND * PX
        local band = {}
        band.bg = f:CreateTexture(nil, "BACKGROUND")
        band.bg:SetPoint("TOPLEFT", 0, y)
        -- 1 unit taller than the band so scaled rows never leave seams
        band.bg:SetSize(W * PX, BAND * PX + 1)
        band.wallL = f:CreateTexture(nil, "BORDER")
        band.wallL:SetPoint("TOPLEFT", 0, y)
        band.wallR = f:CreateTexture(nil, "BORDER")
        band.wallR:SetPoint("TOPRIGHT", 0, y)
        band.edgeL = f:CreateTexture(nil, "ARTWORK")
        band.edgeL:SetPoint("TOPLEFT", band.wallL, "TOPRIGHT")
        band.edgeR = f:CreateTexture(nil, "ARTWORK")
        band.edgeR:SetPoint("TOPRIGHT", band.wallR, "TOPLEFT")
        for _, tex in ipairs({ band.wallL, band.wallR, band.edgeL, band.edgeR }) do
            tex:SetHeight(BAND * PX + 1)
        end
        band.edgeL:SetWidth(PX)
        band.edgeR:SetWidth(PX)
        self.bands[#self.bands + 1] = band
    end

    local props = CreateFrame("Frame", nil, f)
    props:SetAllPoints()
    props:SetFrameLevel(f:GetFrameLevel() + 1)
    self.props = props
    self.pool = {}
    self.used = 0

    local sprite = ns.sprites and ns.sprites.thrall_windrider
    self.sprite = sprite
    local rider = CreateFrame("Frame", nil, f)
    rider:SetSize(sprite.w * PX, sprite.h * PX)
    rider:SetFrameLevel(f:GetFrameLevel() + 2)
    local tex = rider:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(MEDIA .. sprite.file, "CLAMP", "CLAMP", "NEAREST")
    self.rider, self.riderTex = rider, tex

    self:Reset()
    return f
end

function Scene:Reset()
    self.depth = 0
    self.t = self.t or 0
end

-- Draw one solid rectangle from the prop pool, in art pixels.
function Scene:Rect(x, y, w, h, r, g, b, a)
    if x >= W or y >= H or x + w <= 0 or y + h <= 0 then return end
    self.used = self.used + 1
    local tex = self.pool[self.used]
    if not tex then
        tex = self.props:CreateTexture(nil, "ARTWORK")
        self.pool[self.used] = tex
    end
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", self.props, "TOPLEFT", x * PX, -y * PX)
    tex:SetSize(w * PX, h * PX)
    tex:SetColorTexture(r, g, b, a or 1)
    tex:Show()
end

function Scene:DrawBands(depth)
    for i, band in ipairs(self.bands) do
        local yd = depth + ((i - 1) * BAND + BAND / 2 - MID) * YPP
        band.bg:SetColorTexture(ColorAt(yd))

        local layer = Scene.LayerAt(yd)
        local wall = yd >= 0 and layer.walls and WALL[layer.walls]
        if wall then
            local wl = 6 + 2 * math.floor(3 * (1 + math.sin(yd / 70)))
            local wr = 6 + 2 * math.floor(3 * (1 + math.sin(yd / 53 + 2)))
            band.wallL:SetWidth(wl * PX)
            band.wallR:SetWidth(wr * PX)
            band.wallL:SetColorTexture(wall.body[1], wall.body[2], wall.body[3])
            band.wallR:SetColorTexture(wall.body[1], wall.body[2], wall.body[3])
            band.edgeL:SetColorTexture(wall.edge[1], wall.edge[2], wall.edge[3])
            band.edgeR:SetColorTexture(wall.edge[1], wall.edge[2], wall.edge[3])
            band.wallL:Show(); band.wallR:Show(); band.edgeL:Show(); band.edgeR:Show()
        else
            band.wallL:Hide(); band.wallR:Hide(); band.edgeL:Hide(); band.edgeR:Hide()
        end
    end
end

function Scene:DrawProps(depth, t)
    local first = math.floor((depth - MID * YPP) / SLOT) - 2
    local last = math.ceil((depth + MID * YPP) / SLOT) + 2
    for k = math.max(0, first), last do
        local yd = k * SLOT
        local layer = Scene.LayerAt(yd)
        local h = Hash(k)
        local sy = math.floor(MID + (yd - depth) / YPP + 0.5)

        if layer.clouds then
            if h < layer.clouds then
                local x = math.floor((h * 997 + t * (6 + h * 8)) % 200 - 20)
                self:Rect(x + 4, sy, 10, 2, 1, 1, 1)
                self:Rect(x, sy + 2, 20, 3, 1, 1, 1)
                self:Rect(x + 2, sy + 5, 16, 1, 0.84, 0.89, 0.94)
            end
        elseif layer.mesas then
            if h < 0.3 then
                local x = math.floor(h * 500) % 150
                self:Rect(x, sy, 10, 4, 0.71, 0.33, 0.18)
                self:Rect(x + 2, sy - 2, 6, 2, 0.71, 0.33, 0.18)
            end
        elseif layer.crystals then
            if h < 0.5 then
                local x = (h < 0.25) and 14 or 142
                local r, g, b = 0.72, 0.49, 1
                if h < 0.25 then r, g, b = 0.44, 0.76, 1 end
                self:Rect(x, sy, 2, 3, r, g, b)
                self:Rect(x - 1, sy + 1, 4, 1, r, g, b)
            end
        elseif layer.embers then
            for e = 0, 1 do
                local hh = Hash(k * 3 + e)
                local x = math.floor(14 + hh * 130)
                local y = sy - math.floor((t * 10 + hh * 40) % 40)
                if hh > 0.5 then
                    self:Rect(x, y, 1, 1, 1, 0.8, 0.2)
                else
                    self:Rect(x, y, 1, 1, 1, 0.35, 0.1)
                end
            end
        elseif layer.stars then
            if (t + h * 7) % 2 < 1.5 then
                local x = math.floor(h * 160)
                self:Rect(x, sy, 1, 1, 0.72, 0.49, 1)
                if h > 0.8 then
                    self:Rect(x - 1, sy, 3, 1, 0.72, 0.49, 1)
                    self:Rect(x, sy - 1, 1, 3, 0.72, 0.49, 1)
                end
            end
        end
    end
end

-- Advance the scene. `target` is the depth (yards) Thrall is heading for.
-- Returns the depth currently shown.
function Scene:Update(dt, target)
    if not self.frame then return 0 end
    self.t = self.t + dt
    local t = self.t

    self.depth = self.depth + (target - self.depth) * math.min(1, dt * 2.2)
    if math.abs(target - self.depth) < 0.5 then self.depth = target end
    local depth = self.depth
    local moving = math.abs(target - depth) > 4

    self:DrawBands(depth)

    self.used = 0
    self:DrawProps(depth, t)

    if moving then
        local tick = math.floor(t * 12)
        for i = 1, 10 do
            local x = math.floor(Hash(i + tick) * 150 + 5)
            local y = math.floor(Hash(i * 7 + tick) * 90)
            self:Rect(x, y, 1, 6, 1, 1, 1, 0.7)
        end
    end

    -- depth meter down the left edge
    self:Rect(3, 30, 5, 64, 0.11, 0.08, 0.13)
    local fill = math.floor(62 * math.min(1, depth / LAYERS[#LAYERS].at) + 0.5)
    if fill > 0 then self:Rect(4, 31, 3, fill, 0.95, 0.76, 0.31) end

    for i = self.used + 1, #self.pool do self.pool[i]:Hide() end

    local sprite = self.sprite
    local frame = math.floor(t * (moving and 10 or 5)) % sprite.frames
    self.riderTex:SetTexCoord(frame * sprite.w / sprite.texW, (frame + 1) * sprite.w / sprite.texW,
        0, sprite.h / sprite.texH)
    local bob = math.floor(math.sin(t * 3) + 0.5)
    self.rider:SetPoint("TOPLEFT", self.frame, "TOPLEFT", RIDER_X * PX, -(RIDER_Y + bob) * PX)

    return depth
end
