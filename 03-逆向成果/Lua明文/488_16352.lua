local RemoteProxy = requireProxy("RemoteProxy")
local TradeProxy = class("TradeProxy", RemoteProxy)
TradeProxy.NAME = global.ProxyTable.TradeProxy

function TradeProxy:ctor()
    TradeProxy.super.ctor(self)

    self._trader                 = false
    self._isTrading              = false
    self._myselfLockState        = false
    self._mysureLockState        = false --自己的确认状态
    self._targetSureLockState    = false --对方的确认状态

    self._itemsDataMySelf        = {}
    self._itemsMySelfNum         = 0
    self._itemsDataTarget        = {}
    self._tradeList              = {}
    self._goldMySelf             = 0
    self._goldTarget             = 0
    self._tradeMoney             = nil
    self._moveTradeConfirmed     = true  --移动取消交易确认
end

function TradeProxy:onRegister()
    TradeProxy.super.onRegister(self)
end

function TradeProxy:Cleanup()
    self._trader = nil -- 名字、等级、好友、公会
    self._myselfLockState = false
    self._mysureLockState = false
    self._targetSureLockState = false
    self._tradeMoney = nil
end

function TradeProxy:GetTrader()
    return self._trader
end

function TradeProxy:GetTraderID()
    return self._trader and self._trader.userId
end

function TradeProxy:GetTraderName()
    return self._trader and self._trader.name
end

function TradeProxy:IsTrading()
    return self._isTrading
end

function TradeProxy:GetSelfItemDataByMadeIndex(itemId)
    if not itemId then
        return
    end
    return self._itemsDataMySelf[itemId]
end

function TradeProxy:SetSelfItemDataByItemId(itemId, item)
    if not itemId then
        return
    end
    if not item then
        self._itemsMySelfNum = math.max(self._itemsMySelfNum - 1, 0)
    else
        if not self._itemsDataMySelf[itemId] then
            self._itemsMySelfNum = self._itemsMySelfNum + 1
        end
    end
    self._itemsDataMySelf[itemId] = item
end

function TradeProxy:GetTargetItemDataByMadeIndex(itemId)
    if not itemId then
        return
    end
    return self._itemsDataTarget[itemId]
end

function TradeProxy:SetTargetItemDataByItemId(itemId, item)
    if not itemId then
        return
    end
    self._itemsDataTarget[itemId] = item
end

function TradeProxy:SetMyselfGoldNum(num)
    self._goldMySelf = num or 0
end

function TradeProxy:SetTargetGoldNum(num)
    self._goldTarget = num or 0
end

function TradeProxy:ClearItemData()
    self._itemsDataMySelf = {}
    self._itemsMySelfNum = 0
    self._itemsDataTarget = {}
    self._goldMySelf = 0
    self._goldTarget = 0
    self._mysureLockState = false
    self._targetSureLockState = false
end

function TradeProxy:GetTargetItemData()
    return clone(self._itemsDataTarget)
end

function TradeProxy:GetSelfItemData()
    return clone(self._itemsDataMySelf)
end

function TradeProxy:GetSelfItemNum()
    return self._itemsMySelfNum
end

function TradeProxy:GetSelfItemDataCount()
    local data = self:GetSelfItemData()
    local count = 0
    if not data or next(data) == nil then
        return count
    end
    for k, v in pairs(data) do
        if v and next(v) then
            count = count + 1
        end
    end
    return count
end

function TradeProxy:GetSelfGoldNum()
    return clone(self._goldMySelf)
end

function TradeProxy:GetTargetGoldNum()
    return clone(self._goldTarget)
end

function TradeProxy:GetTradeMoneyID()
    return self._tradeMoney
end

function TradeProxy:GetMySureLockState()
    return self._mysureLockState
end

function TradeProxy:GetTargetSureLockState()
    return self._targetSureLockState
end

function TradeProxy:SetMySureLockState(state)
    self._mysureLockState = state
    SL:onLUAEvent(LUA_EVENT_TRADE_MY_STATUS_CHANGE)
end

function TradeProxy:SetTargetSureLockState(state)
    self._targetSureLockState = state
    SL:onLUAEvent(LUA_EVENT_TRADE_STATUS_CHANGE)
end

function TradeProxy:CheckTradeLockState()
    local myLockState = self:GetMySureLockState()
    local targetLockState = self:GetTargetSureLockState()
    if not targetLockState or not myLockState then
        return false
    end
    return true
