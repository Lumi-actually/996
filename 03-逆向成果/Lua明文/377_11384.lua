local BaseUIMediator = requireMediator("BaseUIMediator")
local NPCLayerMediator = class('NPCLayerMediator', BaseUIMediator)
NPCLayerMediator.NAME = "NPCLayerMediator"

local mAbs = math.abs

local function CheckLayerOutScreen(tag)
    local LayerFacadeMediator = global.Facade:retrieveMediator("LayerFacadeMediator")
    if tag and tag == "BAG" then
        local isMergePanelMode = GUIDefineEx.IsMergeMode
        local win = isMergePanelMode and GUI:GetWindow(nil, UIConst.LAYERID.MergeBagLayerGUI) or
        GUI:GetWindow(nil, UIConst.LAYERID.BagLayerGUI)
        local mediator = win and win.mediator
        if mediator then
            return LayerFacadeMediator:checkOutScreen(mediator)
        end
    end
    
    return false         
end

function NPCLayerMediator:ctor()
    NPCLayerMediator.super.ctor(self)

    self._currentNPCID = nil
    self._npcBindWinList = {}
end

function NPCLayerMediator:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return {
        noticeTable.Layer_NPC_Talk_Open,
        noticeTable.Layer_NPC_Talk_Close,
        noticeTable.MainPlayerActionEnded,
        noticeTable.NpcOutOfView,
        noticeTable.ChangeScene,
    }
end

function NPCLayerMediator:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeID == noticeTable.Layer_NPC_Talk_Open then
        if global.IsReceiveRole or global.IsVisitor then  -- 收货或者试玩不要打开npc界面
            return
        end

        self:OpenLayer()

    elseif noticeID == noticeTable.Layer_NPC_Talk_Close then
        self:CloseLayer()

    elseif noticeID == noticeTable.MainPlayerActionEnded then
        self:OnMainPlayerActionEnded(data)

    elseif noticeID == noticeTable.NpcOutOfView then
        self:OnNpcOutOfView(data)

    elseif noticeID == noticeTable.ChangeScene then
        self:OnChangeScene()

    end
end

function NPCLayerMediator:OpenLayer()
    local lastLayerID = nil
    if self._layer and self._layer.background then
        if self._layer.background.element.attr.layerid then
            lastLayerID = self._layer.background.element.attr.layerid
        end
    end

    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    if self._currentNPCID and self._currentNPCID ~= NPCProxy:GetCurrentNPCID() then
        self:CloseLayer()
    end

    self._currentNPCID = NPCProxy:GetCurrentNPCID()

    if not self._layer then
        self._layer = requireLayerUI("npc_layer/NpcTalkLayer").create()
        self._type = global.UIZ.UI_NORMAL

        local forbidBagEquip = false

        -- load
        self._layer:loadTalkContent()

        -- property, ctrl by background
        if self._layer.background then
            local background     = self._layer.background
            local render         = background.render
            local element        = background.element
            self._resetPostion   = (tonumber(element.attr.reset) or 1) == 1
            self._escClose       = (tonumber(element.attr.esc) or 1)   == 1
            self._hideMain       = tonumber(element.attr.hideMain)     == 1
            self._adapet         = (tonumber(element.attr.show) or 0)  == 6             -- 加黑幕
            forbidBagEquip       = (tonumber(element.attr.forbidBagEquip) or 0) == 1    -- 禁止打开背包/角色

            if render then
                global.mouseEventController:registerMouseMoveEvent(render)
                global.mouseEventController:registerMouseButtonEvent(render)
            end

            -- notify server npc layer open
            if background.element.attr.layerid then
                NPCProxy:RequestNotifyTalkOpen(background.element.attr.layerid)
            end

            -- bagPos
            if tonumber(background.element.attr.bagPos) == 1 then
                SL:onLUAEvent(LUA_EVENT_BAGLAYER_POS_CHANGE, { x = 0, y = 0 })
            elseif tonumber(background.element.attr.bagPos) == 3 then
                if CheckLayerOutScreen("BAG") then
                    local offsetX = nil
                    if tonumber(background.element.attr.show) == 1 then
                        offsetX = global.isWinPlayMode and -40 or -60
                    else
                        offsetX = global.isWinPlayMode and 500 or 470
                    end
                    SL:onLUAEvent(LUA_EVENT_BAGLAYER_POS_CHANGE, {x = offsetX, y = 40})
                end
                dump("LUA_EVENT_BAGLAYER_POS_CHANGE____")
            else
                local offsetX = nil
                if tonumber(background.element.attr.show) == 1 then
                    offsetX = global.isWinPlayMode and -40 or -60
                else
                    offsetX = global.isWinPlayMode and 500 or 470
                end
                SL:onLUAEvent(LUA_EVENT_BAGLAYER_POS_CHANGE, {x = offsetX, y = 40})
                dump("LUA_EVENT_BAGLAYER_POS_CHANGE____222")
            end
        end

        NPCProxy:SetForbidOpenBagEquip(forbidBagEquip)

        NPCLayerMediator.super.OpenLayer(self)

        -- update move
        if self._layer and self._layer.background then
            local element = self._layer.background.element 
            local needMove = (tonumber(element.attr.move) or 0) == 1
            if needMove then
                local render = self._layer.background.render
                self:setLayerMoveEnable(render)
            end
        end

        SLBridge:onLUAEvent(LUA_EVENT_NPCLAYER_OPENSTATUS, true)

    else
        self._layer:loadTalkContent()

        -- notify server npc layer close
        if self._layer and self._layer.background then
            if lastLayerID ~= self._layer.background.element.attr.layerid then
                local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
                npcProxy:RequestNotifyTalkClose(lastLayerID)
            end
        end

        -- notify server npc layer open
        if self._layer and self._layer.background then
            if lastLayerID ~= self._layer.background.element.attr.layerid then
                local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
                npcProxy:RequestNotifyTalkOpen(self._layer.background.element.attr.layerid)
            end
        end

        -- update move
        if self._layer and self._layer.background then
            local element = self._layer.background.element 
            local needMove = (tonumber(element.attr.move) or 0) == 1
            local render = self._layer.background.render
            if render then
                if needMove then
                    self:setLayerMoveEnable(render)
                end
                global.mouseEventController:registerMouseMoveEvent(render)
                global.mouseEventController:registerMouseButtonEvent(render)
            end
            self._resetPostion = (tonumber(element.attr.reset) or 1) == 1
            local LayerFacadeMediator = global.Facade:retrieveMediator("LayerFacadeMediator")
            if self._resetPostion then
                LayerFacadeMediator:resetLayerPostion(self)
            end
        end

        RefreshPositionByParent(self._layer)
    end
