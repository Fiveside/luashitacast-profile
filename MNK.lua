local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("services/helm");
local Idle = gFunc.LoadFile("services/idle");
local Utils = gFunc.LoadFile("util");

local profile = {};
local state = {
    syncedLevel = 0,
}

local sets = {
    Idle_Priority = {
        Main = {"T.M. Hooks +2", "Tekko Kagi", "Impact Knuckles", "Lynx Baghnakhs", "Burning Cesti"},
        Ammo = {"Civet Sachet", "Happy Egg"},
        Head = {"Optical Hat", "Temple Crown", "Mrc.Cpt. Headgear", "Mrc. Hachimaki"},
        Neck = {"Peacock Amulet", "Spike Necklace"},
        Ear1 = {"Spike Earring", "Beetle Earring +1"},
        Ear2 = {"Spike Earring", "Beetle Earring +1"},
        Body = {"Scorpion Harness", "Temple Cyclas", --[["Jujitsu Gi", ]] "Savage Separates", "Power Gi"},
        Hands = {"Ochiudo's Kote", "Federation Tekko", "Lgn. Mittens"},
        Ring1 = {"Rajas Ring", "Courage Ring", },
        Ring2 = {"Toreador's Ring", "Victory Ring", "Courage Ring", "Bastokan Ring"},
        Back = {"Amemet Mantle +1", "Jaguar Mantle", "Nomad's Mantle"},
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

local Multihit_WS = T{"Combo", "Raging Fists", "Asuran Fists"};
sets.WS_Multihit_Priority = {
    Neck = {"Peacock Amulet"},
    Ring1 = {"Rajas Ring"},
    Ring2 = {"Toreador's Ring"},
    Waist = {"Life Belt"}
}

sets.WS_Priority = {
    Neck = {"Spike Necklace"},
    Ring1 = {"Rajas Ring"},
    Ring2 = {"Victory Ring", "Courage Ring"},
    Waist = {"Brown Belt"},
}

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
        state.syncedLevel = myLevel
        gFunc.EvaluateLevels(sets, myLevel);
        gFunc.EvaluateLevels(JA_sets, myLevel);
    end
    local layers = T{};
    layers:append(sets.Idle);
    layers:append(getZoneSet());
    layers:append(Idle.getSet());
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
    local action = gData.GetAction();
    if Multihit_WS:contains(action.Name) then
        gFunc.EquipSet(sets.WS_Multihit);
    else
        gFunc.EquipSet(sets.WS);
    end
end

return profile;