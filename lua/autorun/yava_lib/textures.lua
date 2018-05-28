
function yava._setup_atlas() {
    local blockTypes = yava.config.blockTypes

    local textures = {}
    local texture_count=0
    for k,v in pairs(blockTypes) do
        local default = v.texture or k
        local tab = {
            v.topTexture or default,
            v.bottomTexture or default,
            v.frontTexture or default,
            v.backTexture or default,
            v.leftTexture or default,
            v.rightTexture or default
        }

        for _,tex in pairs(tab) do
            if not textures[tex] then
                textures[texture_count] = tex
                textures[tex] = texture_count
                texture_count=texture_count+1
            end
        end
    end
    -- 16384
    local atlas_texture = GetRenderTargetEx("__yava_atlas",16,1024,RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,0 --[[point sample?]], CREATERENDERTARGETFLAGS_AUTOMIPMAP, IMAGE_FORMAT_RGBA8888)

    render.PushRenderTarget(atlas_texture)
    cam.Start2D()

    render.Clear(255,0,255,255)
    surface.SetDrawColor(255,255,255,255)
    surface.DrawRect(0, 0, 1, 1)
    for i=0,texture_count-1 do
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

    yava._atlas_lut = textures
}