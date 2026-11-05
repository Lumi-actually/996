local RemoteProxy = requireProxy("RemoteProxy")
local AssistProxy = class("AssistProxy", RemoteProxy)
AssistProxy.NAME  = global.ProxyTable.AssistProxy
local proxyUtils  = requireUtil("proxyUtils")

-- StdMode=25 Shape=1  灰色药粉
-- StdMode=25 Shape=2  黄色药粉
-- StdMode=25 Shape=5  护身符
local InputMoveT = {type = GUIDefine.InputMoveType.AUTOMOVE}
-- 使用护身符的技能
local function isHSFSkill(skillID)
    local skills = {13, 14, 15, 16, 17, 18, 19, 30, 55, 57, 76, 85}
    for key, value in pairs(skills) do
        if value == skillID then
            return true
        end
    end
    return false
end

-- 使用毒的技能
local function isDUSkill(skillID)
    local skills = {6, 51}
    for key, value in pairs(skills) do
        if value == skillID then
            return true
        end
    end
    return false
end

-- 是护身符
local function isHSFItem(item)
    if not item then
        return false
    end
    return item.StdMode == 25 and item.Shape == 5
end

-- 是毒药粉
local function isDUItem(item)
    if not item then
        return false
    end
    return item.StdMode == 25 and (item.Shape == 1 or item.Shape == 2)
end

-- 通过 stdmode和 shape从背包找物品
local function findBagItem(stdMode, shape)
    local items    = BagData.GetBagData()
    for _, item in pairs(items) do
        if item.StdMode == stdMode and item.Shape == shape then
            return item
        end
    end

    return nil
end



function AssistProxy:ctor()
    AssistProxy.super.ctor(self)

    self._offlineState          = false


    self._isFindMapMonster      = false
    self._isFindMapMonsterFail  = false
    self._requestMonsterFlag    = false

    self._nextAutoEquipShape    = nil  -- 上次挂机时使用的是什么药粉
end

function AssistProxy:onRegister()
    AssistProxy.super.onRegister(self)
    
    local msgType = global.MsgType
end

function AssistProxy:checkIsBusy()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    local mapData    = global.sceneManager:GetMapData2DPtr()
    if not mapData or not mainPlayer then
        return true
    end

    local facade        = global.Facade
    local inputProxy    = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local autoProxy     = facade:retrieveProxy(global.ProxyTable.AutoProxy)

    -- afk
    if autoProxy:IsAFKState() then
        return false
    end

    -- 有掉落物可以捡
    if autoProxy:IsCanAutoPick() then
        return true
    end

    -- 不可以移动
    if not inputProxy:IsMovePermission() then
        return true
    end

    -- 移动中断
    if inputProxy:GetMoveInterruptFlag() then
        return true
    end

    -- 移动中
    if (inputProxy:IsMoveDirty() or inputProxy:GetCurrPathPoint() > 0) then
        return true
    end
    
    return false
end

function AssistProxy:autoDressEquipSkill(skillID)
    -- 0(穿戴) 才需要自动穿
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    if MapProxy:GetUseAmuletType() ~= 0 then
        return false
    end

    -- 自动红绿毒
    if not (isHSFSkill(skillID) or isDUSkill(skillID)) then
        return false
    end

    -- 装备位置 9
    -- step1 符/毒，
    -- 符，判断当前是否包含符子串， 是.不管  否.背包找，找到就换
    -- 毒，灰/黄毒轮换，换为符之后重置

    -- 挂机，用与上次 灰/黄 药粉不一样的装备
    local AutoProxy = global.Facade:retrieveProxy( global.ProxyTable.AutoProxy )
    local isAFKState = AutoProxy:IsAFKState()
    local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local isAlwaysAttack = PlayerInputProxy:IsAttackState()

    local dressEquip   = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Bujuk)
    local replaceItem  = nil

    local autoShapeDU1 = 1
    local autoShapeDU2 = 2
    if isAFKState or (isAlwaysAttack and CHECK_SETTING(global.MMO.SETTING_IDX_ALWAYS_ATTACK) == 1)  then
        self._nextAutoEquipShape = self._nextAutoEquipShape or 1
        autoShapeDU1 = self._nextAutoEquipShape
        autoShapeDU2 = 3 - autoShapeDU1
    else
        self._nextAutoEquipShape = nil
    end

    if isHSFSkill(skillID) and CHECK_SETTING(global.MMO.SETTING_IDX_DU_FU_AUTOCHANGE) == 1 then
        -- 符
        if not isHSFItem(dressEquip) then
            replaceItem = findBagItem(25, 5)
        end

    elseif isDUSkill(skillID) and CHECK_SETTING(global.MMO.SETTING_IDX_DU_FU_AUTOCHANGE) == 1 then
        -- 毒
        if dressEquip and dressEquip.StdMode == 25 then
            if dressEquip.Shape == 5 then
                replaceItem = findBagItem(25, autoShapeDU1) or findBagItem(25, autoShapeDU2)

            elseif dressEquip.Shape == 1 then
                replaceItem = findBagItem(25, 2)
                
            elseif dressEquip.Shape == 2 then
                replaceItem = findBagItem(25, 1)
            end
        else
            replaceItem = findBagItem(25, autoShapeDU1) or findBagItem(25, autoShapeDU2)
        end
    end
    if replaceItem then
        local ItemUseProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemUseProxy)
        ItemUseProxy:UseItem(replaceItem)

        if (isAFKState or (isAlwaysAttack and CHECK_SETTING(global.MMO.SETTING_IDX_ALWAYS_ATTACK) == 1) ) and (replaceItem.Shape == 1 or replaceItem.Shape == 2) then
            self._nextAutoEquipShape = 3 - replaceItem.Shape
        end
    end
