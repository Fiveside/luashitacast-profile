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
    -- Legs = "Seer's slacks +1",
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

});

sets.DarkMagic = Utils.compress_tables(sets.MagicAttack, T {
    -- Body = "Black Cotehardie",
    Main = "Dark staff",
    Legs = "Wizard's tonban",
});

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
    end
};

-- A map from an element to the appropriate obi.
local ELEMENT_OBI = T {
    Ice = "Hyorin Obi",
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
    -- print(T(args):slice(2, #args-1):join('|'))
    if args[1] == 'stepdown' then
        local spellName = T(args):slice(2, #args - 1):join(" ");
        downCast(spellName)
    end
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
    -- local me = gData.GetPlayer();
    -- local env = gData.GetEnvironment();

    if action.Skill == 'Dark Magic' then
        layers:append(sets.DarkMagic)
    elseif action.Skill == 'Elemental Magic' then
        layers:append(sets.MagicAttack)
    end

    -- local element = gData.GetAction().Element;
    -- local staff = ELEMENT_STAFF[element];

    -- if (staff ~= nil) then
    --     layers:append(T { Main = staff })
    -- end
    layers:append(getSpellEnvSet());

    for conditionalSet, condition in pairs(CONDITIONAL_GEAR) do
        if condition() then
            layers:append(conditionalSet)
        end
    end

    if (#layers > 0) then
        gFunc.EquipSet(Utils.compress_tables(layers:unpack()));
    end
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

-- local DOWNCAST_MAP = T{
--     ['Thunder IV'] = 'Thunder III',
--     ['Thunder III'] = 'Thunder II',
--     ['Thunder II'] = 'Thunder',

--     ['Blizzard IV'] = 'Blizzard III',
--     ['Blizzard III'] = 'Blizzard II',
--     ['Blizzard II'] = 'Blizzard',

--     ['Fire IV'] = 'Fire III',
--     ['Fire III'] = 'Fire II',
--     ['Fire II'] = 'Fire',

-- }

-- function canCast(spell)
--     -- local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName);
--     -- if (spell == nil) then
--     --     return false;
--     -- end
--     local player = AshitaCore:GetMemoryManager():GetPlayer();
--     local mainJobLevelReq = spell.LevelRequired[player:GetMainJob() + 1];
--     if  (mainJobLevelReq == -1 or mainJobLevelReq > player:GetMainJobLevel()) then
--         return false;
--     end

--     -- TODO: Check to see if the player knows the spell.
--     -- TODO: Check to see if the player's subjob knows the spell.
--     -- TODO: Spells that come from Job Points (not sure if I wanna bother?)
--     return true;
-- end

-- function downCast(spellName)
--     local rm = AshitaCore:GetResourceManager();
--     local player = AshitaCore:GetMemoryManager():GetPlayer();
--     local spell = rm:GetSpellByName(spellName, 0);
--     local mainJobLevelReq = spell.LevelRequired[player:GetMainJob() + 1];
--     -- local subJobLevelReq = spell.LevelRequired[player.GetSubJobLevel() + 1];

--     print("asdf " .. mainJobLevelReq .. " " .. player:GetMainJobLevel());
--     while true do
--         if canCast(spell) then
--             AshitaCore:GetChatManager():QueueCommand(1, '/echo /ma "' .. spellName .. '" <t>')
--             return;
--         else
--             spellName = DOWNCAST_MAP[spellName];
--             if (spellName == nil) then
--                 print("Error: No candidate");
--                 return;
--             end
--         end
--     end
--     -- if (mainJobLevelReq > -1 and mainJobLevelReq < player:GetMainJobLevel()) then
--     --     -- do the thing!
--     --     print("TRying ".. spellName)
--     -- else
--     --     print("nah")
--     -- end
-- end



function getElementalStaffSet()
    local action = gFunc.GetAction()
    local element = action.Element
    local staff = ELEMENT_STAFF[element];
    if staff ~= nil then
        return { Main = staff };
    end
    return {};
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
