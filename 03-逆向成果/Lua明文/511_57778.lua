local RemoteProxy = requireProxy("RemoteProxy")
local ItemMoveProxy = class("ItemMoveProxy", RemoteProxy)
ItemMoveProxy.NAME = global.ProxyTable.ItemMoveProxy

local proxyUtils = requireUtil("proxyUtils")

local takeOnEquipFromTo = {
    [GUIDefine.ItemFrom.BAG] = {
        [GUIDefine.ItemGoTo.PLAYER_EQUIP]   = true,
        [GUIDefine.ItemGoTo.BEST_RINGS]     = true,
        [GUIDefine.ItemGoTo.HERO_EQUIP]     = true,
    },
    [GUIDefine.ItemFrom.HERO_BAG] = {
        [GUIDefine.ItemGoTo.HERO_EQUIP]      = true,
        [GUIDefine.ItemGoTo.HERO_BEST_RINGS] = true,
        [GUIDefine.ItemGoTo.PLAYER_EQUIP]    = true,
    },
}

function ItemMoveProxy:ctor()
    ItemMoveProxy.super.ctor(self)
    self.onMovingItem = nil
    self.onMoving = false
    self.movingItemFrom = nil
    self.linkFunc = nil
    self.onMovingSkill = nil
    self._guiTypeNum = 0
    self._lastOnMovingTakeOnItem = nil     -- 上次移动穿戴物品MakeIndex (用于穿戴失败刷新)
end

function ItemMoveProxy:DropItem(data)
    --背包丢弃开关
    if SL:GetValue("SETTING_ENABLED", SLDefine.SETTINGID.SETTING_IDX_DISCARD_GOODS) == 0 then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    local item = data.itemData
    --   背包 -> 地面
    if not item or next(item) == nil then
        return true
    end
    global.Facade:sendNotification(global.NoticeTable.IntoDropItem, item)
    return false
end
function ItemMoveProxy:DropItem_Hero(data)
    local item = data.itemData
    --   英雄背包 -> 地面
    if not item or next(item) == nil then
        return true
    end
    global.Facade:sendNotification(global.NoticeTable.IntoDropItem_Hero, item)
    return false
end

function ItemMoveProxy:DropGold(data)
    -- 丢弃金币 背包金币 -> 地面
    local function callback(btnType, data)
        local bagState = {
            goldState = 1
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, bagState)
        if data.editStr and data.editStr ~= "" then
            if type(data.editStr) == "string" then
                local num = tonumber(data.editStr)
                LuaSendMsg(global.MsgType.MSG_CS_MAP_GOOD_DISCARD, num, 0, 0, 0)
            end
        end
    end
    local data = {}
    data.str = GET_STRING(90020002)
    data.callback = callback
    data.btnType = 1
    data.showEdit = true
    data.editParams = {
        inputMode = 2
    }
    UIOperator:OpenCommonTipsUI(data)
end

function ItemMoveProxy:ChangeItemPos(data)
    -- 道具换位 背包 -> 背包
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag --点击到的位置
    local posMakeIndexInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local posDataInBag = BagData.GetItemDataByMakeIndex(posMakeIndexInbag)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    if posMakeIndexInbag then
        if posMakeIndexInbag == itemData.MakeIndex then --不变
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        elseif posDataInBag and posDataInBag.Index == itemData.Index and ItemConfigProxy:CheckItemOverLapById(itemData.Index) then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
            local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
            BagProxy:RequestItemTwoToOne(posMakeIndexInbag, itemData.MakeIndex)
            return true
        else --换位
            -- 先结束事件
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
            BagData.ExchangePos(itemData.MakeIndex, targetPosInBag, posMakeIndexInbag, beginPos)

            if global.isWinPlayMode then
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                    MakeIndex = posMakeIndexInbag,
                    pos = pos
                })
                return true
            end
        end
    else --移动
        -- 先结束事件
        if targetPosInBag > BagData.GetMaxBag() then -- 如果位置上锁了
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
            return true
        end
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end
function ItemMoveProxy:ChangeItemPos_Hero(data)
    -- 道具换位 背包 -> 背包
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag --点击到的位置
    local HeroBagProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroBagProxy)
    local posMakeIndexInbag = HeroBagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = HeroBagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local posDataInBag = HeroBagData.GetItemDataByMakeIndex(posMakeIndexInbag)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    if posMakeIndexInbag then
        if posMakeIndexInbag == itemData.MakeIndex then --不变
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        elseif posDataInBag and posDataInBag.Index == itemData.Index and ItemConfigProxy:CheckItemOverLapById(itemData.Index) then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
            HeroBagProxy:RequestItemTwoToOne(posMakeIndexInbag, itemData.MakeIndex)
            return true
        else --换位
            -- 先结束事件
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
            HeroBagData.ExchangePos(itemData.MakeIndex, targetPosInBag, posMakeIndexInbag, beginPos)

            if global.isWinPlayMode then
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_HERO_BAG_POS_CHANGE,{
                    MakeIndex = posMakeIndexInbag,
                    pos = pos
                })
                return true
            end
        end
    else --移动
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        HeroBagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end
function ItemMoveProxy:PutItemInTreasureBox(data)
    -- 道具换位 背包 -> 宝箱
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

    local layer = data.boxLayer
    local itemData = data.itemData
    local boxData = data.boxData
    local MakeIndex = itemData.MakeIndex
    local boxMakeIndex = boxData.MakeIndex
    if ItemConfigProxy:CheckItemTreasureBoxKey(itemData) then
        if MakeIndex and boxMakeIndex and itemData.Shape == boxData.Shape then
            LuaSendHeader6(global.MsgType.MSG_SC_OPEN_TREASUREBOX, boxMakeIndex, MakeIndex)
            layer:setTouchEnabled(false)
        end
    end
end

