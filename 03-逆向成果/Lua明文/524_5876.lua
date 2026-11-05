local RemoteProxy = requireProxy("RemoteProxy")
local TradingBankLookPlayerProxy = class("TradingBankLookPlayerProxy", RemoteProxy)
TradingBankLookPlayerProxy.NAME = global.ProxyTable.TradingBankLookPlayerProxy

require("GUIData/TradingBankLookPlayerData")
function TradingBankLookPlayerProxy:ctor()
    TradingBankLookPlayerProxy.super.ctor(self)
    self.SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.Skill)
    if TradingBankLookPlayerData then 
        TradingBankLookPlayerData.Init()
    end
    self._tempData = {}
end

function TradingBankLookPlayerProxy:onRegister()
    TradingBankLookPlayerProxy.super.onRegister(self)
end

function TradingBankLookPlayerProxy:handle_MSG_SC_ROLE_INFO_RESPONSE(msg)
    local p0 = msg:GetP0()
    -- dump(p0,"handle_MSG_SC_ROLE_INFO_RESPONSE____")
    if p0 == 1 or p0 == 2 then--bag --
        local dataCount = msg:GetP1()
        local buffer = msg:GetBodyLuaBuffer()
        self._tempData.bagItems = self._tempData.bagItems or {}
        for i = 1, dataCount do
            local item = ReadItemData(buffer)
            table.insert(self._tempData.bagItems, item)
        end
        return
    elseif p0 == 3 then --storeItems
        local dataCount = msg:GetP1()
        local buffer = msg:GetBodyLuaBuffer()
        self._tempData.storeItems = self._tempData.storeItems or {}
        for i = 1, dataCount do
            local item = ReadItemData(buffer)
            table.insert(self._tempData.storeItems, item)
        end
        return
    elseif p0 == 4 then --equip
        local dataCount = msg:GetP1()
        local buffer = msg:GetBodyLuaBuffer()
        self._tempData.equips = self._tempData.equips or {}
        for i = 1, dataCount do
            local item = ReadItemData(buffer)
            table.insert(self._tempData.equips, item)
        end
        return
    elseif p0 == 5 then --baseAttr
        local buffer = msg:GetBodyLuaBuffer()
        if buffer == nil then
            return
        end
        self._tempData.arrCurAbil = G_BufferReadArrInt64(buffer, 256, 0)
        self._tempData.arrMaxAbil = G_BufferReadArrInt64(buffer, 256, 0)
        return
    elseif p0 == 7 then--heroBag --
        local dataCount = msg:GetP1()
        local buffer = msg:GetBodyLuaBuffer()
        self._tempData.HeroData = self._tempData.HeroData or {}
        self._tempData.HeroData.bagItems = self._tempData.HeroData.bagItems or {}
        for i = 1, dataCount do
            local item = ReadItemData(buffer)
            table.insert(self._tempData.HeroData.bagItems, item)
        end
        return
    elseif p0 == 8 then --heroEquip
        local dataCount = msg:GetP1()
        local buffer = msg:GetBodyLuaBuffer()
        if buffer == nil then
            return
        end
        self._tempData.HeroData = self._tempData.HeroData or {}
        self._tempData.HeroData.equips = self._tempData.HeroData.equips or {}
        for i = 1, dataCount do
            local item = ReadItemData(buffer)
            table.insert(self._tempData.HeroData.equips, item)
        end
        return
    elseif p0 == 9 then --heroBaseAttr
        local buffer = msg:GetBodyLuaBuffer()
        if buffer == nil then
            return
        end
        self._tempData.HeroData = self._tempData.HeroData or {}
        self._tempData.HeroData.arrCurAbil = G_BufferReadArrInt64(buffer, 256, 0)
        self._tempData.HeroData.arrMaxAbil = G_BufferReadArrInt64(buffer, 256, 0)
        return

    elseif p0 == 10 or p0 == 11 or p0 == 12 or p0 == 13 or p0 == 14 then
        local nCount = msg:GetP1()
        if nCount < 1 then
            return
        end
        local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
        local jsonData = msg:GetJsonData()
        for i = 1, nCount do
            local v = SL:JsonDecode(jsonData[i])
            if v and v.ID then
                MetaValueProxy:SetCustomVar(v.ID, v)
            end
        end
        return
    end
    --p0 == 6
    local data = ParseRawMsgToJson(msg)
    -- dump(data,"data__")
    data.bagItems = self._tempData.bagItems or {}
    data.storeItems = self._tempData.storeItems or {}
    data.equips = self._tempData.equips or {}
    data.arrCurAbil = self._tempData.arrCurAbil or {}
    data.arrMaxAbil =self._tempData.arrMaxAbil or {}

    if data.HeroData or self._tempData.HeroData then 
        data.HeroData = data.HeroData or {}
        data.HeroData.bagItems = self._tempData.HeroData.bagItems or {}
        data.HeroData.equips = self._tempData.HeroData.equips or {}
        data.HeroData.arrCurAbil = self._tempData.HeroData.arrCurAbil or {}
        data.HeroData.arrMaxAbil = self._tempData.HeroData.arrMaxAbil or {}
    end
    self._tempData = {}
    -- print("=====查看玩家")
    -- dump(data,"data___")
    TradingBankLookPlayerData.handle_MSG_SC_ROLE_INFO_RESPONSE(data)
    
    if self._func then
        self._func()
    end
end


function TradingBankLookPlayerProxy:RequestPlayerData(uid, func)
    dump(uid, "uid____")
    if uid == nil then
        return
    end
    self._func = func
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    if HeroPropertyProxy:IsHeroOpen() then
        LuaSendMsg(global.MsgType.MSG_CM_GETPLAYERINFO, uid, 1, 0, 0)
    else
        LuaSendMsg(global.MsgType.MSG_CM_GETPLAYERINFO, uid, 0, 0, 0)
    end

end

function TradingBankLookPlayerProxy:RegisterMsgHandler()
    TradingBankLookPlayerProxy.super.RegisterMsgHandler(self)

    local msgType    = global.MsgType
    --预请求查看数据
    LuaRegisterMsgHandler(msgType.MSG_SC_GETPLAYERINFO, handler(self, self.handle_MSG_SC_ROLE_INFO_RESPONSE))
end

return TradingBankLookPlayerProxy