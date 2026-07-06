-- Allows users to register callbacks to some formalized events
local ffi = require('ffi');

ffi.cdef[[
    typedef long time_t;
    struct timeval {
        time_t tv_sec;
        time_t tv_usec;
    };
    int gettimeofday(struct timeval *restrict tv, void *restrict tz);
]]

local tv = ffi.new("struct timeval");



-- function DefaultTable(default_fn)
--     local tbl = {};
--     local mtbl = {};
--     mtbl.__index = function (tbl, key)
--         local val = rawget(tbl, key);
--         if val == nil then
--             val = default_fn();
--             rawset(tbl, key, val)
--         end
--         return val;
--     end
-- end


local Events = {};
Events.__index = Events;

local ASHITA_PACKET_IN_NAME = "lac_profile_packet_in_event_handler"

---@alias LowResTimestamp {sec: integer, ms: integer};

---@class TimeEvent
---@field after LowResTimestamp
---@field callback fun(Events, ...)

---@alias EventName string

Events.PACKET_IN = "packetIn"
Events.PACKET_OUT = "packetIn"
Events.SKILLCHAIN = "skillchain"
Events.MAGIC_BURST_WINDOW_OPEN = "magicBurstWindowOpen"
Events.MAGIC_BURST_WINDOW_CLOSE = "magicBurstWindowOpen"

function Events.new()
    local self = setmetatable({}, {__index=Events});

    ---@type TimeEvent[]
    self._timeEvents = T{};

    ---@type table<integer, fun(Events, ...)[]>
    self._events = T{
        [Events.PACKET_IN] = T{},
        [Events.PACKET_OUT] = T{},
        [Events.SKILLCHAIN] = T{},
        [Events.MAGIC_BURST_WINDOW_OPEN] = T{},
        [Events.MAGIC_BURST_WINDOW_OPEN] = T{},
    };

    return self;
end

function Events:install()
    local this = self;
    ashita.events.register("packet_in", ASHITA_PACKET_IN_NAME, function (pkt)
        this:trigger(Events.PACKET_IN, pkt);
    end);
end

function Events:uninstall()
    ashita.events.unregister("packet_in", ASHITA_PACKET_IN_NAME);
end

function Events:tick()
    -- do shit.  Call this each frame.
    ffi.C.gettimeofday(tv, nil);

    -- Backwards iteration because we're modifying the table
    -- in the middle of the loop.
    for i = #self._timeEvents, 1, -1 do
        local event= self._timeEvents[i];
        if event.after.sec > tv.tv_sec and event.after.ms > tv.tv_usec then
            event.callback(self)
            table.remove(self._timeEvents, i);
        end
    end
end

---Set a function to run after a duration
---@param after integer The amount of time to delay execution by (milliseconds).
---@param fn fun() The callback to run
function Events:after(after, fn)
    ffi.C.gettimeofday(tv, nil);
    local ms = tv.tv_usec + after;
    local secdelta = math.modf(ms/1000);
    local afterTime = T{
        sec = tv.tv_sec + secdelta,
        ms = after % 1000,
    }
    table.insert(self.timeEvents, afterTime);
end

---Register an event handler
---@param event integer
---@param callback fun(any, ...)
function Events:on(event, callback)
    table.insert(self._events[event], callback)
end

---Trigger all event handlers for an event
---@param event EventName
---@param ... unknown Arguments to pass to the event handler.
function Events:trigger(event, ...)
    -- Could probably use pcall, but this is all my code.
    -- so don't write shitty event handlers.
    for _, cb in ipairs(self._events[event]) do
        cb(self, ...);
    end
end

return Events;