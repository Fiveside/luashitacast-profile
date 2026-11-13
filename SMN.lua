local Util = require("util");
local Shared = require("shared");
local events = require("events").profile;
local SetBuilder = require("setbuilder");
local CommonSets = require("common_sets");
local JSE = CommonSets.JSE;

---@type LAC.Profile
local profile = {
    Sets = T {},
    Packer = T {},
};
local sets = profile.Sets;
CommonSets.applyCommonMagicSets(sets);

sets.MaxMP_Priority = {
    -- Main = { Shared.getElementalStaff("Dark") },
    Ammo = { "Fortune egg" },
    Head = { "Austere Hat" },
    Ear1 = { "Morion Earring" },
    Hands = { "Savage Gauntlets", "Mycophile cuffs" },
    Ring1 = { "Kshama Ring No.5", "San d'Orian Ring" },
    Ring2 = { "Eremite's ring", "Windurstian Ring" },
    Waist = { "Qiqirn Sash +1" },
    Legs = { "Seer's slacks +1" },
    Feet = { "Austere Sabots" },
};

sets.StaffStrap_Prioirty = {
    Sub = { "Bugard Strap +1" },
};

-- Haste and conserve mp.
sets.Midcast_Priority = {}

sets.Resting_Priority = {
    Main = { Shared.getElementalStaff("Dark"), "Pilgrim's Wand" },
    Neck = { "Beak Necklace +1" },
    Body = { "Seer's Tunic" },
    Waist = { "Qiqirn Sash +1" },
    Legs = { "Baron's slops" },
    Ear1 = { "Relaxing Earring" },
    Ear2 = { "Antivenom Earring" },
};

-- Reduces recast on blood pacts.
-- Snapshotted when the summoner orders a blood pact. (HandleAbility)
sets.BloodPactDelay_Priority = T {
    Head = { "Austere Hat" },
    Body = { "Austere Robe" },
    Hands = { "Austere Cuffs" },
}

-- Affects a number of things:
-- - Blood pact rage accuracy and magic accuracy.  Snapshotted when the skill connects.
-- - Blood pact ward buff duration.  Snapshotted when the skill connects.
-- - AI of elemental spirits
-- - Time between casts from elemental spirits
sets.Skill_Summoning_Priority = T {
    Head = { "Austere Hat" },
    Hands = { "Austere Cuffs" },
    Legs = { "Austere Slops" },
    Feet = { "Austere Sabots" },
}

-- Non-specific avatar perpetuation cost gear.
sets.PerpetuationCost_Priority = T {
    Body = { "Austere Robe" },
}

sets.PerpetuationCost_Carbuncle_Priority = {
    Hands = { "Carbuncle mitts" },
};

-- Avatar to element map, for use when choosing which staff to use
---@type table<string, LAC.Element>
local AVATAR_ELEMENT = {
    Carbuncle = "Light",
    Ramuh = "Thunder",
    Shiva = "Ice",
    Ifrit = "Fire",
    Garuda = "Wind",
    Leviathan = "Water",
    Titan = "Earth",
    Fenrir = "Dark",
    Diabolos = "Dark",

    ["Light Spirit"] = "Light",
    ["Thunder Spirit"] = "Thunder",
    ["Ice Spirit"] = "Ice",
    ["Fire Spirit"] = "Fire",
    ["Wind Spirit"] = "Wind",
    ["Water Spirit"] = "Water",
    ["Earth Spirit"] = "Earth",
    ["Dark Spirit"] = "Dark",
};

-- The actual midcast flow for the player without considering the pet.
local function getMidcastSet()
    local layers = SetBuilder.new();
    local action = gData.GetAction();
    ---@cast action -?

    local skillSet = sets["Skill_" .. action.Skill]
    if skillSet ~= nil then
        layers:add(skillSet);
    end

    local staff = Shared.getElementalStaff()
    if staff ~= nil then
        layers:add(sets.StaffStrap);
        layers:add({ Main = staff });
    end

    local spellSpecificSet = sets["MA_" .. action.Name];
    if spellSpecificSet ~= nil then
        layers:add(spellSpecificSet);
    end

    return layers:finalize();
end