end

function TradeProxy:RespTradeResult(msg)
    local header = msg:GetHeader()
    if header and next(header) then
        local errorType = header.recog
        --交易失败即弹窗
        SL:onLUAEvent(LUA_EVENT_TRADE_FAIL_ERROR_TIPS, errorType)
        -- 清除旧数据
        self:Cleanup()
        self:ClearItemData()
        self._isTrading = false
        SL:onLUAEvent(LUA_EVENT_TRADE_CANCELED)
    end
    self._moveTradeConfirmed = true
end

function TradeProxy:RespTradingInfo(msg)
    local code = msg:GetP1()
    if code == 1 then
        local userId = msg:GetP0Str()
        local userName = msg:GetBodyStr()
        local tradeData = {}
        tradeData.userId = userId
        tradeData.name = userName
        tradeData.type = 1
        self._tradeList[userId] = tradeData
        self._tradeMoney = msg:GetP2()
        SL:onLUAEvent(LUA_EVENT_TRADE_BUBBLE_TIPS_CHANGE, tradeData)
    else
        --xx请求和你交易错误弹窗
        SL:onLUAEvent(LUA_EVENT_TRADE_REQUEST_ERROR_TIPS, code)
    end
end

function TradeProxy:GetInviteItems()
    return self._tradeList
end

function TradeProxy:GetInviteCount()
    local count = 0
    for _, v in pairs(self._tradeList) do
        count = count + 1
    end
    return count
end

function TradeProxy:ClearInviteItemsById(UserId)
    self._tradeList[UserId] = nil
end

function TradeProxy:ClearInviteItems()
    self._tradeList = {}
    -- 气泡
    local data = {}
    data.type = 0
    SL:onLUAEvent(LUA_EVENT_TRADE_BUBBLE_TIPS_CHANGE, data)
end

function TradeProxy:RespAcceptAll(msg)
    local userId = msg:GetP0Str()
    local name = msg:GetBodyStr()
    -- 清除旧数据
    self:Cleanup()
    -- 字符串：对方名字
    local trader = {}
    trader.name = name
    trader.userId = userId
    self._trader = trader

    self._tradeMoney = msg:GetP1()
    self:ClearItemData()
    self._isTrading = true
    -- 交易打开
    UIOperator:OpenTradeUI()
end

function TradeProxy:RespTradingCancel(msg)
    local header = msg:GetHeader()
    local data = self:GetSelfItemData()
    -- 清除旧数据
    self:Cleanup()
    self:ClearItemData()
    self._isTrading = false
    self._moveTradeConfirmed = true
    SL:onLUAEvent(LUA_EVENT_TRADE_CANCELED)
end

function TradeProxy:RespTraderMoneyChange(msg)
    local targetMoney = msg:GetP0()
    self:SetTargetGoldNum(targetMoney)

    local data = {}
    data.count = targetMoney
    SL:onLUAEvent(LUA_EVENT_TRADE_TARGET_MONEY_CHANGE, data)
    SL:onLUAEvent(LUA_EVENT_TRADE_TARGET_MONEY_CHANGE_AUDIO)
end

function TradeProxy:RespMyselfMoneyChange(msg)
    local tradingNum = msg:GetP0()
    local nowGoldNum = msg:GetP1()
    self:SetMyselfGoldNum(tradingNum)

    local data = {}
    data.count = tradingNum
    SL:onLUAEvent(LUA_EVENT_TRADE_MYSELF_MONEY_CHANGE, data)
end

function TradeProxy:RespMyselfMoneyChangeFail(msg)
    local tradingNum = msg:GetP0()
    local nowGoldNum = msg.GetP1()
    SL:print(nowGoldNum,"nowGoldNum")
    self:SetMyselfGoldNum(tradingNum)

    local data = {}
    data.count = tradingNum
    SL:onLUAEvent(LUA_EVENT_TRADE_MYSELF_MONEY_CHANGE, data)
end

function TradeProxy:RespTraderItemPutIn(netPkg)
    --对方放入物品消息
    local buffData = netPkg:GetBodyLuaBuffer()
    local buffItem = ReadItemData(buffData)
    if buffItem then
        self:SetTargetItemDataByItemId(buffItem.MakeIndex, buffItem)

        local data = {}
        data.way = 1
        SL:onLUAEvent(LUA_EVENT_TRADE_TRADER_ITEM_CHANGE, data)
    end
end

