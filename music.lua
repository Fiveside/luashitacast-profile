local Music = {};
Music.__index = Music;



function Music:new()
    local obj = {};
    setmetatable(obj, self);
    return obj;
end

function Music:destroy()
end

return Music;