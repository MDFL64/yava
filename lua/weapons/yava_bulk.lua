AddCSLuaFile()

SWEP.PrintName = "Bulk Voxel Gun"

SWEP.UseHands = true
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.ViewModel = "models/weapons/c_357.mdl"

SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

SWEP.Category = "YAVA"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Slot = 5

function SWEP:SetupDataTables()
	self:NetworkVar("Int",0,"BrushSize")
end

function SWEP:Initialize()
	self:SetBrushSize(500)
end

function SWEP:PrimaryAttack()
	if IsFirstTimePredicted() and yava then
		if !self.Owner:KeyDown(IN_RELOAD) then self:EmitSound( "ambient/explosions/explode_1.wav" ) end

		if SERVER then
			local r_world = self:GetBrushSize()
			local r = yava.worldDistToBlockCount(r_world)

			if self.Owner:KeyDown(IN_RELOAD) then
				if r_world<5000 then self:SetBrushSize(r_world+5) end
				return
			end

			local tr = self.Owner:GetEyeTrace()
			local x,y,z = yava.worldPosToBlockCoords(tr.HitPos-tr.HitNormal)

			if r>0 then
				yava.setSphere(x,y,z,r,"void")
			else
				yava.setRegion(x-r,y-r,z-r,x+r,y+r,z+r,"void")
			end
		end
	end

	self:SetNextPrimaryFire(CurTime()+1)
end

function SWEP:SecondaryAttack()
	if IsFirstTimePredicted() and yava then
		if !self.Owner:KeyDown(IN_RELOAD) then self:EmitSound( "npc/env_headcrabcanister/explosion.wav" ) end

		if SERVER then
			local r_world = self:GetBrushSize()
			local r = yava.worldDistToBlockCount(r_world)

			if self.Owner:KeyDown(IN_RELOAD) then
				if r_world>-5000 then self:SetBrushSize(r_world-5) end
				return
			end

			local tr = self.Owner:GetEyeTrace()
			local x,y,z = yava.worldPosToBlockCoords(tr.HitPos+tr.HitNormal)

			if r>0 then
				yava.setSphere(x,y,z,r,self.Owner:GetInfo("yava_brush_mat"))
			else
				yava.setRegion(x-r,y-r,z-r,x+r,y+r,z+r,self.Owner:GetInfo("yava_brush_mat"))
			end
		end
	end

	self:SetNextSecondaryFire(CurTime()+1)
end

local mat = Material("models/wireframe")

function SWEP:YavaDraw()
	local b = self:GetBrushSize()
	local tr = self.Owner:GetEyeTrace()
	render.SetMaterial(mat)

	if b>0 then
		render.DrawSphere(tr.HitPos,b,10,10)
	else
		local off = Vector(b,b,b)
		render.DrawBox(tr.HitPos,Angle(0,0,0),off,-off)
	end
end