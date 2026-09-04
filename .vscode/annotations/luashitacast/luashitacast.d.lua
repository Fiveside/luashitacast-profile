---@meta

---@alias LAC.CurrentCall
---| '"OnLoad"'
---| '"OnUnload"'
---| '"HandleCommand"'
---| '"HandleDefault"'
---| '"HandleAbility"'
---| '"HandleItem"'
---| '"HandlePrecast"'
---| '"HandleMidcast"'
---| '"HandlePreshot"'
---| '"HandleMidshot"'
---| '"HandleWeaponskill"'
---| '"N/A"'

---@alias LAC.ActionType
---| '"White Magic"' Spell actions
---| '"Black Magic"' Spell actions
---| '"Summoning"' Spell actions
---| '"Ninjutsu"' Spell actions
---| '"Bard Song"' Spell actions
---| '"Blue Magic"' Spell actions
---| '"Rune Enchantment"' Ability actions
---| '"Ready"' Ability actions
---| '"Blood Pact: Rage"' Ability actions
---| '"Blood Pact: Ward"' Ability actions
---| '"Corsair Roll"' Ability actions
---| '"Quick Draw"' Ability actions
---| '"Unknown"'

---@alias LAC.ActionSkill
---| '"Divine Magic"'
---| '"Healing Magic"'
---| '"Enhancing Magic"'
---| '"Enfeebling Magic"'
---| '"Elemental Magic"'
---| '"Dark Magic"'
---| '"Summoning"'
---| '"Ninjutsu"'
---| '"Singing"'
---| '"Blue Magic"'
---| '"Geomancy"'
---| '"Unknown "'

---@alias LAC.Element
---| '"Fire"'
---| '"Ice"'
---| '"Wind"'
---| '"Earth"'
---| '"Thunder"'
---| '"Water"'
---| '"Light"'
---| '"Dark"'
---| '"Non-Elemental"'
---| '"Unknown"'

---@alias LAC.ActionCategory
---| '"Spell"'
---| '"Weaponskill"'
---| '"Ability"'
---| '"Ranged"'
---| '"Item"'

---@alias LAC.EntityType
---| '"PC"'
---| '"NPC"'
---| '"Alliance"'
---| '"Party"'
---| '"Monster"'
---| '"Unknown"'

---@alias LAC.EntityStatus
---| '"Idle"'
---| '"Engaged"'
---| '"Dead"'
---| '"Zoning"'
---| '"Resting"'
---| '"Unknown"'

---@alias LAC.GData.GetBuffCountArgs
---| 'string' The name of the buff you are checking for
---| 'number' The ID of the buff you are checking for

---@alias LAC.WeatherElement
---| '"None"'
---| '"Fire"'
---| '"Earth"'
---| '"Water"'
---| '"Wind"'
---| '"Ice"'
---| '"Thunder"'
---| '"Light"'
---| '"Dark"'
---| '"Unknown"'

---@alias LAC.Weather
---| '"Clear"'
---| '"Sunshine"'
---| '"Clouds"'
---| '"Fog"'
---| '"Fire"'
---| '"Fire x2"'
---| '"Water"'
---| '"Water x2"'
---| '"Earth"'
---| '"Earth x2"'
---| '"Wind"'
---| '"Wind x2"'
---| '"Ice"'
---| '"Ice x2"'
---| '"Thunder"'
---| '"Thunder x2"'
---| '"Light"'
---| '"Light x2"'
---| '"Dark"'
---| '"Dark x2"'
---| '"Unknown"'

---@alias LAC.MoonPhase
---| '"Full Moon"'
---| '"Waning Gibbous"'
---| '"Last Quarter"'
---| '"Waning Crescent"'
---| '"New Moon"'
---| '"Waxing Crescent"'
---| '"First Quarter"'
---| '"Waxing Gibbous"'
---| '"Unknown"'

---@alias LAC.Weekday
---| '"Firesday"'
---| '"Earthsday"'
---| '"Watersday"'
---| '"Windsday"'
---| '"Iceday"'
---| '"Lightningday"'
---| '"Lightsday"'
---| '"Darksday"'
---| '"Unknown"'

