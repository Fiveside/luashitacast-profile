local profile = {};
local sets = {
    Idle = {
        Main = 'Burning Cesti',
        Head = 'Cmp. Eye Circlet',
        Neck = 'Spike Necklace',
        Body = 'Power Gi',
        Hands = 'Lgn. Mittens',
        Ring1 = 'Bastokan Ring',
        Waist = 'White Belt',
        Legs = 'Republic Subligar',
        Feet = 'Windurstian Kyahan',
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