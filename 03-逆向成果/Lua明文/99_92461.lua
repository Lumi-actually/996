SL = {}

require("GUI/SLFunctions")

local tconcat = table.concat
local tinsert = table.insert
local tkeys = table.keys
local tsort = table.sort
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next
local sfind = string.find
local ssub = string.sub
local slen = string.len
local sbyte = string.byte
local sgsub = string.gsub
local sformat = string.format
local supper = string.upper
local cjson = require("cjson")
local proxyUtils = requireUtil("proxyUtils")
local queue = requireUtil("queue")
local invalidStr = { "%", "(", ")", "_", "lib", "function", "then", "end", "_G", "return", "index", "set" }
local invalidStr2= {"lib","function","then","end","_G","return","index","set"}
local SharedPoint = {}

SL._DEBUG = global.isWindows and (global.isDebugMode or global.isGMMode)

SL.FormParam = {}
SL.LocalStringCache = {}        -- 将要存储的数据缓存
SL.LocalStringTimerID = nil     -- 存储数据定时器
SL.DigitChangeTimerID = nil     -- 数字滚动定时器
SL.CustomMapEffects = {}        -- 添加地图特效数据
SL.OpenGUITXTEditor = false

SL.TradingCustomCaptureLua = {}
---------------------------------------------------------------------------
local function deprecatedTip(old_name, new_name)
    SL:Print("\n********** \n"..old_name.." was deprecated please use ".. new_name .. " instead.\n**********")
end


---------------------------------------------------------------------------
-- 基础函数
function SL:release_print(...)
    release_print(...)
end

function SL:Print(...)
    if not SL._DEBUG then
        return nil
    end
    SL:release_print(...)
end

function SL:PrintEx(...)
    if not SL._DEBUG then
        return nil
    end
    SL:release_print(...)
    SL:release_print(debug.traceback())
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function SL:dump(value, desciption, nesting)
    if not SL._DEBUG then
        return nil
    end

    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = G_GetSplitArray(debug.traceback("", 2), "\n")
    SL:Print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result + 1] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result + 1] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result + 1] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent .. "    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                tsort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        SL:Print(line)
    end
end

function SL:PrintTraceback()
    local traceback = G_GetSplitArray(debug.traceback("", 2), "\n")
    SL:PrintTable(traceback)
end
SL.print = SL.Print
SL.printEx = SL.PrintEx
SL.Dump = SL.dump
SL.PrintTable = SL.dump
---------------------------------------------------------------------------

local function CheckJsonInvalid(jsonStr, invalidStr, is)
    for i = 1, #invalidStr do
        local v = invalidStr[i]
        local v2 = (is and i < 4) and "%"..v or v
        if sfind(jsonStr, v2) then
            SL:release_print(string.format("Jeson Error: Invalid character '%s'", v))
            return false
        end
    end
    return true
end

-- json字符串解密
-- params: json string
-- return: json table
function SL:JsonDecode(jsonStr, ischeck)
    if not jsonStr or jsonStr == "" then
        return nil
    end
    if ischeck then
        if CheckJsonInvalid(jsonStr, invalidStr, true) then
            return cjson.decode(jsonStr)
        end
    else
        return cjson.decode(jsonStr)
    end
end

-- json字符串加密
-- params: json table
-- return: json string
function SL:JsonEncode(jsonData, ischeck)
    if ischeck then
        local jData = cjson.encode(jsonData)
        if CheckJsonInvalid(jData, invalidStr, true) then
            return jData
        end
    else
        return cjson.encode(jsonData)
    end
end

-- 向服务器发送一个表单
-- params: string, string, string
-- return: nil
function SL:SubmitForm(filename, funcName, param)
    local isSend = true
    if param and not CheckJsonInvalid(param, invalidStr2) then
        isSend = false
    end

    if isSend then
        SL.NetworkUtil:SendUIMsg(filename, funcName, param)
        SL:Print("[GUI LOG] SL:SubmitForm(filename, funcName, param) ", filename, funcName, param)
    end
end


-- 深拷贝
function SL:CopyData(data)
    return clone(data)
end

function SL:Split(input, delimiter)
    return string.split(input, delimiter)
end

-- 注册游戏事件回调
-- params: string, string, function
-- return: nil
function SL:RegisterLUAEvent(eventID, eventTag, eventCB, widget)
    if not eventID then
        ErrorDebugPrint("[GUI ERROR] SL:RegisterLUAEvent, eventID is null", eventID, eventTag, eventCB)
        return
    end
    if not eventTag then
        ErrorDebugPrint("[GUI ERROR] SL:RegisterLUAEvent, eventTag is null", eventID, eventTag, eventCB)
        return
    end
    if not eventCB then
        ErrorDebugPrint("[GUI ERROR] SL:RegisterLUAEvent, eventCB is null", eventID, eventTag, eventCB)
        return
    end
    SLBridge.LUAEvent[eventID] = SLBridge.LUAEvent[eventID] or {}
    SLBridge.LUAEvent[eventID][eventTag] = eventCB

    if widget then
        GUI:Win_BindLuaEvent(widget, eventID, eventTag)
    end
end

-- 注销游戏事件回调
-- params: string, string, function
-- return: nil
function SL:UnRegisterLUAEvent(eventID, eventTag)
    if not eventID then
        ErrorDebugPrint("[GUI ERROR] SL:UnRegisterLUAEvent, eventID is null", eventID, eventTag)
        return
    end
    if not eventTag then
        ErrorDebugPrint("[GUI ERROR] SL:UnRegisterLUAEvent, eventTag is null", eventID, eventTag)
        return
    end
    if not SLBridge.LUAEvent[eventID] then
        SL:Print("[GUI ERROR] SL:UnRegisterLUAEvent, can't registered", eventID)
        return
    end
    SLBridge.LUAEvent[eventID][eventTag] = nil
end

function SL:onLUAEvent(name, data)
    SLBridge:onLUAEvent(name, data)
end
SL.OnLUAEvent = SL.onLUAEvent

function SL:SendNetMsg(msgID, p1, p2, p3, sendData)
    SL.NetworkUtil:SendMsg(msgID, sendData, p1, p2, p3)
end

function SL:RegisterNetMsg(msgID, netCB, widget)
    SL.NetworkUtil:RegisterNetworkHandler(msgID, netCB)
    if widget then
        GUI:Win_BindNetMsgEvent(widget, msgID)
    end
end

function SL:UnRegisterNetMsg(msgID)
    SL.NetworkUtil:UnRegisterNetworkHandler(msgID)
end

function SL:SendLuaNetMsg(msgID, p1, p2, p3, sendData)
    SL.NetworkUtil:SendLuaMsg(msgID, p1, p2, p3, sendData)
end

function SL:RegisterLuaNetMsg(msgID, netCB, widget)
    SL.NetworkUtil:RegisterLuaNetworkHandler(msgID, netCB)
    if widget then
        GUI:Win_BindLuaNetMsgEvent(widget, msgID)
    end
end

function SL:UnRegisterLuaNetMsg(msgID)
    SL.NetworkUtil:UnRegisterLuaNetworkHandler(msgID)
end

-- 开启一个定时器
-- params: function, number
-- return: int
function SL:Schedule(callback, interval)
    return Schedule(callback, interval)
end

-- 开启一个单次定时器
-- params: function, number
-- return: int
function SL:ScheduleOnce(listener, time)
    return PerformWithDelayGlobal(listener, time)
end

-- 停止一个定时器
-- params: int
function SL:UnSchedule(scheduleID)
    if not scheduleID then
        return
    end
    UnSchedule(scheduleID)
end

-- 开启一个定时器, 绑定node
-- params: function, number
-- return: int
function SL:schedule(node, callback, delay)
    return schedule(node, callback, delay)
end

-- 开启一个单次定时器
-- params: int
function SL:scheduleOnce(node, callback, delay)
    return performWithDelay(node, callback, delay)
end

-- 关闭一个单次定时器
-- params: action
function SL:unSchedule(action)
    global.ActionManager:removeAction(action)
end

-- 加载文件
function SL:Require(file, reload)
    if reload then
        package.loaded[file] = nil
    end
    return require(file)
end

-- 加载文件
function SL:RequireFile(file)
    if SL._DEBUG then
        package.loaded[file] = nil
    end
    return require(file)
end

function SL:HTTPRequestGet(url, callback)
    HTTPRequest(url, callback)
end

-- notForce: 不强行设置("Content-type", "application/x-www-form-urlencoded")
function SL:HTTPRequestPost(url, callback, data, header, notForce)
    HTTPRequestPost(url, callback, data, header, notForce)
end

-- 基础函数
---------------------------------------------------------------------------
--哈希表转成按数组
function SL:HashToSortArray(hashTab, sortFunc)
    return HashToSortArray(hashTab, sortFunc)
end

-- 转换颜色，从16进制字符转为{r, g, b}
function SL:ConvertColorFromHexString(hexString)
    return ConvertHexStrToColor3B(hexString)
end

function SL:CheckBit(num, pos)
    return CheckBit(num, pos)
end

-- 数字转换成万、亿单位
function SL:GetSimpleNumber(n, places)
    if GUIFunction.GetSimpleNumber then
        return GUIFunction:GetSimpleNumber(n, places)
    end

    local places = places and "%."..places.."f" or "%.2f"
    if n >= 100000000 then
        return string.format(places.."%s", n / 100000000, GET_STRING(1045))
    end
    if n >= 100000 then
        return string.format(places.."%s", n / 10000, GET_STRING(1005))
    end
    if n >= 10000 then
        return string.format(places.."%s", n / 10000, GET_STRING(1005))
    end
    return tostring(n)
end

