
yava.FACE_NONE = 0
yava.FACE_TRANSPARENT = 1
yava.FACE_TRANSPARENT_NOCULL = 2
yava.FACE_OPAQUE = 3

yava.blockTypes = {
    air = {faceType = yava.FACE_NONE}
}

function yava.addBlockType(name,table) {
    yava.blockTypes[name] = table
}

function yava._setupBlockTypes() {
    local blockTypes = yava.blockTypes

    local current_id = 1
    local blockArray = {}
    local textures = {}
    local current_texture=1
    for k,v in pairs(yava.blockTypes) do
        v[1] = k
        v[2] = current_id

        blockArray[current_id] = v
        current_id = current_id + 1
        
        local defaultImage = v.faceImage or v[1]
        local imageTable = {
            v.frontImage or defaultImage,
            v.leftImage or defaultImage,
            v.topImage or defaultImage,
            v.backImage or defaultImage,
            v.rightImage or defaultImage,
            v.bottomImage or defaultImage
        }
        
        local defaultType = v.faceType or yava.FACE_OPAQUE
        local typeTable = {
            v.frontType or defaultType,
            v.leftType or defaultType,
            v.topType or defaultType,
            v.backType or defaultType,
            v.rightType or defaultType,
            v.bottomType or defaultType
        }
        
        for _,tex in pairs(imageTable) do
            if not textures[tex] then
                textures[current_texture] = tex
                textures[tex] = current_texture
                current_texture=current_texture+1
            end
        end
        
        for i=1,6 do
            v[i*2+1] = imageTable[i]
            v[i*2+2] = typeTable[i]
        end
    end
    table.Merge( yava.blockTypes, blockArray )

    -- ATLAS SETUP
    -- 16384
    local atlas_texture = GetRenderTargetEx("__yava_atlas",16,1024,RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,0 --[[point sample?]], CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_RGBA8888)

    render.PushRenderTarget(atlas_texture)
    cam.Start2D()

    render.Clear(255,0,255,255)
    surface.SetDrawColor(255,255,255,255)
    surface.DrawRect(0, 0, 1, 1)
    for i=0,current_texture-1 do
        local name = textures[i]
        local source = Material("yava/"..name..".png")

        surface.SetMaterial(source)
        surface.DrawTexturedRectUV(0,16+i*32,16,8,0,.5,1,1)
        surface.DrawTexturedRect(0,24+i*32,16,16)
        surface.DrawTexturedRectUV(0,40+i*32,16,8,0,0,1,.5)
    end

    cam.End2D()
    render.PopRenderTarget()

    yava._atlas = CreateMaterial("__yava_atlas", "VertexLitGeneric")
    yava._atlas:SetTexture("$basetexture",atlas_texture)

    --yava._atlasLUT = textures
}
