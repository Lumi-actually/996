local utils        = {}
local tSort        = table.sort
local mAbs         = math.abs

-- RS_ENEMY    = 1,              -- 敌人
-- RS_NO       = 2,              -- 非敌人,没有关系
-- RS_GROUP    = 3,              -- 同队伍
-- RS_GUILD    = 4,              -- 同行会
-- RS_CAMP     = 5,              -- 同阵营
-- RS_ALLIANCE = 6,              -- 同盟
-- RS_NATION   = 7,              -- 国家

local CHECK_ENEMY_VALUE = {
    -- 获取最终的actor的主人玩家actor player
    [0] = function( targetActor )
        local masterActor = nil
        if targetActor:IsHero() or targetActor:IsPet() or targetActor:IsHumanoid() then
            local tMasterID     = targetActor:GetMasterID()
            local tMasterActor  = global.actorManager:GetActor( tMasterID )
            if tMasterActor and targetActor:IsHumanoid() and tMasterActor:IsHero() then
                tMasterID     = targetActor:GetMasterID()
                tMasterActor  = global.actorManager:GetActor( tMasterID )
            end
            if tMasterActor and tMasterActor:IsPlayer() then
                masterActor = tMasterActor
            end
        end
        return masterActor or targetActor
    end,
}

local CHECK_ENEMY_FUNC  = {
    -- 全体
    [global.MMO.HAM_ALL] = function( mainPlayer, targetActor )
        return global.MMO.RS_ENEMY
    end,

    -- 行会
    [global.MMO.HAM_GUILD] = function( mainPlayer, targetActor )
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        local mGuildID      = mainPlayer:GetGuildID()
        local tGuildID      = tMasterActor and tMasterActor:GetGuildID()
        local GuildProxy    = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        if (tMasterActor and tMasterActor:GetID()) == mainPlayer:GetID() then
            return global.MMO.RS_NO
        end
        if tGuildID and tGuildID ~= "" and mGuildID and mGuildID ~= "" and (mGuildID == tGuildID or GuildProxy:IsAllyGuild(tGuildID)) then
            return global.MMO.RS_GUILD
        end
        return global.MMO.RS_ENEMY
    end,

    -- 队伍
    [global.MMO.HAM_GROUP] = function( mainPlayer, targetActor )
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        local teamProxy     = global.Facade:retrieveProxy( global.ProxyTable.TeamProxy )
        local actorID       = tMasterActor and tMasterActor:GetID()
        if actorID and actorID == mainPlayer:GetID() then
            return global.MMO.RS_NO
        end
        if actorID and teamProxy:IsTeamMember( actorID) then
            return global.MMO.RS_GROUP
        end
        return global.MMO.RS_ENEMY
    end,

    -- 阵营
    [global.MMO.HAM_CAMP] = function( mainPlayer, targetActor )
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        if (tMasterActor and tMasterActor:GetID()) == mainPlayer:GetID() then
            return global.MMO.RS_NO
        end
        local mFaction = mainPlayer:GetFaction()
        if mFaction and mFaction > 0 and mFaction == tMasterActor:GetFaction() then
            return global.MMO.RS_CAMP
        end
        return global.MMO.RS_ENEMY
    end,

    -- 善恶
    [global.MMO.HAM_SHANE] = function( mainPlayer, targetActor )
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        local mPKLv = mainPlayer:GetPKLv()
        local tPKLv = tMasterActor:GetPKLv()
        if not mPKLv or not tPKLv then
            return global.MMO.RS_NO
        end

        -- 白: 0  黄 1  红 2  灰 3
        -- 不判断自身状态  可以攻击灰/红
        if tPKLv == 2 or tPKLv == 3 then
            return global.MMO.RS_ENEMY
        end

        return global.MMO.RS_NO
    end,

    -- 区服
    [global.MMO.HAM_SERVER] = function( mainPlayer, targetActor )
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        if (tMasterActor and tMasterActor:GetID()) == mainPlayer:GetID() then
            return global.MMO.RS_NO
        end
        if mainPlayer:GetServerID() == tMasterActor:GetServerID() then
            return global.MMO.RS_SERVER
        end
        return global.MMO.RS_ENEMY
    end,

    -- 国家
    [global.MMO.HAM_NATION] = function( mainPlayer, targetActor )
        local mNationID = mainPlayer:GetNationID()
        local tMasterActor  = CHECK_ENEMY_VALUE[0]( targetActor )
        local tNationID = nil
        if tMasterActor:IsPlayer() then
            tNationID = tMasterActor:GetNationID()
        elseif tMasterActor:IsMonster() and tMasterActor:IsNationEnemyPK() then
            tNationID = tMasterActor:GetNationID()
        end

        if mNationID and mNationID > 0 and mNationID == tNationID then
            return global.MMO.RS_NATION
        end

        return global.MMO.RS_ENEMY
    end,

    -- 和平
    [global.MMO.HAM_PEACE] = function(mainPlayer, targetActor)
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        if not autoProxy:IsAFKState() and not autoProxy:IsAutoFightState() then -- 非自动战斗
            return global.MMO.RS_ENEMY
        end
        return global.MMO.RS_NO
    end,
}

