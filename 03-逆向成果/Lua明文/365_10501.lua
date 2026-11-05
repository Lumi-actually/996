local AutoController = class('AutoController', framework.Mediator)
AutoController.NAME = "AutoController"

local proxyUtils        = requireUtil("proxyUtils")

local AutoFindActorBehavior      = require("auto_behavior/AutoFindActorBehavior")
local AutoFindSkillBehavior      = require("auto_behavior/AutoFindSkillBehavior")
local AutoFindMoveBehavior       = require("auto_behavior/AutoFindMoveBehavior")

local facade            = global.Facade

local isFarMovePointsLimit = 30    -- 远距离寻路路径点限制

function AutoController:ctor()
    AutoController.super.ctor(self, self.NAME)

    self._autoFindBehavior = {}
end

function AutoController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.GameWorldInitComplete,
        noticeTable.ClearAllAutoState,
        noticeTable.ChangeScene,
        noticeTable.AFKBegin,
        noticeTable.AFKEnd,
        noticeTable.AutoPickBegin,
        noticeTable.AutoPickEnd,
        noticeTable.ActorInOfView,
        noticeTable.ActorRevive,
        noticeTable.CheckAutoTarget,
    }
end


function AutoController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.GameWorldInitComplete == noticeID then
        self:OnInit()

    elseif noticeTable.ClearAllAutoState == noticeID then
        self:onClearAllAutoState(data)

    elseif noticeTable.ChangeScene == noticeID then
        local mapID = data
        local lastMapID = notification:getType()
        self:OnChangeScene(mapID, lastMapID)
    
    elseif noticeTable.AFKBegin == noticeID then
        self:OnAFKBegin()
    
    elseif noticeTable.AFKEnd == noticeID then
        self:OnAFKEnd()
    
    elseif noticeTable.AutoPickBegin == noticeID then
        self:OnAutoPickBegin()
    
    elseif noticeTable.AutoPickEnd == noticeID then
        self:OnAutoPickEnd()
            
    elseif noticeTable.ActorInOfView == noticeID then
        self:OnActorInOfView(data)

    elseif noticeTable.ActorRevive == noticeID then
        self:OnActorRevive(data)

    elseif noticeTable.CheckAutoTarget == noticeID then
        self:OnCheckAutoTarget(data)
    end
end

function AutoController:OnInit()
    self._assistProxy       = facade:retrieveProxy(global.ProxyTable.AssistProxy)
    self._inputProxy        = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    self._skillProxy        = facade:retrieveProxy(global.ProxyTable.SkillProxy)
    self._autoProxy         = facade:retrieveProxy(global.ProxyTable.AutoProxy)

    table.insert(self._autoFindBehavior, AutoFindActorBehavior.new())
    table.insert(self._autoFindBehavior, AutoFindSkillBehavior.new())
    table.insert(self._autoFindBehavior, AutoFindMoveBehavior.new())
    
    self._isInited = true
end

function AutoController:onClearAllAutoState(ignore)
    if not self._isInited then
        return
    end

    if self._autoProxy:GetPickItemID() then
        self._autoProxy:SetPickItemID(nil)
    end

    if ignore and ignore.ignoreAutoMining == 1 then
    else
        self._autoProxy:ClearAutoMining()
    end
end

function AutoController:OnChangeScene(mapID, lastMapID)
    if not mapID then
        return nil
    end

    -- clear auto state
    facade:sendNotification(global.NoticeTable.ClearAllAutoState)

    -- slove change scene
    if mapID == lastMapID then
        self:onChangeSameScene(mapID, lastMapID)
    else
        self:onChangeOtherScene(mapID, lastMapID)
    end
end

function AutoController:onChangeSameScene(mapID, lastMapID)
    if not self._isInited then
        return
    end

    if CHECK_SERVER_OPTION(global.MMO.SERVER_CHECK_AUTO_FIGHT) then
        return
    end
    
    -- 随机石切换地图
    if self._autoProxy:GetRandStoneAFKFlag() then
        self._autoProxy:SetRandStoneAFKFlag(false)
    else
        self._autoProxy:ClearAFKState()
        self._autoProxy:ClearAllState()
        self._autoProxy:ClearPickState()
    end
end

function AutoController:onChangeOtherScene(mapID, lastMapID)
    if not self._isInited then
        return
    end
    
    local movePos = self._autoProxy:PopMove()
    if movePos and movePos.mapID == mapID then
        -- move to next pos at next action
        facade:sendNotification(global.NoticeTable.InputMove, movePos)
    else
        -- exception
        self._autoProxy:ClearAllState()
        self._autoProxy:ClearAFKState()
        self._autoProxy:ClearPickState()
    end
