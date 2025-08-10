include("shared.lua")

local BOX_COL = Color(120, 200, 255, 30)
local EDGE_COL = Color(120, 200, 255, 120)
local HILITE_COL = Color(255, 200, 80, 180)

function ENT:DrawTranslucent()
  if not GetConVar("gravityzone_showzones") or GetConVar("gravityzone_showzones"):GetBool() ~= true then return end
  render.SetColorMaterial()
  local mins, maxs = self:OBBMins(), self:OBBMaxs()
  render.DrawBox(self:GetPos(), self:GetAngles(), mins, maxs, BOX_COL)
  render.DrawWireframeBox(self:GetPos(), self:GetAngles(), mins, maxs, EDGE_COL, true)

  local tr = LocalPlayer():GetEyeTrace()
  if IsValid(tr.Entity) and tr.Entity == self then
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), mins, maxs, HILITE_COL, true)
  end
end