utils.CheckCustomModeTag = function(mainPlayer, targetActor, customMode)
    local tMasterActor  = CHECK_ENEMY_VALUE[0](targetActor)
    if (tMasterActor and tMasterActor:GetID()) == mainPlayer:GetID() then
        return global.MMO.RS_NO
    end
    for i = 1, 2 do
        local targetNetID = tMasterActor and tMasterActor:GetJoinNetTypeData(customMode, i)
        for j = 1, 2 do
            local mainNetID = mainPlayer and mainPlayer:GetJoinNetTypeData(customMode, j) 
            if targetNetID and mainNetID and targetNetID == mainNetID then -- 拥有同一关系netID
                return customMode
            end
        end
    end

    return global.MMO.RS_ENEMY
end

utils.CheckEnemyTag = function( actor )
    if not actor then
        return global.MMO.RS_NO
    end

     -- 1. oneself
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer or ( actor:IsPlayer() and actor:IsMainPlayer() ) then
        return global.MMO.RS_NO
    end

    -- 除全体模式 可以锁定自己人外 别的模式不能锁定 走game表配置 默认不可锁定
    local pkModeLock = SL:GetValue("GAME_DATA", "pk_mode_lock") or 0
    if pkModeLock == 1 and (actor:IsPlayer() or actor:IsMonster()) then
        return global.MMO.RS_ENEMY
    end

    -- check pk mode
    local playerPropertyProxy = global.Facade:retrieveProxy( global.ProxyTable.PlayerPropertyProxy )
    local pkState             = playerPropertyProxy:GetPKMode()

    if actor:IsMonster() and global.MMO.HAM_NATION ~= pkState then
        return global.MMO.RS_ENEMY
    end

    if actor:IsHumanoid() and global.MMO.HAM_NATION ~= pkState then
        return global.MMO.RS_ENEMY
    end

    if CHECK_ENEMY_FUNC[pkState] then
        return CHECK_ENEMY_FUNC[pkState]( mainPlayer, actor )
    end

    if table.indexof(SL:GetValue("RELATION_TYPE_LIST"), pkState) then
       return utils.CheckCustomModeTag(mainPlayer, actor, pkState)
    end

    return global.MMO.RS_NO
end

utils.CheckLaunchTargetByID = function( targetID )
    return GUIFunction:CheckLaunchEnableByID(targetID)
end

utils.CheckAutoTargetEnableByID = function( targetID )
    return GUIFunction.CheckAutoTargetEnableByID(targetID)
end

utils.IsDrug = function(itemIndex)
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugSHY")) do
        if itemIndex == v then
            return true,1
        end
    end
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugHY")) do
        if itemIndex == v then
            return true,2
        end
    end
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugLY")) do
        if itemIndex == v then
            return true,3
        end
    end
    return false
end

utils.IsStone = function(itemIndex)
    for _, v in ipairs(SL:GetValue("GAME_DATA","cityStone")) do
        if itemIndex == v then
            return true
        end
    end
    for _, v in ipairs(SL:GetValue("GAME_DATA","randStone")) do
        if itemIndex == v then
            return true
        end
    end

    return false
end

utils.FindItemByIndex = function(index)
    local itemData = QuickUseData.GetQuickUseDataByIndex(index)
    if itemData and itemData[1] then
        return itemData[1]
    end

    local itemData = BagData.GetItemDataByItemIndex(index)
    if itemData and itemData[1] then
        return itemData[1]
    end

    return nil
end
utils.FindItemByIndex_Hero = function(index)
    local itemData = HeroBagData.GetItemDataByItemIndex(index)
    if itemData and itemData[1] then
        return itemData[1]
    end

    return nil
end