function ItemMoveProxy:AddToQuickUse(data)
    -- 道具换位 背包 -> 快捷使用栏
    -- PC端将来自背包道具加入快捷栏 如果目标位置有道具则将该道具加入移动 该道具归属改变为来自背包
    -- 移动端 将道具加入快捷栏 如果快捷栏有道具 则将该道具移动到背包 不加入移动
    local itemData = data.itemData
    local pos = data.pos
    local posInQuickUse = data.posInQuickUse
    local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
    local canPutInList = AttrConfigProxy:GetItemsConfigQuickUsable()

    if not posInQuickUse
    or posInQuickUse <= 0
    or posInQuickUse > QuickUseData.GetQuickUseSize()
    or not canPutInList[itemData.StdMode] then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end

    -- 先结束事件
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)

    local posData = QuickUseData.GetQuickUseDataByPos(posInQuickUse)
    -- 从背包移出
    BagData.DelItemData(itemData)

    if posData then --替换
        -- 置空
        QuickUseData.SetQuickUsePosData(posInQuickUse, posData, true)
        -- 加入背包
        BagData.AddItemDataAndNotice(posData)
        -- PC 将背包的该道具加入移动
        if global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                MakeIndex = posData.MakeIndex,
                pos = pos
            })
        end
    end
    -- 加入快捷栏
    QuickUseData.SetQuickUsePosData(posInQuickUse, itemData)
    return true
end
function ItemMoveProxy:AddToQuickUse_FromHeroBag(data)
    -- 道具换位 背包 -> 快捷使用栏
    -- PC端将来自背包道具加入快捷栏 如果目标位置有道具则将该道具加入移动 该道具归属改变为来自背包
    -- 移动端 将道具加入快捷栏 如果快捷栏有道具 则将该道具移动到背包 不加入移动
    local itemData = data.itemData
    local pos = data.pos
    local posInQuickUse = data.posInQuickUse
    local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
    local canPutInList = AttrConfigProxy:GetItemsConfigQuickUsable()

    if not posInQuickUse
    or posInQuickUse <= 0
    or posInQuickUse > QuickUseData.GetQuickUseSize()
    or not canPutInList[itemData.StdMode] then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end

    -- 先结束事件
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)

    local posData = QuickUseData.GetQuickUseDataByPos(posInQuickUse)
    -- 从背包移出
    HeroBagData.DelItemData(itemData)

    if posData then --替换
        -- 置空
        QuickUseData.SetQuickUsePosData(posInQuickUse, posData, true)
        -- 加入背包
        HeroBagData.AddItemDataAndNotice(posData)
        -- PC 将背包的该道具加入移动
        if global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                MakeIndex = posData.MakeIndex,
                pos = pos
            })
        end
    end
    -- 加入快捷栏
    QuickUseData.SetQuickUsePosData(posInQuickUse, itemData)
    return true
end
function ItemMoveProxy:ChangeItemPosQuickUse(data)
    -- 道具换位 快捷栏 -> 快捷栏
    -- 换位  移动端直接换位
    -- PC端将目标位置的道具加入移动 来源位置为原移动道具位置
    local itemData = data.itemData
    local pos = data.pos
    local MakeIndex = itemData.MakeIndex
    local targetPos = data.posInQuickUse
    local myOldPos = QuickUseData.GetQuickUsePosByMakeIndex(MakeIndex)
    local targetItemData = QuickUseData.GetQuickUseDataByPos(targetPos)
    -- 清空原位置数据
    QuickUseData.SetQuickUsePosData(myOldPos, itemData, true)
    -- 清空目标位置数据
    if targetItemData then
        QuickUseData.SetQuickUsePosData(targetPos, targetItemData, true)
    end
    -- 目标位置数据加入
    QuickUseData.SetQuickUsePosData(targetPos, itemData)
    -- 原位置数据加入
    if targetItemData then
        QuickUseData.SetQuickUsePosData(myOldPos, targetItemData)
    end
    -- TODO: PC 端 将新创建节点的信息加入移动
    if global.isWinPlayMode then

    end
end

function ItemMoveProxy:DeleteQuickUse(data)
    -- 道具换位 快捷栏 -> 背包
    -- 如果背包格子满了 取消
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local isFull = BagData.isToBeFull()
    if isFull then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    else
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 从快捷栏移出
        local pos = QuickUseData.GetQuickUsePosByMakeIndex(MakeIndex)
        QuickUseData.SetQuickUsePosData(pos, itemData, true)
        -- 加入背包
        BagData.AddItemDataAndNotice(itemData)
        return true
    end
end
function ItemMoveProxy:DeleteQuickUse_ToHeroBag(data)
    -- 道具换位 快捷栏 -> 英雄背包
    -- 如果背包格子满了 取消
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local HeroBagProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroBagProxy)
    local isFull = HeroBagData.isToBeFull()
    if isFull then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    else
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 从快捷栏移出
        local pos = QuickUseData.GetQuickUsePosByMakeIndex(MakeIndex)
        QuickUseData.SetQuickUsePosData(pos, itemData, true)
        -- 加入背包
        HeroBagProxy:RequestHumBagToHeroBag(data.itemData.MakeIndex, data.itemData.Name)
        return true
    end
end

function ItemMoveProxy:TakeOnBestRing(data)
    -- 装备 背包 -> 主角装备
    local itemData = data.itemData
    local pos = data.pos
    local equipPos = data.equipPos
    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    global.Facade:sendNotification(global.NoticeTable.TakeOnRequest,
    {
        itemData = itemData,
        pos = equipPos
    }
    )
    return false

end
function ItemMoveProxy:TakeOnBestRing_Hero( data )
    -- 装备 背包 -> 主角装备
    local itemData = data.itemData
    local pos = data.pos
    local equipPos = data.equipPos
    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    global.Facade:sendNotification(global.NoticeTable.HeroTakeOnRequest,
    {
        itemData = itemData,
        pos = equipPos
    }
    )
    return false

end
function ItemMoveProxy:TakeOnItem_Hero( data )
    -- 装备 背包 -> 主角装备
    local itemData = data.itemData
    local equipPos = data.equipPos

    if equipPos == GUIDefine.EquipPosUI.Equip_Type_Bujuk then
        local posItemData = GUIFunction:GetEquipDataByPos(equipPos, nil, GUIDefine.EquipDataType.HEROEQUIP)
        if posItemData and posItemData.StdMode == 96 then
            local targetShape = posItemData.Shape
            local myAniCount = itemData.AniCount
            if itemData and itemData.StdMode == 3 and itemData.Shape == 4 and targetShape and myAniCount and targetShape == myAniCount then
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

                LuaSendHeader6(global.MsgType.MSG_CS_ITEM_FIX_ITEMS, itemData.MakeIndex, posItemData.MakeIndex)
                return true
            end
        end
    end

    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    local equipPosList = GUIFunction:GetEquipMappingConfig(equipPos)
    equipPosList = equipPosList or { equipPos }
    for k, v in pairs(list) do
        for _, equipPosition in ipairs(equipPosList) do -- 头部位置 显示上只有头 实际穿了头和斗笠两个位置
            if v == equipPosition then
                global.Facade:sendNotification(global.NoticeTable.HeroTakeOnRequest,
                {
                    itemData = itemData,
                    pos = equipPosition
                }
                )
                return false
            end
        end
    end
    if not global.isWinPlayMode then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    end
    return true
