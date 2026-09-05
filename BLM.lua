---@module 'types'

local Utils = gFunc.LoadFile("util");
local getZoneSet = gFunc.LoadFile("town");
local Idle = gFunc.LoadFile("idle");
local CommonSets = gFunc.LoadFile("common_sets");
local Bursts = gFunc.LoadFile("bursts");
local events = gFunc.LoadFile("events");
local ui = gFunc.LoadFile("ui");
local JSE = CommonSets.JSE;

-- A map from an element to the appropriate staff
local ELEMENT_STAFF = T {
    Thunder = "Jupiter's staff",
    Fire = "Vulcan's staff",
    Ice = "Aquilo's staff",
    Wind = "Auster's staff",
    Water = "Neptune's staff",
    Earth = "Earth staff",
    Dark = "Pluto's staff",
};

-- A map from an element to the appropriate obi.
local ELEMENT_OBI = T {
    Ice = "Hyorin Obi",
    Dark = "Anrin Obi",
};

local profile = {};
local sets = T {};
sets.Idle = T {
    Body = "Sorcerer's Coat",
};

---@type PriorityGearSet
sets.Resting_Priority = T {
    Main = { ELEMENT_STAFF.Dark, "Pilgrim's Wand" },
    Body = { "Errant Hpl.", "Seer's Tunic" },
    Waist = { "Qiqirn Sash +1" },
    Legs = { "Baron's slops" },
    Ear1 = { "Relaxing Earring" },
};

sets.Precast = T {
    Ear1 = "Loquac. Earring",
}

-- This set is the base set overridden by other more specialized sets
-- This should mainly include haste gear to reduce cooldown timers.
-- Really this only applys to spells targeting the player.
---@type GearSet
sets.Midcast = T {
    Waist = "Swift Belt",
};

-- This set should be considered the default set.
---@type GearSet
sets.MagicAttack = T {
    Ammo = "Phtm. Tathlum",
    Head = JSE.BLM.RelicPlus1.Head,
    Neck = "Philomath Stole",
    Ear1 = "Moldavite Earring",
    Ear2 = "Morion Earring",
    Body = "Igqira weskit",
    -- Body = "Black Cotehardie",
    -- Hands = "Wizard's gloves",
    Hands = "Zenith Mitts",
    Ring1 = "Snow Ring",
    Ring2 = "Snow Ring",
    -- Ring1 = "Kshama Ring No.5",
    -- Ring2 = "Windurstian Ring",
    Back = "Red Cape +1",
    Waist = "Penitent's Rope",
    Legs = "Errant slops",
    -- Legs = "Seer's Slacks +1",
    -- Legs = "Wizard's Tonban",
    Feet = "Rostrum Pumps",
    -- Feet = "Wizard's Sabots",
};

---@type GearSet
sets.ElementalMagic = Utils.compress_tables(sets.MagicAttack, T {
    Head = JSE.BLM.RelicPlus1.Head,
    Body = JSE.BLM.Relic.Body,
    Hands = JSE.BLM.Artifact.Hands,
    Back = "Merciful Cape",
});

---@type GearSet
sets.EnfeeblingMagic = Utils.compress_tables(sets.MagicAttack, T {
    Head = JSE.BLM.RelicPlus1.Head,
    Body = JSE.BLM.Artifact.Body,
    Back = "Altruistic Cape",
});

---@type GearSet
sets.DarkMagic = Utils.compress_tables(sets.MagicAttack, T {
    Main = ELEMENT_STAFF.Dark,
    Hands = JSE.BLM.RelicPlus1.Hands,
    Legs = "Wizard's Tonban",
    Back = "Merciful Cape",
});

---@type GearSet
sets.EnhancingMagic = Utils.compress_tables(sets.MagicAttack, T {
    Back = "Merciful Cape",
});

-- A list of gear that only gets equipped while the magic burst window is open on the target
---@type GearSet
sets.MagicBurst = T {
    Hands = JSE.BLM.RelicPlus1.Hands,
};


-------------------------
-- Spell specific gear
-------------------------

-- Maximizes MND.
sets.MA_Stoneskin = T {
    Body = "Kirin's Osode",
    Neck = "Faith Torque",
    Hands = "Savage Gauntlets",
    Waist = "Penitent's Rope",
    Back = "Red Cape +1",
    Feet = "Rostrum Pumps",
}

-- Specific gear for job actions, spells, and weapon skills
CommonSets.applyCommonMagicSets(sets);

---Specific gear along with functions that return true when they it should be equipped
---Equip happens during midcast
local CONDITIONAL_GEAR = T {
    [T { Legs = "Sorcerer's Tonban" }] = function()
        local action = gData.GetAction()
        local env = gData.GetEnvironment()
        return action.Element == env.DayElement;
    end,

    [T { Ring2 = "Diabolos's Ring" }] = function()
        -- The ring adds -15% mp, which sucks.  So only do this if our mp is already low.
        local me = gData.GetPlayer();
        local mpWithinRange = me.MPP < 85;
        local isDarksday = gData.GetEnvironment().DayElement == "Dark";
        local isDarkMagic = gData.GetAction().Skill == "Dark Magic";
        return isDarksday and isDarkMagic and mpWithinRange;
    end,

    [T { Neck = "Uggalepih Pendant" }] = function()
        local action = gData.GetAction();
        local me = gData.GetPlayer();

        -- The mp threshold calculation conditions are actually somewhat intricate, but
        -- a straight 50% check covers 99.9% of cases.  Good enough.
        return me.MPP < 50 and action.Skill == "ElementalMagic";
    end,

    [T { Main = "Diabolos's Pole" }] = function()
        local actionName = gData.GetAction().Name;
        if actionName ~= "Drain" and actionName ~= "Aspir" then
            return false;
        end
        local weather = gData.GetEnvironment().Weather;
        return weather == "Dark" or weather == "Dark x2";
    end,

};

