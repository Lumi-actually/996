local RemoteProxy = requireProxy("RemoteProxy")
local AuctionProxy = class("AuctionProxy", RemoteProxy)
AuctionProxy.NAME = global.ProxyTable.AuctionProxy

local socket = require("socket")

require("GUIData/AuctionData")

-- useritem     道具基础数据
-- userid       归属者ID
-- type         货币ID
-- price        当前价格
-- lastprice    一口价
-- time         上架时间戳
-- lasttime     最后出价时间戳
-- endtime      下架时间戳
-- curruserid   当前竞价玩家ID
-- joinuser     是否参与过竞价
-- flag         0.正常 1.表示拍卖成功的物品 2.表示流拍的物品
-- page         0.世界 1.行会
-- index
-- meguildRate  同行会折扣率

local function getUnitNumber(n)
    if n >= 100000000 then
        return string.format("%.1f%s", n / 100000000, GET_STRING(1045))
    end
    if n >= 10000 then
        return string.format("%.1f%s", n / 10000, GET_STRING(1005))
    end
    return tostring(n)
end

local function parseItem(item)
    if not item then
        return nil
    end
    local titem = ChangeItemServersSendDatas(item.useritem)
    setmetatable(item, { __index = titem })
    return item
end

function fixAuctionPrice(price, unit)
    return unit and getUnitNumber(price) or price
end

AuctionProxy.INFINITY_PRICE = 100000000

function AuctionProxy:ctor()
    AuctionProxy.super.ctor(self)

    self._currencies      = {} -- 可拍卖货币
    self._qualities       = {} -- 品阶

    self._biddinglist     = {} -- 竞价列表
    self._putlist         = {} -- 上架列表
    self._src             = 0  -- 最近一次请求来源 1.世界拍卖  2.行会拍卖
    self._page            = 0
    self._complete        = false

    self._jobAble         = {} -- 职业过滤
    self._limitShelf      = 6  -- 货架数量

    self._lowBidPrice     = 1  -- 默认最低竞拍价
    self._lowBuyPrice     = 1  -- 默认最低一口价

    self._highBidPrice    = nil
    self._highBuyPrice    = nil

    self._requestMinTime  = 600 -- 拍卖行数据请求最小时间间隔(毫秒)
    self._lastRequestTime = nil

    if AuctionData.Init then
        AuctionData.Init()
    end
end

function AuctionProxy:Clear()
    self._page = 0
    self._complete = false

    SL:onLUAEvent(LUA_EVENT_AUCTION_ITEM_LIST_CLEAR)
end

function AuctionProxy:IsComplete()
    return self._complete
end

function AuctionProxy:GetCurrencies()
    return self._currencies
end

function AuctionProxy:AddCurrency(item)
    table.insert(self._currencies, { id = item.Index, name = item.Name, item = item })
end

function AuctionProxy:ClearCurrencies()
    self._currencies = {}
end

function AuctionProxy:GetQualities()
    return self._qualities
end

function AuctionProxy:SetQualities(rawData)
    if not rawData then
        return
    end
    for _, value in ipairs(rawData) do
        local slices = G_GetSplitArray(value, "#")
        if(slices[2] ~= nil and slices[2] ~= "") then
            table.insert(self._qualities, { id = tonumber(slices[1]), name = slices[2] })
        end
    end
end

function AuctionProxy:GetJobAble()
    return self._jobAble
end

function AuctionProxy:SetJobAble(able)
    self._jobAble = able
end

function AuctionProxy:GetLimitShelf()
    return self._limitShelf or 8
end

function AuctionProxy:SetLimitShelf(count)
    self._limitShelf = count
end

function AuctionProxy:GetPutListCount()
    return #self._putlist
end

function AuctionProxy:CheckBidAble(item)
    if not item then
        return false
    end
    return item.nCurPrice and item.nCurPrice > 0
end

function AuctionProxy:CheckBuyAble(item)
    if not item then
        return false
    end
    return item.nLastPrice and item.nLastPrice > 0
end

function AuctionProxy:CalcItemStatus(item)
    if not item then
        return 3, 0
    end
    local status    = 0 -- 2.竞拍中 3.已超时
    local endTime   = item.nAddTime + item.nReadTime + item.nConTime    -- 结束时间
    endTime         = endTime or GetServerTime() + 1
    local showTime  = item.nAddTime + item.nReadTime    -- 展示时间
    local remaining = 0

    if GetServerTime() >= endTime then
        -- 已超时
        status = 3
        remaining = 0
    else
        --竞拍中
        status = 2
        remaining = endTime - GetServerTime()
    end

    if showTime and (showTime - GetServerTime()) > 0 then
        remaining = showTime - GetServerTime()
    end

    remaining = math.max(remaining, 0)
    return status, remaining
end

function AuctionProxy:IsAuctioningItem(item)
    return item.flag == 0
end