end
function ItemMoveProxy:TakeOnItem_Hero_FromHumBag(data)
    -- 人物背包 -> 英雄装备
    local itemData = data.itemData
    local equipPos = data.equipPos

    if equipPos == GUIDefine.EquipPosUI.Equip_Type_Bujuk then
        local posItemData = GUIFunction:GetEquipDataByPos(equipPos, nil, GUIDefine.EquipDataType.HEROEQUIP)
        if posItemData and posItemData.StdMode == 96 then
            local targetShape = posItemData.Shape
            local myAniCount = itemData.AniCount
            if itemData and itemData.StdMode == 3 and itemData.Shape == 4 and targetShape and myAniCount and targetShape == myAniCount then
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

                LuaSendHeader6(global.MsgType.MSG_CS_ITEM_FIX_ITEMS, itemData.MakeIndex, posItemData.MakeIndex)
                return true
            end
        end
    end

    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    local equipPosList = GUIFunction:GetEquipMappingConfig(equipPos)
    equipPosList = equipPosList or { equipPos }
    for k, v in pairs(list) do
        for _, equipPosition in ipairs(equipPosList) do -- 头部位置 显示上只有头 实际穿了头和斗笠两个位置
            if v == equipPosition then
                global.Facade:sendNotification(global.NoticeTable.HeroTakeOnRequestFromHumBag,
                {
                    itemData = itemData,
                    pos = equipPosition
                }
                )
                return false
            end
        end
    end
    if not global.isWinPlayMode then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    end
    return true
end


function ItemMoveProxy:TakeOnItem_FromHeroBag(data)
    --  英雄背包 -> 主角装备
    local itemData = data.itemData
    local equipPos = data.equipPos

    if equipPos == GUIDefine.EquipPosUI.Equip_Type_Bujuk then
        local posItemData = GUIFunction:GetEquipDataByPos(equipPos)
        if posItemData and posItemData.StdMode == 96 then
            local targetShape = posItemData.Shape
            local myAniCount = itemData.AniCount
            if itemData and itemData.StdMode == 3 and itemData.Shape == 4 and targetShape and myAniCount and targetShape == myAniCount then
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

                LuaSendHeader6(global.MsgType.MSG_CS_ITEM_FIX_ITEMS, itemData.MakeIndex, posItemData.MakeIndex)
                return true
            end
        end
    end

    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    local equipPosList = GUIFunction:GetEquipMappingConfig(equipPos)
    equipPosList = equipPosList or { equipPos }
    for k, v in pairs(list) do
        for _, equipPosition in ipairs(equipPosList) do -- 头部位置 显示上只有头 实际穿了头和斗笠两个位置
            if v == equipPosition then
                global.Facade:sendNotification(global.NoticeTable.TakeOnRequestFromHeroBag,
                {
                    itemData = itemData,
                    pos = equipPosition
                }
                )
                return false
            end
        end
    end
    if not global.isWinPlayMode then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    end
    return true
end
function ItemMoveProxy:TakeOnItem(data)
    -- 装备 背包 -> 主角装备
    local itemData = data.itemData
    local equipPos = data.equipPos

    if equipPos == GUIDefine.EquipPosUI.Equip_Type_Bujuk then
        local posItemData = GUIFunction:GetEquipDataByPos(equipPos)
        if posItemData and posItemData.StdMode == 96 then
            local targetShape = posItemData.Shape
            local myAniCount = itemData.AniCount
            if itemData and itemData.StdMode == 3 and itemData.Shape == 4 and targetShape and myAniCount and targetShape == myAniCount then
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

                LuaSendHeader6(global.MsgType.MSG_CS_ITEM_FIX_ITEMS, itemData.MakeIndex, posItemData.MakeIndex)
                return true
            end
        end
    end

    local list = GUIDefine.EquipPosByStdMode[itemData.StdMode]
    if not list or not next(list) then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return true
    end
    local equipPosList = GUIFunction:GetEquipMappingConfig(equipPos)
    equipPosList = equipPosList or { equipPos }
    for k, v in pairs(list) do
        for _, equipPosition in ipairs(equipPosList) do -- 头部位置 显示上只有头 实际穿了头和斗笠两个位置
            if v == equipPosition then
                global.Facade:sendNotification(global.NoticeTable.TakeOnRequest,
                {
                    itemData = itemData,
                    pos = equipPosition
                }
                )
                return false
            end
        end
    end
    if not global.isWinPlayMode then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    end
    return true
end
--CancelMove_Hero
function ItemMoveProxy:CancelHeroEquipMove_Hero(data)
    -- 在拖动或者其他延时操作时，被自动穿戴替换道具，此时的异常处理
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    return true
end

function ItemMoveProxy:TakeOffEquip_Hero(data)
    -- 脱下装备  英雄装备栏 -> 英雄背包
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local equipItemData = HeroEquipData.GetEquipDataByMakeIndex(MakeIndex)
    -- 在拖动或者其他延时操作时，被自动穿戴替换道具，此时的异常处理
    if not equipItemData then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return
    end

    global.Facade:sendNotification(global.NoticeTable.HeroTakeOffRequest, itemData)
end

function ItemMoveProxy:TakeOffEquip_Hero_To_HumBag(data)
    -- 脱下装备  英雄装备栏 -> 人物背包
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local equipItemData = HeroEquipData.GetEquipDataByMakeIndex(MakeIndex)
    -- 在拖动或者其他延时操作时，被自动穿戴替换道具，此时的异常处理
    if not equipItemData then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return
    end
    global.Facade:sendNotification(global.NoticeTable.HeroTakeOffRequestToHumBag, itemData)
