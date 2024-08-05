

local HELMSET = {
    Body = "Field Tunica",
    Hands = "Field Gloves",
    Legs = "Field Hose",
    Feet = "Field Boots",
}

local enabled = false;
local lastZone = "unknown";

local Export = {};

function Export.getSet()
    local environ = gData.GetEnvironment()
    if environ.Area ~= lastZone then
        enabled = false
    end
    if not enabled then
        return {};
    end
    return HELMSET;
end


function Export.toggle()
    local environ = gData.GetEnvironment();
    if enabled then
        enabled = false;
    else
        lastZone = environ.Area;
        enabled = true;
    end
end

function Export.handleCommand(args)
    if string.lower(args[1]) == "helm" then
        Export.toggle();
    end
end

return Export;