local getZoneSet = gFunc.LoadFile("town");
local HELM = gFunc.LoadFile("services/helm");
local Utils = gFunc.LoadFile("util");
local Idle = gFunc.LoadFile("services/idle");

local profile = {};
local state = {
    syncedLevel = 0,
};
local sets = {
};

sets.Idle_Priority = {
    Main = {"Martial Axe", "Darksteel Tabar", "Mythril Pick +1", "Cmb.Cst. Axe", "Barbaroi Axe", "Plain Pick", "Battleaxe +1", "Legionnaire's Axe"},
    Sub = {"Barbaroi Axe", "Warrior's Axe", "Battleaxe +1"},
    Head = {"Optical Hat", "Celata", "Mrc.Cpt. Headgear", "Ryl.Ftm. Bandana"},
    Neck = {"Peacock Amulet", "Spike Necklace"},
    Ear1 = {"Spike Earring", "Beetle Earring +1"},
    Ear2 = {"Beastly Earring", "Spike Earring", "Beetle Earring +1"},
    Body = {"Scorpion Harness", "Savage Separates", "Beetle Harness +1", "Brass Harness"},
    Hands = {"Beast Gloves", "Battle Gloves", "Lgn. Mittens"},
    Ring1 = {"Rajas Ring"},
    Ring2 = {"Victory Ring", "Courage Ring"},
    Back = {"Amemet Mantle +1", "Jaguar Mantle", "Nomad's Mantle"},
    Waist = {"Ryl.Kgt. Belt", "Warrior's Belt +1"},
    Legs = {"Ryl.Kgt. Breeches", "Republic Subligar", "Beetle Subligar +1"},
    Feet = {"Thick Sollerets", "Savage Gaiters", "Btl. Leggings +1"},
};

local WS_MULTIHIT = T{"Raging Axe", "Rampage", "Decimation"};
sets.WS_Multihit_Priority = {
    Ring1 = {"Rajas Ring"},
    Ring2 = {"Toreador's Ring"},
    Waist = {"Life Belt"}
}

local JA_sets = {
    Charm_Priority = {
        Head = {"Noble's Ribbon"},
        Neck = {"Bird Whistle"},
        Hands = {"Beast Gloves"};
        Ring1 = {"Hope Ring"},
        Ring2 = {"Hope Ring"},
        Feet = {"Beast Gaiters", "Savage Gaiters"},
    },
    Reward_Priority = {
        Ammo = {"Pet Food Zeta", "Pet Fd. Epsilon", "Pet Food Delta", "Pet Fd. Gamma"},
        Body = {"Beast Jackcoat"},
        Feet = {"Beast Gaiters"},
    }
};

profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    -- ashita.events.register("packet_in", "toz_lac_profile_handler", HandleInboundPacket);
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
    end
    local layers = T{};
    layers:append(sets.Idle);
    layers:append(getZoneSet());
    layers:append(Idle.getSet());
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

-- local IsZoning = false;

-- function HandleInboundPacket(event)
--     -- Send lockstyle event once on zone.
--     if (event.id == 0xB) then
--         IsZoning = true;
--     end
--     if (event.id == 0x1D) and IsZoning then
--         IsZoning = false;
--     end
-- end

return profile;