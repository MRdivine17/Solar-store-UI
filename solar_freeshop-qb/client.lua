local QBCore = exports['qb-core']:GetCoreObject()
local createdPeds = {}

RegisterNetEvent("shop:client:openShop", function(shopId)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openShop",
        shopId = shopId
    })
end)

RegisterNUICallback("closeShop", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- OPTIONAL: Command to test opening UI manually
RegisterCommand("openshop", function()
    TriggerEvent("shop:client:openShop", "burger_shop")
    TriggerEvent("solar_freeshop:getName")
end, false)


CreateThread(function()
    while not Config or not Config.Shops do Wait(100) end

    for _, shop in pairs(Config.Shops) do
        -- Load and spawn ped
        local pedModel = shop.ped or "a_m_m_business_01"
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(10)
        end

        local coords = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
        local heading = shop.heading or 0.0

        local ped = CreatePed(0, pedModel, coords.x, coords.y, coords.z - 1.0, heading, false, true)

        if DoesEntityExist(ped) then
            print("[FreeShop] Ped spawned at:", coords.x, coords.y, coords.z)
        else
            print("[FreeShop] ❌ Failed to spawn ped!")
        end

        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        table.insert(createdPeds, ped)

        -- ✅ QB-Target Setup
        exports['qb-target']:AddCircleZone(shop.id, coords, 2.0, {
            name = shop.id,
            debugPoly = false,
            useZ = true
        }, {
            options = {
                {
                    type = "client",
                    icon = "fas fa-store",
                    label = ("Open %s"):format(shop.label),
                    action = function()
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            action = "openShop",
                            shopId = shop.id
                        })
                    end
                }
            },
            distance = 2.0
        })
        -- Blip setup
        if shop.blip then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, shop.blip.sprite or 52)
            SetBlipScale(blip, shop.blip.scale or 0.8)
            SetBlipDisplay(blip, 4)
            SetBlipColour(blip, shop.blip.color or 0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.label or shop.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)


-- Cleanup on stop
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(createdPeds) do
        DeleteEntity(ped)
    end
end)

-- Close UI
RegisterNUICallback("closeUI", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- Get items
RegisterNUICallback("getItems", function(data, cb)
    local result = {}
    local shopId = data.shopId or "default"

    for _, shop in pairs(Config.Shops) do
        if shop.id == shopId then
            for _, category in ipairs(shop.categories or {}) do
                result[category] = Config.Categories[category] or {}
            end
            break
        end
    end

    cb(result)
end)

-- Complete purchase
RegisterNUICallback("completePurchase", function(data, cb)
    -- Forward to server via NetEvent
    TriggerServerEvent("free_shop:completePurchase", data.method, data.cart)
    cb({ success = true }) -- Let NUI know it can proceed (hide UI etc)
end)

local currentShopId = nil
local cartItems = {}

RegisterNUICallback("requestBillData", function(data, cb)
    local player = PlayerId()
    local playerName = GetPlayerName(player)

    TriggerServerEvent("free_shop:getBillData", data.shopId, data.cart, playerName)
    cb({})
end)

RegisterNetEvent("free_shop:sendBillData", function(data)
    SendNUIMessage({
        type = "showBillData",
        payload = {
            customerName = data.customer,
            shopName = data.shop
        }
    })
end)

-- When server sends back bill info
RegisterNetEvent("free_shop:sendBillData", function(data)

    -- Send the final info to NUI
    SendNUIMessage({
        type = "toggleBillUI",
        show = true,
        customerName = data.customer,
        shopName = data.shop,
        cart = data.cart
    })
end)

RegisterNUICallback("getPlayerNameFromServer", function(_, cb)
    local name = "Customer"

    QBCore.Functions.TriggerCallback("getPlayerNameFromServer", function(serverName)
        name = serverName or "Customer"
        cb({ playerName = name }) -- ✅ return proper JSON
    end)
end)