function AuctionProxy:IsExistAcquireItem()
    local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
    for _, item in ipairs(self._biddinglist) do
        if item.flag == 1 and item.curruserid == mainPlayerID then
            return true
        end
    end
    return false
end

function AuctionProxy:SetLowBidPrice(price)
    self._lowBidPrice = price
end

function AuctionProxy:SetLowBuyPrice(price)
    self._lowBuyPrice = price
end

function AuctionProxy:SetHighBidPrice(price)
    self._highBidPrice = price
end

function AuctionProxy:SetHighBuyPrice(price)
    self._highBuyPrice = price
end

function AuctionProxy:GetLowBidPrice()
    return self._lowBidPrice
end

function AuctionProxy:GetLowBuyPrice()
    return self._lowBuyPrice
end

function AuctionProxy:GetHighBidPrice()
    return self._highBidPrice
end

function AuctionProxy:GetHighBuyPrice()
    return self._highBuyPrice
end

function AuctionProxy:GetShowBagItems()
    local ItemConfigProxy  = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)

    local bagData          = BagData.GetBagData()
    local quickData        = QuickUseData.GetQuickUseData()
    local articleType      = GUIDefine.ItemArticleType
    local bagItems         = {}
    local itemMaps         = {}
    for _, vItem in pairs(quickData) do
        local _, isMeetType = CheckItemisBind(vItem, articleType.TYPE_TRADE_AUCTION)
        if not isMeetType then
            table.insert(bagItems, vItem)
            itemMaps[vItem.MakeIndex] = vItem
        end
    end

    for _, vItem in pairs(bagData) do
        local _, isMeetType = CheckItemisBind(vItem, articleType.TYPE_TRADE_AUCTION)
        if not isMeetType then
            table.insert(bagItems, vItem)
            itemMaps[vItem.MakeIndex] = vItem
        end
    end

    return bagItems, itemMaps
end

function AuctionProxy:SetRequestMinTime(time)
    self._requestMinTime = time
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- 拉取拍卖数据：发送消息号：1120，第一个参数为页，世界=0，行会=1
function AuctionProxy:RequestItemList(data)
    local curTime = socket.gettime()
    local needDelay = false
    if self._lastRequestTime and self._requestMinTime then
        if (curTime - self._lastRequestTime) * 1000 < self._requestMinTime then
            needDelay = true
            SL:ShowSystemTips("<font color = '#00FF00'>正在读取数据中...</font>")
        end
    end

    local function callback()
        local filter = clone(data)
        filter.page = self._page
        self._lastRequestTime = socket.gettime()
        SendTableToServer(global.MsgType.MSG_CS_AUCTION_ITEM_LIST, filter)
    end
    SL:ScheduleOnce(callback, needDelay and (self._requestMinTime / 1000) or 0)
end

local function transformAuctionItem(data)
    local item = {}
    item.nid = data.ID
    item.btPage = data.btPage
    item.meguildRate = data.MeGuildRate
    item.sGuildID = data.GuildID
    item.UserId = data.UserID
    item.item = ChangeItemServersSendDatas(data.Item)
    item.nCurPrice = data.CurrPrice
    item.btType = data.Type
    item.nLastPrice = data.LastPrice
    item.sCurUser = data.CurrUser
    item.nAddTime = data.AddTime
    item.nReadTime = data.ReadTime
    item.nConTime = data.ConTime
    item.nLastTime = data.LastTime
    item.btFlag = data.Flag
    item.joinuser = data.joinuser
    return item
end

function AuctionProxy:RespItemList(msg)
    UIOperator:CloseLoadingBarUI()
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    if len <= 0 then
        return false
    end
    self._page    = header.recog + 1
    local source  = header.param1
    local itemLen = header.param2

    local data      = msg:GetJsonData()
    local itemList  = data.ItemList or {}
    local buffer  = msg:GetBodyLuaBuffer()
    local items   = {}
    for i = 1, itemLen do
        if not itemList[i] then
            break
        end
        local item = transformAuctionItem(itemList[i])
        table.insert(items, item)
    end
    SL:onLUAEvent(LUA_EVENT_AUCTION_PUT_LIST, { source = source, items = items })
end

-- 你发送1154号消息，第一个参数=1，表示查询自己上架的物品，=2表示查询参与过的。
function AuctionProxy:RequestItems(listType)
    LuaSendMsg(global.MsgType.MSG_CS_AUCTION_PUT_LIST, listType)
end

-- 返回1130号消息给你。第一个参数为对应的查询类型
function AuctionProxy:RespItems(msg)
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    local data   = msg:GetJsonData()
    if len <= 0 then
        return false
    end
    local itemLen = header.param1
    local itemList = data.ItemList or {}
    local items = {}
    for i = 1, itemLen do
        if not itemList[i] then
            break
        end
        local item = transformAuctionItem(itemList[i])
        table.insert(items, item)
    end

    if header.recog == 1 then
        self._putlist = {}
        self._putlist = table.order_merge(self._putlist or {}, items)
        SL:onLUAEvent(LUA_EVENT_AUCTION_PUT_LIST, self._putlist)
    elseif header.recog == 2 then
        self._biddinglist = {}
        self._biddinglist = table.order_merge(self._biddinglist or {}, items)
        SL:onLUAEvent(LUA_EVENT_AUCTION_BIDDING_LIST, self._biddinglist)
    end