end


-------------------------------------------------
-- 自动挂机
function AssistProxy:setOfflineState(state)
    self._offlineState = state
end

function AssistProxy:getOfflineState()
    return self._offlineState
end

function AssistProxy:resetOfflineState()
    self:setOfflineState(false)
    self:resetOfflineSchedule()
end

function AssistProxy:resetOfflineSchedule()
    if self._offlineScheduleID then
        UnSchedule(self._offlineScheduleID)
        self._offlineScheduleID = nil
    end
end

function AssistProxy:checkOfflineAble()
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    local mapData    = global.sceneManager:GetMapData2DPtr()
    if not mapData or not mainPlayer then
        return false
    end

    local facade        = global.Facade
    local inputProxy    = facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local autoProxy     = facade:retrieveProxy(global.ProxyTable.AutoProxy)

    -- 有掉落物可以捡 （并且 不满足 范围内有足够怪物  小精灵 不是一个个拾取 ）
    if autoProxy:IsCanAutoPick() and not proxyUtils:CheckIsEnoughMonster() and not proxyUtils:CheckIsPlayerAbandonPickup() then
        return false
    end

    -- afk
    if not autoProxy:IsAFKState() then
        return false
    end
    
    -- 当前有目标
    if inputProxy:GetTargetID() then
        return false
    end

    -- 不可以移动
    if not inputProxy:IsMovePermission()then
        return false
    end

    -- 移动中断
    if inputProxy:GetMoveInterruptFlag() then
        return false
    end

    -- 移动中
    if (inputProxy:IsMoveDirty() or inputProxy:GetCurrPathPoint() > 0) then
        return false
    end
    
    return true
end

