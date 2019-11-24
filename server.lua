local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRPclient = Tunnel.getInterface("vRP","vrp_KoRadio")
vRP = Proxy.getInterface("vRP")

local permesso = {
    ['Megafono'] = 'police.megafono',
    ['Menu'] = 'police.menu',
    ['Placcaggio'] = 'police.placcaggio'
}
local itemIllegali = {}

local WebHook = 'https://discordapp.com/api/webhooks/643918182062751756/QBcByPY9t5X9ydTvn3BzPm1VBiEqoCaMy9CZx3VFE5txORIX_5V5uGUozPDe6-oOSFbW'

seizable_items = {
  "dirty_money",
  "cocaine",
  "lsd",
  "seeds",
  "harness",
  "credit",
  "weed"
}

-- jails {x,y,z,radius}
jails = {
  {459.485870361328,-1001.61560058594,24.914867401123,2.1},
  {459.305603027344,-997.873718261719,24.914867401123,2.1},
  {459.999938964844,-994.331298828125,24.9148578643799,1.6}
}

function SendToDiscord(message)
    local valori = {
        {
            ['title'] = message,
            ['type'] = 'rich',
            ['color'] = nil,
            ['footer'] = {
                ['text'] = 'Check Anti-Cheat'
            }
        }
    }

    if message == nil or message == '' then
        return FALSE
    else
        PerformHttpRequest(WebHook, function(err, text, headers) end, 'POST', json.encode({username = 'Check Anti-Cheat', embeds = valori}), {['Content-Type'] = 'application/json'})
    end
end

RegisterServerEvent('vrp_KoRadio:tryTackle')
AddEventHandler('vrp_KoRadio:tryTackle', function()
	local user_id = vRP.getUserId({source})
	local player = vRP.getUserSource({user_id})

    local _source = source

	if vRP.hasPermission({user_id, permesso['Placcaggio']}) then
		vRPclient.getNearestPlayer(player,{5},function(nplayer)
			local nuser_id = vRP.getUserId({nplayer})
			if nuser_id ~= nil then
				TriggerClientEvent('vrp_KoRadio:getTackled', nplayer, player)
				TriggerClientEvent('vrp_Ko_Radio:playTackle', player)
			else
				vRPclient.notify(player,{"Nessun player vicino!"})
			end
		end)
	else
		SendToDiscord('Il giocatore ' .. GetPlayerName(player_source) .. ' ha triggerato l\'evento "vrp_KoRadio:tryTackle" senza avere i permessi necessari')
	end
end)

RegisterServerEvent('checkPermission')
AddEventHandler('checkPermission', function()
	local _source = source
	local user_id = vRP.getUserId({source})
	local player = vRP.getUserSource({user_id})

	if vRP.hasPermission({user_id, permesso['Menu']}) then
		TriggerClientEvent('returnPermissionYes', player)
	else
		TriggerClientEvent('returnPermissionFalse', player)
	end
end)

RegisterServerEvent('vrp_policeMenu:doAction')
AddEventHandler('vrp_policeMenu:doAction', function(option)
    local user_id, player_source = vRP.getUserId({source}), vRP.getUserSource({user_id})

    if vRP.hasPermission({user_id, permesso['Menu']}) then
        if option == 'megafonoOne' then
            TriggerEvent('InteractSound_SV:PlayWithinDistance', 50, option, 1.0)
        elseif option == 'checkPlate' or option == 'forceVehicle' then
            TriggerClientEvent('vrp_policeMenu:doAc' .. option, player_source)
        else
            vRPclient.getNearestPlayer(player_source, {3}, function(target)
                local nuser_id = vRP.getUserId({target})

                if nuser_id ~= nil then
                    if option == 'cuff' then
                        TriggerClientEvent('vrp_policeMenu:cuffPlayer', target, player_source)
                        TriggerClientEvent('vrp_policeMenu:cuffAnim', player_source)
                        
                        Citizen.Wait(5000)
                        
                        vRPclient.toggleHandcuff(target, {})
                        return
                    elseif option == 'uncuff' then
                        Citizen.Wait(500)
                        
                        vRPclient.toggleHandcuff(target, {})
                    elseif option == 'jail' then
                        vRPclient.isJailed(target, {}, function(jailed)
                          if jailed then
                            vRPclient.unjail(target, {})
                            vRPclient.notify(target,{'Sei stato scarcerato'})
                            vRPclient.notify(player_source,{'Giocatore scarcerato'})
                          else
                            vRPclient.getPosition(target,{},function(x,y,z)
                              local d_min = 1000
                              local v_min = nil
                              for k,v in pairs(jails) do
                                local dx,dy,dz = x-v[1],y-v[2],z-v[3]
                                local dist = math.sqrt(dx*dx+dy*dy+dz*dz)

                                if dist <= d_min and dist <= 15 then
                                  d_min = dist
                                  v_min = v
                                end

                                if v_min then
                                  vRPclient.jail(target,{v_min[1],v_min[2],v_min[3],v_min[4]})
                                  vRPclient.notify(target,{'Sei stato carcerato'})
                                  vRPclient.notify(player_source,{'Hai mandato in prigione il giocatore'})
                                else
                                  vRPclient.notify(player_source,{'Cella non trovata'})
                                end
                              end
                            end)
                          end
                        end)
                    elseif option == 'seizeWeapons' then
                        vRPclient.isHandcuffed(target,{}, function(handcuffed)
                            if handcuffed then
                                vRPclient.getWeapons(target,{},function(weapons)
                                    for k, v in pairs(weapons) do
                                        vRP.giveInventoryItem(user_id, "wbody|"..k, 1, true)

                                        if v.ammo > 0 then
                                            vRP.giveInventoryItem(user_id, "wammo|"..k, v.ammo, true)
                                        end
                                    end

                                    vRPclient.giveWeapons(nplayer,{{},true})
                                    vRPclient.notify(nplayer,{'Sei stato perquisito, le tue armi illegali sono state sequestrate'})
                                end)
                            else
                                vRPclient.notify(nplayer,{'Il giocatore non è ammanettato'})
                            end
                        end)
                        return
                    elseif option == 'seizeItems' then
                        vRPclient.isHandcuffed(target,{}, function(handcuffed)
                            if handcuffed then
                                for k, v in pairs(seizable_items) do
                                    local amount = vRP.getInventoryItemAmount(target, v)
                                    
                                    if amount > 0 then
                                        local item = vRP.items[v]
                                            
                                        if item then
                                            if vRP.tryGetInventoryItem(target, v, amount, true) then
                                                vRP.giveInventoryItem(user_id, v, amount, false)
                                            end
                                        end
                                    end
                                end
                                vRPclient.notify(player,{'Sei stato perquisito, i tuoi oggetti illegali sono stati sequestrati'})
                            else
                                vRPclient.notify(nplayer,{'Il giocatore non è ammanettato'})
                            end
                        end)
                        return
                    end

                    TriggerClientEvent('vrp_policeMenu:doAc' .. option, target, player_source)
                else
                    vRPclient.notify(player_source, {'Nessun giocatore nelle vicinanze.'})
                end
            end)
        end
    else
        SendToDiscord('Il giocatore ' .. GetPlayerName(player_source) .. ' ha triggerato l\'evento "vrp_megafono:doAction" senza avere i permessi necessari')
    end
end)
