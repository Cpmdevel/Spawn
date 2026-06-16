-- ============================================================
--  Grow A Garden 2 | Full Script
--  Tabs: Shop · Plants · Misc · Util · Pets · Config
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local TeleportService  = game:GetService("TeleportService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Shop
    AutoBuySeeds      = false,
    AutoBuyGear       = false,
    AutoBuyCrates     = false,
    AutoBuyPets       = false,
    AutoEquipPets     = false,
    AutoServerHop     = false,
    -- Plants
    AutoCollect             = false,
    HighestValueFirst       = true,
    AutoCollectEventSeeds   = false,
    AutoCollectDroppedSeeds = false,
    AutoPlant               = false,
    AutoShovel              = false,
    AutoSell                = false,
    AutoBargainSell         = false,
    AutoWater               = false,
    AutoTrowel              = false,
    AutoSprinkler           = false,
    AutoFavourite           = false,
    -- Misc
    SeedPackTools      = false,
    AutoTrader         = false,
    AutoSteal          = false,
    FlingLockedOwners  = false,
    AutoFlingIntruder  = false,
    AntiHit            = false,
    CenterInGarden     = false,
    AutoMail           = false,
    AntiStealer        = false,
    -- Utility
    WalkSpeed          = 16,
    JumpPower          = 50,
    Noclip             = false,
    InfiniteJump       = false,
    AntiAFK            = false,
    AntiSit            = false,
    FPSBoost           = false,
    LowGraphics        = false,
    HidePlants         = false,
    FruitPriceDisplay  = false,
    PetPriceDisplay    = false,
    -- Config
    AutoExecute        = false,
    AutoReconnect      = false,
    RejoinOnFreeze     = false,
    Watermark          = true,
    DPI                = 1,
}

-- ============================================================
-- NOTIFY
-- ============================================================
local function Notify(title, text, dur)
    StarterGui:SetCore("SendNotification", {
        Title = title, Text = text, Duration = dur or 3
    })
end

-- ============================================================
-- GUI
-- ============================================================
-- Remove old GUI if re-executing
if player.PlayerGui:FindFirstChild("GAG2Script") then
    player.PlayerGui.GAG2Script:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "GAG2Script"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = player.PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 520, 0, 550)
MainFrame.Position          = UDim2.new(0.5, -260, 0.5, -275)
MainFrame.BackgroundColor3  = Color3.fromRGB(14, 14, 20)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local _stroke = Instance.new("UIStroke", MainFrame)
_stroke.Color     = Color3.fromRGB(70, 200, 70)
_stroke.Thickness = 1.5

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text              = "🌱  Grow A Garden 2  |  Script"
TitleLabel.Size              = UDim2.new(1, -80, 1, 0)
TitleLabel.Position          = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3        = Color3.fromRGB(70, 220, 70)
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextSize          = 14
TitleLabel.Parent            = TitleBar

local WatermarkLabel = Instance.new("TextLabel")
WatermarkLabel.Text              = "v1.0"
WatermarkLabel.Size              = UDim2.new(0, 50, 1, 0)
WatermarkLabel.Position          = UDim2.new(1, -84, 0, 0)
WatermarkLabel.BackgroundTransparency = 1
WatermarkLabel.TextColor3        = Color3.fromRGB(100, 100, 110)
WatermarkLabel.Font              = Enum.Font.Gotham
WatermarkLabel.TextSize          = 11
WatermarkLabel.Parent            = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text             = "✕"
CloseBtn.Size             = UDim2.new(0, 30, 0, 28)
CloseBtn.Position         = UDim2.new(1, -34, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = i.Position
        startPos  = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Tab Bar
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, 32)
TabBar.Position         = UDim2.new(0, 0, 0, 38)
TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TabBar.BorderSizePixel  = 0
TabBar.Parent           = MainFrame
local _tbl = Instance.new("UIListLayout", TabBar)
_tbl.FillDirection      = Enum.FillDirection.Horizontal
_tbl.Padding            = UDim.new(0, 2)
_tbl.VerticalAlignment  = Enum.VerticalAlignment.Center
local _tbp = Instance.new("UIPadding", TabBar)
_tbp.PaddingLeft = UDim.new(0, 4)

-- Content Area
local ContentFrame = Instance.new("Frame")
ContentFrame.Size               = UDim2.new(1, 0, 1, -70)
ContentFrame.Position           = UDim2.new(0, 0, 0, 70)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent             = MainFrame

