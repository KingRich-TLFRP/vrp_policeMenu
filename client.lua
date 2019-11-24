Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)

        TriggerServerEvent('checkPermission')
    end
end)

local isPolice = false

local Keys = {
    ['Menu'] = 167,
    ['Placcaggio'] = 47,
    ['Radio'] = 19
}
local lastTackleTime = 0

local radioDict, radioNameOne, radioNameTwo = 'random@arrests', 'generic_radio_enter', 'radio_chatter'
local tackleLib, tackleAnim, tackleVictimAnim = 'missmic2ig_11', 'mic_2_ig_11_intro_goon', 'mic_2_ig_11_intro_p_one'
local isTackling, isGettingTackled, isRagdoll = false, false, false

menu_polizia = false

local FineMenu, CivileMenu, VehMenu = {
    {label = 'Metti in carcere', value = 'jail'},
    {label = 'Scarcera', value = 'unjail'}
}, {
    {label = 'Controlla Armi', value = 'seizeWeapons'},
    {label = 'Controlla Oggetti',value = 'seizeItems'},
    {label = 'Ammanetta', value = 'cuff'},
    {label = 'Togli Manette', value = 'uncuff'},
    {label = 'Trascina', value = 'drag'},
    {label = 'Metti nel veicolo', value = 'putInVeh'},
    {label = 'Togli dal veicolo', value = 'removeFromVeh'}
}, {
    {label = 'Scassina veicolo', value = 'forceVehicle'},
    {label = 'Megafono 1', value = 'megafonoOne'},
    {label = 'Controlla Targa', value = 'checkPlate'}
}

RegisterNetEvent('returnPermissionYes')
AddEventHandler('returnPermissionYes', function()
    isPolice = true
end)

RegisterNetEvent('returnPermissionFalse')
AddEventHandler('returnPermissionFalse', function()
    isPolice = false
end)

function OpenPoliceMenu()
    Menu.SetupMenu('police_menu', 'Menu Poliziotto')
    Menu.Switch(nil, 'police_menu')

    Menu.addOption('police_menu', function()
        if Menu.Option('Azioni Civili') then
            OpenMenuFine()
        end
        if Menu.Option('Azioni Veicoli') then
            OpenMenuVeicolo()
        end
        if Menu.Option('Azioni Giuridiche') then
            OpenMenuFine()
        end
    end)
end

function OpenMenuFine()
    Menu.SetupMenu('fine_menu', 'Azioni Giuridiche')
    Menu.Switch('police_menu', 'fine_menu')

    Menu.addOption('fine_menu', function()
        for _, item in pairs(FineMenu) do
            if Menu.Option(item.label) then
                TriggerServerEvent('vrp_policeMenu:doAction', item.value)
            end
        end
    end)
end

function OpenMenuCivile()
    Menu.SetupMenu('civile_menu', 'Azioni Civili')
    Menu.Switch('police_menu', 'civile_menu')

    Menu.addOption('civile_menu', function()
        for _, item in pairs(CivileMenu) do
            if Menu.Option(item.label) then
                TriggerServerEvent('vrp_policeMenu:doAction', item.value)
            end
        end
    end)
end

