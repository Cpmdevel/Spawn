-- ============================================================
--  🌱 FARMING GAME - FarmingGui.lua
--  Place inside: StarterGui  (as a ScreenGui with a LocalScript inside)
--  OR place as a LocalScript inside StarterPlayerScripts
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes

-- Wait for server to set up remotes
repeat task.wait(0.1) until ReplicatedStorage:FindFirstChild("Remotes")
Remotes = ReplicatedStorage.Remotes

local RE_PlantSeed   = Remotes:WaitForChild("PlantSeed")
local RE_HarvestPlot = Remotes:WaitForChild("HarvestPlot")
local RE_SellAll     = Remotes:WaitForChild("SellAll")
local RE_BuySeed     = Remotes:WaitForChild("BuySeed")
local RE_UpdateUI    = Remotes:WaitForChild("UpdateUI")
local RF_GetSeeds    = Remotes:WaitForChild("GetSeeds")

-- ============================================================
--  STATE
-- ============================================================
local playerCoins     = 0
local playerInventory = {}
local playerPlots     = {}
local seedCatalog     = {}
local selectedSeed    = nil
local selectedPlot    = nil
local activeTab       = "Seeds"  -- Seeds | Garden | Sell

-- ============================================================
--  GUI BUILDING
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "FarmingUI"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = player.PlayerGui

-- Colours
local C = {
    bg        = Color3.fromRGB(20,  20,  20),
    panel     = Color3.fromRGB(35,  38,  30),
    green     = Color3.fromRGB(80,  180, 60),
    darkGreen = Color3.fromRGB(40,  110, 30),
    gold      = Color3.fromRGB(255, 200, 50),
    red       = Color3.fromRGB(220, 60,  60),
    blue      = Color3.fromRGB(60,  120, 220),
    white     = Color3.new(1, 1, 1),
    text      = Color3.fromRGB(230, 230, 220),
    dim       = Color3.fromRGB(120, 120, 110),
}

local function makeFrame(parent, name, size, pos, color, radius)
    local f = Instance.new("Frame")
    f.Name            = name
    f.Size            = size
    f.Position        = pos
    f.BackgroundColor3= color or C.panel
    f.BorderSizePixel = 0
    f.Parent          = parent
    if radius then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = f
    end
    return f
end

local function makeLabel(parent, text, size, pos, textColor, fontSize)
    local l = Instance.new("TextLabel")
    l.Size              = size
    l.Position          = pos
    l.Text              = text
    l.TextColor3        = textColor or C.text
    l.BackgroundTransparency = 1
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = fontSize or 14
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = parent
    return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor, radius)
    local b = Instance.new("TextButton")
    b.Size              = size
    b.Position          = pos
    b.Text              = text
    b.TextColor3        = textColor or C.white
    b.BackgroundColor3  = bgColor or C.green
    b.BorderSizePixel   = 0
    b.Font              = Enum.Font.GothamBold
    b.TextSize          = 13
    b.AutoButtonColor   = false
    b.Parent            = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = b
    -- Hover effect
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = bgColor and bgColor:Lerp(Color3.new(1,1,1), 0.15) or C.darkGreen
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            BackgroundColor3 = bgColor or C.green
        }):Play()
    end)
    return b
end

-- ============================================================
--  TOP BAR  (coins + timer display)
-- ============================================================
local topBar = makeFrame(screenGui, "TopBar",
    UDim2.new(1, 0, 0, 50),
    UDim2.new(0, 0, 0, 0),
    Color3.fromRGB(15, 60, 15), 0)

local coinIcon = makeLabel(topBar, "🪙", UDim2.new(0, 40, 1, 0), UDim2.new(0, 10, 0, 0), C.gold, 22)
local coinLabel = makeLabel(topBar, "0", UDim2.new(0, 150, 1, 0), UDim2.new(0, 48, 0, 0), C.gold, 20)
coinLabel.Name = "CoinLabel"

