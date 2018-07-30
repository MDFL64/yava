AddCSLuaFile()

SWEP.PrintName = "Advanced Voxel Gun"

SWEP.UseHands = true
SWEP.WorldModel = "models/weapons/w_SMG1.mdl"
SWEP.ViewModel = "models/weapons/c_SMG1.mdl"

SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

SWEP.Category = "YAVA"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Slot = 5

function SWEP:SetupDataTables()
	self:NetworkVar("Vector",0,"P1")
	self:NetworkVar("Vector",1,"P2")
end

function SWEP:Initialize()
	self.next_reload=0

	if SERVER then
		self.point_selected = false
	end
end

function SWEP:PrimaryAttack()

	if IsFirstTimePredicted() and yava then
		self:EmitSound( "ambient/machines/teleport1.wav" )
		
		if SERVER then
			local x1,y1,z1 = yava.worldPosToBlockCoords(self:GetP1())
			local x2,y2,z2 = yava.worldPosToBlockCoords(self:GetP2())
			yava.setRegion(x1,y1,z1,x2,y2,z2,"void")
		end
	end

	self:SetNextPrimaryFire(CurTime()+1)
end

function SWEP:SecondaryAttack()
	if IsFirstTimePredicted() and yava then
		self:EmitSound( "npc/env_headcrabcanister/explosion.wav" )

		if SERVER then
			local x1,y1,z1 = yava.worldPosToBlockCoords(self:GetP1())
			local x2,y2,z2 = yava.worldPosToBlockCoords(self:GetP2())
			yava.setRegion(x1,y1,z1,x2,y2,z2,self.Owner:GetInfo("yava_brush_mat"))
		end
	end

	self:SetNextSecondaryFire(CurTime()+1)
end

function SWEP:Reload()
	if IsFirstTimePredicted() and yava then
		if CurTime()>self.next_reload then
			self:EmitSound( "buttons/button15.wav" )

			if SERVER then
				local tr = self.Owner:GetEyeTrace()

				if self.point_selected then
					self:SetP1(tr.HitPos+tr.HitNormal*20)
				else
					self:SetP2(tr.HitPos+tr.HitNormal*20)
				end

				self.point_selected= !self.point_selected
			end

			self.next_reload=CurTime()+1
		end
	end
end

local mat = Material("models/wireframe")

function SWEP:YavaDraw()
	local min = self:GetP1()
	local max = self:GetP2()
	
	OrderVectors(min,max)

	render.SetMaterial(mat)

	render.DrawBox(min,Angle(0,0,0),Vector(),max-min)
end