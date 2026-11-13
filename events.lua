-- Allows users to register callbacks to some formalized events.

local xi = gFunc.LoadFile("xi");
local utils = gFunc.LoadFile("util");

require("common");

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
---@field private handlers table<fun(...), fun(...)>
local EventEmitter = {};
function EventEmitter.new()
    local this = {
        handlers = {},
    };
    return setmetatable(this, { __index = EventEmitter });
end

---Register a callback.  Returns a function that can be called to de-register this.
---@param callback fun(...)
---@return fun()
function EventEmitter:on(callback)
    self.handlers[callback] = callback;
    return self.off:bindn(self, callback);
end

---Unregister a callback.  Pass the same callback in to unregister it.
---@param callback fun(...)
function EventEmitter:off(callback)
    self.handlers[callback] = nil;
end

---Register a callback to be called only once.  Returns a function that can be called to de-register this.
---@param callback fun(...)
---@return fun()
function EventEmitter:once(callback)
    local function cb(...)
        callback(...);
        self:off(cb);
    end;
    return self:on(cb);
end

---Trigger this event, calling all callbacks.
---@param ... any
function EventEmitter:trigger(...)
    for cb in pairs(self.handlers) do
        cb(...);
    end
end

---Create a fanout for multiple emitters that triggers all of them when the returned emitter is triggered
---@param ... EventEmitter
---@return EventEmitter
function EventEmitter.createFanout(...)
    local proxy = EventEmitter.new();
    local registrations = {};
    for _, ee in ipairs({ ... }) do
        proxy:on(ee.trigger:bindn(ee));
    end
    return proxy;
end

---@class EventEmitterProxy: EventEmitter
local EventEmitterProxy = setmetatable({}, { __index = EventEmitter });
function EventEmitterProxy.new(emitters)
    local this = EventEmitter.new()
    this.emitters = emitters;
    this.offs = {};
    return setmetatable(this, { __index = EventEmitterProxy })
end

function EventEmitterProxy:on(callback)
    local offs = T {};
    for _, ee in ipairs(self.emitters) do
        table.insert(offs, ee:on(callback));
    end
    local offAll = function()
        for _, off in ipairs(offs) do
            off();
        end
    end
    self.offs[callback] = offAll;
end

function EventEmitterProxy:off(callback)
    local off = self.offs[callback];
    if off ~= nil then
        off()
    end
end

---Create a proxy that can be used to register a single callback for multiple events
---@param ... EventEmitter
---@return EventEmitter
function EventEmitter.with(...)
    return EventEmitterProxy.new({ ... })
end

---Create a bitreader for linear packet reads
---@param pkt any ashita packet event
---@param startingOffset integer Where in the packet to begin reading from.  Suggest 32 to skip packet header
---@return fun(numBits): integer read Call to read the next N bits
---@return fun(numBits) skip Call to skip the next N bits
local function createBitreader(pkt, startingOffset)
    local offset = startingOffset;
    local function read(numBits)
        local result = ashita.bits.unpack_be(pkt.data_raw, offset, numBits);
        offset = offset + numBits;
        return result;
    end
    local function skip(numBits)
        offset = offset + numBits;
    end
    return read, skip;
end

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
    ashita.events.register("d3d_present", "lac_events_d3d_present", function()
        -- timer:tick();
        render:trigger();
    end)
end
local function uninstallGameTick()
    ashita.events.unregister("d3d_present", "lac_events_d3d_present");
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
        local jobOffset = pktHeaderSize + 64;
        mjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset, 8)
        mjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 8, 8)
        sjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 16, 8)
        sjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 24, 8);
    elseif pkt.id == 0x0DD then
        -- Party member update packet.
        -- We're checking this packet as well because of the following scenario:
        -- If you are in a level synced party where the sync is someone else
        -- If the sync levels up, then pkt 0x061 isn't sent.  However, this packet is.
        -- Therefore we can fire the job change events when pt member 0 (us) receives the update.
        -- This might be private server behavior, have not yet checked retail.

        local partyMemberId = ashita.bits.unpack_be(pkt.data_raw, pktHeaderSize, 9);
        local playerEntity = GetPlayerEntity();
        if (playerEntity == nil) then
            return;
        end
        if partyMemberId ~= playerEntity.ServerId then
            return;
        end

        local partyMemberNoOffset = pktHeaderSize + 128 + 32 + 16;
        -- local partyMemberNo = ashita.bits.unpack_be(pkt.data_raw, partyMemberNoOffset, 8);

        -- print("MJC from 0x0DD pt: " .. tostring(partyMemberNo))
        -- if partyMemberNo ~= 0 then
        --     return;
        -- end

        local jobOffset = partyMemberNoOffset + 64;
        mjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset, 8);
        mjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 8, 8)
        sjob = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 16, 8)
        sjobLevel = ashita.bits.unpack_be(pkt.data_raw, jobOffset + 24, 8);

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
        local jobName = resources:GetString("jobs.names_abbr", mjob):trimend("\x00");
        lastStats.mainJob = mjob;
        lastStats.mainLevel = mjobLevel;
        mainJobChange:trigger(utils.ShiftJIS_To_UTF8(jobName), mjobLevel);
    end
    if sjob ~= lastStats.subJob or sjobLevel ~= lastStats.subLevel then
        local jobName = resources:GetString("jobs.names_abbr", sjob):trimend("\x00")
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

