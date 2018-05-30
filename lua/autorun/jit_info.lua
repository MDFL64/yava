local map = {}
local complete = {}

jit.attach( function(what,tr,func)
    if what == "start" then
        map[tr] = func
    elseif what == "stop" then
        local func = map[tr]
        complete[func] = (complete[func] or 0) + 1
    end
end, "trace")

local function jit_info()
    for func,count in pairs(complete) do
        local info = debug.getinfo(func)

        local file = file.Open(info.short_src,"r","GAME") 
        
        for i=1,info.linedefined-1 do
            local l = file:ReadLine()
        end
        
        local name_line = string.Replace(file:ReadLine() or "", "\n", "")
        file:Close()

        if not name_line:find("function") then continue end
        name_line = name_line:Replace("local ",""):Replace("function ",""):Trim()
        
        print(string.format("%-50s%-80s(x%i)",info.short_src..":"..info.linedefined,name_line,count))
    end

    map = {}
    complete = {}
end

if SERVER then
    concommand.Add("jit_info_sv",jit_info)
else
    concommand.Add("jit_info_cl",jit_info)
end