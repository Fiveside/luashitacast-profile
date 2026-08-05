-- Detect if a target has a skillchain on it

local COMMAND_TYPES = T { 3, 4, 6, 11, 13 };

---@class SkillchainInfo
---@field Name string
---@field Elements string[]

local SKILLCHAINS = T {
    [1] = T { Name = "Light", Elements = T { "Light", "Thunder", "Fire", "Wind" } },
    [2] = T { Name = "Darkness", Elements = T { "Dark", "Ice", "Water", "Earth" } },
    [3] = T { Name = "Gravitation", Elements = T { "Dark", "Earth" } },
    [4] = T { Name = "Fragmentation", Elements = T { "Fire", "Wind" } },
    [5] = T { Name = "Distortion", Elements = T { "Ice", "Water" } },
    [6] = T { Name = "Fusion", Elements = T { "Light", "Fire" } },
    [7] = T { Name = "Compression", Elements = T { "Dark" } },
    [8] = T { Name = "Liquefaction", Elements = T { "Fire" } },
    [9] = T { Name = "Induration", Elements = T { "Ice" } },
    [10] = T { Name = "Reverberation", Elements = T { "Water" } },
    [11] = T { Name = "Transfixion", Elements = T { "Light" } },
    [12] = T { Name = "Scission", Elements = T { "Earth" } },
    [13] = T { Name = "Detonation", Elements = T { "Wind" } },
    [14] = T { Name = "Impaction", Elements = T { "Thunder" } },
    [15] = T { Name = "Radiance", Elements = T { "Light", "Thunder", "Fire", "Wind" } },
    [16] = T { Name = "Umbra", Elements = T { "Dark", "Ice", "Water", "Earth" } },
}


local PERFORMANCE_FREQUENCY = ashita.time.query_performance_frequency().quad_part;

--- A timestamp with approximately millisecond resolution.
---@return number
local function now()
    local pc = ashita.time.query_performance_counter().quad_part;
    return (pc * 1000) / PERFORMANCE_FREQUENCY;
end

---@type table<integer, {time: integer, chain: SkillchainInfo}>
local TARGET_STATE = T{};

---@type fun(integer, SkillchainInfo)[]
local SKILLCHAIN_CALLBACKS = T{};

local function onSkillchain(targetId, chainId)
    local chainInfo = SKILLCHAINS[chainId];
    TARGET_STATE[targetId] = {
        time = now(),
        chain = chainInfo,
    };

    print("Skillchain " .. chainInfo.Name);

    for _, cb in ipairs(SKILLCHAIN_CALLBACKS) do
        cb(targetId, chainInfo);
    end
end

local function housekeeping()
    local now = now();
    for targetId, state in pairs(TARGET_STATE) do
        if now < state.time + 10000 then -- Is it always 10 seconds per mb window?
            TARGET_STATE[targetId] = nil;
        end
    end
end

local function onPacketIn(pkt)
    housekeeping();

    if pkt.id ~= 0x28 then
        return;
    end

    -- We're going to assume one target, and one result inside
    -- the packet.

    -- 40 bits for the common packet header
    -- 42 bits to reach cmd_no
    local typ = ashita.bits.unpack_be(pkt.data_raw, 40 + 42, 4);
    if not COMMAND_TYPES:contains(typ) then
        return;
    end

    -- 40 bits for common packet header
    -- 46 to reach past cmd_no
    -- 32 info
    -- inside 1st target block
    -- 32 target id
    -- 4 num results
    -- inside 1st result block
    -- 3 miss
    -- 2 kind
    -- 12 sub_kind
    -- 5 info
    -- 5 scale
    -- 17 value
    -- 10 message
    -- 31 bit
    -- 1 has_proc
    -- 6 proc_kind

    -- Need to pull target id, has_proc, and proc_kind
    local targetMath = 40 + 46 + 32
    local targetId = ashita.bits.unpack_be(pkt.data_raw, targetMath, 32);

    local hasProcMath = 40 + 46 + 32 + 32 + 4 + 3 + 2 + 12 + 5 + 5 + 17 + 10 + 31
    local hasProc = ashita.bits.unpack_be(pkt.data_raw, hasProcMath, 1);
    if hasProc == 0 then
        return;
    end

    local procMath = 40 + 46 + 32 + 32 + 4 + 3 + 2 + 12 + 5 + 5 + 17 + 10 + 31 + 1
    local proc = ashita.bits.unpack_be(pkt.data_raw, procMath, 6);
    if proc == 0 then
        return;
    end

    onSkillchain(targetId, proc);
end


local Export = T{};

---Returns a skillchain block for a target or nil if one doesn't exist
---@param targetId integer
---@return SkillchainInfo?
function Export.getSkillchain(targetId)
    local state = TARGET_STATE[targetId];
    if state ~= nil then
        return state.chain;
    end
end

Export.onPacketIn = onPacketIn;

---Register a callback to be called when a skillchain occurs.
---@param callback fun(integer, SkillchainInfo)
function Export.onSkillchain(callback)
    table.insert(SKILLCHAIN_CALLBACKS, callback);
end

function Export.onProfileLoad()
    -- reset state
    SKILLCHAIN_CALLBACKS = T{};
    TARGET_STATE = T{};
end

-- Also reset state on unload just in case we forget.
Export.onProfileUnload = Export.onProfileLoad;

return Export;