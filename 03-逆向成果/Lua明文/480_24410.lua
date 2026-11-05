local RemoteProxy = requireProxy("RemoteProxy")
local NPCStorageProxy = class("NPCStorageProxy", RemoteProxy)
NPCStorageProxy.NAME = global.ProxyTable.NPCStorageProxy

function NPCStorageProxy:ctor()
    NPCStorageProxy.super.ctor(self)

    self._storageData = {}
    self._maxPage = 1    -- 仓库的最大页
    self._npcIndex = nil
    self._touchType = 0
    self._openedCount = 0
    self._pageIndex = 1
    self._scheduleId = nil  --请求存储的计时器 0.5s

    self._posMark = {}   --仓库位置 有序 k = pos
    self._posData = {}   --仓库位置 k = makeindex
    self._storageVo = {} --仓库数据 k = maekindex
    self._itemCount = 0
    self._storageMax = global.MMO.NPC_STORAGE_MAX_PAGE
    self._itemCountByIndex = {}
    self._isInited = false

    self:InitStoragePosMark()
end

function NPCStorageProxy:InitStoragePosMark()
    local storagePosData = self:GetPosMarkData()
    if not self._isInited or not storagePosData then 
        for i = 1, self._storageMax do
            self._posMark[i] = ""
        end
        self:SetPosMarkData()
    else 
        self._posMark = storagePosData
    end 
end

function NPCStorageProxy:SetMaxStorage(maxStorage)
    self._storageMax = maxStorage
end

function NPCStorageProxy:GetMaxStorage()
    return self._storageMax or 0
end

function NPCStorageProxy:SetNewStoragePosMark()
    local newPosMark = {}
    for i = 1, self._storageMax do
        if not self._posMark[i] or self._posMark[i] == "" then
            newPosMark[i] = ""
        else
            newPosMark[i] = self._posMark[i]
        end
    end
    self._posMark = newPosMark
end

function NPCStorageProxy:GetHistoryPos(MakeIndex)
    for k, v in pairs(self._posMark) do
        if v == MakeIndex then
            return k
        end
    end
    return nil
end

-- 从头开始 找到空位就返回pos
function NPCStorageProxy:NewItemPos()
    for i = 1, self._storageMax do
        if self._posMark[i] and self._posMark[i] == "" then
            return i
        end
    end
    return nil
end

-- 保存位置数据
function NPCStorageProxy:SetItemPosData(MakeIndex, pos)
    self._posData[MakeIndex] = pos
    if pos then
        self._posMark[pos] = MakeIndex
    end
end

-- 增
function NPCStorageProxy:AddItem(item, pos)
    local MakeIndex = item.MakeIndex
    if pos then
        self._storageVo[MakeIndex] = item
        self._itemCount = self._itemCount + 1
        self:ChangeItemCountByIndex(item.Index, item.OverLap)
        SL:SetValue("ITEM_BELONG_BY_MAKEINDEX", MakeIndex, GUIDefine.ItemBelong.STORAGE)
    end
end

-- 删
function NPCStorageProxy:SubItem(MakeIndex)
    if self._storageVo[MakeIndex] then
        local item = self._storageVo[MakeIndex]
        self:ChangeItemCountByIndex(item.Index,-item.OverLap)
        self._storageVo[MakeIndex] = nil
        self._itemCount = self._itemCount - 1
        if SL:GetValue("ITEM_BELONG_BY_MAKEINDEX", MakeIndex) == GUIDefine.ItemBelong.STORAGE then
            SL:SetValue("ITEM_BELONG_BY_MAKEINDEX", MakeIndex, nil)
        end
    end
end

function NPCStorageProxy:UpdateItem(item)
    local makeIndex = item.MakeIndex
    if self._storageVo[makeIndex] then
        local oldItem = self._storageVo[makeIndex]
        local oldOverLap = oldItem.OverLap or 1
        local newOverLap = item.OverLap or 1
        self:ChangeItemCountByIndex(item.Index, newOverLap - oldOverLap)
        self._storageVo[makeIndex] = item
        --
        self:UpdateStorageData(makeIndex, item.OverLap)
    end
