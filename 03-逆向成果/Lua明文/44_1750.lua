-- local breakInfoFun,xpcallFun = require("LuaDebugjit")("localhost", 7003,true)
-- cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakInfoFun, 0.02, false)

release_print([[

*********************************************
Hello, World, This is Lua. By 996M2
*********************************************
]])

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    local msgStr = tostring(msg)
    local trace = debug.traceback()

    release_print("----------------------------------------")
    release_print("LUA ERROR: " .. msgStr .. "\n")
    release_print(trace)
    release_print("----------------------------------------")

    if global.isWindows then
        local date = os.date("*t")
        local filename = string.format("ERRORLOG_%s_%s_%s.txt", date.year, date.month, date.day)
        local filePath = global.WritablePath .. filename
        local ERRTITLE = string.format("%s/%s/%s/%s:%s:%s", date.year, date.month, date.day, date.hour, date.min, date.sec)

        local errorStr = ""
        errorStr = errorStr .. "----------------------------------" .. "\n"
        errorStr = errorStr .. ERRTITLE .. "\n"
        errorStr = errorStr .. "LUA ERROR: " .. msgStr .. "\n"
        errorStr = errorStr .. trace
        errorStr = errorStr .. "\n" .. "----------------------------------" .. "\n"

        local file = io.open(filePath, "a")
        file:write(errorStr)
        file:close()
    end

    -- bugly report
    if cc.PLATFORM_OS_ANDROID == global.Platform then
        buglyReportLuaException(msgStr, trace, false)
    end
end

local function Init()
    require("init/init")
end

local function main()
    Init()
end

xpcall(main, __G__TRACKBACK__)