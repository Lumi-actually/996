local RemoteProxy    = requireProxy("RemoteProxy")
local PageStoreProxy = class("PageStoreProxy", RemoteProxy)
PageStoreProxy.NAME = global.ProxyTable.PageStoreProxy

PageStoreProxy.normalNpcStorePageId = 100

function PageStoreProxy:ctor()
    PageStoreProxy.super.ctor(self)
    self.pageData = {}
end

function PageStoreProxy:onRegister()
    PageStoreProxy.super.onRegister(self)
end

function PageStoreProxy:ResetPageData(page, data)
    self.pageData[page] = data
end

function PageStoreProxy:InitPageStoreData()
    local initPage = 4
    for i = 1, initPage do
        self:RequestPageData(i)
    end
end

function PageStoreProxy:GetPageData(page)
    return self.pageData[page]
end

function PageStoreProxy:RequestPageData(page)
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_DATA_BY_PAGE, page)
end

function PageStoreProxy:RequestBuy(Index, num, reduceCardIndex)
    local buyNum = num or 1
    local useCardIndex = reduceCardIndex or 0
    LuaSendMsg(global.MsgType.MSG_CS_PAGE_STORE_REQUEST_BUY_ITEM, Index, buyNum, useCardIndex)
end

function PageStoreProxy:RequestItemIndexData(index)
    LuaSendMsg(global.MsgType.MSG_CS_REQUEST_DATA_BY_INDEX, index)
end

function PageStoreProxy:GetItemDataByStoreIndex(Index)
    if not Index then
        return nil
    end
    for _, v in pairs(self.pageData) do
        for _, itemData in pairs(v) do
            local storeIndex = itemData.Index
            if storeIndex == Index then
                return itemData
            end
        end
    end
    return nil
end

function PageStoreProxy:CheckStoreLimitStatus(Index)
    local data = self:GetItemDataByStoreIndex(Index)
    if not data then
        return false
    end
    if data.LimitCount and data.LimitCount > 0 and data.LimitType then
        local buyCount = data.BuyCount or 0
        local leftCount = data.LimitCount - buyCount
        return leftCount > 0
    else
        return true
    end
end

function PageStoreProxy:handle_MSG_SC_GOTDATA_BY_PAGE(msg)
    local header = msg:GetHeader()
    local page = header.recog
    local count = header.param1
    local buffer  = msg:GetBodyLuaBuffer()

    local items = {}
    for i = 1, count do
        local item = {}
        item.ID = buffer:ReadInt()
        item.Index = buffer:ReadInt()
        item.SortIndex = buffer:ReadInt()
        item.Look = buffer:ReadInt()
        item.LimitType = buffer:ReadByte()
        item.LimitCount = buffer:ReadInt()
        item.BuyCount = buffer:ReadInt()
        item.Price = buffer:ReadInt()
        item.NowPrice = buffer:ReadInt()
        item.ShowLable = buffer:ReadByte()
        item.CountMin = buffer:ReadInt()
        item.CountMax = buffer:ReadInt()
        item.CostType = buffer:ReadInt()
        item.ArrConstID = {}
        local ArrCostCount = buffer:ReadInt()
        if ArrCostCount > 0 then
            for j = 1, ArrCostCount do
                local id = buffer:ReadByte()
                table.insert(item.ArrConstID, id)
            end
        end
        table.insert(items, item)
    end

    if not page or #items == 0 then
        return
    end
    local pageData = {
        page = page
    }
    self:ResetPageData(page, items)

    if page == self.normalNpcStorePageId then
        -- 如果是100 则是通用NPC商店面板
        SL:onLUAEvent(LUA_EVENT_NPC_STORE_OPEN, items)
    elseif page >= 1000 then
        
    else
        SL:onLUAEvent(LUA_EVENT_LAYER_PAGE_STORE_REFRESH, pageData)
    end
end

function PageStoreProxy:RegisterMsgHandler()
    PageStoreProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    -- 根据页签返回页签数据
    LuaRegisterMsgHandler(msgType.MSG_SC_GOTDATA_BY_PAGE, handler(self, self.handle_MSG_SC_GOTDATA_BY_PAGE))
end

return PageStoreProxy