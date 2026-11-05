local RemoteProxy = requireProxy("RemoteProxy")
local AutoProxy   = class("AutoProxy", RemoteProxy)
AutoProxy.NAME    = global.ProxyTable.AutoProxy

local ResetFightInterval = 2                            -- reset _tryExitFight 时间间隔

local BehaviorConfig    = global.BehaviorConfig
local proxyUtils = requireUtil("proxyUtils")

local function init_target()
    local target =
    {
        x           = nil,
        y           = nil,
        mapID       = nil,
        targetIndex = global.MMO.AUTO_FIND_TARGET_NONE, -- current auto fight target type_index
        targetType  = global.MMO.ACTOR_NONE, -- current auto fight target type
        autoMoveType= global.MMO.AUTO_MOVE_TYPE_TARGET,
    }

    return target
end

function AutoProxy:ctor()
    AutoProxy.super.ctor(self)

    local Queue                 = requireUtil("queue")

    ----------- state ------------------------
    self._afkState              = false                             -- 是否在挂机状态
    self._randStoneAFKFlag      = false                             -- 随机石否继续挂机状态 

    self._pickState             = false                             -- 是否自动捡物状态
    
    self._fightState            = false                             -- 是否自动战斗
    self._moveState             = false                             -- 是否自动寻路
    self._lockState             = false                             -- 是否锁定目标

    self._inputPriority         = global.MMO.INPUT_PRIORITY_SYSTEM  -- input priority
    ------------------------------------------

    ----------- move queue ------------------
    self._moveQueue             = Queue.new()                       -- move queue
    ------------------------------------------

    ----------- auto fight state -------------
    self._target                = init_target()                     -- trace current target( index/type/priority/pos...)
    self._interruptFlag         = false                             -- interrupt flag
    self._tryExitFight          = 0                                 -- try to exit auto fight
    self._findTargetState       = global.MMO.AUTO_TARGET_STATE_END  -- find target state
    self._afkTargetDeath        = false                               
    ------------------------------------------

    ----------- auto pick target -------------
    self._pickFlag              = false                             -- 是否有掉落物
    self._pickItemID            = nil                               -- current pick item ID
    self._pickBeginT            = nil                               -- current pick begin time
    ------------------------------------------

    ----------- launch first -----------------
    self._launchFirstSkillID    = nil                               -- 下次自动释放技能 优先释放的skillID
    self._launchFirstPosX       = nil
    self._launchFirstPosY       = nil
    self._launchFirstStamp      = nil
    ------------------------------------------

    ---------- launch lock skill -------------
    self._launchAutoLockSkillID = nil
    ------------------------------------------

    ---------- launch avoid skill ------------
    self._launchAvoidStamp      = 0
    ------------------------------------------
    
    ---------- auto mining -------------------
    self._autoMiningDir         = nil                               -- 自动挖矿
    self._autoMiningDstX        = nil                               -- 自动挖矿
    self._autoMiningDstY        = nil
    ------------------------------------------

    ----------- launch du -------------------
    self._duTimes               = 0                                 -- 施毒次数
    self._duStamp               = nil                               -- 检测结束时间戳 
    ------------------------------------------
end

function AutoProxy:GetAutoInputPriority()
    return self._inputPriority
end

function AutoProxy:SetAutoInputPriority(type)
    self._inputPriority = type
end


----------- auto move -------------
function AutoProxy:IsAutoMoveState()
    return self._moveState
end

function AutoProxy:SetIsAutoMoveState(state)
    self._moveState = state
end

function AutoProxy:GetMoveQueueSize()
    return self._moveQueue:size()
end

-- queue back
function AutoProxy:PushMove(pos)
    self._moveQueue:push(pos)
end

function AutoProxy:PopMove()
    if self._moveQueue:empty() then
        return nil
    end
    return self._moveQueue:pop()
end

function AutoProxy:IsMoveCompleted()
    return self._moveQueue:empty()
end

function AutoProxy:ClearAutoMove()
    self:SetIsAutoMoveState(false)
    self._moveQueue:clear()
end
----------- auto move end -------------

----------- auto fight -------------
function AutoProxy:IsAFKState()
    return self._afkState
end

function AutoProxy:SetIsAFKState(state)
    self._afkState = state
    
    local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
    DataTrackProxy:OnExpandInfoChanage()
end

function AutoProxy:ClearAFKState()
    if self:IsAFKState() then
        self:SetIsAFKState(false)
        self:RequestNoticeIntteruptAFK()
        
        SLBridge:onLUAEvent(LUA_EVENT_AFKEND)
    end
