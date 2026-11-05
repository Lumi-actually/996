local RemoteProxy = requireProxy("RemoteProxy")
local ItemManagerProxy = class("ItemManagerProxy", RemoteProxy)
ItemManagerProxy.NAME = global.ProxyTable.ItemManagerProxy

--README: 储存下道具来源，道具归属等信息

ItemManagerProxy.ItemType = {
    DruaAndSomething = 1, 		-- 道具表 StdMode 0~3 的道具
    SkillBook 		 = 2, 		-- 技能书
    Equip 			 = 3, 		-- 装备
    Bundle 			 = 4, 		-- 困束
    Box 			 = 5, 		-- 盒子
    TreasureMap 	 = 6, 		-- StdMode 为 101 的道具
    FashionItem 	 = 7, 		-- 时装道具
    MonsterCard 	 = 8, 		-- 怪物卡片
    SomethingCanUse  = 9, 		-- StdMode 为 49 的道具
    BoxKey 			 = 10, 		-- 箱子钥匙
    Collimator       = 11, 		-- 准星道具
    WishBox 		 = 12, 		-- StdMode 为 96 的道具
    NewPet 			 = 13, 		-- 宠物系统，道具使用
    Other 			 = 99 		-- 其他
}

function ItemManagerProxy:ctor()
    ItemManagerProxy.super.ctor(self)
    self.itemDataFrom = {}

    self._customItemMap = {}    -- 自定义随机/回城道具Index {[index] = true, ...}
end

function ItemManagerProxy:InitCustomItemConfig()
    self._customItemMap = {}
    local dataStr = SL:GetValue("GAME_DATA", "CustomCityRandItem")
    if dataStr and string.len(dataStr) > 0 then
        local list = G_GetSplitArray(dataStr, "#") or {}
        for i, v in ipairs(list) do
            if tonumber(v) then
                self._customItemMap[tonumber(v)] = true
            end
        end
    end
end

function ItemManagerProxy:GetItemSettingType()
    return clone(self.ItemType)
end

function ItemManagerProxy:SetItemBelong(MakeIndex, from)
    self.itemDataFrom[MakeIndex] = from
end

function ItemManagerProxy:GetItemBelong(MakeIndex)
    return self.itemDataFrom[MakeIndex]
end

function ItemManagerProxy:CleanItemBelongs()
    self.itemDataFrom = {}
end

function ItemManagerProxy:GetItemTypeByStdMode(stdMode)
    local equipMap = GUIDefine.EquipMapByStdMode
    local stdMode = stdMode or 0
    local type = self.ItemType.Other
    if stdMode >= 0 and stdMode <= 3 then
        type = self.ItemType.DruaAndSomething
    elseif stdMode == 4 then
        type = self.ItemType.SkillBook
    elseif equipMap[stdMode] or stdMode == 25 then --特殊 护身符
        type = self.ItemType.Equip
    elseif stdMode == 31 then -- 困 束
        type = self.ItemType.Bundle
    elseif stdMode == 200 then -- 盒子
        type = self.ItemType.Box
    elseif stdMode == 101 then
        type = self.ItemType.TreasureMap
    elseif stdMode == 102 then
        type = self.ItemType.FashionItem
    elseif stdMode == 103 then
        type = self.ItemType.MonsterCard
    elseif stdMode == 49 then
        type = self.ItemType.SomethingCanUse
    elseif stdMode == 40 then
        type = self.ItemType.BoxKey
    elseif stdMode == 47 then --准星道具
        type = self.ItemType.Collimator
    elseif stdMode == 201 then --新宠物系统
        type = self.ItemType.NewPet
    end
    return type
end

-- 是否药品
function ItemManagerProxy:IsDurg(item)
    local stdMode = item.StdMode
    local shape = item.Shape
    if stdMode == 0 and (shape == 0 or shape == 1 or shape == 4) then
        return true
    elseif stdMode == 3 and shape == 12 then
        return true
    elseif stdMode == 2 and shape == 9 then
        return true
    end

    return false
end

function ItemManagerProxy:IsBestRings(item)
    return item.StdMode > 99 and item.StdMode < 112
end

function ItemManagerProxy:IsCityStoneByIndex(Index)
    for k, v in ipairs(SL:GetValue("GAME_DATA", "cityStone")) do
        if v == Index then
            return true
        end
    end
    return false
end

