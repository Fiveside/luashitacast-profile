-- Equips items that allows you to regen while not in combat, up to 95% max hp.
local Conquest = gFunc.LoadFile("lib/conquest");
local Enums = gFunc.LoadFile("enums");
local bit = require('bit');
local Utils = gFunc.LoadFile("util")



local function includeBangles()
    -- Returns tue if circumstances allow the
    -- Garden Bangles to trigger regen
    local gameTime = gData.GetEnvironment().Time;
    return gameTime > 8.0 and gameTime < 18.0;
end

local function includeHairpin()
    -- Hairpin should be enabled if we are NOT
    -- in a zone controlled by our city state.
    return not Conquest.GetInsideControl()
end


local ITEM_SETS = T{
    ["President. Hairpin"] = T{
        set = T{ Head = "President. Hairpin" },
        condition = includeHairpin,
    },
    -- Not yet acquired.
    -- ["Garden Bangles"] = T{ 
    --     set = T{ Hands = GARDEN_BANGLES },
    --     condition = includeBangles
    -- },
};

local ITEM_INFO = T{};

-- Set up item information
do
    local mem = AshitaCore:GetMemoryManager();
    local res = AshitaCore:GetResourceManager();

    for itemName, _ in pairs(ITEM_SETS) do
        local item = res:GetItemByName(itemName, Enums.LanguageId.English);
        local jobs = T{};
        for job, mask in pairs(Enums.JobMask) do
            if bit.band(item.Jobs, mask) > 0 then
                jobs:append(job);
            end
        end
        ITEM_INFO[itemName] = T{ jobs = jobs, level = item.Level };
    end
end

local function buildGearSet()
    local player = gData.GetPlayer();

    local sets = {}
    for itemName, item in pairs(ITEM_SETS) do
        local itemInfo = ITEM_INFO[itemName];
        if item.condition() and itemInfo.jobs:contains(player.MainJob) and itemInfo.level <= player.MainJobSync then
            sets[#sets + 1] = item.set
        end
    end
    return Utils.compress_tables(table.unpack(sets));
end


local Export = {};
local state = {
    lastTickEnabled = false,
};

local function shouldEnable()
    -- Enable the regen set if
    -- - We are not in combat
    -- - We are not casting
    -- - Either:
    -- - - We have less than 95% hp
    -- - - And:
    -- - - - We have less than 100% hp
    -- - - - Last tick, we enabled the regen set
    local player = gData.GetPlayer();
    if not (player.Status == "Idle" or player.Status == 'Resting') then
        return false;
    end
    -- todo: how to detect when casting?

    if player.HPP < 95 then
        return true;
    end
    if player.HPP < 100 and state.lastTickEnabled then
        return true;
    end
    return false;
end

function Export.getSet()
    local enabled = shouldEnable();
    state.lastTickEnabled = enabled;
    if not enabled then
        return {};
    end
    return buildGearSet();
end

return Export;