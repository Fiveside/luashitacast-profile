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
    Hands = { "Mycophile cuffs" },
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

sets.Blood_Pact_Priority = T {

}

local state = {
    syncedLevel = 0,
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
