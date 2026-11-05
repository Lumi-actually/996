local DebugProxy = requireProxy("DebugProxy")
local PlayerInputProxy = class("PlayerInputProxy", DebugProxy)
PlayerInputProxy.NAME = global.ProxyTable.PlayerInputProxy

local cjson = require("cjson")

function PlayerInputProxy:ctor()
    PlayerInputProxy.super.ctor(self)
    
    self._movePermission = true
    
    ----------- target -------------
    self._targetID          = nil
    self._lastTargetID      = nil
    self._attackState       = false     -- 持续攻击状态 shift锁定
    self._attackTargetID    = nil       -- 持续攻击目标
    self._ownerPlayerID     = nil       -- 目标怪物归属的玩家id
    self._isTraceOwnerPlayer= false     -- 自动追踪归属玩家
    ------------------------------
    
    ----------- move -------------
    self._moveDirty         = false
    self._moveType          = GUIDefine.InputMoveType.OTHER
    self._currMovePos       = nil -- current move to pos
    self._pathFindPoints    = nil
    self._currPathPoint     = 0
    self._isMoveBlocked     = false     -- 寻路被
    self._launchNoWalkPos   = nil       -- 攻击时  走路不可通行的位置(强制刷新阻挡)
    self._userInputMoveDir  = 0
    self._userInputMoveStep = 1
    self._farPathMoveForTarget = false  -- 是否远距离寻路到目标
    self._lastFarPathMovePosX = nil
    self._lastFarPathMovePosY = nil

    ------------------------------

    ----------- skill -------------
    self._launchDirty       = false
    self._skillID           = nil
    self._launchPosX        = nil
    self._launchPosY        = nil
    self._launchTargetID    = nil
    self._launchType        = global.MMO.LAUNCH_TYPE_USER
    self._launchPriority    = global.MMO.LAUNCH_PRIORITY_SYSTEM
    self._clearTimes        = 0
    ------------------------------

    ----------- collection -------------
    self._collectCount      = 0
    ------------------------------

    ----------- dig coprse -------------
    self._coprseID          = nil
    self._digDest           = nil
    ------------------------------------

    ----------- mining -----------------
    self._miningDir         = nil
    self._miningDestX       = nil
    self._miningDestY       = nil
    ------------------------------------
    
    ----------- mouse touch ------------
    self._mouseTouchPos     = nil
    self._mouseTouchWay     = nil
    ------------------------------------
    
    ----------- mouse turn -------------
    self._mouseTurnDir      = global.MMO.ORIENT_INVAILD
    ------------------------------------

    ----------- mouse target ID --------
    self._mouseOverTargetID = nil
    ------------------------------------
end

--------------- util -----------------
function PlayerInputProxy:GetCursorWorldPosition()
    local cursorPos = global.userInputController:GetCursorPos()
    return Screen2World(cursorPos) --return x,y
end

function PlayerInputProxy:GetCursorWorldDirection()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return global.MMO.ORIENT_INVAILD
    end
    local srcX = mainPlayer:getPositionX()
    local srcY = mainPlayer:getPositionY()
    local dstX, dstY = self:GetCursorWorldPosition()
    return G_ActorUtils.CalcWorldDirection(dstX, dstY, srcX, srcY)
end

function PlayerInputProxy:GetCursorMapPosition()
    local cursorPos = global.userInputController:GetCursorPos()
    local worldPosX, worldPosY = Screen2World(cursorPos)
    local mapX, mapY = global.sceneManager:WorldPos2MapPos(worldPosX, worldPosY)
    return mapX, mapY
end

function PlayerInputProxy:GetMainPlayerFaceDest()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return cc.p(0, 0)
    end

    local normalize = G_ActorUtils.DirToNormalizeVec2(mainPlayer:GetDirection())
    return cc.pAdd(cc.p(mainPlayer:GetMapX(), mainPlayer:GetMapY()), normalize)
end

----------------------------------------------------------------
-- move
function PlayerInputProxy:IsMovePermission()
    return self._movePermission
end

function PlayerInputProxy:SetMovePermission(permission)
    self._movePermission = permission
end

