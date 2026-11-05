local netActorController = class("netActorController")
netActorController.NAME = "netActorController"

local SharedT = {}

-- 是否死亡
local function ActorIsDie(actor)
    return actor:IsDie() or actor:IsDeath()    
end

-- 状态队列
local ACTION_CACHE      = 
{
    WALK                = 1,    -- 走
    RUN                 = 2,    -- 跑
    RIDE_RUN            = 3,    -- 坐骑 跑
    STUCK               = 4,    -- 受击
    SKILL_ACTION        = 5,    -- 魔法 纯动作
    SKILL_MAGIC         = 6,    -- 魔法 纯魔法 -- 无用
    SKILL_ACTION_MAGIC  = 7,    -- 魔法 动作 + 魔法
    DASH                = 8,    -- 野蛮
    ONDASH              = 9,    -- 被野蛮，被推开
    SBYS                = 10,   -- 十步一杀
    QLS                 = 11,   -- 擒龙手 
    SNEAK               = 12,   -- 潜行
    ZXC                 = 27,   -- 追心刺 
}

local ACTION_CACHE_FUNC = {
    [ACTION_CACHE.STUCK] = function (actor)
        actor:SetAction(global.MMO.ACTION_STUCK)
        return false
    end,
    [ACTION_CACHE.WALK] = function (actor, data)
        actor:SetMoveTo(data.posX, data.posY)
        actor:SetAction(global.MMO.ACTION_WALK, false, true)
        actor:SetConfirmed(true)
        return false
    end,
    [ACTION_CACHE.SNEAK] = function (actor, data)
        actor:SetMoveTo(data.posX, data.posY)
        actor:SetAction(global.MMO.ACTION_ASSASSIN_SNEAK)
        actor:SetConfirmed(true)
        return false
    end,
    [ACTION_CACHE.RUN] = function (actor, data)
        actor:SetMoveTo(data.posX, data.posY)
        actor:SetAction(global.MMO.ACTION_RUN, false, true)
        actor:SetConfirmed(true)
        return false
    end,
    [ACTION_CACHE.RIDE_RUN] = function (actor, data)
        actor:SetMoveTo(data.posX, data.posY)
        actor:SetAction(global.MMO.ACTION_RIDE_RUN, false, true)
        actor:SetConfirmed(true)
        return false
    end,
    [ACTION_CACHE.SKILL_ACTION] = function (actor, data)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:actorEnterAction(data.jsonData, data.isMagic)
        SkillProxy:requestSkillPresent(data.jsonData, 1)
        if data.skillStage == 2 then
            SkillProxy:requestSkillPresent(data.jsonData, 2)
        end
        actor.skillStage = data.skillStage
        actor.skillID = data.jsonData.MagicID
        return false
    end,
    [ACTION_CACHE.SKILL_ACTION_MAGIC] = function (actor, data)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:actorEnterAction(data.jsonData, data.isMagic)
        SkillProxy:requestSkillPresent(data.jsonData, 3)
        return false
    end,
    [ACTION_CACHE.DASH] = function (actor, data)
        local msgHdr    = data.msgHdr
        local mapX      = msgHdr.t1
        local mapY      = msgHdr.t2
        local dir       = msgHdr.t3
        local time      = msgHdr.t4 * 0.001
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and time > 0 then
            G_ActorUtils.ActorDash(actor, mapX, mapY, dir, time)
            return false
        end
        return true
    end,
    [ACTION_CACHE.ONDASH] = function (actor, data)
        local msgHdr   = data.msgHdr
        local mapX     = msgHdr.t1
        local mapY     = msgHdr.t2
        local dir      = msgHdr.t3
        local time     = msgHdr.t4
        local moveTime = L16Bit(time) * 0.001
        local idleTime = math.min(H16Bit(time) * 0.001, 5)
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and moveTime > 0 then
            G_ActorUtils.ActorOnDash(actor, mapX, mapY, dir, moveTime, idleTime)
            return false
        end
        return true
    end,
    [ACTION_CACHE.SBYS] = function (actor, data)
        local msgHdr    = data.msgHdr
        local mapX      = msgHdr.X
        local mapY      = msgHdr.Y
        local dir       = msgHdr.Dir
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) then
            G_ActorUtils.ActorSBYS(actor, mapX, mapY, dir)
            return false
        end
        return true
    end,
    [ACTION_CACHE.QLS] = function (actor, data)
        local msgHdr    = data.msgHdr
        local mapX      = msgHdr.X
        local mapY      = msgHdr.Y
        local dir       = msgHdr.Dir
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) then
            G_ActorUtils.ActorQLS(actor, mapX, mapY, dir)
            return false
        end
        return true
    end,
    [ACTION_CACHE.ZXC] = function (actor, data)
        local msgHdr    = data.msgHdr
        local mapX      = msgHdr.t1
        local mapY      = msgHdr.t2
        local dir       = msgHdr.t3
        local time      = msgHdr.t4 * 0.001
        if ((mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY())) and time > 0 then
            G_ActorUtils.ActorZhuiXinCi(actor, mapX, mapY, dir, time)
            return false
        end
        return true
    end
}

