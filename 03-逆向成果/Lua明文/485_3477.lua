local RemoteProxy = requireProxy("RemoteProxy")
local NPCDoSomethingProxy = class("NPCDoSomethingProxy", RemoteProxy)
NPCDoSomethingProxy.NAME = global.ProxyTable.NPCDoSomethingProxy

local cjson = require("cjson")

function NPCDoSomethingProxy:ctor()
    NPCDoSomethingProxy.super.ctor(self)
    self._onDoThingsData = nil
    self._sellStep = GUIDefine.NpcDosomethingStep.WAITING
    self._sellPrice = nil
    self._doSomethingParam = {}
end

function NPCDoSomethingProxy:SetonDoThingsData(data)
    self._onDoThingsData = data

    if data then
        self:SetDoThingsStep(GUIDefine.NpcDosomethingStep.ADD_ITEM)
        BagData.SetOnSellOrRepaire(data.MakeIndex)

    else
        self:SetDoThingsStep(GUIDefine.NpcDosomethingStep.WAITING)
        BagData.CleanOnSellOrRepaire()
    end
end

function NPCDoSomethingProxy:GetonDoThingsData()
    return self._onDoThingsData
end

function NPCDoSomethingProxy:SetDoSomethingParam(data)
    if data and next(data) then
        self._doSomethingParam = data
    else
        self._doSomethingParam = {}
    end
end

function NPCDoSomethingProxy:GetDoSomethingParam()
    return self._doSomethingParam
end

function NPCDoSomethingProxy:SetDoThingsStep(step)
    if step then
        self._sellStep = step
    end
end

function NPCDoSomethingProxy:GetDoThingsStep()
    return self._sellStep
end

function NPCDoSomethingProxy:RequestNpcDoSomething()
    local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
    local param = self:GetDoSomethingParam()
    local flag = param.Flag or 0
    local recovery = param.Recovery
    local data = self._onDoThingsData
    local Name = data.Name
    local MakeIndex = data.MakeIndex
    local sendData = {
        Name = Name,
        Flag = flag,
        Recovery = recovery,
        MakeIndex = MakeIndex
    }
    local jsonStr = cjson.encode(sendData)
    LuaSendMsg(global.MsgType.MSG_CS_NPC_DOSOMETHING, npcId, 0, 0, 0, jsonStr, string.len(jsonStr))
end

function NPCDoSomethingProxy:ResetDoSomethingState()
    self:SetonDoThingsData(nil)
    self:SetDoSomethingParam(nil)

    local data = {
        way = GUIDefine.NpcEventType.DOSOMETHING,
        reset = true
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

function NPCDoSomethingProxy:CleanOnDoData()
    self:SetonDoThingsData(nil)

    local data = {
        way = GUIDefine.NpcEventType.DOSOMETHING,
        reset = true
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end

function NPCDoSomethingProxy:handle_MSG_SC_NPC_DOSOMETHING(msg)
    local header = msg:GetHeader()
    local param1 = header.param1
    if param1 > 0 then
        self:CleanOnDoData()
        return
    end

    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return -1
    end

    dump(jsonData)

    self:SetDoSomethingParam(jsonData)
    local type = GUIDefine.NpcEventType.DOSOMETHING
    if tonumber(jsonData.Flag) ~= type then
        return
    end
    
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_OPEN, {type = type, param = self._doSomethingParam})
end

function NPCDoSomethingProxy:RegisterMsgHandler()
    NPCDoSomethingProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    -- NPC 自定义框
    LuaRegisterMsgHandler(msgType.MSG_SC_NPC_DOSOMETHING, handler(self, self.handle_MSG_SC_NPC_DOSOMETHING))
end

return NPCDoSomethingProxy