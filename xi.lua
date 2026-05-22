-- This file contains constants and functions for accessing FFXI things that aren't LAC specific
-- Constants pulled from https://github.com/AshitaXI/Ashita-v4beta/blob/main/plugins/sdk/ffxi/enums.h

local bit = require('bit');

local Export = {}

Export.LanguageId = {
    Default = 0,
    Japanese = 1,
    English = 2,
}

Export.JobMask = {
    None  = 0x00000000,
    WAR   = 0x00000002,
    MNK   = 0x00000004,
    WHM   = 0x00000008,
    BLM   = 0x00000010,
    RDM   = 0x00000020,
    THF   = 0x00000040,
    PLD   = 0x00000080,
    DRK   = 0x00000100,
    BST   = 0x00000200,
    BRD   = 0x00000400,
    RNG   = 0x00000800,
    SAM   = 0x00001000,
    NIN   = 0x00002000,
    DRG   = 0x00004000,
    SMN   = 0x00008000,
    BLU   = 0x00010000,
    COR   = 0x00020000,
    PUP   = 0x00040000,
    DNC   = 0x00080000,
    SCH   = 0x00100000,
    GEO   = 0x00200000,
    RUN   = 0x00400000,
    MON   = 0x00800000,
    JOB24 = 0x01000000,
    JOB25 = 0x02000000,
    JOB26 = 0x04000000,
    JOB27 = 0x08000000,
    JOB28 = 0x10000000,
    JOB29 = 0x20000000,
    JOB30 = 0x40000000,
    JOB31 = 0x80000000,

    AllJobs = 0x007FFFFE,
}

---Returns a table of strings for all current buffs
---@return table<string, number>;
function Export.getMyBuffsByName()
    local rm = AshitaCore:GetResourceManager();
    local dm = AshitaCore:GetMemoryManager();

    local buffs = T{};
    for buffSlot, buffId in ipairs(dm:GetPlayer():GetBuffs())do
        if buffId ~= nil and buffId >= 0 then
            local name = rm:GetString('buffs.names', buffId, Export.LanguageId.English);
            if name ~= nil then
                buffs[name] = buffId;
            else
                gFunc.Message("Failed to get buff name for buff id " .. buffId .. ' (' .. buffSlot .. ')');
            end
        end
    end
    return buffs;
end

local EQUIPPABLE_BAGS = T{
    0,  -- Inventory
    8,  -- Wardrobe 1
    10, -- Wardrobe 2
    11, -- Wardrobe 3
    12, -- Wardrobe 4
    13, -- Wardrobe 5
    14, -- Wardrobe 6
    15, -- Wardrobe 7
    16, -- Wardrobe 8
}

---Returns details for equipment given the name
---@param itemName string
---@return { name: string, level: integer, jobs: string[], isReady: boolean } isReady indicates if the item is in an equippable bag.
function Export.getEquipmentDetails(itemName)
    local mem = AshitaCore:GetMemoryManager();
    local res = AshitaCore:GetResourceManager();
    
    local item = res:GetItemByName(itemName, Export.LanguageId.English);
    local jobs = T{};
    for job, mask in pairs(Export.JobMask) do
        if bit.band(item.Jobs, mask) > 0 then
            jobs:append(job);
        end
    end

    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local isReady = false;

    for _, containerId in ipairs(EQUIPPABLE_BAGS) do
        for slotId = 1, inventory:GetContainerCount(containerId) do
            local containerItem = inventory:GetContainerItem(containerId, slotId);
            if containerItem.Id == item.Id then
                isReady = true
                break
            end
        end
    end

    return T{
        name = item.Name,
        level = item.Level,
        jobs = jobs,
        isReady = isReady,
    }
end

---Looks through inventory and wardrobes to see if we have the item in question
---@param itemName string
---@return boolean True if this equipment is in a bag we can equip it directly from
function Export.equipmentIsReady(itemName)
    local inventory = AshitaCore:GetMemoryManager():GetInventory()
    local res = AshitaCore:GetResourceManager();

    for _, containerId in ipairs(EQUIPPABLE_BAGS) do
        for slotId = 1, inventory:GetContainerCount(containerId) do
            local itemId = inventory:GetContainerItem(containerId, slotId).Id;
            local item = res:GetItemById(itemId);
            if itemName == item.Name[Export.LanguageId.English] then
                return true;
            end
        end
    end
    return false;
end

return Export;