-- ============================================================
-- TAB BUILDER
-- ============================================================
local Tabs      = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Text             = icon .. " " .. name
    btn.Size             = UDim2.new(0, 78, 1, -4)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    btn.TextColor3       = Color3.fromRGB(140, 140, 150)
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 10
    btn.BorderSizePixel  = 0
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size                  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency= 1
    page.BorderSizePixel       = 0
    page.ScrollBarThickness    = 3
    page.ScrollBarImageColor3  = Color3.fromRGB(70, 200, 70)
    page.Visible               = false
    page.Parent                = ContentFrame

    local layout = Instance.new("UIListLayout", page)
    layout.Padding    = UDim.new(0, 5)
    layout.SortOrder  = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft  = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop   = UDim.new(0, 8)

    layout.Changed:Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    Tabs[name] = { Button = btn, Page = page }

    btn.MouseButton1Click:Connect(function()
        if ActiveTab then
            Tabs[ActiveTab].Page.Visible     = false
            Tabs[ActiveTab].Button.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Tabs[ActiveTab].Button.TextColor3       = Color3.fromRGB(140, 140, 150)
        end
        ActiveTab = name
        page.Visible     = true
        btn.BackgroundColor3 = Color3.fromRGB(45, 160, 45)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    end)

    return page
end

-- ============================================================
-- WIDGET HELPERS
-- ============================================================
local function CreateSectionLabel(parent, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, -6, 0, 22)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    f.BorderSizePixel  = 0
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel", f)
    l.Text          = "  " .. text
    l.Size          = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.TextColor3    = Color3.fromRGB(70, 210, 70)
    l.TextXAlignment= Enum.TextXAlignment.Left
    l.Font          = Enum.Font.GothamBold
    l.TextSize      = 11
    return f
end

local function CreateToggle(parent, label, configKey, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -6, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Text          = label
    lbl.Size          = UDim2.new(1, -60, 1, 0)
    lbl.Position      = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3    = Color3.fromRGB(205, 205, 215)
    lbl.TextXAlignment= Enum.TextXAlignment.Left
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 12

    local bg = Instance.new("Frame", row)
    bg.Size             = UDim2.new(0, 42, 0, 22)
    bg.Position         = UDim2.new(1, -50, 0.5, -11)
    bg.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    bg.BorderSizePixel  = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(195, 195, 205)
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = Config[configKey] or false
    local function refresh()
        TweenService:Create(bg,   TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(50,170,50) or Color3.fromRGB(55,55,65)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
        }):Play()
    end
    refresh()

    local hitbox = Instance.new("TextButton", row)
    hitbox.Size               = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text               = ""
    hitbox.MouseButton1Click:Connect(function()
        state = not state
        Config[configKey] = state
        refresh()
        if callback then callback(state) end
    end)
    return row
end