function ItemManagerProxy:IsRandStoneByIndex(Index)
    for k, v in ipairs(SL:GetValue("GAME_DATA", "randStone")) do
        if v == Index then
            return true
        end
    end
    return false
end

function ItemManagerProxy:IsCustomCityOrRandItemByIndex(index)
    if not index then
        return false
    end

    return self._customItemMap[index]
end

function ItemManagerProxy:IsCityStone(item)
    if item and next(item) then
        for k, v in ipairs(SL:GetValue("GAME_DATA", "cityStone")) do
            if v == item.Index then
                return true
            end
        end
    end
    return false
end

function ItemManagerProxy:IsRandStone(item)
    if item and next(item) then
        for k, v in ipairs(SL:GetValue("GAME_DATA", "randStone")) do
            if v == item.Index then
                return true
            end
        end
    end
    return false
end

--是否是时装道具
local fashionStdMode = {[66] = true, [67] = true, [68] = true, [69] = true}
function ItemManagerProxy:IsFashionEquip(item)
    if item and item.StdMode then
        if fashionStdMode[item.StdMode] then
            return true
        end
    end
    return false
end

function ItemManagerProxy:GetItemType(item)
    if not item or not next(item) then
        return self.ItemType.Other
    end
    local type = self:GetItemTypeByStdMode(item.StdMode)
    return type
end

function ItemManagerProxy:RemoveItems(itemList, tag)
    if not itemList or not next(itemList) then
        return
    end
    for _, MakeIndex in pairs(itemList) do
        local itemBelong = self:GetItemBelong(MakeIndex)

        if itemBelong == global.MMO.ITEM_FROM_BELONG_BAG then
            local itemData = BagData.GetItemDataByMakeIndex(MakeIndex)
            if itemData then
                BagData.DelItemData(itemData, true)
            end
        elseif itemBelong == global.MMO.ITEM_FROM_BELONG_EQUIP then
            local itemData = EquipData.GetEquipDataByMakeIndex(MakeIndex)
            if itemData then
                EquipData.DelEquipData(itemData, tag == 1)
            end
        elseif itemBelong == global.MMO.ITEM_FROM_BELONG_QUICKUSE then
            local pos = QuickUseData.GetQuickUsePosByMakeIndex(MakeIndex)
            local itemData = QuickUseData.GetQuickUseDataByMakeIndex(MakeIndex)
            if pos and itemData then
                BagData.ShowGetOrCostItems(-(itemData.OverLap or 1), itemData.Name)
                QuickUseData.SetQuickUsePosData(pos, itemData, true)
            end
        elseif itemBelong == global.MMO.ITEM_FROM_BELONG_HEROBAG then
            local itemData = HeroBagData.GetItemDataByMakeIndex(MakeIndex)
            if itemData then
                HeroBagData.DelItemData(itemData, true)
            end
        elseif itemBelong == global.MMO.ITEM_FROM_BELONG_HEROEQUIP then
            local itemData = HeroEquipData.GetEquipDataByMakeIndex(MakeIndex)
            if itemData then
                HeroEquipData.DelEquipData(itemData, tag == 1)
            end
        end
    end
end

function ItemManagerProxy:GetItemDataByMakeIndex(MakeIndex)
    local itemData = nil
    if MakeIndex then
        local itemBelong = self:GetItemBelong(MakeIndex)
        if itemBelong then
            if itemBelong == global.MMO.ITEM_FROM_BELONG_BAG then
                itemData = BagData.GetItemDataByMakeIndex(MakeIndex)
            elseif itemBelong == global.MMO.ITEM_FROM_BELONG_EQUIP then
                itemData = EquipData.GetEquipDataByMakeIndex(MakeIndex)
            elseif itemBelong == global.MMO.ITEM_FROM_BELONG_QUICKUSE then
                itemData = QuickUseData.GetQuickUseDataByMakeIndex(MakeIndex)
            elseif itemBelong == global.MMO.ITEM_FROM_BELONG_HEROBAG then
                itemData = HeroBagData.GetItemDataByMakeIndex(MakeIndex)
            elseif itemBelong == global.MMO.ITEM_FROM_BELONG_HEROEQUIP then
                itemData = HeroEquipData.GetEquipDataByMakeIndex(MakeIndex)
            end
        end
    end
    return itemData
end

function ItemManagerProxy:onRegister()
    ItemManagerProxy.super.onRegister(self)
end

return ItemManagerProxy
