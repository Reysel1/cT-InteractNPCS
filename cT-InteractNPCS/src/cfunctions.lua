
function createMenu(array, cb) 
    exports['cT-Menu']:createContextMenu(array, function(callback) 
        cb(callback)
    end)
end


function Notify(text, type)
    exports['cT-Interface']:Notify(text, type)
end

---------------------------------------

function isPedArmed(ped, weaponTypes)
    if (IsPedArmed(ped, weaponTypes)) then 
        return true
    end
    return false
end

function getClosesPedData(ped, pedCoords, radius)
    local peds = GetGamePool('CPed')
    local closePeds = {}
    for i = 1, #peds do 
        local dist = #(GetEntityCoords(peds[i]) - pedCoords)
        if dist < radius then
            table.insert(closePeds, {
                returnPedsHash = GetEntityModel(peds[i]),
                returnPedsCoords = GetEntityCoords(peds[i]),
                returnPedsHealth = GetEntityHealth(peds[i]),
                returnPedid = peds[i],
            })
        end
    end
    return closePeds
end

function aimIngToPed(pedCloses)
    local isAiming, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if isAiming then
        for i = 1, #pedCloses do
            if pedCloses[i].returnPedid and aimedEntity == pedCloses[i].returnPedid then
                return true, GetEntityCoords(aimedEntity), aimedEntity
            end
        end
    end
    return false
end


function stopEntityAnims(entity)
end

function createText3d(text, coords) 
    coords = vector3(coords.x, coords.y, coords.z)

    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)

    local scale = (0.8 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.40 * scale)
    SetTextFont(0)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)

    SetDrawOrigin(coords, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function setupPedForFollowing(ped)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, false)
    SetPedCombatAttributes(ped, 0, false)
    SetPedAsEnemy(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedDropsWeaponsWhenDead(ped, false)
end

function ensurePedStoresWeapon(ped)
    if IsPedArmed(ped, 6) then
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
    end
end

function findEmptySeat(vehicle)
    local seatCount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for seatIndex = -1, seatCount - 2 do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            return seatIndex
        end
    end
    return nil
end

function manageVehicleEntry(ped, target)
    local playerInVehicle = IsPedInAnyVehicle(ped, false)
    local targetInVehicle = IsPedInAnyVehicle(target, false)

    if playerInVehicle then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not targetInVehicle then
            local emptySeat = findEmptySeat(vehicle)
            if emptySeat ~= nil then
                TaskWarpPedIntoVehicle(target, vehicle, emptySeat)
                local timeout = GetGameTimer() + 5000
                while not IsPedInVehicle(target, vehicle, false) and GetGameTimer() < timeout do
                    Wait(100)
                end
                if not IsPedInVehicle(target, vehicle, false) then
                    TaskEnterVehicle(target, vehicle, -1, emptySeat, 1.5, 1, 0)
                    timeout = GetGameTimer() + 5000
                    while not IsPedInVehicle(target, vehicle, false) and GetGameTimer() < timeout do
                        Wait(100)
                    end
                end
            else
                Notify('No hay asientos disponibles en el vehículo', 'error')
            end
        end
    elseif targetInVehicle then
        local targetVehicle = GetVehiclePedIsIn(target, false)
        if targetVehicle then
            TaskLeaveVehicle(target, targetVehicle, 0)
            local timeout = GetGameTimer() + 5000
            while IsPedInVehicle(target, targetVehicle, false) and GetGameTimer() < timeout do
                Wait(100)
            end
        end
    end
end


function startFollowing(ped, target)
    if not DoesEntityExist(target) then
        return
    end

    setupPedForFollowing(target)
    Notify('El ped ha empezado a seguirte', 'info')
    setTableData('add', {
        type = 'following',
        id = target,
        isFollowing = true
    })

    CreateThread(function()
        while true do
            local pedData = getPedData(target)
            if not pedData or not DoesEntityExist(target) then
                setTableData('remove', target)
                return
            end

            ensurePedStoresWeapon(target)

            local playerCoords = GetEntityCoords(ped)
            local targetCoords = GetEntityCoords(target)
            local distance = #(playerCoords - targetCoords)

            if distance > 2.0 then
                TaskGoToEntity(target, ped, -1, 2.0, 10.0, 1073741824, 0)
            else
                ClearPedTasks(target)
            end

            manageVehicleEntry(ped, target)

            Wait(500)
        end
    end)
end

function getPedData(ped)
    for _, pedData in ipairs(followingPeds) do
        if pedData.id == ped then
            return pedData
        end
    end
    return nil
end

function setTableData(action, data)
    if action == 'add' then
        table.insert(followingPeds, data)
    elseif action == 'remove' then
        for i = #followingPeds, 1, -1 do
            if followingPeds[i].id == data then
                table.remove(followingPeds, i)
                break
            end
        end
    elseif action == 'update' then
        for i, pedData in ipairs(followingPeds) do
            if pedData.id == data.id then
                followingPeds[i] = data
                break
            end
        end
    end
end

function stopFollowing(target)
    local pedData = getPedData(target)

    if not pedData then
        return
    end
    setTableData('remove', target)

    ClearPedTasks(target)
    ResetPedMovementClipset(target, 0)
    ResetPedWeaponMovementClipset(target)
    ResetPedStrafeClipset(target)
    Notify('El ped ha dejado de seguirte', 'info')
end


function drawM(type, coords)
    DrawMarker(type, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 0, 0, 250, false, true, 2, true, nil, nil, false)
end

function getDataFromPedArray(entity, type)
    for _, pedData in ipairs(followingPeds) do
        if pedData.id == entity then
            if (pedData.type == type) then
                return true
            end
        end
    end
    return nil
end

function onMenuOptionSelected(entity)
    local playerPed = PlayerPedId()
    startFollowing(playerPed, entity)
end

function initSurrender(entity, animData)
    setTableData('add', {
        type = 'surrender',
        id = entity,
        isSurrendering = true
    })

    initAnim(entity, animData)
    ensureSurrender(entity, animData)
end

function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
end

function initAnim(entity, animData)
    loadAnimDict(animData.animDic)
    TaskPlayAnim(entity, animData.animDic, animData.animName, 8.0, 8.0, -1, 1, 0, false, false, false)
end

function cancelSurrender(entity)
    local pedData = getPedData(entity)
    if not pedData or pedData.type ~= 'surrender' then
        return
    end

    setTableData('remove', entity)
    
    ClearPedTasks(entity)
    ResetPedMovementClipset(entity, 0)
    ResetPedWeaponMovementClipset(entity)
    ResetPedStrafeClipset(entity)
end

function ensureSurrender(entity, animData)
    CreateThread(function()
        while true do
            local pedData = getPedData(entity)
            if not pedData or not pedData.isSurrendering then
                return
            end

            local animDict = animData.animDic
            local animName = animData.animName

            if not IsEntityPlayingAnim(entity, animDict, animName, 3) then
                initAnim(entity, animData)
            end

            Wait(1000)
        end
    end)
end