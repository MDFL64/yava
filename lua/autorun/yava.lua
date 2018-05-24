
if SERVER then return end
include("yava_lib/jit_watch.lua")

local power_lut = {1,4096,4096^2,4096^3}
-- power_lut[i+1]

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

--[[local dims = {0,0,0}
local function chunk_set_block(chunk_block_data,x,y,z,v)
    dims[1] = z
    dims[2] = y
    dims[3] = x
    
    local pack_addr = 1
    --local data_len = #chunk_block_data
    for i=1,3 do
        local major_index = bit.rshift(dims[i],2) + pack_addr
        local minor_index = bit.band(dims[i],3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if val == v then
            -- no change needed
            return
        end

        if i == 3 then
            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, v)
        elseif val < 2048 then
            local base_addr = #chunk_block_data
            pack_addr = base_addr+1
            chunk_block_data[major_index] = edit_packed_12(pack, minor_index, val, base_addr/8 + 2048)
            
            local tmp = rep_packed_12(val)
            for addr = pack_addr,pack_addr+7 do
                chunk_block_data[addr] = tmp
            end
        else
            pack_addr = (val - 2048)*8+1
        end
    end
--[[
    local y_major_index = bit.rshift(y,2) + y_pack_addr
    local y_minor_index = bit.band(y,3)
    local y_pack = chunk_block_data[y_major_index]
    local y_val = get_packed_12(y_pack, y_minor_index)

    local x_pack_addr
    if y_val < 2048 then
        -- not present
        if y_val == v then
            -- no change needed
            return
        end

        local base_addr = #chunk_block_data
        x_pack_addr = base_addr+1
        chunk_block_data[y_major_index] = edit_packed_12(y_pack, y_minor_index, y_val, base_addr/8 + 2048)
        
        local tmp = rep_packed_12(y_val)
        chunk_block_data[x_pack_addr]   = tmp
        chunk_block_data[x_pack_addr+1]   = tmp    
        chunk_block_data[x_pack_addr+2] = tmp
        chunk_block_data[x_pack_addr+3] = tmp
        chunk_block_data[x_pack_addr+4] = tmp
        chunk_block_data[x_pack_addr+5] = tmp
        chunk_block_data[x_pack_addr+6] = tmp
        chunk_block_data[x_pack_addr+7] = tmp
    else
        x_pack_addr = (y_val - 2048)*8+1
    end

    local x_major_index = bit.rshift(x,2) + x_pack_addr
    local x_minor_index = bit.band(x,3)
    local x_pack = chunk_block_data[x_major_index]
    local x_val = get_packed_12(x_pack, x_minor_index)
    
    if x_val == v then
        -- no change needed
        return
    end

    chunk_block_data[x_major_index] = edit_packed_12(x_pack, x_minor_index, x_val, v)]
end]]

local function chunk_set_block(chunk_block_data,x,y,z,v)

    local pack_addr

    -- z
    do
        local major_index = bit.rshift(z,2) + 1
        local minor_index = bit.band(z,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if band(val,0x7FF) == v then
            -- no change needed
            return
        end

        if val < 2048 then
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
        local major_index = bit.rshift(y,2) + pack_addr
        local minor_index = bit.band(y,3)
        local pack = chunk_block_data[major_index]
        local val = get_packed_12(pack, minor_index)

        if band(val,0x7FF) == v then
            -- no change needed
            return
        end

        if val < 2048 then
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
        local major_index = bit.rshift(x,2) + pack_addr
        local minor_index = bit.band(x,3)
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

    local pack_addr = (val - 2048)*8+1

    -- y
    val = get_packed_12(chunk_block_data[rshift(y,2)+pack_addr], band(y,3))

    if val < 2048 then
        return val
    end
    
    pack_addr = (val - 2048)*8+1

    -- x
    return get_packed_12(chunk_block_data[rshift(x,2)+pack_addr], band(x,3))
end

local function chunk_get_row(chunk_block_data,row,y,z)
    local z_major_index = bit.rshift(z,2)+1
    local z_minor_index = bit.band(z,3)
    local z_pack = chunk_block_data[z_major_index]
    local z_val = get_packed_12(z_pack, z_minor_index)

    if z_val < 2048 then
        for i=1,32 do
            row[i] = z_val
        end
        return
    end
    
    local y_pack_addr = (z_val - 2048)*8+1
    
    local y_major_index = bit.rshift(y,2) + y_pack_addr
    local y_minor_index = bit.band(y,3)
    local y_pack = chunk_block_data[y_major_index]
    local y_val = get_packed_12(y_pack, y_minor_index)

    if y_val < 2048 then
        for i=1,32 do
            row[i] = y_val
        end
        return
    end
    
    local x_pack_addr = (y_val - 2048)*8+1

    local i = 1
    for x_major_index=x_pack_addr,x_pack_addr+7 do
        local x_pack = chunk_block_data[x_major_index]
        for x_minor_index=0,3 do
            local x_val = get_packed_12(x_pack, x_minor_index)
            row[i] = x_val
            i = i + 1
        end
    end
end

local mesh_data = {}
local function chunk_gen_mesh_striped_all(chunk_block_data,cx,cy,cz)
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
        local ltx =         {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
        local ltx_start =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
        for y=0,31 do
            local lty = 0
            local ltz = 0

            local lty_start = 0
            local ltz_start = 0

            for x=0,31 do
                local v = chunk_get_block(chunk_block_data,x,y,z)

                local vnx = chunk_get_block(chunk_block_data,math.min(x+1,31),y,z)
                local vny = chunk_get_block(chunk_block_data,x,math.min(y+1,31),z)
                local vnz = chunk_get_block(chunk_block_data,x,y,math.min(z+1,31))
                
                --local tx = 0
                local tx = 0
                local ty = 0
                local tz = 0

                if v != 0 then
                    if x < 31 and vnx == 0 then
                        --add_quad(   x+1,y+1,z,      x+1,y,z,    x+1,y+1,z+1,    x+1,y,z+1,      1,0,0)
                        tx = 1
                    end

                    if y < 31 and vny == 0 then
                        ty = 1
                    end
                    
                    if z < 31 and vnz == 0 then
                        tz = 1
                    end
                else
                    if x < 31 and vnx != 0 then
                        --add_quad(   x+1,y,z,        x+1,y+1,z,  x+1,y,z+1,      x+1,y+1,z+1,    -1,0,0)
                        tx = -1
                    end

                    if y < 31 and vny != 0 then
                        ty = -1
                    end

                    if z < 31 and vnz != 0 then
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

local mesh_data = {}
local function chunk_gen_mesh_striped_yz(chunk_block_data,cx,cy,cz)
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
        for y=0,31 do
            local lty = 0
            local ltz = 0

            local lty_start = 0
            local ltz_start = 0

            for x=0,31 do
                local v = chunk_get_block(chunk_block_data,x,y,z)
                local vnx = chunk_get_block(chunk_block_data,math.min(x+1,31),y,z) --or 0
                local vny = chunk_get_block(chunk_block_data,x,math.min(y+1,31),z) --or 0
                local vnz = chunk_get_block(chunk_block_data,x,y,math.min(z+1,31)) --or 0
                
                --local tx = 0
                local ty = 0
                local tz = 0

                if v != 0 then
                    if vnx == 0 then
                        add_quad(   x+1,y+1,z,      x+1,y,z,    x+1,y+1,z+1,    x+1,y,z+1,      1,0,0)
                    end

                    if vny == 0 then
                        ty = 1
                    end
                    
                    if vnz == 0 then
                        tz = 1
                    end
                else
                    if vnx != 0 then
                        add_quad(   x+1,y,z,        x+1,y+1,z,  x+1,y,z+1,      x+1,y+1,z+1,    -1,0,0)
                    end

                    if vny != 0 then
                        ty = -1
                    end

                    if vnz != 0 then
                        tz = -1
                    end
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
    end

    return mesh_data, quad_count
end

--local _cx = 0
--local _cy = 0
--local _cz = 0
local mesh_data = {}


local function chunk_gen_mesh_dumb(chunk_block_data,cx,cy,cz)
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
        for y=0,31 do
            for x=0,31 do
                local v = chunk_get_block(chunk_block_data,x,y,z)
                local vnx = chunk_get_block(chunk_block_data,math.min(x+1,31),y,z)
                local vny = chunk_get_block(chunk_block_data,x,math.min(y+1,31),z)
                local vnz = chunk_get_block(chunk_block_data,x,y,math.min(z+1,31))

                if v != 0 then
                    if vnx == 0 then
                        add_quad(   x+1,y+1,z,      x+1,y,z,    x+1,y+1,z+1,    x+1,y,z+1,      1,0,0)
                    end

                    if vny == 0 then
                        add_quad(   x,y+1,z,        x+1,y+1,z,  x,y+1,z+1,      x+1,y+1,z+1,    0,1,0)
                    end
                    
                    if vnz == 0 then
                        add_quad(   x+1,y,z+1,      x,y,z+1,    x+1,y+1,z+1,    x,y+1,z+1,      0,0,1)
                    end
                else
                    if vnx != 0 then
                        add_quad(   x+1,y,z,        x+1,y+1,z,  x+1,y,z+1,      x+1,y+1,z+1,    -1,0,0)
                    end

                    if vny != 0 then
                        add_quad(   x+1,y+1,z,      x,y+1,z,    x+1,y+1,z+1,    x,y+1,z+1,      0,-1,0)
                    end

                    if vnz != 0 then
                        add_quad(   x+1,y+1,z+1,    x,y+1,z+1,  x+1,y,z+1,      x,y,z+1,        0,0,-1)
                    end
                end
            end
        end
    end

    return mesh_data, quad_count
end

local mesh_data = {}
local function chunk_gen_mesh_greedy(chunk_block_data,cx,cy,cz)
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

    local completed_bitmap = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    
    local function get_complete(x,y)
        return bit.band(bit.rshift(completed_bitmap[y+1], x),1) == 1
    end

    local function set_complete(x,y)
        completed_bitmap[y+1] = bit.bor(completed_bitmap[y+1], bit.lshift(1, x))
    end

    do --z
        local function get_signed_type(x,y,z)
            --print(chunk_block_data,x,y,z)
            local v = chunk_get_block(chunk_block_data,x,y,z)
            local vn = chunk_get_block(chunk_block_data,x,y,math.min(z+1,31))

            if v != 0 and vn == 0 then
                return 1
            elseif v == 0 and vn and vn != 0 then
                return -1
            end
            return 0
        end

        local function add_face(x,y,z,w,h,t)
            add_quad(   x+w,y,z+1,      x,y,z+1,    x+w,y+h,z+1,    x,y+h,z+1,      0,0,1)
        end

        for z=0,31 do
            for i=1,32 do
                completed_bitmap[i]=0
            end

            for y=0,31 do
                for x=0,31 do
                    if not get_complete(x,y) then
                        local t = get_signed_type(x,y,z)

                        if t != 0 then
                            local ix = x+1
                            while ix<32 do
                                if get_complete(ix,y) or get_signed_type(ix,y,z) != t then
                                    break
                                end
                                set_complete(ix,y)
                                ix = ix + 1
                            end

                            local iy = y+1
                            while iy<32 do
                                for iix = x,ix-1 do
                                    if get_complete(iix,iy) or get_signed_type(iix,iy,z) != t then
                                        goto bail
                                    end
                                end
                                for iix = x,ix-1 do
                                    set_complete(iix,iy)
                                end
                                iy = iy + 1
                            end
                            ::bail::

                            add_face(x,y,z,ix-x,iy-y,t)
                        end

                        set_complete(x,y)
                    end
                end
            end
        end
    end

    return mesh_data, quad_count
end

local mesh_data = {}
local row    = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_ny = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_nz = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local ltx =         {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local ltx_start =   {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local function chunk_gen_mesh_striped_rowfetch(chunk_block_data,cx,cy,cz)
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

    --[[for z=0,31 do
        chunk_get_row(chunk_block_data,rows[z+1],0,z)
    end]]

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
            local tmp = row_ny
            row_ny = row
            row = tmp

            chunk_get_row(chunk_block_data,row_ny,math.min(y+1,31),z)
            chunk_get_row(chunk_block_data,row_nz,y,math.min(z+1,31))

            --local row = rows[y+1]
            --local row_ny = rows[y+2]
            --local row_nz = row_swap
            --if z<31 then
            --    chunk_get_row(chunk_block_data,row_nz,y,z+1)
            --end
            
            --local tmp = row_swap
            --row_swap = rows[y+1]
            --rows[y+1] = tmp

            for x=0,31 do
                local v = row[x+1]
                local vnx = row[math.min(x+2,31)]
                local vny = row_ny[x+1]
                local vnz = row_nz[x+1]
                
                --local tx = 0
                local tx = 0
                local ty = 0
                local tz = 0

                if v != 0 then
                    if vnx == 0 then
                        --add_quad(   x+1,y+1,z,      x+1,y,z,    x+1,y+1,z+1,    x+1,y,z+1,      1,0,0)
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
                        --add_quad(   x+1,y,z,        x+1,y+1,z,  x+1,y,z+1,      x+1,y+1,z+1,    -1,0,0)
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

local mesh_data = {}
local row    = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_ny = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local row_nz = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local function chunk_gen_mesh_striped_yz_rowfetch(chunk_block_data,cx,cy,cz)
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

    --[[for z=0,31 do
        chunk_get_row(chunk_block_data,rows[z+1],0,z)
    end]]

    for z=0,31 do
        chunk_get_row(chunk_block_data,row_ny,0,z)

        for y=0,31 do
            local lty = 0
            local ltz = 0

            local lty_start = 0
            local ltz_start = 0
            
            -- swap row/ny
            local tmp = row_ny
            row_ny = row
            row = tmp

            chunk_get_row(chunk_block_data,row_ny,math.min(y+1,31),z)
            chunk_get_row(chunk_block_data,row_nz,y,math.min(z+1,31))

            --local row = rows[y+1]
            --local row_ny = rows[y+2]
            --local row_nz = row_swap
            --if z<31 then
            --    chunk_get_row(chunk_block_data,row_nz,y,z+1)
            --end
            
            --local tmp = row_swap
            --row_swap = rows[y+1]
            --rows[y+1] = tmp

            for x=0,31 do
                local v = row[x+1]
                local vnx = row[math.min(x+2,31)]
                local vny = row_ny[x+1]
                local vnz = row_nz[x+1]
                
                local ty = 0
                local tz = 0

                if v != 0 then
                    if vnx == 0 then
                        add_quad(   x+1,y+1,z,      x+1,y,z,    x+1,y+1,z+1,    x+1,y,z+1,      1,0,0)
                        --tx = 1
                    end

                    if vny == 0 then
                        ty = 1
                    end
                    
                    if vnz == 0 then
                        tz = 1
                    end
                else
                    if vnx != 0 then
                        add_quad(   x+1,y,z,        x+1,y+1,z,  x+1,y,z+1,      x+1,y+1,z+1,    -1,0,0)
                        --tx = -1
                    end

                    if vny != 0 then
                        ty = -1
                    end

                    if vnz != 0 then
                        tz = -1
                    end
                end
                
                --[[if tx != ltx[x+1] then
                    if ltx[x+1] > 0 then
                        add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0)
                    elseif ltx[x+1] < 0 then
                        add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0)
                    end
                    ltx[x+1] = tx
                    ltx_start[x+1] = y
                end]]

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

        --[[local y = 32

        for x = 0,31 do
            if 0 != ltx[x+1] then
                if ltx[x+1] > 0 then
                    add_quad(   x+1,y,z,      x+1,ltx_start[x+1],z,    x+1,y,z+1,    x+1,ltx_start[x+1],z+1,      1,0,0)
                elseif ltx[x+1] < 0 then
                    add_quad(   x+1,ltx_start[x+1],z,        x+1,y,z,  x+1,ltx_start[x+1],z+1,      x+1,y,z+1,    -1,0,0)
                end
            end
        end]]
    end

    return mesh_data, quad_count
end

--jit.opt.start("callunroll=10")

local chunks = {}

--JIT_WATCH_FUNC_HEADER(get_packed_12)

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
                            chunk_set_block(block_data,x,y,z,c and 2 or 0)
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
        local data,quad_count = chunk_gen_mesh_striped_rowfetch(chunk.block_data,chunk.x,chunk.y,chunk.z)
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
print("Memory usage:",(memory_sum*8))

--[[
BuildFromTriangles
    0.000005 seconds per quad
Manual Meshing
    0.0000024 seconds per quad
Rough C++ Call Cost
    0.0000000954 seconds
]]


--[[
local test_chunk_block_data = {0,0,0,0,0,0,0,0}

local _low_ = 0
local _hi_ = 31

for z=_low_,_hi_ do
    for y=_low_,_hi_ do
        for x=_low_,_hi_ do
            --local c = math.random()>.9
            local c = z < math.sin(x/8)*5 + math.cos(y/8)*5 + 8
            chunk_set_block(test_chunk_block_data,x,y,z,c and 1 or 0)
        end
    end
end
----->
local res = chunk_gen_mesh_striped_all(test_chunk_block_data)
print("===>",#res)

local mesh = Mesh()
mesh:BuildFromTriangles(res)
----->
]]--

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