end
function ItemMoveProxy:TakeOffEquip(data)
    -- 脱下装备  装备栏 -> 背包
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local equipItemData = EquipData.GetEquipDataByMakeIndex(MakeIndex)
    -- 在拖动或者其他延时操作时，被自动穿戴替换道具，此时的异常处理
    if not equipItemData then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return
    end

    global.Facade:sendNotification(global.NoticeTable.TakeOffRequest, itemData)
end
function ItemMoveProxy:TakeOffEquip_To_HeroBag(data)
    -- 脱下装备  人物装备栏 -> 英雄背包
    local itemData = data.itemData
    local MakeIndex = itemData.MakeIndex
    local equipItemData = EquipData.GetEquipDataByMakeIndex(MakeIndex)
    -- 在拖动或者其他延时操作时，被自动穿戴替换道具，此时的异常处理
    if not equipItemData then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return
    end

    global.Facade:sendNotification(global.NoticeTable.TakeOffToHeroBagRequest, itemData)
end


--TODO:
function ItemMoveProxy:QuickUseIntoSellRequire(data)
    -- 预出售 预修理   快捷栏 -> 预览界面

end

function ItemMoveProxy:AddItemIntoSellRepaire(data)
    -- 预出售 预修理   背包 -> 预览界面
    local itemData = data.itemData
    local pos = data.pos
    local target = data.target
    if not itemData then
        return true
    end
    local data = {
        Name = itemData.Name,
        MakeIndex = itemData.MakeIndex
    }

    if target == GUIDefine.ItemGoTo.SELL then
        local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
        NPCSellProxy:SetOnSellingData(itemData)

        local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
        if not data or not npcId then
            return
        end
        local step = SL:GetValue("NPC_SELLING_STEP")
        if step ~= GUIDefine.NpcSellStep.ADD_ITEM then
            return
        end
        NPCSellProxy:RequestNpcStoreSellPre(data)
    elseif target == GUIDefine.ItemGoTo.REPAIRE then
        local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
        NPCRepaireProxy:SetOnRepairingData(itemData)
        local npcId = SL:GetValue("CURRENT_TALK_NPC_ID")
        if not data or not npcId then
            return
        end

        local step = SL:GetValue("NPC_REPAIRE_STEP")
        if step ~= GUIDefine.NpcRepaireStep.ADD_ITEM then
            return
        end
        NPCRepaireProxy:RequestNpcStoreRepairePre(data)
    elseif target == GUIDefine.ItemGoTo.NPC_DO_SOMETHING then
        local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
        NPCDoSomethingProxy:SetonDoThingsData(itemData)
    elseif target == GUIDefine.ItemGoTo.NEWTYPE then
        local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
        NPCNewTypeOkProxy:SetonDoThingsData(itemData)
    end
    local data = {
        itemData = itemData
    }
    SL:onLUAEvent(LUA_EVENT_NPC_SELL_REPAIRE_UPDATE, data)
end
--和背包丢弃同一接口， 快捷栏数据全部来自于背包
function ItemMoveProxy:DropItemFromQuickUse(data)
    -- 丢弃  快捷栏 -> 地面
    local itemData = data.itemData
    if not itemData or not next(itemData) then
        return true
    end
    global.Facade:sendNotification(global.NoticeTable.IntoDropItem, itemData)
    return false
end

function ItemMoveProxy:PlayerEquipToPlayerEquip(data)
    -- 取消  装备栏 -> 装备栏
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    return true
end

function ItemMoveProxy:BestRingToBestRing(data)
    -- 取消  生肖栏 -> 生肖栏
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    return true
end

function ItemMoveProxy:CancelSellIntoBag(data)
    -- 取消 预出售 预修理  预览界面 -> 背包
    --移动端 直接取消
    --PC端 原位置 == 取消 新位置 移动到新位置 有物品的位置 交换位置并且添加该物品到移动
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag
    local posDataInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
    NPCSellProxy:ResetSellingState()
    if posDataInbag then
        if posDataInbag == itemData.MakeIndex then --不变
            -- 背包中的重新刷出来
            local data = {
                storage = {
                    MakeIndex = itemData.MakeIndex,
                    state = 1
                }
            }
            SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        else --换位
            if global.isWinPlayMode then
                BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
                BagData.SetItemPosData(posDataInbag, beginPos)
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                    MakeIndex = posDataInbag,
                    pos = pos
                })
            else
                local newPos = BagData.GetEmptyPos()
                newPos = newPos < beginPos and newPos or beginPos
                -- 先结束事件
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
                -- 再发刷新
                BagData.SetItemPosData(itemData.MakeIndex, newPos)
            end
            return true
        end
    else --移动
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end

function ItemMoveProxy:CancelRequireIntoBag(data)
    -- 取消 预出售 预修理  预览界面 -> 背包
    -- 移动端 直接取消
    -- PC端 原位置 == 取消 新位置 移动到新位置 有物品的位置 交换位置并且添加该物品到移动
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag
    local posDataInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
    NPCRepaireProxy:ResetRepairingState()
    if posDataInbag then
        if posDataInbag == itemData.MakeIndex then --不变
            -- 背包中的重新刷出来
            local data = {
                storage = {
                    MakeIndex = itemData.MakeIndex,
                    state = 1
                }
            }
            SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        else --换位
            if global.isWinPlayMode then
                BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
                BagData.SetItemPosData(posDataInbag, beginPos)
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                    MakeIndex = posDataInbag,
                    pos = pos
                })
            else
                local newPos = BagData.GetEmptyPos()
                newPos = newPos < beginPos and newPos or beginPos
                -- 先结束事件
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
                -- 再发刷新
                BagData.SetItemPosData(itemData.MakeIndex, newPos)
            end
            return true
        end
    else --移动
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end

function ItemMoveProxy:CancelDoSomethingIntoBag(data)
    -- 取消 请求 -> 背包
    -- 移动端 直接取消
    -- PC端 原位置 == 取消 新位置 移动到新位置 有物品的位置 交换位置并且添加该物品到移动
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag
    local posDataInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
    NPCDoSomethingProxy:CleanOnDoData()
    if posDataInbag then
        if posDataInbag == itemData.MakeIndex then --不变
            -- 背包中的重新刷出来
            local data = {
                storage = {
                    MakeIndex = itemData.MakeIndex,
                    state = 1
                }
            }
            SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        else --换位
            if global.isWinPlayMode then
                BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
                BagData.SetItemPosData(posDataInbag, beginPos)
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                    MakeIndex = posDataInbag,
                    pos = pos
                })
            else
                local newPos = BagData.GetEmptyPos()
                newPos = newPos < beginPos and newPos or beginPos
                -- 先结束事件
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
                -- 再发刷新
                BagData.SetItemPosData(itemData.MakeIndex, newPos)
            end
            return true
        end
    else --移动
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end

