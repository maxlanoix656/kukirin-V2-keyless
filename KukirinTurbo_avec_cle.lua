-- KUKIRIN // TURBO — Neon Control Panel
-- Place as a LocalScript in StarterPlayer > StarterPlayerScripts.
-- Intended for your own Roblox Studio experience / authorized testing.
-- Note: client-side CFrame movement may be overridden by server/network ownership.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🔐 KEY GATE — single LocalScript, before the original panel is created.
-- Demo key only: client-side keys are visible to anyone who can inspect this script.
local CLE_AUTORISEE = "KUKIRIN-2026"

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KukirinKeySystem"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.DisplayOrder = 999
keyGui.Parent = playerGui

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyPanel"
keyFrame.Size = UDim2.fromOffset(360, 215)
keyFrame.Position = UDim2.new(0.5, -180, 0.5, -107)
keyFrame.BackgroundColor3 = Color3.fromRGB(9, 12, 13)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = keyGui
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 14)
local keyStroke = Instance.new("UIStroke")
keyStroke.Color = Color3.fromRGB(153, 255, 0)
keyStroke.Thickness = 2
keyStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -20, 0, 42)
keyTitle.Position = UDim2.fromOffset(10, 12)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "KUKIRIN // KEY SYSTEM"
keyTitle.TextColor3 = Color3.fromRGB(153, 255, 0)
keyTitle.TextSize = 21
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.Parent = keyFrame

local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, -30, 0, 22)
keyHint.Position = UDim2.fromOffset(15, 52)
keyHint.BackgroundTransparency = 1
keyHint.Text = "Entre ta clé pour ouvrir le panneau"
keyHint.TextColor3 = Color3.fromRGB(142, 154, 144)
keyHint.TextSize = 12
keyHint.Font = Enum.Font.Gotham
keyHint.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Name = "KeyInput"
keyInput.Size = UDim2.new(1, -40, 0, 40)
keyInput.Position = UDim2.fromOffset(20, 82)
keyInput.BackgroundColor3 = Color3.fromRGB(29, 36, 34)
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Entre la clé ici..."
keyInput.PlaceholderColor3 = Color3.fromRGB(142, 154, 144)
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(240, 246, 236)
keyInput.TextSize = 15
keyInput.Font = Enum.Font.GothamBold
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyFrame
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 7)

local keyButton = Instance.new("TextButton")
keyButton.Name = "ValidateKey"
keyButton.Size = UDim2.new(1, -40, 0, 38)
keyButton.Position = UDim2.fromOffset(20, 132)
keyButton.BackgroundColor3 = Color3.fromRGB(153, 255, 0)
keyButton.BorderSizePixel = 0
keyButton.Text = "VALIDER LA CLÉ"
keyButton.TextColor3 = Color3.fromRGB(9, 12, 13)
keyButton.TextSize = 14
keyButton.Font = Enum.Font.GothamBlack
keyButton.Parent = keyFrame
Instance.new("UICorner", keyButton).CornerRadius = UDim.new(0, 7)

local keyMessage = Instance.new("TextLabel")
keyMessage.Size = UDim2.new(1, -20, 0, 22)
keyMessage.Position = UDim2.fromOffset(10, 174)
keyMessage.BackgroundTransparency = 1
keyMessage.Text = ""
keyMessage.TextColor3 = Color3.fromRGB(255, 75, 75)
keyMessage.TextSize = 12
keyMessage.Font = Enum.Font.GothamBold
keyMessage.Parent = keyFrame

local keyAccepted = false
local function validateKey()
    if keyInput.Text == CLE_AUTORISEE then
        keyAccepted = true
        keyButton.Text = "CLÉ ACCEPTÉE"
        keyMessage.TextColor3 = Color3.fromRGB(153, 255, 0)
        keyMessage.Text = "Accès autorisé..."
        task.wait(0.25)
        keyGui:Destroy()
    else
        keyMessage.TextColor3 = Color3.fromRGB(255, 75, 75)
        keyMessage.Text = "Clé incorrecte. Réessaie."
        keyInput.Text = ""
        keyInput:CaptureFocus()
    end
end
keyButton.Activated:Connect(validateKey)
keyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then validateKey() end
end)

-- Do not create/show the original KUKIRIN panel until the key is accepted.
repeat task.wait() until keyAccepted


-- Avoid duplicate GUIs if the script is re-run in Studio.
local previousGui = playerGui:FindFirstChild("KukirinTurbo")
if previousGui then
    previousGui:Destroy()
end

-- SETTINGS
local DEFAULTS = {
    floatDistance = 5,
    spinSpeed = 20,
    scooterSpeedBoost = 50,
    numberOfSpins = 20,
    repeatDelay = 1,
    liftDuration = 0.7,
    landDuration = 0.7,
}

local settings = table.clone(DEFAULTS)

local running = false
local busy = false
local cancelId = 0
local antiAFKEnabled = false
local antiRagdollEnabled = false
local antiRagdollConnection = nil
local scooterBoostEnabled = false
local sessionStartedAt = nil
local sessionElapsed = 0
local lastRunStartedAt = nil
local totalRuns = 0
local currentPhase = "READY"
local currentSpinProgress = 0
local connections = {}
local labelRegistry = {}
local rainbowConnection = nil
local rainbowEnabled = false
local rainbowParts = {}
local halloweenEnabled = false
local halloweenRunId = 0

