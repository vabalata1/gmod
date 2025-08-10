TOOL.Category = "Gravity"
TOOL.Name = "Gravity Zone"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
  language.Add("tool.gravityzone.name", "Gravity Zone")
  language.Add("tool.gravityzone.desc", "Place and resize gravity zones that invert gravity inside")
  language.Add("tool.gravityzone.0", "Left-click: Place/resize zone. Right-click: Set gravity dir to surface normal. Reload: Toggle view inversion.")
end

TOOL.ClientConVar["minx"] = -256
TOOL.ClientConVar["miny"] = -256
TOOL.ClientConVar["minz"] = -128
TOOL.ClientConVar["maxx"] = 256
TOOL.ClientConVar["maxy"] = 256
TOOL.ClientConVar["maxz"] = 128
TOOL.ClientConVar["accel"] = 600

local function getZone(ply, trace)
  local ent = trace.Entity
  if IsValid(ent) and ent:GetClass() == "ent_gravity_zone" then return ent end
  return nil
end

function TOOL:LeftClick(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  local zone = getZone(ply, trace)
  if not IsValid(zone) then
    zone = ents.Create("ent_gravity_zone")
    zone:SetPos(trace.HitPos)
    zone:Spawn()
    undo.Create("Gravity Zone")
    undo.AddEntity(zone)
    undo.SetPlayer(ply)
    undo.Finish()
  end

  local mins = Vector(self:GetClientNumber("minx"), self:GetClientNumber("miny"), self:GetClientNumber("minz"))
  local maxs = Vector(self:GetClientNumber("maxx"), self:GetClientNumber("maxy"), self:GetClientNumber("maxz"))
  zone:SetExtents(mins, maxs)
  zone:SetGravityAccel(self:GetClientNumber("accel"))
  return true
end

function TOOL:RightClick(trace)
  if CLIENT then return true end
  local zone = getZone(self:GetOwner(), trace)
  if not IsValid(zone) then return false end
  -- Set gravity direction to pull toward the hit surface (use inverted normal)
  zone:SetGravityVector(-trace.HitNormal)
  return true
end

function TOOL:Reload(trace)
  if CLIENT then return true end
  local zone = getZone(self:GetOwner(), trace)
  if not IsValid(zone) then return false end
  zone:SetInvertView(not zone:GetInvertView())
  return true
end

function TOOL.BuildCPanel(panel)
  panel:AddControl("Header", { Description = "Place and configure gravity zones." })

  panel:NumSlider("Accel (units/s^2)", "gravityzone_accel", 100, 1200, 0)

  panel:Help("Extents (mins)")
  panel:NumSlider("min x", "gravityzone_minx", -1024, 0, 0)
  panel:NumSlider("min y", "gravityzone_miny", -1024, 0, 0)
  panel:NumSlider("min z", "gravityzone_minz", -1024, 0, 0)

  panel:Help("Extents (maxs)")
  panel:NumSlider("max x", "gravityzone_maxx", 0, 1024, 0)
  panel:NumSlider("max y", "gravityzone_maxy", 0, 1024, 0)
  panel:NumSlider("max z", "gravityzone_maxz", 0, 1024, 0)
end