--[[
    NEXUS // PHANTOM X — ADVANCED CLIENT EDITION
    Roblox Luau • script local • painel único, sem dependências externas

    Recursos locais: ESP, caixas 2D, traçadores, nomes, HP, distância,
    destaque 3D, seleção automática, camera-lock com predição,
    FOV configurável, voo local, joystick de voo para mobile,
    painel movível, configurações persistentes quando disponíveis.

    IMPORTANTE: Este programa NÃO altera munição, recarga, dano ou
    anticheat no servidor. Não há como garantir essas mudanças com
    um script exclusivamente cliente. Compatibilidade depende do jogo.

    EXECUÇÃO: carregar uma única vez no cliente. Rodar de novo limpa
    a cópia anterior automaticamente.
]]

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local Workspace = game:GetService('Workspace')

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local Environment = (type(getgenv) == 'function' and getgenv()) or _G
local KEY = '__NEXUS_PHANTOM_X_2026__'
local OLD_KEYS = { '__NEXUS_ARENA_2026__', '__NEXUS_PHANTOM_2025__' }
for _, old in ipairs(OLD_KEYS) do
    if type(Environment[old]) == 'table' and
        type(Environment[old].Destroy) == 'function' then
        pcall(Environment[old].Destroy)
    end
end
if type(Environment[KEY]) == 'table' and type(Environment[KEY].Destroy) == 'function' then
    pcall(Environment[KEY].Destroy)
end

local Toolkit = {
    Alive = true,
    Connections = {},
    Objects = {},
    Lines = {},
    Flight = {},
    ESP = {},
    NPCESP = {},
    Target = nil,
    Visible = true,
    Holding = {},
    Statistics = { Frames = 0, Players = 0, Target = 'Nenhum', Visible = 0, BehindWall = 0, ToolShots = 0, Locks = 0, Switches = 0 },
    AimState = { LockedSince = 0, LockCount = 0, LastTarget = nil, LastSelection = 0, LastShot = 0, LastCombatTool = nil, AutoEquipped = false },
    Diagnostics = { ESPFailures = 0, AimFailures = 0, LastError = '' },
}
Environment[KEY] = Toolkit

local Theme = {
    Background = Color3.fromRGB(9, 11, 24),
    Surface = Color3.fromRGB(18, 22, 40),
    Surface2 = Color3.fromRGB(27, 31, 58),
    Border = Color3.fromRGB(49, 65, 93),
    Primary = Color3.fromRGB(63, 234, 255),
    Purple = Color3.fromRGB(169, 83, 255),
    Gold = Color3.fromRGB(255, 205, 95),
    PrimaryLow = Color3.fromRGB(28, 73, 112),
    Text = Color3.fromRGB(241, 246, 255),
    Muted = Color3.fromRGB(155, 174, 197),
    Positive = Color3.fromRGB(100, 239, 174),
    Danger = Color3.fromRGB(255, 110, 136),
    Shadow = Color3.fromRGB(0, 0, 0),
}

local Defaults = {
    Aim = true,
    AimFOV = 190,
    AimSmooth = 100,
    AimDistance = 1100,
    AimInfiniteRange = true,
    AimAcquireGlobal = true,
    AimTrackOffscreen = true,
    AimTrackThroughWalls = true,
    AimAutoSwitch = true,
    AimInstant = true,
    AimLeadTime = 12,
    AimVerticalLead = 0,
    AimRetargetDelay = 0,
    AimSmoothingMode = 'Direct',
    AimRequireHealthy = true,
    AimMinHealth = 1,
    AimClosestBody = false,
    AimAlertOnSwitch = true,
    AimAutoFire = false,
    AimFireRate = 7,
    AimFireCondition = 'Visible',
    AimFireMaxDistance = 300,
    AimDisableWhileMenu = false,
    AimSmartLead = false,
    AimAirPrediction = false,
    AimAutoEquip = false,
    AimPart = 'Head',
    AimPriority = 'Distance',
    AimSticky = true,
    AimTeamCheck = true,
    AimVisibility = false,
    AimRequiresTool = false,
    AimShowFOV = true,
    AimCrosshair = true,
    ESPEnabled = true,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPHighlight = true,
    ESPSkeleton = false,
    ESPShowWeapon = false,
    ESPHeadDot = false,
    ESPOffscreen = true,
    ESPThroughWalls = true,
    ESPTeamCheck = true,
    ESPRange = 1300,
    ESPUnlimitedRange = true,
    ESPTracersOffscreen = true,
    ESPTraceOrigin = 'Bottom',
    ESPTracerThickness = 2,
    ESPLockIndicator = true,
    ESPPulseTarget = true,
    ESPUpdateRate = 20,
    ESPIncludeNPC = false,
    ESPNPCRange = 1100,
    ESPNPCMax = 30,
    ESPNPCScanInterval = 5,
    ESPAdaptivePerformance = true,
    RadarEnabled = false,
    HUDMotion = true,
    HUDLockRing = true,
    HUDOffscreenLockArrow = true,
    HUDShowVisibility = true,
    HUDWarnings = false,
    HUDPredictionMarker = true,
    HUDSpectate = false,
    UIAnimations = true,
    UISpectrum = true,
    QuickButtons = true,
    TargetNotifications = true,
    RadarRange = 420,
    RadarSize = 142,
    HUDTargetCard = true,
    FlightEnabled = false,
    FlightSpeed = 65,
    FlightVerticalSpeed = 50,
    FlightFacing = true,
    FlightUseControl = true,
    UIPositionX = 0.5,
    UIPositionY = 0.5,
}

local Config = {}
for name, value in pairs(Defaults) do Config[name] = value end
local SaveName = 'nexus_phantom_x_v3.json'
local function loadSettings()
    if type(readfile) ~= 'function' or type(isfile) ~= 'function' then return end
    local ok, decoded = pcall(function()
        if not isfile(SaveName) then return nil end
        return HttpService:JSONDecode(readfile(SaveName))
    end)
    if ok and type(decoded) == 'table' then
        for name, default in pairs(Defaults) do
            if type(decoded[name]) == type(default) then
                Config[name] = decoded[name]
            end
        end
    end
    -- Não ativar voo sozinho depois de uma execução nova.
    Config.FlightEnabled = false
end
loadSettings()

local function saveSettings()
    if type(writefile) ~= 'function' then return end
    pcall(function()
        local saved = {}
        for name in pairs(Defaults) do
            saved[name] = Config[name]
        end
        writefile(SaveName, HttpService:JSONEncode(saved))
    end)
end

local function connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Toolkit.Connections, conn)
    return conn
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(obj, radius)
    return make('UICorner', { CornerRadius = UDim.new(0, radius or 10) }, obj)
end

local function border(obj, color, thickness, transparency)
    return make('UIStroke', {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, obj)
end

local function pad(obj, top, right, bottom, left)
    return make('UIPadding', {
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft = UDim.new(0, left),
    }, obj)
end

local function label(props, parent)
    local settings = {
        BackgroundTransparency = 1,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
    }
    for k, v in pairs(props or {}) do settings[k] = v end
    return make('TextLabel', settings, parent)
end

local function button(props, parent)
    local settings = {
        AutoButtonColor = false,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Surface2,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
    }
    for k, v in pairs(props or {}) do settings[k] = v end
    return make('TextButton', settings, parent)
end

local function animate(obj, info, properties)
    if obj and obj.Parent then
        pcall(function() TweenService:Create(obj, info, properties):Play() end)
    end
end
local QuickTween = TweenInfo.new(.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Screen = make('ScreenGui', {
    Name = 'PHANTOM_X_UI_V3',
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 99,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)
Toolkit.Root = Screen

local Overlay = make('Frame', {
    Name = 'Overlay',
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(0, 0),
    ZIndex = 2,
}, Screen)

local UI = make('Frame', {
    Name = 'Dashboard',
    AnchorPoint = Vector2.new(.5, .5),
    Size = UDim2.new(0, 390, 0, 440),
    Position = UDim2.fromScale(Config.UIPositionX, Config.UIPositionY),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 30,
    Active = true,
}, Screen)
corner(UI, 17)
border(UI, Theme.Border, 1.2)
local scale = make('UIScale', { Scale = 1 }, UI)

local Header = make('Frame', {
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 64),
    ZIndex = 31,
    Active = true,
}, UI)
corner(Header, 17)
make('Frame', {
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -15),
    Size = UDim2.new(1, 0, 0, 15),
    ZIndex = 31,
}, Header)
make('Frame', {
    BackgroundColor3 = Theme.Primary,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 15, 0, 16),
    Size = UDim2.fromOffset(3, 30),
    ZIndex = 32,
}, Header)
label({
    Text = 'PHANTOM   /   X',
    Font = Enum.Font.GothamBlack,
    TextSize = 17,
    Position = UDim2.new(0, 29, 0, 10),
    Size = UDim2.new(1, -122, 0, 25),
    ZIndex = 32,
}, Header)
label({
    Text = 'TACTICAL INTERFACE  •  V3  •  LUA',
    TextColor3 = Theme.Muted,
    TextSize = 9,
    Position = UDim2.new(0, 30, 0, 37),
    Size = UDim2.new(1, -112, 0, 15),
    ZIndex = 32,
}, Header)
local Close = button({
    Text = '—',
    TextSize = 19,
    Size = UDim2.fromOffset(34, 30),
    Position = UDim2.new(1, -46, 0, 16),
    BackgroundColor3 = Theme.Surface2,
    ZIndex = 33,
}, Header)
corner(Close, 9)

