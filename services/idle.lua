-- Equips items that allows you to regen while not in combat, up to 95% max hp.
local Conquest = gFunc.LoadFile("lib/conquest");

local HAIRPIN = T{
    Head = {"President. Hairpin"},
};
local function includeHairpin()
    -- Hairpin should be enabled if we are NOT
    -- in a zone controlled by our city state.
    return not Conquest.GetInsideControl()
end

local BANGLES = T{
    Hands = {"Garden Bangles"},
}

local function includeBangles()
    -- Returns tue if circumstances allow the
    -- Garden Bangles to trigger regen
    local gameTime = gData.GetEnvironment().Time;
    return gameTime > 8.0 and gameTime < 18.0;
end


local SETS = {
    Hairpin_Priority = HAIRPIN,
    Bangles_Priority = BANGLES,
}

local Export = {};
local state = {
    lastLevel = 0,
    lastTickEnabled = false,
};

function shouldEnable()
    -- Enable the idle regen set if
    -- - We are not in combat
    -- - We are not casting
    -- - Either:
    -- - - We have less than 95% hp
    -- - - And:
    -- - - - We have less than 100% hp
    -- - - - Last tick, we enabled the regen set
    local player = gData.GetPlayer();
    if not (player.Status == "Idle" or player.Status == 'Resting') then
        return false;
    end
    -- todo: how to detect when casting?

    if player.HPP < 95 then
        return true;
    end
    if player.HPP < 100 and state.lastTickEnabled then
        return true;
    end
    return false;
end

function Export.getSet()
    local enabled = shouldEnable();
    state.lastTickEnabled = enabled;
    if not enabled then
        return {};
    end
    
    local player = gData.GetPlayer();
    if player.MainJobLevel ~= state.lastLevel then
        state.lastLevel = player.MainJobLevel;
        gFunc.EvaluateLevels(SETS, player.MainJobLevel);
    end
    
    local result = {};
    -- TODO: convert to sets and set compression
    if includeHairpin() and player.MainJobLevel >= 65 then
        result.Head = "President. Hairpin";
    end
    -- if includeBangles() then
    --     result:append(SETS.Bangles);
    -- end
    return result;
end

return Export;