--------------------- target ------------------------------
function PlayerInputProxy:SetTargetID(targetID)
    self._lastTargetID  = self._targetID
    self._targetID      = targetID

    self:SetTraceOwnerPlayerState(false)

    global.Facade:sendNotification(global.NoticeTable.TargetChange, {targetID = targetID})
    SLBridge:onLUAEvent(LUA_EVENT_TARGET_CHANGE, targetID)

    -- 记录上次目标
    if (nil == self._targetID) then
        if self._targetScheduleID then
            UnSchedule(self._targetScheduleID)
            self._targetScheduleID = nil
        end
        self._targetScheduleID = PerformWithDelayGlobal(function()
            self._lastTargetID = nil
            self._targetScheduleID = nil
        end, 5)
    end

    -- clear auto lock
    if nil == self._targetID then
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:ClearAutoLock()
        autoProxy:ClearDu()
    end

    local actor    = global.actorManager:GetActor(targetID)
    if not targetID or not actor then
        return
    end
end

function PlayerInputProxy:SetOwnerPlayerID(ID)
    if ID == "" or ID == -1 or ID == global.MMO.ACTOR_ID_INVALID then
        ID = nil
    end

    self._ownerPlayerID = ID

    global.Facade:sendNotification(global.NoticeTable.Layer_Monster_Belong_TargetChange,{targetID=ID or self._targetID})
    SLBridge:onLUAEvent(LUA_EVENT_TARGET_OWNER_CHANGE, self._ownerPlayerID or self._targetID)
end

function PlayerInputProxy:GetOwnerPlayerID()
    return self._ownerPlayerID
end

function PlayerInputProxy:IsTraceOwnerPlayer()
    return self._isTraceOwnerPlayer == true
end

function PlayerInputProxy:SetTraceOwnerPlayerState(state)
    self._isTraceOwnerPlayer = state

    if self._ownerPlayerID then --是否有归属
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        if not mainPlayer then
            return
        end
    
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        AutoProxy:SetIsAutoLockState(true)
    end

    SLBridge:onLUAEvent(LUA_EVENT_TARGET_BELONG_SELECT)
end

function PlayerInputProxy:GetTargetID()
    if self._isTraceOwnerPlayer then
        return self._ownerPlayerID or self._targetID
    end

    return self._targetID
end

function PlayerInputProxy:ClearTarget()
    self:SetTargetID(nil)
end

function PlayerInputProxy:GetLastTargetID()
    return self._lastTargetID
end

function PlayerInputProxy:SetAttackTargetID(targetID)
    self._attackTargetID = targetID
    
    global.Facade:sendNotification(global.NoticeTable.AttackTargetChange, {targetID = targetID})
end

function PlayerInputProxy:GetAttackTargetID()
    return self._attackTargetID
end

function PlayerInputProxy:ClearAttackTargetID()
    self:SetAttackTargetID(nil)
end

function PlayerInputProxy:SetAttackState(state)
    self._attackState = state
end

function PlayerInputProxy:IsAttackState()
    return self._attackState
end
--------------------- target end ------------------------------


--------------------- move ------------------------------
function PlayerInputProxy:SetUserInputMoveDir(dir)
    self._userInputMoveDir = dir
end

function PlayerInputProxy:GetUserInputMoveDir()
    return self._userInputMoveDir
end

function PlayerInputProxy:SetUserInputMoveStep(step)
    self._userInputMoveStep = step
end

function PlayerInputProxy:GetUserInputMoveStep()
    return self._userInputMoveStep
end

function PlayerInputProxy:SetCurrMovePos(pos)
    self._moveDirty = true
    self._currMovePos = pos
end

function PlayerInputProxy:GetCurrMovePos()
    return self._currMovePos
end

function PlayerInputProxy:IsMoveDirty()
    return self._moveDirty
end

function PlayerInputProxy:IsMoving()
    return self:IsMoveDirty() or self:GetCurrPathPoint() > 0
end

function PlayerInputProxy:GetMoveInterruptFlag()
    if not self._currMovePos then
        return false
    end
    
    return self._currMovePos.isInterrupt
end