-- ===============================================
-- PHANTOM DESIGN SYSTEM • gradients + motion
-- ===============================================
local MainBorder = UI:FindFirstChildOfClass('UIStroke')
local Spectrum = make('UIGradient', {
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(.33, Theme.Purple),
        ColorSequenceKeypoint.new(.66, Theme.Gold),
        ColorSequenceKeypoint.new(1, Theme.Primary)
    }),
}, MainBorder)
local HeaderGradient = make('UIGradient', {
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Surface),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(29, 19, 57)),
        ColorSequenceKeypoint.new(1, Theme.Surface)
    }),
}, Header)
local HeaderBeam = make('Frame', {
    Name = 'FluxSweep',
    BackgroundColor3 = Theme.Primary,
    BackgroundTransparency = .15,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(.35, 0, 0, 2),
    ZIndex = 33,
}, Header)
local BeamGradient = make('UIGradient', {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, HeaderBeam)
local PulseTag = label({
    Text = '●  LIVE',
    TextColor3 = Theme.Positive,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextSize = 9,
    Size = UDim2.fromOffset(75, 12),
    Position = UDim2.new(1, -124, 0, 39),
    ZIndex = 33,
}, Header)
local UIEffects = { elapsed = 0, previousSwitch = 0, accent = Theme.Primary }
connect(Header.MouseEnter, function()
    animate(HeaderBeam, QuickTween, { BackgroundTransparency = 0 })
end)
connect(Header.MouseLeave, function()
    animate(HeaderBeam, QuickTween, { BackgroundTransparency = .15 })
end)

local Tabs = make('ScrollingFrame', {
    Name = 'Tabs',
    Position = UDim2.new(0, 10, 0, 73),
    Size = UDim2.new(1, -20, 0, 42),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    ScrollingDirection = Enum.ScrollingDirection.X,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ZIndex = 32,
}, UI)
make('UIListLayout', {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Tabs)

local Content = make('Frame', {
    Name = 'Contents',
    Position = UDim2.new(0, 10, 0, 124),
    Size = UDim2.new(1, -20, 1, -163),
    BackgroundTransparency = 1,
    ZIndex = 32,
}, UI)

local Footer = make('Frame', {
    Name = 'Footer',
    Position = UDim2.new(0, 14, 1, -30),
    Size = UDim2.new(1, -28, 0, 20),
    BackgroundTransparency = 1,
    ZIndex = 32,
}, UI)
local FooterStatus = label({
    Text = '●  ATIVO',
    TextColor3 = Theme.Positive,
    TextSize = 10,
    Size = UDim2.new(.57, 0, 1, 0),
    ZIndex = 32,
}, Footer)
local FooterRight = label({
    Text = 'ESP 0  •  ALVO —',
    TextColor3 = Theme.Muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.new(.48, 0, 0, 0),
    Size = UDim2.new(.52, 0, 1, 0),
    ZIndex = 32,
}, Footer)

local Floating = button({
    Name = 'OpenMenu',
    Text = 'X',
    TextColor3 = Theme.Background,
    TextSize = 18,
    BackgroundColor3 = Theme.Primary,
    Size = UDim2.fromOffset(46, 46),
    Position = UDim2.new(0, 12, .5, -23),
    Visible = false,
    ZIndex = 40,
}, Screen)
corner(Floating, 14)
border(Floating, Color3.fromRGB(255, 255, 255), 1, .7)

local function animateIntro()
    if not Config.UIAnimations then return end
    local targetScale = scale.Scale
    scale.Scale = targetScale * .87
    animate(scale, TweenInfo.new(.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = targetScale })
end

local function togglePanel()
    Toolkit.Visible = not Toolkit.Visible
    UI.Visible = Toolkit.Visible
    Floating.Visible = not Toolkit.Visible
    if Toolkit.Visible then
        animateIntro()
        animate(Floating, QuickTween, { BackgroundColor3 = Theme.Primary })
    end
end
connect(Close.MouseButton1Click, togglePanel)
connect(Floating.MouseButton1Click, togglePanel)

local Notice = make('Frame', {
    Name = 'Toast',
    AnchorPoint = Vector2.new(.5, 0),
    Position = UDim2.new(.5, 0, 0, -70),
    Size = UDim2.new(0, 315, 0, 42),
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    ZIndex = 80,
}, Screen)
corner(Notice, 11)
border(Notice)
local NoticeText = label({
    Text = '',
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 81,
}, Notice)
local NoticeToken = 0
local function toast(message)
    NoticeToken = NoticeToken + 1
    local token = NoticeToken
    NoticeText.Text = message
    animate(Notice, QuickTween, { Position = UDim2.new(.5, 0, 0, 24) })
    task.delay(2.6, function()
        if Toolkit.Alive and NoticeToken == token then
            animate(Notice, QuickTween, { Position = UDim2.new(.5, 0, 0, -70) })
        end
    end)
end

local function clampDashboard()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
    if not viewport then return end
    local width, height = viewport.X, viewport.Y
    if width < 430 or height < 500 then
        local s = math.min(.95, (width - 12) / 390, (height - 20) / 440)
        scale.Scale = math.max(.54, s)
    else
        scale.Scale = 1
    end
end
clampDashboard()

local dragging = false
local dragStart = nil
local dragOffset = nil
connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        dragOffset = UI.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragging or not dragStart or not dragOffset then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and
       input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    local cx = dragOffset.X.Offset + delta.X
    local cy = dragOffset.Y.Offset + delta.Y
    UI.Position = UDim2.new(dragOffset.X.Scale, cx, dragOffset.Y.Scale, cy)
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
            if view and view.X > 0 and view.Y > 0 then
                Config.UIPositionX = math.clamp(UI.AbsolutePosition.X / view.X + UI.AbsoluteSize.X / view.X / 2, 0, 1)
                Config.UIPositionY = math.clamp(UI.AbsolutePosition.Y / view.Y + UI.AbsoluteSize.Y / view.Y / 2, 0, 1)
            end
        end
    end
end)

-- Componentes internos. Não depende de UI libraries baixadas da internet.
local Library = {}
Library.__index = Library
local Pages = {}
local Refreshers = {}
local CurrentPage = nil

function Library:CreatePage(name, width)
    local tab = button({
        Text = name,
        TextSize = 11,
        Size = UDim2.new(0, width or 72, 1, -3),
        LayoutOrder = #Pages + 1,
        BackgroundColor3 = Theme.Surface,
        TextColor3 = Theme.Muted,
        ZIndex = 33,
    }, Tabs)
    corner(tab, 9)

    local scroll = make('ScrollingFrame', {
        Name = name,
        Visible = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Primary,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ZIndex = 32,
    }, Content)
    pad(scroll, 2, 7, 12, 1)
    make('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, scroll)
    local data = { Tab = tab, Body = scroll, Name = name }
    table.insert(Pages, data)
    connect(tab.MouseButton1Click, function()
        for _, page in ipairs(Pages) do
            local active = page == data
            page.Body.Visible = active
            animate(page.Tab, QuickTween, {
                BackgroundColor3 = active and Theme.PrimaryLow or Theme.Surface,
                TextColor3 = active and Theme.Primary or Theme.Muted,
            })
        end
        CurrentPage = data
    end)
    return setmetatable({ Body = scroll, Count = 0 }, Library)
end

function Library:_row(height)
    self.Count = self.Count + 1
    local row = make('Frame', {
        LayoutOrder = self.Count,
        Size = UDim2.new(1, -3, 0, height),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 33,
    }, self.Body)
    corner(row, 10)
    return row
end

function Library:Section(titleText)
    self.Count = self.Count + 1
    local section = label({
        Text = string.upper(titleText),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Primary,
        LayoutOrder = self.Count,
        Size = UDim2.new(1, 0, 0, 19),
        ZIndex = 34,
    }, self.Body)
    return section
end

function Library:Note(text)
    local row = self:_row(53)
    label({
        Text = text,
        TextColor3 = Theme.Muted,
        TextSize = 11,
        TextWrapped = true,
        Position = UDim2.new(0, 12, 0, 5),
        Size = UDim2.new(1, -24, 1, -10),
        ZIndex = 34,
    }, row)
    return row
end

function Library:Toggle(titleText, setting, description, onChange)
    local row = self:_row(description and 63 or 48)
    label({
        Text = titleText,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Position = UDim2.fromOffset(12, 5),
        Size = UDim2.new(1, -78, 0, 27),
        ZIndex = 34,
    }, row)
    if description then
        label({
            Text = description,
            TextColor3 = Theme.Muted,
            TextSize = 10,
            Position = UDim2.fromOffset(12, 31),
            Size = UDim2.new(1, -80, 0, 22),
            TextWrapped = true,
            ZIndex = 34,
        }, row)
    end
    local toggle = button({
        Text = '',
        Position = UDim2.new(1, -59, .5, -12),
        Size = UDim2.fromOffset(47, 24),
        BackgroundColor3 = Theme.Surface2,
        ZIndex = 34,
    }, row)
    corner(toggle, 12)
    local knob = make('Frame', {
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 35,
    }, toggle)
    corner(knob, 8)
    local function refresh()
        local on = Config[setting]
        animate(toggle, QuickTween, {
            BackgroundColor3 = on and Theme.PrimaryLow or Theme.Surface2,
        })
        animate(knob, QuickTween, {
            BackgroundColor3 = on and Theme.Primary or Theme.Muted,
            Position = UDim2.fromOffset(on and 27 or 4, 4),
        })
    end
    refresh()
    table.insert(Refreshers, refresh)
    connect(toggle.MouseButton1Click, function()
        Config[setting] = not Config[setting]
        for _, updater in ipairs(Refreshers) do pcall(updater) end
        if onChange then onChange(Config[setting]) end
        saveSettings()
    end)
    return refresh
end

function Library:Slider(titleText, setting, min, max, suffix, onChange)
    local row = self:_row(66)
    label({
        Text = titleText,
        Font = Enum.Font.GothamMedium,
        Size = UDim2.new(1, -110, 0, 20),
        Position = UDim2.fromOffset(12, 5),
        TextSize = 12,
        ZIndex = 34,
    }, row)
    local valueLabel = label({
        Text = '',
        TextColor3 = Theme.Primary,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 92, 0, 20),
        Position = UDim2.new(1, -103, 0, 5),
        TextSize = 12,
        ZIndex = 34,
    }, row)
    local track = make('Frame', {
        BackgroundColor3 = Theme.Surface2,
        Position = UDim2.new(0, 13, 0, 44),
        Size = UDim2.new(1, -26, 0, 6),
        ZIndex = 34,
    }, row)
    corner(track, 3)
    local fill = make('Frame', {
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.Primary,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 35,
    }, track)
    corner(fill, 3)
    local dot = make('Frame', {
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(.5, .5),
        Position = UDim2.new(0, 0, .5, 0),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = 36,
    }, track)
    corner(dot, 7)
    local hitArea = button({
        Text = '',
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, .5, -14),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 37,
    }, track)
    local function refresh()
        local v = math.clamp(Config[setting], min, max)
        local ratio = (v - min) / math.max(1, max - min)
        valueLabel.Text = tostring(v) .. (suffix or '')
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        dot.Position = UDim2.new(ratio, 0, .5, 0)
    end
    refresh()
    table.insert(Refreshers, refresh)
    local active = false
    local activeInput = nil
    local function update(input)
        local width = track.AbsoluteSize.X
        if width < 1 then return end
        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        local value = math.floor(min + ratio * (max - min) + .5)
        Config[setting] = value
        refresh()
        if onChange then onChange(value) end
    end
    connect(hitArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = true
            activeInput = input
            update(input)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if not active then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input == activeInput then update(input) end
    end)
    connect(UserInputService.InputEnded, function(input)
        if not active then return end
        if input == activeInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = false
            activeInput = nil
            saveSettings()
        end
    end)
    return refresh
end

function Library:Choice(titleText, setting, values, onChange)
    local row = self:_row(54)
    label({
        Text = titleText,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(.52, -12, 1, 0),
        ZIndex = 34,
    }, row)
    local choice = button({
        Text = tostring(Config[setting]) .. '  ›',
        TextColor3 = Theme.Primary,
        BackgroundColor3 = Theme.Surface2,
        Position = UDim2.new(.53, 0, .5, -16),
        Size = UDim2.new(.47, -12, 0, 32),
        ZIndex = 34,
    }, row)
    corner(choice, 7)
    table.insert(Refreshers, function()
        choice.Text = tostring(Config[setting]) .. '  ›'
    end)
    connect(choice.MouseButton1Click, function()
        local index = table.find(values, Config[setting]) or 0
        Config[setting] = values[index % #values + 1]
        choice.Text = tostring(Config[setting]) .. '  ›'
        saveSettings()
        if onChange then onChange(Config[setting]) end
    end)
    return choice
end

function Library:Button(titleText, action, description)
    local row = self:_row(description and 61 or 47)
    local actionButton = button({
        Text = titleText,
        TextSize = 12,
        BackgroundColor3 = Theme.Surface2,
        Position = UDim2.new(0, 9, 0, 7),
        Size = UDim2.new(1, -18, 0, description and 30 or 33),
        ZIndex = 34,
    }, row)
    corner(actionButton, 8)
    border(actionButton, Theme.PrimaryLow, 1)
    if description then
        label({
            Text = description,
            TextColor3 = Theme.Muted,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new(0, 10, 0, 39),
            Size = UDim2.new(1, -20, 0, 16),
            ZIndex = 34,
        }, row)
    end
    connect(actionButton.MouseButton1Click, function()
        animate(actionButton, QuickTween, { BackgroundColor3 = Theme.PrimaryLow })
        task.delay(.18, function()
            if Toolkit.Alive then
                animate(actionButton, QuickTween, { BackgroundColor3 = Theme.Surface2 })
            end
        end)
        if action then action() end
    end)
    return actionButton
end

-- Search box with confirmation; no server requests.
function Library:SearchPlayer(titleText, callback)
    local row = self:_row(94)
    label({
        Text = titleText,
        TextColor3 = Theme.Primary,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Position = UDim2.fromOffset(12, 4),
        Size = UDim2.new(1, -24, 0, 23),
        ZIndex = 35,
    }, row)
    local input = make('TextBox', {
        Text = '',
        PlaceholderText = 'Nome / @usuário',
        ClearTextOnFocus = false,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -111, 0, 38),
        Position = UDim2.fromOffset(10, 37),
        ZIndex = 36,
    }, row)
    corner(input, 8)
    pad(input, 0, 8, 0, 9)
    local go = button({
        Text = 'LOCK',
        TextSize = 11,
        TextColor3 = Theme.Background,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.new(1, -93, 0, 37),
        Size = UDim2.fromOffset(83, 38),
        ZIndex = 36,
    }, row)
    corner(go, 8)
    connect(go.MouseButton1Click, function() callback(input.Text) end)
    connect(input.FocusLost, function(enter)
        if enter then callback(input.Text) end
    end)
    return input
end

-- Playback-free animated telemetry bars.
function Library:Telemetry(titleText, valueProvider)
    local row = self:_row(48)
    label({
        Text = titleText,
        TextSize = 11,
        TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(12, 2),
        Size = UDim2.new(1, -155, 1, -4),
        ZIndex = 35,
    }, row)
    local v = label({
        Text = '—',
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Primary,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -148, 0, 2),
        Size = UDim2.fromOffset(136, 41),
        ZIndex = 35,
    }, row)
    table.insert(Toolkit.Objects, function()
        if v.Parent then
            local ok, result = pcall(valueProvider)
            if ok then v.Text = tostring(result) end
        end
    end)
    return row
end

-- HUD de visão central / FOV.
local FOVCircle = make('Frame', {
    Name = 'FOV',
    AnchorPoint = Vector2.new(.5, .5),
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2),
    Visible = false,
    ZIndex = 7,
}, Overlay)
corner(FOVCircle, 9999)
border(FOVCircle, Theme.Primary, 1, .28)
local Crosshair = make('Frame', {
    Name = 'Crosshair',
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(26, 26),
    AnchorPoint = Vector2.new(.5, .5),
    Visible = false,
    ZIndex = 8,
}, Overlay)
for _, rec in ipairs({
    { x = 0, y = 11, w = 9, h = 2 },
    { x = 17, y = 11, w = 9, h = 2 },
    { x = 12, y = 0, w = 2, h = 9 },
    { x = 12, y = 17, w = 2, h = 9 },
}) do
    make('Frame', {
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.Primary,
        Position = UDim2.fromOffset(rec.x, rec.y),
        Size = UDim2.fromOffset(rec.w, rec.h),
        ZIndex = 8,
    }, Crosshair)
end

local TargetBanner = label({
    Text = 'ALVO: —',
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.Primary,
    TextXAlignment = Enum.TextXAlignment.Center,
    AnchorPoint = Vector2.new(.5, 0),
    Size = UDim2.fromOffset(230, 22),
    Visible = false,
    ZIndex = 8,
}, Overlay)

