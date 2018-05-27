
if SERVER then return end
include("yava_lib/jit_watch.lua")

local int = bit.tobit
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local floor = math.floor

-- store 4 12 bit numbers
local function get_packed_12(n,i)
    return band(floor(n/4096^i),0xFFF)
end

local function edit_packed_12(n,i,old,new)
    return n + (new - old)*4096^i
end

local function rep_packed_12(v)
    return v
         + v*4096
         + v*4096^2
         + v*4096^3
end

local function make_packed_12(a,b,c,d)
    return a
         + b*4096
         + c*4096^2
         + d*4096^3
end

local function chunk_set_block(chunk_block_data,x,y,z,v,dbg)

    local pack_addr

    -- z 
    do
        local major_index = rshift(z,2) + 1
        local minor_index = band(z,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if bit.band(val,0x800)==0 then
            if val == v then
                -- no change needed
                return
            end

            local base_addr = #chunk_block_data
            pack_addr = base_addr+1
            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, bor(rshift(base_addr,3),2048))
            
            local tmp = rep_packed_12(val)
            for addr = pack_addr,pack_addr+7 do
                chunk_block_data[addr] = tmp
            end
        else
            pack_addr = band(val,0x7FF)*8+1
        end
    end

    -- y
    do
        local major_index = rshift(y,2) + pack_addr
        local minor_index = band(y,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if bit.band(val,0x800)==0 then
            if val == v then
                -- no change needed
                return
            end

            local base_addr = #chunk_block_data
            pack_addr = base_addr+1
            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, bor(rshift(base_addr,3),2048))
            
            local tmp = rep_packed_12(val)
            for addr = pack_addr,pack_addr+7 do
                chunk_block_data[addr] = tmp
            end
        else
            pack_addr = band(val,0x7FF)*8+1
        end
    end

    -- x
    do
        local major_index = rshift(x,2) + pack_addr
        local minor_index = band(x,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if val == v then
            -- no change needed
            return
        end

        chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, v)
    end
end

local function chunk_get_block(chunk_block_data,x,y,z)
    
    -- z
    local val = get_packed_12(chunk_block_data[rshift(z,2)+1], band(z,3))

    if val < 2048 then
        return val
    end

    local pack_addr = band(val,0x7FF)*8+1

    -- y
    val = get_packed_12(chunk_block_data[rshift(y,2)+pack_addr], band(y,3))

    if val < 2048 then
        return val
    end
    
    pack_addr = band(val,0x7FF)*8+1

    -- x
    return get_packed_12(chunk_block_data[rshift(x,2)+pack_addr], band(x,3))
end

-- rewrite?
local function chunk_get_row(chunk_block_data,row,y,z,dbg)
    
    --[[if dbg then
        print("===>>>>>>>>>===")
        for x=0,31 do
            print(".",chunk_get_block(chunk_block_data,x,y,z))
        end
    end]]

    -- z
    local val = get_packed_12(chunk_block_data[rshift(z,2)+1], band(z,3))

    if val < 2048 then
        for i=1,32 do
            row[i] = val
        end
        return
    end
    
    local pack_addr = band(val,0x7FF)*8+1

    -- y
    local val = get_packed_12(chunk_block_data[rshift(y,2)+pack_addr], band(y,3))

    if val < 2048 then
        for i=1,32 do
            row[i] = val
        end
        return
    end
    
    local pack_addr = band(val,0x7FF)*8+1
    
    -- x
    local i = 1
    --if dbg then print(">>>>>>>>>",x_pack_addr) end
    for x_major_index=pack_addr,pack_addr+7 do
        local x_pack = chunk_block_data[x_major_index]
        --if dbg then print(">",x_pack) end
        for x_minor_index=0,3 do
            local x_val = get_packed_12(x_pack, x_minor_index)
            row[i] = x_val
            i = i + 1
        end
    end
end

