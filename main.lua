local start_time = os.clock()
local secure_mode = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local function secure_call(func, ...)
    if secure_mode then
        return pcall(func, ...)
    else
        return true, func(...)
    end
end

local get_service = setmetatable({}, {
    __index = function(self, index)
        return cloneref(game:GetService(index))
    end
})

local services = {
    proximity_prompt = get_service.ProximityPromptService,
    marketplace = get_service.MarketplaceService,
    replicated_storage = get_service.ReplicatedStorage,
    user_input = get_service.UserInputService,
    virtual_user = get_service.VirtualUser,
    tween = get_service.TweenService,
    run = get_service.RunService,
    workspace = get_service.Workspace,
    players = get_service.Players,
    stats = get_service.Stats
}

local game_info = services.marketplace:GetProductInfo(game.PlaceId)
local player = services.players.LocalPlayer
local backpack = player.Backpack

local game_paths = {
    world = services.workspace:FindFirstChild("World"),
    npcs = services.workspace:FindFirstChild("World"):FindFirstChild("NPCs"),
    zones = services.workspace:FindFirstChild("World"):FindFirstChild("Zones"),
    hole_folders = services.workspace:FindFirstChild("World"):FindFirstChild("Zones"):FindFirstChild("_NoDig"),
    diggable = services.workspace:FindFirstChild("World"):FindFirstChild("Zones"):FindFirstChild("_Dig"),
    totems = services.workspace:FindFirstChild("Active"):FindFirstChild("Totems"),
    bosses = services.workspace:FindFirstChild("Spawns"):FindFirstChild("BossSpawns"),
    abundance = services.workspace:FindFirstChild("World"):FindFirstChild("Map"):FindFirstChild("_Abundances")
}

for name, path in pairs(game_paths) do
    if not path then
        return player:Kick(string.format("%s folder not found!", name))
    end
end

local cache = {
    abundance_names = {}
}

local config = {
    dig = {
        auto_enabled = false,
        option = "Blatant",
        auto_hole = false,
        auto_equip = false,
        auto_dig = false,
        auto_dig_delay = 0.1,
        auto_fix_shovel = false,
        auto_fix_delay = 10 -- Waktu tunggu dalam detik sebelum auto fix shovel dijalankan
    },
    
    farm = {
        auto_pizza = false
    },
    
    staff = {
        anti_staff = false,
        method = "Notify"
    },
    
    player = {
        anti_afk = true,
        inf_jump = false,
        tp_walk = false,
        tp_walk_speed = 10
    },
    
    inventory = {
        auto_sell = false,
        sell_delay = 5,
        auto_favorite = false,
        favorite_items = {},
        favorite_action = "Favorite" -- "Favorite" or "Unfavorite"
    }
}

local utils = {}

function utils.get_tool()
    return player.Character:FindFirstChildOfClass("Tool")
end

function utils.get_shovel()
    if not player.Character then return nil end
    
    for _, tool in ipairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and string.match(tool.Name:lower(), "shovel") then
            return tool
        end
    end
    
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.match(tool.Name:lower(), "shovel") then
            return tool
        end
    end
    
    return nil
end

function utils.closest_totem()
    local totem = nil
    local dist = 9e99

    for _, v in pairs(game_paths.totems:GetChildren()) do
        if v:GetAttribute("IsActive") then
            local distance = (v:GetPivot().Position - player.Character:GetPivot().Position).Magnitude
            if distance < dist then
                dist = distance
                totem = v
            end
        end
    end

    return totem
end

function utils.is_staff(player_obj)
    local rank = player_obj:GetRankInGroup(35289532)
    local role = player_obj:GetRoleInGroup(35289532)
    
    if rank >= 2 then
        if config.staff.method == "Kick" then
            player:Kick(role.." detected! Username: "..player_obj.DisplayName)
        elseif config.staff.method == "Notify" then
            -- Notifikasi dihapus sesuai permintaan pengguna
            print("Staff Detected! "..role.." detected! Username: "..player_obj.DisplayName)
        end
        return true
    end
    return false
