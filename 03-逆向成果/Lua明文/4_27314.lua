
function handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
    if type(t) == "userdata" then
        local peer = tolua.getpeer(t)
        if not peer then
            peer = {}
            tolua.setpeer(t, peer)
        end
        setmetatableindex_(peer, index)
    else
        local mt = getmetatable(t)
        if not mt then mt = {} end
        if not mt.__index then
            mt.__index = index
            setmetatable(t, mt)
        elseif mt.__index ~= index then
            setmetatableindex_(mt, index)
        end
    end
end

setmetatableindex = setmetatableindex_
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, ...)
    local cls = {__cname = classname}

    local supers = {...}
    for _, super in ipairs(supers) do
        local superType = type(super)
        assert(superType == "nil" or superType == "table" or superType == "function",
            string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
                classname, superType))

        if superType == "function" then
            assert(cls.__create == nil,
                string.format("class() - create class \"%s\" with more than one creating function",
                    classname));
            -- if super is function, set it to __create
            cls.__create = super
        elseif superType == "table" then
            if super[".isclass"] then
                -- super is native class
                assert(cls.__create == nil,
                    string.format("class() - create class \"%s\" with more than one creating function or native class",
                        classname));
                cls.__create = function() return super:create() end
            else
                -- super is pure lua class
                cls.__supers = cls.__supers or {}
                cls.__supers[#cls.__supers + 1] = super
                if not cls.super then
                    -- set first super pure lua class as class.super
                    cls.super = super
                end
            end
        else
            error(string.format("class() - create class \"%s\" with invalid super type",
                        classname), 0)
        end
    end

    cls.__index = cls
    if not cls.__supers or #cls.__supers == 1 then
        setmetatable(cls, {__index = cls.super})
    else
        setmetatable(cls, {__index = function(_, key)
            local supers = cls.__supers
            for i = 1, #supers do
                local super = supers[i]
                if super[key] then return super[key] end
            end
        end})
    end

    if not cls.ctor then
        -- add default constructor
        cls.ctor = function() end
    end
    cls.new = function(...)
        local instance
        if cls.__create then
            instance = cls.__create(...)
        else
            instance = {}
        end
        setmetatableindex(instance, cls)
        instance.class = cls
        instance:ctor(...)
        return instance
    end
    cls.create = function(_, ...)
        return cls.new(...)
    end

    return cls
end


------------------------------------------------------
cc = cc or {}

cc.Color3B = 
{
    WHITE   = { r = 255, g = 255, b = 255 },
    YELLOW  = { r = 255, g = 255, b =   0 },
    GREEN   = { r =   0, g = 255, b =   0 },
    BLUE    = { r =   0, g =   0, b = 255 },
    RED     = { r = 255, g =   0, b =   0 },
    MAGENTA = { r = 255, g =   0, b = 255 },
    BLACK   = { r =   0, g =   0, b =   0 },
    ORANGE  = { r = 255, g = 127, b =   0 },
    GRAY    = { r = 166, g = 166, b = 166 },
}
------------------------------------------------------


-------------------------------------------------------
function Schedule(callback, interval)
    return cc.Director:getInstance():getScheduler():scheduleScriptFunc(callback, interval, false)
end

function UnSchedule(scheduleID)
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(scheduleID)
end

function PerformWithDelayGlobal(listener, time)
    local handle
    handle =
        cc.Director:getInstance():getScheduler():scheduleScriptFunc(
        function()
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(handle)
            listener()
        end,
        time,
        false
    )
    return handle
end

function ReportBuglyError(tag, content)
    local tagStr = tostring(tag)
    local contentStr = tostring(content)
    if not tagStr or not contentStr then
        return
    end

    local contentLen = string.len(contentStr)
    local reportContent = contentLen <= 512 and contentStr or ssub(contentStr, 1, 512)

    if cc.PLATFORM_OS_ANDROID == global.Platform then
        buglyLog(1, tagStr, reportContent)
        buglyReportLuaException(tagStr, tagStr, false)
    else
        release_print(tagStr .. ":" .. reportContent)
    end
end

function RecordBuglyLog(index, value)
    if not index or not value then
        return
    end

    if not global.BuglyLogs then
        global.BuglyLogs = {}
    end

    global.BuglyLogs[index] = value
end

function RecordBuglyLogIm(index, value)
    if not index or not value then
        return
    end

    if cc.PLATFORM_OS_ANDROID == global.Platform then
        buglyLog(1, tostring(index), tostring(value))
    else
        release_print(tostring(index) .. ":" .. tostring(value))
    end
end


function AdjustPath( path )
    local len = string.len(path)
    if len > 0 and string.byte(path, len) ~= 47 then -- 47 == '/'
        path = path .. "/"
    end

    return path
end


function HTTPRequest(url, callback)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("GET", url)

    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            release_print("Http Request Code:" .. tostring(code))
            callback(success, response, url, code)
        end

        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    httpRequest:send()
end

function HTTPRequestPost(url, callback, data, header)
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    if header then
        for k, v in pairs(header) do
            httpRequest:setRequestHeader(k, v)
        end
    end

    if callback then
        local function HttpResponseCB()
            local code = httpRequest.status
            local success = code >= 200 and code < 300
            local response = httpRequest.response

            release_print("Http Request Code:" .. tostring(code))
            callback(success, response, code)
        end
        httpRequest:setRequestHeader("Content-type", "application/x-www-form-urlencoded")
        httpRequest:registerScriptHandler(HttpResponseCB)
    end

    --httpRequest:setRequestHeader
    httpRequest:send(data)
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value, desciption, nesting)
    if not global.isDebugMode then 
        return 
    end
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
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
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function ShowLoadingBar(t)
    global.L_LoadingBarManager:OpenLayer(t)