-- 血量单位 过十亿(单位：E)   10w-99999w(单位：W）
function SL:HPUnit(hp, pointBit, notCheckSet)
    if GUIFunction.ConvertHPUnit then
        return GUIFunction:ConvertHPUnit(hp, pointBit, notCheckSet)
    end

    local hpNum = tonumber(hp) or 0
    if hpNum < 0 then
        return hpNum
    end

    if notCheckSet then
        return hpNum
    elseif CHECK_SETTING(global.MMO.SETTING_IDX_HP_UNIT) ~= 1 then
        return hpNum
    end

    -- 小数点后几位  默认保留后两位
    pointBit = pointBit or 2

    local unitFunc = function(num)
        if pointBit == 0 then
            return math.floor(num)
        end
        local iNum, fNum = math.modf(num)
        local fDecimal = math.pow(10, tostring(pointBit))
        local newFNum = math.floor(tostring(fNum * fDecimal))
        local newINum = iNum + (newFNum / fDecimal)
        return newINum
    end

    if hpNum >= 1000000000 then
        hp = unitFunc(hpNum / 100000000) .. GET_STRING(310000600)
    elseif hpNum >= 100000 and hpNum <= 999999999 then
        hp = unitFunc(hpNum / 10000) .. GET_STRING(310000601)
    end

    return hp
end

-- 中文转换成竖着显示
function SL:ChineseToVertical(str)
    local UTF8 = require("util/utf8")
    local len = UTF8:length(str)
    local newStr = ""
    for i = 1, len do
        newStr = newStr .. UTF8:sub(str, i, 1)
        if i < len then
            newStr = newStr .. "\n"
        end
    end
    return newStr
end

-- 获取字符串的byte长度
function SL:GetUTF8ByteLen(str)
    local function chsize(char)
        if not char then
            print("not char")
            return 0
        elseif char > 240 then
            return 4
        elseif char > 225 then
            return 3
        elseif char > 192 then
            return 2
        else
            return 1
        end
    end
    local len = 0
    local chineseLen = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local char = sbyte(str, currentIndex)
        local charS = chsize(char)
        currentIndex = currentIndex + charS
        len = len + charS
        if charS >= 3 then
            chineseLen = chineseLen + 1
        end
    end
    return len, chineseLen
end

-- 时间格式化成字符串显示
function SL:TimeFormatToStr(time)
    return TimeFormatToString(time)
end

function SL:SecondToHMS(sec, isToStr, isSimple)
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

-- 数字转化为千分位字符串
function SL:GetThousandSepString(num)
    local formatted = ""
    if tonumber(num) then
        formatted = tostring(num)
    end
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- 阿拉伯数字转中文大写
function SL:NumberToChinese(szNum)
    return NumberToChinese(szNum)
end

-- UTF8字符串截取
function SL:GetUTF8SubString(str, subStar, subEnd)
    return StringUTF8Sub(str, subStar, subEnd)
end

-- 
function SL:FixStringFormatCharacter(str)
    return FixStringFormatCharacter(str)
end

function SL:FixFilePath(path)
    return FixFilePath(path)
end

function SL:CreateQueue()
    return queue.new()
end

-- GBK转UTF8编码
function SL:UTF8ToGBK(str)
    if UTF8ToGB2312 then
        return UTF8ToGB2312(str)
    end
end

-- UTF8转GBK编码
function SL:GBKToUTF8(str)
    if GB2312ToUTF8 then
        return GB2312ToUTF8(str)
    end
end

-- 搜索路径下所有文件(path: dev下面的文件路径; 例如："res/")
function SL:GetFilesByPath(path)
    local fileUtil      = global.FileUtilCtl
    local resourcePath  = fileUtil:getDefaultResourceRootPath()
    local mCachePath    = global.L_ModuleManager:GetCurrentModule():GetSubModPath()
    local mStabPath     = global.L_ModuleManager:GetCurrentModule():GetStabPath()

    path                = path or ""
    local directory     = "dev/"  .. path
    local exportFolder  = resourcePath .. mStabPath  .. path
    local exportFolder2 = resourcePath .. mCachePath .. path
    local GMFolder      = resourcePath .. directory
    local cacheFolder   = fileUtil:getWritablePath() .. mCachePath .. path
    local cacheFolder2  = fileUtil:getWritablePath() .. mStabPath  .. path


    local GetFileName = function (str)
        local rerStr = string.reverse(str)
        local _, i   = sfind(rerStr, "/")
        local len    = slen(str)
        local st     = len - i + 2
        return ssub(str, st, len)
    end

    local files = {}
    local items = {}

    local iflag = {}
    local fflag = {}
    for _, path in ipairs({GMFolder, cacheFolder, exportFolder, cacheFolder2, exportFolder2}) do
        repeat
            if not fileUtil:isDirectoryExist(path) then --遍历不存在的目录在ios上会崩溃
                break
            end
            local listfiles = fileUtil:listFiles(path)
            for k, info in ipairs(listfiles) do
                -- 去掉末尾可能出现的 /
                info = sgsub(info, "[/]+$", "")

                local filename = GetFileName(info)
                if filename and not sfind(filename, "^%.") then
                    
                    if fileUtil:isDirectoryExist(info) then -- 是否是文件夹
                        if not fflag[filename] then
                            files[#files + 1] = filename
                            fflag[filename] = true
                        end
                    else
                        if not iflag[filename] then
                            items[#items + 1] = filename
                            iflag[filename] = true
                        end
                    end
                end
            end
        until true
    end

    tsort(files, function (a, b) return supper(a) < supper(b) end)
    tsort(items, function (a, b) return supper(a) < supper(b) end)

    for i, v in ipairs(items) do
        files[#files + 1] = v
    end

    return files
end

-- 解析带元变量格式文本 例：&<EQUIPBYPOS/1>&
function SL:ParseMetaValueStr(str)
    if not str or str == "" then
        return str
    end
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    return metaValueProxy:MetaValueFormat(str)
end

function SL:UrlEncode(input)
    return string.urlencode(input)
end

function SL:UrlDecode(input)
    return string.urldecode(input)
end
---------------------------------------------------------------------------
-- 文件操作
-- 文件路径是否存在
function SL:IsFileExist(path)
    return global.FileUtilCtl:isFileExist(path)
end

-- 根据文件名字获取绝对路径
function SL:GetFullPathForFilename(filename)
    return global.FileUtilCtl:fullPathForFilename(filename)
end

-- 移除文件
function SL:RemoveFile(path)
    global.FileUtilCtl:removeFile(path)
end

-- 移除文件
function SL:WriteStringToFile(okstr, path)
    global.FileUtilCtl:writeStringToFile(okstr, path)
end

function SL:GetDataFromFileEx(filename)
    return global.FileUtilCtl:getDataFromFileEx(filename)
end

-- 指定分隔符拆解一个文件
function SL:LoadTxtFile(path, delimiter, callBack)
    if nil == path or nil == callBack then
        print("LoadText error")
        return
    end

    local strBuffer = global.FileUtilCtl:getDataFromFileEx(path)
    strBuffer = sgsub(strBuffer, "\r", "")
    local lineBreak = "\n"

    local lines = G_GetSplitArray(strBuffer, lineBreak)
    local len = 0
    local pos1 = nil
    for k, v in ipairs(lines) do
        len = slen(v)
        if len > 0 then
            pos1, _ = sfind(v, "//")
            if not pos1 then -- skip //
                local dataTable
                if delimiter == nil or delimiter == "" or delimiter == "\n" then -- ignore "" \n
                    dataTable = {}
                    dataTable[1] = v
                else
                    dataTable = G_GetSplitArray(v, delimiter)
                end

                callBack(dataTable)
            end
        end
    end
end

local function writefile(str, filePath)
    local path = global.FileUtilCtl:getSuitableFOpen(filePath) -- io.open 读写不能是UTF-8
    local file = io.open(path, "w+")
    if file then 
        print("open file success...", path)
        local tbl = G_GetSplitArray(str, "\n")
        for i = 1, #tbl do
            tbl[i] = sgsub(tbl[i], "!@2@!", "\\n")
            file:write(tbl[i] .. "\n")
        end
        print("write file complete...", string.len(str))
        file:close()
    else 
        print("open file error...", path)
    end 
end

local function dealSpecialStr(str)
    str = sgsub(str, '\\', '\\\\')
    str = sgsub(str, '"([^"]*)"', '!@1@!%1!@1@!')
    str = sgsub(str, '"([^"]*)"', '%1')
    str = sgsub(str, '!@1@!', '\\\"')
    return str
end

-- serialize table to str
local function serialize(t, sortfunc, quotKey)
    if next(t) == nil then
        local serStr = "{" .. "\n" .. "}"
        return "local config = " .. serStr .. "\nreturn config"
    end
    local function ser_table(tbl, deep)
        local tmp = {}
        local sortList = tkeys(tbl)
        for _, k in ipairs(sortList) do
            local v = tbl[k]
            if type(k) == "string" and tonumber(k) then
                k = tonumber(k)
            end

            if type(v) == "table" then
                deep = deep + 1

                local key = type(k) == "number" and string.format("[%s]", k) or (quotKey and string.format('["%s"]', k) or k)
                if key == "" then
                    key = string.format('["%s"]', k)
                end
                local space = srep(" ", deep * 4)
                tinsert(tmp, string.format("\n%s%s = %s", space, key, ser_table(v, deep)))

                deep = deep - 1
            else
                local key2 = type(k) == "number" and "[" .. k .. "]" or k
                if key2 == "" then
                    key2 = string.format('["%s"]', k)
                end
                local space = "\n" .. srep(" ", (deep + 1) * 4)
                if type(v) == "string" then
                    if sfind(v, "\n") then
                        v = sgsub(v, "\n", "!@2@!")
                    end
                    v = dealSpecialStr(v)
                    tinsert(tmp, space .. key2 .. '="' .. v .. '"')
                else
                    tinsert(tmp, space .. key2 .. "=" .. tostring(v))
                end
            end
        end

        return string.format("{%s\n%s}", table.concat(tmp, ","), srep(" ", deep * 4))
    end

    local sortT = tkeys(t)
    tsort(sortT)

    local finalStr = { "local config = {\n" }
    local cnt = #sortT

    for index, k in ipairs(sortT) do
        local oneStr = ""
        if type(t[k]) == "string" then
            oneStr = string.format('"%s"', t[k])
        else
            oneStr = ser_table(t[k], 1)
        end 
        local key = type(k) == "number" and "[" .. k .. "]" or (quotKey and '["' .. k .. '"]' or k)
        oneStr = sformat("    %s = %s,%s", key, oneStr, index == cnt and "" or "\n")
        table.insert(finalStr, oneStr)
    end
    table.insert(finalStr, "\n}\n")
    table.insert(finalStr, "return config")
    return table.concat(finalStr)
end

-- lua table转成config配置表
-- tab lua表, name 要保存的config名字, destPath 保存的路径(默认dev/scripts/game_config/),
-- sortFunc 外层排序函数, quotKey ["key"]这种带引号的key,默认不带引号
function SL:SaveTableToConfig(tab, name, destPath, sortFunc, quotKey)
    if not tab or type(tab) ~= "table" or not name or string.len(name) == 0 then
        return
    end

    SL:Print("++++++Save begin++++++", name)
    local startMS = GetTimeInMS()

    local serializeStr = serialize(tab, sortFunc, quotKey)

    local serMS = GetTimeInMS()
    print("serialize cost:" .. (serMS - startMS))

    local path = (destPath or "dev/scripts/game_config/") .. name .. ".lua"
    writefile(serializeStr, path)

    print("io cost:" .. (GetTimeInMS() - serMS))
    SL:Print("------Save end------")
end

-- 同步官方配置表
function SL:UpdateConfig(file)
    local fileList = file and {file} or SLDefine.ConfigSettingFile
    local configPath = "scripts/game_config/"
    local module = global.L_ModuleManager:GetCurrentModule()

    -- 母包路径
    local motherPath = global.FileUtilCtl:getDefaultResourceRootPath() .. tostring(module:GetID()) .. "/" .. module:GetVersion() .. "/" .. configPath
    -- 热更路径
    local hotUpdatePath = module:GetStabPath() .. configPath

    local officalPath = {}
    for i, name in pairs(fileList) do 
        local filePath = nil
        if global.FileUtilCtl:isFileExist(motherPath..name) then 
            filePath = motherPath..name
        end 
        if global.FileUtilCtl:isFileExist(hotUpdatePath..name) then 
            filePath = hotUpdatePath..name
        end 
        if global.FileUtilCtl:isFileExist(filePath) then -- 官方路径 先找母包 再找热更 以热更为主
            officalPath[name] = filePath
        end 
    end 

    local customPath = {}
    for i, name in pairs(fileList) do 
        local filePath = nil 
        local devPath = global.FileUtilCtl:getDefaultResourceRootPath() .. "dev" .. "/" .. configPath .. fileList[i]
        if global.FileUtilCtl:isFileExist(devPath) then 
            filePath = devPath
        end 
        if global.FileUtilCtl:isFileExist(filePath) then -- 本地路径 dev目录下
            customPath[name] = filePath
        end 
    end 

    local function getAddFile(path)
        local config = require(path)
        if config and next(config) then 
            return config
        end 
    end 

    local function getUpdateFile(pathOffcial, pathCustom)
        local offcialCfg = require(pathOffcial)
        local customCfg = require(pathCustom)

        if offcialCfg and next(offcialCfg) and customCfg and next(customCfg) then 
            for key, cfg in pairs(offcialCfg) do 
                if not customCfg[key] then 
                    customCfg[key] = cfg
                end 
            end 
        end 

        return customCfg
    end 

    -- 对比 有无新增
    for i, name in pairs(fileList) do 
        local newCfg = nil
        if not officalPath[name] and customPath[name] then -- 官方无 本地有 用本地
            -- do nothing 
        end 
        
        if officalPath[name] and not customPath[name] then -- 官方有 本地无 新增官方表
            newCfg = getAddFile(officalPath[name])
        end  

        if officalPath[name] and customPath[name] then -- 官方有 本地有 对比 1.本地已有key不操作 2.本地无的key补全
            newCfg = getUpdateFile(officalPath[name], customPath[name])
        end 

        if newCfg and next(newCfg) then 
            local cfgName = string.gsub(name, ".lua", "")
            SL:SaveTableToConfig(newCfg, cfgName, nil, nil, true)
            global.FileUtilCtl:purgeCachedEntries()
        end 
    end 
end 

-- 同步服务下发配置表
function SL:UpdateServerConfig(file)
    local fileList = file and {file} or SLDefine.ConfigServerFile
    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)
    for i, name in pairs(fileList) do 
        local clientCfg = {}
        local severCfg = GameConfigMgrProxy:getServerConfingByKey(name) or {}
        if not severCfg or next(severCfg) == nil then 
            print("未找到服务配置"..name)
        end 

        local configPath = "scripts/game_server_config/"
        local devPath = global.FileUtilCtl:getDefaultResourceRootPath() .. "dev/" .. configPath .. name .. ".lua"
        local isFile = global.FileUtilCtl:isFileExist(devPath)
        if isFile then 
            clientCfg  = require(devPath)
        end 

        -- 对比 同步客户端修改的配置
        if severCfg and next(severCfg) then 
            if clientCfg and next(clientCfg) then 
                for key, cfg in pairs(clientCfg) do 
                    if severCfg[key] then 
                        local keys = {}
                        keys = table.keys(cfg)
                        for _, key2 in pairs(keys) do 
                            severCfg[key][key2] = cfg[key2] -- 服务删除字段：a.客户端有 补全, b.客户端没有不管。 服务新增字段：新增。服务修改字段：以客户端为准
                        end 
                    else 
                        severCfg[key] = cfg -- 客户端新增key
                    end  
                end 
            end 

            local newCfg = {}
            newCfg = severCfg
            SL:SaveTableToConfig(newCfg, name)
            global.FileUtilCtl:purgeCachedEntries()
        end 
    end
end 

-- 删除GM缓存资源 
function SL:RemoveGMResFile(filePath)
    local module            = global.L_ModuleManager:GetCurrentModule()
    local modulePath        = module:GetSubModPath()
    local gmCachePath       = global.WritablePath .. modulePath
    local fullPath          = gmCachePath .. filePath
    if not global.FileUtilCtl:isFileExist(fullPath) then
        return
    end
    global.FileUtilCtl:removeFile(fullPath)
    global.FileUtilCtl:purgeCachedEntries()
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 十六进制转十进制
function SL:HexToInt(hexStr)
    return tonumber(hexStr, 16)
end

function SL:GetStrMD5(str)
    return get_str_MD5(str)
end

function SL:GetPointDistanceSQ(pt1, pt2)
    return cc.pDistanceSQ(pt1, pt2)
end

function SL:GetPointDistance(pt1, pt2)
    return cc.pGetDistance(pt1, pt2)
end

function SL:GetPointLength(pt)
    return cc.pGetLength(pt)
end

function SL:GetPointLengthSQ(pt)
    return cc.pLengthSQ(pt)
end

function SL:GetMidPoint(pt1, pt2)
    return cc.pMidpoint(pt1, pt2)
end

function SL:GetAddPoint(pt1, pt2)
    return cc.pAdd(pt1, pt2)
end

function SL:GetSubPoint(pt1, pt2)
    return cc.pSub(pt1, pt2)
end

function SL:GetNormalizePoint(pt)
    return cc.pNormalize(pt)
end

function SL:GetPointAngle(pt1, pt2)
    return cc.pGetAngle(pt1, pt2)
end

function SL:GetPointRotate(pt1, pt2)
    local angle = cc.pGetAngle(pt1, pt2)
    return angle * 180 / math.pi
end

function SL:GetPointAngleSelf(pt)
    return cc.pToAngleSelf(pt)
end

function SL:GetPointRotateSelf(pt)
    local angle = cc.pToAngleSelf(pt)
    return angle * 180 / math.pi
end

------------------------------游戏相关--------------------------------------
-- 提示
function SL:ShowSystemTips(str)
    ShowSystemTips(str)
end

-- 发送系统消息
function SL:ShowSystemChat(msg, fcolor, bcolor)
    local mdata = {
        Msg        = msg or "",
        FColor     = fcolor or 255,
        BColor     = bcolor or 255,
        ChannelId  = GUIDefine.ChatChannel.SYSTEM,
    }
    SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)
end

-- 显示获得到背包{name = "", num = 0}
function SL:ShowGetBagItem(data)
    global.Facade:sendNotification(global.NoticeTable.ShowGetBagItem, data)
end

-- 显示获得到背包{name = "", num = 0}
function SL:ShowCostItem(data)
    global.Facade:sendNotification(global.NoticeTable.ShowCostItem, data)
end

-- 显示获得到背包{name = "", num = 0}
function SL:ShowGetHeroBagItem(data)
    global.Facade:sendNotification(global.NoticeTable.ShowGetBagItem_Hero, data)
end

-- 显示获得到背包{name = "", num = 0}
function SL:ShowCostHeroItem(data)
    global.Facade:sendNotification(global.NoticeTable.ShowCostItem_Hero, data)
end

-- 本地公告展示 [ssr]
-- FIXME: 考虑单独拆开实现
function SL:ShowLocalNoticeByType(jsonData)
    if not jsonData or not jsonData.Type then
        return
    end

    if jsonData.Type == 12 then
        local mdata     = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            ChannelId   = GUIDefine.ChatChannel.SYSTEM,
            textType    = GUIDefine.ChatTextType.SYSTEMTIPS,
        }
        SLBridge:onLUAEvent(LUA_EVENT_CHAT_MSG_ADD, mdata)

    elseif jsonData.Type == 4 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowServerNotice, data)

    elseif jsonData.Type == 5 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.Y,
            Count       = jsonData.Count,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNotice, data)

    elseif jsonData.Type == 6 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            Label       = jsonData.Label
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNotice, data)

    elseif jsonData.Type == 9 then
        ShowSystemTips(jsonData.Msg)

    elseif jsonData.Type == 10 then
        local data      = {
            X           = jsonData.X,
            Y           = jsonData.Y,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeXY, data)

    elseif jsonData.Type == 11 then
        local data      = {
            Type        = jsonData.Type,
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
        }
        global.Facade:sendNotification(global.NoticeTable.ServerNoticeEvent, data)
    elseif jsonData.Type == 13 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Y           = jsonData.Y,
            Count       = jsonData.Count,
            ShowTime    = jsonData.time,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowSystemNoticeScale, data)
    elseif jsonData.Type == 14 then
        local data      = {
            Msg         = jsonData.Msg,
            FColor      = jsonData.FColor,
            BColor      = jsonData.BColor,
            Time        = jsonData.Time,
            X           = jsonData.X,
            isDelete    = jsonData.isDelete,
        }
        global.Facade:sendNotification(global.NoticeTable.ShowTimerNoticeXY, data)
    end
