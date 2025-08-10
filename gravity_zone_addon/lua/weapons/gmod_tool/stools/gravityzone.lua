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
TOOL.ClientConVar["showzones"] = 1

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

if SERVER then
  util.AddNetworkString("gravityzone_showzones")
  net.Receive("gravityzone_showzones", function(len, ply)
    local show = net.ReadBool()
    ply._gravityZoneShow = show and true or false
  end)

  concommand.Add("gravityzone_remove_target", function(ply)
    local tr = ply:GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity:GetClass() == "ent_gravity_zone" then
      tr.Entity:Remove()
    end
  end)

  concommand.Add("gravityzone_remove_all", function(ply)
    for _, ent in ipairs(ents.FindByClass("ent_gravity_zone")) do
      if IsValid(ent) then ent:Remove() end
    end
  end)
end

if CLIENT then
  cvars.CreateClientConVar("gravityzone_showzones", "1", true, false, "Show gravity zone volumes")
  hook.Add("Think", "gravityzone_send_show", function()
    local want = cvars.Number("gravityzone_showzones", 1) ~= 0
    if LocalPlayer()._gravityZoneShow ~= want then
      LocalPlayer()._gravityZoneShow = want
      net.Start("gravityzone_showzones")
      net.WriteBool(want)
      net.SendToServer()
    end
  end)
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

  panel:CheckBox("Afficher les zones", "gravityzone_showzones")
  panel:Button("Supprimer la zone visée", "gravityzone_remove_target")
  panel:Button("Supprimer toutes les zones", "gravityzone_remove_all")
end