local util = require('util');


local profile = {};
local state = {
    currentLevel = 0,
    currentSet = "Idle",
};
local sets = {
    Idle_Priority = {
        Main = {"Neckchopper", "Greataxe"},
        Ammo = {"Happy Egg"},
        Head = {"Ryl.Ftm. Bandana"},
        Neck = "Spike Necklace",
        Body = {"Beetle Harness", "Brass Harness"},
        Hands = {"Lgn. Mittens"},
        Ear1 = "Beetle Earring +1",
        Ear2 = "Beetle Earring +1",
        Ring1 = {"Courage Ring", "Bastokan Ring"},
        Ring2 = {"Courage Ring"},
        Back = {"Nomad's Mantle"},
        Waist = {"Warrior's Belt +1"},
        Legs = {"Republic Subligar", "Lgn. Subligar", "Scale Cuisses"},
        Feet = {"Beetle Leggings", "Scale Greaves"},
    },
};
local extendedSets = {
    Idle_Priority = {
        RangedAttack_Priority = {
            Range = 'Power Bow +1',
            Ammo = 'Beetle Arrow',
        }
    }
}

profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    util.extend_sets(sets, sets, extendedSets);
end

profile.OnUnload = function()
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.currentLevel) then
        state.currentLevel = myLevel
        gFunc.EvaluateLevels(sets, myLevel)
    end
    gFunc.EquipSet(sets.Idle)
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