end

--显示提示文本
function SL:SHOW_DESCTIP(str, width, worldPos, anchorPoint, swallowType)
    SHOW_DESCTIP(str, width, worldPos, anchorPoint, swallowType)
end

-- 跳转到某个超链
-- id: int  param: 附加参数
function SL:JumpTo(id, param)
    JUMPTO(id, param)
end
function SL:CheckOpenLayer(id, param, calllback)
    G_CheckOpenLayer(id, param, calllback)
end

function SL:SubmitAct(data)
    local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
    SUIComponentProxy:SubmitAct(data)  
end

-- 关闭世界公告事件
function SL:CloseGameWorldEvent()
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    if LoginProxy:IsCloseGameWorldStatus() then
        print("Warning: SL:CloseGameWorldEvent() is already called.")
        return
    end
    LoginProxy:SetCloseGameWorldStatus(true)
    global.Facade:sendNotification(global.NoticeTable.GameWorldConfirm)
    global.Facade:sendNotification(global.NoticeTable.GameWorldCheckTimeout)
end

-- 退出到选角界面
function SL:ExitToRoleUI()
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if shiwan and tonumber(shiwan) == 1 then
        return
    end
    local data = {}
    data.str = GET_STRING(30003056)
    data.btnDesc = { GET_STRING(1001), GET_STRING(1000) }
    data.callback = function(bType)
        if bType == 1 then
            global.Facade:sendNotification(global.NoticeTable.RequestLeaveWorld)
        end
    end
    UIOperator:OpenCommonTipsUI(data)

    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_LAYER_CLICK
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

