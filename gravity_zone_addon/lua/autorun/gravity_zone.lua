if SERVER then
  local GROUND_SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  hook.Add("PlayerDisconnected", "gravity_zone_cleanup", function(ply)
    ply.CurrentGravityZone = nil
    ply:SetNWEntity("GravityZone", NULL)
  end)

  hook.Add("SetupMove", "gravity_zone_move_server", function(ply, mv, cmd)
    local zone = ply:GetNWEntity("GravityZone")
    if not IsValid(zone) then return end

    local gDir = zone:GetGravityVector()
    if not isvector(gDir) then return end
    local dir = gDir:GetNormalized()
    local accel = zone:GetGravityAccel() or 600

    local vel = mv:GetVelocity()
    vel:Add(dir * accel * FrameTime())

    local hullMins, hullMaxs = ply:Crouching() and ply:GetHullDuck() or ply:GetHull()
    local origin = mv:GetOrigin()

    local tr = util.TraceHull({
      start = origin,
      endpos = origin + dir * GROUND_SNAP_DIST,
      mins = hullMins,
      maxs = hullMaxs,
      mask = MASK_PLAYERSOLID,
      filter = ply
    })

    ply.GravityZoneOnGround = tr.Hit

    if tr.Hit then
      mv:SetOrigin(tr.HitPos - dir * 0.5)
      local into = vel:Dot(dir)
      if into > 0 then
        vel:Sub(dir * into)
      end

      local tangential = vel - dir * vel:Dot(dir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 6)
        tangential:Mul((speed - drop) / speed)
        vel = tangential + dir * vel:Dot(dir)
      end

      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(dir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  hook.Add("GetFallDamage", "gravity_zone_fall_damage", function(ply, speed)
    if IsValid(ply:GetNWEntity("GravityZone")) then return 0 end
  end)

  concommand.Add("gz_demo", function(ply)
    if not IsValid(ply) then return end
    local tr = ply:GetEyeTrace()
    local zone = ents.Create("ent_gravity_zone")
    zone:SetPos(tr.HitPos + tr.HitNormal * 8)
    zone:Spawn()
    zone:SetGravityVector(-tr.HitNormal)
    zone:SetGravityAccel(600)
    zone:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    if zone.SetExtents then
      zone:SetExtents(Vector(-128, -128, -64), Vector(128, 128, 64))
    end
  end)
end

if CLIENT then
  local GROUND_SNAP_DIST = 16
  local JUMP_IMPULSE = 250

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

  -- Client prediction: approximate movement locally for responsiveness
  hook.Add("SetupMove", "gravity_zone_move_client", function(ply, mv, cmd)
    if ply ~= LocalPlayer() then return end
    local zone = ply:GetNWEntity("GravityZone")
    if not IsValid(zone) then return end

    local dir = zone:GetGravityVector():GetNormalized()
    local accel = zone:GetGravityAccel() or 600

    local vel = mv:GetVelocity()
    vel:Add(dir * accel * FrameTime())

    local hullMins, hullMaxs = ply:Crouching() and ply:GetHullDuck() or ply:GetHull()
    local origin = mv:GetOrigin()

    local tr = util.TraceHull({
      start = origin,
      endpos = origin + dir * GROUND_SNAP_DIST,
      mins = hullMins,
      maxs = hullMaxs,
      mask = MASK_PLAYERSOLID,
      filter = ply
    })

    if tr.Hit then
      mv:SetOrigin(tr.HitPos - dir * 0.5)
      local into = vel:Dot(dir)
      if into > 0 then vel:Sub(dir * into) end

      local tangential = vel - dir * vel:Dot(dir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 6)
        tangential:Mul((speed - drop) / speed)
        vel = tangential + dir * vel:Dot(dir)
      end

      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(dir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  hook.Add("CalcView", "gravity_zone_calcview", function(ply, origin, angles, fov, znear, zfar)
    local zone = ply:GetNWEntity("GravityZone")
    if not IsValid(zone) or not zone:GetInvertView() then return end
    local dir = zone:GetGravityVector():GetNormalized()
    local targetUp = -dir
    local forward = angles:Forward()
    local newAngles = buildAnglesFromForwardUp(forward, targetUp)
    return { origin = origin, angles = newAngles, fov = fov, znear = znear, zfar = zfar, drawviewer = false }
  end)

  hook.Add("PrePlayerDraw", "gravity_zone_playerdraw", function(ply)
    local zone = ply:GetNWEntity("GravityZone")
    if not IsValid(zone) then return end
    local dir = zone:GetGravityVector():GetNormalized()
    local up = -dir
    local forward = ply:EyeAngles():Forward()
    local ang = buildAnglesFromForwardUp(forward, up)
    ply._gravityZoneOldAngles = ply:GetRenderAngles()
    ply:SetRenderAngles(ang)
  end)

  hook.Add("PostPlayerDraw", "gravity_zone_playerdraw", function(ply)
    if ply._gravityZoneOldAngles then
      ply:SetRenderAngles(ply._gravityZoneOldAngles)
      ply._gravityZoneOldAngles = nil
    end
  end)
end