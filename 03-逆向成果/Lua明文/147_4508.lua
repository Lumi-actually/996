local SendNetPackage = class("SendNetPackage")

local TCONCAT = table.concat
local STR_LEN = string.len
local STR_PACK = string.pack
local MATH_FLOOR = math.floor

function SendNetPackage:ctor(msgID)
    self._netPkg = netPackage:new()
    self._header = luaBuffer:new()
    self._body = luaBuffer:new()
    self._msgID = msgID
    self._netPkg:SetMsgID(msgID)
    self._bodyLen = 0
end

function SendNetPackage:GetMsgID()
    return self._msgID
end

function SendNetPackage:GetHeadBytes()
    return self._header
end

function SendNetPackage:GetBodyBytes()
    return self._body
end

function SendNetPackage:GetBodyLen()
    return self._body:GetLength()
end

function SendNetPackage:SetHead3(value)
    local Id = tonumber(value.Id) or 0
    local X = tonumber(value.X) or 0
    local Y = tonumber(value.Y) or 0
    local Dir = tonumber(value.Dir) or 0
    local Type = tonumber(value.Type) or 0
    local Flag = tonumber(value.Flag) or 0
    self._header:WriteInt64(MATH_FLOOR(Id))
    self._header:WriteInt(MATH_FLOOR(X))
    self._header:WriteInt(MATH_FLOOR(Y))
    self._header:WriteShort(MATH_FLOOR(Dir))
    self._header:WriteShort(MATH_FLOOR(Type))
    self._header:WriteInt(MATH_FLOOR(Flag))
    self._header:WriteInt64(0)
end

function SendNetPackage:SetHeadStr(value)
    local slen = STR_LEN(value)
    if slen == 0 or slen >= 32 then
        self._header:WriteShortString("")
    else
        self._header:WriteShortString(value)
    end
end

function SendNetPackage:SetArrInt64OrStr(arrInt64)
    for i = 1, 4 do
        local value = arrInt64[i] or 0
        if type(value) == "string" then 
            self._header:WriteInt64Str(value)
        else
            self._header:WriteInt64(MATH_FLOOR(value))
        end
    end
end

function SendNetPackage:SetArrInt64(arrInt64)
    for i = 1, 4 do
        local value = arrInt64[i] or 0
        self._header:WriteInt64(MATH_FLOOR(value))
    end
end

function SendNetPackage:SetArrInt(arrInt)
    for i = 1, 8 do
        local value = arrInt[i] or 0
        self._header:WriteInt(MATH_FLOOR(value))
    end
end

function SendNetPackage:SetArrUInt(arrUInt)
    for i = 1, 8 do
        local value = arrUInt[i] or 0
        self._header:WriteUInt(MATH_FLOOR(value))
    end
end

function SendNetPackage:SetArrGuid(arrGuid)
    local bytes = {}
    for i = 1, 2 do
        local guid = arrGuid[i] or ""
        dump(guid,"guid___")
        self._header:WriteGuid(guid)
    end
end

function SendNetPackage:SetGuidInt32(values)
    --16 4 4 4 4 
    local guid = values[1] or ""
    self._header:WriteGuid(guid)
    for i = 1, 4 do
        self._header:WriteInt(MATH_FLOOR(values[i + 1] or 0))
    end
end

function SendNetPackage:SetGuidInt64(values)
    --16 8 8
    local guid = values[1] or ""
    self._header:WriteGuid(guid)
    for i = 1, 2 do
        local value = values[i + 1]
        if type(value) == "string" then 
            self._header:WriteInt64Str(value)
        else
            self._header:WriteInt64(MATH_FLOOR(value or 0))
        end
    end
end

function SendNetPackage:SetArrByte(arrByte)
    for i = 1, 32 do
        local value = arrByte[i] or 0
        self._header:WriteByte(MATH_FLOOR(value))
    end
end

function SendNetPackage:SetArrP1P2Int64(arrInt)
    for i = 1, 6 do
        local value = arrInt[i] or 0
        if i >= 2 and i <= 5 then
            self._header:WriteInt(MATH_FLOOR(value))
        else
            self._header:WriteInt64(MATH_FLOOR(value))
        end
    end
end

function SendNetPackage:SetBody(value)
    value = value or ""
    if value ~= "" then
        self._body:WriteString(value)
    end
end

function SendNetPackage:WriteBuffer(protos, buffer)
    local bytes = {}
    local num   = #protos
    for i = 1, num do
        local v   = protos[i]
        local key = v.key
        bytes[i] =  G_BUFFER_WRITE[key](buffer, v.value)  
    end
    return bytes
end

function SendNetPackage:SetHeadBody(headProtos, bodyProtos)
    if headProtos then 
        self:WriteBuffer(headProtos,self._header)
    end
    if bodyProtos then 
        self:WriteBuffer(bodyProtos,self._body)
    end
end

function SendNetPackage:GetNetPackage()
    return self._netPkg
end

function SendNetPackage:SetHeadAndBody()
    self._netPkg:SetHeadData(self._header)
    self._netPkg:SetBodyData(self._body)
end
return SendNetPackage