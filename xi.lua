-- This file contains constants and functions for accessing FFXI things that aren't LAC specific
-- Constants pulled from https://github.com/AshitaXI/Ashita-v4beta/blob/main/plugins/sdk/ffxi/enums.h

local bit = require("bit");
local ItemData = require("ffxi/itemdata");

local Export = {}

---@enum LanguageId
Export.LanguageId = {
    Default = 1,
    Japanese = 2,
    English = 3,
}

-- Export.Job = {
--     None = 0,
--     WAR  = 1,
--     MNK  = 2,
--     WHM  = 3,
--     BLM  = 4,
--     RDM  = 5,
--     THF  = 6,
--     PLD  = 7,
--     DRK  = 8,
--     BST  = 9,
--     BRD  = 10,
--     RNG  = 11,
--     SAM  = 12,
--     NIN  = 13,
--     DRG  = 14,
--     SMN  = 15,
--     BLU  = 16,
--     COR  = 17,
--     PUP  = 18,
--     DNC  = 19,
--     SCH  = 20,
--     GEO  = 21,
--     RUN  = 22,
--     MON  = 23, -- Used during Monstrosity.
-- };

-- Export.JobId = {};
-- do
--     for job, id in pairs(Export.Job) do
--         Export.JobId[id] = job;
--     end
-- end

---@enum JobMask
Export.JobMask = {
    -- None    = 0x00000000,
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

    -- AllJobs = 0x007FFFFE,
}

Export.JobMask = T(Export.JobMask);

---@enum EquipmentSlot
Export.EquipmentSlot = {
    Main = 0,
    Sub = 1,
    Range = 2,
    Ammo = 3,
    Head = 4,
    Body = 5,
    Hands = 6,
    Legs = 7,
    Feet = 8,
    Neck = 9,
    Waist = 10,
    Ear1 = 11,
    Ear2 = 12,
    Ring1 = 13,
    Ring2 = 14,
    Back = 15,

    -- Max = 16,
};

Export.EquipmentSlot = T(Export.EquipmentSlot);

Export.EquipmentSlotMask = {
    -- None  = 0x0000,
    Main  = 0x0001,
    Sub   = 0x0002,
    Range = 0x0004,
    Ammo  = 0x0008,
    Head  = 0x0010,
    Body  = 0x0020,
    Hands = 0x0040,
    Legs  = 0x0080,
    Feet  = 0x0100,
    Neck  = 0x0200,
    Waist = 0x0400,
    Ear1  = 0x0800,
    Ear2  = 0x1000,
    Ring1 = 0x2000,
    Ring2 = 0x4000,
    Back  = 0x8000,

    -- Slot Groups
    -- Ears  = bit.bor(0x0800, 0x1000), -- LEar | REar
    -- Rings = bit.bor(0x2000, 0x4000), -- LRing | RRing

    -- All Slots
    -- All   = 0xFFFF,
}

Export.EquipmentSlotMask = T(Export.EquipmentSlotMask);

Export.Skillchains = T {
    [1] = T { Name = "Light", Elements = T { "Light", "Thunder", "Fire", "Wind" } },
    [2] = T { Name = "Darkness", Elements = T { "Dark", "Ice", "Water", "Earth" } },
    [3] = T { Name = "Gravitation", Elements = T { "Dark", "Earth" } },
    [4] = T { Name = "Fragmentation", Elements = T { "Thunder", "Wind" } },
    [5] = T { Name = "Distortion", Elements = T { "Ice", "Water" } },
    [6] = T { Name = "Fusion", Elements = T { "Light", "Fire" } },
    [7] = T { Name = "Compression", Elements = T { "Dark" } },
    [8] = T { Name = "Liquefaction", Elements = T { "Fire" } },
    [9] = T { Name = "Induration", Elements = T { "Ice" } },
    [10] = T { Name = "Reverberation", Elements = T { "Water" } },
    [11] = T { Name = "Transfixion", Elements = T { "Light" } },
    [12] = T { Name = "Scission", Elements = T { "Earth" } },
    [13] = T { Name = "Detonation", Elements = T { "Wind" } },
    [14] = T { Name = "Impaction", Elements = T { "Thunder" } },
    [15] = T { Name = "Radiance", Elements = T { "Light", "Thunder", "Fire", "Wind" } },
    [16] = T { Name = "Umbra", Elements = T { "Dark", "Ice", "Water", "Earth" } },
};

-- Maps an element with the element it is weak to
---@type { [LAC.Element]: LAC.Element}
Export.ElementalWeakness = T {
    Thunder = "Earth",
    Ice = "Fire",
    Fire = "Water",
    Wind = "Ice",
    Water = "Thunder",
    Earth = "Wind",
    Dark = "Light",
    Light = "Dark",
};