end

function AutoProxy:IsPickState()
    return self._pickState
end

function AutoProxy:SetIsPickState(state)
    self._pickState = state

    if self._pickState then
        SLBridge:onLUAEvent(LUA_EVENT_AUTOPICKBEGIN)
    end
end

function AutoProxy:ClearPickState()
    if self:IsPickState() then
        self:SetIsPickState(false)
        SLBridge:onLUAEvent(LUA_EVENT_AUTOPICKEND)
    end
end

function AutoProxy:GetRandStoneAFKFlag()
    return self._randStoneAFKFlag
end

function AutoProxy:SetRandStoneAFKFlag(flag)
    self._randStoneAFKFlag = flag
    
    if self._randStoneTimerID then
        UnSchedule(self._randStoneTimerID)
        self._randStoneTimerID = nil
    end
    if self._randStoneAFKFlag then
        self._randStoneTimerID = PerformWithDelayGlobal(function()
            self._randStoneAFKFlag = false
            self._randStoneTimerID = nil
        end, 2)
    end
end

function AutoProxy:IsAutoFightState()
    return self._fightState
end

function AutoProxy:SetIsAutoFightState(state)
    if self._fightState == state then
        return
    end

    self._fightState = state
end

function AutoProxy:SetTargetType(t)
    self._target.targetType = t
end

function AutoProxy:GetTargetType()
    return self._target.targetType
end

function AutoProxy:SetTargetIndex(index)
    self._target.targetIndex = index
end

function AutoProxy:GetTargetIndex()
    return self._target.targetIndex
end

function AutoProxy:SetTargetState(state)
    self._findTargetState = state
end

function AutoProxy:GetTargetState()
    return self._findTargetState
end

function AutoProxy:SetAFKTargetDeath(t)
    self._afkTargetDeath = t
    
    if self._afkTargetDeath then
        -- 挂机目标死亡
        if self._afkTargetDeathScheduleID then
            UnSchedule(self._afkTargetDeathScheduleID)
            self._afkTargetDeathScheduleID = nil
        end
        self._afkTargetDeathScheduleID = PerformWithDelayGlobal(function()
            self._afkTargetDeath = false
        end, 0.2)
    end
end

function AutoProxy:GetAFKTargetDeath()
    return self._afkTargetDeath
end

function AutoProxy:GetAutoTarget()
    return self._target
end

function AutoProxy:SetAutoTarget(target)
    if target then
        self._target.x              = target.x
        self._target.y              = target.y
        self._target.mapID          = target.mapID
        self._target.targetType     = target.targetType
        self._target.targetIndex    = target.targetIndex
        self._target.priority       = target.priority
        self._target.state          = target.state
        self._target.autoMoveType   = target.autoMoveType
    else
        self._target = init_target()
    end
end

function AutoProxy:SetAutoTargetInterruptFlag(flag)
    self._interruptFlag = flag
end

function AutoProxy:GetAutoTargetInterruptFlag()
    return self._interruptFlag
end

function AutoProxy:PauseAutoTarget()
    if self:GetAutoTargetInterruptFlag() then
        return
    end

    -- clone target
    local oldAutoTarget = self:GetAutoTarget()
    local autoTarget = clone(oldAutoTarget)
    oldAutoTarget.isPauseAutoTarget = true

    self:ClearAllState()

    self:SetAutoTarget(autoTarget)
    self:SetAutoTargetInterruptFlag(true)
end

function AutoProxy:ResumeAutoTarget()
    if not self:GetAutoTargetInterruptFlag() then
        return
    end

    self:SetAutoTargetInterruptFlag(false)

    local autoTarget = clone(self:GetAutoTarget())
    if autoTarget then
        if autoTarget.x and autoTarget.y then
            global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, autoTarget)
        elseif autoTarget.targetType ~= global.MMO.ACTOR_NONE then
            global.Facade:sendNotification(global.NoticeTable.AutoFightBegin, autoTarget)
        end
    end
end

function AutoProxy:IsTargetTypePickEnable(targetType)
    if targetType == nil then
        targetType = self:GetTargetType()
    end

    -- 开始自动寻找NPC时，不再处罚自动拾取
    local currType = self:GetTargetType()
    if currType == global.MMO.ACTOR_NPC then
        local state = self:GetTargetState()
        return state ~= global.MMO.AUTO_TARGET_STATE_RUNNING
    end

    return targetType ~= global.MMO.ACTOR_COLLECTION