---@alias LAC.Container
---| '"Inventory"'
---| '"Safe"'
---| '"Storage"'
---| '"Temporary"'
---| '"Locker"'
---| '"Satchel"'
---| '"Sack"'
---| '"Case"'
---| '"Wardrobe"'
---| '"Safe2"'
---| '"Wardrobe2"'
---| '"Wardrobe3"'
---| '"Wardrobe4"'

---@alias LAC.GearSlot
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

---@alias LAC.GearSlotReference
---| number the 1-based index of the slot you want to equip to(1-16)
---| LAC.GearSlot the name of the slot you want to equip to

---@class LAC.DetailedGearReference
---@field Name string Must be specified. The item to be equipped has to have a name matching the value of this member.
---@field Bag integer|LAC.Container? The item must be in this container to be equipped. Please note that while the tag supports all containers, only heavily modified Topaz servers can equip from anything besides inventory or wardrobes.
---@field Augment string|string[]? At least one of the item's augments must match the string to be equipped. The augment must match all strings if this is a table
---@field AugPath 'A'|'B'|'C'|'D'? The item must have this augment path to be equipped.
---@field AugRank integer? The item must be exactly this rank to be equipped.
---@field AugTrial integer? The item must be on this trial to be equipped.

---@class LAC.PackerGearReference: LAC.DetailedGearReference
---@field Quantity number|"all"? This is used to tell Packer to retrieve more than one of an item. It is not needed for cases such as 2 of the same ring, as that will be handled internally. Best used for medications inside the Packer section, or ammo inside sets.

---@alias LAC.GearReference
---| string The name of the gear piece
---| LAC.DetailedGearReference A reference to the gear piece with additional discriminations

---@alias LAC.GearSlotEntry
---| LAC.GearReference The gear piece itself.
---| '"displaced"' Indicates that this gear slot will be cleared by another piece of gear (EX: Vermillion Cloak displaces head)
---| '"remove"' Unequips gear from this slot.

---@alias LAC.GearSet table<LAC.GearSlot, LAC.GearSlotEntry>

---@class LAC.Alliance
---@field ActionTarget boolean true if you are currently executing an action targeting an alliance member, false otherwise
---@field Count integer number of members in your alliance
---@field InAlly boolean true if you are currently in an alliance with members in other parties, false otherwise
---@field Target boolean true if you are currently targeting an alliance member, false otherwise

-- These are similar, but the subtle differences in fields and documentation make it easier to keep them separate.

---@class LAC.Party
---@field ActionTarget boolean true if you are currently executing an action targeting a party member, false otherwise
---@field Count integer number of members in your party
---@field InParty boolean true if you are currently in a party with other members
---@field Target boolean true if you are currently targeting a party member, false otherwise

---@class LAC.Timestamp
---@field day integer
---@field hour integer
---@field minute integer

---@class LAC.Action
---@field ActionType LAC.ActionCategory Spell Weaponskill Ability Ranged Item
---@field CastTime number the duration, in milliseconds, of a spell or item's base casttime (nil if Type is not Spell or Item)
---@field Element LAC.Element? Fire, Ice, Wind, Earth, Thunder, Water, Light, Dark, Non-Elemental, Unknown (nil if Type is not Spell)
---@field Id number the internal ID of the action
---@field MpCost number the amount of MP the spell costs (nil if Type is not Spell)
---@field Name string the action's name
---@field Recast number the recast time of the spell or item, in milliseconds (nil if Type is not Item or Spell)
---@field Resource IItem|ISpell|IAbility|nil a table from ashita API of type IItem, ISpell, IAbility (nil if Type is Ranged)
---@field Skill LAC.ActionSkill? Specifies the discipline that this spell uses. nil if this is not a spell.
---@field Type LAC.ActionType Specifies the specific kind of action (spell type or ability type)

---@class LAC.PlayerAction: LAC.Action
---@field MpAftercast number the amount of MP you will have remaining if the cast completes at full mp cost (nil if Type is not Spell)
---@field MppAftercast number the percentage of remaining MP you will have remaining if the cast completes at full mp cost (nil if Type is not Spell)
---@field Resend boolean true if this is a resend of the last action, false if not