function PlayerInputProxy:SetMoveInterruptFlag(flag)
    if self._currMovePos then
        self._currMovePos.isInterrupt = flag
    end
end

function PlayerInputProxy:SetCurrMoveType(type)
    self._moveType = type
end

function PlayerInputProxy:GetCurrMoveType()
    return self._moveType
end

function PlayerInputProxy:SetPathFindPoints(points)
    self._pathFindPoints = points
    self._moveDirty = nil
    
    local size = self:GetPathPointSize()
    self:SetCurrPathPoint(size)
    
    if size > 1 then
        -- move begin
        SL:onLUAEvent(LUA_EVENT_MINIMAP_FIND_PATH)
    else
        -- move end
        SL:onLUAEvent(LUA_EVENT_MINIMAP_FIND_PATH)
    end
end

function PlayerInputProxy:GetPathFindPoints()
    return self._pathFindPoints or {}
end

function PlayerInputProxy:GetPathPointSize()
    if self._pathFindPoints then
        return #self._pathFindPoints
    end
    return 0
end

function PlayerInputProxy:SetCurrPathPoint(curr)
    self._currPathPoint = curr
end

function PlayerInputProxy:GetCurrPathPoint()
    return self._currPathPoint
end

function PlayerInputProxy:SetLastLaunchMoveFarPos(x, y)
    self._lastFarPathMovePosX = x
    self._lastFarPathMovePosY = y
end

function PlayerInputProxy:GetLastLaunchMoveFarPos()
    return self._lastFarPathMovePosX, self._lastFarPathMovePosY
end

function PlayerInputProxy:ClearLastLaunchMoveFarPos()
    self._lastFarPathMovePosX = nil
    self._lastFarPathMovePosY = nil
end

function PlayerInputProxy:ClearMove()
    self:SetCurrMoveType(GUIDefine.InputMoveType.OTHER)
    self:SetPathFindPoints(nil)
    
    self._currMovePos = nil
    self._moveDirty = nil
end

function PlayerInputProxy:SetIsMoveBlocked(v)
    self._isMoveBlocked = v
end

function PlayerInputProxy:IsMoveBlocked()
    return self._isMoveBlocked
end

function PlayerInputProxy:SetLaunchNoWalkPos(pos)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return nil
    end

    if self._launchNoWalkPos then
        mapData:setObstacle(self._launchNoWalkPos.x, self._launchNoWalkPos.y, 0)
        self._launchNoWalkPos = nil
    end

    if pos and self._moveType == GUIDefine.InputMoveType.LAUNCH then
        if mapData:isObstacle(pos.x, pos.y) == 0 then
            self._launchNoWalkPos = pos
            mapData:setObstacle(self._launchNoWalkPos.x, self._launchNoWalkPos.y, 1)
        end
    end

end

function PlayerInputProxy:GetLaunchNoWalkPos()
    return self._launchNoWalkPos
end
--------------------- move end------------------------------


--------------------- trun --------------------------------
function PlayerInputProxy:SetMouseTurnDir(dir)
    self._mouseTurnDir = dir
end

function PlayerInputProxy:GetMouseTurnDir()
    return self._mouseTurnDir
end

function PlayerInputProxy:ClearMouseTurnDir()
    self._mouseTurnDir = global.MMO.ORIENT_INVAILD
end

function PlayerInputProxy:RequestActorTurn(dir)
	local mainPlayer = global.gamePlayerController:GetMainPlayer()
	if mainPlayer and dir and dir >= global.MMO.ORIENT_U and dir <= global.MMO.ORIENT_LU then
		local x = mainPlayer:GetMapX()
		local y = mainPlayer:GetMapY()
		local point = y * 65536 + x
		LuaSendMsg(global.MsgType.MSG_CS_MAIN_PLAYER_TURN, point, 0, dir)

        
        local mainPlayerID = mainPlayer:GetID()
        global.BuffManager:UpdateBuffSfxDir(mainPlayerID)
        global.ActorEffectManager:UpdateEffectDir(mainPlayer, mainPlayerID)
	end
end
--------------------- trun --------------------------------


--------------------- skill --------------------------------
function PlayerInputProxy:IsLaunchDirty()
    return self._launchDirty
