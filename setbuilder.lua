local XI = require("xi");

---@class SetBuilderOptions
---@field replaceUsable boolean Allow the gearset to replace usable equipment we already have equipped. (default true)
local defaultSetbuilderOptions = {
    replaceUsable = true,
}

---Manages the construction of a gearset via layering.  Includes support for lazy
---entry resolution by using a callable instead of a string or table for a gear piece.
---@class SetBuilder
---@field private options SetBuilderOptions
---@field private layers LAC.GearSet[]
local SetBuilder = T {};

---Create a new setbuilder
---@param options SetBuilderOptions?
---@return SetBuilder
function SetBuilder.new(options)
    options = options or T {};
    options = T({}):merge(options):merge(defaultSetbuilderOptions)

    local this = {
        layers = T {},
        options = options,
    };
    return setmetatable(this, { __index = SetBuilder });
end

---Add one or more gearsets to the builder
---@param ... LAC.GearSet[]
---@return self
function SetBuilder:add(...)
    for _, set in ipairs({ ... }) do
        self.layers:append(set);
    end
    return self;
end

-- Remove items from the passed gearset that would be equipped in a slot currently
-- occupied by a usable item with a ready timer.
local function removeUsable(gs)
    local ret = T {};
    local hasReadyItem = false;
    local equipped = XI.getEquipment();
    for _, slotName in ipairs(XI.EquipmentSlot:keys()) do
        local eqItem = equipped[slotName];
        local isReady = XI.isUsableEquipmentReady(eqItem.item);
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

---Return the built set without doing any lazy resolution.
---@return LAC.GearSet
function SetBuilder:getCurrentSet()
    local compressed = T {};
    for _, layer in ipairs(self.layers) do
        for k, v in pairs(layer) do
            compressed[k] = v;
        end
    end

    if not self.options.replaceUsable then
        compressed = removeUsable(compressed);
    end

    self.layers = T { compressed };
    return compressed;
end

---Static method that just resolves any lazy references in a gearset.
---@param inputGs LAC.GearSet
---@return LAC.GearSet
function SetBuilder.resolveLazy(inputGs)
    local gs = T {};
    for k, v in pairs(inputGs) do
        local ok, newV = pcall(v);
        if ok then
            gs[k] = newV;
        else
            gs[k] = v;
        end
    end
    return gs;
end

---Resolve any lazy entries and return the built set.
---@return LAC.GearSet
function SetBuilder:finalize()
    return self.resolveLazy(self:getCurrentSet());
end

return SetBuilder;
