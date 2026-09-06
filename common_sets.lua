local Slips = require("slips/slips");
local Xi = require("xi");

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

-- Collecting AF, AF+1, Relic, and Relic+1 into something easy to reference.
-- job->category->slot->itemName
---@type table<string, table<string, table<GearSlot, string>>>
Export.JSE = T {};
do
    local slipMap = {
        Artifact = 4,
        ArtifactPlus1 = 5,
        Relic = 6,
        RelicPlus1 = 7,
    }
    local jse = T {};
    Export.JSE = jse;
    for cat, slipNum in pairs(slipMap) do
        local slip = Slips.slipItems[slipNum];
        for _, item in Slips.listSlipContents(slip) do
            ---@cast item IItem
            -- JSE gear is job specific by nature, so only one of the jobs matches.  We can iterate through
            -- the job list until we find it.
            local job = T(Xi.JobMask):find(item.Jobs);

            -- Again, JSE gear only goes into one slot.
            -- Artifact weapons can actually fit into multiple slots, but we don't really
            -- care about those for this collection.  All we care about are head, body, hands, legs, and feet.
            local slot = T(Xi.EquipmentSlotMask):find(item.Slots);

            if slot ~= nil then
                if jse[job] == nil then
                    jse[job] = T {};
                end
                if jse[job][cat] == nil then
                    jse[job][cat] = T {};
                end
                jse[job][cat][slot] = item.Name[Xi.LanguageId.Default];
            end
        end
    end
end


return Export;
