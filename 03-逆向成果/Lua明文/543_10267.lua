local RemoteProxy = requireProxy("RemoteProxy")
local PurchaseProxy = class("PurchaseProxy", RemoteProxy)
PurchaseProxy.NAME = global.ProxyTable.PurchaseProxy

local socket = require("socket")
local cjson = require("cjson")

-- guid         标识
-- userid       归属者ID
-- itemid       道具ID
-- stdmode      道具类型stdmode
-- currency     货币ID
-- totalqty     总数量
-- minqty       最小数量
-- remainqty    剩余数量
-- waitrecqty   待提取数量
-- recedqty     已提取数量
-- price        单价
-- qty          数量
-- amount       金额
-- starttime    上架时间
-- endtime      下架时间(为0不限制下架时间)
-- pageindex    页码
-- pagemax      总共页数

function PurchaseProxy:ctor()
    PurchaseProxy.super.ctor(self)

    self._config_type   = {}

    self._currencies    = {}        -- 可求购货币
    self._currencyMap   = {}


    self._receivelist   = {}        -- 我的 - 已收列表
    self._putlist       = {}        -- 我的 - 求购列表
    self._src           = 0         -- 请求来源 0.世界求购  1.我的求购 2.我的已收
    self._sort          = 0         -- 排序 0.默认 1.单价正序 2.单价倒序 3.总价正序 4.总价倒序
    self._page          = 0
    self._complete      = false

    self._itemConfig    = {}

    self._requestMinTime    = 600       -- 拍卖行数据请求最小时间间隔(毫秒)
    self._lastRequestTime   = nil

    self._filter1Item       = nil       -- 分类一级数据
    self._itemListByType    = {}        -- 按类分物品列表

    self:LoadConfig()
end

function PurchaseProxy:LoadConfig()
    self._config_type = clone(SL:RequireFile("game_config/cfg_auction_type"))
end

function PurchaseProxy:InitItemConfig(...)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    self._itemConfig = ItemConfigProxy:GetItemConfigData()
end

function PurchaseProxy:Clear()
    self._page = 0
    self._complete = false
end

function PurchaseProxy:IsComplete()
    return self._complete
end

function PurchaseProxy:GetCurrencies()
    return self._currencies
end

-- #分隔
function PurchaseProxy:SetCurrencies(str)
    if str and string.len(str) > 0 then
        local data = G_GetSplitArray(str, "#")
        for k, v in ipairs(data) do
            local id = tonumber(v)
            if id and not self._currencyMap[id] then
                self._currencyMap[id] = true
                table.insert(self._currencies, {id = id})
            end
        end
    end
end

function PurchaseProxy:SetTypeItemList(list)
    self._itemListByType = list or {}
end

function PurchaseProxy:GetItemListByType(key)
    return self._itemListByType and self._itemListByType[key] or {}
end

function PurchaseProxy:clearData()
    self._itemListByType = {}
end

function PurchaseProxy:SetSortType(type)
    self._sort = type
end

function PurchaseProxy:GetSortType()
    return self._sort
end

function PurchaseProxy:GetCTypeByID(id)
    return self._config_type[id]
end

function PurchaseProxy:GetStdModeByID(id)
    local config = self:GetCTypeByID(id)
    if not config then
        return {}
    end
    local slices = G_GetSplitArray(tostring(config.stdmode), "#")
    local stdmode = {}
    for key, value in ipairs(slices) do
        table.insert(stdmode, tonumber(value))
    end
    return stdmode
end

-- 一级页签
function PurchaseProxy:GetFirstFilterItem()
    if not self._filter1Item then
        local items = {}
        for i, v in pairs(self._config_type) do
            if not items[v.firstlevel] then
                items[v.firstlevel] = {}
            end
            table.insert(items[v.firstlevel], v)
        end

        for i, v in pairs(items) do 
            table.sort(v, function(a, b) return a.id < b.id end)
        end 
        self._filter1Item = items
    end
    return self._filter1Item
end

-- 二级页签
function PurchaseProxy:GetSecondFilterItem(g)
    local items = self:GetFirstFilterItem()[g] or {}
    -- table.sort(items, function(a, b) return a.id < b.id end)
    return items
end

function PurchaseProxy:GetItemConfig()
    return self._itemConfig
end

function PurchaseProxy:SetRequestMinTime(time)
    self._requestMinTime = time
end

----------------------------------------------------------------------------------
-- 拉取求购数据：发送消息号：1510, recog 世界=0, 我的求购=1, 我的已收=2
function PurchaseProxy:RequestItemList(data)
    local curTime = socket.gettime()
    local needDelay = false
    -- if self._lastRequestTime and self._requestMinTime then
    --     if (curTime - self._lastRequestTime) * 1000 < self._requestMinTime then
    --         needDelay = true
    --         SL:ShowSystemTips("<font color = '#00FF00'>正在读取数据中...</font>")
    --     end
    -- end
    local function callback()
        local sendData = data
        self._lastRequestTime = socket.gettime()
        local jsonStr = cjson.encode(sendData)
        LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_ITEM_LIST, data.type or 0, 0, 0, 0, jsonStr, string.len(jsonStr))
    end
    PerformWithDelayGlobal(callback, needDelay and (self._requestMinTime / 1000) or 0)
