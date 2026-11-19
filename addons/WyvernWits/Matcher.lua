-- Wyvern Wits: rarity tiers and answer matching.

local _, ns = ...

ns.TIERS = {
    { name = "Peon",        points = 10,  color = "c8c8c8" },
    { name = "Grunt",       points = 25,  color = "5fd35f" },
    { name = "Blademaster", points = 45,  color = "4aa8ff" },
    { name = "Far Seer",    points = 70,  color = "b77cff" },
    { name = "Warchief",    points = 100, color = "ff9a2e" },
}

local Matcher = {}
ns.Matcher = Matcher

-- "The Un'Goro Crater!" -> "ungorocrater"
function Matcher.Normalize(text)
    local s = strlower(strtrim(text or ""))
    s = s:gsub("^the%s+", "")
    s = s:gsub("[^%w]", "")
    return s
end

-- Edit distance, giving up early once every path is over `limit`.
local function Distance(a, b, limit)
    local la, lb = #a, #b
    if math.abs(la - lb) > limit then return limit + 1 end
    local prev, cur = {}, {}
    for j = 0, lb do prev[j] = j end
    for i = 1, la do
        cur[0] = i
        local rowMin = i
        local ca = a:byte(i)
        for j = 1, lb do
            local cost = (ca == b:byte(j)) and 0 or 1
            local v = math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            cur[j] = v
            if v < rowMin then rowMin = v end
        end
        if rowMin > limit then return limit + 1 end
        prev, cur = cur, prev
    end
    return prev[lb]
end

-- Build the lookup table for a prompt the first time it's used.
-- tiers[n] is a list of answers; an answer is a name or
-- { "Display name", "alias", ... }.
local function Compile(prompt)
    if prompt.map then return end
    prompt.map, prompt.keys = {}, {}
    for tier, answers in ipairs(prompt.tiers) do
        for _, entry in ipairs(answers) do
            local names = type(entry) == "table" and entry or { entry }
            local hit = { name = names[1], tier = tier }
            for _, name in ipairs(names) do
                local key = Matcher.Normalize(name)
                if key ~= "" and not prompt.map[key] then
                    prompt.map[key] = hit
                    prompt.keys[#prompt.keys + 1] = key
                end
            end
            if not prompt.best or tier > prompt.best.tier then
                prompt.best = hit
            end
        end
    end
end

-- Returns { name = "Display name", tier = n } or nil.
-- Allows 1 typo for answers of 5+ letters, 2 for 9+.
function Matcher.Lookup(prompt, text)
    Compile(prompt)
    local key = Matcher.Normalize(text)
    if key == "" then return nil end
    if prompt.map[key] then return prompt.map[key] end

    local limit = (#key >= 9 and 2) or (#key >= 5 and 1) or 0
    if limit == 0 then return nil end
    local best, bestDistance = nil, limit + 1
    for _, candidate in ipairs(prompt.keys) do
        local d = Distance(key, candidate, limit)
        if d < bestDistance then
            best, bestDistance = prompt.map[candidate], d
        end
    end
    return best
end

-- The rarest answer for a prompt, shown after each round.
function Matcher.Best(prompt)
    Compile(prompt)
    return prompt.best
end
