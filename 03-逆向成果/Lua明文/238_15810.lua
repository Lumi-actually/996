local PathFindController = class("PathFindController")
local PathFindAStar = require("logic/PathFindAStar")

local function squLen(x, y)
    return x * x + y * y
end

local function convertDir(dir)
    if dir > global.MMO.ORIENT_LU then
        dir = dir - (global.MMO.ORIENT_LU+1)

    elseif dir < global.MMO.ORIENT_U then
        dir = dir + (global.MMO.ORIENT_LU+1)
    end
    return dir
end

local function checkMoveAbleOneStep(mapData, sX, sY, moveStep, moveDir)
    local normalize = nil
    local dX = 0
    local dY = 0
    for i = 1, moveStep do
        normalize = G_ActorUtils.DirToNormalizeVec2(moveDir)
        dX  = sX + normalize.x*i
        dY  = sY + normalize.y*i
        if mapData:isObstacle(dX, dY) ~= 0 then
            return false
        end
    end
    return true, dX, dY
end

function PathFindController:ctor()
    self._dirIQ = 1  -- 摇杆遇到阻挡时，找更远处方向时，优先找上次方向
    self._aiManager = aiManager:Inst()
    self._aiPathFind = nil
    self._pathFindAStar = PathFindAStar.new()
end

function PathFindController:destory()
end

function PathFindController:create()
    local _this = PathFindController.new()
    return _this
end

function PathFindController:GetAIPathFind()
    if not self._aiPathFind then
        self._aiPathFind = self._aiManager:GetPathFind()
    end
    return self._aiPathFind
end

function PathFindController:IsOutBounds(x, y)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return true
    end

    local mapRows = mapData:getMapDataRows()
    local mapCols = mapData:getMapDataCols()
    return (x < 0 or x >= mapCols or y < 0 or y >= mapRows)
end

function PathFindController:CheckMoveAble(x, y)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return false
    end

    if self:IsOutBounds(x, y) then
        return false
    end
    if mapData:isObstacle(x, y) == 0 then
        return true
    end
    return false
end

function PathFindController:IsImpass(x, y)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return true
    end

    for xx = x-1, x+1, 1 do
        for yy = y-1, y+1, 1 do
            if xx == x and yy == y then
            else
                if self:CheckMoveAble(xx, yy) then
                    return false
                end
            end
        end
    end

    return true
end

function PathFindController:FindPathAStar(sX, sY, dX, dY)
    local findPoints = {}

    if not sX or not sY or not dX or not dY then
        return findPoints
    end

    if sX == dX and sY == dY then   -- it's current pos,nothing to do
        return findPoints
    end

    -- 死路
    if true == self:IsImpass(sX, sY) or true == self:IsImpass(dX, dY) then
        return findPoints
    end

    -- 
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return findPoints
    end

    -- find
    self._aiManager:FindPath(sX, sY, dX, dY, mapData)
    findPoints = self:GetAIPathFind():GetPathPoints()

    return findPoints
end

function PathFindController:FindPathAStarLimits(sX, sY, dX, dY)
    local findPoints = {}

    if sX == dX and sY == dY then   -- it's current pos,nothing to do
        return findPoints
    end

    -- 死路
    if true == self:IsImpass(sX, sY) or true == self:IsImpass(dX, dY) then
        return findPoints
    end

    -- 
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return findPoints
    end

    -- find
    local max = math.max(math.abs(sX - dX), math.abs(sY - dY))  
    local count = max * max * 2
    if not self._aiManager.FindPathLimits then
        findPoints = self._pathFindAStar:find_path_limit(sX, sY, dX, dY, count)
    else
        self._aiManager:FindPathLimits(sX, sY, dX, dY, mapData, count)
        findPoints = self:GetAIPathFind():GetPathPoints()
    end
    
    return findPoints
end