-- COLORS
local BLACK = Color3.fromRGB(9, 12, 13)
local PANEL = Color3.fromRGB(20, 25, 25)
local PANEL_LIGHT = Color3.fromRGB(29, 36, 34)
local GREEN = Color3.fromRGB(153, 255, 0)
local GREEN_DARK = Color3.fromRGB(54, 94, 20)
local WHITE = Color3.fromRGB(240, 246, 236)
local GRAY = Color3.fromRGB(142, 154, 144)
local RED = Color3.fromRGB(255, 75, 75)
local YELLOW = Color3.fromRGB(255, 197, 64)

-- HUD theme colors (the user can switch these in the interface).
local HUD_THEMES = {
    {name = "NEON GREEN", accent = Color3.fromRGB(153, 255, 0), dark = Color3.fromRGB(54, 94, 20)},
    {name = "CYAN", accent = Color3.fromRGB(0, 220, 255), dark = Color3.fromRGB(0, 80, 100)},
    {name = "PURPLE", accent = Color3.fromRGB(190, 100, 255), dark = Color3.fromRGB(75, 35, 110)},
    {name = "PINK", accent = Color3.fromRGB(255, 75, 180), dark = Color3.fromRGB(110, 25, 75)},
    {name = "ORANGE", accent = Color3.fromRGB(255, 150, 35), dark = Color3.fromRGB(120, 60, 10)},
    {name = "WHITE", accent = Color3.fromRGB(245, 245, 245), dark = Color3.fromRGB(90, 90, 90)},
}
local currentThemeIndex = 1

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function make(className, props, parent)
    local obj = Instance.new(className)

    for key, value in pairs(props or {}) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

local function round(parent, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or GREEN,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

-- GUI ROOT
local gui = make("ScreenGui", {
    Name = "KukirinTurbo",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local frame = make("Frame", {
    Name = "MainPanel",
    Size = UDim2.fromOffset(520, 780),
    Position = UDim2.new(0.5, -260, 0.5, -390),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    Active = true,
}, gui)

round(frame, 15)
stroke(frame, GREEN, 2)

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 82),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    Active = true,
}, frame)

round(header, 14)

