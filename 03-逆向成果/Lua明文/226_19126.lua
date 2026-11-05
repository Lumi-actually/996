local gamePlayerController = class("gamePlayerController")
local Queue = requireUtil("queue")
gamePlayerController.NAME = "gamePlayerController"


local moveMsgType = {
    [global.MMO.ACTION_WALK] = global.MsgType.MSG_CS_MAIN_PLAYER_WALK,
    [global.MMO.ACTION_RUN] = global.MsgType.MSG_CS_MAIN_PLAYER_RUN,
    [global.MMO.ACTION_RIDE_RUN] = global.MsgType.MSG_CS_MAIN_PLAYER_RIDE_RUN,
    [global.MMO.ACTION_ASSASSIN_SNEAK] = global.MsgType.MSG_CS_MAIN_PLAYER_WALK
}

local SharedT = {}
local SharedT2 = {}

-- 是否死亡
local function ActorIsDie(actor)
    return actor:IsDie() or actor:IsDeath()
end

function gamePlayerController:ctor()
    self.mMainPlayerActor = nil
    self.mLuaTouchHandler = -1
    self.mLuaInputHandler = -1

    self.mHandleOnActCompleted = {}
    self.mHandleOnActBegin = {}
    self.mInputEnable = true
    self.mNextAction = nil

    self:RegisterMsgHandler()
end

function gamePlayerController:destory()
end

function gamePlayerController:create()
    local _this = gamePlayerController.new()
    return _this
end

function gamePlayerController:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_MOVE_FAIL, handler(self, self.handle_MSG_SC_NET_PLAYER_MOVE_FAIL))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTION_CONFIREM_SUCCESS, handler(self, self.handle_MSG_SC_ACTION_CONFIRM))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SKILL_ACTION_CONFIRM_SUCCESS, handler(self, self.handle_MSG_SC_SKILL_ACTION_CONFIRM))
end

function gamePlayerController:Cleanup()
    self.mMainPlayerActor = nil

    self.mHandleOnActCompleted = {}
    self.mHandleOnActBegin = {}

    self.mLuaInputHandler = -1

    self.mInputEnable = true
    self.mNextAction = nil
end

function gamePlayerController:CleanupMainPlayer()
    self.mMainPlayerActor = nil
end

function gamePlayerController:GetMainPlayer()
    return self.mMainPlayerActor
end

function gamePlayerController:GetMainPlayerID()
    if not self.mMainPlayerActor then
        return
    end
    return self.mMainPlayerActor:GetID()
end

function gamePlayerController:AddHandleOnActCompleted(func)
    table.insert(self.mHandleOnActCompleted, func)
end

function gamePlayerController:AddHandleOnActBegin(func)
    table.insert(self.mHandleOnActBegin, func)
end

function gamePlayerController:RegisterLuaInputHandler(inputHandler)
    self.mLuaInputHandler = inputHandler
end

function gamePlayerController:handleActionBegin(actor, actBegin)
    if nil == self.mMainPlayerActor then
        return -1
    end

    if actBegin == global.MMO.ACTION_WALK or actBegin == global.MMO.ACTION_ASSASSIN_SNEAK or actBegin ==
        global.MMO.ACTION_RUN or actBegin == global.MMO.ACTION_RIDE_RUN then
        -- Store last point for moving confirmation
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        local mapIdx = MapProxy:GetMapIdx()
        local msgType = moveMsgType[actBegin]

        -- 检测服务器开关
        if actBegin == global.MMO.ACTION_RUN and CHECK_SERVER_OPTION(global.MMO.SERVER_RUN_ONE) then
            msgType = global.MsgType.MSG_CS_WALKEX
        end

        local dir = self.mMainPlayerActor:GetDirection()
        local player = self.mMainPlayerActor
        local mapX = player:GetMapX()
        local mapY = player:GetMapY()

        local headData = {
            Id = mapIdx,
            X = mapX,
            Y = mapY,
            Dir = dir
        }
        LuaSendHeader3(msgType, headData)
    end

    self:OnActionBegin(actor, actBegin)

    -- Action begin handle.

    for k,v in pairs(self.mHandleOnActBegin) do
        if actor then
            v(actor, actBegin)
        end
    end

    SL:onLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, {actorID = actor:GetID(), act = actBegin})
