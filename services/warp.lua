require('common');
local chat = require('chat');

-- local Warp = {};
-- Warp.__index = Warp;

-- Prefer warpable objects in this priority
local PRIORITY = T{
    T{ Main = "Trick Staff II" },
    T{ Main = "Warp Cudgel" },
}

local enabled = false;
local lastZone = "unknown";

-- Cacheing the set we're using to warp
local warpSet = {};

local Export = {};

function Export.toggle()
    local environ = gData.GetEnvironment();
    if not enabled then
        lastZone = environ.Area;
    end
    enabled = not enabled;
end

function Export.handleCommand(args)
    if string.lower(args[1]) == "warp" then
        Export.toggle();
    end
end

function Export.getSet()
    
end