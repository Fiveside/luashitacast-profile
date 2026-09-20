local Util = require("util");
local Shared = require("shared");
local events = require("events");

---@type LAC.Profile
local profile = {
    Sets = T {},
    Packer = T {},
};
local sets = profile.Sets;

sets.Idle_Priority = {
    Main = { "Solid Wand", "Yew wand +1", "Willow wand +1", "Maple Wand" },
    Ammo = { "Fortune egg" },
    -- Head = {"Silver hairpin"},
    -- Body = {"Kingdom tunic"},-- {"Ducal Aketon"},
    Hands = { "Savage Gauntlets", "Mycophile cuffs" },
    Legs = { "Seer's slacks +1" },
    Ring1 = { "Eremite's ring", "San d'Orian Ring" },
    Ring2 = { "Eremite's ring", "Windurstian Ring" }
};

sets.Resting_Priority = {
    Main = { "Pilgrim's Wand" },
    Body = { "Seer's Tunic" },
    Legs = { "Baron's slops" },
};

sets.Carbuncle_Priority = {
    Hands = { "Carbuncle mitts" },
};

-- This is for -bp delay gear.
sets.BloodPact_Priority = T {
    Head = { "Austere Hat" },
    Body = { "Austere Robe" },
}

sets.SummoningMagic_Priority = T {
    Head = { "Austere Hat" },
}

-- Non-specific avatar perpetuation cost gear.
sets.PerpetuationCost_Priority = T {
}

-- Avatar to element map, for use when choosing which staff to use
---@type table<string, LAC.Element>
local AVATAR_ELEMENT = {
    Carbuncle = "Light",
    Ramuh = "Thunder",
    Shiva = "Ice",
    Ifrit = "Fire",
    Garuda = "Wind",
    Leviathan = "Water",
    Titan = "Earth",
    Fenrir = "Dark",
    Diabolos = "Dark",

    ["Light Spirit"] = "Light",
    ["Thunder Spirit"] = "Thunder",
    ["Ice Spirit"] = "Ice",
    ["Fire Spirit"] = "Fire",
    ["Wind Spirit"] = "Wind",
    ["Water Spirit"] = "Water",
    ["Earth Spirit"] = "Earth",
    ["Dark Spirit"] = "Dark",
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;

    events.onProfileLoad();
    events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl);
    end);
    gFunc.EvaluateLevels(sets, gData.GetPlayer().MainJobSync);
end

profile.OnUnload = function()
    events.onProfileUnload();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local layers = T {};
    layers:append(sets.Idle);

    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        layers:append(sets.Resting);
    end

    local pet = gData.GetPet()
    if (pet ~= nil) then
        local petSet = sets[pet.Name];
        if (petSet ~= nil) then
            layers:append(petSet);
        end
    end

    gFunc.EquipSet(Util.compress_tables(layers:unpack()));
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
