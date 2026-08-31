-- Allows users to register callbacks to some formalized events.

local xi = gFunc.LoadFile('xi');
local utils = gFunc.LoadFile('util');
local encoding = require('encoding');
require('common');

---@class IncommingPacket
---@field id integer Type of packet
---@field size integer Size in bytes of the packet.
---@field data number[] Packet data.
---@field data_raw number[] Packet data as a raw pointer (for use with FFI)
---@field data_modified number[] Packet data.  Modify this if you intend to change the packet.
---@field data_modified_raw number[] Modified packet data as a raw pointer (for use with FFI)
---@field injected boolean True if another addon injected this packet.
---@field blocked boolean Set to true to prevent the client from processing this packet

local pktHeaderSize = 32; -- The size of the fields common to every packet (id, size, sync)

---@class EventEmitter
local EventEmitter = {};
function EventEmitter.new()
    local this = {
        handlers = {},
        onceHandlers = {},
    };
    return setmetatable(this, {__index=EventEmitter});
end

function EventEmitter:on(callback)
    self.handlers[callback] = callback;
end

function EventEmitter:once(callback)
    self.once[callback] = callback;
end

function EventEmitter:trigger(...)
    for cb in pairs(self.onceHandlers) do
        cb(...);
    end
    self.onceHandlers = {};
    for cb in pairs(self.handlers) do
        cb(...);
    end
end

-- ---@class TimedEventEmitter
-- local TimedEventEmitter = {};
-- function TimedEventEmitter.new()
--     local this = {
--         handlers = {}
--     }
--     return setmetatable(this, {__index=TimedEventEmitter});
-- end

-- local perfFreq = ashita.time.query_performance_frequency().quad_part;
-- local function nowTimestamp()
--     local now = ashita.time.query_performance_counter().quad_part;
--     return (now*1000)/perfFreq;
-- end

-- function TimedEventEmitter:after(time, callback)
--     table.insert(self.handlers, {
--         timestamp = nowTimestamp()+time,
--         callback = callback,
--     })
-- end

-- function TimedEventEmitter:tick()
--     local now = nowTimestamp();
--     for i = #self.handlers, 1, -1 do
--         local handler = self.handlers[i];
--         if handler.timestamp < now then
--             handler.callback()
--             table.remove(self.handlers, i);
--         end
--     end
-- end

----------------------
-- Packet In
----------------------
local packetIn = EventEmitter.new();
local function installPacketIn()
    ashita.events.register("packet_in", "lac_events_packet_in", function(pkt)
        packetIn:trigger(pkt);
    end)
end

local function uninstallPacketIn()
    ashita.events.unregister("packet_in", "lac_events_packet_in");
end

----------------------
-- Game Tick
----------------------
local render = EventEmitter.new();
-- local timer = TimedEventEmitter.new();
local function installGameTick()
    ashita.events.register('d3d_present', 'lac_events_d3d_present', function()
        -- timer:tick();
        render:trigger();
    end)
end
local function uninstallGameTick()
    ashita.events.unregister('d3d_present', 'lac_events_d3d_present');
end

----------------------
-- Job or Level Change
----------------------

local mainJobChange = EventEmitter.new();
local subJobChange = EventEmitter.new();

