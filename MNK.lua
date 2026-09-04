---@module 'town'
local getZoneSet = gFunc.LoadFile("town");
---@module 'services.helm'
local HELM = gFunc.LoadFile("services/helm");
---@module 'idle'
local Idle = gFunc.LoadFile("idle");
---@module 'xi'
local Xi = gFunc.LoadFile("xi");
---@module 'ui'
local Ui = gFunc.LoadFile("ui");
---@module 'util'
local Utils = gFunc.LoadFile("util");
local SetBuilder = Utils.SetBuilder;

local profile = {};
local state = {
    currentLevel = 0,
    idleRegen = nil,

    ---@type SetSelector
    combatSelector = nil,
}

local sets = T {};

sets.Idle = T {};

sets.TP = T {
    Main = "Destroyers",
    Ammo = "Tiphia Sting",
    Head = "Shr.Znr.Kabuto",
    -- Head = "Melee Crown",
    Neck = "Faith Torque",
    Ear1 = "Brutal Earring",
    Ear2 = "Ethereal Earring",
    Body = "Shura Togi",
    Hands = "Mel. Gloves +1",
    Ring1 = "Rajas Ring",
    Ring2 = "Toreador's Ring",
    Back = "Amemet Mantle +1",
    Waist = "Black Belt",
    Legs = "Byakko's Haidate",
    Feet = "Fuma Sune-Ate",
};

-- Basically high evasion, PDT, and counter.
sets.Tanking = Utils.compress_tables(sets.TP, T {
    Head = "Optical Hat",
    Body = "Arhat's Gi +1",
    Legs = "Temple Hose",
    Feet = "Melee Gaiters",
});

sets.Evasion = Utils.compress_tables(sets.Tanking, T {
    Ammo = "Civet Satchet",
    Head = "Optical Hat",
    Body = "Scorpion Harness",
});

sets.HundredFists = Utils.compress_tables(sets.TP, T {
    Legs = "Shura Haidate",
    Feet = "Shura Sune-Ate",
});

-- The name of the set should be JA_<Jobability>_Priority with appropriate capitalization.
sets.JA_Chakra_Priority = {
    -- Chakra is based on Vit, so this should be a high vit set.
    -- Special gear:
    --   Temple Cyclas - changes the vit multiplier from 1x to 2x
    --   Melee gloves - Adds an additional 0.6 multiplier to vit
    Ammo = { "Fortune Egg" },
    Head = { "Genbu's Kabuto" },
    Body = { "Temple Cyclas" },
    Waist = { "Warrior's Belt +1" },
    Hands = { "Mel. Gloves +1" },
    Ring1 = { "Soil Ring" },
    Ring2 = { "Soil Ring" },
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

-- Modifiers: STR 10%, VIT 10%
-- Asuran Fists gains no benefit from multiattack
sets["WS_Asuran Fists"] = T {
    Head = "Shr.Znr.Kabuto",
    Neck = "Faith Torque",
    Body = "Shura Togi",
    Ring1 = "Rajas Ring",
    Ring2 = "Toreador's Ring",
    Waist = "Black Belt",
    legs = "Shura Haidate",
    Feet = "Shura Sune-Ate",
}

-- Modifiers: STR 50%, VIT 50%
sets["WS_Dragon Kick"] = T {
    Head = "Genbu's Kabuto",
    Neck = "Faith Torque",
    Body = "Kirin's Osode",
    Ring1 = "Rajas Ring",
    Ring2 = "Victory Ring",
    Waist = "Black Belt",
    legs = "Shura Haidate",
    Feet = "Dune Boots",
}

-- Modifiers: STR: 20%, DEX: 20%
sets["WS_Raging Fists"] = Utils.compress_tables(sets["WS_Asuran Fists"], T {
    Head = "Melee Crown",
    Legs = "Byakko's Haidate",
});

-- Modifiers: STR: 50%, VIT: 20%
sets["WS_Howling Fist"] = Utils.compress_tables(sets["WS_Dragon Kick"], T {
    Feet = "Shura Sune-Ate",
});

sets.WS_Combo = Utils.compress_tables(sets["WS_Asuran Fists"]);

sets.IdleRegen = T {
    Body = "Melee Cyclas",
};

profile.Sets = sets;

profile.Packer = {
};

local function equipFenrirEar(set)
    -- Fenrir's earring can replace a +atk earring during the day.
    if Xi.isDaytime() then
        local item = "Fenrir's Earring"
        local replaces = T { "Ethereal Earring" }
        if replaces:contains(set.Ear1) then
            return { Ear1 = item };
        elseif replaces:contains(set.Ear2) then
            return { Ear2 = item };
        end
    end
end

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    state.idleRegen = Idle.IdleRegen:new(sets.IdleRegen);
    state.currentLevel = 0;
    state.combatSelector = Utils.SetSelector.new("Combat", "p", sets);

    state.combatSelector:addSet("TP", "TP")
    state.combatSelector:addSet("Tanking", "Tanking")
    -- state.combatSelector:addSet("HundredFists", "Hundred Fists");

    -- Default to TP set
    state.combatSelector:use("TP");

    Ui.onProfileLoad({
        selectors = {
            state.combatSelector
        }
    });
end

profile.OnUnload = function()
    Ui.onProfileUnload();
end

profile.HandleCommand = function(args)
    HELM.handleCommand(args);
    Ui.onSlashCommand(args);
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel
        gFunc.EvaluateLevels(sets, myLevel);
        state.idleRegen:refresh();
    end

    local layers = SetBuilder.new();

    local player = gData.GetPlayer();
    if player.Status == "Engaged" then
        -- layers:append(sets.TP);
        -- layers:append(sets.Tanking);

        local buffs = Xi.getMyBuffsByName();
        if buffs["Hundred Fists"] ~= nil then
        end
    else
        layers:add(sets.Idle);
    end

    layers:add(state.combatSelector:getSet())
    layers:add(state.idleRegen:getSet());
    layers:add(getZoneSet());
    layers:add(HELM.getSet());
    layers:add(equipFenrirEar(layers:getSet()));

    return gFunc.EquipSet(Xi.excludeUsableEquippedItems(layers:getSet()));
end

profile.HandleAbility = function()
    local layers = SetBuilder.new();
    local action = gData.GetAction();
    if action.ActionType == "Ability" then
        local set = sets["JA_" .. action.Name];
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
    local layers = SetBuilder.new();
    if sets[setname] ~= nil then
        layers:add(sets[setname])
    end
    layers:add(equipFenrirEar(layers:getSet()));
    gFunc.EquipSet(layers:getSet());
end

return profile;
