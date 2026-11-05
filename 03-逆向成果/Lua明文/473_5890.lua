local RemoteProxy    = requireProxy("RemoteProxy")
local DarkLayerProxy = class("DarkLayerProxy", RemoteProxy)
DarkLayerProxy.NAME = global.ProxyTable.DarkLayerProxy
local offset = cc.p(0, global.MMO.PLAYER_AVATAR_OFFSET.y)
local shareT1 = {}
local shareT2 = {offset = offset}
DarkLayerProxy.MODE = {
    day  = 0,           -- 全天白天
    dark = 1            -- 有黑夜
}

-- 0-白天，1-黑夜，2-日出，3-傍晚
DarkLayerProxy.STATE = {
    daytime = 0,        -- 白天
    night   = 1,        -- 晚上
    sunrise = 2,        -- 日出  
    evening = 3         -- 傍晚
}

DarkLayerProxy.Opacity = {
    [DarkLayerProxy.STATE.daytime] = 0,
    [DarkLayerProxy.STATE.night] = 1,
    [DarkLayerProxy.STATE.sunrise] = 0.5,
    [DarkLayerProxy.STATE.evening] = 0.5
}

DarkLayerProxy.LIGHT_TYPE = {
    Default     = {r = 2.5, w = 1.5},           -- 自身默认
    Two_Skill   = {r = 2, w = 1.9},             -- 
    Custom1     = {r = 1 , w = 1},
}


function DarkLayerProxy:ctor()
    DarkLayerProxy.super.ctor(self)

    self._state = DarkLayerProxy.STATE.daytime
    self._mode = DarkLayerProxy.MODE.day
    self.lastState = DarkLayerProxy.STATE.daytime
end

function DarkLayerProxy:setLastState(state)
    if self.lastState ~= state then
        self.lastState = state
    end
end

function DarkLayerProxy:getLastState()
    return self.lastState
end

function DarkLayerProxy:onRegister()
    DarkLayerProxy.super.onRegister(self)
end

function DarkLayerProxy:handle_MSG_SC_DAYSTATE(msg)
    local header = msg:GetHeader()
    local state = header.param2 --0-白天，1-黑夜，2-日出，3-傍晚
    dump(header, "handle_MSG_SC_DAYSTATE___")
    self:setState(state)
    local mode = header.param1--0 全域白天   1 以地图设定为优先级   地图未设定 以时间为准
    self:setMode(mode)
    SL:onLUAEvent(LUA_EVENT_DARK_STATE_CHANGE)
end

function DarkLayerProxy:GetLightData(num, actorID)
    -- 啥也没带
    if num == 0 then
        if  global.gamePlayerController:GetMainPlayerID() == actorID then 
            return DarkLayerProxy.LIGHT_TYPE.Default
        else
            return nil
        end
    else 
        local t = clone(DarkLayerProxy.LIGHT_TYPE.Custom1)
        t.r = t.r + num
        return t
    end
end

function DarkLayerProxy:handle_MSG_SC_CHANGECANDLE(msg)
    local header = msg:GetHeader()
    local num = header.param1--人物携带蜡烛状态 格子数
    dump(header, "handle_MSG_SC_CHANGECANDLE___")
    local msgLen = msg:GetDataLength()
    local actorID = msg:GetBodyStr()

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end
    local lightData
    -- 啥也没带
    if num == 0 then
        if global.gamePlayerController:GetMainPlayerID() == actorID or SL:GetValue("HERO_ID") == actorID then 
            lightData =  DarkLayerProxy.LIGHT_TYPE.Default
        end
    else 
        local t = clone(DarkLayerProxy.LIGHT_TYPE.Custom1)
        t.r = t.r + num
        t.w = t.w + num
        lightData = t
    end
    local lightID = actor:GetLightID()
    if lightID then
        if lightData then
            shareT1.r = lightData.r
            shareT1.w = lightData.w
            global.darkNodeManager:updateNode(lightID, shareT1)
        else
            global.darkNodeManager:removeNode(lightID)
            actor:SetLightID(nil)
        end
    elseif lightData then 
        local wX, wY = global.sceneManager:MapPos2WorldPos(actor:GetMapX(), actor:GetMapY(), true)
        shareT2.x = wX
        shareT2.y = wY
        shareT2.r = lightData.r
        shareT2.w = lightData.w
        lightID = global.darkNodeManager:createNode(shareT2)
        actor:SetLightID(lightID)
    end
end

function DarkLayerProxy:getUnit()
    return math.max(global.MMO.MapGridWidth, global.MMO.MapGridHeight)
end

-- state --0-白天，1-黑夜，2-日出，3-傍晚
function DarkLayerProxy:setState(state)
    if state ~= self._state then 
        self._state = state
    end
end

function DarkLayerProxy:getOpacity()
    return DarkLayerProxy.Opacity[self:getCurState()]
end
-- 获取当前状态
function DarkLayerProxy:getState()
    return self._state
end

-- 获取当前状态 （根据地图属性  模式等）  
function DarkLayerProxy:getCurState()
    local mode = self:getMode()
    local state = self:getState()
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local mapFlag = MapProxy:GetFlag()
    local mapnight = bit.band(bit.rshift(mapFlag, 9), 1) == 1
    local mapday = bit.band(bit.rshift(mapFlag, 10), 1) == 1
    if mapnight or mapday then--优先以地图的时间状态为准
        if mapnight then--优先黑夜
            state = DarkLayerProxy.STATE.night
        else
            state = DarkLayerProxy.STATE.daytime
        end
    end

    if mode == DarkLayerProxy.MODE.day then--全域白天
        state = DarkLayerProxy.STATE.daytime
    end
    return state
end

--mode 0 全域白天   1 以地图设定为优先级   地图未设定 以时间为准
function DarkLayerProxy:setMode(mode)
    if mode == 0 then
        self._mode = DarkLayerProxy.MODE.day
    elseif mode == 1 then
        self._mode = DarkLayerProxy.MODE.dark
    end
end

function DarkLayerProxy:getMode()
    return self._mode
end

function DarkLayerProxy:RegisterMsgHandler()
    DarkLayerProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_DAYSTATE, handler(self, self.handle_MSG_SC_DAYSTATE))          -- 昼夜状态
    LuaRegisterMsgHandler(msgType.MSG_SC_CHANGECANDLE, handler(self, self.handle_MSG_SC_CHANGECANDLE))  -- 切换蜡烛状态
end

return DarkLayerProxy