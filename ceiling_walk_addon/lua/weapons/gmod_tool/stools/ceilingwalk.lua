TOOL.Category = "Movement"
TOOL.Name = "Ceiling Walk"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
  language.Add("tool.ceilingwalk.name", "Ceiling Walk")
  language.Add("tool.ceilingwalk.desc", "Pick a ceiling surface and walk on it")
  language.Add("tool.ceilingwalk.0", "Right-click a ceiling to select. Left-click to enable/disable. Reload to toggle view inversion.")
end

TOOL.ClientConVar["accel"] = 600

local function setPlane(ply, hitpos, hitnormal)
  ply:SetNWVector("CW_Point", hitpos)
  ply:SetNWVector("CW_Normal", hitnormal)
end

function TOOL:RightClick(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  if not trace.Hit then return false end
  setPlane(ply, trace.HitPos, trace.HitNormal)
  ply:SetNWFloat("CW_Accel", math.Clamp(self:GetClientNumber("accel"), 100, 2000))
  ply:ChatPrint("Ceiling selected. Left-click to enable.")
  return true
end

function TOOL:LeftClick(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  local enable = not ply:GetNWBool("CW_Enabled")
  ply:SetNWBool("CW_Enabled", enable)
  if enable then
    if not ply:GetNWVector("CW_Normal"):IsZero() then
      ply:SetGravity(0.0001)
      ply:ChatPrint("Ceiling Walk: enabled")
    else
      ply:ChatPrint("Select a ceiling first (right-click).")
      ply:SetNWBool("CW_Enabled", false)
    end
  else
    ply:SetGravity(1)
    ply:ChatPrint("Ceiling Walk: disabled")
  end
  return true
end

function TOOL:Reload(trace)
  if CLIENT then return true end
  local ply = self:GetOwner()
  local val = not ply:GetNWBool("CW_InvertView", true)
  ply:SetNWBool("CW_InvertView", val)
  ply:ChatPrint("Invert view: " .. tostring(val))
  return true
end

function TOOL.BuildCPanel(panel)
  panel:AddControl("Header", { Description = "Pick a ceiling (right-click), then enable with left-click. Reload to toggle camera inversion." })
  panel:NumSlider("Accel (units/s^2)", "ceilingwalk_accel", 100, 2000, 0)
  panel:Button("Demo: Select look surface and enable", "cw_demo")
  panel:Button("Disable", "cw_disable")
end

if SERVER then
  concommand.Add("cw_disable", function(ply)
    if not IsValid(ply) then return end
    ply:SetNWBool("CW_Enabled", false)
    ply:SetGravity(1)
  end)
end