local PlayerInputController = class('PlayerInputController', framework.Mediator)
PlayerInputController.NAME  = "PlayerInputController"

local proxyUtils        = requireUtil("proxyUtils")
local SharedInputLaunchData = {}

function PlayerInputController:ctor()
    PlayerInputController.super.ctor(self, self.NAME)
end

function PlayerInputController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.GameWorldInitComplete,
        noticeTable.ClearAllInputState,
        noticeTable.MainPlayerDie,
        noticeTable.ChangeScene,
        noticeTable.ForbiddenMoveBuffBegan,
        noticeTable.ForbiddenMoveBuffEnd,
        noticeTable.UserInputMove,
        noticeTable.UserInputLaunch,
        noticeTable.UserInputCorpse,
        noticeTable.UserInputMining,
        noticeTable.UserPressedShift,
        noticeTable.UserReleaseShift,
        noticeTable.LaunchAttackSkill,
    }
end

function PlayerInputController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.GameWorldInitComplete == noticeID then
        self:OnInit()
    
    elseif noticeTable.ClearAllInputState == noticeID then
        self:OnClearAllInputState()
    
    elseif noticeTable.MainPlayerDie == noticeID then
        self:onMainPlayerDie()

    elseif noticeTable.ChangeScene == noticeID then
        local mapID = data
        local lastMapID = notification:getType()
        self:OnChangeScene(mapID, lastMapID)

    elseif noticeTable.ForbiddenMoveBuffBegan == noticeID then
        self:onForbiddenMoveBuffBegan()
    
    elseif noticeTable.ForbiddenMoveBuffEnd == noticeID then
        self:onForbiddenMoveBuffEnd()

    elseif noticeTable.UserInputMove == noticeID then
        self:onUserInputMove(data)

    elseif noticeTable.UserInputLaunch == noticeID then
        SLBridge:onLUAEvent(LUA_EVENT_USER_INPUT_LAUNCH_SKILL, data)

    elseif noticeTable.UserInputCorpse == noticeID then
        self:onUserInputCorpse(data)

    elseif noticeTable.UserInputMining == noticeID then
        self:onUserInputMining(data)
    
    elseif noticeTable.UserPressedShift == noticeID then
        self:onUserPressedShift()

    elseif noticeTable.UserReleaseShift == noticeID then
        self:onUserReleaseShift()

    elseif noticeTable.LaunchAttackSkill == noticeID then
        self:onLaunchAttackSkill()
    end
end

function PlayerInputController:OnInit()
    self._inputProxy        = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    self._skillProxy        = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    self._autoProxy         = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)

    self._isInited = true
end

function PlayerInputController:OnClearAllInputState()
    if not self._isInited then
        return
    end

    self._inputProxy:ClearMouseTouch()
    self._inputProxy:ClearLaunch()
    self._inputProxy:ClearMining()
    self._inputProxy:ClearCorpse()
    self._inputProxy:ClearDigDest()
end

function PlayerInputController:onMainPlayerDie()
    if not self._isInited then
        return
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()
end

function PlayerInputController:OnChangeScene(mapID, lastMapID)
    if not self._isInited then
        return
    end

    if not mapID then
        return nil
    end


    if mapID == lastMapID then
        global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
        global.Facade:sendNotification(global.NoticeTable.InputIdle)
    end
end

function PlayerInputController:onForbiddenMoveBuffBegan()
    if not self._isInited then
        return
    end

    self._inputProxy:SetMovePermission(false)
end

function PlayerInputController:onForbiddenMoveBuffEnd()
    if not self._isInited then
        return
    end

    self._inputProxy:SetMovePermission(true)
end

----------------------------------------------------
--- user input
function PlayerInputController:onUserInputMove(data)
    if not self._isInited then
        return
    end


    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()

    -- 移动取消攻击锁定
    if CHECK_SETTING(60) == 1 then
        self._autoProxy:ClearAutoLock()
    end

    -- 
    global.Facade:sendNotification(global.NoticeTable.InputMove, data)
end

function PlayerInputController:onUserInputCorpse(data)
    if not self._isInited then
        return
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()

    -- 
    global.Facade:sendNotification(global.NoticeTable.InputCorpse, data)
end

function PlayerInputController:onUserInputMining(data)
    if not self._isInited then
        return
    end

    if not self._inputProxy:IsLaunchMining(data.destX, data.destY) then
        return
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()
    
    -- 
    self._autoProxy:SetAutoMining(data.dir, data.destX, data.destY)
    global.Facade:sendNotification(global.NoticeTable.InputMining, data)
end
----------------------------------------------------


----------------------------------------------------
function PlayerInputController:onUserPressedShift()
    if not self._isInited then
        return
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()

    if self._inputProxy:GetTargetID() then
        self._inputProxy:SetAttackState(true)
    end
end

function PlayerInputController:onUserReleaseShift()
    if not self._isInited then
        return
    end

    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.ClearAllAutoState, {ignoreAutoMining = 1})
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()

    self._inputProxy:ClearLaunch()

    if self._inputProxy:GetTargetID() then
        self._inputProxy:SetAttackState(true)
    end
end

function PlayerInputController:onLaunchAttackSkill()
    if not self._isInited then
        return
    end
    
    local skillID, destPosX, destPosY = SkillUtils.FindAttackLaunchSkill()

    if not skillID then
        return
    end

    self._inputProxy:ClearTarget()

    SharedInputLaunchData.launchType = global.MMO.LAUNCH_TYPE_ATTACK
    SharedInputLaunchData.priority = global.MMO.LAUNCH_PRIORITY_USER
    SharedInputLaunchData.skillID = skillID
    SharedInputLaunchData.destPosX = destPosX
    SharedInputLaunchData.destPosY = destPosY
    global.Facade:sendNotification(global.NoticeTable.InputLaunch, SharedInputLaunchData)
end

return PlayerInputController
