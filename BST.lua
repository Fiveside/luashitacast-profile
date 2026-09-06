local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("helm");
local Utils = gFunc.LoadFile("util");
-- local Idle = gFunc.LoadFile("idle");

local profile = {};
local state = {
    syncedLevel = 0,
    idleRegen = nil,
};
local sets = {
};

sets.Idle = T {};

sets.TP_Priority = {
    Main = { "Retributor", "Mythril Pick +1", "Cmb.Cst. Axe", "Barbaroi Axe", "Battleaxe +1" },
    Sub = { "Temperance Axe", "Martial Axe", "Barbaroi Axe", "Battleaxe +1" },
    Head = { "Optical Hat", "Emperor Hairpin", "Ryl.Ftm. Bandana" },
    Neck = { "Peacock Amulet", "Spike Necklace" },
    Ear1 = { "Brutal Earring", "Spike Earring", "Beetle Earring +1" },
    Ear2 = { "Ethereal Earring", "Spike Earring", "Beetle Earring +1" },
    Body = { "Kirin's Osode", "Assault Jerkin", "Scorpion Harness", "Savage Separates", "Beetle Harness +1", "Brass Harness" },
    Hands = { "Beast Gloves", "Battle Gloves", "Lgn. Mittens" },
    Ring1 = { "Rajas Ring" },
    Ring2 = { "Toreador's Ring", "Kshama Ring No.2", "Courage Ring" },
    Back = { "Amemet Mantle +1", "Jaguar Mantle", "Nomad's Mantle" },
    Waist = { "Swift Belt", "Ryl.Kgt. Belt", "Warrior's Belt +1" },
    Legs = { "Byakko's Haidate", "Ryl.Kgt. Breeches", "Republic Subligar", "Beetle Subligar +1" },
    Feet = { "Thick Sollerets", "Savage Gaiters", "Btl. Leggings +1" },
};

local WS_MULTIHIT = T { "Raging Axe", "Rampage", "Decimation" };
sets.WS_Multihit_Priority = {
    Body = { "Assault Jerkin" },
    Ring1 = { "Rajas Ring" },
    Ring2 = { "Toreador's Ring" },
    Waist = { "Life Belt" }
}

local JA_sets = {
    Charm_Priority = {
        Head = { "Beast Helm", "Noble's Ribbon" },
        Neck = { "Bird Whistle" },
        Body = { "Monster Jackcoat" },
        Hands = { "Beast Gloves" },
        Ring1 = { "Hope Ring" },
        Ring2 = { "Hope Ring" },
        Waist = { "Corsette +1" },
        Legs = { "Beast Trousers" },
        Feet = { "Beast Gaiters", "Savage Gaiters" },
    },
    Reward_Priority = {
        Ammo = { "Pet Food Zeta", "Pet Fd. Epsilon", "Pet Food Delta", "Pet Fd. Gamma" },
        Body = { "Monster Jackcoat", "Beast Jackcoat" },
        Feet = { "Beast Gaiters" },
    }
};

profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    -- ashita.events.register("packet_in", "toz_lac_profile_handler", HandleInboundPacket);
    -- state.idleRegen = Idle.IdleRegen:new();
end

profile.OnUnload = function()
    -- ashita.events.unregister("packet_in", "toz_lac_profile_handler");
end

profile.HandleCommand = function(args)
    HELM.handleCommand(args);
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel;
        gFunc.EvaluateLevels(sets, myLevel);
        gFunc.EvaluateLevels(JA_sets, myLevel);
        -- state.idleRegen:refresh();
    end
    local layers = T {};

    local player = gData.GetPlayer();
    if player.Status == "Engaged" then
        layers:append(sets.TP);
    else
        layers:append(sets.Idle);
    end

    -- layers:append(state.idleRegen:getSet());
    layers:append(getZoneSet());
    layers:append(HELM.getSet());
    -- print(string.format("Heads: %s -> %s", layers:map(function(t) return t.Head; end):join(','), Utils.compress_tables(layers:unpack()).Head));
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
    local name = action.Name;
    if WS_MULTIHIT:contains(name) then
        gFunc.EquipSet(sets.WS_Multihit);
    end
end

return profile;
