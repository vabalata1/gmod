if SERVER then
  local CAPTURE_DIST = 128
  local SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  local function getPlane(ply)
    local point = ply:GetNWVector("CW_Point")
    local normal = ply:GetNWVector("CW_Normal")
    if not isvector(point) or not isvector(normal) or normal == vector_origin then return nil end
    return point, normal:GetNormalized()
  end

  local function isNearPlane(origin, point, normal)
    local dist = (origin - point):Dot(normal)
    return math.abs(dist) <= CAPTURE_DIST, dist
  end

  hook.Add("PlayerDisconnected", "cw_cleanup", function(ply)
    if not IsValid(ply) then return end
    ply:SetNWBool("CW_Enabled", false)
    ply:SetNWVector("CW_Point", vector_origin)
    ply:SetNWVector("CW_Normal", vector_origin)
    ply:SetGravity(1)
  end)

  -- Movement (server authoritative)
  hook.Add("SetupMove", "cw_move_server", function(ply, mv, cmd)
    if not ply:GetNWBool("CW_Enabled") then return end
    local point, normal = getPlane(ply)
    if not point then return end

    local origin = mv:GetOrigin()
    local near, signedDist = isNearPlane(origin, point, normal)
    if not near then return end

    local gdir = -normal
    local accel = ply:GetNWFloat("CW_Accel", 600)

    local vel = mv:GetVelocity()
    vel:Add(gdir * accel * FrameTime())

    -- Ground snap against geometry matching the plane normal roughly
    local hullMins, hullMaxs = ply:Crouching() and ply:GetHullDuck() or ply:GetHull()
    local tr = util.TraceHull({
      start = origin,
      endpos = origin + gdir * SNAP_DIST,
      mins = hullMins,
      maxs = hullMaxs,
      mask = MASK_PLAYERSOLID,
      filter = ply
    })

    if tr.Hit and tr.HitNormal:Dot(normal) > 0.75 then
      mv:SetOrigin(tr.HitPos - gdir * 0.5)
      local into = vel:Dot(gdir)
      if into > 0 then vel:Sub(gdir * into) end

      local tangential = vel - gdir * vel:Dot(gdir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 6)
        tangential:Mul((speed - drop) / speed)
        vel = tangential + gdir * vel:Dot(gdir)
      end

      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(gdir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  hook.Add("GetFallDamage", "cw_no_fall_damage", function(ply)
    if ply:GetNWBool("CW_Enabled") then return 0 end
  end)

  -- Demo command: choose the surface you're looking at and enable
  concommand.Add("cw_demo", function(ply)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end
    ply:SetNWVector("CW_Point", tr.HitPos)
    ply:SetNWVector("CW_Normal", tr.HitNormal)
    ply:SetNWFloat("CW_Accel", 600)
    ply:SetNWBool("CW_InvertView", true)
    ply:SetNWBool("CW_Enabled", true)
    ply:SetGravity(0.0001)
  end)
end

if CLIENT then
  local CAPTURE_DIST = 128
  local SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  local function getPlane(ply)
    local point = ply:GetNWVector("CW_Point")
    local normal = ply:GetNWVector("CW_Normal")
    if not isvector(point) or not isvector(normal) or normal == vector_origin then return nil end
    return point, normal:GetNormalized()
  end

  -- Prediction for responsiveness
  hook.Add("SetupMove", "cw_move_client", function(ply, mv, cmd)
    if ply ~= LocalPlayer() then return end
    if not ply:GetNWBool("CW_Enabled") then return end

    local point, normal = getPlane(ply)
    if not point then return end

    local origin = mv:GetOrigin()
    local dist = (origin - point):Dot(normal)
    if math.abs(dist) > CAPTURE_DIST then return end

    local gdir = -normal
    local accel = ply:GetNWFloat("CW_Accel", 600)
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

    if tr.Hit and tr.HitNormal:Dot(normal) > 0.75 then
      mv:SetOrigin(tr.HitPos - gdir * 0.5)
      local into = vel:Dot(gdir)
      if into > 0 then vel:Sub(gdir * into) end

      local tangential = vel - gdir * vel:Dot(gdir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 6)
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

  hook.Add("CalcView", "cw_view", function(ply, origin, angles, fov, znear, zfar)
    if not ply:GetNWBool("CW_Enabled") then return end
    if not ply:GetNWBool("CW_InvertView", true) then return end

    local point, normal = getPlane(ply)
    if not point then return end

    local targetUp = normal
    local forward = angles:Forward()
    local newAngles = buildAnglesFromForwardUp(forward, targetUp)
    return { origin = origin, angles = newAngles, fov = fov, znear = znear, zfar = zfar, drawviewer = false }
  end)
end