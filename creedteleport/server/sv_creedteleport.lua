RegisterServerEvent('creedteleport:logTeleport')
AddEventHandler('creedteleport:logTeleport', function(playerId, fromLocation, toLocation)
    local playerName = GetPlayerName(playerId)
    print(('[Teleport] %s teleported from %s to %s'):format(playerName, fromLocation, toLocation))
end)