end

function PlayerInputProxy:ResetLaunchDirty()
    self._launchDirty = false
end

function PlayerInputProxy:GetLaunchPriority()
    return self._launchPriority
end

function PlayerInputProxy:ClearLaunch()
    self._launchDirty       = false
    self._skillID           = nil
    self._launchPosX        = nil
    self._launchPosY        = nil
    self._launchTargetID    = nil
    self._launchPriority    = global.MMO.LAUNCH_PRIORITY_SYSTEM
    self._launchType        = global.MMO.LAUNCH_TYPE_USER
end

function PlayerInputProxy:SetLaunchSkillID(skillID, priority, launchType)
    self._launchDirty       = nil ~= skillID
    self._skillID           = skillID
    self._launchPriority    = priority or global.MMO.LAUNCH_PRIORITY_SYSTEM
    self._launchType        = launchType or global.MMO.LAUNCH_TYPE_USER
end

function PlayerInputProxy:GetLaunchSkillID()
    return self._skillID
end

function PlayerInputProxy:SetLaunchTargetX(x)
    self._launchPosX = x
end

function PlayerInputProxy:SetLaunchTargetY(y)
    self._launchPosY = y
end

function PlayerInputProxy:GetLaunchTargetPos()
    return self._launchPosX, self._launchPosY
end

function PlayerInputProxy:SetLaunchTargetID(id)
    self._launchTargetID = id
end

function PlayerInputProxy:GetLaunchTargetID()
    return self._launchTargetID
end

function PlayerInputProxy:GetLaunchType()
    return self._launchType
end

-------------- clear
function PlayerInputProxy:CheckClearLaunch()
    if self._launchTargetID then
        self:ClearTimerBegan()
        self._clearTimes = self._clearTimes + 1
        if self._clearTimes >= 2 then
            self:ClearTimerEnded()
            if self._currMovePos and self._currMovePos.targetID == self._launchTargetID then
                self:ClearMove()
            end
            self:ClearLaunch()
        end
    end
end

function PlayerInputProxy:ClearTimerBegan()
    if not self._clearTimerID then
        local function callback(delta)
            self:ClearTimerEnded()
        end

        self._clearTimerID = Schedule(callback, 1)
    end
end

function PlayerInputProxy:ClearTimerEnded()
    if self._clearTimerID then
        UnSchedule(self._clearTimerID)
        self._clearTimerID = nil
    end
    self._clearTimes = 0
end
--------------------- skill end ------------------------------


--------------------- collect ------------------------------
function PlayerInputProxy:GetCollectCount()
    return self._collectCount
end

function PlayerInputProxy:AddCollectCount()
    self._collectCount = self._collectCount + 1
end

function PlayerInputProxy:SubCollectCount()
    self._collectCount = self._collectCount - 1
end
--------------------- collect ------------------------------

--------------------- dig corpse --------------------
function PlayerInputProxy:GetCorpseID()
    return self._coprseID
end

function PlayerInputProxy:SetCorpseID(id)
    self._coprseID = id
end

function PlayerInputProxy:ClearCorpse()
    self._coprseID = nil
end

function PlayerInputProxy:GetDigDest()
    return self._digDest
end

function PlayerInputProxy:SetDigDest(dest)
    self._digDest = dest
end

function PlayerInputProxy:ClearDigDest()
    self:SetDigDest(nil)
end

--------------------- mining --------------------
function PlayerInputProxy:CheckMiningAble()
	return GUIFunction:CheckMiningAble()
end

function PlayerInputProxy:GetMiningDir()
    return self._miningDir
end

function PlayerInputProxy:SetMiningDir(dir)
    self._miningDir = dir
end

function PlayerInputProxy:GetMiningDest()
    return self._miningDestX, self._miningDestY
end

function PlayerInputProxy:SetMiningDest(destX, destY)
    self._miningDestX = destX
    self._miningDestY = destY
end

function PlayerInputProxy:ClearMining()
    self._miningDir = nil
    self._miningDestX = nil
    self._miningDestY = nil
end

