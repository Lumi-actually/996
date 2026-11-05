local RecvNetPackage = class("RecvNetPackage")
local cjson = require("cjson")
local jdecode =  cjson.decode
---------------------------------------------------------------------------
function RecvNetPackage:ctor(netPkg)
    self._netPkg = netPkg
    self._msgID = netPkg:GetMsgID()
    self._header = netPkg:GetHeadData()
    self._bodyLen = netPkg:GetBodyLength()
    if self._bodyLen > 0 then 
        self._body = netPkg:GetBodyData()
    end
end

function RecvNetPackage:GetMsgID()
    return self._msgID
end

function RecvNetPackage:GetHeader()
    local header = 
    {
        msgId = self._msgID,
        recog = self:GetP0(),
        param1 = self:GetP1(),
        param2 = self:GetP2(),
        param3 = self:GetP3(),
    }
    return header
end

function RecvNetPackage:GetHeader2()
    return self:GetArrInt64()
end

function RecvNetPackage:GetHeader3()
    self._header:SetLuaIndex(0)
    local header = 
    {
        Id = self._header:ReadInt64(),       -- int64
        X = self._header:ReadInt(),        -- int32
        Y = self._header:ReadInt(),       -- int32
        Dir = self._header:ReadShort(),     -- short
        Type = self._header:ReadShort(),    -- short
        Flag = self._header:ReadInt(),    -- int32
        X2 = self._header:ReadInt(),      -- int32
        Y2 = self._header:ReadInt(),      -- int32
    }
    return header
end

function RecvNetPackage:GetHeader3_Str()
    self._header:SetLuaIndex(0)
    local header = 
    {
        Id = self._header:ReadInt64Str(),       -- int64
        X = self._header:ReadInt(),        -- int32
        Y = self._header:ReadInt(),       -- int32
        Dir = self._header:ReadShort(),     -- short
        Type = self._header:ReadShort(),    -- short
        Flag = self._header:ReadInt(),    -- int32
        X2 = self._header:ReadInt(),      -- int32
        Y2 = self._header:ReadInt(),      -- int32
    }
    return header
end

function RecvNetPackage:GetHeader4()
    return self:GetArrInt()
end

function RecvNetPackage:GetHeader5()
    return self:GetArrUInt()
end

function RecvNetPackage:GetHeader6()
    self._header:SetLuaIndex(0)
    local guid1 = self._header:ReadGuid()
    local guid2 = self._header:ReadGuid()
    local header = 
    {
        Guid = guid1,       -- 16 bit string
        Guid2 = guid2        -- 16 bit string
    }
    return header
end

function RecvNetPackage:GetHeader7()
    return self:GetArrByte()
end

function RecvNetPackage:GetHeader8()
    return self:GetArrWord()
end

function RecvNetPackage:GetHeader11()
    self._header:SetLuaIndex(0)
    local header = 
    {
        t0 = self._header:ReadInt64(),    -- int64
        t1 = self._header:ReadInt(),      -- int32
        t2 = self._header:ReadInt(),      -- int32
        t3 = self._header:ReadInt(),      -- int32
        t4 = self._header:ReadInt(),      -- int32
        t5 = self._header:ReadInt(),      -- int32
        t6 = self._header:ReadInt(),      -- int32
    }
    return header
end

function RecvNetPackage:GetHeader11_Str()
    self._header:SetLuaIndex(0)
    local header = 
    {
        t0 = self._header:ReadInt64Str(),    -- int64
        t1 = self._header:ReadInt(),      -- int32
        t2 = self._header:ReadInt(),      -- int32
        t3 = self._header:ReadInt(),      -- int32
        t4 = self._header:ReadInt(),      -- int32
        t5 = self._header:ReadInt(),      -- int32
        t6 = self._header:ReadInt(),      -- int32
    }
    return header
end

function RecvNetPackage:GetHeader12()
    self._header:SetLuaIndex(0)
    local guid = self._header:ReadGuid()
    local int64_1 = self._header:ReadInt64()      -- int64
    local int64_2 = self._header:ReadInt64()      -- int64

    local header = 
    {
        Guid = guid,       -- 16 bit string
        p1 = int64_1,
        p2 = int64_2       
    }
    return header
end

function RecvNetPackage:GetHeader13()
    self._header:SetLuaIndex(0)
    local guid = self._header:ReadGuid()
    local int32_1 = self._header:ReadInt()       
    local int32_2 = self._header:ReadInt()      
    local int32_3 = self._header:ReadInt()       
    local int32_4 = self._header:ReadInt()        

    local header = 
    {
        Guid = guid,       -- 16 bit string
        p1 = int32_1 ,
        p2 = int32_2 ,
        p3 = int32_3 ,
        p4 = int32_4 ,       
    }
    return header
end

function RecvNetPackage:GetHeader14()
    self._header:SetLuaIndex(0)
    local int32_0 = self._header:ReadInt()
    local int32_1 = self._header:ReadInt()
    local int32_2 = self._header:ReadInt()
    local int32_3 = self._header:ReadInt()
    local int32_4 = self._header:ReadInt()
    local int32_5 = self._header:ReadInt()
    local int32_6 = self._header:ReadInt()
    local int32_7 = self._header:ReadInt()

    local header = 
    {
        MagId   = int32_0,
        Lv      = int32_1,
        LvExt   = int32_2,
        Act     = int32_3,
        TagSel  = int32_4,
        Type    = int32_5,
        CD      = int32_6,
        ActionId= int32_7,
    }
    return header
