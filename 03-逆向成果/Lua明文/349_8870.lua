local BuffEntity = require("buff/BuffEntity")
local BuffEntityPoisonTransparent = class("BuffEntityPoisonTransparent", BuffEntity)
local tAnchorPoint = cc.p(0.5, 0.5)
-- FIXME，special blend is not expected in RTT
local function filterSpecialBlendChild(node, filteredTable, isEqual)
    local children = node:getChildren()
    for _, child in ipairs(children) do
        if child.getBlendFunc then
            local blendFunc = child:getBlendFunc()
            local compareBlend = global.MMO.normal_blend_func
            if not isEqual and blendFunc.dst ~= compareBlend.dst and blendFunc.src ~= compareBlend.src then
                if child:isVisible() then
                    filteredTable[#filteredTable + 1] = child
                    child:setVisible(false)
                end
            elseif isEqual and blendFunc.dst == compareBlend.dst and blendFunc.src == compareBlend.src then
                if child:isVisible() then
                    filteredTable[#filteredTable + 1] = child
                    child:setVisible(false)
                end
            end
        end
        filterSpecialBlendChild(child, filteredTable, isEqual)
    end
end

local function rebackSpecialBlendChild(filteredTable)
    for _, node in ipairs(filteredTable) do
        node:setVisible(true)
    end
end

function BuffEntityPoisonTransparent:ctor(data)
    BuffEntityPoisonTransparent.super.ctor(self, data)

end

function BuffEntityPoisonTransparent:OnEnter()
    BuffEntityPoisonTransparent.super.OnEnter(self)

    self:CoverSeparateActor()
end

function BuffEntityPoisonTransparent:Tick(dt)
    BuffEntityPoisonTransparent.super.Tick(self, dt)
    if not self:IsInvalid() then
        self:visitRenderTextureActor()
    end
end

function BuffEntityPoisonTransparent:CoverSeparateActor(opacity)
    local opacity = self._param
    local actor = global.actorManager:GetActor(self._actorID)
    if not actor or not opacity or opacity == 0 then
        return false
    end

    if not actor:IsPlayer() then
        return false
    end

    local camera = global.gameCameraController:GetViewCamera()
    if not camera then
        return
    end

    self._originWinSize = global.Director:getWinSize()

    local rootNode  = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SPRITE)
    local size      = global.Director:getWinSize()
    local coverNode = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
    coverNode:setCameraMask(cc.CameraFlag.USER2, true)
    coverNode:setKeepMatrix(true)
    rootNode:addChild(coverNode)
    self._coverNode = coverNode

    local coverSprite = coverNode:getSprite()
    coverSprite:setAnchorPoint(tAnchorPoint)
    coverSprite:setOpacity(opacity)

    local animCoverNode = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
    animCoverNode:setCameraMask(cc.CameraFlag.USER2, true)
    animCoverNode:setKeepMatrix(true)
    rootNode:addChild(animCoverNode)
    self._animCoverNode = animCoverNode

    local animCoverSprite = animCoverNode:getSprite()
    animCoverSprite:setAnchorPoint(tAnchorPoint)
    animCoverSprite:setOpacity(opacity)
    animCoverSprite:setBlendFunc(global.MMO.screen_blend_func)

    self:visitRenderTextureActor()
end

function BuffEntityPoisonTransparent:visitRenderTextureActor()
    if not self._coverNode then
        return
    end

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        return
    end

    local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    if actor:IsMainPlayer() or PlayerInputProxy:GetTargetID() == self._actorID then
        if not self._visitCoverNode then
            local rootNode  = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_MAP_OBJ)
            local size      = global.Director:getWinSize()
            self._visitCoverNode = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
            self._visitCoverNode:setCameraMask(cc.CameraFlag.USER1, true)
            self._visitCoverNode:setKeepMatrix(true)
            rootNode:addChild(self._visitCoverNode)

            local coverSprite = self._visitCoverNode:getSprite()
            coverSprite:setAnchorPoint(tAnchorPoint)
            coverSprite:setOpacity(128)
        end
    else
        if self._visitCoverNode then
            self._visitCoverNode:removeFromParent()
            self._visitCoverNode = nil
        end

        if self._visitCoverNodeHandler then 
            global.RenderTextureManager:RmvDrawFunc(self._visitCoverNodeHandler)
            self._visitCoverNodeHandler = nil 
        end
    end

    self._coverNodeHandler = global.RenderTextureManager:AddDrawFuncOnce({func = function ()
        self._coverNodeHandler = nil
        self:visitRenderTexture(self._coverNode, self._animCoverNode)
    end})

    self._visitCoverNodeHandler = global.RenderTextureManager:AddDrawFuncOnce({func = function ()
        self._visitCoverNodeHandler = nil
        self:visitRenderTexture(self._visitCoverNode)
    end})