end

function gamePlayerController:OnActionBegin(actor, actBegin)
    if actBegin == global.MMO.ACTION_WALK or actBegin == global.MMO.ACTION_RUN or actBegin == global.MMO.ACTION_RIDE_RUN then
        local slt = global.SLT.AudioPlayTable
        slt.type = global.MMO.SND_TYPE_ACT_MOVE
        slt.index = actBegin
        slt.isRide = actor:GetHorseMasterID()
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    end

    if actBegin ~= global.MMO.ACTION_IDLE then
        global.Facade:sendNotification(global.NoticeTable.MainPlayerActionBegan, actBegin)
    end
end

local moveAct = {
    [global.MMO.ACTION_ASSASSIN_SNEAK] = 1,
    [global.MMO.ACTION_RIDE_RUN] = 1,
    [global.MMO.ACTION_WALK] = 1,
    [global.MMO.ACTION_RUN] = 1,
}
function gamePlayerController:handleActionCompleted(actor, actCompleted)  
    local actorID = actor:GetID()

    self:OnActionCompleted( actor, actCompleted )

    -- Action completion handle.
    for k,v in pairs(self.mHandleOnActCompleted) do
        v(actor, actCompleted)
    end

    -- 针对移动的一些处理    
    if GUIFunction:IsMoveAction(actCompleted) then
        -- 主玩家移动，取消交易
        SL:CancelTradeInMoving()
        SL:onLUAEvent(LUA_EVENT_PLAYER_MAPPOS_CHANGE)

        -- PC 鼠标处理
        if SL:GetValue("IS_PC_OPER_MODE") then
            -- 移动时，其他玩家的鼠标经过显示消失
            local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
            if inputProxy:GetMouseOverTargetID() then
                local actor = global.actorManager:GetActor(inputProxy:GetMouseOverTargetID())
                inputProxy:SetMouseOverTargetID(nil)
                if actor then
                    local hudParam = G_ActorUtils.GetActorAttr(actor, global.MMO.ACTOR_ATTR_HUDPARAM)
                    if hudParam and next(hudParam) then
                        global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel,  actorID)
                    end
                end
            end
        end

    end

    -- 
    SharedT2.actorID = actorID
    SharedT2.act = actCompleted
    SL:onLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, SharedT2)

    -- 下一动作
    if self.mNextAction then
        self:ExecuteNextAction()
        self.mInputEnable = false
    else
        self.mInputEnable = true
    end

    -- 执行输入
    self:ProcessLuaInput(actor, actCompleted)

    -- 
    if moveAct[actCompleted] == 1 then
        -- 动作结束后处理，移动结束坐标修正
        if moveAct[actor:GetAction()] == nil then
            actor:setPosition(actor.mTargePosX, actor.mTargePosY)
        end
    elseif actCompleted == global.MMO.ACTION_DASH_FAIL then
        local wX, wY = global.sceneManager:MapPos2WorldPos(actor:GetMapX(), actor:GetMapY(), true)
        actor:setPosition(wX, wY)

    end
end

function gamePlayerController:OnActionCompleted(actor, actCompleted)
    -- 事件分发
    if actCompleted ~= global.MMO.ACTION_IDLE then
        global.Facade:sendNotification(global.NoticeTable.MainPlayerActionEnded, actCompleted)
        SLBridge:onLUAEvent(LUA_EVENT_MAIN_PLAYER_ACTION_ENDED, actCompleted)
    end
end

function gamePlayerController:ProcessLuaInput(actor, actCompleted)
    if -1 ~= self.mLuaInputHandler and actCompleted ~= global.MMO.ACTION_DIE and self.mInputEnable then
        self.mLuaInputHandler(actor, actCompleted)
    end
