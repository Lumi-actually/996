local RemoteProxy = requireProxy("RemoteProxy")
local RankProxy = class("RankProxy", RemoteProxy)
RankProxy.NAME = global.ProxyTable.RankProxy

function RankProxy:ctor()
    RankProxy.super.ctor(self)
    self._rankData = {}
    self._rankData_hero = {}
    self._rankConfig = {}
end

function RankProxy:SetListRankData(rankID, data)
    rankID = rankID + 1
    self._rankData[rankID] = data
end

function RankProxy:SetListRankData_hero(rankID, data)
    rankID = rankID + 1
    self._rankData_hero[rankID] = data
end

function RankProxy:GetRankDataByID(rankID)
    if not rankID or not self._rankData then
        return nil
    end
    return self._rankData[rankID]
end

function RankProxy:GetRankDataByID_hero(rankID)
    if not rankID or not self._rankData_hero then
        return nil
    end
    return self._rankData_hero[rankID]
end

function RankProxy:GetRankConfig()
    return self._rankConfig
end

function RankProxy:RequestRankConfig()
    LuaSendMsg(global.MsgType.MSG_CS_RANK_SET_CONFIG_REQUEST)
end

function RankProxy:RequestListData(rankType, selectType)
    rankType = math.max(rankType - 1, 0)
    selectType = selectType - 1
    LuaSendMsg(global.MsgType.MSG_CS_RANK_LIST_DATA_REQUEST, rankType, selectType, 0, 0)
end

function RankProxy:RequestPlayerShowData(playerUid, type)
    LuaSendMsg(global.MsgType.MSG_CS_RANK_PLAYER_DATA_REQUEST, type, 0, 0, 0, playerUid, string.len(playerUid))
end

function RankProxy:RequestNotifyClickRankType(type)
    -- 0玩家 1英雄
    type = type - 1 
    LuaSendMsg(global.MsgType.MSG_CS_CLICK_RANK_TYPE, type)
end

function RankProxy:RequestNotifyClickRankValue(rank)
    LuaSendMsg(global.MsgType.MSG_CS_CLICK_RANK_VALUE, rank)
end

function RankProxy:handle_MSG_SC_RANK_SET_CONFIG_RESPONSE(msg)
    local jsonData = msg:GetJsonData()
    if not jsonData then
        return
    end
    --  id  group  name  valuename  cuscol
    -- 服务端数据id从0开始
    local config = {}
    local typeList = {}
    local typeNum = 1
    for i, v in ipairs(jsonData) do
        if v.enable and v.enable == 1 then
            v.id = v.id + 1
            if v.group and not typeList[v.group] then
                typeList[v.group] = typeNum
                typeNum = typeNum + 1
            end
            local index = typeList[v.group]
            config[index] = config[index] or {}
            table.insert(config[index], v)
        end
    end
    self._rankConfig = config
end

function RankProxy:handle_MSG_SC_RANK_LIST_DATA_RESPONSE(msg)
    local rankID = msg:GetP0()
    local selectType = msg:GetP1()
    local rankData = msg:GetJsonData()
    -- UserID  Name  Job  Sex  Value  Level  GuildName
    if not rankData then
        return
    end

    if selectType == 0 then
        self:SetListRankData(rankID, rankData)
    else
        self:SetListRankData_hero(rankID, rankData)
    end

    SLBridge:onLUAEvent(LUA_EVENT_RANK_DATA_UPDATE, {rankType = rankID, selectType = selectType + 1})
end

function RankProxy:handle_MSG_SC_RANK_PLAYER_DATA_RESPONSE(msg)
    local jsonData = msg:GetJsonData() or {}

    SLBridge:onLUAEvent(LUA_EVENT_RANK_PLAYER_UPDATE, jsonData)
end

function RankProxy:RegisterMsgHandler()
    RankProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_RANK_LIST_DATA_RESPONSE, handler(self, self.handle_MSG_SC_RANK_LIST_DATA_RESPONSE))
    LuaRegisterMsgHandler(msgType.MSG_SC_RANK_PLAYER_DATA_RESPONSE, handler(self, self.handle_MSG_SC_RANK_PLAYER_DATA_RESPONSE))
    LuaRegisterMsgHandler(msgType.MSG_SC_RANK_SET_CONFIG_RESPONSE, handler(self, self.handle_MSG_SC_RANK_SET_CONFIG_RESPONSE))
end

return RankProxy