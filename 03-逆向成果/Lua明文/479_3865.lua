local RemoteProxy = requireProxy("RemoteProxy")
local NPCSellProxy = class("NPCSellProxy", RemoteProxy)
NPCSellProxy.NAME = global.ProxyTable.NPCSellProxy

function NPCSellProxy:ctor()
    NPCSellProxy.super.ctor(self)
    self._onSellingData = nil
    self._sellStep = GUIDefine.NpcSellStep.WAITING
    self._sellPrice = nil
    self._itemFrom = nil
end

function NPCSellProxy:SetOnSellingData(data)
    self._onSellingData = data

    if data then
        self:SetSellingStep(GUIDefine.NpcSellStep.ADD_ITEM)
        BagData.SetOnSellOrRepaire(data.MakeIndex)
    else
        self:SetSellingStep(GUIDefine.NpcSellStep.WAITING)
        self:SetSellingFrom(nil)
        BagData.CleanOnSellOrRepaire()
    end
end

function NPCSellProxy:GetOnSellingData()
    return self._onSellingData
end

function NPCSellProxy:SetSellingStep(step)
    if step then
        self._sellStep = step
    end
end

function NPCSellProxy:GetSellingStep()
    return self._sellStep
end

function NPCSellProxy:SetSellingFrom(from)
    self._itemFrom = from
end

function NPCSellProxy:GetSellingFrom()
    return self._itemFrom
end

function NPCSellProxy:SetSellingPrice(price)
    self._sellPrice = price
end

function NPCSellProxy:GetSellingPrice(price)
    return self._sellPrice
end

function NPCSellProxy:RequestNpcStoreSellPre(data)
    local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
    local MakeIndex = data.MakeIndex

    LuaSendHeader12(global.MsgType.MSG_CS_NPC_STORE_SELL_PRE, MakeIndex, npcId )
    self:SetSellingStep(GUIDefine.NpcSellStep.GET_PRICE)
end

function NPCSellProxy:RequestNpcStoreSell()
    local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
    local data = self._onSellingData
    local MakeIndex = data.MakeIndex

    LuaSendHeader12(global.MsgType.MSG_CS_NPC_STORE_SELL_ITEM, MakeIndex, npcId)
    self:SetSellingStep(GUIDefine.NpcSellStep.SELLING)
end

function NPCSellProxy:ResetSellingState()
    self:SetOnSellingData(nil)
    local data = {
        way = GUIDefine.NpcEventType.SELL,
        reset = true
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

-- 出售价格返回
function NPCSellProxy:handle_MSG_SC_NPC_STORE_SELL_PRICE(msg)
    local head = msg:GetHeader()
    if not head then
        return
    end

    local price = head.recog
    self:SetSellingPrice(price)
    self:SetSellingStep(GUIDefine.NpcSellStep.HAD_PRICE)

    local data = {
        way = GUIDefine.NpcEventType.SELL,
        price = price
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

function NPCSellProxy:handle_MSG_SC_NPC_STORE_SELL_RESULT_FAIL(msg)
    self:ResetSellingState()
end

function NPCSellProxy:handle_MSG_SC_NPC_STORE_SELL_RESULT_SUCCESS(msg)
    self:ResetSellingState()
end

function NPCSellProxy:handle_MSG_SC_NPC_SELL(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    SL:onLUAEvent(LUA_EVENT_NPC_SELL_OPEN, {type = GUIDefine.NpcEventType.SELL})
end

function NPCSellProxy:RegisterMsgHandler()
    NPCSellProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    -- NPC出售
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_SELL, handler(self, self.handle_MSG_SC_NPC_SELL))
    -- NPC商店出售道具预显示价格返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_SELL_PRICE, handler(self, self.handle_MSG_SC_NPC_STORE_SELL_PRICE))
    -- NPC商店出售失败返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_SELL_RESULT_FAIL, handler(self, self.handle_MSG_SC_NPC_STORE_SELL_RESULT_FAIL))
    -- NPC商店出售成功返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_STORE_SELL_RESULT_SUCCESS, handler(self, self.handle_MSG_SC_NPC_STORE_SELL_RESULT_SUCCESS))
end

return NPCSellProxy