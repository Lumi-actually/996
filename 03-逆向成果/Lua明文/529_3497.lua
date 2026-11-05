local RemoteProxy    = requireProxy("RemoteProxy")
local HeroEquipProxy = class("HeroEquipProxy", RemoteProxy)
HeroEquipProxy.NAME = global.ProxyTable.HeroEquipProxy

require("GUIData/HeroEquipData")

function HeroEquipProxy:ctor()
    HeroEquipProxy.super.ctor(self)
    if HeroEquipData.Init then 
        HeroEquipData.Init()
    end
end

function HeroEquipProxy:handle_MSG_SC_EQUIP_Embattle_RESPONSE(netPkg)
    local data = netPkg:GetP0()
    local embattle = {}
    if data and data ~= 0 then
        embattle = {
            H16Bit(data), L16Bit(data)
        }
    end
    HeroEquipData.handle_MSG_SC_EQUIP_Embattle_RESPONSE(embattle)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_ON_FAIL(netPkg)
    local pos = netPkg:GetP0()
    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_ON_FAIL(pos)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS(netPkg)
    local pos = netPkg:GetP0()
    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS(pos)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS( netPkg )
    local pos = netPkg:GetP0()
    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS(pos)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL(netPkg)
    local header = netPkg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        errorCode = header.p1
    }
    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL(data)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_INFO_HERO(netPkg)
    local buffer = netPkg:GetBodyLuaBuffer()
    local nCount = netPkg:GetP0()

    local items  = {}
    for i = 1, nCount do
        items[i] = ReadItemData(buffer)
    end

    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_INFO(items)
end

function HeroEquipProxy:RequestBestRingsOpenState()
    
    LuaSendMsg(global.MsgType.MSG_CS_PLAYER_EQUIP_BEST_RINGS_STATE_HERO, 0, 0, 0, 0)
end

function HeroEquipProxy:handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE(netPkg)
    local state = netPkg:GetP0() == 1
    HeroEquipData.handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE(state)
end

function HeroEquipProxy:onRegister()
    HeroEquipProxy.super.onRegister(self)
end

function HeroEquipProxy:RegisterMsgHandler()
    HeroEquipProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    -- 初始化装备信息
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_INFO_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_INFO_HERO))
    -- 装备穿上确认-成功
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_ON_SUCCESS_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS))
    -- 装备穿上确认-失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_ON_FAIL_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_ON_FAIL))
    -- 装备脱下确认-成功
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_OFF_SUCCESS_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS))
    -- 装备脱下确认-失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_OFF_FAIL_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL))
    -- 首饰盒开启状态
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE_HERO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE))
    -- 法阵
    LuaRegisterMsgHandler( msgType.MSG_SC_EQUIP_Embattle_RESPONSE_HERO,handler(self, self.handle_MSG_SC_EQUIP_Embattle_RESPONSE) )
end

return HeroEquipProxy