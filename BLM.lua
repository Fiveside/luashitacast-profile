---@module 'types'

local Utils = require("util");
local getZoneSet = require("town");
local Shared = require("shared");
local CommonSets = require("common_sets");
local Bursts = require("bursts");
local events = require("events");
local ui = require("ui");
local SetBuilder = require('setbuilder')
local JSE = CommonSets.JSE;

---@type LAC.Profile
local profile = {
    Sets = T {},
    Packer = T {},
};
local sets = profile.Sets;

sets.AutoRefresh = T {
    Body = JSE.BLM.Relic.Body,
};

sets.Resting = T {
    Main = Shared.getElementalStaff:bind1("Dark"),
    Body = "Errant Hpl.",
    Waist = "Qiqirn Sash +1",
    Legs = "Baron's slops",
    Ear1 = "Relaxing Earring",
};

sets.Precast = T {
    Ear1 = "Loquac. Earring",
    Feet = "Rostrum Pumps",
};

-- This set is the base set overridden by other more specialized sets
-- This should mainly include haste gear to reduce cooldown timers,
-- and Conserve MP gear.
sets.Midcast = T {
    Hands = "Nashira Gages",
    Waist = "Swift Belt",
    Legs = "Nashira Seraweels",
};

-- This set should be considered the default set.
sets.MagicAttack = T {
    Ammo = "Phtm. Tathlum",
    Head = JSE.BLM.RelicPlus1.Head,
    -- Head = JSE.BLM.Artifact.Head,
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
    Waist = "Sorcerer's Belt",
    Legs = "Errant slops",
    -- Legs = "Seer's Slacks +1",
    -- Legs = "Wizard's Tonban",
    Feet = "Rostrum Pumps",
    -- Feet = "Wizard's Sabots",
};

-- Maximizes -Enmity
sets.MinusEnmity = T {
    Head = JSE.BLM.Artifact.Head,
    Body = "Hydra Doublet",
    Hands = JSE.BLM.RelicPlus1.Hands,
    Waist = "Penitent's Rope",
    Legs = JSE.BLM.Relic.Legs,
    Feet = JSE.BLM.Artifact.Feet,
};

-- Maximizes +Elemental Magic Skill
sets.ElementalMagic = T {
    Head = JSE.BLM.RelicPlus1.Head,
    Body = JSE.BLM.Relic.Body,
    Hands = JSE.BLM.Artifact.Hands,
    Back = "Merciful Cape",
};

-- Maximizes +Enfeebling Magic Skill
sets.EnfeeblingMagic = T {
    Head = JSE.BLM.RelicPlus1.Head,
    Body = JSE.BLM.Artifact.Body,
    Back = "Altruistic Cape",
    Legs = "Nashira Seraweels",
};

-- Maximizes +Dark Magic Skill
sets.DarkMagic = T {
    Main = Shared.getElementalStaff:bind1("Dark"),
    Hands = JSE.BLM.RelicPlus1.Hands,
    Legs = "Wizard's Tonban",
    Back = "Merciful Cape",
};

-- Maximizes +Enhancing Magic Skill
sets.EnhancingMagic = T {
    Back = "Merciful Cape",
};

-- A list of gear that only gets equipped while the magic burst window is open on the target
sets.MagicBurst = T {
    Hands = JSE.BLM.RelicPlus1.Hands,
};


-------------------------
-- Spell specific gear
-------------------------

-- Maximizes MND.
sets.MA_Stoneskin = T {
    --TODO: find room for kirin's pole in wardrobes
    Main = Shared.getElementalStaff:bind1("Water"),
    Sub = "Bugard Strap +1",
    Body = "Kirin's Osode",
    Neck = "Faith Torque",
    Hands = "Savage Gauntlets",
    Waist = "Penitent's Rope",
    Back = "Red Cape +1",
    Legs = "Errant Slops",
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
        return me.MPP < 50 and action.Skill == "Elemental Magic";
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
    -- Used to handle magic burst switching
    currentSpell = nil,
    currentTargetId = nil,
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

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
    events.onProfileLoad();
    events.skillchain:on(onSkillchain);
    events.mainJobChange:on(function(job, lvl)
        gFunc.EvaluateLevels(sets, lvl);
    end);
    gFunc.EvaluateLevels(sets, gData.GetPlayer().MainJobLevel);

    ui.onProfileLoad()
end

profile.OnUnload = function()
    ui.onProfileUnload();
    events.onProfileUnload();
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local layers = SetBuilder:new();
    layers:add(Shared.autoRegen:getSet());
    layers:add(Shared.autoRefresh:getSet(sets.AutoRefresh));
    layers:add(getZoneSet());

    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        layers:add(sets.Resting);
    end

    gFunc.EquipSet(layers:finalize());
end

profile.HandleAbility = function()
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
    gFunc.EquipSet(SetBuilder.resolveLazy(sets.Precast));
end

profile.HandleMidcast = function()
    local layers = SetBuilder:new();
    local action = gData.GetAction();
    local target = gData.GetActionTarget();
    local me = gData.GetPlayer();

    ---@cast target -?
    ---@cast action -?

    layers:add(sets.Midcast);

    if target.Type ~= "PC" then
        if FORCED_ELEMENTAL_SPELLS:contains(action.Name) then
            layers:add(sets.ElementalMagic);
        elseif action.Skill == "Dark Magic" then
            layers:add(sets.DarkMagic)
        elseif action.Skill == "Elemental Magic" then
            layers:add(sets.MagicAttack)
        elseif action.Skill == "Enfeebling Magic" then
            layers:add(sets.EnfeeblingMagic)
        end
    end

    -- Staff and Obi set.
    layers:add(T {
        Main = Shared.getElementalStaff(),
        Sub = "Bugard Strap +1",
        Waist = Shared.getElementalObi(),
    });

    -- Sets with complex activation conditions.
    for conditionalSet, condition in pairs(CONDITIONAL_GEAR) do
        if condition() then
            layers:add(conditionalSet)
        end
    end

    -- Sets that only apply to one spell.
    local spellSpecificSet = sets["MA_" .. action.Name];
    if spellSpecificSet ~= nil then
        layers:add(spellSpecificSet);
    end

    -- If a burst window is open, equip that set too.
    local chain = Bursts.getSkillchain(gData.GetActionTarget().Id);
    if chain ~= nil and chain.Elements:contains(action.Element) then
        layers:add(sets.MagicBurst);
    end

    gFunc.EquipSet(layers:finalize());
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