function OpenMenuVeicolo()
    Menu.SetupMenu('vehicle_menu', 'Azioni Veicoli')
    Menu.Switch('police_menu', 'vehicle_menu')

    Menu.addOption('vehicle_menu', function()
        for _, item in pairs(VehMenu) do
            if Menu.Option(item.label) then
                TriggerServerEvent('vrp_policeMenu:doAction', item.value)
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isPolice then
            if IsControlJustReleased(0, Keys['Menu']) then
                menu_polizia = true

                OpenPoliceMenu()
            end
            if menu_polizia then
                Menu.DisplayCurMenu()
            end

            if IsControlPressed(0, Keys['Placcaggio']) and not isTackling and not IsPedInAnyVehicle(GetPlayerPed(-1), false) and GetGameTimer() - lastTackleTime > 10 * 1000 then
                Citizen.Wait(10)
                TriggerServerEvent('vrp_KoRadio:tryTackle')
            end

            local ped = PlayerPedId()
            local pedId = PlayerId()

            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                if not IsPauseMenuActive() then
                    if IsControlJustReleased(0, Keys['Radio']) then
                        loadAnimDict(radioDict)
                        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'off', 0.1)
                        ClearPedTasks(ped)
                        SetEnableHandcuffs(ped, false)
                    else
                        if IsControlJustPressed(0, Keys['Radio']) and not IsPlayerFreeAiming(pedId) then
                            loadAnimDict(radioDict)
                            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'on', 0.1)
                            TaskPlayAnim(ped, radioDict, radioNameOne, 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 )
                            SetEnableHandcuffs(ped, true)
                        elseif IsControlJustPressed(0, Keys['Radio']) and IsPlayerFreeAiming(pedId) then
                            loadAnimDict(radioDict)
                            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'on', 0.1)
                            TaskPlayAnim(ped, radioDict, radioNameTwo, 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 )
                            SetEnableHandcuffs(ped, true)
                        end
                        if IsEntityPlayingAnim(GetPlayerPed(pedId), radioDict, radioNameOne, 3) then
                            DisableActions(ped)
                        elseif IsEntityPlayingAnim(GetPlayerPed(pedId), radioDict, radioNameTwo, 3) then
                            DisableActions(ped)
                        end
                    end
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    loadAnimDict(tackleLib)
    loadAnimDict(cuffDict)
    loadAnimDict('mp_arrest_paired')
    loadAnimDict('mp_arresting')

    while true do
        Citizen.Wait(0)

        if isRagdoll then
            SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
        end
    end
end)

RegisterNetEvent('vrp_KoRadio:getTackled')
AddEventHandler('vrp_KoRadio:getTackled', function(target)
    loadAnimDict(tackleLib)
    isGettingTackled = true

    local playerPed, targetPed = GetPlayerPed(-1), GetPlayerPed(GetPlayerFromServerId(target))

    AttachEntityToEntity(GetPlayerPed(-1), targetPed, 11816, 0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
    TaskPlayAnim(playerPed, tackleLib, tackleVictimAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)

    Citizen.Wait(3000)

    DetachEntity(playerPed, true, false)

    isRagdoll = true
    Citizen.Wait(3000)
    isRagdoll = false

    isGettingTackled = false
end)

RegisterNetEvent('vrp_Ko_Radio:playTackle')
AddEventHandler('vrp_Ko_Radio:playTackle', function()
    loadAnimDict(tackleLib)
    local playerPed = GetPlayerPed(-1)

    TaskPlayAnim(playerPed, tackleLib, tackleAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)

	Citizen.Wait(3000)

	isTackling = false
end)

-- Arresto
local isCuffed, isCuffing = false, false
local isDragged = false
local copDragging = nil

local cuffDict, cuffNameOne, cuffNameTwo = 'mp_arrest_paired', 'cop_p2_back_left', 'crook_p2_back_left'

RegisterNetEvent('vrp_policeMenu:cuffPlayer')
AddEventHandler('vrp_policeMenu:cuffPlayer', function(target)
    isCuffing = true

    local playerPed, targetPlayerPed = GetPlayerPed(-1), GetPlayerPed(GetPlayerFromServerId(target))

    loadAnimDict(cuffDict)

    AttachEntityToEntity(playerPed, targetPlayerPed)
    TaskPlayAnim(playerPed, cuffDict, cuffNameTwo, 8.0, -8.0, 5500, 33, 0, false, false, false)

    Citizen.Wait(950)

    DetachEntity(playerPed, true, false)

    isCuffing = false
    isCuffed = true
end)

RegisterNetEvent('vrp_policeMenu:doAcunCuff')
AddEventHandler('vrp_policeMenu:doAcunCuff', function(target)
    isCuffed = false
end)

RegisterNetEvent('vrp_policeMenu:cuffAnim')
AddEventHandler('vrp_policeMenu:cuffAnim', function()
    local playerPed = GetPlayerPed(-1)

    loadAnimDict(cuffDict)

    TaskPlayAnim(playerPed, cuffDict, cuffNameOne, 8.0, -8.0, 5500, 33, 0, false, false, false)

    Citizen.Wait(3000)
end)

RegisterNetEvent('vrp_policeMenu:docheckPlate')
AddEventHandler('vrp_policeMenu:docheckPlate', function()
    local playerPed, coords = PlayerPedId(), GetEntityCoords(playerPed)

    if IsAnyVehicleNearPoint(coords, 5.0) then
        local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)
        local plate = GetVehicleNumberPlateText(vehicle)

        TriggerEvent('chat:addMessage', {
            color = {0, 0, 255},
            multiline = false,
            args = {"Police Menu", "Plate of the nearest vehicle: " .. plate}
        })
    end
end)

