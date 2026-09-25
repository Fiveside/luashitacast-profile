local Util = require("util");
local Shared = require("shared");
local events = require("events");
local SetBuilder = require("setbuilder");

---@type LAC.Profile
local profile = {
    Sets = T {},
    Packer = T {},
};
local sets = profile.Sets;

sets.Idle_Priority = {
    Main = { "Solid Wand", "Yew wand +1", "Willow wand +1", "Maple Wand" },
    Ammo = { "Fortune egg" },
    -- Head = {"Silver hairpin"},
    -- Body = {"Kingdom tunic"},-- {"Ducal Aketon"},
    Hands = { "Savage Gauntlets", "Mycophile cuffs" },
    Legs = { "Seer's slacks +1" },
    Ring1 = { "Eremite's ring", "San d'Orian Ring" },
    Ring2 = { "Eremite's ring", "Windurstian Ring" }
};

sets.Resting_Priority = {
    Main = { "Pilgrim's Wand" },
    Body = { "Seer's Tunic" },
    Legs = { "Baron's slops" },
};

sets.Carbuncle_Priority = {
    Hands = { "Carbuncle mitts" },
};

-- This is for -bp delay gear.
sets.BloodPact_Priority = T {
    Head = { "Austere Hat" },
    Body = { "Austere Robe" },
}

sets.SummoningMagic_Priority = T {
    Head = { "Austere Hat" },
}

-- Non-specific avatar perpetuation cost gear.
sets.PerpetuationCost_Priority = T {
}

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

    return layers:finalize();
end

local function onPetActionComplete(actorId, targetId)
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

    return layers:finalize();
end

profile.HandleDefault = function()
    local layers = SetBuilder.new({ replaceUsable = false });
    layers:add(sets.Idle);

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
    local petAction = gData.GetPetAction();

    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        layers:append(sets.Resting);
    end

    local pet = gData.GetPet()
    if (pet ~= nil) then
        local petSet = sets[pet.Name];
        if (petSet ~= nil) then
            layers:add(petSet);
        end
    end

    gFunc.EquipSet(Util.compress_tables(layers:unpack()));
end

profile.HandleAbility = function()
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
end

profile.HandleMidcast = function()
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