-- Ferramentas de alvo.
local function characterParts(plr)
    local char = plr and plr.Character
    if not char or not char.Parent then return end
    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if not humanoid or humanoid.Health <= 0 then return end
    local root = char:FindFirstChild('HumanoidRootPart')
        or char:FindFirstChild('Torso')
        or char:FindFirstChild('UpperTorso')
        or char:FindFirstChild('LowerTorso')
        or char.PrimaryPart
    if not root then
        root = char:FindFirstChildWhichIsA('BasePart', true)
    end
    if not root or not root:IsA('BasePart') then return end
    local head = char:FindFirstChild('Head')
        or char:FindFirstChild('UpperTorso')
        or char:FindFirstChild('Torso')
        or root
    return char, humanoid, root, head
end

local function sameTeam(plr)
    if plr == LocalPlayer then return true end
    if LocalPlayer.Team and plr.Team then
        return plr.Team == LocalPlayer.Team
    end
    if not LocalPlayer.Neutral and not plr.Neutral then
        return LocalPlayer.TeamColor == plr.TeamColor
    end
    return false
end

local function hasEquippedTool()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:FindFirstChildOfClass('Tool') ~= nil
end

local function isVisibleToCamera(char, part)
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local target = part.Position
    local direction = target - origin
    if direction.Magnitude < .01 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, cam }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin, direction, params)
    return hit == nil or (hit.Instance and hit.Instance:IsDescendantOf(char))
end

-- Radar que desenha pontos para avatares próximos sem acessar o servidor.
local Radar = make('Frame', {
    Name = 'Radar',
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 16),
    Size = UDim2.fromOffset(Config.RadarSize, Config.RadarSize),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = .15,
    BorderSizePixel = 0,
    ZIndex = 11,
    Visible = false,
}, Screen)
corner(Radar, 16)
border(Radar, Theme.Border, 1)
local RadarHeading = label({
    Text = 'RADAR',
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = Theme.Primary,
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.fromOffset(10, 3),
    ZIndex = 12,
}, Radar)
local RadarCircle = make('Frame', {
    BackgroundTransparency = 1,
    Position = UDim2.new(.5, -52, .5, -44),
    Size = UDim2.fromOffset(104, 104),
    ZIndex = 12,
}, Radar)
corner(RadarCircle, 90)
border(RadarCircle, Theme.PrimaryLow, 1)
local RadarDotMe = make('Frame', {
    BackgroundColor3 = Theme.Text,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5),
    Size = UDim2.fromOffset(6, 6),
    ZIndex = 14,
}, RadarCircle)
corner(RadarDotMe, 6)
local RadarDots = {}

local function refreshRadar()
    Radar.Visible = Config.RadarEnabled and not Toolkit.Visible
    if not Radar.Visible then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild('HumanoidRootPart')
    local cam = Workspace.CurrentCamera
    if not myRoot or not cam then return end
    local look = cam.CFrame.LookVector
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < .02 then forward = Vector3.new(0, 0, -1) end
    forward = forward.Unit
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local pixels = 47
    for _, dot in pairs(RadarDots) do dot.Visible = false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char, _, root = characterParts(plr)
            if char and root then
                local delta = root.Position - myRoot.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                if flat.Magnitude <= Config.RadarRange then
                    local dot = RadarDots[plr]
                    if not dot then
                        dot = make('Frame', {
                            Name = 'P_' .. plr.UserId,
                            BackgroundColor3 = Theme.Danger,
                            BorderSizePixel = 0,
                            Size = UDim2.fromOffset(5, 5),
                            AnchorPoint = Vector2.new(.5, .5),
                            ZIndex = 14,
                        }, RadarCircle)
                        corner(dot, 6)
                        RadarDots[plr] = dot
                    end
                    local x = flat:Dot(right) / Config.RadarRange * pixels
                    local y = -flat:Dot(forward) / Config.RadarRange * pixels
                    dot.Position = UDim2.new(.5, x, .5, y)
                    dot.BackgroundColor3 = sameTeam(plr) and Theme.Positive or Theme.Danger
                    dot.Visible = true
                end
            end
        end
    end
end

local TargetCard = make('Frame', {
    Name = 'TargetInfo',
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = .1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(.5, 0),
    Size = UDim2.fromOffset(222, 62),
    Visible = false,
    ZIndex = 11,
}, Overlay)
corner(TargetCard, 10)
border(TargetCard, Theme.PrimaryLow, 1)
local TargetCardTitle = label({
    Text = '',
    TextColor3 = Theme.Primary,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Position = UDim2.fromOffset(10, 5),
    Size = UDim2.new(1, -20, 0, 22),
    ZIndex = 12,
}, TargetCard)
local TargetCardData = label({
    Text = '',
    TextColor3 = Theme.Muted,
    TextSize = 10,
    Position = UDim2.fromOffset(10, 30),
    Size = UDim2.new(1, -20, 0, 21),
    ZIndex = 12,
}, TargetCard)

local function refreshTargetCard()
    local cam = Workspace.CurrentCamera
    local target = Toolkit.Target
    TargetCard.Visible = false
    if not cam or not target or not Config.HUDTargetCard or not Config.Aim then return end
    local char, hum, root = characterParts(target)
    if not char then return end
    local dist = (root.Position - cam.CFrame.Position).Magnitude
    TargetCard.Position = UDim2.fromOffset(cam.ViewportSize.X / 2,
        math.min(cam.ViewportSize.Y - 75, cam.ViewportSize.Y / 2 + 100))
    TargetCardTitle.Text = target.DisplayName .. '  •  ' .. target.Name
    TargetCardData.Text = string.format('HP %d/%d   |   %.0f studs',
        math.floor(hum.Health), math.floor(hum.MaxHealth), dist)
    TargetCard.Visible = true
end

local function screenCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2.new(0, 0) end
    return cam.ViewportSize / 2
end

-- =====================================================
-- PHANTOM • Target acquisition and persistent tracking
-- FOV is used to acquire a target only in FOV mode.
-- Tracking NEVER relies on an unobstructed wall raycast
-- when AimTrackThroughWalls is enabled.
-- =====================================================
local function getAimPart(plr)
    local char, hum, root, head = characterParts(plr)
    if not char then return end
    local targetPart = Config.AimPart == 'Head' and head or root
    if Config.AimPart == 'Chest' then
        targetPart = char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso') or root
    end
    if Config.AimClosestBody then
        local cam = Workspace.CurrentCamera
        if cam then
            local bestDist = math.huge
            for _, bp in ipairs(char:GetChildren()) do
                if bp:IsA('BasePart') and bp.Transparency < 1 then
                    local vp = cam:WorldToViewportPoint(bp.Position)
                    if vp.Z > 0 then
                        local diff = (Vector2.new(vp.X, vp.Y) - cam.ViewportSize / 2).Magnitude
                        if diff < bestDist then
                            bestDist = diff
                            targetPart = bp
                        end
                    end
                end
            end
        end
    end
    return targetPart, char, hum, root
end

local function validLock(plr, acquiring, manual)
    if not plr or plr == LocalPlayer or plr.Parent ~= Players then return end
    local part, char, hum, root = getAimPart(plr)
    if not part then return end
    if Config.AimTeamCheck and sameTeam(plr) and not manual then return end
    if Config.AimRequireHealthy and hum.Health < Config.AimMinHealth then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local dist = (part.Position - cam.CFrame.Position).Magnitude
    if not Config.AimInfiniteRange and dist > Config.AimDistance then return end
    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
    if not acquiring then
        if not Config.AimTrackOffscreen and (screen.Z <= 0 or not onScreen) then return end
        if not Config.AimTrackThroughWalls and not isVisibleToCamera(char, part) then return end
    else
        if not Config.AimAcquireGlobal then
            if not onScreen or screen.Z <= 0 then return end
            local center = cam.ViewportSize / 2
            if (Vector2.new(screen.X, screen.Y) - center).Magnitude > Config.AimFOV then return end
        end
        if Config.AimVisibility and not isVisibleToCamera(char, part) then return end
    end
    local pixDist = (Vector2.new(screen.X, screen.Y) - cam.ViewportSize / 2).Magnitude
    local score = pixDist
    if Config.AimPriority == 'Distance' then
        score = dist
    elseif Config.AimPriority == 'LowHealth' then
        score = hum.Health
    elseif Config.AimPriority == 'Threat' then
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild('HumanoidRootPart')
        local delta = myRoot and (myRoot.Position - root.Position) or Vector3.zero
        local velocity = root.AssemblyLinearVelocity
        local approach = 0
        if delta.Magnitude > 1 and velocity.Magnitude > 1 then
            approach = velocity.Unit:Dot(delta.Unit)
        end
        score = dist * .20 - math.max(0, approach) * 180
    end
    return part, pixDist, dist, score
end

local function findBestTarget(ignorePlayer)
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr ~= ignorePlayer then
            local part, _, _, score = validLock(plr, true, false)
            if part and score < bestScore then
                best, bestScore = plr, score
            end
        end
    end
    return best
end

local function selectTarget(newPlayer, reason)
    if newPlayer == Toolkit.Target then return end
    local old = Toolkit.Target
    Toolkit.Target = newPlayer
    Toolkit.AimState.LockedSince = os.clock()
    Toolkit.AimState.LastSelection = os.clock()
    if newPlayer then
        Toolkit.AimState.LastTarget = newPlayer
        Toolkit.Statistics.Locks = Toolkit.Statistics.Locks + 1
        if old and old ~= newPlayer then
            Toolkit.Statistics.Switches = Toolkit.Statistics.Switches + 1
        end
        Toolkit.AimState.ManualPlayer = (reason == 'manual') and newPlayer or nil
        if Config.AimAlertOnSwitch and Config.TargetNotifications and
            (old or reason == 'manual') then
            toast('LOCK  //  ' .. newPlayer.DisplayName)
        end
    end
end

