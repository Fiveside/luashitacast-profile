local BGM = require('packets/bgm');

local profile = {};
local state = {
    currentLevel = 0,
    music = nil,
}

local sets = {
    Idle_Priority = {
        Main = {"T.M. Hooks +1", "Tekko Kagi", "Impact Knuckles", "Lynx Baghnakhs", "Burning Cesti"},
        Ammo = {"Happy Egg"},
        Head = {"Mrc.Cpt. Headgear", "Mrc. Hachimaki"},
        Neck = "Spike Necklace",
        Ear1 = "Beetle Earring +1",
        Ear2 = "Beetle Earring +1",
        Body = { --[["Jujitsu Gi", ]] "Savage Separates", "Power Gi"},
        Hands = {"Federation Tekko", "Lgn. Mittens"},
        Ring1 = {"Courage Ring", "Bastokan Ring"},
        Ring2 = "Courage Ring",
        Back = {"Nomad's Mantle"},
        Waist = {"Purple Belt", "White Belt"},
        Legs = "Republic Subligar",
        Feet = {"Savage Gaiters", "Win. Kyahan"},
    },
};
profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    state.music = BGM:new();
end

profile.OnUnload = function()
    state.music:destroy();
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