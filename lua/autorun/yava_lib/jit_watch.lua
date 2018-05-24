
include("dis_x86.lua")

local op_names = {
	[0]="ISLT","ISGE","ISLE","ISGT",															--DONE
	"ISEQV","ISNEV","ISEQS","ISNES","ISEQN","ISNEN","ISEQP","ISNEP",							--DONE
	"ISTC","ISFC","IST","ISF",																	--DONE
	"MOV","NOT","UNM","LEN",																	--DONE
	"ADDVN","SUBVN","MULVN","DIVVN","MODVN",													--DONE
	"ADDNV","SUBNV","MULNV","DIVNV","MODNV",													--DONE
	"ADDVV","SUBVV","MULVV","DIVVV","MODVV",													--DONE
	"POW","CAT",																				--DONE
	"KSTR","KCDATA","KSHORT","KNUM","KPRI","KNIL",												--DONE
	"UGET","USETV","USETS","USETN","USETP","UCLO","FNEW",										--DONE
	"TNEW","TDUP","GGET","GSET","TGETV","TGETS","TGETB","TSETV","TSETS","TSETB","TSETM",		--DONE
	"CALLM","CALL","CALLMT","CALLT","ITERC","ITERN","VARG","ISNEXT",												--TODO 2 -- fukn tailcalls
	"RETM","RET","RET0","RET1",																	--DONE
	"FORI","JFORI",																				--DONE
	"FORL","IFORL","JFORL",																		--DONE
	"ITERL","IITERL","JITERL",																	--DONE
	"LOOP","ILOOP","JLOOP",																		--DONE
	"JMP",																						--DONE
	"FUNCF","IFUNCF","JFUNCF","FUNCV","IFUNCV","JFUNCV","FUNCC","FUNCCW"						--NOT IN DUMP
}

local function seek_val(base_string,table,val,seen)
    seen[table] = true
    for k,v in pairs(table) do
        local new_base = base_string.."."..k
        --print("check "..new_base)
        if type(k) != "string" then
            continue
        end

        if v == val then
            return new_base
        elseif type(v) == "table" and not seen[v] then
            local r = seek_val(new_base,v,val,seen)
            if r != nil then
                return r
            end
        end
    end
end

local function get_line(filename,line)

    local file = file.Open(filename,"r","GAME") 

    for i=1,line-1 do
        local l = file:ReadLine()
    end

    local name_line = string.Replace(file:ReadLine(), "\n", "")
    file:Close()

    return "["..line.."] "..name_line
end

local traces = {}
local watch_func_header

--local aborts = 0
--local exits = 0
local function ontrace(what, tr, func, pc, otr, oex)
    if what=="start" then
        traces[tr] = traces[tr] or {}
        traces[tr].id = tr
        traces[tr].func = func
        traces[tr].pc = pc
        traces[tr].children = {}
        traces[tr].exits = {}
    elseif what=="stop" then
        table.Merge(traces[tr], jit.util.traceinfo(tr) )
        if traces[tr].link != 0 and traces[tr].link != tr then
            table.insert(traces[traces[tr].link].children,traces[tr])
        end
    elseif what=="abort" then
        --table.Merge(traces[tr], jit.util.traceinfo(tr) )
        
        local reason = oex
        if type(reason) == "function" then
            reason = op_names[bit.band(jit.util.funcbc(func,pc),0xFF)] .." -> "..get_func_loc(reason)
        end
        if type(reason) == "number" then
            reason = op_names[reason]
        end
        if reason == nil then
            reason = op_names[bit.band(jit.util.funcbc(func,pc),0xFF)].. " ???"
        end

        if reason then
            local info = jit.util.funcinfo(func,pc)
            local source = string.Replace(info.source, "@", "")

            print("ABORT",reason.." @ "..get_line(source,info.currentline))
            if watch_func_header then
                print(" ----> "..op_names[bit.band(jit.util.funcbc(watch_func_header,0),0xFF)])
            end
        end
    end
end

local function onexit(tr,ex)

    local key = ex

    if traces[tr].exits[key] then
        traces[tr].exits[key] = traces[tr].exits[key] + 1
    else
        traces[tr].exits[key] = 1
    end
end

function JIT_WATCH_START()
    jit.attach(ontrace, "trace")
    jit.attach(onexit, "texit")
end