local function cycleTarget(direction)
    local available = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and validLock(plr, true, false) then
            table.insert(available, plr)
        end
    end
    table.sort(available, function(a, b)
        return a.UserId < b.UserId
    end)
    if #available == 0 then
        selectTarget(nil)
        toast('Nenhum alvo replicado no cliente')
        return
    end
    local at = table.find(available, Toolkit.Target) or 0
    at = (at - 1 + direction + #available) % #available + 1
    selectTarget(available[at], 'manual')
    Config.HUDSpectate = false
    Config.Aim = true
end

local function targetByName(fragment)
    local query = string.lower((fragment or ''):gsub('^%s+', ''):gsub('%s+$', ''))
    if #query < 2 then
        toast('Digite ao menos 2 caracteres')
        return nil
    end
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local n = string.lower(p.Name)
            local d = string.lower(p.DisplayName)
            local fromName = string.find(n, query, 1, true)
            local fromDisplay = string.find(d, query, 1, true)
            if fromName or fromDisplay then
                local score = fromName or (fromDisplay + 10)
                if not best or score < bestScore then best, bestScore = p, score end
            end
        end
    end
    if best then
        Config.HUDSpectate = false
        Config.Aim = true
        selectTarget(best, 'manual')
        toast('Selecionado: ' .. best.Name)
    else
        toast('Jogador não encontrado')
    end
    return best
end

local function acquireTarget(avoided)
    local candidate = findBestTarget(avoided)
    if not candidate and avoided then candidate = findBestTarget() end
    selectTarget(candidate, 'auto')
    return candidate
end

-- Optional low-cost height correction for falling/jumping avatars.
local function estimateAimLead(part, distance)
    local base = Config.AimLeadTime / 100
    if not Config.AimSmartLead then return base end
    local speed = math.max(35, math.min(1000, distance / .65))
    local adjusted = (distance / speed) * .15
    return math.clamp(base + adjusted, 0, .65)
end

local function predictTarget(part, distance)
    local t = estimateAimLead(part, distance)
    local vel = part.AssemblyLinearVelocity
    local predicted = part.Position + vel * t
    if Config.AimAirPrediction and math.abs(vel.Y) > 6 then
        predicted = predicted + Vector3.new(0, -Workspace.Gravity * t * t * .35, 0)
    end
    local up = Config.AimVerticalLead / 100
    return predicted + Vector3.new(0, up * distance / 100, 0)
end

local function updateAim(dt)
    if not Config.Aim then
        if Toolkit.Target and not Config.HUDSpectate then selectTarget(nil) end
        return
    end
    if Config.AimRequiresTool and not hasEquippedTool() then return end
    if Config.AimDisableWhileMenu and Toolkit.Visible then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local target = Toolkit.Target
    local part = target and validLock(target, false, target == Toolkit.AimState.ManualPlayer)
    if part and not Config.AimSticky then
        -- Dynamic mode periodically replaces a locked target by priority.
        if os.clock() - Toolkit.AimState.LastSelection > .35 then
            local candidate = findBestTarget()
            if candidate and candidate ~= target then
                selectTarget(candidate, 'auto')
                target = candidate
                part = validLock(target, false, false)
            else
                Toolkit.AimState.LastSelection = os.clock()
            end
        end
    end
    if not part then
        if target and not Config.AimAutoSwitch then return end
        local now = os.clock()
        if now - Toolkit.AimState.LastSelection >= Config.AimRetargetDelay / 100 then
            target = acquireTarget(target)
            part = target and validLock(target, false, false)
        else
            return
        end
    end
    if not part then return end
    local distance = (part.Position - cam.CFrame.Position).Magnitude
    local predicted = predictTarget(part, distance)
    if (predicted - cam.CFrame.Position).Magnitude < .01 then return end
    local desired = CFrame.lookAt(cam.CFrame.Position, predicted)
    local mode = Config.AimSmoothingMode
    if Config.AimInstant or mode == 'Direct' then
        cam.CFrame = desired
    else
        local rate = math.max(.01, Config.AimSmooth / 100)
        local alpha = 1 - math.exp(-dt * (mode == 'Adaptive' and (30 * rate) or (15 * rate)))
        cam.CFrame = cam.CFrame:Lerp(desired, math.clamp(alpha, .005, 1))
    end
end

local function getCombatTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass('Tool')
end

local function equipAnyTool()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass('Humanoid')
    if not hum then return end
    if getCombatTool() then return end
    local backpack = LocalPlayer:FindFirstChildOfClass('Backpack')
    local tool = backpack and backpack:FindFirstChildOfClass('Tool')
    if tool then
        pcall(function() hum:EquipTool(tool) end)
    end
end

local function autoFireStep()
    if not Config.AimAutoFire or not Config.Aim then return end
    if Toolkit.Visible then return end
    local target = Toolkit.Target
    if not target then return end
    local part, char, _, root = getAimPart(target)
    if not part or not root then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local dist = (part.Position - cam.CFrame.Position).Magnitude
    if dist > Config.AimFireMaxDistance then return end
    if Config.AimFireCondition == 'Visible' and not isVisibleToCamera(char, part) then return end
    if Config.AimFireCondition == 'Crosshair' then
        local projected, on = cam:WorldToViewportPoint(part.Position)
        if not on or projected.Z <= 0 then return end
        if (Vector2.new(projected.X, projected.Y) - cam.ViewportSize / 2).Magnitude > 28 then
            return
        end
    end
    if Config.AimAutoEquip then equipAnyTool() end
    local tool = getCombatTool()
    if not tool then return end
    local enabled = true
    local enabledOk, enabledState = pcall(function() return tool.Enabled end)
    if enabledOk then enabled = enabledState end
    if not enabled then return end
    local interval = 1 / math.max(1, Config.AimFireRate)
    if os.clock() - Toolkit.AimState.LastShot < interval then return end
    Toolkit.AimState.LastShot = os.clock()
    local ok = pcall(function() tool:Activate() end)
    if ok then Toolkit.Statistics.ToolShots = Toolkit.Statistics.ToolShots + 1 end
end

-- HUD de jogadores em 2D e Highlight 3D.
local function lineFrame(parent, thickness)
    local frame = make('Frame', {
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(0, thickness or 1),
        Visible = false,
        ZIndex = 5,
    }, parent)
    return frame
end

local function setLine(frame, a, b, color, thickness)
    local offset = b - a
    local length = offset.Magnitude
    if length < 1 or length > 10000 then
        frame.Visible = false
        return
    end
    frame.Visible = true
    frame.BackgroundColor3 = color
    frame.Size = UDim2.fromOffset(length, thickness or 1)
    frame.Position = UDim2.fromOffset((a.X + b.X - length) / 2, (a.Y + b.Y - (thickness or 1)) / 2)
    -- Rotacionar em torno do centro do segmento, não de sua ponta.
    frame.AnchorPoint = Vector2.new(0, 0)
    frame.Rotation = math.deg(math.atan2(offset.Y, offset.X))
    -- A posição acima era calculada para largura sem rotação; corrigir para o centro.
    frame.AnchorPoint = Vector2.new(.5, .5)
    frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
end

local SkeletonR15 = {
    { 'Head', 'UpperTorso' },
    { 'UpperTorso', 'LowerTorso' },
    { 'UpperTorso', 'LeftUpperArm' },
    { 'LeftUpperArm', 'LeftLowerArm' },
    { 'LeftLowerArm', 'LeftHand' },
    { 'UpperTorso', 'RightUpperArm' },
    { 'RightUpperArm', 'RightLowerArm' },
    { 'RightLowerArm', 'RightHand' },
    { 'LowerTorso', 'LeftUpperLeg' },
    { 'LeftUpperLeg', 'LeftLowerLeg' },
    { 'LeftLowerLeg', 'LeftFoot' },
    { 'LowerTorso', 'RightUpperLeg' },
    { 'RightUpperLeg', 'RightLowerLeg' },
    { 'RightLowerLeg', 'RightFoot' },
}
local SkeletonR6 = {
    { 'Head', 'Torso' },
    { 'Torso', 'Left Arm' },
    { 'Torso', 'Right Arm' },
    { 'Torso', 'Left Leg' },
    { 'Torso', 'Right Leg' },
}

local function createESP(plr)
    if Toolkit.ESP[plr] then return Toolkit.ESP[plr] end
    local holder = make('Frame', {
        Name = 'ESP_' .. tostring(plr.UserId),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 4,
    }, Overlay)
    local box = make('Frame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(70, 100),
        ZIndex = 5,
    }, holder)
    border(box, Theme.Primary, 1.5)
    local top = label({
        Text = '',
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = .3,
        Size = UDim2.fromOffset(160, 20),
        ZIndex = 6,
    }, holder)
    local bottom = label({
        Text = '',
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = .35,
        Size = UDim2.fromOffset(120, 18),
        ZIndex = 6,
    }, holder)
    local healthBackground = make('Frame', {
        BackgroundColor3 = Theme.Danger,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, holder)
    local healthFill = make('Frame', {
        BackgroundColor3 = Theme.Positive,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        ZIndex = 6,
    }, healthBackground)
    local tracer = lineFrame(holder, 1.2)
    local weaponText = label({
        Text = '',
        TextSize = 10,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = .3,
        Size = UDim2.fromOffset(170, 20),
        ZIndex = 6,
    }, holder)
    local headDot = make('Frame', {
        BackgroundColor3 = Theme.Primary,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(7, 7),
        Visible = false,
        ZIndex = 8,
    }, holder)
    corner(headDot, 8)
    local offscreen = label({
        Text = '▲',
        Font = Enum.Font.GothamBlack,
        TextSize = 20,
        TextColor3 = Theme.Danger,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(26, 26),
        Visible = false,
        ZIndex = 8,
    }, holder)
    local skeleton = {}
    for index = 1, #SkeletonR15 do
        skeleton[index] = lineFrame(holder, 1)
    end
    local highlight = nil
    local data = {
        Player = plr,
        Root = holder,
        Box = box,
        Top = top,
        Bottom = bottom,
        HPBar = healthBackground,
        HPFill = healthFill,
        Tracer = tracer,
        Weapon = weaponText,
        HeadDot = headDot,
        Offscreen = offscreen,
        Skeleton = skeleton,
        Highlight = highlight,
    }
    Toolkit.ESP[plr] = data
    return data
end

local function destroyESP(plr)
    local data = Toolkit.ESP[plr]
    if not data then return end
    if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
    pcall(function() data.Root:Destroy() end)
    Toolkit.ESP[plr] = nil
end

local function ensureHighlight(data, char)
    if not Config.ESPHighlight then
        if data.Highlight then data.Highlight:Destroy(); data.Highlight = nil end
        return
    end
    if not data.Highlight or data.Highlight.Parent ~= char then
        if data.Highlight then data.Highlight:Destroy() end
        data.Highlight = make('Highlight', {
            Name = 'NexusLocalESP',
            Adornee = char,
            FillTransparency = .78,
            OutlineTransparency = .03,
            FillColor = Theme.Primary,
            OutlineColor = Theme.Primary,
        }, char)
    end
    data.Highlight.DepthMode = Config.ESPThroughWalls and
        Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end

local function hideESP(data)
    data.Root.Visible = false
    if data.Highlight then data.Highlight.Enabled = false end
end

local function updateSkeleton(data, char, cam, color)
    if not Config.ESPSkeleton then
        for _, line in ipairs(data.Skeleton) do line.Visible = false end
        return
    end
    local segments = char:FindFirstChild('UpperTorso') and SkeletonR15 or SkeletonR6
    for i, line in ipairs(data.Skeleton) do
        local names = segments[i]
        if not names then
            line.Visible = false
        else
            local first = char:FindFirstChild(names[1])
            local second = char:FindFirstChild(names[2])
            if first and second then
                local ap = cam:WorldToViewportPoint(first.Position)
                local bp = cam:WorldToViewportPoint(second.Position)
                if ap.Z > 0 and bp.Z > 0 then
                    setLine(line, Vector2.new(ap.X, ap.Y), Vector2.new(bp.X, bp.Y), color, 1.2)
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end
end

local function updateOffscreen(data, cam, root, color)
    data.Offscreen.Visible = false
    if not Config.ESPOffscreen then return end
    local world = root.Position
    local point, on = cam:WorldToViewportPoint(world)
    if on and point.Z > 0 then return end
    local center = screenCenter()
    local dx = point.X - center.X
    local dy = point.Y - center.Y
    if point.Z < 0 then dx, dy = -dx, -dy end
    local direction = Vector2.new(dx, dy)
    if direction.Magnitude < .1 then direction = Vector2.new(0, -1) end
    direction = direction.Unit
    local margin = 39
    local half = Vector2.new(math.max(20, center.X - margin), math.max(20, center.Y - margin))
    local factor = math.min(half.X / math.max(.01, math.abs(direction.X)),
        half.Y / math.max(.01, math.abs(direction.Y)))
    local pos = center + direction * factor
    data.Offscreen.Position = UDim2.fromOffset(pos.X - 13, pos.Y - 13)
    data.Offscreen.Rotation = math.deg(math.atan2(direction.Y, direction.X)) + 90
    data.Offscreen.TextColor3 = color
    data.Offscreen.Visible = true
end

local function updateESP()
    local cam = Workspace.CurrentCamera
    if not cam or not Config.ESPEnabled then
        for plr, data in pairs(Toolkit.ESP) do
            hideESP(data)
        end
        Toolkit.Statistics.Players = 0
        return
    end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild('HumanoidRootPart')
    local total = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local data = createESP(plr)
            local char, hum, root, head = characterParts(plr)
            local valid = char ~= nil and root ~= nil
            local offscreenOnly = false
            if valid and Config.ESPTeamCheck and sameTeam(plr) then valid = false end
            local distance = (myRoot and root) and (root.Position - myRoot.Position).Magnitude or math.huge
            if valid and not Config.ESPUnlimitedRange and distance > Config.ESPRange then valid = false end
            if valid then
                -- Highlights are handled independently of 2D screen projection.
                ensureHighlight(data, char)
                if data.Highlight then data.Highlight.Enabled = true end
                local screenTop, topOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1.25, 0))
                local screenBot, botOn = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                valid = screenTop.Z > 0 and screenBot.Z > 0 and (topOn or botOn)
                local color = (Toolkit.Target == plr and Config.Aim) and Theme.Danger or Theme.Primary
                if not valid then
                    offscreenOnly = Config.ESPOffscreen or Config.ESPTracersOffscreen
                    total = total + 1
                    data.Root.Visible = offscreenOnly
                    data.Box.Visible = false
                    data.Top.Visible = false
                    data.Bottom.Visible = false
                    data.HPBar.Visible = false
                    data.Tracer.Visible = false
                    data.Weapon.Visible = false
                    data.HeadDot.Visible = false
                    for _, segment in ipairs(data.Skeleton) do segment.Visible = false end
                    updateOffscreen(data, cam, root, color)
                    if Config.ESPLine and Config.ESPTracersOffscreen then
                        local tp = cam:WorldToViewportPoint(root.Position)
                        local c = cam.ViewportSize / 2
                        local dir = Vector2.new(tp.X - c.X, tp.Y - c.Y)
                        if tp.Z < 0 then dir = -dir end
                        if dir.Magnitude < .001 then dir = Vector2.new(0, -1) end
                        dir = dir.Unit
                        local half = cam.ViewportSize / 2 - Vector2.new(15, 15)
                        local d = math.min(half.X / math.max(.001, math.abs(dir.X)),
                            half.Y / math.max(.001, math.abs(dir.Y)))
                        local edge = c + dir * d
                        local origin = Vector2.new(c.X, cam.ViewportSize.Y - 8)
                        if Config.ESPTraceOrigin == 'Center' then origin = c end
                        if Config.ESPTraceOrigin == 'Top' then origin = Vector2.new(c.X, 8) end
                        setLine(data.Tracer, origin, edge, color, Config.ESPTracerThickness)
                    end
                else
                    local height = math.clamp(math.abs(screenBot.Y - screenTop.Y), 12, 1900)
                    local width = math.clamp(height * .52, 7, 980)
                    local x = (screenTop.X + screenBot.X) / 2
                    local y = (screenTop.Y + screenBot.Y) / 2
                    data.Offscreen.Visible = false
                    data.Root.Visible = true
                    data.Box.Visible = Config.ESPBox
                    data.Box.Position = UDim2.fromOffset(x - width / 2, y - height / 2)
                    data.Box.Size = UDim2.fromOffset(width, height)
                    local stroke = data.Box:FindFirstChildOfClass('UIStroke')
                    if stroke then stroke.Color = color end
                    data.Top.Visible = Config.ESPName
                    data.Top.Text = plr.DisplayName
                    data.Top.TextColor3 = color
                    data.Top.Position = UDim2.fromOffset(x - 80, y - height / 2 - 22)
                    data.Bottom.Visible = Config.ESPDistance
                    data.Bottom.Text = string.format('%d studs', math.floor(distance))
                    data.Bottom.Position = UDim2.fromOffset(x - 60, y + height / 2 + 3)
                    data.HPBar.Visible = Config.ESPHealth
                    data.HPBar.Position = UDim2.fromOffset(x - width / 2 - 8, y - height / 2)
                    data.HPBar.Size = UDim2.fromOffset(4, height)
                    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    data.HPFill.Size = UDim2.new(1, 0, ratio, 0)
                    data.HeadDot.Visible = Config.ESPHeadDot
                    data.HeadDot.Position = UDim2.fromOffset(screenTop.X - 3.5,
                        screenTop.Y + math.max(5, height * .12))
                    data.HeadDot.BackgroundColor3 = color
                    data.Weapon.Visible = Config.ESPShowWeapon
                    if Config.ESPShowWeapon then
                        local tool = char:FindFirstChildOfClass('Tool')
                        data.Weapon.Text = tool and tool.Name or 'Sem Tool equipada'
                        data.Weapon.Position = UDim2.fromOffset(x - 85, y + height / 2 + 20)
                    end
                    updateSkeleton(data, char, cam, color)
                    if Config.ESPLine then
                        local start = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y - 8)
                        if Config.ESPTraceOrigin == 'Center' then
                            start = cam.ViewportSize / 2
                        elseif Config.ESPTraceOrigin == 'Top' then
                            start = Vector2.new(cam.ViewportSize.X / 2, 8)
                        end
                        setLine(data.Tracer, start, Vector2.new(x, y + height / 2), color,
                            Config.ESPTracerThickness)
                    else
                        data.Tracer.Visible = false
                    end
                    total = total + 1
                end
            end
            if not valid then
                if not offscreenOnly then
                    if data.Highlight and (not char or distance > Config.ESPRange and not Config.ESPUnlimitedRange or
                        Config.ESPTeamCheck and sameTeam(plr)) then
                        data.Highlight.Enabled = false
                    end
                    data.Root.Visible = false
                end
            end
        end
    end
    Toolkit.Statistics.Players = total
