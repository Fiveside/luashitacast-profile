local Export = {};

--- Specific gear for job actions, spells, and weapon skills.
--- These sets apply to all jobs.
function Export.applyCommonMagicSets(sets)
    ---@type GearSet
    sets.MA_Sneak = T {
        Feet = "Dream Boots +1",
    };

    ---@type GearSet
    sets.MA_Invisible = T {
        Hands = "Dream Mittens +1"
    };
end


return Export;