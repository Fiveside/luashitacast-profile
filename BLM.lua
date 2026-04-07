local Utils = gFunc.LoadFile("util");
local getZoneSet = gFunc.LoadFile("town");

local profile = {};
local sets = T{};
sets.Idle = T{
    -- Main = {"Solid Wand", "Yew Wand +1", "Willow wand +1", "Maple Wand"},
    -- Sub = {"Solid wand", "Yew Wand +1"},
    Head = "Displaced",
    -- Body = "Black Cloak",
    Body = "Sorcerer's Coat",
}
    
sets.Resting_Priority = T{
    Main = {"Dark Staff", "Pilgrim's Wand"},
    Body = {"Errant Hpl.", "Black cloak", "Seer's Tunic"},
    Legs = {"Baron's slops"},
}
    
sets.ElementalMagic = T{
    Head = "Wizard's Petasos",
    Body = "Igqira weskit",
    -- Body = "Black Cotehardie",
    -- Body = "Black Cloak",
    -- Legs = "Seer's slacks +1",
    Legs = "Errant slops",
}

sets.DarkMagic = Utils.compress_tables(sets.ElementalMagic, T{
    -- Body = "Black Cotehardie",
    Main = "Dark staff",
    Legs = "Wizard's tonban",
});

local state = {
    syncedLevel = 0,
};
profile.Sets = sets;

profile.Packer = {
};

profile.OnLoad = function()
    gSettings.AllowAddSet = false;
end

profile.OnUnload = function()
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
    local layers = T{};
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
    local layers = T{};
    local action = gData.GetAction();
    local me = gData.GetPlayer();
    local env = gData.GetEnvironment();

    if action.Skill == 'Dark Magic' then
        layers:append(sets.DarkMagic)
    elseif action.Skill == 'Elemental Magic' then
        layers:append(sets.ElementalMagic)
    end

    local element = gData.GetAction().Element;
    local staff = nil;
    -- print("Action[" .. action.Id  .. "]: " .. action.Name .. ' ' .. action.Skill .. ' / ' .. element);
    if (element == 'Thunder') then
        staff = "Jupiter's staff";
    elseif (element == 'Fire') then
        staff = 'Fire staff';
    elseif (element == 'Ice') then
        staff = "Aquilo's staff";
    elseif (element == 'Wind') then
        staff = 'Wind staff';
    elseif (element == 'Water') then
        staff = 'Water staff';
    elseif (element == 'Earth') then
        staff = 'Earth staff';
    elseif (element == 'Dark') then
        staff = 'Dark staff';
    end

    if (staff ~= nil) then
        layers:append(T{ Main = staff })
    end

    if action.Name == 'Drain' or action.Name == 'Aspir' then
        layers:append(getDrainSet());
    end

    if action.Element == env.DayElement then
        layers:append({ Legs = "Sorcerer's Tonban" })
    end

    if me.MPP < 50 then
        layers:append({ Neck = "Uggalepih Pendant" })
    else
        layers:append({ Neck = "Philomath Stole" })
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

local DOWNCAST_MAP = T{
    ['Thunder IV'] = 'Thunder III',
    ['Thunder III'] = 'Thunder II',
    ['Thunder II'] = 'Thunder',

    ['Blizzard IV'] = 'Blizzard III',
    ['Blizzard III'] = 'Blizzard II',
    ['Blizzard II'] = 'Blizzard',

    ['Fire IV'] = 'Fire III',
    ['Fire III'] = 'Fire II',
    ['Fire II'] = 'Fire',

}

function canCast(spell)
    -- local spell = AshitaCore:GetResourceManager():GetSpellByName(spellName);
    -- if (spell == nil) then
    --     return false;
    -- end
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local mainJobLevelReq = spell.LevelRequired[player:GetMainJob() + 1];
    if  (mainJobLevelReq == -1 or mainJobLevelReq > player:GetMainJobLevel()) then
        return false;
    end

    -- TODO: Check to see if the player knows the spell.
    -- TODO: Check to see if the player's subjob knows the spell.
    -- TODO: Spells that come from Job Points (not sure if I wanna bother?)
    return true;
end

function downCast(spellName)
    local rm = AshitaCore:GetResourceManager();
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local spell = rm:GetSpellByName(spellName, 0);
    local mainJobLevelReq = spell.LevelRequired[player:GetMainJob() + 1];
    -- local subJobLevelReq = spell.LevelRequired[player.GetSubJobLevel() + 1];
    
    print("asdf " .. mainJobLevelReq .. " " .. player:GetMainJobLevel());
    while true do
        if canCast(spell) then
            AshitaCore:GetChatManager():QueueCommand(1, '/echo /ma "' .. spellName .. '" <t>')
            return;
        else
            spellName = DOWNCAST_MAP[spellName];
            if (spellName == nil) then
                print("Error: No candidate");
                return;
            end
        end
    end
    -- if (mainJobLevelReq > -1 and mainJobLevelReq < player:GetMainJobLevel()) then
    --     -- do the thing!
    --     print("TRying ".. spellName)
    -- else
    --     print("nah")
    -- end
end

local ELEMENT_STAFF = T{
    Thunder = "Thunder staff",
    Ice = "Aquilo's staff"
}

function getElementalStaffSet(element)

end

function getDrainSet()
    local env = gData.GetEnvironment()
    local weather = env.Weather
    if weather == 'Dark' or weather == 'Dark x2' then
        return {
            Main = "Diabolos's Pole"
        }
    else
        return {}
    end
end

return profile;