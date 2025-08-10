include("shared.lua")

local BOX_COL = Color(120, 200, 255, 30)
local EDGE_COL = Color(120, 200, 255, 120)

function ENT:DrawTranslucent()
  render.SetColorMaterial()
  local mins, maxs = self:OBBMins(), self:OBBMaxs()
  render.DrawBox(self:GetPos(), self:GetAngles(), mins, maxs, BOX_COL)
  render.DrawWireframeBox(self:GetPos(), self:GetAngles(), mins, maxs, EDGE_COL, true)
end