---Returns a table of strings for all current buffs
---@return table<string, number>;
function Export.getMyBuffsByName()
    local rm = AshitaCore:GetResourceManager();
    local dm = AshitaCore:GetMemoryManager();

    local buffs = T {};
    for buffSlot, buffId in ipairs(dm:GetPlayer():GetBuffs()) do
        if buffId ~= nil and buffId >= 0 then
            local name = rm:GetString("buffs.names", buffId, Export.LanguageId.English);
            if name ~= nil then
                buffs[name] = buffId;
            else
                gFunc.Message("Failed to get buff name for buff id " .. buffId .. " (" .. buffSlot .. ")");
            end
        end
    end
    return buffs;
end

local EQUIPPABLE_BAGS = T {
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

---Looks through equipped items to see if we're currently wearing something that can be
---used like an item.  If we find one, then we return the list of slots that item
---is occupying so that gearswap logic can ignore swapping these in the default handler
---@return LAC.GearSlot[]
function Export.getEquipedExclusionList()
    -- Get currently equipped items.
    local inv = AshitaCore:GetMemoryManager():GetInventory();
    local res = AshitaCore:GetResourceManager();

    -- Slots that have time items ready for use.
    local timeSlots = {};
    for slotName, slotId in pairs(Export.EquipmentSlot) do
        local eqItem = inv:GetEquippedItem(slotId);
        if eqItem ~= nil then
            -- .Index is a uint16 who's upper 8 are the container id and lower 8 are the index in the container
            local containerId = bit.rshift(bit.band(eqItem.Index, 0xFF00), 8);
            local containerIndex = bit.band(eqItem.Index, 0xFF);

            -- These can be nil if we're zoning and inventory hasn't loaded yet.
            local item = inv:GetContainerItem(containerId, containerIndex);
            local rItem = res:GetItemById(item.Id);

            if item ~= nil and rItem ~= nil then
                local timeData = ItemData.parse_timer_info(item, rItem, true);

                -- timeData is empty object if there isn't good timer info on the item
                if timeData.max_charges ~= nil then
                    -- Checking if the time to use this item is within the default cooldown
                    -- that comes from freshly equipping the item.
                    -- Add the additional 3 seconds to this check because the game only has second level precision.
                    local isFreshEquipped = rItem.CastDelay + 3 >= timeData.use_delay;

                    -- Checking for items that have zero charges, because they're always ready
                    -- to use
                    local hasCharges = timeData.remaining_charges > 0;

                    if isFreshEquipped and hasCharges then
                        table.insert(timeSlots, slotName);
                    end
                end
            end
        end
    end

    -- If we have slots with timer data, then also add all empty slots so that we
    -- don't accidentally unequip items that occupy multiple slots (like Mandragora Suit);
    if #timeSlots > 0 then
        for slotName, slotId in pairs(Export.EquipmentSlot) do
            if inv:GetEquippedItem(slotId).Index == 0 then
                table.insert(timeSlots, slotName);
            end
        end
    end

    return timeSlots;
end

---Takes a gearset and returns one without entries in it that could conflict with usable items we
---currently have equipped.
---@param gs LAC.GearSet
---@return LAC.GearSet
function Export.excludeUsableEquippedItems(gs)
    local exclusionList = Export.getEquipedExclusionList();

    local result = T(gs):copy();
    for _, slotName in ipairs(exclusionList) do
        result[slotName] = nil;
    end
    return result;
end

---Returns items currently equipped
---@return table<LAC.GearSlot, {resource: IItem, item: item_t, container: integer, index: integer}>
function Export.getEquipment()
    local inv = AshitaCore:GetMemoryManager():GetInventory();
    local resources = AshitaCore:GetResourceManager();
    local ret = T {};
    for slotName, slotId in pairs(Export.EquipmentSlot) do
        local gearPiece = inv:GetEquippedItem(slotId);
        if gearPiece ~= nil then
            local containerId = bit.rshift(bit.band(gearPiece.Index, 0xFF00), 8);
            local containerIndex = bit.band(gearPiece.Index, 0xFF);
            local item = inv:GetContainerItem(containerId, containerIndex);
            ret[slotName] = T {
                resource = resources:GetItemById(item.Id),
                item = item,
                container = containerId,
                index = containerIndex,
            }
        end
    end
    return ret;
end

---Returns true if the item has finished cooling down and is ready, or is waiting for the "just equipped" cooldown to finish.
---Returns false if the item is cooling down or doesn't have a timer on it.
---@param item item_t
---@return boolean
function Export.isUsableEquipmentReady(item)
    local rItem = AshitaCore:GetResourceManager():GetItemById(item.Id);
    ---@cast rItem -?

    local timeData = ItemData.parse_timer_info(item, rItem, true);

    -- timeData is empty object if there isn't good timer info on the item
    if timeData.max_charges == nil then
        return false;
    end
    -- Checking if the time to use this item is within the default cooldown
    -- that comes from freshly equipping the item.
    -- Add the additional 3 seconds to this check because the timer data has second level precision.
    local isFreshEquipped = rItem.CastDelay + 3 >= timeData.use_delay;

    -- Checking for items that have zero charges, because they're always ready
    -- to use
    local hasCharges = timeData.remaining_charges > 0;

    return isFreshEquipped and hasCharges;
end

---Remove items from the passed gearset that would be equipped in a slot currently
---occupied by a usable item with a ready timer.  Returns the passed argument if no removal is needed.
---@param gs LAC.GearSet
---@return LAC.GearSet
function Export.removeUsableEquipment(gs)
    local ret = T {};
    local hasReadyItem = false;
    local equipped = Export.getEquipment();
    for _, slotName in ipairs(Export.EquipmentSlot:keys()) do
        local eqItem = equipped[slotName];
        local isReady = Export.isUsableEquipmentReady(eqItem.item);
        if eqItem ~= nil and not isReady then
            ret[slotName] = gs[slotName];
        end
        hasReadyItem = hasReadyItem or isReady;
    end

    if hasReadyItem then
        return ret;
    end
    return gs;
end

---Returns true if its currently daytime and "Daytime" conditional gear is active.
---False does signal that "Nighttime" conditional gear is active.
---@return boolean
function Export.isDaytime()
    -- TODO: we could probably do this ourselves so we don't rely on LAC here, but this
    -- function's implementation is pretty messy.
    local gameTime = gData.GetEnvironment().Time;
    return gameTime > 8.0 and gameTime < 18.0;
end

---@alias ContainerDefinition {id: integer, name: string, equippable: boolean}

-- Ordered this way because it appears in the UI this way.
---@type ContainerDefinition[]
local CONTAINER_LIST = T {
    { id = 3,  name = "Temporary", equippable = false },
    { id = 0,  name = "Inventory", equippable = true },
    { id = 1,  name = "Safe",      equippable = false },
    { id = 9,  name = "Safe2",     equippable = false },
    { id = 2,  name = "Storage",   equippable = false },
    { id = 4,  name = "Locker",    equippable = false },
    { id = 5,  name = "Satchel",   equippable = false },
    { id = 6,  name = "Sack",      equippable = false },
    { id = 7,  name = "Case",      equippable = false },
    { id = 8,  name = "Wardrobe",  equippable = true },
    { id = 10, name = "Wardrobe2", equippable = true },
    { id = 11, name = "Wardrobe3", equippable = true },
    { id = 12, name = "Wardrobe4", equippable = true },
    { id = 13, name = "Wardrobe5", equippable = true },
    { id = 14, name = "Wardrobe6", equippable = true },
    { id = 15, name = "Wardrobe7", equippable = true },
    { id = 16, name = "Wardrobe8", equippable = true },
};

---@type table<integer, string>
local CONTAINERS = T {};
do
    for _, c in ipairs(CONTAINER_LIST) do
        CONTAINERS[c.id] = c.name
    end
end

---An iterator for an inventory container's contents
---@param containerId integer
---@param index integer
---@return integer?, item_t?
local function containerIterator(containerId, index)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    for i = index, inventory:GetContainerCountMax(containerId) do
        local inventoryItem = inventory:GetContainerItem(containerId, i);
        if inventoryItem ~= nil and inventoryItem.Id > 0 then
            return i + 1, inventoryItem
        end
    end
end

---An iterator for the entire inventory's contents
---@param containers ContainerDefinition[]
---@param index {container: integer, index: integer}
---@return {container: integer, index: integer}?, {item: item_t, location: integer}?
local function inventoryIterator(containers, index)
    local itemIndex = index.index;
    for cindex = index.container, #containers do
        local containerId = containers[cindex].id;
        local iid, item = containerIterator(containerId, itemIndex)
        if iid ~= nil then
            return { container = cindex, index = iid }, { item = item, location = containerId };
        end
        -- Reset item index for the next container
        itemIndex = 1;
    end
end

Export.InventoryContainers = CONTAINERS;
Export.InventoryContainerList = CONTAINER_LIST;
Export.debug = inventoryIterator;

---An iterator over all items in our inventory
---@return fun(): ContainerDefinition?, {item: item_t, location: integer}? iterator function
---@return ContainerDefinition[] invariant
---@return {id: integer, name: string} starting index
function Export.listEntireInventory()
    return inventoryIterator, CONTAINER_LIST, { container = 1, index = 1 }
end

---An iterator over all items in equippable containers in our inventory
---@return fun(): ContainerDefinition?, {item: item_t, location: integer}? iterator function
---@return ContainerDefinition[] invariant
---@return {id: integer, name: string} starting index
function Export.listEquippableInventory()
    local containers = CONTAINER_LIST:filteri(function(c) return c.equippable; end);
    return inventoryIterator, containers, { container = 1, index = 1 }
end

---An iterator over all items in a container
---@param containerId integer
---@return fun(integer, integer): integer?, item_t? iterator function
---@return integer invariant
---@return integer starting index
function Export.listContainer(containerId)
    return containerIterator, containerId, 1
end

return Export;