RegisterNetEvent('vrp_policeMenu:doforceVehicle')
AddEventHandler('vrp_policeMenu:doforceVehicle', function()
    local playerPed, coords = PlayerPedId(), GetEntityCoords(playerPed)

    if IsAnyVehicleNearPoint(coords, 5.0) then
        local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

        TaskStartScenarioInPlace(playerPed, '', 0, true)
        Citizen.Wait(5000)
        ClearPedTasksImmediately(playerPed)

        SetVehicleDoorsLocked(vehicle, 1)
    end
end)

RegisterNetEvent('vrp_policeMenu:doAcdrag')
AddEventHandler('vrp_policeMenu:doAcdrag', function(target)
    if not isCuffed then
        return
    end

    isDragged = not isDragged
    copDragging = target
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isCuffed then
            local playerPed = GetPlayerPed(-1)

            if isDragged then
                local targetPlayerPed = GetPlayerPed(GetPlayerFromServerId(copDragging))

                if not IsPedInAnyVehicle(targetPlayerPed, false) then
                    AttachEntityToEntity(playerPed, targetPlayerPed)
                else
                    isDragged = false
                    DetachEntity(playerPed, true, false)
                end

                if IsPedDeadOrDying(targetPlayerPed, true) then
                    isDragged = false
                    DetachEntity(playerPed, true, false)
                end
            else
                DetachEntity(playerPed, true, false)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNetEvent('vrp_policeMenu:doAcputInVeh')
AddEventHandler('vrp_policeMenu:doAcputInVeh', function()
    local playerPed, coords = PlayerPedId(), GetEntityCoords(playerPed)

    if not isCuffed then
        return
    end

    if IsAnyVehicleNearPoint(coords, 5.0) then
        local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

        if DoesEntityExist(vehicle) then
            local maxSeat, postoLibero = GetVehicleMaxNumberOfPassengers(vehicle)

            for i = maxSeat - 1, 0, -1 do
                if IsVehicleSeatFree(vehicle, i) then
                    postoLibero = i
                    return
                end
            end

            if postoLibero then
                TaskWarpPedIntoVehicle(playerPed, vehicle, postoLibero)
                isDragged = false
            end
        end
    end
end)

RegisterNetEvent('vrp_policeMenu:doAcremoveFromVeh')
AddEventHandler('vrp_policeMenu:doAcremoveFromVeh', function()
    local playerPed = PlayerPedId()

    if not IsPedSittingInVehicle(ped) then
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    TaskLeaveVehicle(playerPed, vehicle, 16)
end)

function loadAnimDict(dict)
    RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
	end
end

function DisableActions(ped)
	DisableControlAction(1, 140, true)
	DisableControlAction(1, 141, true)
	DisableControlAction(1, 142, true)
	DisableControlAction(1, 37, true)
    DisablePlayerFiring(ped, true)
end