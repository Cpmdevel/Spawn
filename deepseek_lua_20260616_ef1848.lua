-- ============================================================
--  🌱 FARMING GAME - FarmingGui.lua  v2.2 (Mobile+)
--  ✅ Mobile‑first UI (large touch targets, responsive)
--  ✅ Real‑time seed stats (weight, price, grow time)
--  ✅ Bug‑fixed plot selection & refresh
--  ✅ Works with Delta / any executor
-- ============================================================

-- ── Executor guard ──────────────────────────────────────────
local env = (getgenv and getgenv()) or _G
if env._FarmingGuiLoaded then
    warn("[FarmingGui] Already loaded – skipping duplicate.")
    return
end
env._FarmingGuiLoaded = true

-- ── Services ────────────────────────────────────────────────
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Remote retry helper ─────────────────────────────────────
local function waitForRemote(parent, name, timeout, retryInterval)
    timeout = timeout or 15
    retryInterval = retryInterval or 0.5
    local start = tick()
    while (tick() - start) < timeout do
        local obj = parent:FindFirstChild(name)
        if obj then return obj end
        task.wait(retryInterval)
    end
    return nil
end

-- ── Locate Remotes ──────────────────────────────────────────
local Remotes = waitForRemote(ReplicatedStorage, "Remotes", 20)
if not Remotes then
    warn("[FarmingGui] Remotes folder not found – aborting.")
    return
end

local function getRemote(name)
    return waitForRemote(Remotes, name, 10)
end

local RE_PlantSeed   = getRemote("PlantSeed")
local RE_HarvestPlot = getRemote("HarvestPlot")
local RE_HarvestAll  = getRemote("HarvestAll")   -- optional
local RE_SellAll     = getRemote("SellAll")
local RE_SellOne     = getRemote("SellOne")      -- optional
local RE_BuySeed     = getRemote("BuySeed")
local RE_UpdateUI    = getRemote("UpdateUI")
local RF_GetSeeds    = getRemote("GetSeeds")

if not RE_UpdateUI then
    warn("[FarmingGui] Critical remote 'UpdateUI' missing – UI will not auto‑update.")
end
if not RF_GetSeeds then
    warn("[FarmingGui] Remote 'GetSeeds' missing – seed shop may be empty.")
end

-- ── State ───────────────────────────────────────────────────
local playerCoins     = 0
local playerInventory = {}
local playerPlots     = {}
local seedCatalog     = {}
local selectedSeed    = nil
local selectedPlot    = nil
local activeTab       = "Seeds"
local isMinimised     = false
local buyQty          = 1
local isRefreshing    = false

-- ── Colour Palette ──────────────────────────────────────────
local C = {
    bg        = Color3.fromRGB(14, 16, 14),
    panel     = Color3.fromRGB(24, 32, 22),
    card      = Color3.fromRGB(32, 46, 28),
    cardSel   = Color3.fromRGB(55, 90, 42),
    green     = Color3.fromRGB(72, 185, 55),
    darkGreen = Color3.fromRGB(38, 110, 28),
    gold      = Color3.fromRGB(255, 205, 55),
    red       = Color3.fromRGB(215, 55, 55),
    blue      = Color3.fromRGB(55, 130, 225),
    orange    = Color3.fromRGB(230, 140, 30),
    white     = Color3.new(1, 1, 1),
    text      = Color3.fromRGB(225, 228, 215),
    dim       = Color3.fromRGB(115, 118, 106),
    topbar    = Color3.fromRGB(12, 55, 12),
    plotEmpty = Color3.fromRGB(110, 75, 38),
    plotGrow  = Color3.fromRGB(52, 100, 44),
    plotReady = Color3.fromRGB(42, 185, 48),
}

-- ── Helpers ─────────────────────────────────────────────────
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 90, 50)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function makeFrame(parent, name, size, pos, color, radius)
    local f = Instance.new("Frame")
    f.Name             = name or "Frame"
    f.Size             = size
    f.Position         = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or C.panel
    f.BorderSizePixel  = 0
    f.Parent           = parent
    if radius then corner(f, radius) end
    return f
end

