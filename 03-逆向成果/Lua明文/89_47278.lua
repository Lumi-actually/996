local STR_FROMAT = string.format

local noUsedKeys = {
    "bEffectZ",
    "sEffectZ",
    "newLooks",
    "newBEffect",
    "newSEffect"
}

-- 服务器道具属性变更，在这里变更服务器属性为前端需要的属性
function ChangeItemServersSendDatas(item)
    
    if not item or not next(item) then
        print("=======================================")
        print("item data error")
        print("=======================================")
    end
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local itemconfigO = ItemConfigProxy:GetItemDataByIndex(item.Index)
    if not itemconfigO or next(itemconfigO) == nil then
        print("=======================================")
        print("no this item: my index is " .. item.Index)
        print("=======================================")
    end

    --服务端的判断 因为改成结构体 放客户端判断。。。---------------------------------------------------------
        -- local AddValues = {}
        -- for i,v in pairs(item.AddValues) do
        --     if v ~= 0 then 
        --         table.insert(AddValues, {Id = i ,Value = v})
        --     end
        -- end
        -- item.AddValues = AddValues

        -- local values = {}
        -- for i,v in pairs(item.values) do
        --     if v ~= 0 then 
        --         table.insert(values, {Id = i ,Value = v})
        --     end
        -- end
        -- item.values = values
        -- local find = false
        -- if item.ExtendInfo.Sockets then
        --     for i,v in ipairs(item.ExtendInfo.Sockets) do
        --         if v > 0 then 
        --             find = true 
        --             break
        --         end
        --     end
        -- end
        -- if not find then
        --     item.ExtendInfo.Sockets = nil
        -- end

        -- for i = 0,2 do
        --     if item.ExtendInfo["LH" .. i] then
        --         if not (item.ExtendInfo["LH"..i][1] == 1 or item.ExtendInfo["LH"..i][7] ~= 0) then 
        --             item.ExtendInfo["LH"..i]  = nil
        --         end
        --     end
        -- end
        -- if item.ItemSrc and item.ItemSrc[4] == 0 then 
        --     item.ItmSrc = nil
        -- end
    -------------------------------------------------------------------------


    local itemconfig = {}
    setmetatable(itemconfig,{
        __index = function(t,key)
            local Index = t.Index
            if not Index then
                return
            end
            local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
            local config = ItemConfigProxy:GetItemDataByIndex(Index) or {}
            rawset(t, key, config[key])
            return config[key]
        end
    })

    local itemCount = item.nOverLap and item.nOverLap or 1
    itemconfig.Index = item.Index
    itemconfig.MakeIndex = item.MakeIndex or 0
    itemconfig.Dura = item.Dura or item.dura or 0
    itemconfig.DuraMax = item.DuraMax or item.duramax or 0
    itemconfig.Where = item.Where
    itemconfig.OverLap = itemCount > 0 and itemCount or 1
    if item.overLap ~= nil and item.overLap >= 1 then
        itemconfig.OverLap = item.overLap
    end

    itemconfig.Quality  = item.Quality 
    itemconfig.ItemSrc  = item.ItemSrc or item.Src

    -- 自定义属性
    itemconfig.DiyAdv   = item.DiyAdv          
    -- 镶嵌格子
    itemconfig.TNCell   = item.TNCell 
    -- 附加值
    itemconfig.AddValues = item.AddValues or {}

    local newBEffectZ = nil
    local newSEffectZ = nil
    local newLooks, newBEffect, newSEffect = ItemConfigProxy:GetChangeItemLook(itemconfig.MakeIndex)

    -- 沙巴克武器升级攻击
    local shabakeUpAttack = 0
    -- 沙巴克武器升级魔法
    local shabakeUpMagic = 0
    -- 沙巴克武器升级道术
    local shabakeUpDaoshu = 0

    -- 服务端json处理 Cell镶嵌
    if item.Cell and next(item.Cell) then
        itemconfig.TNCell = {}
        for i, data in ipairs(item.Cell) do
            if data and next(data) then
                for key, value in pairs(data) do
                    if tonumber(key) then
                        itemconfig.TNCell[tonumber(key)] = value
                    end
                end
            end
        end
    end

    local serverAddV = next(item.AddVale or {}) and item.AddVale
    if serverAddV then      -- 服务端json处理
        for key, value in pairs(serverAddV) do
            if not noUsedKeys[key] then
                -- 服务端参数大小写问题处理
                if key == "CustomName" then
                    key = "customName"
                end
                itemconfig[key] = value
            end
        end

        if itemconfig.limitTimeActive and itemconfig.limitRemainTime then
            itemconfig.limitEndTime = itemconfig.limitRemainTime + GetServerTime()
        end

        newBEffectZ = serverAddV.newBEffectZ
        newSEffectZ = serverAddV.newSEffectZ

        newLooks = serverAddV.newLooks and serverAddV.newLooks > 0 and serverAddV.newLooks or newLooks
        newBEffect = serverAddV.newBEffect and serverAddV.newBEffect > 0 and serverAddV.newBEffect or newBEffect
        newSEffect = serverAddV.newSEffect and serverAddV.newSEffect > 0 and serverAddV.newSEffect or newSEffect

        shabakeUpAttack = serverAddV.shabakeUpAttack or 0
        shabakeUpMagic = serverAddV.shabakeUpMagic or 0
        shabakeUpDaoshu = serverAddV.shabakeUpDaoshu or 0

    else                    -- 物品结构解析
        -- 限时道具
        local value = next(itemconfig.AddValues) and itemconfig.AddValues[0]
        local beginTime = value and value[1]
        local remainTime = value and value[2]
        itemconfig.limitRemainTime = remainTime and remainTime > 0 and remainTime

        -- 绑定
        itemconfig.Bind = next(itemconfig.AddValues) and itemconfig.AddValues[1]

        -- 特殊物品标记用
        local tag = next(itemconfig.AddValues) and itemconfig.AddValues[7]
        if tag then
            -- 是否聚灵珠
            itemconfig.isJulingPearl = CheckBit(tag, 0)
            -- 神秘装备是否显示属性
            itemconfig.mysticShowAttr = CheckBit(tag, 1)
            -- 限时装备激活
            itemconfig.limitTimeActive = CheckBit(tag, 2)
            if itemconfig.limitTimeActive and itemconfig.limitRemainTime then
                itemconfig.limitEndTime = itemconfig.limitRemainTime + GetServerTime()
            end
            -- 是否自定义名称
            itemconfig.hasCustomName = CheckBit(tag, 3)
            -- 背包特效是否在物品后播放(0-在前，1-在后)
            newBEffectZ = bit.band(bit.rshift(tag, 4), 0x1)
            -- 装备内观是否在物品后播放(0-在前，1-在后)
            newSEffectZ = bit.band(bit.rshift(tag, 5), 0x1)
        end

        if itemconfig.AddValues[8] and next(itemconfig.AddValues[8]) then
            -- 物品投保次数
            local times = itemconfig.AddValues[8][1]
            itemconfig.touBaoTimes = times and times > 0 and times

            -- 物品名称自定义颜色
            local color = itemconfig.AddValues[8][2]
            itemconfig.customNameColor = color and color > 0 and color

            -- Looks
            local looks = itemconfig.AddValues[8][3]
            newLooks = looks and looks > 0 and looks or newLooks

            -- bEffect
            local bEffect = itemconfig.AddValues[8][4]
            newBEffect = bEffect > 0 and bEffect or newBEffect
        end

        if itemconfig.AddValues[9] and next(itemconfig.AddValues[9]) then
            -- sEffect
            local sEffect = itemconfig.AddValues[9][2]
            newSEffect = sEffect > 0 and sEffect or newSEffect

            -- 镶嵌开启格子数量
            local tCellNum = itemconfig.AddValues[9][4]
            itemconfig.openTNCellNum = tCellNum
        end

        -- 星星
        local star = itemconfig.AddValues[10] and next(itemconfig.AddValues[10]) and itemconfig.AddValues[10][2]
        itemconfig.Star = star and star > 0 and star

        -- 幸运
        local lucky = itemconfig.AddValues[11] and next(itemconfig.AddValues[11]) and itemconfig.AddValues[11][2]
        itemconfig.Lucky = lucky and lucky ~= 0 and lucky or nil

        -- 沙巴克武器升级记录/标识
        local shabakeUpTag = itemconfig.AddValues[11] and next(itemconfig.AddValues[11]) and itemconfig.AddValues[11][3]
        itemconfig.shabakeUpTag = shabakeUpTag

        -----------------------------------------------------
        --沙巴克武器升级攻击
        shabakeUpAttack = itemconfig.AddValues[11] and next(itemconfig.AddValues[11]) and itemconfig.AddValues[11][4]
        --沙巴克武器升级魔法
        shabakeUpMagic = itemconfig.AddValues[12] and next(itemconfig.AddValues[12]) and itemconfig.AddValues[12][1]
        --沙巴克武器升级道术
        shabakeUpDaoshu = itemconfig.AddValues[12] and next(itemconfig.AddValues[12]) and itemconfig.AddValues[12][2]

        -----------------------------------------

        -- 物品自定义名称
        local customName = itemconfig.AddValues[27]
        if customName and string.len(customName) > 0 then
            itemconfig.customName = customName
        end
    end

    if itemconfig.hasCustomName and itemconfig.customName then
        if not itemconfig.originName then
            itemconfig.originName = itemconfig.Name
        end
        itemconfig.Name = itemconfig.customName
    end
    -- 物品名称自定义颜色
    if itemconfig.customNameColor then
        itemconfig.Color = itemconfig.customNameColor
    end

    if newLooks and newLooks > 0 then
        itemconfig.Looks = newLooks
    end

    -- 背包/内观特效
    if newBEffect and newBEffect > 0 then
        local iBEffect = ""
        if global.ConstantConfig.showOrinalEffec == 1 and itemconfig.bEffect then
            iBEffect = itemconfig.bEffect .. "|"
        end
        itemconfig.bEffect = STR_FROMAT("%s%s#%s", iBEffect, newBEffect, newBEffectZ or 0)
    end

    if newSEffect and newSEffect > 0 then
        local iSEffect = "" 
        if global.ConstantConfig.showOrinalEffec == 1 and itemconfig.sEffect then
            iSEffect = itemconfig.sEffect .. "|"
        end
        itemconfig.sEffect = STR_FROMAT("%s%s#%s", iSEffect, newSEffect, newSEffectZ or 0)
    end

    local attList = {}
    itemconfig.Quality = itemconfig.Quality or {}
    for _, att in ipairs(itemconfig.Quality) do
        if att.Idx and (att.Idx == GUIDefine.AttTypeTable.Max_ATK
            or att.Idx == GUIDefine.AttTypeTable.Max_MAT
            or att.Idx == GUIDefine.AttTypeTable.Max_Daoshu) then
            attList[att.Idx] = att
        end
    end

    if shabakeUpAttack and shabakeUpAttack ~= 0 then 
        local att = attList[GUIDefine.AttTypeTable.Max_ATK]
        if att and att.Value then
            att.Value = att.Value + shabakeUpAttack
        else 
            table.insert(itemconfig.Quality,{Idx = GUIDefine.AttTypeTable.Max_ATK, Value = shabakeUpAttack})
        end
    end

    if shabakeUpMagic and shabakeUpMagic ~= 0 then 
        local att = attList[GUIDefine.AttTypeTable.Max_MAT]
        if att and att.Value then
            att.Value = att.Value + shabakeUpMagic
        else 
            table.insert(itemconfig.Quality,{Idx = GUIDefine.AttTypeTable.Max_MAT, Value = shabakeUpMagic})
        end
    end

    if shabakeUpDaoshu and shabakeUpDaoshu ~= 0 then 
        local att = attList[GUIDefine.AttTypeTable.Max_Daoshu]
        if att and att.Value then
            att.Value = att.Value + shabakeUpDaoshu
        else 
            table.insert(itemconfig.Quality,{Idx = GUIDefine.AttTypeTable.Max_Daoshu, Value = shabakeUpDaoshu})
        end
    end

    return itemconfig
