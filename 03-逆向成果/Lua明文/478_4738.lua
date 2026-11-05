local RemoteProxy = requireProxy("RemoteProxy")
local NPCRepaireProxy = class("NPCRepaireProxy", RemoteProxy)
NPCRepaireProxy.NAME = global.ProxyTable.NPCRepaireProxy

function NPCRepaireProxy:ctor()
    NPCRepaireProxy.super.ctor(self)
    self._repaireStep = GUIDefine.NpcRepaireStep.WAITING
    self._repairePrice = nil
    self._onRepairingData = nil
end

function NPCRepaireProxy:SetOnRepairingData(data)
    self._onRepairingData = data

    if data then
        self:SetRepaireStep(GUIDefine.NpcRepaireStep.ADD_ITEM)
        BagData.SetOnSellOrRepaire(data.MakeIndex)
    else
        self:SetRepaireStep(GUIDefine.NpcRepaireStep.WAITING)
        self:SetRepaireStep(nil)
        BagData.CleanOnSellOrRepaire()
    end
end

function NPCRepaireProxy:GetOnRepairingData()
    return self._onRepairingData
end

function NPCRepaireProxy:SetRepaireStep(step)
    if step then
        self._repaireStep = step
    end
end

function NPCRepaireProxy:GetRepaireStep()
    return self._repaireStep
end

function NPCRepaireProxy:SetRepairingPrice(price)
    self._repairePrice = price
end

function NPCRepaireProxy:GetRepairingPrice()
    return self._repairePrice
end

function NPCRepaireProxy:RequestNpcStoreRepairePre(data)
    local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
    local Name = data.Name
    local MakeIndex = data.MakeIndex

    LuaSendHeader12(global.MsgType.MSG_CS_NPC_STORE_REPAIRE_PRE, MakeIndex, npcId, 0, Name)
    self:SetRepaireStep(GUIDefine.NpcRepaireStep.GET_PRICE)
end

function NPCRepaireProxy:RequestNpcStoreRepaire()
    local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
    local data = self._onRepairingData
    local MakeIndex = data.MakeIndex

    LuaSendHeader12(global.MsgType.MSG_CS_NPC_STORE_REPAIRE_ITEM, MakeIndex, npcId)
    self:SetRepaireStep(GUIDefine.NpcRepaireStep.REPAIRING)
end

function NPCRepaireProxy:RepaireEndChangeItemData(itemMakeIndex, drua, makeDrua)
    if not itemMakeIndex then
        return
    end

    local data = BagData.GetItemDataByMakeIndex(itemMakeIndex)
    if data and next(data) then
        data.Drua = drua or data.Dura
        data.MaxDrua = makeDrua or data.MaxDrua
        BagData.ChangeItemData(data)
    end
end

function NPCRepaireProxy:ResetRepairingState()
    self:SetOnRepairingData(nil)

    local data = {
        way = GUIDefine.NpcEventType.REPAIRE,
        reset = true
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

--修理价格返回
function NPCRepaireProxy:handle_MSG_SC_NPC_REPAIRE_ITEM_PRICE(msg)
    local head = msg:GetHeader()
    if not head then
        return
    end
    local price = head.recog

    self:SetRepairingPrice(price)
    self:SetRepaireStep(GUIDefine.NpcRepaireStep.HAD_PRICE)
    local data = {
        way = GUIDefine.NpcEventType.REPAIRE,
        price = price
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

function NPCRepaireProxy:handle_MSG_SC_NPC_REPAIRE_ITEM_RESULT_SUCCESS(msg)
    local header = msg:GetHeader()
    if not header then
        return
    end

    local MakeIndex = header.param1
    local drua = header.param2
    local maxDrua = header.param3

    self:RepaireEndChangeItemData(MakeIndex, drua, maxDrua)

    self:ResetRepairingState()
end

function NPCRepaireProxy:handle_MSG_SC_NPC_REPAIRE_ITEM_RESULT_FAIL(msg)
    local header    = msg:GetHeader()
    local errorCode = header.recog      --错误
    if errorCode == -1 then
        ShowSystemTips(GET_STRING(90030005))
    end

    self:ResetRepairingState()
end

function NPCRepaireProxy:handle_MSG_SC_NPC_REPAIRE_ITEM(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    SL:onLUAEvent(LUA_EVENT_NPC_SELL_OPEN, {type = GUIDefine.NpcEventType.REPAIRE})
end

function NPCRepaireProxy:RegisterMsgHandler()
    NPCRepaireProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    -- NPC修理道具打开返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_REPAIRE_ITEM, handler(self, self.handle_MSG_SC_NPC_REPAIRE_ITEM))
    -- NPC商店修理失败返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_REPAIRE_ITEM_RESULT_FAIL, handler(self, self.handle_MSG_SC_NPC_REPAIRE_ITEM_RESULT_FAIL))
    -- NPC商店修理成功返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_REPAIRE_ITEM_RESULT_SUCCESS, handler(self, self.handle_MSG_SC_NPC_REPAIRE_ITEM_RESULT_SUCCESS))
    -- NPC商店修理道具预显示价格返回
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_REPAIRE_ITEM_PRICE, handler(self, self.handle_MSG_SC_NPC_REPAIRE_ITEM_PRICE))
end

return NPCRepaireProxy