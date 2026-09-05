---@module 'types'

local Xi = gFunc.LoadFile("xi");

---@alias BlueMagicType Element|PhysicalDamageType|"Healing"|"Ranged"|"Hand-to-Hand"

---@class BlueMagicSpell
---@field name string
---@field type BlueMagicType
---@field scProperty Skillchain[]? nil if this does not do physical damage.
---@field trait string?
---@field family CreatureFamily Monster family this spell came from.

-- Blue magic from here: https://horizonffxi.wiki/Category:Blue_Magic
-- Last updated 2026-08-30

---@type BlueMagicSpell[]
local blueMagic = {
    { name = "Foot Kick",         type = "Slashing",     trait = "Lizard Killer",       scProperty = { "Detonation" },                   family = "Beast" },
    { name = "Pollen",            type = "Light",        trait = "Resist Sleep",        scProperty = nil,                                family = "Vermin" },
    { name = "Sandspin",          type = "Earth",        trait = nil,                   scProperty = nil,                                family = "Amorph" },
    { name = "Power Attack",      type = "Blunt",        trait = "Plantoid Killer",     scProperty = { "Reverberation" },                family = "Vermin" },
    { name = "Sprout Smack",      type = "Blunt",        trait = "Beast Killer",        scProperty = { "Reverberation" },                family = "Plantoid" },
    { name = "Wild Oats",         type = "Piercing",     trait = "Beast Killer",        scProperty = { "Transfixion" },                  family = "Plantoid" },
    { name = "Cocoon",            type = "Earth",        trait = nil,                   scProperty = nil,                                family = "Vermin" },
    { name = "Metallic Body",     type = "Earth",        trait = "Conserve MP",         scProperty = nil,                                family = "Aquan" },
    { name = "Queasyshroom",      type = "Ranged",       trait = nil,                   scProperty = { "Compression" },                  family = "Plantoid" },
    { name = "Battle Dance",      type = "Slashing",     trait = "Attack Bonus",        scProperty = { "Impaction" },                    family = "Beastmen" },
    { name = "Feather Storm",     type = "Ranged",       trait = "Rapid Shot",          scProperty = { "Transfixion" },                  family = "Beastmen" },
    { name = "Head Butt",         type = "Blunt",        trait = nil,                   scProperty = { "Impaction" },                    family = "Beastmen" },
    { name = "Healing Breeze",    type = "Wind",         trait = "Auto Regen",          scProperty = nil,                                family = "Beast" },
    { name = "Helldive",          type = "Blunt",        trait = nil,                   scProperty = { "Transfixion" },                  family = "Bird" },
    { name = "Sheep Song",        type = "Light",        trait = "Auto Regen",          scProperty = nil,                                family = "Beast" },
    { name = "Blastbomb",         type = "Fire",         trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Beastmen" },
    { name = "Bludgeon",          type = "Blunt",        trait = "Undead Killer",       scProperty = { "Liquefaction" },                 family = "Arcana" },
    { name = "Cursed Sphere",     type = "Water",        trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Vermin" },
    { name = "Blood Drain",       type = "Dark",         trait = "Conserve MP",         scProperty = nil,                                family = "Bird" },
    { name = "Claw Cyclone",      type = "Slashing",     trait = "Lizard Killer",       scProperty = { "Scission" },                     family = "Beast" },
    { name = "Poison Breath",     type = "Water",        trait = "Clear Mind",          scProperty = nil,                                family = "Undead" },
    { name = "Soporific",         type = "Dark",         trait = "Clear Mind",          scProperty = nil,                                family = "Plantoid" },
    { name = "Screwdriver",       type = "Piercing",     trait = "Evasion Bonus",       scProperty = { "Transfixion", "Scission" },      family = "Aquan" },
    { name = "Vanity Dive",       type = "Slashing",     trait = "Accuracy Bonus",      scProperty = { "Scission" },                     family = "Empty" },
    { name = "Bomb Toss",         type = "Fire",         trait = "Magic Accuracy",      scProperty = nil,                                family = "Beastmen" },
    { name = "Grand Slam",        type = "Blunt",        trait = "Defense Bonus",       scProperty = { "Induration" },                   family = "Beastmen" },
    { name = "Wild Carrot",       type = "Light",        trait = "Resist Sleep",        scProperty = nil,                                family = "Beast" },
    { name = "Empty Thrash",      type = "Slashing",     trait = "Max HP Boost",        scProperty = { "Compression", "Scission" },      family = "Empty" },
    { name = "Chaotic Eye",       type = "Wind",         trait = "Conserve MP",         scProperty = nil,                                family = "Beast" },
    { name = "Sound Blast",       type = "Fire",         trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Bird" },
    { name = "Death Ray",         type = "Dark",         trait = nil,                   scProperty = nil,                                family = "Amorph" },
    { name = "Smite of Rage",     type = "Slashing",     trait = "Undead Killer",       scProperty = { "Detonation" },                   family = "Arcana" },
    { name = "Digest",            type = "Dark",         trait = "Conserve MP",         scProperty = nil,                                family = "Amorph" },
    { name = "Pinecone Bomb",     type = "Ranged",       trait = nil,                   scProperty = { "Liquefaction" },                 family = "Plantoid" },
    { name = "Occultation",       type = "Wind",         trait = "Evasion Bonus",       scProperty = nil,                                family = "Empty" },
    { name = "Blank Gaze",        type = "Light",        trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Beast" },
    { name = "Jet Stream",        type = "Blunt",        trait = "Rapid Shot",          scProperty = { "Impaction" },                    family = "Bird" },
    { name = "Uppercut",          type = "Blunt",        trait = "Attack Bonus",        scProperty = { "Liquefaction", "Impaction" },    family = "Plantoid" },
    { name = "Mysterious Light",  type = "Wind",         trait = "Max MP Boost",        scProperty = nil,                                family = "Arcana", },
    { name = "Terror Touch",      type = "Hand-to-Hand", trait = "Defense Bonus",       scProperty = { "Compression", "Reverberation" }, family = "Undead" },
    { name = "Auroral Drape",     type = "Wind",         trait = "Fast Cast",           scProperty = nil,                                family = "Empty" },
    { name = "MP Drainkiss",      type = "Dark",         trait = nil,                   scProperty = nil,                                family = "Amorph" },
    { name = "Venom Shell",       type = "Water",        trait = "Clear Mind",          scProperty = nil,                                family = "Aquan" },
    { name = "Blitzstrahl",       type = "Thunder",      trait = "Magic Accuracy",      scProperty = nil,                                family = "Arcana" },
    { name = "Mandibular Bite",   type = "Slashing",     trait = "Plantoid Killer",     scProperty = { "Induration" },                   family = "Vermin" },
    { name = "Stinking Gas",      type = "Wind",         trait = "Auto Refresh",        scProperty = nil,                                family = "Undead" },
    { name = "Awful Eye",         type = "Water",        trait = "Clear Mind",          scProperty = nil,                                family = "Lizard" },
    { name = "Geist Wall",        type = "Dark",         trait = "Auto Refresh",        scProperty = nil,                                family = "Lizard" },
    { name = "Magnetite Cloud",   type = "Earth",        trait = "Magic Defense Bonus", scProperty = nil,                                family = "Beastmen" },
    { name = "Blood Saber",       type = "Dark",         trait = "Auto Refresh",        scProperty = nil,                                family = "Undead" },
    { name = "Jettatura",         type = "Dark",         trait = nil,                   scProperty = nil,                                family = "Bird" },
    { name = "Refueling",         type = "Wind",         trait = nil,                   scProperty = nil,                                family = "Arcana" },
    { name = "Sickle Slash",      type = "Hand-to-Hand", trait = "Store TP",            scProperty = { "Compression" },                  family = "Vermin" },
    { name = "Frightful Roar",    type = "Wind",         trait = "Auto Refresh",        scProperty = nil,                                family = "Demon" },
    { name = "Ice Break",         type = "Ice",          trait = "Magic Defense Bonus", scProperty = nil,                                family = "Arcana" },
    { name = "Self-Destruct",     type = "Fire",         trait = "Auto Refresh",        scProperty = nil,                                family = "Arcana" },
    { name = "Cold Wave",         type = "Ice",          trait = "Auto Refresh",        scProperty = nil,                                family = "Arcana" },
    { name = "Filamented Hold",   type = "Earth",        trait = "Clear Mind",          scProperty = nil,                                family = "Vermin" },
    { name = "Quad. Continnuum",  type = "Piercing",     trait = "Defense Bonus",       scProperty = { "Reverberation", "Scission" },    family = "Empty" },
    { name = "Hecatomb Wave",     type = "Wind",         trait = "Max MP Boost",        scProperty = nil,                                family = "Demon" },
    { name = "Radiant Breath",    type = "Light",        trait = nil,                   scProperty = nil,                                family = "Dragon" },
    { name = "Winds of Promy.",   type = "Light",        trait = "Auto Refresh",        scProperty = nil,                                family = "Empty" },
    { name = "Feather Barrier",   type = "Wind",         trait = "Resist Gravity",      scProperty = nil,                                family = "Bird" },
    { name = "Flying Hip Press",  type = "Wind",         trait = "Max HP Boost",        scProperty = nil,                                family = "Beastmen" },
    { name = "Light of Penance",  type = "Light",        trait = "Auto Refresh",        scProperty = nil,                                family = "Beastmen" },
    { name = "Magic Fruit",       type = "Light",        trait = "Resist Sleep",        scProperty = nil,                                family = "Beast" },
    { name = "Death Scissors",    type = "Slashing",     trait = "Attack Bonus",        scProperty = { "Compression", "Reverberation" }, family = "Vermin" },
    { name = "Dimensional Death", type = "Hand-to-Hand", trait = "Accuracy Bonus",      scProperty = { "Transfixion", "Impaction" },     family = "Undead" },
    { name = "Bad Breath",        type = "Earth",        trait = "Fast Cast",           scProperty = nil,                                family = "Plantoid" },
    { name = "Eyes On Me",        type = "Dark",         trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Demon" },
    { name = "Maelstrom",         type = "Wind",         trait = "Clear Mind",          scProperty = nil,                                family = "Aquan" },
    { name = "1000 Needles",      type = "Light",        trait = "Beast Killer",        scProperty = nil,                                family = "Plantoid" },
    { name = "Body Slam",         type = "Blunt",        trait = "Max HP Boost",        scProperty = { "Impaction" },                    family = "Dragon" },
    { name = "Memento Mori",      type = "Ice",          trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Undead" },
    { name = "Frenetic Rip",      type = "Blunt",        trait = "Accuracy Bonus",      scProperty = { "Induration" },                   family = "Demon" },
    { name = "Frypan",            type = "Blunt",        trait = "Max HP Boost",        scProperty = { "Impaction" },                    family = "Beastmen" },
    { name = "Hydro Shot",        type = "Hand-to-Hand", trait = "Rapid Shot",          scProperty = { "Reverberation" },                family = "Beastmen" },
    { name = "Spinal Cleave",     type = "Slashing",     trait = "Attack Bonus",        scProperty = { "Scission", "Detonation" },       family = "Undead" },
    { name = "Feather Tickle",    type = "Wind",         trait = "Clear Mind",          scProperty = nil,                                family = "Bird" },
    { name = "Voracious Trunk",   type = "Wind",         trait = "Auto Refresh",        scProperty = nil,                                family = "Beast" },
    { name = "Yawn",              type = "Light",        trait = "Resist Sleep",        scProperty = nil,                                family = "Bird" },
    { name = "Infrasonics",       type = "Ice",          trait = nil,                   scProperty = nil,                                family = "Lizard" },
    { name = "Zephyr Mantle",     type = "Wind",         trait = "Conserve MP",         scProperty = nil,                                family = "Dragon" },
    { name = "Frost Breath",      type = "Ice",          trait = "Conserve MP",         scProperty = nil,                                family = "Lizard" },
    { name = "Sandspray",         type = "Dark",         trait = "Clear Mind",          scProperty = nil,                                family = "Beastmen" },
    { name = "Diamondhide",       type = "Earth",        trait = nil,                   scProperty = nil,                                family = "Beastmen" },
    { name = "Enervation",        type = "Dark",         trait = "Counter",             scProperty = nil,                                family = "Beastmen" },
    { name = "Firespit",          type = "Fire",         trait = "Conserve MP",         scProperty = nil,                                family = "Beastmen" },
    { name = "Warm-Up",           type = "Earth",        trait = "Clear Mind",          scProperty = nil,                                family = "Beastmen" },
    { name = "Hysteric Barrage",  type = "Hand-to-Hand", trait = "Evasion Bonus",       scProperty = { "Detonation" },                   family = "Beastmen" },
    { name = "Tail Slap",         type = "Hand-to-Hand", trait = "Store TP",            scProperty = { "Reverberation" },                family = "Beastmen" },
    { name = "Amplification",     type = "Wind",         trait = nil,                   scProperty = nil,                                family = "Amorph" },
    { name = "Cannonball",        type = "Hand-to-Hand", trait = nil,                   scProperty = { "Fusion" },                       family = "Vermin" },
    { name = "Heat Breath",       type = "Fire",         trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Beast" },
    { name = "Lowing",            type = "Fire",         trait = "Clear Mind",          scProperty = nil,                                family = "Beast" },
    { name = "Disseverment",      type = "Piercing",     trait = "Accuracy Bonus",      scProperty = { "Distortion" },                   family = "Luminian" },
    { name = "Saline Coat",       type = "Light",        trait = "Defense Bonus",       scProperty = nil,                                family = "Luminian" },
    { name = "Mind Blast",        type = "Thunder",      trait = "Clear Mind",          scProperty = nil,                                family = "Demon" },
    { name = "Ram Charge",        type = "Blunt",        trait = "Lizard Killer",       scProperty = { "Fragmentation" },                family = "Beast" },
    { name = "Temporal Shift",    type = "Thunder",      trait = "Attack Bonus",        scProperty = nil,                                family = "Luminian" },
    { name = "Actinic Burst",     type = "Light",        trait = "Auto Refresh",        scProperty = nil,                                family = "Luminion" },
    { name = "Magic Hammer",      type = "Light",        trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Beastmen" },
    { name = "Reactor Cool",      type = "Ice",          trait = "Magic Attack Bonus",  scProperty = nil,                                family = "Luminion" },
    { name = "Exuviation",        type = "Fire",         trait = "Resist Sleep",        scProperty = nil,                                family = "Vermin" },
    { name = "Plasma Charge",     type = "Thunder",      trait = "Auto Refresh",        scProperty = nil,                                family = "Luminian" },
    { name = "Vertical Cleave",   type = "Slashing",     trait = "Defense Bonus",       scProperty = { "Gravitation" },                  family = "Luminian" },
};


---@type table<string, BlueMagicSpell>
local blueMagicByName = T {};
do
    for _, spell in ipairs(blueMagic) do
        blueMagicByName[spell.name] = spell;
    end
end

-- Sanity check to make sure all of our spells are correctly referenced
do
    local res = AshitaCore:GetResourceManager();
    for _, spell in ipairs(blueMagic) do
        if res:GetSpellByName(spell.name, Xi.LanguageId.English) == nil then
            gFunc.Error("invalid spell name: " .. spell.name)
        end
    end
end


return {
    BlueMagic = blueMagicByName,
}
