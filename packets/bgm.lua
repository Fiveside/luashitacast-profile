require('common');
local chat = require('chat');
local ffi = require('ffi');

-- Need to consider the following packets:
-- 0x0A - zone in
-- 

-- 0x5F - music update
-- https://github.com/atom0s/XiPackets/tree/main/world/server/0x005F

local BGMUpdate = {};
BGMUpdate.__index = BGMUpdate;
BGMUpdate.id = 0x5F;
BGMUpdate.event_name = 'ashitacast_profile_QTJr3AaEKYg';

ffi.cdef[[
typedef struct {
    uint16_t    id: 9;
    uint16_t    size: 7;
    uint16_t    sync;
    uint16_t    slot;
    uint16_t    musicNum;
} GP_SERV_MUSIC;
]]

function BGMUpdate:new()
    local o = {};
    setmetatable(o, self);
    -- todo: dynamic event name, allowing multiple subsystems to intercept packets.
    ashita.events.register('packet_in', self.event_name, function(e) o:on_packet(e) end)
    return o;
end

function BGMUpdate:on_packet(event)
    if (event.id ~= self.id) then
        return
    end
    print(chat.header('Music') .. 'Received packet with id of 0x5F, now trying to fiddle with it.')
    -- TODO: this is busted and causes a fault.
    local pkt = ffi.cast('GP_SERV_MUSIC*', event.raw_data);
    print(chat.header('Music') .. 'Changed slot [' .. pkt.slot .. '] to [' .. pkt.musicNum ..']');
end

function BGMUpdate:destroy()
    ashita.events.unregister('packet_in', self.event_name)
end

return BGMUpdate;