-- A list of spells that we should ignore the active set for
-- Instead, these will use the ElementalMagic set.
local FORCED_ELEMENTAL_SPELLS = T {
    "Burn", "Frost", "Choke", "Rasp", "Shock", "Drown",
};

local state = {
    -- to redo _Priority sets
    syncedLevel = 0,

    -- Used to handle magic burst switching
    currentSpell = nil,
    currentTargetId = nil,

};
profile.Sets = sets;

profile.Packer = {
};

local function onSkillchain(targetId, chainInfo)
    -- This is called when a skillchain appears nearby
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    if action == nil or target == nil then
        return;
    end
    if target.Id ~= targetId then
        return;
    end

    -- we are currently casting on the target that the skillchain occurred on.
    -- perform emergency gear swap outside of normal midcast callback.
    -- We need to use ForceEquipSet because normal EquipSet is tied to the
    -- LAC managed profile lifecycle. If you call EquipSet outside of a
    -- lifecycle call, it doesn't do anything.
    if chainInfo.Elements:contains(action.Element) then
        gFunc.ForceEquipSet(sets.MagicBurst);
    end
end

-- Maps an element with the element it is weak to
---@type { [Element]: Element}
local ELEMENTAL_WEAKNESS = T {
    Thunder = "Earth",
    Ice = "Fire",
    Fire = "Water",
    Wind = "Ice",
    Water = "Thunder",
    Earth = "Wind",
    Dark = "Light",
    Light = "Dark",
};

--[[
    Spells gain the following potency for affinities:
    10% for magic of the day
    10% for magic matching single weather
    20% for magic matching single weather and day
    25% for magic matching double weather
    35% for magic matching double weather and day
]]


---Calculate and return the multiplier for the current spell based on day and weather
local function getElementEnvBonus(element, dayElement, weatherElement, weatherx2)
    local action = gData.GetAction();
    local env = gData.GetEnvironment();

    local score = 0;

    -- Add day bonus/penalty.
    if action.Element == env.DayElement then
        score = score + 0.1;
    elseif ELEMENTAL_WEAKNESS[env.DayElement] == action.Element then
        score = score - 0.1;
    end

    -- double weather gives +25%
    local weatherBonus = 0.1
    if env.Weather:endswith("x2") then
        weatherBonus = 0.25
    end

    if action.Element == env.WeatherElement then
        score = score + weatherBonus;
    elseif ELEMENTAL_WEAKNESS[action.Element] == env.WeatherElement then
        score = score + (weatherBonus * -1);
    end

    return score;
end

---Returns a set with staff and obi appropriate for the current cast
---@return table The gear set in question
local function getSpellEnvSet()
    local action = gData.GetAction();

    local envMult = getElementEnvBonus();

    local set = {};
    if ELEMENT_STAFF[action.Element] ~= nil then
        set.Main = ELEMENT_STAFF[action.Element];
        set.Sub = "Bugard Strap +1";
    end

    if envMult > 0 and ELEMENT_OBI[action.Element] ~= nil then
        set.Waist = ELEMENT_OBI[action.Element];
    end
    return set;
end

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    -- Bursts.onProfileLoad();
    -- ashita.events.register('packet_in', 'lac_profile_packet_in', function(pkt)
    --     Bursts.onPacketIn(pkt);
    -- end)
    events.onProfileLoad();
    events.skillchain:on(onSkillchain);

    ui.onProfileLoad()
end

profile.OnUnload = function()
    ui.onProfileUnload();
    events.onProfileUnload();
    -- ashita.events.unregister('packet_in', 'lac_profile_packet_in');
    -- Bursts.onProfileUnload();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel;
        gFunc.EvaluateLevels(sets, myLevel);
    end
    local layers = T {};
    layers:append(sets.Idle);
    layers:append(getZoneSet());

    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        layers:append(sets.Resting);
    end

    gFunc.EquipSet(Utils.compress_tables(layers:unpack()));
end

profile.HandleAbility = function()
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
    gFunc.EquipSet(sets.Precast);
end

profile.HandleMidcast = function()
    local layers = T {};
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    local me = gData.GetPlayer();

    ---@cast target -?
    ---@cast action -?

    layers:append(sets.Midcast);

    -- Apply different specialty sets if we're casting on something other than ourself.
    -- This
    if target.Name ~= me.Name and target.Type ~= "PC" then
        if FORCED_ELEMENTAL_SPELLS:contains(action.Name) then
            layers:append(sets.ElementalMagic);
        elseif action.Skill == "Dark Magic" then
            layers:append(sets.DarkMagic)
        elseif action.Skill == "Elemental Magic" then
            layers:append(sets.MagicAttack)
        elseif action.Skill == "Enfeebling Magic" then
            layers:append(sets.EnfeeblingMagic)
        end
    end

    -- Staff and Obi set.
    layers:append(getSpellEnvSet());

    -- Sets with complex activation conditions.
    for conditionalSet, condition in pairs(CONDITIONAL_GEAR) do
        if condition() then
            layers:append(conditionalSet)
        end
    end

    -- Sets that only apply to one spell.
    local spellSpecificSet = sets["MA_" .. action.Name];
    if spellSpecificSet ~= nil then
        layers:append(spellSpecificSet);
    end

    -- If a burst window is open, equip that set too.
    local chain = Bursts.getSkillchain(gData.GetActionTarget().Id);
    if chain ~= nil and chain.Elements:contains(action.Element) then
        layers:append(sets.MagicBurst);
    end

    gFunc.EquipSet(Utils.compress_tables(layers:unpack()));
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
