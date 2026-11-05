local sformat   = string.format
local socket    = require("socket")

--获取0时区时间
function GetGMTime()
    return os.time(os.date("!*t",os.time()))
end

--获取服务器时间 (根据服务器和本地的时间差，算出当前服务器的时间)
function GetServerTime()
    local sub = global.MMO.ServerTime_Sub or 0
    return os.time() + sub
end

function GetTimeInMS()
    return socket.gettime()
end

-- 秒转时间 format : h:m:s
-- p2 : 是否转为字符串
function SecondToHMS(sec, isToStr, isSimple)
    local d = math.floor(sec / 86400)
    local h = math.fmod(math.floor(sec / 3600), 24)
    local m = math.fmod(math.floor(sec / 60), 60)
    local s = math.fmod(sec, 60)
    local time = {}
    time.d = d
    time.h = h
    time.m = m
    time.s = s
    if type(isToStr) == "boolean" and isToStr == true then
        if time.d > 0 then
            if isSimple then
                return sformat("%d天%d时", time.d, time.h)
            else
                return sformat("%d天%d时%d分%d秒", time.d, time.h, time.m, time.s)
            end
        else
            if time.h > 0 then
                if isSimple then
                    return sformat("%d时%d分", time.h, time.m)
                else
                    return sformat("%d时%d分%d秒", time.h, time.m, time.s)
                end
            else
                if time.m > 0 then
                    return sformat("%d分%d秒", time.m, time.s)
                else
                    return sformat("%d秒", time.s)
                end
            end
        end
    else
        return time
    end
end

function TimeFormat(time)
    if not time then
        return
    end

    local day,hour,min,sce = 0,0,0,0
    day = math.floor(time / 86400)
    hour = math.fmod( math.floor(time / 3600) , 24)
    min = math.fmod( math.floor(time/60),60)
    sce = math.fmod(time,60)
    return day,hour,min,sce
end

-- 00:00:00
function TimeFormatToString(time)
    local day, h, m, s = TimeFormat(time)
    if day < 1 then
        return sformat("%02d:%02d:%02d", h, m, s)
    end
    return sformat(GET_STRING(2000), day, h, m)
end
