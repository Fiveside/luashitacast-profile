local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("services/helm");
local Idle = gFunc.LoadFile("idle");
local Utils = gFunc.LoadFile("util");

local profile = {};
local state = {
    syncedLevel = 0,
}

local sets = T {};

sets.Idle = T {
    Body = "Melee Cyclas",
}

sets.TP = T {
    Main = "Destroyers",
    Ammo = "Civet Sachet",
    -- Head = "Optical Hat",
    Head = "Melee Crown",
    Neck = "Faith Torque",
    Ear1 = "Brutal Earring",
    Ear2 = "Ethereal Earring",
    Body = "Shura Togi",
    Hands = "Melee Gloves",
    Ring1 = "Rajas Ring",
    Ring2 = "Toreador's Ring",
    Back = "Amemet Mantle +1",
    Waist = "Brown Belt",
    Legs = "Byakko's Haidate",
    Feet = "Fuma Sune-Ate",
};

-- Basically high evasion and counter.
sets.Tanking = T {
    Main = "Destroyers",
    Ammo = "Civet Sachet",
    Head = "Optical Hat",
    Body = "Scorpion Harness",
    Back = "Amemet Mantle +1",
    Waist = "Brown Belt",
    Legs = "Temple Hose",
    Feet = "Fuma Sune-Ate",
};

-- The name of the set should be JA_<Jobability>_Priority with appropriate capitalization.
sets.JA_Chakra_Priority = {
    -- Chakra is based on Vit, so this should be a high vit set.
    -- Special gear:
    --   Temple Cyclas - changes the vit multiplier from 1x to 2x
    --   Melee gloves - Adds an additional 0.6 multiplier to vit
    Head = { "Genbu's Kabuto" },

    Body = { "Temple Cyclas" },
    Hands = { "Melee Gloves" },
};
sets.JA_Focus_Priority = {
    Head = { "Temple Crown" },
};
sets.JA_Boost_Priority = {
    Hands = { "Temple Gloves" },
};
sets.JA_Dodge_Priority = {
    Feet = { "Temple Gaiters" },
};
sets.JA_Counterstance_Priority = {
    Feet = { "Melee Gaiters" }
};

sets["WS_Asuran Fists"] = T {
    Head = "Genbu's Kabuto",
    Neck = "Faith Torque",
    Ring1 = "Rajas Ring",
    Ring2 = "Toreador's Ring",
    Waist = "Brown Belt",
    legs = "Shura Haidate",
    Feet = "Shura Sune-Ate",
}

-- Modifiers: STR 50%, VIT 50%
sets["WS_Dragon Kick"] = T {
    Head = "Genbu's Kabuto",
    Neck = "Faith Torque",
    Ring1 = "Rajas Ring",
    Ring2 = "Victory Ring",
    Waist = "Brown Belt",
    legs = "Shura Haidate",
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
    end

    local layers = T {};
    local player = gData.GetPlayer();
    if player.Status == "Engaged" then
        layers:append(sets.TP);
        -- layers:append(sets.Tanking);
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
    if action.ActionType == "Ability" then
        local set = sets['JA_' .. action.Name];
        if set ~= nil then
            gFunc.EquipSet(set);
        end
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
