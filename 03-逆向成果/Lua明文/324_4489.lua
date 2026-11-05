local dropItemManager = class('dropItemManager')

local tSort = table.sort
local mAbs = math.abs

function dropItemManager:ctor()
    self.mDropItemMapXYInCurrViewField = {}
    self.mDropItemInCurrViewFieldMap = {}
    self.mDropItemInCurrViewField = {}
    self.mDropItemIndexMap = {}
    self.mDropItemCount = 0
end

function dropItemManager:destory()
end

function dropItemManager:create()
    local _this = dropItemManager.new()
    return _this
end

function dropItemManager:Cleanup()
    self.mDropItemMapXYInCurrViewField = {}
    self.mDropItemInCurrViewFieldMap = {}
    self.mDropItemInCurrViewField = {}
    self.mDropItemIndexMap = {}
    self.mDropItemCount = 0
end

function dropItemManager:FindOneDropItemByID(id)
    return self.mDropItemInCurrViewFieldMap[id]
end

function dropItemManager:AddDropItem(item)
    if not item then
        return false
    end

    local itemID = item:GetID()

    if self.mDropItemInCurrViewFieldMap[itemID] then
        return false
    end

    self.mDropItemCount = self.mDropItemCount + 1

    local n = self.mDropItemCount

    self.mDropItemIndexMap[itemID] = n

    self.mDropItemInCurrViewField[n] = item

    self.mDropItemInCurrViewFieldMap[itemID] = item

    local point = G_ActorUtils.KEY_MAP_XY(item:GetMapX(), item:GetMapY())
    if not self.mDropItemMapXYInCurrViewField[point] then
        self.mDropItemMapXYInCurrViewField[point] = {}
    end
    self.mDropItemMapXYInCurrViewField[point][itemID] = item
end

function dropItemManager:RmvDropItem(itemID)
    local item = self.mDropItemInCurrViewFieldMap[itemID]

    if not item then
        return false
    end

    self.mDropItemInCurrViewFieldMap[itemID] = nil

    local index = self.mDropItemIndexMap[itemID]
    if index == self.mDropItemCount then
        self.mDropItemInCurrViewField[index] = nil
    else
        -- last index --> index
        local lastActor = self.mDropItemInCurrViewField[self.mDropItemCount]
        self.mDropItemInCurrViewField[index] = lastActor
        self.mDropItemIndexMap[lastActor:GetID()] = index

        -- reset last value
        self.mDropItemInCurrViewField[self.mDropItemCount] = nil
    end

    self.mDropItemIndexMap[itemID] = nil
    self.mDropItemCount = self.mDropItemCount - 1

    local point = G_ActorUtils.KEY_MAP_XY(item:GetMapX(), item:GetMapY())
    local itemMapXY = self.mDropItemMapXYInCurrViewField[point][itemID]
    if not itemMapXY then
        return false
    end
    self.mDropItemMapXYInCurrViewField[point][itemID] = nil
end

function dropItemManager:FindAllDropItemInCurrViewField()
    return self.mDropItemInCurrViewField, self.mDropItemCount
end

-- Find any items in range
local function inRange(a, range)
    if -1 == range then
        return true
    end
    local p = global.gamePlayerController:GetMainPlayer()
    if not p then
        return false
    end

    local mX = p:GetMapX()
    local mY = p:GetMapY()
    local dX = a:GetMapX() - mX
    local dY = a:GetMapY() - mY
    local diffA = (mAbs(dX) > mAbs(dY)) and mAbs(dX) or mAbs(dY)

    return diffA <= range
end
local function distCmp(a, b)
    local p = global.gamePlayerController:GetMainPlayer()
    if not p then
        return false
    end
    local mX = p:GetMapX()
    local mY = p:GetMapY()
    local dX = a:GetMapX() - mX
    local dY = a:GetMapY() - mY
    local diffA = (mAbs(dX) > mAbs(dY)) and mAbs(dX) or mAbs(dY)

    dX = b:GetMapX() - mX
    dY = b:GetMapY() - mY
    local diffB = (mAbs(dX) > mAbs(dY)) and mAbs(dX) or mAbs(dY)

    return diffA < diffB
end
function dropItemManager:FindDropItemInCurrViewFieldByRange(range, sortNearToFarFromPlayer)
    if nil == sortNearToFarFromPlayer then
        sortNearToFarFromPlayer = false
    end

    local recvVec = {}
    local num = 0
    for i = 1, self.mDropItemCount do
        local m = self.mDropItemInCurrViewField[i]
        if m and inRange(m, range) then
            num = num + 1
            recvVec[num] = m
        end
    end

    -- Need to sort ?
    if sortNearToFarFromPlayer and num > 1 then
        tSort(recvVec, distCmp)
    end

    return recvVec, num
end

function dropItemManager:FindAllDropItemByXY(X, Y)
    local point = G_ActorUtils.KEY_MAP_XY(X, Y)
    local itemMapXY = self.mDropItemMapXYInCurrViewField[point]

    return itemMapXY
end

return dropItemManager
