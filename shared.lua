-- Equips items that allows you to regen while not in combat, up to 95% max hp.
local Conquest = require("lib/conquest");
local bit = require("bit");
local XI = require("xi");
local Events = require("events");

---@class AutoGearItemPartialDefinition
---@field name string
---@field condition (fun(): boolean)?
---@field displaces LAC.GearSlot[]?

---@class AutoGearItemDefinition: AutoGearItemPartialDefinition
---@field condition fun(): boolean
---@field displaces LAC.GearSlot[]
---@field resource IItem
---@field jobs string[]
---@field slots string[]

---Enriches autoEquipped gear to include fields required for use with EquipConditional.
---@param partialAutoDefs AutoGearItemPartialDefinition[]
---@return AutoGearItemDefinition[]
local function enrichItemPartialDefinition(partialAutoDefs)
    -- Enrich item definitions
    local resources = AshitaCore:GetResourceManager();

    ---@type AutoGearItemDefinition[]
    local autoDefs = T {};

    for _, partialDef in ipairs(partialAutoDefs) do
        local item = resources:GetItemByName(partialDef.name, XI.LanguageId.English);
        if item == nil then
            error("Incorrect item name: " .. partialDef.name);
        end
        local jobs = T(XI.JobMask):filter(function(mask) return bit.band(mask, item.Jobs) > 0; end);
        local slots = T(XI.EquipmentSlotMask):filter(function(mask) return bit.band(mask, item.Slots) > 0; end);

        table.insert(autoDefs, T {
            name = partialDef.name,
            jobs = jobs:keys(),
            slots = slots:keys(),
            resource = item,
            displaces = partialDef.displaces or T {},
            condition = partialDef.condition or function() return true; end,
        })
    end

    return autoDefs;
end


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
        defaultSets = enrichItemPartialDefinition(defaultSets):values(),
        condition = activationCondition or function() return true; end,
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

    for _, autoDef in ipairs(self.defaultSets) do
        if autoDef.jobs:contains(myJob) then
            if autoDef.resource.Level <= myLevel then
                table.insert(self.activeSets, autoDef);
            end
        end
    end
end

---Resets the context of the custom condition back to default.
function EquipConditional:reset()
    self.conditionContext = {};
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
        if autoDef.condition() then
            local canDisplace = autoDef.displaces:imap(function(slot) return finalSet[slot] == nil; end):all();
            if canDisplace then
                -- Find a free slot to fit this
                local emptySlot = autoDef.slots:filter(function(slot) return finalSet[slot] == nil; end):first();
                if emptySlot ~= nil then
                    -- Found a free slot
                    finalSet[emptySlot] = autoDef.name;
                    for _, displacedSlot in ipairs(autoDef.displaces) do
                        finalSet[displacedSlot] = "displaced";
                    end
                end
            end
        end
    end
    return finalSet;
end

----------------------------
-- Auto-Regen, Auto-Refresh, and Auto-Regain
----------------------------

