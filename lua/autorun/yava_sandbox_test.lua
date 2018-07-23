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
yava.addBlockType("stripes")

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

local MAP_FILE
if SERVER then 
    MAP_FILE = file.Open("fortblox2.dat","rb","DATA")
end
local CURRENT_INDEX = 0

local FORTBLOX = false

if FORTBLOX then
    yava.init{
        imageDir = "yava_test",
        blockScale=25,
        chunkDimensions=Vector(8,16,5),
        generator = function(x,y,z)
            if z>=128 then return "void" end

            local index = x + y*256 + z*256*512
            if index~=CURRENT_INDEX then
                MAP_FILE:Seek(index)
                CURRENT_INDEX = index
            end

            local d = MAP_FILE:ReadByte()
            CURRENT_INDEX=CURRENT_INDEX+1

            if d == 0 then      return "void"
            elseif d==1 then    return "rock"
            elseif d==2 then    return "dark"
            elseif d==5 then    return "red"
            elseif d==6 then    return "orange"
            elseif d==10 then   return "green"
            elseif d==128 then  return "dirt"
            else                return "light"
            end
        end
    }
else
    
end

hook.Add("PlayerSpawn","yava_spawn_move",function(ply)
    ply:SetPos(Vector(0, 0, 2120))
    ply:Give("yava_gun")
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