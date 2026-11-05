local sreverse  = string.reverse
local sformat   = string.format
local sfind     = string.find
local sbyte     = string.byte
local schar     = string.char
local sgsub     = string.gsub
local ssub      = string.sub
local slen      = string.len
local strim     = string.trim

local mrandom   = math.random
local mfloor    = math.floor

local hzUnit = {"", "十", "百", "千", "万", "十", "百", "千", "亿", "十", "百", "千", "万", "十", "百", "千"}
local hzNum = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}

local function removeZero(num, szNum)
    -- 去掉末尾多余的 零
    num = tostring(num)
    local szLen = slen(num)
    local zero_num = 0
    for i = szLen, 1, -3 do
        szNum = ssub(num, i - 2, i)
        if szNum == hzNum[1] then
            zero_num = zero_num + 1
        else
            break
        end
    end
    num = ssub(num, 1, szLen - zero_num * 3)
    szNum = ssub(num, 1, 6)
    -- 开头的 "一十" 转成 "十" , 贴近人的读法
    if szNum == hzNum[2] .. hzUnit[2] then
        num = ssub(num, 4, slen(num))
    end
    return num
end

function NumberToChinese(szNum)
    -- 阿拉伯数字转中文大写
    local szChMoney = ""
    local iLen = 0
    local iNum = 0
    local iAddZero = 0
    if nil == tonumber(szNum) then
        return tostring(szNum)
    end
    iLen = slen(szNum)
    if iLen > 10 or iLen == 0 or tonumber(szNum) < 0 then
        return tostring(szNum)
    end
    for i = 1, iLen do
        iNum = tonumber(ssub(szNum, i, i))
        if iNum == 0 and i ~= iLen then
            iAddZero = iAddZero + 1
        else
            if iAddZero > 0 then
                szChMoney = szChMoney .. hzNum[1]
            end
            szChMoney = szChMoney .. hzNum[iNum + 1] --//转换为相应的数字
            iAddZero = 0
        end
        if (iAddZero < 4) and (0 == (iLen - i) % 4 or 0 ~= tonumber(iNum)) then
            szChMoney = szChMoney .. hzUnit[iLen - i + 1]
        end
    end
    return removeZero(szChMoney, szNum)
end

function CheckPasswordIsSimple(password, account)
    if password and slen(password) < 6 then
        return true
    end
    if account == password then
        return true
    end
    if not string.match(password, "[^%d]") then
        return true
    end
    if not string.match(password, "[^%a]") then
        return true
    end
    return false
end

-- uf8字符串截取    str: 字符串    subStar: 截取开始    subEnd: 截取结束
function StringUTF8Sub(str,subStar,subEnd)
    if not str or str == "" then
        return ""
    end
    local charsize = function(ch)
        if not ch then 
            return 0
        elseif ch >= 252 then 
            return 6
        elseif ch >= 248 and ch < 252 then 
            return 5
        elseif ch >= 240 and ch < 248 then 
            return 4
        elseif ch >= 224 and ch < 240 then 
            return 3
        elseif ch >= 192 and ch < 224 then 
            return 2
        elseif ch < 192 then 
            return 1
        end
    end
    subStar                         = subStar or 1
    subEnd                          = subEnd or string.utf8len(str)
    local subLen                    = subEnd-subStar+1
    local byteStar,byteEnd,tempLen  = 0,1,0
    while subStar <= subEnd and subLen > 0 do
        local char = sbyte(str, byteEnd)
        byteEnd = byteEnd + charsize(char)
        tempLen = tempLen + 1
        if tempLen > subStar then
            subLen = subLen - 1
        elseif tempLen == subStar then
            byteStar = byteEnd - charsize(char)
            subLen = subLen - 1
        end
    end
    return ssub(str, byteStar, byteEnd-1)
end


function CheckInputOnlyChinese(str)
    local charsize = function(ch)
        if not ch then 
            return 0
        elseif ch >= 252 then 
            return 6
        elseif ch >= 248 and ch < 252 then 
            return 5
        elseif ch >= 240 and ch < 248 then 
            return 4
        elseif ch >= 224 and ch < 240 then 
            return 3
        elseif ch >= 192 and ch < 224 then 
            return 2
        elseif ch < 192 then 
            return 1
        end
    end

    -- Unicode 4E00 - 9FA5
    local function checkChinese(ch, k) 
        if k == 1 and ch >= 228 and ch <= 233 then
            return true
        end
        if k and (k == 2 or k == 3) then
            if ch >= 128 and ch <= 191 then
                return true
            end
        end
        return false
    end

    local inputStr = ""
    local currentIndex = 1
    while currentIndex <= #str do
        local char = sbyte(str, currentIndex)
        if charsize(char) == 3 then
            local index = currentIndex
            local isCh = true
            for i = 1, 3 do
                isCh = isCh and checkChinese(sbyte(str, index + i - 1), i)
            end
            if isCh then
                inputStr = inputStr .. ssub(str, index, index + 3-1)
            end
        end

        currentIndex = currentIndex + charsize(char)
    end
    return inputStr
end

-- 获取字符串的byte长度
function GetUTF8ByteLen(str)
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
    return len,chineseLen
end

