local RemoteProxy = requireProxy("RemoteProxy")
local NPCNewTypeOkProxy = class("NPCNewTypeOkProxy", RemoteProxy)
NPCNewTypeOkProxy.NAME = global.ProxyTable.NPCNewTypeOkProxy

function NPCNewTypeOkProxy:ctor()
    NPCNewTypeOkProxy.super.ctor(self)
    self._onDoNewData = nil
    self._sellStep = GUIDefine.NpcNewTypeStep.WAITING
    self._sellPrice = nil
    self._doSomethingParam = {}
end

function NPCNewTypeOkProxy:SetonDoThingsData(data)
    self._onDoNewData = data

    if data then
        self:SetDoThingsStep(GUIDefine.NpcNewTypeStep.ADD_ITEM)
        BagData.SetOnSellOrRepaire(data.MakeIndex)
    else
        self:SetDoThingsStep(GUIDefine.NpcNewTypeStep.WAITING)
        BagData.CleanOnSellOrRepaire()
    end
end

function NPCNewTypeOkProxy:GetonDoThingsData()
    return self._onDoNewData
end

function NPCNewTypeOkProxy:SetDoSomethingParam(data)
    if data and next(data) then
        self._doSomethingParam = data
    else
        self._doSomethingParam = {}
    end
end

function NPCNewTypeOkProxy:Get_doSomethingParam()
    return self._doSomethingParam
end

function NPCNewTypeOkProxy:SetDoThingsStep(step)
    if step then
        self._sellStep = step
    end
end

function NPCNewTypeOkProxy:GetDoThingsStep()
    return self._sellStep
end

function NPCNewTypeOkProxy:RequestNpcNewTypeOk()
    local data = self._onDoNewData
    local MakeIndex = data.MakeIndex

    LuaSendHeader12(global.MsgType.MSG_CS_NPC_NEWTYPE_OK, MakeIndex)
end

function NPCNewTypeOkProxy:CleanOnDoData()
    self:SetonDoThingsData(nil)
    local data = {
        way = GUIDefine.NpcEventType.DOSOMETHING,
        reset = true
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

function NPCNewTypeOkProxy:handle_MSG_SC_NPC_NEWTYPE_OK(msg)
    local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
    
    local header = msg:GetHeader()
    if header.param1 > 0 then
        NPCNewTypeOkProxy:CleanOnDoData()
        return
    end

    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    dump(jsonData)

    NPCNewTypeOkProxy:SetDoSomethingParam(jsonData)

    local type = GUIDefine.NpcEventType.NEWTYPE
    if tonumber(jsonData.Flag) ~= type then
        return
    end

    SL:onLUAEvent(LUA_EVENT_NPC_SELL_OPEN, {type = type, param = self._doSomethingParam})
end

function NPCNewTypeOkProxy:RegisterMsgHandler()
    NPCNewTypeOkProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    -- NPC 自定义框
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_DOSOMETHING, handler(self, self.handle_MSG_SC_NPC_NEWTYPE_OK))
end

return NPCNewTypeOkProxy