function netActorController:ctor()
    self.mHandleOnActBegin = {}
    self.mHandleOnActCompleted = {}

    self.mHandleBeginN = 0
    self.mHandleCompletedN = 0

    self.mNextActionCache = {}
end

function netActorController:destory()
end

function netActorController:Init()
end

function netActorController:Cleanup()
    self.mNextActionCache = {}
end

-----------------------------------------------------------------------------
function netActorController:AddHandleOnActCompleted(func)
    self.mHandleCompletedN = self.mHandleCompletedN + 1
    self.mHandleOnActCompleted[self.mHandleCompletedN] = func
end

function netActorController:AddHandleOnActBegin(func)
    self.mHandleBeginN = self.mHandleBeginN + 1
    self.mHandleOnActBegin[self.mHandleBeginN] = func
end

-----------------------------------------------------------------------------
function netActorController:handleActionBegin(actor, act)
    -- Action begin handle.
    for i = 1, self.mHandleBeginN do
        self.mHandleOnActBegin[i](actor, act)
    end
end

function netActorController:handleActionCompleted(actor, act)
    -- Action completion handle.
    for i = 1, self.mHandleCompletedN do
        self.mHandleOnActCompleted[i](actor, act)
    end

    --重置加速
    if actor:GetIsSpeedup() then
        actor:SetIsSpeedup(false)
        actor:DirtyAnimFlag()
    end
    if actor:GetIsFullSpeedup() then
        actor:SetIsFullSpeedup(false)
        actor:DirtyAnimFlag()
    end
    if actor:GetIsMoreSpeedRate() then
        actor:SetIsMoreSpeedRate(false)
        actor:DirtyAnimFlag()
    end
    if actor:GetIsMoreFullSpeedup() then
        actor:SetIsMoreFullSpeedup(false)
        actor:DirtyAnimFlag()
    end

    --确认
    actor:SetConfirmed(true)

    -- 
    local toIdleAction = false
    local nextActionCache = self.mNextActionCache[actor:GetID()]
    if nextActionCache and nextActionCache[1] then
        local nextAction = table.remove(nextActionCache, 1)
        if nextActionCache[1] ~= nil and nextActionCache[1].act ~= ACTION_CACHE.STUCK then
            actor:SetIsSpeedup(true)
            actor:SetIsMoreSpeedRate(CHECK_SETTING(global.MMO.SETTING_IDX_MORE_FAST) == 1)

            -- 堆积的太多，更快的加速
            if nextActionCache[2] ~= nil and nextActionCache[3] ~= nil then
                actor:SetIsFullSpeedup(true)
                actor:SetIsMoreFullSpeedup(CHECK_SETTING(global.MMO.SETTING_IDX_MORE_FAST) == 1)
            end
        end

        local cacheFunc = ACTION_CACHE_FUNC[nextAction.act]
        if cacheFunc then
            toIdleAction = cacheFunc(actor, nextAction)
        else
            toIdleAction = true
        end
    elseif act == global.MMO.ACTION_DIE or act == global.MMO.ACTION_DEATH or act == global.MMO.ACTION_CAVE then
    else
        toIdleAction = true
    end

    -- 切换至待机
    if toIdleAction then
        --移动优化
        if act == global.MMO.ACTION_WALK or act == global.MMO.ACTION_RUN or act == global.MMO.ACTION_RIDE_RUN or act == global.MMO.ACTION_ASSASSIN_SNEAK then
            actor:setPosition(actor.mTargePosX, actor.mTargePosY)
        end
        actor:SetAction(global.MMO.ACTION_IDLE)
    end
end

function netActorController:handleActionProcess(actor)
end

