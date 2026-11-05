--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

function printInfo(fmt, ...)
    if type(DEBUG) ~= "number" or DEBUG < 2 then return end
    printLog("INFO", fmt, ...)
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value, desciption, nesting)
    if not _DEBUG then
        return nil
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

function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
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

local iskindof_
iskindof_ = function(cls, name)
    local __index = rawget(cls, "__index")
    if type(__index) == "table" and rawget(__index, "__cname") == name then return true end

    if rawget(cls, "__cname") == name then return true end
    local __supers = rawget(cls, "__supers")
    if not __supers then return false end
    for _, super in ipairs(__supers) do
        if iskindof_(super, name) then return true end
    end
    return false
end

function iskindof(obj, classname)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then return false end

    local mt
    if t == "userdata" then
        if tolua.iskindof(obj, classname) then return true end
        mt = tolua.getpeer(obj)
    else
        mt = getmetatable(obj)
    end
    if mt then
        return iskindof_(mt, classname)
    end
    return false
end

function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

function handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

local pi_mul_180 = math.pi * 180
function math.radian2angle(radian)
    return radian / pi_mul_180
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end
    
function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

function table.find(arr, val)
    for k, v in pairs(arr) do
        if v == val then
            return k
        end
    end
    return nil
end

function table.split(arr, len)
    local data = {}
    local td = {}
    local idx = 1
    for i = 1, #arr do
        if idx > len then
            idx = 1
            table.insert(data, td)
            td = {}
        end
        table.insert(td, arr[i])
        idx = idx + 1
    end
    if #td > 0 then
        table.insert(data, td)
    end
    return data
end

function table.addition(dataA, dataB)
    for k, v in pairs(dataB) do
        table.insert(dataA, v)
    end
end

function table.IsChild(parent, child)
    if type(child) == "table" and type(parent) == "table" then
        for k, v in pairs(child) do
            if not table.IsChild(parent[k], v) then
                return false
            end
        end
    else
        if child ~= parent then
            return false
        end
    end
    return true
end

-- 顺序表合并
function table.order_merge(a, b)
    local concat = {}
    local out = 1

    local i = 1
    local byte = a[i]
    while byte ~= nil do
        concat[out] = byte
        i = i + 1
        out = out + 1
        byte = a[i]
    end

    i = 1
    byte = b[i]
    while byte ~= nil do
        concat[out] = byte
        i = i + 1
        out = out + 1
        byte = b[i]
    end

    return concat
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
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

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function string.unicode2utf8(str)
    if type(str) ~= "string" then
        return str
    end

    local items = {}
    local i = 1
    while true do
        local num1 = string.byte(str, i)
        local unicode = nil

        if num1 ~= nil and string.sub(str, i, i + 1)=="\\u" then
            unicode = tonumber("0x" .. string.sub(str, i + 2, i + 5))
            i = i + 6
        elseif num1 ~= nil then
            unicode = num1
            i = i + 1
        else
            break
        end

        if unicode <= 0x007f then
            table.insert(items, string.char(bit.band(unicode,0x7f)))

        elseif unicode >= 0x0080 and unicode <= 0x07ff then
            table.insert(items, string.char(bit.bor(0xc0,bit.band(bit.rshift(unicode,6),0x1f))))
            table.insert(items, string.char(bit.bor(0x80,bit.band(unicode,0x3f))))

        elseif unicode >= 0x0800 and unicode <= 0xffff then
            table.insert(items, string.char(bit.bor(0xe0,bit.band(bit.rshift(unicode,12),0x0f))))
            table.insert(items, string.char(bit.bor(0x80,bit.band(bit.rshift(unicode,6),0x3f))))
            table.insert(items, string.char(bit.bor(0x80,bit.band(unicode,0x3f))))
        end
    end
    table.insert(items, '\0')
    return table.concat(items, "")
end

function string.endsWith(str, subStr)
	local len1 = #str
	local len2 = #subStr
	if len1 < len2 then
		return false
	end

	return string.find(str, subStr, len1 - len2 + 1) ~= nil
end

function string.startsWith(str, subStr)
	return string.find(str, subStr) == 1
end

function string.contains(str, subStr)
	return string.find(str, subStr) ~= nil
end