end

function gamePlayerController:handleActionProcess(actor, act, dt)
    if act ~= global.MMO.ACTION_IDLE then
        global.Facade:sendNotification(global.NoticeTable.MainPlayerActionProcess, act)
    end
end

function gamePlayerController:SetNextAction(act)
    self.mNextAction = act
end

function gamePlayerController:ExecuteNextAction()
    if nil == self.mMainPlayerActor then
        return
    end

    self.mMainPlayerActor:SetAction(self.mNextAction)
    self.mNextAction = nil
end

function gamePlayerController:BindMainActor(player)
    print("_______________Bind Main Player", player:GetID())

    -- set is mainPlayer
    self.mMainPlayerActor = player
    self.mMainPlayerActor:SetIsMainPlayer(true)
    self.mMainPlayerActor:SetGameActorActionHandler(self)

    --是否试玩模式
    local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
    if  shiwan and tonumber(shiwan) == 1 or global.IsReceiveRole then 
        global.IsVisitor = true
        local TradingBankLookPlayerProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankLookPlayerProxy)
        TradingBankLookPlayerProxy:RequestPlayerData(global.gamePlayerController:GetMainPlayerID())
        global.Facade:sendNotification(global.NoticeTable.ReconnectForbidden)
        global.Facade:sendNotification(global.NoticeTable.Layer_NPC_Talk_Close)
    end

    -- 
    global.Facade:sendNotification(global.NoticeTable.BindMainPlayer, player)
    SLBridge:onLUAEvent(LUA_EVENT_BIND_MAINPLAYER)

    -- 同步基础信息
    local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    PlayerPropertyProxy:SetRoleJob(player:GetJobID())
    PlayerPropertyProxy:SetRoleSex(player:GetSexID())

    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:SetBindMainPlayerFininsh(true)

    -- 删除绑定前添加
    global.actorManager:RmvMapXYActor(player, player:GetMapX(), player:GetMapY())
end

function gamePlayerController:handle_MSG_SC_ACTION_CONFIRM(msg)
    if nil == self.mMainPlayerActor then
        return -1
    end

    self.mMainPlayerActor:SetConfirmed(true)
    -- self.mMainPlayerActor:SetDashWaiting(false)
end

function gamePlayerController:handle_MSG_SC_SKILL_ACTION_CONFIRM(msg)
    if nil == self.mMainPlayerActor then
        return
    end

    local isConfirmed = true
    local msgLen = msg:GetDataLength()
    if msgLen > 0 then
        local msgHdr = msg:GetHeader()
        local dataString = msg:GetBodyStr()
        isConfirmed = dataString == self.mMainPlayerActor:GetID()
    end

    if isConfirmed then
        self.mMainPlayerActor:SetConfirmed(true)
        self.mMainPlayerActor:SetDashWaiting(false)
    end
end

function gamePlayerController:OnChangeScene( mapX, mapY )  
    if not self.mMainPlayerActor then
        return
    end
    
    if self.mMainPlayerActor:IsDie() or self.mMainPlayerActor:IsDeath() then
        return
    end

    -- Set player to new map position.
    local wX, wY = global.sceneManager:MapPos2WorldPos( mapX, mapY, true )
    self.mMainPlayerActor:SetAction(global.MMO.ACTION_IDLE)
    self.mMainPlayerActor:setPosition(wX, wY)
    global.actorManager:SetActorMapXY(self.mMainPlayerActor, mapX, mapY)

    -- stop player
    self.mMainPlayerActor:SetIsArrived(true)
    self.mMainPlayerActor:SetConfirmed(true)     
    self.mMainPlayerActor:SetDashWaiting(false)  

    --
    SLBridge:onLUAEvent("LUA_EVENT_PLAYER_MAPPOS_CHANGE")

    return 1
end

