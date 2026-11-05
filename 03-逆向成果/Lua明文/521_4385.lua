local RemoteProxy = requireProxy("RemoteProxy")
local SceneEffectProxy = class("SceneEffectProxy", RemoteProxy)
SceneEffectProxy.NAME = global.ProxyTable.SceneEffectProxy


function SceneEffectProxy:ctor()
    SceneEffectProxy.super.ctor(self)
    self._mapEffectList = {}
end

function SceneEffectProxy:GetWeatherEffList(...)
    return self._mapEffectList
end

function SceneEffectProxy:ClearWeatherEffList()
    self._mapEffectList = {}
end

function SceneEffectProxy:handle_MSG_SC_SCREEN_EFFECT_PLAY(msg)
    local data = ParseRawMsgToJson(msg)
    if not data or not next(data) then
        return nil
    end
    local item = {
        id = data.nEffectItemId,
        effectId = data.nEffectId,
        x = data.nClientX,
        y = data.nClientY,
        speed = data.nPlaySpeed,
        times = data.nPlayCount,
        mode = data.nPlayMode,
    }
    PlayEffectOnScreen(item)
end

function SceneEffectProxy:handle_MSG_SC_SCREEN_EFFECT_REMOVE(msg)
    local data = ParseRawMsgToJson(msg)
    dump(data)
    if not data or not next(data) then
        return nil
    end
    local removeName = tostring(data.nEffectItemId)

    global.Facade:sendNotification(global.NoticeTable.Layer_Notice_RemoveChild, removeName)
end

function SceneEffectProxy:handle_MSG_SC_PLAY_WEATHER_EFFECT(msg)
    local header = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    local dataString = msg:GetBodyStr()
    local time = header.param1
    local mode = header.recog   -- 1黄沙 2花瓣 3下雪
    local mapID = dataString

    if not self._mapEffectList[mapID] then
        self._mapEffectList[mapID] = {}
    end
    table.insert(self._mapEffectList[mapID], { mapID = mapID, time = time, mode = mode })
    local weather = { mapID = mapID, time = time, mode = mode }

    global.Facade:sendNotification(global.NoticeTable.Scene_Weather_Effect_Add, { params = weather })
end

function SceneEffectProxy:handle_MSG_SC_PLAY_MAP_ALL_WEATHER(msg)
    local header = msg:GetHeader()
    local num = header.recog  -- 数量
    local msgLen = msg:GetDataLength()
    local dataString = msg:GetBodyStr()   -- 格式：ID,time,map;ID,time,map
    local list = G_GetSplitArray(dataString, ";")
    for _, data in ipairs(list) do
        if data and string.len(data) > 0 then
            local params = G_GetSplitArray(data, ",")
            if params[1] and params[2] and params[3] then
                local mapID = params[3]
                if not self._mapEffectList[mapID] then
                    self._mapEffectList[mapID] = {}
                end
                table.insert(self._mapEffectList[mapID], { mapID = mapID, time = tonumber(params[2]), mode = tonumber(params[1]) })
            end
        end
    end

    global.Facade:sendNotification(global.NoticeTable.Scene_Weather_Effect_Add, { init = true })
end

function SceneEffectProxy:handle_MSG_SC_CLEAR_WEATHER_BY_MAP(msg)
    local header = msg:GetHeader()
    local mode = header.recog  -- 特效ID  -- 0:全清理
    local dataString = msg:GetBodyStr()
    local mapID = dataString

    if mode == 0 then
        self._mapEffectList[mapID] = nil
    elseif self._mapEffectList[mapID] then
        local newList = {}
        for _, data in ipairs(self._mapEffectList[mapID]) do
            if data.mode ~= mode then
                table.insert(newList, data)
            end
        end
        self._mapEffectList[mapID] = #newList > 0 and newList or nil
    end

    global.Facade:sendNotification(global.NoticeTable.Scene_Weather_Effect_Remove, mode)
end

function SceneEffectProxy:onRegister()
    SceneEffectProxy.super.onRegister(self)
    local msgType    = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_SCREEN_EFFECT_PLAY, handler(self, self.handle_MSG_SC_SCREEN_EFFECT_PLAY))
    LuaRegisterMsgHandler(msgType.MSG_SC_SCREEN_EFFECT_REMOVE, handler(self, self.handle_MSG_SC_SCREEN_EFFECT_REMOVE))
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAY_WEATHER_EFFECT, handler(self, self.handle_MSG_SC_PLAY_WEATHER_EFFECT))
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAY_MAP_ALL_WEATHER, handler(self, self.handle_MSG_SC_PLAY_MAP_ALL_WEATHER))
    LuaRegisterMsgHandler(msgType.MSG_SC_CLEAR_WEATHER_BY_MAP, handler(self, self.handle_MSG_SC_CLEAR_WEATHER_BY_MAP))
end


return SceneEffectProxy