end

function AutoProxy:IsTargetTypeLaunchEnable()
    local targetType = self:GetTargetType()
    return (targetType == global.MMO.ACTOR_MONSTER or targetType == global.MMO.ACTOR_PLAYER) -- 目标为 怪、人
end

function AutoProxy:TryExitAutoFight()
    if self:IsAutoFightState() then
        if self:IsTargetTypeLaunchEnable() then
            self:TimerBegan()
            self._tryExitFight = self._tryExitFight + 1
            if self._tryExitFight >= 2 then
                self:TimerEnded()
                global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
                global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
                self:ClearAutoLock()
                self:ClearAllState()
                self:ClearAFKState()
                self:ClearPickState()
                return true

            else
                return false

            end

        else
            if self:IsAutoFightState() then
                global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
                global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
                self:ClearAutoLock()
                self:ClearAllState()
                self:ClearAFKState()
                self:ClearPickState()
            end
        end
    end

    return true
end

function AutoProxy:TimerBegan()
    if not self._exitFightTimerID then
        local function callback(delta)
            self._tryExitFight = 0
            self:TimerEnded()
        end

        self._exitFightTimerID = Schedule(callback, ResetFightInterval)
    end
end

function AutoProxy:TimerEnded()
    if self._exitFightTimerID then
        UnSchedule(self._exitFightTimerID)
        self._exitFightTimerID = nil
    end
end

function AutoProxy:ClearAutoTarget()
    self:SetIsAutoFightState(false)
    self:SetAutoTargetInterruptFlag(false)
    self:SetAutoInputPriority(global.MMO.INPUT_PRIORITY_SYSTEM)
    self:SetTargetState(global.MMO.AUTO_TARGET_STATE_END)
    self:SetAutoTarget(nil)

    self:TimerEnded()
    self._tryExitFight = 0
end

function AutoProxy:ClearAllState()
    if self:IsAutoMoveState() then
        global.Facade:sendNotification(global.NoticeTable.AutoMoveEnd)
    end

    if self:IsAutoFightState() then
        global.Facade:sendNotification(global.NoticeTable.AutoFightEnd)
    end
end
----------- auto fight end -------------

----------- auto pick -------------
function AutoProxy:IsCanAutoPick(targetType)
    return self:GetPickItemFlag() and self:IsTargetTypePickEnable(targetType)
end

function AutoProxy:GetPickItemFlag()
    return self._pickFlag
end

function AutoProxy:SetPickItemFlag(state)
    self._pickFlag = state
end

function AutoProxy:SetPickItemID(id)
    self._pickItemID = id
end

function AutoProxy:GetPickItemID()
    return self._pickItemID
end

function AutoProxy:SetPickBeginTime(t)
    self._pickBeginT = t
end

function AutoProxy:GetPickBeginTime()
    return self._pickBeginT
end

function AutoProxy:CheckPickTimeout()
    local lastPickTime = self:GetPickBeginTime()
    local currTime = GetServerTime()
    -- if pick time to long, discard current pick item
    if not lastPickTime then
        self:SetPickBeginTime(currTime)
    else
        if currTime - lastPickTime >= 3 then
            local itemID = self:GetPickItemID()
            local item = global.dropItemManager:FindOneDropItemByID(self:GetPickItemID())
            if item then
                item:SetPickTimeout()
            end

            self:SetPickItemID(nil)
            self:SetPickBeginTime(currTime)
        end
    end
end

function AutoProxy:ClearAutoPick()
    self:SetPickItemFlag(false)
    self:SetPickItemID(nil)
    self:SetPickBeginTime(nil)
end

-- 处理掉落物被阻挡忽略三秒后人物挂机移动出视野再无法拾取
function AutoProxy:ForceCheckAutoFindItemBehavior(act, currBehavior)
    if not self:IsAFKState() and not self:IsAutoFightState() then
        return false
    end
    if not self:IsCanAutoPick() then
        return false 
    end

    if SL:GetValue("SELECT_TARGET_ID") then
        return false 
    end

    if not GUIFunction:IsMoveAction(act) then
        return false
    end

    if currBehavior ~= BehaviorConfig.BehaviorType.BehaviorMove then
        return false
    end

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    if inputProxy:GetCurrMoveType() ~= GUIDefine.InputMoveType.AUTOMOVE then
        return false
    end
    releasePrint(string.format("Behavior %s Act %s can force check autoFindItem.", currBehavior, act))

    -- 内挂 范围内是否有足够怪物
    if proxyUtils:CheckIsEnoughMonster() then
        return false
    end

    -- 小精灵 如果是一个个拾取模式  需要放弃去拾取
    if proxyUtils:CheckIsPlayerAbandonPickup() then
        return false
    end

     if not inputProxy:IsMoving() then
        if self:GetPickItemID() then
            self:CheckPickTimeout()
            return true
        end
    end

    if nil == self:GetPickItemID() then
        global.Facade:sendNotification(global.NoticeTable.AutoFindDropItem)
    end

    if -1 == global.PathFindController:CheckNextMovePosAble() then
        self:SetPickItemID(nil)
        return false
    end

    if self:GetPickItemID() then
        return true
    end

    return false
