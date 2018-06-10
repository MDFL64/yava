AddCSLuaFile()

local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local floor = math.floor
local min = math.min

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

local function chunk_set_block(chunk_block_data,x,y,z,v)

    local pack_addr

    -- z 
    do
        local major_index = rshift(z,2) + 1
        local minor_index = band(z,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if band(val,0x800)==0 then
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

        if band(val,0x800)==0 then
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

local function chunk_get_row(chunk_block_data,row,y,z)

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
    for x_major_index=pack_addr,pack_addr+7 do
        local x_pack = chunk_block_data[x_major_index]
        for x_minor_index=0,3 do
            local x_val = get_packed_12(x_pack, x_minor_index)
            row[i] = x_val
            i = i + 1
        end
    end
end

local function chunk_set_row(chunk_block_data,y,z,v)
    
    local pack_addr

    -- z 
    do
        local major_index = rshift(z,2) + 1
        local minor_index = band(z,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if band(val,0x800)==0 then
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

        if band(val,0x800)==0 then
            if val == v then
                -- no change needed
                return
            end

            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, v)
        else
            error("Row already has blocks.")
        end
    end

end

local function chunk_set_slice(chunk_block_data,z,v)
    
    -- z 
    do
        local major_index = rshift(z,2) + 1
        local minor_index = band(z,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if band(val,0x800)==0 then
            if val == v then
                -- no change needed
                return
            end

            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, v)
        else
            error("Slice already has rows.")
        end
    end
end

if CLIENT then
    local mesh_data = {}
    local row    = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local row_ny = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local row_nz = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local ltx =         {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local ltx_start =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    function yava._chunkGenMesh(chunk_block_data,cx,cy,cz,nx_data,ny_data,nz_data)
        cx=cx*32
        cy=cy*32
        cz=cz*32

        local i = 1
        local quad_count = 0
        
        local tsize = 16/8192
        local tmult = 32/8192

        local blockFaceImages = yava._blockFaceImages
        local blockFaceTypes = yava._blockFaceTypes
        
        local function add_quad(x1,y1,z1,   x2,y2,z2,   x3,y3,z3,   x4,y4,z4,   xn,yn,zn,   t,tspan)
            t = (t - .75)*tmult

            mesh_data[i] =      xn
            mesh_data[i+1] =    yn
            mesh_data[i+2] =    zn

            mesh_data[i+3] =    x1+cx
            mesh_data[i+4] =    y1+cy
            mesh_data[i+5] =    z1+cz
            mesh_data[i+6] =    tspan
            mesh_data[i+7] =    t+tsize

            mesh_data[i+8] =    x2+cx
            mesh_data[i+9] =    y2+cy
            mesh_data[i+10] =   z2+cz
            mesh_data[i+11] =   0
            mesh_data[i+12] =   t+tsize

            mesh_data[i+13] =   x4+cx
            mesh_data[i+14] =   y4+cy
            mesh_data[i+15] =   z4+cz
            mesh_data[i+16] =   0
            mesh_data[i+17] =   t

            mesh_data[i+18] =   x3+cx
            mesh_data[i+19] =   y3+cy
            mesh_data[i+20] =   z3+cz
            mesh_data[i+21] =   tspan
            mesh_data[i+22] =   t

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
                    chunk_get_row(chunk_block_data,row_ny,min(y+1,31),z)
                end
                
                if z==31 and nz_data then
                    chunk_get_row(nz_data,row_nz,y,0)
                else
                    chunk_get_row(chunk_block_data,row_nz,y,min(z+1,31))
                end

                for x=0,31 do
                    local v = row[x+1]+1
                    local vnx
                    if x==31 and nx_data then
                        vnx = chunk_get_block(nx_data,0,y,z)+1
                    else
                        vnx = row[min(x+2,32)]+1
                    end
                    local vny = row_ny[x+1]+1
                    local vnz = row_nz[x+1]+1
                    
                    --local tx = 0
                    local tx = 0
                    local ty = 0
                    local tz = 0

                    if blockFaceImages[1][v] ~= 0 and blockFaceImages[4][vnx] == 0 then
                        tx = blockFaceImages[1][v]
                    elseif blockFaceImages[1][v] == 0 and blockFaceImages[4][vnx] ~= 0 then
                        tx = -blockFaceImages[4][vnx]
                    end

                    if blockFaceImages[2][v] ~= 0 and blockFaceImages[5][vny] == 0 then
                        ty = blockFaceImages[2][v]
                    elseif blockFaceImages[2][v] == 0 and blockFaceImages[5][vny] ~= 0 then
                        ty = -blockFaceImages[5][vny]
                    end

                    if blockFaceImages[3][v] ~= 0 and blockFaceImages[6][vnz] == 0 then
                        tz = blockFaceImages[3][v]
                    elseif blockFaceImages[3][v] == 0 and blockFaceImages[6][vnz] ~= 0 then
                        tz = -blockFaceImages[6][vnz]
                    end
                    
                    if tx != ltx[x+1] then
                        if ltx[x+1] > 0 then
                            add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0,    ltx[x+1],y-ltx_start[x+1])
                        elseif ltx[x+1] < 0 then
                            add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0,   -ltx[x+1],y-ltx_start[x+1])
                        end
                        ltx[x+1] = tx
                        ltx_start[x+1] = y
                    end

                    if ty != lty then
                        if lty > 0 then
                            add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0,      lty,x-lty_start)
                        elseif lty < 0 then
                            add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0,     -lty,x-lty_start)
                        end
                        lty = ty
                        lty_start = x
                    end

                    if tz != ltz then
                        if ltz > 0 then
                            add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1,      ltz,x-ltz_start)
                        elseif ltz < 0 then
                            add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1,     -ltz,x-ltz_start)
                        end
                        ltz = tz
                        ltz_start = x
                    end
                end
                
                local x = 32

                if 0 != lty then
                    if lty > 0 then
                        add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0,      lty,x-lty_start)
                    elseif lty < 0 then
                        add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0,     -lty,x-lty_start)
                    end
                end

                if 0 != ltz then
                    if ltz > 0 then
                        add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1,      ltz,x-ltz_start)
                    elseif ltz < 0 then
                        add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1,     -ltz,x-ltz_start)
                    end
                end
            end

            local y = 32

            for x = 0,31 do
                if 0 != ltx[x+1] then
                    if ltx[x+1] > 0 then
                        add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0,    ltx[x+1],y-ltx_start[x+1])
                    elseif ltx[x+1] < 0 then
                        add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0,   -ltx[x+1],y-ltx_start[x+1])
                    end
                end
            end
        end

        if quad_count>0 then
            my_mesh = Mesh()
            
            local index = 1
            local normal = Vector()
            local pos = Vector()
            mesh.Begin(my_mesh,MATERIAL_QUADS,quad_count)
            for i=1,quad_count do
                normal.x = mesh_data[index]
                normal.y = mesh_data[index+1]
                normal.z = mesh_data[index+2]
                index = index+3
                
                for j=1,4 do
                    pos.x = mesh_data[index]
                    pos.y = mesh_data[index+1]
                    pos.z = mesh_data[index+2]
                    local u = mesh_data[index+3]
                    local v = mesh_data[index+4]
                    index = index+5
                    
                    mesh.Position(pos)
                    mesh.Normal(normal)
                    mesh.TexCoord(0, u, v)        
                    mesh.AdvanceVertex()
                end
            end
            mesh.End()

            return my_mesh
        else
            return nil
        end
    end
