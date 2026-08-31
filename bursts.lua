-- Tracking if a target has a skillchain on it
local events = gFunc.LoadFile("events");

---@type table<integer, {}>
local TARGET_STATE = T {};

events.skillchain:on(function(targetId, sc)
    local coro = ashita.tasks.once(10, function()
        TARGET_STATE[targetId] = nil;
    end);
    if TARGET_STATE[targetId] ~= nil then
        coroutine.kill(TARGET_STATE[targetId].coro)
    end
    TARGET_STATE[targetId] = {
        sc = sc,
        coro = coro,
    };
end);

local Export = {};

function Export.getSkillchain(targetId)
    local state = TARGET_STATE[targetId];
    if state ~= nil then
        return state.sc
    end
end

return Export;
