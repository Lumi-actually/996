local RemoteProxy = requireProxy("RemoteProxy")
local StallProxy = class("StallProxy", RemoteProxy)
StallProxy.NAME = global.ProxyTable.StallProxy

function StallProxy:ctor()
    StallProxy.super.ctor(self)
    self._isTrading      = false
    self._mySellData     = {}
    self._onSellData     = {}
    self._showStoreName  = nil
    self._seletedItem    = nil
    self._nowOpenStoreId = nil
    self._currencies     = {}        -- 可摆摊货币
end

function StallProxy:onRegister()
    StallProxy.super.onRegister(self)
end

function StallProxy:CheckListViewFull()
    return #self._mySellData >= global.MMO.STALL_MAX_PAGE
end

function StallProxy:AddItemIntoList(data)
    table.insert(self._mySellData, data)
end

function StallProxy:RmvMySellItem(makeIndex)
    for i, v in ipairs(self._mySellData) do
        if v.MakeIndex == makeIndex then 
            table.remove(self._mySellData, i)
            break
        end
    end
end

function StallProxy:GetMySellData()
    return self._mySellData
end

function StallProxy:AddOnSellItems(data)
    table.insert(self._onSellData, data)
end

function StallProxy:GetOnSellData()
    return self._onSellData
end

function StallProxy:GetSelectItem()
    return self._seletedItem
end

function StallProxy:SetSelectItem(itemIndex)
    self._seletedItem = itemIndex
end

function StallProxy:GetShowStoreName()
    return self._showStoreName
end

function StallProxy:SetShowStoreName(name)
    self._showStoreName = name
end

function StallProxy:GetNowOpenStoreId()
    return self._nowOpenStoreId
end

function StallProxy:SetNowOpenStoreId(userId)
    self._nowOpenStoreId = userId
end

function StallProxy:GetMyTradingStatus()
    return self._isTrading
end

function StallProxy:SetMyTradingStatus(status)
    self._isTrading = status
end

function StallProxy:CleanMySellData()
    self._mySellData = {}
end

function StallProxy:RequestAutoStall(name, cancel)
    local data = {}
    data.name = name or ""
    if cancel then
        -- data.items = nil --发送的数据不要有key:items
    else
        for i, v in ipairs(self._mySellData) do
            if not data.items then
                data.items = {}
            end
            local sellData = {}
            sellData.makeindex = v.MakeIndex
            sellData.goldtype = v.goldtype
            sellData.price = v.price
            table.insert(data.items, sellData)
        end
    end
    SendTableToServer(global.MsgType.MSG_CS_REQUEST_AUTO_STALL, data)
end

function StallProxy:RequestBuyItem(makeIndex)
    local userid = self:GetNowOpenStoreId()
    if not userid then
        return
    end
    LuaSendHeader12(global.MsgType.MSG_CS_REQUEST_STALL_BUY_ITEM, makeIndex, userid)
end

function StallProxy:RequestItemList(userId)
    if not userId then
        return
    end
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_STALL_INFO, userId)
end

function StallProxy:ResponItemList(msg)
    local header = msg:GetHeader()
    local data = msg:GetJsonData()
    if not data then
        return
    end
    self:CleanNowData()

    local userid = data.UserID
    local count = data.Count
    local items = {}
    if data.ItemList and next(data.ItemList) then
        for i = 1, count do
            local item = data.ItemList[i]
            if item and next(item) then
                items[i] = ChangeItemServersSendDatas(item.Item)
                items[i].price = item.Price
                items[i].goldtype = item.GoldType

                self:AddOnSellItems(items[i])
            end
        end
    end
    
    local stallName = data.ShopName
    self:SetShowStoreName(stallName)
    self:SetNowOpenStoreId(userid)
    UIOperator:OpenStallLayerUI({ buy = true })

    SL:onLUAEvent(LUA_EVENT_STALL_ITEM_LIST_CHANGE)
end

function StallProxy:CleanNowData()
    self._onSellData = {}
    self._showStoreName = nil
    self:SetNowOpenStoreId(nil)
end

function StallProxy:GetCurrencies()
    return self._currencies
end

function StallProxy:AddCurrency(item)
    table.insert(self._currencies, { id = item.Index, name = item.Name, item = item })
end

function StallProxy:ClearCurrencies()
    self._currencies = {}
end

function StallProxy:RegisterMsgHandler()
    local msgType = global.MsgType

    -- 摆摊列表
    LuaRegisterMsgHandler(msgType.MSG_SC_RESPONE_STALL_INFO, handler(self, self.ResponItemList))
end

return StallProxy