local tremove = table.remove
local tinsert = table.insert

local INFINITY_COST = 0xFFFFFF
local BIAS_VALUE    = 14
local LINE_VALUE    = 10



local PathNode = class("PathNode")
function PathNode:ctor()
    self.x          = 0
    self.y          = 0
    self.t          = "new"
    self.g          = 0
    self.h          = 0
    self.f          = 0
    self.isObstacle = 0
    self.backpointer = nil
end

-- 
local PathFindAStar = class('PathFindAStar')

function PathFindAStar:ctor()
    self.mapNodes  = {}
    self.openlist  = {}
    self.mapData   = nil
end

function PathFindAStar:cleanup()
    self.startPathNode = nil
    self.endPathNode = nil

    self.mapNodes  = {}
    self.openlist  = {}
end

function PathFindAStar:updateLimits(begX, begY, endX, endY)
    local mapData = global.sceneManager:GetMapData2DPtr()
    self.mapRows  = mapData:getMapDataRows()
    self.mapCols  = mapData:getMapDataCols()

    local disX = 24
    local disY = 16
    self.minX  = math.min(math.max(begX - disX, 0), self.mapCols-1)
    self.maxX  = math.min(math.max(begX + disX, 0), self.mapCols-1)
    self.minY  = math.min(math.max(begY - disY, 0), self.mapRows-1)
    self.maxY  = math.min(math.max(begY + disY, 0), self.mapRows-1)

    local limits = {}
    for x = self.minX, self.maxX do
        limits[x] = {}
        for y = self.minY, self.maxY do
            limits[x][y] = mapData:isObstacle(x, y)
        end
    end
    return limits
end

function PathFindAStar:getPathNode(x, y)
    if not self.mapData[x] or not self.mapData[x][y] then
        return nil
    end
    if self.mapNodes[x] and self.mapNodes[x][y] then
        return self.mapNodes[x][y], true
    end

    local node = PathNode.new()
    node.x = x
    node.y = y
    node.g = 0
    node.h = 0
    node.f = 0
    node.t = "new"
    node.backpointer = nil
    node.isObstacle = self.mapData[x][y]

    if not self.mapNodes[x] then
        self.mapNodes[x] = {}
    end
    self.mapNodes[x][y] = node

    return node
end

function PathFindAStar:traverseAround(node)
    local around = 
    {
        { node.x + 1, node.y     }, -- right
        { node.x,     node.y + 1 }, -- bottom
        { node.x - 1, node.y     }, -- left
        { node.x,     node.y - 1 }, -- top
        { node.x + 1, node.y - 1 }, -- right up    
        { node.x + 1, node.y + 1 }, -- right bottom
        { node.x - 1, node.y + 1 }, -- left bottom
        { node.x - 1, node.y - 1 }, -- left top    
    }

    for i = 1, 8 do
        local x = around[i][1]
        local y = around[i][2]
    
        -- not out of bounds
        local unitCost = i > 4 and BIAS_VALUE or LINE_VALUE
        if (x >= self.minX and x <= self.maxX and y >= self.minY and y <= self.maxY) and self.mapData[x][y] == 0 then
            local node_n, isExist = self:getPathNode(x, y)
            if isExist then
                if ((node.g + unitCost) < node_n.g) or (node_n == self.endPathNode and node_n.g == 0) then
                    node_n.backpointer = node
                    self:insert(node_n, node.g + unitCost)
                end
            elseif node_n then
                node_n.g = node.g + unitCost
                node_n.h = (math.abs(self.endPathNode.x - x) + math.abs(self.endPathNode.y - y)) * LINE_VALUE
                node_n.f = node_n.g + node_n.h
                node_n.backpointer = node
                self:insert(node_n)
            end           
        end
    end

end

function PathFindAStar:getMinFNode()
    local node  = nil
    local f     = nil
    local index = nil
    for i, v in ipairs(self.openlist) do
        if not node or v.f < node.f then
            node  = v
            f     = node.f
            index = i
        end
    end
    return node, f, index
    -- table.sort(self.openlist, function(a, b)
    --     if a.f == b.f then
    --         return a.h < b.h
    --     else
    --         return a.f < b.f
    --     end
    -- end)
    -- node = self.openlist[1]
    -- return node, node.f, 1
end

function PathFindAStar:insert(node, g_new)
    if node.t == "new" then
        if g_new then
            node.g = g_new
            node.f = node.g + node.h
        end
        node.t = "open"
        tinsert(self.openlist, node)

    elseif node.t == "open" then
        node.g = math.min(node.g, g_new)
        node.f = node.g + node.h

    elseif node.t == "closed" then
        node.g = math.min(node.g, g_new)
        node.f = node.g + node.h
        node.t = "open"
        tinsert(self.openlist, node)
    end

    return true
end

function PathFindAStar:process_state(currentNode, index)
    if #self.openlist == 0 then
        return -1
    end

    self:traverseAround(currentNode)

    currentNode.t = "closed"
    table.remove(self.openlist, index)

    if #self.openlist == 0 then
        return -1
    end

end

function PathFindAStar:find_path_limit(begX, begY, endX, endY, limitCount)
    self:cleanup()
    
    local points = {}

    if false == global.PathFindController:CheckMoveAble(endX, endY) then
        return points
    end

    self.mapData        = self:updateLimits(begX, begY, endX, endY)
    self.startPathNode  = self:getPathNode(begX, begY)
    self.endPathNode    = self:getPathNode(endX, endY)
    if nil == self.startPathNode or nil == self.endPathNode then
        return points
    end

    if math.abs(self.startPathNode.x - self.endPathNode.x) <= 1 and math.abs(self.startPathNode.y - self.endPathNode.y) <= 1 then
        tinsert(points, {x=self.startPathNode.x, y=self.startPathNode.y})
        return points
    end

    -- start
    self:insert(self.startPathNode, 0)
    local findCount = 0
    local findOut = false
    while true do
        local currentNode, currentF, index = self:getMinFNode()
        local ret = self:process_state(currentNode, index)
        if ret == -1 then
            return points
        elseif self.endPathNode.t == "closed" then
            break
        end
        findCount = findCount + 1
        if findCount > limitCount then
            findOut = true
            break
        end
    end

    -- points
    tinsert(points, {x = self.endPathNode.x, y = self.endPathNode.y})
    local node = self.endPathNode.backpointer
    if not node then
        points = {}
        return points
    end
    while node ~= self.startPathNode do
        tinsert(points, {x = node.x, y = node.y})
        node = node.backpointer

        if nil == node then
            points = {}
            break
        end
    end

    return points
end

return PathFindAStar
