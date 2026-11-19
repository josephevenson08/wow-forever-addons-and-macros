-- Wyvern Wits: the prompt bank.
--
-- Each prompt lists answers in five tiers, most obvious first:
--   1 Peon, 2 Grunt, 3 Blademaster, 4 Far Seer, 5 Warchief
-- An answer is a name, or { "Display name", "alias", "alias" }. Matching
-- ignores case, punctuation, spaces, and a leading "the", so "Un'Goro" and
-- "ungoro" are the same. Short aliases (under 5 letters) must match exactly.
--
-- Grades are by feel: how likely is a typical player to say it?

local _, ns = ...

local Prompts = {}
ns.Prompts = Prompts

local list = {}
Prompts.list = list

local function P(id, text, tiers)
    list[#list + 1] = { id = id, text = text, tiers = tiers }
end

P("zones_kalimdor", "Name a zone in Kalimdor", {
    { "Durotar", "The Barrens", "Ashenvale", "Mulgore" },
    { "Tanaris", "Teldrassil", "Darkshore", { "Stonetalon Mountains", "Stonetalon" }, "Thousand Needles",
      { "Dustwallow Marsh", "Dustwallow" }, "Feralas", "Orgrimmar", "Thunder Bluff", "Darnassus" },
    { "Desolace", { "Un'Goro Crater", "Un'Goro" }, "Felwood", "Winterspring", "Azshara", "Silithus" },
    { "Moonglade", { "Mount Hyjal", "Hyjal" } },
    { { "GM Island", "Designer Island" } },
})

P("zones_ek", "Name a zone in the Eastern Kingdoms", {
    { { "Elwynn Forest", "Elwynn" }, "Westfall", { "Stranglethorn Vale", "Stranglethorn", "STV" }, "Duskwood",
      { "Tirisfal Glades", "Tirisfal" } },
    { "Dun Morogh", { "Redridge Mountains", "Redridge" }, "Loch Modan", { "Silverpine Forest", "Silverpine" },
      { "Hillsbrad Foothills", "Hillsbrad" }, "Wetlands", { "Arathi Highlands", "Arathi" }, "Stormwind", "Ironforge",
      "Undercity", "Burning Steppes", "Badlands", { "Eastern Plaguelands", "EPL" }, { "Western Plaguelands", "WPL" } },
    { { "Alterac Mountains", "Alterac" }, "The Hinterlands", "Searing Gorge", "Swamp of Sorrows", "Blasted Lands",
      { "Deadwind Pass", "Deadwind" } },
    { "Gilneas", "Quel'Thalas", "Grim Batol" },
    { "Programmer Isle" },
})

P("dungeons", "Name a classic dungeon", {
    { { "The Deadmines", "Deadmines", "VC" }, { "Wailing Caverns", "WC" }, { "Ragefire Chasm", "RFC" },
      { "Scarlet Monastery", "SM" } },
    { { "Shadowfang Keep", "SFK" }, { "The Stockade", "Stockades", "Stocks" }, { "Blackfathom Deeps", "BFD" },
      { "Gnomeregan", "Gnomer" }, { "Stratholme", "Strat" }, { "Scholomance", "Scholo" },
      { "Blackrock Depths", "BRD" }, { "Zul'Farrak", "ZF" }, { "Uldaman", "Ulda" } },
    { { "Razorfen Kraul", "RFK" }, { "Razorfen Downs", "RFD" }, { "Maraudon", "Mara" }, "Dire Maul",
      { "Blackrock Spire", "LBRS", "UBRS", "Lower Blackrock Spire", "Upper Blackrock Spire" },
      { "Sunken Temple", "Temple of Atal'Hakkar", "ST" } },
    {},
    {},
})

P("bosses_mc", "Name a boss in Molten Core", {
    { "Ragnaros" },
    { { "Majordomo Executus", "Majordomo", "Domo" }, "Magmadar", { "Baron Geddon", "Geddon" }, "Lucifron" },
    { "Garr", { "Golemagg the Incinerator", "Golemagg" }, "Shazzrah", "Gehennas" },
    { { "Sulfuron Harbinger", "Sulfuron" } },
    {},
})

P("bosses_bwl", "Name a boss in Blackwing Lair", {
    { "Nefarian" },
    { { "Razorgore the Untamed", "Razorgore" }, { "Vaelastrasz the Corrupt", "Vaelastrasz", "Vael" }, "Chromaggus" },
    { { "Broodlord Lashlayer", "Broodlord" }, "Firemaw", "Ebonroc", "Flamegor" },
    { { "Lord Victor Nefarius", "Victor Nefarius" } },
    {},
})

P("bosses_zg", "Name a boss in Zul'Gurub", {
    { { "Hakkar the Soulflayer", "Hakkar" } },
    { { "Bloodlord Mandokir", "Mandokir" }, { "Jin'do the Hexxer", "Jin'do" }, { "High Priest Thekal", "Thekal" } },
    { { "High Priest Venoxis", "Venoxis" }, { "High Priestess Jeklik", "Jeklik" },
      { "High Priestess Mar'li", "Mar'li" }, { "High Priestess Arlokk", "Arlokk" } },
    { "Gahz'ranka" },
    { "Gri'lek", "Hazza'rah", "Renataki", "Wushoolay" },
})

P("herbs", "Name an herb you can gather", {
    { "Peacebloom", "Silverleaf" },
    { "Earthroot", "Mageroyal", "Briarthorn", "Black Lotus", "Kingsblood", "Stranglekelp", "Swiftthistle" },
    { "Bruiseweed", "Wild Steelbloom", "Liferoot", "Fadeleaf", "Goldthorn", "Grave Moss", "Khadgar's Whisker",
      "Firebloom" },
    { "Wintersbite", "Purple Lotus", "Arthas' Tears", "Sungrass", "Blindweed", "Ghost Mushroom", "Gromsblood",
      "Golden Sansam", "Dreamfoil", "Mountain Silversage", "Plaguebloom", "Icecap" },
    {},
})

P("ores", "Name an ore you can mine", {
    { "Copper", "Iron", "Gold" },
    { "Tin", "Silver", "Mithril", "Thorium" },
    { "Truesilver", "Dark Iron" },
    { "Incendicite", "Indurium", "Lesser Bloodstone" },
    { "Elementium" },
})

P("professions", "Name a profession", {
    { "Mining", "Herbalism", "Alchemy", "Blacksmithing" },
    { "Tailoring", "Enchanting", "Engineering", "Leatherworking", "Skinning", "Cooking", "Fishing" },
    { "First Aid" },
    { "Jewelcrafting", "Inscription", "Archaeology" },
    { "Lockpicking", "Poisons", "Riding" },
})

P("classes", "Name a class", {
    { "Warrior", "Mage", "Hunter" },
    { "Rogue", "Priest", "Paladin", "Warlock", "Druid", "Shaman" },
    { { "Death Knight", "DK" }, "Monk", { "Demon Hunter", "DH" } },
    { "Evoker" },
    {},
})

P("races", "Name a playable race", {
    { "Orc", "Human" },
    { { "Undead", "Forsaken" }, "Tauren", "Troll", { "Night Elf", "Night Elves" }, "Dwarf", "Gnome" },
    { { "Blood Elf", "Blood Elves" }, "Draenei", "Goblin", "Worgen", "Pandaren" },
    { "Nightborne", { "Highmountain Tauren", "Highmountain" }, { "Void Elf", "Void Elves" },
      { "Lightforged Draenei", "Lightforged" }, { "Zandalari Troll", "Zandalari" }, "Kul Tiran",
      { "Dark Iron Dwarf", "Dark Iron" }, { "Mag'har Orc", "Mag'har" }, "Mechagnome", "Vulpera", "Dracthyr",
      "Earthen" },
    { "Skyborne" },
})

P("pets", "Name a beast family a hunter can tame", {
    { "Wolf", "Cat", "Bear", "Boar" },
    { "Raptor", "Gorilla", "Spider", "Crab", { "Crocolisk", "Croc" }, "Owl", "Bat", "Scorpid", "Turtle" },
    { "Wind Serpent", "Hyena", "Tallstrider", "Carrion Bird" },
    {},
    {},
})

P("orcs", "Name an orc from Warcraft lore", {
    { "Thrall", { "Grom Hellscream", "Grom", "Grommash" }, { "Garrosh Hellscream", "Garrosh" } },
    { { "Orgrim Doomhammer", "Orgrim", "Doomhammer" }, "Durotan", "Gul'dan", { "Varok Saurfang", "Saurfang" },
      "Ner'zhul", "Blackhand" },
    { { "Kilrogg Deadeye", "Kilrogg" }, "Drek'Thar", "Nazgrel", "Eitrigg", "Draka",
      { "Kargath Bladefist", "Kargath" }, { "Rend Blackhand", "Rend" }, "Mankrik" },
    { { "Nekros Skullcrusher", "Nekros" }, { "Maim Blackhand", "Maim" }, { "Teron Gorefiend", "Gorefiend" },
      "Nazgrim", { "Broxigar", "Brox" } },
    { { "Zuluhed the Whacked", "Zuluhed" }, "Geyah", "Garad", { "Rehgar Earthfury", "Rehgar" } },
})

P("clans", "Name an orc clan", {
    { "Frostwolf", "Warsong", "Blackrock" },
    { "Bleeding Hollow", "Dragonmaw", "Shattered Hand", "Burning Blade", "Thunderlord", "Shadowmoon" },
    { "Bonechewer", "Laughing Skull", "Black Tooth Grin", "Twilight's Hammer", "Stormreaver" },
    { "Lightning's Blade" },
    { "Whiteclaw", "Bladewind" },
})

P("trolls", "Name a troll tribe", {
    { "Darkspear" },
    { "Gurubashi", "Amani", "Zandalari", "Drakkari" },
    { "Sandfury", "Witherbark", "Vilebranch", "Revantusk", "Skullsplitter", "Bloodscalp" },
    { "Shadowpine", "Frostmane", "Smolderthorn", "Mossflayer", "Shatterspear" },
    { "Farraki", "Atal'ai" },
})

P("dragons", "Name a dragon from Warcraft lore", {
    { { "Deathwing", "Neltharion" }, "Onyxia", "Alexstrasza" },
    { "Nefarian", "Ysera", "Malygos", "Nozdormu", "Kalecgos", "Sindragosa" },
    { "Chromie", "Wrathion", { "Korialstrasz", "Krasus" }, "Vaelastrasz", "Azuregos", "Emeriss", "Lethon",
      "Taerar", "Ysondre", "Sabellian" },
    { "Ebonroc", "Firemaw", "Flamegor", "Chromaggus", "Galakrond", "Tyrygosa", "Arygos", "Sartharion" },
    { "Itharius", "Haleh" },
})

P("factions", "Name a faction you can earn reputation with", {
    { "Orgrimmar", "Stormwind", "Argent Dawn" },
    { "Thunder Bluff", "Undercity", { "Darkspear Trolls", "Darkspear" }, "Ironforge", "Darnassus",
      "Gnomeregan Exiles", { "Timbermaw Hold", "Timbermaw" }, "Cenarion Circle", "Thorium Brotherhood",
      "Zandalar Tribe", "Frostwolf Clan", "Stormpike Guard" },
    { "Hydraxian Waterlords", "Brood of Nozdormu", "Booty Bay", "Gadgetzan", "Ratchet", "Everlook",
      "Warsong Outriders", "Silverwing Sentinels", "The Defilers", "League of Arathor", "Darkmoon Faire",
      "Bloodsail Buccaneers" },
    { "Wintersaber Trainers", "Ravenholdt", "Steamwheedle Cartel", "Gelkis Clan Centaur",
      "Magram Clan Centaur" },
    { "Syndicate", "Shen'dralar" },
})

P("flightpoints", "Name a flight point in Kalimdor", {
    { "Orgrimmar", "The Crossroads", "Thunder Bluff", "Ratchet" },
    { "Gadgetzan", "Camp Taurajo", "Splintertree Post", "Sun Rock Retreat", "Astranaar", "Auberdine",
      "Theramore", { "Rut'theran Village", "Rut'theran" }, "Everlook", "Freewind Post" },
    { "Brackenwall Village", "Camp Mojache", "Shadowprey Village", "Bloodvenom Post", "Valormok",
      "Cenarion Hold", "Feathermoon Stronghold", "Nijel's Point", "Stonetalon Peak", "Talonbranch Glade",
      { "Nighthaven", "Moonglade" } },
    { "Marshal's Refuge", { "Zoram'gar Outpost", "Zoram'gar" }, "Thalanaar", "Talrendis Point" },
    {},
})

P("weapons", "Name a famous weapon from Warcraft lore", {
    { "Frostmourne", "Ashbringer", "Doomhammer", "Thunderfury" },
    { "Sulfuras", "Gorehowl", "Atiesh", "Shadowmourne", { "Warglaives of Azzinoth", "Warglaives" } },
    { "Quel'Delar", "Quel'Serrar", "Val'anyr", "Thori'dal", "Dragonwrath", "Benediction", "Anathema" },
    { "Felo'melorn", "Rhok'delar", "Lok'delar", { "Demon Soul", "Dragon Soul" }, "Scepter of Sargeras",
      "Fangs of Ashamane" },
    { "Xal'atath" },
})

P("warchiefs", "Name a Warchief of the Horde", {
    { "Thrall" },
    { { "Garrosh Hellscream", "Garrosh" }, { "Sylvanas Windrunner", "Sylvanas" }, "Vol'jin" },
    { { "Orgrim Doomhammer", "Orgrim", "Doomhammer" } },
    { "Blackhand" },
    {},
})

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- Pick n prompts, preferring ones not seen in recent games.
function Prompts:Pick(n)
    local recent = ns.db.recent
    local isRecent = {}
    for _, id in ipairs(recent) do isRecent[id] = true end

    local fresh, stale = {}, {}
    for _, prompt in ipairs(list) do
        if isRecent[prompt.id] then stale[#stale + 1] = prompt else fresh[#fresh + 1] = prompt end
    end
    Shuffle(fresh)
    Shuffle(stale)

    local picked = {}
    for _, pool in ipairs({ fresh, stale }) do
        for _, prompt in ipairs(pool) do
            if #picked >= n then break end
            picked[#picked + 1] = prompt
        end
    end

    for _, prompt in ipairs(picked) do recent[#recent + 1] = prompt.id end
    while #recent > 12 do table.remove(recent, 1) end
    return picked
end