end

function utils.teleport_to(position)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not hrp then return end
    hrp.CFrame = CFrame.new(position)
end

function utils.auto_holes()
    task.spawn(function()
        while config.dig.auto_hole do
            if not config.farm.auto_pizza then
                local crater = game_paths.hole_folders:FindFirstChild(player.Name.."_Crater_Hitbox")
                if crater then
                    crater:Destroy()
                end
            end
            task.wait(0.1)
        end
    end)
end

local events = {}

events.anti_afk = player.Idled:Connect(function()
    if config.player.anti_afk then
        services.virtual_user:CaptureController()
        services.virtual_user:ClickButton2(Vector2.new())
    end
end)

events.dig_minigame = player.PlayerGui.ChildAdded:Connect(function(v)
    if config.dig.auto_enabled and not config.farm.auto_pizza and v.Name == "Dig" then
        auto_dig_minigame(v)
    end
end)

-- Variabel untuk melacak waktu pertama kali GUI Dig terdeteksi dalam keadaan disabled
local dig_disabled_time = nil

-- Event untuk memastikan UI Backpack tetap muncul
-- Ganti bagian events.ensure_backpack_ui dengan ini:
events.ensure_backpack_ui = services.run.Heartbeat:Connect(function()
    if player.Character and player.Character:FindFirstChildOfClass("Tool") then
        -- Jika pemain sedang memegang tool (seperti shovel), pastikan UI Backpack tetap muncul
        if player.PlayerGui:FindFirstChild("Backpack") and not player.PlayerGui.Backpack.Enabled then
            player.PlayerGui.Backpack.Enabled = true
        end
    end
    
    -- Auto fix shovel jika GUI Dig ada tapi disabled
    if config.dig.auto_fix_shovel then
        local dig_gui = player.PlayerGui:FindFirstChild("Dig")
        
        -- Jika GUI Dig ada dan disabled
        if dig_gui and dig_gui.Enabled == false then
            -- Jika ini adalah pertama kali terdeteksi, catat waktunya
            if dig_disabled_time == nil then
                dig_disabled_time = os.time()
            end
            
            -- Cek apakah sudah melewati waktu tunggu
            if os.time() - dig_disabled_time >= config.dig.auto_fix_delay then
                -- Unequip semua tool (termasuk shovel)
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:UnequipTools()
                end
                
                -- Reset timer setelah mencoba fix
                dig_disabled_time = nil
            end
        else
            -- Reset timer jika GUI Dig tidak ada atau sudah enabled
            dig_disabled_time = nil
        end
    end
end)

-- Fungsi untuk menjalankan auto dig secara terpisah
function auto_dig_minigame(dig_gui)
    if not dig_gui then
        local existing_dig = player.PlayerGui:FindFirstChild("Dig")
        if not existing_dig then return end
        dig_gui = existing_dig
    end
    
    local strong_hit = dig_gui:FindFirstChild("Safezone"):FindFirstChild("Holder"):FindFirstChild("Area_Strong")
    local player_bar = dig_gui:FindFirstChild("Safezone"):FindFirstChild("Holder"):FindFirstChild("PlayerBar")
    
    if not strong_hit or not player_bar then return end
    
    -- Pastikan UI Backpack tetap muncul saat minigame dimulai
    if player.PlayerGui:FindFirstChild("Backpack") then
        player.PlayerGui.Backpack.Enabled = true
    end
    
    -- Tambahkan event untuk mendeteksi saat minigame dihapus (selesai)
    local minigame_removed = dig_gui.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            -- Minigame telah dihapus, pastikan UI Backpack tetap muncul
            task.spawn(function()
                task.wait(0.5) -- Tunggu sebentar setelah minigame selesai
                if player.PlayerGui:FindFirstChild("Backpack") then
                    player.PlayerGui.Backpack.Enabled = true
                end
            end)
            pcall(function() minigame_removed:Disconnect() end)
        end
    end)
    
    local minigame_connection = player_bar:GetPropertyChangedSignal("Position"):Connect(function()
        if not config.dig.auto_enabled or config.farm.auto_pizza then 
            pcall(function() minigame_connection:Disconnect() end)
            pcall(function() if minigame_removed then minigame_removed:Disconnect() end end)
            return 
        end
        
        if config.dig.option == "Legit" and math.abs(player_bar.Position.X.Scale - strong_hit.Position.X.Scale) <= 0.04 then
            local tool = utils.get_tool()
            if tool then
                tool:Activate()
                task.wait()
            end
        elseif config.dig.option == "Blatant" then
            player_bar.Position = UDim2.new(strong_hit.Position.X.Scale, 0, 0, 0)
            local tool = utils.get_tool()
            if tool then
                tool:Activate()
                task.wait()
            end
        end
        
        -- Pastikan UI Backpack tetap muncul selama minigame
        if player.PlayerGui:FindFirstChild("Backpack") then
            player.PlayerGui.Backpack.Enabled = true
        end
    end)