local function onPetActionComplete(actorId, combatAction)
    -- We only care about our pet's action
    local pet = gData.GetPet();
    if pet == nil or pet.Id ~= actorId then
        return;
    end

    -- The only time we need to take action is if we are mid-cast
    -- when the action completes to swap to the casting set.
    local action = gData.GetAction();
    if action ~= nil then
        gFunc.ForceEquipSet(getMidcastSet());
    end
end

profile.OnLoad = function()
    gSettings.AllowAddSet = false;

    events.onProfileLoad();
    events.profileUnload:once(events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl);
    end));
    gFunc.EvaluateLevels(sets, gData.GetPlayer().MainJobSync);

    events.profileUnload:once(events.petActionComplete:on(onPetActionComplete));
end

profile.OnUnload = function()
    events.onProfileUnload();
end

profile.HandleCommand = function(args)
end

-- Execution flow here is a bit complicated
-- If a pet uses an action, it goes
-- HandleAction -> HandleDefault -> getPetActionSet
--
-- if a pet uses an action and we begin casting
-- HandleAction -> HandleDefault -> HandlePrecast -> HandleMidcast(calls getMidcastSet()) -> getPetActionSet
-- And then when the pet completes the action if we're still casting
-- onPetActionComplete -> getMidcastSet -> force equip midcast set
-- If the pet completes the action after we finished casting then
-- the pet's gearset takes priority over our cast's gearset.

local function getPetActionSet()
    local layers = SetBuilder.new();

    local pet = gData.GetPet();
    local petAction = gData.GetPetAction();
    if petAction ~= nil and T({ "Blood Pact: Rage", "Blood Pact: Ward" }):contains(petAction.Type) then
        layers:add(sets.SummoningMagic);
    end
    return layers:finalize();
end

profile.HandleDefault = function()
    local layers = SetBuilder.new({ replaceUsable = false });
    layers:add(sets.MaxMP);
    layers:add(Shared.autoRegen:getSet());
    layers:add(Shared.autoRefresh:getSet());

    -- Pet state changes the desired gear set significantly.
    -- A general rule of thumb is that no gear augments pets
    -- in any permanent way such that you can equip the gear
    -- before summoning the pet and then unequip it after
    -- and have the effects persist.
    --
    -- The typical flow:
    -- Gear swap to +spell haste
    -- master begins casting summon
    -- gear swap to +summoning magic
    -- finish summon
    -- gear swap to -perpetuation cost
    -- master orders pet to attack, pet engages enemy
    -- gear swap to +pet auto effectiveness
    -- time passes
    -- gear swap to -bp recast
    -- Master performs BP action (HandleAbility)
    -- gear swap to +bp effectiveness
    -- pet readies and uses bp
    -- gear swap to -perpetuation cost and or +pet auto effectiveness
    -- master dismisses pet
    -- gear swap to idle
    --
    -- Notable points of the above:
    -- Bp recast is calculated upon the master using the ability, not the pet.
    -- BP gains accuracy and power with +summoning magic
    -- Pet state needs to be managed in HandleDefault, as the master is
    -- -- not doing anything when the pet is readying or using an ability.

    local pet = gData.GetPet()

    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        layers:add(sets.Resting);
    end

    if (pet ~= nil) then
        layers:add(sets.PerpetuationCost);
        local petSet = sets["PerpetuationCost_" .. pet.Name];
        if (petSet ~= nil) then
            layers:add(petSet);
        end

        -- Aligned elemental staffs always have the highest bonuses for every category
        -- on any given pet.
        local petElement = AVATAR_ELEMENT[pet.Name];
        layers:add({ Main = Shared.getElementalStaff(petElement) });
    end

    -- pet actions need to take priority over any idle set.
    if gData.GetPetAction() ~= nil then
        layers:add(getPetActionSet());
    end

    layers:add(Shared.movementSpeed:getSet());

    gFunc.EquipSet(layers:finalize());
end

profile.HandleAbility = function()
    local layers = SetBuilder.new();
    local action = gData.GetAction();
    ---@cast action -?

    if T({ "Blood Pact: Rage", "Blood Pact: Ward" }):contains(action.Type) then
        layers:add(sets.BloodPactDelay);
    end

    gFunc.EquipSet(layers:finalize());
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
    gFunc.EquipSet(Shared.fastCast:getSet())
end

profile.HandleMidcast = function()
    gFunc.EquipSet(getMidcastSet());
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
