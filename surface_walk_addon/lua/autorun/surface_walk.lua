if SERVER then
  local CAPTURE_DIST = 128
  local SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  local function getPlane(ply)
    local point = ply:GetNWVector("SW_Point")
    local normal = ply:GetNWVector("SW_Normal")
    if not isvector(point) or not isvector(normal) or normal == vector_origin then return nil end
    return point, normal:GetNormalized()
  end

  local function isNearPlane(origin, point, normal)
    local dist = (origin - point):Dot(normal)
    return math.abs(dist) <= CAPTURE_DIST, dist
  end

  hook.Add("PlayerDisconnected", "sw_cleanup", function(ply)
    if not IsValid(ply) then return end
    ply:SetNWBool("SW_Enabled", false)
    ply:SetNWVector("SW_Point", vector_origin)
    ply:SetNWVector("SW_Normal", vector_origin)
    ply:SetGravity(1)
  end)

  hook.Add("SetupMove", "sw_move_server", function(ply, mv, cmd)
    if not ply:GetNWBool("SW_Enabled") then return end
    local point, normal = getPlane(ply)
    if not point then return end

    local origin = mv:GetOrigin()
    local near = isNearPlane(origin, point, normal)
    if not near then return end

    local gdir = -normal
    local accel = ply:GetNWFloat("SW_Accel", 700)

    local vel = mv:GetVelocity()
    vel:Add(gdir * accel * FrameTime())

    local hullMins, hullMaxs = ply:Crouching() and ply:GetHullDuck() or ply:GetHull()
    local tr = util.TraceHull({
      start = origin,
      endpos = origin + gdir * SNAP_DIST,
      mins = hullMins,
      maxs = hullMaxs,
      mask = MASK_PLAYERSOLID,
      filter = ply
    })

    if tr.Hit and tr.HitNormal:Dot(normal) > 0.6 then
      mv:SetOrigin(tr.HitPos - gdir * 0.5)
      local into = vel:Dot(gdir)
      if into > 0 then vel:Sub(gdir * into) end

      local tangential = vel - gdir * vel:Dot(gdir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 7)
        tangential:Mul((speed - drop) / speed)
        vel = tangential + gdir * vel:Dot(gdir)
      end

      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(gdir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  hook.Add("GetFallDamage", "sw_no_fall_damage", function(ply)
    if ply:GetNWBool("SW_Enabled") then return 0 end
  end)

  concommand.Add("sw_demo", function(ply)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end
    ply:SetNWVector("SW_Point", tr.HitPos)
    ply:SetNWVector("SW_Normal", tr.HitNormal)
    ply:SetNWFloat("SW_Accel", 700)
    ply:SetNWBool("SW_InvertView", true)
    ply:SetNWBool("SW_Enabled", true)
    ply:SetGravity(0.0001)
  end)
end

if CLIENT then
  local CAPTURE_DIST = 128
  local SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  local function getPlane(ply)
    local point = ply:GetNWVector("SW_Point")
    local normal = ply:GetNWVector("SW_Normal")
    if not isvector(point) or not isvector(normal) or normal == vector_origin then return nil end
    return point, normal:GetNormalized()
  end

  hook.Add("SetupMove", "sw_move_client", function(ply, mv, cmd)
    if ply ~= LocalPlayer() then return end
    if not ply:GetNWBool("SW_Enabled") then return end
    local point, normal = getPlane(ply)
    if not point then return end

    local origin = mv:GetOrigin()
    local dist = (origin - point):Dot(normal)
    if math.abs(dist) > CAPTURE_DIST then return end

    local gdir = -normal
    local accel = ply:GetNWFloat("SW_Accel", 700)
    local vel = mv:GetVelocity()
    vel:Add(gdir * accel * FrameTime())

    local hullMins, hullMaxs = ply:Crouching() and ply:GetHullDuck() or ply:GetHull()
    local tr = util.TraceHull({
      start = origin,
      endpos = origin + gdir * SNAP_DIST,
      mins = hullMins,
      maxs = hullMaxs,
      mask = MASK_PLAYERSOLID,
      filter = ply
    })

    if tr.Hit and tr.HitNormal:Dot(normal) > 0.6 then
      mv:SetOrigin(tr.HitPos - gdir * 0.5)
      local into = vel:Dot(gdir)
      if into > 0 then vel:Sub(gdir * into) end

      local tangential = vel - gdir * vel:Dot(gdir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 7)
        tangential:Mul((speed - drop) / speed)
        vel = tangential + gdir * vel:Dot(gdir)
      end

      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(gdir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  local function buildAnglesFromForwardUp(forward, up)
    local f = forward:GetNormalized()
    local u = up:GetNormalized()
    u = (u - f * f:Dot(u)):GetNormalized()
    local ang = f:Angle()
    local curUp = ang:Up()
    local rollSign = (curUp:Cross(u)):Dot(f) >= 0 and 1 or -1
    local rollCos = math.Clamp(curUp:Dot(u), -1, 1)
    local roll = math.deg(math.acos(rollCos)) * rollSign
    ang.r = roll
    return ang
  end

  hook.Add("CalcView", "sw_view", function(ply, origin, angles, fov, znear, zfar)
    if not ply:GetNWBool("SW_Enabled") then return end
    if not ply:GetNWBool("SW_InvertView", true) then return end

    local point, normal = getPlane(ply)
    if not point then return end

    local targetUp = normal
    local forward = angles:Forward()
    local newAngles = buildAnglesFromForwardUp(forward, targetUp)

    -- Offset the camera so it doesn't clip into the surface and matches feet-on-surface feel
    local eyeHeight = ply:Crouching() and ply:GetViewOffsetDucked().z or ply:GetViewOffset().z
    local currentDist = (origin - point):Dot(normal)
    local desired = math.Clamp(eyeHeight, 40, 70)
    if currentDist < desired then
      origin = origin - targetUp * (desired - currentDist)
    end

    return { origin = origin, angles = newAngles, fov = fov, znear = znear, zfar = zfar, drawviewer = false }
  end)
end