local DebugProxy = requireProxy("DebugProxy")
local ItemConfigProxy = class("ItemConfigProxy", DebugProxy)
ItemConfigProxy.NAME = global.ProxyTable.ItemConfigProxy

local tonumber          = tonumber
local sgsub             = string.gsub

function ItemConfigProxy:ctor(...)
    ItemConfigProxy.super.ctor(self,...)
    self._config = {}
    self._nameConfig = {}
    self._gmConfig = {}
    self._itemChangeLook = {}
    self._itemChangeEffect = {}
    self._itemChangeSEffect = {}
    self._attPowerConfig = {}
end

--[[    道具属性字段 部分字段不在道具表中有配 为前端自己添加进数据 AddItemConfig(item) 补全
    !!!!! 服务器新增字段 要在AddItemConfig(item) 方法中加上
    AniCount = 0,
    batch = 0, 是否可以批量使用 1 可以
    Color = 255,
    Desc = "" 描述
    Dura = 0 当前持久
    DuraMax = 1 最大持久
    Index = 11 道具表配置
    Job = 0 装备职业 0 1 2 战 法 道 3通用
    Looks = 11 内观ID
    MakeIndex = 11 服务器生成 唯一ID
    Name = "赤血魔剑" 道具名字
    Need = "0" 使用条件
    Price = 11 出售价格
    Reserved = 12
    Shape = 30
    Source = 0
    StdMode = 5 大类
    Values = { --极品属性 包括强化  强化属性对应的属性ID可用 GetExAttMap() 获得 16 17 18特殊 16为强化成功星星数 17为失败 18 炼魂等级 19 精炼等级
        1 = {
            Id = 5,
            Value 1
        }
    }
    Weight = 22 重量
    Where = -1 穿戴位置 当前在装备栏中位置 不在装备栏 -1
    Attribute = "3#3#15|3#4#310" -- 装备属性
    honour = ""
    huishou = "" 回收相关
    nBindIdx = 0 绑定相关 不为0 即为绑定 为自己则单纯绑定 为其他 则消耗本身 不足时用对应道具做替代 默认1：1
    nMaxStar = 0 可强化上限
    nMaxLianHun = 0 可炼魂上限
    nQuality = 0 品质
    sEffect = "0" 内观特效     11#0 #前为特效ID #后为层级 0为在上层 1在下层
    OverLap = 0   叠加 大于一 则为叠加
    Level = 0 等级
    AutoUse = 0 自动使用
    refine = 1 是否可以精炼
    refineatt = 当前精炼属性
    pickCondition = "$(LEVEL) > 100|1" -- 自动拾取条件|小精灵不自动拾取开关(1) 新增2:  满足条件-小精灵拾取、不满足也拾取
    QiugouGoldList = "1#200|2#100"   货币类型1#最小200|货币类型2#最小100  --求购物品限制的货币类型和最小值
    QiugouMaxCnt   = 100    --  限制的求购数量最大值

    内观偏移 equipOffest.lua
    内观相关头发 hairOffest.lua
    道具部分前端设定 ItemsConfig.lua
]]
function ItemConfigProxy:LoadConfig()
    local config = {}
    local noToClientCfg = "#" .. (SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_NO_TO_CLIENT_CFG) or "") .. "#"
    local filePath      = "data_config/Output/cfg_item.txt"
    if string.find(noToClientCfg, "#cfg_item#") then
        if global.FileUtilCtl:isFileExist(filePath) then
            local stdItemStr    = global.FileUtilCtl:getDataFromFileEx(filePath)
            local cjson         = require("cjson")
            local stdItemConfig = cjson.decode(stdItemStr)
            config              = stdItemConfig.Value
        end
    else
        local itemConfig = SL:Require("game_config/cfg_item", true)
        for k,v in pairs(itemConfig) do
            config[v.Index] = v
        end
    end
    local equipConfig = SL:Require("game_config/cfg_equip", true)
    for k,v in pairs(equipConfig) do
        if not config[v.Index] then
            config[v.Index] = v
        end
    end

    local GameConfigMgrProxy = global.Facade:retrieveProxy(global.ProxyTable.GameConfigMgrProxy)
    local attrServerConfig = GameConfigMgrProxy:getServerConfingByKey("cfg_stditem") or {}

    local updateItemConfig = GameConfigMgrProxy:GetUpdateItemConfig()
    for k, v in ipairs(updateItemConfig) do
        if v.Index then
            config[v.Index] = v
            if attrServerConfig[tostring(v.Index)] and v.Attribute then
                attrServerConfig[tostring(v.Index)] = v.Attribute
            end
        end
    end

    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    -- local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    AuctionProxy:ClearCurrencies()
    StallProxy:ClearCurrencies()
    PurchaseProxy:clearData()
    -- ExchangeProxy:clearData()
    ExchangeData.clearData()


    self._nameConfig = {}

    local newList = {}
    local drugAndSome = {}
    local cityStone     = {}
    local randStone     = {}
    local drugHY        = {}
    local drugLY        = {}
    local drugSHY       = {}
    local allDrugPack   = {}
    local fixItemDrug   = {}
    local Currency      = {}
    local itemList      = {}
    local exchangelist      = {}


    if config then

        -- 装备道具表的一些key默认值
        local keyValue = {
            ["Index"]               = 0,
            ["Name"]                = "",
            ["StdMode"]             = 0,
            ["Shape"]               = 0,
        }

        local function keyDefaultValue(config)
            for k, v in pairs(keyValue) do
                if not config[k] then
                    config[k] = v
                end
            end
        end

        -- 道具装备表的一些分割key和value
        local splitKeyValue = {
            ["Reserved"]    = {"Reserved", "AutoEat"},
            ["NeedLevel"]   = {"NeedLevel", "NeedLevelParam"},
            ["Comparison"]  = {"comparison", "comparisonJob"}
        }

        local function splitKeys(config)

            for k, v in pairs(splitKeyValue) do
                if k == "Comparison" then
                    local comparison = tonumber(config[k]) or 0
                    local job = 3
                    if type(config[k]) == "string" then
                        local splitArray = G_GetSplitArray(config[k], "#")
                        job = tonumber(splitArray[1]) or 3
                        comparison = tonumber(splitArray[2]) or 0
                    end
                    config[v[1]] = comparison
                    config[v[2]] = job
                else
                    if type(config[k]) == "string" then
                        local splitArray = G_GetSplitArray(config[k], "#")
                        config[v[1]] = tonumber(splitArray[1])
                        config[v[2]] = tonumber(splitArray[2]) or 0
                    end
                end
            end
            
        end

        for k,v in pairs(config) do

            keyDefaultValue(v)
            splitKeys(v)
            
            self._nameConfig[v.Name] = v
            newList[v.Index] = v
            newList[v.Index].Dura = v.DuraMax or 0
            newList[v.Index].DuraMax = v.DuraMax or 0
            newList[v.Index].AniCount = v.AniCount or v.Anicount
            -- 服务端数据 替换属性
            if attrServerConfig[tostring(v.Index)] then
                newList[v.Index].Attribute = attrServerConfig[tostring(v.Index)]
            end
            
            if v.Index < 100 then --货币
                table.insert(Currency, v.Index)
            end

            if v.AutoEat ~= 1 then
                if (v.StdMode == 3 and v.Shape == 3) or (v.StdMode == 2 and v.Shape == 1 and v.Source == 1) or (v.StdMode == 2 and v.Shape == 3)  then
                    -- 回城石
                    table.insert(cityStone, v.Index)
                elseif (v.StdMode == 3 and (v.Shape == 2 or v.Shape == 1)) or (v.StdMode == 2 and v.Shape == 2) then
                    -- 随机石
                    table.insert(randStone, v.Index)
                end
            end
            
            if v.AutoEat ~= 1 then
                -- 红蓝瞬回药
                if v.StdMode == 0 and v.Shape == 0 and v.effectParam and string.find(v.effectParam, "%d+#0$") then
                    -- 红药
                    table.insert(drugHY, v.Index)
                elseif v.StdMode == 0 and v.Shape == 0 and v.effectParam and string.find(v.effectParam, "^0#%d+") then
                    -- 蓝药
                    table.insert(drugLY, v.Index)
                elseif v.StdMode == 0 and v.Shape == 4 and v.effectParam and string.find(v.effectParam, "[1-9]%d*") then
                    -- 瞬回药  内功药
                    table.insert(drugSHY, v.Index)
                elseif v.StdMode == 0 and v.Shape == 1 and v.effectParam and string.find(v.effectParam, "[1-9]%d*#[1-9]%d*") then
                    -- 瞬回药
                    table.insert(drugSHY, v.Index)
                end
            end

            -- 药品包
            if v.StdMode == 31 and v.AutoEat ~= 1 then
                table.insert(allDrugPack, v)
            end
            -- 修复神水
            if v.StdMode == 2 and v.Shape == 9 and v.AutoEat ~= 1 then
                table.insert(fixItemDrug, v.Index)
            end

            -- 拍卖货币
            if v.StdMode == 41 and (v.Shape == 99 or v.Shape == 97) then
                AuctionProxy:AddCurrency(v)
            end

            --摆摊货币 
            if v.StdMode == 41 and (v.Shape == 99 or v.Shape == 98) then
                StallProxy:AddCurrency(v)
            end

            if v.StdMode >=0 and v.StdMode <=3 then
                drugAndSome[v.Index] = newList[v.Index]
            end

            --祝福罐持久
            if v.StdMode == 96 then
                newList[v.Index].Dura = 0
            end
            --聚灵珠持久
            if v.StdMode == 49 then
                newList[v.Index].Dura = 0
                newList[v.Index].DuraMax = v.DuraMax * 10000
            end

            local typeItems = PurchaseProxy:GetFirstFilterItem()
            local function checkStdModeFit(id, itemStdMode)
                local stdmodeList = PurchaseProxy:GetStdModeByID(id)
                for _, v in ipairs(stdmodeList) do
                    if v == itemStdMode then
                        return true
                    end
                end
                return false
            end
            -- 物品禁止求购 -1
            local function checkItemPurchase(itemData)
                local isForbid = itemData.QiugouMaxCnt == -1
                return isForbid
            end
            
            for firstLevel, secondItems in pairs(typeItems) do
                for _, item in ipairs(secondItems) do
                    if #secondItems == 1 and not item.secondlevel then
                        item.secondlevel = 1
                        item.secondlevelname = "全部"
                    end
                    if firstLevel and item.secondlevel and string.find(item.stdmode or "", tostring(v.StdMode)) and checkStdModeFit(item.id, v.StdMode) then
                        local key = string.format("%s_%s", firstLevel, item.secondlevel)
                        if not itemList[key] then
                            itemList[key] = {}
                        end
                        if not checkItemPurchase(v) then
                            table.insert(itemList[key], v.Index)
                        end
                    end
                end
            end

            local exchangeItems = ExchangeData.GetFirstFilterItem()
            local function checkExchangeStdModeFit(id, itemStdMode)
                local stdmodeList = ExchangeData.GetStdModeByID(id)
                for _, v in ipairs(stdmodeList) do
                    if v == itemStdMode then
                        return true
                    end
                end
                return false
            end
            
            for firstLevel, secondItems in pairs(exchangeItems) do
                for _, item in ipairs(secondItems) do
                    if #secondItems == 1 and not item.secondlevel then
                        item.secondlevel = 1
                        item.secondlevelname = "全部"
                    end
                    if firstLevel and item.secondlevel and string.find(item.stdmode or "", tostring(v.StdMode)) and checkExchangeStdModeFit(item.id, v.StdMode) then
                        local key = string.format("%s_%s", firstLevel, item.secondlevel)
                        if not exchangelist[key] then
                            exchangelist[key] = {}
                        end
                        table.insert(exchangelist[key], v.Index)
                    end
                end
            end

        end
    end
    PurchaseProxy:SetTypeItemList(itemList)
    ExchangeData.SetTypeItemList(exchangelist)

    -- 优先级排序
    local function sortCB(a, b)
        local ac = newList[a]
        local bc = newList[b]
        if not ac or not bc then
            return false
        end
        if not ac.Reserved or not bc.Reserved then
            return false
        end
        local ar = tonumber(ac.Reserved) or 0
        local br = tonumber(bc.Reserved) or 0
        return ar < br
    end
    table.sort(cityStone, sortCB)
    table.sort(randStone, sortCB)
    table.sort(drugHY, sortCB)
    table.sort(drugLY, sortCB)
    table.sort(drugSHY, sortCB)

    SL:SetValue("GAME_DATA","cityStone",cityStone)
    SL:SetValue("GAME_DATA","randStone",randStone)
    SL:SetValue("GAME_DATA","drugHY",drugHY)
    SL:SetValue("GAME_DATA","drugLY",drugLY)
    SL:SetValue("GAME_DATA","drugSHY",drugSHY)
    SL:SetValue("GAME_DATA","allDrugPack",allDrugPack)
    SL:SetValue("GAME_DATA","fixItemDrug",fixItemDrug)
    SL:SetValue("GAME_DATA","Currency",Currency)

    self._config = newList
    self._gmConfig = clone(newList)

    self._attPowerConfig = {}
    local filePath = "scripts/game_config/cfg_PlayerPower.lua"
    if SL:IsFileExist(filePath) then
        SL:Print("[Require game_config] ", "cfg_PlayerPower")
        local config = SL:RequireFile(filePath) or {}
        for i, v in pairs(config) do
            if v.type and tonumber(v.type) then
                self._attPowerConfig[tonumber(v.type)] = v
            end
        end
    end

    local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
    ItemManagerProxy:InitCustomItemConfig()
