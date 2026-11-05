local RemoteProxy = requireProxy("RemoteProxy")
local MissionProxy = class("MissionProxy", RemoteProxy)
MissionProxy.NAME = global.ProxyTable.MissionProxy

function MissionProxy:ctor()
    MissionProxy.super.ctor(self)

    self._data = {}
    self._data.items = {}
end

function MissionProxy:onRegister()
    MissionProxy.super.onRegister(self)
end

-- 任务置顶
function MissionProxy:RespMissionTop(msg)
    SLBridge:onLUAEvent(LUA_EVENT_TASK_TO_TOP, msg:GetHeader().recog)
end

function MissionProxy:CalcMissionOrderByID(id)
    local item = self:GetMissionByID(id)
    return item and item.order or 0
end

function MissionProxy:GetMissionByID(id)
    return self._data.items[id]
end

function MissionProxy:RequestSubmitMission(missionID)
    local item = self:GetMissionByID(missionID)
    self:SubmitMission(item)
end

function MissionProxy:SubmitMission(item)
    SendTableToServer(global.MsgType.MSG_SC_MISSION_SUBMIT, item)
end

function MissionProxy:RespMission(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return nil
    end
    self:UpdateMission(jsonData)
end

function MissionProxy:UpdateMission(item)
    -- item = {
    --     type = xx,
    --     head = {
    --         content = xx,
    --         color = xx,
    --     },
    --     body = {
    --         content = xx,
    --         color = xx,
    --     }
    --     flag = xx, 0 未接取 1进行中 2完成未提交
    -- }
    -- 有head表示增加或者修改
    -- 没有head表示删除
    -- 单条处理，有head就是新增或者修改，否则为删除
    if item.head then
        self:ChangeMissionItem(item)
    else
        self:RemoveMissionItem(item)
    end

    local loginProxy        = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    item.main_servid        = loginProxy:GetMainSelectedServerId()
    item.main_server_name   = loginProxy:GetMainSelectedServerName()

    local NativeBridgeProxy = global.Facade:retrieveProxy( global.ProxyTable.NativeBridgeProxy )
    NativeBridgeProxy:GN_Mission( item )

end

function MissionProxy:ChangeMissionItem(item)
    -- 任务是否已存在
    if self._data.items[item.type] then
        self._data.items[item.type] = item
        SLBridge:onLUAEvent(LUA_EVENT_TASK_CHANGE, item)
    else
        self._data.items[item.type] = item
        SLBridge:onLUAEvent(LUA_EVENT_TASK_ADD, item)
    end
end

function MissionProxy:RemoveMissionItem(item)
    if not self._data.items[item.type] then
        return false
    end
    self._data.items[item.type] = nil
    SLBridge:onLUAEvent(LUA_EVENT_TASK_DEL, item)
end

function MissionProxy:RegisterMsgHandler()
    MissionProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_MISSION_CHANGE, handler(self, self.RespMission))
    LuaRegisterMsgHandler(msgType.MSG_SC_MISSION_TOP, handler(self, self.RespMissionTop))
end

return MissionProxy