local titleLabel = makeLabel(topBar, "🌱 FARMING GAME", UDim2.new(0, 300, 1, 0),
    UDim2.new(0.5, -150, 0, 0), C.green, 18)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  TAB BUTTONS
-- ============================================================
local tabBar = makeFrame(screenGui, "TabBar",
    UDim2.new(0, 360, 0, 50),
    UDim2.new(0.5, -180, 0, 50),
    Color3.fromRGB(25, 50, 20), 10)

local tabs = {
    { name = "Seeds",  icon = "🌱", x = 0 },
    { name = "Garden", icon = "🌿", x = 0.333 },
    { name = "Sell",   icon = "💰", x = 0.666 },
}

local tabButtons = {}
for _, t in ipairs(tabs) do
    local btn = makeButton(tabBar, t.icon .. " " .. t.name,
        UDim2.new(0.333, -4, 1, -8),
        UDim2.new(t.x, 2, 0, 4),
        t.name == activeTab and C.green or Color3.fromRGB(50, 80, 40),
        C.white, 8)
    btn.Name = t.name .. "Tab"
    tabButtons[t.name] = btn
end

-- ============================================================
--  MAIN PANEL
-- ============================================================
local mainPanel = makeFrame(screenGui, "MainPanel",
    UDim2.new(0, 380, 0, 380),
    UDim2.new(0.5, -190, 0, 108),
    C.panel, 12)

