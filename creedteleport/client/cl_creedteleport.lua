local airportCircle = { x = -947.18, y = -3533.08, z = 14.07, radius = 10.0 }
local cayoCircle = { x = 4500.0, y = -4500.0, z = 4.0, radius = 10.0 }
local heliModel = "cargobob"
local blipSprite = 64 -- Blip Shown on map
local blipColor = 1 -- Green color

-- Adjusted flare positions next to the helicopter
local flareOffset1 = vector3(3.0, 3.0, 0.0)  -- Offset for the first flare
local flareOffset2 = vector3(-3.0, -3.0, 0.0) -- Offset for the second flare on the opposite side

local isNearCircle = false
local currentCircle = nil

local lastFlare1 = nil
local lastFlare2 = nil

-- Define teleport locations
local cayoLocations = {
    vector3(4264.13, -4275.83, 2.53),
    vector3(4646.24, -4447.64, 7.0),
    vector3(4817.72, -4307.69, 5.46),
    vector3(4886.19, -4380.03, 1.72),
    vector3(4969.31, -4473.8, 10.4),
    vector3(5110.66, -4583.2, 4.39),
    vector3(5179.26, -4589.14, 3.75),
    vector3(5175.31, -4676.64, 2.44),
    vector3(5097.66, -4891.42, 17.03),
    vector3(5161.26, -4943.76, 13.86),
    vector3(5269.73, -5020.96, 22.71),
    vector3(5384.91, -5199.48, 31.72),
    vector3(5461.15, -5238.15, 27.54),
    vector3(5264.48, -5426.11, 65.6),
    vector3(5265.19, -5639.12, 43.23),
    vector3(5080.35, -5724.49, 15.77),
    vector3(4985.15, -5717.34, 25.23),
    vector3(4888.51, -5736.47, 26.35),
    vector3(4881.64, -5457.18, 29.55)
}

local airportOffsetLocation = vector3(-937.18, -3533.08, 14.07) -- 10 meters away from the helicopter

-- Create the blips
local function createBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipSprite)
    SetBlipColour(blip, blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Extraction Point")
    EndTextCommandSetBlipName(blip)
end

createBlip(airportCircle)
createBlip(cayoCircle)

-- Function to spawn helicopter
local function spawnHelicopter(coords)
    RequestModel(heliModel)
    while not HasModelLoaded(heliModel) do
        Wait(0)
    end
    local helicopter = CreateVehicle(heliModel, coords.x, coords.y, coords.z, 0.0, true, false)
    SetEntityAsMissionEntity(helicopter, true, true)
    SetVehicleDoorsLocked(helicopter, 2) -- Locked
    FreezeEntityPosition(helicopter, true) -- Immovable
    SetEntityInvincible(helicopter, true)
    return helicopter
end

-- Function to check player proximity to circle
local function isPlayerInCircle(circle)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, circle.x, circle.y, circle.z)
    return distance < circle.radius
end

-- Function to draw a visible red marker (circle) on the ground
local function drawCircleMarker(coords, radius)
    DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2, radius * 2, 0.5, 255, 0, 0, 150, false, false, 2, false, nil, nil, false)
end

-- Function to shoot two flares at specific locations every 20 seconds
local function startFlareLoop(coords1, coords2)
    Citizen.CreateThread(function()
        while true do
            -- Remove the last flares if they exist
            if lastFlare1 then
                DeleteEntity(lastFlare1)
            end
            if lastFlare2 then
                DeleteEntity(lastFlare2)
            end

            -- Shoot the first flare and store its entity
            lastFlare1 = ShootSingleBulletBetweenCoords(
                coords1.x, coords1.y, coords1.z,
                coords1.x, coords1.y, coords1.z - 1,
                0, false, GetHashKey("weapon_flare"), 0, true, true, -1.0
            )

            -- Shoot the second flare and store its entity
            lastFlare2 = ShootSingleBulletBetweenCoords(
                coords2.x, coords2.y, coords2.z,
                coords2.x, coords2.y, coords2.z - 1,
                0, false, GetHashKey("weapon_flare"), 0, true, true, -1.0
            )

            Wait(20000) -- Wait 20 seconds before deploying the next flares
        end
    end)
end

-- Spawning helicopters and flares
local airportHeli = spawnHelicopter(airportCircle)
local cayoHeli = spawnHelicopter(cayoCircle)

-- Calculate flare positions based on the helicopter positions and offsets
local airportFlareCoords1 = GetEntityCoords(airportHeli) + flareOffset1
local airportFlareCoords2 = GetEntityCoords(airportHeli) + flareOffset2
local cayoFlareCoords1 = GetEntityCoords(cayoHeli) + flareOffset1
local cayoFlareCoords2 = GetEntityCoords(cayoHeli) + flareOffset2

-- Start flare loops on both sides of the helicopters
startFlareLoop(airportFlareCoords1, airportFlareCoords2)
startFlareLoop(cayoFlareCoords1, cayoFlareCoords2)

-- Function to select a random location from the predefined Cayo Perico locations
local function getRandomCayoLocation()
    return cayoLocations[math.random(#cayoLocations)]
end

-- Function to display countdown during teleportation
local function teleportWithCountdown(coords, fromLocation, toLocation, randomCayo, offsetHeli)
    for i = 3, 1, -1 do
        local endTime = GetGameTimer() + 1000
        while GetGameTimer() < endTime do
            -- Display the countdown text
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 1.0)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("Extracting in " .. i)
            DrawText(0.5, 0.5)
            Citizen.Wait(0) -- Ensure the text is continuously drawn during this second
        end
    end

    -- After the countdown, fade the screen and teleport
    DoScreenFadeOut(1000)
    Wait(1000)

    if randomCayo then
        coords = getRandomCayoLocation()
    elseif offsetHeli then
        coords = airportOffsetLocation
    end

    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    TriggerServerEvent('creedteleport:logTeleport', GetPlayerServerId(PlayerId()), fromLocation, toLocation)
    Wait(1000)
    DoScreenFadeIn(1000)
end

-- Main thread to handle teleportation and drawing markers
Citizen.CreateThread(function()
    while true do
        Wait(0)
        isNearCircle = false
        if isPlayerInCircle(airportCircle) then
            isNearCircle = true
            currentCircle = "airport"
        elseif isPlayerInCircle(cayoCircle) then
            isNearCircle = true
            currentCircle = "cayo"
        end

        -- Draw the circle markers on the ground
        drawCircleMarker(airportCircle, airportCircle.radius)
        drawCircleMarker(cayoCircle, cayoCircle.radius)

        if isNearCircle then
            DisplayHelpText("Press ~INPUT_CONTEXT~ To Extract")

            if IsControlJustReleased(0, 38) then -- E key
                if currentCircle == "airport" then
                    teleportWithCountdown(cayoCircle, "Airport", "Cayo Perico", true, false) -- Random Cayo Location
                elseif currentCircle == "cayo" then
                    teleportWithCountdown(airportCircle, "Cayo Perico", "Airport", false, true) -- Specific location 10 meters away from the helicopter at the airport
                end
            end
        end
    end
end)

-- Function to display help text
function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

























