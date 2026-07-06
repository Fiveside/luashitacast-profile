
---@module 'types'

local Utils = gFunc.LoadFile("util");
local getZoneSet = gFunc.LoadFile("town");
local Idle = gFunc.LoadFile("idle");
local Events = gFunc.LoadFile("services/events");
local Skillchains = gFunc.LoadFile("services/skillchain");

local profile = {};
local sets = T {};
sets.Idle = T {
    Body = "Sorcerer's Coat",
};

---@type PriorityGearSet
sets.Resting_Priority = T {
    Main = { "Pluto's Staff", "Pilgrim's Wand" },
    Body = { "Errant Hpl.", "Black cloak", "Seer's Tunic" },
    Legs = { "Baron's slops" },
};

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
    Head = "Wizard's Petasos",
    Neck = "Philomath Stole",
    Ear1 = "Moldavite Earring",
    Ear2 = "Morion Earring",
    Body = "Igqira weskit",
    Hands = "Wizard's gloves",
    Ring1 = "Snow Ring",
    Ring2 = "Snow Ring",
    -- Body = "Black Cotehardie",
    -- Body = "Black Cloak",
    -- Legs = "Seer's Slacks +1",
    Back = "Red Cape +1",
    Waist = "Penitent's Rope",
    Legs = "Errant slops",
    Feet = "Rostrum Pumps",
};

---@type GearSet
sets.ElementalMagic = Utils.compress_tables(sets.MagicAttack, T {
    Body = "Sorcerer's Coat",
    Hands = "Wizard's Gloves",
    Back = "Merciful Cape",
});

---@type GearSet
sets.EnfeeblingMagic = Utils.compress_tables(sets.MagicAttack, T {
    Body = "Wizard's Coat",
});

---@type GearSet
sets.DarkMagic = Utils.compress_tables(sets.MagicAttack, T {
    Main = "Dark staff",
    Hands = "Sorcerer's Gloves",
    Legs = "Wizard's tonban",
    Back = "Merciful Cape",
});

---@type GearSet
sets.EnhancingMagic = Utils.compress_tables(sets.MagicAttack, T {
    Back = "Merciful Cape",
});

-- A list of gear that only gets equipped while the magic burst window is open on the target
---@type GearSet
sets.MagicBurst = T {
    Hands = "Sorcerer's Gloves",
};

-- Specific gear for job actions, spells, and weapon skills
---@type GearSet
sets.MA_Sneak = T {
    Feet = "Dream Boots +1",
};

sets.MA_Invisible = T {
    Hands = "Dream Mittens +1"
};

-- A map from an element to the appropriate staff
local ELEMENT_STAFF = T {
    Thunder = "Jupiter's staff",
    Fire = "Vulcan's staff",
    Ice = "Aquilo's staff",
    Wind = "Auster's staff",
    Water = "Neptune's staff",
    Earth = 'Earth staff',
    Dark = "Pluto's staff",
};

-- A map from an element to the appropriate obi.
local ELEMENT_OBI = T {
    Ice = "Hyorin Obi",
    Dark = "Anrin Obi",
};

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
        local isDarksday = gData.GetEnvironment().DayElement == 'Dark';
        local isDarkMagic = gData.GetAction().Skill == 'Dark Magic';
        return isDarksday and isDarkMagic and mpWithinRange;
    end,

    [T { Neck = "Uggalepih Pendant" }] = function()
        local action = gData.GetAction();
        local me = gData.GetPlayer();

        -- The mp threshold calculation conditions are actually somewhat intricate, but
        -- a straight 50% check covers 99.9% of cases.  Good enough.
        -- Include drain and aspir since those use magic attack
        local isDarkAttack = action.Name == 'Drain' or action.Name == 'Aspir';
        return me.MPP < 50 and (action.Skill == 'ElementalMagic' or isDarkAttack);
    end,

    [T { Main = "Diabolos's Pole" }] = function()
        local actionName = gData.GetAction().Name;
        if actionName ~= 'Drain' and actionName ~= 'Aspir' then
            return false;
        end
        local weather = gData.GetEnvironment().Weather;
        return weather == 'Dark' or weather == 'Dark x2';
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

    events = nil;
};
profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;

    state.events = Events.new();
    state.events:install();
    Skillchains.install(state.events);
    
    state.events:on(Events.MAGIC_BURST_WINDOW_OPEN, onMagicBurstWindowOpen);
