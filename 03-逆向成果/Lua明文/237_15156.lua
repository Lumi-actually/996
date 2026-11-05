local ObstacleController = class('ObstacleController', framework.Mediator)
ObstacleController.NAME = "ObstacleController"

local INVALID_MAP_POS = 0xFFFF

function ObstacleController:ctor()
    ObstacleController.super.ctor(self, self.NAME)

    self._obstacles = {}
end

function ObstacleController:destory()
    global.Facade:removeMediator( ObstacleController.NAME )
end

function ObstacleController:create()
    local _this = ObstacleController.new()
    global.Facade:registerMediator(_this)
    return _this
end

function ObstacleController:onRegister()
    ObstacleController.super.onRegister(self)

    local function actCallback(actor, act)
        -- 非移动类action
        if not GUIFunction:IsMoveAction(act) then
            return
        end

        self:DynamicPathPoints()
    end
    global.gamePlayerController:AddHandleOnActCompleted(actCallback)
end

function ObstacleController:listNotificationInterests()
    local noticeTable = global.NoticeTable
    return 
    {
        noticeTable.ActorInOfView,
        noticeTable.ActorOutOfView,
        noticeTable.ActorPlayerDie,
        noticeTable.ActorMonsterDie,
        noticeTable.ActorMonsterDeath,
        noticeTable.ActorRevive,
        noticeTable.ActorEffectInOfView,
        noticeTable.ActorEffectOutOfView,
        noticeTable.PlayerStallStatusChange,
        noticeTable.ActorSafeZoneChange,
        noticeTable.ActorMapXYChange,
        noticeTable.MapData_Load_Success,
        noticeTable.Map_Refresh_Throug_HHum,
    }
end

function ObstacleController:handleNotification(notification)
    local noticeTable = global.NoticeTable
    local noticeID = notification:getName()
    local data = notification:getBody()

    if noticeID == noticeTable.ActorInOfView then
        self:OnActorInOfView(data)

    elseif noticeID == noticeTable.ActorOutOfView then
        self:OnActorOutOfView(data)

    elseif noticeID == noticeTable.ActorPlayerDie then
        self:OnActorPlayerDie(data)

    elseif noticeID == noticeTable.ActorMonsterDie then
        self:OnActorMonsterDie(data)

    elseif noticeID == noticeTable.ActorMonsterDeath then
        self:OnActorMonsterDeath(data)
        
    elseif noticeID == noticeTable.ActorRevive then
        self:OnActorRevive(data)

    elseif noticeID == noticeTable.ActorEffectInOfView then
        self:OnActorEffectInOfView(data)

    elseif noticeID == noticeTable.ActorEffectOutOfView then
        self:OnActorEffectOutOfView(data)

    elseif noticeID == noticeTable.PlayerStallStatusChange then
        self:OnPlayerStallStatusChange(data)

    elseif noticeID == noticeTable.ActorSafeZoneChange then
        self:OnActorSafeZoneChange(data)
        
    elseif noticeID == noticeTable.ActorMapXYChange then
        self:OnActorMapXYChange(data)

    elseif noticeID == noticeTable.MapData_Load_Success then
        self:OnMapDataLoadSuccess()

    elseif noticeID == noticeTable.Map_Refresh_Throug_HHum then
        self:OnUpdateAllObstacles()

    end
end

function ObstacleController:CheckActorIsObstacle(actor)
    -- main player
    if actor:IsPlayer() and actor:IsMainPlayer() then
        return false
    end

    -- 管理员不受控制
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    if MapProxy:IsAdmin() and MapProxy:IsGMRunAll() then
        return false
    end

    -- dead
    if actor:IsDie() or actor:IsDeath() then
        return false
    end

    -- 该actor服务器控制可穿
    if (actor:IsNPC() or actor:IsPlayer() or actor:IsMonster()) and actor:IsThroughAble() then
        return false
    end

    local MapProxy                      = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local isCrossAllSafeArea            = MapProxy:IsCrossAllSafeArea()             -- 安全区 不受控制
    local isForbidCrossNPCSafeArea      = MapProxy:IsForbidCrossNpcSafeArea()       -- 安全区 禁止穿 NPC
    local isForbidCrossStallSafeArea    = MapProxy:IsForbidCrossStallSafeArea()     -- 安全区 禁止穿 摆摊玩家
    local isForbidCrossOfflineSafeArea  = MapProxy:IsForbidCrossOfflineSafeArea()   -- 安全区 禁止穿 离线玩家

    -- new obstacle data
    local isObstacle            = 0
    if actor:IsNPC() then
        isObstacle              = MapProxy:IsCrossNpcEnable() and 0 or 1
        if actor:GetInSafeZone() then
            isObstacle          = isCrossAllSafeArea and 0 or isObstacle
            isObstacle          = isForbidCrossNPCSafeArea and 1 or isObstacle
        end

    elseif actor:IsPlayer() and not actor:IsHumanoid() then
        isObstacle              = (MapProxy:IsCrossPlayerEnable() and 0 or 1)
        if actor:GetInSafeZone() then
            isObstacle          = isCrossAllSafeArea and 0 or isObstacle
            if actor:IsStallStatus() then
                isObstacle      = isForbidCrossStallSafeArea and 1 or isObstacle
            end
            if actor:GetIsOffLine() then
                isObstacle      = isForbidCrossOfflineSafeArea and 1 or isObstacle
            end
        end

    elseif actor:IsDefender() then
        isObstacle              = (MapProxy:IsCrossDefenderEnable() and 0 or 1)
        if actor:GetInSafeZone() then
            isObstacle          = isCrossAllSafeArea and 0 or isObstacle
        end

    elseif actor:IsMonster() or actor:IsHumanoid() then
        isObstacle              = (MapProxy:IsCrossMonsterEnable() and 0 or 1)
        if actor:GetInSafeZone() then
            isObstacle          = isCrossAllSafeArea and 0 or isObstacle
        end

    elseif actor:IsSEffect() then
        local mainPlayerID      = global.gamePlayerController:GetMainPlayerID()
        isObstacle              = (actor:GetEffectType() == global.MMO.EFFECT_TYPE_EMPTY and actor:GetDuranceID() == mainPlayerID) and 1 or 0
    end

    return isObstacle == 1
