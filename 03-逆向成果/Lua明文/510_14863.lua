local RemoteProxy  = requireProxy("RemoteProxy")
local ItemUseProxy = class("ItemUseProxy", RemoteProxy)
ItemUseProxy.NAME  = global.ProxyTable.ItemUseProxy

function ItemUseProxy:ctor()
    self.itemCD = {}
    self.itemCD_Hero = {}
    ItemUseProxy.super.ctor(self)
end

function ItemUseProxy:GetUseMsgID(isDrug)
    if isDrug then
       return global.MsgType.MSG_CS_EAT_BAG_DRUG
    end

    return global.MsgType.MSG_CS_USE_BAG_ITEM
end

function ItemUseProxy:UseItem(item, autoUse)
    if not item or next(item) == nil then
        return
    end
    if SL:GetValue("STALL_MY_TRADING_STATUS") then
        SL:ShowSystemTips("摆摊中，禁止操作")
        return
    end
    
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    if item.from ~= GUIDefine.ItemFrom.BAG then
        if BagData.GetBagCollimator() then --判断背包准星操作
            return
        end
    end

    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local canUse, strList, notCheckUse = CheckItemUseNeed(item)
    if not canUse and not notCheckUse then
        for i,v in ipairs(strList) do
            if not v.can and not notCheckUse then
                local color = GUIFunction:ItemUseConditionColor(v.can)
                local conditionStr = string.format(GET_STRING(80049997), color, v.str)
                global.Facade:sendNotification(global.NoticeTable.SystemTips, conditionStr)
                break
            end
        end
        return
    end

    local isUseCd = self:CheckIsCD(item.Index)
    if isUseCd then
        return
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local ret,buffid = BuffProxy:CheckUseItemEnable(item.Index)
    if not ret then
        if buffid then
            local config = BuffProxy:GetConfigByID(buffid) or {}
            if config.bufftitle then
                ShowSystemTips(config.bufftitle)
            end
        end
        return
    end

    local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
    local Item_Type = ItemManagerProxy:GetItemSettingType()
    local itemType = ItemManagerProxy:GetItemType(item)
    
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local isDrug = ItemManagerProxy:IsDurg(item)
    if (item.StdMode == 2 or item.StdMode == 3) and not isDrug then
        local itemUseCd = MapProxy:GetEatItemSpeed() or 500
        self:IntoCD(item.Index, itemUseCd)
    end

    if isDrug then
        local itemUseCd = MapProxy:GetEatDuraSpeed() or 500
        self:IntoCD(item.Index, itemUseCd)
    end

    if item.StdMode == 96 then
        itemType = Item_Type.WishBox
    end
    if itemType == Item_Type.DruaAndSomething
        or itemType == Item_Type.Bundle
        or itemType == Item_Type.Box
        or itemType == Item_Type.TreasureMap
        or itemType == Item_Type.FashionItem
        or itemType == Item_Type.MonsterCard
        or itemType == Item_Type.SomethingCanUse
        or itemType == Item_Type.WishBox 
        or itemType == Item_Type.Collimator 
        or itemType == Item_Type.NewPet then
        self:handleItem(item)

        local Name      = item.Name or ""
        local MakeIndex = item.MakeIndex
        if item.StdMode == 200 and item.Shape == 0 and (ItemConfigProxy:CheckItemOverLap(item) or ItemConfigProxy:CheckItemBatch(item)) then
            if item.StdMode == 200 and item.Shape == 0 then
                autoUse = true
            end
            if autoUse then -- 自动使用 用全部
                local autoUseNumber = item.OverLap > 1 and item.OverLap or 1
                LuaSendHeader13(self:GetUseMsgID(isDrug), MakeIndex, autoUseNumber, 0, 0, 0, Name)
            else
                -- 叠加道具批量使用
                local function callback(btnType, data)
                    if data.editStr and data.editStr ~= "" then
                        if type(data.editStr) == "string" then
                            local num  = tonumber(data.editStr)
                            if not num or num > item.OverLap or num <= 0 then
                                global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(90020007))
                                return
                            end
                            LuaSendHeader13(self:GetUseMsgID(isDrug), MakeIndex, num, 0, 0, 0, Name)
                        end
                    end
                end
                local data = {}
                data.str = GET_STRING(90020006)
                data.callback = callback
                data.btnType = 2
                data.showEdit = true
                data.editParams = {
                    inputMode = 2,
                    str = item.OverLap
                }
                UIOperator:OpenCommonTipsUI(data)
            end
        else
            if itemType == Item_Type.Bundle and ItemConfigProxy:CheckItemTreasureBox(item) then
                if GoldBox and not GoldBox.CheckGoldBoxCanUse() then
                    ShowSystemTips("该系统正在使用中..")
                    return
                end
                local data = {
                    storage = {
                        MakeIndex = MakeIndex,
                        state = 0
                    }
                }
                SL:onLUAEvent(LUA_EVENT_BAG_STATE_CHANGE, data)
                UIOperator:OpenTreasure(item)
                return
            end
            
            LuaSendHeader13(self:GetUseMsgID(isDrug), MakeIndex, 1, 0, 0, 0, Name)
        end
    elseif itemType == Item_Type.SkillBook then
        local function callback(atype,aData)
            if atype == 1 then
                local Name       = item.Name
                local MakeIndex = item.MakeIndex
                LuaSendHeader13(global.MsgType.MSG_CS_USE_BAG_ITEM, MakeIndex, 0, 0, 0, 0, Name)
            end
        end
        local data = {}
        data.str = string.format(GET_STRING(90020001), item.Name)
        data.callback = callback
        data.btnType = 2
        UIOperator:OpenCommonTipsUI(data)
    elseif itemType == Item_Type.Equip then
        local Name      = item.Name
        local MakeIndex = item.MakeIndex

        local targetPos = nil
        -- 是否有找到合适的位置 战力对比
        local comparison = ItemConfigProxy:GetItemComparison(item.Index) 
        local myPower, powerSortIndex = GUIFunction:GetEquipPower(item, {jobPower = true})
        local param = {jobPower = true, power = myPower, comparison = comparison, powerSortIndex = powerSortIndex}
        local excludePos = GUIFunction:CheckEquipExcludePos(item)
        local minPowerPos, onEquipMinPower, hasEquip = GUIFunction:GetMinPowerPosByStdMode(item.StdMode, param, nil, false, excludePos)
        if minPowerPos >= 0 and (not hasEquip or onEquipMinPower < myPower) then
            targetPos = minPowerPos
        end

        UIOperator:CloseAutoUsePopUI(MakeIndex)

        local canUseBuJuk, pos = GUIFunction:CheckBujukUse(item)
        if pos then
            targetPos = pos
        else
            if not canUseBuJuk then 
                return false
            end
        end

        global.Facade:sendNotification(global.NoticeTable.TakeOnRequest, {itemData = item, pos = targetPos, specailOpt = not autoUse})
    end

    global.Facade:sendNotification(global.NoticeTable.Audio_Play, {type = global.MMO.SND_TYPE_USE_ITEM, param = item})
