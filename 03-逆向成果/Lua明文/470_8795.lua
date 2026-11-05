local RemoteProxy = requireProxy("RemoteProxy")
local BagProxy = class("BagProxy", RemoteProxy)
BagProxy.NAME = global.ProxyTable.BagProxy

require("GUIData/BagData")
function BagProxy:ctor()
    BagProxy.super.ctor(self)
    if BagData.Init then 
        BagData.Init()
    end
end

-- 背包数据初始化
function BagProxy:handle_MSG_SC_RETURN_BAGDATA(msg , msgID)
    -- print("------------------------------------")
    -- print(" into here to get and set bag data")
    -- print("------------------------------------")
    -----------------------------------------------------------
    local buffer = msg:GetBodyLuaBuffer()
    local dataCount = msg:GetP0()
    local finish = msg:GetP1() == 0
    dump(finish,"finish___")
    self._tempItems = self._tempItems or {}
    for i = 1, dataCount do
        local jsonData = ReadItemData(buffer)
        table.insert(self._tempItems, jsonData)
    end
    if not finish then 
        return 
    end

    SL:onLUAEvent(LUA_EVENT_RETURN_BAGDATA, {data = self._tempItems}) 
    self._tempItems = nil
end

-- 增加道具
function BagProxy:handle_MSG_SC_BAG_ADD_ITEM(msg)
    local header = msg:GetHeader()
    local recog = header.recog
    -- print("------------------------------------")
    -- print(" into here to add bag item")
    -- print("------------------------------------")
    local buffer = msg:GetBodyLuaBuffer()
    local data = ReadItemData(buffer)

    SL:onLUAEvent(LUA_EVENT_BAG_ADD_ITEM, {header = header, data = data}) 
end

-- 删除道具
function BagProxy:handle_MSG_SC_BAG_DEL_ITEM(msg)
    local header = msg:GetHeader13()
    SL:onLUAEvent(LUA_EVENT_BAG_DEL_ITEM, {header = header}) 
end

-- 更新道具
function BagProxy:handle_MSG_SC_BAG_UPDATE_ITEM(msg)
    local buffer = msg:GetBodyLuaBuffer()
    local data = ReadItemData(buffer)
    SL:onLUAEvent(LUA_EVENT_BAG_UPDATE_ITEM, {data = data}) 
end

--更新道具时间
function BagProxy:handle_MSG_SM_UPDATEITEMTIME(msg)
    local header = msg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        limitRemainTime = header.p1,
        limitTimeActive = header.p2 and header.p2 == 1
    }

    local itemData = BagData.GetItemDataByMakeIndex(data.makeIndex) or EquipData.GetEquipDataByMakeIndex(data.makeIndex)
    if itemData then
        itemData.limitTimeActive = data.limitTimeActive
        itemData.limitRemainTime = data.limitRemainTime
        if itemData.limitTimeActive and itemData.limitRemainTime then
            itemData.limitEndTime = itemData.limitRemainTime + GetServerTime()
        end
    end
    SL:onLUAEvent(LUA_EVENT_BAG_UPDATE_ITEM_TIME, {data = data}) 
end

function BagProxy:handle_MSG_SC_BAG_ITEM_USE_SUCCESS(msg)
    local header = msg:GetHeader13()
    header.recog = header.Guid
    SL:onLUAEvent(LUA_EVENT_BAG_ITEM_USE_SUCCESS, {header = header})
end

-- 道具使用失败
function BagProxy:handle_MSG_SC_BAG_ITEM_USE_FAILED(msg)
    local header = msg:GetHeader13()
    -- 兼容原触发参数
    header.recog = header.Guid
    SL:onLUAEvent(LUA_EVENT_BAG_ITEM_USE_FAIL, {header = header}) 
end

-- 道具拾取失败 -1背包满 -2负重满 -3物品禁止拾取 -99假道具拾取
function BagProxy:handle_MSG_SC_DROP_ITEM_GET_FAILED(msg)
    local header = msg:GetHeader()
    local recog = header.recog
    if recog == -99 then
        local mapX = header.param1
        local mapY = header.param2
        local dItems = global.dropItemManager:FindAllDropItemByXY(mapX, mapY)
        if not dItems then
            return
        end
        for k, dItem in pairs(dItems) do
            if dItem:GetPickState() >= 1 or dItem:IsPickTimeout() then --移除
                global.gameMapController:RmvDropItem(dItem:GetID())
            end
        end
    else 
        SL:onLUAEvent(LUA_EVENT_DROP_ITEM_GET_FAIL, {header = header}) 
    end
end

-- 丢弃道具成功
function BagProxy:handle_MSG_SC_DROP_ITEM_SUCCESS(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_DROP_ITEM_SUCCESS, {header = header}) 
end

-- 丢弃道具失败
function BagProxy:handle_MSG_SC_DROP_ITEM_FAILED(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_DROP_ITEM_FAIL, {header = header}) 
end

-- 移动到英雄背包失败
function BagProxy:handle_MSG_SC_HUMBAG_TO_HEROBAG_FAIL(msg)
    local header = msg:GetHeader6()
    SL:onLUAEvent(LUA_EVENT_HUMBAG_TO_HEROBAG_FAIL, {header = header}) 
end

-- 整理背包
function BagProxy:handle_MSG_SC_RESET_BAG_POS(msg)
    SL:onLUAEvent(LUA_EVENT_RESET_BAG_POS) 
end

-- 开启准星
function BagProxy:handle_MSG_SM_COLLIMATOR_RESPONSE(msg)
    local header = msg:GetHeader13()
    SL:onLUAEvent(LUA_EVENT_COLLIMATOR_RESPONSE, {header = header}) 
