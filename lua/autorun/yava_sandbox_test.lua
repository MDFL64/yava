if game.GetMap()~="yava_void" or GetConVar("gamemode"):GetString()~="sandbox" then return end

AddCSLuaFile()

if SERVER then resource.AddWorkshop("1402515908") end

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
yava.addBlockType("tree",{
    topImage = "tree_top",
    bottomImage = "tree_top"
})
yava.addBlockType("leaves")
yava.addBlockType("wood")
yava.addBlockType("sand")

yava.init{
    imageDir = "yava_test",
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
    ply:Give("yava_gun")
    if ply:IsAdmin() then
        ply:Give("yava_bulk")
        ply:Give("yava_adv")        
    end
end)

if CLIENT then
    hook.Add("Initialize","yava_setup_ui",function()
        CreateClientConVar("yava_brush_mat","purple", false, true)
		CreateClientConVar("yava_atlas_test","0", false, false)        

		local combo = g_ContextMenu:Add("DComboBox")
		combo:SetPos(20,130)
        combo:SetWide(200)
        
        for i=1,#yava._blockTypes do
            local type = yava._blockTypes[i]
            if type ~= "void" then
                combo:AddChoice(type,nil,type=="purple")
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

    concommand.Add("yava_diag", function()
        local texture = yava._atlas_screen:GetTexture("$basetexture")
        local w1,h1 = texture:GetMappingWidth(),texture:GetMappingHeight()
        local w2,h2 = texture:Width(),texture:Height()
        print("Atlas size: "..w1.."x"..h1.." / "..w2.."x"..h2)
    end)

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