function string.cchar(n)
    local t = {
        [174] = "®",
        [175] = "¯",
        [176] = "°",
        [177] = "±",
        [178] = "²",
        [179] = "³",
        [180] = "´",
        [181] = "µ",
        [182] = "¶",
        [183] = "·",
        [184] = "¸",
        [185] = "¹",
        [186] = "º",
        [187] = "»",
        [188] = "¼",
        [189] = "½",
        [190] = "¾",
        [191] = "¿",
        [192] = "À",
        [193] = "Á",
        [194] = "Â",
        [195] = "Ã",
        [196] = "Ä",
        [197] = "Å",
        [198] = "Æ",
        [199] = "Ç",
        [200] = "È",
        [201] = "É",
        [202] = "Ê",
        [203] = "Ë",
        [204] = "Ì",
        [205] = "Í",
        [206] = "Î",
        [207] = "Ï",
        [208] = "Ð",
        [209] = "Ñ",
        [210] = "Ò",
        [211] = "Ó",
        [212] = "Ô",
        [213] = "Õ",
        [214] = "Ö",
        [215] = "×",
        [216] = "Ø",
        [217] = "Ù",
        [218] = "Ú",
        [219] = "Û",
        [220] = "Ü",
        [221] = "Ý",
        [222] = "Þ",
        [223] = "ß",
        [224] = "à",
        [225] = "á",
        [226] = "â",
        [227] = "ã",
        [228] = "ä",
        [229] = "å",
        [230] = "æ",
        [231] = "ç",
        [232] = "è",
        [233] = "é",
        [234] = "ê",
        [235] = "ë",
        [236] = "ì",
        [237] = "í",
        [238] = "î",
        [239] = "ï",
        [240] = "ð",
        [241] = "ñ",
        [242] = "ò",
        [243] = "ó",
        [244] = "ô",
        [245] = "õ",
        [246] = "ö",
        [247] = "÷",
        [248] = "ø",
        [249] = "ù",
        [250] = "ú",
        [251] = "û",
        [252] = "ü",
        [253] = "ý",
        [254] = "þ",
        [255] = "ÿ"
    }
    return t[n]
end

function string.cbyte(c)
    local t = {
        ["®"] = 174,
        ["¯"] = 175,
        ["°"] = 176,
        ["±"] = 177,
        ["²"] = 178,
        ["³"] = 179,
        ["´"] = 180,
        ["µ"] = 181,
        ["¶"] = 182,
        ["·"] = 183,
        ["¸"] = 184,
        ["¹"] = 185,
        ["º"] = 186,
        ["»"] = 187,
        ["¼"] = 188,
        ["½"] = 189,
        ["¾"] = 190,
        ["¿"] = 191,
        ["À"] = 192,
        ["Á"] = 193,
        ["Â"] = 194,
        ["Ã"] = 195,
        ["Ä"] = 196,
        ["Å"] = 197,
        ["Æ"] = 198,
        ["Ç"] = 199,
        ["È"] = 200,
        ["É"] = 201,
        ["Ê"] = 202,
        ["Ë"] = 203,
        ["Ì"] = 204,
        ["Í"] = 205,
        ["Î"] = 206,
        ["Ï"] = 207,
        ["Ð"] = 208,
        ["Ñ"] = 209,
        ["Ò"] = 210,
        ["Ó"] = 211,
        ["Ô"] = 212,
        ["Õ"] = 213,
        ["Ö"] = 214,
        ["×"] = 215,
        ["Ø"] = 216,
        ["Ù"] = 217,
        ["Ú"] = 218,
        ["Û"] = 219,
        ["Ü"] = 220,
        ["Ý"] = 221,
        ["Þ"] = 222,
        ["ß"] = 223,
        ["à"] = 224,
        ["á"] = 225,
        ["â"] = 226,
        ["ã"] = 227,
        ["ä"] = 228,
        ["å"] = 229,
        ["æ"] = 230,
        ["ç"] = 231,
        ["è"] = 232,
        ["é"] = 233,
        ["ê"] = 234,
        ["ë"] = 235,
        ["ì"] = 236,
        ["í"] = 237,
        ["î"] = 238,
        ["ï"] = 239,
        ["ð"] = 240,
        ["ñ"] = 241,
        ["ò"] = 242,
        ["ó"] = 243,
        ["ô"] = 244,
        ["õ"] = 245,
        ["ö"] = 246,
        ["÷"] = 247,
        ["ø"] = 248,
        ["ù"] = 249,
        ["ú"] = 250,
        ["û"] = 251,
        ["ü"] = 252,
        ["ý"] = 253,
        ["þ"] = 254,
        ["ÿ"] = 255
    }
    return t[c]
end