
---@class SlipDefinition
---@field id integer The slip index number (Eg. "Storage Slip 01" = 1)
---@field item_id integer The slip's item id
---@field items integer[] An ordered list of item IDs this slip contains
---@field en string English localized name of this slip
---@field ja string Japanese localized name of this slip

---@type table<integer, SlipDefinition>
local SlipData = gFunc.LoadFile("slips/slipdata");
local XI = gFunc.LoadFile("xi");

---@type integer[]
local SLIP_IDS = T{};

---@type integer[]
local SLIPPABLE_ITEMS = T{}
do
    for _, slip in pairs(SlipData) do
        table.insert(SLIP_IDS, slip.item_id);
        for _, itemId in ipairs(slip.items) do
            table.insert(SLIPPABLE_ITEMS, itemId);
        end
    end
end

---@param slipItem item_t The slip item in the player's inventory
---@param index integer The index of the item in the slip
---@return {item: IItem, owned: boolean} The item at the slip index and a flag indicating whether the slip has this item stored
function getSlipItem(slipItem, index)
    local data = SLIP_IDS[slipItem.Id];
    local itemId = data.items[index];
    if itemId == nil then
        error("Attempted to access a slip id that doesn't exist.")
    end

    local byteIndex = math.modf((index - 1) / 8) + 1;
    local bitmask = 2 ^ ((index - 1) % 8);
    local owned = bit.band(string.byte(slipItem.Extra, byteIndex), bitmask) > 0;
    local item = AshitaCore:GetResourceManager():GetItemById(itemId);
    return { item = item, owned = owned };
end

---@param slipItem item_t invariant
---@param index integer
---@return integer?, IItem?
function possibleSlipContentsIterator(slipItem, index)
    local data = SLIP_IDS[slipItem.Id];
    if data == nil then
        return nil;
    end
    local item = data.items[index];
    if item == nil then
        return nil;
    end
    local result = getSlipItem(slipItem, index);
    return index+1, result;
end

---An iterator for items the player has stored on the given slip
---@param slipItem item_t
---@param index integer
---@return integer?
---@return IItem?
function ownedSlipContentsIterator(slipItem, index)
    local data = SLIP_IDS[slipItem.Id];
    if data == nil then
        return nil;
    end
    for i = index, #data.items do
        local nextIndex, res = possibleSlipContentsIterator(slipItem, i);
        if nextIndex == nil then
            return nil;
        end

        ---@cast res { item: IItem, owned: boolean }
        if res.owned then
            return nextIndex, res.item;
        end
    end
end

---Iterate over all the items a slip can store.  Returns the item and a flag indicating if said item is stored in this slip.
---@param slipItem item_t
---@return fun(item_t, integer): integer, {item: IItem, owned: boolean} iterator
---@return item_t invariant
---@return integer starting index
local function listSlipContents(slipItem)
    return possibleSlipContentsIterator, slipItem, 1
end

---Iterate over all items stored in a slip
---@param slipItem item_t
---@return fun(item_t, integer): integer, IItem iterator
---@return item_t invariant
---@return integer starting index
local function listOwnedSlipContents(slipItem)
    return ownedSlipContentsIterator, slipItem, 1
end

local function getOwnedSlips()
    local slips = T{};
    for _, result in XI.listEntireInventory() do
        ---@cast result {item: item_t, location: integer}
        if SLIP_IDS:contains(result.item.Id) then
            table.insert(slips, result.item);
        end
    end
    return slips;
end


local Export = {
    listSlipContents = listSlipContents,
    listOwnedSlipContents = listOwnedSlipContents,
};

---Returns a boolean if this item id can be stored in a slip
---@param itemId integer
---@return boolean
function Export.isSlippable(itemId)
    return SLIPPABLE_ITEMS:contains(itemId);
end

---Return all items in our inventory that can be stored in a slip.
---Format is map of container id to item in container.
---@return table<integer, item_t>
function Export.getSlippableItemsInInventory()
    local result = T{};
    for _, searchResult in XI.listEntireInventory() do
        ---@cast searchResult {item: item_t, location: integer}
        if SLIPPABLE_ITEMS:contains(searchResult.item.Id) then
            local containerContents = result[searchResult.location];
            if containerContents == nil then
                containerContents = T{};
                result[searchResult.location] = containerContents;
            end
            table.insert(containerContents, searchResult.item);
        end
    end
    return result;
end

---Return all items we have stored in slips.
---@return unknown
function Export.getAllItemsInSlips()
    local result = T{};
    for _, slip in ipairs(getOwnedSlips()) do
        for _, item in listOwnedSlipContents(slip) do
            table.insert(item);
        end
    end
    return result;
end

return Export;