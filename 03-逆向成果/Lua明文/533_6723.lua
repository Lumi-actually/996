local RemoteProxy = requireProxy("RemoteProxy")
local HeroBagProxy = class("HeroBagProxy", RemoteProxy)
HeroBagProxy.NAME = global.ProxyTable.HeroBagProxy
local tinsert = table.insert
require("GUIData/HeroBagData")

function HeroBagProxy:ctor()
    HeroBagProxy.super.ctor(self)
    if HeroBagData.Init then 
        HeroBagData.Init()
    end
end

-- 背包数据初始化
function HeroBagProxy:handle_MSG_SC_RETURN_BAGDATA_HERO(msg)
    local header = msg:GetHeader()
    local buffer = msg:GetBodyLuaBuffer()
    local dataCount = msg:GetP1()

    local data = {}
    if dataCount > 0 then 
        for i = 1, dataCount do
            local jsonData = ReadItemData(buffer)
            table.insert(data, jsonData)
        end
    end

    SL:onLUAEvent(LUA_EVENT_RETURN_HERO_BAGDATA, {header = header, data = data}) 
end

-- 增加道具
function HeroBagProxy:handle_MSG_SC_BAG_ADD_ITEM_HERO(msg)
    local header = msg:GetHeader()
    local buffer = msg:GetBodyLuaBuffer()
    local data = ReadItemData(buffer)
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_ADD_ITEM, {header = header, data = data}) 
end

-- 删除道具
function HeroBagProxy:handle_MSG_SC_BAG_DEL_ITEM_HERO(msg)
    local header = msg:GetHeader13()
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_DEL_ITEM, {header = header}) 
end

-- 更新道具
function HeroBagProxy:handle_MSG_SC_BAG_UPDATE_ITEM_HERO(msg)
    local buffer = msg:GetBodyLuaBuffer()
    local data = ReadItemData(buffer)
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_UPDATE_ITEM, {data = data}) 
end

--更新道具时间
function HeroBagProxy:handle_MSG_SM_HERO_UPDATEITEMTIME(msg)
    local header = msg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        limitRemainTime = header.p1,
        limitTimeActive = header.p2 and header.p2 == 1
    }
    local itemData = HeroBagData.GetItemDataByMakeIndex(data.makeIndex) or HeroEquipData.GetEquipDataByMakeIndex(data.makeIndex)
    if itemData then
        itemData.limitTimeActive = data.limitTimeActive
        itemData.limitRemainTime = data.limitRemainTime
        if itemData.limitTimeActive and itemData.limitRemainTime then
            itemData.limitEndTime = itemData.limitRemainTime + GetServerTime()
        end
    end
    SL:onLUAEvent(LUA_EVENT_BAG_UPDATE_ITEM_TIME, {data = data}) 
end

-- 道具使用失败
function HeroBagProxy:handle_MSG_SC_BAG_ITEM_USE_FAILED_HERO(msg)
    print("道具使用失败消息")
    local header = msg:GetHeader()
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_ITEM_USE_FAIL, {header = header}) 
end

-- 道具拾取失败 -1背包满 -2负重满 -3物品禁止拾取
function HeroBagProxy:handle_MSG_SC_DROP_ITEM_GET_FAILED(msg)
    local header = msg:GetHeader()
    SL:onLUAEvent(LUA_EVENT_HERO_DROP_ITEM_GET_FAIL, {header = header}) 
end

-- 丢弃道具成功
function HeroBagProxy:handle_MSG_SC_DROP_ITEM_SUCCESS(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_HERO_DROP_ITEM_SUCCESS, {header = header}) 
end

-- 丢弃道具失败
function HeroBagProxy:handle_MSG_SC_DROP_ITEM_FAILED(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_HERO_DROP_ITEM_FAIL, {header = header}) 
end

-- 英雄背包到人物背包失败
function HeroBagProxy:handle_MSG_SC_HEROBAG_TO_HUMBAG_FAIL(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_TO_HUMAN_BAG_FAIL, {header = header}) 
end

