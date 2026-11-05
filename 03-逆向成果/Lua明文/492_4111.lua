local RemoteProxy = requireProxy("RemoteProxy")
local RechargeProxy = class("RechargeProxy", RemoteProxy)
RechargeProxy.NAME = global.ProxyTable.RechargeProxy

function RechargeProxy:ctor()
    RechargeProxy.super.ctor(self)
    
    self._products = {}
    self._genOrderNoCB = nil
end

function RechargeProxy:GetProducts()
    return self._products
end

function RechargeProxy:GetProductByID(id)
    for _, v in pairs(self._products) do
        if tostring(id) == tostring(v.currency_itemid) then
            return v
        end
    end
    return nil
end

function RechargeProxy:RespJumpRecharge(msg)
    local channels  = 
    {
        SL:GetValue("PAY_CHANNEL_ALIPAY"),
        SL:GetValue("PAY_CHANNEL_HUABEI"),
        SL:GetValue("PAY_CHANNEL_WEIXIN"),
    }

    local header  = msg:GetHeader()
    local price         = header.recog
    local payChannel    = channels[header.param1]
    local currencyID    = header.param2
    local productIndex  = header.param3

    -- 
    if not payChannel then
        return nil
    end

    -- 二维码回调
    local product = self:GetProductByID(currencyID)
    if not product then
        SL:onLUAEvent(LUA_EVENT_NOT_FOUND_GOODS, currencyID)
        return nil
    end

    -- 二维码充值回调
    local function qrcodeCB(isOK, filename)
        if isOK then
            -- 二维码拉取成功
            local qrcode_data = {
                filename    = filename,
                channel     = payChannel,
            }
            UIOperator:OpenRechargeQRCodeUI(qrcode_data)
        end
    end
    
    -- 开始充值, 手机端使用原生 PC端使用二维码
    local info = 
    {
        id           = product.currency_itemid,
        name         = product.currency_name,
        price        = price,
        productIndex = productIndex,
    }
    local paytype   = SL:GetValue("PLATFORM_WINDOWS") and SL:GetValue("PAY_TYPE_QRCODE") or SL:GetValue("PAY_TYPE_NATIVE")
    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        paytype = SL:GetValue("PAY_TYPE_QRCODE") 
    end
    local payData   = {paytype = paytype, channel = payChannel, product = info, qrcodeCB = qrcodeCB}
    global.Facade:sendNotification(global.NoticeTable.PayProductRequest, payData)
end

function RechargeProxy:RespProductInfo(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return false
    end
    -- dump(jsonData)
    self._products = jsonData
end

function RechargeProxy:RespRechargeComplete(msg)
end

function RechargeProxy:RespRechargeReceived(msg)
    SL:onLUAEvent(LUA_EVENT_RECHARGE_RECEIVED)
end

function RechargeProxy:RequestOrderNo(data, callback)
    UIOperator:OpenLoadingBarUI(5)

    -- 请求生成订单号
    LuaSendJsonData(global.MsgType.MSG_CS_RECHARGE_ORDER_NO, data)
    self._genOrderNoCB = callback
end

function RechargeProxy:handle_MSG_SC_RECHARGE_ORDER_NO(netPkg)
    UIOperator:CloseLoadingBarUI()

    -- 返回请求订单数据 orderID: 订单号
    local orderData = netPkg:GetJsonData()
    if self._genOrderNoCB then
        if netPkg:GetP0() == -1 then -- 失败
            SL:ShowSystemTips("直购配置错误")
            self._genOrderNoCB = nil
            return
        end
        self._genOrderNoCB(orderData)
        self._genOrderNoCB = nil
    end
end

function RechargeProxy:RegisterMsgHandler()
    RechargeProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_JUMP_CHARGE, handler(self, self.RespJumpRecharge))
    LuaRegisterMsgHandler(msgType.MSG_SC_PRODUCT_INFO, handler(self, self.RespProductInfo))
    LuaRegisterMsgHandler(msgType.MSG_SC_RECHARGE_RECEIVED, handler(self, self.RespRechargeReceived))
    LuaRegisterMsgHandler(msgType.MSG_SC_RECHARGE_COMPLETE, handler(self, self.RespRechargeComplete))
    LuaRegisterMsgHandler(msgType.MSG_SC_RECHARGE_ORDER_NO, handler(self, self.handle_MSG_SC_RECHARGE_ORDER_NO))
end

return RechargeProxy