end

-- =====================================================
-- Target lock independent 2D overlay
-- Works with ESP disabled, including offscreen edge guide.
-- =====================================================
local LockIndicator = make('Frame', {
    Name = 'TrackingRing',
    Size = UDim2.fromOffset(50, 50),
    AnchorPoint = Vector2.new(.5, .5),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 18,
}, Overlay)
corner(LockIndicator, 100)
local LockStroke = border(LockIndicator, Theme.Danger, 2, 0)
local LockGrad = make('UIGradient', {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Danger),
        ColorSequenceKeypoint.new(.5, Theme.Gold),
        ColorSequenceKeypoint.new(1, Theme.Danger)
    }),
}, LockStroke)
local TargetDot = make('Frame', {
    BackgroundColor3 = Theme.Danger,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5),
    Size = UDim2.fromOffset(4, 4),
    ZIndex = 19,
}, LockIndicator)
corner(TargetDot, 4)
local LockLabel = label({
    Text = 'LOCKED',
    TextColor3 = Theme.Danger,
    Font = Enum.Font.GothamBlack,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextStrokeTransparency = .2,
    Size = UDim2.fromOffset(160, 21),
    Visible = false,
    ZIndex = 18,
}, Overlay)
local LockGuide = lineFrame(Overlay, 2)
LockGuide.ZIndex = 17
local LockArrow = label({
    Text = '◆',
    Font = Enum.Font.GothamBlack,
    TextSize = 23,
    TextColor3 = Theme.Danger,
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.fromOffset(32, 32),
    Visible = false,
    ZIndex = 18,
}, Overlay)
local EnemyDetected = label({
    Text = '',
    TextColor3 = Theme.Gold,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AnchorPoint = Vector2.new(.5, .5),
    TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.fromOffset(250, 22),
    Visible = false,
    ZIndex = 16,
}, Overlay)
local LeadMarker = make('Frame', {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(.5, .5),
    Size = UDim2.fromOffset(20, 20),
    Visible = false,
    ZIndex = 20,
}, Overlay)
local LeadStroke = border(LeadMarker, Theme.Gold, 1.5)
corner(LeadMarker, 100)
local WarningBanner = label({
    Text = '',
    TextColor3 = Theme.Danger,
    TextSize = 12,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Center,
    AnchorPoint = Vector2.new(.5, 0),
    Size = UDim2.fromOffset(290, 25),
    Visible = false,
    ZIndex = 19,
}, Overlay)
local SpectateTracker = {
    Active = false,
    LastSubject = nil,
    LastTarget = nil,
}
local function stopSpectate()
    local cam = Workspace.CurrentCamera
    if cam and SpectateTracker.Active then
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass('Humanoid')
        cam.CameraSubject = myHum or SpectateTracker.LastSubject or cam.CameraSubject
    end
    SpectateTracker.Active = false
    SpectateTracker.LastTarget = nil
end
local function updateSpectate()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if not Config.HUDSpectate or not Toolkit.Target or Config.Aim then
        if SpectateTracker.Active then stopSpectate() end
        return
    end
    local char, hum = characterParts(Toolkit.Target)
    if not char then return end
    if not SpectateTracker.Active then
        SpectateTracker.LastSubject = cam.CameraSubject
        SpectateTracker.Active = true
    end
    if cam.CameraSubject ~= hum then cam.CameraSubject = hum end
    SpectateTracker.LastTarget = Toolkit.Target
end
local function updateWarningBanner()
    local cam = Workspace.CurrentCamera
    WarningBanner.Visible = false
    if not Config.HUDWarnings or not cam then return end
    local myChar = LocalPlayer.Character
    local hum = myChar and myChar:FindFirstChildOfClass('Humanoid')
    if hum and hum.Health > 0 and hum.Health / math.max(1, hum.MaxHealth) < .3 then
        WarningBanner.Text = '⚠  HP BAIXO • RETIRADA RECOMENDADA'
        WarningBanner.Position = UDim2.fromOffset(cam.ViewportSize.X / 2, 65)
        WarningBanner.Visible = true
    end
end

local function updateLockIndicator()
    LockIndicator.Visible = false
    LockLabel.Visible = false
    LockGuide.Visible = false
    LockArrow.Visible = false
    EnemyDetected.Visible = false
    LeadMarker.Visible = false
    if not Config.Aim or not Toolkit.Target then return end
    local part, char, hum = getAimPart(Toolkit.Target)
    local cam = Workspace.CurrentCamera
    if not part or not cam then return end
    local vp, onscreen = cam:WorldToViewportPoint(part.Position)
    local center = cam.ViewportSize / 2
    local visible = isVisibleToCamera(char, part)
    if Config.HUDShowVisibility then
        EnemyDetected.Visible = true
        EnemyDetected.Position = UDim2.fromOffset(center.X, math.max(38, center.Y - 80))
        EnemyDetected.Text = visible and '●  ALVO VISÍVEL' or '◆  ALVO ATRÁS DE COBERTURA'
    end
    if Config.HUDPredictionMarker then
        local forecast = predictTarget(part, (part.Position - cam.CFrame.Position).Magnitude)
        local ahead, onAhead = cam:WorldToViewportPoint(forecast)
        if ahead.Z > 0 and onAhead then
            LeadMarker.Position = UDim2.fromOffset(ahead.X, ahead.Y)
            LeadMarker.Visible = true
        end
    end
    if vp.Z > 0 and onscreen then
        LockIndicator.Visible = Config.HUDLockRing
        LockIndicator.Position = UDim2.fromOffset(vp.X, vp.Y)
        LockLabel.Visible = Config.HUDLockRing
        LockLabel.Position = UDim2.fromOffset(vp.X - 80, vp.Y - 42)
        LockLabel.Text = string.format('LOCK  %s  |  %d HP',
            Toolkit.Target.DisplayName:sub(1, 11), math.floor(hum.Health))
        if Config.ESPLockIndicator then
            setLine(LockGuide, center, Vector2.new(vp.X, vp.Y), Theme.Danger, 1.5)
        end
    elseif Config.HUDOffscreenLockArrow then
        local dir = Vector2.new(vp.X - center.X, vp.Y - center.Y)
        if vp.Z < 0 then dir = -dir end
        if dir.Magnitude < .01 then dir = Vector2.new(0, -1) end
        dir = dir.Unit
        local half = center - Vector2.new(44, 44)
        local factor = math.min(half.X / math.max(.01, math.abs(dir.X)),
            half.Y / math.max(.01, math.abs(dir.Y)))
        local at = center + dir * factor
        LockArrow.Position = UDim2.fromOffset(at.X - 16, at.Y - 16)
        LockArrow.Rotation = math.deg(math.atan2(dir.Y, dir.X)) + 90
        LockArrow.Visible = true
        setLine(LockGuide, center, at, Theme.Danger, 1.5)
    end
end

-- =======================================================
-- NPC / BOT VISION: Optional highlight + overlay lines.
-- Works with ordinary Humanoid NPC models replicated in
-- Workspace. Deliberately scans at a low frequency on mobile.
-- =======================================================
local NPCQueue = {}
local NPCScanAt = 0
local function removeNPCMarker(npc)
    local rec = Toolkit.NPCESP[npc]
    if not rec then return end
    if rec.Holder then pcall(function() rec.Holder:Destroy() end) end
    if rec.Highlight then pcall(function() rec.Highlight:Destroy() end) end
    Toolkit.NPCESP[npc] = nil
end

local function resetNPCMarkers()
    for npc in pairs(Toolkit.NPCESP) do
        removeNPCMarker(npc)
    end
    table.clear(NPCQueue)
    NPCScanAt = 0
end

local function npcParts(npc)
    if not npc or not npc.Parent or not npc:IsA('Model') then return end
    local hum = npc:FindFirstChildOfClass('Humanoid')
    if not hum or hum.Health <= 0 then return end
    local root = npc:FindFirstChild('HumanoidRootPart')
        or npc:FindFirstChild('UpperTorso')
        or npc:FindFirstChild('Torso')
        or npc.PrimaryPart
    if not root or not root:IsA('BasePart') then return end
    local head = npc:FindFirstChild('Head') or root
    return hum, root, head
end

local function scanNPCs()
    local now = os.clock()
    if now - NPCScanAt < Config.ESPNPCScanInterval then return end
    NPCScanAt = now
    table.clear(NPCQueue)
    local count = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA('Model') and not Players:GetPlayerFromCharacter(inst) then
            local hum = inst:FindFirstChildOfClass('Humanoid')
            if hum and hum.Health > 0 then
                local _, root = npcParts(inst)
                if root then
                    count = count + 1
                    NPCQueue[#NPCQueue + 1] = inst
                    if count >= Config.ESPNPCMax then break end
                end
            end
        end
    end
end

local function getNPCMarker(npc)
    local rec = Toolkit.NPCESP[npc]
    if rec then return rec end
    local holder = make('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Name = 'NPC_' .. tostring(#NPCQueue),
        Visible = false,
        ZIndex = 9,
    }, Overlay)
    local dot = make('Frame', {
        BackgroundColor3 = Theme.Gold,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(9, 9),
        AnchorPoint = Vector2.new(.5, .5),
        ZIndex = 9,
    }, holder)
    corner(dot, 9)
    local info = label({
        Text = npc.Name,
        TextColor3 = Theme.Gold,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = .3,
        Size = UDim2.fromOffset(150, 20),
        ZIndex = 10,
    }, holder)
    local tracer = lineFrame(holder, 1.5)
    rec = { Holder = holder, Info = info, Tracer = tracer, Dot = dot, Highlight = nil }
    Toolkit.NPCESP[npc] = rec
    return rec
end

local function ensureNPCHighlight(npc, rec)
    if not Config.ESPHighlight then
        if rec.Highlight then
            rec.Highlight:Destroy()
            rec.Highlight = nil
        end
        return
    end
    if not rec.Highlight or rec.Highlight.Parent ~= npc then
        if rec.Highlight then rec.Highlight:Destroy() end
        rec.Highlight = make('Highlight', {
            Adornee = npc,
            FillColor = Theme.Gold,
            OutlineColor = Theme.Gold,
            FillTransparency = .85,
            OutlineTransparency = .05,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            Name = 'PhantomNPC',
        }, npc)
    end
    rec.Highlight.Enabled = true
end

