local OverlayManager = {};
OverlayManager.__index = OverlayManager;

function OverlayManager:new()
    local obj = {};
    setmetatable(obj, self);
    obj.members = T{};
    return obj;
end

function OverlayManager:add(...)
    local args = {...};
    self.members.extend(args);
end

function OverlayManager:render()
end

function OverlayManager:destroy()
end

return OverlayManager;