local function makeLabel(parent, text, size, pos, textColor, fontSize, align)
    local l = Instance.new("TextLabel")
    l.Size              = size
    l.Position          = pos or UDim2.new(0,0,0,0)
    l.Text              = text
    l.TextColor3        = textColor or C.text
    l.BackgroundTransparency = 1
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = fontSize or 14
    l.TextXAlignment    = align or Enum.TextXAlignment.Left
    l.TextTruncate      = Enum.TextTruncate.AtEnd
    l.Parent            = parent
    return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor, radius)
    local b = Instance.new("TextButton")
    b.Size              = size
    b.Position          = pos or UDim2.new(0,0,0,0)
    b.Text              = text
    b.TextColor3        = textColor or C.white
    b.BackgroundColor3  = bgColor or C.green
    b.BorderSizePixel   = 0
    b.Font              = Enum.Font.GothamBold
    b.TextSize          = 13
    b.AutoButtonColor   = false
    b.Parent            = parent
    corner(b, radius or 8)
    local orig = bgColor or C.green
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.18)
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = orig
        }):Play()
    end)
    -- Mobile touch feedback
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {
            Size = UDim2.new(size.X.Scale, size.X.Offset - 2, size.Y.Scale, size.Y.Offset - 2)
        }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), {
            Size = size
        }):Play()
    end)
    return b
end