end

function GetItemPowerValue(item, param)
    if not item or not next(item) then
        return 0
    end

    param = param or {}
    -- 基础属性
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local attributeCfg = ItemConfigProxy:GetItemDataByIndex(item.Index)
    local attList = {}
    local n = 0
    local attrArray = G_GetSplitArray(attributeCfg.Attribute or "", "|")
    for i, v in ipairs(attrArray) do
        if v and v ~= "" and string.len(v) > 0 then
            local vArray = G_GetSplitArray(v or "", "#")

            n = n + 1
            attList[n] = {
                id = tonumber(vArray[2]) or 3, value = tonumber(vArray[3]) or 0
            }
        end
    end

    local powerValue, powerSortIndex = CalculateAttPowerValue(attList, param.jobPower, param.powerSortIndex)
    local comparison1 = ItemConfigProxy:GetItemComparison(item.Index)
    local contrast = param.contrastV or 0 -- 选中装备 战力属性值
    local comparison = param.comparisonV or comparison1 -- 选中装备 优先级
    if comparison1 > comparison or (param.powerSortIndex and powerSortIndex > param.powerSortIndex) then --优先级
        powerValue = math.abs(powerValue) + contrast + 1 -- 比选中装备战力高 
    elseif comparison1 < comparison then
        powerValue = math.min(math.abs(powerValue), contrast - 1) -- 比选中装备战力低 
    end

    return powerValue, powerSortIndex