end

function RecvNetPackage:GetJsonData()
    local dataStr = self:GetBodyStr()
    if not dataStr or dataStr == "" then
        return nil
    end
    return jdecode(dataStr)
end

function RecvNetPackage:GetHeadStr()
    self._header:SetLuaIndex(0)
    return self._header:GetShortString(0)
end

function RecvNetPackage:GetP0()
    self._header:SetLuaIndex(0)
    return self._header:ReadInt64()
end
function RecvNetPackage:GetP0Str()
    self._header:SetLuaIndex(0)
    return self._header:ReadInt64Str()
end
function RecvNetPackage:GetP1()
    self._header:SetLuaIndex(8)
    return self._header:ReadInt64()
end
function RecvNetPackage:GetP1L32()
    self._header:SetLuaIndex(8)
    return self._header:ReadInt()
end
function RecvNetPackage:GetP1H32()
    self._header:SetLuaIndex(12)
    return self._header:ReadInt()
end
function RecvNetPackage:GetP1Str()
    self._header:SetLuaIndex(8)
    return self._header:ReadInt64Str()
end
function RecvNetPackage:GetP2()
    self._header:SetLuaIndex(16)
    return self._header:ReadInt64()
end
function RecvNetPackage:GetP2L32()
    self._header:SetLuaIndex(16)
    return self._header:ReadInt()
end
function RecvNetPackage:GetP2H32()
    self._header:SetLuaIndex(20)
    return self._header:ReadInt()
end
function RecvNetPackage:GetP2Str()
    self._header:SetLuaIndex(16)
    return self._header:ReadInt64Str()
end
function RecvNetPackage:GetP3()
    self._header:SetLuaIndex(24)
    return self._header:ReadInt64()
end

function RecvNetPackage:GetArrInt64()
    self._header:SetLuaIndex(0)
    local items = {}
    for i = 1, 4 do
        items[i] = self._header:ReadInt64()
    end
    return items
end

function RecvNetPackage:GetArrInt()
    self._header:SetLuaIndex(0)
    local items = {}
    for i = 1, 8 do
        items[i] = self._header:ReadInt()
    end
    return items
end

function RecvNetPackage:GetArrUInt()
    self._header:SetLuaIndex(0)
    local items = {}
    for i = 1, 8 do
        items[i] = self._header:ReadUInt()
    end
    return items
end

function RecvNetPackage:GetArrByte()
    self._header:SetLuaIndex(0)
    local items = {}
    for i = 1, 32 do
        items[i] = self._header:ReadUByte()
    end
    return items
end

function RecvNetPackage:GetArrWord()
    self._header:SetLuaIndex(0)
    local items = {}
    for i = 1, 16 do
        items[i] = self._header:ReadUShort()
    end
    return items
end

function RecvNetPackage:GetBodyStr()
    if self._bodyLen > 0 then 
        self._body:SetLuaIndex(0)
        return SL:GBKToUTF8(self._body:ReadString())
    else
        return ""
    end
end

function RecvNetPackage:GetBodyBytes()
    return self._body
end

function RecvNetPackage:GetBodyLen()
    return self._bodyLen
end

function RecvNetPackage:GetDataLength()
    return self:GetBodyLen()
end
function RecvNetPackage:GetBodyLuaBuffer()
    return self._body
end

function RecvNetPackage:GetHeadLuaBuffer()
    return self._header
end

-- table
function RecvNetPackage:GetBodyValues(protos, keys)
    local len = self._bodyLen
    if len < 1 then
        return nil
    end
    self._body:SetLuaIndex(0)
    local num = #protos

    local func = function ()
        local l = 0
        for i = 1, num do
            l = l + G_LEN_BYTE[protos[i]]
        end
        return l
    end

    local pLen = func()
    if pLen < 1 then
        return nil
    end
    
    local n = math.ceil(len / pLen)

    local t = {}
    for i = 1, n do
        t[i] = {}
        for k = 1, num do
            t[i][keys[k]] = G_BUFFER_READ[protos[k]](self._body)
        end
    end
    return t
end

-- table Map
function RecvNetPackage:GetBodyValues2(protos, keys, data)
    local len = self._bodyLen
    if len < 1 then
        return nil
    end
    self._body:SetLuaIndex(0)
    local t = data or {}
    for k = 1, #protos do
        t[keys[k]] = G_BUFFER_READ[protos[k]](self._body)
    end

    return t
end

-- 关系网table
function RecvNetPackage:GetBodyNetValues(count)
    local len = self._bodyLen
    if len < 1 or count < 1 then
        return nil
    end
    self._body:SetLuaIndex(0)
    local t = {}
    for i = 1, count do
        local type = self._body:ReadByte()
        local netID1 = self._body:ReadShortString(38)
        local netID2 = self._body:ReadShortString(38)
        t[GetJoinNetTypeIndex(type, 1)] = string.len(netID1) > 0 and netID1 or nil
        t[GetJoinNetTypeIndex(type, 2)] = string.len(netID2) > 0 and netID2 or nil
    end
    return t
end

-- Head table
function RecvNetPackage:GetHeadValues(protos)
    self._header:SetLuaIndex(0)
    local t = {}
    for k = 1, #protos do
        t["P" .. (k - 1)] = G_BUFFER_READ[protos[k]](self._header)
    end
    return t.P0, t.P1, t.P2, t.P3, t.P4, t.P5, t.P6, t.P7
end

return RecvNetPackage