end

function BuffEntityPoisonTransparent:visitRenderTexture(coverNode, animCoverNode)
    if not coverNode then
        return
    end

    local actor = global.actorManager:GetActor(self._actorID)
    if not actor then
        coverNode:setVisible(false)
        if animCoverNode then
            animCoverNode:setVisible(false)
        end
        return
    end

    local camera = global.gameCameraController:GetViewCamera()
    if not camera then
        return
    end
    
    local filteredTable = {}
    filterSpecialBlendChild(actor:GetNode(), filteredTable)

    coverNode:setVisible(true)
    local viewIndex = 0
    global.Director:pushProjectionMatrix(viewIndex)
    global.Director:loadProjectionMatrix(camera:getViewProjectionMatrix(), viewIndex)
    camera:apply()

    local destPosX  = 0
    local destPosY  = 30
    local scaleSize = 1.5
    local currSize  = global.Director:getWinSize()
    local cameraPosX, cameraPosY = camera:getPosition()
    local actorPosX = actor:getPositionX()
    local actorPosY = actor:getPositionY()
    local x = cameraPosX - (actorPosX - cameraPosX) * (scaleSize - 1) + destPosX
    local y = cameraPosY - (actorPosY - cameraPosY) * (scaleSize - 1) + destPosY
    
    coverNode:setPosition(x, y)

    coverNode:beginWithClear(0, 0, 0, 0)
    actor:GetNode():visit()
    
    rebackSpecialBlendChild(filteredTable)
    coverNode:endToLua()

    local screenScaleX = 1
    local screenScaleY = 1
    if not global.isWinPlayMode then
        screenScaleX = currSize.width / self._originWinSize.width
        screenScaleY = currSize.height / self._originWinSize.height
    end
    local viewScaleX, viewScaleY = CalcCameraZoom(camera)
    coverNode:setScaleX(viewScaleX * screenScaleX * scaleSize)
    coverNode:setScaleY(viewScaleY * screenScaleY * scaleSize)
    coverNode:setLocalZOrder(actor:GetNode():getLocalZOrder()-1)

    if animCoverNode then
        filteredTable = {}
        filterSpecialBlendChild(actor:GetNode(), filteredTable, true)
        animCoverNode:setVisible(true)
        animCoverNode:setPosition(cameraPosX - x + destPosX , cameraPosY- y + destPosY)
        animCoverNode:beginWithClear(0, 0, 0, 0)
        actor:GetNode():visit()
        
        rebackSpecialBlendChild(filteredTable)
        animCoverNode:endToLua()

        animCoverNode:setScaleX(viewScaleX * screenScaleX * scaleSize)
        animCoverNode:setScaleY(viewScaleY * screenScaleY * scaleSize)
        animCoverNode:setLocalZOrder(actor:GetNode():getLocalZOrder()-1)
    end

    camera:restore()
    global.Director:popProjectionMatrix(viewIndex)

end


function BuffEntityPoisonTransparent:UnCoverSeparateActor()
    if self._coverNode then
        self._coverNode:removeFromParent()
        self._coverNode = nil
    end
    
    if self._animCoverNode then
        self._animCoverNode:removeFromParent()
        self._animCoverNode = nil
    end

    if self._visitCoverNode then
        self._visitCoverNode:removeFromParent()
        self._visitCoverNode = nil
    end

    if self._coverNodeHandler then 
        global.RenderTextureManager:RmvDrawFunc(self._coverNodeHandler)
        self._coverNodeHandler = nil 
    end

    if self._visitCoverNodeHandler then 
        global.RenderTextureManager:RmvDrawFunc(self._visitCoverNodeHandler)
        self._visitCoverNodeHandler = nil 
    end
end

function BuffEntityPoisonTransparent:OnExit()
    BuffEntityPoisonTransparent.super.OnExit(self)
    self:UnCoverSeparateActor()
end

return BuffEntityPoisonTransparent