function gamePlayerController:handle_MSG_SC_NET_PLAYER_MOVE_FAIL(msg)
    local mainPlayer = self:GetMainPlayer()
    if nil == mainPlayer then
        return
    end

    if mainPlayer:IsDie() or mainPlayer:IsDeath() then
        return
    end

    local msgHdr = msg:GetHeader()
    print(string.format("!!!!!!!!!!! move fail:%d. [%d, %d] ---> [%d, %d]", msgHdr.recog, mainPlayer:GetMapX(), mainPlayer:GetMapY(), msgHdr.param1, msgHdr.param2))
    if msgHdr.param1 == -1 and msgHdr.param2 == -1 then -- 引擎网关无法返回正确位置, 特殊处理
        msgHdr.param1 = mainPlayer:GetMapX()
        msgHdr.param2 = mainPlayer:GetMapY()
        msgHdr.param3 = mainPlayer:GetDirection()
    end
    local wX, wY = global.sceneManager:MapPos2WorldPos(msgHdr.param1, msgHdr.param2, true)
    mainPlayer:SetDirection(msgHdr.param3)
    mainPlayer:setPosition(wX, wY)
    mainPlayer:SetIsArrived(true)
    mainPlayer:SetConfirmed(true)
    global.actorManager:SetActorMapXY(mainPlayer, msgHdr.param1, msgHdr.param2)

    -- 28号消息，recog=1的时候，可以立刻走，其他等待一下
    if msgHdr.recog == 1 then
        -- 拉回时等状态时间结束
        local currentActT = mainPlayer.mCurrentActT
        mainPlayer:SetAction(global.MMO.ACTION_IDLE_LOCK)
        mainPlayer.mCurrentActT = currentActT
    else
        -- 拉回时等状态时间结束
        local currentActT = mainPlayer.mCurrentActT
        mainPlayer:SetAction(global.MMO.ACTION_IDLE_LOCK)
        mainPlayer.mCurrentActT = currentActT
    end
end

function gamePlayerController:handle_MSG_SC_ACTOR_STUCK(actor)
    if ActorIsDie(actor) then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        actor:SetAction(global.MMO.ACTION_STUCK)
    else
        self:SetNextAction(global.MMO.ACTION_STUCK)
    end
end

function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS(actor, jsonData)
    if ActorIsDie(actor) then
        return nil
    end

    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:actorEnterAction(jsonData, true)
end

function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, jsonData)
    if ActorIsDie(actor) then
        return nil
    end

    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:requestSkillPresent(jsonData, 2)
end

-- 野蛮
function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local mapX    = msgHdr.t1
    local mapY    = msgHdr.t2
    local dir     = msgHdr.t3
    local time    = msgHdr.t4 * 0.001
    local skillID = msgHdr.t5 or 0

    -- 坐标不对
    if (mapX == actor:GetMapX() and mapY == actor:GetMapY()) or time == 0 then
        -- 执行野蛮失败撞墙动作
        return actor:SetAction(global.MMO.ACTION_DASH_FAIL)
    end

    -- 防止野蛮后后退
    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)

    if skillID == global.MMO.SKILL_INDEX_ZXC then 
        G_ActorUtils.ActorZhuiXinCi(actor, mapX, mapY, dir, time)
    else
        G_ActorUtils.ActorDash(actor, mapX, mapY, dir, time)
    end
end

-- 被野蛮，被推开
function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local mapX  = msgHdr.t1
    local mapY  = msgHdr.t2
    local dir   = msgHdr.t3
    local mTime = msgHdr.t4
    local iTime = msgHdr.t5

    -- 坐标不对
    if (mapX == actor:GetMapX() and mapY == actor:GetMapY()) or mTime == 0 then
        return
    end

    -- 防止野蛮后后退
    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)
    
    local moveTime = mTime * 0.001
    local idleTime = math.min(iTime * 0.001, 5)
    G_ActorUtils.ActorOnDash(actor, mapX, mapY, dir, moveTime, idleTime)
end