end

-- 改
function NPCStorageProxy:AmendHistoryPos(data)
    if not data then
        return
    end

    local newItems = {}
    local newPosMark = {}
    for i = 1, self._storageMax do 
        newPosMark[i] = ""
    end 

    for i, item in pairs(data) do
        local historyPos = self:GetHistoryPos(item.MakeIndex)
        if historyPos then
            newPosMark[historyPos] = item.MakeIndex
        else
            table.insert(newItems, item)
        end
    end

    for i = 1, #newPosMark do 
        self._posMark[i] = newPosMark[i]
    end 

    for i, v in ipairs(newItems) do
        local newPos = self:NewItemPos()
        if newPos then 
            self._posMark[newPos] = v.MakeIndex
            self._posData[v.MakeIndex] = newPos
        end 
    end
end

function NPCStorageProxy:ChangeItemCountByIndex(Index, diff)
    if not Index then
        return
    end
    if not self._itemCountByIndex then
        self._itemCountByIndex = {}
    end
    local diffCount = diff or 0
    local oldCount = self._itemCountByIndex[Index] or 0
    local newCount = oldCount + diffCount
    self._itemCountByIndex[Index] = newCount > 0 and newCount or 0
end

function NPCStorageProxy:CleanItemPosData(MakeIndex)
    local historyPos = self._posData[MakeIndex]
    if historyPos then
        self._posData[MakeIndex] = nil
        self._posMark[historyPos] = ""
    end 

    local newPosMark = {}
    for i = 1, self._storageMax do
        newPosMark[i] = ""
    end

    local temp = {}
    for i = 1, self._storageMax do 
        if self._posMark[i] ~= "" then 
            table.insert(temp, self._posMark[i])
        end  
    end 

    for i, makeindex in ipairs(temp) do 
        newPosMark[i] = makeindex
        if self._posData[makeindex] then 
            self._posData[makeindex] = i
        end 
    end 

    self._posMark = newPosMark
end

function NPCStorageProxy:CleanStoragePosData()
    self._posMark = {}
    self._posData = {}
    for i = 1, self._storageMax do
        self._posMark[i] = ""
    end
end

function NPCStorageProxy:ClearItemData()
    -- 暂不处理此时清空仓库物品归属
    self._storageVo = {}
    self._itemCount = 0
    self._itemCountByIndex = {}
end

function NPCStorageProxy:GetStoragePosByMakeIndex(MakeIndex)
    return self._posData[MakeIndex]
end

-- 本地仓库位置信息
function NPCStorageProxy:GetPosMarkData()
    local PosData = UserData:new("NPCStoragePosData")
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local flag = proxy:GetSelectedRoleID() or "errorName"

    local inited = PosData:getBoolForKey("storage_inited"..flag)
    if not inited then 
        self._isInited = false
        PosData:setBoolForKey( "storage_inited"..flag, true )
    else 
        self._isInited = true
    end 

    local clientData = PosData:getStringForKey( "storage"..flag )
    if not clientData or clientData == "" then
        return nil
    end

    local cjson = require( "cjson" )
    local lastJsonData = cjson.decode(clientData)
    return lastJsonData
end

function NPCStorageProxy:SetPosMarkData()
    local PosData = UserData:new("NPCStoragePosData")
    local proxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local flag = proxy:GetSelectedRoleID() or "errorName"
    local cjson = require( "cjson" )
    local storagePosData = cjson.encode(self._posMark)
    local clientData = PosData:setStringForKey( "storage"..flag, storagePosData )
end

function NPCStorageProxy:LoadConfig()
    local maxNum = SL:GetValue("GAME_DATA","warehouse_max_num") or 240
    self._maxPage = math.ceil(maxNum / GUIDefine.STORAGE_PER_PAGE_MAX)
end

-- 获取仓库的最大页
function NPCStorageProxy:GetMaxPage()
    return self._maxPage
end