local lastStats = {
    mainJob = nil,
    mainLevel = nil,
    subJob = nil,
    subLevel = nil,
};
packetIn:on(function(pkt)
    ---@cast pkt IncommingPacket

    local resources = AshitaCore:GetResourceManager();
    local mjob, mjobLevel, sjob, sjobLevel;
    if pkt.id == 0x061 then
        -- Character status update packet.
        local jobOffset = pktHeaderSize+64;
        mjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset, 8)
        mjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset+8, 8)
        sjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset+16, 8)
        sjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset+24, 8);
    elseif pkt.id == 0x0DD then
        -- Party member update packet.
        -- We're checking this packet as well because of the following scenario:
        -- If you are in a level synced party where the sync is someone else
        -- If the sync levels up, then pkt 0x061 isn't sent.  However, this packet is.
        -- Therefore we can fire the job change events when pt member 0 (us) receives the update.
        -- This might be private server behavior, have not yet checked retail.

        local partyMemberNoOffset = pktHeaderSize + 128 + 32 + 16;
        local partyMemberNo = ashita.bits.unpack_be(pkt.data_raw, partyMemberNoOffset, 8);

        if partyMemberNo ~= 0 then
            return;
        end

        local jobOffset = partyMemberNoOffset + 64;
        mjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset, 8);
        mjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset+8, 8)
        sjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset+16, 8)
        sjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset+24, 8);

        -- Party member update zeros out most info if the member is outside the current
        -- zone. We can safely reject packet updates if the character's main job is zero.
        -- since that is not a legal job type.  We can't trust the ZoneNo field since characters are
        -- marked as in the current zone but have no hp/mp/jobs while they are in the middle of zoning.
        -- TODO: mjob is zero when we receive an update while /anon. Have not yet figured a way around that.
        if mjob == 0 then
            return;
        end
    else
        -- Not a packet we care about for the job/level change stuff.
        return;
    end

    if mjob ~= lastStats.mainJob or mjobLevel ~= lastStats.mainLevel then
        local jobName = resources:GetString('jobs.names_abbr', mjob):trimend('\x00');
        lastStats.mainJob = mjob;
        lastStats.mainLevel = mjobLevel;
        mainJobChange:trigger(utils.ShiftJIS_To_UTF8(jobName), mjobLevel);
    end
    if sjob ~= lastStats.subJob or sjobLevel ~= lastStats.subLevel then
        local jobName = resources:GetString('jobs.names_abbr', sjob):trimend('\x00')
        lastStats.subJob = sjob;
        lastStats.subLevel = sjobLevel;
        subJobChange:trigger(utils.ShiftJIS_To_UTF8(jobName), sjobLevel);
    end
end)


----------------------
-- Zone Change
----------------------

local zoneChange = EventEmitter.new();
local lastZone;
packetIn:on(function(pkt)
    ---@cast pkt IncommingPacket
    if pkt.id == 0x00A then
        zoneChange:trigger();
    end
end);


---------------------
-- Combat Action
---------------------

local skillchain = EventEmitter.new();
local skillchainCombatTypes = T { 3, 4, 6, 11, 13 }
packetIn:on(function(pkt)
    ---@cast pkt IncommingPacket
    if pkt.id ~= 0x028 then return; end

    -- https://github.com/LandSandBoat/server/blob/base/src/map/packets/s2c/0x028_battle2.cpp
    
    -- this packet contains a uint8_t worksize; variable after the common packet header.
    -- we can safely ignore it.
    local header = pktHeaderSize + 8;

    -- Need to pull target id, cmd_no, has_proc, and proc_kind
    local cmdMath = header + 32 + 10
    local cmd = ashita.bits.unpack_be(pkt.data_raw, cmdMath, 4);
    if not skillchainCombatTypes:contains(cmd) then
        return;
    end

    local targetMath = cmdMath + 4 + 32 + 32;
    local targetId = ashita.bits.unpack_be(pkt.data_raw, targetMath, 32);

    local hasProcMath = targetMath + 32 + 4 + 3 + 2 + 12 + 5 + 5 + 17 + 10 + 31;
    local hasProc = ashita.bits.unpack_be(pkt.data_raw, hasProcMath, 1);
    if hasProc == 0 then
        return;
    end

    local procMath = hasProcMath + 1
    local proc = ashita.bits.unpack_be(pkt.data_raw, procMath, 6);
    if proc == 0 then
        return;
    end

    local sc = xi.Skillchains[proc];
    skillchain:trigger(targetId, sc)
end);


local Export = {
    packetIn = packetIn,
    mainJobChange = mainJobChange,
    subJobChange = subJobChange,
    zoneChange = zoneChange,
    skillchain = skillchain,
    -- timer = timer,
    render = render,
};

function Export.onProfileLoad()
    installPacketIn()
    installGameTick()
end

function Export.onProfileUnload()
    uninstallGameTick()
    uninstallPacketIn()
end

return Export;