---@class LAC.Entity
---@field Distance integer distance in yalms to the entity
---@field HPP number the entity's current HP percentage
---@field Id integer the entity's unique-to-game ID
---@field Index integer the entity's index within the current zone
---@field Name string the entity's name
---@field Status LAC.EntityStatus Idle, Engaged, Dead, Zoning, Resting, Unknown
---@field Type LAC.EntityType PC, NPC, Alliance, Party, Monster, Unknown

---@class LAC.Environment
---@field Area string the zone you are currently in
---@field Day string Firesday, Earthsday, Watersday, Windsday, Iceday, Lightningday, Lightsday, Darksday, Unknown
---@field DayElement string Fire, Earth, Water, Wind, Ice, Thunder, Light, Dark, Unknown
---@field MoonPhase string Full Moon, Waning Gibbous, Last Quarter, Waning Crescent, New Moon, Waxing Crescent, First Quarter, Waxing Gibbous, Unknown
---@field MoonPercent number value from 0-100 representing moon phase
---@field RawWeather LAC.Weather Does not incorporate active storm spells
---@field RawWeatherElement LAC.WeatherElement Does not incorporate active storm spells
---@field Time number the current time in hours/minutes as a decimal for lt and gt comparisons (12:30 would return 12.30)
---@field Timestamp LAC.Timestamp The current vanadiel time
---@field Weather LAC.Weather Incorporates active storm spells
---@field WeatherElement LAC.WeatherElement Incorporates active storm spells

---@class LAC.EquipScreen
---@field Attack integer your current attack
---@field DarkResistance integer your current darkresistance
---@field Defense integer your current defense
---@field EarthResistance integer your current earth resistance
---@field FireResistance integer your current fire resistance
---@field IceResistance integer your current ice resistance
---@field LightningResistance integer your current lightning resistance
---@field LightResistance integer your current light resistance
---@field WaterResistance integer your current water resistance
---@field WindResistance integer your current wind resistance

---@class LAC.Player
---@field HP integer your current hp
---@field MaxHP integer your current max hp
---@field HPP number your current hp percent
---@field IsMoving boolean true if you've moved since last position update, false otherwise
---@field MainJob string 3 letter abbreviation for your main job
---@field MainJobLevel integer the actual level of your main job
---@field MainJobSync integer the level of your main job with any sync or cap effects applied
---@field MP integer your current mp
---@field MaxMP integer your current max mp
---@field MPP number your current mp percent
---@field Name string your character name
---@field Status LAC.EntityStatus Idle, Engaged, Dead, Zoning, Resting, Unknown
---@field SubJob string 3 letter abbreviation for your sub job
---@field SubJobLevel integer the actual level of your sub job
---@field SubJobSync integer the level of your sub job with any sync or cap effects applied
---@field TP integer your current TP

---@class LAC.GData
local gData = {};

---The current lifecycle call being handled
---@return LAC.CurrentCall
function gData.GetCurrentCall() end

---The player's current alliance
---@return LAC.Alliance
function gData.GetAlliance() end

---The currently performing action
---@return LAC.PlayerAction?
function gData.GetAction() end

---The target the current action is being performed on
---@return LAC.Entity?
function gData.GetActionTarget() end

---How many instances of the input buff you have active
---@param matchBuff LAC.GData.GetBuffCountArgs
---@return integer
function gData.GetBuffCount(matchBuff) end

---Retrieve an entity by their index
---@param index integer The entity's index in the current zone
---@return LAC.Entity?
function gData.GetEntity(index) end

---The current environment the player is in
---@return LAC.Environment
function gData.GetEnvironment() end

---The current gear the player has equipped. nil if that slot has nothing equipped.
---@return table<LAC.GearSlot, {Container: number, Item: item_t, Name: string, Resource: IItem}>
function gData.GetEquipment() end

---Stats that the player can view on their equip screen
---@return LAC.EquipScreen
function gData.GetEquipScreen() end

---The player's current pet. nil if you currently do not have a pet, or your pet is dead
---@return LAC.Entity?
function gData.GetPet() end

---The action the player's pet is currently performing. nil if your pet is dead or not currently performing an action.
---@return LAC.Action
function gData.GetPetAction() end

---The player's information
---@return LAC.Player
function gData.GetPlayer() end

