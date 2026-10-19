-- Defines sets that are enabled via slash commands
-- eg /lac fwd toggle HELM would equip an appropriate HELM set

---@class ToggleSet
---@field enabled boolean true if this set is enabled
local ToggleSet = {};

---Create a new toggle set
---@param name string The slash command to be installed.
---@return ToggleSet
function ToggleSet.new(name)
    local this = {
        name = name,
        enabled = false,
    };
    return setmetatable(this, { __index = ToggleSet });
end

---Toggles this set, returning the new state.  Pass a value to force it into a state.
---@param newState any
---@return boolean
function ToggleSet:toggle(newState)
    if newState == nil then
        self.enabled = not self.enabled;
    else
        self.enabled = newState;
    end
    return self.enabled;
end