end
    
do
    local mesh_data = {}
    local row    = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local row_ny = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local row_nz = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local ltx =         {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local ltx_start =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    local mesh_soup = {}
    function yava._chunkGenPhysics_dirtySoup(chunk_block_data,cx,cy,cz,nx_data,ny_data,nz_data)
        cx=cx*32
        cy=cy*32
        cz=cz*32

        local i = 1
        local quad_count = 0
        
        local tsize = 16/16384
        local tmult = 32/16384

        local blockSolidity = yava._blockSolidity
        
        local function add_quad(x1,y1,z1,   x2,y2,z2,   x3,y3,z3,   x4,y4,z4)

            mesh_data[i] =    x1+cx
            mesh_data[i+1] =    y1+cy
            mesh_data[i+2] =    z1+cz

            mesh_data[i+3] =    x2+cx
            mesh_data[i+4] =    y2+cy
            mesh_data[i+5] =   z2+cz

            mesh_data[i+6] =   x4+cx
            mesh_data[i+7] =   y4+cy
            mesh_data[i+8] =   z4+cz

            mesh_data[i+9] =   x3+cx
            mesh_data[i+10] =   y3+cy
            mesh_data[i+11] =   z3+cz

            i = i+12
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
                    chunk_get_row(chunk_block_data,row_ny,min(y+1,31),z)
                end
                
                if z==31 and nz_data then
                    chunk_get_row(nz_data,row_nz,y,0)
                else
                    chunk_get_row(chunk_block_data,row_nz,y,min(z+1,31))
                end

                for x=0,31 do
                    local v = row[x+1]+1
                    local vnx
                    if x==31 and nx_data then
                        vnx = chunk_get_block(nx_data,0,y,z)+1
                    else
                        vnx = row[min(x+2,32)]+1
                    end
                    local vny = row_ny[x+1]+1
                    local vnz = row_nz[x+1]+1
                    
                    --local tx = 0
                    local tx = 0
                    local ty = 0
                    local tz = 0

                    if blockSolidity[v] and not blockSolidity[vnx] then
                        tx = 1
                    elseif not blockSolidity[v] and blockSolidity[vnx] then
                        tx = -1
                    end

                    if blockSolidity[v] and not blockSolidity[vny] then
                        ty = 1
                    elseif not blockSolidity[v] and blockSolidity[vny] then
                        ty = -1
                    end

                    if blockSolidity[v] and not blockSolidity[vnz] then
                        tz = 1
                    elseif not blockSolidity[v] and blockSolidity[vnz] then
                        tz = -1
                    end
                    
                    if tx != ltx[x+1] then
                        if ltx[x+1] > 0 then
                            add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0,    ltx[x+1],y-ltx_start[x+1])
                        elseif ltx[x+1] < 0 then
                            add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0,   -ltx[x+1],y-ltx_start[x+1])
                        end
                        ltx[x+1] = tx
                        ltx_start[x+1] = y
                    end

                    if ty != lty then
                        if lty > 0 then
                            add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0,      lty,x-lty_start)
                        elseif lty < 0 then
                            add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0,     -lty,x-lty_start)
                        end
                        lty = ty
                        lty_start = x
                    end

                    if tz != ltz then
                        if ltz > 0 then
                            add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1,      ltz,x-ltz_start)
                        elseif ltz < 0 then
                            add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1,     -ltz,x-ltz_start)
                        end
                        ltz = tz
                        ltz_start = x
                    end
                end
                
                local x = 32

                if 0 != lty then
                    if lty > 0 then
                        add_quad(   lty_start,y+1,z,        x,y+1,z,  lty_start,y+1,z+1,      x,y+1,z+1,    0,1,0,      lty,x-lty_start)
                    elseif lty < 0 then
                        add_quad(   x,y+1,z,      lty_start,y+1,z,    x,y+1,z+1,    lty_start,y+1,z+1,      0,-1,0,     -lty,x-lty_start)
                    end
                end

                if 0 != ltz then
                    if ltz > 0 then
                        add_quad(   x,y,z+1,      ltz_start,y,z+1,    x,y+1,z+1,    ltz_start,y+1,z+1,      0,0,1,      ltz,x-ltz_start)
                    elseif ltz < 0 then
                        add_quad(   x,y+1,z+1,    ltz_start,y+1,z+1,  x,y,z+1,      ltz_start,y,z+1,        0,0,-1,     -ltz,x-ltz_start)
                    end
                end
            end

            local y = 32

            for x = 0,31 do
                if 0 != ltx[x+1] then
                    if ltx[x+1] > 0 then
                        add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0,    ltx[x+1],y-ltx_start[x+1])
                    elseif ltx[x+1] < 0 then
                        add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0,   -ltx[x+1],y-ltx_start[x+1])
                    end
                end
            end
        end

        if quad_count>0 then
            --my_mesh = Mesh()
            
            local index = 1
            local soup_index = 1
            local positions = {Vector(),Vector(),Vector(),Vector()}
            local scale = yava._scale
            local offset = yava._offset
            local function add_soup_vert(pos)
                if mesh_soup[soup_index] == nil then
                    mesh_soup[soup_index] = {pos=Vector()}--,normal=Vector()}
                end
                local vert = mesh_soup[soup_index]
                vert.pos.x = pos.x
                vert.pos.y = pos.y
                vert.pos.z = pos.z

                --vert.normal.x = normal.x
                --vert.normal.y = normal.y
                --vert.normal.z = normal.z

                soup_index = soup_index+1
            end
            for i=1,quad_count do
                
                for j=1,4 do
                    positions[j].x = mesh_data[index]
                    positions[j].y = mesh_data[index+1]
                    positions[j].z = mesh_data[index+2]
                    positions[j]:Mul( scale )
                    positions[j]:Add( offset )
                    index = index+3
                end

                add_soup_vert(positions[1])
                add_soup_vert(positions[2])
                add_soup_vert(positions[3])

                add_soup_vert(positions[1])
                add_soup_vert(positions[3])
                add_soup_vert(positions[4])
            end
            mesh_soup[soup_index] = nil

            return mesh_soup
        else
            return nil
        end
    end
