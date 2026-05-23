local Utils = gFunc.LoadFile("util");
local getZoneSet = gFunc.LoadFile("town");
local Idle = gFunc.LoadFile("idle");
local BattlePacket = gFunc.LoadFile("battle_packet");

local profile = {};
local sets = T {};
sets.Idle = T {
    -- Main = {"Solid Wand", "Yew Wand +1", "Willow wand +1", "Maple Wand"},
    -- Sub = {"Solid wand", "Yew Wand +1"},
    -- Head = "Displaced",
    -- Body = "Black Cloak",
    Body = "Sorcerer's Coat",
};

sets.Resting_Priority = T {
    Main = { "Pluto's Staff", "Pilgrim's Wand" },
    Body = { "Errant Hpl.", "Black cloak", "Seer's Tunic" },
    Legs = { "Baron's slops" },
};

-- This set is the base set overridden by other more specialized sets
-- This should mainly include haste gear to reduce cooldown timers.
-- Really this only applys to spells targeting the player.
sets.Midcast = T {
    Waist = "Swift Belt",
};

-- This set should be considered the default set.
sets.MagicAttack = T {
    Head = "Wizard's Petasos",
    Neck = "Philomath Stole",
    Ear1 = "Moldavite Earring",
    Ear2 = "Morion Earring",
    Body = "Igqira weskit",
    Hands = "Wizard's gloves",
    Ring1 = "Genius Ring",
    Ring2 = "Genius Ring",
    -- Body = "Black Cotehardie",
    -- Body = "Black Cloak",
    -- Legs = "Seer's Slacks +1",
    Back = "Red Cape +1",
    Waist = "Penitent's Rope",
    Legs = "Errant slops",
    Feet = "Rostrum Pumps",
};

sets.ElementalMagic = Utils.compress_tables(sets.MagicAttack, T {
    Body = "Sorcerer's Coat",
    Hands = "Wizard's Gloves",
});

sets.EnfeeblingMagic = Utils.compress_tables(sets.MagicAttack, T {
    Body = "Wizard's Coat",
});

sets.DarkMagic = Utils.compress_tables(sets.MagicAttack, T {
    Main = "Dark staff",
    Legs = "Wizard's tonban",
});

-- A list of gear that only gets equipped while the magic burst window is open on the target
sets.MagicBurst = T {

};

-- A map from an element to the appropriate staff
local ELEMENT_STAFF = T {
    Thunder = "Jupiter's staff",
    Fire = "Vulcan's staff",
    Ice = "Aquilo's staff",
    Wind = 'Wind staff',
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
        return me.MPP < 50 and action.Skill == 'ElementalMagic';
    end,

    [T { Main = "Diabolos's Pole" }] = function()
        local actionName = gData.GetAction().Name;
        if actionName ~= 'Drain' and actionName ~= 'Aspir' then
            return false;
        end
        local weather = gData.GetEnvironment().Weather;
        return weather == 'Dark' or weather == 'Dark x2';
    end,

    [T { Feet = "Dream Boots +1" }] = function()
        local actionName = gData.GetAction().Name;
        return actionName == 'Sneak';
    end,

    [T { Hands = "Dream Mittens +1" }] = function()
        local actionName = gData.GetAction().Name;
        return actionName == 'Invisible';
    end,
};

-- A list of spells that we should ignore the active set for
-- Instead, these will use the ElementalMagic set.
local FORCED_ELEMENTAL_SPELLS = T {
    "Burn", "Frost", "Choke", "Rasp", "Shock", "Drown",
};

local state = {
    syncedLevel = 0,
};
profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;

    ashita.events.register("packet_in", "lac_profile_packet_handler_0x28", function(e)
        if not BattlePacket.is_possible_skillchain_event(e) then
            return;
        end

        -- todo: detect skillchain and equip sorc gloves if we're in the middle of casting a burst on the target.
        local pkt = BattlePacket.parse_incomming_event(e);
    end);
end

profile.OnUnload = function()
    ashita.events.unregister("packet_in", "lac_profile_packet_handler_0x28");
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

    layers:append(getSpellEnvSet());

    for conditionalSet, condition in pairs(CONDITIONAL_GEAR) do
        if condition() then
            layers:append(conditionalSet)
        end
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

return profile;
