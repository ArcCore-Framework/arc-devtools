---@param vecType number
RegisterNetEvent('arc_dev:client:getVec', function(vecType)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local vectorString = ""
    if vecType == 4 then
        vectorString = string.format("vec4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)
    elseif vecType == 3 then
        vectorString = string.format("vec3(%.2f, %.2f, %.2f)", coords.x, coords.y, coords.z)
    elseif vecType == 2 then
        vectorString = string.format("vec2(%.2f, %.2f)", coords.x, coords.y)
    else
        print("Invalid vector type")
        return
    end

    if lib and lib.setClipboard then
        lib.setClipboard(vectorString)
        print("Copied to clipboard:", vectorString)
    end
end)

RegisterNetEvent('arc_dev:client:getHeading', function()
    local playerPed = PlayerPedId()
    local heading = GetEntityHeading(playerPed)
    lib.setClipboard(string.format("%.2f", heading))
end)

RegisterNetEvent('arc_dev:client:tpm', function()
    local ped = PlayerPedId()
    local waypointBlip = GetFirstBlipInfoId(8)

    if not DoesBlipExist(waypointBlip) then
        print('No waypoint set')
        return
    end

    -- Get current position in case we need to return
    local oldCoords = GetEntityCoords(ped)
    local blipCoords = GetBlipCoords(waypointBlip)
    local x, y = blipCoords.x, blipCoords.y
    local groundZ, Z_START = 850.0, 950.0
    local found = false

    -- Fade out screen before teleporting
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle > 0 then
        FreezeEntityPosition(vehicle, true)
    else
        FreezeEntityPosition(ped, true)
    end

    -- Try to find ground using a for loop
    for z = Z_START, 0, -25.0 do
        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()

        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then break end
            Wait(0)
        end
        NewLoadSceneStop()

        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then break end
            Wait(0)
        end

        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ + 1.0)
            break
        end
        Wait(0)
    end

    -- Fade back in
    DoScreenFadeIn(500)

    if vehicle > 0 then
        FreezeEntityPosition(vehicle, false)
    else
        FreezeEntityPosition(ped, false)
    end

    -- If no ground was found, return to original position
    if not found then
        SetPedCoordsKeepVehicle(ped, oldCoords.x, oldCoords.y, oldCoords.z - 1.0)
        print("No valid ground found, returning to original position.")
    end
end)