end

profile.OnUnload = function()
    state.events:uninstall();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    if (myLevel ~= state.syncedLevel) then
        state.syncedLevel = myLevel;
        gFunc.EvaluateLevels(sets, myLevel);
        -- gFunc.EvaluateLevels(JA_sets, myLevel);
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
end

profile.HandleMidcast = function()
    local layers = T {};
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    local me = gData.GetPlayer();
    -- local me = gData.GetPlayer();
    -- local env = gData.GetEnvironment();

    layers:append(sets.Midcast);

    -- Apply different specialty sets if we're casting on something other than ourself.
    -- This 
    if target.Name ~= me.Name and target.Type ~= 'PC' then
        if FORCED_ELEMENTAL_SPELLS:contains(action.Name) then
            layers:append(sets.ElementalMagic);
        elseif action.Skill == 'Dark Magic' then
            layers:append(sets.DarkMagic)
        elseif action.Skill == 'Elemental Magic' then
            layers:append(sets.MagicAttack)
        elseif action.Skill == 'Enfeebling Magic' then
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
    local spellSpecificSet = sets['MA_' .. action.Name];
    if spellSpecificSet ~= nil then
        layers:append(spellSpecificSet);
    end

    -- If a burst window is open, equip that set too.
    local window = Skillchains.getActiveBurstWindow(gData.GetActionTarget().Id);
    if window ~= nil and window.elements:contains(action.Element) then
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


---@alias Element
---| '"Thunder"'
---| '"Ice"'
---| '"Fire"'
---| '"Wind"'
---| '"Water"'
---| '"Earth"'
---| '"Dark"'
---| '"Light"'


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
---@param element Element Element of the spell being cast.
---@param dayElement Element Element of the current day.
---@param weatherElement Element Element of any extreme weather phenomenon.
---@param weatherx2 boolean True if we're experiencing double weather.
---@return integer score The multiplier
function getElementEnvBonus(element, dayElement, weatherElement, weatherx2)
    local score = 0;

    -- Add day bonus/penalty.
    if element == dayElement then
        score = score + 0.1;
    elseif ELEMENTAL_WEAKNESS[dayElement] == element then
        score = score - 0.1;
    end

    -- double weather gives +25%
    local weatherBonus = 0.1
    if weatherx2 then
        weatherBonus = 0.25
    end

    if element == weatherElement then
        score = score + weatherBonus;
    elseif ELEMENTAL_WEAKNESS[element] == weatherElement then
        score = score + (weatherBonus * -1);
    end

    return score;
end

---Returns a set with staff and obi appropriate for the current cast
---@return table The gear set in question
function getSpellEnvSet()
    local action = gData.GetAction();
    local env = gData.GetEnvironment();

    local envMult = getElementEnvBonus(action.Element, env.DayElement, env.WeatherElement, env.Weather:endswith('x2'));

    local set = {};
    if ELEMENT_STAFF[action.Element] ~= nil then
        set.Main = ELEMENT_STAFF[action.Element];
        set.Sub = "displaced";
    end

    if envMult > 0 and ELEMENT_OBI[action.Element] ~= nil then
        set.Waist = ELEMENT_OBI[action.Element];
    end
    return set;
end

function onMagicBurstWindowOpen(events, who, chain, elements)
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    if action == nil then
        return;
    end

    if target.Id == who and elements:contains(action.Element) then
        gFunc.EquipSet(sets.MagicBurst);
    end
end

return profile;