end

-- currently suboptimal!
function yava._chunkProvideChunk(chunk,consumer)
    local block_data = chunk.block_data

    local blockType, blockCount
    for z=0,31 do
        for y=0,31 do
            for x=0,31 do
                local block = chunk_get_block(block_data,x,y,z)
                if blockType == nil  then
                    blockType = block
                    blockCount = 1
                elseif blockType == block then
                    blockCount = blockCount + 1
                else
                    consumer(blockType,blockCount)
                    blockType = block
                    blockCount = 1
                end
            end
        end
    end
    consumer(blockType,blockCount)
end

function yava._chunkProvideGenerate(cx,cy,cz,consumer)
    local generator = yava._generator
    local blockTypes = yava._blockTypes

    local blockType, blockCount
    for z=0,31 do
        for y=0,31 do
            for x=0,31 do
                local block = generator(cx*32+x, cy*32+y, cz*32+z)
                if blockType == nil  then
                    blockType = block
                    blockCount = 1
                elseif blockType == block then
                    blockCount = blockCount + 1
                else
                    consumer(blockTypes[blockType],blockCount)
                    blockType = block
                    blockCount = 1
                end
            end
        end
    end
    consumer(blockTypes[blockType],blockCount)
end

function yava._chunkConsumerConstruct(cx,cy,cz)
    local base_block = "void"
    local base_data = rep_packed_12(yava._blockTypes[base_block])
    local block_data = {base_data,base_data,base_data,base_data,base_data,base_data,base_data,base_data}

    local x,y,z = 0,0,0
    local function consumer(type,count)
        --print("===>",type,count)
        while z<32 do
            
            if y==0 and x==0 and count>=1024 then
                -- add whole slice
                chunk_set_slice(block_data,z,type)
                
                count = count-1024
            else
                while y<32 do
                    if x==0 and count>=32 then
                        -- add whole row
                        chunk_set_row(block_data,y,z,type)
    
                        count = count-32
                    else
                        -- add individual blocks
                        while x<32 do
                            if count==0 then return end
    
                            chunk_set_block(block_data,x,y,z,type)
    
                            count=count-1
                            x=x+1
                        end
                    end
    
                    x=0
                    y=y+1
                end
            end

            y=0
            z=z+1
        end
    end
    return consumer, {x=cx,y=cy,z=cz,block_data=block_data}