utils.FindItemCountByIndex = function(index)
    local count         = 0
    local itemData = QuickUseData.GetQuickUseDataByIndex(index)
    if itemData and itemData[1] then
        count           = count + #itemData
    end

    local itemData = BagData.GetItemDataByItemIndex(index)
    if itemData and itemData[1] then
        count           = count + #itemData
    end

    return count
end

utils.FindItemCountByIndex_Hero = function(index)
    local count         = 0
    local itemData = HeroBagData.GetItemDataByItemIndex(index)
    if itemData and itemData[1] then
        count           = count + #itemData
    end

    return count
end

utils.FindBagCountByIndex = function(index)
    local count         = 0
    local itemData = BagData.GetItemDataByItemIndex(index)
    if itemData and itemData[1] then
        count           = count + #itemData
    end

    return count
end

utils.UnpackDrugByIndex = function(itemIndex, ignoreCount)
    local ItemUseProxy      = global.Facade:retrieveProxy( global.ProxyTable.ItemUseProxy )
    local ItemConfigProxy   = global.Facade:retrieveProxy( global.ProxyTable.ItemConfigProxy )

    -- 药品才有解包逻辑 + 回城/随机
    local drug,drugType = utils.IsDrug(itemIndex)
    if not drug and not utils.IsStone(itemIndex) then
        return false
    end

    -- 背包有，不需要解包
    local itemCount      = utils.FindItemCountByIndex(itemIndex)
    if itemCount >= 1 and not ignoreCount then
        return false
    end

    -- 没有配置药品包
    if #SL:GetValue("GAME_DATA","allDrugPack") == 0 then
        return false
    end

    local PlayerProperty = global.Facade:retrieveProxy( global.ProxyTable.PlayerPropertyProxy )
    if not PlayerProperty then
        return false
    end

    if drugType == 3 then
        local roleLevel = PlayerProperty:GetRoleLevel()
        local roleJob   = PlayerProperty:GetRoleJob()
        if roleLevel < 28 and roleJob == GUIDefine.Job.FIGHTER then
            return false
        end
    end

    -- 解包时格子数
    local limitCount        = BagData.GetMaxBag() + QuickUseData.GetQuickUseSize()
    local totalCount        = BagData.GetTotalItemCount() + QuickUseData.GetQuickUseItemTotalCount()
    
    -- 找解包药
    local unpackItem = nil
    local unpackItemCount = nil
    local function findPackItem(item)
        if unpackItem then
            return
        end
        if item.AniCount == 0 then
            return
        end
        
        for k, v in ipairs(SL:GetValue("GAME_DATA", "allDrugPack")) do
            if v.Shape == item.AniCount and v.Index ~= item.Index then
                local itemData = BagData.GetItemDataByItemIndex(v.Index)
                if itemData and itemData[1] then
                    -- 找到可以解包了
                    unpackItem = itemData[1]
                    unpackItemCount = unpackItem.nUnPackCount
                    if unpackItem.OverLap and unpackItem.OverLap > 0 then
                        unpackItemCount = 1
                    end
                else
                    -- 未找到，继续向上套
                    findPackItem(v)
                end
                break
            end
        end
    end

    -- 解包
    unpackItem = nil
    findPackItem(ItemConfigProxy:GetItemDataByIndex(itemIndex))

    if unpackItem then
        local calcCount = totalCount + (unpackItemCount or 1) -1
        if calcCount <= limitCount then
            ItemUseProxy:UseItem(unpackItem)
            print("UNPACK", unpackItem.Name, unpackItem.Index)
            return true
        end
    end

    return false
end

utils.UnpackDrugByIndex_Hero = function(itemIndex, ignoreCount,notuse)
    local ItemUseProxy      = global.Facade:retrieveProxy( global.ProxyTable.ItemUseProxy )
    local ItemConfigProxy   = global.Facade:retrieveProxy( global.ProxyTable.ItemConfigProxy )

    -- 药品才有解包逻辑
    if not utils.IsDrug(itemIndex) then
        return false
    end

    -- 背包有，不需要解包
    local itemCount      = utils.FindItemCountByIndex_Hero(itemIndex)
    if itemCount >= 1 and not ignoreCount then
        return false
    end

    -- 没有配置药品包
    if #SL:GetValue("GAME_DATA","allDrugPack") == 0 then
        return false
    end

    -- 解包时格子数
    local limitCount        = HeroBagData.GetMaxBag()
    local totalCount        = HeroBagData.GetTotalItemCount()
    
    -- 找解包药
    local unpackItem = nil
    local function findPackItem(item)
        if unpackItem then
            return
        end
        if item.AniCount == 0 then
            return
        end
        
        for k, v in pairs(SL:GetValue("GAME_DATA","allDrugPack")) do
            if v.Shape == item.AniCount then
                local itemData = HeroBagData.GetItemDataByItemIndex(v.Index)
                if itemData and itemData[1] then
                    -- 找到可以解包了
                    unpackItem = itemData[1]
                else
                    -- 未找到，继续向上套
                    findPackItem(v)
                end
                break
            end
        end
    end

    -- 解包
    unpackItem = nil
    findPackItem(ItemConfigProxy:GetItemDataByIndex(itemIndex))

    if unpackItem then
        local calcCount = totalCount + (unpackItem.nUnPackCount or 1) -1
        if calcCount <= limitCount and not  notuse then
            ItemUseProxy:HeroUseItem(unpackItem)
            print("UNPACK", unpackItem.Name)
            return true
        end
    end

    return false
