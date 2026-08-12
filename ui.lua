
-- idk why this isn't working
local imgui = require('imgui');
---@cast imgui IGuiManager
---@module 'IGuiManagerTypes'

local Slips = gFunc.LoadFile('slips/slips');
local XI = gFunc.LoadFile('xi');
local json = require('json');
local d3d8 = require('d3d8');
local ffi = require('ffi');

local state = {
    showGearlist = {true},
    showHud = {true},
}

-- Texture cache of icons.  Fallback is a color array for imgui.
---@type table<string, {texture: IDirect3DTexture8?, fallback: integer[]}>
local Icons = {
    Lightning = {fallback = {1,1,1,1}},
    Ice = {fallback = {1,1,1,1}},
    Fire = {fallback = {1,1,1,1}},
    Wind = {fallback = {1,1,1,1}},
    Water = {fallback = {1,1,1,1}},
    Earth = {fallback = {1,1,1,1}},
    Light = {fallback = {1,1,1,1}},
    Dark = {fallback = {1,1,1,1}},
}

-- RGBA colors
local TextColors = {
    -- https://www.figma.com/colors/malachite/
    -- Triadic palette.
    -- (function(y) {return [y.slice(0, 2), y.slice(2,4), y.slice(4,6)].map(x => (parseInt(x, 16)/255).toFixed(2)).join(", ");})("510BDA")
    -- LimeGreen = {0.196, 0.804, 0.196, 1},
    Green = {0.04, 0.85, 0.32, 1},
    Blue = {0.21, 0.80, 0.7, 1},
    Orange = {0.85, 0.32, 0.04, 1},
}

local function pushStyleVars(styles)
    local numStyles = 0;
    for k, v in pairs(styles) do
        numStyles = numStyles + 1
        imgui.PushStyleVar(k, v);
    end
    return function() imgui.PopStyleVar(numStyles) end
end
local function pushStyleColors(styles)
    local numStyles = 0
    for k, v in pairs(styles) do
        numStyles = numStyles + 1
        imgui.PushStyleColor(k, v);
    end
    return function() imgui.PopStyleColor(numStyles) end
end

---asf
---@param icon {texture: IDirect3DTexture8?, fallback: integer[]}
local function drawIcon(icon)
    local tex = icon.texture;
    if tex == nil then
        imgui.TextColored(TextColors.Orange, "[Icon]");
    else
        local result, texDesc = tex:GetLevelDesc(0);
        if result ~= ffi.C.S_OK then
            print("Error fetching texture description")
        end
        ---@cast texDesc -?
        local width = texDesc.Width;
        local height = texDesc.Height;
        local lineHeight = imgui.GetTextLineHeight();
        local newWidth = (lineHeight/height) * width;
        imgui.Image(tonumber(ffi.cast("uint32_t", tex)), {newWidth, lineHeight})
    end
end

local function drawHud()
    local popStyleVars = pushStyleVars({
        [ImGuiStyleVar_WindowBorderSize] = 0,
        [ImGuiStyleVar_WindowPadding] = {0, 0},
        [ImGuiStyleVar_WindowMinSize] = {0, 0},
    });

    local spacing = imgui.GetStyle().ItemSpacing;
    local popStyleColors = pushStyleColors({
        [ImGuiStyleVar_ItemSpacing] = {spacing.x, 0},
        [ImGuiCol_WindowBg] = {0, 0, 0, 1},
    })

    local lineHeight = imgui.GetTextLineHeight();
    -- local windowHeight = /

    imgui.SetNextWindowPos({131, 0}, ImGuiCond_Always);
    imgui.SetNextWindowSizeConstraints({250, lineHeight}, {-1, -1});
    local windowFlags = bit.bor(
        -- ImGuiWindowFlags_NoBackground,
        ImGuiWindowFlags_NoInputs,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_NoScrollWithMouse,
        ImGuiWindowFlags_AlwaysAutoResize
    );
    if imgui.Begin("##LAC_pofile_hud", state.showHud, windowFlags) then

        imgui.Text("[" .. os.date("%X") .. "]");
        imgui.SameLine();
        imgui.Text("Active TP set:");
        imgui.SameLine();
        imgui.TextColored(TextColors.Orange, "TP");
        imgui.SameLine();
        drawIcon(Icons.Lightning);
    end
    imgui.End();
    popStyleColors();
    -- imgui.PopStyleColor(1);
    popStyleVars();
end

local function drawUi()
    local resources = AshitaCore:GetResourceManager();

    -- if imgui.Begin("Gear TODOs##lac_profile_todolist", state.visible) then
    --     imgui.SeparatorText("Retrieve from Slip 1")
    --     imgui.Text("Hello World");

    --     local slippables = Slips.getSlippableItemsInInventory();
    --     for _, container in ipairs(XI.InventoryContainerList) do
    --         local items = slippables[container.id];
    --         if items ~= nil then
    --             imgui.SeparatorText(container.name)
    --             for _, item in ipairs(items) do
    --                 ---@cast item item_t
    --                 local res = resources:GetItemById(item.Id);
    --                 imgui.Text(res.Name[1]);
    --             end
    --         end
    --     end
    -- end
    -- imgui.End();
end



local Export = {};

-- Ashita command handler.
function Export.onSlashCommand(args)
    for containerId, items in pairs(Slips.getSlippableItemsInInventory()) do
        print("container " .. tostring(containerId) .. " has " .. tostring(#items) .. " items")
    end
    local command = string.lower(args[1])
    if command == "gearlist" then
        state.showGearlist[1] = true
    elseif command == "hud" then
        state.showHud[1] = not state.showHud[1]
    end
end

function Export.onProfileLoad()
    -- Load textures.
    local elements = {"Lightning", "Ice", "Fire", "Wind", "Water", "Earth", "Light", "Dark"};
    for _, element in ipairs(elements) do
        local path = string.format("%sconfig\\addons\\luashitacast\\%s_%u\\assets\\%s.png", AshitaCore:GetInstallPath(), gState.PlayerName, gState.PlayerId, element);
        local texturePtr = ffi.new('IDirect3DTexture8*[1]');
        local loadResult = ffi.C.D3DXCreateTextureFromFileA(d3d8.get_device(), path, texturePtr)
        if loadResult == ffi.C.S_OK then
            Icons[element].texture = d3d8.gc_safe_release(ffi.cast("IDirect3DTexture8*", texturePtr[0]))
        else
            print("LAC profile: Error loading texture: " .. d3d8.get_error(loadResult));
        end
    end

    ashita.events.register('d3d_present', 'lac_profile_gui', function()
        drawUi();
        drawHud();
    end);
end

function Export.onProfileUnload()
    ashita.events.unregister('d3d_present', 'lac_profile_gui');
end


return Export;