function SL:ForceExitToRoleUI()
    global.gameWorldController:OnGameLeaveWorld()
end

-- 退出到登录界面
function SL:ExitToLoginUI(isJudgePC)
    global.L_NativeBridgeManager:GN_accountLogout()
    global.Facade:sendNotification(global.NoticeTable.RestartGame)
    if isJudgePC then
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        if envProxy:IsNeedExitGame() then
            global.Director:endToLua()
        end
    end
end

-- 上报游戏异常日志
function SL:ReportGameExceptionLog(action,data)
    global.L_NativeBridgeManager:GN_SendGameNetWorkLog({action = action, data = data})
end

-- 上报网络诊断日志
function SL:ReportNetworkDiagnosisLog(ip, port)
    global.L_NativeBridgeManager:GN_SendGameNetWorkLog({action = "networkDiagnostics", data = {ip = ip, port = port}})
end

-- 退出游戏
function SL:ExitGame()
    global.Facade:sendNotification(global.NoticeTable.RequestShutdownGame)
end

-- 退出游戏
function SL:ShutdownGame()
    global.Director:endToLua()
end

-- 创建一个红点到节点
function SL:CreateRedPoint(parent, offset)
    local sprite = cc.Sprite:create(global.MMO.PATH_RES_PUBLIC .. "btn_npcfh_04.png")
    if sprite then
        local size = parent:getContentSize()
        local pos = {}
        pos.x = size.width - (offset and offset.x or 0)
        pos.y = size.height - (offset and offset.y or 0)
        sprite:setPosition(cc.p(pos.x, pos.y))
        parent:addChild(sprite)
    end
    return sprite
end

--绘制一个带有填充色和线条的多边形加入游戏场景节点
function SL:CreateDrawPolygon(sceneZOrder, verts, count, fillColor, borderWidth, borderColor)
    fillColor = fillColor or cc.c4f(0,0,0,0)
    borderWidth = borderWidth or 1
    borderColor = borderColor or cc.c4f(1, 0, 0, 1)

    local drowRoot = cc.DrawNode:create()
    drowRoot:drawPolygon(
        verts,             --顶点数组
        count,             --顶点数量
        fillColor,         --填充颜色
        borderWidth,       --线条宽度
        borderColor        --线条颜色
    )
    GUI:addChild(global.sceneGraphCtl:GetSceneNode(sceneZOrder), drowRoot)
    return drowRoot
end

--播放烟花特效
function SL:CreateShowFireWorks(parent, actorId, effectId, callback)
    local actor = global.playerManager:FindOnePlayerInCurrViewFieldById( actorId )
    if (not actor) then
        return
    end
    local actorNode = actor:GetNode()
    if (not actorNode) then
        return
    end
    --自身的node
    local playerID = global.gamePlayerController:GetMainPlayerID()
    local mActor = global.playerManager:FindOnePlayerInCurrViewFieldById( playerID )
    local mActorNode = mActor:GetNode()

    local visibleSize = global.Director:getVisibleSize()
    local function AddSFXAnimLayer( sfxAnim )
        if not parent then
            local Layout = ccui.Layout:create()
            Layout:setContentSize(visibleSize.width, visibleSize.height)
            Layout:setAnchorPoint(cc.p(0.5, 0.5))
            Layout:setPosition(visibleSize.width/2,visibleSize.height/2)
            Layout:setTouchEnabled(false)
            parent = Layout
            global.Facade:sendNotification(global.NoticeTable.Layer_Notice_AddChild, {child = Layout})
        end
        parent:addChild(sfxAnim,999)
    end

    local posX   = math.ceil(actorNode:getPositionX())
    local posY   = math.ceil(actorNode:getPositionY())
    local mPosX  = math.ceil(mActorNode:getPositionX())
    local mPosY  = math.ceil(mActorNode:getPositionY())
    -- 播放特效
    local sfxAnim = global.FrameAnimManager:CreateSFXAnim(effectId)
    AddSFXAnimLayer(sfxAnim)

    local offPosX = mPosX - posX
    local offPosY = mPosY - posY
    sfxAnim:setPosition(visibleSize.width/2-offPosX, visibleSize.height/2-offPosY)
    sfxAnim:Play(0, 0)
    local function removeEvent()
        sfxAnim:removeFromParent()
        if callback then
            callback()
        end
    end
    sfxAnim:SetAnimEventCallback(removeEvent)
end

-- 
function SL:GetValue(key, ...)
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    return metaValueProxy:GetValueByKey(key, ...)
end

function SL:SetValue(key, ...)
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    return metaValueProxy:SetValueByKey(key, ...)
end

function SL:PrintMetaKey()
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    metaValueProxy:PrintMetaKey()
end

function SL:PrintAllMetaValue()
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    metaValueProxy:PrintAllMetaValue()
end

-- 获取自定义变量值
function SL:GetSerCustomVar(key)
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    return metaValueProxy:GetCustomVarByKey(key)
end

function SL:RequestCustomVar(key)
    local metaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
    return metaValueProxy:RequestCustomVar(key)
end

-- 请求获取剪贴板文本
function SL:RequestGetClipboardText()
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_getClipboardText()
end
--------------------------------------------------------------------------------------------------------------------------------
-- 颜色配置
-- 设置文本样式(按钮、文本)
function SL:SetColorStyle(widget, colorID)
    SET_COLOR_STYLE(widget, colorID)
end

function SL:GetColorCfg(id)
    return GET_COLOR_CONFIG(id)
end

-- 通过色值id获取Color3B
function SL:GetColorByStyleId(id)
    return GET_COLOR_BYID_C3B(id)
end

-- 通过色值id获取hex
function SL:GetHexColorByStyleId(id)
    return GET_COLOR_BYID(id)
end

-- 通过色值id获取字号
function SL:GetSizeByStyleId(id)
    return GET_SIZE_BYID(id)
end

-- 通过Color3B获取hex
function SL:GetColorHexFromRGB( rgb )
    return ConvertColor3BToHexStr(rgb)
end

-- condition
function SL:CheckCondition(conditionStr)
    local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    return ConditionProxy:CheckCondition(conditionStr)
end

-- 显示气泡提醒
function SL:AddBubbleTips(id, path, callback, time, timeOverCB)
    SL:onLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, {id = id, status = true, path = path, callback = callback, time = time, timeOverCB = timeOverCB})
end

-- 删除气泡提醒
function SL:DelBubbleTips(id)
    SL:onLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, {id = id, status = false} )
end

function SL:ReloadMap()
    global.Facade:sendNotification(global.NoticeTable.ReloadMap)
end

------------------------------打开、关闭相关功能界面 不开放 开放的放到UIOperator.lua------------------------------------------------
-- 打开996盒子界面 index: 1: 特权称号 2: 每日礼包 3: 超级礼包 4: 会员礼包 5: SVIP
function UIOperator:OpenBox996UI(index)
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if shiwan and tonumber(shiwan) == 1 then
        return
    end

    local Box996Proxy = global.Facade:retrieveProxy(global.ProxyTable.Box996Proxy)
    Box996Proxy:requestLogUp(Box996Proxy.BOX_UP_BTN[0])
    global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Open, {index = index})
end

-- 关闭996盒子界面
function UIOperator:CloseBox996UI()
    global.Facade:sendNotification(global.NoticeTable.Layer_Box996Main_Close)
end

-- 好评有礼
function UIOperator:OpenReviewGift()
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_ReviewGift()
end

-- 打开设置界面
function UIOperator:OpenSettingUI(data)
    global.Facade:sendNotification(global.NoticeTable.Layer_SettingFrame_Open, data)
end

-- 关闭设置界面
function UIOperator:CloseSettingUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_SettingFrame_Close)
end