end

utils.AutoUnpackDrug = function()
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugSHY")) do
        if utils.UnpackDrugByIndex(v) then
            return true
        end
    end
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugHY")) do
        if utils.UnpackDrugByIndex(v) then
            return true
        end
    end
    for _, v in ipairs(SL:GetValue("GAME_DATA","drugLY")) do
        if utils.UnpackDrugByIndex(v) then
            return true
        end
    end
    return false
end

local CHECK_ITEM_AUTOPICK_EXTRA = function(itemIndex, bySprite)
    if GUIFunction and GUIFunction.CheckAutoPickItemEnable_Extra then
        local value = GUIFunction:CheckAutoPickItemEnable_Extra(itemIndex, bySprite == true)
        if type(value) == "boolean" then
            return value
        end
    end
    return true
end

-- 道具是否能自动拾取 isSprite：是否小精灵自动拾取
function utils:AutoPickItemEnable(dropItem, mainPlayerID, isSprite)
    if not dropItem then
        return false
    end

    if not mainPlayerID then
        mainPlayerID = global.gamePlayerController:GetMainPlayerID()
    end
    if not mainPlayerID then
        return false
    end

    local actorID = dropItem:GetID()
    local bPick = G_ActorUtils.GetActorAttr(dropItem, global.MMO.ACTOR_ATTR_PICK)
    if not bPick then
        return false
    end

    local typeIndex = (dropItem:GetTypeIndex() == 0 and 1 or dropItem:GetTypeIndex())
    local GameSettingProxy = global.Facade:retrieveProxy( global.ProxyTable.GameSettingProxy )
    local group = GameSettingProxy:GetGroupIdByIndex(typeIndex)--是否配了组别
    if group or typeIndex ~= 1  then--金币不判断 开关  配置了组别的需要检测
        if not CHECK_ITEM_AUTO_PICK(typeIndex) or not CHECK_ITEM_PICK(typeIndex) then
            return false
        end

        if CHECK_ITEM_QUALITY_PICK(typeIndex) and not (dropItem.GetQualityState and dropItem:GetQualityState()) then
            return false
        end
    end

    if typeIndex ~= 1 then --不是金币 判断一下背包负重
        local itemData = SL:GetValue("ITEM_DATA", typeIndex)
        if itemData.Weight then 
            local maxbw = SL:GetValue("MAXBW")
            local bw = SL:GetValue("BW")
            if bw + itemData.Weight >= maxbw then 
                return false
            end
        end
    end

    --自己丢弃的物品不要自动拾取了
    local drops = BagData.GetSelfDropItems() or {}
    for i,v in ipairs(drops) do
        if v == dropItem:GetMakeIndex() then 
            return false
        end
    end
    local drops2 = HeroBagData.GetSelfDropItems()
    for i,v in ipairs(drops2) do
        if v == dropItem:GetMakeIndex() then 
            return false
        end
    end

    local ItemConfigProxy = global.Facade:retrieveProxy( global.ProxyTable.ItemConfigProxy )
    local itemData =  ItemConfigProxy:GetItemDataByIndex(typeIndex)
    local ConditionProxy =  global.Facade:retrieveProxy( global.ProxyTable.ConditionProxy )
    local conditionsList = G_GetSplitArray(itemData.pickCondition or "", "|")
    local conditionWay = conditionsList[2] and tonumber(conditionsList[2]) or 0 -- 0: 正常拾取 1: 不让小精灵拾取 2: 满足条件-小精灵拾取、不满足也拾取
    if not ConditionProxy:CheckCondition(conditionsList[1] or "") and conditionWay ~= 2 then 
        return false
    end

    -- 道具能否小精灵自动拾取
    if isSprite then
        if conditionWay == 1 or (conditionWay == 2 and not ConditionProxy:CheckCondition(conditionsList[1] or "")) then
            return false
        end
    end

    if dropItem:CheckOwnerID( mainPlayerID ) then
        if not CHECK_ITEM_AUTOPICK_EXTRA(typeIndex, isSprite) then
            return false
        end
        return true
    end

    local teamProxy = global.Facade:retrieveProxy( global.ProxyTable.TeamProxy )
    if teamProxy:IsTeamMember( dropItem:GetOwnerID() ) then   -- owner is not team member
        if not CHECK_ITEM_AUTOPICK_EXTRA(typeIndex, isSprite) then
            return false
        end
        return true
    end

    return false
