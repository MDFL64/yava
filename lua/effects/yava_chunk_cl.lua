function EFFECT:Init()
    yava._new_chunk_ent = self
end

function EFFECT:Think()
    self:SetCollisionBounds(Vector(-6000,-6000,-6000), Vector(6000,6000,6000) )
    --print(self:GetCollisionGroup())
    --print(self:GetPos())
    self:SetPos(Vector(0,0,0))
    return true
end

function EFFECT:Render()
    --self:DrawModel()
end

function EFFECT:TestCollision() 
    --if SERVER then
    print("!!!!!!")
    --end
end