function AssistProxy:CheckAimlessMove()
    if false == self:checkOfflineAble() then
        self:resetOfflineState()
        return false
    end

    -- 
    if self._offlineScheduleID then
        return false
    end
    local function callback()
        self._offlineScheduleID = nil

        if false == self:checkOfflineAble() then
            return
        end

        local mainPlayer = global.gamePlayerController:GetMainPlayer()
        local mapData    = global.sceneManager:GetMapData2DPtr()
        if not mapData or not mainPlayer then
            return nil
        end

        local mapRows = mapData:getMapDataRows()
        local mapCols = mapData:getMapDataCols()
        local minR = math.ceil(math.min(mapRows, mapCols) / 2) --取地图较小边的一半 防止地图过小 傻太久
        local range = math.min(50, minR) 
        local getNotObstacle = function(x ,y)--在目标和周围一格找
            local isNotObstacle = false
            local t = {
                {x = 0, y = 0},
                {x = -1, y = 1},
                {x = 0, y = 1},
                {x = 1, y = 1},
                {x = 1, y = 0},
                {x = 1, y = 1},
                {x = 0, y = -1},
                {x = -1, y = -1},
                {x = -1, y = 0}
            }
            local _x,_y
            for i, v in ipairs(t) do
                _x = x + v.x
                _y = y + v.y
                isNotObstacle = mapData:isObstacle(_x, _y) == 0
                if isNotObstacle then 
                    return cc.p(_x, _y)
                end
            end
            return nil
        end

        -- 最多找五次
        local counting = 0
        while true do
            counting = counting + 1
            if counting >= 5 then
                break
            end

            -- 找一个随机位置
            local srcX  = mainPlayer:GetMapX()
            local srcY  = mainPlayer:GetMapY()
            local dstX  = Random(srcX-range, srcX+range)
            local dstY  = Random(srcY-range, srcY+range)
            --视野边界  减少无效随机 原X+Y > 20
            if math.abs(dstX-srcX) >= 7 or math.abs(dstY-srcY) >= 7 then
                local dstPos = getNotObstacle(dstX,dstY)
                if dstPos then
                    dstX = dstPos.x
                    dstY = dstPos.y
                    -- auto move
                    local mapProxy  = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
                    local mapID     = mapProxy:GetMapID()
                    InputMoveT.mapID   = mapID
                    InputMoveT.x       = dstX
                    InputMoveT.y       = dstY
                    InputMoveT.range   = SL:GetValue("GAME_DATA","AutoMoveRange_Monster")
                    global.Facade:sendNotification(global.NoticeTable.InputMove, InputMoveT)
                    
                    self:setOfflineState(true)
                    
                    break
                end
            end
        end
    end
    self._offlineScheduleID = PerformWithDelayGlobal(callback, 0.1)

    local values =  GET_SETTING(global.MMO.SETTING_IDX_NO_MONSTER_USE, true)
    if values[1] == 1 then 
        if self._noMonsterScheduleID then 
            return 
        end
        local num = tonumber(values[2]) or 999
        self._noMonsterScheduleID = PerformWithDelayGlobal(function ()
            local autoProxy     = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
            if not autoProxy:IsAFKState() then--不处于挂机状态  取消定时器
                self:resetNoMonsterSchedule()
                return false
            end
            local autoUseItem = function(items)
                local proxyUtils    = requireUtil("proxyUtils")
                local ItemUseProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemUseProxy)
                for _, itemIndex in ipairs(items) do
                    local unpack = proxyUtils.UnpackDrugByIndex(itemIndex)
                    if unpack then
                        return true
                    end
                    local item = proxyUtils.FindItemByIndex(itemIndex)
                    if item then
                        ItemUseProxy:UseItem(item)
                        return true
                    end
                end
                return false
            end

            local index = tonumber(values[3])
            if index then 
                autoUseItem({index})
            end
            self:resetNoMonsterSchedule()
        end, num)
    end
    
    return true
end
function AssistProxy:resetNoMonsterSchedule()
    if  self._noMonsterScheduleID then 
        UnSchedule(self._noMonsterScheduleID)
        self._noMonsterScheduleID = nil
    end
end
-------------------------------------------------

-------------------------------------------------
-- 向服务器找怪
function AssistProxy:findMapMonster()
    self:RequestFindMapMonster()
end

function AssistProxy:isFindMapMonster()
    return self._isFindMapMonster
end

function AssistProxy:resetFindMapMonster()
    self._isFindMapMonsterFail = false
    self._isFindMapMonster = false
end

function AssistProxy:dirtyFindMapMonster()
    self._isFindMapMonster = true
end

function AssistProxy:isFindMapMonsterFail()
    return self._isFindMapMonsterFail
end

function AssistProxy:isRequestMonsterFlag()
    return self._requestMonsterFlag
end
-------------------------------------------------
-- 自动找怪
function AssistProxy:RequestFindMapMonster()
    LuaSendMsg(global.MsgType.MSG_CS_FIND_MAP_MONSTER)
    self._requestMonsterFlag = true
    self._isFindMapMonsterFail = false

    -- 
    if self._findMapTargetScheduleID then
        UnSchedule(self._findMapTargetScheduleID)
        self._findMapTargetScheduleID = nil
    end
    self._findMapTargetScheduleID = PerformWithDelayGlobal(function()
        self._requestMonsterFlag = false
        self:resetFindMapMonster()
    end, 2)

    print("+++++++++++++++++++++++++++++ find map target")
end


function AssistProxy:handle_MSG_SC_FIND_MAP_MONSTER(msg)
    local header = msg:GetHeader()
    local x = header.recog
    local y = header.param1

    dump(header)

    if x == 0 and y == 0 then
        self._requestMonsterFlag = false
        self._isFindMapMonsterFail = true
        return false
    end
    self._requestMonsterFlag = false
    self._isFindMapMonsterFail = false

    -- auto move
    local mapProxy  = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local mapID     = mapProxy:GetMapID()

    InputMoveT.mapID   = mapID
    InputMoveT.x       = x
    InputMoveT.y       = y
    InputMoveT.range   = SL:GetValue("GAME_DATA","AutoMoveRange_Monster")
    global.Facade:sendNotification(global.NoticeTable.InputMove, InputMoveT)

    self:dirtyFindMapMonster()
end


function AssistProxy:RegisterMsgHandler()
    AssistProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_FIND_MAP_MONSTER, handler(self, self.handle_MSG_SC_FIND_MAP_MONSTER)) -- 全图找怪
end

return AssistProxy
