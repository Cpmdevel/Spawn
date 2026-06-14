-- Grow a Garden 2 - Ultimate Spawner Script (No Key)
-- Features: Spawn Pets, Spawn Seeds, Auto Farm, Dupe Seeds, Infinite Sheckles, Auto Steal, Auto Plant
-- Works on most Roblox executors (Synapse X, Krnl, Delta, etc.)
-- Video Reference: GROW A GARDEN 2 | NEW SCRIPT RELEASE | SPAWNER SCRIPT NO KEY

local player = game:GetService("Players").LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenSpawnerGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 480)
frame.Position = UDim2.new(0.5, -160, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
title.Text = "🌱 Grow a Garden 2 | Spawner"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local function createButton(name, text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 25)
statusLabel.Position = UDim2.new(0.05, 0, 0, 445)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "✅ Script Loaded | No Key Required"
statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Parent = frame

local function updateStatus(msg)
    statusLabel.Text = msg
    print("[Garden Script] " .. msg)
end

-- ==================== SPAWN SEED ====================
-- All seeds available in Grow a Garden 2 (Common to Super)
local seedsList = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple", "Bamboo",
    "Corn", "Cactus", "Pineapple", "Mushroom", "Banana", "Grape", "Coconut",
    "DragonFruit", "Acorn", "Moon Bloom", "Dragon's Breath"
}

local function spawnSeed(seedName)
    updateStatus("Spawning seed: " .. seedName)
    -- Method 1: Try to fire remote (most common in new updates)
    local spawnRemote = replicatedStorage:FindFirstChild("GiveSeed") 
        or replicatedStorage:FindFirstChild("AddItem")
        or replicatedStorage:FindFirstChild("SpawnSeed")
    if spawnRemote then
        spawnRemote:FireServer(seedName)
        updateStatus("✅ Spawned " .. seedName .. " seed!")
        return
    end
    -- Method 2: Create tool directly in backpack
    local seedTool = Instance.new("Tool")
    seedTool.Name = seedName .. "_Seed"
    seedTool.RequiresHandle = false
    seedTool:SetAttribute("Type", "Seed")
    seedTool:SetAttribute("SeedName", seedName)
    seedTool:SetAttribute("GrowthTime", 0.3)  -- Fast growth for spawned seeds
    seedTool:SetAttribute("YieldMultiplier", 10)
    seedTool.Parent = player.Backpack
    updateStatus("✅ " .. seedName .. " seed added to backpack!")
end

