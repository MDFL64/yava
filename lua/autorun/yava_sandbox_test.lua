
if game.GetMap()~="yava_void" or GetConVar("gamemode"):GetString()~="sandbox" then return end

AddCSLuaFile()

include("yava.lua")

yava.addBlockType("checkers")
yava.addBlockType("rock")

yava.addBlockType("face")
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

        if ((x-200)^2 + (y-200)^2 + (z-100)^2)^.5 < 30 then
            return "checkers"
        elseif ((x-200)^2 + (y-200)^2)^.5 < (100-z)/10 and (100-z)/10>0 then
            return "purple"
        end
        
        if x>300+math.sin(y/40)*10 and x<350+math.sin(y/10)*5 then
            if z<3 then
                return "stripes"
            end
            if math.random()<.001 then return "test" end
            return "void"
        end

        local lvl = math.sin(x/16)*5 + math.sin(y/16)*20 + 30
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

hook.Add("PlayerSpawn","yava_spawn_move",function(ply)
    ply:SetPos(Vector(-9000, -8000, 3000))
end)
