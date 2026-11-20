-- Ore Atlas: ores, zones, trainer ranks, and skill-up colors.
--
-- Sources (Nov 2026): Warcraft Wiki "Forever mining techniques", plus the
-- Forever mining guides on wowforeverguides.com, classicwowforever.com,
-- forevermastery.com, wow-professions.com and blazingboost.com. The Forever
-- client ships no spawn tables, so zone lists mix two kinds of data:
--   flag "f" = a Forever guide names this zone for the ore
--   flag "d" = one of the densest zones in classic spawn data
--   no flag  = classic spawn data only
-- When in-game mining proves a zone right or wrong, fix it here.

local _, ns = ...

---------------------------------------------------------------------------
-- Trainer ranks
---------------------------------------------------------------------------

ns.RANKS = {
    { name = "Apprentice", cap = 75,  learnAt = 1 },
    { name = "Journeyman", cap = 150, learnAt = 50 },
    { name = "Expert",     cap = 225, learnAt = 125 },
    { name = "Artisan",    cap = 300, learnAt = 200 },
}
ns.MAX_SKILL = 300

function ns.RankName(maxSkill)
    for _, rank in ipairs(ns.RANKS) do
        if rank.cap == maxSkill then return rank.name end
    end
    return ""
end

-- One line of advice about training, or nil.
function ns.RankHint(skill, maxSkill)
    if not skill then
        return "Learn Mining from a trainer. Junior trainers in starting zones teach up to 75."
    end
    if skill >= ns.MAX_SKILL then
        return "Max skill. Heavy Thorium on Mount Hyjal is the new endgame vein."
    end
    for _, rank in ipairs(ns.RANKS) do
        if rank.cap > maxSkill then
            if skill < rank.learnAt then
                return format("%d more until you can train %s (at %d).", rank.learnAt - skill, rank.name, rank.learnAt)
            elseif skill >= maxSkill then
                return format("Capped at %d. Train %s at a Mining trainer to keep going.", maxSkill, rank.name)
            else
                return format("You can train %s now (needs %d).", rank.name, rank.learnAt)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Skill-up colors
---------------------------------------------------------------------------

ns.COLORS = {
    red    = { hex = "ff3030", label = "too low" },
    orange = { hex = "ff8040", label = "orange" },
    yellow = { hex = "ffff00", label = "yellow" },
    green  = { hex = "40c040", label = "green" },
    gray   = { hex = "808080", label = "gray" },
}

-- skill decides the color; effective (skill + gear bonus) decides whether
-- you can mine the node at all.
function ns.ColorFor(ore, skill, effective)
    if not skill then return nil end
    if (effective or skill) < ore.req then return "red" end
    if skill < ore.yellow then return "orange" end
    if skill < ore.green then return "yellow" end
    if skill < ore.gray then return "green" end
    return "gray"
end

---------------------------------------------------------------------------
-- Zones: classic level ranges, and uiMapIDs from the retail client to try
-- if looking the zone up by name fails. Dungeons open their outdoor zone.
---------------------------------------------------------------------------

local ZONES = {}
ns.ZONES = ZONES

local function Zone(name, levels, ids, extra)
    local zone = extra or {}
    zone.name, zone.levels, zone.ids = name, levels, ids or {}
    ZONES[name] = zone
end

-- Kalimdor
Zone("Durotar", "1-10", { 1 })
Zone("Mulgore", "1-10", { 7 })
Zone("Teldrassil", "1-10", { 57 })
Zone("Zephras Isle", "new", nil, { new = true })
Zone("Darkshore", "10-20", { 62 })
Zone("The Barrens", "10-25", { 10 }, { alt = { "Northern Barrens" } })
Zone("Stonetalon Mountains", "15-27", { 65 })
Zone("Ashenvale", "18-30", { 63 })
Zone("Thousand Needles", "25-35", { 64 })
Zone("Desolace", "30-40", { 66 })
Zone("Dustwallow Marsh", "35-45", { 70 })
Zone("Feralas", "40-50", { 69 })
Zone("Tanaris", "40-50", { 71 })
Zone("Azshara", "45-55", { 76 })
Zone("Felwood", "48-55", { 77 })
Zone("Un'Goro Crater", "48-55", { 78 })
Zone("Winterspring", "55-60", { 83 })
Zone("Silithus", "55-60", { 81 })
Zone("Mount Hyjal", "60", { 198 })
Zone("Riverglades", "new", nil, { new = true })
Zone("Ahn'Qiraj", "raid", nil, { inside = "Silithus" })