end

function HideLoadingBar()
    global.L_LoadingBarManager:CloseLayer()
end
function decodeServerInfo( str )
    local dictTAB = { 
        ['0'] = { 'ā','±','ě','ξ' },
        ['1'] = { '♂','τ','ο','δ' },
        ['2'] = { 'φ','ю','é','ī' },
        ['3'] = { 'ш','ō','ē','п' },
        ['4'] = { 'б','ь','ǒ','я' },
        ['5'] = { '＋','á','σ','α' },
        ['6'] = { 'ó','∩','ǎ','ε' },
        ['7'] = { 'í','ò','ì','°' },
        ['8'] = { 'à','○','ψ','♀' },
        ['9'] = { 'ζ','ョ','è','ǐ' },
        ['"'] = { 'λ','ǘ','ι','ǔ' },
        [','] = { 'ǚ','˙','ù','ü' },
        ['['] = { 'ǖ','ū','ё','з' },
        [']'] = { 'ǜ','ú','ω','э' },
        ['a'] = {'ぃ', 'い', 'ぅ', 'う'},
        ['b'] = {'ぇ', 'え', 'ぉ', 'お'},
        ['c'] = {'か', 'が', 'き', 'ぎ'},
        ['d'] = {'く', 'ぐ', 'け', 'げ'},
        ['e'] = {'こ', 'ご', 'さ', 'ざ'},
        ['f'] = {'し', 'じ', 'す', 'ず'},
        ['g'] = {'せ', 'ぜ', 'そ', 'ぞ'},
        ['h'] = {'た', 'だ', 'ち', 'ぢ'},
        ['i'] = {'っ', 'つ', 'づ', 'て'},
        ['j'] = {'で', 'と', 'ど', 'な'},
        ['k'] = {'に', 'ぬ', 'ね', 'の'},
        ['l'] = {'は', 'ば', 'ぱ', 'ひ'},
        ['m'] = {'び', 'ぴ', 'ふ', 'ザ'},
        ['n'] = {'シ', 'ジ', 'ス', 'ズ'},
        ['o'] = {'セ', 'ゼ', 'ソ', 'ゾ'},
        ['p'] = {'タ', 'ダ', 'チ', 'ヂ'},
        ['q'] = {'ッ', 'バ', 'ポ', 'ㄛ'},
        ['r'] = {'ツ', 'パ', 'マ', 'ㄜ'},
        ['s'] = {'ヅ', 'ヒ', 'ミ', 'ㄝ'},
        ['t'] = {'テ', 'ビ', 'ム', 'ㄞ'},
        ['u'] = {'デ', 'ピ', 'メ', 'ㄟ'},
        ['v'] = {'ト', 'フ', 'モ', 'ㄠ'},
        ['w'] = {'ド', 'ブ', 'ャ', 'ㄡ'},
        ['x'] = {'ナ', 'プ', 'ヤ', 'ㄢ'},
        ['y'] = {'ニ', 'ヘ', 'ュ', 'ㄣ'},
        ['z'] = {'ヌ', 'ベ', 'ユ', 'ㄤ'},
        ['.'] = {'ネ', 'ペ', 'ㄧ', 'ㄥ'},
        [':'] = {'ノ', 'ホ', 'ヨ', 'ㄦ'},
        ['/'] = {'ハ', 'ボ', 'ㄚ', 'ㄨ'},
    }
    for k,v in pairs(dictTAB) do
        for _,v1 in pairs(v) do
            str = string.gsub(str, v1, k)
        end
    end
    return str
