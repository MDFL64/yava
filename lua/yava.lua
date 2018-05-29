yava = {}

do -- CONSTANTS
    yava.FACE_NONE = 0
    yava.FACE_TRANSPARENT = 1
    yava.FACE_TRANSPARENT_NOCULL = 2
    yava.FACE_OPAQUE = 3
end

function yava.init(config)
    config = config or {}
    yava._config = config
    
    local function setDefault(key,value)
        if config[key] then return end
        config[key] = value
    end

    setDefault("basePos", Vector(0,0,0))
    setDefault("chunkDimensions", Vector(4,4,4))
    setDefault("blockScale", 40)
    setDefault("generator", function() return "void" end)

    yava._vmatrix = Matrix()

    yava._vmatrix:Translate( config.basePos )
    yava._vmatrix:Scale( Vector( 1, 1, 1 ) * config.blockScale )

    yava._buildAtlas()
    yava._buildChunks()
end

function yava._buildAtlas() 
    -- ATLAS SETUP
    -- 16384
    local atlas_texture = GetRenderTargetEx("__yava_atlas",16,1024,RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,0 --[[point sample?]], CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_RGBA8888)

    render.PushRenderTarget(atlas_texture)
    cam.Start2D()

    render.Clear(255,0,255,255)
    surface.SetDrawColor(255,255,255,255)
    for i=1,#yava._images do
        local name = yava._images[i]
        local source = Material("yava/"..name..".png")

        surface.SetMaterial(source)
        surface.DrawTexturedRectUV(0,i*32-16,16,8,0,.5,1,1)
        surface.DrawTexturedRect(0,i*32-8,16,16)
        surface.DrawTexturedRectUV(0,i*32+8,16,8,0,0,1,.5)
    end

    cam.End2D()
    render.PopRenderTarget()

    yava._atlas = CreateMaterial("__yava_atlas", "VertexLitGeneric")
    yava._atlas:SetTexture("$basetexture",atlas_texture)
end

yava._chunks = {}
yava._stale_chunk_set = {}

function yava._chunkKey(x,y,z)
    return x+y*1024+z*1048576
end

function yava._buildChunks()
    local dims = yava._config.chunkDimensions
    for z=0,dims.z-1 do
        for y=0,dims.y-1 do
            for x=0,dims.x-1 do
                local chunk = yava._chunkInit(x,y,z)
                yava._chunks[yava._chunkKey(x,y,z)] = chunk
                yava._stale_chunk_set[chunk] = true
            end
        end
    end
end

function yava._updateChunks()
    local chunk = next(yava._stale_chunk_set)
    if not chunk then return end

    chunk.mesh = yava._chunkGenMesh(chunk.block_data,chunk.x,chunk.y,chunk.z)
    yava._stale_chunk_set[chunk] = nil
end

yava._blockTypes = {}
yava._images = {}

local next_block_id = 0
function yava.addBlockType(name,settings)
    if yava._config then error("Cannot add block types after init.") end

    settings = settings or {}

    local block_id = #yava._blockTypes

    yava._blockTypes[block_id+1] = settings
    yava._blockTypes[name] = settings

    settings[1] = block_id
    settings[2] = name
    
    local defaultImage = settings.faceImage or name
    local imageTable = {
        settings.frontImage or defaultImage,
        settings.leftImage or defaultImage,
        settings.topImage or defaultImage,
        settings.backImage or defaultImage,
        settings.rightImage or defaultImage,
        settings.bottomImage or defaultImage
    }
    
    local defaultType = settings.faceType or yava.FACE_OPAQUE
    local typeTable = {
        settings.frontType or defaultType,
        settings.leftType or defaultType,
        settings.topType or defaultType,
        settings.backType or defaultType,
        settings.rightType or defaultType,
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
        settings[i*2+1] = yava._images[imageTable[i]] or 0
        settings[i*2+2] = typeTable[i]
    end
end

yava.addBlockType("void",{faceType = yava.FACE_NONE})

include("yava_chunk.lua")

hook.Add("PostDrawOpaqueRenderables","yava_render",function()
    yava._updateChunks()

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