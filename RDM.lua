local profile = {};
local sets = {
};
profile.Sets = sets;

profile.Packer = {
};

sets.Magic = {
    Main = "Yew Wand +1",
}

sets.Resting = {
    Main = "Pilgrim's Wand",
}

profile.OnLoad = function()
    gSettings.AllowAddSet = true;
end

profile.OnUnload = function()
end

profile.HandleCommand = function(args)
end

profile.HandleDefault = function()
    local player = gData.GetPlayer();
    if (player.Status == "Resting") then
        gFunc.EquipSet(sets.Resting);
    end
end

profile.HandleAbility = function()
end

profile.HandleItem = function()
end

profile.HandlePrecast = function()
end

profile.HandleMidcast = function()
    gFunc.EquipSet(sets.Magic);
end

profile.HandlePreshot = function()
end

profile.HandleMidshot = function()
end

profile.HandleWeaponskill = function()
end

return profile;