end

function requireExport_launcher(path)
    return requireLauncher("export/" .. path)
end

function CreateExport_launcher(fileName)
    local ui = requireExport_launcher(fileName).create()
    if ui.root then
        local new_widget = ccui.Widget:create()
        new_widget:setAnchorPoint({x=0, y=0})

        local children = ui.root:getChildren()
        for _, child in pairs(children) do
            child:removeFromParent()
        end
        for _, child in pairs(children) do
            new_widget:addChild(child)
        end

        local name = ui.root:getName()
        -- 自适应代码
        if name ~= "Layer" and name ~= "Node" then
            local visible = cc.Director:getInstance():getVisibleSize()
            new_widget:setContentSize(visible)
            ccui.Helper:doLayout(new_widget)
        else
            new_widget:setContentSize(ui.root:getContentSize())
        end

        return new_widget
    end
    return nil
end

function ui_delegate(nativeUI)
    if (nativeUI == nil) then
        return nil
    end

    local showLanguage = global.L_GameEnvManager:GetEnvDataByKey("showLanguage")
    local isFix = false
    if showLanguage and string.len( showLanguage ) > 0 then
        isFix = true
    end
    -- fixWidget text: ccui.Button    ccui.Text
    local function fixNewString( fixWidget )
        if not isFix or not fixWidget then
            return
        end
        if tolua.type( fixWidget ) == "ccui.Button" then
            local btnTitleStr   = fixWidget:getTitleText()
            btnTitleStr         = fixNewLanguageString( btnTitleStr )
            fixWidget:setTitleText( btnTitleStr )

        elseif tolua.type( fixWidget ) == "ccui.Text" then
            local textStr       = fixWidget:getString()
            textStr             = fixNewLanguageString( textStr )
            fixWidget:setString( textStr )

        end
    end

    local function getChildInSubNodes(nodeTable, key)
        if #nodeTable == 0 then
            return nil
        end
        local child = nil
        local subNodeTable = {}
        for _, v in ipairs(nodeTable) do
            child = v:getChildByName(key)
            if (child) then
                fixNewString( child )
                return child
            end
        end
        for _, v in ipairs(nodeTable) do
            local subNodes = v:getChildren()
            if #subNodes ~= 0 then
                for _, v1 in ipairs(subNodes) do
                    fixNewString( child )
                    table.insert(subNodeTable, v1)
                end
            end
        end
        return getChildInSubNodes(subNodeTable, key)
    end
    local function getChildByKey(parent, key)
        return getChildInSubNodes({parent}, key)
    end

    local tt = {
        __index = function(t, k)
            local u = getChildByKey(t.nativeUI, k)
            rawset(t, k, u)
            return u
        end
    }
    local r = {["nativeUI"] = nativeUI}
    setmetatable(r, tt)
    return r