function TradeProxy:RespTraderItemPutOut(msg)
    --对方取出物品消息
    local header = msg:GetHeader6()
    local makeIndex = header.Guid
    if makeIndex and makeIndex ~= 0 then
        self:SetTargetItemDataByItemId(makeIndex, nil)

        local data = {}
        data.way = 1
        SL:onLUAEvent(LUA_EVENT_TRADE_TRADER_ITEM_CHANGE, data)
    end
end

function TradeProxy:RespMyselfItemPutInSuccess(msg)
    --自己放入物品结果
    local header = msg:GetHeader6()
    if not header.Guid then
        return
    end
    local makeIndex = header.Guid
    local data = {}
    data.way = 0
    data.makeIndex = header.Guid
    local itemData = BagData.GetItemDataByMakeIndex(makeIndex)
    BagData.DelItemData(itemData, true)

    self:SetSelfItemDataByItemId(makeIndex, itemData)

    SL:onLUAEvent(LUA_EVENT_TRADE_MYSELF_ITEM_CHANGE, data)
end

function TradeProxy:RespMyselfItemPutInFail(msg)
    local header = msg:GetHeader6()
    if not header or not header.Guid then
        return
    end
    local data = {
        trading = {
            MakeIndex = header.Guid,
            state = 1
        }
    }
    SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
end

function TradeProxy:RespMyselfItemPutOutSuccess(msg)
    --自己取出物品结果
    local header = msg:GetHeader6()
    if not header.Guid then
        return
    end
    -- 扣掉交易中的
    local makeIndex = header.Guid
    local data = {}
    data.way = 0
    data.MakeIndex = makeIndex

    self:SetSelfItemDataByItemId(makeIndex, nil)

    SL:onLUAEvent(LUA_EVENT_TRADE_MYSELF_ITEM_CHANGE, data)
    -- 背包中的重新刷出来
    local data = {
        trading = {
            MakeIndex = makeIndex,
            state = 1
        }
    }
    SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
end

function TradeProxy:RespMyselfItemPutOutFail(msg)
    local header = msg:GetHeader6()
    local data = {}
    data.way = 0
    data.MakeIndex = header.Guid
    SL:onLUAEvent(LUA_EVENT_TRADE_MYSELF_ITEM_CHANGE, data)
end

function TradeProxy:RespTraderStatusChange(msg)
    -- 收到对方状态改变: 参数1是类型 0取消锁定，1锁定
    local userId = msg:GetP0Str()
    local state = msg:GetP1()
    local targetData = self:GetTrader()
    local myUid = global.gamePlayerController:GetMainPlayerID()
    
    if targetData and targetData.userId and userId == targetData.userId then
        local status = state == 1 and true or false
        if not status then
            self._myselfLockState = false
        end
        self:SetTargetSureLockState(status)
    elseif myUid == userId then
        local status = state == 1 and true or false
        if not status then
            self._myselfLockState = false
        end
        self:SetMySureLockState(status)
    end
end

function TradeProxy:RespTradeSuccess(msg)
    local myTradeData = self._itemsDataMySelf
    if myTradeData and next(myTradeData) then
        for k, v in pairs(myTradeData) do
            if v and next(v) then
                BagData.DelItemData(v, true)
            end
        end
    end

    self:ClearItemData()
    self._isTrading = false
    SL:onLUAEvent(LUA_EVENT_TRADE_CANCELED)
    self._moveTradeConfirmed = true
end

