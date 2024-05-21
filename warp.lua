require('common');
local chat = require('chat');

local Warp = {};
Warp.__index = Warp;

local warpItems = T{
    "Warp Cudgel",
}


function Warp:new()
    local obj = {
        enabled = false,
        zone = "Unknown",
    };
    setmetatable(obj, self);
    return obj;
end

function Warp:enable()
    local environ = gData.GetEnvironment();
    self.enabled = true
    self.zone = environ.Zone
    print("E")
end

function Warp:tickSet()
    if self.enabled then
        local environ = gData.GetEnvironment();
        if (environ.Zone ~= self.Zone) then
            print("fin");
            self.enabled = false;
            return {};
        else
            -- get best warp item and equip it
        end
    else
        return {};
    end
end

function Warp:destroy()
end

return Warp;