-- open panel
function UIOperator:OpenPanelByID(id, parent, extent)
    local JumpProxy = global.Facade:retrieveProxy(global.ProxyTable.JumpProxy)
    return JumpProxy:OpenPanelById(id, parent, extent)
end

-- close panel
function UIOperator:ClosePanelByID(id)
    local JumpProxy = global.Facade:retrieveProxy(global.ProxyTable.JumpProxy)
    return JumpProxy:ClosePanelById(id)
end

--社区帖子
function UIOperator:OpenCommunityUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_CommunityLayer_Open)
end

function UIOperator:CloseCommunityUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_CommunityLayer_Close)
end

-- 打开交易行
function UIOperator:OpenTradingBankUI(page)
    --mac平台不能打开交易行
    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        ShowSystemTips("mac版本交易行暂不支持，请使用其他版本。")
        return
    end
    --试玩不能打开交易行
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if shiwan and tonumber(shiwan) == 1 then
        return
    end
    if global.OtherTradingBank then -- 三方 交易行
        local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
        OtherTradingBankProxy:getTradingBankStatus({}, function(code, data, msg)
            local isOpen = false
            if code == 200 then 
                if data and data.openExchange == 1 then
                    isOpen = true
                else 
                    ShowSystemTips(GET_STRING(600000179))
                end
            else 
                ShowSystemTips(msg or GET_STRING(600000660))
            end
            if isOpen then 
                local gameToken = OtherTradingBankProxy:getGameToken()
                if not gameToken or gameToken == "" or gameToken == "noToken" then 
                    ShowSystemTips(GET_STRING(600000631))
                    return 
                end 
                if global.OtherTradingBankH5 then 
                    OtherTradingBankProxy:showTradingView()
                else 
                    --是否登录
                    if OtherTradingBankProxy:getToken() == "" then 
                        OtherTradingBankProxy:Login1_2(function(code, msg)
                            if code == 200 then 
                                if OtherTradingBankProxy:getToken() ~= "" then 
                                    UIOperator:OpenTradingBankUI(page)
                                end
                            else
                                ShowSystemTips(msg or "")
                            end
                        end)
                        return 
                    end
                    OtherTradingBankProxy:doTrack(OtherTradingBankProxy.UpLoadData.TraingIconBtnClick)--没有请求成功没有appid 和 secret 上报不成功
                    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankFrame_Open_other,  {id = page} ) 
                end
                
            end
            if OtherTradingBankProxy then 
                OtherTradingBankProxy:setOpenStatus(isOpen)
            end
        end, true) 
    else
        local Box996Proxy = global.Facade:retrieveProxy( global.ProxyTable.Box996Proxy )
        Box996Proxy:requestLogUp(Box996Proxy.OTHER_UP_EVEIT[1])
        
        local mainPlayerID = SL:GetValue("USER_ID")
        if mainPlayerID then
            --摆摊状态不能打开
            if SL:GetValue("ACTOR_IS_IN_STALL",mainPlayerID) then
                ShowSystemTips(GET_STRING(600000700))
                return 
            end
        end

        --摆摊和交易行不能同时使用
        if GUI:GetWindow(nil, UIConst.LAYERID.StallLayerGUI) then
            ShowSystemTips(GET_STRING(600000701))
            return
        end

        --拍卖行和交易行不能同时使用
        if GUI:GetWindow(nil, UIConst.LAYERID.AuctionMainGUI) then
            ShowSystemTips(GET_STRING(600000702))
            return
        end

        local TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
        TradingBankProxy:getTradingBankStatus({},function(success, response, code)
            local isOpen = false
            if success then
                local data = cjson.decode(response)
                if data and data.code == 200 and data.data and data.data.status == 0 then
                    isOpen = true
                end
            end
            if isOpen then
                global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankFrame_Open, {id = page})
            else
                ShowSystemTips(GET_STRING(600000179))
            end
            if TradingBankProxy then 
                TradingBankProxy:setOpenStatus(isOpen)
            end
        end)
    end
    
end

-- 关闭交易行
function UIOperator:CloseTradingBankUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankFrame_Close)
end

-- 打开客服UI
function UIOperator:OpenKefuUI()
    global.modBridgeController:GN_kefu()
end

function SL:ClearInviteItemsById(UserId)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:ClearInviteItemsById(UserId)
end
function SL:ClearInviteItems()
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:ClearInviteItems()
end
function SL:CloseTradeUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_Trade_Close)
end

-- 添加登录角色页交易行锁定相关
function SL:OpenLoginTradeLockUI()
    local roles = SL:GetValue("LOGIN_ROLE_DATAS")
    local showLock = false
    if roles and #roles > 0 then
        for i, v in ipairs(roles) do
            if v.LockChar and (v.LockChar == 1 or v.LockChar == 3) then
                showLock = true
            elseif v.newChar and v.newChar == 1 then
                showLock = true
            end
        end
        if showLock then 
            global.Facade:sendNotification(global.NoticeTable.Layer_Login_RoleLock_Open)
        end
    end
end

-- 关闭登录角色页交易行锁定相关
function SL:CloseLoginTradeLockUI()
    global.Facade:sendNotification(global.NoticeTable.Layer_Login_RoleLock_Close)
end
--------------------------------------------------------------------------------------------------------------

--关闭他人人物 子页签
function SL:CloseTradingBankPlayerPageUI(data)
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBank_Look_Player_Child_Del,data)
end

--关闭他人英雄 子页签
function SL:CloseTradingBankHeroPageUI(data)
    global.Facade:sendNotification(global.NoticeTable.Layer_TradingBank_Look_Player_Child_Del_Hero,data)
end
-------

-- 交易行查看他人界面
function SL:CloseTradingBankLookInfoUI()
    if global.OtherTradingBank then 
        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankPlayerInfo_Close_other)
    else
        global.Facade:sendNotification(global.NoticeTable.Layer_TradingBankPlayerInfo_Close)
    end
end
--------------------------------------------------------------------------------------------------------------------------------
function SL:OpenGuideEnter(param)
    SLBridge:onLUAEvent(LUA_EVENT_GUIDE_ENTER_TRANSITION, {name = "GUIDE_BEGIN_SKILL_BUTTON", extent = param})
end
function SL:CloseGuideEnter()
    SLBridge:onLUAEvent(LUA_EVENT_GUIDE_ENTER_TRANSITION, {name = "GUIDE_BEGIN_SKILL_CHANGE_BUTTON"})
end

-- 任务栏打开
function SL:OpenAssistUI()
    SL:SetTaskBarState({status = false})
end
function SL:CloseAssistUI()
    SL:SetTaskBarState({status = true})
end

-- 小地图伸缩
function SL:OpenMiniMapChangeUI()
    SL:onLUAEvent(LUA_EVENT_MAIN_MINIMAP_SHOW_STATUS, true)
end
function SL:CloseMiniMapChangeUI()
    SL:onLUAEvent(LUA_EVENT_MAIN_MINIMAP_SHOW_STATUS, false)
end

-- 直接调用支付
function SL:OpenCallPayUI()
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_PC_CallOF()
end

------------------------------打开、关闭相关功能界面------------------------------------------------

---------------------------------------------------------------------------
-- 通用弹窗
-- 道具拆分弹窗
function SL:OpenItemSplitPop(itemData)
    if not BagData.isToBeFull(true) then
        local bagItemData = BagData.GetItemDataByMakeIndex(itemData.MakeIndex)
        local data = {
            itemData = bagItemData,
            closeCB = function()
                UIOperator:CloseItemTips()
            end
        }
        UIOperator:OpenTipsSplit(data)
    end
end

-- 打开网址/链接
function SL:OpenURL(url)
    if not url or string.len(url) == 0 then
        return
    end
    cc.Application:getInstance():openURL(url)
end

---------------------------------------------------------------------------
-- 引导
-- 打开引导
function SL:StartGuide(data)
    UIOperator:OpenGuideUI(data)
end

-- 关闭引导
function SL:CloseGuide()
    SL:onLUAEvent(LUA_EVENT_GUIDE_EXIT)
end

---------------------------------------------------------------------------
-- 战斗相关
-- 快速选择目标
function SL:QuickSelectTarget(data)
    SLBridge:onLUAEvent(LUA_EVENT_QUICK_SELECT_TARGET, data)
end
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 本地存储
-- 存储字符到本地
function SL:SetLocalString(key, value)
    SL.LocalStringCache[key] = value

    if SL.LocalStringTimerID then
        SL:UnSchedule(SL.LocalStringTimerID)
        SL.LocalStringTimerID = nil
    end
    SL.LocalStringTimerID = SL:ScheduleOnce(function()
        SL.LocalStringTimerID = nil
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local playerID = LoginProxy:GetSelectedRoleID() or "errorID"
        local userData = UserData:new("GUIStorage" .. playerID)
        for k, v in pairs(SL.LocalStringCache) do
            userData:setStringForKey(k, v)
        end
        userData:writeMapDataToFile()
    end, 0.5)
end

-- 从本地读取字符
function SL:GetLocalString(key)
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local playerID = LoginProxy:GetSelectedRoleID() or "errorID"
    local userData = UserData:new("GUIStorage" .. playerID)
    return userData:getStringForKey(key, "")
end

function SL:CreateLocalData(name, key, value)
    if not name or string.len(name) == 0 then
        return
    end
    local localData = UserData:new(name)
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    if key and value and type(value) == "string" then
        local flag = proxy:GetSelectedRoleID() or "errorID"
        localData:setStringForKey(key .. flag, value)
    end
end

function SL:GetLocalData(name, key)
    if not name or string.len(name) == 0 then
        return nil
    end
    local localData = UserData:new(name)
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    if key then
        local flag = proxy:GetSelectedRoleID() or "errorID"
        return localData:getStringForKey(key .. flag, "")
    end
    return nil
end
-- 本地存储
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- ITEM ITEMTIPS
-- 检测人物是否可穿戴
-- FIXME: 移动至GUIFunction
function SL:CheckItemUseNeed_Hero(itemData)
    local canUse, conditionStr, notCheckUse = CheckItemUseNeed_Hero(itemData)
    return {
        canUse = canUse, conditionStr = conditionStr, notCheckUse = notCheckUse
    }
