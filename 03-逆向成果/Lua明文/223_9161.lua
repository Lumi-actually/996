local DebugMediator  = requireMediator("DebugMediator")
local tileSceneManagerHelper = class("tileSceneManagerHelper", DebugMediator)
local SceneDefine = require("scene/sceneDefine")

tileSceneManagerHelper.Name = "tileSceneManagerHelper"

local AtlasSplitConfigs = SceneDefine.AtlasSplitConfigs
local FrameOffset     = SceneDefine.FrameOffset
local ObjMaxOffsetY   = SceneDefine.ObjMaxOffsetY

local MapGridWidth  = global.MMO.MapGridWidth
local MapGridHeight = global.MMO.MapGridHeight

function tileSceneManagerHelper:ctor()
    tileSceneManagerHelper.super.ctor(self)

    self._mapDataPath = nil
end

function tileSceneManagerHelper:destory()
    global.Facade:removeMediator(tileSceneManagerHelper.NAME)
end

function tileSceneManagerHelper:create()
    local _this = tileSceneManagerHelper.new()
    global.Facade:registerMediator(_this)
    return _this
end

function tileSceneManagerHelper:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return
    {
        noticeTable.InitedWorldTree,
        noticeTable.BindMainPlayer,
        noticeTable.MainPlayerActionEnded,
        noticeTable.MainPlayerActionProcess,
        noticeTable.ReleaseMemory,
        noticeTable.ChangeScene,
        noticeTable.ReloadMap,
        noticeTable.SceneFollowMainPlayer,
    }
end

function tileSceneManagerHelper:handleNotification(notification)
    local noticeName  = notification:getName()
    local noticeTable = global.NoticeTable
    local noticeData  = notification:getBody()

    if noticeTable.InitedWorldTree == noticeName then
        self:OnInitedWorldTree()

    elseif noticeTable.BindMainPlayer == noticeName then
        self:onBindMainPlayer(noticeData)

    elseif noticeTable.MainPlayerActionEnded == noticeName then
        self:onMainPlayerActionEnded(noticeData)

    elseif noticeTable.MainPlayerActionProcess == noticeName then
        self:onMainPlayerActionProcess(noticeData)

    elseif noticeTable.ChangeScene == noticeName then
        self:onEnterMap(noticeData)

    elseif noticeTable.SceneFollowMainPlayer == noticeName then
        self:onSceneFollowMainPlayer(noticeData)

    elseif noticeTable.ReloadMap == noticeName then
        self:reloadAllTile()

    elseif noticeTable.ReleaseMemory == noticeName then
        self:Cleanup()
    end
end

function tileSceneManagerHelper:OnInitedWorldTree()
    if global.sceneManager then
        local sceneManager = global.sceneManager

        local mapRoot = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_MAP)
        local actRoot = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_ACTOR_SPRITE)
        local objRoot = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_MAP_OBJ)
        local tileRootNode   = cc.Node:create()
        local smtileRootNode = cc.Node:create()
        local objRootNode    = actRoot
        local miniRootNode   = cc.Node:create()
        local debugRootNode  = cc.Node:create()
        if SL:GetValue("GAME_DATA", "ForbidPreMiniMapShow") == 1 then
            miniRootNode:setVisible(false)
        end
        mapRoot:addChild(tileRootNode)
        mapRoot:addChild(smtileRootNode)
        mapRoot:addChild(miniRootNode, -1)
        objRoot:addChild(debugRootNode)
        sceneManager:SetRootNode(tileRootNode, smtileRootNode, objRootNode, miniRootNode, debugRootNode)


        local camera = global.gameCameraController:GetViewCamera()
        sceneManager:SetCamera(camera)


        if AtlasSplitConfigs then
            for atlasType, splitConfig in pairs(AtlasSplitConfigs) do
                for area, splitSize in pairs(splitConfig) do
                    sceneManager:SetAtlasSplit(atlasType - 1, area, splitSize)
                end
            end
        end

        if ObjMaxOffsetY then
            for mapID, enlargeY in pairs(ObjMaxOffsetY) do
                sceneManager:SetObjEnlargeY(mapID, enlargeY)
            end
        end

        if FrameOffset then
            for area, offsets in pairs(FrameOffset) do
                for imgIdx, offset in pairs(offsets) do
                    sceneManager:SetFrameAnimOffset(area, imgIdx, offset.x, offset.y)
                end
            end
        end

        sceneManager:SetLoadParam(2, 180)
        sceneManager:SetLoadMapDataCallback(handler(self, self.onLoadMapDataCallback))
        sceneManager:SetLoadMiniCallback(handler(self, self.onLoadMiniCallback))
        sceneManager:SetOnOpenDoorFunc(handler(self, self.onOpenDoorCallback))
        sceneManager:SetOnCloseDoorFunc(handler(self, self.onCloseDoorCallback))
    end