end

function PurchaseProxy:RespItemList(msg)
    UIOperator:CloseLoadingBarUI()
    local header = msg:GetHeader()
    local len    = msg:GetDataLength()
    if len <= 0 then
        return false
    end
    local jsonData  = ParseRawMsgToJson(msg)
    local type      = header.recog  -- 0 1 2 

    -- complete
    local data = jsonData and jsonData.data
    if #data == 0 then
        self._complete = true
        SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_ITEM_LIST_COMPLETE, {type = type})
        return
    end

    SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_ITEM_LIST_PULL, {type = type, items = data, pageIndex = jsonData.pageindex})
end

function PurchaseProxy:RequestPutIn(data)
    SendTableToServer(global.MsgType.MSG_CS_PURCHASE_PUT_IN, data)
end

function PurchaseProxy:RequestPutOut(guid)
    if not guid then    -- 全部取消
        LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_PUT_OUT, 0, 0, 0, 1)
    else
        LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_PUT_OUT, 0, 0, 0, 0, guid, string.len(guid))
    end
end

function PurchaseProxy:RequestTakeOut(guid)
    if not guid then    -- 全部取出
        LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_TAKE_OUT, 0, 0, 0, 1)
    else
        LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_TAKE_OUT, 0, 0, 0, 0, guid, string.len(guid))
    end
end

function PurchaseProxy:RequestSell(data)
    SendTableToServer(global.MsgType.MSG_CS_PURCHASE_SELL, data)
end

function PurchaseProxy:NotifyClosePurchase()
    LuaSendMsg(global.MsgType.MSG_CS_PURCHASE_CLOSE)
end

-- 操作返回  recog=类型 1=上架 2=取出 3=出售 4=下架, nparam 0 成功 小于0 失败
function PurchaseProxy:RespOperaBack(msg)
    local header    = msg:GetHeader()
    local type      = header.recog
    local errorcode = header.param1

    if errorcode == 0 then
        ShowSystemTips("成功")
    elseif errorcode == -1 then
        ShowSystemTips("道具不合法")
    elseif errorcode == -2 then
        ShowSystemTips("单价不合法")
    elseif errorcode == -3 then
        ShowSystemTips("最小数量不合法")
    elseif errorcode == -4 then
        ShowSystemTips("货币类型不合法")
    elseif errorcode == -5 then
        ShowSystemTips("数量不合法")
    elseif errorcode == -6 then
        ShowSystemTips("金额不合法")
    elseif errorcode == -7 then
        ShowSystemTips("玩家货币不足")
    elseif errorcode == -8 then
        ShowSystemTips("有未提取道具不允许下架")    
    end
end

-- recog 	类型 1=上架 2=取出 3=出售 4=下架
function PurchaseProxy:RespItemUpdate(msg)
    local header = msg:GetHeader()
    local action = header.recog
    local jsonData = ParseRawMsgToJson(msg)
    releasePrint("==================RespItemUpdate===============", action)

    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    local myUid = PlayerProperty:GetRoleUID()
    local isMy = jsonData.userid == myUid
    -- 已收列表 待提取数量 > 0
    local isReceive = jsonData.waitrecqty > 0 

    -- type: 1 新增
    local TYPE = {
        ADD = 1,
        REMOVE = 2,
        UPDATE = 3,
    }
    if action == 1 then -- 上架
        if isMy then
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_MYITEM_UPDATE, {isReceive = isReceive, type = TYPE.ADD, item = jsonData})
        else
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_WORLDITEM_UPDATE, {type = TYPE.ADD, item = jsonData})
        end
    elseif action == 2 then -- 取出
        if isMy then -- 已收列表
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_MYITEM_UPDATE, {isReceive = true, type = TYPE.REMOVE, item = jsonData})
        end
    elseif action == 3 then -- 出售 / 已收列表新增
        if isMy then
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_MYITEM_UPDATE, {isReceive = isReceive, type = TYPE.UPDATE, item = jsonData})
        else
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_WORLDITEM_UPDATE, {type = TYPE.UPDATE, item = jsonData})
        end
    elseif action == 4 then -- 下架
        if isMy then
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_MYITEM_UPDATE, {type = TYPE.REMOVE, item = jsonData})
        else
            SLBridge:onLUAEvent(LUA_EVENT_PURCHASE_WORLDITEM_UPDATE, {type = TYPE.REMOVE, item = jsonData})
        end
    end
end

function PurchaseProxy:RegisterMsgHandler()
    PurchaseProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_PURCHASE_ITEM_LIST,    handler(self, self.RespItemList))
    LuaRegisterMsgHandler(msgType.MSG_SC_PURCHASE_OPERA,        handler(self, self.RespOperaBack))
    LuaRegisterMsgHandler(msgType.MSG_SC_PURCHASE_UPDATE,       handler(self, self.RespItemUpdate))

end

return PurchaseProxy