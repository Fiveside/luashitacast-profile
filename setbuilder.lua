
---Manages the construction of a gearset via layering.  Includes support for lazy
---entry resolution by using a callable instead of a string or table for a gear piece.
---@class SetBuilder
local SetBuilder = T {};

---Create a new setbuilder
---@return SetBuilder
function SetBuilder.new()
    local this = {
        layers = T {},
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

---Return the built set without doing any lazy resolution.
---@return LAC.GearSet
function SetBuilder:getCurrentSet()
    local compressed = T {};
    for _, layer in ipairs(self.layers) do
        for k, v in pairs(layer) do
            compressed[k] = v;
        end
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
