--[[
永远跟党走，心中有党，事业理想。☭
]]

-- Lua性能分析器，分析Lua代码消耗

LuaProfiler = {}
__LUA_PROFILER_ENABLE = false
__LIMIT = 3

local LuaPFTask = class("LuaPFTask")
function LuaPFTask:ctor(name, limit)
    self.name = name
    
    self.time = 0       -- 总时间
    self.hits = 0       -- 总命中次数

    self.limit = limit or __LIMIT
    self.depth = 0      -- 深度
    self.clock = 0      -- 
end

function LuaPFTask:HitB()
    self.clock = os.clock()
end

function LuaPFTask:HitE()
    self.hits = self.hits + 1
    self.time = self.time + math.floor((os.clock() - self.clock)*1000)
end

LuaProfiler._queue = {}
LuaProfiler._tasks = {}
LuaProfiler._names = {}

function LuaProfiler.Init()
    if not __LUA_PROFILER_ENABLE then return end

    local EVENT_AFTER_UPDATE = "director_after_update"
    local updateHandler = cc.EventListenerCustom:create(EVENT_AFTER_UPDATE, LuaProfiler.Update)
    global.EventDispatcher:addEventListenerWithFixedPriority(updateHandler, 1)
end

function LuaProfiler.Update(dt)
    if not __LUA_PROFILER_ENABLE then return end

    LuaProfiler.SeekGlobalScheduleException()
    LuaProfiler.PrintHighCalc()

    LuaProfiler._tasks = {}
    LuaProfiler._queue = {}
    LuaProfiler._names = {}
end

function LuaProfiler.BeginSample(name, limit)
    if not __LUA_PROFILER_ENABLE then return end

    if not LuaProfiler._tasks[name] then
        LuaProfiler._tasks[name] = LuaPFTask.new(name, limit)
        table.insert(LuaProfiler._names, name)
    end

    table.insert(LuaProfiler._queue, name)
    local task = LuaProfiler._tasks[name]
    task.depth = #LuaProfiler._queue
    task:HitB()
end

function LuaProfiler.EndSample()
    if not __LUA_PROFILER_ENABLE then return end

    local name = table.remove(LuaProfiler._queue, #LuaProfiler._queue)
    local task = LuaProfiler._tasks[name]
    task:HitE()
end

function LuaProfiler.Print()
    -- local sortTable = {}
    -- for _, v in pairs(LuaProfiler._tasks) do
    --     table.insert(sortTable, v)
    -- end
    -- if #sortTable > 2 then
    --     table.sort(sortTable, function(a, b)
    --         return a.time > b.time
    --     end)
    -- end

    -- print("--------------------------------------------")
    -- print("name                               calls                              time(ms)")
    -- for i, v in ipairs(sortTable) do
    --     local spaceTable = {}
    --     for i = 1, v.depth, 1 do
    --         spaceTable[i] = "  "
    --     end
    --     local spaceStr = table.concat(spaceTable, "")
    --     print(spaceStr, v.name, v.hits, v.time)
    -- end
    -- print("--------------------------------------------")
end

function LuaProfiler.PrintHighCalc()
    local tasks = {}
    local count = #LuaProfiler._names
    local task = nil
    for i, v in ipairs(LuaProfiler._names) do
        task = LuaProfiler._tasks[v]
        if task.time > task.limit then
            table.insert(tasks, task)
        end
    end

    if #tasks > 0 then
        print("-------------------------------------------- !!!!!!!!!!!!!!! By Lua Profiler")
        for i, v in ipairs(tasks) do
            print(v.name, v.hits, v.time .. "(ms)")
        end
        print("--------------------------------------------")
    end
end

---------------------------------------------------------------------------------
-- 检测表长度
local threshold = 500
local ignores = 
{
    ["__index"] = true,
    ["__newindex"] = true,
    ["package"] = true,
    ["class"] = true,
    ["__supers"] = true,
    ["super"] = true,
    ["__create"] = true,
}
function LuaProfiler.PrintLargeTable()
    local function checkT(tk, t)
        if rawget(t, "__check") == true then
            return
        end
        rawset(t, "__check", true)

        local count = 0
        local keys = table.keys(t)
        local v = nil
        for _, k in ipairs(keys) do
            if ignores[k] then
            else
                count = count + 1

                -- 取出内容
                v = rawget(t, k)

                -- 继续遍历表
                -- 忽略元表
                if type(v) == "table" then
                    -- print(tk .. "/" .. k, v)
                    checkT(tk .. "/" .. k, v)
                end
            end
        end

        if count >= threshold then
            print(tk, count)
        end
    end
    print("------------------------------ PrintLargeTable begin")
    checkT("_G", clone(_G))
    print("------------------------------ PrintLargeTable end")
end

---------------------------------------------------------------------------------
-- 检测全局定时器数量
LuaProfiler._globalScheduleLimit = 20
LuaProfiler._globalSchedules = {}
function LuaProfiler.BeginGlobalSchedule(entryId)
    if not __LUA_PROFILER_ENABLE then return end
    LuaProfiler._globalSchedules[entryId] = 1
end

function LuaProfiler.EndGlobalSchedule(entryId)
    if not __LUA_PROFILER_ENABLE then return end
    LuaProfiler._globalSchedules[entryId] = nil
end

function LuaProfiler.SeekGlobalScheduleException()
    local count = 0
    for k, v in pairs(LuaProfiler._globalSchedules) do
        count = count + 1
    end
    if count > LuaProfiler._globalScheduleLimit then
        print("------------------------------ !!!!!!!!!!!!!!! By Lua Profiler", count)
        for k, v in pairs(LuaProfiler._globalSchedules) do
            print(k, v)
        end
        print("------------------------------")
    end
end