end

-- Cek apakah GUI Dig sudah ada saat script dimulai
function check_existing_dig_gui()
    if config.dig.auto_enabled and not config.farm.auto_pizza then
        local existing_dig = player.PlayerGui:FindFirstChild("Dig")
        if existing_dig then
            auto_dig_minigame(existing_dig)
        end
    end
end

events.jump_request = services.user_input.JumpRequest:Connect(function()
    if config.player.inf_jump then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

events.tp_walk = services.run.Heartbeat:Connect(function()
    if config.player.tp_walk and player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        if humanoid.MoveDirection.Magnitude > 0 then
            player.Character:TranslateBy(humanoid.MoveDirection * config.player.tp_walk_speed / 10)
        end
    end
end)

events.player_added = services.players.PlayerAdded:Connect(function(player_obj)
    if config.staff.anti_staff and player_obj ~= player then
        utils.is_staff(player_obj)
    end
end)

function start_auto_sell()
    if not config.inventory.auto_sell then return end
    
    task.spawn(function()
        while config.inventory.auto_sell do
            -- Pastikan UI Backpack tetap muncul sebelum menjual
            if player.PlayerGui:FindFirstChild("Backpack") then
                player.PlayerGui.Backpack.Enabled = true
            end
            
            -- Gunakan fungsi sell_all_items yang sudah diperbaiki
            sell_all_items()
            
            -- Tunggu sebelum menjual lagi
            task.wait(config.inventory.sell_delay)
            
            -- Pastikan UI Backpack tetap muncul setelah delay
            if player.PlayerGui:FindFirstChild("Backpack") then
                player.PlayerGui.Backpack.Enabled = true
            end
        end
    end)
end

function start_auto_pizza()
    if not config.farm.auto_pizza then return end
    
    task.spawn(function()
        while config.farm.auto_pizza do
            services.replicated_storage:WaitForChild("Remotes"):WaitForChild("Change_Zone"):FireServer("Penguins Pizza")
            services.replicated_storage:WaitForChild("DialogueRemotes"):WaitForChild("StartInfiniteQuest"):InvokeServer("Pizza Penguin")
            task.wait(math.random(1, 3))
            
            local pizza_customer = workspace:FindFirstChild("Active"):FindFirstChild("PizzaCustomers"):FindFirstChildOfClass("Model")
            if pizza_customer then
                utils.teleport_to(pizza_customer:GetPivot().Position)
                task.wait(math.random(2, 5))
                services.replicated_storage:WaitForChild("Remotes"):WaitForChild("Quest_DeliverPizza"):InvokeServer()
                task.wait(math.random(1, 3))
            end
            
            services.replicated_storage:WaitForChild("Remotes"):WaitForChild("Change_Zone"):FireServer("Penguins Pizza")
            services.replicated_storage:WaitForChild("DialogueRemotes"):WaitForChild("CompleteInfiniteQuest"):InvokeServer("Pizza Penguin")
            task.wait(math.random(60, 90))
        end
    end)
end

function sell_all_items()
    -- Pastikan UI Backpack tetap muncul
    if player.PlayerGui:FindFirstChild("Backpack") then
        player.PlayerGui.Backpack.Enabled = true
    end
    
    -- Gunakan remote event SellAllItems untuk menjual semua item sekaligus
    local Event = services.replicated_storage:WaitForChild("DialogueRemotes"):WaitForChild("SellAllItems")
    Event:FireServer(
        workspace.World.NPCs.Rocky
    )
    
    -- Notifikasi dihapus sesuai permintaan pengguna
    -- print("All items have been sold!")
    
    -- Pastikan UI Backpack tetap muncul setelah menjual
    task.spawn(function()
        task.wait(0.5) -- Tunggu sebentar setelah menjual
        if player.PlayerGui:FindFirstChild("Backpack") then
            player.PlayerGui.Backpack.Enabled = true
        end
    end)
end

function sell_held_item()
    -- Pastikan UI Backpack tetap muncul
    if player.PlayerGui:FindFirstChild("Backpack") then
        player.PlayerGui.Backpack.Enabled = true
    end
    
    local tool = utils.get_tool()
    if not tool then
        -- Notifikasi dihapus sesuai permintaan pengguna
        -- print("No Tool Found!")
        return
    end
    
    if not tool:GetAttribute("InventoryLink") then
        -- Notifikasi dihapus sesuai permintaan pengguna
        -- print("Cant Sell This Item!")
        return
    end
    
    services.replicated_storage:WaitForChild("DialogueRemotes"):WaitForChild("SellHeldItem"):FireServer(tool)
    
    -- Pastikan UI Backpack tetap muncul setelah menjual
    task.spawn(function()
        task.wait(0.5) -- Tunggu sebentar setelah menjual
        if player.PlayerGui:FindFirstChild("Backpack") then
            player.PlayerGui.Backpack.Enabled = true
        end
    end)
end

function claim_discovered_items()
    local hud = player.PlayerGui:FindFirstChild("HUD")
    if not hud then return end
    
    local journal = hud:FindFirstChild("Frame"):FindFirstChild("Journal"):FindFirstChild("Scroller")
    for _, v in pairs(journal:GetChildren()) do
        if v:IsA("ImageButton") and v:FindFirstChild("Discovered") and v:FindFirstChild("Discovered").Visible then
            firesignal(v.MouseButton1Click)
            task.wait(0.1)
        end
    end
end

function teleport_to_merchant()
    local merchant = game_paths.npcs:FindFirstChild("Merchant Cart")
    if merchant then
        utils.teleport_to(merchant:GetPivot().Position)
    end
end

function teleport_to_meteor()
    local meteor = workspace:FindFirstChild("Active"):FindFirstChild("ActiveMeteor")
    if meteor then
        utils.teleport_to(meteor:GetPivot().Position)
    else
        -- Notifikasi dihapus sesuai permintaan pengguna
        -- print("No Meteor Found!")
    end
end

function teleport_to_enchantment_altar()
    local altar = game_paths.world:FindFirstChild("Interactive"):FindFirstChild("Enchanting"):FindFirstChild("EnchantmentAltar"):FindFirstChild("EnchantPart")
    if altar then
        utils.teleport_to(altar:GetPivot().Position)
    end
end

function teleport_to_active_totem()
    local totem = utils.closest_totem()
    if totem then
        utils.teleport_to(totem:GetPivot().Position)
    else
        -- Notifikasi dihapus sesuai permintaan pengguna
        -- print("No Active Totem Found!")
    end
end

function start_auto_dig()
    if not config.dig.auto_dig then return end
    
    task.spawn(function()
        while config.dig.auto_dig do
            -- Pastikan UI Backpack tetap muncul saat auto dig aktif
            if player.PlayerGui:FindFirstChild("Backpack") then
                player.PlayerGui.Backpack.Enabled = true
            end
            
            local shovel = utils.get_shovel()
            if shovel and shovel.Parent == player.Character then
                shovel:Activate()
            elseif config.dig.auto_equip and shovel and shovel.Parent == player.Backpack then
                -- Pastikan UI Backpack tetap muncul sebelum equip
                if player.PlayerGui:FindFirstChild("Backpack") then
                    player.PlayerGui.Backpack.Enabled = true
                end
                
                -- Equip shovel jika auto equip aktif
                pcall(function()
                    local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if Event then
                        Event = Event:FindFirstChild("Backpack_Equip") or Event:FindFirstChild("BackpackEquip")
                        if Event then
                            Event:FireServer(shovel)
                        end
                    end
                end)
                task.wait(0.2) -- Tunggu untuk equip
                
                -- Pastikan UI Backpack tetap muncul setelah equip
                if player.PlayerGui:FindFirstChild("Backpack") then
                    player.PlayerGui.Backpack.Enabled = true
                end
            end
            task.wait(config.dig.auto_dig_delay)
        end
    end)
end

local Luna = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua",
  true
))()
local abundance_parts = {}
local abundance_names = {}

