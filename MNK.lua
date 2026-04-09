local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("services/helm");
local Idle = gFunc.LoadFile("idle");
local Utils = gFunc.LoadFile("util");

local profile = {};
local state = {
    syncedLevel = 0,
}

local sets = T{};

sets.Idle = T{
    Body = "Melee Cyclas",
}

sets.TP_Priority = T{
    Main = {"Destroyers", "Tekko Kagi", "Impact Knuckles", "Burning Cesti"},
    Ammo = {"Civet Sachet", "Happy Egg"},
    Head = {"Optical Hat", "Temple Crown", "Emperor Hairpin", "Mrc. Hachimaki"},
    Neck = {"Peacock Amulet", "Spike Necklace"},
    Ear1 = {"Brutal Earring", "Spike Earring", "Beetle Earring +1"},
    Ear2 = {"Ethereal Earring", "Spike Earring", "Beetle Earring +1"},
    Body = {"Shura Togi", "Scorpion Harness", "Temple Cyclas", --[["Jujitsu Gi", ]] "Savage Separates", "Power Gi"},
    Hands = {"Melee Gloves", --[["Ochiudo's Kote",]] "Federation Tekko", "Lgn. Mittens"},
    Ring1 = {"Rajas Ring", "Courage Ring", },
    Ring2 = {"Toreador's Ring", "Victory Ring", "Courage Ring", "Bastokan Ring"},
    Back = {"Amemet Mantle +1", "Jaguar Mantle", "Nomad's Mantle"},
    Waist = {"Brown Belt"},
    Legs = {"Byakko's Haidate", "Melee Hose", "Temple Hose", "Republic Subligar"},
    Feet = {"Fuma Sune-Ate", "Temple Gaiters", "Savage Gaiters", "Win. Kyahan"},
};

-- The name of the set should be <Jobability>_Priority with appropriate capitalization.
local JA_sets = {
    Chakra_Priority = {
        -- Chakra is based on Vit, so this should be a high vit set.
        -- Special gear: 
        --   Temple Cyclas - changes the vit multiplier from 1x to 2x
        --   Melee gloves - Adds an additional 0.6 multiplier to vit
        Head = {"Genbu's Kabuto"},
        Body = {"Temple Cyclas"},
        Hands = {"Melee Gloves"},
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
    Counterstance_Priority = {
        Feet = {"Melee Gaiters"}
    }
};

sets["WS_Asuran Fists"] = T{
    Head = "Genbu's Kabuto",
    Neck = "Peacock Amulet",
    Ring1 = "Rajas Ring",
    Ring2 = "Toreador's Ring",
    Waist = "Brown Belt",
    Feet = "Shura Sune-Ate",
}

-- Modifiers: STR 50%, VIT 50%
sets["WS_Dragon Kick"] = T{
    Head = "Genbu's Kabuto",
    Neck = "Spike Necklace",
    Ring1 = "Rajas Ring",
    Ring2 = "Victory Ring",
    Waist = "Brown Belt",
    Feet = "Dune Boots",
}

sets.WS_Raging_Fists = Utils.compress_tables(sets.WS_Asuran_Fists);
sets.WS_Combo = Utils.compress_tables(sets.WS_Asuran_Fists);

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
    local player = gData.GetPlayer();
    if player.Status == "Engaged" then
        layers:append(sets.TP);
    else
        layers:append(sets.Idle);
    end
    
    -- layers:append(sets.TP);
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
    local setname = "WS_" .. action.Name
    if sets[setname] ~= nil then
        gFunc.EquipSet(sets[setname]);
    end
end

return profile;