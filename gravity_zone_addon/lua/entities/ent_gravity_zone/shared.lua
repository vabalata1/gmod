ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Gravity Zone"
ENT.Author = "gravity-zone"
ENT.Category = "Gravity"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
  -- Direction of gravity inside the zone (world vector). For ceiling, use Vector(0,0,1).
  self:NetworkVar("Vector", 0, "GravityVector")
  -- Gravity acceleration magnitude (units/s^2). e.g., 600.
  self:NetworkVar("Float", 0, "GravityAccel")
  -- If true, roll the player's view to align with the inverted up direction.
  self:NetworkVar("Bool", 0, "InvertView")
end