---The player's current party
---@return LAC.Party
function gData.GetParty() end

---The player's current target. nil if the player isn't currently targeting anything.
---@return LAC.Entity?
function gData.GetTarget() end

---@class LAC.GFunc
local gFunc = {};

---Backs up your profile, replaces the set with your current equipment, then writes your profile back to disc.
---Will no longer modify anything besides the set in question. If the set doesn't already exist, it will be added to the end of your sets.
---This can be blocked with the gSettings.AllowAddSet setting. The gSettings.AddSetBackup setting can be set to false to prevent backups.
---For this to function, your main sets table must be initialized local sets = {, local Sets = {, or profile.Sets = {.
---@param setName string the name of the set you want to add or replace
function gFunc.AddSet(setName) end

---Recursively searches all sets for 'BaseSet' attributes, and references those sets to incorporate their items.
---Subtables should be notated with '.'
---@param baseTable {BaseSet: LAC.GearSet}[]
function gFunc.ApplyBaseSets(baseTable) end

---Cancels the pending action and any accompanying swaps when called from Precast, Preshot, Ability, Item, or Weaponskill.
function gFunc.CancelAction() end

---Changes a pending action to a different action of the same type when called from Precast, Ability, or Weaponskill.
---@param id integer the ID of the action you'd like to change to
function gFunc.ChangeActionId(id) end

---Changes a pending action to act on a different target.
---@param target integer the index of an entity within zone to change target to
function gFunc.ChangeActionTarget(target) end

---Clears all pending swaps.
function gFunc.ClearEquipBuffer() end

---Returns a new table containing the slots from override, and the slots from base where a slot in override was not present.
---@param base LAC.GearSet
---@param override LAC.GearSet
function gFunc.Combine(base, override) end

---Returns true if the provided userdata item matches the provided itemEntry using LAC's internal checks.
---@param item item_t An inventory item.
---@param itemEntry string|LAC.GearReference a name or single item table representing the piece of equipment you want to check.
---@param container integer? the container the userdata item is located in, for checking Bag attributes. If nil, bag will not be checked.
---@return boolean true if the provided userdata item matches the provided itemEntry using LAC's internal checks.
function gFunc.CompareItem(item, itemEntry, container) end

---Disables the specified slot, preventing swaps from altering the currently equipped piece.
---@param slot LAC.GearSlotReference the 1-based index of the slot (1-16) or the name of the slot. Use 'all' for all slots
function gFunc.Disable(slot) end

---Prints text of a specified color to chat log using the LuAshitacast header.
---@param color integer a value from 0 to 255 to represent the color
---@param text string the text you would like to print
function gFunc.Echo(color, text) end

---Enables the specified slot, allowing it to be changed again.
---@param slot LAC.GearSlotReference the 1-based index of the slot (1-16) or the name of the slot. Use 'all' for all slots
function gFunc.Enable(slot) end

---Equips an item to the internal buffer. This does not send a packet and can be safely called multiple times on
---the same slot. When your current stage finishes, the equipment will all be put on.
---@param slot LAC.GearSlotReference the name of the slot you want to equip to.
---@param item LAC.GearReference the item to equip in this slot
function gFunc.Equip(slot, item) end

---Equips an item set to the internal buffer. This does not send a packet and can be safely called multiple times.
---When your current stage finishes, the equipment will all be put on.
---@param set string|LAC.GearSet A gear set table or the name of a set table, which must be located directly inside the profile.Sets table
function gFunc.EquipSet(set) end

---Prints text of the default error color to chat log using the LuAshitacast header.
---@param text string the text you would like to print
function gFunc.Error(text) end

---Looks for any set ending in _Priority, then treats each slot entry containing a table as a priority list.
---Creates a new set without the _Priority suffix using the first item in each priority list to be below or at
---your level as the active slot. See example usage in tutorial.
---@param sets table your profile's base sets table
---@param level integer the level to match against
function gFunc.EvaluateLevels(sets, level) end

---Sends an equip packet directly to equip an item. This should not be used unless you specifically understand why you're using it.
---@param slot LAC.GearSlotReference the name of the slot you want to equip to.
---@param item LAC.GearReference the item to equip in this slot
function gFunc.ForceEquip(slot, item) end

---Sends equip packets to directly to equip a set. This should not be used unless you specifically understand why you're using it.
---@param set string|LAC.GearSet A gear set table or the name of a set table, which must be located directly inside the profile.Sets table
function gFunc.ForceEquipSet(set) end

---Equips an item to a secondary internal buffer. If used in midcast or midranged in combination with gFunc.SetMidDelay, this equipment
---will be worn after precast/preranged until the final equipment is put on. This will not do anything elsewhere.
---@param slot LAC.GearSlotReference the name of the slot you want to equip to.
---@param item LAC.GearReference the item to equip in this slot
function gFunc.InterimEquip(slot, item) end

---Equips an item set to a secondary internal buffer. If used in midcast or midranged in combination with gFunc.SetMidDelay, this equipment
---will be worn after precast/preranged until the final equipment is put on. This will not do anything elsewhere.
---@param set string|LAC.GearSet A gear set table or the name of a set table, which must be located directly inside the profile.Sets table
function gFunc.InterimEquipSet(set) end

---Prints text of the default message color to chat log using the LuAshitacast header.
---@param text string the text you would like to print
function gFunc.Message(text) end

---Loads a lua file, searching first for a full path match, then for a match inside ashita/config/addons/luashitacast/playername_playerid,
---then ashita/config/addons/luashitacast/, and finally in each package path(same as require).
---Should be used in place of require for any dependencies, to allow easy per-character overrides and default fallback, as well as
---prevent issues with multiple require from different profiles.
---@param path string filename or filepath to load
function gFunc.LoadFile(path) end

---Overrides all state processing and equips a set for the specified period of time. This does not bypass disable/enable.
---@param set string|LAC.GearSet A gear set table or the name of a set table, which must be located directly inside the profile.Sets table
---@param seconds number the length of seconds(decimals allowed) to lock a set on for
function gFunc.LockSet(set, seconds) end

---Uses the main, sub, range, ammo, head, body, hands, legs, and feet components of the input set to send a lockstyle packet to server.
---This happens immediately, unlike the equip functions. Fields besides name are not considered.
---@param set LAC.GearSet a set table
function gFunc.LockStyle(set) end

---When used in precast, midcast, preshot, or midshot callbacks, delays the midcast/midshot gear from going on for this period of time.
---If action completes before delay finishes, equipment won't go on at all. This can be called in the pre-events to allow easier
---synergy with fast cast and snapshot calculations.
---@param delay number how long, in seconds, to delay midcast/midshot
function gFunc.SetMidDelay(delay) end

---@class LAC.GSettings
---@field AddSetEquipScreenOrder boolean If true, addset will write your sets in the order of equip screen rows. If false, addset will write them in the order of equipment slot IDs.
---@field AllowSyncEquip boolean If true, LuAshitacast will judge equipment based on your real level and attempt to equip pieces above your current sync level. If false, LuAshitacast will not try to equip anything above your current sync level.
---@field AddSetBackups boolean If true, a timestamped backup of your profile will be saved to the 'backups' subdirectory of the folder it is in whenever you use addset.
---@field Debug boolean If enabled, LuAshitacast will print your equipment swaps to the chat log.
---@field EquipBags integer[] This determines the containers and order that LuAshitacast will search for equipment. It must be an ipairs compatible table.
---@field EnableNomadStorage boolean If true, LuAshitacast will assume you have access to storage at nomad moogles. This should not be needed in normal circumstances, as storage is not an equippable container. It was included in case of particularly bazaar Topaz implementations.
---@field ForceDisableBags integer[] Any container indices listed in this table will be treated as if you do not have access to them, regardless of whether you do. This is intended for Topaz servers that do not enable wardrobes the same way as retail.
---@field ForceEnableBags integer[] Any container indices listed in this table will be treated as if you have access to them, regardless of whether you do. This is intended for Topaz servers that do not enable wardrobes the same way as retail.
---@field PetskillDelay number  This is the time, in seconds, that LuAshitacast will wait for a pet skill to complete before assuming the completion packet was lost.
---@field WeaponskillDelay number This is the time, in seconds, that LuAshitacast will wait for a player weaponskill to complete before assuming the completion packet was lost.
---@field AbilityDelay number This is the time, in seconds, that LuAshitacast will wait for a player ability to complete before assuming the completion packet was lost.
---@field SpellOffset number Additional time, in seconds, to be added to a calculated spell casttime before assuming the completion packet was lost.
---@field RangedBase number Base time, in seconds, to wait for a ranged attack to complete before assuming the completion packet was lost.
---@field RangedOffset number Additional time, in seconds, to wait for a ranged attack to complete before assuming the completion packet was lost.
---@field ItemOffset number Additional time, in seconds, to be added to a calculated item usage time before assuming the completion packet was lost.
---@field FastCast number Value of fast cast to be used in reducing spell cast completion estimate. Can be set during precast function.
---@field Snapshot number Value of snapshot to be used in reducing ranged attack completion estimate. Can be set during preshot function.

-- https://github.com/ThornyFFXI/LuAshitacast/blob/main/config.lua

---@type LAC.GSettings
local gSettings = {
    --Miscellaneous
    AddSetEquipScreenOrder = true,
    AllowSyncEquip = true,
    AddSetBackups = true,
    -- HorizonMode = false,
    Debug = false,

    --Inventory
    EquipBags = { 8, 10, 11, 12, 13, 14, 15, 16, 0 },
    EnableNomadStorage = false,
    ForceDisableBags = {},
    ForceEnableBags = {},

    --Timing
    PetskillDelay = 4.0,
    WeaponskillDelay = 3.0,
    AbilityDelay = 2.5,
    SpellOffset = 1.0,
    RangedBase = 10.0,
    RangedOffset = 0.5,
    -- ItemBase = 8,
    ItemOffset = 1.0,
    FastCast = 0,
    Snapshot = 0,
}

---@class LAC.Profile
---@field Sets table<string, LAC.GearSet|LAC.GearSet[]> This table should contain all of your sets. While you can directly equip set objects that are not contained within this table, only sets within this table will be written with '/lac addset', equipped with '/lac set', or respond to string based EquipSet calls.
---@field Packer LAC.PackerGearReference[] This table should contain a list of items for use with /lac gear and /lac validate. Keys can be anything, values can be strings or tables, such as in sets. An additional parameter,
local profile = {};

---This function is called when your profile is first loaded. It should handle any
---ashita event registration, dependency loading, variable initialization, settings modification,
---dynamic set allocation, keybinds, etc.
function profile.OnLoad() end

---This function is called when your profile is unloaded. It should undo any
---ashita event registration, keybinds, global variables, or anything else you've done that may
---persist outside the scope of your profile.
function profile.OnUnload() end

---This function is called when the user types '/lac fwd' based commands. Any arguments input after the first 2 are passed in.
---This should be used for interfacing with the profile's user
---@param args string[]
function profile.HandleCommand(args) end

---This function is called continuously while you are not performing any actions. Unlike Ashitacast, this does not include pet spells or skills.
---As a result, you should use the default section to handle those by checking the gData.GetPetAction() object. You should also use this section
---to handle idle, engaged, resting, or other sets that you are likely to need while not performing actions.
function profile.HandleDefault() end

---This function is called when you use an ability and should be used to equip gear that will make the ability more effective or a defensive set.
function profile.HandleAbility() end

---This function is called when you use an item and should be used to equip gear that will make the item more effective or a defensive set.
function profile.HandleItem() end

---This function is called when you cast a spell, and equips are processed before the spell packet. It should be used to equip fast cast and quick magic gear.
function profile.HandlePrecast() end

---This function is called when you cast a spell, and equips are processed after the spell packet. It should be used to equip anything that changes the result or recast time of a spell.
function profile.HandleMidcast() end

---This function is called when you use ranged attack, and equips are processed before the ranged attack packet. It should be used to equip snapshot and rapid shot gear.
function profile.HandlePreshot() end

---This function is called when you use ranged attack, and equips are processed after the ranged attack packet. It should be used to equip anything that changes the result of the ranged attack.
function profile.HandleMidshot() end

---This function is called when you use a weaponskill and should be used to equip gear that you want to wear while weaponskilling.
function profile.HandleWeaponskill() end