end

-- 道具是否能拾取
function utils:DropItemPickEnable( dropItem )
    if not dropItem then
        return false
    end

    local typeIndex = (dropItem:GetTypeIndex() == 0 and 1 or dropItem:GetTypeIndex())
    if not CHECK_ITEM_PICK(typeIndex) then
        return false
    end

    -- 仅拾取极品装备
    if CHECK_ITEM_QUALITY_PICK(typeIndex) and not (dropItem.GetQualityState and dropItem:GetQualityState()) then
        return false
    end
    
    return true
end

--四周是否有足够的敌人
utils.CheckIsEnoughEnemy = function(targetID,count,distance)
    local targetActor = global.actorManager:GetActor( targetID )
    if not targetActor then
        return false
    end
    
    local enoughCount = tonumber(count) or 3
    local count = 0
    local actors, actorNums = global.actorManager:GetActors()
    local pMapX = targetActor:GetMapX()
    local pMapY = targetActor:GetMapY()
    distance    = distance or 2     -- 多少格之内

    for i = 1, actorNums do
        local actor = actors[i]
        if actor then
            if (actor:IsPlayer() or actor:IsMonster()) and mAbs(actor:GetMapX() - pMapX) <= distance and mAbs(actor:GetMapY() - pMapY) <= distance and utils.CheckLaunchTargetByID(actor:GetID()) then
                count = count + 1
            end
            if count >= enoughCount then
                return true
            end
        end
    end
    
    return false
end

--人物是否需要放弃自动拾取
utils.CheckIsPlayerAbandonPickup = function()
    local PickupSpriteProxy         = global.Facade:retrieveProxy( global.ProxyTable.PickupSpriteProxy )
    if not PickupSpriteProxy or not PickupSpriteProxy:getPickupSpriteState() then
        return false
    end
    local mode = PickupSpriteProxy:getPickSpriteMode()
    if mode == 0 or mode == 1 then 
        return false
    end
    return true --模式 2 3 是一个个拾取 需要放弃
end
-- 交易 获取锁的状态
utils.GetLockState = function(noTips)
    local state = SL:GetValue("TRADE_MY_LOCK_STATUS")
    if not noTips and state then
        --请解锁后操作提示
        SL:onLUAEvent(LUA_EVENT_TRADE_UNLOCK_OPERATION)
    end
    return state
end

function utils:GetFixItemDrug()
    for _, v in ipairs( SL:GetValue("GAME_DATA","fixItemDrug") ) do
        local itemData = QuickUseData.GetQuickUseDataByIndex(v)
        if itemData and itemData[1] then
            return itemData[1]
        end

        local itemData = BagData.GetItemDataByItemIndex(v)
        if itemData and itemData[1] then
            return itemData[1]
        end
    end
    return nil
end

-- 是否能挖肉
function utils:checkDigEnable(target, mainPlayer)
    return GUIFunction:CheckTargetDigAble(target:GetID())
end

--英雄选中的目标是否能锁定
function utils:CheckHeroLockTargetEnable(target)
    return utils.CheckLaunchTargetByID(target:GetID())
end

--内挂 范围内是否有足够怪物 不拾取 
function utils:CheckIsEnoughMonster(target)
    local values
    local EnoughCount =  1
    local distance = 1
    values =  GET_SETTING(global.MMO.SETTING_IDX_N_RANGE_NO_PICK,true)
    distance = tonumber(values[2]) or 0
    local enable = values[1] and values[1] == 1 
    if not enable then 
        return false
    end

    local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
    return utils.CheckIsEnoughEnemy(mainPlayerID,EnoughCount,distance)
end

return utils