end

function GetItemPowerValue_Hero(item, param)
    if not item or next(item) == nil then
        return 0
    end

    param = param or {}

    -- 基础属性
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local attributeCfg = ItemConfigProxy:GetItemDataByIndex(item.Index)
    local attList = {}
    local n = 0
    local attrArray = G_GetSplitArray(attributeCfg.Attribute or "", "|")
    for i, v in ipairs(attrArray) do
        if v and v ~= "" and string.len(v) > 0 then
            local vArray = G_GetSplitArray(v or "", "#")

            n = n + 1
            attList[n] = {
                id = tonumber(vArray[2]) or 3, value = tonumber(vArray[3]) or 0
            }
        end
    end

    local powerValue, powerSortIndex = CalculateAttPowerValue(attList, param.jobPower, param.powerSortIndex, true)
    local comparison1 = ItemConfigProxy:GetItemComparison(item.Index)
    local contrast = param.contrastV or 0 --比对装备的属性值
    local comparison = param.comparisonV or comparison1 --比对装备的优先级
    if comparison1 > comparison or (param.powerSortIndex and powerSortIndex > param.powerSortIndex) then --优先级
        powerValue = math.abs(powerValue) + contrast + 1 --自身战力 + 对比装备的战力（ > 对比装备的战力 ） 1(避免等于0的情况)
    elseif comparison1 < comparison then
        powerValue = math.min(math.abs(powerValue), contrast - 1) --对比装备的战力 +  > 自身战力（ < 对比装备的战力 ）1(避免等于0的情况)
    end

    return powerValue, powerSortIndex
