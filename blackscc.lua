-- LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
button.Text = "Turn OFF"
button.Parent = gui -- bukan parent frame biar ga ikut hilang

-- Toggle fungsi
local visible = true
button.MouseButton1Click:Connect(function()
	visible = not visible
	frame.Visible = visible
	button.Text = visible and "Turn OFF" or "Turn ON"
end)

-- Update Level & Money
task.spawn(function()
	while task.wait(1) do
		local success, _ = pcall(function()
			local levelText = playerGui.XP.Frame.LevelCount.Text
			local moneyText = playerGui.Events.Frame.CurrencyCounter.Counter.ContentText
			levelLabel.Text = "Level: " .. tostring(levelText)
			moneyLabel.Text = "Money: " .. tostring(moneyText)
		end)
		if not success then
			levelLabel.Text = "Level: ?"
			moneyLabel.Text = "Money: ?"
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
		local fps = frames / (now - lastTime)
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
		statsLabel.Text = string.format("FPS: %d | Ping: %s", fps, ping)
		frames = 0
		lastTime = now
	end
end)
-- Made by RIP#6666
_G.Settings = {
    Players = {
        ["Ignore Me"] = true, -- Ignore your Character
        ["Ignore Others"] = true -- Ignore other Characters
    },
    Meshes = {
        Destroy = true, -- Destroy Meshes
        LowDetail = true -- Low detail meshes (NOT SURE IT DOES ANYTHING)
    },
    Images = {
        Invisible = true, -- Invisible Images
        LowDetail = true, -- Low detail images (NOT SURE IT DOES ANYTHING)
        Destroy = true, -- Destroy Images
    },
    ["No Particles"] = true, -- Disables all ParticleEmitter, Trail, Smoke, Fire and Sparkles
    ["No Camera Effects"] = true, -- Disables all PostEffect's (Camera/Lighting Effects)
    ["No Explosions"] = true, -- Makes Explosion's invisible
    ["No Clothes"] = true, -- Removes Clothing from the game
    ["Low Water Graphics"] = true, -- Removes Water Quality
    ["No Shadows"] = true, -- Remove Shadows
    ["Low Rendering"] = true, -- Lower Rendering
    ["Low Quality Parts"] = true -- Lower quality parts
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
