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
    local final = {};
    for _, member in ipairs(self.members) do
        local success, rendered = pcall(member.render, member);
        if success then
            for key, value in pairs(rendered) do
                if final[key] == nil then
                    final[key] = value;
                end
            end
        end
    end
    return final;
end

function OverlayManager:tick()
    for _, member in ipairs(self.members) do
        pcall(member.tick, member);
    end
end

function OverlayManager:destroy()
    for _, member in ipairs(self.members) do
        pcall(member.destroy, member);
    end
end

return OverlayManager;