-- ============================================================
--  SEEDS TAB
-- ============================================================
local seedsPanel = makeFrame(mainPanel, "SeedsPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(0,0,0), 0)
seedsPanel.BackgroundTransparency = 1

local seedTitle = makeLabel(seedsPanel, "🛒 Buy Seeds", UDim2.new(1, -20, 0, 28),
    UDim2.new(0, 10, 0, 8), C.green, 16)
seedTitle.TextXAlignment = Enum.TextXAlignment.Center

local seedScroll = Instance.new("ScrollingFrame")
seedScroll.Name               = "SeedScroll"
seedScroll.Size               = UDim2.new(1, -10, 1, -100)
seedScroll.Position           = UDim2.new(0, 5, 0, 40)
seedScroll.BackgroundTransparency = 1
seedScroll.BorderSizePixel    = 0
seedScroll.ScrollBarThickness = 4
seedScroll.ScrollBarImageColor3 = C.green
seedScroll.Parent             = seedsPanel

local seedList = Instance.new("UIListLayout")
seedList.Padding     = UDim.new(0, 6)
seedList.Parent      = seedScroll

-- Bottom buy controls
local buyQtyLabel = makeLabel(seedsPanel, "Qty: 1", UDim2.new(0, 80, 0, 30),
    UDim2.new(0, 10, 1, -38), C.text, 13)
buyQtyLabel.Name = "BuyQtyLabel"

local qtyMinus = makeButton(seedsPanel, "-", UDim2.new(0, 30, 0, 30),
    UDim2.new(0, 90, 1, -38), C.red, C.white, 6)
local qtyPlus = makeButton(seedsPanel, "+", UDim2.new(0, 30, 0, 30),
    UDim2.new(0, 125, 1, -38), C.green, C.white, 6)
local buyBtn = makeButton(seedsPanel, "BUY SEED", UDim2.new(0, 120, 0, 30),
    UDim2.new(1, -130, 1, -38), Color3.fromRGB(255, 180, 0), C.bg, 8)
buyBtn.Name = "BuyBtn"

local buyQty = 1
local function updateBuyQty(n)
    buyQty = math.max(1, math.min(99, n))
    buyQtyLabel.Text = "Qty: " .. buyQty
end

qtyMinus.MouseButton1Click:Connect(function() updateBuyQty(buyQty - 1) end)
qtyPlus.MouseButton1Click:Connect(function() updateBuyQty(buyQty + 1) end)

-- ============================================================
--  GARDEN TAB
-- ============================================================
local gardenPanel = makeFrame(mainPanel, "GardenPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(0,0,0), 0)
gardenPanel.BackgroundTransparency = 1
gardenPanel.Visible = false

local gardenTitle = makeLabel(gardenPanel, "🌿 Your Garden", UDim2.new(1, -20, 0, 28),
    UDim2.new(0, 10, 0, 8), C.green, 16)
gardenTitle.TextXAlignment = Enum.TextXAlignment.Center

-- 3x3 plot grid
local plotGrid = makeFrame(gardenPanel, "PlotGrid",
    UDim2.new(1, -20, 1, -90),
    UDim2.new(0, 10, 0, 42),
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
        Color3.fromRGB(100, 70, 40), C.text, 8)
    pb.Name       = "Plot_" .. i
    pb.TextSize   = 11
    pb.Font       = Enum.Font.Gotham
    plotButtons[i] = pb
end

-- Seed selector dropdown for planting
local plantSeedLabel = makeLabel(gardenPanel, "Select seed to plant:", UDim2.new(0.5, -10, 0, 22),
    UDim2.new(0, 10, 1, -45), C.dim, 12)
local plantSeedScroll = Instance.new("ScrollingFrame")
plantSeedScroll.Name               = "PlantSeedScroll"
plantSeedScroll.Size               = UDim2.new(0.5, -10, 0, 32)
plantSeedScroll.Position           = UDim2.new(0, 10, 1, -36)
plantSeedScroll.BackgroundColor3   = Color3.fromRGB(30, 50, 25)
plantSeedScroll.BorderSizePixel    = 0
plantSeedScroll.ScrollBarThickness = 3
plantSeedScroll.Parent             = gardenPanel

local plantList = Instance.new("UIListLayout")
plantList.FillDirection = Enum.FillDirection.Horizontal
plantList.Padding       = UDim.new(0, 4)
plantList.Parent        = plantSeedScroll

local plantBtn = makeButton(gardenPanel, "🌱 PLANT",
    UDim2.new(0.45, -10, 0, 32),
    UDim2.new(0.55, 0, 1, -38),
    C.green, C.white, 8)
plantBtn.Name = "PlantBtn"

-- ============================================================
--  SELL TAB
-- ============================================================
local sellPanel = makeFrame(mainPanel, "SellPanel",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(0,0,0), 0)
sellPanel.BackgroundTransparency = 1
sellPanel.Visible = false

local sellTitle = makeLabel(sellPanel, "💰 Sell Crops", UDim2.new(1, -20, 0, 28),
    UDim2.new(0, 10, 0, 8), C.green, 16)
sellTitle.TextXAlignment = Enum.TextXAlignment.Center

local inventoryScroll = Instance.new("ScrollingFrame")
inventoryScroll.Name               = "InventoryScroll"
inventoryScroll.Size               = UDim2.new(1, -10, 1, -110)
inventoryScroll.Position           = UDim2.new(0, 5, 0, 40)
inventoryScroll.BackgroundTransparency = 1
inventoryScroll.BorderSizePixel    = 0
inventoryScroll.ScrollBarThickness = 4
inventoryScroll.ScrollBarImageColor3 = C.gold
inventoryScroll.Parent             = sellPanel

local invList = Instance.new("UIListLayout")
invList.Padding = UDim.new(0, 6)
invList.Parent  = inventoryScroll

local totalValueLabel = makeLabel(sellPanel, "Total Value: 🪙0",
    UDim2.new(1, -20, 0, 24),
    UDim2.new(0, 10, 1, -60), C.gold, 15)
totalValueLabel.Name = "TotalValueLabel"
totalValueLabel.TextXAlignment = Enum.TextXAlignment.Center

local sellAllBtn = makeButton(sellPanel, "💰 SELL ALL CROPS",
    UDim2.new(1, -20, 0, 38),
    UDim2.new(0, 10, 1, -44),
    Color3.fromRGB(220, 160, 0), C.bg, 10)
sellAllBtn.TextSize = 16

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================
local notifFrame = makeFrame(screenGui, "Notif",
    UDim2.new(0, 260, 0, 44),
    UDim2.new(0.5, -130, 0, 500),
    Color3.fromRGB(30, 80, 30), 10)
notifFrame.Visible = false

local notifLabel = makeLabel(notifFrame, "",
    UDim2.new(1, -10, 1, 0),
    UDim2.new(0, 5, 0, 0),
    C.white, 13)
notifLabel.TextXAlignment = Enum.TextXAlignment.Center

local notifActive = false
local function showNotif(text, color)
    notifFrame.BackgroundColor3 = color or Color3.fromRGB(30, 80, 30)
    notifLabel.Text = text
    notifFrame.Visible = true
    TweenService:Create(notifFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -130, 1, -70)
    }):Play()
    task.delay(2, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, -130, 1, 20)
        }):Play()
        task.delay(0.4, function()
            notifFrame.Visible = false
        end)
    end)
