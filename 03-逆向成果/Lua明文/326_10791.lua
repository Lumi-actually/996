------------
local lightNode = class("lightNode")

local darkNodeManager = class("darkNodeManager")
local MAXNODE = 200 -- 最多有多少个圈

function darkNodeManager:ctor()
    self._nodeInfo = {}
    self._nodeNum = 0
    self._mapLight = {}
end

function darkNodeManager:destory()
end

function darkNodeManager:create()
    local _this = darkNodeManager.new()
    return _this
end

function darkNodeManager:Cleanup()
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    self._nodeInfo = {}
    self._nodeNum = 0
end

---MapGridWidth      = 48,                   -- 地图格子宽度
-- MapGridHeight     = 32,                   -- 地图格子高度
local MapGridWidth = global.MMO.MapGridWidth
--- data { pos ,  t} -> {x,y,r,w}
function darkNodeManager:createNode(data)-- 光圈数据  {x,y,r,w} --x,y世界坐标 r光圈半径 w 渐变宽度
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    -- return 
    local index
    --最多两百个圈
    for i = 1, MAXNODE do
        if not self._nodeInfo[i .. ""] then
            index = i .. ""
            break
        end
    end
    if _DEBUG and not index then
        dump("200个圈了！！！")
    end
    if index then 
        
        local offset = data.offset or cc.p(0, 0) 
        self._nodeInfo[index] = { x = data.x + offset.x, y = data.y + offset.y, r = data.r * MapGridWidth , w = data.w * MapGridWidth}
        self._nodeNum = self._nodeNum + 1
    end
    return index
end

function darkNodeManager:updateNode(index, data) -- 
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    if not index then 
        return false
    end
    local light = self._nodeInfo[index] 
    if not light then
        return false
    end

    if data.r then 
        light.r = data.r * MapGridWidth
    end
    if data.w then 
        light.w = data.w * MapGridWidth 
    end

    local offset = cc.p(0, 0)
    if data.offset then 
        offset = data.offset
    end

    if data.x then 
        light.x = data.x + offset.x
    end
    
    if data.y then 
        light.y = data.y + offset.y
    end
    
    return true
end

function darkNodeManager:removeNode(index) -- 
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    if not index then 
        return false
    end
    local light = self._nodeInfo[index]
    if not light then
        return false
    end
    self._nodeInfo[index] = nil
    self._nodeNum = self._nodeNum - 1
    return true
end
--b 是否保留自己的灯光
function darkNodeManager:clearAllNodes(b) -- 
    if SL:GetValue("GAME_DATA", "dark") ~= 1 then
        return
    end
    if b then 
        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        local id
        if mainPlayer then
            id = mainPlayer:GetLightID()
        end
        local light = self._nodeInfo[id]
        self._nodeInfo = {}
        self._nodeNum = 0
        if light then 
            self._nodeInfo[id] = light
            self._nodeNum = 1
        end
    else
        self._nodeInfo = {}
        self._nodeNum = 0
    end
    self._mapLight = {}
    
end

function darkNodeManager:getAllNodes()
    return self._nodeInfo
end

function darkNodeManager:getNodeNums()
    return self._nodeNum
end
------------------
--地图数据相关
function darkNodeManager:InitmapInfo()
    local mapData = global.sceneManager:GetMapData2DPtr()
    local needLoadLight = false
    repeat
        if not mapData then
            break
        end
        if not mapData.GetLight then
            break
        end
        if SL:GetValue("GAME_DATA", "dark") ~= 1 then
            break
        end
        needLoadLight = true
    until true
    self._mapRows = mapData:getMapDataRows()
    self._mapCols = mapData:getMapDataCols()
    self._needLoadLight = needLoadLight
    self._lastTilesArea = cc.rect(0,0,0,0)
    self._tilesArea = cc.rect(0,0,0,0)
    self._screenArea = cc.rect(0,0,0,0)
end

function darkNodeManager:followPlayer(pos)
    self:calcScreenAreaRect(pos)
    self:calcScreenLight()
    self:loadScreenTile()
end

function darkNodeManager:SetRect(rectT, x, y, width, height)
    rectT.x = x
    rectT.y = y
    rectT.width = width
    rectT.height = height
end

function darkNodeManager:calcScreenAreaRect(pos)
    if not self._needLoadLight then 
        return 
    end
    local viewSize =  global.gameCameraController:GetViewSize()
    local centerOffset =  global.gameCameraController:GetViewCenterOffset()
    local centerOfViewW = viewSize.width/2 + centerOffset.x
    local centerOfViewH = viewSize.height/2 + centerOffset.y
    local  x = pos.x;
    local  y = -pos.y;
    self:SetRect(self._screenArea, x - centerOfViewW, y - centerOfViewH, viewSize.width, viewSize.height)
end

function darkNodeManager:calcScreenLight()
    if not self._needLoadLight then 
        return 
    end
    local queryRect = self._screenArea
    local  minX, minY;
    local  maxX, maxY;
    local  sliceW = global.MMO.MapGridWidth;
    local  sliceH = global.MMO.MapGridHeight;
    local  offset = global.gameCameraController:GetViewCenterOffset()
    minX = queryRect.x / sliceW;
    minX = (minX > 0) and  minX or 0;
    minY = queryRect.y
    minY = minY / sliceH;
    minY = (minY > 0) and  minY or 0;
    maxX = cc.rectGetMaxX(queryRect)
    maxX = maxX / sliceW;
    maxX = (maxX % sliceW > 0 and  maxX < self._mapCols) and  maxX + 1 or maxX
    maxY = cc.rectGetMaxY(queryRect)
    maxY = maxY / sliceH;
    maxY = (maxY % sliceH > 0 and  maxY < self._mapRows) and  maxY + 1 or maxY
    minX = math.max(0, minX - 4);
    minY = math.max(0, minY - 3);
    maxX = math.min(maxX + 3, self._mapCols - 1);
    maxY = math.min(maxY + 3, self._mapRows - 1);
    self:SetRect(self._lastTilesArea, self._tilesArea.x, self._tilesArea.y, self._tilesArea.width, self._tilesArea.height)
    self:SetRect(self._tilesArea, minX, minY, maxX - minX, maxY - minY)