function ItemMoveProxy:CancelNewTypeIntoBag(data)
    -- 取消 请求 -> 背包
    -- 移动端 直接取消
    -- PC端 原位置 == 取消 新位置 移动到新位置 有物品的位置 交换位置并且添加该物品到移动
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInBag = data.itemPosInbag
    local posDataInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
    local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
    local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
    NPCNewTypeOkProxy:CleanOnDoData()
    if posDataInbag then
        if posDataInbag == itemData.MakeIndex then --不变
            -- 背包中的重新刷出来
            local data = {
                storage = {
                    MakeIndex = itemData.MakeIndex,
                    state = 1
                }
            }
            SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
        else --换位
            if global.isWinPlayMode then
                BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
                BagData.SetItemPosData(posDataInbag, beginPos)
                SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                    MakeIndex = posDataInbag,
                    pos = pos
                })
            else
                local newPos = BagData.GetEmptyPos()
                newPos = newPos < beginPos and newPos or beginPos
                -- 先结束事件
                SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
                -- 再发刷新
                BagData.SetItemPosData(itemData.MakeIndex, newPos)
            end
            return true
        end
    else --移动
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
        -- 再发刷新
        BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
        return true
    end
end

function ItemMoveProxy:SellOrRequiredCancel(data)
    -- if global.isWinPlayMode then
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    -- end
end

function ItemMoveProxy:AddItemIntoTrade(data)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    local state = proxyUtils.GetLockState()
    if state then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInTrade = data.itemPosInTrade
    if not itemData then
        return true
    end

    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local MakeIndex = itemData.MakeIndex
    local Name = itemData.Name
    local isBind, isMeetType = CheckItemisBind(itemData, GUIDefine.ItemArticleType.TYPE_TRADE)
    if isMeetType then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        local data = {}
        data.str = string.format(GET_STRING(90020014), Name)
        data.btnType = 1
        UIOperator:OpenCommonTipsUI(data)
        return true
    else
        TradeProxy:RequestPutInItem(MakeIndex)
    end
end

function ItemMoveProxy:DeleteItemIntoTrade(data)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    local state = proxyUtils.GetLockState()
    if state then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInTrade = data.itemPosInTrade
    if not itemData then
        return true
    end
    local MakeIndex = itemData.MakeIndex
    local Name = itemData.Name
    TradeProxy:RequestPutOutItem(MakeIndex, Name)
end

function ItemMoveProxy:AddGoldToTrade(data)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    local state = proxyUtils.GetLockState()
    local moneyId = TradeProxy:GetTradeMoneyID()
    local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
    if state then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    -- 交易金币 背包金币 -> 交易栏
    local function callback(btnType, data)
        local bagState = {
            goldState = 1
        }
        SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, bagState)
        if data.editStr and data.editStr ~= "" then
            if type(data.editStr) == "string" then
                local num = tonumber(data.editStr)
                local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
                TradeProxy:RequestChangeMoney(num)
            end
        end
    end
    local data = {}
    local moneyName = moneyId and MoneyProxy:GetMoneyNameById(moneyId) or "金币"
    data.str = string.format(GET_STRING(90020016), moneyName)
    data.callback = callback
    data.btnType = 1
    data.showEdit = true
    data.editParams = {
        inputMode = 2
    }
    UIOperator:OpenCommonTipsUI(data)
end

function ItemMoveProxy:PutOutTradingGold(data)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    local state = proxyUtils.GetLockState()
    if state then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    local tradingCount = 0
    local tradingCount = TradeProxy:GetSelfGoldNum() or 0
    if tradingCount > 0 then
        TradeProxy:RequestChangeMoney(0)
    end
end
--取出
function ItemMoveProxy:GetOutStorageItemsToBag(data)

    local data = data.itemData
    local StorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    StorageProxy:RequestPutOutStorageData(data.MakeIndex, data.Name)

end
--放入
function ItemMoveProxy:AddItemIntoStorage(data)
    local data = data.itemData
    local StorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    StorageProxy:RequestSaveToStorage(data.MakeIndex, data.Name)
end

function ItemMoveProxy:CancelPutOutStorage(data)
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
end

-- 摆摊取出
function ItemMoveProxy:PutStallItemInBag(data)
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInTrade = data.itemPosInTrade
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        SL:ShowSystemTips("摆摊中，禁止操作")
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    if not itemData then
        -- 先结束事件
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    -- 先结束事件
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
    local MakeIndex = itemData.MakeIndex
    SL:StallRmvMySellItem(MakeIndex)
    itemData.goldtype = nil
    itemData.price = 0
    BagData.AddItemDataAndNotice(itemData)
    SL:onLUAEvent(LUA_EVENT_STALL_SELF_ITEM_CHANGE, itemData)

end
-- 摆摊放入
function ItemMoveProxy:PutItemInStall(data)
    local itemData = data.itemData
    local pos = data.pos
    local targetPosInTrade = data.itemPosInTrade
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        SL:ShowSystemTips("摆摊中，禁止操作")
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return true
    end
    if not itemData then
        return true
    end

    local MakeIndex = itemData.MakeIndex
    local Name = itemData.Name
    local isBind, noTradeByArticle = SL:GetValue("ITEM_IS_BIND", itemData, GUIDefine.ItemArticleType.TYPE_TRADE_AUCTION)
    if isBind or noTradeByArticle then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        local data = {}
        data.str = string.format(isBind and GET_STRING(90020005) or GET_STRING(90170005), Name)
        data.btnType = 1
        UIOperator:OpenCommonTipsUI(data)
        return true    
    end
    UIOperator:OpenStallPutLayerUI(MakeIndex)
end
-- itembox 取出
function ItemMoveProxy:PutITEMBOXItemInBag(data)
    local boxindex = global.SUIManager:GetITEMBOXIndexByMakeIndex(data.itemData.MakeIndex)
    if boxindex then
        local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        local submitData =         {
            index    = boxindex,
            npcid    = npcProxy:GetCurrentNPCID()
        }
        global.SUIManager:RequestITEMBOXPutout(submitData)
    end
