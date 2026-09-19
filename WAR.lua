local util = require("util");
local shared = require("shared");
local events = require("events")

---@type LAC.Profile
local profile = {
    Sets = T {},
    Packer = T {},
};
local sets = profile.Sets;
local state = {
    currentSet = "Idle",
};

sets.Idle_Priority = {
    Main = { "Centurion's Axe", "Neckchopper", "Greataxe" },
    Ammo = { "Happy Egg" },
    Head = { "Shade Tiara", "Ryl.Ftm. Bandana" },
    Neck = "Spike Necklace",
    Body = { "Beetle Harness +1", "Brass Harness" },
    Hands = { "Lgn. Mittens" },
    Ear1 = "Beetle Earring +1",
    Ear2 = "Beetle Earring +1",
    Ring1 = { "Rajas Ring", "Courage Ring" },
    Ring2 = { "Victory Ring", "Courage Ring", "Bastokan Ring" },
    Back = { "Nomad's Mantle" },
    Waist = { "Warrior's Belt +1" },
    Legs = { "Republic Subligar", "Beetle Subligar +1", "Scale Cuisses" },
    Feet = { "Btl. Leggings +1", "Scale Greaves" },
};


local extendedSets = {
    Idle_Priority = {
        RangedAttack_Priority = {
            Range = "Power Bow +1",
            Ammo = "Beetle Arrow",
        }
    }
}

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    util.extend_sets(sets, sets, extendedSets);
    events.onProfileLoad();
    events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl)
    end);
    gFunc.EvaluateLevels(sets, gData.GetPlayer().MainJobSync);
end

profile.OnUnload = function()
    events.onProfileUnload();
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
