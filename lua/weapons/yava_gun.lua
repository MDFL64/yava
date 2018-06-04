AddCSLuaFile()

SWEP.PrintName = "VOXEL GUN"

SWEP.UseHands = true
SWEP.WorldModel = "models/weapons/w_Pistol.mdl"
SWEP.ViewModel = "models/weapons/c_Pistol.mdl"

SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

function SWEP:PrimaryAttack()
	if IsFirstTimePredicted() then
		self:EmitSound( "physics/concrete/concrete_impact_soft1.wav" )

		if SERVER then
			local tr = self.Owner:GetEyeTrace()
			local x,y,z = yava.worldPosToBlockCoords(tr.HitPos-tr.HitNormal)
			yava.setBlock(x,y,z,"void")
		end
	end

	self:SetNextPrimaryFire(CurTime()+.2)
end

function SWEP:SecondaryAttack()
	if IsFirstTimePredicted() then
		self:EmitSound( "physics/concrete/concrete_block_impact_hard1.wav" )
		
		if SERVER then
			local tr = self.Owner:GetEyeTrace()
			local x,y,z = yava.worldPosToBlockCoords(tr.HitPos+tr.HitNormal)
			yava.setBlock(x,y,z,self.Owner:GetInfo("yava_brush_mat"))
		end
	end

	self:SetNextSecondaryFire(CurTime()+.2)
end