end
-- itembox 放入
function ItemMoveProxy:PutItemInTEMBOX(data)
    local function checkAble()
        if data.stdmode == "*" then
            return true
        end
        local slices = G_GetSplitArray(data.stdmode, ",")
        for i, v in ipairs(slices) do
            if tonumber(v) == data.itemData.StdMode then
                return true
            end
        end
        return false
    end
    if false == checkAble() then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return nil
    end

    -- send msg
    local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    local submitData = {
        makeindex = data.itemData.MakeIndex,
        index    = data.boxindex,
        npcid    = npcProxy:GetCurrentNPCID()
    }
    global.SUIManager:RequestITEMBOXPutin(submitData)
end

function ItemMoveProxy:PutItemIntoSomeEquip(data)
    -- 快捷栏 快捷栏 -> 主角装备
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
    local itemData = data.itemData
    local equipPos = data.equipPos

    if equipPos == GUIDefine.EquipPosUI.Equip_Type_Bujuk then
        local posItemData = GUIFunction:GetEquipDataByPos(equipPos)
        if posItemData and posItemData.StdMode == 96 then
            local targetShape = posItemData.Shape
            local myAniCount = itemData.AniCount
            if itemData and itemData.StdMode == 3 and itemData.Shape == 4 and targetShape and myAniCount and targetShape == myAniCount then

                LuaSendHeader6(global.MsgType.MSG_CS_ITEM_FIX_ITEMS, itemData.MakeIndex, posItemData.MakeIndex)
            end
        end
    end
    return true
end
function ItemMoveProxy:HumBagToHeroBag(data)
    -- 人物背包 -> 英雄背包
    local HeroBagProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroBagProxy)
    if not HeroBagData.isToBeFull(true) then
        HeroBagProxy:RequestHumBagToHeroBag(data.itemData.MakeIndex, data.itemData.Name)
    end
end
function ItemMoveProxy:HeroBagToHumBag(data)
    -- 人物背包 -> 英雄背包
    local HeroBagProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroBagProxy)
    HeroBagProxy:RequestHeroBagToHumBag(data.itemData.MakeIndex, data.itemData.Name)
end

-----
function ItemMoveProxy:SkillShowToTopUI(data)
    if not data.skillId then
        return
    end

    SLBridge:onLUAEvent(LUA_EVENT_SKILL_ADD_TO_UI_WIN32, { skillID = data.skillId, pos = data.pos })
end

----- GUIItemBox
-- GUI Itembox 取出
function ItemMoveProxy:PutGUIItemBoxItemInBag(data)
    local boxindex = global.SUIManager:GetGUIItemBoxIndexByMakeIndex(data.itemData.MakeIndex)
    if boxindex then
        global.Facade:sendNotification(global.NoticeTable.GUI_ITEMBOX_Widget_Remove, {boxindex = boxindex})

        local itemData = data.itemData
        local pos = data.pos
        local targetPosInBag = data.itemPosInbag
        local posDataInbag = BagData.GetMakeIndexByBagPos(targetPosInBag)
        local beginPos = BagData.GetBagPosByMakeIndex(itemData.MakeIndex)
        if posDataInbag then
            if posDataInbag == itemData.MakeIndex then --不变
                -- 背包中的重新刷出来
                local data = {
                    storage = {
                        MakeIndex = itemData.MakeIndex,
                        state = 1
                    }
                }
                SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
            else --换位
                if global.isWinPlayMode then
                    BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
                    BagData.SetItemPosData(posDataInbag, beginPos)
                    SL:onLUAEvent(LUA_EVENT_ITEM_MOVE_BEGIN_BAG_POS_CHANGE,{
                        MakeIndex = posDataInbag,
                        pos = pos
                    })
                else
                    local newPos = BagData.GetEmptyPos()
                    newPos = newPos < beginPos and newPos or beginPos
                    -- 先结束事件
                    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
                    -- 再发刷新
                    BagData.SetItemPosData(itemData.MakeIndex, newPos)
                end
                return true
            end
        else --移动
            -- 先结束事件
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
            -- 再发刷新
            BagData.SetItemPosData(itemData.MakeIndex, targetPosInBag)
            return true
        end

    end
end

-- GUI ItemBox 放入
function ItemMoveProxy:PutItemInGUIItemBox(data)
    local function checkAble()
        if data.stdmode == "*" then
            return true
        end
        local stdmodeList = {}
        if type(data.stdmode) == "table" then
            stdmodeList = data.stdmode
        elseif type(data.stdmode) == "number" then
            table.insert(stdmodeList, data.stdmode)
        end
        for i, v in ipairs(stdmodeList) do
            if tonumber(v) == data.itemData.StdMode then
                return true
            end
        end
        return false
    end
    if false == checkAble() then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        return nil
    end

    global.Facade:sendNotification(global.NoticeTable.GUI_ITEMBOX_Widget_Update, data)
end

function ItemMoveProxy:TakeOffPetEquipLink(data)
    -- 宠物装备栏 -> 背包 （ 不限制宠物
    local itemData = data.itemData
    local pos = data.pos
    SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)

    if type(data.linkFunc) == "function" then
        data.linkFunc()
    end
end
----------------------------
function ItemMoveProxy:ExchangeItemMoveItem(param)
    local resetOldCallBack = param.resetOld
    local newItemData = param.goMovingData
    --step1:RESET Old ITEM STATE
    resetOldCallBack()
    --step2:CHANGE MOVING DATA ON newItemData
    --TODO:将当前移动的节点用新的替换
end

function ItemMoveProxy:GetItemMoveFrom()
    return self.movingItemFrom
end

function ItemMoveProxy:SetMoveItemData(data, from, skillId)
    --有来源即可  可能移动的节点 不一定是道具
    if from then
        self.onMovingItem = data
        self.onMoving = true
        self.onMovingSkill = skillId
        if skillId then
            SLBridge:onLUAEvent(LUA_EVENT_SKILL_DEL_TO_UI_WIN32, skillId)
        end
    else
        self.onMovingItem = nil
        self.onMoving = false
        self.onMovingSkill = nil
    end
    self.movingItemFrom = from
end

function ItemMoveProxy:SetLinkFunc(func)
    if type(func) == "function" then
        self.linkFunc = func
    else
        self.linkFunc = nil
    end
end

