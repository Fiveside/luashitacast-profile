-- Tracking if a target has a skillchain on it
local events = require("events");

---@type table<integer, {}>
local TARGET_STATE = T {};

events.skillchain:on(function(targetId, sc)
    print("Am I even called?")
    local coro = ashita.tasks.once(10, function()
        print(string.format("Clearing SC target %d", targetId));
        TARGET_STATE[targetId] = nil;
    end);
    if TARGET_STATE[targetId] ~= nil then
        print(string.format("Aborting SC clear on target %d", targetId))
        coroutine.kill(TARGET_STATE[targetId].coro)
    end
    print(string.format("Tracking sc on target ", targetId))
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