-- 十步一杀 瞬移
function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_82_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return false
    end

    -- 清理所有输入状态
    global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
    global.Facade:sendNotification(global.NoticeTable.InputIdle)

    -- 关闭技能
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    if SkillProxy:GetSelectSkill() == global.MMO.SKILL_INDEX_SBYS then
        SkillProxy:ClearSelectSkill()
    end
    
    local dir  = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y
    
    -- 进入十步一杀技能表现
    G_ActorUtils.ActorSBYS(actor, mapX, mapY, dir)

    SLBridge:onLUAEvent(LUA_EVENT_CLEAR_SELECT_SKILL, global.MMO.TEN_STEP_A_KILL)
end

-- 擒龙手 瞬移
function gamePlayerController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(actor, msgHdr)
    if ActorIsDie(actor) then
        return nil
    end

    local dir  = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y

    G_ActorUtils.ActorQLS(actor, mapX, mapY, dir)
end

function gamePlayerController:handle_Die(actor, msgHdr)
    -- Force stop player
    actor.mIsArrived = true
    actor:SetConfirmed(true)
    actor:SetDashWaiting(false)
    actor.mOrient = msgHdr.Dir
    local wX, wY = global.sceneManager:MapPos2WorldPos(actor.mCurrMapX, actor.mCurrMapY, true)
    actor:setPosition(wX, wY)
    actor:SetAction(global.MMO.ACTION_DIE)

    -- 
    global.actorManager:SetActorMapXY(actor, msgHdr.X, msgHdr.Y)

    -- 
    local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    PlayerPropertyProxy:SetAlive(false)
end

function gamePlayerController:handle_Revive(actor, jsonData)
    -- feature
    if jsonData.curHP and jsonData.maxHP then
        actor:SetCurAbilByID(GUIDefine.AttTypeTable.HP, jsonData.curHP)
        actor:SetMaxAbilByID(GUIDefine.AttTypeTable.HP, jsonData.maxHP)
        actor:RefHPHUD()
    end

    -- To map grid position
    local wX, wY = global.sceneManager:MapPos2WorldPos(jsonData.X, jsonData.Y, true)

    actor:SetConfirmed(true)
    actor:SetIsArrived(true)
    actor:StopAnimToFrame(nil)
    actor:setPosition(wX, wY)
    actor:SetDirection(jsonData.Dir)
    actor:SetAction(global.MMO.ACTION_IDLE, true)
    actor:DirtyAnimFlag()

    -- 
    global.actorManager:SetActorMapXY(actor, jsonData.X, jsonData.Y)

    -- 刷新主玩家安全区
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    MapProxy:UpdateInSafeAreaState()

    -- 
    local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    PlayerPropertyProxy:SetAlive(true)

    -- 
    global.Facade:sendNotification(global.NoticeTable.Audio_Play_BGM, {type = global.MMO.SND_TYPE_BGM_MAP})

    -- 
    local actorID = jsonData.actorID
    global.Facade:sendNotification(global.NoticeTable.ActorRevive, actorID)

    -- 
    SharedT.actorID = actorID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_REVIVE, SharedT)

    -- 
    global.Facade:sendNotification(global.NoticeTable.SceneFollowMainPlayer)
end

function gamePlayerController:handle_Move_Force(actor, jsonData)
    self:SetNextAction(nil)

    if ActorIsDie(actor) then
        return
    end

    local wX, wY = global.sceneManager:MapPos2WorldPos(jsonData.mapX, jsonData.mapY, true)
    actor:SetAction(global.MMO.ACTION_IDLE, true)
    actor.mIsArrived = true
    actor.mIsConfirmed = true
    actor:SetDirection(jsonData.dir)
    actor:setPosition(wX, wY)
    global.actorManager:SetActorMapXY(actor, jsonData.mapX, jsonData.mapY)

    global.Facade:sendNotification(global.NoticeTable.SceneFollowMainPlayer)
end

return gamePlayerController 
