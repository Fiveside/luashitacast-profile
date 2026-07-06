---@alias GearSlot
---| '"Main"'
---| '"Sub"'
---| '"Range"'
---| '"Ammo"'
---| '"Head"'
---| '"Neck"'
---| '"Ear1"'
---| '"Ear2"'
---| '"Body"'
---| '"Hands"'
---| '"Ring1"'
---| '"Ring2"'
---| '"Back"'
---| '"Waist"'
---| '"Legs"'
---| '"Feet"'

---@alias GearSet
---| { [GearSlot]: string }

---@alias PriorityGearSet
---| { [GearSlot]: string[] }

-- Because for some reason, we don't have the definition for T in the official ashita
-- type files

---@generic _T_Shorthand : {}
---@param p1 `_T_Shorthand`
---@return _T_Shorthand
function T(p1) end
