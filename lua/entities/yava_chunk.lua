AddCSLuaFile()

ENT.Type   = "anim"

function ENT:Initialize()
    -- :)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end

function ENT:SetupCollisions(soup)
    self:EnableCustomCollisions(true)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    self:PhysicsFromMesh(soup)
    self:GetPhysicsObject():EnableMotion(false)
    
    --self:SetCollisionBounds(Vector(-6000,-6000,-6000), Vector(6000,6000,6000) )
    --self:PhysicsInit(SOLID_VPHYSICS)
end

--[[function ENT:TestCollision() 
    if SERVER then
        print("!!!",self:GetCollisionBounds())
    end
end]]

function ENT:Think()
    --print("~")
    self:SetCollisionBounds(Vector(-6000,-6000,-6000), Vector(6000,6000,6000) )
end

--[[function ENT:Draw()
    print("rer")
end]]