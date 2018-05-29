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

    yava._buildAtlas()
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

    settings[1] = name
    settings[2] = block_id
    
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

yava.addBlockType("air",{faceType = yava.FACE_NONE})

function yava._buildAtlas() 
    print("build atlas now plz")
end