function NPCStorageProxy:SetStorageData(data)
    self._storageData = data or {}

    -- clear data
    self:ClearItemData()
    -- 更新位置
    self:AmendHistoryPos(data)

    local makeindex = {}
    for _, v in ipairs(data) do 
        local itemPos = self:GetHistoryPos(v.MakeIndex) or self:NewItemPos()
        if itemPos then
            self:SetItemPosData(v.MakeIndex, itemPos)
        end
        self:AddItem(v, itemPos)
    end 

    self:SetPosMarkData()

    -- 重新排列数据
    self._storageData = {}
    local data = {}
    data = self._storageVo
    for i, v in pairs(data) do 
        local pos = self:GetStoragePosByMakeIndex(v.MakeIndex)
        if pos then 
            self._storageData[pos] = v
        end 
    end 
end

function NPCStorageProxy:GetStorageData()
    return self._storageData
end

function NPCStorageProxy:SetStoragePageIndex(Index)
    self._pageIndex = math.min(Index or 1, self._maxPage)
end

function NPCStorageProxy:GetStoragePageIndex()
    return self._pageIndex
end

function NPCStorageProxy:GetStorageDataByPage(page)
    local newList = {}
    if not page then
        return newList
    end

    for k, v in pairs(self._storageData) do
        if v.Where == page then
            table.insert(newList, v)
        end
    end
    
    return newList
end

function NPCStorageProxy:SetNpcIndex(idx)
    self._npcIndex = idx
end

function NPCStorageProxy:GetNpcIndex()
    return self._npcIndex
end

function NPCStorageProxy:SetOpenSize(openCount)
    local size = SL:GetValue("GAME_DATA","warehouse_num")
    local setBaseSize = size and tonumber(size)
    local base = setBaseSize or 24
    local open = openCount or 0
    self._openedCount = base + open
    if self._openedCount > 240 then 
        self._openedCount = 240
    end 
    self:SetMaxStorage(self._openedCount)
    self:SetNewStoragePosMark()
end

function NPCStorageProxy:GetOpenSize()
    return self._openedCount
end

function NPCStorageProxy:GetTouchType()
    return self._touchType
end

function NPCStorageProxy:SetTouchType(type)
    self._touchType = type
end

function NPCStorageProxy:CleanData()
    self._storageData = {}
    self._npcIndex = nil

    if self._scheduleId then
        UnSchedule(self._scheduleId)
        self._scheduleId = nil
    end
end

function NPCStorageProxy:AddStorageData(data, where)
    local itemData = data
    if not itemData or next(itemData) == nil then
        return
    end

    -- 记录位置
    local itemPos = self:GetHistoryPos(itemData.MakeIndex) or self:NewItemPos()
    if itemPos then
        self:AddItem(itemData, itemPos)
        self:SetItemPosData(itemData.MakeIndex, itemPos)
        self:SetPosMarkData()
    end

    -- 脚本存仓库, 服务端不知存储页码 给到-1 客户端处理.
    if where == -1 and itemPos then
        local pageMaxNum = GUIDefine.STORAGE_PER_PAGE_MAX
        local pageIndex = math.ceil(itemPos / pageMaxNum)
        where = pageIndex
        -- 再通知服务端页码 [npcIndex -1标识 -> 仅改变页码]
        LuaSendHeader12(global.MsgType.MSG_CS_STORAGE_STORE_REQUEST, itemData.MakeIndex, -1, pageIndex, itemData.Name)
    end

    itemData.Where = where
    table.insert(self._storageData, itemData)
    SL:onLUAEvent(LUA_EVENT_STORAGE_DATA_UPDATE, where)

    local data = {
        opera = GUIDefine.OperateType.ADD,
        item = itemData,
        page = where
    }
    SLBridge:onLUAEvent(LUA_EVENT_STORAGE_DATA_CHANGE, data)
end

