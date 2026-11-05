local dropItemController = class("dropItemController")
dropItemController.NAME = "dropItemController"

local proxyUtils                = requireUtil("proxyUtils")
local DROPITEM_RES_PATH         = "res/item"
local DROPITEM_GROUND_RES_PATH  = "res/item_ground"
local sformat                   = string.format

function dropItemController:ctor()
    self.mLastDropItemX = 0xFFFF
    self.mLastDropItemY = 0xFFFF
    self.mTryCheckDrop  = 0.0
    self.mLooksCache    = {}

    self:Init()
end

function dropItemController:destory()
end

function dropItemController:create()
    local _this = dropItemController.new()
    return _this
end

function dropItemController:Cleanup()
    self.mLastDropItemX = 0xFFFF
    self.mLastDropItemY = 0xFFFF
    self.mTryCheckDrop  = 0.0
    self.mLooksCache    = {}
end

function dropItemController:Init()
    local function loadCallback(actorID, act)
        self:OnPlayerActCompleted(actorID, act)
    end
    global.gamePlayerController:AddHandleOnActCompleted(loadCallback)
end

function dropItemController:Tick(delta)
    self.mTryCheckDrop = self.mTryCheckDrop + delta
    self:CheckPickSprite(delta)
end

function dropItemController:CheckPickSprite(delta)
    -- dump(delta,"delta__")
    local PickupSpriteProxy = global.Facade:retrieveProxy(global.ProxyTable.PickupSpriteProxy)
    if PickupSpriteProxy:getPickupSpriteState() then
        local time = PickupSpriteProxy:getTickTime()
        local delay = PickupSpriteProxy:getDelayTime() + 200--+200延时不然服务器不认
        time = time + delta * 1000
        if time > delay then
            time = 0
            global.Facade:sendNotification(global.NoticeTable.AutoPickupBySprite)
        end
        PickupSpriteProxy:setTickTime(time)
    end
end

function dropItemController:HandleDropItemPick(mapX, mapY)
    local pickInterval = SL:GetValue("GAME_DATA", "PickupTime")
    if self.mTryCheckDrop <= (pickInterval * 0.001) then
        return 1
    end

    -- 同位置时，1s间隔
    if self.mLastDropItemX == mapX and self.mLastDropItemY == mapY and self.mTryCheckDrop <= 1 then
        return 1
    end


    local dItems = global.dropItemManager:FindAllDropItemByXY(mapX, mapY)

    if not dItems then
        return
    end

    local bagfull   = BagData.isToBeFull()
    local pickable = false
    for k, dItem in pairs(dItems) do
        if dItem and proxyUtils:DropItemPickEnable(dItem) and dItem:IsPickEnable() then
            if not bagfull then
                dItem:PickStateMark()
            end
            pickable = true
            break
        end
    end

    if pickable then
        self.mLastDropItemX = mapX
        self.mLastDropItemY = mapY
        self.mTryCheckDrop  = 0

        LuaSendMsg(global.MsgType.MSG_CS_MAP_ITEM_PICK, mapX, mapY ,0 , 0)
    end

    return 1
end

function dropItemController:AddDropItemToWorld(item)
    -- if exist, change ownerID
    local id        = item.Id
    local mapX      = item.X
    local mapY      = item.Y
    local looks     = item.Looks
    local ownerID   = item.Of
    local MakeIndex = item.MakeIndex
    local ShowItemDropEff = item.ShowItemDropEff


    local p = {}
    p.cloth = looks
    p.ownerID = ownerID

    local dropItem = global.actorManager:CreateActor(id, global.MMO.ACTOR_DROPITEM, p, true)
    dropItem:SetMakeIndex(MakeIndex)
    dropItem:SetDropShake(ShowItemDropEff)
    
    -- position
    -- To map grid position.
    dropItem.mCurrMapX = mapX
    dropItem.mCurrMapY = mapY
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    dropItem:setPosition(wX, wY)

    return dropItem
end

function dropItemController:RmvDropItemFromWorld(id)
    -- to drop item manager
    global.dropItemManager:RmvDropItem(id)
    global.actorManager:RemoveActor(id)
end

function dropItemController:OnPlayerActCompleted(actorID, act)
    if global.MMO.ACTION_DIE ~= act and global.MMO.ACTION_DEATH ~= act then
        self:HandleDropItemPick(SL:GetValue("X", actorID), SL:GetValue("Y", actorID))
    end
end

function dropItemController:PickMainPlayerPosItem(targetPos)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return false
    end
    local mapX = mainPlayer:GetMapX()
    local mapY = mainPlayer:GetMapY()

    if targetPos and next(targetPos) then
        if targetPos.mapX ~= mapX or targetPos.mapY ~= mapY then
            return false
        end
    end

    -- 拾取间隔
    local pickInterval = SL:GetValue("GAME_DATA", "PickupTime")
    if self.mTryCheckDrop <= (pickInterval * 0.001) then
        return false
    end

    -- 同位置时，1s间隔
    if self.mLastDropItemX == mapX and self.mLastDropItemY == mapY and self.mTryCheckDrop <= 1 then
        return false
    end

    local dItems = global.dropItemManager:FindAllDropItemByXY(mapX, mapY)

    if not dItems or not next(dItems) then
        return false
    end

    self.mLastDropItemX = mapX
    self.mLastDropItemY = mapY
    self.mTryCheckDrop  = 0

    LuaSendMsg(global.MsgType.MSG_CS_MAP_ITEM_PICK, mapX, mapY , 0, 0)

    return true
end

function dropItemController:GetItemGroundFile(looks)
    if not (self.mLooksCache[looks]) then
        local fileIndex     = looks % 10000
        local fileName      = sformat(GET_STRING(1070), fileIndex)
        local pathIndex     = math.floor(looks / 10000)
        local groundFile    = sformat("%s/item_ground_%s/%s.png", DROPITEM_GROUND_RES_PATH, pathIndex, fileName)
        groundFile          = global.FileUtilCtl:isFileExist(groundFile) and groundFile or sformat("%s/item_%s/%s.png", DROPITEM_RES_PATH, pathIndex, fileName)
        self.mLooksCache[looks] = groundFile
    end
    return self.mLooksCache[looks]
end

return dropItemController