-----------------------------------------------------------------------------
function netActorController:handleActorOutOfView(actor)
    self.mNextActionCache[actor:GetID()] = nil
end

function netActorController:handle_Die(actor, msgHdr)
    self:SyncLatestPosition(actor, false)
    self.mNextActionCache[actor:GetID()] = nil

    -- 死亡时不拉坐标了，会闪现
    global.actorManager:SetActorMapXY(actor, msgHdr.X, msgHdr.Y)
    actor:StopAnimToFrame(nil)
    actor:SetAction(global.MMO.ACTION_DIE, true)
end

function netActorController:handle_DeathSkeleton(actor, msgHdr)
    self:SyncLatestPosition(actor, false)
    self.mNextActionCache[actor:GetID()] = nil

    -- 死亡时不拉坐标了，会闪现
    global.actorManager:SetActorMapXY(actor, msgHdr.X, msgHdr.Y)
    actor:StopAnimToFrame(nil)
    actor:SetAction(global.MMO.ACTION_DEATH, true)
end

function netActorController:handle_Revive(actor, jsonData)
    self.mNextActionCache[actor:GetID()] = nil

    -- feature
    if jsonData.curHP and jsonData.maxHP then
        actor:SetCurAbilByID(GUIDefine.AttTypeTable.HP, jsonData.curHP)
        actor:SetMaxAbilByID(GUIDefine.AttTypeTable.HP, jsonData.maxHP)
        actor:RefHPHUD()
    end

    -- To map grid position
    local wX, wY = global.sceneManager:MapPos2WorldPos(jsonData.X, jsonData.Y, true)
    local action = actor:IsMonster() and global.MMO.ACTION_BORN or global.MMO.ACTION_IDLE

    actor:SetConfirmed(true)
    actor:SetIsArrived(true)
    actor:StopAnimToFrame(nil)
    actor:setPosition(wX, wY)
    actor:SetDirection(jsonData.Dir)
    actor:SetAction(action, true)
    actor:DirtyAnimFlag()
    global.actorManager:SetActorMapXY(actor, jsonData.X, jsonData.Y)

    local actorID = jsonData.actorID
    global.Facade:sendNotification(global.NoticeTable.ActorRevive, actorID)

    -- 
    SharedT.actorID = actorID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_REVIVE, SharedT)
end

function netActorController:handleActorSitdown(actor, Dir)
    if ActorIsDie(actor) then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetDirection(Dir)
        actor:SetAction(global.MMO.ACTION_SITDOWN)
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.SITDOWN, Dir = Dir}
    end
end

function netActorController:handleActorMining(actor, Dir)
    if ActorIsDie(actor) then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetDirection(Dir)
        actor:SetAction(global.MMO.ACTION_MINING)
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.MINING, Dir = Dir}
    end
end

function netActorController:handle_MSG_SC_ACTOR_WALK(actor, moveData)
    if ActorIsDie(actor) then
        return nil
    end

    -- 最后一步数据
    local x = moveData.X
    local y = moveData.Y

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        local act = global.MMO.ACTION_WALK
        if actor:GetValueByKey(global.MMO.ACT_SNEAK) then
            act = global.MMO.ACTION_ASSASSIN_SNEAK
        end

        actor:SetMoveTo(x, y)
        actor:SetAction(act)
        actor:SetConfirmed(true)
    else
        -- Another action is running
        local act = ACTION_CACHE.WALK
        if actor:GetValueByKey(global.MMO.ACT_SNEAK) then
            act = ACTION_CACHE.SNEAK
        end

        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = act, posX = x, posY = y}
    end
end

function netActorController:handle_MSG_SC_ACTOR_RUN(actor, moveData)
    if ActorIsDie(actor) then
        return nil
    end

    local x = moveData.X
    local y = moveData.Y

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetMoveTo(x, y)
        actor:SetAction(global.MMO.ACTION_RUN)
        actor:SetConfirmed(true)
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.RUN, posX = x, posY = y}
    end
end

function netActorController:handle_MSG_SC_ACTOR_RIDE_RUN(actor, moveData)
    if ActorIsDie(actor) then
        return nil
    end

    local x = moveData.X
    local y = moveData.Y

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetMoveTo(x, y)
        actor:SetAction(global.MMO.ACTION_RIDE_RUN)
        actor:SetConfirmed(true)
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.RIDE_RUN, posX = x, posY = y}
    end
end