end

function ObstacleController:AddRef(x, y)
    local key = G_ActorUtils.KEY_MAP_XY(x, y)

    self._obstacles[key] = self._obstacles[key] or 0
    self._obstacles[key] = self._obstacles[key] + 1

    -- 第一次增加引用计数，将地图置为阻挡状态
    if self._obstacles[key] == 1 then
        local mapData = global.sceneManager:GetMapData2DPtr()
        if not mapData then
            return nil
        end
        mapData:setObstacle(x, y, 1)
    end
end

function ObstacleController:DecRef(x, y)
    local key = G_ActorUtils.KEY_MAP_XY(x, y)

    self._obstacles[key] = self._obstacles[key] or 0
    self._obstacles[key] = self._obstacles[key] - 1

    -- 警告
    if self._obstacles[key] < 0 then
        print("WARNING, dynamic obstacle less than 0!!!", self._obstacles[key], x, y)
        PrintTraceback()
    end

    -- 计数 < 0, 当前位置已无动态阻挡
    if self._obstacles[key] <= 0 then
        self._obstacles[key] = nil
        local mapData = global.sceneManager:GetMapData2DPtr()
        if not mapData then
            return nil
        end
        mapData:setObstacle(x, y, 0)
    end
end

function ObstacleController:OnActorMapXYChange(data)
    if not data or not data.actor then
        return
    end
    local actor = data.actor
    local lastMapX = actor:GetLastMapX()
    local lastMapY = actor:GetLastMapY()
    local currMapX = actor:GetMapX()
    local currMapY = actor:GetMapY()
    
    -- 该Actor无阻挡标记，不进行阻挡引用计数 +-
    if not actor:IsObstacleFlag() then
        return
    end

    -- 当前坐标点无效，可能是未执行进视野先执行了刷新
    if currMapX == INVALID_MAP_POS and currMapY == INVALID_MAP_POS then
        return
    end

    if lastMapX ~= INVALID_MAP_POS and lastMapY ~= INVALID_MAP_POS then
        self:DecRef(lastMapX, lastMapY)
    end

    self:AddRef(currMapX, currMapY)
end

function ObstacleController:CheckAddObstacle(data)
    if not data or not data.actorID then
        return
    end
    local actor = global.actorManager:GetActor(data.actorID)

    -- 检测是否给阻挡标记
    local isObstacle = self:CheckActorIsObstacle(actor)
    actor:SetObstacleFlag(isObstacle)

    -- 不存在阻挡标记
    if not actor:IsObstacleFlag() then
        return
    end

    -- 增加该位置引用计数
    local currMapX = actor:GetMapX()
    local currMapY = actor:GetMapY()
    self:AddRef(currMapX, currMapY)
end

function ObstacleController:CheckRemoveObstacle(actorID)
    if not actorID then 
        return 
    end
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end

    -- 不存在阻挡标记
    if not actor:IsObstacleFlag() then
        return
    end

    -- ???? 是否应该置为 false
    actor:SetObstacleFlag(false)

    -- 减少该位置引用计数
    local currMapX = actor:GetMapX()
    local currMapY = actor:GetMapY()
    self:DecRef(currMapX, currMapY)
end

