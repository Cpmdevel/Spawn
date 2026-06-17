--[[
    GROW A GARDEN 2 – ULTIMATE AUTO‑FARM (STEALTH EDITION)
    - No GUI, no chat spam, no visible changes.
    - Auto‑detects remotes, leaderstats, buttons, and collectibles.
    - Uses low‑frequency loops to avoid rate‑limiting.
    - Works with Delta Executor (mobile) and all modern executors.
    - Updated: June 2026 – adapts to common game updates.
]]

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualUser = (syn and syn.request) and syn  -- for advanced input if needed

-- ===== CONFIGURATION =====
local CONFIG = {
    LeaderstatCash = true,      -- Try to set leaderstats cash
    ClickGenerate = true,       -- Auto‑click the "Generate" button
    SpamRemotes = true,         -- Fire all possible remotes with money arguments
    AutoCollect = true,         -- Click on crops/collectables
    AutoPlant = true,           -- Click on plots to plant seeds
    AutoBuy = true,             -- Click on buy/upgrade buttons
    ClickDelay = 0.3,           -- Delay between clicks (increase if throttled)
    RemoteDelay = 0.5,          -- Delay between remote spam
    CollectDelay = 0.5,
    PlantDelay = 1.0,
    BuyDelay = 0.4,
}

-- ===== UTILITY FUNCTIONS =====
local function findFirstDescendant(parent, className, predicate)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA(className) and (not predicate or predicate(obj)) then
            return obj
        end
    end
    return nil
end

local function findAllDescendants(parent, className, predicate)
    local list = {}
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA(className) and (not predicate or predicate(obj)) then
            table.insert(list, obj)
        end
    end
    return list
end

-- ===== 1. LEADERSTATS OVERWRITE =====
local function leaderstatHack()
    if not CONFIG.LeaderstatCash then return false end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return false end
    local cash = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Cash") or ls:FindFirstChild("Money")
    if cash and (cash:IsA("IntValue") or cash:IsA("NumberValue")) then
        spawn(function()
            while true do
                cash.Value = 999999999
                wait(0.1)
            end
        end)
        return true
    end
    return false
end

-- ===== 2. AUTO‑CLICK GENERATE BUTTON =====
local function clickGenerate()
    if not CONFIG.ClickGenerate then return false end
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return false end
    local btn = findFirstDescendant(gui, "TextButton", function(b)
        local n = b.Name:lower()
        local t = (b.Text or ""):lower()
        return n:find("generate") or n:find("gen") or t:find("generate") or t:find("gen")
    end)
    if not btn then return false end
    spawn(function()
        while true do
            pcall(btn.Click, btn)
            wait(CONFIG.ClickDelay)
        end
    end)
    return true
end

-- ===== 3. REMOTE SPAM (smart injection) =====
local function spamRemotes()
    if not CONFIG.SpamRemotes then return false end
    local remotes = findAllDescendants(replicatedStorage, "RemoteEvent")
    local functions = findAllDescendants(replicatedStorage, "RemoteFunction")
    if #remotes == 0 and #functions == 0 then return false end

    -- Common argument patterns used in farming games
    local argsList = {
        {"Generate"},
        {"collect", 999999},
        {"addMoney", 999999},
        {"GetMoney", 999999},
        {"Claim", "all"},
        {"Click"},
        {"Buy", "Sheckles", 999999},
        {"Multiplier", 999999},
        {"Harvest", "all"},
        {"Sell", "all"},
        {"AutoCollect", true},
    }

    spawn(function()
        while true do
            for _, remote in ipairs(remotes) do
                for _, args in ipairs(argsList) do
                    pcall(remote.FireServer, remote, table.unpack(args))
                end
            end
            for _, func in ipairs(functions) do
                for _, args in ipairs(argsList) do
                    pcall(func.InvokeServer, func, table.unpack(args))
                end
            end
            wait(CONFIG.RemoteDelay)
        end
    end)
    return true
end

-- ===== 4. AUTO‑COLLECT CROPS =====
local function autoCollect()
    if not CONFIG.AutoCollect then return end
    spawn(function()
        while true do
            -- Search workspace for clickable objects with crop/plant names
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Part") then
                    local name = obj.Name:lower()
                    if name:find("crop") or name:find("plant") or name:find("tree") or name:find("collect") or name:find("harvest") or name:find("seed") then
                        -- Try ClickDetector
                        local cd = obj:FindFirstChild("ClickDetector")
                        if cd and cd:IsA("ClickDetector") then
                            pcall(cd.Click, cd)
                        end
                        -- Try ProximityPrompt
                        local pp = obj:FindFirstChild("ProximityPrompt")
                        if pp and pp:IsA("ProximityPrompt") then
                            pcall(pp.InputHoldStart, pp)
                            wait(0.1)
                            pcall(pp.InputHoldEnd, pp)
                        end
                    end
                end
            end
            wait(CONFIG.CollectDelay)
        end
    end)
end

-- ===== 5. AUTO‑PLANT SEEDS =====
local function autoPlant()
    if not CONFIG.AutoPlant then return end
    spawn(function()
        while true do
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Part") then
                    local name = obj.Name:lower()
                    if name:find("plot") or name:find("soil") or name:find("garden") or name:find("pot") then
                        local cd = obj:FindFirstChild("ClickDetector")
                        if cd and cd:IsA("ClickDetector") then
                            pcall(cd.Click, cd)
                        end
                        local pp = obj:FindFirstChild("ProximityPrompt")
                        if pp and pp:IsA("ProximityPrompt") then
                            pcall(pp.InputHoldStart, pp)
                            wait(0.1)
                            pcall(pp.InputHoldEnd, pp)
                        end
                    end
                end
            end
            wait(CONFIG.PlantDelay)
        end
    end)
end

-- ===== 6. AUTO‑BUY UPGRADES =====
local function autoBuy()
    if not CONFIG.AutoBuy then return end
    spawn(function()
        while true do
            local gui = player:FindFirstChild("PlayerGui")
            if gui then
                for _, btn in ipairs(findAllDescendants(gui, "TextButton")) do
                    local t = (btn.Text or ""):lower()
                    if t:find("buy") or t:find("upgrade") or t:find("purchase") or t:find("unlock") then
                        pcall(btn.Click, btn)
                        wait(CONFIG.BuyDelay)
                    end
                end
            end
            wait(1)
        end
    end)
end

-- ===== EXECUTION =====
local status = {
    Leaderstat = leaderstatHack(),
    Generate = clickGenerate(),
    Remotes = spamRemotes(),
}
autoCollect()
autoPlant()
autoBuy()

-- Silent feedback (no prints unless you remove comment)
-- print("[GAG2] Status: Leaderstat=" .. tostring(status.Leaderstat) .. " Generate=" .. tostring(status.Generate) .. " Remotes=" .. tostring(status.Remotes))
-- print("[GAG2] Auto‑farm running in stealth mode.")

-- Keep the script alive (prevents executor from closing)
while true do wait(1) end