-- Allows users to register callbacks to some formalized events.

local Utils = gFunc.LoadFile('util');

local Export = {};

local HANDLERS = T{};

function Export.on(eventName, callback)
    HANDLERS[eventName] = HANDLERS[eventName] or T{};
    table.insert(HANDLERS[eventName], callback);
end

function Export.trigger(eventName, ...)
    local callbacks = HANDLERS[eventName];
    if callbacks == nil then 
        return;
    end
    for _, cb in ipairs(callbacks) do
        cb(...);
    end
end

----------------------
-- Main job level change
----------------------


local lastJobLevel = 0;
local MainJobLevelChange = {
    init = function()
        return {
            lastJobLevel = 0,
        }
    end,
    onDefault = function(state)
        local mainJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
        if state.lastJobLevel ~= nil and state.lastJobLevel == mainJobLevel then
            return;
        end
        state.lastJobLevel = mainJobLevel;
        Export.trigger("levelChange", mainJobLevel);
    end,
}


------------------------
-- Using modules
------------------------

local ACTIVE_MODULES = {
    MainJobLevelChange,
}

local MODULE_STATES = {
}

function Export.onProfileLoad()
    MODULE_STATES = {};
    for _, mod in ipairs(ACTIVE_MODULES) do
        MODULE_STATES[mod] = mod.init();
    end
end

function Export.onDefault()
    for _, mod in ipairs(ACTIVE_MODULES) do
        if mod.onDefault ~= nil then
            mod.onDefault(MODULE_STATES[mod])
        end
    end
end