local function print_trace(t,indent)
    indent = indent and indent.." |  " or ""
    local info = jit.util.funcinfo(t.func,t.pc)
    local source = string.Replace(info.source, "@", "")
    print(indent.."Trace #"..t.id.." ["..t.linktype.."] ("..source..")")
    if t.abort_reason then
        print(indent.." - Aborted: "..t.abort_reason)
    end
    local exit_sum = 0
    for k,v in pairs(t.exits) do
        exit_sum = exit_sum + v
    end
    print(indent.." - Exits: "..exit_sum)
    print(indent.." - Function: "..get_line(source,info.linedefined))
    print(indent.." - Trace Start: "..get_line(source,info.currentline))
    if #t.children > 0 then
        print(indent.." + Children:")
        for k,v in pairs(t.children) do
            print_trace(v,indent)
        end
    end
end

function JIT_WATCH_PAUSE()
    jit.attach(ontrace)
    jit.attach(onexit)
end

function JIT_WATCH_PRINT()
    for k,v in pairs(traces) do
        if v.link == 0 or v.link == v.id then
            print_trace(v)
        end
    end
end

function JIT_WATCH_FUNC_HEADER(func)
    watch_func_header = func
end


local symtabmt = { __index = false }
local symtab = {}
local nexitsym = 0

-- Fill nested symbol table with per-trace exit stub addresses.
local function fillsymtab_tr(tr, nexit)
    local t = {}
    symtabmt.__index = t
    for i=0,nexit-1 do
        local addr = traceexitstub(tr, i)
        if addr < 0 then addr = addr + 2^32 end
        t[addr] = tostring(i)
    end
    local addr = traceexitstub(tr, nexit)
    if addr then t[addr] = "stack_check" end
end

-- Fill symbol table with trace exit stub addresses.
local function fillsymtab(tr, nexit)
    local t = symtab
    if nexitsym == 0 then
        local ircall = {
            [0]="str_cmp",
            "str_new",
            "strscan_num",
            "str_fromint",
            "str_fromnum",
            "tab_new1",
            "tab_dup",
            "tab_newkey",
            "tab_len",
            "gc_step_jit",
            "gc_barrieruv",
            "mem_newgco",
            "math_random_step",
            "vm_modi",
            "sinh",
            "cosh",
            "tanh",
            "fputc",
            "fwrite",
            "fflush"
        }
        for i=0,#ircall do
            local addr = jit.util.ircalladdr(i)
            if addr ~= 0 then
                if addr < 0 then addr = addr + 2^32 end
                    t[addr] = ircall[i]
                end
            end
        end
    if nexitsym == 1000000 then -- Per-trace exit stubs.
        fillsymtab_tr(tr, nexit)
    elseif nexit > nexitsym then -- Shared exit stubs.
        for i=nexitsym,nexit-1 do
            local addr = jit.util.traceexitstub(i)
            if addr == nil then -- Fall back to per-trace exit stubs.
                fillsymtab_tr(tr, nexit)
                setmetatable(symtab, symtabmt)
                nexit = 1000000
                break
            end
            if addr < 0 then addr = addr + 2^32 end
            t[addr] = tostring(i)
        end
        nexitsym = nexit
    end
    return t
end


concommand.Add("jit_disas", function(ply,cmd,args)
    local ord = tonumber(args[1])
    local trace = traces[ord]
    local mcode, addr, loop = jit.util.tracemc(ord)
    if addr < 0 then addr = addr + 2^32 end
    PrintTable(trace.exits)

    local ctx = dis_x86(mcode,addr,function(x)
        x = x:Replace("\n","")
        --[[for k,v in pairs(trace.exits) do
            if string.find(x,k) then
                x = x.." ------------------- EXIT x "..v
            end
        end]]
        print( x )
    end)

    --[[for i=0,trace.nexit do
        local addr = jit.util.traceexitstub(i)
        if addr == nil then
            addr = jit.util.traceexitstub(ord,i)
        end
        if addr < 0 then addr = addr + 2^32 end
        symtab[addr] = "exit_"..i
        print(string.format("0x%x",addr),"exit_"..i)
    end]]
    
    --[[for k,v in pairs(trace.exits) do
        symtab[k]= "EXIT x "..v
    end]]
    --ctx.hexdump = 0
    ctx.symtab = fillsymtab(ord,trace.nexit)

    if loop ~= 0 then
        symtab[addr+loop] = "LOOP"
        ctx:disass(0, loop)
        print("LOOP:")
        ctx:disass(loop, #mcode-loop)
      else
        ctx:disass(0, #mcode)
    end
end)
--[[
concommand.Add("jit_bc",function(ply,cmd,args)
    local ord = tonumber(args[1])
    local trace = traces[ord]
    PrintTable(trace)
    for i=1,1000000 do
        local a,b = jit.util.funcbc(trace.func, i)
        print(op_names[bit.band(a,0xFF)],op_names[bit.band(b,0xFF)])
    end
end)]]