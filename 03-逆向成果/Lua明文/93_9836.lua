local cjson = require("cjson")
local slen = string.len
local jdecode = cjson.decode
local jencode = cjson.encode

_LOG_RECV_NET_MSG = {}
_LOG_RECV_ABLE    = false
_LOG_SEND_NET_MSG = {}
_LOG_SEND_ABLE    = false
G_LEN_BYTE = {
    i1  = 1,
    I1  = 1,
    i2  = 2,
    i4  = 4,
    I4  = 4,
    i8  = 8,
    I8  = 8,
    C16 = 17,
    C32 = 33,
    C50 = 51
}

G_BUFFER_READ = {
    i1  = function (b) return b:ReadBool()   end,
    I1  = function (b) return b:ReadByte()   end,
    i2  = function (b) return b:ReadShort()  end,
    i4  = function (b) return b:ReadInt()    end,
    I4  = function (b) return b:ReadFloat()  end,
    i8  = function (b) return b:ReadInt64()  end,
    I8  = function (b) return b:ReadDouble() end,
    C32 = function (b) return SL:GBKToUTF8(b:ReadShortString(32)) end,
    C50 = function (b) return SL:GBKToUTF8(b:ReadShortString(50)) end
}
G_BUFFER_WRITE = {
    i1  = function (b, value) return b:WriteBool(value)   end,
    I1  = function (b, value) return b:WriteByte(value)   end,
    i2  = function (b, value) return b:WriteShort(value)  end,
    i4  = function (b, value) return b:WriteInt(value)    end,
    I4  = function (b, value) return b:WriteFloat(value)  end,
    i8  = function (b, value) return b:WriteInt64(value)  end,
    i8s = function (b, value) return b:WriteInt64Str(value) end,
    I8  = function (b, value) return b:WriteDouble(value) end,
    C32 = function (b, value) return b:WriteShortString(32, value) end,
    C50 = function (b, value) return b:WriteShortString(50, value) end
}

G_BUFFER_READ_PARSE = {
    i1  = function (b) return b:ReadByte()  end,
    I1  = function (b) return b:ReadUByte() end,
    i2  = function (b) return b:ReadShort() end,
    I2  = function (b) return b:ReadUShort() end,
    i4  = function (b) return b:ReadInt() end,
    I4  = function (b) return b:ReadUInt() end,
    i8  = function (b) return b:ReadInt64() end,
    I8  = function (b) return b:ReadInt64() end,
    i8s  = function (b) return b:ReadInt64Str() end,
    i8S  = function (b) return b:ReadInt64Str() end,
    I8s  = function (b) return b:ReadInt64Str() end,
    I8S  = function (b) return b:ReadInt64Str() end,
    s = function (b) return SL:GBKToUTF8(b:ReadString()) end,
    S = function (b) return SL:GBKToUTF8(b:ReadString()) end, 
    g = function (b) return b:ReadGuid() end,
    G = function (b) return b:ReadGuid() end,
}

function LuaRegisterMsgHandler(msgID, netCB)
    global.networkCtl:RegisterHandler(msgID, function(msg)
        -- 统计收到服务端的消息号
        if _DEBUG and _LOG_RECV_ABLE then
            local header = msg:GetHeader()
            print("recv net msg", msgID, header.recog, header.param1, header.param2, header.param3, msg:GetDataLength())
            _LOG_RECV_NET_MSG[msgID] = _LOG_RECV_NET_MSG[msgID] or {}
            _LOG_RECV_NET_MSG[msgID].hits = (_LOG_RECV_NET_MSG[msgID].hits or 0) + 1
            _LOG_RECV_NET_MSG[msgID].msgId = msgID
            _LOG_RECV_NET_MSG[msgID].dataLen = msg:GetDataLength()
            local headerBuffer = msg:GetHeadLuaBuffer()
            headerBuffer:SetLuaIndex(0)
        end

        netCB(msg)
    end)
end

function LuaSendBytes(...)
    global.networkCtl:SendBytes(...)

    -- 统计收到服务端的消息号
    if _DEBUG and _LOG_SEND_ABLE then
        local data = {...}
        local msgID = data[1]
        local dataLen = data[3]
        
        print("send net msg", msgID, dataLen or 0)
        _LOG_SEND_NET_MSG[msgID] = _LOG_SEND_NET_MSG[msgID] or {}
        _LOG_SEND_NET_MSG[msgID].hits = (_LOG_SEND_NET_MSG[msgID].hits or 0) + 1
        _LOG_SEND_NET_MSG[msgID].msgId = msgID
        _LOG_SEND_NET_MSG[msgID].dataLen = dataLen or 0
    end
end

function SendTableToServer(msgID, tableData)
    local jsonStr = jencode(tableData)
    if not jsonStr then
        print(msgID, "json data encode error")
        return nil
    end

    LuaSendMsg(msgID, 0, 0, 0, 0, jsonStr, slen(jsonStr))
end

function SendUserIDToServer(msgID, userID)
    if nil == userID or type(userID) ~= "string" then
        print(msgID, "userID error")
        return nil
    end

    local sendData = {
        UserID = userID
    }

    SendTableToServer(msgID, sendData)
end

function CheckMsgDataLen(msg)
    local dataLen = msg:GetBodyLen()
    local msgHdr = msg:GetHeader()
    if dataLen <= 0 then
        print(msgHdr.msgId, ": data is empty or overflowed!", dataLen)
        return false
    end

    return true
end