-- Spawn OP Seed (Mythic/Super rarity)
local function spawnOpSeed()
    local opNames = {"Dragon's Breath", "Moon Bloom", "Golden Dragonfruit", "Cursed Pumpkin", "Starfall Seed"}
    local selected = opNames[math.random(1, #opNames)]
    local opSeed = Instance.new("Tool")
    opSeed.Name = selected .. "_OP_Seed"
    opSeed.RequiresHandle = false
    opSeed:SetAttribute("Type", "Seed")
    opSeed:SetAttribute("Rarity", "Mythic")
    opSeed:SetAttribute("GrowthTime", 0.05)
    opSeed:SetAttribute("YieldMultiplier", 100)
    opSeed:SetAttribute("ValueMultiplier", 1000)
    opSeed.Parent = player.Backpack
    updateStatus("✨ OP Mythic Seed spawned: " .. selected)
end

-- ==================== SPAWN PET ====================
-- All pets available in Grow a Garden 2 (Common to Super)
local petsList = {
    -- Common
    "Frog", "Bunny",
    -- Uncommon
    "Owl", "Big Owl",
    -- Rare
    "Deer",
    -- Legendary
    "Robin", "Bee",
    -- Mythic
    "Monkey", "Golden Dragonfly", "Unicorn",
    -- Super
    "Raccoon", "Black Dragon", "Ice Serpent"
}

local function spawnPet(petName)
    updateStatus("Spawning pet: " .. petName)
    -- Try remote first
    local petRemote = replicatedStorage:FindFirstChild("SummonPet") 
        or replicatedStorage:FindFirstChild("GetPet")
        or replicatedStorage:FindFirstChild("SpawnPet")
    if petRemote then
        petRemote:FireServer(petName)
        updateStatus("🐾 Pet spawned: " .. petName)
        return
    end
    -- Alternative: create a physical pet model that follows player
    local petModel = Instance.new("Model")
    petModel.Name = petName .. "_Pet"
    petModel.Parent = workspace
    
    local petPart = Instance.new("Part")
    petPart.Size = Vector3.new(1.2, 1.2, 1.2)
    petPart.Shape = Enum.PartType.Ball
    petPart.BrickColor = BrickColor.random()
    petPart.Material = Enum.Material.Neon
    petPart.Parent = petModel
    
    local followBodyPos = Instance.new("BodyPosition")
    followBodyPos.MaxForce = Vector3.new(5000, 5000, 5000)
    followBodyPos.P = 3000
    followBodyPos.D = 500
    followBodyPos.Parent = petPart
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local offset = Vector3.new(3, 1, 3)
            followBodyPos.Position = root.Position + offset
            petPart.CFrame = petPart.CFrame * CFrame.Angles(0, 0.05, 0)
        end
    end)
    
    updateStatus("🐾 Custom pet spawned: " .. petName .. " (follows you)")
end

-- ==================== AUTO FARM ====================
local autoFarmEnabled = false
local farmConnection

local function autoFarm()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        updateStatus("🚜 Auto Farm ENABLED")
        farmConnection = runService.Heartbeat:Connect(function()
            -- Find all garden plots
            for _, plot in pairs(workspace:GetDescendants()) do
                if plot:IsA("Model") and plot.Name:find("Plot") then
                    -- Harvest if ready
                    local harvestRemote = replicatedStorage:FindFirstChild("Harvest")
                    if harvestRemote and plot:FindFirstChild("IsReady") and plot.IsReady.Value == true then
                        harvestRemote:FireServer(plot)
                        task.wait(0.2)
                    end
                    -- Auto plant if empty
                    local plantRemote = replicatedStorage:FindFirstChild("PlantSeed")
                    if plantRemote and plot:FindFirstChild("IsEmpty") and plot.IsEmpty.Value == true then
                        local seed = player.Backpack:FindFirstChildWhichIsA("Tool")
                        if seed and seed:GetAttribute("Type") == "Seed" then
                            plantRemote:FireServer(plot, seed)
                            task.wait(0.3)
                        end
                    end
                    -- Auto water
                    local waterRemote = replicatedStorage:FindFirstChild("Water")
                    if waterRemote and plot:FindFirstChild("NeedsWater") and plot.NeedsWater.Value == true then
                        waterRemote:FireServer(plot)
                        task.wait(0.1)
                    end
                end
            end
        end)
    else
        updateStatus("🚜 Auto Farm DISABLED")
        if farmConnection then farmConnection:Disconnect() end
    end
end

-- ==================== DUPE SEED ====================
local function dupeSeed()
    updateStatus("Attempting to duplicate seed...")
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        updateStatus("❌ Backpack not found.")
        return
    end
    -- Find a seed tool in backpack
    local seed = nil
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("seed") or tool:GetAttribute("Type") == "Seed") then
            seed = tool
            break
        end
    end
    if not seed then
        updateStatus("❌ No seed found in backpack.")
        return
    end
    -- Duplicate by cloning (works in most cases)
    local dupeRemote = replicatedStorage:FindFirstChild("DuplicateItem")
    if dupeRemote then
        dupeRemote:FireServer(seed.Name)
    else
        local clone = seed:Clone()
        clone.Parent = backpack
    end
    updateStatus("✅ Duplicated: " .. seed.Name)
end

-- ==================== INFINITE SHECKLES ====================
local function infiniteSheckles()
    updateStatus("💰 Enabling INF Sheckles...")
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local sheckles = leaderstats:FindFirstChild("Sheckles")
        if sheckles then
            sheckles:SetReadOnly(false)
            runService.Stepped:Connect(function()
                if sheckles and sheckles.Value < 999999999 then
                    sheckles.Value = 999999999
                end
            end)
            updateStatus("💰 INF Sheckles enabled! (999M)")
        else
            updateStatus("❌ Sheckles not found.")
        end
    else
        updateStatus("❌ leaderstats not found.")
    end
end

-- ==================== AUTO STEAL ====================
local autoStealEnabled = false
local stealConnection

