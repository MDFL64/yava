AddCSLuaFile()

yava = {}

do -- CONSTANTS
    yava.FACE_NONE = 0
    yava.FACE_TRANSPARENT = 1
    yava.FACE_TRANSPARENT_NOCULL = 2
    yava.FACE_OPAQUE = 3
end


-- Kill old chunk colliders
if SERVER then
    --print("deleting")
    for _, ent in pairs( ents.FindByClass( "yava_chunk" ) ) do
        ent:Remove()
    end
    --print("deleted")
end

function yava.init(config)
    config = config or {}
    
    local function setDefault(key,value)
        if config[key] then return end
        config[key] = value
    end

    setDefault("basePos", Vector(-12800,-12800,0))
    setDefault("chunkDimensions", Vector(20,20,5))
    setDefault("blockScale", 40)
    setDefault("generator", function() return "void" end)

    yava._vmatrix = Matrix()

    yava._offset = config.basePos
    yava._scale = config.blockScale
    yava._vmatrix:Translate( yava._offset )
    yava._vmatrix:Scale( Vector( 1, 1, 1 ) * yava._scale )

    yava._generator = config.generator

    if CLIENT then
        timer.Simple(0,function()
            yava._buildAtlas()
        end)
    else
        yava._buildChunks( config.chunkDimensions )
        for _,ply in pairs(player.GetHumans()) do
            yava._addClient(ply)
        end
    end

    yava._isSetup = true
end

if CLIENT then

    function yava._buildAtlas()
        local pointSample = true
        local atlas_texture = GetRenderTargetEx("__yava_atlas",16,16384,
            RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,pointSample and 1 or 0,CREATERENDERTARGETFLAGS_AUTOMIPMAP,IMAGE_FORMAT_RGBA8888)

        render.PushRenderTarget(atlas_texture)
        cam.Start2D()

        render.Clear(0,0,0,255)
        surface.SetDrawColor(255,255,255,255)
        for i=1,#yava._images do
            local name = yava._images[i]
            local source = Material("yava/"..name..".png")

            surface.SetMaterial(source)
            surface.DrawTexturedRectUV(0,(i-1)*32,16,8,0,.5,1,1)
            surface.DrawTexturedRect(0,(i-1)*32+8,16,16)
            surface.DrawTexturedRectUV(0,(i-1)*32+24,16,8,0,0,1,.5)
        end

        cam.End2D()
        render.PopRenderTarget()

        yava._atlas = CreateMaterial("__yava_atlas", "VertexLitGeneric")
        yava._atlas:SetTexture("$basetexture",atlas_texture)
    end
end

yava._chunks = {}
yava._stale_chunk_set = {}

function yava._chunkKey(x,y,z)
    return x+y*1024+z*1048576
end

if SERVER then
    function yava._buildChunks(dims)
        for z=0,dims.z-1 do
            for y=0,dims.y-1 do
                for x=0,dims.x-1 do
                    local consumer, chunk = yava._chunkConsumerConstruct(x,y,z)
                    yava._chunkProvideGenerate(x,y,z,consumer)

                    yava._chunks[yava._chunkKey(x,y,z)] = chunk
                    yava._stale_chunk_set[chunk] = true
                end
            end
        end

        local sum = 0
        for _,chunk in pairs(yava._chunks) do
            sum = sum + #chunk.block_data
        end
        --print(sum*8)
    end
end

local nul_table = {}
--local cl_table = {}
function yava._updateChunks()
    local chunk = next(yava._stale_chunk_set)
    if not chunk then return false end

    if CLIENT then
        local cnx = yava._chunks[yava._chunkKey(chunk.x+1,chunk.y,chunk.z)] or nul_table
        local cny = yava._chunks[yava._chunkKey(chunk.x,chunk.y+1,chunk.z)] or nul_table
        local cnz = yava._chunks[yava._chunkKey(chunk.x,chunk.y,chunk.z+1)] or nul_table
        
        chunk.mesh = yava._chunkGenMesh(chunk.block_data,chunk.x,chunk.y,chunk.z,cnx.block_data,cny.block_data,cnz.block_data)
    end
    if SERVER then
        local cnx = yava._chunks[yava._chunkKey(chunk.x+1,chunk.y,chunk.z)] or nul_table
        local cny = yava._chunks[yava._chunkKey(chunk.x,chunk.y+1,chunk.z)] or nul_table
        local cnz = yava._chunks[yava._chunkKey(chunk.x,chunk.y,chunk.z+1)] or nul_table

        local soup = yava._chunkGenPhysics_dirtySoup(chunk.block_data,chunk.x,chunk.y,chunk.z,cnx.block_data,cny.block_data,cnz.block_data)

        if IsValid(chunk.collider_ent) then
            -- todo try reusing it instead
            --print("delete old")
            chunk.collider_ent:Remove()
            --print("delete old done")
        end

        if soup then
            if SERVER then
                
                local mins = yava._offset + Vector(chunk.x,chunk.y,chunk.z)*yava._scale*32
                local maxs = mins + Vector(32,32,32)*yava._scale

                local e = ents.Create("yava_chunk")
                e:Spawn()
                e:SetupCollisions(soup,mins,maxs)

                chunk.collider_ent = e
            else
                --[[local ed = EffectData()
                util.Effect("yava_chunk_cl", ed)
                local e = yava._new_chunk_ent

                do
                    --e:EnableCustomCollisions(true)
        
                    e:PhysicsInit(SOLID_VPHYSICS)
                    e:SetSolid(SOLID_VPHYSICS)
                    e:SetMoveType(MOVETYPE_VPHYSICS)
                
                    e:PhysicsFromMesh(soup_data)
                    e:GetPhysicsObject():EnableMotion(false)
                    --local m = e:GetPhysicsObject():GetMesh()
                end]]
            end
            --print("~~",e)
        end
    end

    yava._stale_chunk_set[chunk] = nil
    return true
