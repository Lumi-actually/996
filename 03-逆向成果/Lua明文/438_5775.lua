local BaseUIMediator = requireMediator("BaseUIMediator")
local DarkMediator = class('DarkMediator', BaseUIMediator)
DarkMediator.NAME = "DarkMediator"
local shareT1 = {}
function DarkMediator:ctor()
    DarkMediator.super.ctor(self)
end

function DarkMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_Main_Init,
        noticeTable.MapData_Load_Success,
        noticeTable.ReleaseMemory,
        noticeTable.ActorInOfView,
        noticeTable.ActorOutOfView,
        noticeTable.ActorEffectOutOfView,
        noticeTable.ActorEffectInOfView
    }
end

function DarkMediator:handleNotification(notification)
    local noticeName = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData = notification:getBody()
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    if noticeTable.Layer_Main_Init == noticeName then
        self:OpenLayer(noticeData)
    elseif noticeTable.MapData_Load_Success == noticeName then
        self:OnMapData_Load_Success(noticeData)
    elseif noticeTable.ReleaseMemory == noticeName then
        self:CloseLayer()
    elseif noticeTable.ActorInOfView == noticeName then
        self:OnActorInOfView(noticeData)
    elseif noticeTable.ActorOutOfView == noticeName then
        self:OnActorOutOfView(noticeData)
    elseif noticeTable.ActorEffectOutOfView == noticeName then
        self:OnActorEffectOutOfView(noticeData)
    elseif noticeTable.ActorEffectInOfView == noticeName then
        self:OnActorEffectInOfView(noticeData)
    end
end

function DarkMediator:OpenLayer(Data)
    if not (self._layer) then
        self._layer = requireLayerUI("dark_layer/DarkLayer").create(Data)
        self._type = global.UIZ.UI_MAIN
        local data = {}
        data.child = self._layer
        data.index = global.MMO.MAIN_NODE_SUI_BOTTOM_LB
        self._layer:setLocalZOrder(-999)
        global.Facade:sendNotification(global.NoticeTable.Layer_Main_AddChild, data)
    end
end

function DarkMediator:OnMapData_Load_Success()
    global.darkNodeManager:InitmapInfo()
end

function DarkMediator:OnActorInOfView(data)
    local hudParam = data and data.hudParam
    local actorID = data and data.actorID
    local actor = global.actorManager:GetActor(actorID)

    if hudParam and hudParam.Candle and actor then
        local ismain = false
        if actor:IsPlayer() and actor:IsMainPlayer() then
            ismain = true
        end
        local actorPosX = actor:getPositionX()
        local actorPosY = actor:getPositionY()
        local DarkLayerProxy = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
        local lightData = nil
        if hudParam.Candle == 0 then --啥也没带
            if ismain or SL:GetValue("HERO_ID") == actorID then 
                lightData = DarkLayerProxy.LIGHT_TYPE.Default
            end
        else 
            lightData = clone(DarkLayerProxy.LIGHT_TYPE.Custom1)
            lightData.r = lightData.r + hudParam.Candle
            lightData.w = lightData.w + hudParam.Candle
        end
        local lightID = actor:GetLightID()
        if not lightID then
            if lightData then
                shareT1.x = actorPosX
                shareT1.y = actorPosY
                shareT1.r = lightData.r
                shareT1.w = lightData.w
                lightID = global.darkNodeManager:createNode(shareT1)
                actor:SetLightID(lightID)
            end
        else
            if lightData then
                shareT1.x = actorPosX
                shareT1.y = actorPosY
                shareT1.r = lightData.r
                shareT1.w = lightData.w
                global.darkNodeManager:updateNode(lightID, shareT1)
            else
                global.darkNodeManager:removeNode(lightID)
                actor:SetLightID(nil)
            end
        end
    end

end

function DarkMediator:OnActorOutOfView(actorID)
    if not actorID then
        return
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local lightID = actor:GetLightID()
    if lightID then
        global.darkNodeManager:removeNode(lightID)
        actor:SetLightID(nil)
    end
end

function DarkMediator:OnActorEffectOutOfView(actorID)
    if not actorID then
        return
    end
    local sfxActor = global.actorManager:GetActor(actorID)
    if not sfxActor then
        return nil
    end
    if sfxActor:GetLightID() then
        global.darkNodeManager:removeNode(sfxActor:GetLightID())
        sfxActor:SetLightID(nil)
    end
end

function DarkMediator:OnActorEffectInOfView(data)
    local needLight = data.needLight
    local actorID = data and data.actorID
    if not actorID then
        return
    end
    local sfxActor = global.actorManager:GetActor(actorID)
    if not sfxActor then
        return nil
    end
    if needLight then --火墙等
        if not sfxActor:GetLightID() then
            local DarkLayerProxy = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
            local lightData = DarkLayerProxy.LIGHT_TYPE.Two_Skill
            shareT1.x = sfxActor:getPositionX()
            shareT1.y = sfxActor:getPositionY()
            shareT1.r = lightData.r
            shareT1.w = lightData.w
            local lightID = global.darkNodeManager:createNode(shareT1)
            sfxActor:SetLightID(lightID)
        end
    end
end

function DarkMediator:CloseLayer()
    if self._layer then
        self._layer:removeFromParent()
        self._layer = nil
    end
end

return DarkMediator