-- Ore Atlas: read and track the player's Mining skill.
--
-- GetNumSkillLines is gone on Forever, so we use GetProfessions +
-- GetProfessionInfo. No event fires for a single skill point, so we re-read
-- on CHAT_MSG_SKILL ("Your skill in Mining has increased to ...") and on
-- SKILL_LINES_CHANGED (learning, unlearning, new rank).

local _, ns = ...

local Skill = { known = false, rank = 0, max = 0, modifier = 0 }
ns.Skill = Skill

local MINING_LINE = 186        -- TradeSkillLineID for Mining
local MINING_ICON = 136248     -- Interface\Icons\Trade_Mining

local function IsMining(name, icon, skillLine)
    if skillLine == MINING_LINE or icon == MINING_ICON then return true end
    if skillLine and C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLine)
        if ok and info then
            if info.professionID == MINING_LINE or info.parentProfessionID == MINING_LINE then return true end
            if Enum.Profession and info.profession == Enum.Profession.Mining then return true end
        end
    end
    return type(name) == "string" and name:find("Mining", 1, true) ~= nil
end

-- Returns name, icon, rank, maxRank, skillLine, modifier for Mining, or nil.
function Skill:Find()
    if not (GetProfessions and GetProfessionInfo) then return nil end
    local prof1, prof2 = GetProfessions()
    for _, index in pairs({ prof1, prof2 }) do
        local name, icon, rank, maxRank, _, _, skillLine, modifier = GetProfessionInfo(index)
        if IsMining(name, icon, skillLine) then
            return name, icon, rank, maxRank, skillLine, modifier
        end
    end
end

function Skill:Effective()
    return self.rank + (self.modifier or 0)
end

-- Re-read the skill and tell the rest of the addon if anything changed.
function Skill:Read()
    local _, _, rank, maxRank, _, modifier = self:Find()
    local known = rank ~= nil
    rank, maxRank, modifier = rank or 0, maxRank or 0, modifier or 0

    local before = { known = self.known, rank = self.rank, max = self.max }
    if known == self.known and rank == self.rank and maxRank == self.max and modifier == self.modifier then
        return
    end
    self.known, self.rank, self.max, self.modifier = known, rank, maxRank, modifier
    if known and not self.sessionStart then self.sessionStart = rank end

    self:SaveCharacter()
    ns.OnSkillChanged(before, self)
end

function Skill:SessionGain()
    if not (self.known and self.sessionStart) then return 0 end
    return self.rank - self.sessionStart
end

-- Remember every character's Mining so the pane can show alts.
function Skill:SaveCharacter()
    local name, realm = UnitName("player"), GetRealmName()
    if not name or (issecretvalue and issecretvalue(name)) then return end
    local key = name .. "-" .. (realm or "")
    local _, classFile = UnitClass("player")
    ns.db.chars[key] = {
        name = name,
        class = classFile,
        known = self.known,
        rank = self.rank,
        max = self.max,
        updated = time(),
    }
    self.charKey = key
end

-- Other characters with Mining, highest first: { {name, rank, class}, ... }
function Skill:Alts()
    local list = {}
    for key, char in pairs(ns.db.chars) do
        if key ~= self.charKey and char.known then list[#list + 1] = char end
    end
    table.sort(list, function(a, b) return a.rank > b.rank end)
    return list
end