end

function g_OnEnterForColor(sender)
end

function getNewFoldername(foldername)
    if nil == LuaBridgeCtl:Inst().GetNewFoldername then
        return foldername
    end
    return LuaBridgeCtl:Inst():GetNewFoldername(foldername)
end

function decodeXK( str )
    local function hex2dec( hexStr )
        hexStr = "0x" .. hexStr
        return tonumber(hexStr)
    end
    
    local dict = 
    {
        [0x00] = "0",   -- 0
        [0x01] = "1",   -- 1
        [0x02] = "2",   -- 2
        [0x03] = "3",   -- 3
        [0x04] = "4",   -- 4
        [0x05] = "5",   -- 5
        [0x06] = "6",   -- 6
        [0x07] = "7",   -- 7
        [0x08] = "8",   -- 8
        [0x09] = "9",   -- 9
        [0x0a] = "a",   -- 10
        [0x0b] = "b",   -- 11
        [0x0c] = "c",   -- 12
        [0x0d] = "d",   -- 13
        [0x0e] = "e",   -- 14
        [0x0f] = "f",   -- 15

        [0x10] = "g",
        [0x11] = "h",
        [0x12] = "i",
        [0x13] = "j",
        [0x14] = "k",
        [0x15] = "l",
        [0x16] = "m",
        [0x17] = "n",
        [0x18] = "o",
        [0x19] = "p",
        [0x1a] = "q",
        [0x1b] = "r",
        [0x1c] = "s",
        [0x1d] = "t",
        [0x1e] = "u",
        [0x1f] = "v",

        [0x20] = "w",
        [0x21] = "x",
        [0x22] = "y",
        [0x23] = "z",
        [0x24] = "A",
        [0x25] = "B",
        [0x26] = "C",
        [0x27] = "D",
        [0x28] = "E",
        [0x29] = "F",
        [0x2a] = "G",
        [0x2b] = "H",
        [0x2c] = "I",
        [0x2d] = "J",
        [0x2e] = "K",
        [0x2f] = "L",

        [0x30] = "M",
        [0x31] = "N",
        [0x32] = "O",
        [0x33] = "P",
        [0x34] = "Q",
        [0x35] = "R",
        [0x36] = "S",
        [0x37] = "T",
        [0x38] = "U",
        [0x39] = "V",
        [0x3a] = "W",
        [0x3b] = "X",
        [0x3c] = "Y",
        [0x3d] = "Z",
        [0x3e] = "!",
        [0x3f] = "@",

        [0x40] = "#",
        [0x41] = "$",
        [0x42] = "%",
        [0x43] = "^",
        [0x44] = "&",
        [0x45] = "*",
        [0x46] = "(",
        [0x47] = ")",
        [0x48] = "_",
        [0x49] = "+",
        [0x4a] = "-",
        [0x4b] = "[",
        [0x4c] = "]",
        [0x4d] = "{",
        [0x4e] = "}",
        [0x4f] = "|",
    }

    if not str or "" == str then
        return nil
    end

    -- 解密 1 次
    str = decodeServerInfo( str )

    -- 长度是否是 偶数
    local len = string.len(str)
    if 0 ~= len%2 then
        return nil
    end 

    -- 截取，计算出正确的密钥
    local key = ""
    local tmp = ""
    while string.len(str) > 0 do
        tmp = string.sub(str, 1, 2)
        str = string.len(str) > 2 and string.sub(str, 3, string.len(str)) or ""
        key = key .. dict[hex2dec(tmp)]
    end

    return key
end

function GetHTTPSign(data, key)
    return get_str_MD5("key="..key .. "&time="..os.time())
end

function GetCdnSign(gameId, time, key)
    -- dump(string.format("gameId=%s&time=%s&key=%ssh", gameId, time, key),"签名原串")
    return get_str_MD5(string.format("gameId=%s&time=%s&key=%ssh", gameId, time, key))