function PlayerInputProxy:IsLaunchMining(destX, destY)
    if not destX or not destY then
        return false
    end

    local actor = global.actorManager:GetNPCActorByMapXY(destX, destY)
    if actor and actor:IsNPC() then
        return false
    end

    return true
end

--------------------- mouse touch ------------------
function PlayerInputProxy:SetMouseTouchPos(pos)
    self._mouseTouchPos = pos
end

function PlayerInputProxy:GetMouseTouchPos()
    return self._mouseTouchPos
end

function PlayerInputProxy:SetMouseTouchWay(way)
    self._mouseTouchWay = way
end

function PlayerInputProxy:GetMouseTouchWay()
    return self._mouseTouchWay
end

function PlayerInputProxy:ClearMouseTouch()
    self._mouseTouchPos = nil
    self._mouseTouchWay = nil
end

--------------------- collect begin ------------------------------
function PlayerInputProxy:RequestCollect()
    local targetID  = self:GetTargetID()
    if targetID then
        LuaSendMsg(global.MsgType.MSG_CS_COLLECT_REQUEST, 0, 0, 0, 0, targetID, string.len(targetID))
    end
end

function PlayerInputProxy:CompletedCollect()
    local targetID  = self:GetTargetID()
    if targetID then
        LuaSendMsg(global.MsgType.MSG_CS_COLLECT_COMPLETED, 0, 0, 0, 0, targetID, string.len(targetID))
    end
end

function PlayerInputProxy:RequestDigCorpse(dir, id)
    local jsonData      = {}
    jsonData.Dir        = dir
    jsonData.ID         = id
    local jsonStr       = cjson.encode(jsonData)
    LuaSendMsg(global.MsgType.MSG_CS_PICK_CORPSE, 0, 0, 0, 0, jsonStr, string.len(jsonStr))
end

function PlayerInputProxy:handle_MSG_SC_COLLECT_COMPLETED(msg)
    local header = msg:GetHeader()

    if header.pram1 == 1 then --开始采集状态
        SLBridge:onLUAEvent(LUA_EVENT_COLLECT_BEGIN)
    elseif header.param2 == 2 then --结束采集状态
        SLBridge:onLUAEvent(LUA_EVENT_COLLECT_COMPLETED)
    end
end
--------------------- collect end ------------------------------

function PlayerInputProxy:GetMouseOverTargetID()
    return self._mouseOverTargetID
end

function PlayerInputProxy:SetMouseOverTargetID(targetID)
    self._mouseOverTargetID = targetID
end

--------------------- limit move -------------------------------
-- 是否限制移动(与镖车距离超出限制距离)
function PlayerInputProxy:CheckEscortLimitMove(destMapX, destMapY)
    if not destMapX or not destMapY then
        return false
    end
    if self._limitEscortParam and next(self._limitEscortParam) then
        if self._limitEscortParam.distance <= 0 then
            return false
        elseif self._limitEscortParam.id then
            local actor = global.actorManager:GetActor(self._limitEscortParam.id)
            if not actor or not actor:IsEscort() then
                return false
            end
            local distance = self._limitEscortParam.distance
            local tMapX = actor:GetMapX()
            local tMapY = actor:GetMapY()
            if math.abs(destMapX - tMapX) > distance or math.abs(destMapY - tMapY) > distance then
                return true
            end
        end
    end
    return false
end

function PlayerInputProxy:GetLimitEscortDistance()
    return self._limitEscortParam
end

local shareLimitTab = {}
function PlayerInputProxy:handle_MSG_SC_LIMIT_DISTANCE_ESCORT(msg)
    local distance = msg:GetP0() -- 范围内不让走跑
    local actorID = msg:GetBodyStr()

    shareLimitTab.id = actorID
    shareLimitTab.distance = distance
    self._limitEscortParam = shareLimitTab
end

function PlayerInputProxy:onRegister()
    PlayerInputProxy.super.onRegister(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_COLLECT_COMPLETED, handler(self, self.handle_MSG_SC_COLLECT_COMPLETED))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_LIMIT_DISTANCE_ESCORT, handler(self, self.handle_MSG_SC_LIMIT_DISTANCE_ESCORT))
end

return PlayerInputProxy
