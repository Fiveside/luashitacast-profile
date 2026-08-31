-- Equips items that allows you to regen while not in combat, up to 95% max hp.
local Conquest = gFunc.LoadFile("lib/conquest");
local bit = require("bit");
local Utils = gFunc.LoadFile("util")
local XI = gFunc.LoadFile("xi");



local function includeBangles()
    -- Regen on garden bangles only works during the daytime.
    local gameTime = gData.GetEnvironment().Time;
    return gameTime > 8.0 and gameTime < 18.0;
end

local function includeHairpin()
    -- Hairpin should be enabled if we are in a zone considered
    -- "outside own nation's control".

    -- Note that XI considers "not inside control" and "outside control" to be
    -- two different conditions. Unsure if LSB emulates this detail.
    -- This may need to be updated when playing in ToAU zones.
    local isValidZone = not Conquest.GetInsideControl();

    -- The auto-regen on the hairpin only procs if we have signet.
    local hasSignet = XI.getMyBuffsByName()["Signet"] ~= nil;

    return isValidZone and hasSignet;
end

local ITEM_SETS = T {
    [T { Head = "President. Hairpin" }] = includeHairpin,
    [T { Hands = "Garden Bangles" }] = includeBangles,
};


local EquipConditional = T {};

---Creates a new special equipment manager.
---@param defaultSets any
---@return unknown
function EquipConditional:new(defaultSets)
    defaultSets = defaultSets or T {};
    local obj = T {
        activeSets = T {},
        defaultSets = defaultSets,
    };
    setmetatable(obj, { __index = self });
    obj:refresh();
    return obj;
end

function EquipConditional:refresh()
    -- Get the default list of sets, prune sets that we can't equip
    self.activeSets = T {};
    local me = gData.GetPlayer();
    local myJob = me.MainJob;
    local myLevel = me.MainJobSync;

    for set, condition in pairs(self.defaultSets) do
        local items = set:values():map(function(name) return XI.getEquipmentDetails(name) end);
        local includeSet = items:map(function(item)
            return item.jobs:contains(myJob) and item.level <= myLevel and item.isReady
        end):all();
        if includeSet then
            self.activeSets[set] = condition;
        end
    end
end

function EquipConditional:getSet()
    local res = T {};
    for set, condition in pairs(self.activeSets) do
        if condition() then
            res:merge(set, true)
        end
    end
    return res;
end

local IdleRegen = T {}
setmetatable(IdleRegen, { __index = EquipConditional });

function IdleRegen:new(customSet)
    -- Merge in global regen stuff
    customSet = customSet or T {};
    local sets = Utils.compress_tables(ITEM_SETS, { [customSet] = function() return true; end });

    local obj = EquipConditional:new(sets);
    obj.lastTickEnabled = false;
    setmetatable(obj, { __index = self });
    return obj;
end

local function shouldEnable(lastTickEnabled)
    -- Enable the regen set if
    -- - We are not in combat
    -- - We are not casting
    -- - Either:
    -- - - We have less than 95% hp
    -- - - And:
    -- - - - We have less than 100% hp
    -- - - - Last tick, we enabled the regen set
    local player = gData.GetPlayer();
    if not (player.Status == "Idle" or player.Status == "Resting") then
        return false;
    end
    -- todo: how to detect when casting?

    if player.HPP < 95 then
        return true;
    end
    if player.HPP < 100 and lastTickEnabled then
        return true;
    end
    return false;
end

function IdleRegen:getSet()
    -- Only build the set list if we're idle.
    if shouldEnable(self.lastTickEnabled) then
        self.lastTickEnabled = true;
        return EquipConditional.getSet(self);
    else
        self.lastTickEnabled = false;
        return T {};
    end
end

local Export = {};

Export.EquipConditional = EquipConditional;
Export.IdleRegen = IdleRegen;

return Export;