end

function AutoController:OnAFKBegin()
    if not self._isInited then
        return
    end
    
    self._autoProxy:ClearAutoTarget()
    
    if self._autoProxy:IsAFKState() then
        return nil
    end

    facade:sendNotification(global.NoticeTable.ClearAllInputState)
    facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()

    self._autoProxy:SetIsAFKState(true)
    facade:sendNotification(global.NoticeTable.AutoFightBegin, global.MMO.INPUT_PRIORITY_SYSTEM)

    SLBridge:onLUAEvent(LUA_EVENT_AFKBEGIN)
end

function AutoController:OnAFKEnd()
    if not self._isInited then
        return
    end
    
    if not self._autoProxy:IsAFKState() then
        return nil
    end

    facade:sendNotification(global.NoticeTable.ClearAllInputState)
    facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()
end

function AutoController:OnAutoPickBegin()
    if self._autoProxy:IsPickState() then
        return nil
    end

    facade:sendNotification(global.NoticeTable.ClearAllInputState)
    facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()

    print("----------------------- pick state begin")
    self._autoProxy:SetIsPickState(true)
end

function AutoController:OnAutoPickEnd()
    if not self._autoProxy:IsPickState() then
        return nil
    end

    facade:sendNotification(global.NoticeTable.ClearAllInputState)
    facade:sendNotification(global.NoticeTable.ClearAllAutoState)
    facade:sendNotification(global.NoticeTable.InputIdle)
    self._autoProxy:ClearAutoLock()
    self._autoProxy:ClearAllState()
    self._autoProxy:ClearAFKState()
    self._autoProxy:ClearPickState()

    print("----------------------- pick state end")
end


------------------------------------------------------------

-------------------------------------------------------------
function AutoController:stateBegin(player, actCompleted)
    if not self._isInited then
        return false
    end
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return false
    end
    
    local ret = false
    for k, v in pairs(self._autoFindBehavior) do
        if v:Update(player, actCompleted) then
            ret = true
            break
        end
    end

    return ret
end
-------------------------------------------------------------
function AutoController:OnActorInOfView(data)
    local actorID = data.actorID
    if not actorID then 
        return 
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        return 
    end
    if self._inputProxy and actor and false == actor:IsDie() and (actor:IsPlayer() or actor:IsMonster()) then

        -- 进视野选择
        if (nil == self._inputProxy:GetTargetID()) and (self._inputProxy:GetLastTargetID() and self._inputProxy:GetLastTargetID() == actorID) then
            self._inputProxy:SetTargetID(actorID)
        end
    end
end

function AutoController:OnCheckAutoTarget(actorID)
    if not actorID then 
        return 
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        return 
    end

    if self._inputProxy and not actor:IsDie() and (actor:IsHumanoid() or actor:IsMonster()) then
    
        local targetID = self._inputProxy:GetTargetID()
        if targetID == actorID then
            return
        end

        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        local curPathSize = PlayerInputProxy:GetCurrPathPoint()

        if SL:GetValue("BATTLE_IS_AUTO_FIGHT_STATE") and SL:GetValue("LAST_LAUNCH_MOVE_FAR_POS") and curPathSize > isFarMovePointsLimit 
          and GUIFunction.CheckAutoTargetEnableByID(actorID) then
            -- 正在远距离寻路找怪, 有可攻击目标在附近换目标
            self._inputProxy:ClearTarget()
            self._inputProxy:ClearLaunch()
            self._inputProxy:ClearMove()
        end

        -- 选择
        if nil == self._inputProxy:GetTargetID() and (self._inputProxy:GetLastTargetID() and self._inputProxy:GetLastTargetID() == actorID) then
            self._inputProxy:SetTargetID(actorID)
        end
    end
end

function AutoController:OnActorRevive(actorID)
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    if self._inputProxy and actor and false == actor:IsDie() and (actor:IsPlayer() or actor:IsMonster()) then
        -- 复活选择
        if (nil == self._inputProxy:GetTargetID()) and (self._inputProxy:GetLastTargetID() and self._inputProxy:GetLastTargetID() == actorID) then
            self._inputProxy:SetTargetID(actorID)

            if not global.isWinPlayMode and self._inputProxy:IsAttackState() and CHECK_SETTING(global.MMO.SETTING_IDX_ALWAYS_ATTACK) == 1 then
                self._autoProxy:SetIsAutoLockState(true)
                if not self._autoProxy:GetAutoLockSkillID() then
                    local skillID = SkillUtils.FindLockLaunchSkill()
                    self._autoProxy:SetAutoLockSkillID(skillID or 0)
                end
            end
        end
    end
end

return AutoController