end

local rectIntersectionT = {}
function darkNodeManager:rectIntersection (rect1, rect2)
    local x = math.max(rect1.x, rect2.x)
    local y = math.max(rect1.y, rect2.y)
    local width = math.min(rect1.x + rect1.width, rect2.x + rect2.width) - x;
    local height = math.min(rect1.y + rect1.height, rect2.y + rect2.height) - y;
    local rect = cc.rect(x, y, width, height)
    self:SetRect(rectIntersectionT, x, y, width, height)
    return rectIntersectionT
end

function darkNodeManager:loadScreenTile()
    if not self._needLoadLight then 
        return 
    end
    local  isInter = cc.rectIntersectsRect( self._tilesArea, self._lastTilesArea ) 
    if not isInter then 
        self:UnloadAllLight();
        self:LoadLightInRect(self._tilesArea);
    else
        local  interRect = self:rectIntersection(self._lastTilesArea, self._tilesArea);
        
        local unLoadTileArray = self:GetDiffRect(self._lastTilesArea, interRect);
        for i, rect in ipairs(unLoadTileArray) do
            self:UnLoadLightInRect(rect);
        end
        
        local loadTileArray = self:GetDiffRect(self._tilesArea, interRect);
        for i, rect in ipairs(loadTileArray) do
            self:LoadLightInRect(rect);
        end
    end

end

local cacheT = {}
local cacheT1 = {}
local cacheT2 = {}
function darkNodeManager:GetDiffRect(originRect, interRect)
    cacheT[1] = nil
    cacheT[2] = nil
    local dx = interRect.x - originRect.x;
    if dx ~= 0 or interRect.width ~= originRect.width then 
        local beginX = originRect.x;
        local endX = beginX + dx - 1;
        if dx == 0 then 
            beginX = cc.rectGetMaxX(interRect) + 1;
            endX = cc.rectGetMaxX(originRect);
        end

        local beginY = originRect.y;
        local endY = beginY + originRect.height;
        self:SetRect(cacheT1, beginX, beginY, endX - beginX, endY - beginY)
        cacheT[#cacheT + 1] = cacheT1
    end

    local dy = interRect.y - originRect.y;
    if dy ~= 0 or interRect.height ~= originRect.height then
        local beginX = math.max(interRect.x, originRect.x);
        if dx == 0 then 
            beginX = interRect.x;
        end
        local endX = beginX + interRect.width;

        local beginY = originRect.y;
        local endY = beginY + dy - 1;
        if dy == 0 then 
            beginY = cc.rectGetMaxY(interRect) + 1;
            endY = cc.rectGetMaxY(originRect)
        end
        self:SetRect(cacheT2, beginX, beginY, endX - beginX, endY - beginY)
        cacheT[#cacheT + 1] = cacheT2
    end
    return cacheT
end

function darkNodeManager:UnloadAllLight()
    for k, v in pairs(self._mapLight) do
        self:removeNode(v)
    end
    self._mapLight = {}
end

function darkNodeManager:UnLoadLightInRect(rect)
    local minX = math.ceil(rect.x);
    local minY = math.ceil(rect.y);
    local maxX = math.ceil(cc.rectGetMaxX(rect));
    local maxY = math.ceil(cc.rectGetMaxY(rect));
    for  y = minY, maxY do
        for x = minX, maxX do
            self:UnLoadOneLight(x,y)
        end
    end
end

function darkNodeManager:LoadLightInRect(rect)
    local minX = math.floor(rect.x);
    local minY = math.floor(rect.y);
    local maxX = math.floor(cc.rectGetMaxX(rect));
    local maxY = math.floor(cc.rectGetMaxY(rect));
    for  y = minY, maxY do
        for x = minX, maxX do
            self:LoadOneLight(x,y)
        end
    end
end

local LoadOneLightT = {}
function darkNodeManager:LoadOneLight(x,y)
    if not self._needLoadLight then
        return
    end
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then 
        return 
    end
    local light = mapData:GetLight(x, y)
    local DarkLayerProxy = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
    if light > 0 then
        local index = string.format("%s_%s",x,y)
        local wX, wY = global.sceneManager:MapPos2WorldPos(x, y, true)
        local param = DarkLayerProxy.LIGHT_TYPE.Two_Skill
        LoadOneLightT.x = wX
        LoadOneLightT.y = wY
        LoadOneLightT.r = param.r 
        LoadOneLightT.w = param.w
        self._mapLight[index] = self:createNode(LoadOneLightT)
    end
end

function darkNodeManager:UnLoadOneLight(x,y)
    if not self._needLoadLight then
        return
    end
    local index = string.format("%s_%s",x,y)
    if self._mapLight[index] then
        self:removeNode(self._mapLight[index])
        self._mapLight[index] = nil
    end
end
------------------
return darkNodeManager