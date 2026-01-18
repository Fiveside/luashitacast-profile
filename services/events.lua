-- Allows users to register callbacks to some formalized events

function DefaultTable(default_fn)
    local tbl = {};
    local mtbl = {};
    mtbl.__index = function (tbl, key)
        local val = rawget(tbl, key);
        if val == nil then
            val = default_fn();
            rawset(tbl, key, val)
        end
        return val;
    end
end

local Events = {};
Events.__index = Events;

Events.LEVEL_CHANGE = "onLevelChange"

Events.new = function ()
    self._events = DefaultTable(function() return {}; end)
end

Events.tick = function ()
    -- do shit
end

Events.onLevelChange = function (fn)
    table.insert(self._events["levelChange"], fn)
end