end

function ItemUseProxy:HeroUseItem(item, autoUse)
    if not item or next(item) == nil then
        return
    end

    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local canUse, strList, notCheckUse = CheckItemUseNeed_Hero(item)
    if not canUse and not notCheckUse then
        for i,v in ipairs(strList) do
            if not v.can and not notCheckUse then
                local color = GUIFunction:ItemUseConditionColor(v.can)
                local conditionStr = string.format(GET_STRING(80049997), color, v.str)
                global.Facade:sendNotification(global.NoticeTable.SystemTips, conditionStr)
                break
            end
        end
        return
    end

    local isUseCd = self:CheckIsCD_Hero(item.Index)
    if isUseCd then
        return
    end

    if item.StdMode == 2 or item.StdMode == 3 then
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        local itemUseCd = MapProxy:GetEatItemSpeed() or 500
        self:IntoCD_Hero(item.Index, itemUseCd)
    end

    local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
    local Item_Type = ItemManagerProxy:GetItemSettingType()
    local itemType = ItemManagerProxy:GetItemType(item)

    if item.StdMode == 96 then
        itemType = Item_Type.WishBox
    end
    if itemType == Item_Type.DruaAndSomething
        or itemType == Item_Type.Bundle
        or itemType == Item_Type.Box
        or itemType == Item_Type.TreasureMap
        or itemType == Item_Type.FashionItem
        or itemType == Item_Type.MonsterCard
        or itemType == Item_Type.SomethingCanUse
        or itemType == Item_Type.WishBox 
        or itemType == Item_Type.Collimator then
        -- self:handleItem(item)

        local Name       = item.Name
        local MakeIndex = item.MakeIndex
        if item.StdMode == 200 and item.Shape == 0 and (ItemConfigProxy:CheckItemOverLap(item) or ItemConfigProxy:CheckItemBatch(item)) then
            if item.StdMode == 200 and item.Shape == 0 then
                autoUse = true
            end
            if autoUse then -- 自动使用 用全部
                local autoUseNumber = item.OverLap > 1 and item.OverLap or 1
                LuaSendHeader13(global.MsgType.MSG_CS_USE_BAG_ITEM_HERO, MakeIndex, autoUseNumber)
            else
                -- 叠加道具批量使用
                local function callback(btnType, data)
                    if data.editStr and data.editStr ~= "" then
                        if type(data.editStr) == "string" then
                            local num  = tonumber(data.editStr)
                            if not num or num > item.OverLap or num <= 0 then
                                global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(90020007))
                                return
                            end
                            LuaSendHeader13(global.MsgType.MSG_CS_USE_BAG_ITEM_HERO, MakeIndex, num)
                        end
                    end
                end
                local data = {}
                data.str = GET_STRING(90020006)
                data.callback = callback
                data.btnType = 2
                data.showEdit = true
                data.editParams = {
                    inputMode = 2,
                    str = item.OverLap
                }
                UIOperator:OpenCommonTipsUI(data)
            end
        else
            if itemType == Item_Type.Bundle and ItemConfigProxy:CheckItemTreasureBox(item) then
                local data = {
                    storage = {
                        MakeIndex = MakeIndex,
                        state = 0
                    }
                }
                SL:onLUAEvent(LUA_EVENT_HERO_BAG_STATE_CHANGE, data)
                UIOperator:OpenTreasure(item)
                return
            end
            
            LuaSendHeader13(global.MsgType.MSG_CS_USE_BAG_ITEM_HERO, MakeIndex, 1)
        end
    elseif itemType == Item_Type.SkillBook then
        local function callback(atype,aData)
            if atype == 1 then
                local Name       = item.Name
                local MakeIndex = item.MakeIndex
                LuaSendHeader13(global.MsgType.MSG_CS_USE_BAG_ITEM_HERO, MakeIndex, 0)
            end
        end
        local data = {}
        data.str = string.format(GET_STRING(90020001), item.Name)
        data.callback = callback
        data.btnType = 2
        UIOperator:OpenCommonTipsUI(data)
    elseif itemType == Item_Type.Equip then
        local Name       = item.Name
        local MakeIndex = item.MakeIndex

        local targetPos = nil
        -- 是否有找到合适的位置 战力对比
        local comparison = ItemConfigProxy:GetItemComparison(item.Index) 
        local myPower,powerSortIndex = GUIFunction:GetEquipPower(item, {jobPower = true}, true)
        local param = {jobPower = true, power = myPower, comparison = comparison, powerSortIndex = powerSortIndex}
        local excludePos = GUIFunction:CheckEquipExcludePos(item)
        local minPowerPos, onEquipMinPower, hasEquip = GUIFunction:GetMinPowerPosByStdMode(item.StdMode, param, nil, true, excludePos)

        if minPowerPos >= 0 and (not hasEquip or onEquipMinPower < myPower) then
            targetPos = minPowerPos
        end

        local canUseBuJuk, pos = GUIFunction:CheckBujukUse(item, targetPos)
        if pos then
            targetPos = pos
        else
            if not canUseBuJuk then 
                return false
            end
        end

        global.Facade:sendNotification(global.NoticeTable.HeroTakeOnRequest, {itemData = item, pos = targetPos})
    end

    global.Facade:sendNotification(global.NoticeTable.Audio_Play, {type = global.MMO.SND_TYPE_USE_ITEM, param = item})
end

function ItemUseProxy:handleItem(item)

    ---随机卷轴
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
    if ItemManagerProxy:IsRandStone(item) then
        autoProxy:SetRandStoneAFKFlag(true)
    end
end

function ItemUseProxy:IntoCD(index ,times)
    local cdtimes = times or 500 
    self.itemCD[index] = true
    PerformWithDelayGlobal(function()
        self.itemCD[index] = false
    end, cdtimes/1000)
end

function ItemUseProxy:CheckIsCD(index)
    return self.itemCD[index]
end

function ItemUseProxy:IntoCD_Hero(index ,times)
    local cdtimes = times or 500 
    self.itemCD_Hero[index] = true
    PerformWithDelayGlobal(function()
        self.itemCD_Hero[index] = false
    end, cdtimes/1000)
end

function ItemUseProxy:CheckIsCD_Hero(index)
    return self.itemCD_Hero[index]
end
function ItemUseProxy:onRegister()
    ItemUseProxy.super.onRegister(self)
end

return ItemUseProxy