end


function GetModListServerTime(isLauncher, subMod)
    global.modListSrvTime = os.time()
    if not subMod then 
        if not global or not global.L_ModuleManager or not global.L_ModuleManager:GetCurrentModule() then
            return
        end
        local module        = global.L_ModuleManager:GetCurrentModule()
        if not module then
            return  
        end
        subMod        = module:GetCurrentSubMod()
    end
    
    if not subMod then 
        return 
    end

    local TimeCallBacks = function ()
        if global.modListSrvTimeCallFuncs then 
            for i, func in ipairs(global.modListSrvTimeCallFuncs) do
                func()
            end    
        end
    end 

    -- dump(subMod,"subMod___")
    local subModInfo    = subMod:GetSubModInfo()
    local gameid        = subMod:GetOperID()
    local xk            = subMod:GetXK() or ""
    local xkDomain      = subModInfo.xkDomain 
    if not xkDomain or xkDomain == "" then 
        releasePrint( "xkDomain: empty"  )
        TimeCallBacks()
        return 
    end

    local serverTimeUrlOri  = xkDomain .. "/server_time"
    local serverTimeData    = serverTimeUrlOri
    serverTimeData          = string.gsub(serverTimeData, "http://", "")
    serverTimeData          = string.gsub(serverTimeData, "https://", "")
    serverTimeData          = string.gsub(serverTimeData, "/gsl/auth/mod_list_auth", "")
    serverTimeData          = string.gsub(serverTimeData, "/gsl/main", "")
    local s                 = string.find(serverTimeData, "/")
    serverTimeData          = string.sub(serverTimeData, s+1, string.len(serverTimeData))

    local signKey           = global.L_GameEnvManager:GetModlistSignKey()
    local timestamp         = os.time()
    local sign              = get_str_MD5("data=" .. serverTimeData .. "&key=" .. signKey .. "&time="..os.time())
    local serverTimeUrl     = serverTimeUrlOri .. string.format("?time=%s&sign=%s", timestamp, sign)
    releasePrint( "serverTimeUrl1:" ..serverTimeUrl )

    if isLauncher then 
        ShowLoadingBar(1)
    end

    HTTPRequest(serverTimeUrl,function (success, response)
        if isLauncher then 
            HideLoadingBar()
        end
        releasePrint( "time:" )
        releasePrint( response)
        if success then
            global.modListSrvTime = tonumber(response) or os.time()
        end

        TimeCallBacks()
    end)
end


