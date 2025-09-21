-- =============================================
-- AUTO FRIEND & UI SYSTEM FOR ROBLOX
-- Organized and optimized version
-- =============================================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local FriendService = game:GetService("FriendService")

-- Player references
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================
-- CONFIGURATION SETTINGS
-- =============================================
local Config = {
    -- Friend System Settings
    AutoAcceptFriends = true,
    AutoAddFriends = false,
    AddFriendsCooldown = 10,
    
    -- UI Settings
    UIVisible = true,
    CheckInterval = 1,
    
    -- FPS Booster Settings (optional)
    EnableFPSBooster = true
}

-- =============================================
-- FPS BOOSTER (OPTIONAL)
-- =============================================
if Config.EnableFPSBooster then
    _G.Settings = {
        Players = {
            ["Ignore Me"] = true,
            ["Ignore Others"] = true
        },
        Meshes = {
            Destroy = true,
            LowDetail = true
        },
        Images = {
            Invisible = true,
            LowDetail = true,
            Destroy = true,
        },
        ["No Particles"] = true,
        ["No Camera Effects"] = true,
        ["No Explosions"] = true,
        ["No Clothes"] = true,
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true
    }
    
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
    end)
end

-- =============================================
-- UI CREATION FUNCTION
-- =============================================
local function createUI()
    -- GUI utama
    local gui = Instance.new("ScreenGui")
    gui.Name = "BlackScreenUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    -- Background hitam + konten
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Visible = Config.UIVisible
    frame.Parent = gui

    -- Container utama di tengah
    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0, 400, 0, 300)
    container.BackgroundTransparency = 1
    container.Parent = frame

    -- Gambar profile
    local profile = Instance.new("ImageLabel")
    profile.Size = UDim2.new(0, 100, 0, 100)
    profile.Position = UDim2.new(0.5, -50, 0, 0)
    profile.BackgroundTransparency = 1
    profile.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=100&height=100&format=png"
    profile.Parent = container

    -- Nama player
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 40)
    nameLabel.Position = UDim2.new(0, 0, 0, 110)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 24
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Parent = container

    -- Level player
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0, 30)
    levelLabel.Position = UDim2.new(0, 0, 0, 150)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level: ..."
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextSize = 20
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    levelLabel.Parent = container

    -- Uang player
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, 0, 0, 30)
    moneyLabel.Position = UDim2.new(0, 0, 0, 180)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "Money: ..."
    moneyLabel.Font = Enum.Font.Gotham
    moneyLabel.TextSize = 20
    moneyLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    moneyLabel.Parent = container

    -- FPS + Ping
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 0, 30)
    statsLabel.Position = UDim2.new(0, 0, 0, 210)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "FPS: ... | Ping: ..."
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 20
    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
    statsLabel.Parent = container

    -- Tombol On/Off (SELALU DI ATAS)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 40)
    button.AnchorPoint = Vector2.new(0.5, 1)
    button.Position = UDim2.new(0.5, 0, 1, -20)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Text = Config.UIVisible and "Turn OFF" or "Turn ON"
    button.Parent = gui

    return {
        GUI = gui,
        Frame = frame,
        LevelLabel = levelLabel,
        MoneyLabel = moneyLabel,
        StatsLabel = statsLabel,
        ToggleButton = button
    }
end