local function updateNPCESP()
    if not Config.ESPIncludeNPC or not Config.ESPEnabled then
        for npc, rec in pairs(Toolkit.NPCESP) do
            if rec.Holder then rec.Holder.Visible = false end
            if rec.Highlight then rec.Highlight.Enabled = false end
        end
        return
    end
    scanNPCs()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local cameraPos = cam.CFrame.Position
    local keep = {}
    for _, npc in ipairs(NPCQueue) do
        local hum, root, head = npcParts(npc)
        if hum and root and (root.Position - cameraPos).Magnitude < Config.ESPNPCRange then
            keep[npc] = true
            local rec = getNPCMarker(npc)
            ensureNPCHighlight(npc, rec)
            local screen, onScreen = cam:WorldToViewportPoint(head.Position)
            if screen.Z > 0 and onScreen then
                local pixel = Vector2.new(screen.X, screen.Y)
                local center = cam.ViewportSize / 2
                rec.Holder.Visible = true
                rec.Dot.Position = UDim2.fromOffset(pixel.X, pixel.Y)
                rec.Info.Text = string.format('[BOT] %s  |  %d HP', npc.Name:sub(1, 12),
                    math.floor(hum.Health))
                rec.Info.Position = UDim2.fromOffset(pixel.X - 75, pixel.Y - 37)
                if Config.ESPLine then
                    local origin = Vector2.new(center.X, cam.ViewportSize.Y - 8)
                    if Config.ESPTraceOrigin == 'Center' then origin = center end
                    if Config.ESPTraceOrigin == 'Top' then origin = Vector2.new(center.X, 8) end
                    setLine(rec.Tracer, origin, pixel, Theme.Gold, Config.ESPTracerThickness)
                else
                    rec.Tracer.Visible = false
                end
            else
                rec.Holder.Visible = false
            end
        end
    end
    for npc, rec in pairs(Toolkit.NPCESP) do
        if not keep[npc] then
            if rec.Holder then rec.Holder.Visible = false end
            if rec.Highlight then rec.Highlight.Enabled = false end
            if not npc.Parent then removeNPCMarker(npc) end
        end
    end
end

-- Voo local. LinearVelocity é a classe moderna da Roblox para controlar velocidade.
local MoveKeys = {
    W = 'forward', Up = 'forward',
    S = 'back', Down = 'back',
    A = 'left', Left = 'left',
    D = 'right', Right = 'right',
    E = 'rise', Space = 'rise',
    Q = 'fall', LeftControl = 'fall',
}

local function stopFlight()
    Config.FlightEnabled = false
    for key in pairs(Toolkit.Holding) do Toolkit.Holding[key] = false end
    local state = Toolkit.Flight
    if state.Linear then pcall(function() state.Linear:Destroy() end) end
    if state.Orient then pcall(function() state.Orient:Destroy() end) end
    if state.Attach then pcall(function() state.Attach:Destroy() end) end
    if state.Humanoid then
        pcall(function() state.Humanoid.AutoRotate = true end)
    end
    Toolkit.Flight = {}
end

local function startFlight()
    if not Config.FlightEnabled then return false end
    local char, hum, root = characterParts(LocalPlayer)
    if not char or not root then
        Config.FlightEnabled = false
        toast('Personagem indisponível para voo')
        return false
    end
    if Toolkit.Flight.Root == root and Toolkit.Flight.Linear then return true end
    stopFlight()
    Config.FlightEnabled = true
    local attachment = make('Attachment', { Name = 'NexusFlyAttachment' }, root)
    local linear = make('LinearVelocity', {
        Name = 'NexusFlyVelocity',
        Attachment0 = attachment,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
        ForceLimitsEnabled = false,
        VectorVelocity = Vector3.zero,
    }, root)
    local orientation = make('AlignOrientation', {
        Name = 'NexusFlyFacing',
        Attachment0 = attachment,
        Mode = Enum.OrientationAlignmentMode.OneAttachment,
        MaxTorque = 1e9,
        Responsiveness = 30,
        RigidityEnabled = false,
    }, root)
    hum.AutoRotate = false
    Toolkit.Flight = {
        Attachment = attachment,
        Attach = attachment,
        Linear = linear,
        Orient = orientation,
        Root = root,
        Humanoid = hum,
    }
    toast('Voo local ativado')
    return true
end

local function updateFlight()
    if not Config.FlightEnabled then return end
    local state = Toolkit.Flight
    if not state.Root or not state.Root.Parent or not state.Linear then
        startFlight()
        state = Toolkit.Flight
    end
    if not state.Root or not state.Linear then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local look = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    local forward = Vector3.new(look.X, 0, look.Z)
    local sideways = Vector3.new(right.X, 0, right.Z)
    if forward.Magnitude > .01 then forward = forward.Unit end
    if sideways.Magnitude > .01 then sideways = sideways.Unit end
    local horizontal = Vector3.zero
    if Toolkit.Holding.forward then horizontal = horizontal + forward end
    if Toolkit.Holding.back then horizontal = horizontal - forward end
    if Toolkit.Holding.right then horizontal = horizontal + sideways end
    if Toolkit.Holding.left then horizontal = horizontal - sideways end
    if horizontal.Magnitude > 1 then horizontal = horizontal.Unit end
    local vertical = 0
    if Toolkit.Holding.rise then vertical = vertical + 1 end
    if Toolkit.Holding.fall then vertical = vertical - 1 end
    local velocity = horizontal * Config.FlightSpeed +
        Vector3.new(0, vertical * Config.FlightVerticalSpeed, 0)
    state.Linear.VectorVelocity = velocity
    if state.Orient then
        state.Orient.Enabled = Config.FlightFacing
        if forward.Magnitude > .01 then
            state.Orient.CFrame = CFrame.lookAt(Vector3.zero, forward)
        end
    end
end

connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    local move = MoveKeys[input.KeyCode.Name]
    if move then Toolkit.Holding[move] = true end
    if input.KeyCode == Enum.KeyCode.RightShift then
        togglePanel()
    end
    if input.KeyCode == Enum.KeyCode.T then
        Config.Aim = not Config.Aim
        if not Config.Aim then Toolkit.Target = nil end
        saveSettings()
        toast(Config.Aim and 'Trava ligada (T)' or 'Trava desligada (T)')
    end
    if input.KeyCode == Enum.KeyCode.Y then
        cycleTarget(1)
    end
    if input.KeyCode == Enum.KeyCode.G then
        Config.AimAutoFire = not Config.AimAutoFire
        toast(Config.AimAutoFire and 'AUTO TOOL ON' or 'AUTO TOOL OFF')
    end
    if input.KeyCode == Enum.KeyCode.F then
        Config.FlightEnabled = not Config.FlightEnabled
        if Config.FlightEnabled then startFlight() else stopFlight() end
        saveSettings()
    end
end)
connect(UserInputService.InputEnded, function(input)
    local move = MoveKeys[input.KeyCode.Name]
    if move then Toolkit.Holding[move] = false end
end)

local FlightControls = make('Frame', {
    Name = 'FlightPad',
    Size = UDim2.fromOffset(258, 175),
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -10, 1, -12),
    BackgroundTransparency = 1,
    ZIndex = 25,
    Visible = false,
}, Screen)

