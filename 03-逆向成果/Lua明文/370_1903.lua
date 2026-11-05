local AssistMediator = class('AssistMediator', framework.Mediator)
AssistMediator.NAME = "AssistMediator"
local proxyUtils = requireUtil("proxyUtils")

function AssistMediator:ctor()
    AssistMediator.super.ctor(self, self.NAME)
end

function AssistMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.ActorInOfView,
    }
end

function AssistMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()
    
    if noticeTable.ActorInOfView == noticeID then
        self:OnActorInOfView(data)
    end
end

function AssistMediator:OnActorInOfView(data)
    local actorID = data.actorID
    if not actorID then 
        return  
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        return  
    end
    if not actor:IsMonster() and not actor:IsPlayer() then
        return nil
    end

    local assistProxy = global.Facade:retrieveProxy( global.ProxyTable.AssistProxy )
    if false == assistProxy:getOfflineState() and false == assistProxy:isFindMapMonster() then
        return nil
    end

    -- 不打守卫
    if actor:IsMonster() and actor:IsDefender() then
        return nil
    end

    -- 只打人形怪
    if actor:IsPlayer() and not actor:IsHumanoid() then
        return nil
    end

    if false == proxyUtils.CheckAutoTargetEnableByID(actorID) then
        return nil
    end

    assistProxy:resetOfflineState()
    assistProxy:resetFindMapMonster()

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    inputProxy:SetTargetID(actor:GetID())
    assistProxy:resetNoMonsterSchedule()
    inputProxy:ClearLaunch()
    inputProxy:ClearMove()
end

return AssistMediator
