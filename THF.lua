---@module 'types'
local getZoneSet = gFunc.LoadFile("town");
local Utils = gFunc.LoadFile("util");
local Xi = gFunc.LoadFile('xi');


local profile = {};
local sets = {
};
profile.Sets = sets;

profile.Packer = {
};

local state = T{
    syncedLevel = 0,
};

---@type PriorityGearSet
sets.TP_Priority = T{
    Main = {"Demon's Knife +1", "Beetle Knife +1"},
    Sub = {"Demon's Knife +1", "Marauder's Knife"},
    Range = {"Rogetsurin"},

    Head = {"Voyager Sallet", "Emperor Hairpin"},
    Neck = {"Peacock Amulet"},
    Ear1 = {"Spike Earring"},
    Ear2 = {"Spike Earring"},

    Body = {"Rapparee Harness"},
    Hands = {"Rogue's armlets"},
    Ring1 = {"Rajas Ring"},
    Ring2 = {"Kshama Ring No.2"},

    Back = {"Amemet Mantle +1", "Jaguar Mantle"},
    Waist = {"Swift Belt"},
    Legs = {"Republic Subligar"},
    Feet = {"Leaping Boots"},
}

sets.Evasion_Priority = Utils.compress_tables(sets.TP_Priority, T{
    Head = {"Emperor Hairpin"},
    Ear1 = {"displaced"},
    Ear2 = {"empty"},
    Body = {"Scorpion Harness"},
});

-----------------------------
-- Job Ability specific sets
-----------------------------

---@type GearSet
sets.JA_Steal = T{
    Head = "Rogue's Bonnet",
    Hands = "Rogue's Armlets",
    Legs = "Rogue's Culottes",
    Feet = "Rogue's Poulaines",
};

sets.JA_Flee = T{
    Feet = "Rogue's Poulaines",
};

sets.JA_Hide = T{
    Body = "Rogue's Vest",
};

-----------------------------
-- Weaponskill specific sets
-----------------------------

-- Modifiers: Dex: 100%
-- Resonance: Scission
-- Hits: 2
-- TP multipliers: 1000: 1.0, 2000: 1.0, 3000: 1.0
---@type GearSet
sets["WS_Viper Bite"] = T{
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

-- Modifiers: DEX: 30%, CHR: 40%
-- Resonance: Scission, Detonation
-- Hits: 5
-- TP multipliers: 1000: 1.1875, 2000: 1.1875, 3000: 1.1875
---@type GearSet
sets["WS_Dancing Edge"] = T{
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

-- Modifiers: DEX: 30%, CHR: 40%
-- Resonance: Fragmentation
-- Hits: 2
-- TP multipliers: 1000: 2, 2000: 2.5, 3000: 3
---@type GearSet
sets["WS_Shark Bite"] = T{
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

-- Modifiers: DEX: 30%, CHR: 30%
-- Resonance: Gravitation, Transfixion
-- Hits: 5
-- TP multipliers: 1000: 1.0, 2000: 1.0, 3000: 1.0
-- TP Crit rates: 1000: 10%, 2000: 30%, 3000: 50%
---@type GearSet
sets["WS_Evisceration"] = T{
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
end

profile.OnUnload = function()
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        gFunc.EvaluateLevels(sets, myLevel);
        state.syncedLevel = myLevel
    end

    local layers = T{};
    local player = gData.GetPlayer();
    if player.Status == 'Engaged' then
        -- layers:append(sets.TP);
        layers:append(sets.Evasion);
    end

    layers:append(getZoneSet());
    local final = Utils.compress_tables(table.unpack(layers));
    gFunc.EquipSet(Xi.excludeUsableEquippedItems(final));
end

profile.HandleAbility = function()
    local action = gData.GetAction();
    local set = sets['JA_' .. action.Name];
    if action.ActionType == 'Ability' and set ~= nil then
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
    local setname = "WS_" .. action.Name;
    if sets[setname] ~= nil then
        gFunc.EquipSet(sets[setname]);
    end
end

return profile;