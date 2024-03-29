if Config.OldESX == true then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

function Sanitize(str)
    local replacements = {
        ['&' ] = '&amp;',
        ['<' ] = '&lt;',
        ['>' ] = '&gt;',
        ['\n'] = '<br/>'
    }
    return str
        :gsub('[&<>\n]', replacements)
        :gsub(' +', function(s)
            return ' '..('&nbsp;'):rep(#s-1)
        end)
end

function RefreshScoreboard()
    local xPlayers = ESX.GetExtendedPlayers()
    TriggerClientEvent("gs-scoreboard:refrehScoreboard", -1)
    getIllegalActivitesData()
    for _, xPlayer in pairs(xPlayers) do
        local playerID = xPlayer.source
        local playerName = Sanitize(xPlayer.getName())
        local playerJob = xPlayer.job.label
        local playerGroup = xPlayer.getGroup()
        TriggerClientEvent("gs-scoreboard:addUserToScoreboard", -1, playerID, playerName, playerJob, playerGroup)
        TriggerClientEvent("gs-scoreboard:sendConfigToNUI", -1)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Citizen.Wait(1000)
        RefreshScoreboard()
    end
    TriggerClientEvent("gs-scoreboard:sendConfigToNUI", -1)
end)

RegisterCommand("refreshscoreboard", function()
    RefreshScoreboard()
end, true)

RegisterServerEvent("gs-scoreboard:updateValues")
AddEventHandler(
    "gs-scoreboard:updateValues",
    function()
        local onlinePlayers = getOnlinePlayers()
        local onlineStaff = getOnlineStaff()
        local onlinePolice = getOnlineByType(Config.policeCounterType,Config.policeCounterIdentifier)
        local onlineEMS = getOnlineByType(Config.emsCounterType,Config.emsCounterIdentifier)
        local onlineTaxi = getOnlineByType(Config.taxiCounterType,Config.taxiCounterIdentifier)
        local onlineMechanics = getOnlineByType(Config.mechanicCounterType,Config.mechanicCounterIdentifier)
        TriggerClientEvent("gs-scoreboard:setValues", -1, onlinePlayers, onlineStaff, onlinePolice, onlineEMS, onlineTaxi, onlineMechanics, illegalActivites)
    end
)

RegisterNetEvent('gs-scoreboard:requestUserData')
AddEventHandler(
    'gs-scoreboard:requestUserData',
    function(target)
        TriggerClientEvent("gs-scoreboard:retrieveUserData", tonumber(target), source, tonumber(target))
    end
)

RegisterNetEvent('gs-scoreboard:sendRequestedData')
AddEventHandler(
    'gs-scoreboard:sendRequestedData',  
    function(to, data)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer ~= nil then
            data.roleplayName = xPlayer.getName()
            TriggerClientEvent("gs-scoreboard:receiveRequestedData", to, source, data)
        end
    end
)

AddEventHandler(
    'esx:playerLoaded',  
    function()
        Citizen.Wait(500)
        RefreshScoreboard()
    end
)

AddEventHandler(
    'playerDropped', 
    function()
        Citizen.Wait(500)
        RefreshScoreboard()
    end
)
  

function getOnlinePlayers()
    local xPlayers = ESX.GetExtendedPlayers()
    return #xPlayers
end

function getOnlineStaff()
    local xPlayersTotal = ESX.GetExtendedPlayers()
    local xPlayersUsers = ESX.GetExtendedPlayers('group','user')
    return (#xPlayersTotal - #xPlayersUsers)
end

function getOnlineByType(type, value)
    local xPlayers = ESX.GetPlayers()
    local counter = 0

    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if type == "group" and xPlayer.getGroup() == value then
            counter = counter + 1
        elseif type == "job" and xPlayer.getJob().name == value then
            counter = counter + 1
        end
    end

    return counter
end

function getIllegalActivitesData()
    local data = Config.illegalActivites
    for i = 1,#data do
        data[i]["onlinePlayers"] = getOnlinePlayers()
        data[i]["onlineGroup"] = getOnlineByType(data[i]["groupType"],data[i]["groupName"])
        TriggerClientEvent("gs-scoreboard:sendIllegalActivity",-1,data[i])
    end
    return data
end
