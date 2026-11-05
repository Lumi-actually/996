local RemoteProxy = requireProxy("RemoteProxy")
local ReinAttrProxy = class("ReinAttrProxy", RemoteProxy)
ReinAttrProxy.NAME = global.ProxyTable.ReinAttrProxy

local cjson = require("cjson")

function ReinAttrProxy:ctor()
    ReinAttrProxy.super.ctor(self)

    self._bonusPoint    = nil
    self._data          = {}
    self._nData         = {}        -- 新版各属性加点数据
    self._isNewBouns    = false     -- 是否启用新版
    self._bounsConfig   = {}        -- 新版属性点配置表
end

function ReinAttrProxy:RespReinData(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return false
    end
    self._data = jsonData
    self._bonusPoint = jsonData.m_nBonusPoint

    SL:onLUAEvent(LUA_EVENT_REIN_ATTR_CHANGE)
end

function ReinAttrProxy:RequestAddReinAttr(data, bonusPoint)
    local jsonStr = cjson.encode(data)
    if not jsonStr then
        return nil
    end

    LuaSendMsg(global.MsgType.MSG_CS_REIN_ATTR_CONFIRM, bonusPoint, 0, 0, 0, jsonStr, string.len(jsonStr))
end

function ReinAttrProxy:GetData()
    return self._data
end

function ReinAttrProxy:GetBonusAbilData()
    return self._data.BonusAbil
end

function ReinAttrProxy:GetBonusTickData()
    return self._data.BonusTick
end

function ReinAttrProxy:GetNakedAbilData()
    return self._data.NakedAbil
end

function ReinAttrProxy:GetAdjustAbilData()
    return self._data.m_AdjustAbil 
end

function ReinAttrProxy:GetBonusPoint()
    return self._bonusPoint
end

------------------------------------- 新版 --------------------------------
function ReinAttrProxy:SetIsNewBouns(value)
    self._isNewBouns = value == true
end

function ReinAttrProxy:IsNewBouns()
    return self._isNewBouns
end

function ReinAttrProxy:LoadConfig()
    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)
    self._bounsConfig = GameConfigMgrProxy:getConfigByKey("cfg_bonus") or {}
end

function ReinAttrProxy:GetConfig()
    return self._bounsConfig
end

function ReinAttrProxy:GetNewAddData()
    return self._nData
end

function ReinAttrProxy:GetNewAddPointsById(id)
    if not self._nData or not id then
        return 0
    end
    for _, data in ipairs(self._nData) do
        if data.id == id then
            return data.value or 0
        end
    end
    return 0
end

function ReinAttrProxy:RespAddAttrData(msg)
    local msgHdr = msg:GetHeader()
    self._bonusPoint = msgHdr.recog
    
    local jsonData = ParseRawMsgToJson(msg)
    if jsonData then
        self._nData = jsonData
    end
    SL:onLUAEvent(LUA_EVENT_REIN_ATTR_CHANGE)
end

function ReinAttrProxy:RequestAddReinAttrNew(data, bonusPoint)
    local jsonStr = cjson.encode(data)
    if not jsonStr then
        return nil
    end

    LuaSendMsg(global.MsgType.MSG_CS_ADD_ATTR_CONFIRM, bonusPoint, 0, 0, 0, jsonStr, string.len(jsonStr))
end

---------------------------------------------------------------------------

function ReinAttrProxy:RegisterMsgHandler()
    ReinAttrProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler( msgType.MSG_SC_REIN_ATTR_RESPONSE, handler(self, self.RespReinData))
    LuaRegisterMsgHandler( msgType.MSG_SC_ADD_ATTR_RESPONSE, handler(self, self.RespAddAttrData))

end

return ReinAttrProxy