-- Eastern Kingdoms
Zone("Elwynn Forest", "1-10", { 37 })
Zone("Dun Morogh", "1-10", { 27 })
Zone("Tirisfal Glades", "1-10", { 18 })
Zone("Westfall", "10-20", { 52 })
Zone("Loch Modan", "10-20", { 48 })
Zone("Silverpine Forest", "10-20", { 21 })
Zone("Redridge Mountains", "15-25", { 49 })
Zone("Duskwood", "18-30", { 47 })
Zone("Wetlands", "20-30", { 56 })
Zone("Hillsbrad Foothills", "20-30", { 25 })
Zone("Alterac Mountains", "30-40", nil, { alt = { "Hillsbrad Foothills" } })
Zone("Arathi Highlands", "30-40", { 14 })
Zone("Stranglethorn Vale", "30-45", { 224, 50 }, { alt = { "Northern Stranglethorn" } })
Zone("Badlands", "35-45", { 15 })
Zone("Swamp of Sorrows", "35-45", { 51 })
Zone("The Hinterlands", "40-50", { 26 })
Zone("Searing Gorge", "43-50", { 32 })
Zone("Blasted Lands", "45-55", { 17 })
Zone("Burning Steppes", "50-58", { 36 })
Zone("Western Plaguelands", "51-58", { 22 })
Zone("Eastern Plaguelands", "53-60", { 23 })
Zone("Uldaman", "dungeon", nil, { inside = "Badlands" })
Zone("Blackrock Depths", "dungeon", nil, { inside = "Burning Steppes" })
Zone("Blackrock Spire", "dungeon", nil, { inside = "Burning Steppes" })
Zone("Zul'Gurub", "raid", nil, { inside = "Stranglethorn Vale" })

---------------------------------------------------------------------------
-- Ores, in order of required skill.
--   minor      quest ore with only a few nodes
--   rare       spawns in place of a common vein; never the "best" pick
--   always     shown even when the "Useful for me" filter is on
---------------------------------------------------------------------------

local ORES = {}
ns.ORES = ORES

