local BGM = require('packets/bgm');

local profile = {};
local state = {
    syncedLevel = 0,
    -- music = nil,
}

local sets = {
    Idle_Priority = {
        Main = {"T.M. Hooks +1", "Tekko Kagi", "Impact Knuckles", "Lynx Baghnakhs", "Burning Cesti"},
        Ammo = {"Happy Egg"},
        Head = {"Temple Crown", "Mrc.Cpt. Headgear", "Mrc. Hachimaki"},
        Neck = "Spike Necklace",
        Ear1 = {"Spike Earring", "Beetle Earring +1"},
        Ear2 = {"Spike Earring", "Beetle Earring +1"},
        Body = {"Scorpion Harness", "Temple Cyclas", --[["Jujitsu Gi", ]] "Savage Separates", "Power Gi"},
        Hands = {"Temple Gloves", "Federation Tekko", "Lgn. Mittens"},
        Ring1 = {"Courage Ring", "Bastokan Ring"},
        Ring2 = "Courage Ring",
        Back = {"Amemet Mantle", "Jaguar Mantle", "Nomad's Mantle"},
        Waist = {"Brown Belt", "Purple Belt"},
        Legs = {"Temple Hose", "Republic Subligar"},
        Feet = {"Temple Gaiters", "Savage Gaiters", "Win. Kyahan"},
    },
};

-- The name of the set should be <Jobability>_Priority with appropriate capitalization.
local JA_sets = {
    Chakra_Priority = {
        -- Chakra is based on Vit, so this should be a high vit set.
        -- Special gear: 
        --   Temple Cyclas - changes the vit multiplier from 1x to 2x
        --   Melee gloves - Adds an additional 0.6 multiplier to vit
        Body = {"Temple Cyclas"},
        Hands = {"Savage Gauntlets"},
    },
    Focus_Priority = {
        Head = {"Temple Crown"},
    },
    Boost_Priority = {
        Hands = {"Temple Gloves"},
    },
    Dodge_Priority = {
        Feet = {"Temple Gaiters"},
    },
};

profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    -- state.music = BGM:new();
end

profile.OnUnload = function()
    -- state.music:destroy();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel
        gFunc.EvaluateLevels(sets, myLevel);
        gFunc.EvaluateLevels(JA_sets, myLevel);
    end
    gFunc.EquipSet(sets.Idle)
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