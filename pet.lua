-- Making pet state easy to manage in multiple jobs.

local PetState = T {};

local function getState()
    local pet = gData.GetPet();
    local action = gData.GetAction();
end
