-- Tracking if a target has a skillchain on it
local events = require("events");
local Xi = require("xi");

---------------------
-- Magic burst windows
---------------------

---@type table<integer, {coro: thread, sc: SkillchainDefinition}>
local SKILLCHAIN_TRACKING = T {};

events.skillchain:on(function(targetId, sc)
    local coro = ashita.tasks.once(10, function()
        SKILLCHAIN_TRACKING[targetId] = nil;
    end);
    if SKILLCHAIN_TRACKING[targetId] ~= nil then
        coroutine.kill(SKILLCHAIN_TRACKING[targetId].coro)
    end
    SKILLCHAIN_TRACKING[targetId] = {
        sc = sc,
        coro = coro,
    };
end);

local Export = {};

---Return any active skillchain on the target, nil otherwise
---@param targetId integer
---@return SkillchainDefinition?
function Export.getSkillchain(targetId)
    local state = SKILLCHAIN_TRACKING[targetId];
    if state ~= nil then
        return state.sc
    end
end

---------------------
-- Tresure hunter tracking (personal only)
---------------------

-- Assume that treasure hunter is applied to the target if we are a THF, and an action is applied to the target
-- Assume that treasure hunter falls off a target if:
-- - The target dies.
-- - The target de-agros
-- - The target is not rendered for five minutes. (normal overworld respawn timer)
-- - We zone

-- The following abilities don't engage a mob and should be excluded from TH detection
local NON_TH_ACTIONS = {
    -- [52] = true, -- Charm (only on success)
    [53] = true, -- Gauge
    [54] = true, -- Tame
    [69] = true, -- Fight
    [88] = true, -- Assault
}

---Return true if this action should proc TH.
---@param action CombatAction
---@param result CombatActionTargetResult
---@return boolean
local function isValidTHAction(action, result)
    if action.cmd == 6 then -- Ability completes
        -- Testing for charm success specifically
        if action.cmd_arg == 52 and result.message == 136 then
            return false;
        end
        return not NON_TH_ACTIONS[action.cmd_arg];
    end
    return true;
end

-- Map of server IDs to the current TH tracking state if we think this target has TH applied on them.
---@type table<integer, {expires: integer}>
local TH_TRACKING = T {};

---@param targetId integer
local function applyTh(targetId)
    local thState = TH_TRACKING[targetId];
    if thState == nil then
        thState = { expires = 0 };
        TH_TRACKING[targetId] = thState;
    end

    -- Set expiration time to now + 5 mins, as that's the default mob respawn timer.
    thState.expires = os.time() + 600;
end

---Returns true if the player character has applied treasure hunter to this target.
---@param serverId integer
---@return boolean
function Export.isTreasureHunterApplied(serverId)
    return TH_TRACKING[serverId] ~= nil;
end

-- th tracking housekeeping.  Refresh timeouts on all entities we can see and drop tracking on expired ones.
events.eachSecond:on(function()
    local now = os.time();

    for serverId, state in pairs(TH_TRACKING) do
        local entity = Xi.getEntityByServerId(serverId);

        -- flag is set if the entity is currently being rendered.
        if entity ~= nil and bit.band(entity.Render.Flags0, 0x200) > 0 then
            state.expires = os.time()
        end

        if state.expires < now then
            TH_TRACKING[serverId] = nil;
        end
    end
end);

-- Begin tracking when we attack a target and our main job is thief.
events.combatAction:on(function(action)
    ---@cast action CombatAction
    local party = AshitaCore:GetMemoryManager():GetParty();
    local playerId = party:GetMemberServerId(0);
    local mainJob = party:GetMemberMainJob(0);
    if action.actor ~= playerId or mainJob ~= Xi.JobId.THF then
        return;
    end

    for _, target in ipairs(action.targets) do
        for _, result in ipairs(target.results) do
            if isValidTHAction(action, result) then
                applyTh(target.target);
            end
        end
    end
end);

-- Stop tracking on mob death
events.death:on(function(serverId, entityIndex)
    TH_TRACKING[serverId] = nil;
end);

-- Stop tracking on mob despawn
events.despawn:on(function(serverId, entityIndex)
    TH_TRACKING[serverId] = nil;
end);

return Export;