make("Frame", {
    Size = UDim2.new(1, -2, 0, 4),
    Position = UDim2.new(0, 1, 1, -4),
    BackgroundColor3 = GREEN,
    BorderSizePixel = 0,
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(17, 8),
    Size = UDim2.new(1, -70, 0, 34),
    BackgroundTransparency = 1,
    Text = "KUKIRIN // TURBO",
    TextColor3 = GREEN,
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(18, 44),
    Size = UDim2.new(1, -36, 0, 19),
    BackgroundTransparency = 1,
    Text = "E-SCOOTER MOTION CONTROL  •  MK-V",
    TextColor3 = GRAY,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- Minimize to a tiny floating, draggable button; the large original GUI is preserved.
local collapsed = false
local expandedSize = frame.Size
local toggleButton = make("TextButton", {
    Name = "MenuToggle",
    Position = UDim2.new(1, -42, 0, 12),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = PANEL_LIGHT,
    BorderSizePixel = 0,
    Text = "−",
    TextColor3 = GREEN,
    TextSize = 22,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = true,
    ZIndex = 5,
}, header)
round(toggleButton, 7)

local miniButton = make("TextButton", {
    Name = "FloatingRestoreButton",
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(0, 24, 0.5, -24),
    BackgroundColor3 = BLACK,
    BorderSizePixel = 0,
    Text = "K",
    TextColor3 = GREEN,
    TextSize = 22,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = true,
    Visible = false,
    Active = true,
    ZIndex = 50,
}, gui)
round(miniButton, 14)
stroke(miniButton, GREEN, 2)

local function setCollapsed(value)
    collapsed = value
    frame.Visible = not collapsed
    miniButton.Visible = collapsed
    if collapsed then
        toggleButton.Text = "+"
    else
        frame.Size = expandedSize
        toggleButton.Text = "−"
    end
end

connect(toggleButton.Activated, function()
    setCollapsed(not collapsed)
end)
-- Drag the floating mini-button; a simple tap restores the full panel.
local miniDragging = false
local miniMoved = false
local miniDragStart, miniStartPosition
connect(miniButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = true
        miniMoved = false
        miniDragStart = input.Position
        miniStartPosition = miniButton.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniDragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then miniMoved = true end
        miniButton.Position = UDim2.new(
            miniStartPosition.X.Scale, miniStartPosition.X.Offset + delta.X,
            miniStartPosition.Y.Scale, miniStartPosition.Y.Offset + delta.Y
        )
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if miniDragging and not miniMoved then setCollapsed(false) end
        miniDragging = false
    end
end)

-- Drag panel (mouse and touch)
local dragging = false
local dragInput, dragStart, startPosition

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
        dragInput = input
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

local function label(text, y, height, color, size)
    local obj = make("TextLabel", {
        Position = UDim2.fromOffset(17, y),
        Size = UDim2.new(1, -34, 0, height or 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or WHITE,
        TextSize = size or 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    table.insert(labelRegistry, {object = obj, text = text})
    return obj
end

label("/// MOTION CONFIGURATION", 91, 20, GREEN, 12)

local function settingBox(titleText, y, defaultValue)
    label(titleText, y, 17, GRAY, 10)

    local box = make("TextBox", {
        Position = UDim2.fromOffset(17, y + 18),
        Size = UDim2.new(1, -34, 0, 30),
        BackgroundColor3 = PANEL_LIGHT,
        BorderSizePixel = 0,
        Text = tostring(defaultValue),
        PlaceholderText = tostring(defaultValue),
        TextColor3 = GREEN,
        PlaceholderColor3 = GRAY,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    round(box, 7)

    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
    }, box)

    stroke(box, Color3.fromRGB(59, 78, 43), 1)

    return box
end

local distanceBox = settingBox(
    "FLOAT DISTANCE / STUDS (2–100)",
    115,
    DEFAULTS.floatDistance
)

local speedBox = settingBox(
    "SPIN SPEED / ROTATIONS PER SECOND (0.1–1000)",
    169,
    DEFAULTS.spinSpeed
)

local spinsBox = settingBox(
    "FULL ROTATIONS (1–100)",
    223,
    DEFAULTS.numberOfSpins
)

local delayBox = settingBox(
    "REPEAT DELAY / SECONDS (0–300)",
    277,
    DEFAULTS.repeatDelay
)

local speedBoostBox = settingBox(
    "SCOOTER SPEED (1–200)",
    331,
    DEFAULTS.scooterSpeedBoost
)

local themeButton = make("TextButton", {
    Name = "HudColorButton",
    Position = UDim2.fromOffset(17, 385),
    Size = UDim2.new(1, -34, 0, 30),
    BackgroundColor3 = PANEL_LIGHT,
    BorderSizePixel = 0,
    Text = "HUD COLOR: NEON GREEN  •  CLICK TO CHANGE",
    TextColor3 = GREEN,
    TextSize = 11,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = true,
}, frame)
round(themeButton, 7)
stroke(themeButton, Color3.fromRGB(59, 78, 43), 1)

local boostButton = make("TextButton", {
    Name = "ScooterBoostButton",
    Position = UDim2.fromOffset(17, 418),
    Size = UDim2.new(1, -34, 0, 24),
    BackgroundColor3 = GREEN_DARK,
    BorderSizePixel = 0,
    Text = "⚡ PERMANENT SPEED: OFF  •  CLICK TO TOGGLE",
    TextColor3 = WHITE,
    TextSize = 11,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = true,
}, frame)
round(boostButton, 7)

local function applyTheme(index)
    currentThemeIndex = ((index - 1) % #HUD_THEMES) + 1
    local theme = HUD_THEMES[currentThemeIndex]
    gui:SetAttribute("HudAccentColor", theme.accent)
    themeButton.Text = "HUD COLOR: " .. theme.name .. "  •  CLICK TO CHANGE"
    themeButton.TextColor3 = theme.accent

    -- Recolor the existing HUD without depending on controls declared later.
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("UIStroke") then
            obj.Color = theme.accent
        elseif obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            if obj.TextColor3 == GREEN then
                obj.TextColor3 = theme.accent
            end
        elseif obj:IsA("Frame") then
            if obj.BackgroundColor3 == GREEN then
                obj.BackgroundColor3 = theme.accent
            elseif obj.BackgroundColor3 == GREEN_DARK then
                obj.BackgroundColor3 = theme.dark
            end
        end
    end
end

-- STATUS CARD
local statusCard = make("Frame", {
    Position = UDim2.fromOffset(17, 445),
    Size = UDim2.new(1, -34, 0, 61),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
}, frame)

round(statusCard, 9)
stroke(statusCard, Color3.fromRGB(55, 76, 44), 1)

local statusDot = make("Frame", {
    Position = UDim2.fromOffset(12, 14),
    Size = UDim2.fromOffset(9, 9),
    BackgroundColor3 = GREEN,
    BorderSizePixel = 0,
}, statusCard)

round(statusDot, 9)

local statusLabel = make("TextLabel", {
    Position = UDim2.fromOffset(29, 8),
    Size = UDim2.new(1, -39, 0, 20),
    BackgroundTransparency = 1,
    Text = "SYSTEM READY",
    TextColor3 = GREEN,
    TextSize = 12,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
}, statusCard)

local detailLabel = make("TextLabel", {
    Position = UDim2.fromOffset(29, 30),
    Size = UDim2.new(1, -39, 0, 18),
    BackgroundTransparency = 1,
    Text = "Waiting for START",
    TextColor3 = GRAY,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, statusCard)

local progressBack = make("Frame", {
    Position = UDim2.fromOffset(17, 514),
    Size = UDim2.new(1, -34, 0, 7),
    BackgroundColor3 = PANEL_LIGHT,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, frame)

round(progressBack, 4)

local progressFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = GREEN,
    BorderSizePixel = 0,
}, progressBack)

round(progressFill, 4)

local function setStatus(main, detail, color)
    statusLabel.Text = main
    detailLabel.Text = detail or ""
    statusLabel.TextColor3 = color or GREEN
    statusDot.BackgroundColor3 = color or GREEN
end

local function tweenProgress(value)
    TweenService:Create(
        progressFill,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad),
        {
            Size = UDim2.new(
                math.clamp(value, 0, 1),
                0,
                1,
                0
            ),
        }
    ):Play()
end

local function button(text, x, y, width, color, textColor)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, 39),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = textColor or BLACK,
        TextSize = 13,
        Font = Enum.Font.GothamBlack,
        AutoButtonColor = true,
    }, frame)

    round(b, 8)

    return b
end

local startButton = button(
    "▶  START", 17, 535, 158, GREEN, BLACK
)

local stopButton = button(
    "■  STOP", 185, 535, 158, RED, BLACK
)

local afkButton = button(
    "ANTI-AFK: OFF", 17, 582, 238, PANEL_LIGHT, GRAY
)
local antiRagdollButton = button(
    "ANTI-RAGDOLL: OFF", 265, 582, 238, PANEL_LIGHT, GRAY
)

local rainbowButton = button("🌈 RAINBOW: OFF", 17, 629, 238, PANEL_LIGHT, GREEN)
local halloweenButton = button("🎃 AUTO HALLOWEEN: OFF", 265, 629, 238, PANEL_LIGHT, YELLOW)

-- Organized multi-page interface. Each tab shows only its matching controls.
local activeTab = "Mouvement"
local tabButtons = {}
local tabNames = {"Mouvement", "Trottinette", "Halloween", "Protection", "Apparence"}
for i, tabName in ipairs(tabNames) do
    local tab = make("TextButton", {
        Name = "Tab_" .. tabName,
        Position = UDim2.fromOffset(12 + (i - 1) * 100, 88),
        Size = UDim2.fromOffset(96, 29),
        BackgroundColor3 = PANEL_LIGHT,
        BorderSizePixel = 0,
        Text = tabName,
        TextColor3 = WHITE,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        ZIndex = 4,
    }, frame)
    round(tab, 6)
    tabButtons[tabName] = tab
end

local function setPosition(obj, x, y, w, h)
    if obj then
        obj.Position = UDim2.fromOffset(x, y)
        obj.Size = UDim2.new(0, w, 0, h)
        obj.Visible = true
    end
end

local function showTab(tabName)
    activeTab = tabName
    -- Hide direct children, then re-enable shared header and the selected page.
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= header then
            if child:IsA("GuiObject") then child.Visible = false end
        end
    end
    header.Visible = true
    toggleButton.Visible = true
    for name, tab in pairs(tabButtons) do
        tab.Visible = true
        tab.BackgroundColor3 = (name == tabName) and GREEN_DARK or PANEL_LIGHT
        tab.TextColor3 = (name == tabName) and GREEN or WHITE
    end

    for _, entry in ipairs(labelRegistry) do entry.object.Visible = false end
    local function show(obj) if obj then obj.Visible = true end end
    show(statusCard); show(progressBack); show(timerLabel); show(statsLabel); show(footer)
    setPosition(statusCard, 17, 480, 486, 61)
    setPosition(progressBack, 17, 550, 486, 7)
    setPosition(timerLabel, 17, 570, 486, 19)
    setPosition(statsLabel, 17, 592, 486, 17)
    setPosition(footer, 17, 748, 486, 15)

    local function labelLike(needle, x, y, w)
        for _, entry in ipairs(labelRegistry) do
            if string.find(string.lower(entry.text), string.lower(needle), 1, true) then
                setPosition(entry.object, x or 17, y, w or 486, 17)
                entry.object.TextXAlignment = Enum.TextXAlignment.Left
                return entry.object
            end
        end
    end

    if tabName == "Mouvement" then
        labelLike("MOTION CONFIGURATION", 17, 120)
        labelLike("FLOAT DISTANCE", 17, 145); setPosition(distanceBox, 17, 163, 486, 30)
        labelLike("SPIN SPEED", 17, 201); setPosition(speedBox, 17, 219, 486, 30)
        labelLike("FULL ROTATIONS", 17, 257); setPosition(spinsBox, 17, 275, 486, 30)
        labelLike("REPEAT DELAY", 17, 313); setPosition(delayBox, 17, 331, 486, 30)
        setPosition(startButton, 17, 385, 238, 39); setPosition(stopButton, 265, 385, 238, 39)
    elseif tabName == "Trottinette" then
        labelLike("SCOOTER SPEED", 17, 145); setPosition(speedBoostBox, 17, 163, 486, 30)
        setPosition(boostButton, 17, 210, 486, 32)
        setPosition(rainbowButton, 17, 252, 486, 39)
        setPosition(themeButton, 17, 300, 486, 32)
    elseif tabName == "Halloween" then
        local heading = labelLike("MOTION CONFIGURATION", 17, 120)
        if heading then heading.Text = "🎃 HALLOWEEN — AUTOMATIC OBJECTIVE ROUTE"; heading.TextColor3 = YELLOW end
        setPosition(halloweenButton, 17, 150, 486, 44)
        local hint = labelLike("FULL ROTATIONS", 17, 215)
        if hint then hint.Text = "Tag your event objects with HalloweenQuest, or name them Halloween / Pumpkin / Candy."; hint.TextWrapped = true; hint.Size = UDim2.fromOffset(486, 44) end
    elseif tabName == "Protection" then
        local heading = labelLike("MOTION CONFIGURATION", 17, 120)
        if heading then heading.Text = "PLAYER PROTECTION"; heading.TextColor3 = GREEN end
        setPosition(afkButton, 17, 150, 238, 42); setPosition(antiRagdollButton, 265, 150, 238, 42)
    elseif tabName == "Apparence" then
        local heading = labelLike("MOTION CONFIGURATION", 17, 120)
        if heading then heading.Text = "HUD PERSONALISATION"; heading.TextColor3 = GREEN end
        setPosition(themeButton, 17, 150, 486, 42)
    end
end
for name, tab in pairs(tabButtons) do
    connect(tab.Activated, function() showTab(name) end)
end

connect(themeButton.Activated, function()
    applyTheme(currentThemeIndex + 1)
end)
applyTheme(1)

local timerLabel = label(
    "SESSION  00:00:00", 670, 19, GREEN, 11
)

local statsLabel = label(
    "RUNS COMPLETED: 0", 692, 17, GRAY, 10
)

local footer = label(
    "KUKIRIN PERFORMANCE DIVISION  •  CLIENT BUILD",
    715,
    15,
    GRAY,
    8
)

footer.TextXAlignment = Enum.TextXAlignment.Center

-- Validate all values before starting.
local function readSettings()
    local d = tonumber(distanceBox.Text)
    local s = tonumber(speedBox.Text)
    local n = tonumber(spinsBox.Text)
    local delay = tonumber(delayBox.Text)
    local boost = tonumber(speedBoostBox.Text)

    if not d or not s or not n or not delay or not boost
        or d ~= d or s ~= s or n ~= n or delay ~= delay
        or d < 1 or d > 100
        or s < 0.1 or s > 1000
        or boost < 1 or boost > 200
        or n < 1 or n > 100
        or delay < 0 or delay > 300 then

        setStatus(
            "INVALID SETTINGS",
            "Use values inside the ranges shown",
            RED
        )

        return false
    end

    settings.floatDistance = d
    settings.spinSpeed = s
    settings.scooterSpeedBoost = boost
    settings.numberOfSpins = math.floor(n)
    settings.repeatDelay = delay

    return true
end

-- Find the character and, if seated, its vehicle model.
local function getRide()
    local character = player.Character

    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil
    end

    local vehicle
    local seat = humanoid.SeatPart

    if seat then
        local current = seat.Parent

        while current and current ~= workspace do
            if current:IsA("Model") then
                vehicle = current
                break
            end

            current = current.Parent
        end
    end

    return humanoid, root, vehicle
end

-- 🌈 Rainbow colors every physical part in the scooter model, not only its seat.
local function stopRainbow(restore)
    rainbowEnabled = false
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end
    if restore then
        for _, item in ipairs(rainbowParts) do
            if item.part and item.part.Parent then
                item.part.Color = item.originalColor
            end
        end
    end
    table.clear(rainbowParts)
    rainbowButton.Text = "🌈 RAINBOW: OFF"
    rainbowButton.BackgroundColor3 = PANEL_LIGHT
    rainbowButton.TextColor3 = GREEN
end

connect(rainbowButton.Activated, function()
    if rainbowEnabled then
        stopRainbow(true)
        setStatus("RAINBOW OFF", "Couleurs d'origine restaurées", GREEN)
        return
    end

    local humanoid, root, vehicle = getRide()
    if not humanoid or not humanoid.SeatPart or not vehicle then
        setStatus("MONTE SUR LA TROTTINETTE", "Le Rainbow nécessite le siège de la trottinette", YELLOW)
        return
    end

    table.clear(rainbowParts)
    for _, object in ipairs(vehicle:GetDescendants()) do
        if object:IsA("BasePart") then
            table.insert(rainbowParts, {part = object, originalColor = object.Color})
        end
    end
    if #rainbowParts == 0 then
        setStatus("AUCUNE PIÈCE TROUVÉE", "Vérifie le modèle de la trottinette", YELLOW)
        return
    end

    rainbowEnabled = true
    rainbowButton.Text = "🌈 RAINBOW: ON"
    rainbowButton.BackgroundColor3 = GREEN_DARK
    rainbowButton.TextColor3 = WHITE
    local hue = 0
    rainbowConnection = RunService.Heartbeat:Connect(function(dt)
        if not rainbowEnabled then return end
        hue = (hue + dt * 0.3) % 1
        for index, item in ipairs(rainbowParts) do
            if item.part and item.part.Parent then
                item.part.Color = Color3.fromHSV((hue + (index - 1) / math.max(#rainbowParts, 1)) % 1, 1, 1)
            end
        end
    end)
    setStatus("RAINBOW ACTIVÉ", tostring(#rainbowParts) .. " pièces colorées", GREEN)
end)

-- 🎃 Auto Halloween: tagged event targets first, then clearly named Halloween objects.
-- The event's own server script still needs to validate collection/rewards.
local function getHalloweenPart(object)
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") then return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true) end
    if object:IsA("Attachment") then return object.Parent and object.Parent:IsA("BasePart") and object.Parent or nil end
    return nil
end

local function findHalloweenTargets()
    local found, seen = {}, {}
    local function add(object)
        local part = getHalloweenPart(object)
        if part and part:IsDescendantOf(workspace) and not seen[part] then
            seen[part] = true
            table.insert(found, part)
        end
    end
    for _, object in ipairs(CollectionService:GetTagged("HalloweenQuest")) do add(object) end
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") or object:IsA("Model") or object:IsA("Attachment") then
            local name = string.lower(object.Name)
            if object:GetAttribute("HalloweenQuest") == true
                or object:GetAttribute("IsQuestTarget") == true
                or string.find(name, "halloween", 1, true)
                or string.find(name, "pumpkin", 1, true)
                or string.find(name, "candy", 1, true)
                or string.find(name, "lantern", 1, true) then
                add(object)
            end
        end
    end
    table.sort(found, function(a, b)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return a:GetFullName() < b:GetFullName() end
        return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
    end)
    return found
end

local function halloweenOff(message, detail, color)
    halloweenEnabled = false
    halloweenButton.Text = "🎃 AUTO HALLOWEEN: OFF"
    halloweenButton.BackgroundColor3 = PANEL_LIGHT
    halloweenButton.TextColor3 = YELLOW
    setStatus(message, detail, color or YELLOW)
end

connect(halloweenButton.Activated, function()
    halloweenEnabled = not halloweenEnabled
    halloweenRunId += 1
    local runId = halloweenRunId
    if not halloweenEnabled then
        halloweenButton.Text = "🎃 AUTO HALLOWEEN: OFF"
        halloweenButton.BackgroundColor3 = PANEL_LIGHT
        halloweenButton.TextColor3 = YELLOW
        setStatus("AUTO HALLOWEEN ARRÊTÉ", "Parcours interrompu", GRAY)
        return
    end

    halloweenButton.Text = "🎃 AUTO HALLOWEEN: ON"
    halloweenButton.BackgroundColor3 = GREEN_DARK
    halloweenButton.TextColor3 = WHITE
    task.spawn(function()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not root then
            halloweenOff("PERSONNAGE NON DISPONIBLE", "Réapparais puis réessaie", YELLOW)
            return
        end
        if humanoid.SeatPart then
            halloweenOff("DESCENDS DE LA TROTTINETTE", "Le parcours auto se fait à pied", YELLOW)
            return
        end

        local visited, completed, attempts = {}, 0, 0
        setStatus("RECHERCHE DES QUÊTES", "Recherche des cibles Halloween…", YELLOW)
        while halloweenEnabled and halloweenRunId == runId and attempts < 100 do
            character = player.Character
            humanoid = character and character:FindFirstChildOfClass("Humanoid")
            root = character and character:FindFirstChild("HumanoidRootPart")
            if not humanoid or humanoid.Health <= 0 or not root then
                halloweenOff("PERSONNAGE PERDU", "Arrêt du parcours automatique", YELLOW)
                return
            end
            if humanoid.SeatPart then
                halloweenOff("TROTTINETTE DÉTECTÉE", "Descends pour continuer le parcours", YELLOW)
                return
            end

            local target
            for _, candidate in ipairs(findHalloweenTargets()) do
                if candidate.Parent and not visited[candidate] and (candidate.Position - root.Position).Magnitude > 5 then
                    target = candidate
                    break
                elseif candidate.Parent and not visited[candidate] then
                    visited[candidate] = true
                    completed += 1
                end
            end
            if not target then break end
            attempts += 1
            setStatus("HALLOWEEN EN COURS", string.format("Objectif %d • %s", completed + 1, target.Name), GREEN)

            local path = PathfindingService:CreatePath({AgentCanJump = true, WaypointSpacing = 6})
            local ok = pcall(function() path:ComputeAsync(root.Position, target.Position) end)
            local reached = false
            if ok and path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, waypoint in ipairs(waypoints) do
                    if not halloweenEnabled or halloweenRunId ~= runId then break end
                    if not target.Parent then break end
                    if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
                    humanoid:MoveTo(waypoint.Position)
                    local arrived = false
                    local connection = humanoid.MoveToFinished:Connect(function(success) arrived = success end)
                    local began = os.clock()
                    while halloweenEnabled and halloweenRunId == runId and not arrived and os.clock() - began < 5 do task.wait(0.1) end
                    connection:Disconnect()
                    if not arrived then break end
                end
                reached = (target.Position - root.Position).Magnitude <= 12
            else
                humanoid:MoveTo(target.Position)
                local arrived = false
                local connection = humanoid.MoveToFinished:Connect(function(success) arrived = success end)
                local began = os.clock()
                while halloweenEnabled and halloweenRunId == runId and not arrived and os.clock() - began < 5 do task.wait(0.1) end
                connection:Disconnect()
                reached = (target.Position - root.Position).Magnitude <= 12
            end
            visited[target] = true
            if reached then completed += 1 end
            task.wait(0.2)
        end
        if halloweenRunId == runId and halloweenEnabled then
            halloweenOff("PARCOURS TERMINÉ", completed .. " cible(s) visitée(s). Récompenses à valider côté serveur.", GREEN)
        end
    end)
end)

local function animate(runId)
    local humanoid, root, vehicle = getRide()

    if not humanoid then
        setStatus(
            "CHARACTER NOT READY",
            "Spawn and try START again",
            YELLOW
        )

        return false
    end

    local useVehicle = vehicle ~= nil
    local originalAutoRotate = humanoid.AutoRotate

    local originalPivot = useVehicle
        and vehicle:GetPivot()
        or root.CFrame

    local originalPosition = originalPivot.Position
    local originalRotation = originalPivot.Rotation

    local highPosition = originalPosition
        + Vector3.new(0, settings.floatDistance, 0)

    local finishedNormally = false

    local function isCancelled()
        return not running
            or cancelId ~= runId
            or not root.Parent
            or humanoid.Health <= 0
            or (useVehicle and not vehicle.Parent)
    end

    local function getCurrentPosition()
        if useVehicle then
            return vehicle:GetPivot().Position
        end

        return root.Position
    end

    -- Rotate around world Y while preserving starting orientation.
    local function setPivot(position, angle)
        if useVehicle then
            if not vehicle.Parent then
                return
            end

            vehicle:PivotTo(
                CFrame.new(position)
                    * CFrame.Angles(0, angle, 0)
                    * originalRotation
            )
        else
            if not root.Parent then
                return
            end

            root.CFrame =
                CFrame.new(position)
                * CFrame.Angles(0, angle, 0)
                * originalRotation
        end
    end

    local function moveTo(target, duration, allowCancel)
        local origin = getCurrentPosition()
        local started = os.clock()

        duration = math.max(duration, 0.01)

        while true do
            if not root.Parent
                or humanoid.Health <= 0
                or (useVehicle and not vehicle.Parent) then

                return false
            end

            if allowCancel and isCancelled() then
                return false
            end

            local alpha = math.clamp(
                (os.clock() - started) / duration,
                0,
                1
            )

            local smooth = alpha * alpha * (3 - 2 * alpha)

            setPivot(origin:Lerp(target, smooth), 0)
            tweenProgress(alpha)

            if alpha >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end

        return true
    end

    humanoid.AutoRotate = false

    local ok, err = pcall(function()
        setStatus(
            "LIFTING",
            useVehicle and "Moving seated vehicle" or "Moving character"
        )

        if not moveTo(highPosition, DEFAULTS.liftDuration, true) then
            return
        end

        if isCancelled() then
            return
        end

        setStatus(
            "TURBO SPIN ACTIVE",
            string.format(
                "%d rotations • %.1f rps",
                settings.numberOfSpins,
                settings.spinSpeed
            ),
            GREEN
        )

        local totalTime = settings.numberOfSpins / settings.spinSpeed
        local started = os.clock()

        while true do
            if isCancelled() then
                return
            end

            local elapsed = math.min(
                os.clock() - started,
                totalTime
            )

            local angle = elapsed
                * settings.spinSpeed
                * math.pi
                * 2

            setPivot(highPosition, angle)
            tweenProgress(elapsed / totalTime)

            if elapsed >= totalTime then
                break
            end

            RunService.Heartbeat:Wait()
        end

        finishedNormally = true
    end)

    -- Attempt to return to starting height if possible.
    if root.Parent
        and humanoid.Parent
        and humanoid.Health > 0
        and (not useVehicle or vehicle.Parent) then

        setStatus(
            "LANDING",
            "Returning to starting position",
            YELLOW
        )

        pcall(function()
            moveTo(
                originalPosition,
                DEFAULTS.landDuration,
                false
            )
        end)
    end

    if humanoid.Parent then
        humanoid.AutoRotate = originalAutoRotate
    end
    if not ok then
        warn("[KUKIRIN TURBO] Motion error: " .. tostring(err))

        setStatus(
            "MOTION ERROR",
            "Check Output for details",
            RED
        )
    end

    tweenProgress(0)

    return finishedNormally
end

local function stopMotion()
    running = false
    cancelId += 1

    if sessionStartedAt then
        sessionElapsed = os.clock() - sessionStartedAt
        sessionStartedAt = nil

        timerLabel.Text = "SESSION  " .. formatTime(sessionElapsed)
    end

    setStatus(
        "STOPPING",
        "Returning to starting height if possible",
        RED
    )
end

connect(startButton.Activated, function()
    if busy then
        return
    end

    if not readSettings() then
        return
    end

    busy = true
    running = true
    cancelId += 1

    local myRunId = cancelId

    sessionStartedAt = os.clock()
    sessionElapsed = 0
    lastRunStartedAt = nil
    totalRuns = 0

    statsLabel.Text = "RUNS COMPLETED: 0"

    setStatus(
        "SYSTEM STARTING",
        "Reading character and settings"
    )

    startButton.Text = "●  RUNNING"
    startButton.BackgroundColor3 = GREEN_DARK
    startButton.TextColor3 = WHITE

    task.spawn(function()
        while running and cancelId == myRunId do
            lastRunStartedAt = os.clock()

            local completed = animate(myRunId)

            if completed then
                totalRuns += 1
                statsLabel.Text = "RUNS COMPLETED: " .. totalRuns
            end

            if not running or cancelId ~= myRunId then
                break
            end

            local remaining = settings.repeatDelay

            while running
                and cancelId == myRunId
                and remaining > 0 do

                setStatus(
                    "REPEAT WAIT",
                    string.format(
                        "Next run in %.1f seconds",
                        remaining
                    ),
                    GREEN
                )

                local before = os.clock()

                task.wait(math.min(0.1, remaining))

                remaining -= os.clock() - before
            end
        end

        busy = false
        running = false

        if sessionStartedAt then
            sessionElapsed = os.clock() - sessionStartedAt
            sessionStartedAt = nil

            timerLabel.Text = "SESSION " .. formatTime(sessionElapsed)
        end

        startButton.Text = "▶  START"
        startButton.BackgroundColor3 = GREEN
        startButton.TextColor3 = BLACK

        if gui.Parent then
            setStatus(
                "SYSTEM STOPPED",
                "Ready for another run",
                GRAY
            )

            tweenProgress(0)
        end
    end)
end)

connect(stopButton.Activated, stopMotion)

-- Persistent scooter speed controller.
-- While enabled and the player is seated, continually controls horizontal speed
-- in the direction the scooter is facing. This is client-side and may be limited
-- by the vehicle's own server-side controller/network ownership.
connect(boostButton.Activated, function()
    local boost = tonumber(speedBoostBox.Text)
    if not boost or boost ~= boost or boost < 1 or boost > 200 then
        setStatus("INVALID SPEED LEVEL", "Enter a value from 1 to 5", RED)
        return
    end

    settings.scooterSpeedBoost = boost
    local humanoid, root, vehicle = getRide()
    if not humanoid or not humanoid.SeatPart or not vehicle then
        setStatus("NOT ON SCOOTER", "Sit on the scooter before enabling permanent speed", YELLOW)
        return
    end

    local part = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart", true)
    if not part or part.Anchored then
        setStatus("SPEED UNAVAILABLE", "Scooter needs an unanchored physical part", RED)
        return
    end

    scooterBoostEnabled = not scooterBoostEnabled
    if scooterBoostEnabled then
        boostButton.Text = "⚡ PERMANENT SPEED: ON  •  CLICK TO STOP"
        boostButton.BackgroundColor3 = GREEN_DARK
        setStatus("PERMANENT SPEED ON", string.format("Target speed: %d", math.floor(boost)), GREEN)
    else
        boostButton.Text = "⚡ PERMANENT SPEED: OFF  •  CLICK TO TOGGLE"
        boostButton.BackgroundColor3 = PANEL_LIGHT
        setStatus("PERMANENT SPEED OFF", "Speed controller disabled", GRAY)
    end
end)

connect(RunService.Heartbeat, function(dt)
    if not scooterBoostEnabled then
        return
    end

    local humanoid, root, vehicle = getRide()
    if not humanoid or not humanoid.SeatPart or not vehicle then
        return
    end

    local seat = humanoid.SeatPart
    local part = vehicle.PrimaryPart or seat
    if not part or not part:IsA("BasePart") or part.Anchored then
        return
    end

    local velocity = part.AssemblyLinearVelocity
    local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
    local targetSpeed = math.min(settings.scooterSpeedBoost, 200)

    -- Respect a VehicleSeat's throttle when available. For other seats, preserve
    -- the current travel direction and maintain the target once the scooter moves.
    local throttle = nil
    if seat:IsA("VehicleSeat") then
        throttle = seat.ThrottleFloat
    end

    local direction
    if throttle ~= nil then
        -- For VehicleSeat vehicles, only accelerate while the player presses
        -- forward or reverse; let the vehicle slow down when throttle is released.
        if math.abs(throttle) > 0.05 then
            direction = part.CFrame.LookVector * (throttle > 0 and 1 or -1)
            direction = Vector3.new(direction.X, 0, direction.Z)
            if direction.Magnitude > 0.01 then
                direction = direction.Unit
            else
                direction = nil
            end
        end
    elseif horizontal.Magnitude > 2 then
        -- Generic seats have no throttle signal, so maintain existing travel direction.
        direction = horizontal.Unit
    end

    if direction then
        -- Smoothly bring speed to the selected target without changing vertical motion.
        local blend = math.clamp(dt * 8, 0, 1)
        local desired = direction * targetSpeed
        local nextHorizontal = horizontal:Lerp(desired, blend)
        part.AssemblyLinearVelocity = Vector3.new(nextHorizontal.X, velocity.Y, nextHorizontal.Z)
    end
end)

connect(afkButton.Activated, function()
    antiAFKEnabled = not antiAFKEnabled

    if antiAFKEnabled then
        afkButton.Text = "ANTI-AFK: ON"
        afkButton.BackgroundColor3 = GREEN_DARK
        afkButton.TextColor3 = GREEN

        setStatus(
            "ANTI-AFK FLAG ON",
            "No idle-kick guarantee in this client",
            YELLOW
        )
    else
        afkButton.Text = "ANTI-AFK: OFF"
        afkButton.BackgroundColor3 = PANEL_LIGHT
        afkButton.TextColor3 = GRAY

        setStatus(
            "SYSTEM READY",
            "Anti-AFK flag disabled",
            GREEN
        )
    end
end)


-- Anti-ragdoll for this character in experiences you own or are authorized to test.
-- Server-controlled ragdoll systems may override client-side state changes.
local function attachAntiRagdoll(character)
    if antiRagdollConnection then
        antiRagdollConnection:Disconnect()
        antiRagdollConnection = nil
    end
    if not antiRagdollEnabled or not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    local function recoverIfRagdolled(newState)
        if not antiRagdollEnabled or humanoid.Health <= 0 then return end
        if newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown
            or newState == Enum.HumanoidStateType.Physics then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end

    antiRagdollConnection = humanoid.StateChanged:Connect(function(_, newState)
        recoverIfRagdolled(newState)
    end)
    recoverIfRagdolled(humanoid:GetState())
end

connect(antiRagdollButton.Activated, function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        antiRagdollButton.Text = "ANTI-RAGDOLL: ON"
        antiRagdollButton.BackgroundColor3 = GREEN_DARK
        antiRagdollButton.TextColor3 = GREEN
        attachAntiRagdoll(player.Character)
        setStatus("ANTI-RAGDOLL ON", "Attempts to recover from falls", GREEN)
    else
        antiRagdollButton.Text = "ANTI-RAGDOLL: OFF"
        antiRagdollButton.BackgroundColor3 = PANEL_LIGHT
        antiRagdollButton.TextColor3 = GRAY
        if antiRagdollConnection then
            antiRagdollConnection:Disconnect()
            antiRagdollConnection = nil
        end
        setStatus("ANTI-RAGDOLL OFF", "Normal character physics restored", GRAY)
    end
end)

-- Status-only toggle; this does not bypass Roblox idle enforcement.
connect(player.CharacterAdded, function(character)
    if running then
        stopMotion()

        setStatus(
            "CHARACTER RESPAWNED",
            "Motion stopped safely",
            YELLOW
        )
    end
    if antiRagdollEnabled then
        task.defer(function() attachAntiRagdoll(character) end)
    end
end)

-- Accurate elapsed timer.
connect(RunService.Heartbeat, function()
    if sessionStartedAt then
        sessionElapsed = os.clock() - sessionStartedAt

        timerLabel.Text = "SESSION  " .. formatTime(sessionElapsed)
    end
end)

-- Gentle neon pulse on the outline.
task.spawn(function()
    while gui.Parent do
        local outline = frame:FindFirstChildOfClass("UIStroke")

        if not outline then
            break
        end

        local fadeOut = TweenService:Create(
            outline,
            TweenInfo.new(
                1.1,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Transparency = 0.45
            }
        )

        fadeOut:Play()
        fadeOut.Completed:Wait()

        if not gui.Parent then
            break
        end

        local fadeIn = TweenService:Create(
            outline,
            TweenInfo.new(
                1.1,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            ),
            {
                Transparency = 0
            }
        )

        fadeIn:Play()
        fadeIn.Completed:Wait()
    end
end)

-- Clean up event connections if the GUI is removed.
connect(gui.Destroying, function()
    if rainbowConnection then rainbowConnection:Disconnect() end
    halloweenEnabled = false
    halloweenRunId += 1
    running = false
    cancelId += 1

    for _, c in ipairs(connections) do
        if c.Connected then
            c:Disconnect()
        end
    end
end)

showTab("Mouvement")
setStatus(
    "SYSTEM READY",
    "Choisis un onglet puis lance une fonction",
    GREEN
)
