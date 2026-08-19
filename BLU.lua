local Ui = gFunc.LoadFile('ui');
local Utils = gFunc.LoadFile('util');

local profile = {};
local sets = {
};
profile.Sets = sets;

profile.Packer = {
};

local state = {
    combatSet = nil,
};

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    state.combatSet = Utils.SetSelector.new("Combat", 'p', profile.Sets);
    state.combatSet:addSet('set1', "Thing1");
    state.combatSet:addSet('set2', "Thing2");
    state.combatSet:addSet("override1", "Override1");

    state.combatSet:use('set1');

    Ui.onProfileLoad({
        selectors = {
            state.combatSet,
        }
    });
end

profile.OnUnload = function()
    Ui.onProfileUnload();
end

profile.HandleCommand = function(args)
    Ui.onSlashCommand(args);
end

profile.HandleDefault = function()
    local target = gData.GetTarget()
    if target ~= nil and target.Id % 2 > 0 then
        state.combatSet:override('override1');
    else
        state.combatSet:override();
    end
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