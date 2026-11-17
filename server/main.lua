-- rose_Movie-Mode - Server
-- Der Server ist die einzige Stelle, die entscheidet, wer den Filmmodus nutzen darf.
-- Rechte haengen an der Rockstar-Lizenz des Spielers und bleiben gespeichert,
-- bis ein Admin sie wieder entzieht (auch ueber Reconnect/Neustart hinweg).

local ESX = nil
if GetResourceState('es_extended') == 'started' then
    local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok then ESX = obj end
end

local KVP_KEY = 'rose_moviemode:rights'

-- Rights[license] = { name = 'Spielername', by = 'Adminname', at = os.time() }
local Rights = json.decode(GetResourceKvpString(KVP_KEY) or '{}') or {}
-- Active[src] = { invisible = bool, noclip = bool }, solange der Filmmodus gestartet ist
-- Noclip schliesst Unsichtbarkeit immer mit ein.
local Active = {}
-- LastToggle[src] = Zeitpunkt des letzten Umschaltens (Spam-Schutz)
local LastToggle = {}

local function saveRights()
    SetResourceKvp(KVP_KEY, json.encode(Rights))
end

local function licenseOf(src)
    return GetPlayerIdentifierByType(src, 'license')
end

local function hasRights(src)
    local lic = licenseOf(src)
    return lic ~= nil and Rights[lic] ~= nil
end

local function isTeam(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, Config.Ace) then return true end
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and Config.AdminGroups[xPlayer.getGroup()] then return true end
    end
    return false
end

local function nameOf(src)
    if src == 0 then return 'Konsole' end
    return ('%s (ID %d)'):format(GetPlayerName(src) or '?', src)
end

-- Kurze Rueckmeldung an einen einzelnen Spieler (ox_lib)
local function notify(src, msg, kind)
    if src == 0 then print('[rose_Movie-Mode] ' .. msg) return end
    TriggerClientEvent('rose_moviemode:notify', src, msg, kind or 'inform')
end

-- txAdmin-Direktnachricht an alle Team-Mitglieder, die gerade online sind
local function txAdminTeam(msg)
    print('[rose_Movie-Mode] ' .. msg)
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if isTeam(id) then
            TriggerClientEvent('txcl:showDirectMessage', id, msg, Config.TxAdminAuthor)
        end
    end
end

local function sendState(src)
    local granted = hasRights(src)
    if not granted then Active[src] = nil end
    local a = Active[src]
    TriggerClientEvent('rose_moviemode:state', src, granted, a ~= nil,
        a ~= nil and (a.invisible or a.noclip) or false,
        a ~= nil and a.noclip or false)
end

