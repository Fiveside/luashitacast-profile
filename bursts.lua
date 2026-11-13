-- Tracking if a target has a skillchain on it
local events = require("events");

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
local TH_TRACKING = T {};

---@param target CombatActionTarget
local function applyTh(target)
    local id = target.target;
    local thState = TH_TRACKING[id];
end

events.combatAction:on(function(action)
    ---@cast action CombatAction
    local playerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    if action.actor ~= playerId then
        return;
    end

    for _, target in ipairs(action.targets) do
        for _, result in ipairs(target.results) do
            if isValidTHAction(action, result) then
                applyTh(target);
            end
        end
    end
end)

return Export;
