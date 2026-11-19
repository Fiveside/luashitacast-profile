---@module 'types'
local getZoneSet = require("town");
local Utils = require("util");
local Xi = require("xi");
local Shared = require("shared");
local Events = require("events").profile;
local SetBuilder = require("setbuilder");
local JSE = require("common_sets").JSE.THF;
local Tracking = require("tracking")
local ui = require("ui");

---@type LAC.Profile
local profile = {
    Sets = {},
    Packer = {},
};
local sets = profile.Sets;

sets.TP_Priority = T {
    Main = { "Heart Snatcher", "Demon's Knife +1", "Beetle Knife +1" },
    Sub = { "Hoplites Harpe" },
    Range = { "Thug's Zamburak" },

    Head = { "Optical Hat", "Voyager Sallet", "Emperor Hairpin" },
    Neck = { "Peacock Amulet" },
    Ear1 = { "Brutal Earring" },
    Ear2 = { "Ethereal Earring", "Spike Earring" },

    Body = { "Rapparee Harness" },
    Hands = { "Dusk Gloves" },
    Ring1 = { "Rajas Ring" },
    Ring2 = { "Toreador's Ring", "Kshama Ring No.2" },

    Back = { "Amemet Mantle +1", "Jaguar Mantle" },
    Waist = { "Swift Belt" },
    Legs = { "Homam Cosciales", JSE.Artifact.Legs, "Republic Subligar" },
    Feet = { "Homam Gambieras", "Leaping Boots" },
}

sets.Evasion_Priority = Utils.compress_tables(sets.TP_Priority, T {
    Head = { "Optical Hat", "Emperor Hairpin" },
    Ear1 = { "Brutal Earring" },
    Ear2 = { "Ethereal Earring" },
    Body = { "Scorpion Harness" },
});

sets.TreasureHunter_Priority = {
    Neck = { "Nanaa's Charm" },
    Hands = { JSE.RelicPlus1.Hands },
}

-- Stuff that slows down movement speed.  Only matters if the gear is in one of our sets.
sets.AntiMovementSpeed = {
    Hands = "Dusk Gloves",
}

-----------------------------
-- Job Ability specific sets
-----------------------------

sets.JA_Steal = T {
    Head = "Rogue's Bonnet",
    Hands = "Rogue's Armlets",
    Legs = "Assassin's Culottes",
    Feet = "Rogue's Poulaines",
};

sets.JA_Flee = T {
    Feet = "Rogue's Poulaines",
};

sets.JA_Hide = T {
    Body = "Rogue's Vest",
};

-----------------------------
-- Weaponskill specific sets
-----------------------------

-- Modifiers: Dex: 100%
-- Resonance: Scission
-- Hits: 2
-- TP multipliers: 1000: 1.0, 2000: 1.0, 3000: 1.0
sets["WS_Viper Bite"] = T {
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

-- Modifiers: DEX: 30%, CHR: 40%
-- Resonance: Scission, Detonation
-- Hits: 5
-- TP multipliers: 1000: 1.1875, 2000: 1.1875, 3000: 1.1875
sets["WS_Dancing Edge"] = T {
    Waist = "Swordbelt +1",
    Body = "Scorpion Harness",
}

-- Modifiers: DEX: 30%, CHR: 40%
-- Resonance: Fragmentation
-- Hits: 2
-- TP multipliers: 1000: 2, 2000: 2.5, 3000: 3
sets["WS_Shark Bite"] = T {
    Hands = "Dusk Gloves",
    Body = "Assault Jerkin",
    Waist = "Swordbelt +1",
    Feet = JSE.Relic.Feet,
}

-- Modifiers: DEX: 30%, CHR: 30%
-- Resonance: Gravitation, Transfixion
-- Hits: 5
-- TP multipliers: 1000: 1.0, 2000: 1.0, 3000: 1.0
-- TP Crit rates: 1000: 10%, 2000: 30%, 3000: 50%
sets["WS_Evisceration"] = T {
    Hands = "Dusk Gloves",
    Body = "Assault Jerkin",
    Waist = "Swordbelt +1",
}

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    Events.onProfileLoad();
    Events.profileUnload:once(Events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl);
    end));
    gFunc.EvaluateLevels(sets, gData.GetPlayer().MainJobLevel)

    ui.onProfileLoad();
end

profile.OnUnload = function()
    Events.onProfileUnload()

    ui.onProfileUnload();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local layers = SetBuilder.new({ replaceUsable = false });
    local player = gData.GetPlayer();
    layers:add(Shared.autoRegen:getSet());
    layers:add(Shared.autoRegain:getSet());

    if player.Status == "Engaged" then
        layers:add(sets.TP);

        local target = gData.GetTarget();
        if target ~= nil and not Tracking.isTreasureHunterApplied(target.Id) then
            layers:add(sets.TreasureHunter);
        end
    end


    layers:add(Shared.movementSpeed:getSet());
    if Shared.movementSpeed:isActive() then
        layers:exclude(sets.AntiMovementSpeed);
    end

    gFunc.EquipSet(layers:finalize());
end

profile.HandleAbility = function()
    local layers = SetBuilder.new();
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    ---@cast action -?
    ---@cast target -?

    local set = sets["JA_" .. action.Name];
    if action.ActionType == "Ability" and set ~= nil then
        layers:add(set);
    end

    -- Treasure hunter takes priority over other abilities.
    if not Tracking.isTreasureHunterApplied(target.Id) then
        layers:add(sets.TreasureHunter);
    end

    gFunc.EquipSet(layers:finalize());
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
end

profile.HandleMidcast = function()
    local layers = SetBuilder.new();
    local target = gData.GetTarget();

    if target ~= nil and not Tracking.isTreasureHunterApplied(target.Id) then
        layers:add(sets.TreasureHunter);
    end

    gFunc.EquipSet(layers:finalize())
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
    local layers = SetBuilder.new();
    local target = gData.GetActionTarget();
    ---@cast target -?

    if not Tracking.isTreasureHunterApplied(target.Id) then
        layers:add(sets.TreasureHunter);
    end

    gFunc.EquipSet(layers:finalize())
end

profile.HandleWeaponskill = function()
    local action = gData.GetAction();
    local setname = "WS_" .. action.Name;
    if sets[setname] ~= nil then
        gFunc.EquipSet(sets[setname]);
    end
end

return profile;