end

local function writeVarWidth(n)
    repeat
        local bits = band(n,0x7F)
        n = rshift(n,7)
        if n~=0 then bits=bits+0x80 end
        net.WriteUInt(bits, 8)
    until n==0
end

local function readVarWidth()
    local n=0
    local s=0
    repeat
        local bits = net.ReadUInt(8)
        n = bor(n,lshift(band(bits,0x7F),s))
        s=s+7
    until band(bits,0x80)==0
    return n
end

function yava._chunkConsumerNetwork()
    local function consumer(type,count)
        type = type*2
        if count == 1 then
            writeVarWidth(type)
        else
            writeVarWidth(type+1)
            writeVarWidth(count)
        end
    end
    local function finalizer()
        writeVarWidth(0xFFFF)
    end
    return consumer, finalizer
end

function yava._chunkProvideNetwork(consumer)
    local failsafe = 0
    while failsafe<1000000 do
        local type = readVarWidth()
        --print(string.format("%x",type))
        if type==0xFFFF then break end
        if type%2==1 then
            consumer(rshift(type,1),readVarWidth())
        else
            consumer(rshift(type,1),1)
        end
        failsafe=failsafe+1
    end
    if failsafe==1000000 then error("rer") end
end

yava._chunkSetBlock = chunk_set_block
yava._chunkGetBlock = chunk_get_block