---------------------------------------------------------------------
-- Admin-Befehl
--   /filmmodus <ID>            Rechte geben bzw. wieder entziehen (Umschalter)
--   /filmmodus <ID> an|aus     Rechte fest geben / entziehen
--   /filmmodus liste           alle gespeicherten Berechtigten anzeigen
--   /filmmodus entziehen <Nr>  Rechte per Listennummer entziehen (auch offline)
---------------------------------------------------------------------
local function sortedRights()
    local list = {}
    for lic, r in pairs(Rights) do list[#list + 1] = { lic = lic, r = r } end
    table.sort(list, function(a, b) return (a.r.at or 0) < (b.r.at or 0) end)
    return list
end

local function revokeLicense(lic)
    Rights[lic] = nil
    saveRights()
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if licenseOf(id) == lic then
            if Active[id] then
                txAdminTeam(('%s hat den Filmmodus verlassen (Rechte entzogen).'):format(nameOf(id)))
            end
            Active[id] = nil
            sendState(id)
            notify(id, 'Deine Filmmodus-Rechte wurden entzogen.', 'inform')
        end
    end
end

RegisterCommand(Config.GrantCommand, function(src, args)
    if not isTeam(src) then
        notify(src, 'Dazu hast du keine Berechtigung.', 'error')
        return
    end

    local sub = args[1] and args[1]:lower() or nil

    if sub == 'liste' then
        local list = sortedRights()
        if #list == 0 then notify(src, 'Niemand hat Filmmodus-Rechte.', 'inform') return end
        local lines = {}
        for i, e in ipairs(list) do
            lines[#lines + 1] = ('%d. %s (von %s)'):format(i, e.r.name or '?', e.r.by or '?')
        end
        notify(src, table.concat(lines, '\n'), 'inform')
        return
    end

    if sub == 'entziehen' then
        local e = sortedRights()[tonumber(args[2]) or 0]
        if not e then notify(src, ('Benutzung: /%s entziehen <Nr aus der Liste>'):format(Config.GrantCommand), 'error') return end
        revokeLicense(e.lic)
        notify(src, ('%s hat keine Filmmodus-Rechte mehr.'):format(e.r.name or '?'), 'success')
        return
    end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        notify(src, ('Benutzung: /%s <Spieler-ID> [an|aus] | liste | entziehen <Nr>'):format(Config.GrantCommand), 'error')
        return
    end

    local lic = licenseOf(target)
    if not lic then notify(src, 'Spieler hat keine Lizenz-Kennung.', 'error') return end

    local mode = args[2] and args[2]:lower() or nil
    local enable
    if mode == 'an' or mode == 'on' then enable = true
    elseif mode == 'aus' or mode == 'off' then enable = false
    else enable = Rights[lic] == nil end

    if enable then
        if Rights[lic] then notify(src, nameOf(target) .. ' hat bereits Filmmodus-Rechte.', 'inform') return end
        Rights[lic] = { name = GetPlayerName(target), by = src == 0 and 'Konsole' or GetPlayerName(src), at = os.time() }
        saveRights()
        sendState(target)
        notify(target, ('Du hast Filmmodus-Rechte erhalten. Menue jederzeit mit /%s'):format(Config.MenuCommand), 'success')
        notify(src, nameOf(target) .. ' hat jetzt Filmmodus-Rechte.', 'success')
    else
        if not Rights[lic] then notify(src, nameOf(target) .. ' hat keine Filmmodus-Rechte.', 'inform') return end
        revokeLicense(lic)
        notify(src, nameOf(target) .. ' hat keine Filmmodus-Rechte mehr.', 'success')
    end
end, false)

---------------------------------------------------------------------
-- Spieler oeffnet das Menue per Befehl (nur Rechte-Pruefung, keine Meldung)
---------------------------------------------------------------------
RegisterNetEvent('rose_moviemode:open', function()
    local src = source
    if not hasRights(src) then
        notify(src, 'Du hast keine Filmmodus-Rechte.', 'error')
        sendState(src)
        return
    end
    sendState(src)
    TriggerClientEvent('rose_moviemode:openMenu', src)
end)

---------------------------------------------------------------------
-- Umschalten
--   'film'      Filmmodus starten/beenden -> txAdmin-Meldung ans Team
--   'noclip'    nur im Filmmodus, macht automatisch unsichtbar
--   'invisible' nur im Filmmodus, solange Noclip an ist bleibt man unsichtbar
---------------------------------------------------------------------
RegisterNetEvent('rose_moviemode:toggle', function(what)
    local src = source
    if not hasRights(src) then
        print(('[rose_Movie-Mode] WARNUNG: %s hat ohne Rechte versucht "%s" zu schalten.'):format(nameOf(src), tostring(what)))
        sendState(src)
        return
    end

    if what == 'film' then
        local now = os.time()
        if LastToggle[src] and now - LastToggle[src] < Config.ToggleCooldown then
            notify(src, 'Bitte kurz warten.', 'error')
            sendState(src)
            return
        end
        LastToggle[src] = now

        if Active[src] then
            Active[src] = nil
            txAdminTeam(('%s hat den Filmmodus verlassen.'):format(nameOf(src)))
        else
            Active[src] = { invisible = false, noclip = false }
            txAdminTeam(('%s wechselt in den Filmmodus.'):format(nameOf(src)))
        end
    elseif what == 'noclip' or what == 'invisible' then
        local a = Active[src]
        if not a then
            notify(src, 'Starte zuerst den Filmmodus.', 'error')
        elseif what == 'invisible' and a.noclip then
            notify(src, 'Im Noclip bist du immer unsichtbar.', 'inform')
        else
            a[what] = not a[what]
        end
    end
    sendState(src)
end)

-- Client fragt nach Join / Resource-Neustart seinen Status ab
RegisterNetEvent('rose_moviemode:requestState', function()
    sendState(source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Active[src] then
        txAdminTeam(('%s hat den Filmmodus verlassen (Disconnect).'):format(GetPlayerName(src) or ('ID ' .. src)))
    end
    Active[src] = nil
    LastToggle[src] = nil
end)
