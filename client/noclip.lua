-- rose_Movie-Mode - Noclip
-- Bewegung relativ zur Kamera. Funktioniert zu Fuss und im Fahrzeug.

local active = false

local function getEntity()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then return veh end
    return ped
end

local function setPhysics(ent, on)
    FreezeEntityPosition(ent, on)
    SetEntityCollision(ent, not on, not on)
    SetEntityInvincible(ent, on)
    if not on then SetEntityVelocity(ent, 0.0, 0.0, 0.0) end
end

local function camDirection()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local cx = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(rx)),
           vector3(math.cos(rz), math.sin(rz), 0.0)
end

local function loop()
    local ent = getEntity()
    setPhysics(ent, true)

    while active do
        local cur = getEntity()
        if cur ~= ent then
            setPhysics(ent, false)
            ent = cur
            setPhysics(ent, true)
        end

        -- Steuerungen, die beim Fliegen stoeren, sperren
        DisableControlAction(0, 30, true)  -- links/rechts
        DisableControlAction(0, 31, true)  -- vor/zurueck
        DisableControlAction(0, 44, true)  -- Q (Deckung)
        DisableControlAction(0, 38, true)  -- E
        DisableControlAction(0, 21, true)  -- Shift (Sprint)
        DisableControlAction(0, 19, true)  -- Alt
        DisableControlAction(0, 22, true)  -- Leertaste
        DisableControlAction(0, 75, true)  -- Fahrzeug verlassen

        local speed = Config.Noclip.speed
        if IsDisabledControlPressed(0, 21) then speed = speed * Config.Noclip.fastMulti end
        if IsDisabledControlPressed(0, 19) then speed = speed * Config.Noclip.slowMulti end

        local fwd, right = camDirection()
        local pos = GetEntityCoords(ent)
        local move = vector3(0.0, 0.0, 0.0)

        if IsDisabledControlPressed(0, 32) then move = move + fwd end    -- W
        if IsDisabledControlPressed(0, 33) then move = move - fwd end    -- S
        if IsDisabledControlPressed(0, 34) then move = move - right end  -- A
        if IsDisabledControlPressed(0, 35) then move = move + right end  -- D
        if IsDisabledControlPressed(0, 44) then move = move + vector3(0.0, 0.0, 1.0) end -- Q hoch
        if IsDisabledControlPressed(0, 38) then move = move - vector3(0.0, 0.0, 1.0) end -- E runter

        local np = pos + move * speed
        SetEntityCoordsNoOffset(ent, np.x, np.y, np.z, true, true, true)
        SetEntityHeading(ent, GetGameplayCamRot(2).z)

        Wait(0)
    end

    setPhysics(ent, false)
    if ent ~= PlayerPedId() then setPhysics(PlayerPedId(), false) end
end

function SetNoclip(on)
    if on == active then return end
    active = on
    if on then CreateThread(loop) end
end