end
function SL:CheckItemUseNeed(itemData)
    local canUse, conditionStr, notCheckUse = CheckItemUseNeed(itemData)
    return {
        canUse = canUse, conditionStr = conditionStr, notCheckUse = notCheckUse
    }
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 注册控件事件
function SL:RegisterWndEvent(widget, desc, msgtype, callback)
    SLHandlerEvent:RegisterWndEvent(widget, desc, msgtype, callback)
end
-- 取消控件事件
function SL:UnRegisterWndEvent(widget, desc, msgtype)
    SLHandlerEvent:UnRegisterWndEvent(widget, desc, msgtype)
end

-- 添加窗体控件自定义属性
function SL:AddWndProperty(widget, desc, key, value)
    SLHandlerEvent:AddWndProperty(widget, desc, key, value)
end

-- 删除窗体控件自定义属性
function SL:DelWndProperty(widget, desc, key)
    SLHandlerEvent:DelWndProperty(widget, desc, key)
end

-- 获取窗体控件自定义属性
function SL:GetWndProperty(widget, desc, key)
    return SLHandlerEvent:GetWndProperty(widget, desc, key)
end

---------------------------------------------------------------------------
-- 交易对方金币改变播放音效
function SL:PlayMoneyChangeAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_MONEY
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end
-- 播放按钮点击音效
function SL:PlayBtnClickAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_BTN_CLICK
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放登陆-开门音效
function SL:PlayLoginOpenDoorAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_LOGIN_DOOR
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放登陆-选角音效
function SL:PlaySelectRoleAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_LOGIN_SELECTONE
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放开宝箱音效
function SL:PlayOpenBoxAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_OPEN_BOX
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放宝箱内选中音效
function SL:PlayFlashBoxAudio()
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLASH_BOX
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放NPC音效
function SL:PlayNpcTalkAudio(id)
    local slt = global.SLT.AudioPlayTable3
    slt.type = global.MMO.SND_TYPE_NPC_TALK
    slt.index = id
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
end

-- 播放音效
function SL:PlaySound(id, isLoop)
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, {type = global.MMO.SUD_TYPE_NORMAL, index = id, isLoop = isLoop})
end
-- 播放点击道具音效
function SL:PlayClickItemSound(itemData)
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, {type = global.MMO.SND_TYPE_CLICK_ITEM, param=itemData})
end
-- 停止音效
function SL:StopSound(id)
    global.Facade:sendNotification(global.NoticeTable.Audio_Stop_EffectId, id)
end

-- 停止所有音效
function SL:StopAllAudio()
    global.Facade:sendNotification(global.NoticeTable.Audio_Stop_All)
end

-- 播放BGM
function SL:PlayAudioBGMByType(type)
    global.Facade:sendNotification(global.NoticeTable.Audio_Play_BGM, {type = type})
end

-- 播放BGM path: 音频文件路径
function SL:PlayAudioBGMByPath(path)
    global.Facade:sendNotification(global.NoticeTable.Audio_Play_BGM, {path = path})
end

-- 暂停BGM
function SL:PauseAudioBGM()
    global.Facade:sendNotification(global.NoticeTable.Audio_Pause_BGM)
end

-- 恢复BGM
function SL:ResumeAudioBGM()
    global.Facade:sendNotification(global.NoticeTable.Audio_Resume_BGM)
end

-- 停止BGM
function SL:StopAudioBGM()
    global.Facade:sendNotification(global.NoticeTable.Audio_Stop_BGM)
end

---------------------------------------------------------------------------
-- 聊天

-- FIXME: 考虑放到聊天模块代码
-- 物品数据转化 -聊天装备展示
function SL:TransItemDataIntoChatShow(itemData)
    return clone(ChangeItemServersSendDatas(itemData))
end

function SL:ShowActorSay(data)
    global.Facade:sendNotification(global.NoticeTable.ActorSay, data)
end

-- 新增掉落消息
local shareDropParams = {}
function SL:AddDropChatMsgShow(data)
    if not data or not data.dropType then
        SL:Print("[SL ERROR] SL:AddDropChatMsgShow param dropType is nil.")
        return 
    end
    shareDropParams.Msg         = data.Msg or ""
    shareDropParams.FColor      = data.FColor or 255
    shareDropParams.BColor      = data.BColor or 255
    shareDropParams.ChannelId   = GUIDefine.ChatChannel.DROP
    shareDropParams.textType    = GUIDefine.ChatTextType.SRTEXT
    shareDropParams.dropType    = data.dropType
    ChatData.AddChatItem(shareDropParams)
end

-- 聊天
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 资源下载
function SL:DownLoadRes(path, url, downloadCB)
    if path and path ~= "" then
        path = string.gsub(tostring(path), "\\", "/")
        path = string.gsub(tostring(path), " ", "")
    end
    if not url or string.len(url) == 0 then
        global.ResDownloader:download(path, function(isOK)
            if downloadCB then
                downloadCB(isOK)
            end
        end)
        return
    end
    url = string.gsub(tostring(url), "\\", "/")
    url = string.gsub(tostring(url), " ", "")
    global.ResDownloader:downloadEx(path, url, function(isOK)
        if isOK and downloadCB then
            downloadCB()
        end
    end)
end

-- 下载小地图
function SL:DownloadMiniMapRes(minimapId, callback)
    local miniMapPath = ""
    if SL:GetValue("GAME_DATA", "NoLimitMiniMapIDFile") == 1 then
        miniMapPath = string.format("scene/uiminimap/%s.png", minimapId)
    else
        -- ? 减1是保留老三端逻辑暂不动 ?
        miniMapPath = string.format("scene/uiminimap/%06d.png", tonumber(minimapId) - 1)
    end

    global.ResDownloader:download(miniMapPath, function(isOK)
        callback(isOK, miniMapPath)
    end)
end

-----脚本变量额外属性 添加监听更新
---@param needSimpleNum boolean 是否需要简单数字格式化 [只处理单独数值变量]
function SL:CustomAttrWidgetAdd(metaValue, widget, needSimpleNum)
    global.Facade:sendNotification(global.NoticeTable.CustomAttrWidgetAdd, {metaValue = metaValue , widget = widget, simplenum = needSimpleNum and 1 or 0})
end

-- 用于检测goodsitem 是否在listview 并且可视
function SL:CheckNodeCanCallBack(node, mousePos, checkLevel)
    return CheckNodeCanCallBack(node, mousePos, checkLevel)
end

---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- id 必须唯一 name 按钮名字 func 跳转函数
function SL:AddUpgradeBtn(id, name, func)
    local RemindUpgradeProxy = global.Facade:retrieveProxy(global.ProxyTable.RemindUpgradeProxy)   
    RemindUpgradeProxy:RefData(id, true,{id = id, name = name, func = func})
end

function SL:RemoveUpgradeBtn(id)
    local RemindUpgradeProxy = global.Facade:retrieveProxy(global.ProxyTable.RemindUpgradeProxy)   
    RemindUpgradeProxy:RefData(id, false)
end

---------------------------------------------------------------------------

---------------------------------------------------------------------------
----- 鼠标模拟事件 ---------------------------------------------------------
-- 模拟左键点击触发左键点击事件
function SL:WinClick(widget)
    if not widget or tolua.isnull(widget) then
        return false
    end
    if type(widget._clickCallBack_) == "function" then
        widget._clickCallBack_()
    elseif type(widget._touchCallBack_) == "function" then
        widget._touchCallBack_()
    end
end

---------------------------------------------------------------------------
-- 坐标转换
function SL:ConvertWorldPos2MapPos(worldX, worldY)
    return global.sceneManager:WorldPos2MapPos(worldX, worldY)
end

function SL:ConvertMapPos2WorldPos(mapX, mapY, centerOfGrid)
    return global.sceneManager:MapPos2WorldPos(mapX, mapY, centerOfGrid)
end

function SL:ConvertWorldPos2Screen(worldX, worldY)
    SharedPoint.x = worldX
    SharedPoint.y = worldY
    return World2Screen(SharedPoint)
end

function SL:ConvertScreen2WorldPos(screenX, screenY)
    SharedPoint.x = screenX
    SharedPoint.y = screenY
    return Screen2World(SharedPoint)
end

---------------------------------------------------------------------------
-- 添加TXT控件
function SL:AttachTXTSUI(data)
    global.Facade:sendNotification(global.NoticeTable.SUIComponentAttach, data)
end

-- 移除TXT控件
function SL:UnAttachTXTSUI(data)
    global.Facade:sendNotification(global.NoticeTable.SUIComponentDetach, data)
end

-- 挂接/卸载GUI_lua控件
-- param {index = 挂接ui编号, subid = 内容编号, content = 内容, type = 类型(0/nil: 添加; 1: 删除)}
function SL:AttachOrUnAttachGUI(data)
    global.Facade:sendNotification(global.NoticeTable.GUIComponentAttachOrDetch, data)
end

SL.AttachOrUnAttachSUI = SL.AttachOrUnAttachGUI

-- 震屏
function SL:ShakeScene(time, distance)
    local data = {
        time = time,
        distance = distance
    }
    global.Facade:sendNotification( global.NoticeTable.ShakeScene, data)
end

-- 获取16高位
function SL:GetH16Bit(value)
    return H16Bit(value)
end

-- 获取16低位
function SL:GetL16Bit(value)
    return L16Bit(value)
end

