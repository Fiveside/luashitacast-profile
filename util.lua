local Export = {};

local function table_tostring(o)
-- function Export.table_tostring(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. table_tostring(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

Export.table_tostring = table_tostring;

function Export.compress_tables(...)
    local fin = {};
    local arg = {...};
    for _i, t in ipairs(arg) do
        for k, v in pairs(t) do
            fin[k] = v
        end
    end
    return fin
end

-- extendedSets is intended to be a table of this format:
--[[
    {
        BaseSetName = {
            ExtendedSetName = {...set details...}
        }
    }
]]
-- and baseSets is intedned to be a table of this format:
--[[
    {
        BaseSetName = {...set details...}
    }
]]
-- and we merge them all.  This is a convenience function for table assign.

function Export.extend_sets(sets, baseSets, extendedSets)
    for baseSetName, extensionTable in pairs(extendedSets) do
        for extensionName, extensionSet in pairs(extensionTable) do
            sets[extensionName] = Export.compress_tables(baseSets[baseSetName], extensionset)
        end
    end
end

local PERFORMANCE_FREQUENCY = ashita.time.query_performance_frequency().quad_part;

--- A timestamp with approximately millisecond resolution.  Not tied to wall time.
---@return number
function Export.now()
    local pc = ashita.time.query_performance_counter().quad_part;
    return (pc * 1000) / PERFORMANCE_FREQUENCY;
end

---@class SetSelector
---@field keybind string the keybind associated with this set
local SetSelector = {};

Export.SetSelector = SetSelector;

---Create a new set selector
---@param name string The name of the selector displayed in the ui.
---@param keybind string The keybind that will be installed to switch this selector
---@param sets table The global sets object for the current profile.
---@return table|SetSelector
function SetSelector.new(name, keybind, sets)
    -- sets should be the profile.sets object
    local this = {
        _sets = sets,
        options = T{},
        name = name,
        selectedName = nil,
        overrideName = nil,
        keybind = keybind,
    }
    return setmetatable(this, {__index = SetSelector})
end

---Add a new set to this selector
---@param setName string the key to index into the global sets object for to find this set
---@param displayName string The string to print in the UI when this set is selected
function SetSelector:addSet(setName, displayName)
    self.options[setName] = displayName;
end

---Configure this set selector to use a specified set
---@param setName string the name of the set to select
function SetSelector:use(setName)
    if self.options[setName] == nil then
        error("Unregistered set name: " .. setName);
    end
    self.overrideName = nil;
    self.selectedName = setName;
    -- return self._sets[setName];
end

---Configure this set selector to choose the next registered set.
function SetSelector:rotate()
    local setNames = T(self.options):sortkeys();
    local nextIndex = 1;
    for idx, name in ipairs(setNames) do
        if name == self.selectedName then
            if idx ~= #setNames then
                nextIndex = idx+1;
            end
        end
    end
    self.selectedName = setNames[nextIndex];
end

---Declare an override set that should superceed the user's set choice
---@param setName string the name of the set to select
function SetSelector:override(setName)
    if setName ~= nil and self.options[setName] == nil then
        error("Unregistered set name: " .. setName);
    end
    self.overrideName = setName;
end

---Return the name of the set displayed to the UI
---@return string
function SetSelector:getDisplayName()
    return self.options[self.selectedName];
end

---If an override is declared, return the display name of that set
---@return string?
function SetSelector:getOverrideName()
    if self.overrideName == nil then
        return nil;
    end
    return self.options[self.overrideName]
end

---Return the set that has been selected
---@return GearSet
function SetSelector:getSet()
    if self.overrideName ~= nil then
        return self._sets[self.overrideName];
    end
    return self._sets[self.selectedName];
end

return Export;