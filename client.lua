local isScoreboardOpen = false
local requestedData

Citizen.CreateThread(function() 
    ESX = nil

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    ESX.PlayerData = ESX.GetPlayerData()

    while true do
        Citizen.Wait(Config.updateScoreboardInterval)
        TriggerServerEvent("gs-scoreboard:updateValues")
    end
end)

local PlayerPedPreview
function createPedScreen(playerID)
    CreateThread(function()
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_JOINING_SCREEN"), true, -1)
        Citizen.Wait(100)
        N_0x98215325a695e78a(false)
        PlayerPedPreview = ClonePed(playerID, GetEntityHeading(playerID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        Wait(200)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
    end)
end

RegisterCommand('togglescoreboard', function()
    if not isScoreboardOpen then
        TriggerServerEvent('gs-scoreboard:requestUserData', tonumber(GetPlayerServerId(PlayerId())))
        if Config.showPlayerPed then
            SetFrontendActive(true)
            createPedScreen(PlayerPedId())
        end
        SendNUIMessage({
            action = "show",
            keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
        })
        SetNuiFocus(true,true)
        if Config.screenBlur then
            TriggerScreenblurFadeIn(Config.screenBlurAnimationDuration)
        end
        isScoreboardOpen = true
    elseif isScoreboardOpen then
        if Config.showPlayerPed then
            DeleteEntity(PlayerPedPreview)
            SetFrontendActive(false)
        end
        SendNUIMessage({
            action = "hide",
            keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
        })
        SetNuiFocus(false,false)
        isScoreboardOpen = false
        if Config.screenBlur then
            TriggerScreenblurFadeOut(Config.screenBlurAnimationDuration)
        end
    end
end, false)

RegisterKeyMapping('togglescoreboard', 'Show/Hide Scoreboard', 'keyboard', 'GRAVE')

RegisterNUICallback('closeScoreboard', function()
    ExecuteCommand('togglescoreboard')
end)

RegisterNetEvent("gs-scoreboard:addUserToScoreboard")
AddEventHandler(
    "gs-scoreboard:addUserToScoreboard",
    function(playerID, playerName, playerJob, playerGroup)
        SendNUIMessage(
            {
                action="addUserToScoreboard",
                playerID = playerID,
                playerName = playerName,
                playerJob = playerJob,
                playerGroup = playerGroup,
            }
        )
    end
)

RegisterNetEvent("gs-scoreboard:sendConfigToNUI")
AddEventHandler("gs-scoreboard:sendConfigToNUI",
    function()
        SendNUIMessage({
            action = "getConfig",
            config = json.encode(Config),
        })
    end
)

RegisterNetEvent("gs-scoreboard:sendIllegalActivity")
AddEventHandler("gs-scoreboard:sendIllegalActivity",
    function(data)
        SendNUIMessage({
            action = "addActivity",
            activity = data,
        })
    end
)

RegisterNetEvent("gs-scoreboard:setValues")
AddEventHandler(
    "gs-scoreboard:setValues",
    function(onlinePlayers, onlineStaff, onlinePolice, onlineEMS, onlineTaxi, onlineMechanics)
        SendNUIMessage(
            {
                action="updateScoreboard",
                onlinePlayers = onlinePlayers,
                onlineStaff = onlineStaff,
                onlinePolice = onlinePolice,
                onlineEMS = onlineEMS,
                onlineTaxi = onlineTaxi,
                onlineMechanics = onlineMechanics,
            }
        )
    end
)

RegisterNetEvent("gs-scoreboard:refrehScoreboard")
AddEventHandler(
    "gs-scoreboard:refrehScoreboard",
    function()
        SendNUIMessage(
            {
                action="refreshScoreboard",
            }
        )
    end
)

RegisterNUICallback('showPlayerPed', function(data)
    TriggerServerEvent('gs-scoreboard:requestUserData', tonumber(data.playerID))
    if Config.showPlayerPed then
        local playerID = data.playerID
        DeleteEntity(PlayerPedPreview)
        local playerTargetID = GetPlayerPed(GetPlayerFromServerId(playerID))
        PlayerPedPreview = ClonePed(playerTargetID, GetEntityHeading(playerTargetID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
    end
end)

RegisterNetEvent("gs-scoreboard:receiveRequestedData")
AddEventHandler(
    "gs-scoreboard:receiveRequestedData",
    function(from, data)
        requestedData = data
        local tooFar = false
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - data.playerCoords) > 300 then
            tooFar = true
        end
        SendNUIMessage(
        {
            action="playerInfoUpdate",
            playerName = requestedData.playerName,
            playerID = requestedData.playerID,
            timePlayed = requestedData.timePlayed,
            roleplayName = requestedData.roleplayName,
            tooFar = tooFar,
        })
    end
)

RegisterNetEvent("gs-scoreboard:retrieveUserData")
AddEventHandler(
    "gs-scoreboard:retrieveUserData",
    function(from, to)
        local data = {}
        data.playerName = GetPlayerName(PlayerId())
        data.playerID = to
        data.playerCoords = GetEntityCoords(PlayerPedId())
        local retVal, timePlayed = StatGetInt('mp0_total_playing_time')
        data.timePlayed = timePlayed
        TriggerServerEvent('gs-scoreboard:sendRequestedData', from, data)
    end
)
