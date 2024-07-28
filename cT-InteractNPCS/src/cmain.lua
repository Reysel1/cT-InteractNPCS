SetPoliceIgnorePlayer(PlayerPedId(), true)
SetEveryoneIgnorePlayer(PlayerPedId(), true)
SetPlayerCanBeHassledByGangs(PlayerPedId(), false)
SetIgnoreLowPriorityShockingEvents(PlayerPedId(), true)


CreateThread(function() 
    while true do
        local msc = 0
        local ped = PlayerPedId()
        local armed = IsPedArmed(ped, shared.intConfig.armedType)
        local getPedCloses = getClosesPedData(ped, GetEntityCoords(ped), shared.intConfig.distanceToInteract)
        local aiming, pedCoordsAimming, entity = aimIngToPed(getPedCloses)

        SetBlockingOfNonTemporaryEvents(entity,true)
        SetPedFleeAttributes(entity, 0, 0)
        SetPedCombatAttributes(entity, 17, 1)
        if(GetPedAlertness(entity) ~= 0) then
            SetPedAlertness(entity,0)
        end

        msc = shared.intConfig.mscUpdate

        if (armed and aiming) then 
            msc = 0
            createText3d('E - To Interact', vec3(pedCoordsAimming.x, pedCoordsAimming.y, pedCoordsAimming.z + 1.2))
            drawM(2, vec3(pedCoordsAimming.x, pedCoordsAimming.y, pedCoordsAimming.z + 1.0))


       
            if (IsControlJustPressed(0, 38)) then 
                local menuArray = {
                    id = string.format('interact_%s', entity),
                    titleConfig = {
                        menuTitle = "Interact Menu",
                        menuTitleType = 'animated',
                        menuTitleIcon = "hrjifpbq",
                    },
                    menuItems = {
                        {
                            title = "Surrender",
                            description =  getDataFromPedArray(entity, 'surrender') and "Cancelar rendición" or "Rendirse",
                            icon = "fa-solid fa-gun",
                            closeClick = false,
                            params = {
                                handler = function()
                                    local boolData = getDataFromPedArray(entity, 'surrender')
                                    if (not boolData) then 
                                        stopFollowing(entity)
                                        Wait(500)
                                        initSurrender(entity, shared.animsConfig.surrender)
                                    else
                                        cancelSurrender(entity)
                                        onMenuOptionSelected(entity)
                                    end
                                end
                            }
                        },
                        {
                            title = "Que te siga",
                            description = getDataFromPedArray(entity, 'following') and "Dejar de seguir" or "Hacer que este ped te siga",
                            icon = "fa-solid fa-person-running",
                            closeClick = true,
                            params = {
                                handler = function()
                                    local boolData = getDataFromPedArray(entity, 'following')
                                    if (boolData) then 
                                        stopFollowing(entity)
                                    else
                                        cancelSurrender(entity)
                                        Wait(500)
                                        onMenuOptionSelected(entity)
                                    end
                                end
                            }
                        }
                    }
                }
                createMenu(menuArray, function(callback) 
                    if (callback == 'close') then 
                        FreezeEntityPosition(entity, false)
                    end
                end)
            end
        end
        Wait(msc)
    end
end)