local AUTO_REGEN_ITEMS = T {
    {
        name = "President. Hairpin",
        condition = function()
            -- Hairpin should be enabled if we are in a zone considered
            -- "outside own nation's control".

            -- Note that XI considers "not inside control" and "outside control" to be
            -- two different conditions.
            local isValidZone = not Conquest.GetInsideControl();

            -- The auto-regen on the hairpin only procs if we have signet.
            local hasSignet = gData.GetBuffCount("Signet") > 0;

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

local AUTO_REFRESH_ITEMS = T {
    {
        name = "Vermillion Cloak",
        displaces = T { "Head" },
    }
};

local autoRefresh = EquipConditional.new(AUTO_REFRESH_ITEMS, function(ctx)
    -- Identical rules to the auto-regen set, just for mp now.
    local player = gData.GetPlayer();

    -- If the player has zero mp, then MPP will also be zero
    if player.MaxMP == 0 then
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

local AUTO_REGAIN_ITEMS = T {
    {
        name = "Opo-opo Necklace",
        condition = function()
            -- Only recovers TP while we're asleep.
            return gData.GetBuffCount("sleep") > 0;
        end,
    }
};

local autoRegain = EquipConditional.new(AUTO_REGAIN_ITEMS, function(ctx)
    -- There's no reason not to recover TP until we hit 3k.  No gear flashing
    -- changes the math (unlike regen and refresh).
    return gData.GetPlayer().TP < 3000;
end);

Events.mainJobChange:on(function(job, lvl)
    autoRegen:refresh(job, lvl);
    autoRefresh:refresh(job, lvl);
    autoRegain:refresh(job, lvl);
end);

Events.zoneChange:on(function()
    autoRegen:reset();
    autoRefresh:reset();
    autoRegain:reset();
end);

local Export = {
    EquipConditional = EquipConditional,
    autoRegen = autoRegen,
    autoRefresh = autoRefresh,
    autoRegain = autoRegain,
};

----------------------------
-- Staffs, Obis, and Torques
----------------------------

-- Spells gain the following potency for affinities:
-- 10% for magic of the day
-- 10% for magic matching single weather
-- 20% for magic matching single weather and day
-- 25% for magic matching double weather
-- 35% for magic matching double weather and day

---Calculate and return the multiplier for the passed element based on day and weather
---@param element LAC.Element
---@return number
local function getElementEnvBonus(element)
    local action = gData.GetAction();
    local env = gData.GetEnvironment();

    local score = 0;

    -- Add day bonus/penalty.
    if element == env.DayElement then
        score = score + 0.1;
    elseif XI.ElementalWeakness[env.DayElement] == element then
        score = score - 0.1;
    end

    -- double weather gives +25%
    local weatherBonus = 0.1
    if env.Weather:endswith("x2") then
        weatherBonus = 0.25
    end

    if element == env.WeatherElement then
        score = score + weatherBonus;
    elseif XI.ElementalWeakness[element] == env.WeatherElement then
        score = score + (weatherBonus * -1);
    end

    return score;
end

-- A constant for every possible elemental staff.  We search for the right ones later.
---@type table<LAC.Element, string[]>
local STAFFS = T {
    Thunder = { "Jupiter's Staff", "Thunder Staff" },
    Ice = { "Aquilo's Staff", "Ice Staff" },
    Fire = { "Vulcan's Staff", "Fire Staff" },
    Wind = { "Auster's Staff", "Wind Staff" },
    Water = { "Neptune's Staff", "Water Staff" },
    Earth = { "Terra's Staff", "Earth Staff" },
    Light = { "Apollo's Staff", "Light Staff" },
    Dark = { "Pluto's Staff", "Dark Staff" },
};

---@type table<LAC.Element, string[]>
local OBIS = T {
    Fire = { "Karin Obi" },
    Earth = { "Dorin Obi" },
    Water = { "Suirin Obi" },
    Wind = { "Furin Obi" },
    Ice = { "Hyorin Obi" },
    Thunder = { "Rairin Obi" },
    Light = { "Korin Obi" },
    Dark = { "Anrin Obi" },
};

---@type table<LAC.Element, string[]>
local TORQUES = T {
    Fire = { "Flame Gorget" },
    Earth = { "Soil Gorget" },
    Water = { "Aqua Gorget" },
    Wind = { "Breeze Gorget" },
    Ice = { "Snow Gorget" },
    Thunder = { "Thunder Gorget" },
    Light = { "Light Gorget" },
    Dark = { "Shadow Gorget" },
};

-- Map each item's id to its element. Include the position of the item
-- in the above priority maps in the event we find more than one.
---@type table<integer, {element: LAC.Element, index: integer, name: string, type: any}>
local ITEMS_TO_ELEMENTS = T {};
do
    local resources = AshitaCore:GetResourceManager();
    for _, typ in ipairs({ STAFFS, OBIS, TORQUES }) do
        for elem, gearList in pairs(typ) do
            for priority, itemName in ipairs(gearList) do
                local item = resources:GetItemByName(itemName, XI.LanguageId.English);
                assert(item ~= nil, string.format("Programming error: No item named {}", itemName));
                ITEMS_TO_ELEMENTS[item.Id] = T {
                    element = elem,
                    index = priority,
                    name = itemName,
                    type = typ,
                };
            end
        end
    end
end

-- Map of element -> surrogate key -> item name
-- where surrogate key is a type of item (staff, obi, etc).
-- nil means the cache needs to be rebuilt.
---@type table<LAC.Element, table<table, string>>?
local EQUIP_CACHE = nil;

Events.inventoryUpdate:on(function()
    EQUIP_CACHE = nil;
end);

---Get (and possibly rebuild) the equipment cache
---@return table<LAC.Element, table<table, string>>
local function getEquipmentCache()
    if EQUIP_CACHE ~= nil then
        return EQUIP_CACHE;
    end

    -- Reset the cache
    EQUIP_CACHE = T {};
    for elem in pairs(STAFFS) do
        EQUIP_CACHE[elem] = T {};
    end

    ---@type table<string, integer>
    local priorityCache = {};

    -- Rebuild the cache
    for _, result in XI.listEquippableInventory() do
        local candidate = result.item;
        local elementalItem = ITEMS_TO_ELEMENTS[candidate.Id];
        if elementalItem ~= nil then
            priorityCache[elementalItem.name] = elementalItem.index;
            local element = EQUIP_CACHE[elementalItem.element];

            -- check priority cache to see if this one is more important
            local isHigherPriority = false;
            if priorityCache[element[elementalItem.type]] ~= nil then
                isHigherPriority = priorityCache[element[elementalItem.type]] < elementalItem.index;
            end

            if element[elementalItem.type] == nil or isHigherPriority then
                element[elementalItem.type] = elementalItem.name;
            end
        end
    end

    return EQUIP_CACHE;
end


---Return the appropriate staff for the passed element or currently casting spell
---@param element LAC.Element?
---@return string?
function Export.getElementalStaff(element)
    if element == nil then
        local action = gData.GetAction();
        if action == nil then
            return nil;
        end
        element = action.Element;
    end
    return getEquipmentCache()[element][STAFFS];
end

---Return the appropriate staff for the passed element or currently casting spell
---@param element LAC.Element?
---@return string?
function Export.getElementalObi(element)
    if element == nil then
        local action = gData.GetAction();
        if action == nil then
            return nil;
        end
        element = action.Element;
    end
    ---@cast element -?

    -- IMPORTANT: According to a post by the developers, the current
    -- day imparts a magic accuracy bonus to matching spells. However,
    -- I'm not sure LSB implements this magic accuracy adjustment.
    --
    -- We only want an obi if the current day and weather
    -- amplifies the spell we're casting.
    if getElementEnvBonus(element) <= 0 then
        return nil;
    end
    return getEquipmentCache()[element][OBIS];
end

---Return the appropriate torque for the current weaponskill.
---Does no divining of the correct torque, instead the user must
---provide all applicable elements for the weaponskill and we will
---return the first one we find.
---@param ... LAC.Element[]
---@return string?
function Export.getElementalTorque(...)
    local eq = getEquipmentCache();
    for _, element in ipairs({ ... }) do
        local torque = eq[element][TORQUES];
        if torque ~= nil then
            return torque;
        end
    end
end

return Export;