end

function tileSceneManagerHelper:onBindMainPlayer(player)
    self:followPlayer(player)
end

function tileSceneManagerHelper:onSceneFollowMainPlayer()
    self:FollowMainPlayer()
end

function tileSceneManagerHelper:onMainPlayerActionEnded(act)
    if GUIFunction:IsMoveAction(act) then
        local player = global.gamePlayerController:GetMainPlayer()
        self:followPlayer(player)
    end
end

function tileSceneManagerHelper:onMainPlayerActionProcess(action)
    local mmo = global.MMO
    if mmo.ACTION_DASH == action or mmo.ACTION_ONPUSH == action or mmo.ACTION_TELEPORT == action or mmo.ACTION_ZXC then
        self:FollowMainPlayer()
    end
end

function tileSceneManagerHelper:onEnterMap(mapID)
    if global.sceneManager then
        local mapDataPath = string.format("scene/map/%s.map", tostring(mapID))
        local mapMiniPath = ""
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        if mapProxy then
            local miniFile = mapProxy:GetMiniMapFile()
            if miniFile then
                mapMiniPath = miniFile
            end

            local mapDataID = mapProxy:GetMapDataID()
            print("mapDataIDDDDDDDDDDDDDDD", mapDataID)
            if mapDataID then
                mapDataPath = string.format("scene/map/%s.map", tostring(mapDataID))
            end
        end

        if self._mapDataPath ~= mapDataPath then
            --清理光圈  因为changeScene 和 Load_Success不一定哪个先 所以放这
            global.darkNodeManager:clearAllNodes(true)
            global.sceneManager:LoadMap(mapID, mapDataPath, mapMiniPath)
        end
        self._mapDataPath = mapDataPath
    end

    self:FollowMainPlayer()
end

function tileSceneManagerHelper:reloadAllTile()
    if global.sceneManager then
        global.sceneManager:reloadAllTile()

        self:FollowMainPlayer()
    end
end

function tileSceneManagerHelper:Cleanup()
    if global.sceneManager then
        global.sceneManager:Cleanup()
    end
end

function tileSceneManagerHelper:FollowMainPlayer()
    local player = global.gamePlayerController:GetMainPlayer()
    self:followPlayer(player)
end

local followPlayerPosT = {}
function tileSceneManagerHelper:followPlayer(player)
    if player then 
        followPlayerPosT.x = player.mPositionX
        followPlayerPosT.y = player.mPositionY
        if global.sceneManager then
            global.sceneManager:followPlayer(followPlayerPosT)
        end
        if global.darkNodeManager then 
            global.darkNodeManager:followPlayer(followPlayerPosT)
        end
    end
end

function tileSceneManagerHelper:onLoadMapDataCallback(mapID, mapWidthInPixel, mapHeightInPixel)
    print("onLoadMapDataCallback", mapID, mapWidthInPixel, mapHeightInPixel)

    global.gameCameraController:CalcMapFollowParam(mapWidthInPixel, mapHeightInPixel)
    self:FollowMainPlayer()

    global.Facade:sendNotification(global.NoticeTable.MapData_Load_Success)
    SLBridge:onLUAEvent(LUA_EVENT_MAPDATA_LOAD_SUCCESS, mapID)
end
function tileSceneManagerHelper:onLoadMiniCallback(mapID, miniName)
    print("onLoadMiniCallback", mapID, miniName)

    local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    if mapProxy then
        SLBridge:onLUAEvent(LUA_EVENT_MINIMAP_DOWNLOAD_SUCCESS, mapProxy:GetMiniMapID())
    end
end
function tileSceneManagerHelper:onOpenDoorCallback(mapX, mapY)
    print("onOpenDoorCallback", mapX, mapY)
end
function tileSceneManagerHelper:onCloseDoorCallback(mapX, mapY)
    print("onCloseDoorCallback", mapX, mapY)
end
--------------------------------------------------------------

local tileSceneManager = tileSceneManager
if tileSceneManager then
    function tileSceneManager:destory()
        global.Facade:removeMediator(tileSceneManagerHelper.NAME)
    end

    function tileSceneManager:WorldPos2MapPos(worldX, worldY)
        return math.floor(worldX / MapGridWidth), math.floor(-worldY / MapGridHeight)
    end

    function tileSceneManager:MapPos2WorldPos(mapX, mapY, centerOfGrid)
        local worldX = mapX * MapGridWidth
        local worldY = -mapY * MapGridHeight

        if centerOfGrid then
            worldX = worldX + MapGridWidth * 0.5
            worldY = worldY - MapGridHeight * 0.5
        end

        return worldX, worldY
    end
end

return tileSceneManagerHelper
