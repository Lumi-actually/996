local RemoteProxy = requireProxy("RemoteProxy")
local EquipProxy = class("EquipProxy", RemoteProxy)
EquipProxy.NAME = global.ProxyTable.EquipProxy

require("GUIData/EquipData")
function EquipProxy:ctor()
    EquipProxy.super.ctor(self)
    if EquipData.Init then 
        EquipData.Init()
    end
end

function EquipProxy:handle_MSG_SC_EQUIP_Embattle_RESPONSE(netPkg)
    local data = netPkg:GetP0()
    local embattle = {}
    if data and data ~= 0 then
        embattle = {
            H16Bit(data), L16Bit(data)
        }
    end
    EquipData.handle_MSG_SC_EQUIP_Embattle_RESPONSE(embattle)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_ON_FAIL(netPkg)
    local pos = netPkg:GetP0()
    EquipData.handle_MSG_SC_PLAYER_EQUIP_ON_FAIL(pos)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS(netPkg)
    local pos = netPkg:GetP0()
    EquipData.handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS(pos)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS(netPkg)
    local header = netPkg:GetHeader13()     -- 脱成功 p1: 装备位 拖失败 p2: 装备位
    local pos = header.p1
    EquipData.handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS(pos)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL(netPkg)
    local header = netPkg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        errorCode = header.p1
    }
    EquipData.handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL(data)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_INFO(msg)
    local buffer = msg:GetBodyLuaBuffer()
    local nCount = msg:GetP0()

    local items  = {}
    for i = 1, nCount do
        items[i] = ReadItemData(buffer)
    end

    EquipData.handle_MSG_SC_PLAYER_EQUIP_INFO(items)
end

function EquipProxy:RequestBestRingsOpenState()
    LuaSendMsg(global.MsgType.MSG_CS_PLAYER_EQUIP_BEST_RINGS_STATE, 0, 0, 0, 0)
end

function EquipProxy:handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE(netPkg)
    local state = netPkg:GetP0() == 1
    EquipData.handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE(state)
end

function EquipProxy:onRegister()
    EquipProxy.super.onRegister(self)
end

function EquipProxy:RegisterMsgHandler()
    EquipProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    -- 初始化装备信息
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_INFO, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_INFO))
    -- 装备穿上确认-成功
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_ON_SUCCESS, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_ON_SUCCESS))
    -- 装备穿上确认-失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_ON_FAIL, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_ON_FAIL))
    -- 装备脱下确认-成功
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_OFF_SUCCESS, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_OFF_SUCCESS))
    -- 装备脱下确认-失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_OFF_FAIL, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_OFF_FAIL))
    -- 首饰盒开启状态
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE, handler(self, self.handle_MSG_SC_PLAYER_EQUIP_BEST_RINGS_STATE))
    -- 法阵
    LuaRegisterMsgHandler(msgType.MSG_SC_EQUIP_Embattle_RESPONSE,handler(self, self.handle_MSG_SC_EQUIP_Embattle_RESPONSE) )
end

return EquipProxy