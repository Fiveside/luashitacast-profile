local UUID4 = require('uuid/uuid4');

local Export = {};

function Export.table_tostring(o)
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

function Export.table_assign(...)
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
            sets[extensionName] = Export.table_assign(baseSets[baseSetName], extensionset)
        end
    end
end

function Export.create_event_name(prefix)
    return prefix .. '_' .. UUID4.getUUID();
end

-- function Export.

return Export;