end
----------- auto pick end -------------

----------- auto lock begin -------------
function AutoProxy:IsAutoLockState()
    return self._lockState
end

function AutoProxy:SetIsAutoLockState(state)
    self._lockState = state
end

function AutoProxy:GetAutoLockSkillID()
    return self._launchAutoLockSkillID
end

function AutoProxy:SetAutoLockSkillID(skillID)
    self._launchAutoLockSkillID = skillID
end

function AutoProxy:ClearAutoLock()
    self._lockState            = false
    self._launchAutoLockSkillID = nil
end
----------- auto lock end -------------

----------- launch first skill --------
function AutoProxy:SetLaunchFirstSkill(skillID, destPosX, destPosY)
    self._launchFirstSkillID    = skillID
    self._launchFirstPosX       = destPosX
    self._launchFirstPosY       = destPosY
    self._launchFirstStamp      = GetServerTime()
end

function AutoProxy:GetLaunchFirstSkill()
    return self._launchFirstSkillID, self._launchFirstPosX, self._launchFirstPosY, self._launchFirstStamp
end

function AutoProxy:ClearLaunchFirstSkill()
    self._launchFirstSkillID    = nil
    self._launchFirstPosX       = nil
    self._launchFirstPosY       = nil
    self._launchFirstStamp      = nil
end
----------- launch first skill

function AutoProxy:ResetLaunchAvoidStamp()
    self._launchAvoidStamp      = GetServerTime()
end

function AutoProxy:GetLaunchAvoidStamp()
    return self._launchAvoidStamp
end


----------- auto mining
function AutoProxy:SetAutoMining(dir, dstX, dstY)
    self._autoMiningDir = dir
    self._autoMiningDstX = dstX
    self._autoMiningDstY = dstY
end

function AutoProxy:GetAutoMining()
    return self._autoMiningDir, self._autoMiningDstX, self._autoMiningDstY
end

function AutoProxy:ClearAutoMining()
    self:SetAutoMining(nil, nil, nil)
end

-------------- auto du
function AutoProxy:UpdateDuTime()
    self._duTimes = self._duTimes + 1
    if self._duTimes >= 4 then
        self._duStamp = GetServerTime()
    end
end

function AutoProxy:CheckDu()
    if not self._duStamp then
        return true
    end

    if GetServerTime() - self._duStamp > 5 then
        self:ClearDu()
        return true
    end
    return false
end

function AutoProxy:ClearDu()
    if self._duTimes == 0 then
        return
    end
    self._duTimes = 0
    self._duStamp = nil
end

----------- notice 
function AutoProxy:RequestNoticeIntteruptAFK()
    -- 自动战斗被打断，通知服务器
    LuaSendMsg(global.MsgType.MSG_SC_INTTERUPT_AFK)
end

function AutoProxy:RequestAutoMoveNotify(act, destX, destY, isCrossMap)
    -- 通知服务器自动寻路状态
    if act == global.MMO.AUTO_MOVE_START then
        LuaSendMsg(global.MsgType.MSG_CS_AUTO_MOVE_NOTIFY, act, destX, destY, isCrossMap and 1 or 0)
    else
        LuaSendMsg(global.MsgType.MSG_CS_AUTO_MOVE_NOTIFY, act)
    end
end

function AutoProxy:handle_MSG_SC_AFK(msg)
    local moveTarget = ParseRawMsgToJson(msg)
    print("AFK +++++++++++++++++++++++++++++++++++++++++++")
    dump(moveTarget)

    -- stop auto fight
    global.Facade:sendNotification(global.NoticeTable.AFKEnd)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:ClearLastLaunchMoveFarPos()
    
    -- check param
    if not moveTarget or not next(moveTarget) then
        return nil
    end
    global.Facade:sendNotification(global.NoticeTable.AFKBegin)
end

