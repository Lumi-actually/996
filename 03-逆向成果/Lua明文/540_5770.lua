local RemoteProxy   = requireProxy( "RemoteProxy" )
local InformationProxy = class( "InformationProxy", RemoteProxy )
InformationProxy.NAME   = global.ProxyTable.InformationProxy

function InformationProxy:ctor()
    InformationProxy.super.ctor( self )

    self._config = {}
    self._day_count = {}
    self._pay_day_count = {}    --充值信息

    self._curr_day = 1
    self._pay_curr_day = 1      --当前数组的天数

    self._select_day = {} --记录本地已选择的天数

    self:LoadConfig()
end

function InformationProxy:LoadConfig()
    local fileName = "cfg_information.lua"
    if global.FileUtilCtl:isFileExist("scripts/game_config/" .. fileName) then
        self._config = requireGameConfig("cfg_information")
    end

    self._select_day = self:GetSelecDaykData()
end

function InformationProxy:GetConfig()
    return self._config
end

function InformationProxy:GetConfigByID( id )
    if not id then
        return {}
    end
    return self._config[id] or {}
end

function InformationProxy:GetDayByID( id )
    if not id then
        return 7
    end

    return self._select_day[id] or 7
end

function InformationProxy:SetDayByID( id,day )
    if not id or not day then
        return
    end

    self._select_day[id] = day
    self:SetSelecDaykData()
end

function InformationProxy:GetDayMath( day )
    if not day then
        return ""
    end
    local ret = ""
    if day >= 365 then
        ret = string.format( GET_STRING(310000308), math.floor(day/365) )
    elseif day >= 30 then
        ret = string.format( GET_STRING(310000307), math.floor(day/30) )
    elseif day > 0 then
        ret = string.format( GET_STRING(310000306), day )
    end
    return ret
end

function InformationProxy:GetInformationCount( day,id )
    if not day then
        return 0
    end
    local count = 0
    local offDay = 0
    
    local currDay = 1
    local dayCount = {}
    if id == 4 then             --充值信息单独获取
        dayCount = self._pay_day_count
        currDay = self._pay_curr_day
    else
        dayCount = self._day_count
        currDay = self._curr_day
    end
    
    for i=1,day do
        local index = currDay - i + offDay + 1
        if index == 0 then
            index = 365
            offDay = 365
        end
        count = count + (dayCount[index] or 0)
    end
    return count
end

function InformationProxy:PareseInformationName( id )
    if not id then
        return {}
    end
    local config = self:GetConfigByID( id )
    local array1 = G_GetSplitArray( config.page2name or "", "#" )
    local array2 = G_GetSplitArray( config.page3name or "", "#" )
    
    local array = {}
    for i,v in ipairs(array1) do
        array[i] = {
            name = array1[i] or "",
            txtStr = array2[i] or ""
        }
    end

    return array
end

function InformationProxy:SetDayCountData( str )
    self._day_count = {}

    local array = G_GetSplitArray( str or "", ";" )
    for i,v in ipairs( array ) do
        if v and v ~= "" then
            local arry1 = G_GetSplitArray(v,"=")
            local day = tonumber(arry1[1]) or 0
            local count = tonumber(arry1[2]) or 0
            self._day_count[day] = count
        end
    end
end

function InformationProxy:SetPayDayCountData( str )
    self._pay_day_count = {}

    local array = G_GetSplitArray( str or "", ";" )
    for i,v in ipairs( array ) do
        if v and v ~= "" then
            local arry1 = G_GetSplitArray(v,"=")
            local day = tonumber(arry1[1]) or 0
            local count = tonumber(arry1[2]) or 0
            self._pay_day_count[day] = count
        end
    end
end

-- 本地缓存数据
function InformationProxy:GetSelecDaykData()
    local PosData = UserData:new("InformationData")
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local flag = proxy:GetSelectedRoleID() or "errorName"
    local clientData = PosData:getStringForKey( "information"..flag )
 
    if not clientData or clientData == "" then
       return {}
    end
    local cjson = require( "cjson" )
    local lastJsonData = cjson.decode(clientData)
    return lastJsonData
 end
 
 function InformationProxy:SetSelecDaykData()
 
    local PosData = UserData:new("InformationData")
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local flag = proxy:GetSelectedRoleID() or "errorName"
    local cjson = require( "cjson" )
    local selectDayData = cjson.encode(self._select_day)
    local clientData = PosData:setStringForKey( "information"..flag, selectDayData )
    
 end

-- 收集个人信息
function InformationProxy:handle_MSG_SC_GET_INFORMATION_RESPON( msg )
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    local dataString = msg:GetBodyStr()

    self._curr_day = msgHdr.recog
    self:SetDayCountData( dataString )
end

-- 收集个人充值信息
function InformationProxy:handle_MSG_SC_GET_EVERYDAY_CHARGE( msg )
    local msgLen = msg:GetDataLength()
    local msgHdr = msg:GetHeader()
    local dataString = msg:GetBodyStr()

    self._pay_curr_day = msgHdr.recog
    self:SetPayDayCountData( dataString )
end

function InformationProxy:RegisterMsgHandler()
    InformationProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler( msgType.MSG_SC_GET_INFORMATION_RESPON, handler( self, self.handle_MSG_SC_GET_INFORMATION_RESPON) )
    LuaRegisterMsgHandler( msgType.MSG_SC_GET_EVERYDAY_CHARGE, handler( self, self.handle_MSG_SC_GET_EVERYDAY_CHARGE) )
end

return InformationProxy