function ItemMoveProxy:GetItemCanGoTargetFunc(target)
    self._lastOnMovingTakeOnItem = nil
    if not self.movingItemFrom or not target then
        return false
    end
    local itemTargetMap = ItemMoveProxy.ItemFromAndGoToMap[self.movingItemFrom]

    if not itemTargetMap or not next(itemTargetMap) then
        return false
    end
    local callBackFun = itemTargetMap[target]

    if takeOnEquipFromTo[self.movingItemFrom] and takeOnEquipFromTo[self.movingItemFrom][target] then
        self._lastOnMovingTakeOnItem = self.onMovingItem and self.onMovingItem.MakeIndex
    end

    return callBackFun
end
-- 如果不需要结束移动，或者在自己的逻辑中已经结束 则方法返回bool true
function ItemMoveProxy:CheckAndCallBack(data)
    local target = data.target
    local callBackFunc = self:GetItemCanGoTargetFunc(target)
    if not callBackFunc then
        if not global.isWinPlayMode then
            SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL)
        end
        return
    end
    data.itemData = self.onMovingItem
    data.linkFunc = self.linkFunc
    data.skillId = self.onMovingSkill
    if not callBackFunc(self, data) then
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_END)
    end
end

function ItemMoveProxy:GetMovingItemState()
    return self.onMoving
end

function ItemMoveProxy:GetMovingItemData()
    return self.onMovingItem
end

function ItemMoveProxy:GetMovingSkill()
    return self.onMovingSkill
end

function ItemMoveProxy:GetLastMovingTakeOnItem()
    return self._lastOnMovingTakeOnItem
end

function ItemMoveProxy:ClearLastMovingTakeOnItem()
    self._lastOnMovingTakeOnItem = nil
end