function ParseRawMsgToJson(msg)
    if not CheckMsgDataLen(msg) then
        return nil
    end

    local msgHdr       = msg:GetHeader()
    local dataString   = msg:GetBodyStr()
    local jsonData = nil

    local function decodeJson()
        jsonData = jdecode(dataString)
    end

    if pcall(decodeJson) then
    else
        print("ParseRawMsgToJson ERROR", msgHdr.msgId, dataString)
    end

    if not jsonData then
        print(msgHdr.msgId, ": data decode to json error!")
        return nil
    end

    return jsonData
end

function G_BufferReadArrInt64(buffer, count, startIndex)
    startIndex = startIndex or 1
    local t = {}
    for i = startIndex, startIndex + count - 1 do
        t[i] = buffer:ReadInt64()
    end
    return t
end

function G_BufferReadArrInt64Str(buffer, count, startIndex)
    startIndex = startIndex or 1
    local t = {}
    for i = startIndex, startIndex + count - 1 do
        t[i] = buffer:ReadInt64Str()
    end
    return t
end

function G_BufferReadArrInt(buffer, count, startIndex)
    startIndex = startIndex or 1
    local t = {}
    for i = startIndex, startIndex + count - 1 do
        t[i] = buffer:ReadInt()
    end
    return t
end

function G_BufferReadQuality(buffer, count, startIndex)
    startIndex = startIndex or 1
    local t = {}
    for i = startIndex, startIndex + count - 1 do
        -- id -> value
        local id = buffer:ReadShort()
        local value = buffer:ReadInt64()
        t[#t + 1] = {Idx = id, Value = value}
    end
    return t
end

function G_BufferReadAddValues(buffer, count, startIndex)
    startIndex = startIndex or 1
    local t = {}
    for i = startIndex, startIndex + count - 1 do
        if i == 0 then  -- 限时装备
            t[i] = {
                [1] = buffer:ReadInt(),     -- 开始时间戳
                [2] = buffer:ReadInt()      -- 剩余时间 单位:秒
            }
        elseif i == 8 then
            t[i] = {
                [1] = buffer:ReadUShort(),  -- 投保次数
                [2] = buffer:ReadUShort(),  -- 名字颜色
                [3] = buffer:ReadUShort(),  -- 背包图片ID
                [4] = buffer:ReadUShort(),  -- 背包特效ID
            }
        elseif i == 9 then
            t[i] = {
                [1] = buffer:ReadUShort(),  -- 装备内观
                [2] = buffer:ReadUShort(),  -- 装备内观特效ID
                [3] = buffer:ReadUShort(),  -- 装备外观特效ID
                [4] = buffer:ReadShort(),   -- 镶嵌开启格子数量
            }
        elseif i == 10 then
            t[i] = {
                [1] = buffer:ReadInt(),     -- 物品标记
                [2] = buffer:ReadInt(),     -- 星星
            }
        elseif i == 11 then
            t[i] = {
                [1] = buffer:ReadShort(),   -- 武器升级数量
                [2] = buffer:ReadShort(),   -- 武器幸运(16位有符号)
                [3] = buffer:ReadShort(),   -- 沙巴克武器升级记录
                [4] = buffer:ReadShort(),   -- 沙巴克武器升级攻击
            }
        elseif i == 12 then
            t[i] = {
                [1] = buffer:ReadShort(),     --沙巴克武器升级魔法
                [2] = buffer:ReadShort(),     --沙巴克武器升级道术
                [3] = buffer:ReadInt(),       
            }
        elseif i == 27 then                 -- 27-29 物品自定义属性
            t[i] = SL:GBKToUTF8(buffer:ReadString(24))
            break
        else
            t[i] = buffer:ReadInt64()
        end
    end
    return t
end

function G_BufferReadItemSrc(buff)
    return {
        Type            = buff:ReadByte(),
        Map             = SL:GBKToUTF8(buff:ReadShortString(30)),
        DropName        = SL:GBKToUTF8(buff:ReadShortString(30)),
        ChrName         = SL:GBKToUTF8(buff:ReadShortString(30)),
        Time            = buff:ReadInt()
    }
end

function ReadItemData(buffer)
    local jsonData = {}
    jsonData.MakeIndex = buffer:ReadGuid()
    jsonData.Index     = buffer:ReadInt()
    jsonData.Dura      = buffer:ReadInt()
    jsonData.DuraMax   = buffer:ReadInt()
    jsonData.Where     = buffer:ReadShort()
    jsonData.nOverLap  = buffer:ReadInt()

    -- 极品记录
    jsonData.Quality   = G_BufferReadQuality(buffer, 30, 0)

    -- 附加值
    jsonData.AddValues = G_BufferReadAddValues(buffer, 30, 0)

    -- 镶嵌格子
    jsonData.TNCell    = G_BufferReadArrInt(buffer, 20, 0)
    
    -- 物品来源
    jsonData.ItemSrc   = G_BufferReadItemSrc(buffer)

    local nCount       = buffer:ReadByte()
    -- 自定义属性
    local diyAdv = {}
    for i = 1, nCount, 1 do
        diyAdv[i] = {
            Type       = buffer:ReadUByte(),    -- 组编号
            Job        = buffer:ReadByte(),     -- 职业
            Idx        = buffer:ReadShort(),    -- 属性ID
            Value      = buffer:ReadInt64()     -- 值
        }
    end
    jsonData.DiyAdv = diyAdv
    -- dump(jsonData, "-------物品----------")

    local data = ChangeItemServersSendDatas(jsonData)
    return data
end