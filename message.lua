-- Backpack Item Counter Script untuk Synapse X
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Wait untuk module scripts dan require mereka
local function loadDictionary(path)
    local success, result = pcall(function()
        local module = ReplicatedStorage:WaitForChild("Dictionary", 10)
        if path == "Items" then
            return require(module:WaitForChild("Items", 5))
        elseif path == "Sizes" then
            return require(module:WaitForChild("Sizes", 5))
        elseif path == "Modifiers" then
            return require(module:WaitForChild("Modifiers", 5))
        end
    end)
    return success and result or nil
end

print("Loading dictionaries...")
local ItemsDictionary = loadDictionary("Items")
local SizesDictionary = loadDictionary("Sizes") 
local ModifiersDictionary = loadDictionary("Modifiers")

if not ItemsDictionary then
    error("Failed to load Items Dictionary!")
end

if not SizesDictionary then
    print("Warning: Failed to load Sizes Dictionary!")
    SizesDictionary = {}
end

if not ModifiersDictionary then
    print("Warning: Failed to load Modifiers Dictionary!")
    ModifiersDictionary = {}
end

print("Dictionaries loaded successfully!")

-- Fungsi untuk mengkonversi Color3 ke Hex
local function Color3ToHex(color)
    return string.format("#%02x%02x%02x", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

-- Fungsi untuk mengkonversi Hex ke Color3
local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    return Color3.fromRGB(r * 255, g * 255, b * 255)
end

-- Fungsi untuk mendapatkan nama size berdasarkan warna hex DAN text
local function getSizeFromColorAndText(hexColor, text)
    if not SizesDictionary or type(SizesDictionary) ~= "table" then
        return nil, nil
    end
    
    local matchingColors = {}
    
    -- Pertama, kumpulkan semua size yang memiliki warna yang sama
    for sizeName, sizeData in pairs(SizesDictionary) do
        if sizeData and sizeData.Color then
            local sizeHex = Color3ToHex(sizeData.Color)
            if sizeHex:lower() == hexColor:lower() then
                table.insert(matchingColors, {name = sizeName, data = sizeData})
            end
        end
    end
    
    -- Jika hanya ada satu match, return itu
    if #matchingColors == 1 then
        return matchingColors[1].name, matchingColors[1].data
    end
    
    -- Jika ada beberapa match dengan warna sama, cek berdasarkan text
    if #matchingColors > 1 and text then
        for _, match in pairs(matchingColors) do
            if text:lower():find(match.name:lower()) then
                return match.name, match.data
            end
        end
        
        -- Jika tidak ada yang cocok dengan text, return yang pertama sebagai fallback
        return matchingColors[1].name, matchingColors[1].data
    end
    
    return nil, nil
end

-- Fungsi untuk mendapatkan nama modifier berdasarkan warna hex DAN text
local function getModifierFromColorAndText(hexColor, text)
    if not ModifiersDictionary or type(ModifiersDictionary) ~= "table" then
        return nil, nil
    end
    
    local matchingColors = {}
    
    -- Pertama, kumpulkan semua modifier yang memiliki warna yang sama
    for modifierName, modifierData in pairs(ModifiersDictionary) do
        if modifierData and modifierData.Color then
            local modifierHex = Color3ToHex(modifierData.Color)
            if modifierHex:lower() == hexColor:lower() then
                table.insert(matchingColors, {name = modifierName, data = modifierData})
            end
        end
    end
    
    -- Jika hanya ada satu match, return itu
    if #matchingColors == 1 then
        return matchingColors[1].name, matchingColors[1].data
    end
    
    -- Jika ada beberapa match dengan warna sama, cek berdasarkan text
    if #matchingColors > 1 and text then
        for _, match in pairs(matchingColors) do
            if text:lower():find(match.name:lower()) then
                return match.name, match.data
            end
        end
        
        -- Jika tidak ada yang cocok dengan text, return yang pertama sebagai fallback
        return matchingColors[1].name, matchingColors[1].data
    end
    
    return nil, nil
end

-- Fungsi untuk mengparse ItemName dan mendapatkan informasi size/modifier/shiny
local function parseItemName(itemNameText)
    local result = {
        baseName = "",
        size = nil,
        sizeData = nil,
        modifier = nil,
        modifierData = nil,
        isShiny = false,
        fullText = itemNameText,
        debugInfo = {}
    }
    
    print("🔍 DEBUG - Parsing:", itemNameText)
    
    -- Cek apakah item shiny (biasanya ada kata "Shiny" atau simbol ✨)
    if itemNameText:lower():find("shiny") or itemNameText:find("✨") or itemNameText:find("⭐") then
        result.isShiny = true
        print("   ✨ Detected Shiny: true")
    end
    
    -- Extract warna dan text dari font color tag
    local colorPattern = '<font color="(#%x%x%x%x%x%x)">([^<]*)</font>'
    local colors = {}
    local texts = {}
    
    -- Ambil semua warna dan teks yang ada di dalam tag font
    for color, text in itemNameText:gmatch(colorPattern) do
        table.insert(colors, color)
        table.insert(texts, text)
        print("   🎨 Found color:", color, "with text:", '"' .. text .. '"')
    end
    
    -- Bersihkan teks dari tag HTML untuk mendapatkan base name
    local cleanText = itemNameText:gsub('<[^>]+>', '')
    -- Hapus kata "Shiny" dari base name jika ada
    cleanText = cleanText:gsub("Shiny ", ""):gsub(" Shiny", ""):gsub("✨", ""):gsub("⭐", ""):gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "")
    result.baseName = cleanText
    print("   📝 Base name:", '"' .. cleanText .. '"')
    
    -- Cek setiap warna dan text untuk size dan modifier
    for i, color in ipairs(colors) do
        local text = texts[i] or ""
        print("   🔍 Checking color", color, "with text", '"' .. text .. '"')
        
        -- Cek untuk size dengan warna DAN text
        local sizeName, sizeData = getSizeFromColorAndText(color, text)
        if sizeName then
            result.size = sizeName
            result.sizeData = sizeData
            print("   📏 Size found:", sizeName, "- Multiplier:", sizeData.PriceMultiplier or "none")
        end
        
        -- Cek untuk modifier dengan warna DAN text
        local modifierName, modifierData = getModifierFromColorAndText(color, text)
        if modifierName then
            result.modifier = modifierName
            result.modifierData = modifierData
            print("   🔧 Modifier found:", modifierName, "- Multiplier:", modifierData.PriceMultiplier or "none")
        end
        
        -- Jika tidak ketemu size atau modifier, print untuk debug
        if not sizeName and not modifierName then
            print("   ❓ No size/modifier found for color:", color, "text:", '"' .. text .. '"')
        end
    end
    
    return result
