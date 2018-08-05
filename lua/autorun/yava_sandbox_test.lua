if game.GetMap()~="yava_void" or GetConVar("gamemode"):GetString()~="sandbox" then return end

AddCSLuaFile()

if SERVER then resource.AddWorkshop("1402515908") end

include("yava.lua")

yava.addBlockType("rock")
yava.addBlockType("dirt")

yava.addBlockType("grass",{
    topImage = "grass_top",
    bottomImage = "dirt"
})

--laylad
yava.addBlockType("light")
yava.addBlockType("dark")
yava.addBlockType("orange")
yava.addBlockType("red")
yava.addBlockType("green")

yava.addBlockType("face")
yava.addBlockType("checkers")
yava.addBlockType("purple")
yava.addBlockType("water")

yava.addBlockType("test",{
    frontImage = "test_front",
    backImage = "test_back",
    leftImage = "test_left",
    rightImage = "test_right",
    topImage = "test_top",
    bottomImage = "test_bottom"
})
yava.addBlockType("tree",{
    topImage = "tree_top",
    bottomImage = "tree_top"
})
yava.addBlockType("leaves")
yava.addBlockType("wood")
yava.addBlockType("sand")

yava.init{
    imageDir = "yava_test",
    saveDir = "testbed",
    generator = function(x,y,z)
        
        local offset_mid_x = x-320
        local offset_mid_y = y-320
    
        local dist_mid_sqr = offset_mid_x^2 + offset_mid_y^2
    
        if dist_mid_sqr<100 and z<=50 then
            return "rock"
        end
    
        if ((x-180)^2 + (y-180)^2 + (z-120)^2)^.5 < 30 then
            return "checkers"
        elseif ((x-180)^2 + (y-180)^2)^.5 < (100-z)/10 and (100-z)/10>0 then
            return "purple"
        end
    
        local lvl
        
        if dist_mid_sqr<10000 then
            lvl = 50
        elseif dist_mid_sqr<16000 then
            if z<3 then
                return "water"
            elseif z<50 and math.random()<.002 then
                return "test"
            end
            return "void"
        else
            local scale = dist_mid_sqr/15000
            lvl = (math.sin(x/16) + math.sin(y/16)*4)*scale + 50
        end
        
        if z<lvl then
            if lvl-z <= 1 then
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

if SERVER then
    timer.Create("yava_autosave",60*10,0, function()
        yava.save()
    end)

    hook.Add("ShutDown","yava_autosave",function()
        yava.save()
    end)

    concommand.Add("yava_reload", function(ply,cmd,args)
        if ply:IsAdmin() then
            if args[1] then
                if args[1] == "@" then
                    yava.currentConfig.loadFile = nil
                else
                    yava.currentConfig.loadFile = args[1]
                end
            end
            yava.init()
        end
    end)
end

hook.Add("PlayerSpawn","yava_spawn_move",function(ply)
    ply:SetPos(Vector(0, 0, -10690))
    ply:Give("yava_gun")
    ply:SetStepSize(20)
    if ply:IsAdmin() then
        ply:Give("yava_bulk")
        ply:Give("yava_adv")        
    end
end)

if CLIENT then
    hook.Add("Initialize","yava_setup_ui",function()
        CreateClientConVar("yava_brush_mat","rock", false, true)
		CreateClientConVar("yava_atlas_test","0", false, false)        

        local combo = g_ContextMenu:Add("DComboBox")
		combo:SetPos(20,130)
        combo:SetWide(200)
        
        for i=1,#yava._blockTypes do
            local type = yava._blockTypes[i]
            if type ~= "void" then
                combo:AddChoice(type,nil,type=="rock")
            end
        end

        combo.OnSelect = function(self,index,value,data)
			RunConsoleCommand("yava_brush_mat",value)
        end
    end)

    hook.Add("PostDrawOpaqueRenderables","yava_drawhelpers",function()
        local w = LocalPlayer():GetActiveWeapon()
		if IsValid(w) and w.YavaDraw then
			w:YavaDraw()
		end
	end)

    -- diagnostics

    --[[concommand.Add("yava_diag", function()
        local texture = yava._atlas_screen:GetTexture("$basetexture")
        local w1,h1 = texture:GetMappingWidth(),texture:GetMappingHeight()
        local w2,h2 = texture:Width(),texture:Height()
        print("Atlas size: "..w1.."x"..h1.." / "..w2.."x"..h2)
    end)]]

    hook.Add("HUDPaint", "yava_atlas_test", function() 
        if GetConVar("yava_atlas_test"):GetBool() and yava._atlas then
            local texture = yava._atlas_screen:GetTexture("$basetexture")
            local w,h = texture:GetMappingWidth(),texture:GetMappingHeight()

            surface.SetMaterial(yava._atlas_screen)
            surface.SetDrawColor( 255, 255, 255, 255 ) 
            surface.DrawTexturedRect(0,0,w,h)
        end
    end)
end