-- 添加地图特效
function SL:AddMapSpecialEffect(ID, mapID, sfxId, x, y, loop, showType, num)
    if not ID or not mapID or not sfxId then
        return
    end
    SL.CustomMapEffects = SL.CustomMapEffects or {}
    SL.CustomMapEffects[mapID] = SL.CustomMapEffects[mapID] or {}

    if type(loop) ~= "boolean" then
        loop = true
    end
    local item = {
        sfxId = sfxId,
        x = x,
        y = y,
        loop = loop,
        isBehind = tonumber(showType) == 0,
        isFront = tonumber(showType) == 1,
        num = num
    }
    SL.CustomMapEffects[mapID][ID] = item

    local curMapID = SL:GetValue("MAP_ID")
    if curMapID == mapID then
        local isInit  = false
        local actorID = ID
        local mapX = item.x
        local mapY = item.y
        local sfxActor = global.actorManager:GetActor(actorID)
        if not sfxActor then
            isInit = true
            local paramSfx  = {}
            paramSfx.sfxId  = item.sfxId
            paramSfx.isLoop = item.loop
            paramSfx.type   = global.MMO.EFFECT_TYPE_SFX
            paramSfx.num    = item.num
            sfxActor = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_SEFFECT, paramSfx, item.isBehind, item.isFront)
        end

        local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
        sfxActor:setPosition(wX, wY)
        global.actorManager:SetActorMapXY(sfxActor, mapX, mapY)

        global.Facade:sendNotification( global.NoticeTable.DelayDirtyFeature, actorID)

        if isInit then
            global.sceneEffectManager:AddSceneEffect(sfxActor)
        end
    end
end

-- 删除地图特效
function SL:RmvMapSpecialEffect(ID, mapID)
    if not ID or not mapID then
        return
    end

    local curMapID = SL:GetValue("MAP_ID")
    if curMapID == mapID then
        global.sceneEffectManager:RmvSceneEffect(ID)
        global.actorManager:RemoveActor(ID)
    end

    if SL.CustomMapEffects and SL.CustomMapEffects[mapID] then
        SL.CustomMapEffects[mapID][ID] = nil
    end

end


--- 添加actor特效
---@param actorID string actor id
---@param sfxID integer 特效id
---@param isFront boolean 是否在模型前  默认在前面
---@param offX integer x偏移
---@param offY integer y偏移
---@param count integer 播放次数
---@param finishCallBack function 播放完毕结束回调
function SL:AddActorEffect(actorID, sfxID, isFront, offX, offY, count, finishCallBack)
    -- body
    if isFront == nil then
        isFront = true
    end
    local data =
    {
        actorID = actorID,
        sfxID   = tonumber(sfxID),
        frame   = 0,
        speed   = 1,
        count   = count or 0,
        front   = isFront,
        offsetX = offX or 0,
        offsetY = offY or 0,
        finishCallBack = finishCallBack
    }
    global.ActorEffectManager:AddEffect(data)
end

--- 删除actor特效
---@param actorID string actor id
---@param sfxID integer 特效id
function SL:RmvActorEffect(actorID, sfxID)
    -- body
    local data  = {
        actorID = actorID,
        sfxID   = sfxID,
    }
    global.ActorEffectManager:RmvEffect(data)
end
---------------------------------------------------------------------------

function SL:ActorPickerMouseRightBeganEvent(touch)
    global.actorPickerController:HandleTouchEndEvent(touch, global.MMO.MOVE_EVENT_MOUSE_R, cc.Handler.EVENT_TOUCH_BEGAN)
end

function SL:ActorPickerMouseLeftBeganEvent(touch)
    global.actorPickerController:HandleTouchEndEvent(touch, global.MMO.MOVE_EVENT_TOUCH_AND_MOUSE_L, cc.Handler.EVENT_TOUCH_BEGAN)
end

function SL:MouseMoveWorldEvent(touch)
    global.actorPickerController:MouseMoveWorldEvent(touch)
end

function SL:KeepMovingBegin(touch)
    local data = {
        way = global.MMO.MOVE_EVENT_MOUSE_R,
        pos = touch
    }
    global.Facade:sendNotification(global.NoticeTable.keepMovingBegin, data)
end

function SL:KeepMovingUpdate(touch)
    local data = {
        way = global.MMO.MOVE_EVENT_MOUSE_R,
        pos = touch
    }
    global.Facade:sendNotification(global.NoticeTable.keepMovingUpdate, data)
end

function SL:MouseMoveEvent(data)
    -- 除开window端手动发送鼠标事件 模拟点击
    if not global.isWinPlayMode and data then
        local mouseEventType_Down = 1
        local mouseButtonType_right = 1
        local mouseEvent = cc.EventMouse:new(mouseEventType_Down)
        mouseEvent:setCursorPosition(data.x,data.y)
        mouseEvent:setMouseButton(mouseButtonType_right)
        mouseEvent.specialRight = true
        global.EventDispatcher:dispatchEvent(mouseEvent)
    end
end

function SL:KeepMovingEnded()
    global.Facade:sendNotification(global.NoticeTable.keepMovingEnded)
end

--移动的道具 更新属性
function SL:ItemMoveUpdate(data)
    if data and data.pos then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_MOVING, data)
    else 
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_UP_DATA, data)
    end
end

--移动的道具 检测
function SL:ItemMoveCheck(data)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:CheckAndCallBack(data)
end

--检查是否叠加物
function SL:CheckItemOverLap(item)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    return ItemConfigProxy:CheckItemOverLap(item)
end

--检查是否绑定
function SL:CheckItemBind(Index)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    return ItemConfigProxy:CheckItemBind(Index)
end

--背包数据改变延迟通知
function SL:BagDataDelayNotice(isHero)
    if isHero then
        global.Facade:sendNotification(global.NoticeTable.HeroBag_Oper_Data_Delay)
    else
        global.Facade:sendNotification(global.NoticeTable.Bag_Oper_Data_Delay)
    end
end

-- 添加红点 
--[[ data : table
    {
        add     = 状态,     -- 1添加 0删除
        mainId  = 主窗口ID,
        uiId    = 按钮ID, 
        x       = X坐标, 
        y       = Y坐标, 
        mode    = 模式,     -- 0图片 1特效
        res     = 图片路径或特效编号,
    }
--]]
function SL:AddRedDot(data)
    local RedDotProxy = global.Facade:retrieveProxy(global.ProxyTable.RedDotProxy)
    RedDotProxy:SetBagRedDotByData(data)
    UIOperator:RefreshRedDot(data)
end

--删除背包红点
function SL:DeleteBagRedDot(makeIndex)
    local RedDotProxy = global.Facade:retrieveProxy(global.ProxyTable.RedDotProxy)
    RedDotProxy:DeleteBagRedDot(makeIndex)
end

--物品更新通知
function SL:ItemUpdateNotice(item)
    global.Facade:sendNotification(global.NoticeTable.ItemUpdate, item)
end

--清理自动挖矿
function SL:ClearAutoMining()
    local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    AutoProxy:ClearAutoMining()
end

-- 是否禁止打开背包、装备
function SL:IsForbidOpenBagOrEquip()
    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    return NPCProxy:IsForbidOpenBagEquip()
end

-- 设置任务栏状态
function SL:SetTaskBarState(param)
    if MainAssist and MainAssist.ChangeHideStatus then
        MainAssist.ChangeHideStatus(param)
    end
end

-------------------- 废弃代码 (暂保留, 避免报错) --------------------
-- 添加装备红点
function SL:PlayerEquipUILoadSuccessAddRed()
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 添加装备红点
function SL:HeroEquipUILoadSuccessAddRed()
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 性别改变
function SL:SexChangeAddRed(ishero)
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 玩家界面加载成功 添加红点
function SL:OnPlayerFrameLoadSuccessAddRed()
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 英雄界面加载成功 添加红点
function SL:OnHeroFrameLoadSuccessAddRed()
    -- local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 玩家装备初始化完成 添加红点
function SL:OnPlayEquipInitAddRed()
    -- local ConditionProxy  = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end

-- 英雄装备初始化完成 添加红点
function SL:OnHeroEquipInitAddRed()
    -- local ConditionProxy  = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
    -- if ConditionProxy then 
    --     ConditionProxy:StartCheck()
    -- end
end
-------------------------------------------------------------------

-- 释放技能
function SL:OnLaunchSkill(skillID)
    if SL:GetValue("IS_PC_OPER_MODE") then
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)

        -- 开关技能
        if SkillProxy:IsOnoffSkill(skillID) then
            return SkillProxy:RequestSkillOnoff(skillID)
        end
        
        -- 技能释放
        local destPosX, destPosY = inputProxy:GetCursorMapPosition()
        global.Facade:sendNotification(global.NoticeTable.UserInputLaunch, {skillID = skillID, destPosX = destPosX, destPosY = destPosY})
    else
        if skillID == 0 and GUIFunction:CheckMiningAble() then
            -- 无用操作
            -- local mainPlayer = global.gamePlayerController:GetMainPlayer()
            -- global.Facade:sendNotification(global.NoticeTable.UserInputMining, {destX = mainPlayer:GetMapX(), destY = mainPlayer:GetMapY()})
        else
            global.Facade:sendNotification(global.NoticeTable.UserInputLaunch, {skillID = skillID, priority = global.MMO.LAUNCH_PRIORITY_USER})
        end
    end
end

-- 清理释放技能
function SL:ClearLaunchFirstSkill()
    local autoProxy = global.Facade:retrieveProxy( global.ProxyTable.AutoProxy )
    autoProxy:ClearLaunchFirstSkill()
end

-- 清理输入状态
function SL:ClearAllInputState()
    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
end

--1行会 2地图 3组队
function SL:RmEffectOnScreen(index)
    local mediator = global.Facade:retrieveMediator("NoticeMediator")
    if mediator:GetEffectsData()[index] then
        for _, v in ipairs(mediator:GetEffectsData()[index]) do
            global.Facade:sendNotification(global.NoticeTable.Layer_Notice_RemoveChild, tostring(v))
        end
        mediator:GetEffectsData()[index] = {}
    end
end

--PC设置分辨率
function SL:SetPCResolutionSize(data)
    global.Facade:sendNotification( global.NoticeTable.ResolutionSizeChange, data )
end

-- 删除技能键
function SL:DeleteSkillKey(skillID)
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:DelSkillKey(skillID)
end

--摆摊增加我卖的数据
function SL:StallAddItemToSell(data)
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    StallProxy:AddItemIntoList(data)
end

--清理我卖的数据
function SL:StallCleanMySellData()
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    StallProxy:CleanMySellData()
end

