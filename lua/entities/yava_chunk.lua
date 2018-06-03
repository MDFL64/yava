AddCSLuaFile()

ENT.Type   = "anim"

function ENT:Initialize()
    -- :)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end

local count = 0
function ENT:SetupCollisions(soup,mins,maxs)
    print("creating")
    self:PhysicsFromMesh(soup)
    self:GetPhysicsObject():EnableMotion(false)

    self:EnableCustomCollisions(true)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)


    self.correct_mins = mins
    self.correct_maxs = maxs
    count = count + 1
    print("created",count)
end

--[[function ENT:TestCollision() 
    if SERVER then
        print("!!!",self:GetCollisionBounds())
    end
end]]

function ENT:Think()
    local mins = self.correct_mins
    local maxs = self.correct_maxs

    self:SetCollisionBounds(mins, maxs)
end

--[[function ENT:Draw()
    print("rer")
end]]