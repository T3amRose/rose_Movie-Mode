-- rose_Movie-Mode - Client
-- Der Client schaltet NICHTS selbst ein. Alles laeuft ueber den Server,
-- der den Zustand per 'rose_moviemode:state' zurueckschickt.
-- Filmmodus starten schaltet Noclip/Unsichtbar frei; Noclip ist immer unsichtbar.

MovieMode = {
    granted   = false,
    film      = false,
    invisible = false,
    noclip    = false,
}

local function menuData()
    return { film = MovieMode.film, invisible = MovieMode.invisible, noclip = MovieMode.noclip }
end

local menuOpen = false
local nuiReady = false

local function applyInvisible(on)
    local ped = PlayerPedId()
    SetEntityVisible(ped, not on, false)
    if not on then ResetEntityAlpha(ped) end
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu()
    if not MovieMode.granted then return end
    if not nuiReady then
        lib.notify({
            title = 'Filmmodus',
            description = 'Menue-Seite nicht geladen. In der Server-Konsole "refresh" und "ensure rose_Movie-Mode" ausfuehren.',
            type = 'error', duration = 8000,
        })
        print('[rose_Movie-Mode] NUI-Seite wurde nicht geladen (ui_page fehlt? refresh vergessen?)')
        return
    end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', state = menuData() })
end

RegisterNetEvent('rose_moviemode:state', function(granted, film, invisible, noclip)
    local wasNoclip = MovieMode.noclip
    MovieMode.granted   = granted
    MovieMode.film      = granted and film or false
    MovieMode.noclip    = MovieMode.film and noclip or false
    MovieMode.invisible = MovieMode.film and (invisible or MovieMode.noclip) or false

    applyInvisible(MovieMode.invisible)
    SetNoclip(MovieMode.noclip)

    if not granted then closeMenu() return end
    if menuOpen then
        SendNUIMessage({ action = 'state', state = menuData() })
        -- Nach dem Einschalten von Noclip Menue kurz zeigen und schliessen, damit man direkt fliegen kann
        if MovieMode.noclip and not wasNoclip then
            SetTimeout(700, closeMenu)
        end
    end
end)

RegisterNetEvent('rose_moviemode:notify', function(msg, kind)
    lib.notify({ title = 'Filmmodus', description = msg, type = kind or 'inform', duration = 6000 })
end)

RegisterNetEvent('rose_moviemode:openMenu', openMenu)

-- NUI-Rueckmeldungen
RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    cb('ok')
end)

RegisterNUICallback('toggle', function(data, cb)
    local what = data and data.what
    if what == 'film' or what == 'noclip' or what == 'invisible' then
        TriggerServerEvent('rose_moviemode:toggle', what)
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Befehl geht immer ueber den Server, der die Rechte prueft
RegisterCommand(Config.MenuCommand, function()
    TriggerServerEvent('rose_moviemode:open')
end, false)
if Config.MenuKey and Config.MenuKey ~= '' then
    RegisterKeyMapping(Config.MenuCommand, 'Filmmodus-Menue', 'keyboard', Config.MenuKey)
end

-- Unsichtbarkeit halten (z.B. nach Respawn); optional sich selbst lokal sehen
CreateThread(function()
    while true do
        if MovieMode.invisible then
            local ped = PlayerPedId()
            if IsEntityVisible(ped) then SetEntityVisible(ped, false, false) end
            if Config.SeeSelf then SetEntityLocallyVisible(ped) end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Nach (Re)Start der Resource Status vom Server holen
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('rose_moviemode:requestState')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if menuOpen then SetNuiFocus(false, false) end
    applyInvisible(false)
    SetNoclip(false)
end)
