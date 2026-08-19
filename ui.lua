
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
    LimeGreen = {0.196, 0.804, 0.196, 1},
    -- Green = {0.04, 0.85, 0.32, 1},
    Green = {0, 1, 0, 1},
    Blue = {0.21, 0.80, 0.7, 1},
    Orange = {0.85, 0.32, 0.04, 1},

    Light =         { 1.0, 1.0, 1.0, 1.0 }, --'0xFFFFFFFF';
    Dark =          { 0.0, 0.0, 0.8, 1.0 }, --'0x0000CCFF';
    Ice =           { 0.0, 1.0, 1.0, 1.0 }, --'0x00FFFFFF';
    Water =         { 0.0, 1.0, 1.0, 1.0 }, --'0x00FFFFFF';
    Earth =         { 0.6, 0.5, 0.0, 1.0 }, --'0x997600FF';
    Wind =          { 0.4, 1.0, 0.4, 1.0 }, --'0x66FF66FF';
    Fire =          { 1.0, 0.0, 0.0, 1.0 }, --'0xFF0000FF';
    Lightning =     { 1.0, 0.0, 1.0, 1.0 }, --'0xFF00FFFF';
    Gravitation =   { 0.4, 0.2, 0.0, 1.0 }, --'0x663300FF';
    Fragmentation = { 1.0, 0.6, 1.0, 1.0 }, --'0xFA9CF7FF';
    Fusion =        { 1.0, 0.4, 0.4, 1.0 }, --'0xFF6666FF';
    Distortion =    { 0.2, 0.6, 1.0, 1.0 }, --'0x3399FFFF';
};

local profileState = {
    ---@type SetSelector[]
    selectors = {}
};

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

-- Draws a strikethrough across the previous text
local function strikethroughPrevious()
    local upLeftX, upLeftY = imgui.GetItemRectMin()
    local downRightX, downRightY = imgui.GetItemRectMax();
    local lineHeight = imgui.GetTextLineHeight();
    local drawList = imgui.GetWindowDrawList();
    local y = upLeftY + (lineHeight/2);
    local color = imgui.GetColorU32({1,0,0,1});
    drawList:AddLine({upLeftX, y}, {downRightX, y}, color, 2.5);
end

local function drawSetSelectors()
    for _, selector in ipairs(profileState.selectors) do
        imgui.Text('[');
        imgui.SameLine(0,0);
        imgui.TextColored(TextColors.Green, selector.keybind);
        imgui.SameLine(0,0);
        imgui.Text(string.format("]%s:", selector.name));
        imgui.SameLine()
        imgui.TextColored(TextColors.Blue, selector:getDisplayName());
        local override = selector:getOverrideName();
        if override ~= nil then
            -- TODO: Draw strikethrough on previous text
            strikethroughPrevious();
            imgui.SameLine()
            imgui.TextColored(TextColors.Orange, override);
        end
    end
end

local function drawEnvironment()
    local env = gData.GetEnvironment();

    -- Draw clock, zone, day, and weather.
    imgui.Text("[" .. os.date("%X") .. "]");

    -- Current zone.
    imgui.SameLine();
    imgui.Text(env.Area);
    imgui.SameLine();
    imgui.Text("|")

    -- Current day.
    -- TODO: color the text based on the day.
    imgui.SameLine();
    imgui.Text(env.Day);
    imgui.SameLine();
    imgui.Text("|")

    -- Weather
    -- TODO icons when elemental weather is coming.
    imgui.SameLine();
    imgui.Text(env.Weather)
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

        drawEnvironment();
        -- imgui.Text("[" .. os.date("%X") .. "]");
        -- imgui.SameLine();
        -- imgui.Text("Active TP set:");
        -- imgui.SameLine();
        -- imgui.TextColored(TextColors.Orange, "TP");
        -- imgui.SameLine();
        -- drawIcon(Icons.Lightning);

        imgui.SameLine();
        imgui.Text(" | ")
        -- imgui.SameLine();
        -- imgui.TextColored({1,0,0,1}, "Fizz");
        -- imgui.SameLine(0, 0);
        -- imgui.TextColored({0,1,0,1}, "Buzz");

        imgui.SameLine();
        drawSetSelectors();

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
    local command = string.lower(args[1])
    if command == "gearlist" then
        state.showGearlist[1] = true
    elseif command == "hud" then
        print("showHud: " .. tostring(state.showHud[1]))
        state.showHud[1] = not state.showHud[1]
    end

    -- Handle selector rotator
    if command == "selector" then
        local selectorId = tonumber(args[2]);
        if selectorId == nil then
            print("Command error: selector id is invalid " .. tostring(args[2]));
        else
            profileState.selectors[selectorId]:rotate();
        end
    end
end

function Export.onProfileLoad(options)
    if options ~= nil then
        if options.selectors ~= nil then
            profileState.selectors = options.selectors
        end
    end

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

    -- install keybinds for these sets.
    local kb = AshitaCore:GetInputManager():GetKeyboard();
    for index, selector in ipairs(profileState.selectors) do
        local keycode = kb:S2D(selector.keybind)
        if kb:IsBound(keycode, true, false, false, false, false, false, false, false) then
            error(string.format("Keybind [%s] is already used, cannot assign to set selector %s", selector.keybind, selector.name));
        end
        kb:Bind(keycode, true, false, false, false, false, false, false, false, '/lac fwd selector ' .. tostring(index))
    end
end

function Export.onProfileUnload()
    ashita.events.unregister('d3d_present', 'lac_profile_gui');

    -- Uninstall keybinds
    local kb = AshitaCore:GetInputManager():GetKeyboard();
    for _, selector in ipairs(profileState.selectors) do
        kb:Unbind(kb:S2D(selector.keybind), true, false, false, false, false, false, false, false);
    end
end


return Export;