local mesh_data = {}
local row    = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_ny = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_nz = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local ltx =         {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local ltx_start =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local function chunk_gen_mesh_striped_rowfetch_stitch(chunk_block_data,cx,cy,cz,nx_data,ny_data,nz_data)
    cx=cx*32
    cy=cy*32
    cz=cz*32

    local i = 1
    local quad_count = 0
    local function add_quad(x1,y1,z1,   x2,y2,z2,   x3,y3,z3,   x4,y4,z4,   xn,yn,zn)
        mesh_data[i] =      xn
        mesh_data[i+1] =    yn
        mesh_data[i+2] =    zn

        mesh_data[i+3] =    x1+cx
        mesh_data[i+4] =    y1+cy
        mesh_data[i+5] =    z1+cz
        mesh_data[i+6] =    0
        mesh_data[i+7] =    .5

        mesh_data[i+8] =    x2+cx
        mesh_data[i+9] =    y2+cy
        mesh_data[i+10] =   z2+cz
        mesh_data[i+11] =   .5
        mesh_data[i+12] =   .5

        mesh_data[i+13] =   x4+cx
        mesh_data[i+14] =   y4+cy
        mesh_data[i+15] =   z4+cz
        mesh_data[i+16] =   .5
        mesh_data[i+17] =   0

        mesh_data[i+18] =   x3+cx
        mesh_data[i+19] =   y3+cy
        mesh_data[i+20] =   z3+cz
        mesh_data[i+21] =   0
        mesh_data[i+22] =   0

        i = i+23
        quad_count = quad_count+1
    end

    for z=0,31 do
        for i=1,32 do
            ltx[i] = 0
            ltx_start[i] = 0
        end
        
        chunk_get_row(chunk_block_data,row_ny,0,z)

        for y=0,31 do
            local lty = 0
            local ltz = 0

            local lty_start = 0
            local ltz_start = 0
            
            -- swap row/ny
            local tmp = row
            row = row_ny
            row_ny = tmp

            if y==31 and ny_data then
                chunk_get_row(ny_data,row_ny,0,z)
            else
                chunk_get_row(chunk_block_data,row_ny,math.min(y+1,31),z)
            end
            
            if z==31 and nz_data then
                chunk_get_row(nz_data,row_nz,y,0)
            else
                chunk_get_row(chunk_block_data,row_nz,y,math.min(z+1,31))
            end

            for x=0,31 do
                local v = row[x+1]
                local vnx
                if x==31 and nx_data then
                    vnx = chunk_get_block(nx_data,0,y,z)
                else
                    vnx = row[math.min(x+2,32)]
                end
                local vny = row_ny[x+1]
                local vnz = row_nz[x+1]
                
                --local tx = 0
                local tx = 0
                local ty = 0
                local tz = 0

                if v != 0 then
                    if vnx == 0 then
                        tx = 1
                    end

                    if vny == 0 then
                        ty = 1
                    end
                    
                    if vnz == 0 then
                        tz = 1
                    end
                else
                    if vnx != 0 then
                        tx = -1
                    end

                    if vny != 0 then
                        ty = -1
                    end

                    if vnz != 0 then
                        tz = -1
                    end
                end
                
                if tx != ltx[x+1] then
                    if ltx[x+1] > 0 then
                        add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0)
                    elseif ltx[x+1] < 0 then
                        add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0)
                    end
                    ltx[x+1] = tx
                    ltx_start[x+1] = y
                end

                if ty != lty then
                    if lty > 0 then
                        add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0)
                    elseif lty < 0 then
                        add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0)
                    end
                    lty = ty
                    lty_start = x
                end

                if tz != ltz then
                    if ltz > 0 then
                        add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1)
                    elseif ltz < 0 then
                        add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1)
                    end
                    ltz = tz
                    ltz_start = x
                end
            end
            
            local x = 32

            if 0 != lty then
                if lty > 0 then
                    add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0)
                elseif lty < 0 then
                    add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0)
                end
            end

            if 0 != ltz then
                if ltz > 0 then
                    add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1)
                elseif ltz < 0 then
                    add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1)
                end
            end
        end

        local y = 32

        for x = 0,31 do
            if 0 != ltx[x+1] then
                if ltx[x+1] > 0 then
                    add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0)
                elseif ltx[x+1] < 0 then
                    add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0)
                end
            end
        end
    end

    return mesh_data, quad_count
end

local chunks = {}

