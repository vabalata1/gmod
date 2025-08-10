AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local DEFAULT_MINS = Vector(-256, -256, -128)
local DEFAULT_MAXS = Vector(256, 256, 128)

function ENT:Initialize()
  self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
  self:SetNoDraw(true)
  self:DrawShadow(false)

  self:PhysicsInitBox(DEFAULT_MINS, DEFAULT_MAXS)
  self:SetCollisionBounds(DEFAULT_MINS, DEFAULT_MAXS)
  self:SetMoveType(MOVETYPE_NONE)
  self:SetSolid(SOLID_BBOX)
  self:SetTrigger(true)

  if not self:GetGravityVector() or self:GetGravityVector() == vector_origin then
    self:SetGravityVector(Vector(0, 0, 1)) -- pull toward ceiling (world +Z)
  end
  if self:GetGravityAccel() == 0 then
    self:SetGravityAccel(600)
  end
  self:SetInvertView(true)

  self._touchingPlayers = {}
end

function ENT:SetExtents(mins, maxs)
  self:PhysicsInitBox(mins, maxs)
  self:SetCollisionBounds(mins, maxs)
end

function ENT:SpawnFunction(ply, tr, classname)
  if not tr.Hit then return end
  local ent = ents.Create(classname or "ent_gravity_zone")
  ent:SetPos(tr.HitPos + tr.HitNormal * 4)
  ent:Spawn()
  ent:Activate()
  ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
  return ent
end

function ENT:StartTouch(ent)
  if not IsValid(ent) or not ent:IsPlayer() then return end
  self._touchingPlayers[ent] = true
  ent.CurrentGravityZone = self
  ent._gravityZoneOldGravity = ent:GetGravity()
  ent:SetGravity(0.0001) -- neutralize base gravity so our custom gravity dominates
end

function ENT:EndTouch(ent)
  if not IsValid(ent) or not ent:IsPlayer() then return end
  self._touchingPlayers[ent] = nil
  if ent.CurrentGravityZone == self then
    ent.CurrentGravityZone = nil
  end
  if ent._gravityZoneOldGravity then
    ent:SetGravity(ent._gravityZoneOldGravity)
    ent._gravityZoneOldGravity = nil
  else
    ent:SetGravity(1)
  end
end

function ENT:OnRemove()
  for ply, _ in pairs(self._touchingPlayers or {}) do
    if IsValid(ply) and ply.CurrentGravityZone == self then
      ply.CurrentGravityZone = nil
      if ply._gravityZoneOldGravity then
        ply:SetGravity(ply._gravityZoneOldGravity)
        ply._gravityZoneOldGravity = nil
      else
        ply:SetGravity(1)
      end
    end
  end
end