local flightButtons = {}
local function flightPadButton(text, action, x, y, w, h)
    local b = button({
        Text = text,
        TextSize = 10,
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = .12,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        ZIndex = 26,
    }, FlightControls)
    corner(b, 10)
    border(b, Theme.Primary, 1, .48)
    local press = false
    local heldInput = nil
    local function begin(input)
        if press then return end
        heldInput = input
        press = true
        Toolkit.Holding[action] = true
        animate(b, QuickTween, { BackgroundColor3 = Theme.PrimaryLow })
    end
    local function finish()
        if not press then return end
        press = false
        heldInput = nil
        Toolkit.Holding[action] = false
        animate(b, QuickTween, { BackgroundColor3 = Theme.Surface })
    end
    connect(b.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            begin(input)
        end
    end)
    connect(b.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            finish()
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        -- Também solta o botão quando o toque termina fora do seu limite.
        if press and input == heldInput then finish() end
    end)
    flightButtons[#flightButtons + 1] = { Button = b, Release = finish }
    return b
end
flightPadButton('▲', 'forward', 66, 0, 48, 48)
flightPadButton('▼', 'back', 66, 108, 48, 48)
flightPadButton('◀', 'left', 10, 54, 48, 48)
flightPadButton('▶', 'right', 122, 54, 48, 48)
flightPadButton('SUBIR', 'rise', 184, 7, 70, 57)
flightPadButton('DESCER', 'fall', 184, 83, 70, 57)

-- Botão compacto de travar alvo (não precisa abrir menu).
local LockButton = button({
    Name = 'PhantomLock',
    Text = '◎\nLOCK',
    TextColor3 = Theme.Primary,
    TextSize = 11,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.fromOffset(56, 51),
    Position = UDim2.new(1, -68, .39, 0),
    ZIndex = 24,
}, Screen)
corner(LockButton, 12)
border(LockButton, Theme.PrimaryLow, 1)
connect(LockButton.MouseButton1Click, function()
    Config.Aim = not Config.Aim
    if not Config.Aim then Toolkit.Target = nil end
    toast(Config.Aim and 'Trava de câmera ligada' or 'Trava de câmera desligada')
    saveSettings()
end)

-- Quick actions that remain accessible with the panel hidden.
local QuickActions = make('Frame', {
    Name = 'MobileActions',
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(67, 171),
    Position = UDim2.new(1, -77, .51, 0),
    ZIndex = 27,
}, Screen)
local NextButton = button({
    Text = 'NEXT',
    TextSize = 10,
    BackgroundColor3 = Theme.Surface,
    TextColor3 = Theme.Primary,
    Size = UDim2.fromOffset(65, 36),
    Position = UDim2.fromOffset(0, 0),
    ZIndex = 28,
}, QuickActions)
corner(NextButton, 10)
border(NextButton, Theme.Primary, 1, .35)
connect(NextButton.MouseButton1Click, function()
    cycleTarget(1)
end)
local FireButton = button({
    Text = 'FIRE',
    TextSize = 11,
    TextColor3 = Theme.Danger,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.fromOffset(65, 36),
    Position = UDim2.fromOffset(0, 44),
    ZIndex = 28,
}, QuickActions)
corner(FireButton, 10)
border(FireButton, Theme.Danger, 1, .35)
connect(FireButton.MouseButton1Click, function()
    Config.AimAutoFire = not Config.AimAutoFire
    saveSettings()
    toast(Config.AimAutoFire and 'AUTO TOOL: ON' or 'AUTO TOOL: OFF')
end)
local ClearButton = button({
    Text = 'CLEAR',
    TextSize = 10,
    TextColor3 = Theme.Gold,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.fromOffset(65, 36),
    Position = UDim2.fromOffset(0, 88),
    ZIndex = 28,
}, QuickActions)
corner(ClearButton, 10)
border(ClearButton, Theme.Gold, 1, .35)
connect(ClearButton.MouseButton1Click, function()
    Config.Aim = false
    selectTarget(nil)
    saveSettings()
    toast('Mira e alvo liberados')
end)

local ViewButton = button({
    Text = 'VIEW',
    TextSize = 10,
    TextColor3 = Theme.Gold,
    BackgroundColor3 = Theme.Surface,
    Size = UDim2.fromOffset(65, 36),
    Position = UDim2.fromOffset(0, 132),
    ZIndex = 28,
}, QuickActions)
corner(ViewButton, 10)
border(ViewButton, Theme.Gold, 1, .35)
connect(ViewButton.MouseButton1Click, function()
    Config.HUDSpectate = not Config.HUDSpectate
    if Config.HUDSpectate then Config.Aim = false end
    if not Config.HUDSpectate then stopSpectate() end
    saveSettings()
    toast(Config.HUDSpectate and 'Espectar jogador selecionado' or 'Espectador desativado')
end)

local function updateHud()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local center = cam.ViewportSize / 2
    FOVCircle.Position = UDim2.fromOffset(center.X, center.Y)
    FOVCircle.Size = UDim2.fromOffset(Config.AimFOV * 2, Config.AimFOV * 2)
    FOVCircle.Visible = Config.AimShowFOV and not Config.AimAcquireGlobal
    Crosshair.Position = UDim2.fromOffset(center.X, center.Y)
    Crosshair.Visible = Config.AimCrosshair
    TargetBanner.Position = UDim2.fromOffset(center.X, center.Y + Config.AimFOV + 9)
    TargetBanner.Visible = Config.Aim and Toolkit.Target ~= nil
    local target = Toolkit.Target
    if target then
        TargetBanner.Text = 'ALVO: ' .. target.DisplayName
        Toolkit.Statistics.Target = target.DisplayName
    else
        Toolkit.Statistics.Target = 'Nenhum'
    end
    FlightControls.Visible = Config.FlightEnabled and Config.FlightUseControl
    updateLockIndicator()
    updateSpectate()
    updateWarningBanner()
    QuickActions.Visible = Config.QuickButtons
    FireButton.TextColor3 = Config.AimAutoFire and Theme.Positive or Theme.Danger
    ViewButton.TextColor3 = Config.HUDSpectate and Theme.Positive or Theme.Gold
    LockButton.TextColor3 = Config.Aim and Theme.Positive or Theme.Primary
    LockButton.Text = Config.Aim and '◉\nON' or '◎\nLOCK'
    refreshRadar()
    refreshTargetCard()
    FooterRight.Text = string.format('ESP %d  •  ALVO %s',
        Toolkit.Statistics.Players, target and string.sub(target.Name, 1, 9) or '—')
end

-- Telas do menu.
local AimPage = Library:CreatePage('MIRA', 68)
local ESPPage = Library:CreatePage('ESP', 62)
local FlyPage = Library:CreatePage('VOO', 62)
local HUDPage = Library:CreatePage('HUD', 62)
local CombatPage = Library:CreatePage('COMBATE', 95)
local TargetPage = Library:CreatePage('ALVOS', 83)
local FXPage = Library:CreatePage('VISUAL', 80)
local StatsPage = Library:CreatePage('STATUS', 82)
local InfoPage = Library:CreatePage('SOBRE', 72)

AimPage:Section('PHANTOM LOCK • CAPTURA & RASTREIO')
AimPage:Toggle('Trava automática de câmera', 'Aim', 'Seleciona o alvo mais próximo da mira', function(value)
    if not value then Toolkit.Target = nil end
    toast(value and 'Mira automática ativada' or 'Mira desativada')
end)
AimPage:Toggle('Fixar alvo até morrer', 'AimSticky', 'Não solta o alvo por sair do FOV')
AimPage:Toggle('Trava atravessando paredes', 'AimTrackThroughWalls', 'Rastreia a posição replicada mesmo atrás de paredes')
AimPage:Toggle('Trava fora da tela', 'AimTrackOffscreen', 'Não perde o jogador quando vira as costas')
AimPage:Toggle('Buscar em todo o mapa', 'AimAcquireGlobal', 'Captura mesmo fora da mira; pode ser inesperado')
AimPage:Toggle('Distância ilimitada (cliente)', 'AimInfiniteRange', 'Não aplica corte artificial em studs')
AimPage:Toggle('Trocar após morte / perda', 'AimAutoSwitch', 'Automaticamente seleciona outro jogador válido')
AimPage:Toggle('Travamento instantâneo', 'AimInstant', 'Câmera diretamente alinhada a cada frame')
AimPage:Toggle('Predição dinâmica por distância', 'AimSmartLead')
AimPage:Toggle('Corrigir queda em saltos', 'AimAirPrediction')
AimPage:Toggle('Desligar mira quando menu aberto', 'AimDisableWhileMenu')
AimPage:Toggle('Ignorar membros da equipe', 'AimTeamCheck')
AimPage:Toggle('Exigir linha de visão', 'AimVisibility', 'Paredes bloqueiam a aquisição')
AimPage:Toggle('Funcionar só com Tool equipada', 'AimRequiresTool')
AimPage:Choice('Ponto da mira', 'AimPart', { 'Head', 'Chest', 'Root' })
AimPage:Toggle('Membro mais perto do centro', 'AimClosestBody')
AimPage:Choice('Método de mira', 'AimSmoothingMode', { 'Direct', 'Adaptive', 'Smooth' })
AimPage:Choice('Prioridade do alvo', 'AimPriority', { 'Crosshair', 'Distance', 'LowHealth', 'Threat' })
AimPage:Slider('Raio FOV', 'AimFOV', 40, 450, ' px')
AimPage:Slider('Força do acompanhamento', 'AimSmooth', 5, 100, '%')
AimPage:Slider('Tempo de predição', 'AimLeadTime', 0, 50, '/100s')
AimPage:Slider('Lead vertical', 'AimVerticalLead', 0, 30, '%')
AimPage:Slider('Tempo entre trocas', 'AimRetargetDelay', 0, 60, '/100s')
AimPage:Slider('Distância máxima', 'AimDistance', 100, 10000, ' st')
AimPage:Button('PROCURAR NOVO ALVO', function()
    selectTarget(findBestTarget(), 'manual')
    toast(Toolkit.Target and ('Alvo: ' .. Toolkit.Target.DisplayName) or 'Nenhum alvo no FOV')
end)
AimPage:Button('PRÓXIMO ALVO', function()
    cycleTarget(1)
end)
AimPage:Button('ALVO ANTERIOR', function()
    cycleTarget(-1)
end)
AimPage:Button('SOLTAR ALVO ATUAL', function()
    Config.Aim = false
    selectTarget(nil)
    toast('Alvo liberado')
end)

ESPPage:Section('VISÃO DE JOGADORES')
ESPPage:Toggle('ESP geral', 'ESPEnabled', 'Exibe jogadores próximos na tela')
ESPPage:Toggle('Caixas 2D', 'ESPBox')
ESPPage:Toggle('Linhas / tracers', 'ESPLine', 'Desenhadas em ScreenGui; independentes de Drawing')
ESPPage:Toggle('Tracers fora da tela', 'ESPTracersOffscreen', 'Continua linhas até a borda quando o alvo sai da tela')
ESPPage:Choice('Origem da linha', 'ESPTraceOrigin', { 'Bottom', 'Center', 'Top' })
ESPPage:Slider('Espessura das linhas', 'ESPTracerThickness', 1, 5, ' px')
ESPPage:Toggle('Nome do jogador', 'ESPName')
ESPPage:Toggle('Barra de vida', 'ESPHealth')
ESPPage:Toggle('Distância em studs', 'ESPDistance')
ESPPage:Toggle('Destaque 3D / Highlight', 'ESPHighlight')
ESPPage:Toggle('Esqueleto / bones', 'ESPSkeleton')
ESPPage:Toggle('Nome da arma equipada', 'ESPShowWeapon')
ESPPage:Toggle('Ponto da cabeça', 'ESPHeadDot')
ESPPage:Toggle('Indicadores fora da tela', 'ESPOffscreen')
ESPPage:Toggle('Destaque através de paredes', 'ESPThroughWalls')
ESPPage:Toggle('Ignorar a própria equipe', 'ESPTeamCheck')
ESPPage:Toggle('Sem limite de distância local', 'ESPUnlimitedRange')
ESPPage:Toggle('Linha exclusiva do alvo', 'ESPLockIndicator')
ESPPage:Toggle('Retícula animada no alvo', 'ESPPulseTarget')
ESPPage:Slider('Raio máximo do ESP', 'ESPRange', 100, 10000, ' st')
ESPPage:Slider('Atualizações por segundo', 'ESPUpdateRate', 5, 40, ' fps')
ESPPage:Toggle('FPS adaptável', 'ESPAdaptivePerformance', 'Reduz atualização do ESP quando há travamentos')
ESPPage:Section('NPC / BOTS • OPCIONAL')
ESPPage:Toggle('Detectar NPCs com Humanoid', 'ESPIncludeNPC', 'ESP em bots replicados no Workspace', function(enabled)
    if not enabled then resetNPCMarkers() end
end)
ESPPage:Slider('Alcance de bots', 'ESPNPCRange', 100, 5000, ' st')
ESPPage:Slider('Máximo de bots desenhados', 'ESPNPCMax', 5, 60, ' bots')
ESPPage:Slider('Intervalo de busca de bots', 'ESPNPCScanInterval', 2, 10, ' s')
ESPPage:Button('LIMPAR MARCADORES', function()
    for plr in pairs(Toolkit.ESP) do destroyESP(plr) end
    resetNPCMarkers()
    toast('Marcadores recriados na próxima atualização')
end)

-- ====================================================
-- COMBAT, TARGET, FX AND DIAGNOSTICS TABS
-- These are functional client-side controls.
-- ====================================================
CombatPage:Section('ATIVAÇÃO DE TOOL • COMBATE')
CombatPage:Toggle('Auto disparar Tool equipada', 'AimAutoFire',
    'Aciona Tool:Activate() quando há alvo válido. Depende da arma.')
CombatPage:Choice('Condição de disparo', 'AimFireCondition',
    { 'Visible', 'Crosshair', 'Any' })
CombatPage:Slider('Cadência solicitada', 'AimFireRate', 1, 22, ' /s')
CombatPage:Slider('Alcance de disparo', 'AimFireMaxDistance', 50, 2000, ' st')
CombatPage:Toggle('Equipar Tool da mochila', 'AimAutoEquip',
    'Equipe a primeira Tool do Backpack quando necessário')
CombatPage:Button('EQUIPAR PRIMEIRA TOOL', function()
    equipAnyTool()
    toast(getCombatTool() and 'Tool equipada' or 'Nenhuma Tool pronta')
end)
CombatPage:Button('TESTE DE ATIVAÇÃO DA TOOL', function()
    local tool = getCombatTool()
    if not tool then toast('Nenhuma Tool na mão'); return end
    local ok = pcall(function() tool:Activate() end)
    toast(ok and 'Ativação enviada à Tool' or 'Tool recusou ativação')
end, 'Não inventa dano, munição ou controle de servidor')
CombatPage:Note('Auto disparo usa Tool:Activate(); o servidor decide tiro, dano, cadência, distância e recarga. Modo Any não faz disparos atravessarem paredes.')
CombatPage:Section('FILTROS DO RADAR TÁTICO')
CombatPage:Toggle('Avisos de alvo', 'TargetNotifications')
CombatPage:Button('PARAR TODAS AS AÇÕES', function()
    Config.AimAutoFire = false
    Config.Aim = false
    Config.FlightEnabled = false
    stopFlight()
    selectTarget(nil)
    for _, refresh in ipairs(Refreshers) do pcall(refresh) end
    toast('Todas as ações desativadas')
end)

TargetPage:Section('SELECIONE QUALQUER JOGADOR')
TargetPage:SearchPlayer('FOCUS / BUSCAR JOGADOR', targetByName)
TargetPage:Button('PEGAR ALVO MAIS PERTO DA MIRA', function()
    local old = Config.AimAcquireGlobal
    Config.AimAcquireGlobal = false
    local p = findBestTarget()
    Config.AimAcquireGlobal = old
    selectTarget(p, 'manual')
    if p then Config.Aim = true end
    toast(p and ('LOCK: ' .. p.DisplayName) or 'Nenhum no FOV')
end)
TargetPage:Button('PEGAR ALVO MAIS PERTO NO MAPA', function()
    local oldP, oldG = Config.AimPriority, Config.AimAcquireGlobal
    Config.AimPriority, Config.AimAcquireGlobal = 'Distance', true
    local p = findBestTarget()
    Config.AimPriority, Config.AimAcquireGlobal = oldP, oldG
    selectTarget(p, 'manual')
    if p then Config.Aim = true end
    toast(p and ('LOCK: ' .. p.DisplayName) or 'Nenhum encontrado')
end)
TargetPage:Button('PRÓXIMO JOGADOR', function() cycleTarget(1) end)
TargetPage:Button('JOGADOR ANTERIOR', function() cycleTarget(-1) end)
TargetPage:Button('REMOVER TRAVA', function() Config.Aim = false; selectTarget(nil) end)
TargetPage:Section('INTELIGÊNCIA DE ALVO')
TargetPage:Telemetry('Nome do alvo', function()
    return Toolkit.Target and Toolkit.Target.Name or '—'
end)
TargetPage:Telemetry('Vida do alvo', function()
    local _, hum = characterParts(Toolkit.Target)
    return hum and (math.floor(hum.Health) .. ' HP') or '—'
end)
TargetPage:Telemetry('Distância', function()
    local _, _, root = characterParts(Toolkit.Target)
    local cam = Workspace.CurrentCamera
    return root and cam and math.floor((root.Position - cam.CFrame.Position).Magnitude) .. ' studs' or '—'
end)
TargetPage:Telemetry('Cobertura', function()
    local p, c = getAimPart(Toolkit.Target)
    return p and c and (isVisibleToCamera(c, p) and 'LIVRE' or 'PAREDE') or '—'
end)
TargetPage:Note('O Roblox pode não replicar posições de jogadores muito distantes quando StreamingEnabled está ativo. Não há localização por trás do servidor.')

FXPage:Section('PHANTOM X / ANIMATED INTERFACE')
FXPage:Toggle('Animação da HUD', 'HUDMotion')
FXPage:Toggle('Borda com cores em rotação', 'UISpectrum')
FXPage:Toggle('Efeitos do alvo', 'ESPPulseTarget')
FXPage:Toggle('Exibir retícula de foco', 'HUDLockRing')
FXPage:Toggle('Traçar linha até o alvo', 'ESPLockIndicator')
FXPage:Toggle('Indicador de paredes', 'HUDShowVisibility')
FXPage:Toggle('Botões flutuantes', 'QuickButtons')
FXPage:Button('ALTERNAR PAINEL', function() togglePanel() end)
FXPage:Button('SALVAR VISUAL', function()
    saveSettings()
    toast('Tema e controles salvos quando o executor permite')
end)
FXPage:Note('Design em preto espacial, ciano, roxo, gradientes e motion FX. Evita bibliotecas externas que podem quebrar.')

-- Live player roster populated on demand; select directly by touch.
TargetPage:Section('LISTA DE JOGADORES')
local PlayerList = TargetPage:_row(184)
local RosterInfo = label({
    Text = 'Toque em um jogador para marcar o alvo',
    TextColor3 = Theme.Muted,
    TextSize = 10,
    Position = UDim2.fromOffset(10, 2),
    Size = UDim2.new(1, -20, 0, 18),
    ZIndex = 34,
}, PlayerList)
local RosterScroll = make('ScrollingFrame', {
    Name = 'RosterScroll',
    Size = UDim2.new(1, -16, 1, -25),
    Position = UDim2.fromOffset(8, 22),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 34,
}, PlayerList)
make('UIListLayout', {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
}, RosterScroll)
local RosterButtons = {}
local function refreshRoster()
    if not Toolkit.Alive then return end
    for _, b in pairs(RosterButtons) do
        if b.Parent then b:Destroy() end
    end
    table.clear(RosterButtons)
    local count = 0
    local joined = Players:GetPlayers()
    table.sort(joined, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
    for _, plr in ipairs(joined) do
        if plr ~= LocalPlayer then
            count = count + 1
            local char, hum, root = characterParts(plr)
            local friendly = sameTeam(plr)
            local color = Toolkit.Target == plr and Theme.Gold or
                (friendly and Theme.Positive or Theme.Primary)
            local currentName = plr.DisplayName
            local hp = hum and tostring(math.floor(hum.Health)) or '?'
            local b = button({
                Name = 'P_' .. plr.UserId,
                Text = (Toolkit.Target == plr and '◉  ' or '◎  ') ..
                    currentName:sub(1, 16) .. '   ·   ' .. hp .. ' HP',
                TextColor3 = color,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 10,
                BackgroundColor3 = Theme.Surface2,
                Size = UDim2.new(1, -5, 0, 30),
                ZIndex = 36,
                LayoutOrder = count,
            }, RosterScroll)
            corner(b, 6)
            b.MouseButton1Click:Connect(function()
                if not plr or plr.Parent ~= Players then return end
                Config.Aim = true
                Config.HUDSpectate = false
                selectTarget(plr, 'manual')
                saveSettings()
            end)
            table.insert(RosterButtons, b)
        end
    end
    RosterInfo.Text = 'JOGADORES  ' .. count .. ' • Toque para travar'
end
TargetPage:Button('ATUALIZAR LISTA DE JOGADORES', refreshRoster)
connect(Players.PlayerAdded, function()
    if CurrentPage and CurrentPage.Name == 'ALVOS' then
        task.defer(refreshRoster)
    end
end)
-- List is repopulated only when actually on its tab.
table.insert(Toolkit.Objects, function()
    if CurrentPage and CurrentPage.Name == 'ALVOS' then
        if os.clock() - (Toolkit.LastRosterUpdate or 0) > 1.4 then
            Toolkit.LastRosterUpdate = os.clock()
            refreshRoster()
        end
    end
end)

StatsPage:Section('TELEMETRIA DO CLIENTE')
StatsPage:Telemetry('Jogadores projetados', function()
    return Toolkit.Statistics.Players
end)
StatsPage:Telemetry('Travamentos em alvo', function()
    return Toolkit.Statistics.Locks
end)
StatsPage:Telemetry('Trocas de alvo', function()
    return Toolkit.Statistics.Switches
end)
StatsPage:Telemetry('Ativações Tool', function()
    return Toolkit.Statistics.ToolShots
end)
StatsPage:Telemetry('Erros de câmera', function()
    return Toolkit.Diagnostics.AimFailures
end)
StatsPage:Telemetry('Erros de ESP', function()
    return Toolkit.Diagnostics.ESPFailures
end)
StatsPage:Telemetry('FPS aproximado', function()
    return Toolkit.Statistics.ApproxFPS or 0
end)
StatsPage:Button('REINICIAR MARCADORES', function()
    for plr in pairs(Toolkit.ESP) do destroyESP(plr) end
    toast('Marcadores de jogador reiniciados')
end)
StatsPage:Button('COPIAR DIAGNÓSTICO', function()
    local diag = string.format('PHANTOM X | AimErr=%d | EspErr=%d | Last=%s',
        Toolkit.Diagnostics.AimFailures, Toolkit.Diagnostics.ESPFailures,
        Toolkit.Diagnostics.LastError)
    if type(setclipboard) == 'function' then
        pcall(setclipboard, diag)
        toast('Diagnóstico copiado')
    else toast(diag:sub(1, 58)) end
end)
StatsPage:Note('A ferramenta não pode garantir 100% dos jogos nem alterar validações do servidor. Eventos especiais e armas customizadas dependem de cada jogo.')

FlyPage:Section('MOVIMENTAÇÃO AÉREA')
FlyPage:Toggle('Ativar voo', 'FlightEnabled', 'Movimento local pode ser corrigido pelo servidor', function(value)
    if value then startFlight() else stopFlight() end
end)
FlyPage:Toggle('Controles na tela', 'FlightUseControl', 'Direcional + SUBIR / DESCER')
FlyPage:Toggle('Olhar na direção da câmera', 'FlightFacing')
FlyPage:Slider('Impulso horizontal', 'FlightSpeed', 15, 165, ' st/s')
FlyPage:Slider('Impulso vertical', 'FlightVerticalSpeed', 15, 155, ' st/s')
FlyPage:Note('PC: W/A/S/D para mover, E ou espaço para subir, Q para descer. Tecla F liga/desliga o voo.')
FlyPage:Button('PARAR E DESCER EM SEGURANÇA', function()
    stopFlight()
    toast('Controle de voo desativado')
end)

HUDPage:Section('MIRA E INDICADORES')
HUDPage:Toggle('Mostrar círculo FOV', 'AimShowFOV')
HUDPage:Toggle('Predição: ponto adiantado', 'HUDPredictionMarker')
HUDPage:Toggle('Alertar vida baixa', 'HUDWarnings')
HUDPage:Toggle('Espectar alvo sem usar mira', 'HUDSpectate', 'Câmera segue personagem selecionado', function(value)
    if value then Config.Aim = false else stopSpectate() end
end)
HUDPage:Toggle('Animações do painel', 'UIAnimations')
HUDPage:Toggle('Borda espectral', 'UISpectrum')
HUDPage:Toggle('Anel no alvo', 'HUDLockRing')
HUDPage:Toggle('Seta para alvo fora da tela', 'HUDOffscreenLockArrow')
HUDPage:Toggle('Ver cobertura / parede', 'HUDShowVisibility')
HUDPage:Toggle('Botões de combate flutuantes', 'QuickButtons')
HUDPage:Toggle('Mostrar mira central', 'AimCrosshair')
HUDPage:Toggle('Mini-radar 2D', 'RadarEnabled')
HUDPage:Toggle('Ficha de alvo', 'HUDTargetCard')
HUDPage:Slider('Distância máxima do radar', 'RadarRange', 100, 1250, ' st')
HUDPage:Note('O botão LOCK fica na lateral mesmo com o painel fechado. O painel pode ser arrastado pelo cabeçalho.')
HUDPage:Button('CENTRALIZAR PAINEL', function()
    UI.Position = UDim2.fromScale(.5, .5)
    Config.UIPositionX, Config.UIPositionY = .5, .5
    saveSettings()
    toast('Painel centralizado')
end)
HUDPage:Button('SALVAR CONFIGURAÇÕES', function()
    saveSettings()
    toast(type(writefile) == 'function' and 'Configurações salvas' or 'Salvar indisponível neste executor')
end)
HUDPage:Button('RESTAURAR PADRÕES', function()
    stopFlight()
    for key, value in pairs(Defaults) do Config[key] = value end
    Toolkit.Target = nil
    saveSettings()
    for _, refresh in ipairs(Refreshers) do pcall(refresh) end
    toast('Padrões restaurados')
end)
HUDPage:Button('ENCERRAR SCRIPT / LIMPAR UI', function()
    Toolkit.Destroy()
end)

InfoPage:Section('PHANTOM X • V3')
InfoPage:Note('Interface animada integrada, sem bibliotecas externas. Luau • painéis e botões para touch e PC.')
InfoPage:Section('O QUE É REALMENTE CLIENTE')
InfoPage:Note('O ESP e a trava controlam apenas o que o seu cliente desenha e sua câmera. Isso não garante acerto de tiro.')
InfoPage:Note('Voo também depende da simulação física e da validação do servidor de cada experiência.')
InfoPage:Section('MUNIÇÃO / RECARGA')
InfoPage:Note('Munição infinita, tiro sem recarga e dano dependem do código da arma e de validação do servidor. Um script genérico no Delta não consegue forçar isso em todos os jogos.')
InfoPage:Section('ATALHOS')
InfoPage:Note('RightShift menu • T lock • Y próximo • G auto Tool • F voo. Celular: LOCK, NEXT, FIRE, CLEAR.')
InfoPage:Button('COPIAR STATUS PARA CLIPBOARD', function()
    local status = string.format('PHANTOM X • Aim=%s ESP=%s Fly=%s',
        tostring(Config.Aim), tostring(Config.ESPEnabled), tostring(Config.FlightEnabled))
    if type(setclipboard) == 'function' then
        pcall(setclipboard, status)
        toast('Status copiado')
    else
        toast('Clipboard indisponível')
    end
end)

-- Aba inicial.
if #Pages > 0 then
    local start = Pages[1]
    CurrentPage = start
    start.Body.Visible = true
    start.Tab.BackgroundColor3 = Theme.PrimaryLow
    start.Tab.TextColor3 = Theme.Primary
end

-- Câmera só deve ser alterada DEPOIS da atualização padrão da Roblox.
-- RenderPriority.Camera + 1 permite que o lock local acompanhe o alvo.
local AimRenderName = 'NEXUS_LOCAL_CAMERA_' .. tostring(LocalPlayer.UserId)
RunService:BindToRenderStep(AimRenderName, Enum.RenderPriority.Camera.Value + 40, function(dt)
    if not Toolkit.Alive then return end
    local ok, err = pcall(updateAim, math.min(dt, .12))
    if not ok then
        Toolkit.Diagnostics.AimFailures = Toolkit.Diagnostics.AimFailures + 1
        Toolkit.Diagnostics.LastError = tostring(err):sub(1, 150)
    end
end)

-- Renderização central: conexões são encerradas na destruição.
local espTime = 0
local hudTime = 0
connect(RunService.RenderStepped, function(dt)
    if not Toolkit.Alive then return end
    local ok, err = pcall(function()
        updateFlight()
        autoFireStep()
        UIEffects.elapsed = UIEffects.elapsed + dt
        if UIEffects.elapsed > 100000 then UIEffects.elapsed = 0 end
        if Config.UIAnimations then
            local t = UIEffects.elapsed
            if Config.UISpectrum then
                Spectrum.Rotation = (t * 35) % 360
                LockGrad.Rotation = (-t * 65) % 360
                HeaderGradient.Rotation = math.sin(t * .7) * 19
                local wave = (math.sin(t * 1.8) + 1) / 2
                HeaderBeam.Position = UDim2.new(wave * .64, 0, 1, -2)
                PulseTag.TextTransparency = .12 + wave * .5
            end
            local pulse = (math.sin(t * 4) + 1) / 2
            if Config.ESPPulseTarget and Config.HUDMotion then
                LockIndicator.Size = UDim2.fromOffset(44 + pulse * 13, 44 + pulse * 13)
                LockStroke.Transparency = pulse * .25
            end
        end
        Toolkit.Statistics.ApproxFPS = math.floor(1 / math.max(dt, 0.001) + .5)
        if Toolkit.Objects then
            if math.floor(UIEffects.elapsed * 3) ~= math.floor((UIEffects.elapsed - dt) * 3) then
                for _, reporter in ipairs(Toolkit.Objects) do pcall(reporter) end
            end
        end
        espTime = espTime + dt
        hudTime = hudTime + dt
        local limit = Config.ESPUpdateRate
        if Config.ESPAdaptivePerformance and Toolkit.Statistics.ApproxFPS < 35 then
            limit = math.max(5, math.floor(limit / 2))
        end
        local targetInterval = 1 / math.max(5, limit)
        if espTime >= targetInterval then
            espTime = 0
            updateESP()
            updateNPCESP()
        end
        if hudTime >= .08 then
            hudTime = 0
            updateHud()
            clampDashboard()
        end
    end)
    if not ok then
        Toolkit.Diagnostics.ESPFailures = Toolkit.Diagnostics.ESPFailures + 1
        Toolkit.Diagnostics.LastError = tostring(err):sub(1, 150)
    end
end)

connect(Players.PlayerRemoving, function(plr)
    destroyESP(plr)
    if RadarDots[plr] then
        RadarDots[plr]:Destroy()
        RadarDots[plr] = nil
    end
    if Toolkit.Target == plr then selectTarget(nil) end
end)

connect(LocalPlayer.CharacterRemoving, function()
    if Config.FlightEnabled then stopFlight() end
end)
connect(LocalPlayer.CharacterAdded, function()
    if not Config.HUDSpectate then stopSpectate() end
end)

function Toolkit.Destroy()
    if not Toolkit.Alive then return end
    Toolkit.Alive = false
    pcall(function() RunService:UnbindFromRenderStep(AimRenderName) end)
    stopFlight()
    stopSpectate()
    for plr in pairs(Toolkit.ESP) do destroyESP(plr) end
    resetNPCMarkers()
    for _, connection in ipairs(Toolkit.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    pcall(function() Screen:Destroy() end)
    if Environment[KEY] == Toolkit then Environment[KEY] = nil end
end

toast('PHANTOM X V3 • LOCK + ESP ATIVOS')
print('[PHANTOM X] Mira persistente / rastreio / ESP / Tool activation. Nunca altera segurança ou munição do servidor.')