end

-- Fungsi untuk menghitung harga item dengan multiplier termasuk shiny
local function calculateItemPrice(basePrice, sizeData, modifierData, isShiny)
    local finalPrice = basePrice
    local multipliers = {"Base: " .. basePrice}
    
    -- Apply size multiplier
    if sizeData and sizeData.PriceMultiplier then
        finalPrice = finalPrice * sizeData.PriceMultiplier
        table.insert(multipliers, "Size x" .. sizeData.PriceMultiplier .. " = " .. finalPrice)
    end
    
    -- Apply modifier multiplier
    if modifierData and modifierData.PriceMultiplier then
        finalPrice = finalPrice * modifierData.PriceMultiplier
        table.insert(multipliers, "Modifier x" .. modifierData.PriceMultiplier .. " = " .. finalPrice)
    end
    
    -- Apply shiny multiplier (3)
    if isShiny then
        finalPrice = finalPrice * 1.275
        table.insert(multipliers, "Shiny 3 = " .. finalPrice)
    end
    
    print("   💰 Price calculation:", table.concat(multipliers, " → "))
    
    return math.floor(finalPrice)
end

-- Fungsi utama untuk menghitung semua item
local function countAllItems()
    -- Validasi backpack path
    local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("Backpack")
    if not backpackGui then
        error("Backpack GUI not found!")
    end
    
    local backpackScroll = backpackGui.Backpack.Inventory.Container.Scroll
    if not backpackScroll then
        error("Backpack scroll container not found!")
    end
    
    -- Validasi ItemsDictionary
    if not ItemsDictionary or type(ItemsDictionary) ~= "table" then
        error("Items Dictionary is not loaded or invalid!")
    end
    
    local itemCounts = {}
    local totalValue = 0
    local totalItems = 0
    
    print("=== BACKPACK ITEM COUNTER ===")
    print("Menghitung semua item di backpack...")
    
    for _, itemFrame in pairs(backpackScroll:GetChildren()) do
        if itemFrame:IsA("GuiObject") and itemFrame:FindFirstChild("Main") and itemFrame.Main:FindFirstChild("ItemName") then
            local itemNameLabel = itemFrame.Main.ItemName
            local itemNameText = itemNameLabel.Text
            
            -- Parse item name untuk mendapatkan info
            local itemInfo = parseItemName(itemNameText)
            local baseName = itemInfo.baseName
            
            -- Cari item di dictionary
            local itemData = nil
            for itemKey, data in pairs(ItemsDictionary) do
                if itemKey == baseName or (baseName:find(itemKey) or itemKey:find(baseName)) then
                    itemData = data
                    baseName = itemKey
                    break
                end
            end
            
            if itemData then
                -- Hitung harga dengan multiplier termasuk shiny
                local basePrice = itemData.Price or 0
                local finalPrice = calculateItemPrice(basePrice, itemInfo.sizeData, itemInfo.modifierData, itemInfo.isShiny)
                
                -- Buat key unik untuk item dengan size/modifier/shiny
                local uniqueKey = baseName
                if itemInfo.size then
                    uniqueKey = uniqueKey .. " (" .. itemInfo.size .. ")"
                end
                if itemInfo.modifier then
                    uniqueKey = uniqueKey .. " [" .. itemInfo.modifier .. "]"
                end
                if itemInfo.isShiny then
                    uniqueKey = "✨ " .. uniqueKey .. " (Shiny)"
                end
                
                -- Tambah ke counter
                if not itemCounts[uniqueKey] then
                    itemCounts[uniqueKey] = {
                        count = 0,
                        basePrice = basePrice,
                        finalPrice = finalPrice,
                        size = itemInfo.size,
                        modifier = itemInfo.modifier,
                        isShiny = itemInfo.isShiny,
                        rarity = itemData.Rarity or "Unknown"
                    }
                end
                
                itemCounts[uniqueKey].count = itemCounts[uniqueKey].count + 1
                totalValue = totalValue + finalPrice
                totalItems = totalItems + 1
                
                local shinyText = itemInfo.isShiny and " ✨(SHINY)" or ""
                print("✅ Found: " .. baseName .. (itemInfo.size and (" [" .. itemInfo.size .. "]") or "") .. (itemInfo.modifier and (" [" .. itemInfo.modifier .. "]") or "") .. shinyText)
            else
                print("❌ Item tidak ditemukan di dictionary: " .. baseName)
            end
        end
    end
    
    -- Tampilkan hasil
    print("\n=== HASIL PERHITUNGAN ===")
    print("Total Items: " .. totalItems)
    print("Total Value: " .. totalValue .. " coins")
    print("\n=== DETAIL ITEMS ===")
    
    -- Sort berdasarkan rarity dan nama
    local sortedItems = {}
    for itemName, data in pairs(itemCounts) do
        table.insert(sortedItems, {name = itemName, data = data})
    end
    
    table.sort(sortedItems, function(a, b)
        if a.data.rarity == b.data.rarity then
            return a.name < b.name
        end
        return a.data.rarity < b.data.rarity
    end)
    
    for _, item in ipairs(sortedItems) do
        local name = item.name
        local data = item.data
        local sizeText = data.size and (" [Size: " .. data.size .. "]") or ""
        local modifierText = data.modifier and (" [Mod: " .. data.modifier .. "]") or ""
        local shinyText = data.isShiny and " ✨" or ""
        local totalItemValue = data.finalPrice * data.count
        
        -- Tampilkan multiplier yang diapply
        local multiplierInfo = ""
        if data.isShiny or data.size or data.modifier then
            local multipliers = {}
            if data.size then table.insert(multipliers, "Size") end
            if data.modifier then table.insert(multipliers, "Modifier") end
            if data.isShiny then table.insert(multipliers, "Shiny 3") end
            multiplierInfo = " [" .. table.concat(multipliers, ", ") .. "]"
        end
        
        print(string.format("📦 %s x%d - %d coins each (Base: %d)%s (Total: %d)%s%s [%s]", 
            name, data.count, data.finalPrice, data.basePrice, multiplierInfo, totalItemValue, sizeText, modifierText, data.rarity))
    end
    
    print("\n=== RINGKASAN ===")
    print("💰 Total Semua Item: " .. totalItems .. " pieces")
    print("💎 Total Nilai: " .. totalValue .. " coins")
    
    return {
        items = itemCounts,
        totalItems = totalItems,
        totalValue = totalValue
    }
end

-- Jalankan fungsi dengan error handling
local success, result = pcall(countAllItems)

if success then
    print("\n🎉 Script executed successfully!")
    -- Simpan hasil ke variabel global jika dibutuhkan
    _G.BackpackData = result
else
    print("\n❌ Error occurred: " .. tostring(result))
    print("\nDebugging info:")
    print("- Players service:", Players ~= nil)
    print("- LocalPlayer:", LocalPlayer ~= nil)
    print("- ReplicatedStorage:", ReplicatedStorage ~= nil)
    
    local backpackExists = pcall(function()
        return LocalPlayer.PlayerGui.Backpack ~= nil
    end)
    print("- Backpack GUI exists:", backpackExists)
    
    print("- Items Dictionary type:", type(ItemsDictionary))
    if ItemsDictionary then
        local itemCount = 0
        for _ in pairs(ItemsDictionary) do
            itemCount = itemCount + 1
        end
        print("- Items in dictionary:", itemCount)
    end
end