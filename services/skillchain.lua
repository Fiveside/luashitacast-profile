local BattlePacket = require('services.battle_packet');

local Export = {};

---@alias Skillchain
---| "Light"
---| "Darkness"
---| "Gravitation"
---| "Fragmentation"
---| "Distortion"
---| "Fusion"
---| "Compression"
---| "Liquefaction"
---| "Induration"
---| "Reverberation"
---| "Transfixion"
---| "Scission"
---| "Detonation"
---| "Impaction"
---| "Radiance"
---| "Umbra"

---@type Skillchain[]
local SKILLCHAIN_BY_ID = T{
    [1] = "Light",
    [2] = "Darkness",
    [3] = "Gravitation",
    [4] = "Fragmentation",
    [5] = "Distortion",
    [6] = "Fusion",
    [7] = "Compression",
    [8] = "Liquefaction",
    [9] = "Induration",
    [10] = "Reverberation",
    [11] = "Transfixion",
    [12] = "Scission",
    [13] = "Detonation",
    [14] = "Impaction",
    [15] = "Radiance",
    [16] = "Umbra",
}

---@type table<Skillchain, Element[]>
local SKILLCHAIN_ELEMENTS = T{
    Light = T{"Light", "Thunder", "Fire", "Wind"},
    Darkness = T{"Dark", "Ice", "Water", "Earth"},
    Gravitation = T{"Dark", "Earth"},
    Fragmentation = T{"Fire", "Wind"},
    Distortion = T{"Ice", "Water"},
    Fusion = T{"Light", "Fire"},
    Compression = T{"Dark"},
    Liquefaction = T{"Fire"},
    Induration = T{"Ice"},
    Reverberation = T{"Water"},
    Transfixion = T{"Light"},
    Scission = T{"Earth"},
    Detonation = T{"Wind"},
    Impaction = T{"Thunder"},
    Radiance = T{"Light", "Thunder", "Fire", "Wind"},
    Umbra = T{"Dark", "Ice", "Water", "Earth"},
};

local function onPacketIn(events, packetEvent)
    if not BattlePacket.isPossibleSkillchainEvent(packetEvent) then
        return;
    end

    local bp = BattlePacket.parseIncomingEvent(packetEvent);

    for _, target in pairs(bp.targets) do
        for _, result in pairs(target.results) do
            if result.has_proc then
                local sc = result.proc_kind;
                if sc ~= 0 then -- No skillchain
                    events:trigger(events.SKILLCHAIN, target.m_uID, SKILLCHAIN_BY_ID[sc]);
                end
            end
        end
    end
end

---@type table<integer, {skillchain: Skillchain, nonce: {}, elements: Element[]}>
local ACTIVE_BURST_WINDOWS = T{};

local function onSkillchain(events, who, chain)
    -- If the current target has an active burst window, clear it.
    local oldWindow = ACTIVE_BURST_WINDOWS[who];
    if oldWindow ~= nil then
        events:trigger(events.MAGIC_BURST_WINDOW_CLOSE, who);
    end
    -- Register an active mb window and set a timer to clear the window
    local elements = SKILLCHAIN_ELEMENTS[chain];
    local nonce = {};
    ACTIVE_BURST_WINDOWS[who] = {
        skillchain = chain,
        elements = elements,
        nonce = nonce,
    };
    events:trigger(events.MAGIC_BURST_WINDOW_OPEN, who, chain, elements);

    -- Burst windows are open for 8 seconds (Needs verification) after the
    -- WS that closes the chain completes.  Note that this is when the
    -- WS animation begins, not ends.
    events:after(8000, function()
        local window = ACTIVE_BURST_WINDOWS[who];
        if window.nonce ~= nonce then
            -- This callback was registered for a different burst window
            -- We manually clear those windows above, so we have nothing
            -- to do here.
            return;
        end
        events:trigger(events.MAGIC_BURST_WINDOW_CLOSE, who);
    end);
end

function Export.install(events)
    events:on(events.PACKET_IN, onPacketIn)
    events:on(events.SKILLCHAIN, onSkillchain)
end

function Export.getActiveBurstWindow(targetId)
    local window = ACTIVE_BURST_WINDOWS[targetId];
    if window == nil then
        return nil;
    end
    return window.elements;
end

return Export;