function AutoProxy:handle_MSG_SC_AUTO_FIND(msg)
    local jsonData = ParseRawMsgToJson( msg )
    -- debug
    print( "auto find+++++++++++++++++++++++++++++++++++++++++++" )
    dump(jsonData)
    if not jsonData or not next(jsonData) then
        releasePrint( "auto find error!, json" )
        return nil
    end

    if jsonData.T == 1 then
        jsonData.autoMoveType = global.MMO.AUTO_MOVE_TYPE_SERVER
    end

    global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, jsonData)
    -- self:SetAutoTarget(jsonData)
end

function AutoProxy:handle_MSG_SC_STOP_AUTO_FIND(msg)
    -- debug
    print( "stop auto find+++++++++++++++++++++++++++++++++++++++++++" )
    
    -- clear current state
    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    self:ClearAllState()
    self:ClearAFKState()
end


function AutoProxy:handle_MSG_SC_MAP_ITEM_PICK_FAIL(msg)
    local header = msg:GetHeader()

    -- case -2:  // 一定时间内无法捡（别人的东西）
    -- case -3:  // 禁止拾取
    -- case -4:  // 背包满
    -- case -5:  // 最多只能拾取X个
    -- case -6:  // 不能捡特定阵营的道具
    if header.recog <= -2 then
        self:SetPickItemID(nil)

        if header.recog == -5 then
            local tips = string.format(GET_STRING(800905), header.param1)
            global.Facade:sendNotification(global.NoticeTable.SystemTips, tips)
        else
            global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(800900 - header.recog))
        end
    end
end


function AutoProxy:handle_MSG_SC_NET_PLAYER_MOVE_FAIL(msg)
    if not self:GetAutoTargetInterruptFlag() then
        if self:IsAutoFightState() or self:IsAutoMoveState() then
            self:PauseAutoTarget()
            self:ResumeAutoTarget()
        end
    end
end


function AutoProxy:handle_MSG_SC_PICKUP_MODE_UPDATE(netPkg)
    local visible = netPkg:GetP0() == 1
    SLBridge:onLUAEvent(LUA_EVENT_MAIN_PICKUP_SHOW, visible)
end


function AutoProxy:handle_MSG_SC_AUTO_MOVE(msg)
    local header = msg:GetHeader()
    local mapX = header.param1
    local mapY = header.param2
    
    print( "auto move ++++++++++++++++++++++++++++++" )
    dump(header)


    local type = header.recog
    if type == 2 then   -- 跨地图寻路
        local mapParam = string.lower(msg:GetBodyStr())
        local moveData = 
        {
            mapID = mapParam,
            x = mapX,
            y = mapY,
            isCrossMapNoPos = mapX == 0 or mapY == 0,
            autoMoveType = global.MMO.AUTO_MOVE_TYPE_SERVER
        }
        global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, moveData)

    else
        if mapX == 0 or mapY == 0 then
            return nil
        end

        -- 开始寻路
        local moveData = 
        {
            x = mapX,
            y = mapY,
            autoMoveType = global.MMO.AUTO_MOVE_TYPE_SERVER
        }
        global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, moveData)
    end

end


function AutoProxy:onRegister()
    AutoProxy.super.onRegister(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_AFK,                   handler(self, self.handle_MSG_SC_AFK))                      -- 自动挂机
    LuaRegisterMsgHandler(msgType.MSG_SC_AUTO_FIND,             handler(self, self.handle_MSG_SC_AUTO_FIND))                -- 自动任务
    LuaRegisterMsgHandler(msgType.MSG_SC_STOP_AUTO_FIND,        handler(self, self.handle_MSG_SC_STOP_AUTO_FIND))           -- 自动任务停止
    LuaRegisterMsgHandler(msgType.MSG_SC_MAP_ITEM_PICK_FAIL,    handler(self, self.handle_MSG_SC_MAP_ITEM_PICK_FAIL))       -- 拾取掉落物失败
    LuaRegisterMsgHandler(msgType.MSG_SC_NET_PLAYER_MOVE_FAIL,  handler(self, self.handle_MSG_SC_NET_PLAYER_MOVE_FAIL))     -- 移动失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PICKUP_MODE_UPDATE,    handler(self, self.handle_MSG_SC_PICKUP_MODE_UPDATE))       -- 拾取模式
    LuaRegisterMsgHandler(msgType.MSG_SC_AUTO_MOVE,             handler(self, self.handle_MSG_SC_AUTO_MOVE))          -- 脚本通知寻路
end


return AutoProxy