---@class CombatActionTargetResult
---@field miss integer Enum describing how the hit connected (hit, miss, evade, dodge, etc.)
---@field message integer Enum string lookup for the log message template to use for this action result
---@field proc {kind: integer}? If a proc occurred with this result, then this is populated with the proc.

---@class CombatActionTarget
---@field target integer target's server ID
---@field results CombatActionTargetResult[] The list of results from an action

---@class CombatAction
---@field actor integer actor's server ID
---@field cmd integer the kind of action being taken
---@field cmd_arg integer a context sensitive value based on the value of cmd
---@field targets CombatActionTarget[] The list of targets this action affects

local combatAction = EventEmitter.new();
packetIn:on(function(pkt)
    ---@cast pkt IncommingPacket
    if pkt.id ~= 0x028 then return; end

    -- We get tons of these, and they're bitpacked; making parsing expensive.
    -- So instead of parsing the whole thing, we just parse as much as we currently need
    -- and change the logic here to read or skip as the needs change.
    local read, skip = createBitreader(pkt, pktHeaderSize);

    -- https://github.com/atom0s/XiPackets/blob/main/world/server/0x0028/README.md
    -- https://github.com/LandSandBoat/server/blob/base/src/map/packets/s2c/0x028_battle2.cpp
    -- https://github.com/LandSandBoat/server/issues/4152#issuecomment-1646781138
    -- https://github.com/AshitaXI/Ashita-v4beta/blob/main/addons/actionparse/parser.lua

    -- this packet contains a uint8_t worksize; variable after the common packet header.
    -- we can safely ignore it.
    skip(8);

    local actorId = read(32);

    local trg_sum = read(4);
    skip(4); -- res_sum
    local cmd_no = read(4);
    local cmd_arg = read(32);
    skip(32); -- info

    local action = T {
        actor = actorId,
        cmd = cmd_no,
        cmd_arg = cmd_arg,
        targets = T {},
    };

    -- Target parsing
    for _i = 1, trg_sum do
        local targetId = read(32);
        local result_sum = read(4);
        local target = T {
            target = targetId,
            results = T {},
        }
        table.insert(action.targets, target);

        -- Result parsing.  This section has variable size, so we need
        -- to read the whole thing to find all targets.
        for _j = 1, result_sum do
            local result = T {};
            table.insert(target.results, result)

            skip(3);  -- miss
            skip(2);  -- kind
            skip(12); -- sub_kind
            skip(5);  -- info
            skip(5);  -- scale
            skip(17); -- value
            result.message = read(10);
            skip(31); -- bit

            local has_proc = read(1) > 0;
            local proc = T { kind = 0 };
            if has_proc then
                result.proc = proc;
                proc.kind = read(6); -- kind
                skip(4);             -- info
                skip(17);            -- value
                skip(10);            -- message
            end

            if read(1) > 0 then -- has_react
                skip(6);        -- kind
                skip(4);        -- info
                skip(14);       -- value
                skip(10);       -- message
            end
        end
    end

    combatAction:trigger(action);
end);

---------------------
-- Skillchain
---------------------

local skillchain = EventEmitter.new();
local skillchainCombatTypes = T { 3, 4, 6, 11, 13 }
combatAction:on(function(action)
    ---@cast action CombatAction

    if not skillchainCombatTypes:contains(action.cmd) then
        return;
    end

    -- Skillchains only proc on the first target in the targets list.  There's currently a bug
    -- in LSB where a blue aoe chain affinity spell says it triggers a chain on every target it hits
    -- if the designated target did trigger a chain.  This isn't true, and the other targets aren't actually
    -- being chained on.  So we purposefully ignore every target aside from the first.
    local result = action.targets[1].results[1];
    if result == nil or result.proc == nil then
        return;
    end

    local sc = xi.Skillchains[result.proc.kind];
    skillchain:trigger(action.targets[1].target, sc);
end);


---------------------
-- Pet actions
---------------------

local petActionComplete = EventEmitter.new();
combatAction:on(function(action)
    ---@cast action CombatAction
    if action.cmd ~= 13 then
        return;
    end
    petActionComplete:trigger(action.actor, action)
end);

---------------------
-- Inventory Updates
---------------------

local inventoryUpdate = EventEmitter.new();

-- we get loads of packets indicating the inventory has been updated.
inventoryUpdate.trigger = utils.throttle(1, inventoryUpdate.trigger);

