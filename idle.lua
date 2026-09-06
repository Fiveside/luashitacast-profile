-- Equips items that allows you to regen while not in combat, up to 95% max hp.
local Conquest = require("lib/conquest");
local bit = require("bit");
local XI = require("xi");
local Events = require("events");

---@class AutoGearItemPartialDefinition: AutoGearItemDefinition
---@field name string
---@field condition (fun(): boolean)?
---@field displaces GearSlot[]?

---@class AutoGearItemDefinition
---@field condition fun(): boolean
---@field displaces GearSlot[]
---@field resource IItem
---@field jobs string[]
---@field slots string[]

---@type AutoGearItemPartialDefinition[]
local AUTO_REGEN_ITEMS = T {
    {
        name = "President. Hairpin",
        condition = function()
            -- Hairpin should be enabled if we are in a zone considered
            -- "outside own nation's control".

            -- Note that XI considers "not inside control" and "outside control" to be
            -- two different conditions. Unsure if LSB emulates this detail.
            -- This may need to be updated when playing in ToAU zones.
            local isValidZone = not Conquest.GetInsideControl();

            -- The auto-regen on the hairpin only procs if we have signet.
            local hasSignet = gData.GetBuffCount("Signet") ~= nil;

            return isValidZone and hasSignet;
        end,
    },
    {
        name = "Garden Bangles",
        condition = function()
            -- Regen on garden bangles only works during the daytime.
            local gameTime = gData.GetEnvironment().Time;
            return gameTime > 8.0 and gameTime < 18.0;
        end,
    },
};

---@type AutoGearItemPartialDefinition[]
local AUTO_REFRESH_ITEMS = T {
    {
        name = "Vermillion Cloak",
        displaces = T { "Head" },
    }
};

---@type AutoGearItemPartialDefinition[]
local AUTO_REGAIN_ITEMS = T {
    {
        name = "Opo-opo Necklace",
        condition = function()
            -- Only triggers regain when we're asleep
            return gData.GetBuffCount("slee") > 0;
        end,
    }
};

do
    -- Enrich item definitions
    local resources = AshitaCore:GetResourceManager();
    for _, collection in ipairs({ AUTO_REGEN_ITEMS, AUTO_REFRESH_ITEMS, AUTO_REGAIN_ITEMS }) do
        for _, autoDef in ipairs(collection) do
            local item = resources:GetItemByName(autoDef.name, XI.LanguageId.English);
            if item == nil then
                error("Incorrect item name: " .. autoDef.name);
            end
            local jobs = T(XI.JobMask):filter(function(mask) return bit.band(mask, item.Jobs) > 0; end);
            local slots = T(XI.EquipmentSlotMask):filter(function(mask) return bit.band(mask, item.Slots) > 0; end);

            autoDef.jobs = jobs:keys();
            autoDef.slots = slots:keys();
            autoDef.resource = item;
            autoDef.displaces = autoDef.displaces or T {};
            autoDef.condition = autoDef.condition or function() return true; end;
        end
    end
end


---@cast AUTO_REGEN_ITEMS AutoGearItemDefinition
---@cast AUTO_REFRESH_ITEMS AutoGearItemDefinition
---@cast AUTO_REGAIN_ITEMS AutoGearItemDefinition

---@class EquipConditional
---@field activeSets AutoGearItemDefinition[]
---@field defaultSets AutoGearItemDefinition[]
local EquipConditional = T {};

---Creates a new special equipment manager.
---@param defaultSets AutoGearItemDefinition[]
---@param activationCondition fun(this: table): boolean
---@return EquipConditional
function EquipConditional.new(defaultSets, activationCondition)
    defaultSets = defaultSets or T {};
    local obj = T {
        activeSets = T {},
        defaultSets = T(defaultSets):values(),
        condition = activationCondition,
        conditionContext = {},
    };
    setmetatable(obj, { __index = EquipConditional });

    local player = gData.GetPlayer();
    obj:refresh(player.MainJob, player.MainJobLevel);
    return obj;
end

---Recalculates what the default gear should be.  Call this when your job or level changes.
---@param myJob string
---@param myLevel integer
function EquipConditional:refresh(myJob, myLevel)
    -- Get the default list of sets, prune sets that we can't equip
    self.activeSets = T {};
    local me = gData.GetPlayer();
    local myJob = me.MainJob;
    local myLevel = me.MainJobSync;

    local resources = AshitaCore:GetResourceManager();

    for _, autoDef in ipairs(self.defaultSets) do
        if autoDef.jobs:filter(function(job) return myJob ~= job; end):any() then
            if autoDef.level <= myLevel then
                table.insert(self.activeSets, autoDef);
            end
        end
    end
end

function EquipConditional:getSet(additionalSet)
    if not self.condition(self.conditionContext) then
        return T {};
    end

    -- The set combination logic here is backwards because
    -- we want to preserve "displaced" entries with their
    -- corresponding gear.
    additionalSet = additionalSet or T {};
    local finalSet = T(additionalSet):copy();
    local env = gData.GetEnvironment();
    for i = #self.activeSets, 1, -1 do
        local autoDef = self.activeSets[i];
        local canDisplace = autoDef.displaces:imap(function(slot) return finalSet[slot] == nil; end):all();
        if canDisplace then
            -- Find a free slot to fit this
            local emptySlot = autoDef.slots:ifilter(function(slot) return finalSet[slot] == nil; end):first();
            if emptySlot ~= nil then
                -- Found a free slot
                finalSet[emptySlot] = autoDef.name;
                for _, displacedSlot in ipairs(autoDef.displaces) do
                    finalSet[displacedSlot] = "displaced";
                end
            end
        end
    end
    return finalSet;
end

local autoRegen = EquipConditional.new(AUTO_REGEN_ITEMS, function(ctx)
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
        ctx.lastTickEnabled = true;
        return true;
    end
    if player.HPP < 100 and ctx.lastTickEnabled then
        return true;
    end
    ctx.lastTickEnabled = false;
    return false;
end);

local autoRefresh = EquipConditional.new(AUTO_REFRESH_ITEMS, function(ctx)
    -- Identical rules to the auto-regen set, just for mp now
    local player = gData.GetPlayer();
    if not (player.Status == "Idle" or player.Status == "Resting") then
        return false;
    end
    if gData.GetAction() ~= nil then
        return false;
    end

    if player.MPP < 95 then
        ctx.lastTickEnabled = true;
        return true;
    end
    if player.MPP < 100 and ctx.lastTickEnabled then
        return true;
    end
    ctx.lastTickEnabled = false;
    return false;
end);

local autoRegain = EquipConditional.new(AUTO_REGAIN_ITEMS, function(ctx)
    -- TODO: implement when we have concrete regain gear (opo-opo neck)
    return true;
end);

Events.mainJobChange:on(function(job, lvl)
    autoRegen:refresh(job, lvl);
    autoRefresh:refresh(job, lvl);
    autoRegain:refresh(job, lvl);
end);

return {
    EquipConditional = EquipConditional,
    autoRegen = autoRegen,
    autoRefresh = autoRefresh,
    autoRegain = autoRegain,
};