--删除我卖的数据
function SL:StallRmvMySellItem(makeIndex)
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    return StallProxy:RmvMySellItem(makeIndex)
end

-- 拍卖行清理
function SL:AuctionClear()
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    AuctionProxy:Clear()
end

-- 角度转方向
function SL:ConverAngleToDirection(angle)
    return G_ActorUtils.ConverAngleToDirection(angle)
end

-- 主玩家移动，取消交易
function SL:CancelTradeInMoving()
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:CheckPlayerMove() 
end

---------------------------------------------------------------
---------------------------------------------------------------
-- 重置出售状态
function SL:ResetSellingState()
    local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
    NPCSellProxy:ResetSellingState()
end

-- 重置修理状态
function SL:ResetRepairingState()
    local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
    NPCRepaireProxy:ResetRepairingState()
end

-- 清除自定义数据
function SL:CleanOnDoData()
    local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
    NPCDoSomethingProxy:CleanOnDoData()
end

-- npc仓库整理
function SL:ArrangeStorageData(data)
    local npcStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    npcStorageProxy:ArrangeStorageData(data)
end

-- 仓库删除物品
function SL:DeleteStorageData(item)
    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    NPCStorageProxy:DeleteStorageData(item)
end

-- 仓库更新物品
function SL:UpdateStorageData(item)
    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    NPCStorageProxy:UpdateItem(item)
end
---------------------------------------------------------------

-- 挖
local digDestPos = cc.p(0, 0)
function SL:ToDoDig(targetID)
    if not targetID then
        return false
    end

    local target = global.actorManager:GetActor(targetID)
    if not target then
        return false
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)

    local authProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    authProxy:ClearAutoLock()
    authProxy:ClearAllState()
    authProxy:ClearAFKState()

    digDestPos.x, digDestPos.y = global.sceneManager:MapPos2WorldPos(target:GetMapX(), target:GetMapY(), true)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:SetDigDest(digDestPos)
end

function SL:AutoFindCollection()
    global.Facade:sendNotification(global.NoticeTable.AutoFindCollection)
end

-----------------------------------------------------------------
-- 获取纹理
function SL:GetTextureForKey(path)
    global.TextureCache:getTextureForKey(path)
end

-- 移除纹理
function SL:RemoveTextureForKey(path)
    global.TextureCache:removeTextureForKey(path)
end

-----------------------------------------------------------------
-- base编码
function SL:Base64Encode(str)
    if not str then
        return ""
    end

    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local s64 = ''

    while #str > 0 do
        local bytes_num = 0
        local buf = 0

        for byte_cnt=1,3 do
            buf = (buf * 256)
            if #str > 0 then
                buf = buf + string.byte(str, 1, 1)
                str = string.sub(str, 2)
                bytes_num = bytes_num + 1
            end
        end

        for group_cnt=1,(bytes_num+1) do
            local b64char = math.fmod(math.floor(buf/262144), 64) + 1
            s64 = s64 .. string.sub(b64chars, b64char, b64char)
            buf = buf * 64
        end

        for fill_cnt=1,(3-bytes_num) do
            s64 = s64 .. '='
        end
    end

    return s64
end
-- base64解码
function SL:Base64Dec(data)
    return Base64dec(data)
end

-- 解析特效配置
function SL:ParseModelEffect(effect)
    return ParseModelEffect(effect)
end

-----------------------------------------------------------------
--解包操作
function SL:UnpackDrugByIndex(itemIndex, ignoreCount)
    return proxyUtils.UnpackDrugByIndex(itemIndex, ignoreCount)
end

function SL:UnpackDrugByIndexHero(itemIndex, ignoreCount, notuse)
    return proxyUtils.UnpackDrugByIndex_Hero(itemIndex, ignoreCount, notuse)
end

------------------------------------------------------------------
-- 字符串分析
function SL:LexicalHelperParse(str)
    local LexicalHelper = require("sui/LexicalHelper")
    return LexicalHelper:Parse(str)
end
------------------------------------------------------------------
-- 文件名处理
function SL:SUIHelperFixImageFileName(path)
    local SUIHelper = require("sui/SUIHelper")
    return SUIHelper.fixImageFileName(path)
end
------------------------------------------------------------------

-------------------------------------------------------------------
-- 交易行相关登录操作
function SL:DoTradingBankLoginOperations()
    if global.OtherTradingBank then 
        local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
        OtherTradingBankProxy:setLoginSuccessTimes()
    else
        if global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") ~= 1 then 
            local TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
            TradingBankProxy:clearToken()
        end
    end
end

-- 保存本地登录数据
function SL:SaveLoginLocalData()
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:SaveLocalData()
end

-- 账号页设置分辨率 isReset: 重置
function SL:ChangeDebugResolutionSize(isReset, width, height)
    if not SL._DEBUG then
        return
    end
    if isReset then
        local userData = UserData:new("phone_mode_device")
        local key      = global.isWinPlayMode and "pc" or "phone"
        userData:setStringForKey(key, nil)
        userData:writeMapDataToFile()
        SL:ExitToLoginUI()
    elseif width and height then
        if width ~= global.DesignSize_Win.width or height ~= global.DesignSize_Win.height then
            local userData = UserData:new("phone_mode_device")
            local key      = global.isWinPlayMode and "pc" or "phone"
            local value    = cjson.encode({width = width, height = height})
            userData:setStringForKey(key, value)
            userData:writeMapDataToFile()
            SL:ExitToLoginUI()
        end
    end
end

function SL:GetDebugResolutionSize()
    if SL._DEBUG then
        local userData = UserData:new("phone_mode_device")
        local cjson    = require("cjson")
        local key      = global.isWinPlayMode and "pc" or "phone"
        local jsonStr  = userData:getStringForKey(key, "")
        if jsonStr and string.len(jsonStr) > 0 then
            local size = cjson.decode(jsonStr)
            size.width = ConvertToEven(size.width)
            size.height = ConvertToEven(size.height)
            return size
        end
    end
    return nil
end

-- 切换游戏状态到角色
function SL:SwitchGameStateToRole()
    global.Facade:sendNotification(global.NoticeTable.ChangeGameState, global.MMO.GAME_STATE_ROLE)
end
------------------------------------------------------------------
-- 
function SL:InputLaunch(data)
    global.Facade:sendNotification(global.NoticeTable.InputLaunch, data)
end

function SL:InputMove(data)
    global.Facade:sendNotification(global.NoticeTable.InputMove, data)
end

function SL:InputMining(data)
    global.Facade:sendNotification(global.NoticeTable.InputMining, data)
end

function SL:ClearInputLaunch()
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:ClearLaunch()
end

function SL:ResetInputLaunchDirty()
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:ResetLaunchDirty()
end

------------------------------------------------------------------
-- HUD相关刷新 [主动触发]
-- HUDLabel 行会角色名等信息
function SL:OnRefreshActorHUDLabel(actorID)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel, actorID)
end

-- HUDLabel Color
function SL:OnRefreshActorHUDLabelColor(actorID)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabelColor, actorID)
end

-- HUDTitle 称号封号
function SL:OnRefreshActorHUDTitle(actorID)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDTitle, actorID)
end

-- HUDBar 血条蓝条内功条偏移坐标
function SL:OnRefreshActorHUDBarOffset(actorID)
    global.HUDManager:RefreshHUDBarOffset(actorID)
end

-- HUD HPLabel 血量
function SL:OnRefreshActorHUDHPLabel(actorID)
    if not actorID then
        return
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end

    global.HUDHPManager:Update(actor)
end

------------------------------------------------------------------
-- 直接飘血 [不加入队列]
local shareThrowTab = {}
function SL:ThrowDamageNumImmediate(actorID, id, damageNum)
    shareThrowTab.actorID = actorID
    shareThrowTab.Id = id
    shareThrowTab.Power = damageNum
    global.Facade:sendNotification(global.NoticeTable.SLThrowDamageNum, shareThrowTab)
end

------------------------------------------------------------------
-- 交易行测试截图是否报错 pc端可以调用调试 报错的话可以查看控制台日志,图片可以在当前项目cache中
function SL:TradingTestCapture()
    local data = {}
    data.action = "screenshots"
    data.type = "role"
    data.testCapture = true
    global.Facade:sendNotification(global.NoticeTable.TradingBank_other_Capture,{datatype = data})
end

-- 交易行lua自定义截图
---@param open  function    打开当前页面
---@param close function    关闭当前页面
---@param getNode function  返回一个当前页面父节点panel，会截图这个父节点上所有子节点，并且这个父节点可以获取到getContentSize的可视截图大小
function SL:AddTradingCustomCaptureTaskLua(open, close, getNode)
    local data  = {
        open = function()
            open()
        end,
        close = function()
            close()
        end,
        getNode = getNode
    }
    table.insert(SL.TradingCustomCaptureLua, data)
end

-- 删除交易行lua截图任务
function SL:RemoveTradingCustomCaptureTask()
    SL.TradingCustomCaptureLua = {}
end

-- 调用sdk接口打开第三方应用   需sdk实现
function SL:OpenThirdApp(data)
    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    if NativeBridgeProxy then
        NativeBridgeProxy:GN_Third_APP( data )
    end
end

------------------------------------------------------------------
-- 地图点阻挡
-- 加
function SL:AddMapObstacle(x, y)
    if not x then
        ErrorDebugPrint("[SL ERROR] SL:AddMapObstacle, x is nil")
        return
    end
    if not y then
        ErrorDebugPrint("[SL ERROR] SL:AddMapObstacle, y is nil")
        return
    end

    global.ObstacleController:AddRef(x, y)
end

-- 删
function SL:DecMapObstacle(x, y)
    if not x then
        ErrorDebugPrint("[SL ERROR] SL:DecMapObstacle, x is nil")
        return
    end
    if not y then
        ErrorDebugPrint("[SL ERROR] SL:DecMapObstacle, y is nil")
        return
    end

    global.ObstacleController:DecRef(x, y)
end

------------------------------------------------------------------