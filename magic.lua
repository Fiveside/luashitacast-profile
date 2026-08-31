

---@alias BlueMagicType Element|PhysicalDamageType|"Healing"|"Ranged"

---@class BlueMagicSpell
---@field name string
---@field type BlueMagicType
---@field scProperty Skillchain[]? nil if this does not do physical damage.
---@field trait string?
---@field family CreatureFamily Monster family this spell came from.


---@type BlueMagicSpell[]
local blueMagic = {
    {
        name = "Pollen",
        type = "Healing",
        trait = "Resist Sleep",
        family = "Vermin",
    },
    {
        name = "Foot Kick",
        type = "Slashing",
        scProperty = {"Detonation"},
        trait = "Lizard Killer",
        family = "Beast",
    },
    {
        name = "Sandspin",
        type = "Earth",
        family = "Amorph",
    },
    {
        name = "Power Attack",
        type = "Blunt",
        scProperty = {"Reverberation"},
        trait = "Plantoid Killer",
        family = "Vermin",
    },
    {
        name = "Sprout Smack",
        type = "Blunt",
        scProperty = {"Reverberation"},
        trait = "Beast Killer",
        family = "Plantoid",
    },
    {
        name = "Wild Oats",
        type = "Piercing",
        scProperty = {"Transfixion"},
        trait = "Beast Killer",
        family = "Plantoid",
    },
    {
        name = "Cocoon",
        type = "Earth",
        family = "Vermin",
    },
    {
        name = "Metalic Body",
        type = "Earth",
        trait = "Conserve MP",
        family = "Aquan",
    },
    {
        name = "Queasyshroom",
        type = "Ranged",
        scProperty = {"Compression"},
        family = "Plantoid",
    },
    {
        name = "Battle Dance",
        type = "Slashing",
        scProperty = {"Impaction"},
        trait = "Attack Bonus",
        family = "Beast",
    },
    {
        name = "Feather Storm",
        type = "Ranged",
        scProperty = {"Transfixion"},
        trait = "Rapid Shot",
        family = "Beastmen",
    },
    {
        name = "Head Butt",
        type = "Blunt",
        scProperty = {"Impaction"},
        family = "Beastmen",
    },
    {
        name = "Healing Breeze",
        -- Wiki says Wind magic, and LSB comment says wind.  But LSB SQL says non-elemental and LSB code says Healing.
        type = "Healing",
        trait = "Auto Regen",
        family = "Beast",
    },
    {
        name = "Helldive",
    }
};



-- Sanity check to make sure all of our spells are correctly referenced
do
    local res = AshitaCore:GetResourceManager();

end