--------------------------------------------
--%S -> %s  %D -> %d  %x ->%%x %%x ->%%x
-- %s %d %%D %xxx %s %xx %m %  ->%s %d %%d %%xxx %s %%xx %%m %%
function FixStringFormatCharacter(str)
    if not str then 
        return ""
    end
    str = sgsub(str,"%%S","%%s")
    str = sgsub(str,"%%D","%%d")
    str = sgsub(str,"([^%%])(%%[^sSdD%%])","%1%%%2")
    str = sgsub(str,"%%$","%%%%")
    str = sgsub(str,"^%%([^sSdD%%])","%%%%%1")--开头是%x的
    return str
end
--------------------------------------------
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function Base64enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function Base64dec(data)
    data = sgsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return schar(c)
    end))
end

function FixFilePath(path)
    if path and slen(path) > 0 then
        return sgsub(sgsub(sgsub(sgsub(strim(path), [[\\]], "/"), [[\]],  "/"), "dev/", ""), "^/", "")
    end
    return path
end

-- 拆分文件夹(返回文件夹和文件名)
function GetFileInfoByFilePath(path)
    path = FixFilePath(path)
    local rerStr = sreverse(path)
    local _, i   = sfind(rerStr, "/")
    if not i then
        return "", path
    end
    local len = slen(path)
    local st  = len - i + 2
    return ssub(path, 1, st-2), ssub(path, st, len)
end

local function urlencodechar(char)
    return "%" .. sformat("%02X", sbyte(char))
end
local function urlencodeT(input)
    -- convert line endings
    input = sgsub(tostring(input), "\n", "\r\n")

    -- escape all characters but alphanumeric, '.' and '-'
    input = sgsub(input, "([^%w%.%-%_%~ :/=?&])", urlencodechar)
    -- convert spaces to "+" symbols
    return sgsub(input, " ", "+")
end
function EncodeToJP(str)
    str = tostring(str)
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

    local eStr = ""
    for i = 1, #str do
        local t = ssub(str, i, i)
        local tStr = t
        if dictTAB[t] then
            local table = dictTAB[t]
            tStr = table[mrandom(1, #table)]
        end
        eStr = eStr .. tStr
    end
    return eStr
end

function StringToUTF8String(convertStr)
    if type(convertStr) ~= "string" then
        return convertStr
    end

    local utf8Str = ""
    local i = 1
    local numericCodes = sbyte(convertStr, i)
    --
    while numericCodes ~= nil do
        local part1 = 0
        local part2 = 0
        if numericCodes >= 0x00 and numericCodes <= 0x7f then
            part1 = numericCodes
            part2 = 0
        elseif numericCodes >= 0xc0 and numericCodes <= 0xdf then
            local temp1 = 0
            local temp2 = 0
            temp1 = math.fmod(numericCodes, 0x20)

            i = i + 1
            numericCodes = sbyte(convertStr, i)
            temp2 = math.fmod(numericCodes, 0x40)

            part1 = temp2 + 64 * math.fmod(temp1, 0x04)
            part2 = mfloor(temp1 / 4)
        elseif numericCodes >= 0xe0 and numericCodes <= 0xf7 then
            local temp1 = 0
            local temp2 = 0
            local temp3 = 0
            temp1 = math.fmod(numericCodes, 0x10)

            i = i + 1
            numericCodes = sbyte(convertStr, i)
            temp2 = math.fmod(numericCodes, 0x40)

            i = i + 1
            numericCodes = sbyte(convertStr, i)
            temp3 = math.fmod(numericCodes, 0x40)

            part1 = math.fmod(temp2, 0x04) * 64 + temp3
            part2 = temp1 * 16 + mfloor(temp2 / 4)
        else
            part1 = 0x20
            part2 = 0x00
        end
        utf8Str = utf8Str .. sformat("0x%02x%02x", part2, part1)

        i = i + 1
        numericCodes = sbyte(convertStr, i)
    end
    --
    return utf8Str
end

-- 检测日文  unicode 0x0800 ~ 0x4e00
function IsJapaneseLanguage(str)
    if slen(str or "") < 1 then
        return false
    end

    local UTF8 = require("util/utf8")
    local len = UTF8:length(str)
    for i = 1, len do
        local utf8Str = StringToUTF8String(UTF8:sub(str, i, 1))
        local value = tonumber(utf8Str)
        if value and value >= tonumber(0x0800) and value <= tonumber(0x4e00) then
            return true
        end
    end

    return false
end

-- 获取文件内容md5
function GetFileMD5(filePath)
    if not global.FileUtilCtl:isFileExist(filePath) then
        return ""
    end
    local jsonStr = global.FileUtilCtl:getDataFromFileEx(filePath)
    if not jsonStr or jsonStr == "" or jsonStr == filePath then
        return ""
    end
    local md5 = SL:GetStrMD5(jsonStr)
    return md5
end

local function getRandomStr(n)
    local s = ""
    for i = 1, n do
        local type = mrandom(1,3)
        if type == 1 then
            s = s .. mrandom(0, 9)
        elseif type == 2 then
            s = s .. schar(mrandom(0, 25) + 65)
        elseif type == 3 then
            s = s .. schar(mrandom(0, 25) + 97)
        end
    end
    return s
end

function RandDataID(role_id)
    -- body
    local data_id = role_id
    data_id = data_id.."-"..getRandomStr(16)
    return data_id
end