local profile = {};
local state = {
    currentLevel = 0
};
local sets = {
    Idle_Priority = {
        Main = {"Greataxe"},
        Head = {"Ryl.Ftm. Bandana"},
        Neck = "Spike Necklace",
        Body = {"Brass Harness"},
        Hands = {"Lgn. Mittens"},
        Ear1 = "Beetle Earring +1",
        Ear2 = "Beetle Earring +1",
        Ring1 = {"Courage Ring", "Bastokan Ring"},
        Ring2 = {"Courage Ring"},
        Back = {"Nomad's Mantle"},
        Waist = {"Warrior's Belt"},
        Legs = {"Republic Subligar", "Scale Cuisses"},
        Feet = "Scale Greaves",
    },
    RangedAttack_Priority = {

    },
};
profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
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