end

-- maps (name -> id) and (id+1 -> name)
yava._blockTypes = {}
-- each subtable maps (id+1 -> data)
if CLIENT then
    yava._blockFaceImages = {{},{},{},{},{},{}}
    yava._blockFaceTypes = {{},{},{},{},{},{}}
    -- maps (name -> index) and (index -> name)
    yava._images = {}
end

yava._blockSolidity = {}

local next_block_id = 0
function yava.addBlockType(name,settings)
    if yava._isSetup then error("Cannot add block types after init.") end
    settings = settings or {}

    local block_id = #yava._blockTypes

    yava._blockTypes[block_id+1] = name
    yava._blockTypes[name] = block_id
    
    if CLIENT then
        local defaultImage = settings.faceImage or name
        local imageTable = {
            settings.rightImage or defaultImage,
            settings.backImage or defaultImage,
            settings.topImage or defaultImage,
            settings.leftImage or defaultImage,
            settings.frontImage or defaultImage,
            settings.bottomImage or defaultImage
        }
        
        local defaultType = settings.faceType or yava.FACE_OPAQUE
        local typeTable = {
            settings.rightType or defaultType,
            settings.backType or defaultType,
            settings.topType or defaultType,
            settings.leftType or defaultType,
            settings.frontType or defaultType,
            settings.bottomType or defaultType
        }
        
        for i,img_name in pairs(imageTable) do
            if not yava._images[img_name] and typeTable[i] ~= 0 then
                local img_id = #yava._images+1
                yava._images[img_id] = img_name
                yava._images[img_name] = img_id
            end
        end
        
        for i=1,6 do
            yava._blockFaceImages[i][block_id+1] = yava._images[imageTable[i]] or 0
            yava._blockFaceTypes[i][block_id+1] = typeTable[i]
        end
    end

    local solid = settings.solid
    if solid == nil then solid = true end

    yava._blockSolidity[block_id+1] = solid
end

yava.addBlockType("void",{faceType = yava.FACE_NONE, solid = false})

include("yava_lib_chunk.lua")

hook.Add("Think","yava_update",function()
    local start = SysTime()
    
    for i=1,100 do
        local t = SysTime()-start
        if not yava._updateChunks() then break end
        if t>.005 then break end
    end
    
    if SERVER then
        yava._sendChunks()
    end
end)

