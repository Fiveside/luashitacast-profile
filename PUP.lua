local ui = gFunc.LoadFile("ui");

---@type LAC.Profile
local profile = {
    Sets = {},
    Packer = {},
};
local sets = profile.Sets;

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
    ui.onProfileLoad();
end

profile.OnUnload = function()
    ui.onProfileUnload();
end

profile.HandleCommand = function(args)
    ui.onSlashCommand(args);
end

profile.HandleDefault = function()
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