function netActorController:handle_MSG_SC_ACTOR_STUCK(actor)
    if ActorIsDie(actor) then
        return nil
    end

    -- 受击弯腰，只保留一个
    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetAction(global.MMO.ACTION_STUCK)
    else
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}

        -- 有受击直接返回
        for _, v in ipairs(self.mNextActionCache[actorID]) do
            if v.act == ACTION_CACHE.STUCK then
                return
            end
        end

        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.STUCK}
    end
end

function netActorController:handle_MSG_SC_NET_PLAYER_ATTACK(actor, jsonData)
    if ActorIsDie(actor) then
        return nil
    end

    if actor:IsMonster() and jsonData.IsHaveLaunchAct > 0 then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:actorEnterAction(jsonData, false)
        SkillProxy:requestSkillPresent(jsonData, 3)
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.SKILL_ACTION_MAGIC, jsonData = jsonData, isMagic = false}
    end
end

function netActorController:handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS(actor, jsonData)
    if ActorIsDie(actor) then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:actorEnterAction(jsonData, true)
        SkillProxy:requestSkillPresent(jsonData, 1)
        actor.skillStage = 1
        actor.skillID = jsonData.MagicID
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.SKILL_ACTION, jsonData = jsonData, isMagic = true, skillStage = 1}
    end
end

function netActorController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, jsonData)
    if ActorIsDie(actor) then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:requestSkillPresent(jsonData, 2)

    elseif (global.MMO.ACTION_ATTACK == actor:GetAction() or global.MMO.ACTION_SKILL == actor:GetAction() or G_ActorUtils.CheckInSkillAction(actor:GetAction())) and actor.skillStage == 1 and actor.skillID == jsonData.MagicID then
        actor.skillStage = 2
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:requestSkillPresent(jsonData, 2)
    else
        -- Another action is running
        if jsonData.ShowSkillMagic then
            local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
            SkillProxy:requestSkillPresent(jsonData, 3)
        else
            for i, v in ipairs(self.mNextActionCache[actor:GetID()] or {}) do
                if v.act == ACTION_CACHE.SKILL_ACTION and v.skillStage == 1 then
                    v.jsonData = jsonData
                    v.skillStage = 2
                    break
                end
            end
        end
    end
end

-- 野蛮
function netActorController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local mapX    = msgHdr.t1
    local mapY    = msgHdr.t2
    local dir     = msgHdr.t3
    local time    = msgHdr.t4 * 0.001
    local skillID = msgHdr.t5 or 0

    if skillID == global.MMO.SKILL_INDEX_ZXC then 
        if global.MMO.ACTION_IDLE == actor:GetAction() then
            if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and time > 0 then
                G_ActorUtils.ActorZhuiXinCi(actor, mapX, mapY, dir)
            end
        else
            -- Another action is running
            local actorID = actor:GetID()
            self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
            self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.ZXC, msgHdr = msgHdr}
        end
    else
        if global.MMO.ACTION_IDLE == actor:GetAction() then
            if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and time > 0 then
                G_ActorUtils.ActorDash(actor, mapX, mapY, dir, time)
            else
                --执行野蛮失败撞墙动作
                actor:SetAction(global.MMO.ACTION_DASH_FAIL)
            end        
        else
            if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and time > 0 then
                -- Another action is running
                local actorID = actor:GetID()
                self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
                
                -- 野蛮： 立即释放技能， 不需要上个动作完成即能释放
                local cacheCount = #self.mNextActionCache[actorID]
                if cacheCount > 0 then
                    table.remove(self.mNextActionCache[actorID], cacheCount)
                    cacheCount = cacheCount - 1
                end

                if cacheCount == 0 then
                    G_ActorUtils.ActorDash(actor, mapX, mapY, dir, time)
                else
                    self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.DASH, msgHdr = msgHdr}
                end
            end
        end
    end 
end

-- 被野蛮，被推开
function netActorController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local mapX      = msgHdr.t1
    local mapY      = msgHdr.t2
    local dir       = msgHdr.t3
    local mTime     = msgHdr.t4
    local iTime     = msgHdr.t5

    local moveTime = mTime * 0.001
    local idleTime = math.min(iTime * 0.001, 5)

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) and moveTime > 0 then
            G_ActorUtils.ActorOnDash(actor, mapX, mapY, dir, moveTime, idleTime)
        end
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.ONDASH, msgHdr = msgHdr}
    end
