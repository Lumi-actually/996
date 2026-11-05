local DamageNumMediator = class('DamageNumMediator', framework.Mediator)
DamageNumMediator.NAME  = "DamageNumMediator"

local Queue       = requireUtil("queue")
local LIMIT_COUNT = 40

local sharedDamageTab = {}
function DamageNumMediator:ctor()
    DamageNumMediator.super.ctor(self, self.NAME)

    self._damageQueue = Queue.new()
    self.TIMER_INTERVAL = 20 * 0.001
end

function DamageNumMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.PlayerPropertyInited,
        noticeTable.ReleaseMemory,
        noticeTable.ShowThrowDamage,
        noticeTable.SLThrowDamageNum,
    }
end

function DamageNumMediator:handleNotification(notification)
    local noticeID = notification:getName()
    local notices  = global.NoticeTable
    local data     = notification:getBody()

    if notices.ReleaseMemory == noticeID then
        self:OnClose()

    elseif notices.PlayerPropertyInited == noticeID then
        self:OnInit()

    elseif notices.ShowThrowDamage == noticeID then
        self:InsertDamageQueue(data)
    
    elseif notices.SLThrowDamageNum == noticeID then
        self:OnSLThrowDamageNum(data)
    end
end

function DamageNumMediator:OnInit()
    if not (self._viewComponent) then
        local ThrowDamageNumLayout = requireView("scene/ThrowDamageNumLayout")
        self._viewComponent        = ThrowDamageNumLayout.create()
    end
end

function DamageNumMediator:OnClose()
    if self._viewComponent then
        self._viewComponent:OnClose()
        self._viewComponent = nil
    end
end

function DamageNumMediator:throwDamage(type, num, pos, parentNode, isMain, speed)
    local damageProxy = global.Facade:retrieveProxy(global.ProxyTable.DamageNumProxy)
    if self._viewComponent and parentNode then
        local config = damageProxy:GetConfig(type)
        if not config then
            return nil
        end

        if config.enable == 0 then 
            return 
        end 

        local actionsDatas = nil
        if isMain then
            actionsDatas = damageProxy:GetOwnActionData(type)
        else
            actionsDatas = damageProxy:GetOtherActionData(type)
        end

        if not actionsDatas or #actionsDatas <= 0 then
            return nil
        end

        local offsetDatas = damageProxy:GetOffsetData(type)

        local param = {
            type       = type,
            originNum  = num,
            originPos  = pos,
            parentNode = parentNode,
            speed      = speed or 1
        }

        local showType = damageProxy:GetThrowShowType(type)
        if showType == global.MMO.DAMAGE_SHOW_NUM then
            self._viewComponent:ThrowDamageNum(param, config, actionsDatas, offsetDatas)
        elseif showType == global.MMO.DAMAGE_SHOW_SPRITE then 
            self._viewComponent:ThrowSprite(param, config, actionsDatas, offsetDatas)
        elseif showType == global.MMO.DAMAGE_SHOW_TEXT then 
            if tonumber(num) and tonumber(num) > 0 then 
                self._viewComponent:ThrowDamageNum(param, config, actionsDatas, offsetDatas)
            else 
                self._viewComponent:ThrowDamageText(param, config, actionsDatas, offsetDatas)
            end 
        elseif showType == global.MMO.DAMAGE_SHOW_POINT then
            self._viewComponent:ThrowDamagePoint(param, config, actionsDatas, offsetDatas)
        end

        -- 特效
        local animID = damageProxy:GetAnimID(type)
        if animID then
            self._viewComponent:CreateAnim(animID, pos, parentNode)
        end
    end

    -- 震屏
    if damageProxy:IsShake(type) then
        local data    = {}
        data.time    = 1000
        data.distance = 20
        global.Facade:sendNotification(global.NoticeTable.ShakeScene, data)
    end
end