end

-- 请求背包数据
function BagProxy:RequestBagData()
    SL:onLUAEvent(LUA_EVENT_REQ_BAGDATA)
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_BAGDATA)
end

-- 叠加道具
function BagProxy:RequestItemTwoToOne(MakeIndex1, MakeIndex2)
    SL:onLUAEvent(LUA_EVENT_BAG_REQ_TWO_TO_ONE, {MakeIndex1 = MakeIndex1, MakeIndex2 = MakeIndex2})
    LuaSendHeader6(global.MsgType.MSG_CS_ITEM_TWO_TO_ONE, MakeIndex1, MakeIndex2)
end

-- 拆分道具
function BagProxy:RequestCountItem(MakeIndex, num)
    SL:onLUAEvent(LUA_EVENT_BAG_REQ_NUMBER_CHANGE, {MakeIndex = MakeIndex, num = num})
    LuaSendHeader13(global.MsgType.MSG_CS_ITEM_NUMBER_CHANGE, MakeIndex, num, 0, 0)
end

-- 请求准星瞄准消息(使用)
function BagProxy:RequestCollimator(MakeIndex)
    if MakeIndex then
        SL:onLUAEvent(LUA_EVENT_BAG_REQ_COLLIMATOR, {MakeIndex = MakeIndex})
        LuaSendHeader12(global.MsgType.MSG_CM_COLLIMATOR_REQUEST, MakeIndex)
    end
end

-- 请求取消准星瞄准
function BagProxy:RequestCancelCollimator()
    SL:onLUAEvent(LUA_EVENT_BAG_REQ_CANCELCOLLIMATOR)
    LuaSendMsg(global.MsgType.MSG_CM_CANCELCOLLIMATOR_REQUEST, 0, 0, 0, 0)
end

-- 请求解锁背包格子
function BagProxy:RequestUnlockBagSize()
    SL:onLUAEvent(LUA_EVENT_BAG_REQ_UNLOCK_BAG_SIZE)
    LuaSendMsg(global.MsgType.MSG_CS_UNLOCK_BAG_SIZE)
end

--更新道具时间
function BagProxy:handle_MSG_SM_UPDATEITEMTIME(msg)
    local header = msg:GetHeader13()
    local data = {
        makeIndex = header.Guid,
        limitRemainTime = header.p1,
        limitTimeActive = header.p2 and header.p2 == 1
    }

    local itemData = BagData.GetItemDataByMakeIndex(data.makeIndex) or EquipData.GetEquipDataByMakeIndex(data.makeIndex)
    if itemData then
        itemData.limitTimeActive = data.limitTimeActive
        itemData.limitRemainTime = data.limitRemainTime
        if itemData.limitTimeActive and itemData.limitRemainTime then
            itemData.limitEndTime = itemData.limitRemainTime + GetServerTime()
        end
    end
    SL:onLUAEvent(LUA_EVENT_BAG_UPDATE_ITEM_TIME, {data = data}) 
end

function BagProxy:onRegister()
    BagProxy.super.onRegister(self)
end

function BagProxy:RegisterMsgHandler()
    BagProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    LuaRegisterMsgHandler(msgType.MSG_SC_RETURN_BAGDATA, handler(self, self.handle_MSG_SC_RETURN_BAGDATA))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_ADD_ITEM, handler(self, self.handle_MSG_SC_BAG_ADD_ITEM))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_DEL_ITEM, handler(self, self.handle_MSG_SC_BAG_DEL_ITEM))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_UPDATE_ITEM, handler(self, self.handle_MSG_SC_BAG_UPDATE_ITEM))
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_ITEM_USE_SUCCESS, handler(self, self.handle_MSG_SC_BAG_ITEM_USE_SUCCESS) )
    LuaRegisterMsgHandler(msgType.MSG_SC_BAG_ITEM_USE_FAILED, handler(self, self.handle_MSG_SC_BAG_ITEM_USE_FAILED))
    LuaRegisterMsgHandler(msgType.MSG_SC_DROP_ITEM_GET_FAILED, handler(self, self.handle_MSG_SC_DROP_ITEM_GET_FAILED))
    LuaRegisterMsgHandler(msgType.MSG_SC_DROP_ITEM_SUCCESS, handler(self, self.handle_MSG_SC_DROP_ITEM_SUCCESS))
    LuaRegisterMsgHandler(msgType.MSG_SC_DROP_ITEM_FAILED, handler(self, self.handle_MSG_SC_DROP_ITEM_FAILED))
    LuaRegisterMsgHandler(msgType.MSG_SC_HUMBAG_TO_HEROBAG_FAIL, handler(self, self.handle_MSG_SC_HUMBAG_TO_HEROBAG_FAIL))
    LuaRegisterMsgHandler(msgType.MSG_SC_RESET_BAG_POS, handler(self, self.handle_MSG_SC_RESET_BAG_POS))
    LuaRegisterMsgHandler(msgType.MSG_SM_COLLIMATOR_RESPONSE, handler(self, self.handle_MSG_SM_COLLIMATOR_RESPONSE))
    LuaRegisterMsgHandler(msgType.MSG_SC_RETURN_BAGDATA_REMAINING, handler(self, self.handle_MSG_SC_RETURN_BAGDATA))
    LuaRegisterMsgHandler(msgType.MSG_SM_UPDATEITEMTIME, handler(self, self.handle_MSG_SM_UPDATEITEMTIME))
end

return BagProxy