local function Ore(ore)
    ore.yellow = ore.yellow or ore.req + 25
    ore.green = ore.green or ore.req + 50
    ore.gray = ore.gray or ore.req + 100
    local zones = {}
    for _, spec in ipairs(ore.zones) do
        local name, flags = spec:match("^([^|]+)|?(%a*)$")
        zones[#zones + 1] = {
            name = name,
            dense = flags:find("d", 1, true) ~= nil,
            forever = flags:find("f", 1, true) ~= nil,
        }
    end
    ore.zones = zones
    ORES[#ORES + 1] = ore
end

Ore {
    key = "copper", name = "Copper Vein", ore = "Copper Ore", item = 2770, req = 1,
    zones = { "Durotar|d", "Mulgore|f", "Elwynn Forest|f", "Dun Morogh|f", "Tirisfal Glades|f", "Teldrassil|f",
              "Zephras Isle|f", "Westfall|d", "Loch Modan", "Silverpine Forest", "Darkshore", "The Barrens|f",
              "Redridge Mountains|f", "Duskwood", "Stonetalon Mountains" },
    notes = "Forever adds Poor Copper Veins to every starting zone, and Chunks of Amber in Teldrassil "
         .. "(small ones only give skill up to 20).",
}

Ore {
    key = "tin", name = "Tin Vein", ore = "Tin Ore", item = 2771, req = 65,
    zones = { "Wetlands|d", "Loch Modan", "Redridge Mountains|f", "Silverpine Forest", "Duskwood",
              "Hillsbrad Foothills|f", "Ashenvale|f", "The Barrens|f", "Stonetalon Mountains", "Riverglades|f" },
    notes = "Can also drop Pyrite in Forever.",
}

Ore {
    key = "incendicite", name = "Incendicite Mineral Vein", ore = "Incendicite Ore", item = 3340, req = 65,
    minor = true,
    zones = { "Wetlands" },
    notes = "Quest ore with only a handful of veins.",
}

Ore {
    key = "silver", name = "Silver Vein", ore = "Silver Ore", item = 2775, req = 75, rare = true,
    zones = { "Arathi Highlands|d", "Wetlands|f", "Alterac Mountains", "Stranglethorn Vale",
              "Hillsbrad Foothills|f", "Thousand Needles|f", "The Barrens|f", "Loch Modan", "Duskwood",
              "Silverpine Forest|f", "Westfall|f" },
    notes = "Rare: spawns in place of Tin and Iron. Ooze Covered Silver Veins in Thousand Needles.",
}

Ore {
    key = "bloodstone", name = "Lesser Bloodstone Deposit", ore = "Lesser Bloodstone Ore", item = 4278, req = 75,
    minor = true,
    zones = { "Arathi Highlands" },
    notes = "Quest ore with only a handful of deposits.",
}

Ore {
    key = "iron", name = "Iron Deposit", ore = "Iron Ore", item = 2772, req = 125,
    zones = { "Arathi Highlands|df", "Alterac Mountains", "Stranglethorn Vale|f", "Thousand Needles|f",
              "Desolace|f", "Duskwood", "Badlands", "Dustwallow Marsh", "Feralas", "Swamp of Sorrows",
              "Riverglades|f" },
    notes = "Can drop Pyrite or Bauxite in Forever (guides disagree on which).",
}

Ore {
    key = "indurium", name = "Indurium Mineral Vein", ore = "Indurium Ore", item = 5833, req = 150,
    minor = true,
    zones = { "Uldaman" },
    notes = "Quest ore, found only inside the Uldaman dungeon.",
}

Ore {
    key = "gold", name = "Gold Vein", ore = "Gold Ore", item = 2776, req = 155, rare = true,
    zones = { "Arathi Highlands|df", "Stranglethorn Vale|f", "Badlands|f", "Alterac Mountains",
              "The Hinterlands", "Blasted Lands|f", "Felwood|f", "Desolace", "Dustwallow Marsh", "Tanaris",
              "Feralas" },
    notes = "Rare: spawns in place of Iron and Mithril. Ooze Covered Gold Veins in Feralas and Thousand Needles.",
}

Ore {
    key = "mithril", name = "Mithril Deposit", ore = "Mithril Ore", item = 3858, req = 175,
    zones = { "The Hinterlands|df", "Alterac Mountains", "Badlands|f", "Searing Gorge|f", "Tanaris|f",
              "Stranglethorn Vale", "Azshara|f", "Blasted Lands|f", "Felwood|f", "Desolace|f", "Feralas",
              "Burning Steppes" },
    notes = "Can drop Bauxite in Forever. Ooze Covered Mithril in Feralas and Thousand Needles.",
}

Ore {
    key = "truesilver", name = "Truesilver Deposit", ore = "Truesilver Ore", item = 7911, req = 230, rare = true,
    zones = { "The Hinterlands|df", "Burning Steppes|f", "Badlands", "Searing Gorge", "Eastern Plaguelands",
              "Winterspring|f", "Blasted Lands|f", "Felwood|f", "Tanaris", "Un'Goro Crater" },
    notes = "Rare: spawns in place of Mithril and Thorium. Ooze Covered Truesilver in Silithus, Un'Goro and Feralas.",
}

Ore {
    key = "darkiron", name = "Dark Iron Deposit", ore = "Dark Iron Ore", item = 11370, req = 230, rare = true,
    zones = { "Burning Steppes", "Searing Gorge", "Blackrock Depths|d", "Blackrock Spire|f" },
    notes = "Smelt it at the Black Forge inside Blackrock Depths.",
}

Ore {
    key = "thorium", name = "Small Thorium Vein", ore = "Thorium Ore", item = 10620, req = 245,
    zones = { "Silithus|df", "Un'Goro Crater|f", "Burning Steppes|f", "Tanaris", "Western Plaguelands|f",
              "Eastern Plaguelands|f", "Felwood|f", "Winterspring|f", "Blasted Lands|f", "Azshara", "Feralas",
              "The Hinterlands" },
    notes = "Ooze Covered Thorium in Un'Goro and Feralas.",
}

Ore {
    key = "richthorium", name = "Rich Thorium Vein", ore = "Thorium Ore", item = 10620, req = 275,
    zones = { "Eastern Plaguelands|df", "Winterspring|f", "Azshara|f", "Burning Steppes", "Silithus",
              "Un'Goro Crater", "Western Plaguelands|f", "Zul'Gurub" },
    notes = "Ooze Covered Rich Thorium in Silithus, Hakkari Thorium in Zul'Gurub. "
         .. "Guides report few spawns around 295.",
}

Ore {
    key = "heavythorium", name = "Heavy Thorium Vein", ore = "Heavy Thorium Ore", item = 248815, req = 300,
    yellow = 300, green = 300, gray = 300, always = true,
    zones = { "Mount Hyjal|f" },
    notes = "New in Forever and rare. Smelts only at a Molten Foundry (mining camp, skill 300). "
         .. "Some guides haven't found it yet.",
}

Ore {
    key = "obsidian", name = "Obsidian Chunk", ore = "Small and Large Obsidian Shards", item = 22202, req = 305,
    always = true,
    zones = { "Ahn'Qiraj" },
    notes = "Inside the Ahn'Qiraj raids. Needs 305, so you need +Mining gear such as the Goblin Mining Helmet.",
}

-- The ore to go mine now: the highest common vein that's orange, else
-- yellow, else green. Returns ore, color (or nil).
function ns.BestOre(skill, effective)
    if not skill then return nil end
    for _, want in ipairs({ "orange", "yellow", "green" }) do
        local best
        for _, ore in ipairs(ORES) do
            if not (ore.minor or ore.rare or ore.always) and ns.ColorFor(ore, skill, effective) == want then
                best = ore
            end
        end
        if best then return best, want end
    end
end

-- "Arathi Highlands, Alterac Mountains, Stranglethorn Vale"
function ns.TopZones(ore, count)
    local names = {}
    for i = 1, math.min(count, #ore.zones) do names[i] = ore.zones[i].name end
    return table.concat(names, ", ")
end
