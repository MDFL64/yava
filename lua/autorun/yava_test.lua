if SERVER then return end

include("yava.lua")

yava.addBlockType("face")
yava.addBlockType("checkers")
yava.addBlockType("purple")
yava.addBlockType("stripes")

yava.init{
    generator = function(x,y,z) if math.random()>.999 then return "face" else return "void" end end
}

hook.Add("HUDPaint", "sd0f98sdf", function()
    
    surface.SetMaterial(yava._atlas)
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.DrawTexturedRect(10,10,16,1024)

end)