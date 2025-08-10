if SERVER then
  local GROUND_SNAP_DIST = 16
  local JUMP_IMPULSE = 250

  hook.Add("PlayerDisconnected", "gravity_zone_cleanup", function(ply)
    ply.CurrentGravityZone = nil
  end)

  hook.Add("SetupMove", "gravity_zone_move", function(ply, mv, cmd)
    local zone = ply.CurrentGravityZone
    if not IsValid(zone) then return end

    local gDir = zone:GetGravityVector()
    if not isvector(gDir) then return end
    local dir = gDir:GetNormalized()
    local accel = zone:GetGravityAccel() or 600

    -- Apply custom gravity toward the "ground" (ceiling in world coords)
    local vel = mv:GetVelocity()
    vel:Add(dir * accel * FrameTime())

    -- Simple ground detection in gravity direction
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
      -- Snap to surface and cancel velocity into the surface
      mv:SetOrigin(tr.HitPos - dir * 0.5)
      local into = vel:Dot(dir)
      if into > 0 then
        vel:Sub(dir * into)
      end

      -- Basic friction when grounded
      local tangential = vel - dir * vel:Dot(dir)
      local speed = tangential:Length()
      if speed > 0 then
        local drop = math.min(speed, 6) -- tune me
        tangential:Mul((speed - drop) / speed)
        vel = tangential + dir * vel:Dot(dir)
      end

      -- Jump: push away from the surface (opposite gravity direction)
      if mv:KeyPressed(IN_JUMP) then
        vel:Sub(dir * JUMP_IMPULSE)
      end
    end

    mv:SetVelocity(vel)
  end)

  hook.Add("GetFallDamage", "gravity_zone_fall_damage", function(ply, speed)
    if IsValid(ply.CurrentGravityZone) then return 0 end
  end)

  -- Demo command: spawns a gravity zone pulling toward the surface you are looking at
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
  local function buildAnglesFromForwardUp(forward, up)
    -- Ensure orthonormal basis
    local f = forward:GetNormalized()
    local u = up:GetNormalized()
    -- Remove forward component from up, then recompute right
    u = (u - f * f:Dot(u)):GetNormalized()
    local r = f:Cross(u)
    -- Construct Angle from basis: set yaw/pitch from forward, then set roll using up
    local ang = f:Angle()
    -- Compute roll so that ang:Up() aligns with desired up vector
    local curUp = ang:Up()
    local rollSign = (curUp:Cross(u)):Dot(f) >= 0 and 1 or -1
    local rollCos = math.Clamp(curUp:Dot(u), -1, 1)
    local roll = math.deg(math.acos(rollCos)) * rollSign
    ang.r = roll
    return ang
  end

  hook.Add("CalcView", "gravity_zone_calcview", function(ply, origin, angles, fov, znear, zfar)
    local zone = ply.CurrentGravityZone
    if not IsValid(zone) or not zone:GetInvertView() then return end

    local dir = zone:GetGravityVector():GetNormalized()
    local targetUp = -dir -- up vector is opposite gravity pull

    local forward = angles:Forward()
    local newAngles = buildAnglesFromForwardUp(forward, targetUp)

    return { origin = origin, angles = newAngles, fov = fov, znear = znear, zfar = zfar, drawviewer = false }
  end)

  -- Rotate player models visually to match gravity so other players look correct
  hook.Add("PrePlayerDraw", "gravity_zone_playerdraw", function(ply)
    local zone = ply.CurrentGravityZone
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