-- =============================================
-- UI UPDATE FUNCTIONS
-- =============================================
local function setupUIUpdates(uiElements)
    -- Toggle fungsi
    uiElements.ToggleButton.MouseButton1Click:Connect(function()
        Config.UIVisible = not Config.UIVisible
        uiElements.Frame.Visible = Config.UIVisible
        uiElements.ToggleButton.Text = Config.UIVisible and "Turn OFF" or "Turn ON"
    end)

    -- Update Level & Money
    task.spawn(function()
        while task.wait(Config.CheckInterval) do
            local success, _ = pcall(function()
                if playerGui:FindFirstChild("XP") and playerGui.XP:FindFirstChild("Frame") then
                    local levelText = playerGui.XP.Frame.LevelCount.Text
                    uiElements.LevelLabel.Text = "Level: " .. tostring(levelText)
                end
                
                if playerGui:FindFirstChild("Events") and playerGui.Events:FindFirstChild("Frame") then
                    local moneyText = playerGui.Events.Frame.CurrencyCounter.Counter.ContentText
                    uiElements.MoneyLabel.Text = "Money: " .. tostring(moneyText)
                end
            end)
            
            if not success then
                uiElements.LevelLabel.Text = "Level: ?"
                uiElements.MoneyLabel.Text = "Money: ?"
            end
        end
    end)

    -- Update FPS & Ping
    local frames = 0
    local lastTime = tick()
    
    RunService.RenderStepped:Connect(function()
        frames += 1
        local now = tick()
        
        if now - lastTime >= 1 then
            local fps = math.floor(frames / (now - lastTime))
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            uiElements.StatsLabel.Text = string.format("FPS: %d | Ping: %s", fps, ping)
            frames = 0
            lastTime = now
        end
    end)
end

-- =============================================
-- FRIEND SYSTEM FUNCTIONS
-- =============================================
local targetPlayers = {}

local function acceptFriendRequests()
    if not Config.AutoAcceptFriends then return end
    
    local success, result = pcall(function()
        local requests = FriendService:GetFriendRequests()
        for _, request in ipairs(requests) do
            FriendService:AcceptFriendRequest(request.Id)
            print("Accepted friend request from:", request.Username)
            task.wait(1) -- Cooldown antar penerimaan
        end
    end)
    
    if not success then
        warn("Error accepting friend requests:", result)
    end
end

local function sendFriendRequests()
    if not Config.AutoAddFriends then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and not table.find(targetPlayers, player.UserId) then
            local isFriend = Players.LocalPlayer:IsFriendsWith(player.UserId)
            
            if not isFriend then
                local success, result = pcall(function()
                    FriendService:SendFriendRequest(player.UserId)
                    print("Sent friend request to:", player.Name)
                    table.insert(targetPlayers, player.UserId)
                    task.wait(Config.AddFriendsCooldown) -- Cooldown antar pengiriman
                end)
                
                if not success then
                    warn("Error sending friend request to", player.Name, ":", result)
                end
            end
        end
    end
end

local function setupFriendSystem()
    -- Loop utama untuk auto accept
    if Config.AutoAcceptFriends then
        task.spawn(function()
            while Config.AutoAcceptFriends do
                acceptFriendRequests()
                task.wait(10) -- Cek setiap 10 detik
            end
        end)
    end

    -- Loop utama untuk auto add
    if Config.AutoAddFriends then
        task.spawn(function()
            while Config.AutoAddFriends do
                sendFriendRequests()
                task.wait(30) -- Cek setiap 30 detik
            end
        end)
    end

    -- Event ketika pemain baru bergabung
    if Config.AutoAddFriends then
        Players.PlayerAdded:Connect(function(player)
            if not Players.LocalPlayer:IsFriendsWith(player.UserId) then
                task.wait(5) -- Tunggu beberapa detik setelah pemain bergabung
                
                local success, result = pcall(function()
                    FriendService:SendFriendRequest(player.UserId)
                    print("Sent friend request to new player:", player.Name)
                end)
                
                if not success then
                    warn("Error sending friend request to new player", player.Name, ":", result)
                end
            end
        end)
    end
end

-- =============================================
-- INITIALIZATION
-- =============================================
local function initialize()
    -- Create UI
    local uiElements = createUI()
    
    -- Setup UI updates
    setupUIUpdates(uiElements)
    
    -- Setup friend system
    setupFriendSystem()
    
    print("Auto Friend & UI System loaded successfully!")
end

-- Start the system
initialize()
