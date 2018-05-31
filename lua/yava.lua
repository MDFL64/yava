yava = {}

do -- CONSTANTS
    yava.FACE_NONE = 0
    yava.FACE_TRANSPARENT = 1
    yava.FACE_TRANSPARENT_NOCULL = 2
    yava.FACE_OPAQUE = 3
end

function yava.init(config)
    config = config or {}
    
    local function setDefault(key,value)
        if config[key] then return end
        config[key] = value
    end

    setDefault("basePos", Vector(-5000,-2000,2000))
    setDefault("chunkDimensions", Vector(4,4,4))
    setDefault("blockScale", 40)
    setDefault("generator", function() return "void" end)

    yava._vmatrix = Matrix()

    yava._vmatrix:Translate( config.basePos )
    yava._vmatrix:Scale( Vector( 1, 1, 1 ) * config.blockScale )

    yava._generator = config.generator

    if CLIENT then
        yava._buildAtlas()
    else
        yava._buildChunks( config.chunkDimensions )
        for _,ply in pairs(player.GetHumans()) do
            yava._addClient(ply)
        end
    end
end

if CLIENT then
    function yava._buildAtlas()
        local pointSample = true
        local atlas_texture = GetRenderTargetEx("__yava_atlas",16,16384,
            RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,pointSample and 1 or 0,CREATERENDERTARGETFLAGS_AUTOMIPMAP,IMAGE_FORMAT_RGBA8888)

        render.PushRenderTarget(atlas_texture)
        cam.Start2D()

        render.Clear(255,0,255,255)
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
                    local chunk = yava._chunkGenerate(x,y,z)
                    yava._chunks[yava._chunkKey(x,y,z)] = chunk
                    yava._stale_chunk_set[chunk] = true
                end
            end
        end
    end
end

local nul_table = {}
function yava._updateChunks()
    local chunk = next(yava._stale_chunk_set)
    if not chunk then return end

    if CLIENT then
        local cnx = yava._chunks[yava._chunkKey(chunk.x+1,chunk.y,chunk.z)] or nul_table
        local cny = yava._chunks[yava._chunkKey(chunk.x,chunk.y+1,chunk.z)] or nul_table
        local cnz = yava._chunks[yava._chunkKey(chunk.x,chunk.y,chunk.z+1)] or nul_table
    
        chunk.mesh = yava._chunkGenMesh(chunk.block_data,chunk.x,chunk.y,chunk.z,cnx.block_data,cny.block_data,cnz.block_data)
    end

    yava._stale_chunk_set[chunk] = nil
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

local next_block_id = 0
function yava.addBlockType(name,settings)
    if yava._generator then error("Cannot add block types after init.") end
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
end

yava.addBlockType("void",{faceType = yava.FACE_NONE})

include("yava_chunk.lua")

hook.Add("Think","yava_update",function()
    yava._updateChunks()

    if SERVER then
        yava._sendChunks()
    end
end)

if CLIENT then
    hook.Add("PostDrawOpaqueRenderables","yava_render",function()
        render.SuppressEngineLighting(true) 
        render.SetModelLighting(BOX_TOP,    1,1,1 )
        render.SetModelLighting(BOX_FRONT,  .8,.8,.8 )
        render.SetModelLighting(BOX_RIGHT,  .6,.6,.6 )
        render.SetModelLighting(BOX_LEFT,   .5,.5,.5 )
        render.SetModelLighting(BOX_BACK,   .3,.3,.3 )
        render.SetModelLighting(BOX_BOTTOM, .1,.1,.1 )
        
        render.SetMaterial( yava._atlas )

        cam.PushModelMatrix( yava._vmatrix )
        for _,chunk in pairs(yava._chunks) do
            if chunk.mesh then
                chunk.mesh:Draw()
            end
        end
        cam.PopModelMatrix()

        render.SuppressEngineLighting(false) 
    end)

    net.Receive("yava_chunk_blocks", function(bitlen)
        local x = net.ReadUInt(16)
        local y = net.ReadUInt(16)
        local z = net.ReadUInt(16)
        local len = net.ReadUInt(16)

        local block_data = {}
        for i=1,len do
            local n = net.ReadUInt(24)
            n = n+net.ReadUInt(24)*16777216
            table.insert(block_data,n)
        end

        local chunk = {x=x,y=y,z=z,block_data=block_data}
        yava._chunks[yava._chunkKey(x,y,z)] = chunk
        yava._stale_chunk_set[chunk] = true

        local next_chunk = yava._chunks[yava._chunkKey(x-1,y,z)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end
        local next_chunk = yava._chunks[yava._chunkKey(x,y-1,z)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end
        local next_chunk = yava._chunks[yava._chunkKey(x,y,z-1)]
        if next_chunk then yava._stale_chunk_set[next_chunk] = true end
    end)
else
    -- the last client we tried to send a chunk to
    -- used for a round-robin scheme
    util.AddNetworkString("yava_chunk_blocks")

    yava._currentClient = nil
    yava._clients = {}

    hook.Add("PlayerInitialSpawn","yava_player_join",function(ply)
        yava._addClient(ply)
    end)

    function yava._addClient(ply)
        if yava._clients[ply] then return end

        yava._clients[ply] = {}
        for _,chunk in pairs(yava._chunks) do
            yava._clients[ply][chunk] = true
        end

        print("adding client",ply)
    end

    local nextChunk = 0
    function yava._sendChunks()
        if SysTime()<nextChunk then
            return
        end

        yava._currentClient = next(yava._clients,yava._currentClient)
        if not IsValid(yava._currentClient) then
            if yava._currentClient ~= nil then
                yava._clients[yava._currentClient] = nil
                yava._currentClient = nil
            end
            return
        end

        local client_table = yava._clients[yava._currentClient]

        local send_chunk = next(client_table)

        if not send_chunk then return end
        
        -- send the chunk
        net.Start("yava_chunk_blocks")
        net.WriteUInt(send_chunk.x, 16)
        net.WriteUInt(send_chunk.y, 16)
        net.WriteUInt(send_chunk.z, 16)
        net.WriteUInt(#send_chunk.block_data, 16)

        for i=1,#send_chunk.block_data do
            local n = send_chunk.block_data[i]
            net.WriteUInt(bit.band(n,0xFFFFFF), 24)
            net.WriteUInt(bit.band(math.floor(n/16777216),0xFFFFFF), 24)
        end

        net.Send(yava._currentClient)
        
        nextChunk = SysTime() + (#send_chunk.block_data)/100000

        client_table[send_chunk] = nil
    end
end