end

-- attList: 属性   isJobPower： 是否是只要对比     sortIndex：对比的属性下标(按照职业 按照属性 先比较匹配的属性  再比较物防  最后比较魔防  都是上限属性)
function CalculateAttPowerValue(attList, isJobPower, sortIndex, isHero)
    --[[      
        按照职业 按照属性 先比较匹配的属性  再比较物防  最后比较魔防  都是上限属性
        战士=攻击
        法师=魔法
        道士=道术
    ]]

    local attIDs = {
        [GUIDefine.AttTypeTable.Max_MDF] = 1,             -- 魔防上限
        [GUIDefine.AttTypeTable.Max_DEF] = 2              -- 防御上限
    }

    if isJobPower then
        local myJob = isHero and SL:GetMetaValue("H.JOB") or SL:GetMetaValue("JOB")
        
        local jobIdxs = {
            [0]  = GUIDefine.AttTypeTable.Max_ATK,            -- 战士
            [1]  = GUIDefine.AttTypeTable.Max_MAT,            -- 法师
            [2]  = GUIDefine.AttTypeTable.Max_Daoshu,         -- 道士

            [5]  = GUIDefine.AttTypeTable.Max_CustJobAttr_5,  -- 自定义职业(5-15)
            [6]  = GUIDefine.AttTypeTable.Max_CustJobAttr_6,
            [7]  = GUIDefine.AttTypeTable.Max_CustJobAttr_7,
            [8]  = GUIDefine.AttTypeTable.Max_CustJobAttr_8,
            [9]  = GUIDefine.AttTypeTable.Max_CustJobAttr_9,
            [10] = GUIDefine.AttTypeTable.Max_CustJobAttr_10,
            [11] = GUIDefine.AttTypeTable.Max_CustJobAttr_11,
            [12] = GUIDefine.AttTypeTable.Max_CustJobAttr_12,
            [13] = GUIDefine.AttTypeTable.Max_CustJobAttr_13,
            [14] = GUIDefine.AttTypeTable.Max_CustJobAttr_14,
            [15] = GUIDefine.AttTypeTable.Max_CustJobAttr_15
        }

        local jobIdx = jobIdxs[myJob]
        if jobIdx then
            attIDs[jobIdx] = 3
        end
    end

    local powers = {}
    local index = 0

    for i, att in ipairs(attList) do
        local id = attIDs[att.id]
        local value = att.value
        if id then
            powers[id] = value
            if id > index and value > 0 then
                index = id
            end
        end
    end

    if sortIndex and index <= sortIndex then
        index = sortIndex
    end

    return powers[index] or -1, index
end

local GET_CHECK_VALUE = {
    --等级
    [0] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleLevel()
    end,
    --属性：攻击
    [1] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleAttByAttType(GUIDefine.AttTypeTable.Max_ATK)
    end,
    --属性： 魔法
    [2] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleAttByAttType(GUIDefine.AttTypeTable.Max_MAT)
    end,
    --属性： 道术
    [3] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleAttByAttType(GUIDefine.AttTypeTable.Max_Daoshu) 
    end,
    -- 转生等级
    [4] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleReinLv()
    end,
    -- 声望值
    [5] = function(isHero)
        local proxy         = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        return proxy:GetItemCount(15,true)
    end,
    -- 是否加入行会
    [6] = function (isHero)
        local proxy         = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return proxy:IsJoinGuild()
    end,
    -- 是否是沙城成员
    [7] = function(isHero)
        local proxy         = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return proxy:IsShabakeMember()
    end,
    -- 是否是行会会长
    [8] = function(isHero)
        local proxy         = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return proxy:IsGuildChairman()
    end,
    -- 是否是沙城会长
    [9] = function(isHero)
        local proxy         = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return proxy:IsShabakeAdmin()
    end,
    -- 获取职业
    [10] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleJob()
    end,
    -- 获取货币
    [11] = function(costID)
        if not costID then
            return 0
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        return PayProxy:GetItemCount(costID)
    end,
    -- 获取属性值
    [12] = function(attrID, isHero)
        if not attrID then
            return
        end
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleAttByAttType(attrID)
    end,
    -- 刺术 刺客属性
    [13] = function(isHero)
        local proxyTable    = isHero and global.ProxyTable.HeroPropertyProxy or global.ProxyTable.PlayerPropertyProxy
        local proxy         = global.Facade:retrieveProxy(proxyTable)
        return proxy:GetRoleAttByAttType(GUIDefine.AttTypeTable.Max_Prick) 
    end,
}