function NPCStorageProxy:DeleteStorageData(data)
    if data and data.MakeIndex and self._storageData and next(self._storageData) then
        for k, v in pairs(self._storageData) do
            if data.MakeIndex and v.MakeIndex and data.MakeIndex == v.MakeIndex then
                -- 记录位置
                self:SubItem(data.MakeIndex)
                self:CleanItemPosData(data.MakeIndex)
                self:SetPosMarkData()

                table.remove(self._storageData, k)
                SL:onLUAEvent(LUA_EVENT_STORAGE_DATA_UPDATE, data.Where)

                local data = {
                    opera = GUIDefine.OperateType.DEL,
                    item = data,
                    page = data.Where
                }
                SLBridge:onLUAEvent(LUA_EVENT_STORAGE_DATA_CHANGE, data)
                break
            end
        end
    end
end

-- 更新物品的叠加数据
function NPCStorageProxy:UpdateStorageData(MakeIndex, nums)
    if MakeIndex then
        for _, v in pairs(self._storageData) do
            if v.MakeIndex and MakeIndex == v.MakeIndex then
                v.OverLap = nums
                SL:onLUAEvent(LUA_EVENT_STORAGE_DATA_UPDATE, v.Where)

                local data = {
                    opera = GUIDefine.OperateType.CHANGE,
                    item = v,
                    page = v.Where
                }
                SLBridge:onLUAEvent(LUA_EVENT_STORAGE_DATA_CHANGE, data)
                break
            end
        end
    end
end

function NPCStorageProxy:GetStorageDataByMakeIndex(MakeIndex)
    local MakeIndex = MakeIndex or 0
    local data = nil
    for _, v in pairs(self._storageData) do
        if MakeIndex and v.MakeIndex and MakeIndex == v.MakeIndex then
            data = v
            break
        end
    end
    return data
end

-- 整理仓库
local function sortFunc(a, b)
    local powera = GUIFunction:GetEquipPower(a)
    local powerb = GUIFunction:GetEquipPower(b)
    if powera ~= powerb then
        return powera > powerb
    else
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local isBindA, bindIndexA = ItemConfigProxy:CheckItemBind(a.Index)
        local isBindB, bindIndexB = ItemConfigProxy:CheckItemBind(b.Index)
        if isBindA == isBindB then
            return a.Index < b.Index
        else
            return isBindA
        end
    end
end

function NPCStorageProxy:ArrangeStorageData(page) 
    local data = {}
    for _, v in pairs(self._storageData) do
        table.insert(data, v)
    end
    if not data or next(data) == nil then 
        return 
    end 

    -- 按照战力排序
    if GUIFunction.SortStorageItemFunc then
        table.sort(data, function(a, b)
            return GUIFunction:SortStorageItemFunc(a, b)
        end)
    else
        table.sort(data, sortFunc)
    end

    -- 更新位置
    self:CleanStoragePosData()
    self:AmendHistoryPos(data)
    self:SetPosMarkData()

    -- 重新排列数据
    self._storageData = {}
    local data = {}
    data = self._storageVo
    for i, v in pairs(data) do 
        local pos = self:GetStoragePosByMakeIndex(v.MakeIndex)
        if pos then 
            self._storageData[pos] = v
        end 
    end 

    SL:onLUAEvent(LUA_EVENT_STORAGE_DATA_UPDATE, page)

    local data = {
        opera = 4,  -- 整理/刷新页
        page = page
    }
    SLBridge:onLUAEvent(LUA_EVENT_STORAGE_DATA_CHANGE, data)
end 