function ObstacleController:CheckUpdateObstacle(actorID)
    -- 注意这里刷新，坐标无改变，应认为 同位置刷新
    if not actorID then 
        return 
    end
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    local currMapX = actor:GetMapX()
    local currMapY = actor:GetMapY()

    -- 当前坐标点无效，可能是未执行进视野先执行了刷新
    if currMapX == INVALID_MAP_POS and currMapY == INVALID_MAP_POS then
        return
    end

    -- 否是阻挡
    local lastObstacleFlag = actor:IsObstacleFlag()

    -- 检测是否给阻挡标记
    local isObstacle = self:CheckActorIsObstacle(actor)
    actor:SetObstacleFlag(isObstacle)

    -- 阻挡数据无变化
    if lastObstacleFlag == actor:IsObstacleFlag() then
        return
    end

    -- 上次是阻挡，减引用计数
    if lastObstacleFlag then
        self:DecRef(currMapX, currMapY)
    end
    
    -- 当前是阻挡，加引用计数
    if actor:IsObstacleFlag() then
        self:AddRef(currMapX, currMapY)
    end
end

function ObstacleController:OnActorInOfView(data)
    self:CheckAddObstacle(data)
end

function ObstacleController:OnActorEffectInOfView(data)
    self:CheckAddObstacle(data)
end

function ObstacleController:OnActorOutOfView(actorID)
    self:CheckRemoveObstacle(actorID)
end

function ObstacleController:OnActorPlayerDie(actorID)
    self:CheckRemoveObstacle(actorID)
end

function ObstacleController:OnActorMonsterDie(actorID)
    self:CheckRemoveObstacle(actorID)
end

function ObstacleController:OnActorMonsterDeath(actorID)
    self:CheckRemoveObstacle(actorID)
end

function ObstacleController:OnActorRevive(actorID)
    self:CheckUpdateObstacle(actorID)
end

function ObstacleController:OnActorEffectOutOfView(actorID)
    self:CheckRemoveObstacle(actorID)
end

function ObstacleController:OnPlayerStallStatusChange(actorID)
    self:CheckUpdateObstacle(actorID)
end

function ObstacleController:OnActorSafeZoneChange(actorID)
    self:CheckUpdateObstacle(actorID)
end
local sharedT = {}
function ObstacleController:OnMapDataLoadSuccess(data)
    self._obstacles = {}

    -- npc
    local actors, ncount = global.npcManager:GetAllNpcInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            sharedT.actorID = actor:GetID()
            self:CheckAddObstacle(sharedT)
        end
    end

    -- player
    local actors, ncount = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            sharedT.actorID = actor:GetID()
            self:CheckAddObstacle(sharedT)
        end
    end

    -- monsters
    local actors, ncount = global.monsterManager:GetAllMonsterInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            sharedT.actorID = actor:GetID()
            self:CheckAddObstacle(sharedT)
        end
    end
end

function ObstacleController:OnUpdateAllObstacles()
    -- npc
    local actors, ncount = global.npcManager:GetAllNpcInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            self:CheckUpdateObstacle(actor:GetID())
        end
    end

    -- player
    local actors, ncount = global.playerManager:GetAllPlayerInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            self:CheckUpdateObstacle(actor:GetID())
        end
    end

    -- monsters
    local actors, ncount = global.monsterManager:GetAllMonsterInCurrViewField()
    for i = 1, ncount do
        local actor = actors[i]
        if actor then
            self:CheckUpdateObstacle(actor:GetID())
        end
    end
end

function ObstacleController:DynamicPathPoints()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return nil
    end

    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return nil
    end

    local PlayerInputProxy  = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local currPathPoint     = PlayerInputProxy:GetCurrPathPoint()
    local pathPoints        = PlayerInputProxy:GetPathFindPoints()
    if currPathPoint <= 0 or #pathPoints <= 0 then
        return nil
    end

    local sX        = mainPlayer:GetMapX()
    local sY        = mainPlayer:GetMapY()
    local dX        = nil
    local dY        = nil
    local destIndex = nil

    -- find dest pos
    if pathPoints[currPathPoint] then
        local path = pathPoints[currPathPoint]
        if mapData:isObstacle(path.x, path.y) == 1 then
            for i = currPathPoint, 1, -1 do
                path = pathPoints[i]
                if mapData:isObstacle(path.x, path.y) == 0 then
                    dX = path.x
                    dY = path.y
                    destIndex = i
                    break
                end
            end
        end
    end

    -- can't find obstacle
    if not dX or  not dY then
        return nil
    end

    print("--------------------- modify path", dX, dY)

    -- it's current pos,nothing to do
    if sX == dX and sY == dY then
        return nil
    end

    -- find path
    local findPoints = global.PathFindController:FindPathAStarLimits(sX, sY, dX, dY)

    -- can't find dest
    if #findPoints <= 0 then
        return nil
    end

    -- new path points
    local newPathPoints = {}
    for i, v in ipairs(pathPoints) do
        if i == destIndex then
            break
        end
        table.insert(newPathPoints, v)
    end
    for i, v in ipairs(findPoints) do
        table.insert(newPathPoints, v)
    end
    PlayerInputProxy:SetPathFindPoints( newPathPoints )
end

return ObstacleController