local CHECK_USE_NEED = {}
local M_CHECK_USE_NEED = {
    -- 等级   聚灵珠客户端不判断等级
    [0] = function(param, isHero)
        local level     = param.value or 0
        if param.StdMode == 49 or level <= 0 then
            return true,{}
        end

        local gValue    = GET_CHECK_VALUE[0](isHero)
        local canUse    =  gValue >= level

        return canUse, {{str = STR_FROMAT(GET_STRING(80010000), level), can = canUse}}
    end,

    -- 攻
    [1] = function(param, isHero)
        local dc        = param.value or 0
        local gValue    = GET_CHECK_VALUE[1](isHero)
        local canUse    = gValue >= dc

        return canUse, {{str = STR_FROMAT(GET_STRING(80010001),dc), can = canUse}}
    end,

    -- 魔
    [2] = function(param, isHero)
        local mc        = param.value or 0
        local gValue    = GET_CHECK_VALUE[2](isHero)
        local canUse    = gValue >= mc

        return canUse, {{str = STR_FROMAT(GET_STRING(80010002),mc), can = canUse}}
    end,

    -- 道
    [3] = function(param, isHero)
        local sc        = param.value or 0
        local gValue    = GET_CHECK_VALUE[3](isHero)
        local canUse    = gValue >= sc

        return canUse, {{str = STR_FROMAT(GET_STRING(80010003),sc), can = canUse}}
    end,

    -- 转生
    [4] = function(param, isHero)
        local value     = param.value or 0
        local gValue    = GET_CHECK_VALUE[4](isHero)
        local canUse    = gValue >= value

        return canUse, {{str = STR_FROMAT(GET_STRING(80010004),value), can = canUse}}
    end,

    --需要指定声望点
    [5] = function(param, isHero)
        local value     = param.value or 0
        local gValue    = GET_CHECK_VALUE[5](isHero)
        local canUse    = gValue >= value

        return canUse, {{str = STR_FROMAT(GET_STRING(80010005),value), can = canUse}}
    end,

    -- 是否加入行会
    [6] = function(param, isHero)
        local canUse    = GET_CHECK_VALUE[6](isHero)

        return canUse, {{str = GET_STRING(80010006), can = canUse}}
    end,

    -- 沙城成员 不做检测 默认满足
    [7] = function(param, isHero)
        return true, {{str = GET_STRING(80010007), can = true}}
    end,

    -- 指定职业和等级
    [10] = function(param,isHero)
        if param.StdMode == 49 then
            return true,{}
        end

        local value     = param.value or 0 
        local job       = L16Bit(value)
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            local combJob   = {[0] = 0, [1] = 1, [2] = 2}   -- 人物、英雄通用
            local heroJob   = {[3] = 3, [4] = 4, [5] = 5}   
            local playerJob = {[6] = 6, [7] = 7, [8] = 8}
            if combJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](isHero)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GET_STRING(50000324 + job)), can = canUse}
            elseif heroJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](true)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010086), GET_STRING(50000324 + job - 3)), can = canUse}
            elseif playerJob[job] then
                local job   = job - 6
                canUse      = job == GET_CHECK_VALUE[10]()
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010085), GET_STRING(50000324 + job)), can = canUse}
            end
        end

        local levelCanUse,condition = CHECK_USE_NEED[0]({
            StdMode = param.StdMode,
            value   = H16Bit(value),
        }, isHero)

        conditions[2] = condition[1]
        return canUse and levelCanUse,conditions
    end,

    -- 指定职业和攻击力
    [11] = function(param,isHero)
        if param.StdMode == 49 then
            return true,{}
        end

        local value     = param.value or 0 
        local job       = L16Bit(value)
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            local combJob   = {[0] = 0, [1] = 1, [2] = 2}   -- 人物、英雄通用
            local heroJob   = {[3] = 3, [4] = 4, [5] = 5}   
            local playerJob = {[6] = 6, [7] = 7, [8] = 8}
            if combJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](isHero)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GET_STRING(50000324 + job)), can = canUse}
            elseif heroJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](true)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010086), GET_STRING(50000324 + job - 3)), can = canUse}
            elseif playerJob[job] then
                local job   = job - 6
                canUse      = job == GET_CHECK_VALUE[10]()
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010085), GET_STRING(50000324 + job)), can = canUse}
            end
        end

        local dcCanUse,condition = CHECK_USE_NEED[1]({
            StdMode = param.StdMode,
            value   = H16Bit(value),
        }, isHero)

        conditions[2] = condition[1]
        return canUse and dcCanUse,conditions
    end,

    -- 12：指定职业和魔法力
    [12] = function(param,isHero)
        if param.StdMode == 49 then
            return true,{}
        end

        local value     = param.value or 0 
        local job       = L16Bit(value)
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            local combJob   = {[0] = 0, [1] = 1, [2] = 2}   -- 人物、英雄通用
            local heroJob   = {[3] = 3, [4] = 4, [5] = 5}   
            local playerJob = {[6] = 6, [7] = 7, [8] = 8}
            if combJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](isHero)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GET_STRING(50000324 + job)), can = canUse}
            elseif heroJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](true)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010086), GET_STRING(50000324 + job - 3)), can = canUse}
            elseif playerJob[job] then
                local job   = job - 6
                canUse      = job == GET_CHECK_VALUE[10]()
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010085), GET_STRING(50000324 + job)), can = canUse}
            end
        end

        local mcCanUse,condition = CHECK_USE_NEED[2]({
            StdMode = param.StdMode,
            value   = H16Bit(value),
        }, isHero)

        conditions[2] = condition[1]
        return canUse and mcCanUse,conditions
    end,

    -- 13：指定职业和道术
    [13] = function(param,isHero)
        if param.StdMode == 49 then
            return true,{}
        end

        local value     = param.value or 0 
        local job       = L16Bit(value)
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            local combJob   = {[0] = 0, [1] = 1, [2] = 2}   -- 人物、英雄通用
            local heroJob   = {[3] = 3, [4] = 4, [5] = 5}   
            local playerJob = {[6] = 6, [7] = 7, [8] = 8}
            if combJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](isHero)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GET_STRING(50000324 + job)), can = canUse}
            elseif heroJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](true)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010086), GET_STRING(50000324 + job - 3)), can = canUse}
            elseif playerJob[job] then
                local job   = job - 6
                canUse      = job == GET_CHECK_VALUE[10]()
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010085), GET_STRING(50000324 + job)), can = canUse}
            end
        end

        local scCanUse,condition = CHECK_USE_NEED[3]({
            StdMode = param.StdMode,
            value   = H16Bit(value),
        }, isHero)

        conditions[2] = condition[1]
        return canUse and scCanUse,conditions
    end,

    --指定等级
    [14] = function(param,isHero)
        local level     = param.value or 0
        local gValue    = GET_CHECK_VALUE[0](isHero)
        local canUse    =  gValue == level

        return canUse, {{str = STR_FROMAT(GET_STRING(80010084), level), can = canUse}}
    end,

    -- 等级 及转生
    [40] = function(param,isHero)
        local value     = param.value or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = H16Bit(value)
        }
        local levelCanUse,condition1    = CHECK_USE_NEED[0](checkParam,isHero)
        checkParam.value                = L16Bit(value)
        local reinLVCanUse,condition2   = CHECK_USE_NEED[4](checkParam,isHero)

        return levelCanUse and reinLVCanUse, {condition1[1], condition2[1] }
    end,

    -- 攻    及转生
    [41] = function(param,isHero)
        local value     = param.value or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = H16Bit(value)
        }
        local levelCanUse,condition1    = CHECK_USE_NEED[1](checkParam,isHero)
        checkParam.value                = L16Bit(value)
        local reinLVCanUse,condition2   = CHECK_USE_NEED[4](checkParam,isHero)

        return levelCanUse and reinLVCanUse, {condition2[1], condition1[1] }
    end,

    -- 魔    及转生
    [42] = function(param,isHero)
        local value     = param.value or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = H16Bit(value)
        }
        local levelCanUse,condition1    = CHECK_USE_NEED[2](checkParam,isHero)
        checkParam.value                = L16Bit(value)
        local reinLVCanUse,condition2   = CHECK_USE_NEED[4](checkParam,isHero)

        return levelCanUse and reinLVCanUse, {condition2[1], condition1[1] }
    end,

    -- 道    及转生
    [43] = function(param,isHero)
        local value     = param.value or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = H16Bit(value)
        }
        local levelCanUse,condition1    = CHECK_USE_NEED[3](checkParam,isHero)
        checkParam.value                = L16Bit(value)
        local reinLVCanUse,condition2   = CHECK_USE_NEED[4](checkParam,isHero)

        return levelCanUse and reinLVCanUse, {condition2[1], condition1[1] }
    end,

    --声望等级    指定声望点
    [44] = function(param,isHero)
        local value     = param.value or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = H16Bit(value)
        }
        local levelCanUse,condition1    = CHECK_USE_NEED[5](checkParam,isHero)
        checkParam.value                = L16Bit(value)
        local reinLVCanUse,condition2   = CHECK_USE_NEED[4](checkParam,isHero)

        return levelCanUse and reinLVCanUse, {condition2[1], condition1[1] }
    end,

    -- 指定职业和转生等级
    [45] = function(param,isHero)
        if param.StdMode == 49 then
            return true,{}
        end
        
        local value     = param.value or 0 
        local job       = H16Bit(value)
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            local combJob   = {[0] = 0, [1] = 1, [2] = 2}   -- 人物、英雄通用
            local heroJob   = {[3] = 3, [4] = 4, [5] = 5}   
            local playerJob = {[6] = 6, [7] = 7, [8] = 8}
            if combJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](isHero)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GET_STRING(50000324 + job)), can = canUse}
            elseif heroJob[job] then
                canUse      = job == GET_CHECK_VALUE[10](true)
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010086), GET_STRING(50000324 + job - 3)), can = canUse}
            elseif playerJob[job] then
                local job   = job - 6
                canUse      = job == GET_CHECK_VALUE[10]()
                conditions[1] = {str = STR_FROMAT(GET_STRING(80010085), GET_STRING(50000324 + job)), can = canUse}
            end
        end

        local reinLVCanUse,condition = CHECK_USE_NEED[4]({
            StdMode = param.StdMode,
            value   = L16Bit(value),
        },isHero)
        conditions[2] = condition[1]

        return canUse and reinLVCanUse,conditions
    end,

    -- 是否是行会会长
    [60] = function(param,isHero)
        local value     = param.value or 0
        local canUse    = GET_CHECK_VALUE[8](isHero)

        return canUse,{{str = GET_STRING(80010060), can = canUse}}
    end,

    -- 沙城会长 不做检测 默认满足
    [70] = function(param, isHero)
        return true,{{str = GET_STRING(80010070), can = true}}
    end,

    -- 110 - 120 新增 [职业判断无额外设定]
    -- 指定职业和等级
    [110] = function (param, isHero)
        local job       = param.value or 99
        local value2    = param.value2 or 0
        local canUse    = job == 99
        local conditions= {}

        if not canUse then 
            canUse = job == GET_CHECK_VALUE[10](isHero)
            conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        local levelCanUse, condition = CHECK_USE_NEED[0]({
            StdMode = param.StdMode,
            value   = value2,
        }, isHero)

        conditions[2] = condition[1]
        return canUse and levelCanUse, conditions
    end,

    -- 指定职业和攻击力
    [111] = function(param, isHero)
        if param.StdMode == 49 then
            return true, {}
        end

        local job       = param.value or 99 
        local value2    = param.value2 or 0
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            canUse      = job == GET_CHECK_VALUE[10](isHero)
            conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        local dcCanUse, condition = CHECK_USE_NEED[1]({
            StdMode = param.StdMode,
            value   = value2,
        }, isHero)

        conditions[2] = condition[1]
        return canUse and dcCanUse, conditions
    end,

    -- 112：指定职业和魔法力
    [112] = function(param, isHero)
        if param.StdMode == 49 then
            return true, {}
        end

        local job       = param.value or 99 
        local value2    = param.value2 or 0
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            canUse      = job == GET_CHECK_VALUE[10](isHero)
            conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        local mcCanUse,condition = CHECK_USE_NEED[2]({
            StdMode = param.StdMode,
            value   = value2,
        }, isHero)

        conditions[2] = condition[1]
        return canUse and mcCanUse, conditions
    end,

    -- 113：指定职业和道术
    [113] = function(param, isHero)
        if param.StdMode == 49 then
            return true,{}
        end

        local job       = param.value or 99 
        local value2    = param.value2 or 0
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            canUse      = job == GET_CHECK_VALUE[10](isHero)
            conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        local scCanUse,condition = CHECK_USE_NEED[3]({
            StdMode = param.StdMode,
            value   = value2,
        }, isHero)

        conditions[2] = condition[1]
        return canUse and scCanUse, conditions
    end,

    -- 114: 指定货币
    [114] = function(param)
        local costID = param.value or 0
        if costID == 0 then
            return true, {}
        end

        -- 货币数量
        local value2 = param.value2 or 0
        if value2 <= 0 then
            return true, {}
        end

        local hasValue  = GET_CHECK_VALUE[11](costID)
        local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
        local costName  = MoneyProxy:GetMoneyNameById(costID) or "无效货币"
        local canUse    = hasValue >= value2
        return canUse, {{str = STR_FROMAT(GET_STRING(80010100), costName, value2), can = canUse}}
    end,

    -- 115: 指定转生等级和等级
    [115] = function(param, isHero)
        local reLevel   = param.value or 0
        local level     = param.value2 or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        checkParam.value                = level
        local levelCanUse, condition2   = CHECK_USE_NEED[0](checkParam, isHero)

        return reinLVCanUse and levelCanUse, {condition1[1], condition2[1]}
    end,

    -- 116: 指定转生等级和攻击力
    [116] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        checkParam.value                = value2
        local canUse, condition2        = CHECK_USE_NEED[1](checkParam, isHero)

        return reinLVCanUse and canUse, {condition1[1], condition2[1]}
    end,

    -- 117: 指定转生等级和魔法力
    [117] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        checkParam.value                = value2
        local canUse, condition2        = CHECK_USE_NEED[2](checkParam, isHero)

        return reinLVCanUse and canUse, {condition1[1], condition2[1]}
    end,

    -- 118: 指定转生等级和道术
    [118] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        checkParam.value                = value2
        local canUse, condition2        = CHECK_USE_NEED[3](checkParam, isHero)

        return reinLVCanUse and canUse, {condition1[1], condition2[1]}
    end,

    -- 119: 指定转生等级和声望点
    [119] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        checkParam.value                = value2
        local canUse, condition2        = CHECK_USE_NEED[5](checkParam, isHero)

        return reinLVCanUse and canUse, {condition1[1], condition2[1]}
    end,

    -- 120: 指定转生等级和职业
    [120] = function(param, isHero)
        if param.StdMode == 49 then
            return true, {}
        end
        
        local value     = param.value or 0 
        local job       = param.value2 or 99
        local canUse    = job == 99
        local conditions= {}

        local reinLVCanUse, condition = CHECK_USE_NEED[4]({
            StdMode = param.StdMode,
            value   = value,
        }, isHero)
        conditions[1] = condition[1]

        if not canUse then
            canUse      = job == GET_CHECK_VALUE[10](isHero)
            conditions[2] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        return canUse and reinLVCanUse, conditions 
    end,
    -- 121: 指定职业和职业对应核心属性值以上
    [121] = function(param, isHero)
        if param.StdMode == 49 then
            return true, {}
        end

        local job       = param.value or 99 
        local value2    = param.value2 or 0
        local canUse    = job == 99
        local conditions= {}

        if not canUse then
            canUse      = job == GET_CHECK_VALUE[10](isHero)
            conditions[1] = {str = STR_FROMAT(GET_STRING(80010083), GUIFunction:GetJobNameByID(job)), can = canUse}
        end

        local attrCanUse = nil
        if job >= 5 and job <= 15 then
            local attId = GUIDefine.AttTypeTable["Max_CustJobAttr_" .. job]
            local attrValue = GET_CHECK_VALUE[12](attId, isHero) or 0
            attrCanUse = attrValue >= value2
            local config = SL:GetValue("ATTR_CONFIG", attId) or {}
            conditions[2] = {str = STR_FROMAT(GET_STRING(80010100), config.name or STR_FROMAT("职业%s核心属性", job), value2), can = attrCanUse}
        else
            local aCanUse, condition = CHECK_USE_NEED[job + 1]({
                StdMode = param.StdMode,
                value   = value2,
            }, isHero)
            attrCanUse = aCanUse
            conditions[2] = condition[1]
        end
        
        return canUse and attrCanUse, conditions
    end,
    -- 122: 指定转生等级和刺客属性上限值
    [122] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local conditions = {}
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        conditions[1] = condition1[1]

        local attrValue     = GET_CHECK_VALUE[13](isHero) or 0
        local attrCanUse    = attrValue >= value2
        local config = SL:GetValue("ATTR_CONFIG", GUIDefine.AttTypeTable.Max_Prick) or {}
        conditions[2] = {str = STR_FROMAT(GET_STRING(80010100), config.name or "刺客核心属性", value2), can = attrCanUse}

        return reinLVCanUse and attrCanUse, conditions
    end,

    -- 123: 指定转生等级和职业5属性上限值
    -- 123 - 134 ：职业5 - 15
    [123] = function(param, isHero)
        local reLevel   = param.value or 0
        local value2    = param.value2 or 0
        local jobIdx    = param.jobIdx or 0
        local conditions = {}
        local checkParam = {
            StdMode = param.StdMode,
            value   = reLevel
        }
        local reinLVCanUse, condition1  = CHECK_USE_NEED[4](checkParam, isHero)
        conditions[1] = condition1[1]

        local job = 5 + jobIdx
        local attId = GUIDefine.AttTypeTable["Max_CustJobAttr_" .. job]
        local attrValue = GET_CHECK_VALUE[12](attId, isHero) or 0
        local attrCanUse = attrValue >= value2
        local config = SL:GetValue("ATTR_CONFIG", attId) or {}
        conditions[2] = {str = STR_FROMAT(GET_STRING(80010100), config.name or STR_FROMAT("职业%s核心属性", job), value2), can = attrCanUse}

        return reinLVCanUse and attrCanUse, conditions
    end
}

