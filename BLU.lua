local Ui = gFunc.LoadFile("ui");
local Utils = gFunc.LoadFile("util");
local events = gFunc.LoadFile("events");
local Xi = gFunc.LoadFile("xi");
local Magic = gFunc.LoadFile("magic");
local Common = gFunc.LoadFile("common_sets");

local JSE = Common.JSE;

---@type LAC.Profile
local profile = {
    Sets = {},
    Packer = {},
};
local sets = profile.Sets;

sets.TP_Priority = {
    -- Main = "Kilij",
    -- Sub = "Immortal's Scimitar",
    Ammo = "Civet Sachet",
    Head = "Voyager Sallet",
    Neck = "Peacock Amulet",
    Ear1 = "Morion Earring",
    Ear2 = "Moldavite Earring",
    Body = { "Scorpion Harness", "Brigandine" },
    Hands = { "Magus Bazubands", "Savage Gauntlets" },
    Ring1 = "Rajas Ring",
    Ring2 = "Kshama Ring No.2",
    Back = { "Amemet Mantle +1", "Jaguar Mantle" },
    Waist = "Life Belt",
    Legs = "Magus Shalwar",
    Feet = "Magus Charuqs",
};

sets.Resting = T {
    Head = "displaced",
    Body = "Vermillion Cloak",
    Waist = "Qiqirn Sash +1",
    Legs = "Baron's Slops",
};

sets.Idle_Priority = T {
    Head = { { Name = "displaced", Level = 62, } },
    Body = { "Vermillion Cloak" }
}

local physDamageSet = T {
    Ammo = "Tiphia Sting",
    Ear1 = "Spike Earring",
    Ear2 = "Spike Earring",
    Body = { "Magus Jubbah", "Scorpion Harness" },
    Hands = "Battle Gloves",
    Feet = "Savage Gaiters",
};

sets.PhysicalSpell_Prioirty = physDamageSet;

local magicDamagePrioritySet = T {
    Head = { JSE.BLU.Artifact.Head },
    Ammo = { "Phtm. Tathlum" },
    Ear1 = { "Moldavite Earring" },
    Ear2 = { "Morion Earring" },
}

sets.MagicalBlueSpell_Priority = magicDamagePrioritySet;

sets["MA_Bludgeon_Priority"] = physDamageSet:copy(true)
sets["MA_Jet Stream_Priority"] = physDamageSet:copy(true)
sets["MA_Quad. Continuum_Priority"] = physDamageSet:copy(true)
sets["MA_Sickle Slash_Priority"] = physDamageSet:copy(true)
sets["MA_Death Scissors_Priority"] = physDamageSet:copy(true)
sets["MA_Death Scissors_Priority"] = physDamageSet:copy(true)

local state = {
    combatSet = nil,
};

profile.OnLoad = function()
    -- gSettings.AllowAddSet = true;
    state.combatSet = Utils.SetSelector.new("Combat", "p", profile.Sets);
    state.combatSet:addSet("set1", "Thing1");
    state.combatSet:addSet("set2", "Thing2");
    state.combatSet:addSet("override1", "Override1");

    state.combatSet:use("set1");

    Ui.onProfileLoad({
        selectors = {
            state.combatSet,
        }
    });

    events.onProfileLoad();
    local mjoblvl = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    gFunc.EvaluateLevels(sets, mjoblvl)
    events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl);
    end)
end

profile.OnUnload = function()
    events.onProfileUnload();
    Ui.onProfileUnload();
end

profile.HandleCommand = function(args)
    Ui.onSlashCommand(args);
end

profile.HandleDefault = function()
    local layers = T {};
    local target = gData.GetTarget()
    if target ~= nil and target.Id % 2 > 0 then
        state.combatSet:override("override1");
    else
        state.combatSet:override();
    end

    local player = gData.GetPlayer();
    if player.Status == "Resting" then
        layers:append(sets.Resting);
    elseif player.Status == "Engaged" then
        layers:append(sets.TP);
    else
        layers:append(sets.Idle);
    end

    local finalSet = Utils.compress_tables(layers:unpack());
    gFunc.EquipSet(Xi.excludeUsableEquippedItems(finalSet));
end

profile.HandleAbility = function()
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
end

profile.HandleMidcast = function()
    local action = gData.GetAction();
    ---@cast action -?

    local spell = Magic.BlueMagic[action.Name];

    local setName = "MA_" .. action.Name;
    if sets[setName] ~= nil then
        gFunc.EquipSet(sets[setName])
    end
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
