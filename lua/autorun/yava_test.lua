if SERVER then return end

include("yava.lua")

yava.addBlockType("face")
yava.addBlockType("checkers")
yava.addBlockType("purple")
yava.addBlockType("stripes")

yava.init{
    generator = function(x,y,z)
        
        if ((x-60)^2 + (y-60)^2 + (z-100)^2)^.5 < 30 then
            return "checkers"
        end
        
        if x>30 and x<45 then
            if z<10 then
                return "stripes"
            end   
            return "void"
        end

        local lvl = math.sin(x/16)*5 + math.sin(y/16)*10 + 30
        if z<lvl then
            if lvl-z > 5 then
                return "face"
            end
            return "purple"
        else
            return "void"
        end
    end
}

--[[hook.Add("HUDPaint", "sd0f98sdf", function()
    
    surface.SetMaterial(yava._atlas)
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.DrawTexturedRect(10,10,16,16384)

end)]]