CHECK_USE_NEED = M_CHECK_USE_NEED

local COMMON_FUNC_IDX = 123
local COMMON_FUNC_IDX_MAX = 134
local function checkComFunc(needType)
    if needType >= COMMON_FUNC_IDX and needType <= COMMON_FUNC_IDX_MAX then
        local index = needType - COMMON_FUNC_IDX
        return COMMON_FUNC_IDX, index
    end
end

-- 服务器翻过来 用于前端检测道具使用
function CheckItemUseNeed(item)
    local needType = item.Need
    local needLevel = item.NeedLevel
    local notCheckUse = true --不检测是否满足使用条件

    -- 聚灵珠不用判断显示
    if item.StdMode == 49 then
        return true, {}, notCheckUse
    end

    if not needType or not needLevel then
        return true, {}, notCheckUse
    end

    local commonType, jobIdx = checkComFunc(needType)
    if not CHECK_USE_NEED[commonType or needType] then
        return true, {}, notCheckUse
    end

    local param = {
        StdMode = item.StdMode,
        value   = needLevel,
        value2  = item.NeedLevelParam or 0,
        jobIdx  = jobIdx
    }
    local canUse, conditionStr = CHECK_USE_NEED[commonType or needType](param)
    return canUse, conditionStr, notCheckUse
end

function CheckItemUseNeed_Hero(item)
    local needType = item.Need
    local needLevel = item.NeedLevel
    local notCheckUse = true --不检测是否满足使用条件

    if not needType or not needLevel then
        return true, {}, notCheckUse
    end

    if not CHECK_USE_NEED[needType] then
        return true, {}, notCheckUse
    end

    local param = {
        StdMode = item.StdMode,
        value   = needLevel,
        value2  = item.NeedLevelParam or 0,
    }
    local canUse, conditionStr = CHECK_USE_NEED[needType](param, true)
    return canUse, conditionStr, notCheckUse
end