-- 请求存储
function NPCStorageProxy:RequestSaveToStorage(MakeIndex, Name)
    local npcIndex = self:GetNpcIndex()
    if not npcIndex then
        return
    end

    if not self:CheckPutInStorageState() or self._scheduleId then
        local systipStr = self._scheduleId and GET_STRING(90100005) or GET_STRING(90100004)
        global.Facade:sendNotification(global.NoticeTable.SystemTips, systipStr)

        -- 背包中的重新刷出来
        local data = {
            storage = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        return
    end

    self._scheduleId = PerformWithDelayGlobal(function()
        self._scheduleId = nil
    end, 0.3)

    local pageIndex = self:GetStoragePageIndex() or 1
    LuaSendHeader12(global.MsgType.MSG_CS_STORAGE_STORE_REQUEST, MakeIndex, npcIndex, pageIndex, Name)
end

function NPCStorageProxy:RequestSaveToStorageAllPage(MakeIndex, Name, setPageIndex)
    --请求存储
    local npcIndex = self:GetNpcIndex()
    if not npcIndex then
        return
    end
    local pageIndex = 1
    for i = 1, self._maxPage do
        local index = i
        local openCount = self._openedCount
        local pageData = self:GetStorageDataByPage(index)
        local itemCount = #pageData
        local pageMaxNum = GUIDefine.STORAGE_PER_PAGE_MAX
        local thisPageOpenCount = openCount - (index-1) * pageMaxNum
        if thisPageOpenCount > pageMaxNum then
            thisPageOpenCount = pageMaxNum
        end
        if itemCount < thisPageOpenCount then
            pageIndex = i
            break
        end
        pageIndex = nil
    end
    if not pageIndex or self._scheduleId then
        local systipStr = self._scheduleId and GET_STRING(90100005) or GET_STRING(90100004)
        global.Facade:sendNotification(global.NoticeTable.SystemTips, systipStr)
        -- 背包中的重新刷出来
        local data = {
            storage = {
                MakeIndex = MakeIndex,
                state = 1
            }
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        return
    end

    self._scheduleId = PerformWithDelayGlobal(function()
        self._scheduleId = nil
    end, 0.3)
    LuaSendHeader12(global.MsgType.MSG_CS_STORAGE_STORE_REQUEST, MakeIndex, npcIndex , pageIndex, Name)
end

function NPCStorageProxy:CheckPutInStorageState()
    local index = self:GetStoragePageIndex()
    local pageData = self:GetStorageDataByPage(index)
    local itemCount = #pageData
    local pageMaxNum = GUIDefine.STORAGE_PER_PAGE_MAX
    local thisPageOpenCount = self._openedCount - (index - 1) * pageMaxNum

    local isWinMode = SL:GetValue("IS_PC_OPER_MODE")
    local storage_row_col = SL:GetValue("GAME_DATA", "bag_storage_row_col_max")
    local bBig = false  -- 是否大仓库
    if isWinMode and storage_row_col then
        local slices = G_GetSplitArray(storage_row_col, "|")
        local row = tonumber(slices[1]) or 8
        local col = tonumber(slices[2]) or 6
        if row * col > pageMaxNum then 
            bBig = true
        end 
    end 
    if not bBig and thisPageOpenCount > pageMaxNum then
        thisPageOpenCount = pageMaxNum
    end
    return itemCount < thisPageOpenCount
end

--请求仓库数据
function NPCStorageProxy:RequestStorageData()
    LuaSendMsg(global.MsgType.MSG_CS_STORAGEDATA_REQUEST, 0, 0, 0, 0, 0, 0)
end

-- 请求取出
function NPCStorageProxy:RequestPutOutStorageData(MakeIndex, Name)
    local npcIndex = self:GetNpcIndex()
    if not npcIndex then
        return
    end

    -- 背包已满，仓库中重新刷出来
    if BagData.isToBeFull(true) then
        local data = {
            resetItem = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }

        SL:onLUAEvent(LUA_EVENT_STORAGE_ITEM_STATE, data)
        return
    end

    LuaSendHeader12(global.MsgType.MSG_CS_STORAGE_PICK_OUT_REQUEST, MakeIndex, npcIndex, 0, Name)
end

function NPCStorageProxy:handle_MSG_SC_STOR_DATA(msg)
    local openCount = msg:GetP0()
    local index = msg:GetP1()
    local count = msg:GetP2()
    local isself = msg:GetP3()
    self:CleanData()

    self:SetOpenSize(openCount)

    local buffer = msg:GetBodyLuaBuffer()
    local Items = {}
    for i = 1, count do
        local data = ReadItemData(buffer)
        Items[i] = data
    end
    self:SetStorageData(Items)

    self:SetNpcIndex(index)

    local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    npcProxy:Cleanup()

    if isself == 0 then--是自己请求的还是脚本发的
        UIOperator:OpenNpcStorageUI()
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_STORE_STORED_ADD(msg)
    print("存仓成功")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex and MakeIndex ~= 0 then
        local item = BagData.GetItemDataByMakeIndex(MakeIndex)
        if item then
            BagData.DelItemData(item, true)
            local pageIdnex = header.p1
            self:AddStorageData(item, pageIdnex)
        end
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_STORE_FULL(msg)
    print("存仓失败， 仓库满")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex then
        -- 背包中的重新刷出来
        local data = {
            storage = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_STORE_FORBIDDEN(msg)
    print("存仓失败")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex then
        -- 背包中的重新刷出来
        local data = {
            storage = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_PICK_OUT_FORBIDDEN(msg)
    print("取出失败")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex then
        -- 仓库中重新刷出来
        local data = {
            resetItem = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }
        SL:onLUAEvent(LUA_EVENT_STORAGE_ITEM_STATE, data)
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_PICK_OUT_SUCC(msg)
    print("取出成功")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex and MakeIndex ~= 0 then
        local item = self:GetStorageDataByMakeIndex(MakeIndex)
        if item then
            self:DeleteStorageData(item)
        end
    end

end

function NPCStorageProxy:handle_MSG_SC_STORAGE_PICK_OUT_FULL(msg)
    print("背包满 取出失败")
    local header = msg:GetHeader12()
    local MakeIndex = header.Guid
    if MakeIndex then
        -- 背包已满，仓库中重新刷出来
        local data = {
            resetItem = {
                state = 1,
                MakeIndex = MakeIndex,
            }
        }
        SL:onLUAEvent(LUA_EVENT_STORAGE_ITEM_STATE, data)
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_UPDATE(msg)
    local header = msg:GetHeader13()
    local MakeIndex = header.Guid
    if MakeIndex and MakeIndex ~= 0 then
        local bagMakeIndex = msg:GetBodyStr()
        local item = BagData.GetItemDataByMakeIndex(bagMakeIndex)
        if item then
            BagData.DelItemData(item, true)
        end

        local itemNums = header.p1
        self:UpdateStorageData(MakeIndex, itemNums)
    end
end

function NPCStorageProxy:handle_MSG_SC_STORAGE_COUNT_CHANGE(msg)
    local count = msg:GetP0()
    self:SetOpenSize(count)

    SLBridge:onLUAEvent(LUA_EVENT_STORAGE_SIZE_CHANGE)
end

function NPCStorageProxy:RegisterMsgHandler()
    NPCStorageProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    -- 仓库数据
    LuaRegisterMsgHandler(msgType.MSG_SC_STOR_DATA, handler(self, self.handle_MSG_SC_STOR_DATA))
    -- 存仓成功
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_STORE_STORED_ADD, handler(self, self.handle_MSG_SC_STORAGE_STORE_STORED_ADD))
    -- 仓库满 存仓失败
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_STORE_FULL, handler(self, self.handle_MSG_SC_STORAGE_STORE_FULL))
    -- 其他 存仓失败
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_STORE_FORBIDDEN, handler(self, self.handle_MSG_SC_STORAGE_STORE_FORBIDDEN))
    -- 其他 取出失败
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_PICK_OUT_FORBIDDEN, handler(self, self.handle_MSG_SC_STORAGE_PICK_OUT_FORBIDDEN))
    -- 取出成功
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_PICK_OUT_SUCC, handler(self, self.handle_MSG_SC_STORAGE_PICK_OUT_SUCC))
    -- 背包满 取出失败
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_PICK_OUT_FULL, handler(self, self.handle_MSG_SC_STORAGE_PICK_OUT_FULL))
    --仓库，存物品时候，存的叠加物品，需要更新
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_UPDATE, handler(self, self.handle_MSG_SC_STORAGE_UPDATE))
    -- 仓库格子数增加
    LuaRegisterMsgHandler(msgType.MSG_SC_STORAGE_COUNT_CHANGE, handler(self, self.handle_MSG_SC_STORAGE_COUNT_CHANGE))
end

return NPCStorageProxy