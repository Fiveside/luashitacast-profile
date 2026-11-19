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
---@field private exclusions LAC.GearSet[]
local SetBuilder = T {};

---Create a new setbuilder
---@param options SetBuilderOptions?
---@return SetBuilder
function SetBuilder.new(options)
    options = options or T {};
    options = T({}):merge(options):merge(defaultSetbuilderOptions)

    local this = {
        layers = T {},
        exclusions = T {},
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

---Exclude one or more gearsets, preventing any items in those sets from being considered
---@param ... LAC.GearSet[]
---@return self
function SetBuilder:exclude(...)
    for _, set in ipairs({ ... }) do
        for slot, item in pairs(set) do
            local spread = self.exclusions[slot] or T {};
            self.exclusions[slot] = spread;
            spread:append(item);
        end
    end
    return self;
end

---Return the built set without doing any lazy resolution.
---@return LAC.GearSet
function SetBuilder:getCurrentSet()
    local compressed = T {};
    for _, layer in ipairs(self.layers) do
        for slot, item in pairs(layer) do
            local spread = self.exclusions[slot];
            if spread == nil or not spread:contains(item) then
                compressed[slot] = item;
            end
        end
    end

    if not self.options.replaceUsable then
        compressed = XI.removeUsableEquipment(compressed);
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
    local set = self.resolveLazy(self:getCurrentSet());
    for slot, spread in pairs(self.exclusions) do
        if #spread > 0 and set[slot] == nil then
            set[slot] = "remove";
        end
    end
    return set;
end

return SetBuilder;