packetIn:on(function(pkt)
    -- Packet governs when the loading indicators at the top of the screen
    -- should appear.  They only appear when streaming inventory updates from the server.
    -- Most commonly seen after zoning.
    if pkt.id == 0x1D then
        local state = ashita.bits.unpack_be(pkt.data_raw, pktHeaderSize, 8);
        -- local flags = ashita.bits.unpack_be(pkt.data_raw, pktHeaderSize + 8 + (5 * 8), 32);
        if state == 1 then
            inventoryUpdate:trigger();
        end
    end
end);


-- ATT: We export all of these event emitters as singletons.  The expectation is that
-- require('events') will execute this file once and cache the return value as a module.
-- Then, subsequent require() calls just return the cached module.  However, LuAshitaCast
-- does not use require() to load profiles.  It uses gFunc.LoadFile() instead.  Internally,
-- gFunc.LoadFile() does not do any cacheing of returned modules.  Thus every time gFunc.LoadFile()
-- is called, it executes the file and returns a fresh instance of the returned module.
-- This means that any modules returned by identical gFunc.LoadFile() calls are distinct.
-- Including the event emitters returned here.  This is why we use require() everywhere in
-- the profile code; so that the singletons returned by modules remain unique and aren't
-- duplicated.  LuAshitaCast itself uses gFunc.LoadFile() to load a job profile, however.
-- So every time LuAshitaCast imports a profile, the file is re-executed.  require() calls
-- in the profile still return the cached modules, as expected.  But any event callbacks
-- registered in the profile file itself will be re-registered.  EventEmitter uses the
-- callback function itself as the unique registration key.  So anonymous functions and
-- functions from freshly parsed and executed lua code (such as during gFunc.LoadFile())
-- will generate additional entries in the emitter's callback list.  EventEmitter also
-- does not currently have a published method of un-registering a callback, and doesn't have
-- a way of clearing handlers loaded inside the main profile file (the one that gets
-- re-executed by gFunc.LoadFile()).
--
-- All this means that when the user changes jobs (for example from from MNK->BLM) new
-- callbacks are registered (in BLM.lua) and old callbacks are not un-registered (in MNK.lua).
--
-- The Export.profile table contains an identical separate set of emitters specifically for profile code.
-- When the profile is unloaded, (via onProfileUnload()), all these emitters will be cleared
-- allowing users to register event handlers inside of profile code without worrying about
-- cleanup when the profile is unloaded. Thus your profile file should use this:
-- local events = require('events').profile;
-- while everything outside of the profile file can just import events as normal.


local profileLoad = EventEmitter.new();
local profileUnload = EventEmitter.new();

local Export = {
    packetIn = packetIn,
    profileLoad = profileLoad,
    profileUnload = profileUnload,
    mainJobChange = mainJobChange,
    subJobChange = subJobChange,
    zoneChange = zoneChange,
    combatAction = combatAction,
    skillchain = skillchain,
    -- timer = timer,
    render = render,
    inventoryUpdate = inventoryUpdate,
    petActionComplete = petActionComplete,
};

-- This assumes that the export contains _only_ event emitters and
-- that anything that isn't an event emitter has a key on Export.profile
-- already, ensuring that Export.profile.mt.__index isn't called.
---@type table<string, {proxy: EventEmitter, off: fun()}>
local profileEmitterCache = T {};
local profileIndex = function(table, key)
    if profileEmitterCache[key] ~= nil then
        return profileEmitterCache[key].proxy;
    end
    if Export[key] == nil then
        print(debug.traceback(string.format("Key error: %s", key)))
        error(string.format("Cannot create profile proxy for %s: No emitter with that name exists.", key));
    end
    -- We can take advantage of the profile unload hook to unregister
    -- and clear these proxies.  Once an emitter is evicted from the
    -- cache, all references to it should be gone.
    local proxy = EventEmitter.new();
    local off = Export[key]:on(proxy.trigger:bind1(proxy));
    profileEmitterCache[key] = { proxy = proxy, off = off };
    profileUnload:once(function()
        off();
        profileEmitterCache[key] = nil;
    end);

    -- Just in-case we're stupid today.
    proxy.trigger = function()
        error("This is a proxied emitter, do not directly trigger events on this emitter.");
    end;

    return proxy;
end

Export.profile = setmetatable({}, { __index = profileIndex });

function Export.onProfileLoad()
    installPacketIn()
    installGameTick()
    profileLoad:trigger();
end

function Export.onProfileUnload()
    profileUnload:trigger();
    uninstallGameTick()
    uninstallPacketIn()
end

-- Also include the onprofile load and onprofile unload in the
-- profile proxy for easy usage and to keep the require() logic down to 1 line.
Export.profile.onProfileLoad = Export.onProfileLoad;
Export.profile.onProfileUnload = Export.onProfileUnload;

return Export;