local dirs = {}
function PathFindController:FindDestPosJoystick(sX, sY, moveDir, moveStep)
    -- 绝路
    if true == self:IsImpass(sX, sY) then
        return nil
    end
    -- 
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return nil
    end

    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local moveDirty = false
    local dX = sX
    local dY = sY
    -- 先根据方向找格子
    if not moveDirty then
        for i = moveStep, 1, -1 do
            moveDirty, dX, dY = checkMoveAbleOneStep(mapData, sX, sY, i, moveDir)
            if moveDirty then
                return dX, dY
            end
        end
    end
    
    -- 找邻近2个方向
    if not moveDirty then
        dirs[1] = moveDir+(self._dirIQ*1)
        dirs[2] = moveDir-(self._dirIQ*1)
        for i, dir in ipairs(dirs) do
            dir = convertDir(dir)

            for j = moveStep, 1, -1 do
                moveDirty, dX, dY = checkMoveAbleOneStep(mapData, sX, sY, j, dir)
                if moveDirty then
                    self._dirIQ = (i == 1 and self._dirIQ or self._dirIQ*-1)
                    return dX, dY
                end
            end
        end
    end

    -- 找更远2个方向
    if not moveDirty then
        dirs[1] = moveDir+(self._dirIQ*2)
        dirs[2] = moveDir-(self._dirIQ*2)
        for i, dir in ipairs(dirs) do
            dir = convertDir(dir)

            moveDirty, dX, dY = checkMoveAbleOneStep(mapData, sX, sY, 1, dir)
            if moveDirty then
                self._dirIQ = (i == 1 and self._dirIQ or self._dirIQ*-1)
                return dX, dY
            end
        end
    end

    -- 
    -- if not moveDirty then
    --     local normalize  = G_ActorUtils.DirToNormalizeVec2(moveDir)
    --     for i = moveStep, SL:GetValue("GAME_DATA","Joystick_Check_Range") or 0 do
    --         dX = sX + normalize.x*i
    --         dY = sY + normalize.y*i
    --         if mapData:isObstacle(dX, dY) == 0 then
    --             moveDirty = true
    --             return dX, dY
    --         end
    --     end
    -- end

    -- if not moveDirty then
    --     return nil
    -- end
    -- local findPoints = self:FindPathAStarLimits(sX, sY, dX, dY)
    -- if not findPoints then
    --     return nil
    -- end

    -- local pathLen = #findPoints
    -- if pathLen <= 0 then
    --     return nil
    -- end
    -- -- 第一步
    -- dX = findPoints[pathLen].x
    -- dY = findPoints[pathLen].y

    -- -- 是否能走多步
    -- if pathLen > 1 and pathLen >= moveStep then
    --     local moveDir = G_ActorUtils.CalcActorDirByPos(sX, sY, findPoints[pathLen].x, findPoints[pathLen].y)
    --     for i = pathLen-1, 1, -1 do
    --         -- 步数超出
    --         if pathLen - i >= moveStep then
    --             break
    --         end
    --         -- 不同方向
    --         if moveDir ~= G_ActorUtils.CalcActorDirByPos(findPoints[i+1].x, findPoints[i+1].y, findPoints[i].x, findPoints[i].y) then
    --             break
    --         end
    --         dX = findPoints[i].x
    --         dY = findPoints[i].y
    --     end
    -- end
    return nil--dX, dY
end

--------------------------------------------------------------------------------------------
function PathFindController:CheckMovePosEnable(x, y)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return false
    end

    return mapData:isObstacle(x, y) == 0
end

function PathFindController:CheckNextMovePos(player, pathPoints, currPathPoint)
    if currPathPoint <= 0 then
        return nil, nil
    end
    
    -- check first point
    local moveStep = 1
    local pX = player:GetMapX()
    local pY = player:GetMapY()
    local nextPos = pathPoints[currPathPoint]
    local nextEnable = self:CheckMovePosEnable(nextPos.x, nextPos.y)
    if not nextEnable then
        return nil, nil
    end

    -- 寻路只有一格
    if currPathPoint <= 1 then
        return nextPos, moveStep
    end
    
    -- 只能走路buff
    if not G_ActorUtils.CheckRunAble() or G_ActorUtils.CheckRunStep() <= 1 then
        return nextPos, moveStep
    end

    local nextDir = G_ActorUtils.CalcActorDirByPos(pX, pY, nextPos.x, nextPos.y)

    -- check second point
    local next2Pos = pathPoints[currPathPoint - 1]
    if nextDir ~= G_ActorUtils.CalcActorDirByPos(nextPos.x, nextPos.y, next2Pos.x, next2Pos.y) or not self:CheckMovePosEnable(next2Pos.x, next2Pos.y) then
        return nextPos, moveStep
    end

    -- 2 step only.
    moveStep = 2
    if G_ActorUtils.CheckRunStep() <= 2 or currPathPoint <= 2 then
        return next2Pos, moveStep
    end
    
    -- check third point
    local next3Pos = pathPoints[currPathPoint - 2]
    if nextDir ~= G_ActorUtils.CalcActorDirByPos(next2Pos.x, next2Pos.y, next3Pos.x, next3Pos.y) or not self:CheckMovePosEnable(next3Pos.x, next3Pos.y) then
        return next2Pos, moveStep
    end
    
    moveStep = 3
    return next3Pos, moveStep
end

function PathFindController:CheckNextMovePosAble()
    local player                = global.gamePlayerController:GetMainPlayer()
    if not player then
        return -1
    end

    local inputProxy            = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local pathPoints            = inputProxy:GetPathFindPoints()
    local currPathPoint         = inputProxy:GetCurrPathPoint()
    if currPathPoint <= 0 then
        return 0
    end

    local nextPoint, moveStep   = self:CheckNextMovePos(player, pathPoints, currPathPoint)
    if nextPoint then
        -- walk, check next point has player/monster/npc
        if moveStep == 1 and not self:CheckAbleToWalk(nextPoint) then
            return -1
        end
        
        return 1
    end

    return -1
end

