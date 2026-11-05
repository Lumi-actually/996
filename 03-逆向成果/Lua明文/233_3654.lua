local gameCameraController = class("gameCameraController")
gameCameraController.NAME  = "gameCameraController"

function gameCameraController:ctor()
    self.mCamera     = nil
    self.mViewSize   = nil
    self.mBoundaryL  = nil
    self.mBoundaryR  = nil
    self.mBoundaryT  = nil
    self.mBoundaryB  = nil
    self.mViewCentOffset = cc.p(0.0, 0.0)
    self.mFollowActorPos = cc.p(0.0, 0.0)

    self:Init()
end

function gameCameraController:destory()
    if self.mCamera then 
        self.mCamera:autorelease()
        self.mCamera = nil
    end
end

function gameCameraController:create()
    local _this = gameCameraController.new()
    return _this
end

function gameCameraController:Init()
    self:InitMapScrollFollow()
end

function gameCameraController:Tick(dt)
    self:FollowMainPlayer()
end

function gameCameraController:InitMapScrollFollow()
    local  winSize = global.Director:getWinSize()
    self.mFullScreenSize = cc.p(winSize.width, winSize.height)
    self.mHalfScreenSize = cc.pMul(self.mFullScreenSize, 0.5)

    local pcOffset = cc.p(-22, -80)
    if global.isWinPlayMode and SL:GetValue("GAME_DATA", "PCMapCenterOffset") then
        local valueList = G_GetSplitArray(SL:GetValue("GAME_DATA", "PCMapCenterOffset"), "|")
        if tonumber(valueList[1]) and tonumber(valueList[2]) then
            pcOffset.x = tonumber(valueList[1])
            pcOffset.y = tonumber(valueList[2])
        end
    end

    local offset = global.isWinPlayMode and pcOffset or cc.p(0.0, 0.0)
    self:SetViewCenterOffset(offset.x, offset.y)
end

function gameCameraController:SetViewCamera(camera)
    self.mCamera = camera

    if self.mCamera then
        self.mCamera:retain()
    end
end

function gameCameraController:GetViewCamera()
    return self.mCamera
end

function gameCameraController:SetViewSize(size)
    self.mViewSize = size
end

function gameCameraController:GetViewSize() 
    if self.mViewSize then
        return self.mViewSize
    end

    local size = global.Director:getWinSize()
    if self.mCamera then
        local scaleX, scaleY = CalcCameraZoom(self.mCamera)
        size.width  = math.ceil(size.width  * scaleX)
        size.height = math.ceil(size.height * scaleY)
    end
    self.mViewSize = size
    
    return self.mViewSize
end

function gameCameraController:SetViewCenterOffset(x, y)
    self.mViewCentOffset.x = x
    self.mViewCentOffset.y = y

    global.sceneManager:SetViewCenterOffset(self.mViewCentOffset.x, self.mViewCentOffset.y)
end

function gameCameraController:GetViewCenterOffset()
    return self.mViewCentOffset
end

function gameCameraController:FollowMainPlayer()
    if not self.mBoundaryB then 
        return
    end

    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then 
        return 
    end

    local playerPos = mainPlayer:getPosition()
    if self.mFollowActorPos.x == playerPos.x and self.mFollowActorPos.y == playerPos.y then
        return
    end

    self.mFollowActorPos.x = playerPos.x
    self.mFollowActorPos.y = playerPos.y

    if self.mCamera then
        local tempPos = cc.pAdd(playerPos, self.mViewCentOffset)
        self.mCamera:setPosition(tempPos)
    end
end

function gameCameraController:CalcMapFollowParam(width, height)
    self.mBoundaryL = self.mHalfScreenSize.x
    self.mBoundaryR = math.max(width - self.mHalfScreenSize.x, 0)
    self.mBoundaryT = -self.mHalfScreenSize.y
    self.mBoundaryB = math.min(-(height - self.mHalfScreenSize.y), 0)
end

return gameCameraController
