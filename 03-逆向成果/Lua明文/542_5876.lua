local RemoteProxy = requireProxy("RemoteProxy")
local MeridianProxy = class("MeridianProxy", RemoteProxy)
MeridianProxy.NAME = global.ProxyTable.MeridianProxy

local optionsUtils = requireUtil("optionsUtils")

function MeridianProxy:ctor()
    MeridianProxy.super.ctor(self)

    -- 人物
    self._meridianLvList = {}
    self._meridianOpenList = {}
    -- 英雄
    self._heroMeridianLvList = {}
    self._heroMeridianOpenList = {}

    self._extraNgHudShow = true    -- 内功hud显示(客户端接口额外控制)

    self._config = {}
    self:LoadConfig()
end

function MeridianProxy:LoadConfig()
    self._config = requireGameConfig("cfg_PulsDesc")
end

function MeridianProxy:GetTipsConfig()
    return self._config
end

function MeridianProxy:GetAucPointStateByType(type, isHero)
    if type then
        if isHero then
            return self["_mHeroAucPointList_".. type] or {}
        else
            return self["_mAucPointList_".. type] or {}
        end
    end
    return nil
end

function MeridianProxy:GetMeridianOpenList(isHero)
    if isHero then
        return self._heroMeridianOpenList
    else
        return self._meridianOpenList
    end
end

function MeridianProxy:GetMeridianLvByType(type, isHero)
    if isHero then
        return self._heroMeridianLvList[type] or 0
    else
        return self._meridianLvList[type] or 0
    end
end

function MeridianProxy:GetExtraNGHudShow()
    return self._extraNgHudShow
end

function MeridianProxy:SetExtraNGHudShow(state)
    self._extraNgHudShow = state
end

function MeridianProxy:OnRefreshNGHudShow()
    local players, nPlayer = global.playerManager:FindAllPlayerInCurrViewField()
    for i = 1, nPlayer do
        local player = players[i]
        if player then
            optionsUtils:InitHUDVisibleValue(player, global.MMO.HUD_NGBAR_VISIBLE)
            optionsUtils:CheckHUDNGBarVisible(player)
        end
    end
end

function MeridianProxy:RequestAucPointOpen(typeID, aucPointID, isHero)
    LuaSendMsg(global.MsgType.MSG_CS_MERIDIAN_ACUPOINT_OPEN, typeID, aucPointID, isHero and 1 or 0)
end

function MeridianProxy:RequestMeridianLevelUp(typeID, isHero)
    LuaSendMsg(global.MsgType.MSG_CS_MERIDIAN_LEVELUP, typeID, isHero and 1 or 0)
end

function MeridianProxy:RequestGetMeridianInfo(isHero)
    LuaSendMsg(global.MsgType.MSG_CS_MERIDIAN_GET_INFO, isHero and 1 or 0)
end

-- 经络ID 冲脉=1    阴跷=2    阴维=3    任脉=4    奇经=5 (服务端-1)
function MeridianProxy:handle_MSG_SC_MERIDIAN_GET_INFO(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return
    end
    local header = msg:GetHeader()
    local type = header.param1
    -- dump(jsonData, "________handle_MSG_SC_MERIDIAN_GET_INFO"..type)
    if type == 0 then --人物
        -- 各经络对应等级
        self._meridianLvList = jsonData.NGPulseMainLv
        -- 各经络各穴位开关状态 0为未激活 1已激活
        for i = 1, 5 do
            if not self["_mAucPointList_".. i] then
                self["_mAucPointList_".. i] = {}
            end
            self["_mAucPointList_" .. i] = jsonData["NGPulseSubLv" .. i]
        end
        -- 各经络开关状态
        self._meridianOpenList = jsonData.NGPulseState
        SLBridge:onLUAEvent(LUA_EVENT_MERIDIAN_DATA_REFRESH)
    elseif type == 1 then -- 英雄
        self._heroMeridianLvList = jsonData.NGPulseMainLv
        for i = 1, 5 do
            if not self["_mHeroAucPointList_".. i] then
                self["_mHeroAucPointList_".. i] = {}
            end
            self["_mHeroAucPointList_" .. i] = jsonData["NGPulseSubLv" .. i]
        end
        self._heroMeridianOpenList = jsonData.NGPulseState
        SLBridge:onLUAEvent(LUA_EVENT_HERO_MERIDIAN_DATA_REFRESH)
    end
end

function MeridianProxy:handle_MSG_SC_MERIDIAN_INFO_UPDATE(msg)
    local jsonData = ParseRawMsgToJson(msg)
    if not jsonData then
        return
    end
    local header = msg:GetHeader()
    local type = header.param1
    -- dump(jsonData, "_______handle_MSG_SC_MERIDIAN_INFO_UPDATE"..type)
    if type == 0 then
        -- 各经络对应等级
        if jsonData.NGPulseMainLv then
            self._meridianLvList = jsonData.NGPulseMainLv
        end
        -- 各经络各穴位开关状态
        for i = 1, 5 do
            if jsonData["NGPulseSubLv" .. i] then
                self["_mAucPointList_" .. i] = jsonData["NGPulseSubLv" .. i]
            end
        end
        -- 各经络开关状态
        if jsonData.NGPulseState then
            self._meridianOpenList = jsonData.NGPulseState
        end
        SLBridge:onLUAEvent(LUA_EVENT_MERIDIAN_DATA_REFRESH)
    else
        -- 各经络对应等级
        if jsonData.NGPulseMainLv then
            self._heroMeridianLvList = jsonData.NGPulseMainLv
        end
        -- 各经络各穴位开关状态
        for i = 1, 5 do
            if jsonData["NGPulseSubLv" .. i] then
                self["_mHeroAucPointList_" .. i] = jsonData["NGPulseSubLv" .. i]
            end
        end
        -- 各经络开关状态
        if jsonData.NGPulseState then
            self._heroMeridianOpenList = jsonData.NGPulseState
        end
        SLBridge:onLUAEvent(LUA_EVENT_HERO_MERIDIAN_DATA_REFRESH)
    end
end

function MeridianProxy:RegisterMsgHandler()
    MeridianProxy.super.RegisterMsgHandler(self)

    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_MERIDIAN_GET_INFO, handler(self, self.handle_MSG_SC_MERIDIAN_GET_INFO))           -- 初始化经络信息
    LuaRegisterMsgHandler(msgType.MSG_SC_MERIDIAN_INFO_UPDATE, handler(self, self.handle_MSG_SC_MERIDIAN_INFO_UPDATE))     -- 刷新经络信息
end

return MeridianProxy