function PathFindController:CheckAbleToWalkByActor(actor)
    if not actor then
        return true
    end

    -- 死亡状态 可穿
    if actor:IsDie() or actor:IsDeath() or actor:IsCave() then
        return true
    end

    -- 该actor 可穿
    if actor:IsPlayer() or actor:IsMonster() or actor:IsNPC() then
        if actor:IsThroughAble() then
            return true
        end
    end

    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)

    -- 地图设置 可穿
    if actor:IsPlayer() and not actor:IsHumanoid() then
        if MapProxy:IsAbleWalkCrossPlayer() then
            return true
        end

        if MapProxy:IsCrossAllSafeArea() and actor:GetInSafeZone() then
            return true
        end

    end

    -- 地图设置 可穿
    if actor:IsMonster() or actor:IsHumanoid() then
        
        if MapProxy:IsAbleWalkCrossMonster() then
            return true
        end

    end

    -- 地图设置 可穿
    if actor:IsNPC() then
        if MapProxy:IsCrossNpcEnable() then
            return true
        end

        if MapProxy:IsCrossAllSafeArea() and actor:GetInSafeZone() then
            return true
        end
    end

    return false
end

function PathFindController:CheckAbleToWalk(nextPoint)
    -- 管理员不受控制
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    if MapProxy:IsAdmin() and MapProxy:IsGMRunAll() then
        return true
    end

    local actors = global.actorManager:GetMonsterActorByMapXY(nextPoint.x, nextPoint.y, true)
    for i, actor in ipairs(actors) do
        if actor and false == self:CheckAbleToWalkByActor(actor) then
            return false
        end
    end

    actors = global.actorManager:GetPlayerActorByMapXY(nextPoint.x, nextPoint.y, true)
    for i, actor in ipairs(actors) do
        if actor and false == self:CheckAbleToWalkByActor(actor) then
            return false
        end
    end

    actors = global.actorManager:GetNPCActorByMapXY(nextPoint.x, nextPoint.y, true)
    for i, actor in ipairs(actors) do
        if actor and false == self:CheckAbleToWalkByActor(actor) then
            return false
        end
    end  

    return true
end

-- 检测直线阻挡是否存在npc player monster
local around = 
{
    { 0,        -1 }, -- ORIENT_U
    { 1,        -1 }, -- ORIENT_RU
    { 1,         0 }, -- ORIENT_R
    { 1,         1 }, -- ORIENT_RB
    { 0,         1 }, -- ORIENT_B    
    {-1,         1 }, -- ORIENT_LB
    {-1,         0 }, -- ORIENT_L
    {-1,        -1 }, -- ORIENT_LU  
}
local function checkActors(actors, ncount, x, y)
    for i = 1, ncount do
        local actor = actors[i]
        if actor and actor:GetMapX() == x and actor:GetMapY() == y then
            return actor
        end
    end
    return nil
end
function PathFindController:CheckActorLimitObstacle(sX, sY, dX, dY)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return false
    end

    local inputProxy    = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local moveDir       = G_ActorUtils.CalcMapDirection(dX, dY, sX, sY)
    local distance      = G_ActorUtils.CalcMapDistance(sX, sY, dX, dY)

    local ret = true
    local target = nil
    local actors = {}
    local ncount = 0

    for i=1,distance do
        sX = sX + around[moveDir+1][1]
        sY = sY + around[moveDir+1][2]

        if mapData:isObstacle(sX, sY) == 1 then
            -- npc
            if not target then
                actors, ncount = global.npcManager:GetAllNpcInCurrViewField()
                target = checkActors(actors, ncount, sX, sY)
            end

            -- player
            if not target then
                actors, ncount = global.playerManager:FindAllPlayerInCurrViewField()
                target = checkActors(actors, ncount, sX, sY)
            end

            -- monster
            if not target then
                actors, ncount = global.monsterManager:FindAllMonsterInCurrViewField(false, false)
                target = checkActors(actors, ncount, sX, sY)
            end

            if not target then
                ret = false
                break
            end
        end
    end

    return ret
end

-- 检测目标点临近点有阻挡的方向
local checkDir = {}
function PathFindController:CheckDestNearObstacleDir(dX, dY, moveDir)
    local mapData = global.sceneManager:GetMapData2DPtr()
    if not mapData then
        return false
    end

    local tX = dX + around[moveDir + 1][1]
    local tY = dY + around[moveDir + 1][2]

    if mapData:isObstacle(tX, tY) == 1 then
        return moveDir
    end

    -- 找邻近2个方向
    checkDir[1] = moveDir + 1
    checkDir[2] = moveDir - 1
    for i, dir in ipairs(checkDir) do
        dir = convertDir(dir)
        tX = dX + around[dir + 1][1]
        tY = dY + around[dir + 1][2]

        if mapData:isObstacle(tX, tY) == 1 then
            return dir
        end
    end

    -- 找更远2个方向
    checkDir[1] = moveDir + 2
    checkDir[2] = moveDir - 2
    for i, dir in ipairs(checkDir) do
        dir = convertDir(dir)
        tX = dX + around[dir + 1][1]
        tY = dY + around[dir + 1][2]

        if mapData:isObstacle(tX, tY) == 1 then
            return dir
        end
    end

    return false
end
--------------------------------------------------------------------------------------------


return PathFindController