function ItemMoveProxy:onRegister()
    ItemMoveProxy.super.onRegister(self)
    --放在最后 先注册方法
    ItemMoveProxy.ItemFromAndGoToMap = {
        [GUIDefine.ItemFrom.BAG] = {
            [GUIDefine.ItemGoTo.BAG]            = ItemMoveProxy.ChangeItemPos,
            [GUIDefine.ItemGoTo.PLAYER_EQUIP]   = ItemMoveProxy.TakeOnItem,
            [GUIDefine.ItemGoTo.QUICK_USE]      = ItemMoveProxy.AddToQuickUse,
            [GUIDefine.ItemGoTo.STORAGE]        = ItemMoveProxy.AddItemIntoStorage,
            [GUIDefine.ItemGoTo.SELL]           = ItemMoveProxy.AddItemIntoSellRepaire,
            [GUIDefine.ItemGoTo.DROP]           = ItemMoveProxy.DropItem,
            [GUIDefine.ItemGoTo.REPAIRE]        = ItemMoveProxy.AddItemIntoSellRepaire,
            [GUIDefine.ItemGoTo.TRADE]          = ItemMoveProxy.AddItemIntoTrade,
            [GUIDefine.ItemGoTo.BEST_RINGS]     = ItemMoveProxy.TakeOnBestRing,
            [GUIDefine.ItemGoTo.AUTO_TRADE]     = ItemMoveProxy.PutItemInStall,
            [GUIDefine.ItemGoTo.ITEMBOX]        = ItemMoveProxy.PutItemInTEMBOX,
            [GUIDefine.ItemGoTo.NPC_DO_SOMETHING] = ItemMoveProxy.AddItemIntoSellRepaire,
            [GUIDefine.ItemGoTo.TreasureBox]    = ItemMoveProxy.PutItemInTreasureBox,
            [GUIDefine.ItemGoTo.HERO_BAG]       = ItemMoveProxy.HumBagToHeroBag,
            [GUIDefine.ItemGoTo.NEWTYPE]        = ItemMoveProxy.AddItemIntoSellRepaire,
            [GUIDefine.ItemGoTo.HERO_EQUIP]     = ItemMoveProxy.TakeOnItem_Hero_FromHumBag,
            [GUIDefine.ItemGoTo.GUI_ITEMBOX]    = ItemMoveProxy.PutItemInGUIItemBox,
        },
        [GUIDefine.ItemFrom.PLAYER_EQUIP] = {
            [GUIDefine.ItemGoTo.BAG]          = ItemMoveProxy.TakeOffEquip,
            [GUIDefine.ItemGoTo.PLAYER_EQUIP] = ItemMoveProxy.PlayerEquipToPlayerEquip,
            [GUIDefine.ItemGoTo.HERO_BAG]     = ItemMoveProxy.TakeOffEquip_To_HeroBag,
        },
        [GUIDefine.ItemFrom.QUICK_USE] = {
            [GUIDefine.ItemGoTo.BAG]          = ItemMoveProxy.DeleteQuickUse,
            [GUIDefine.ItemGoTo.QUICK_USE]    = ItemMoveProxy.ChangeItemPosQuickUse,
            -- [GUIDefine.ItemGoTo.STORAGE] = ItemMoveProxy.AddItemIntoStorage,
            -- [GUIDefine.ItemGoTo.SELL] = ItemMoveProxy.QuickUseIntoSellRequire,
            [GUIDefine.ItemGoTo.DROP]         = ItemMoveProxy.DropItemFromQuickUse,
            -- [GUIDefine.ItemGoTo.REPAIRE] = ItemMoveProxy.QuickUseIntoSellRequire,
            [GUIDefine.ItemGoTo.PLAYER_EQUIP] = ItemMoveProxy.PutItemIntoSomeEquip,
            [GUIDefine.ItemGoTo.HERO_BAG]     = ItemMoveProxy.DeleteQuickUse_ToHeroBag,
        },
        [GUIDefine.ItemFrom.STORAGE] = {
            [GUIDefine.ItemGoTo.BAG]       = ItemMoveProxy.GetOutStorageItemsToBag,
            [GUIDefine.ItemGoTo.STORAGE]   = ItemMoveProxy.CancelPutOutStorage,
        },
        [GUIDefine.ItemFrom.BAG_GOLD] = {
            [GUIDefine.ItemGoTo.DROP]      = ItemMoveProxy.DropGold,
            [GUIDefine.ItemGoTo.TRADE]     = ItemMoveProxy.AddGoldToTrade,
            [GUIDefine.ItemGoTo.TRADE_GOLD]= ItemMoveProxy.AddGoldToTrade,
        },
        [GUIDefine.ItemFrom.SELL] = {
            [GUIDefine.ItemGoTo.BAG]       = ItemMoveProxy.CancelSellIntoBag,
            [GUIDefine.ItemGoTo.QUICK_USE] = ItemMoveProxy.ChangeItemPos,
            [GUIDefine.ItemGoTo.SELL]      = ItemMoveProxy.SellOrRequiredCancel
        },
        [GUIDefine.ItemFrom.REPAIRE] = {
            [GUIDefine.ItemGoTo.BAG]       = ItemMoveProxy.CancelRequireIntoBag,
            [GUIDefine.ItemGoTo.QUICK_USE] = ItemMoveProxy.ChangeItemPos,
            [GUIDefine.ItemGoTo.REPAIRE]   = ItemMoveProxy.SellOrRequiredCancel
        },
        [GUIDefine.ItemFrom.TRADE] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.DeleteItemIntoTrade,
        },
        [GUIDefine.ItemFrom.TRADE_GOLD] = {
            [GUIDefine.ItemGoTo.BAG_GOLD] = ItemMoveProxy.PutOutTradingGold,
        },
        [GUIDefine.ItemFrom.BEST_RINGS] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.TakeOffEquip,
            [GUIDefine.ItemGoTo.BEST_RINGS] = ItemMoveProxy.BestRingToBestRing,
        },
        [GUIDefine.ItemFrom.AUTO_TRADE] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.PutStallItemInBag,
        },
        [GUIDefine.ItemFrom.ITEMBOX] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.PutITEMBOXItemInBag,
        },
        [GUIDefine.ItemFrom.NPC_DO_SOMETHING] = {
            [GUIDefine.ItemGoTo.BAG]              = ItemMoveProxy.CancelDoSomethingIntoBag,
            [GUIDefine.ItemGoTo.QUICK_USE]        = ItemMoveProxy.ChangeItemPos,
            [GUIDefine.ItemGoTo.NPC_DO_SOMETHING] = ItemMoveProxy.SellOrRequiredCancel
        },
        [GUIDefine.ItemFrom.HERO_BAG] = {
            [GUIDefine.ItemGoTo.HERO_BAG]        = ItemMoveProxy.ChangeItemPos_Hero,
            [GUIDefine.ItemGoTo.HERO_EQUIP]      = ItemMoveProxy.TakeOnItem_Hero,
            [GUIDefine.ItemGoTo.BAG]             = ItemMoveProxy.HeroBagToHumBag,
            [GUIDefine.ItemGoTo.DROP]            = ItemMoveProxy.DropItem_Hero,
            [GUIDefine.ItemGoTo.HERO_BEST_RINGS] = ItemMoveProxy.TakeOnBestRing_Hero,
            [GUIDefine.ItemGoTo.PLAYER_EQUIP]    = ItemMoveProxy.TakeOnItem_FromHeroBag,
        },
        [GUIDefine.ItemFrom.HERO_EQUIP] = {
            [GUIDefine.ItemGoTo.HERO_BAG]   = ItemMoveProxy.TakeOffEquip_Hero,
            [GUIDefine.ItemGoTo.HERO_EQUIP] = ItemMoveProxy.CancelHeroEquipMove_Hero,
            [GUIDefine.ItemGoTo.DROP]       = ItemMoveProxy.CancelHeroEquipMove_Hero,
            [GUIDefine.ItemGoTo.BAG]        = ItemMoveProxy.TakeOffEquip_Hero_To_HumBag,
        },
        [GUIDefine.ItemFrom.HERO_BEST_RINGS] = {
            [GUIDefine.ItemGoTo.HERO_BAG] = ItemMoveProxy.TakeOffEquip_Hero,
            [GUIDefine.ItemGoTo.HERO_BEST_RINGS] = ItemMoveProxy.BestRingToBestRing,
        },
        [GUIDefine.ItemFrom.NEWTYPE] = {
            [GUIDefine.ItemGoTo.BAG]       = ItemMoveProxy.CancelNewTypeIntoBag,
            [GUIDefine.ItemGoTo.QUICK_USE] = ItemMoveProxy.ChangeItemPos,
            [GUIDefine.ItemGoTo.NEWTYPE]   = ItemMoveProxy.SellOrRequiredCancel
        },
        [GUIDefine.ItemFrom.SKILL_WIN] = {
            [GUIDefine.ItemGoTo.TOPUI] = ItemMoveProxy.SkillShowToTopUI,
        },
        [GUIDefine.ItemFrom.GUI_ITEMBOX] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.PutGUIItemBoxItemInBag
        },
        [GUIDefine.ItemFrom.PETS_EQUIP] = {
            [GUIDefine.ItemGoTo.BAG] = ItemMoveProxy.TakeOffPetEquipLink,
        },
    }
end

function ItemMoveProxy:AddMoveTypeAndFunc(from, to, fromToEvent, toFromEvent)
    local type = 100 + self._guiTypeNum
    if not GUIDefine.ItemFrom[from] then
        GUIDefine.ItemFrom[from] = type
    end

    if not GUIDefine.ItemGoTo [from] then
        GUIDefine.ItemGoTo [from] = type
    end
    self._guiTypeNum = self._guiTypeNum + 1

    local toType = 100 + self._guiTypeNum
    if not GUIDefine.ItemFrom[to] then
        GUIDefine.ItemFrom[to] = toType
    end

    if not GUIDefine.ItemGoTo [to] then
        GUIDefine.ItemGoTo [to] = toType
    end

    local fromType = GUIDefine.ItemFrom[from]
    local toType = GUIDefine.ItemGoTo [to]

    if fromToEvent then
        if not ItemMoveProxy.ItemFromAndGoToMap[fromType] then
            ItemMoveProxy.ItemFromAndGoToMap[fromType] = {
                [toType] = fromToEvent
            }
        else
            ItemMoveProxy.ItemFromAndGoToMap[fromType][toType] = fromToEvent
        end
    end

    if toFromEvent then
        if not ItemMoveProxy.ItemFromAndGoToMap[toType] then
            ItemMoveProxy.ItemFromAndGoToMap[toType] = {
                [fromType] = toFromEvent
            }
        else
            ItemMoveProxy.ItemFromAndGoToMap[toType][fromType] = toFromEvent
        end
    end
end

return ItemMoveProxy