local function makeScrollFrame(parent, name, size, pos, barColor)
    local sf = Instance.new("ScrollingFrame")
    sf.Name               = name
    sf.Size               = size
    sf.Position           = pos or UDim2.new(0,0,0,0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel    = 0
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = barColor or C.green
    sf.CanvasSize         = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    sf.Parent             = parent
    return sf
end

-- ── Remove old GUI ───────────────────────────────────────────
if playerGui:FindFirstChild("FarmingUI") then
    playerGui.FarmingUI:Destroy()
end

-- ── ScreenGui ───────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "FarmingUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ── Main Container (draggable, responsive) ──────────────────
local viewport = workspace.CurrentCamera.ViewportSize
local panelW = math.min(400, viewport.X * 0.9)  -- max 400px, 90% of screen on mobile
local panelH = math.min(560, viewport.Y * 0.85) -- max 560px, 85% of screen height

local container = makeFrame(screenGui, "Container",
    UDim2.new(0, panelW, 0, panelH),
    UDim2.new(0.5, -panelW/2, 0.5, -panelH/2),
    C.bg, 14)
stroke(container, Color3.fromRGB(55, 90, 45), 1)

-- ── Drag Logic ──────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        container.Position = UDim2.new(0,
            startPos.X.Offset + delta.X, 0,
            startPos.Y.Offset + delta.Y)
    end
    local function attachDrag(topBar)
        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = input.Position
                startPos  = container.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
             or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
    end
    env._FarmingAttachDrag = attachDrag
end

-- ── Top Bar (larger touch area) ────────────────────────────
local topBar = makeFrame(container, "TopBar",
    UDim2.new(1, 0, 0, 54), -- taller for mobile
    UDim2.new(0, 0, 0, 0),
    C.topbar, 0)
local tcorner = Instance.new("UICorner")
tcorner.CornerRadius = UDim.new(0, 14)
tcorner.Parent = topBar

local titleLabel = makeLabel(topBar, "🌱 FARMING",
    UDim2.new(1, -160, 1, 0),
    UDim2.new(0, 14, 0, 0),
    C.green, 16, Enum.TextXAlignment.Left)

-- Coin display
local coinLabel = makeLabel(topBar, "🪙 0",
    UDim2.new(0, 120, 1, 0),
    UDim2.new(1, -132, 0, 0),
    C.gold, 16, Enum.TextXAlignment.Right)
coinLabel.Name = "CoinLabel"

-- Refresh button (larger)
local refreshBtn = makeButton(topBar, "⟳",
    UDim2.new(0, 38, 0, 38),
    UDim2.new(1, -114, 0, 8),
    Color3.fromRGB(40, 70, 50), C.white, 6)
refreshBtn.TextSize = 18

-- Minimise button
local minBtn = makeButton(topBar, "─",
    UDim2.new(0, 38, 0, 38),
    UDim2.new(1, -74, 0, 8),
    Color3.fromRGB(50, 80, 40), C.white, 6)
minBtn.TextSize = 18

-- Close button
local closeBtn = makeButton(topBar, "✕",
    UDim2.new(0, 38, 0, 38),
    UDim2.new(1, -34, 0, 8),
    C.red, C.white, 6)
closeBtn.TextSize = 16

env._FarmingAttachDrag(topBar)

-- ── Body ────────────────────────────────────────────────────
local body = makeFrame(container, "Body",
    UDim2.new(1, 0, 1, -54),
    UDim2.new(0, 0, 0, 54),
    C.panel, 0)

-- ── Tab Bar ─────────────────────────────────────────────────
local tabBar = makeFrame(body, "TabBar",
    UDim2.new(1, -16, 0, 44),
    UDim2.new(0, 8, 0, 8),
    Color3.fromRGB(20, 32, 18), 10)
stroke(tabBar, Color3.fromRGB(45, 70, 38), 1)

local TABS = {
    { name = "Seeds",  icon = "🌱" },
    { name = "Garden", icon = "🌿" },
    { name = "Sell",   icon = "💰" },
}

local tabButtons = {}
for i, t in ipairs(TABS) do
    local btn = makeButton(tabBar,
        t.icon .. " " .. t.name,
        UDim2.new(0.333, -4, 1, -8),
        UDim2.new((i-1) * 0.333, 2, 0, 4),
        t.name == activeTab and C.green or Color3.fromRGB(38, 60, 32),
        C.white, 8)
    btn.Name = t.name .. "Tab"
    btn.TextSize = 14
    tabButtons[t.name] = btn
end

-- ── Content area ─────────────────────────────────────────────
local content = makeFrame(body, "Content",
    UDim2.new(1, -16, 1, -66),
    UDim2.new(0, 8, 0, 58),
    Color3.new(0,0,0), 0)
content.BackgroundTransparency = 1

-- ============================================================
--  SEEDS PANEL
-- ============================================================
local seedsPanel = makeFrame(content, "SeedsPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.new(0,0,0), 0)
seedsPanel.BackgroundTransparency = 1

makeLabel(seedsPanel, "🛒 Seed Shop",
    UDim2.new(1, 0, 0, 28), UDim2.new(0,0,0,0),
    C.green, 16, Enum.TextXAlignment.Center)

local seedScroll = makeScrollFrame(seedsPanel, "SeedScroll",
    UDim2.new(1, 0, 1, -92),
    UDim2.new(0, 0, 0, 32),
    C.green)

local seedListLayout = Instance.new("UIListLayout")
seedListLayout.Padding = UDim.new(0, 8)
seedListLayout.Parent  = seedScroll

-- Bottom controls
local buyQtyLabel = makeLabel(seedsPanel, "Qty: 1",
    UDim2.new(0, 80, 0, 34),
    UDim2.new(0, 8, 1, -42),
    C.text, 14)
buyQtyLabel.Name = "BuyQtyLabel"

local qtyMinus = makeButton(seedsPanel, "−",
    UDim2.new(0, 38, 0, 38),
    UDim2.new(0, 88, 1, -44),
    C.red, C.white, 6)
local qtyPlus = makeButton(seedsPanel, "+",
    UDim2.new(0, 38, 0, 38),
    UDim2.new(0, 128, 1, -44),
    C.green, C.white, 6)
local buyBtn = makeButton(seedsPanel, "BUY SEED",
    UDim2.new(0, 160, 0, 38),
    UDim2.new(1, -170, 1, -44),
    C.gold, C.bg, 8)
buyBtn.Name    = "BuyBtn"
buyBtn.TextSize = 15

local function updateBuyQty(n)
    buyQty = math.clamp(n, 1, 99)
    buyQtyLabel.Text = "Qty: " .. buyQty
end
qtyMinus.MouseButton1Click:Connect(function() updateBuyQty(buyQty - 1) end)
qtyPlus.MouseButton1Click:Connect(function()  updateBuyQty(buyQty + 1) end)

-- ============================================================
--  GARDEN PANEL
-- ============================================================
local gardenPanel = makeFrame(content, "GardenPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.new(0,0,0), 0)
gardenPanel.BackgroundTransparency = 1
gardenPanel.Visible = false

makeLabel(gardenPanel, "🌿 Your Garden",
    UDim2.new(1, 0, 0, 28), UDim2.new(0,0,0,0),
    C.green, 16, Enum.TextXAlignment.Center)

-- 3×3 plot grid
local plotGrid = makeFrame(gardenPanel, "PlotGrid",
    UDim2.new(1, 0, 0, 240),
    UDim2.new(0, 0, 0, 32),
    Color3.new(0,0,0), 0)
plotGrid.BackgroundTransparency = 1

local plotButtons = {}
for i = 1, 9 do
    local row = math.floor((i-1)/3)
    local col = (i-1) % 3
    local pb = makeButton(plotGrid,
        "Plot " .. i .. "\n[Empty]",
        UDim2.new(0.333, -4, 0.333, -4),
        UDim2.new(col * 0.333, 2, row * 0.333, 2),
        C.plotEmpty, C.text, 8)
    pb.Name     = "Plot_" .. i
    pb.TextSize = 12
    pb.Font     = Enum.Font.Gotham
    pb.TextWrapped = true
    pb.TextYAlignment = Enum.TextYAlignment.Center
    plotButtons[i] = pb
end

-- Seed selector (horizontal scroll)
makeLabel(gardenPanel, "Seed to plant:",
    UDim2.new(0.55, -10, 0, 22),
    UDim2.new(0, 8, 0, 278),
    C.dim, 13)

local plantSeedScroll = Instance.new("ScrollingFrame")
plantSeedScroll.Name               = "PlantSeedScroll"
plantSeedScroll.Size               = UDim2.new(0.55, -8, 0, 38)
plantSeedScroll.Position           = UDim2.new(0, 8, 0, 302)
plantSeedScroll.BackgroundColor3   = Color3.fromRGB(22, 38, 18)
plantSeedScroll.BorderSizePixel    = 0
plantSeedScroll.ScrollBarThickness = 3
plantSeedScroll.ScrollBarImageColor3 = C.green
plantSeedScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.X
plantSeedScroll.CanvasSize         = UDim2.new(0,0,0,0)
plantSeedScroll.Parent             = gardenPanel
corner(plantSeedScroll, 6)

local plantListLayout = Instance.new("UIListLayout")
plantListLayout.FillDirection = Enum.FillDirection.Horizontal
plantListLayout.Padding       = UDim.new(0, 4)
plantListLayout.Parent        = plantSeedScroll

local plantBtn = makeButton(gardenPanel, "🌱 PLANT",
    UDim2.new(0.43, -8, 0, 38),
    UDim2.new(0.57, 0, 0, 302),
    C.green, C.white, 8)
plantBtn.Name = "PlantBtn"
plantBtn.TextSize = 14

-- Harvest All button
local harvestAllBtn = makeButton(gardenPanel, "🌾 HARVEST ALL",
    UDim2.new(1, 0, 0, 38),
    UDim2.new(0, 0, 0, 348),
    Color3.fromRGB(55, 160, 40), C.white, 8)
harvestAllBtn.TextSize = 14

-- ============================================================
--  SELL PANEL
-- ============================================================
local sellPanel = makeFrame(content, "SellPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.new(0,0,0), 0)
sellPanel.BackgroundTransparency = 1
sellPanel.Visible = false

makeLabel(sellPanel, "💰 Sell Crops",
    UDim2.new(1, 0, 0, 28), UDim2.new(0,0,0,0),
    C.green, 16, Enum.TextXAlignment.Center)

local inventoryScroll = makeScrollFrame(sellPanel, "InventoryScroll",
    UDim2.new(1, 0, 1, -116),
    UDim2.new(0, 0, 0, 32),
    C.gold)

local invListLayout = Instance.new("UIListLayout")
invListLayout.Padding = UDim.new(0, 8)
invListLayout.Parent  = inventoryScroll

local totalValueLabel = makeLabel(sellPanel, "Total Value: 🪙0",
    UDim2.new(1, -20, 0, 24),
    UDim2.new(0, 10, 1, -78),
    C.gold, 15, Enum.TextXAlignment.Center)
totalValueLabel.Name = "TotalValueLabel"

local sellAllBtn = makeButton(sellPanel, "💰 SELL ALL CROPS",
    UDim2.new(1, 0, 0, 44),
    UDim2.new(0, 0, 1, -46),
    C.gold, C.bg, 10)
sellAllBtn.TextSize = 16

-- ============================================================
--  NOTIFICATION (top‑slide, stackable)
-- ============================================================
local notifQueue = {}
local notifActive = false

local function showNotif(text, color)
    table.insert(notifQueue, {text = text, color = color or Color3.fromRGB(28, 80, 28)})
    if notifActive then return end
    notifActive = true

    task.spawn(function()
        while #notifQueue > 0 do
            local data = table.remove(notifQueue, 1)
            local frame = makeFrame(screenGui, "Notif",
                UDim2.new(0, math.min(300, viewport.X * 0.9), 0, 50),
                UDim2.new(0.5, -150, 0, -60), -- starts above screen
                data.color, 12)
            frame.ZIndex = 10
            stroke(frame, Color3.fromRGB(55, 130, 45), 1)
            local label = makeLabel(frame, data.text,
                UDim2.new(1, -12, 1, 0),
                UDim2.new(0, 6, 0, 0),
                C.white, 14, Enum.TextXAlignment.Center)
            label.ZIndex = 11
            frame.Visible = true
            -- Slide down from top
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Position = UDim2.new(0.5, -150, 0, 12)
            }):Play()
            task.wait(2.5)
            TweenService:Create(frame, TweenInfo.new(0.25), {
                Position = UDim2.new(0.5, -150, 0, -60)
            }):Play()
            task.wait(0.3)
            frame:Destroy()
        end
        notifActive = false
    end)
end

-- ============================================================
--  TAB SWITCHING
-- ============================================================
local panels = { Seeds = seedsPanel, Garden = gardenPanel, Sell = sellPanel }

local function switchTab(name)
    activeTab = name
    for tabName, panel in pairs(panels) do
        panel.Visible = (tabName == name)
        local btn = tabButtons[tabName]
        if btn then
            btn.BackgroundColor3 = (tabName == name)
                and C.green
                or Color3.fromRGB(38, 60, 32)
        end
    end
end

for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

-- ============================================================
--  MINIMISE / CLOSE
-- ============================================================
minBtn.MouseButton1Click:Connect(function()
    isMinimised = not isMinimised
    body.Visible = not isMinimised
    minBtn.Text  = isMinimised and "□" or "─"
    TweenService:Create(container, TweenInfo.new(0.2), {
        Size = isMinimised
            and UDim2.new(0, panelW, 0, 54)
            or  UDim2.new(0, panelW, 0, panelH)
    }):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(container, TweenInfo.new(0.2), {
        Size = UDim2.new(0, panelW, 0, 0)
    }):Play()
    task.delay(0.25, function()
        screenGui:Destroy()
        env._FarmingGuiLoaded = nil
    end)
end)

-- ============================================================
--  BUILD SEED SHOP (dynamic, with weight/extra stats)
-- ============================================================
local seedCards = {}

local function buildSeedShop(seeds)
    for _, child in ipairs(seedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    seedCards = {}

    if not seeds or next(seeds) == nil then
        local empty = makeLabel(seedScroll, "No seeds available.",
            UDim2.new(1, -10, 0, 40),
            UDim2.new(0, 5, 0, 10),
            C.dim, 14, Enum.TextXAlignment.Center)
        return
    end

    local names = {}
    for n in pairs(seeds) do table.insert(names, n) end
    table.sort(names)

    for _, seedName in ipairs(names) do
        local info = seeds[seedName]
        local invCount = playerInventory[seedName] or 0

        local card = makeFrame(seedScroll, seedName,
            UDim2.new(1, -4, 0, 64), -- taller for extra stats
            UDim2.new(0, 0, 0, 0),
            C.card, 8)
        stroke(card, Color3.fromRGB(45, 70, 36), 1)

        -- Left accent bar
        makeFrame(card, "Bar",
            UDim2.new(0, 6, 1, 0),
            UDim2.new(0, 0, 0, 0),
            info.color or C.green, 3)

        -- Name + icon (first line)
        makeLabel(card, info.icon and (info.icon .. " " .. seedName) or seedName,
            UDim2.new(0.5, 0, 0, 22),
            UDim2.new(0, 14, 0, 4),
            C.white, 15)

        -- Price (second line, left)
        makeLabel(card, "🪙 " .. info.price,
            UDim2.new(0.3, 0, 0, 20),
            UDim2.new(0, 14, 0, 28),
            C.gold, 14)

        -- Grow time (second line, middle)
        makeLabel(card, "⏱ " .. info.growTime .. "s",
            UDim2.new(0.3, 0, 0, 20),
            UDim2.new(0.35, 0, 0, 28),
            C.dim, 13)

        -- Weight (if available) – like in your image
        if info.weight then
            makeLabel(card, "⚖️ " .. info.weight .. "kg",
                UDim2.new(0.25, 0, 0, 20),
                UDim2.new(0.65, 0, 0, 28),
                C.dim, 13)
        end

        -- Stock
        local stockL = makeLabel(card, "In bag: " .. invCount,
            UDim2.new(0.2, 0, 0, 18),
            UDim2.new(0.8, 0, 0, 4),
            C.dim, 12)
        stockL.Name = seedName .. "_Stock"

        -- Select button (larger)
        local selBtn = makeButton(card, "SELECT",
            UDim2.new(0.18, -4, 0, 30),
            UDim2.new(0.82, 2, 0, 18),
            C.darkGreen, C.white, 6)
        selBtn.TextSize = 12

        selBtn.MouseButton1Click:Connect(function()
            selectedSeed = seedName
            for _, sc in ipairs(seedCards) do
                sc.card.BackgroundColor3 = C.card
            end
            card.BackgroundColor3 = C.cardSel
            buyBtn.Text = "BUY " .. seedName:upper()
            showNotif("Selected: " .. seedName, C.darkGreen)
        end)

        table.insert(seedCards, { name = seedName, card = card, stockLabel = stockL })
    end
end

-- ============================================================
--  UPDATE GARDEN
-- ============================================================
local function updateGardenUI(plots)
    if plots then playerPlots = plots end
    for i, plot in ipairs(playerPlots) do
        local pb = plotButtons[i]
        if not pb then continue end

        if plot.state == "empty" then
            pb.BackgroundColor3 = (selectedPlot == i) and Color3.fromRGB(88, 140, 65) or C.plotEmpty
            pb.Text = "Plot " .. i .. "\n[Empty]"
            pb.TextColor3 = C.dim

        elseif plot.state == "growing" then
            pb.BackgroundColor3 = C.plotGrow
            local elapsed   = os.time() - (plot.plantedAt or os.time())
            local info      = seedCatalog[plot.seed]
            local remaining = info and math.max(0, info.growTime - elapsed) or 0
            pb.Text = (info and info.icon and info.icon .. " " or "🌱 ") ..
                      (plot.seed or "?") .. "\n⏳ " .. remaining .. "s"
            pb.TextColor3 = C.text

        elseif plot.state == "ready" then
            pb.BackgroundColor3 = C.plotReady
            pb.Text = "✅ " .. (plot.seed or "?") .. "\n[HARVEST!]"
            pb.TextColor3 = C.white
        end
    end
end

-- ============================================================
--  UPDATE SELL TAB
-- ============================================================
local function updateSellUI(inventory, seeds)
    for _, child in ipairs(inventoryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local total    = 0
    local hasItems = false

    local names = {}
    for n, count in pairs(inventory) do
        if count and count > 0 then
            local info = seeds[n]
            if info then table.insert(names, n) end
        end
    end
    table.sort(names)

    for _, cropName in ipairs(names) do
        local count = inventory[cropName]
        local info  = seeds[cropName]
        if not info then continue end
        hasItems    = true
        local value = info.sellPrice * count
        total       = total + value

        local row = makeFrame(inventoryScroll, cropName,
            UDim2.new(1, -4, 0, 52),
            UDim2.new(0, 0, 0, 0),
            C.card, 8)
        stroke(row, Color3.fromRGB(45, 70, 36), 1)

        makeFrame(row, "Bar",
            UDim2.new(0, 5, 1, 0),
            UDim2.new(0, 0, 0, 0),
            info.color or C.green, 3)

        makeLabel(row,
            (info.icon and info.icon .. " " or "") .. cropName,
            UDim2.new(0.38, 0, 0, 24),
            UDim2.new(0, 12, 0, 4),
            C.white, 14)
        makeLabel(row, "x" .. count,
            UDim2.new(0.15, 0, 0, 24),
            UDim2.new(0.38, 0, 0, 4),
            C.text, 14)
        makeLabel(row, "🪙 " .. value,
            UDim2.new(0.25, 0, 0, 24),
            UDim2.new(0.53, 0, 0, 4),
            C.gold, 14)

        if RE_SellOne then
            local sellOneBtn = makeButton(row, "SELL",
                UDim2.new(0.2, -8, 0, 32),
                UDim2.new(0.8, 4, 0, 10),
                C.orange, C.white, 6)
            sellOneBtn.TextSize = 12
            sellOneBtn.MouseButton1Click:Connect(function()
                RE_SellOne:FireServer(cropName)
                showNotif("Sold " .. cropName .. "!", C.orange)
            end)
        end

        makeLabel(row, info.sellPrice .. "¢ ea",
            UDim2.new(0.35, 0, 0, 18),
            UDim2.new(0.12, 0, 0, 32),
            C.dim, 11)
    end

    if not hasItems then
        local empty = makeLabel(inventoryScroll, "No crops to sell.\nGrow some first! 🌱",
            UDim2.new(1, -10, 0, 60),
            UDim2.new(0, 5, 0, 10),
            C.dim, 14, Enum.TextXAlignment.Center)
    end

    totalValueLabel.Text  = "Total Value: 🪙 " .. total
    sellAllBtn.Active     = hasItems
    sellAllBtn.BackgroundColor3 = hasItems
        and C.gold
        or  Color3.fromRGB(60, 60, 50)
end

-- ============================================================
--  PLANT SEED BUTTONS
-- ============================================================
local plantSeedBtns = {}

local function updatePlantSeedButtons(inventory)
    for _, b in ipairs(plantSeedBtns) do b:Destroy() end
    plantSeedBtns = {}

    local names = {}
    for n, c in pairs(inventory) do
        if c and c > 0 then table.insert(names, n) end
    end
    table.sort(names)

    for _, seedName in ipairs(names) do
        local count = inventory[seedName]
        local info  = seedCatalog[seedName]
        local icon  = info and info.icon or "🌱"
        local b = makeButton(plantSeedScroll,
            icon .. " " .. seedName .. " ×" .. count,
            UDim2.new(0, 110, 0, 30),
            UDim2.new(0, 0, 0, 0),
            Color3.fromRGB(42, 78, 34), C.white, 6)
        b.TextSize = 11
        b.MouseButton1Click:Connect(function()
            selectedSeed = seedName
            for _, sb in ipairs(plantSeedBtns) do
                sb.BackgroundColor3 = Color3.fromRGB(42, 78, 34)
            end
            b.BackgroundColor3 = C.green
            showNotif("Selected: " .. seedName, C.darkGreen)
        end)
        table.insert(plantSeedBtns, b)
    end
end

-- ============================================================
--  GARDEN PLOT CLICK LOGIC
-- ============================================================
for i, pb in ipairs(plotButtons) do
    pb.MouseButton1Click:Connect(function()
        local plot = playerPlots[i]
        if not plot then return end

        if plot.state == "ready" then
            RE_HarvestPlot:FireServer(i)
            showNotif("🌾 Harvested " .. (plot.seed or "crop") .. "!", C.green)

        elseif plot.state == "empty" then
            if selectedPlot == i then
                selectedPlot = nil
                pb.BackgroundColor3 = C.plotEmpty
                showNotif("Plot " .. i .. " deselected.", C.dim)
            else
                if selectedPlot then
                    local old = plotButtons[selectedPlot]
                    if old then old.BackgroundColor3 = C.plotEmpty end
                end
                selectedPlot = i
                pb.BackgroundColor3 = Color3.fromRGB(88, 140, 65)
                showNotif("Plot " .. i .. " selected! Pick a seed below.", C.darkGreen)
            end

        elseif plot.state == "growing" then
            local info      = seedCatalog[plot.seed]
            local elapsed   = os.time() - (plot.plantedAt or os.time())
            local remaining = info and math.max(0, info.growTime - elapsed) or "?"
            showNotif("⏳ " .. (plot.seed or "?") .. " – " .. remaining .. "s left", C.orange)
        end
    end)
end

-- ── Plant button ─────────────────────────────────────────────
plantBtn.MouseButton1Click:Connect(function()
    if not selectedSeed then
        showNotif("❌ Pick a seed first!", C.red) return
    end
    if not selectedPlot then
        showNotif("❌ Select a plot first!", C.red) return
    end
    if (playerInventory[selectedSeed] or 0) <= 0 then
        showNotif("❌ No " .. selectedSeed .. " seeds!", C.red) return
    end
    RE_PlantSeed:FireServer(selectedPlot, selectedSeed)
    showNotif("🌱 Planted " .. selectedSeed .. " in Plot " .. selectedPlot, C.green)
    -- Keep plot selected? We'll deselect to avoid confusion
    local oldPlot = selectedPlot
    selectedPlot = nil
    plotButtons[oldPlot].BackgroundColor3 = C.plotEmpty
end)

-- ── Harvest All ──────────────────────────────────────────────
harvestAllBtn.MouseButton1Click:Connect(function()
    local hasReady = false
    for _, plot in ipairs(playerPlots) do
        if plot.state == "ready" then hasReady = true break end
    end
    if not hasReady then
        showNotif("Nothing ready to harvest yet!", C.dim) return
    end
    if RE_HarvestAll then
        RE_HarvestAll:FireServer()
        showNotif("🌾 Harvested all ready crops!", C.green)
    else
        for i, plot in ipairs(playerPlots) do
            if plot.state == "ready" then
                RE_HarvestPlot:FireServer(i)
            end
        end
        showNotif("🌾 Harvested all ready crops!", C.green)
    end
end)

-- ── Sell All ─────────────────────────────────────────────────
sellAllBtn.MouseButton1Click:Connect(function()
    local hasItems = false
    for _, v in pairs(playerInventory) do if v > 0 then hasItems = true break end end
    if not hasItems then showNotif("Nothing to sell!", C.red) return end
    RE_SellAll:FireServer()
    showNotif("💰 Sold all crops!", C.gold)
end)

-- ── Buy button ───────────────────────────────────────────────
buyBtn.MouseButton1Click:Connect(function()
    if not selectedSeed then
        showNotif("❌ Select a seed first!", C.red) return
    end
    local info = seedCatalog[selectedSeed]
    if not info then
        showNotif("❌ Seed info missing – refresh?", C.red) return
    end
    local cost = info.price * buyQty
    if cost > playerCoins then
        showNotif("❌ Need 🪙" .. cost .. " (have " .. playerCoins .. ")", C.red) return
    end
    RE_BuySeed:FireServer(selectedSeed, buyQty)
    showNotif("✅ Bought " .. buyQty .. "× " .. selectedSeed, C.green)
end)

-- ============================================================
--  MANUAL REFRESH (full UI rebuild)
-- ============================================================
refreshBtn.MouseButton1Click:Connect(function()
    if isRefreshing then return end
    isRefreshing = true
    showNotif("🔄 Refreshing data...", C.blue)

    -- Try to fetch seeds
    if RF_GetSeeds then
        local ok, seeds = pcall(function()
            return RF_GetSeeds:InvokeServer()
        end)
        if ok and seeds then
            seedCatalog = seeds
            buildSeedShop(seeds)
            -- Also force update other tabs using current inventory/plots
            updateGardenUI(playerPlots)
            updateSellUI(playerInventory, seeds)
            updatePlantSeedButtons(playerInventory)
            showNotif("✅ Data refreshed!", C.green)
        else
            showNotif("❌ Refresh failed – check remotes", C.red)
        end
    else
        showNotif("❌ GetSeeds remote missing", C.red)
    end
    isRefreshing = false
end)

-- ============================================================
--  SERVER UPDATE EVENT
-- ============================================================
if RE_UpdateUI then
    RE_UpdateUI.OnClientEvent:Connect(function(data)
        playerCoins     = data.coins     or 0
        playerInventory = data.inventory or {}
        playerPlots     = data.plots     or {}
        seedCatalog     = data.seeds     or seedCatalog

        local display = playerCoins >= 1000
            and string.format("%.1fK", playerCoins / 1000)
            or  tostring(playerCoins)
        coinLabel.Text = "🪙 " .. display

        buildSeedShop(seedCatalog)
        updateGardenUI(playerPlots)
        updateSellUI(playerInventory, seedCatalog)
        updatePlantSeedButtons(playerInventory)
    end)
else
    warn("[FarmingGui] RE_UpdateUI missing – auto‑updates disabled.")
end

-- ============================================================
--  GARDEN TIMER LOOP
-- ============================================================
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if activeTab == "Garden" then
            updateGardenUI(nil)
        end
    end
end)

-- ============================================================
--  INITIAL DATA FETCH
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    if RF_GetSeeds then
        local ok, seeds = pcall(function()
            return RF_GetSeeds:InvokeServer()
        end)
        if ok and seeds then
            seedCatalog = seeds
            buildSeedShop(seeds)
        else
            warn("[FarmingGui] GetSeeds failed:", seeds)
            showNotif("⚠️ Could not fetch seed data – try refresh", C.orange)
        end
    else
        showNotif("⚠️ GetSeeds remote missing – contact server dev", C.red)
    end
end)

print("✅ FarmingGui v2.2 (Mobile) loaded!")