-- 叠加道具
function HeroBagProxy:RequestItemTwoToOne(MakeIndex1, MakeIndex2)
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_REQ_TWO_TO_ONE, {MakeIndex1 = MakeIndex1, MakeIndex2 = MakeIndex2})
    LuaSendHeader6(global.MsgType.MSG_CS_ITEM_TWO_TO_ONE, MakeIndex1, MakeIndex2)
end

-- 拆分道具
function HeroBagProxy:RequestCountItem(MakeIndex, num)
    SL:onLUAEvent(LUA_EVENT_HERO_BAG_REQ_NUMBER_CHANGE, {MakeIndex = MakeIndex, num = num})
    LuaSendHeader13(global.MsgType.MSG_CS_ITEM_NUMBER_CHANGE, MakeIndex, num, 0, 0)
end

--请求人物背包到英雄背包
function HeroBagProxy:RequestHumBagToHeroBag(MakeIndex, ItemName)
    SL:onLUAEvent(LUA_EVENT_REQ_HUM_BAG_TO_HERO_BAG, {MakeIndex = MakeIndex, ItemName = ItemName})
    LuaSendHeader13(global.MsgType.MSG_CS_HUMBAG_TO_HEROBAG, MakeIndex, 0, 0, 0, 0, ItemName)
end

--请求英雄背包到人物背包
function HeroBagProxy:RequestHeroBagToHumBag(MakeIndex, ItemName)
    SL:onLUAEvent(LUA_EVENT_REQ_HERO_BAG_TO_HUM_BAG, {MakeIndex = MakeIndex, ItemName = ItemName})
    LuaSendHeader13(global.MsgType.MSG_CS_HEROBAG_TO_HUMBAG, MakeIndex, 0, 0, 0, 0, ItemName)
end

--更新道具时间
function HeroBagProxy:handle_MSG_SM_HERO_UPDATEITEMTIME(msg)
    local header = msg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        limitRemainTime = header.p1,
        limitTimeActive = header.p2 and header.p2 == 1
    }
    local itemData = HeroBagData.GetItemDataByMakeIndex(data.makeIndex) or HeroEquipData.GetEquipDataByMakeIndex(data.makeIndex)
    if itemData then
        itemData.limitTimeActive = data.limitTimeActive
        itemData.limitRemainTime = data.limitRemainTime
        if itemData.limitTimeActive and itemData.limitRemainTime then
            itemData.limitEndTime = itemData.limitRemainTime + GetServerTime()
        end
    end
    SL:onLUAEvent(LUA_EVENT_BAG_UPDATE_ITEM_TIME, {data = data}) 
end

function HeroBagProxy:onRegister()
    HeroBagProxy.super.onRegister(self)
end

function HeroBagProxy:RegisterMsgHandler()
    HeroBagProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_RETURN_BAGDATA_HERO, handler(self, self.handle_MSG_SC_RETURN_BAGDATA_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_ADD_ITEM_HERO, handler(self, self.handle_MSG_SC_BAG_ADD_ITEM_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_DEL_ITEM_HERO, handler(self, self.handle_MSG_SC_BAG_DEL_ITEM_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_UPDATE_ITEM_HERO, handler(self, self.handle_MSG_SC_BAG_UPDATE_ITEM_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_ITEM_USE_FAILED_HERO, handler(self, self.handle_MSG_SC_BAG_ITEM_USE_FAILED_HERO))
    LuaRegisterMsgHandler(msgType.MSG_SC_DROP_ITEM_SUCCESS_HERO, handler(self, self.handle_MSG_SC_DROP_ITEM_SUCCESS))
    LuaRegisterMsgHandler(msgType.MSG_SC_DROP_ITEM_FAILED_HERO, handler(self, self.handle_MSG_SC_DROP_ITEM_FAILED))
    LuaRegisterMsgHandler(msgType.MSG_SC_HEROBAG_TO_HUMBAG_FAIL, handler(self, self.handle_MSG_SC_HEROBAG_TO_HUMBAG_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SM_HEROUPDATEITEMTIME, handler(self, self.handle_MSG_SM_HERO_UPDATEITEMTIME))
end

return HeroBagProxy