local function setup()
    local t1 = SysTime()

    for cz=0,3 do
        for cy=0,3 do
            for cx=0,3 do
                local key = cx..":"..cy..":"..cz
                
                local base_block = cz <= 1 and 2 or 0
                local base_data = rep_packed_12(base_block)
                local block_data = {base_data,base_data,base_data,base_data,base_data,base_data,base_data,base_data}

                --JIT_WATCH_START()
                for z=0,31 do
                    for y=0,31 do
                        for x=0,31 do
                            --local c = math.random()>.9
                            local rx = cx*32+x
                            local ry = cy*32+y
                            local rz = cz*32+z

                            local c = rz < math.sin(rx/8)*8 + math.cos(ry/8)*8 + 64
                            chunk_set_block(block_data,x,y,z,c and 2 or 0,cx==0 and cy==0 and cz==2 and y==0 and z==0)
                        end
                    end
                end
                --JIT_WATCH_PAUSE()

                chunks[key] = {x=cx,y=cy,z=cz,block_data=block_data}
                --print(">>",#block_data)
            end
        end
    end
    local t2 = SysTime()
    local ts = 0
    local tn = 0

    for _,chunk in pairs(chunks) do
        --JIT_WATCH_START()
        local cnx = chunks[(chunk.x+1)..":"..chunk.y..":"..chunk.z]
        local cny = chunks[chunk.x..":"..(chunk.y+1)..":"..chunk.z]
        local cnz = chunks[chunk.x..":"..chunk.y..":"..(chunk.z+1)]
        local data,quad_count = chunk_gen_mesh_striped_rowfetch_stitch(chunk.block_data,chunk.x,chunk.y,chunk.z,cnx and cnx.block_data,cny and cny.block_data,cnz and cnz.block_data)
        --JIT_WATCH_PAUSE()
        
        local my_mesh = nil
        if quad_count>0 then
            local ta = SysTime()
            my_mesh = Mesh()
            
            local index = 1
            local normal = Vector()
            local pos = Vector()
            mesh.Begin(my_mesh,MATERIAL_QUADS,quad_count)
            for i=1,quad_count do
                normal.x = data[index]
                normal.y = data[index+1]
                normal.z = data[index+2]
                index = index+3
                
                for j=1,4 do
                    pos.x = data[index]
                    pos.y = data[index+1]
                    pos.z = data[index+2]
                    local u = data[index+3]
                    local v = data[index+4]
                    index = index+5
                    
                    mesh.Position(pos)
                    mesh.Normal(normal)
                    mesh.TexCoord(0, u, v)        
                    mesh.AdvanceVertex()
                end
            end
            mesh.End()
            
            local tb = SysTime()
            local t = tb - ta
            --print(string.format("%.10f",t/(count/6)))
        else
            --print("EMPTY")
        end
        
        chunk.mesh = my_mesh
    end
    
    local t3 = SysTime()
    
    return t2-t1, t3-t2
end

if true then
    local as = {}
    local bs = {}
    for i=1,21 do
        as[i],bs[i] = setup()
    end
    table.sort(as)
    table.sort(bs)
    print("WORLD GEN")
    PrintTable(as)
    print("MESH GEN")
    PrintTable(bs)
    print(bs[1],bs[7],bs[14],bs[21])
else
    print(">>>>>>>>>>>>>>>")
    setup()
end

--JIT_WATCH_PRINT()

local memory_sum = 0
for _,chunk in pairs(chunks) do
    memory_sum = memory_sum + #chunk.block_data
end
print("Memory usage:",(memory_sum*8).." bytes")
print("Memory/block:",string.format("%.2f",(memory_sum*8)/(128*128*128)).." bytes")

local material_base = Material("atlas-ng.png")
local material = CreateMaterial("yava-atlas", "VertexLitGeneric")
material:SetTexture("$basetexture",material_base:GetTexture("$basetexture"))

local scale = 40

local matrix = Matrix()
matrix:Translate( Vector(-4000,-600,0) )
matrix:Scale( Vector( 1, 1, 1 ) * scale )

hook.Add("PostDrawOpaqueRenderables","pdoraawa",function()
    render.SetMaterial( material )

    render.SuppressEngineLighting(true) 
    render.SetModelLighting(BOX_TOP,    1,1,1 )
    render.SetModelLighting(BOX_FRONT,  .8,.8,.8 )
    render.SetModelLighting(BOX_RIGHT,  .6,.6,.6 )
    render.SetModelLighting(BOX_LEFT,   .5,.5,.5 )
    render.SetModelLighting(BOX_BACK,   .3,.3,.3 )
    render.SetModelLighting(BOX_BOTTOM, .1,.1,.1 )
    
    cam.PushModelMatrix( matrix )
    for _,chunk in pairs(chunks) do
        if chunk.mesh then
            chunk.mesh:Draw()
        end
    end
    cam.PopModelMatrix()
end)
