TOOL.Category = "Movement"
TOOL.Name = "Surface Walk"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
  language.Add("tool.surfacewalk.name", "Surface Walk")
  language.Add("tool.surfacewalk.desc", "Walk on walls and ceilings by selecting a surface")
  language.Add("tool.surfacewalk.0", "Right-click a surface to select. Left-click to enable/disable. Reload toggles camera alignment.")
end

TOOL.ClientConVar["accel"] = 700

local function setSurface(ply, hitpos, hitnormal)
  ply:SetNWVector("SW_Point", hitpos)
  ply:SetNWVector("SW_Normal", hitnormal)
end

function TOOL:RightClick(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  if not trace.Hit then return false end
  setSurface(ply, trace.HitPos, trace.HitNormal)
  ply:SetNWFloat("SW_Accel", math.Clamp(self:GetClientNumber("accel"), 100, 3000))
  ply:ChatPrint("Surface selected. Left-click to enable.")
  return true
end

function TOOL:LeftClick(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  local enable = not ply:GetNWBool("SW_Enabled")
  ply:SetNWBool("SW_Enabled", enable)
  if enable then
    if not ply:GetNWVector("SW_Normal"):IsZero() then
      ply:SetGravity(0.0001)
      ply:ChatPrint("Surface Walk: enabled")
    else
      ply:ChatPrint("Select a surface first (right-click).")
      ply:SetNWBool("SW_Enabled", false)
    end
  else
    ply:SetGravity(1)
    ply:ChatPrint("Surface Walk: disabled")
  end
  return true
end

function TOOL:Reload(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  local val = not ply:GetNWBool("SW_InvertView", true)
  ply:SetNWBool("SW_InvertView", val)
  ply:ChatPrint("Align camera: " .. tostring(val))
  return true
end

function TOOL.BuildCPanel(panel)
  panel:AddControl("Header", { Description = "Right-click to select a surface, left-click to enable walking. Reload toggles camera alignment." })
  panel:NumSlider("Accel (units/s^2)", "surfacewalk_accel", 100, 3000, 0)
  panel:Button("Demo: select look surface and enable", "sw_demo")
  panel:Button("Disable", "sw_disable")
end

if SERVER then
  concommand.Add("sw_disable", function(ply)
    if not IsValid(ply) then return end
    ply:SetNWBool("SW_Enabled", false)
    ply:SetGravity(1)
  end)
end