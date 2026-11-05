local RemoteProxy = requireProxy("RemoteProxy")
local ExchangeProxy = class("ExchangeProxy", RemoteProxy)
ExchangeProxy.NAME = global.ProxyTable.ExchangeProxy

local socket = require("socket")
local cjson = require("cjson")
require("GUIData/ExchangeData")
function ExchangeProxy:ctor()
    ExchangeProxy.super.ctor(self)
    if ExchangeData.Init then 
        ExchangeData.Init()
    end
    self._complete      = false
end

-- 拉取交易所数据：发送消息号：1510, recog 世界=0, 我的上架=1, 我的记录=2
function ExchangeProxy:RequestItemList(data)
    local curTime = socket.gettime()
    local needDelay = false
    local function callback()
        local sendData = data
        self._lastRequestTime = socket.gettime()
        local jsonStr = cjson.encode(sendData)
        LuaSendMsg(global.MsgType.MSG_CS_EXCHANGE_ITEM_LIST, data.type or 0, 0, 0, 0, jsonStr, string.len(jsonStr))
    end
    PerformWithDelayGlobal(callback, needDelay and (self._requestMinTime / 1000) or 0)
end

function ExchangeProxy:RequestBuy(data)
    SendTableToServer(global.MsgType.MSG_CS_EXCHANGE_SELL, data)
end

function ExchangeProxy:RespItemList(msg)
    UIOperator:CloseLoadingBarUI()
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    if len <= 0 then
        return false
    end
    local jsonData  = ParseRawMsgToJson(msg)
    local type      = header.recog  -- 0 1 2 

    -- complete
    local data = jsonData and jsonData.data
    if #data == 0  then
        self._complete = true
        SLBridge:onLUAEvent(LUA_EVENT_EXCHANGE_ITEM_LIST_COMPLETE, {type = type})
        return
    end
    SLBridge:onLUAEvent(LUA_EVENT_EXCHANGE_ITEM_LIST_PULL, {type = type, items = data, pageIndex = jsonData.pageindex})
end

-- 操作返回  recog=类型 1=上架 2=取出 3=出售 4=下架, nparam 0 成功 小于0 失败
function ExchangeProxy:RespOperaBack(msg)
    local header    = msg:GetHeader()
    local type      = header.recog
    local errorcode = header.param1

    SL:onLUAEvent(LUA_EVENT_EXCHANGE_OPERABACK, {type = type, errorcode = errorcode})
end

function ExchangeProxy:RespItemUpdate(msg)
    local header = msg:GetHeader()
    local action = header.recog
    local jsonData = ParseRawMsgToJson(msg)

    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local myUid = PlayerProperty:GetRoleUID()
    local isMy = jsonData.userid == myUid
    SL:onLUAEvent(LUA_EVENT_REQ_EXCHANGEDATA,{isMy = isMy, action = action, item = jsonData})
end


function ExchangeProxy:RequestPutInPrice(data)
    LuaSendMsg(global.MsgType.MSG_CS_EXCHANGE_ITEM_PRICE, data)
end

function ExchangeProxy:RequestPutin(guid, submitData)
    local submitData = SL:JsonEncode(submitData)
    LuaSendHeader12(global.MsgType.MSG_CS_EXCHANGE_PUT_IN, guid,0,0,submitData)

end

function ExchangeProxy:RequestPutout(makeIndex)
    LuaSendHeader13(global.MsgType.MSG_CS_EXCHANGE_PUT_OUT, makeIndex)
end

function ExchangeProxy:RespItemPrice(msg)
    local newPrice = msg:GetP0()
    local iconType = msg:GetP1()

    SLBridge:onLUAEvent(LUA_EVENT_EXCHANGE_ITEM_PRICE, {iconType = iconType, newPrice = newPrice})
end


function ExchangeProxy:RegisterMsgHandler()
    ExchangeProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_EXCHANGE_ITEM_LIST,    handler(self, self.RespItemList))
    LuaRegisterMsgHandler(msgType.MSG_SC_EXCHANGE_OPERA,        handler(self, self.RespOperaBack))
    LuaRegisterMsgHandler(msgType.MSG_SC_EXCHANGE_UPDATE,       handler(self, self.RespItemUpdate))
    LuaRegisterMsgHandler(msgType.MSG_SC_EXCHANGE_ITEM_PRICE,    handler(self, self.RespItemPrice))

end
return ExchangeProxy