local function CreateSlider(parent, label, configKey, min, max, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -6, 0, 52)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Text          = label .. ":  " .. tostring(Config[configKey] or min)
    lbl.Size          = UDim2.new(1, -10, 0, 22)
    lbl.Position      = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3    = Color3.fromRGB(205, 205, 215)
    lbl.TextXAlignment= Enum.TextXAlignment.Left
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 12

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(1, -20, 0, 6)
    track.Position         = UDim2.new(0, 10, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct = math.clamp((Config[configKey] - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.ZIndex           = 2
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider then
            local rel = math.clamp(
                (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel * (max - min))
            Config[configKey] = val
            lbl.Text    = label .. ":  " .. val
            fill.Size   = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -7, 0.5, -7)
            if callback then callback(val) end
        end
    end)
    return row
end

local function CreateButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -6, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(38, 120, 38)
    btn.TextColor3       = Color3.fromRGB(240, 255, 240)
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 12
    btn.Text             = label
    btn.BorderSizePixel  = 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================================
-- CREATE TABS
-- ============================================================
local ShopPage  = CreateTab("Shop",   "🛒")
local PlantPage = CreateTab("Plants", "🌿")
local MiscPage  = CreateTab("Misc",   "⚙️")
local UtilPage  = CreateTab("Util",   "🔧")
local PetPage   = CreateTab("Pets",   "🐾")
local CfgPage   = CreateTab("Config", "💾")

-- Auto-activate Shop tab
Tabs["Shop"].Button.MouseButton1Click:Fire()

-- ============================================================
-- SHOP TAB
-- ============================================================
CreateSectionLabel(ShopPage, "── Auto Buy ──")
CreateToggle(ShopPage, "Auto Buy Seeds",   "AutoBuySeeds",  nil)
CreateToggle(ShopPage, "Auto Buy Gear",    "AutoBuyGear",   nil)
CreateToggle(ShopPage, "Auto Buy Crates",  "AutoBuyCrates", nil)
CreateToggle(ShopPage, "Auto Buy Pets",    "AutoBuyPets",   nil)
CreateToggle(ShopPage, "Auto Equip Pets",  "AutoEquipPets", nil)
CreateToggle(ShopPage, "Auto Server Hop",  "AutoServerHop", nil)
CreateSectionLabel(ShopPage, "── Info ──")
CreateButton(ShopPage, "📦 Stock Info", function()
    Notify("Stock Info", "Checking shop stock...", 2)
    -- TODO: hook ReplicatedStorage remote
end)
CreateButton(ShopPage, "🔮 Weather / Seed Predictor", function()
    Notify("Predictor", "Predictor activated", 2)
    -- TODO: hook predictor remote
end)

-- ============================================================
-- PLANTS TAB
-- ============================================================
CreateSectionLabel(PlantPage, "── Auto Collect ──")
CreateToggle(PlantPage, "Auto Collect",              "AutoCollect",             nil)
CreateToggle(PlantPage, "Highest Value First",        "HighestValueFirst",       nil)
CreateToggle(PlantPage, "Auto Collect Event Seeds",   "AutoCollectEventSeeds",   nil)
CreateToggle(PlantPage, "Auto Collect Dropped Seeds", "AutoCollectDroppedSeeds", nil)
CreateSectionLabel(PlantPage, "── Auto Farm ──")
CreateToggle(PlantPage, "Auto Plant",        "AutoPlant",       nil)
CreateToggle(PlantPage, "Auto Shovel",       "AutoShovel",      nil)
CreateToggle(PlantPage, "Auto Sell",         "AutoSell",        nil)
CreateToggle(PlantPage, "Auto Bargain Sell", "AutoBargainSell", nil)
CreateSectionLabel(PlantPage, "── Auto Care ──")
CreateToggle(PlantPage, "Auto Water",        "AutoWater",       nil)
CreateToggle(PlantPage, "Auto Trowel",       "AutoTrowel",      nil)
CreateToggle(PlantPage, "Auto Sprinkler",    "AutoSprinkler",   nil)
CreateToggle(PlantPage, "Auto Favourite",    "AutoFavourite",   nil)

-- ============================================================
-- MISC TAB
-- ============================================================
CreateSectionLabel(MiscPage, "── Tools ──")
CreateToggle(MiscPage, "Seed Pack Tools",      "SeedPackTools",    nil)
CreateToggle(MiscPage, "Auto Trader",          "AutoTrader",       nil)
CreateSectionLabel(MiscPage, "── Steal / Fling ──")
CreateToggle(MiscPage, "Auto Steal",           "AutoSteal",        nil)
CreateToggle(MiscPage, "Fling Locked Owners",  "FlingLockedOwners",nil)
CreateToggle(MiscPage, "Auto Fling Intruder",  "AutoFlingIntruder",nil)
CreateToggle(MiscPage, "Anti Stealer",         "AntiStealer",      nil)
CreateSectionLabel(MiscPage, "── QoL ──")
CreateToggle(MiscPage, "Anti Hit",             "AntiHit",          nil)
CreateToggle(MiscPage, "Center In Garden",     "CenterInGarden",   nil)
CreateToggle(MiscPage, "Auto Mail",            "AutoMail",         nil)

-- ============================================================
-- UTILITY TAB
-- ============================================================
CreateSectionLabel(UtilPage, "── Movement ──")
CreateSlider(UtilPage, "WalkSpeed", "WalkSpeed", 16, 200, function(v)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
CreateSlider(UtilPage, "JumpPower", "JumpPower", 50, 500, function(v)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)
CreateToggle(UtilPage, "Noclip", "Noclip", nil)
CreateToggle(UtilPage, "Infinite Jump", "InfiniteJump", function(s)
    if s then
        UserInputService.JumpRequest:Connect(function()
            if Config.InfiniteJump then
                local char = player.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
end)
CreateSectionLabel(UtilPage, "── Anti ──")
CreateToggle(UtilPage, "Anti AFK", "AntiAFK", function()
    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        if Config.AntiAFK then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end)
CreateToggle(UtilPage, "Anti Sit", "AntiSit", nil)
CreateSectionLabel(UtilPage, "── Visual ──")
CreateToggle(UtilPage, "FPS Boost", "FPSBoost", function(s)
    local L = game:GetService("Lighting")
    L.GlobalShadows = not s
    L.FogEnd        = s and 9e9 or 1000
end)
CreateToggle(UtilPage, "Low Graphics", "LowGraphics", function(s)
    settings().Rendering.QualityLevel = s and 1 or 10
end)
CreateToggle(UtilPage, "Hide Plants",         "HidePlants",        nil)
CreateToggle(UtilPage, "Fruit Price Display", "FruitPriceDisplay", nil)
CreateToggle(UtilPage, "Pet Price Display",   "PetPriceDisplay",   nil)
CreateSectionLabel(UtilPage, "── Server ──")
CreateButton(UtilPage, "🔁 Rejoin", function()
    TeleportService:Teleport(game.PlaceId, player)
end)
CreateButton(UtilPage, "🔌 Hop Until PlaceVersion", function()
    Notify("Server Hop", "Hopping to latest version server...", 3)
    -- TODO: loop teleport until PlaceVersion matches
end)
CreateButton(UtilPage, "📋 Join by JobId", function()
    Notify("Join JobId", "Set JobId in Config tab then press this.", 3)
end)

-- ============================================================
-- PET FINDER TAB
-- ============================================================
CreateSectionLabel(PetPage, "── Cross-Server Pet Finder ──")
CreateButton(PetPage, "🔍 Scan All Servers for Rare Pets", function()
    Notify("Pet Finder", "Scanning servers... please wait.", 4)
    -- TODO: iterate server list via MessagingService / TeleportService
end)
CreateButton(PetPage, "📋 Show Found Pet List", function()
    Notify("Pet Finder", "No rare pets found yet. Run a scan first.", 3)
end)

-- ============================================================
-- CONFIG TAB
-- ============================================================
CreateSectionLabel(CfgPage, "── Behaviour ──")
CreateToggle(CfgPage, "Auto Execute",     "AutoExecute",   nil)
CreateToggle(CfgPage, "Auto Reconnect",   "AutoReconnect", nil)
CreateToggle(CfgPage, "Rejoin on Freeze", "RejoinOnFreeze",nil)
CreateToggle(CfgPage, "Watermark",        "Watermark", function(s)
    WatermarkLabel.Visible = s
end)
CreateSlider(CfgPage, "DPI Scale", "DPI", 1, 3, function(v)
    ScreenGui.IgnoreGuiInset = v > 1
end)
CreateSectionLabel(CfgPage, "── Import / Export ──")
CreateButton(CfgPage, "📤 Export Config (copy to clipboard)", function()
    local ok, json = pcall(function() return HttpService:JSONEncode(Config) end)
    if ok then
        setclipboard(json)
        Notify("Config", "Config copied to clipboard!", 3)
    else
        Notify("Config", "Export failed.", 2)
    end
end)
CreateButton(CfgPage, "📥 Import Config (paste from clipboard)", function()
    local ok, result = pcall(function()
        return HttpService:JSONDecode(getclipboard())
    end)
    if ok and type(result) == "table" then
        for k, v in pairs(result) do
            if Config[k] ~= nil then Config[k] = v end
        end
        Notify("Config", "Config imported! Re-open GUI to see changes.", 4)
    else
        Notify("Config", "Invalid or empty clipboard.", 3)
    end
end)

-- ============================================================
-- BACKGROUND LOOPS
-- ============================================================

-- Noclip
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = player.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Anti Sit + generic loop
task.spawn(function()
    while task.wait(0.5) do
        local char = player.Character
        if not char then continue end
        if Config.AntiSit then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then hum.Sit = false end
        end
        if Config.CenterInGarden then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                -- Replace with actual garden center CFrame from workspace
                root.CFrame = CFrame.new(0, 5, 0)
            end
            Config.CenterInGarden = false
        end
        -- === HOOK TEMPLATE ===
        -- Wire these to the game's actual RemoteEvents:
        --
        -- if Config.AutoCollect then
        --     local r = ReplicatedStorage:FindFirstChild("CollectFruit", true)
        --     if r then r:FireServer() end
        -- end
        -- if Config.AutoPlant then
        --     local r = ReplicatedStorage:FindFirstChild("PlantSeed", true)
        --     if r then r:FireServer(bestSeedName) end
        -- end
        -- if Config.AutoSell then
        --     local r = ReplicatedStorage:FindFirstChild("SellAll", true)
        --     if r then r:FireServer() end
        -- end
        -- if Config.AutoWater then
        --     local r = ReplicatedStorage:FindFirstChild("WaterPlant", true)
        --     if r then r:FireServer() end
        -- end
        -- if Config.AutoSteal then
        --     for _, p in pairs(Players:GetPlayers()) do
        --         if p ~= player then
        --             local r = ReplicatedStorage:FindFirstChild("StealFruit", true)
        --             if r then r:FireServer(p) end
        --         end
        --     end
        -- end
    end
end)

-- Freeze Detection + Rejoin
local lastPosition = rootPart.Position
local freezeTimer  = 0
RunService.Heartbeat:Connect(function(dt)
    if Config.RejoinOnFreeze then
        if (rootPart.Position - lastPosition).Magnitude < 0.01 then
            freezeTimer = freezeTimer + dt
            if freezeTimer > 15 then
                TeleportService:Teleport(game.PlaceId, player)
            end
        else
            freezeTimer = 0
        end
        lastPosition = rootPart.Position
    end
end)

-- Auto Reconnect on teleport fail
player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed and Config.AutoReconnect then
        task.wait(3)
        TeleportService:Teleport(game.PlaceId, player)
    end
end)

Notify("GAG2 Script", "✅ Loaded! Use tabs to configure features.", 4)
print("[GAG2 Script] Loaded successfully — v1.0")