end

function AuctionProxy:RequestPutin(data)
    SendTableToServer(global.MsgType.MSG_CS_AUCTION_PUT_IN, data)
end

function AuctionProxy:RequestReputin(data)
    SendTableToServer(global.MsgType.MSG_CS_AUCTION_REPUT_IN, data)
end

function AuctionProxy:RespPutin(msg)
    local data = msg:GetJsonData()
    SL:onLUAEvent(LUA_EVENT_AUCTION_PUT_IN, {item = transformAuctionItem(data)})
end

function AuctionProxy:RequestPutout(makeIndex)
    LuaSendHeader13(global.MsgType.MSG_CS_AUCTION_PUT_OUT, makeIndex)
end

function AuctionProxy:RespPutout(msg)
    local header    = msg:GetHeader13()
    local makeindex = header.Guid

    SL:onLUAEvent(LUA_EVENT_AUCTION_PUT_OUT, { makeindex = makeindex })
end

function AuctionProxy:RequestBid(data)
    local sendData = { makeindex = data.makeindex, price = data.price }
    SendTableToServer(global.MsgType.MSG_CS_AUCTION_BID, sendData)
end

-- 竞拍返回 消息号：1112，recog=0，失败：recog=-1，表示已经有人出更高价，=-2表示已经被买走 =-3自己的物品
function AuctionProxy:RespBid(msg)
    local header    = msg:GetHeader()
    local errorcode = header.recog

    SL:onLUAEvent(LUA_EVENT_AUCTION_BID_ERRORCODE, { errorcode = errorcode, })
    SL:onLUAEvent(LUA_EVENT_AUCTION_BID, { errorcode = errorcode, })
end

function AuctionProxy:RequestAcquireItem(makeIndex)
    LuaSendHeader13(global.MsgType.MSG_CS_AUCTION_ACQUIRE, makeIndex)
end

function AuctionProxy:RespAcquireItem(msg)
    local header = msg:GetHeader13()
    local makeindex = header.recog
    SL:onLUAEvent(LUA_EVENT_AUCTION_ACQUIRE, { makeindex = makeindex, })
end

function AuctionProxy:RequestLeaveAuction()
    LuaSendMsg(global.MsgType.MSG_CS_AUCTION_LEAVE)
end

-- 1115号消息，recog=1，表示新加，=2表示删除，=3表示更新
function AuctionProxy:RespItemUpdate(msg)
    local header = msg:GetHeader()
    local action = header.recog
    local data = msg:GetJsonData()
    local item = transformAuctionItem(data)
    -- 世界拍卖
    if action == 1 then
        SL:onLUAEvent(LUA_EVENT_AUCTION_WORLD_ITEM_ADD, { item = item })
    elseif action == 2 then
        for k, v in pairs(self._biddinglist) do
            if v.MakeIndex == item.MakeIndex then
                table.remove(self._biddinglist, k)
                break
            end
        end

        SL:onLUAEvent(LUA_EVENT_AUCTION_WORLD_ITEM_DEL, { item = item })
    elseif action == 3 then
        for k, v in pairs(self._biddinglist) do
            if v.MakeIndex == item.MakeIndex then
                self._biddinglist[k] = item
                break
            end
        end

        SL:onLUAEvent(LUA_EVENT_AUCTION_WORLD_ITEM_CHANGE, { item = item })
    end

    SL:onLUAEvent(LUA_EVENT_AUCTION_ITEM_UPDATE, { item = item })

    local peopleproxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local myUid = peopleproxy:GetRoleUID()
    if item.UserId == myUid and action ~= 2 then
        SL:onLUAEvent(LUA_EVENT_AUCTION_PUT_IN, { item = item })
    end
end

function AuctionProxy:RespPutCount(msg)
    local header = msg:GetHeader()
    self:SetLimitShelf(header.recog)
end

function AuctionProxy:RegisterMsgHandler()
    AuctionProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_ITEM_LIST, handler(self, self.RespItemList))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_PUT_LIST, handler(self, self.RespItems))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_PUT_OUT, handler(self, self.RespPutout))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_PUT_IN, handler(self, self.RespPutin))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_BID, handler(self, self.RespBid))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_ACQUIRE, handler(self, self.RespAcquireItem))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_ITEM_UPDATE, handler(self, self.RespItemUpdate))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_PUT_COUNT, handler(self, self.RespPutCount))
    LuaRegisterMsgHandler(msgType.MSG_SC_AUCTION_PUT_LIST2, handler(self, self.RespItems))
end

return AuctionProxy
