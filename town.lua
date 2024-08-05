local ZONES = T{
    [T{"Bastok Markets", "Bastok Mines", "Metalworks", "Port Bastok"}] = {
        Body = "Republic Aketon",
    },
    [T{"Southern San d'Oria", "Northern San d'Oria", "Port San d'Oria", "Chateau d'Oraguille"}] = {
        Body = "Kingdom Aketon",
    },
    [T{"Windurst Woods", "Windurst Walls", "Windurst Waters", "Port Windurst"}] = {
        Body = "Federation Aketon",
    },
};

local DUCAL_ZONES = T{
    "Ru'Lude Gardens",
    "Upper Jeuno",
    "Lower Jeuno",
    "Port Jeuno",

    -- Outlands and smaller cities
    "Tavnazian Safehold",
    "Selbina",
    "Mhaura",
    "Rabao",
};

local DUCAL_SET = {
    Body = "Ducal Aketon",
}

-- Ducal aketon includes all cities
for k, _v in pairs(ZONES) do
    DUCAL_ZONES:extend(k);
end

local lastZone = "undefined";
local lastSet = {};
local use_ducal_aketon = true;

return function ()
    local zoneName = gData.GetEnvironment().Area
    if zoneName == lastZone then
        return lastSet;
    end
    lastZone = zoneName;
    if use_ducal_aketon then
        if DUCAL_ZONES:contains(zoneName) then
            lastSet = DUCAL_SET;
            return DUCAL_SET;
        end
    else
        for zones, set in pairs(ZONES) do
            if zones:contains(zoneName) then
                lastSet = set;
                return set;
            end
        end
    end
    lastSet = {};
    return lastSet;
end