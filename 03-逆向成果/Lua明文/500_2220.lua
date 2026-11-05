local RemoteProxy = requireProxy("RemoteProxy")
local MiniMapProxy = class("MiniMapProxy", RemoteProxy)
MiniMapProxy.NAME = global.ProxyTable.MiniMapProxy

require("GUIData/MiniMapData")

local cjson = require("cjson")
function MiniMapProxy:ctor()
    MiniMapProxy.super.ctor(self)

    self._monsters = {}
    self._teamData = {}
    
    if MiniMapData.Init then
        MiniMapData.Init()
    end
end

function MiniMapProxy:getMonsters()
    return self._monsters
end

function MiniMapProxy:getTeams()
    return self._teamData
end

function MiniMapProxy:RespMonsters(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return nil
    end

    local tag = msg:GetP0()
    if tag == 1 then -- 其他地图怪物数据 并打开/刷新小地图
        -- open
        jsonData.Info = jsonData.Info and cjson.decode(jsonData.Info)
        UIOperator:OpenOtherMiniMap(jsonData)

    else
        self._monsters = jsonData
        SL:onLUAEvent(LUA_EVENT_MINIMAP_MONSTER)
    end
end

function MiniMapProxy:RequestMonsters()
    local mapID = SL:GetValue("MAP_ID")
    if not mapID then
        return
    end
    LuaSendMsg(global.MsgType.MSG_CS_MINIMAP_MONSTERS_POINT, 0, 0, 0, 0, mapID, string.len(mapID))
end

function MiniMapProxy:RespTeamMemebersData(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return nil
    end
    self._teamData = jsonData
    SL:onLUAEvent(LUA_EVENT_MINIMAP_TEAM, jsonData)
end

function MiniMapProxy:RequestTeamMemberData()
    LuaSendMsg(global.MsgType.MSG_CS_TEAMMEMEBER_DATA)
end

function MiniMapProxy:RequestNotifyCrossMapClickPos(mapX, mapY)
    LuaSendMsg(global.MsgType.MSG_CS_CLICK_REMOTE_MAP, mapX, mapY)
end

function MiniMapProxy:RegisterMsgHandler()
    MiniMapProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    -- 返回 小地图 怪物坐标
    LuaRegisterMsgHandler(msgType.MSG_SC_MINIMAP_MONSTERS_POINT, handler(self, self.RespMonsters))    
    --返回组队成员信息 
    LuaRegisterMsgHandler(msgType.MSG_SC_MINIMAP_TEAM_DATA, handler(self, self.RespTeamMemebersData))  
end

return MiniMapProxy