function TradeProxy:RegisterMsgHandler()
    local msgType = global.MsgType

    -- 请求交易结果
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADE_TRADER_RESULT, handler(self, self.RespTradeResult))
    -- xx请求和你交易
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADE_INFO_RESPONSE, handler(self, self.RespTradingInfo))
    -- 打开交易界面
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_ACCEPT_ALL, handler(self, self.RespAcceptAll))
    -- (回复): 取消交易,关闭界面
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_CANCEL, handler(self, self.RespTradingCancel))
    -- (回复): 对方货币数量改变
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_TRADER_CHANGE_MONEY, handler(self, self.RespTraderMoneyChange))
    -- (回复): 自己货币数量改变
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_CHANGE_MONEY, handler(self, self.RespMyselfMoneyChange))
    -- (回复): 自己货币数量改变失败
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_CHANGE_MONEY_FAIL, handler(self, self.RespMyselfMoneyChangeFail))
    -- (回复): 对方交易物品放入
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_TRADER_PUTIN_ITEM, handler(self, self.RespTraderItemPutIn))
    -- (回复): 对方交易物品取出
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_TRADER_PUTOUT_ITEM, handler(self, self.RespTraderItemPutOut))
    -- (回复): 自己放入物品成功
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_PUTIN_ITEM_SUCCESS, handler(self, self.RespMyselfItemPutInSuccess))
    -- (回复): 自己放入物品失败
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_PUTIN_ITEM_FAIL, handler(self, self.RespMyselfItemPutInFail))
    -- (回复): 自己取回物品成功
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_PUTOUT_ITEM_SUCCESS, handler(self, self.RespMyselfItemPutOutSuccess))
    -- (回复): 自己取回物品失败
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_MYSELF_PUTOUT_ITEM_FAIL, handler(self, self.RespMyselfItemPutOutFail))
    -- (回复): 双方状态改变
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_LOCK_CHANGE_STATUS, handler(self, self.RespTraderStatusChange))
    -- (回复): 交易成功
    LuaRegisterMsgHandler(msgType.MSG_SC_TRADING_SUCCESSFUL, handler(self, self.RespTradeSuccess))
end

function TradeProxy:RequestTrade(uid, name, refuse)
    if not refuse and SL:GetValue("STALL_MY_TRADING_STATUS") then
        --摆摊中，禁止操作
        SL:onLUAEvent(LUA_EVENT_TRADE_STALL_FORBID)
        return
    end
    local tradeTargetUid = 0
    local targetLen = 0
    if uid then
        tradeTargetUid = uid
        targetLen = string.len(uid)
    end
    if not refuse then
        self:ClearInviteItems()
    end
    LuaSendMsg(global.MsgType.MSG_CS_TRADING_INFO_REQUEST, tradeTargetUid)
end

function TradeProxy:SendTradeRequest(uid)
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        --摆摊中，禁止操作
        SL:onLUAEvent(LUA_EVENT_TRADE_STALL_FORBID)
        return
    end

    if self:IsTrading() then
        return
    end

    local tradeTargetUid = 0
    local targetLen = 0
    if uid then
        tradeTargetUid = uid
        targetLen = string.len(uid)
    end
    if CHECK_SERVER_OPTION(global.MMO.SERVER_OPTION_TRADE_DEAL) == true then
        LuaSendMsg(global.MsgType.MSG_CS_TRADE_SEND_REQUEST)
    else
        LuaSendMsg(global.MsgType.MSG_CS_TRADE_SEND_REQUEST, tradeTargetUid)
    end
end

function TradeProxy:RequestCancel()
    -- 请求取消交易
    LuaSendMsg(global.MsgType.MSG_CS_TRADING_CANCEL)
end

function TradeProxy:RequestChangeMoney(count)
    -- 请求修改货币 ，参数1：数量
    LuaSendMsg(global.MsgType.MSG_CS_TRADING_MYSELF_CHANGE_MONEY, count)
end

function TradeProxy:RequestPutInItem(itemID)
    -- 请求放入物品
    LuaSendHeader6(global.MsgType.MSG_CS_TRADING_MYSELF_PUTIN_ITEM, itemID)
end

function TradeProxy:RequestPutOutItem(itemID)
    -- 请求取出物品
    LuaSendHeader6(global.MsgType.MSG_CS_TRADING_MYSELF_PUTOUT_ITEM, itemID)
end

function TradeProxy:RequestTradeEnd()
    self._myselfLockState = true
    LuaSendMsg(global.MsgType.MSG_CS_TRADING_TRADE, 0, 0, 0, 0)
end

function TradeProxy:RequestChangeLock()
    local nowState = self:GetMySureLockState()
    -- 主动请求改变自己锁定状态
    local changeStatus = not nowState and 1 or 0
    LuaSendMsg(global.MsgType.MSG_CS_CHANGE_MY_TRADE_STATE, changeStatus, 0, 0, 0)
end

function TradeProxy:CheckPlayerOutOfView(userId)
    if not self._isTrading then
        return
    end
    if not self._trader then
        return
    end
    if userId ~= self._trader.userId then
        return
    end
    self:RequestCancel()
end

-- 主玩家移动  如果正在交易   直接取消
function TradeProxy:CheckPlayerMove()
    if self._moveTradeConfirmed and self:IsTrading() then
        self._moveTradeConfirmed = false
        self:RequestCancel()
    end
end

return TradeProxy