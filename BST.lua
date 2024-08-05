local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("services/helm");
local Utils = gFunc.LoadFile("util");

local profile = {};
local state = {
    syncedLevel = 0,
};
local sets = {
};

sets.Idle_Priority = {
    Main = {"Martial Axe", "Darksteel Tabar", "Mythril Pick +1", "Cmb.Cst. Axe", "Barbaroi Axe", "Plain Pick", "Battleaxe +1", "Legionnaire's Axe"},
    Sub = {"Barbaroi Axe", "Warrior's Axe", "Battleaxe +1"},
    Head = {"Optical Hat", "Celata", "Mrc.Cpt. Headgear", "Ryl.Ftm. Bandana"},
    Neck = {"Spike Necklace"},
    Ear1 = {"Spike Earring", "Beetle Earring +1"},
    Ear2 = {"Beastly Earring", "Spike Earring", "Beetle Earring +1"},
    Body = {"Scorpion Harness", "Savage Separates", "Beetle Harness +1", "Brass Harness"},
    Hands = {"Beast Gloves", "Battle Gloves", "Lgn. Mittens"},
    Ring1 = {"Victory Ring", "Courage Ring"},
    Ring2 = {"Victory Ring", "Courage Ring"},
    Back = {"Amemet Mantle", "Jaguar Mantle", "Nomad's Mantle"},
    Waist = {"Ryl.Kgt. Belt", "Warrior's Belt +1"},
    Legs = {"Ryl.Kgt. Breeches", "Republic Subligar", "Beetle Subligar +1"},
    Feet = {"Thick Sollerets", "Savage Gaiters", "Btl. Leggings +1", "Field Boots"},
};

local JA_sets = {
    Charm_Priority = {
        Head = {"Noble's Ribbon"},
        Neck = {"Bird Whistle"},
        Hands = {"Beast Gloves"};
        Ring1 = {"Hope Ring"},
        Ring2 = {"Hope Ring"},
        Feet = {"Beast Gaiters", "Savage Gaiters"},
    },
    Reward_Priority = {
        Ammo = {"Pet Food Zeta", "Pet Fd. Epsilon", "Pet Food Delta", "Pet Fd. Gamma"},
        Body = {"Beast Jackcoat"},
        Feet = {"Beast Gaiters"},
    }
};

profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
end

profile.OnUnload = function()
end

profile.HandleCommand = function(args)
    HELM.handleCommand(args);
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel;
        gFunc.EvaluateLevels(sets, myLevel);
        gFunc.EvaluateLevels(JA_sets, myLevel);
    end
    local layers = T{};
    layers:append(sets.Idle);
    layers:append(getZoneSet());
    layers:append(HELM.getSet());
    gFunc.EquipSet(Utils.compress_tables(layers:unpack()));
end

profile.HandleAbility = function()
    local action = gData.GetAction();
    local set = JA_sets[action.Name];
    if set ~= nil then
        gFunc.EquipSet(set);
    end
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