local function autoSteal()
    autoStealEnabled = not autoStealEnabled
    if autoStealEnabled then
        updateStatus("👤 Auto Steal ENABLED")
        stealConnection = runService.Heartbeat:Connect(function()
            for _, plot in ipairs(workspace:GetDescendants()) do
                if plot:IsA("Model") and plot.Name:find("Plot") and plot:FindFirstChild("Owner") then
                    local owner = plot.Owner.Value
                    if owner ~= player.Name and plot:FindFirstChild("Fruit") then
                        local stealRemote = replicatedStorage:FindFirstChild("Steal") or replicatedStorage:FindFirstChild("Harvest")
                        if stealRemote then
                            stealRemote:FireServer(plot)
                        end
                        task.wait(0.5)
                    end
                end
            end
        end)
    else
        updateStatus("👤 Auto Steal DISABLED")
        if stealConnection then stealConnection:Disconnect() end
    end
end

-- ==================== AUTO PLANT ====================
local autoPlantEnabled = false
local plantConnection

local function autoPlant()
    autoPlantEnabled = not autoPlantEnabled
    if autoPlantEnabled then
        updateStatus("🌱 Auto Plant ENABLED")
        plantConnection = runService.Heartbeat:Connect(function()
            for _, plot in ipairs(workspace:GetDescendants()) do
                if plot:IsA("Model") and plot.Name:find("Plot") and plot:FindFirstChild("IsEmpty") and plot.IsEmpty.Value == true then
                    local seed = player.Backpack:FindFirstChildWhichIsA("Tool")
                    if seed and (seed.Name:lower():find("seed") or seed:GetAttribute("Type") == "Seed") then
                        local plantRemote = replicatedStorage:FindFirstChild("PlantSeed")
                        if plantRemote then
                            plantRemote:FireServer(plot, seed)
                        else
                            seed.Parent = plot
                            plot.IsEmpty.Value = false
                        end
                        task.wait(0.5)
                    end
                end
            end
        end)
    else
        updateStatus("🌱 Auto Plant DISABLED")
        if plantConnection then plantConnection:Disconnect() end
    end
end

-- ==================== GUI BUTTONS ====================
local y = 45
createButton("SpawnCarrot", "🥕 Spawn Carrot Seed", y, function() spawnSeed("Carrot") end)
createButton("SpawnDragon", "🐉 Spawn Dragon Fruit Seed", y+42, function() spawnSeed("DragonFruit") end)
createButton("SpawnMythic", "✨ Spawn OP Mythic Seed", y+84, spawnOpSeed)
createButton("SpawnRandomSeed", "🎲 Spawn Random Seed", y+126, function()
    local randomSeed = seedsList[math.random(1, #seedsList)]
    spawnSeed(randomSeed)
end)
createButton("SpawnFrog", "🐸 Spawn Frog Pet", y+168, function() spawnPet("Frog") end)
createButton("SpawnDragonPet", "🐉 Spawn Dragon Pet", y+210, function() spawnPet("Black Dragon") end)
createButton("SpawnRandomPet", "🦄 Spawn Random Pet", y+252, function()
    local randomPet = petsList[math.random(1, #petsList)]
    spawnPet(randomPet)
end)
createButton("AutoFarm", "🚜 Toggle Auto Farm", y+294, autoFarm)
createButton("AutoSteal", "👤 Toggle Auto Steal", y+336, autoSteal)
createButton("DupeSeed", "🔄 Dupe Seed", y+378, dupeSeed)
createButton("InfSheckles", "💰 INF Sheckles", y+420, infiniteSheckles)
createButton("AutoPlant", "🌱 Toggle Auto Plant", y+462, autoPlant)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    if farmConnection then farmConnection:Disconnect() end
    if stealConnection then stealConnection:Disconnect() end
    if plantConnection then plantConnection:Disconnect() end
end)

-- Chat commands (type in Roblox chat)
local function onChat(msg)
    local lowerMsg = msg:lower()
    if lowerMsg:sub(1,6) == ";seed " then
        local seedName = msg:sub(7)
        spawnSeed(seedName)
    elseif lowerMsg:sub(1,5) == ";pet " then
        local petName = msg:sub(6)
        spawnPet(petName)
    elseif lowerMsg == ";opseed" then
        spawnOpSeed()
    elseif lowerMsg == ";dupe" then
        dupeSeed()
    elseif lowerMsg == ";money" then
        infiniteSheckles()
    elseif lowerMsg == ";autofarm" then
        autoFarm()
    end
end
game:GetService("Players").LocalPlayer.Chatted:Connect(onChat)

updateStatus("✅ Script loaded! Use GUI buttons or chat commands: ;seed [name], ;pet [name], ;opseed, ;dupe, ;money, ;autofarm")