end

-- 十步一杀 瞬移
function netActorController:handle_MSG_SC_PLAYER_SKILL_82_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local dir  = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        if(mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) then
            G_ActorUtils.ActorSBYS(actor, mapX, mapY, dir)
        end
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.SBYS, msgHdr = msgHdr}
    end
end

-- 擒龙手 瞬移
function netActorController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local dir  = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        if (mapX ~= actor:GetMapX() or mapY ~= actor:GetMapY()) then
            G_ActorUtils.ActorQLS(actor, mapX, mapY, dir)
        end
    else
        -- Another action is running
        local actorID = actor:GetID()
        self.mNextActionCache[actorID] = self.mNextActionCache[actorID] or {}
        self.mNextActionCache[actorID][#self.mNextActionCache[actorID] + 1] = {act = ACTION_CACHE.QLS, msgHdr = msgHdr}
    end
end

function netActorController:handle_Move_Force(actor, jsonData)
    self.mNextActionCache[actor:GetID()] = nil

    local wX, wY = global.sceneManager:MapPos2WorldPos(jsonData.mapX, jsonData.mapY, true)
    actor:SetAction(global.MMO.ACTION_IDLE, true)
    actor.mIsArrived = true
    actor.mIsConfirmed = true
    actor:SetDirection(jsonData.dir)
    actor:setPosition(wX, wY)

    global.actorManager:SetActorMapXY(actor, jsonData.mapX, jsonData.mapY)
end

function netActorController:handle_FlyIn(actor, msgHdr)
    self.mNextActionCache[actor:GetID()] = nil

    local mapX = msgHdr.X
    local mapY = msgHdr.Y
    local dir  = msgHdr.Dir
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    actor:SetAction(global.MMO.ACTION_IDLE, true)
    actor:SetIsArrived(true)
    actor:SetConfirmed(true)    
    actor:SetDirection(dir)
    actor:setPosition(wX, wY)

    global.actorManager:SetActorMapXY(actor, mapX, mapY)
end

function netActorController:handle_FlyIn2(actor, msgHdr)
    self.mNextActionCache[actor:GetID()] = nil

    local mapX = msgHdr.X
    local mapY = msgHdr.Y
    local dir  = msgHdr.Dir
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    actor:SetAction(global.MMO.ACTION_IDLE, true)
    actor:SetIsArrived(true)
    actor:SetConfirmed(true)    
    actor:SetDirection(dir)
    actor:setPosition(wX, wY)

    global.actorManager:SetActorMapXY(actor, mapX, mapY)
end

function netActorController:cleanupCacheByActorID(actorID)
    self.mNextActionCache[actorID] = nil
end

function netActorController:SyncLatestPosition(actor, updateCurrPosition)
    local p1 = self.mNextActionCache[actor:GetID()]
    if p1 == nil then p1 = {} end
    local lastMoveAct = nil

    for k, v in pairs(p1) do
        local netAct = v
        if ACTION_CACHE.WALK == netAct.act or ACTION_CACHE.RUN == netAct.act or ACTION_CACHE.RIDE_RUN == netAct.act then
            lastMoveAct = netAct
        end
    end

    if lastMoveAct then
        local mapX = lastMoveAct.posX
        local mapY = lastMoveAct.posY
        local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
        actor:setPosition(wX, wY)
        global.actorManager:SetActorMapXY(actor, mapX, mapY)

    elseif updateCurrPosition then
        if actor.mCurrentActT > 0.0001 then
            actor:SetCurrActTime(0)
            local mapX = actor:GetMapX()
            local mapY = actor:GetMapY()
            local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
            actor:setPosition(wX, wY)
        end
    end

    -- reset state
    actor:SetIsArrived(true)
    actor:SetConfirmed(true)
end

function netActorController:handle_ActorMapXYChange(actor, mapX, mapY)
    global.Facade:sendNotification(global.NoticeTable.ActorMapXYChange, { actor = actor, actorID = actor:GetID() })
end

function netActorController:handle_MSG_SC_NET_MONSTER_BORN(actor, msgHdr, msgData)
end

function netActorController:handle_MSG_SC_NET_MONSTER_CAVE(actor, msgHdr, msgData)
end

function netActorController:handle_MSG_SC_NET_ACTOR_TURN(actor, jsonData)
    actor:SetDirection(jsonData.Dir)
    actor:DirtyAnimFlag()
end

return netActorController