end

function NPCLayerMediator:CloseLayer()
    if not self._layer then
        return nil
    end

    if self._escClose then
        self._escClose = nil
        local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        npcProxy:Cleanup()
        return
    end

    SL:onLUAEvent(LUA_EVENT_GUIDE_EVENT_ENDED, { name = "GUIDE_END_NPC_TALK_LAYER_CLOSED" })

    -- reset current npcID
    self._currentNPCID = nil

    -- notify server npc layer close
    local background = self._layer.background
    if background and background.element.attr.layerid then
        local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        npcProxy:RequestNotifyTalkClose(background.element.attr.layerid)
    end

    local bagPos = background and tonumber(background.element.attr.bagPos)

    -- caching
    if self._layer.trunk then
        global.SWidgetCache:cachingTrunk(self._layer.trunk)
    end

    -- reset bag position
    if not (bagPos and bagPos == 3) then
        SL:onLUAEvent(LUA_EVENT_BAGLAYER_POS_CHANGE, { x = 0, y = 0 })
        dump("LUA_EVENT_BAGLAYER_POS_CHANGE____33")
    end

    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    NPCProxy:SetForbidOpenBagEquip(false)

    -- close
    NPCLayerMediator.super.CloseLayer(self)
    SLBridge:onLUAEvent(LUA_EVENT_NPCLAYER_OPENSTATUS, false)
end


function NPCLayerMediator:OnMainPlayerActionEnded(act)
    if not GUIFunction:IsMoveAction(act) then
        return
    end

    GUIFunction:CheckNpcTalkTips()
    self:CheckCloseNpcTalkLayer()
    self:CheckCloseSUIWin()
end

function NPCLayerMediator:CheckCloseNpcTalkLayer()
    if not self._layer then
        return
    end

    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return
    end

    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    local clickNPCID = NPCProxy:GetCurrentClickNPCID()
    if not clickNPCID then
        return
    end

    local npc = global.npcManager:FindOneNpcInCurrViewFieldById(clickNPCID)
    if not npc then
        return
    end

    local x = mainPlayer:GetMapX()
    local y = mainPlayer:GetMapY()
    local dis = math.max(math.abs(x - npc:GetMapX()), math.abs(y - npc:GetMapY()))
    if dis >= 8 then
        global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
    end
end

function NPCLayerMediator:OnNpcOutOfView(npcId)
    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    NPCProxy:CheckNpcTalkLayerClose(npcId)

    GUI:Win_CloseByNPCID(npcId)
end

function NPCLayerMediator:OnChangeScene()
    self:CheckCloseSUIWin()
end

function NPCLayerMediator:AddWinBindNPCIdx(widget, npcID)
    if not widget or not npcID then
        return
    end
    npcID = tostring(npcID)
    if not self._npcBindWinList[npcID] then
        self._npcBindWinList[npcID] = {}
    end
    table.insert(self._npcBindWinList[npcID], widget)
end

function NPCLayerMediator:CheckCloseSUIWin(...)
    for npcID, winList in pairs(self._npcBindWinList) do        
        local function closeBindWins()
            self._npcBindWinList[npcID] = {}
        end
        
        local npc = global.npcManager:FindOneNpcInCurrViewFieldById(npcID)
        if not npc then
            closeBindWins()
        else
            local mainPlayer = global.gamePlayerController:GetMainPlayer()
            if mainPlayer then
                local x = mainPlayer:GetMapX()
                local y = mainPlayer:GetMapY()
                local dis = math.max(math.abs(x - npc:GetMapX()), math.abs(y - npc:GetMapY()))
                if dis >= 8 then
                    closeBindWins()
                end
            end
        end
    end
end

return NPCLayerMediator