function DamageNumMediator:handle_throwDamageNum(actor, actorID, mainPlayerID, jsonData)
    if 1 ~= CHECK_SETTING(global.MMO.SETTING_IDX_DAMAGE_NUM) or not actor or not mainPlayerID or not jsonData.Id then
        return nil
    end

    local originPos  = actor:getPosition()
    local tempNum    = tonumber(jsonData.Power) or 0
    local damageNum  = tempNum == 0 and 0 or jsonData.Power
    local type       = jsonData.Id
    local isMain     = mainPlayerID == actorID
    local parentNode = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_DAMAGE)
    local baseTime   = tonumber(jsonData.AttackCurrSpeed)
    local currTime   = tonumber(jsonData.AttackCurrSpeed)
    local speed      = 1
    if baseTime and currTime then
        speed = baseTime / currTime
    end

    local damageProxy = global.Facade:retrieveProxy(global.ProxyTable.DamageNumProxy)
    local showType = damageProxy:GetThrowShowType(type)
    if showType == global.MMO.DAMAGE_SHOW_NUM and damageNum == 0 then
        return
    end  

    self:throwDamage(type, damageNum, originPos, parentNode, isMain, speed)
end

function DamageNumMediator:OnSLThrowDamageNum(data)
    if not data or not next(data) then
        return
    end

    local actorID = data.actorID
    if not actorID then
        return
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end

    local mainPlayerID = global.gamePlayerController:GetMainPlayerID()
    self:handle_throwDamageNum(actor, actorID, mainPlayerID, data)
end

function DamageNumMediator:Tick(dt)
    if self._damageQueue:size() > 0 then
        local jsonData = self._damageQueue:pop()
        local numID    = jsonData.Id
        local actorID  = jsonData.UserID
        local actor    = global.actorManager:GetActor(actorID)
        if not actor then
            return
        end

        local damageProxy = global.Facade:retrieveProxy(global.ProxyTable.DamageNumProxy)

        -- 潜行状态  不飘字
        if not actor:IsMainPlayer() and actor:GetValueByKey(global.MMO.HUD_SNEAK) then
            return
        end

        local mainPlayerID  = global.gamePlayerController:GetMainPlayerID()

        if GUIGlobal_OnDamgeNumQueueTick then
            GUIGlobal_OnDamgeNumQueueTick(jsonData)
        else
            -- 飘血
            self:handle_throwDamageNum(actor, actorID, mainPlayerID, jsonData)
        end
        
        -- 主玩家被攻击
        if actor:IsMainPlayer() and damageProxy:IsBeDamaged(numID) then
            global.Facade:sendNotification(global.NoticeTable.PlayerBeDamaged)
        end

        -- 
        sharedDamageTab.actorID = actorID
        sharedDamageTab.damageID = numID
        sharedDamageTab.damageNum = tonumber(jsonData.Power)
        sharedDamageTab.damageNumStr = jsonData.Power
        SL:onLUAEvent(LUA_EVENT_THROW_DAMAGE, sharedDamageTab)

        -- 英雄被攻击
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        local HeroID = HeroPropertyProxy:GetRoleUID()
        if HeroID == actorID and damageProxy:IsBeDamaged(numID) then
            global.Facade:sendNotification(global.NoticeTable.HeroBeDamaged)
        end
    else
        self:TimerEnded()
    end
end

function DamageNumMediator:TimerBegan()
    if not self._timerID then
        local function callback(delta)
            self:Tick(delta)
        end
        self._timerID = Schedule(callback, self.TIMER_INTERVAL)
        callback(self.TIMER_INTERVAL)
    end
end

function DamageNumMediator:TimerEnded()
    if self._timerID then
        UnSchedule(self._timerID)
        self._timerID = nil
    end
end

function DamageNumMediator:InsertDamageQueue(data)
    if not data then
        return
    end

    -- 服务器会同时发N个飘血给前端，且无法处理，让前端做队列
    self._damageQueue:push(data)
    if self._damageQueue:size() > LIMIT_COUNT then
        self._damageQueue:pop()
    end
    self:TimerBegan()
end

function DamageNumMediator:handle_MSG_SC_NET_ACTOR_DAMAGE_NUMBER_SHOW(netPkg)
    local UserID = netPkg:GetP0Str()
    local pxType = netPkg:GetP1()
    local damageValue = netPkg:GetP2Str()

    if not UserID then
        return false
    end

    local actor = global.actorManager:GetActor(UserID) 
    if not actor then
        return false
    end

    self:InsertDamageQueue({
        Id = pxType,
        UserID = UserID,
        Power = damageValue
    })
end

function DamageNumMediator:onRegister()
    DamageNumMediator.super.onRegister(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_DAMAGE_NUMBER_SHOW, handler(self, self.handle_MSG_SC_NET_ACTOR_DAMAGE_NUMBER_SHOW))
end

return DamageNumMediator