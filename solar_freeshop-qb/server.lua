
local QBCore = exports['qb-core']:GetCoreObject()
-- ✅ Load config.lua manually using FiveM-safe method
-- Load config.lua
local configCode = LoadResourceFile(GetCurrentResourceName(), "config.lua")
if configCode then
    assert(load(configCode))()
    print("[SERVER] config.lua loaded ✅")
else
    print("[SERVER] ERROR: config.lua NOT FOUND ❌")
end

print("[SERVER] server.lua loaded ✅")

-- ✅ Version Checker
local CURRENT_VERSION = "1.0.1"
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/MRdivine17/Solar-store-UI/main/solar_freeshop-qb/version.json"

CreateThread(function()
    Wait(2000)
    PerformHttpRequest(GITHUB_RAW_URL, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data and data.version then
                if data.version ~= CURRENT_VERSION then
                    print("^3========================================^0")
                    print("^3[VERSION CHECK] UPDATE AVAILABLE!^0")
                    print("^3Current Version: ^1" .. CURRENT_VERSION .. "^0")
                    print("^3Latest Version: ^2" .. data.version .. "^0")
                    if data.changelog then
                        print("^3Changelog: ^0" .. data.changelog)
                    end
                    print("^3Update at: https://github.com/MRdivine17/Solar-store-UI^0")
                    print("^3========================================^0")
                else
                    print("^2[VERSION CHECK] You are running the latest version (" .. CURRENT_VERSION .. ")^0")
                end
            else
                print("^1[VERSION CHECK] Failed to parse version data^0")
            end
        else
            print("^1[VERSION CHECK] Failed to check for updates (Status: " .. statusCode .. ")^0")
        end
    end, "GET")
end)

-- Grab QBCore object
local QBCore = nil

CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        if QBCore == nil then
            -- fallback (recommended for newer versions)
            QBCore = exports['qb-core']:GetCoreObject()
        end
        Wait(100)
    end

    print("[SERVER] QBCore loaded ✅")
    print("[SERVER] Is Config present at startup?", Config and "YES" or "NO")
end)


-- NUI callback to send item data
local QBCore = exports['qb-core']:GetCoreObject()

-- Register server callback for QBCore
QBCore.Functions.CreateCallback("free_shop:getItems", function(source, cb)
    print("[CALLBACK] Received getItems request")

    if not Config then
        print("[CALLBACK] ERROR: Config is nil")
        cb({})
        return
    end

    if not Config.Items then
        print("[CALLBACK] ERROR: Config.Items is nil")
        cb({})
        return
    end

    local result = {}

    for category, items in pairs(Config.Items) do
        print(string.format("[CALLBACK] Processing category: %s (%d items)", category, #items))
        result[category] = {}

        for _, item in ipairs(items) do
            local label = item.label or QBCore.Shared.Items[item.name]?.label or item.name
            local image = string.format("nui://%s/ui/images/%s.png", GetCurrentResourceName(), item.name)

            table.insert(result[category], {
                name = item.name,
                label = label,
                price = item.price,
                image = image
            })
        end
    end

    print("[CALLBACK] Sending data to client")
    cb(result)
end)


-- Event: give item to player
RegisterNetEvent("free_shop:buyItem", function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "add") -- optional visual feedback
        print(("[SERVER] Gave 1x %s to %s"):format(itemName, Player.PlayerData.name))
    else
        print("[SERVER] ERROR: Player not found")
    end
end)


RegisterNetEvent("free_shop:completePurchase", function(method, cart)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        print("[SERVER] ERROR: Player not found")
        return
    end

    local totalCost = 0

    -- Calculate total cost
    for itemName, itemData in pairs(cart) do
        local price = tonumber(itemData.price)
        local qty = tonumber(itemData.quantity)

        if not price or not qty or price < 0 or qty <= 0 then
            print(("[SERVER] Invalid item data for '%s'"):format(itemName))
            return
        end

        totalCost = totalCost + (price * qty)
    end

    -- Check payment method
    local hasMoney = false
    if method == "cash" then
        hasMoney = Player.Functions.GetMoney("cash") >= totalCost
    elseif method == "bank" then
        hasMoney = Player.Functions.GetMoney("bank") >= totalCost
    else
        print("[SERVER] Invalid payment method")
        return
    end

    if not hasMoney then
        TriggerClientEvent("ox_lib:notify", src, {
            type = "error",
            title = "Purchase Failed",
            description = "Not enough money."
        })
        return
    end

    -- Deduct money
    Player.Functions.RemoveMoney(method, totalCost)

    -- Give items
    for itemName, itemData in pairs(cart) do
        local qty = tonumber(itemData.quantity)
        if qty and qty > 0 then
            Player.Functions.AddItem(itemName, qty)
            TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemName], "add") -- Optional item box
        end
    end

    print(("[SERVER] %s bought items for ₹%s via %s"):format(Player.PlayerData.name, totalCost, method))

    -- Success notify
    TriggerClientEvent("ox_lib:notify", src, {
        type = "success",
        title = "Purchase Successful",
        description = "Thank you for your purchase!"
    })
end)


RegisterNetEvent("free_shop:getBillData", function(shopId, cart, customerName)
    local src = source
    local shopName = "Unknown Shop"

    for _, shop in pairs(Config.Shops) do
        if shop.id == shopId then
            shopName = shop.label
            break
        end
    end

    TriggerClientEvent("free_shop:sendBillData", src, {
        customer = customerName,
        shop = shopName,
        cart = cart
    })
end)

local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback("getPlayerNameFromServer", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        cb(Player.PlayerData.name)
    else
        cb("Customer")
    end
end)