end

-- ============================================================
--  TAB SWITCHING
-- ============================================================
local panels = {
    Seeds  = seedsPanel,
    Garden = gardenPanel,
    Sell   = sellPanel,
}

local function switchTab(name)
    activeTab = name
    for tabName, panel in pairs(panels) do
        panel.Visible = (tabName == name)
        local btn = tabButtons[tabName]
        if btn then
            btn.BackgroundColor3 = (tabName == name)
                and C.green
                or Color3.fromRGB(50, 80, 40)
        end
    end
end

for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
end

-- ============================================================
--  POPULATE SEED SHOP
-- ============================================================
local seedCards = {}  -- { name, card }

local function buildSeedShop(seeds)
    for _, child in ipairs(seedScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    seedCards = {}

    for seedName, info in pairs(seeds) do
        local card = makeFrame(seedScroll, seedName,
            UDim2.new(1, -8, 0, 54),
            UDim2.new(0, 0, 0, 0),
            Color3.fromRGB(40, 55, 30), 8)

        -- Color bar on left
        local bar = makeFrame(card, "Bar",
            UDim2.new(0, 6, 1, 0),
            UDim2.new(0, 0, 0, 0),
            info.color, 3)

        local nameL = makeLabel(card, seedName,
            UDim2.new(0.5, 0, 0, 20),
            UDim2.new(0, 14, 0, 4),
            C.white, 14)

        local infoL = makeLabel(card,
            "⏱ " .. info.growTime .. "s  |  Sell: 🪙" .. info.sellPrice,
            UDim2.new(0.6, 0, 0, 18),
            UDim2.new(0, 14, 0, 26),
            C.dim, 11)

        local priceL = makeLabel(card,
            "🪙 " .. info.price .. " each",
            UDim2.new(0.4, -10, 0, 20),
            UDim2.new(0.6, 5, 0, 4),
            C.gold, 13)

        -- Select button
        local selBtn = makeButton(card, "SELECT",
            UDim2.new(0.3, -10, 0, 22),
            UDim2.new(0.7, 0, 0, 26),
            C.darkGreen, C.white, 6)
        selBtn.TextSize = 11

        selBtn.MouseButton1Click:Connect(function()
            selectedSeed = seedName
            -- Highlight selected
            for _, sc in ipairs(seedCards) do
                sc.card.BackgroundColor3 = Color3.fromRGB(40, 55, 30)
            end
            card.BackgroundColor3 = Color3.fromRGB(60, 90, 40)
            buyBtn.Text = "BUY " .. seedName:upper()
        end)

        table.insert(seedCards, { name = seedName, card = card })
    end

    seedScroll.CanvasSize = UDim2.new(0, 0, 0, seedList.AbsoluteContentSize.Y + 10)
end

-- ============================================================
--  UPDATE GARDEN PLOTS
-- ============================================================
local function updateGardenUI(plots)
    playerPlots = plots or playerPlots
    for i, plot in ipairs(playerPlots) do
        local pb = plotButtons[i]
        if not pb then continue end

        if plot.state == "empty" then
            pb.BackgroundColor3 = Color3.fromRGB(100, 70, 40)
            pb.Text = "Plot " .. i .. "\n[Empty]"
            pb.TextColor3 = C.dim

        elseif plot.state == "growing" then
            pb.BackgroundColor3 = Color3.fromRGB(60, 100, 50)
            local elapsed   = os.time() - (plot.plantedAt or os.time())
            local info      = seedCatalog[plot.seed]
            local remaining = info and math.max(0, info.growTime - elapsed) or 0
            pb.Text = "🌱 " .. (plot.seed or "?") .. "\n⏳ " .. remaining .. "s"
            pb.TextColor3 = C.text

        elseif plot.state == "ready" then
            pb.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
            pb.Text = "✅ " .. (plot.seed or "?") .. "\n[HARVEST!]"
            pb.TextColor3 = C.white
        end
    end
end

-- Garden plot click
for i, pb in ipairs(plotButtons) do
    pb.MouseButton1Click:Connect(function()
        local plot = playerPlots[i]
        if not plot then return end

        if plot.state == "ready" then
            RE_HarvestPlot:FireServer(i)
            showNotif("🌾 Harvested " .. (plot.seed or "crop") .. "!", C.green)

        elseif plot.state == "empty" then
            if not selectedPlot then
                selectedPlot = i
                pb.BackgroundColor3 = Color3.fromRGB(80, 130, 60)
                showNotif("Plot " .. i .. " selected! Pick a seed below.", C.darkGreen)
            else
                selectedPlot = nil
            end

        elseif plot.state == "growing" then
            showNotif("Still growing... ⏳", Color3.fromRGB(80, 80, 30))
        end
    end)
end

-- Plant button
plantBtn.MouseButton1Click:Connect(function()
    if not selectedSeed then
        showNotif("❌ Pick a seed first!", C.red)
        return
    end
    if not selectedPlot then
        showNotif("❌ Select a plot first!", C.red)
        return
    end
    local inv = playerInventory[selectedSeed] or 0
    if inv <= 0 then
        showNotif("❌ No " .. selectedSeed .. " seeds!", C.red)
        return
    end
    RE_PlantSeed:FireServer(selectedPlot, selectedSeed)
    showNotif("🌱 Planted " .. selectedSeed .. " in Plot " .. selectedPlot, C.green)
    selectedPlot = nil
end)

-- ============================================================
--  UPDATE SELL TAB
-- ============================================================
local function updateSellUI(inventory, seeds)
    for _, child in ipairs(inventoryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local total = 0
    local hasItems = false

    for cropName, count in pairs(inventory) do
        if count and count > 0 then
            local info = seeds[cropName]
            if not info then continue end
            hasItems = true
            local value = info.sellPrice * count
            total = total + value

            local row = makeFrame(inventoryScroll, cropName,
                UDim2.new(1, -8, 0, 44),
                UDim2.new(0, 0, 0, 0),
                Color3.fromRGB(40, 55, 30), 8)

            local cbar = makeFrame(row, "Bar",
                UDim2.new(0, 5, 1, 0),
                UDim2.new(0, 0, 0, 0),
                info.color, 3)

            makeLabel(row, cropName, UDim2.new(0.4, 0, 0, 20),
                UDim2.new(0, 12, 0, 4), C.white, 13)
            makeLabel(row, "x" .. count, UDim2.new(0.2, 0, 0, 20),
                UDim2.new(0.4, 0, 0, 4), C.text, 13)
            makeLabel(row, "🪙 " .. value, UDim2.new(0.35, -10, 0, 20),
                UDim2.new(0.65, 5, 0, 4), C.gold, 13)
            makeLabel(row, "(" .. info.sellPrice .. " each)", UDim2.new(0.4, 0, 0, 16),
                UDim2.new(0.12, 0, 0, 24), C.dim, 11)
        end
    end

    if not hasItems then
        makeLabel(inventoryScroll, "No crops to sell.\nGrow some first! 🌱",
            UDim2.new(1, -10, 0, 60),
            UDim2.new(0, 5, 0, 10),
            C.dim, 13).TextXAlignment = Enum.TextXAlignment.Center
    end

    inventoryScroll.CanvasSize = UDim2.new(0, 0, 0, invList.AbsoluteContentSize.Y + 10)
    totalValueLabel.Text = "Total Value: 🪙" .. total

    sellAllBtn.Active = hasItems
    sellAllBtn.BackgroundColor3 = hasItems
        and Color3.fromRGB(220, 160, 0)
        or  Color3.fromRGB(80, 80, 60)
end

-- Plant seed inventory buttons in Garden tab
local plantSeedBtns = {}
local function updatePlantSeedButtons(inventory)
    for _, b in ipairs(plantSeedBtns) do b:Destroy() end
    plantSeedBtns = {}
    for seedName, count in pairs(inventory) do
        if count and count > 0 then
            local b = makeButton(plantSeedScroll, seedName .. " x" .. count,
                UDim2.new(0, 90, 0, 28),
                UDim2.new(0,0,0,0),
                Color3.fromRGB(50, 90, 40), C.white, 6)
            b.TextSize = 11
            b.MouseButton1Click:Connect(function()
                selectedSeed = seedName
                for _, sb in ipairs(plantSeedBtns) do
                    sb.BackgroundColor3 = Color3.fromRGB(50, 90, 40)
                end
                b.BackgroundColor3 = C.green
                showNotif("Selected: " .. seedName, C.darkGreen)
            end)
            table.insert(plantSeedBtns, b)
        end
    end
    plantSeedScroll.CanvasSize = UDim2.new(0, plantList.AbsoluteContentSize.X + 10, 0, 0)
end

-- Sell all button
sellAllBtn.MouseButton1Click:Connect(function()
    local hasItems = false
    for _, v in pairs(playerInventory) do if v > 0 then hasItems = true break end end
    if not hasItems then
        showNotif("Nothing to sell!", C.red)
        return
    end
    RE_SellAll:FireServer()
    showNotif("💰 Sold all crops!", Color3.fromRGB(180, 130, 0))
end)

-- Buy button
buyBtn.MouseButton1Click:Connect(function()
    if not selectedSeed then
        showNotif("❌ Select a seed first!", C.red)
        return
    end
    local info = seedCatalog[selectedSeed]
    if not info then return end
    local cost = info.price * buyQty
    if cost > playerCoins then
        showNotif("❌ Not enough coins! Need 🪙" .. cost, C.red)
        return
    end
    RE_BuySeed:FireServer(selectedSeed, buyQty)
    showNotif("✅ Bought " .. buyQty .. "x " .. selectedSeed, C.green)
end)

-- ============================================================
--  RECEIVE SERVER UPDATES
-- ============================================================
RE_UpdateUI.OnClientEvent:Connect(function(data)
    playerCoins     = data.coins     or 0
    playerInventory = data.inventory or {}
    playerPlots     = data.plots     or {}
    seedCatalog     = data.seeds     or seedCatalog

    -- Update coin label
    local coinsDisplay = playerCoins >= 1000
        and string.format("%.2fK", playerCoins / 1000)
        or  tostring(playerCoins)
    coinLabel.Text = coinsDisplay .. "¢"

    -- Rebuild seed shop if needed
    if not next(seedCards) then
        buildSeedShop(seedCatalog)
    end

    updateGardenUI(playerPlots)
    updateSellUI(playerInventory, seedCatalog)
    updatePlantSeedButtons(playerInventory)
end)

-- ============================================================
--  GARDEN TIMER LOOP  (updates countdown every second locally)
-- ============================================================
task.spawn(function()
    while true do
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
    task.wait(2)
    local seeds = RF_GetSeeds:InvokeServer()
    if seeds then
        seedCatalog = seeds
        buildSeedShop(seeds)
    end
end)

print("✅ Farming GUI loaded!")