if CLIENT then
    hook.Add("PostDrawOpaqueRenderables","yava_render",function()
        
        if not yava._isSetup then return end
        
        render.SuppressEngineLighting(true) 
        render.SetModelLighting(BOX_TOP,    1,1,1 )
        render.SetModelLighting(BOX_FRONT,  .8,.8,.8 )
        render.SetModelLighting(BOX_RIGHT,  .6,.6,.6 )
        render.SetModelLighting(BOX_LEFT,   .5,.5,.5 )
        render.SetModelLighting(BOX_BACK,   .3,.3,.3 )
        render.SetModelLighting(BOX_BOTTOM, .1,.1,.1 )
        
        if yava._atlas then
            render.SetMaterial( yava._atlas )
        end

        cam.PushModelMatrix( yava._vmatrix )
        for _,chunk in pairs(yava._chunks) do
            if chunk.mesh then
                chunk.mesh:Draw()
            end
        end
        cam.PopModelMatrix()

        render.SuppressEngineLighting(false) 
    end)

    local rx_chunk_count = 0
    net.Receive("yava_chunk_blocks", function()
        local x = net.ReadUInt(16)
        local y = net.ReadUInt(16)
        local z = net.ReadUInt(16)

        local consumer, chunk = yava._chunkConsumerConstruct(x,y,z)
        yava._chunkProvideNetwork(consumer)

        yava._chunks[yava._chunkKey(x,y,z)] = chunk
        yava._stale_chunk_set[chunk] = true

        local next_chunk = yava._chunks[yava._chunkKey(x-1,y,z)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end
        local next_chunk = yava._chunks[yava._chunkKey(x,y-1,z)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end
        local next_chunk = yava._chunks[yava._chunkKey(x,y,z-1)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end

        net.Start("yava_chunk_blocks_ack")
        net.WriteUInt(x, 16)
        net.WriteUInt(y, 16)
        net.WriteUInt(z, 16)
        net.SendToServer()
        
        rx_chunk_count = rx_chunk_count+1
        --print(rx_chunk_count)
    end)
else
    util.AddNetworkString("yava_chunk_blocks")
    util.AddNetworkString("yava_chunk_blocks_ack")
    util.AddNetworkString("yava_block")

    yava._clients = {}

    hook.Add("PlayerInitialSpawn","yava_player_join",function(ply)
        yava._addClient(ply)
    end)

    function yava._addClient(ply)
        if yava._clients[ply] then return end

        local info = {chunks={},send_count=1,last_chunk=nil,chunks_left=0}
        yava._clients[ply] = info
        for _,chunk in pairs(yava._chunks) do
            info.chunks[chunk] = false
            info.chunks_left = info.chunks_left + 1
        end
    end

    function yava._sendChunks()

        local removed_clients = {}

        for client, client_info in pairs(yava._clients) do

            if not IsValid(client) then table.insert(removed_clients,client) continue end
            
            if client_info.chunks_left > 0 then
                client_info.send_count = client_info.send_count + 1
                
                local expire_time = CurTime() - (client:Ping()/500)

                for i=1,100 do
                    if client_info.chunks_left <= 0 or client_info.send_count <= 0 then break end
                    
                    local chunk,v = next(client_info.chunks,client_info.last_chunk)
                    client_info.last_chunk = chunk
                    if chunk == nil then continue end
                    
                    if not v or v<expire_time then
                        -- send the chunk
                        net.Start("yava_chunk_blocks",true)
                        net.WriteUInt(chunk.x, 16)
                        net.WriteUInt(chunk.y, 16)
                        net.WriteUInt(chunk.z, 16)
                        
                        local consumer, finalize = yava._chunkConsumerNetwork()
                        yava._chunkProvideChunk(chunk,consumer)
                        finalize()
                        
                        net.Send(client,true)
                        
                        client_info.chunks[chunk] = CurTime()
                        
                        client_info.send_count = client_info.send_count - 1
                    end
                end
            end
        end
        
        -- prune client table
        for _,client in pairs(removed_clients) do
            yava._clients[client] = nil
        end
    end

    net.Receive("yava_chunk_blocks_ack", function(len,ply)
        local x = net.ReadUInt(16)
        local y = net.ReadUInt(16)
        local z = net.ReadUInt(16)

        local client_info = yava._clients[ply]
        local chunk = yava._chunks[yava._chunkKey(x,y,z)]

        if client_info and chunk then
            if client_info.chunks[chunk] ~= nil then
                client_info.chunks[chunk] = nil
                client_info.send_count = client_info.send_count + 1
                client_info.chunks_left = client_info.chunks_left - 1
                --print("ACK",client_info.send_count,client_info.chunks_left)
            end
        end
    end)
end

-- setBlock crap
do
    local function set_block(x,y,z,v)
        local cx = math.floor(x/32)
        local cy = math.floor(y/32)
        local cz = math.floor(z/32)
        local lx = x%32
        local ly = y%32
        local lz = z%32
        
        local chunk = yava._chunks[yava._chunkKey(cx,cy,cz)]
        
        if chunk and v then
            yava._chunkSetBlock(chunk.block_data,lx,ly,lz,v)
            yava._stale_chunk_set[chunk] = true
            
            if lx==0 then
                local next_chunk = yava._chunks[yava._chunkKey(cx-1,cy,cz)]
                if next_chunk then yava._stale_chunk_set[next_chunk] = true end
            end
            if ly==0 then
                local next_chunk = yava._chunks[yava._chunkKey(cx,cy-1,cz)]
                if next_chunk then yava._stale_chunk_set[next_chunk] = true end
            end
            if lz==0 then
                local next_chunk = yava._chunks[yava._chunkKey(cx,cy,cz-1)]
                if next_chunk then yava._stale_chunk_set[next_chunk] = true end
            end

            if SERVER then
                net.Start("yava_block")
                net.WriteInt(x,16) 
                net.WriteInt(y,16)
                net.WriteInt(z,16)
                net.WriteInt(v,16)
                net.Broadcast() 
            end
        end
    end

    if SERVER then
        yava.setBlock = function(x,y,z,type)
            --print(x,y,z,type)
            local v = yava._blockTypes[type]
            set_block(x,y,z,v)
        end
    else
        net.Receive("yava_block", function(bitlen)
            local x = net.ReadUInt(16)
            local y = net.ReadUInt(16)
            local z = net.ReadUInt(16)
            local v = net.ReadUInt(16)
            
            set_block(x,y,z,v)
        end)
    end
end

function yava.worldPosToBlockCoords(pos)
    local coords = (pos - yava._offset) / yava._scale
    return math.floor(coords.x), math.floor(coords.y), math.floor(coords.z)
end

-- Don't let players screw with our voxels!
hook.Add("PhysgunPickup", "yava_nophysgun", function(ply,ent)
	if ent:GetClass() == "yava_chunk" then return false end
end)

hook.Add("CanTool", "yava_notool", function(ply,tr,tool)
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "yava_chunk" then return false end
end)