end

function ItemConfigProxy:GetAttPowerConfig()
    return self._attPowerConfig
end

function ItemConfigProxy:GetItemGMConfigData()
    return self._gmConfig
end

function ItemConfigProxy:GetItemConfigData()
    return self._config
end

function ItemConfigProxy:GetItemDataByIndex(Index)
    Index = tonumber(Index)
    return self._config[Index] or {}
end

function ItemConfigProxy:GetItemName(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return nil
    end
    return itemData.Name
end

function ItemConfigProxy:GetItemNameColor(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData or not itemData.Color then
        return "#FFFFFF"
    end
    return GET_COLOR_BYID(self._config[Index].Color)
end

function ItemConfigProxy:GetItemNameColorId(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData or not itemData.Color then
        return 1006
    end
    return itemData.Color
end

function ItemConfigProxy:GetItemGuangZhu(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return nil
    end

    local splitArray = G_GetSplitArray(itemData.guangzhu or "", "#")
    return splitArray[1], tonumber(splitArray[2])~=1
end

function ItemConfigProxy:GetItemLooks(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return -1
    end
    return itemData.Looks or -1
end

--获取优先级
function ItemConfigProxy:GetItemComparison(Index)
    -- body
    local comparison = 0
    local job = -1
    if self._config[Index] then
        comparison = self._config[Index].comparison
        job = self._config[Index].comparisonJob
    end
    return comparison, job
end

function ItemConfigProxy:CheckItemBind(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return false, nil
    end

    local bindIndex = itemData.nBindIdx
    local bind = false
    if bindIndex == itemData.Index then -- 等于自己单纯绑定
        bind = true
    elseif bindIndex ~= 0 then   -- 绑定 并且等价 即本身消耗不够时可以用绑定道具代替
        bind = true
    end

    return bind, bindIndex
end

function ItemConfigProxy:GetSameReservedByMoneyIndex(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return {}
    end

    local itemData2 = nil
    local moneys = {}
    local Currencys = SL:GetValue("GAME_DATA","Currency") or {}
    if tonumber(itemData.Reserved) ~= 0 then
        for i, v in ipairs(Currencys) do
            itemData2 = self:GetItemDataByIndex(v)
            if itemData2.Reserved == itemData.Reserved and itemData2.Index ~= Index then
                table.insert(moneys, v)
            end
        end
    end
    return moneys
end

function ItemConfigProxy:GetItemQuality(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return 0
    end
    return itemData.nQuality or 0
end

function ItemConfigProxy:GetItemNameByIndex(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return "ERROR ITEM INDEX" .. Index
    end
    return itemData.Name or ""
end

function ItemConfigProxy:GetItemIndexByName(name)
    return self._nameConfig[name] and self._nameConfig[name].Index
end

function ItemConfigProxy:GetItemReservedByIndex(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return 0
    end
    return itemData.Reserved or 0
end

function ItemConfigProxy:CheckItemTreasureBox(item)
    -- body
    if not item or not next(item) then
        return false
    end
    return item.StdMode == 31 and item.Shape >= 1 and item.Shape <= 99 and item.Reserved == 1
end

function ItemConfigProxy:CheckItemTreasureBoxKey(item)
    -- body
    if not item or not next(item) then
        return false
    end
    return item.StdMode == 40 and item.Shape >= 1 and item.Shape <= 99
end

function ItemConfigProxy:CheckItemOverLapById(Index)
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData or not itemData.OverLap then
        return false
    end
    return itemData.OverLap and itemData.OverLap > 1
end

function ItemConfigProxy:CheckItemOverLap(item)
    if not item or not item.OverLap or not next(item) then
        return false
    end
    return item.OverLap and item.OverLap > 1
end

function ItemConfigProxy:CheckItemBatch(item)
    if not item or not next(item) then
        return false
    end
    return item.batch and item.batch > 0
end

function ItemConfigProxy:CheckItemAutoUse(item)
    if not item or not next(item) then
        return false
    end
    return item.AutoUse and item.AutoUse <= 0
end

--获取规则类型表
function ItemConfigProxy:GetArticleType()
    return GUIDefine.ItemArticleType
end

-- 获取item规则   Index: 道具Index    itemArticleType: 规则类型
function ItemConfigProxy:GetItemArticle(Index, itemArticleType)
    if not Index or not itemArticleType then
        return false
    end
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return false
    end

    if not itemData.Article or not tonumber(itemData.Article) then
        return false
    end

    local _, isMeetType = CheckItemisBind(itemData, itemArticleType)
    return isMeetType
end

--获取item改变的look, effect
function ItemConfigProxy:GetChangeItemLook(MakeIndex, Index)
    if not MakeIndex then
        return nil, nil, nil
    end
    local itemData = self:GetItemDataByIndex(Index)
    if not itemData then
        return nil, nil, nil
    end

    local newLook = self._itemChangeLook[MakeIndex]
    local newEffect = self._itemChangeEffect[MakeIndex]
    local newSEffect = self._itemChangeSEffect[MakeIndex]
    newLook = newLook and newLook > 0 and newLook or itemData.Looks
    newEffect = newEffect and newEffect > 0 and newEffect or itemData.bEffect
    newSEffect = newSEffect and newSEffect > 0 and newSEffect or itemData.sEffect
    return newLook, newEffect, newSEffect
end

--设置item改变的look  MakeIndex: 唯一id    newLook: 道具图片    newEffect: 背包特效    newSEffect:  内观特效  tag: 0 人物 1 英雄
function ItemConfigProxy:SetChangeItemLook(MakeIndex, newLook, newEffect, newSEffect, tag)
    self._itemChangeLook[MakeIndex] = newLook
    self._itemChangeEffect[MakeIndex] = newEffect
    self._itemChangeSEffect[MakeIndex] = newSEffect
    local bagDataDispose = tag == 1 and HeroBagData or BagData
    local equipDataDispose = tag == 1 and HeroEquipData or EquipData
    local data = bagDataDispose.GetItemDataByMakeIndex(MakeIndex)
    if data and data.Index then
        data.Looks, data.bEffect, data.sEffect = self:GetChangeItemLook(MakeIndex, data.Index)
    else
        local item = equipDataDispose.GetEquipDataByMakeIndex(MakeIndex)
        if not item then
            return
        end
        item.Looks, item.bEffect, item.sEffect = self:GetChangeItemLook(item.MakeIndex, item.Index)
        equipDataDispose.ChangeEquipData(item, nil, true)
    end
end

--更换item look
function ItemConfigProxy:handle_MSG_SM_SETITEMLOOKS(msg)
    local msgHdr = msg:GetHeader()
    local MakeIndex = msg:GetBodyStr()
    self:SetChangeItemLook(MakeIndex, msgHdr.param2, msgHdr.param3, msgHdr.recog, msgHdr.param1)
end

function ItemConfigProxy:onRegister()
    ItemConfigProxy.super.onRegister(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_SETITEMLOOKS, handler(self, self.handle_MSG_SM_SETITEMLOOKS))
end

return ItemConfigProxy