if game_paths.abundance then
    for _, part in ipairs(game_paths.abundance:GetChildren()) do
        local attr = part:GetAttribute("Abundance")
        if attr then
            local name = string.match(attr, "^[^,]+")
            if name and not abundance_parts[name] then
                table.insert(abundance_names, name)
                abundance_parts[name] = part
            end
        end
    end
end

table.sort(abundance_names)

local Window = Luna:CreateWindow{
  Name = "Private Script Dig",
  Subtitle = "by @bdx7 on Discord",
  LogoID = nil,
  LoadingEnabled = true,
  LoadingTitle = "Luna UI",
  LoadingSubtitle = "by Nebula‑Softworks",
  ConfigSettings = {
    RootFolder = nil,
    ConfigFolder = "NamaFolderConfig"
  },
  KeySystem = false
}

-- Tab Farm
local farm = Window:CreateTab({Name="Farm", ShowTitle=true})
farm:CreateSection("Dig Settings")
farm:CreateToggle({
    Name = "Auto Equip Shovel", 
    CurrentValue = false, 
    Callback = function(v)
        config.dig.auto_equip = v
        if v then
            task.spawn(function()
                while config.dig.auto_equip do
                    if player.Character then
                        local shovel = utils.get_shovel()
                        if shovel then
                            if shovel.Parent == player.Backpack then
                                pcall(function()
                                    local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                                    if Event then
                                        Event = Event:FindFirstChild("Backpack_Equip") or Event:FindFirstChild("BackpackEquip")
                                        if Event then
                                            Event:FireServer(shovel)
                                        end
                                    end
                                end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

farm:CreateToggle({
    Name = "Auto Fix Shovel", 
    CurrentValue = false, 
    Callback = function(v)
        config.dig.auto_fix_shovel = v
    end
})

farm:CreateSlider({
    Name = "Auto Fix Shovel Delay", 
    Range = {1, 30}, 
    Increment = 1, 
    CurrentValue = config.dig.auto_fix_delay, 
    Callback = function(v) 
        config.dig.auto_fix_delay = v 
        -- print("Auto Fix Shovel Delay diatur ke " .. v .. " detik")
    end
})

farm:CreateToggle({
    Name = "Auto start dig", 
    CurrentValue = false, 
    Callback = function(v)
        config.dig.auto_dig = v
        if v then
            start_auto_dig()
        end
    end
})
table.insert(abundance_names, 1, "None")


farm:CreateToggle({Name="Auto Dig Minigame", CurrentValue=config.dig.auto_enabled, Callback=function(v) 
    config.dig.auto_enabled=v 
    if v then
        check_existing_dig_gui()
    end
end})
farm:CreateDropdown({Name="Choose Dig Option", Options={"Legit","Blatant"}, CurrentOption={config.dig.option}, MultipleOptions=false, Callback=function(v) config.dig.option=v end})
farm:CreateToggle({Name="Auto Holes", CurrentValue=config.dig.auto_hole, Callback=function(v) 
    config.dig.auto_hole=v 
    if v then utils.auto_holes() end
end})

farm:CreateSection("Farm Settings")
farm:CreateToggle({Name="Auto Pizza Delivery", CurrentValue=config.farm.auto_pizza, Callback=function(v) config.farm.auto_pizza=v if v then start_auto_pizza() end end})

-- Tab Misc
local misc = Window:CreateTab({Name="Misc", ShowTitle=true})
misc:CreateSection("Staff Settings")
misc:CreateToggle({Name="Anti Staff", CurrentValue=config.staff.anti_staff, Callback=function(v) config.staff.anti_staff=v if v then for _,p in pairs(services.players:GetPlayers()) do if p~=player then utils.is_staff(p) end end end end})
misc:CreateDropdown({Name="Choose Staff Method", Options={"Notify","Kick"}, CurrentOption={config.staff.method}, MultipleOptions=false, Callback=function(v) config.staff.method=v end})
misc:CreateSection("Anti Afk Settings")
misc:CreateToggle({Name="Anti Afk", CurrentValue=config.player.anti_afk, Callback=function(v) config.player.anti_afk=v end})
misc:CreateSection("LocalPlayer Settings")
misc:CreateToggle({Name="Inf Jump", CurrentValue=config.player.inf_jump, Callback=function(v) config.player.inf_jump=v end})
misc:CreateToggle({Name="Tp Walk", CurrentValue=config.player.tp_walk, Callback=function(v) config.player.tp_walk=v end})
misc:CreateSlider({Name="Tp Walk Speed", Range={1,100}, Increment=1, CurrentValue=config.player.tp_walk_speed, Callback=function(v) config.player.tp_walk_speed=v end})

-- Tab Inventory
local inv = Window:CreateTab({Name="Inventory", ShowTitle=true})
inv:CreateSection("Selling")
inv:CreateToggle({Name="Auto Sell", CurrentValue=config.inventory.auto_sell, Callback=function(v) config.inventory.auto_sell=v if v then start_auto_sell() end end})
inv:CreateSlider({Name="Auto Sell Delay", Range={1,60}, Increment=1, CurrentValue=config.inventory.sell_delay, Callback=function(v) config.inventory.sell_delay=v end})
inv:CreateButton({Name="Sell Held Item", Callback=sell_held_item})
inv:CreateSection("Journal Settings")
inv:CreateButton({Name="Claim Unclaimed Discovered Items", Callback=claim_discovered_items})

-- Favoriting Section
inv:CreateSection("Favorite Items")

-- Setup auto favorite config
config.inventory.auto_favorite = false
config.inventory.favorite_items = {}
config.inventory.favorite_action = "Favorite"
config.inventory.favorited_ids = {} -- Track already favorited items

-- Get all item names
local function get_all_item_names()
    local items = {}
    local itemsDictionary = require(services.replicated_storage:WaitForChild("Dictionary"):WaitForChild("Items"))
    
    for itemName, _ in pairs(itemsDictionary) do
        table.insert(items, itemName)
    end
    
    table.sort(items)
    return items
end

-- Function to toggle favorite status
function toggle_favorite(item, should_favorite)
    if not item or not item:GetAttribute("InventoryLink") then return end
    
    local Event = services.replicated_storage:WaitForChild("Remotes"):WaitForChild("Backpack_Favourite")
    if not Event then return end
    
    -- Parse inventoryLink format: ItemName_UUID_OwnerID
    local inventoryLink = item:GetAttribute("InventoryLink")
    local parts = string.split(inventoryLink, "_")
    local itemID = parts[2] or inventoryLink
    
    -- Check if item is already in desired state
    local isAlreadyFavorited = config.inventory.favorited_ids[itemID]
    if (should_favorite and isAlreadyFavorited) or (not should_favorite and not isAlreadyFavorited) then
        return -- Item already in desired state
    end
    
    -- Create arguments structure
    local args = {
        ItemName = item.Name,
        ID = itemID,
        OwnerID = tonumber(parts[3]) or player.UserId,
        Attributes = {
            Favourited = should_favorite
        }
    }
    
    Event:FireServer(args)
    
    -- Update tracked state
    if should_favorite then
        config.inventory.favorited_ids[itemID] = true
    else
        config.inventory.favorited_ids[itemID] = nil
    end
end

-- Function to check if an item is favorited
function is_item_favorited(item)
    if not item or not item:GetAttribute("InventoryLink") then return false end
    
    local inventoryLink = item:GetAttribute("InventoryLink")
    local parts = string.split(inventoryLink, "_")
    local itemID = parts[2] or inventoryLink
    
    return config.inventory.favorited_ids[itemID] == true
end

-- Function to auto favorite/unfavorite based on list
function start_auto_favorite()
    if not config.inventory.auto_favorite then return end
    
    task.spawn(function()
        while config.inventory.auto_favorite do
            for _, item in pairs(backpack:GetChildren()) do
                if table.find(config.inventory.favorite_items, item.Name) then
                    local should_favorite = config.inventory.favorite_action == "Favorite"
                    
                    -- Only toggle if item isn't already in desired state
                    local is_favorited = is_item_favorited(item)
                    if (should_favorite and not is_favorited) or (not should_favorite and is_favorited) then
                        toggle_favorite(item, should_favorite)
                        task.wait(0.2) -- Delay to avoid rate limiting
                    end
                end
            end
            task.wait(1) -- Check every second
        end
    end)
end

-- Function to favorite/unfavorite a specific item
function favorite_specific_item(item_name, should_favorite)
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name == item_name then
            -- Check if item is already in desired state
            local is_favorited = is_item_favorited(item)
            if (should_favorite and is_favorited) or (not should_favorite and not is_favorited) then
                -- Notifikasi dihapus sesuai permintaan pengguna
                -- print("Already " .. (should_favorite and "Favorited" or "Unfavorited") .. ": " .. item_name)
                return true
            end
            
            toggle_favorite(item, should_favorite)
            -- Notifikasi dihapus sesuai permintaan pengguna
            -- print((should_favorite and "Favorited" or "Unfavorited") .. ": " .. item_name)
            return true
        end
    end
    
    -- Notifikasi dihapus sesuai permintaan pengguna
    -- print("Item Not Found: Could not find " .. item_name .. " in backpack")
    return false
end

-- Function to scan current backpack and update favorited status
function scan_favorited_items()
    for _, item in pairs(backpack:GetChildren()) do
        if item:GetAttribute("InventoryLink") then
            local inventoryLink = item:GetAttribute("InventoryLink")
            local parts = string.split(inventoryLink, "_")
            local itemID = parts[2] or inventoryLink
            
            -- Check if item has a Favourited attribute
            local attributes = item:GetAttributes()
            if attributes and attributes.Favourited == true then
                config.inventory.favorited_ids[itemID] = true
            end
        end
    end
end

-- Scan for favorited items when script starts
scan_favorited_items()

-- Auto Favorite Toggle
inv:CreateToggle({
    Name = "Auto Favorite Items", 
    CurrentValue = config.inventory.auto_favorite, 
    Callback = function(v) 
        config.inventory.auto_favorite = v 
        if v then 
            start_auto_favorite() 
        end 
    end
})

-- Action selection (Favorite/Unfavorite)
inv:CreateDropdown({
    Name = "Favorite Action",
    Options = {"Favorite", "Unfavorite"},
    CurrentOption = {config.inventory.favorite_action},
    MultipleOptions = false,
    Callback = function(v) config.inventory.favorite_action = v end
})

local all_item_names = get_all_item_names()

local favorite_dropdown = inv:CreateDropdown({
    Name = "Items to Auto Favorite",
    Options = all_item_names,
    CurrentOption = config.inventory.favorite_items,
    MultipleOptions = true,
    Callback = function(selected_items) 
        config.inventory.favorite_items = selected_items
    end
})
-- Tidak menggunakan SetSearch karena tidak didukung
-- if favorite_dropdown and favorite_dropdown.SetSearch then
--     favorite_dropdown:SetSearch(true)
-- else
--     warn("Dropdown 'Items to Auto Favorite' tidak support SetSearch")
-- end
-- Buttons for favorite/unfavorite all items in backpack
inv:CreateButton({
    Name = "Favorite All Items in Backpack", 
    Callback = function()
        for _, item in pairs(backpack:GetChildren()) do
            if not is_item_favorited(item) then
                toggle_favorite(item, true)
                task.wait(0.1)
            end
        end
    end
})

inv:CreateButton({
    Name = "Unfavorite All Items in Backpack", 
    Callback = function()
        for _, item in pairs(backpack:GetChildren()) do
            if is_item_favorited(item) then
                toggle_favorite(item, false)
                task.wait(0.1)
            end
        end
    end
})


local tp = Window:CreateTab({Name="Teleport", ShowTitle=true})
tp:CreateSection("Misc Teleports")
tp:CreateButton({Name="Teleport To Merchant", Callback=teleport_to_merchant})
tp:CreateButton({Name="Teleport To Meteor", Callback=teleport_to_meteor})
tp:CreateButton({Name="Teleport To EnchantmentAltar", Callback=teleport_to_enchantment_altar})
tp:CreateButton({Name="Teleport To Active Totem", Callback=teleport_to_active_totem})
tp:CreateSection("Abundance Teleports")
local abundance_dropdown = tp:CreateDropdown({
    Name = "Teleport to Abundance",
    Options = abundance_names,
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(v)
        if v == "None" then return end
        local t = abundance_parts[v]
        if t then
            utils.teleport_to(t.Position + Vector3.new(0, 5, 0))
        end
    end
})
-- Tidak menggunakan SetSearch karena tidak didukung
-- if abundance_dropdown and abundance_dropdown.SetSearch then
--     abundance_dropdown:SetSearch(true)
-- end

-- Fungsi untuk memastikan UI Backpack tetap muncul
function ensure_backpack_ui_visible()
    task.spawn(function()
        if player.PlayerGui:FindFirstChild("Backpack") then
            player.PlayerGui.Backpack.Enabled = true
        end
    end)
end

-- Event untuk mendeteksi saat karakter pemain berubah
events.character_added = player.CharacterAdded:Connect(function()
    task.wait(1) -- Tunggu sebentar setelah karakter dimuat
    ensure_backpack_ui_visible()
end)

-- Event untuk mendeteksi saat UI Backpack ditambahkan ke PlayerGui
events.backpack_ui_added = player.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "Backpack" then
        child.Enabled = true
    end
end)

local function init()
    if game:GetService("ReplicatedStorage"):FindFirstChild("Security") then
        print("[WARNING] Anti-cheat detected, enabling secure mode")
        secure_mode = true
    end
    
    print("[DIG Script] Loaded successfully in " .. string.format("%.2f", os.clock() - start_time) .. " seconds")
    print("[DIG Script] Use command :toggleui to show/hide the UI")
    
    check_existing_dig_gui()
    ensure_backpack_ui_visible() -- Pastikan UI Backpack muncul saat script dimulai
    
    return true
end

local success = init()
if not success then
    warn("[DIG Script] Failed to initialize!")
end