-- BOX Game 验签 GET 请求（规则: https://996box-doc.apifox.cn/7493023m0）
function HTTPRequestByBoxSign(url, data, signKey, callback)
    signKey = signKey or ""
    data = data or {}

    local gameId  = tostring(data.gameId or "")
    local userId  = tostring(data.userId or "")

    -- 其余参数拼进 query（gameId/userId 也会带上）
    local query = {}
    for k, v in pairs(data) do
        query[#query + 1] = k .. "=" .. tostring(v)
    end
    local fullURL = url
    if #query > 0 then
        fullURL = url .. (string.find(url, "?", 1, true) and "&" or "?") .. table.concat(query, "&")
    end

    -- 验签
    local clientType = "PC"
    if global.Platform == cc.PLATFORM_OS_ANDROID then
        clientType = "ANDROID"
    elseif global.Platform == cc.PLATFORM_OS_IPHONE or global.Platform == cc.PLATFORM_OS_IPAD then
        clientType = "IOS"
    end
    local userAgent  = "BoxGameSdk-" .. clientType .. "/1.0"
    local socket     = require "socket"
    local timestamp  = tostring(math.floor(socket.gettime() * 1000))    -- 毫秒时间戳
    -- 随机字串(32~64位, [0-9A-Za-z-]), 与 demo 一致的 UUID v4 格式
    local nonce      = string.format("%08x-%04x-4%03x-%04x-%012x",
        math.random(0, 0xffffffff), math.random(0, 0xffff), math.random(0, 0xfff),
        math.random(0x8000, 0xbfff), math.random(0, 0xffffffffffff))

    local path    = string.match(fullURL, "^%a+://[^/]+(/.*)$") or fullURL   -- 去掉协议和域名
    -- 签名串 9 行, 每行以 \n 结尾(含最后一行密钥)
    local signStr = table.concat({ "GET", path, timestamp, nonce, gameId, userId, userAgent, "", signKey }, "\n") .. "\n"
    local sign    = string.lower(get_str_MD5(signStr))
    releasePrint("BOX signStr: ", signStr)

    local header = {
        ["X-BOX-AUTHORIZATION"] = string.format("BOXGAME-MD5 NONCE=%s;TIMESTAMP=%s;SIGNATURE=%s;GAME=%s;USER=%s",
            nonce, timestamp, sign, gameId, userId),
        ["User-Agent"] = userAgent,
    }

    -- 发送
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("GET", fullURL)
    for k, v in pairs(header) do
        httpRequest:setRequestHeader(k, v)
    end
    httpRequest:registerScriptHandler(function()
        local code = httpRequest.status
        releasePrint("Http Request Code:" .. tostring(code))
        callback(code >= 200 and code < 300, httpRequest.response, code)
    end)
    httpRequest:send()
end

-- BOX Game 验签 POST 请求（JSON body, 规则: https://996box-doc.apifox.cn/7493023m0）
function HTTPRequestPostByBoxSign(url, data, signKey, callback)
    signKey = signKey or ""
    data = data or {}
    local cjson = require "cjson"

    local gameId  = tostring(data.gameId or "")
    local userId  = tostring(data.userId or "")

    -- 请求体
    local body = data.body or ""
    if type(body) == "table" then
        body = cjson.encode(data.body)
    end

    -- 验签
    local clientType = "PC"
    if global.Platform == cc.PLATFORM_OS_ANDROID then
        clientType = "ANDROID"
    elseif global.Platform == cc.PLATFORM_OS_IPHONE or global.Platform == cc.PLATFORM_OS_IPAD then
        clientType = "IOS"
    end
    local userAgent  = "BoxGameSdk-" .. clientType .. "/1.0"
    local socket     = require "socket"
    local timestamp  = tostring(math.floor(socket.gettime() * 1000))    -- 毫秒时间戳
    -- 随机字串
    local nonce      = string.format("%08x-%04x-4%03x-%04x-%012x",
        math.random(0, 0xffffffff), math.random(0, 0xffff), math.random(0, 0xfff),
        math.random(0x8000, 0xbfff), math.random(0, 0xffffffffffff))

    local path    = string.match(url, "^%a+://[^/]+(/.*)$") or url      -- 去掉协议和域名
    -- 签名串 9 行, 每行以 \n 结尾(含最后一行密钥)
    local signStr = table.concat({ "POST", path, timestamp, nonce, gameId, userId, userAgent, body or "", signKey }, "\n") .. "\n"
    local sign    = string.lower(get_str_MD5(signStr))
    releasePrint("BOX signStr: ", signStr)

    local header = {
        ["X-BOX-AUTHORIZATION"] = string.format("BOXGAME-MD5 NONCE=%s;TIMESTAMP=%s;SIGNATURE=%s;GAME=%s;USER=%s",
            nonce, timestamp, sign, gameId, userId),
        ["User-Agent"] = userAgent,
        ["Content-Type"] = "application/json",
        ["Accept"] = "*/*",
    }

    -- 发送
    local httpRequest = cc.XMLHttpRequest:new()
    httpRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    httpRequest.timeout = 100000 -- 10 s
    httpRequest:open("POST", url)
    for k, v in pairs(header) do
        httpRequest:setRequestHeader(k, v)
    end
    httpRequest:registerScriptHandler(function()
        local code = httpRequest.status
        releasePrint("Http Request Code:" .. tostring(code))
        callback(code >= 200 and code < 300, httpRequest.response, code)
    end)
    httpRequest:send(body)
end