local helm_set = {
    ['Body'] = 'Field Tunica'
    ['Hands'] = 'Field Gloves'
    -- ['Legs'] = 'Field Hose'
    ['Feet'] = 'Field Boots'
}

local Helm = {};
Helm.__index = Helm;

function Helm:new()
    local o = { enabled: false };
    setmetatable(o, self);
    return o;
end

function Helm:enable()
    self.enabled = true;
end

function Helm:disable()
    self.enabled = false;
end

function Helm:toggle()
    self.enabled = ~self.enabled;
end

function Helm:get_layer()
    local conditions = {
        -- Are we trying to equip this set?
        self.enabled,

        -- Is the player out of combat?
        -- Is the player on anything's agro table?
    }