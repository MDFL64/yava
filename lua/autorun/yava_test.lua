if SERVER then return end

include("yava.lua")

yava.addBlockType("face")
yava.addBlockType("checkers")
yava.addBlockType("purple")
yava.addBlockType("stripes")
yava.addBlockType("test",{
    frontImage = "test_front",
    backImage = "test_back",
    leftImage = "test_left",
    rightImage = "test_right",
    topImage = "test_top",
    bottomImage = "test_bottom"
})
yava.addBlockType("rock")
yava.addBlockType("dirt")
yava.addBlockType("grass",{
    topImage = "grass_top",
    bottomImage = "dirt"
})

yava.init{
    generator = function(x,y,z)
        
        if x==70 and y==70 then
            return "face"
        end

        if ((x-60)^2 + (y-60)^2 + (z-100)^2)^.5 < 30 then
            return "checkers"
        elseif ((x-60)^2 + (y-60)^2)^.5 < (100-z)/10 and (100-z)/10>0 then
            return "purple"
        end
        
        if x>20+math.sin(y/40)*10 and x<45+math.sin(y/10)*5 then
            if z<10 then
                return "stripes"
            end
            if math.random()<.001 then return "test" end
            return "void"
        end

        local lvl = math.sin(x/16)*5 + math.sin(y/16)*10 + 30
        if z<lvl then
            if lvl-z < 1 then
                return "grass"
            end
            if lvl-z > 5 then
                return "rock"
            end
            return "dirt"
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