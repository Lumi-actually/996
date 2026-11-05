local gameMapController = class("gameMapController")
gameMapController.NAME  = "gameMapController"
local optionsUtils = requireUtil("optionsUtils")
local cjson = require("cjson")

local fireSet = {
    [4]  = 27,      -- 困魔咒
    [5]  = 36,      -- 正常火墙
}

-- 转换race， 这些是守卫
local convertDefenderRace = 
{
    [11] = 1,
    [55] = 1,
    [110] = 1,
    [111] = 1,
    [112] = 1,
}

local InputMoveT = {type = GUIDefine.InputMoveType.AUTOMOVE}
local ActorMoveForceT = {}
local ActorIDTable = {}
local FlyInT = {}
local ActorMoveT = {}

local sharedActorTurnTab = {}
function gameMapController:ctor()
    self:RegisterMsgHandler()
end

function gameMapController:destory()
end

function gameMapController:create()
    local _this = gameMapController.new()
    return _this
end

function gameMapController:Cleanup()
    self:CleanupActor(true)
end

function gameMapController:CleanupActor(cleanMainPlayer)
    global.npcManager:Cleanup()
    global.playerManager:Cleanup()
    global.monsterManager:Cleanup()
    global.dropItemManager:Cleanup()
    global.sceneEffectManager:Cleanup()
    global.netPlayerController:Cleanup()
    global.netMonsterController:Cleanup()

    -- 不清主玩家
    if global.gamePlayerController:GetMainPlayer() then
        local mainPlayer = global.gamePlayerController:GetMainPlayer()

        -- remove actors trace
        local actors = global.actorManager:GetActors()
        for k, v in pairs(actors) do
            if not v:IsMainPlayer() then
                global.Facade:sendNotification(global.NoticeTable.ActorOutOfView, v:GetID())
            end
        end

        -- release all actor
        global.actorManager:RemoveAllActor((not cleanMainPlayer) and mainPlayer:GetID() or 0)

        -- keep trace main player
        if not cleanMainPlayer then
            global.playerManager:AddPlayer(mainPlayer)
        else
            global.gamePlayerController:CleanupMainPlayer()
        end
    end
end

function gameMapController:handle_MSG_SC_MAP_ACTOR_CLEANUP(msg)
    self:CleanupActor(false)
end

function gameMapController:handle_MSG_SC_CREATE_MAIN_PLAYER(msg ,msgID)
    dump("主玩家创建______________")
    -- 创建主玩家
    self:handle_InOfView(msgID, msg, true)
end

function gameMapController:handle_MSG_SC_NET_ACTOR_IN_OF_VIEW(msg, msgID)
    -- 创建网络玩家
    LuaProfiler.BeginSample("handle_MSG_SC_NET_ACTOR_IN_OF_VIEW")
    self:handle_InOfView(msgID, msg, false)
    LuaProfiler.EndSample()
end

function gameMapController:refreshActor(actor, jsonData, buffer)
    jsonData.StoneMode = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRSPABIL, global.MMO.STATE_TYPE_STONE)
    jsonData.caved = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRSPABIL, global.MMO.STATE_TYPE_CAVED)
    jsonData.skeleton = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRSPABIL, global.MMO.STATE_TYPE_SKELETON)
    jsonData.die = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRSPABIL, global.MMO.STATE_TYPE_DIE)

    local stopAnimFrame = nil
    local action = global.MMO.ACTION_IDLE
    if jsonData.StoneMode then
        -- 1:祖玛雕像的石化状态
        action = global.MMO.ACTION_BORN
        stopAnimFrame = 1

    elseif jsonData.caved == true then
        -- 触龙神/食人花在地下隐藏状态
        action = global.MMO.ACTION_CAVE
        stopAnimFrame = 1

    elseif jsonData.skeleton == true then
        -- 死亡, 骨头
        action = global.MMO.ACTION_DEATH

    elseif jsonData.die == true then
        action = global.MMO.ACTION_DIE
        stopAnimFrame = -1
    end
    -- 是城墙
    if actor:IsWall() then
        if jsonData.Dir then
            stopAnimFrame = jsonData.Dir + 1
        end
        actor:SetKeyValue(global.MMO.Is_Wall, true)
    end

    -- 是沙巴克大门
    if actor:IsGate() then
        if jsonData.Dir then
            local isOpen = jsonData.Dir >= 3
            actor:SetGateOpenState(isOpen)
        end
        actor:SetKeyValue(global.MMO.Is_Gate, true)
    end

    -- set actor property
    if actor:IsMonster() then
        actor:SetTypeIdex(jsonData.clothID)
    end
    actor:SetDirection(jsonData.Dir or global.MMO.ORIENT_U)
    actor:SetAppearByID(global.MMO.P_F_CLOTH, jsonData.clothID)
    G_ActorUtils.SetActorProperty(actor, jsonData)
    actor:SetAction(action, true)
    actor:StopAnimToFrame(stopAnimFrame)
    actor:DirtyAnimFlag()

    -- refresh pos
    local mapX = jsonData.X
    local mapY = jsonData.Y
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    actor:setPosition(wX, wY)
    global.actorManager:SetActorMapXY(actor, mapX, mapY)
end

local sharedLuaEvent = {}
local mainPropertyT = {}
local inOfViewT = {}
local hudParamT = {}
function gameMapController:handle_InOfView(msgID, netPkg, isMainPlayer)
    local header = netPkg:GetHeader3_Str()
    local buffer = netPkg:GetBodyLuaBuffer()
    -- 消息头数据 
    inOfViewT.UserID = header.Id
    inOfViewT.X = header.X
    inOfViewT.Y = header.Y
    inOfViewT.Dir = header.Dir
    inOfViewT.race = header.Type
    inOfViewT.nActorId = header.Flag
    inOfViewT.raceImg = header.X2
    ---------------------------------------------------------------------------
    inOfViewT.clothID = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRAPPEAR, global.MMO.P_F_CLOTH)
    inOfViewT.faction = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_PKCAMPID)
    ---------------------------------------------------------------------------
    local actorID = inOfViewT.UserID
    local actor = global.actorManager:GetActor(actorID)
    if actor then
        print("--------------- IN OF VIEW, ACTOR IS EXIST, 联系SFY", actorID, actor:GetName(), msgID)

        -- 移动到位置  吸怪
        if actor:IsMonster() then
            local actorMapX = actor:GetMapX()
            local actorMapY = actor:GetMapY()
            local curMapX   = inOfViewT.X
            local curMapY   = inOfViewT.Y
            if curMapX and curMapY and (actorMapX ~= curMapX or actorMapY ~= curMapY) then
                actor:SetMoveTo(curMapX, curMapY)
                actor:SetAction(global.MMO.ACTION_WALK)
                actor:SetConfirmed(true)
            end
        end
        return actor
    end
    ------------------------
    local race      = inOfViewT.race
    local isPlayer  = false
    local isNpc     = false
    local isMonster = false
    -- 0:player;1:hero;150:humanoid
    if race == global.MMO.ACTOR_RACE_NET_PLAYER or race == global.MMO.ACTOR_RACE_HERO or race == global.MMO.ACTOR_RACE_HUMANOID then
        isPlayer    = true
    elseif race == global.MMO.ACTOR_RACE_NPC then
        isNpc       = true
    else
        isMonster   = true
    end

    local actor   = nil
    -- 0:player;1:hero;150:humanoid
    if isPlayer then
        actor = global.netPlayerController:AddNetPlayerToWorld(actorID)
    elseif isNpc then
        actor = global.netNpcController:AddNetNpcToWorld(actorID)
    else
        actor = global.netMonsterController:AddNetMonsterToWorld(actorID, inOfViewT.clothID)
    end

    if nil == actor then
        dump(actor,"actor 创建失败")
        return nil
    end
    actor:SetBuffer(buffer)

    ------------------------------------------------------------
    -- restore actor data
    self:refreshActor(actor, inOfViewT, buffer)

    -- 主玩家，绑定创建
    if isMainPlayer and actor:IsPlayer() then
        dump("绑定主玩家")
        global.gamePlayerController:BindMainActor(actor)
        mainPropertyT.Sex = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_SEX)
        mainPropertyT.Job = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_JOB)
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        PlayerPropertyProxy:SetRoleProperty(mainPropertyT)
    elseif actor:IsHero() then -- 英雄判定使用race, 得在refreshActor之后
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        local HeroID = HeroPropertyProxy:GetRoleUID()
        if HeroID and HeroID == actorID then
            mainPropertyT.Sex = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_SEX)
            mainPropertyT.Job = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_JOB)
            local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
            HeroPropertyProxy:SetRoleProperty(mainPropertyT)
        end
    end

    if actor:IsMonster() then
        -- Add to monster manager
        global.monsterManager:AddMonster(actor)

    elseif actor:IsPlayer() then
        -- Add to player manager
        global.playerManager:AddPlayer(actor)

    elseif actor:IsNPC() then
        -- Add to npc manager
        global.npcManager:AddNpc(actor)
    end
    -- in of view
    local hudParam = {}
    hudParam.Name = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_NAME)
    hudParam.GuildID = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_GUILDID)
    hudParam.GuildName = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_GUILDNAME)
    hudParam.stallname = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_STALLNAME)
    hudParam.RankName = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_RANKNAME)
    hudParam.castlename = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_CASTLENAME)
    hudParam.title = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_TITLE)
    hudParam.Color = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_COLOR)
    hudParam.Candle = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_CANDLE)
    hudParamT.actorID  = actorID
    hudParamT.hudParam = hudParam
    global.Facade:sendNotification(global.NoticeTable.ActorInOfView, hudParamT)

    self:RefreshHorse(actorID, buffer)

    -- lua event
    sharedLuaEvent.id = actorID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, sharedLuaEvent)
    return actor
end

function gameMapController:handle_MSG_SC_NET_ACTOR_DEATH_FALL_DOWN(msg)
    local header = msg:GetHeader3_Str()
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    ActorIDTable.actorID = actorID

    if actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_Die(actor, header)  
            global.Facade:sendNotification(global.NoticeTable.Audio_Play_BGM, {type = global.MMO.SND_TYPE_BGM_DIE})
        else
            global.netPlayerController:handle_Die(actor, header)
            SLBridge:onLUAEvent(LUA_EVENT_NET_PLAYER_DIE, ActorIDTable)
        end
        global.Facade:sendNotification(global.NoticeTable.ActorPlayerDie, actorID)

        local slt = global.SLT.AudioPlayTable3
        slt.type = global.MMO.SND_TYPE_PLAYER_DIE
        slt.index = actor:GetSexID()
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    elseif actor:IsMonster() then
        global.netMonsterController:handle_Die(actor, header) 
        global.Facade:sendNotification(global.NoticeTable.ActorMonsterDie, actorID)

        local slt = global.SLT.AudioPlayTable3
        slt.type = global.MMO.SND_TYPE_MON_DIE
        slt.index = actor:GetAnimationID()
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

        SLBridge:onLUAEvent(LUA_EVENT_MONSTER_DIE, ActorIDTable) 
    end

    global.Facade:sendNotification(global.NoticeTable.ActorDie, {actorID = actorID, actor = actor})

    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_DIE, ActorIDTable)
end

function gameMapController:handle_MSG_SC_NET_ACTOR_DEATH_SKELETON(netPkg)
    local header = netPkg:GetHeader3_Str()
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    
    -- monster only.
    if actor:IsMonster() then
        global.netMonsterController:handle_DeathSkeleton(actor, header) 
        global.Facade:sendNotification(global.NoticeTable.ActorMonsterDeath, actorID)
        ActorIDTable.actorID = actorID
        SLBridge:onLUAEvent(LUA_EVENT_ACTOR_DIE, ActorIDTable)
    end
end

local actorReviveT = {}
local actorReviveEventT = {}
function gameMapController:handle_MSG_SC_NET_ACTOR_REVIVE(netPkg)
    local bodyBuffer = netPkg:GetBodyLuaBuffer()
    local header     = netPkg:GetHeader3_Str()
    local actorID    = header.Id
    local X          = header.X
    local Y          = header.Y
    local Dir        = header.Dir
    local curHP      = bodyBuffer:ReadInt64()
    local maxHP      = bodyBuffer:ReadInt64()

    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end

    actorReviveT.actorID = actorID
    actorReviveT.Dir = Dir
    actorReviveT.X = X
    actorReviveT.Y = Y
    actorReviveT.curHP = curHP
    actorReviveT.maxHP = maxHP

    if actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_Revive(actor, actorReviveT)
        else
            global.netPlayerController:handle_Revive(actor, actorReviveT)
            actorReviveEventT.actorID = actor:GetID()
            SLBridge:onLUAEvent(LUA_EVENT_NET_PLAYER_REVIVE, actorReviveEventT)
        end
    elseif actor:IsMonster() then
        global.netMonsterController:handle_Revive(actor, actorReviveT)
        actorReviveEventT.actorID = actor:GetID()
        SLBridge:onLUAEvent(LUA_EVENT_MONSTER_REVIVE, actorReviveEventT)
    end
end

function gameMapController:handle_MSG_SC_NET_ACTOR_OUT_OF_VIEW(msg)
    local msgHdr = msg:GetHeader3_Str()
    local actorID = msgHdr.Id
    -- dump(msgHdr.param1,"msgHdr.param1__")
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end

    -- 主玩家
    if actor:IsMainPlayer() then
        return
    end

    -- Remove from monster manager
    if actor:IsMonster() then  
        global.monsterManager:RmvMonster(actorID)
        global.netMonsterController:handleActorOutOfView(actor)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            -- effect
            local mainPlayer = global.gamePlayerController:GetMainPlayer()
            if mainPlayer and msgHdr.param1 ~= 1 then
                global.Facade:sendNotification(global.NoticeTable.ActorFlyOut, mainPlayer, 0)
            end
            return 1
        end

        -- 恢复攻击状态和护身
        actor:SetDamage()
        actor:SetHuShen()

        global.playerManager:RmvPlayer(actorID)
        global.netPlayerController:handleActorOutOfView(actor)
    elseif actor:IsNPC() then
        global.npcManager:RmvNpc(actorID)
    end

    global.Facade:sendNotification(global.NoticeTable.ActorOutOfView, actorID)

    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, {id = actorID})

    return global.actorManager:RemoveActor(actorID)
end


function gameMapController:handle_MSG_SC_NET_PLAYER_FLY_IN(msg)
    local msgHdr = msg:GetHeader3_Str()
    local mapX = msgHdr.X
    local mapY = msgHdr.Y
    local dir  = msgHdr.Dir
    local effectType = msgHdr.Type
    local noShow = effectType == 1

    -- dump(msgHdr.Id,"actorid__")

    -- audio
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_IN
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    -- effect
    if not noShow then
        local effectId = effectType and effectType > 1 
        FlyInT.x = mapX
        FlyInT.y = mapY
        global.Facade:sendNotification(global.NoticeTable.ActorFlyIn, FlyInT, effectId or 0)
    end

    -- 如果有actor，强行刷坐标
    local actorID = msgHdr.Id
    if actorID == 0 then 
        return 
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    -- 主玩家不需要强拉坐标，切地图时已经带了坐标
    if actor:IsPlayer() and actor:IsMainPlayer() then
        return nil
    end

    if actor:IsMonster() then
        global.netMonsterController:handle_FlyIn(actor, msgHdr)
        
    elseif actor:IsPlayer() then
        global.netPlayerController:handle_FlyIn(actor, msgHdr)
    end
    ActorMoveForceT.actorID = actorID
    global.Facade:sendNotification(global.NoticeTable.ActorMoveForce, ActorMoveForceT)
end

function gameMapController:handle_MSG_SC_NET_PLAYER_FLY_IN_2(msg)
    local msgHdr = msg:GetHeader3_Str()
    local mapX = msgHdr.X
    local mapY = msgHdr.Y
    local dir  = msgHdr.Dir
    local effectType = msgHdr.Type
    local noShow = effectType == 1

    -- audio
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_IN
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    -- effect
    if not noShow then
        local effectId = effectType > 1 and effectType
        FlyInT.x = mapX
        FlyInT.y = mapY
        global.Facade:sendNotification(global.NoticeTable.ActorFlyIn, FlyInT, effectId or 1)
    end

    -- 如果有actor，强行刷坐标
    local actorID = msgHdr.Id
    if actorID == 0 then 
        return 
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    -- 主玩家不需要强拉坐标，切地图时已经带了坐标
    if actor:IsPlayer() and actor:IsMainPlayer() then
        return nil
    end

    if actor:IsMonster() then
        global.netMonsterController:handle_FlyIn2(actor, msgHdr)
        
    elseif actor:IsPlayer() then
        global.netPlayerController:handle_FlyIn2(actor, msgHdr)
    end

    ActorMoveForceT.actorID = actorID
    global.Facade:sendNotification(global.NoticeTable.ActorMoveForce, ActorMoveForceT)
end

function gameMapController:handle_MSG_SC_NET_PLAYER_FLY_OUT(msg)
    local msgHdr = msg:GetHeader3_Str()
    local effectType = msgHdr.Type
    local noShow = effectType == 1

    local actorID = msgHdr.Id
    if actorID == 0 then 
        return 
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    -- audio
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_OUT
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    
    -- effect
    if not noShow then
        local effectId = effectType > 1 and effectType
        global.Facade:sendNotification(global.NoticeTable.ActorFlyOut, actor, effectId or 0)
    end
end

function gameMapController:handle_MSG_SC_NET_PLAYER_FLY_OUT_2(msg)
    local msgHdr = msg:GetHeader3_Str()
    local effectType = msgHdr.Type
    local noShow = effectType == 1

    local actorID = msgHdr.Id
    if actorID == 0 then 
        return 
    end

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    -- audio
    local slt = global.SLT.AudioPlayTable1
    slt.type = global.MMO.SND_TYPE_FLY_OUT
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    
    -- effect
    if not noShow then
        local effectId = effectType > 1 and effectType
        global.Facade:sendNotification(global.NoticeTable.ActorFlyOut, actor, effectId or 1)
    end
end

function gameMapController:handle_MSG_SC_PLAYER_FEATURE_CHANGED(netPkg)
    local header = netPkg:GetHeader11_Str()
    local actorID = header.t0
    
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end
    local count = header.t1
    local sex = header.t2
    local job = header.t3
    actor:SetSexID(sex)
    actor:SetJobID(job)
    -- 同步至PlayerProperty、HeroPropertyProxy
    if actor:IsMainPlayer() then 
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        PlayerProperty:SetRoleSex(sex)
        PlayerProperty:SetRoleJob(job)
    elseif actor:IsHero() then
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        local heroID = HeroPropertyProxy:GetRoleUID()
        if actorID == heroID then
            HeroPropertyProxy:SetRoleSex(sex)
            HeroPropertyProxy:SetRoleJob(job)
        end 
    end
    
    -- 外观
    local buffer = netPkg:GetBodyLuaBuffer()
    for i = 1, count do
        local id = buffer:ReadByte()
        local value = buffer:ReadInt()
        actor:SetAppearByID(id, value)
    end
    global.Facade:sendNotification(global.NoticeTable.DelayActorFeatureChange, actorID)
end

function gameMapController:handle_MSG_SC_PET_FEATURE_CHANGED(netPkg)
    local header = netPkg:GetHeader11_Str()
    local actorID = header.t0
    
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end
    -- 外观
    local appearID = header.t1
    actor:SetAppearByID(global.MMO.P_F_CLOTH, appearID)
    global.Facade:sendNotification( global.NoticeTable.DelayDirtyFeature, actorID)
end

function gameMapController:handle_MSG_SC_NET_ACTOR_MOVE(netPkg)
    local header = netPkg:GetHeader3_Str()
    local actorID = header.Id
    -- dump(header,"header___")
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    if actor:IsMainPlayer() then
        -- 主玩家不应该接收此消息
        return
    end

    ActorMoveT.X = header.X
    ActorMoveT.Y = header.Y
    ActorMoveT.Dir = header.Dir
    -- dump(moveData,"moveData______")
    if actor:IsMonster() then
        return global.netMonsterController:handle_MSG_SC_ACTOR_WALK(actor, ActorMoveT)
    elseif actor:IsPlayer() then
        return global.netPlayerController:handle_MSG_SC_ACTOR_WALK(actor, ActorMoveT)
    end
end

function gameMapController:handle_MSG_SC_NET_ACTOR_RUN(netPkg)
    self:handle_Run(netPkg)
end

function gameMapController:handle_MSG_SC_WALKEX(netPkg)
    self:handle_Run(netPkg, true)
end

function gameMapController:handle_Run(netPkg, isRunOne)
    local header = netPkg:GetHeader3_Str()
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    if actor:IsMainPlayer() then
        -- 主玩家不应该接收此消息
        return
    end

    ActorMoveT.X = header.X
    ActorMoveT.Y = header.Y
    ActorMoveT.Dir = header.Dir

    actor:SetKeyValue(global.MMO.IS_RUN_ONE, isRunOne)
    if actor:IsMonster() then
        return global.netMonsterController:handle_MSG_SC_ACTOR_RUN(actor, ActorMoveT)
    elseif actor:IsPlayer() then
        return global.netPlayerController:handle_MSG_SC_ACTOR_RUN(actor, ActorMoveT)
    end
end

function gameMapController:handle_MSG_SC_NET_PLAYER_RIDE_RUN(netPkg)
    local header = netPkg:GetHeader3_Str()
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end
    if actor:IsMainPlayer() then
        -- 主玩家不应该接收此消息
        return
    end

    ActorMoveT.X = header.X
    ActorMoveT.Y = header.Y
    ActorMoveT.Dir = header.Dir

    if actor:IsPlayer() then
        return global.netPlayerController:handle_MSG_SC_ACTOR_RIDE_RUN(actor, ActorMoveT)
    end
end

function gameMapController:handle_MSG_SC_NET_ACTOR_TURN(netPkg)
    local header = netPkg:GetHeader3_Str()
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end

    sharedActorTurnTab.dir = header.Dir
    sharedActorTurnTab.actorID = actorID

    if actor:IsMonster() then
        if actor.GetRaceServer and actor:GetRaceServer() == global.MMO.ACTOR_SERVER_RACE_KNIEF then
            G_ActorUtils.SetActorAttrByID(actorID, global.MMO.ACTOR_ATTR_DIR, header.Dir)
        else 
            global.netMonsterController:handle_MSG_SC_NET_ACTOR_TURN(actor, header)
        end
        SLBridge:onLUAEvent(LUA_EVENT_MONSTER_TURN, sharedActorTurnTab)
    elseif actor:IsPlayer() then
        global.netPlayerController:handle_MSG_SC_NET_ACTOR_TURN(actor, header)
        if not actor:IsMainPlayer() then
            SLBridge:onLUAEvent(LUA_EVENT_NET_PLAYER_TURN, sharedActorTurnTab)
        end
    end

    global.BuffManager:UpdateBuffSfxDir(actorID)
    global.ActorEffectManager:UpdateEffectDir(actor, actorID)
end

function gameMapController:handle_MSG_SC_ACTION_PICK_CORPSE(netPkg)
    local header = netPkg:GetHeader11_Str()
    local actorID = header.t0
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor then
        return nil
    end

    local ret = -3
    if actor:IsPlayer() then
        if not actor:IsMainPlayer() then
            if header.t1 == 1 then
                --挖矿
                ret = global.netPlayerController:handleActorMining(actor, header.t4)

            else
                --挖尸体
                ret = global.netPlayerController:handleActorSitdown(actor, header.t4)
            end 
        end

        if header.t2 >= 1 then
            if actor:IsMainPlayer() then
                --挖矿 起灰特效
                local present =
                {
                    skillID = 999,
                    launchX = actor:GetMapX(),
                    launchY = actor:GetMapY(),
                    hitX    = actor:GetMapX(),
                    hitY    = actor:GetMapY(),
                    dir     = actor:GetDirection(),
                    skillStage = 3,
                    launcherID = actor:GetID()
                }
                global.Facade:sendNotification(global.NoticeTable.RequestSkillPresent, present)

                -- 挖矿 起灰音效
                local slt = global.SLT.AudioPlayTable1
                slt.type = global.MMO.SND_TYPE_MINING_DROP
                global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
            end
            
            --挖矿 广播土堆
            local item  = 
            {
                id      = header.t3,
                type    = global.MMO.EFFECT_TYPE_MINING_HIT,
                x       = actor:GetMapX(),
                y       = actor:GetMapY(),
                param   = header.t2,
            }
            self:AddSpecialEffect(item)
        end
    end
end

function gameMapController:handle_MSG_SC_ACTOR_UPDATE_ATTR(netPkg, msgID)
    local actorID = netPkg:GetP0Str()
    local buffer  = netPkg:GetBodyLuaBuffer()
    local actor   = global.actorManager:GetActor(actorID)

    local isMyHero = false
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    local HeroID = HeroPropertyProxy:GetRoleUID()
    if HeroID and HeroID == actorID then
        isMyHero = true
    end

    local arrCurAbil = {}
    local arrMaxAbil = {}
    local arrAbilIDs = {}
    local num = 0
    local length = netPkg:GetBodyLen()
    local offset = 1
    while offset <= length do
        local abilID = buffer:ReadShort()
        offset = offset + 2
        local curValue = buffer:ReadInt64()
        offset = offset + 8
        local maxValue = buffer:ReadInt64()
        offset = offset + 8

        num = num + 1
        arrAbilIDs[num] = abilID

        arrCurAbil[abilID] = curValue
        arrMaxAbil[abilID] = maxValue
        
        if actor then
            actor:SetCurAbilByID(abilID, curValue)
            actor:SetMaxAbilByID(abilID, maxValue)
        end
    end

    -- 同步主玩家和自己的英雄
    local key = actor and (actor:IsMainPlayer() and global.ProxyTable.PlayerPropertyProxy or (isMyHero and global.ProxyTable.HeroPropertyProxy))

    -- 英雄不在视野外,仍要同步属性..
    if not actor and isMyHero then
        key = global.ProxyTable.HeroPropertyProxy
    end
    if key then
        local proxy = global.Facade:retrieveProxy(key)
        proxy:InitAbilID(arrAbilIDs, num)
        if not proxy:IsInited() then 
            proxy:InitProperty(arrCurAbil, arrMaxAbil)

            proxy:NotifyUpdateAbil(arrCurAbil, arrMaxAbil, true)
            
            proxy:UpdateLastArrCurAbil(arrCurAbil)
            proxy:UpdateLastArrMaxAbil(arrMaxAbil)
        else
            proxy:UpdateArrCurAbil(arrCurAbil)
            proxy:UpdateArrMaxAbil(arrMaxAbil)

            proxy:NotifyUpdateAbil(arrCurAbil, arrMaxAbil)

            -- 记录上次属性
            proxy:UpdateLastArrCurAbil(arrCurAbil)
            proxy:UpdateLastArrMaxAbil(arrMaxAbil)
        end
    end

    -- 刷血条HUD
    if arrCurAbil[GUIDefine.AttTypeTable.HP] or arrMaxAbil[GUIDefine.AttTypeTable.HP] or arrCurAbil[GUIDefine.AttTypeTable.MP] or arrMaxAbil[GUIDefine.AttTypeTable.MP] or arrCurAbil[GUIDefine.AttTypeTable.Level]  then
        ActorIDTable.actorID = actorID
        global.Facade:sendNotification(global.NoticeTable.RefreshActorHP, ActorIDTable) 
        SLBridge:onLUAEvent(LUA_EVENT_ACTOR_HP_REFRESH, ActorIDTable)
    end

    -- 内力值改变
    if actor and (actor:IsPlayer() or actor:IsHero()) then
        local lastCurAbilV = actor:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_Value)
        local lastMaxAbilV = actor:GetLastCurAbilByID(GUIDefine.AttTypeTable.Internal_Value)
        local setCurAbilV = arrCurAbil[GUIDefine.AttTypeTable.Internal_Value]
        local setMaxAbilV = arrMaxAbil[GUIDefine.AttTypeTable.Internal_Value]
        -- 服务端计算属性时会推送所有属性, 内力值有差异再更新
        if (setCurAbilV and lastCurAbilV ~= setCurAbilV) or (setMaxAbilV and lastMaxAbilV ~= setMaxAbilV) then
            actor:RefNGHUD()
            ActorIDTable.actorID = actorID
            global.Facade:sendNotification(global.NoticeTable.RefreshActorIForce, ActorIDTable)
        end
    end
end

local refreshActorHPT = {}
function gameMapController:handle_MSG_SC_ACTOR_DAMAGE_HP(netPkg)
    local header  = netPkg:GetHeader11()
    local actorID = netPkg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    -- 飘字类型、是否护身、是否是魔法、后仰标记
    local pxType, huShen, magic, struchRules, weaponID = header.t1, header.t2, header.t3, header.t4 or 0, header.t5

    local buffer       = netPkg:GetBodyLuaBuffer()
    local damageValue  = buffer:ReadInt64Str()         -- 伤害值
    local attackUserID = buffer:ReadInt64Str()         -- 伤害来源

    -- 后仰
    local struck = 1 -- 默认后仰
    local isMain = (actor:IsPlayer() and actor:IsMainPlayer()) or false

    -- 以前是后端判断,  改成前端自行判断
    if (isMain and CheckBit(struchRules, 0)) or ((actor:IsPlayer() or actor:IsHero()) and CheckBit(struchRules, 1)) or (actor:IsMonster() and CheckBit(struchRules, 2)) then
        struck = 0
    end

    if struck == 1 then -- 后仰状态
        self:handle_Stuck(actor)
    end

    -- 音效
    local audioType = magic ~= 1 and global.MMO.SND_TYPE_STUCK or global.MMO.SND_TYPE_SCREAM
    local slt = global.SLT.AudioPlayTable2
    slt.type = audioType
    slt.index = weaponID
    slt.param = actorID
    global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)

    refreshActorHPT.actorID   = actorID
    refreshActorHPT.isDamage  = true
    refreshActorHPT.unAattack = true
    refreshActorHPT.huShen    = huShen    

    global.Facade:sendNotification(global.NoticeTable.RefreshActorHP, refreshActorHPT)

    ActorIDTable.actorID = actorID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_HP_REFRESH, ActorIDTable)

    -- 飘字
    if pxType > 0 then
        global.Facade:sendNotification(global.NoticeTable.ShowThrowDamage, {
            Id = pxType,
            UserID = actorID,
            Power = damageValue,
            TargetID = attackUserID
        })
    end

    GUIFunction:OnAutoFightBackFunc(attackUserID, actorID)
end

-- 技能相关还未做
-- 护身状态掉蓝由服务端直接通知反击
function gameMapController:handle_MSG_SC_FIGHT_BACK_ID(msg)
    local header = msg:GetHeader()
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return
    end
    
    local attackActorID = msg:GetBodyStr()
    local actor = global.actorManager:GetActor(attackActorID)
    if not actor then
        return
    end

    if not actor:IsPlayer() then
        return
    end

    GUIFunction:OnAutoFightBackFunc(attackActorID)
end

function gameMapController:handle_Stuck(actor)
    if actor:IsDie() then
        return false
    end

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_ACTOR_STUCK(actor)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_ACTOR_STUCK(actor)
        else
            global.netPlayerController:handle_MSG_SC_ACTOR_STUCK(actor)
        end
    end
end

local guildsT = {}
function gameMapController:handle_MSG_SC_ACTOR_NAME(netPkg)
    local buffer = netPkg:GetBodyLuaBuffer()
    local jsonData = {}
    ---------------------------------------------------------------------------
    jsonData.UserID             = buffer:ReadInt64Str()
    jsonData.nLevel             = buffer:ReadInt()
    jsonData.Color              = buffer:ReadShort()
    jsonData.SColor             = buffer:ReadShort()
    jsonData.Name               = SL:GBKToUTF8(buffer:ReadShortString(200))
    jsonData.GuildID            = SL:GBKToUTF8(buffer:ReadShortString(40))
    jsonData.GuildName          = SL:GBKToUTF8(buffer:ReadShortString(30))
    jsonData.Rank               = buffer:ReadInt()
    jsonData.RankName           = SL:GBKToUTF8(buffer:ReadShortString(30))
    jsonData.castlename         = SL:GBKToUTF8(buffer:ReadShortString(10))
    jsonData.HaveMaster         = buffer:ReadBool()
    jsonData.MasterId           = buffer:ReadInt64Str()
    jsonData.MasterName         = SL:GBKToUTF8(buffer:ReadShortString(30))
    jsonData.ShenMiRen          = buffer:ReadBool()
    jsonData.WarZone            = buffer:ReadByte()
    jsonData.STID               = buffer:ReadInt64()
    jsonData.DearID             = buffer:ReadInt64()
    jsonData.pklv               = buffer:ReadInt()
    jsonData.nServerId          = buffer:ReadInt()
    jsonData.nationid           = buffer:ReadByte()
    jsonData.faction            = buffer:ReadInt64()
    --------------------------------------------------------------------------
    local actorID = jsonData.UserID
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    local guildID = actor:IsPlayer() and actor:GetGuildID() or nil
    local nationID = nil
    if actor:IsMonster() or actor:IsPlayer() then
        nationID = actor:GetNationID()
    end

    G_ActorUtils.SetActorProperty(actor, jsonData)
    G_ActorUtils.SetActorName(actor, jsonData)
    G_ActorUtils.SetActorAttrByID(actorID, global.MMO.ACTOR_ATTR_HUDPARAM, jsonData)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDLabel,  actorID)

    local newGuildID = actor:IsPlayer() and actor:GetGuildID() or nil
    if guildID ~= newGuildID then
        local guilds = {}
        if guildID and guildID ~= "" then
            guilds[guildID] = true
        end

        if newGuildID and newGuildID ~= "" then
            guilds[newGuildID] = true
        end
        
        if next(guilds) then
            global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, guilds)
        end
    end

    if (actor:IsPlayer() or actor:IsMonster()) and nationID ~= actor:GetNationID() then
        if actor:IsPlayer() and actor:IsMainPlayer() then
            global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, {isNation = true, isAll = true})
        else
            global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, {isNation = true, actorID = actor:GetID()})
        end
    end
end

function gameMapController:handle_MSG_SC_SELL_NOTICE(netPkg)
    local msgHdr = netPkg:GetHeader3_Str()
    local actorID = msgHdr.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    local stallname = netPkg:GetBodyStr() or ""
    -- dump(stallname,"stallname____")
    local sellStatus = msgHdr.Flag
    actor:SetAction(global.MMO.ACTION_IDLE)

    if sellStatus == 1 then
        local wX, wY = global.sceneManager:MapPos2WorldPos(msgHdr.X, msgHdr.Y, true)
        actor:setPosition(wX, wY)
        actor:SetDirection(msgHdr.Dir)
        actor:DirtyAnimFlag()

        global.actorManager:SetActorMapXY(actor, msgHdr.X, msgHdr.Y, true)
    end

    --摆摊状态 (0, 1)
    actor:SetSellStatus(sellStatus)

    --摊位名字
    actor:SetStallName(stallname)

    global.Facade:sendNotification(global.NoticeTable.PlayerStallStatusChange, actorID)
    global.Facade:sendNotification(global.NoticeTable.RefreshActorBooth, {actorID = actorID, actor = actor})

    ActorIDTable.actorID = actorID
    if actorID == global.gamePlayerController:GetMainPlayerID() then
        SLBridge:onLUAEvent(LUA_EVENT_PLAYER_STALL_STATUS_CHANGE, ActorIDTable)
    else
        SLBridge:onLUAEvent(LUA_EVENT_NET_PLAYER_STALL_STATUS_CHANGE, ActorIDTable)
    end
end

function gameMapController:handle_MSG_SC_NET_MONSTER_BORN(msg)
    local msgHdr = msg:GetHeader3_Str()
    local actor = global.actorManager:GetActor(msgHdr.Id)
    if not actor then
        print("[出生 20] 没有发现ACTOR", msgHdr.Id)
        return nil
    end
    if not actor:IsMonster() then
        return nil
    end

    global.netMonsterController:handle_MSG_SC_NET_MONSTER_BORN(actor, msgHdr)
end

function gameMapController:handle_MSG_SC_NET_MONSTER_CAVE(msg)
    local msgHdr = msg:GetHeader3_Str()
    local actor = global.actorManager:GetActor(msgHdr.Id )
    if not actor then
        print("[钻回 21] 没有发现ACTOR", msgHdr.Id)
        return nil
    end
    if not actor:IsMonster() then
        return nil
    end

    global.netMonsterController:handle_MSG_SC_NET_MONSTER_CAVE(actor, msgHdr)
end

function gameMapController:handle_MSG_SC_ACTOR_TITLE_UPDATE(msg)
    local msgHdr = msg:GetHeader3_Str()
    local actorID = msgHdr.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local t1 = msgHdr.Flag
    G_ActorUtils.SetActorAttrByID(actorID, global.MMO.ACTOR_ATTR_HUDTITLE, t1)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDTitle, actorID)
end

function gameMapController:handle_MSG_SC_ACTOR_ICONS_UPDATE(msg)
    local actorID = msg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end
    local buffer = msg:GetBodyLuaBuffer()
    local posFlag = msg:GetP1()
    local posTabel = {}
    for i = 0, 10 do
        if bit.band(posFlag, bit.lshift(1, i)) ~= 0 then 
            table.insert(posTabel, i)
        end 
    end
    local icons = {}
    for i = 1, #posTabel do
        local pos = posTabel[i]
        icons[pos] = {}
        icons[pos].Id = buffer:ReadByte()
        icons[pos].effType = buffer:ReadByte()--0图片1特效
        icons[pos].X = buffer:ReadShort()
        icons[pos].iY = buffer:ReadShort()
        icons[pos].effSrc = SL:GBKToUTF8(buffer:ReadShortString(50))--文件名//特效ID
        icons[pos].height = buffer:ReadByte()--自动补全空白位置0,1(0=掉 1=不掉) 无效  大于1 当长度 自动排序忽视Y
        icons[pos].iSelfSee = buffer:ReadByte()--是否只有自己看见（0=所有人都可以看见 1=仅仅自己可以看见）
        icons[pos].after = buffer:ReadByte()--增加播放在怪物前面和后面参数
    end
    G_ActorUtils.SetActorAttrByID(actorID, global.MMO.ACTOR_ATTR_HUDICONS, icons)
    global.Facade:sendNotification(global.NoticeTable.DelayRefreshHUDTitle, actorID)
end

-- 挖矿
function gameMapController:handle_MSG_SM_ACTOR_AUTO_MINING(msg)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return
    end
    local msgHdr        = msg:GetHeader3_Str()
    local x             = msgHdr.X
    local y             = msgHdr.Y
    local dir           = G_ActorUtils.CalcMapDirection(x, y, mainPlayer:GetMapX(), mainPlayer:GetMapY())
    local obstacleDir   = global.PathFindController:CheckDestNearObstacleDir(x, y, dir)
    if not obstacleDir then
        return
    end

    local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
    autoProxy:SetAutoMining(obstacleDir or dir, x, y)

    local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local mapID = mapProxy:GetMapID()
    InputMoveT.mapID   = mapID 
    InputMoveT.x       = x 
    InputMoveT.y       = y 
    global.Facade:sendNotification(global.NoticeTable.InputMove, InputMoveT)
end

-- 阵营变化
function gameMapController:handle_MSG_SC_ACTOR_CAMP_CHANGE(msg)
    local actorID = msg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    if not actor.SetFaction then
        return nil
    end

    local lastFaction = actor:GetFaction()
    local faction = msg:GetP1()
    actor:SetFaction(faction)

    CheckActorCampValue(actor, faction, lastFaction)
end

-- 队伍变化
function gameMapController:handle_MSG_SC_ACTOR_TEAM_CHANGE(msg)
    local actorID = msg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return nil
    end

    if not actor.SetTeamState then
        return nil
    end

    local teamID = msg:GetP1()
    actor:SetTeamState(teamID)
end

--- 开门 关门
function gameMapController:handle_MSG_SC_OPEN_DOOR_NOTICE(msg)
    local header = msg:GetHeader()
    global.sceneManager:openDoor(header.param1, header.param2)
end

function gameMapController:handle_MSG_SC_CLOSE_DOOR_NOTICE(msg)
    local header = msg:GetHeader()
    global.sceneManager:closeDoor(header.param1, header.param2)
end

local addEffectT = {}
-- 场景特效
function gameMapController:handle_MSG_SC_MAP_ADD_SPECIAL_EFFECT(netPkg)
    local buffer = netPkg:GetBodyLuaBuffer()
    local length = netPkg:GetBodyLen()

    local offset = 1
    while offset <= length do
        addEffectT.id          = buffer:ReadInt64Str()
        addEffectT.x           = buffer:ReadShort()
        addEffectT.y           = buffer:ReadShort()
        addEffectT.type        = buffer:ReadShort()
        addEffectT.param       = buffer:ReadShort()
        addEffectT.sfxId       = buffer:ReadInt()
        addEffectT.TopType     = buffer:ReadByte()
        local duranceID        = buffer:ReadInt64Str()
        addEffectT.DuranceID   = duranceID == "-1" and global.gamePlayerController:GetMainPlayerID() or duranceID
        addEffectT.ownerID     = buffer:ReadInt64Str()  -- 地图事件所有者ID
        self:AddSpecialEffect(addEffectT)
        offset = offset + 37
    end
end

function gameMapController:handle_MSG_SC_MAP_RMV_SPECIAL_EFFECT(netPkg)
    local length        = netPkg:GetBodyLen()
    if length < 1 then 
        return 
    end

    local count         = length / 8
    local buffer        = netPkg:GetBodyLuaBuffer()
    local arrInt        = G_BufferReadArrInt64Str(buffer, count, 0)    
    for i = 0, count - 1 do
        local actorID = arrInt[i]
        local sfxActor = global.actorManager:GetActor(actorID)
        if sfxActor then
            -- notice
            global.Facade:sendNotification(global.NoticeTable.ActorEffectOutOfView, actorID)
        end

        global.sceneEffectManager:RmvSceneEffect(actorID)
        global.actorManager:RemoveActor(actorID)
    end
end

local effectInOfViewT = {}
local paramSfxT = {}
function gameMapController:AddSpecialEffect(item)
    local isInit = true       
    local actorID = item.id
    local needLight = false
    paramSfxT.type = nil
    paramSfxT.sfxId = nil
    paramSfxT.isLoop = nil
    paramSfxT.DuranceID = nil
    paramSfxT.param = nil
    paramSfxT.isOwn = nil

    -- find it
    local sfxActor = global.actorManager:GetActor(actorID) 
    if nil ~= sfxActor then
        sfxActor:GetNode():setVisible(true)
        isInit = false
        -----lightID 
        if not sfxActor:GetLightID() then
            needLight = true
        end
    else
        -- New special effect actor
        paramSfxT.type       = global.MMO.EFFECT_TYPE_NORMAL
        local limitCount    = 200
        local actorCount    = global.actorManager:GetActorNum()

        local isBehind      = false
        local isFront       = false
        local effectRace    = item.type
        if fireSet[effectRace] then
            paramSfxT.sfxId  = fireSet[effectRace]
            paramSfxT.isLoop = true
            isBehind        = (actorCount>limitCount)
            paramSfxT.type   = global.MMO.EFFECT_TYPE_FIRE
            paramSfxT.isOwn  = (item.ownerID == SL:GetValue("USER_ID") or item.ownerID == SL:GetValue("HERO_ID"))  -- 是自己的 / 是自己英雄的
            -----lightID 
            needLight = true

            local sfxId     = item.sfxId and tonumber(item.sfxId)
            if sfxId and sfxId > 0 then
                paramSfxT.sfxId = sfxId
            end

        elseif effectRace == 1 then -- 僵尸2 出生洞
            paramSfxT.sfxId  = global.MMO.SFX_MONSTER_BORN1
            paramSfxT.isLoop = false
            isBehind = true

        elseif effectRace == global.MMO.EFFECT_TYPE_MINING_HIT then
            -- 土(静态特效)(ps: 以前是挖矿 sfxid:999)
            paramSfxT.type   = global.MMO.EFFECT_TYPE_MINING_HIT
            paramSfxT.sfxId  = 2208
            paramSfxT.isLoop = true
            paramSfxT.param  = item.param
            isBehind = true

        elseif effectRace == 27 or effectRace == 50 then
            -- 传送门
            paramSfxT.sfxId  = global.MMO.SFX_PORTAL
            paramSfxT.isLoop = true
            isBehind        = true
            paramSfxT.type   = global.MMO.EFFECT_TYPE_PORTAL
            needLight = true

        elseif effectRace == global.MMO.EFFECT_TYPE_SFX then
            -- 通用特效
            paramSfxT.type   = global.MMO.EFFECT_TYPE_SFX
            paramSfxT.sfxId  = item.sfxId
            paramSfxT.isLoop = true
            isBehind        = item.TopType == 0
            isFront         = item.TopType == 1

        elseif effectRace == global.MMO.EFFECT_TYPE_EMPTY then
            -- 禁锢  设置动态阻挡
            paramSfxT.type       = global.MMO.EFFECT_TYPE_EMPTY
            paramSfxT.sfxId      = item.sfxId
            paramSfxT.isLoop     = true
            paramSfxT.DuranceID  = item.DuranceID
            isBehind            = false

        else
            return -1
        end

        sfxActor = global.actorManager:CreateActor(actorID, global.MMO.ACTOR_SEFFECT, paramSfxT, isBehind, isFront)
        
        if nil == sfxActor then
            return -1
        end
    end

    -- To map grid position.
    local mapX = item.x
    local mapY = item.y
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    sfxActor:setPosition(wX, wY)
    global.actorManager:SetActorMapXY(sfxActor, mapX, mapY)

    -- feature
    global.Facade:sendNotification(global.NoticeTable.DelayDirtyFeature, actorID)

    if isInit then
        -- Track effect.
        global.sceneEffectManager:AddSceneEffect(sfxActor)
    end
    effectInOfViewT.actorID = actorID
    effectInOfViewT.needLight = needLight
    global.Facade:sendNotification(global.NoticeTable.ActorEffectInOfView, effectInOfViewT)
end

-- 场景添加特效
function gameMapController:AddEffectToMap(animID, mapX, mapY)
    if not animID or not mapX or not mapY then
        return
    end

    -- 播放特效
    local sfxAnim = global.FrameAnimManager:CreateSFXAnim(animID)
    if not sfxAnim then
        return
    end

    local root = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL_BEHIND)
    local sfxParent = root:getChildByName("MAP_SFX_PARENT")
    if not sfxParent then
        sfxParent = cc.Node:create()
        sfxParent:setName("MAP_SFX_PARENT")
        root:addChild(sfxParent, 999)
    end

    sfxParent:addChild(sfxAnim, animID)
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY)
    sfxAnim:setPosition(wX, wY)
    sfxAnim:Play(0, 0)
    local function removeEvent()
        sfxAnim:removeFromParent()
    end
    sfxAnim:SetAnimEventCallback(removeEvent)
end

local dropItemT = {}
local dropItemT2 = {}
-- 掉落物
function gameMapController:AddDropItem(item)
    local id = item.Id
    local Idx = item.Idx

    -- refresh drop item ownerID
    local dropItem = global.actorManager:GetActor(id)
    if dropItem and dropItem:IsDropItem() then  -- 服务端掉落物ID跟其他人/怪ID可能重复, 需要自行判断
        dropItem.mOwnerID = item.Of
        global.Facade:sendNotification(global.NoticeTable.RefreshDropItem, id)
        return
    end

    local dropItem = global.dropItemController:AddDropItemToWorld(item)
    global.dropItemManager:AddDropItem(dropItem)

    -- type index
    dropItem:SetTypeIndex(Idx)

    -- 极品
    dropItem:SetQualityState(item.jipin == 1)

    -- pick cd, item under player feet
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if mainPlayer then
        if mainPlayer:GetMapX() == dropItem:GetMapX() and mainPlayer:GetMapY() == dropItem:GetMapY() then
            dropItem:SetBornStamp(GetServerTime())
        end
    end

    dropItemT.actorID = id
    dropItemT.color = item.Color or 255
    dropItemT.jipin = item.jipin
    dropItemT.count = item.cnt
    dropItemT.itemName = item.Name
    global.Facade:sendNotification(global.NoticeTable.DropItemInOfView, dropItemT)
    global.Facade:sendNotification(global.NoticeTable.DelayDirtyFeature, id)

    dropItemT2.actorID = id
    dropItemT2.item = item
    SLBridge:onLUAEvent(LUA_EVENT_DROPITEM_IN_OF_VIEW, dropItemT2)
end

local rmvDropItemT = {}
function gameMapController:RmvDropItem(id)
    local dropItem = global.actorManager:GetActor(id)
    if nil == dropItem then
        return
    end

    local itemMakeIndex = dropItem.GetMakeIndex and dropItem:GetMakeIndex()
    global.Facade:sendNotification(global.NoticeTable.DropItemOutOfView, id)

    global.dropItemController:RmvDropItemFromWorld(id)

    rmvDropItemT.actorID = id
    rmvDropItemT.itemMakeIndex = itemMakeIndex
    SLBridge:onLUAEvent(LUA_EVENT_DROPITEM_OUT_OF_VIEW, rmvDropItemT)
end

local batchItemT = {}
function gameMapController:handle_MSG_SC_MAP_ITEM_DROP_BATCH(netPkg)
    local buffer = netPkg:GetBodyLuaBuffer()
    local length = netPkg:GetBodyLen()

    local offset = 1
    while offset <= length do
        batchItemT.Id                  = buffer:ReadInt64Str()           
        batchItemT.Idx                 = buffer:ReadInt()
        batchItemT.X                   = buffer:ReadShort()
        batchItemT.Y                   = buffer:ReadShort()
        batchItemT.Name                = SL:GBKToUTF8(buffer:ReadShortString(50))
        batchItemT.Color               = buffer:ReadInt()
        batchItemT.Looks               = buffer:ReadInt()
        batchItemT.Of                  = buffer:ReadInt64Str()
        batchItemT.cnt                 = buffer:ReadInt()
        batchItemT.jipin               = buffer:ReadByte()
        batchItemT.MakeIndex           = buffer:ReadGuid()
        batchItemT.ShowItemDropEff     = buffer:ReadByte()
        -- dump(item,"item___")
        self:AddDropItem(batchItemT)
        offset = offset + 105
    end
end

function gameMapController:handle_MSG_SC_MAP_ITEM_REMOVE_BATCH(netPkg)
    local buffer = netPkg:GetBodyLuaBuffer()
    local length = netPkg:GetBodyLen()

    local offset = 1
    while offset <= length do
        local id = buffer:ReadInt64Str()      
        self:RmvDropItem(id)
        offset = offset + 8
    end
end

function gameMapController:handle_MSG_SC_MAP_ITEM_REMOVE_BY_XY(netPkg)
    local x = netPkg:GetP0()
    local y = netPkg:GetP1()
    releasePrint("Warning Drop Item!! Remove by XY : ", x, y)

    local itemMapXY = global.dropItemManager:FindAllDropItemByXY(x, y)
    if not itemMapXY then
        return
    end
    
    local removeIds = {}
    for _, item in pairs(itemMapXY) do
        removeIds[#removeIds + 1] = item:GetID()
    end
    for _, id in ipairs(removeIds) do
        self:RmvDropItem(id)
    end
end

--移动特效、足迹
function gameMapController:handle_MSG_SC_ACTOR_MOVE_EFF(msg)
    local msgHdr    = msg:GetHeader()
    local effID     = msgHdr.recog
    local skipWalk  = msgHdr.param1
    local userid    = msg:GetP2Str()

    local actor = global.actorManager:GetActor(userid)
    if not actor then
        return
    end

    if actor:IsPlayer() then
        actor:SetMoveEff(effID)
        actor:SetEffSkipWalkSwitch(skipWalk) 
    end
end

-- 强制移动
local moveForceT = {}
function gameMapController:handle_MSG_SC_NET_PLAYER_MOVE_FORCE(msg)
    local msgHdr = msg:GetHeader3_Str()
    local actorID = msgHdr.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then 
        return
    end

    moveForceT.mapX = msgHdr.X
    moveForceT.mapY = msgHdr.Y
    moveForceT.dir  = msgHdr.Dir

    if actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_Move_Force(actor, moveForceT)
        else
            global.netPlayerController:handle_Move_Force(actor, moveForceT)
        end
    else
        global.netMonsterController:handle_Move_Force(actor, moveForceT)
    end

    ActorMoveForceT.actorID = actorID
    global.Facade:sendNotification(global.NoticeTable.ActorMoveForce, ActorMoveForceT)
end
----------------------------------------------------------------------------

function gameMapController:handle_MSG_SC_OPENHEALTH(msg)
    local actorID = msg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor or 0 == actor then
        return 
    end
    actor:setVisibleServerHpLabel(true)

    optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_HMPLabel_VISIBLE)
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
end

function gameMapController:handle_MSG_SC_CLOSEHEALTH(msg)
    local actorID = msg:GetP0Str()
    local actor = global.actorManager:GetActor(actorID)
    if nil == actor or 0 == actor then
        return 
    end
    actor:setVisibleServerHpLabel(false)
    
    optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_HMPLabel_VISIBLE)
    optionsUtils:RefreshHUDHMpLabelVisible(actor)
end

-- 技能
function gameMapController:handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS(netPkg)
    local header = netPkg:GetHeader3_Str()

    -- 消息头数据 
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    -- ignore main player
    if actor:IsPlayer() and actor:IsMainPlayer() then
        return false
    end

    local skillLaunchSuccess = {}
    skillLaunchSuccess.UserID   = actorID
    skillLaunchSuccess.X        = header.X
    skillLaunchSuccess.Y        = header.Y
    skillLaunchSuccess.Dir      = header.Dir
    skillLaunchSuccess.IsHaveLaunchAct = header.Type     -- 施法是否有动作
    skillLaunchSuccess.MagicID  = header.Flag

    local buffer          = netPkg:GetBodyLuaBuffer()
    skillLaunchSuccess.btEffect     = buffer:ReadByte()
    skillLaunchSuccess.ScriptEffect = buffer:ReadInt()
    skillLaunchSuccess.ActionId     = buffer:ReadInt()

    if actor:IsMonster() then
        skillLaunchSuccess.monActionID = skillLaunchSuccess.ActionId
        skillLaunchSuccess.ActionId = nil
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS(actor, skillLaunchSuccess)
    elseif actor:IsPlayer() then
        global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS(actor, skillLaunchSuccess)
    end
end



function gameMapController:handle_MSG_SC_NET_PLAYER_ATTACK(netPkg)
    local header = netPkg:GetHeader3_Str()

    -- 消息头数据 
    local actorID = header.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    -- ignore main player
    if actor:IsPlayer() and actor:IsMainPlayer() then
        return false
    end

    local netPlayerAttackt = {}
    netPlayerAttackt.UserID   = actorID
    netPlayerAttackt.X        = header.X
    netPlayerAttackt.Y        = header.Y
    netPlayerAttackt.Dir      = header.Dir
    netPlayerAttackt.IsHaveLaunchAct = header.Type      -- 施法是否有动作
    netPlayerAttackt.MagicID  = header.Flag
    local buffer                   = netPkg:GetBodyLuaBuffer()
    netPlayerAttackt.TargetUserID     = buffer:ReadInt64Str()
    netPlayerAttackt.ScriptEffect = buffer:ReadInt()
    if actor:IsMonster() then
        netPlayerAttackt.monActionID = header.Flag
        netPlayerAttackt.MagicID = header.X2
        global.netMonsterController:handle_MSG_SC_NET_PLAYER_ATTACK(actor, netPlayerAttackt)
    elseif actor:IsPlayer() then
        global.netPlayerController:handle_MSG_SC_NET_PLAYER_ATTACK(actor, netPlayerAttackt)
    end
end

function gameMapController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(netPkg)
    local head = netPkg:GetHeader3_Str()

    local actorID = head.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    local magicSuccessT = {}
    magicSuccessT.UserID   = actorID
    magicSuccessT.X        = head.X
    magicSuccessT.Y        = head.Y
    magicSuccessT.Dir      = head.Dir
    magicSuccessT.ActionId = head.Type
    magicSuccessT.MagicID  = head.Flag


    local buffer                 = netPkg:GetBodyLuaBuffer()
    magicSuccessT.btEffect       = buffer:ReadByte()
    magicSuccessT.btEffectType   = buffer:ReadByte()
    magicSuccessT.ScriptEffect   = buffer:ReadInt()
    magicSuccessT.Hit            = buffer:ReadByte()
    magicSuccessT.IsHaveDir      = buffer:ReadBool()
    magicSuccessT.TargetUserID   = buffer:ReadInt64Str()
    magicSuccessT.ShowSkillMagic = buffer:ReadByte() == 1

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
        else
            global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
        end
    end
end

-- 技能释放成功, 播放技能特效 - 新 JSON格式, 为处理他人多目标技能特效表现
function gameMapController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS_JSON(netPkg)
    local head = netPkg:GetHeader3_Str()
    local jsonData = netPkg:GetJsonData()
    if not jsonData or not next(jsonData) then
       return 
    end

    local actorID = head.Id
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return false
    end

    local magicSuccessT = jsonData
    magicSuccessT.UserID   = actorID
    magicSuccessT.X        = head.X
    magicSuccessT.Y        = head.Y
    magicSuccessT.Dir      = head.Dir
    magicSuccessT.ActionId = head.Type
    magicSuccessT.MagicID  = head.Flag

    
    -- json其余字段同638消息字段对应 [btEffect/btEffectType/IsHaveDir 无用字段, 服务端暂不发]
    -- jsonData.TargetUserID 字符串 多目标ID, 用#隔开 "actorId#actorId#actorId"
    -- jsonData.Targets json数组 多目标ID及位置, 每个元素为 [{"ID":1852,"X":319,"Y":349}, ...] (用于目标不在视野内取不到位置的情况)

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
        else
            global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, magicSuccessT)
        end
    end
end

function gameMapController:handle_MSG_SC_MAINPLAYER_MAGIC(netPkg)
    local x      = netPkg:GetP1()
    local y      = netPkg:GetP2()
    local sfxID  = netPkg:GetP3()

    local offset = global.MMO.PLAYER_AVATAR_OFFSET
    local wX, wY = global.sceneManager:MapPos2WorldPos(x, y, true)
    local root   = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL)
    local sfx    = global.FrameAnimManager:CreateSkillEffAnim(sfxID, 0)
    root:addChild(sfx)
    sfx:setLocalZOrder(sfxID)
    sfx:Play(0, 0, true)
    sfx:setPosition(wX + offset.x, wY + offset.y)
    sfx:SetAnimEventCallback(function(_, eventType)
        sfx:removeFromParent()
        sfx = nil
    end)
end


----------------------------------刷新骑马  BEGIN----------------------------------
local horseActors = {}
local horseBuffData = {}
function gameMapController:RefreshHorse(actorID, buffer)
    local actor = global.actorManager:GetActor(actorID)
    if not actor or not actor:IsPlayer() then
        return
    end
    local doubleUserId = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_DOUBLEUSERID)
    if doubleUserId == "0" or doubleUserId == "" then 
        doubleUserId = nil 
    end
    local isMainHorse = actor:GetAppearByID(global.MMO.P_F_MONSTER) > 0
    horseActors[1] = isMainHorse and actorID or doubleUserId
    horseActors[2] = not isMainHorse and actorID or doubleUserId 
    local mountID = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRAPPEAR, global.MMO.P_F_MONSTER)
    local mountEff = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRAPPEAR, global.MMO.P_F_MONSTER_EFF)
    local mountCloth = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_ARRAPPEAR, global.MMO.P_F_MONSTER_CLOTH)
    local doubleTag = G_ActorUtils.GetBufferPropertyByID(buffer, global.MMO.ACTOR_BUFFER_DOUBLETAG)
    for i,v in ipairs(horseActors) do
        local actor = v and global.actorManager:GetActor(v) or nil
        if actor then
            actor:SetKeyValue(global.MMO.HORSE_MAIN, horseActors[1])
            actor:SetKeyValue(global.MMO.HORSE_COPILOT, horseActors[2])
            actor:SetDoubleHorse(doubleTag)

            horseBuffData.actorID = actor:GetID()
            horseBuffData.buffID  = global.MMO.BUFF_ID_HORSE
            horseBuffData.param = {
                feature = {
                    mountID     = mountID,
                    mountEff    = mountEff,
                    mountCloth  = mountCloth,
                    hairID      = actor:GetAnimationHairID()
                }
            }
            global.Facade:sendNotification(global.NoticeTable.AddBuffEntity, horseBuffData)
        end
    end
end
----------------------------------刷新骑马  END----------------------------------
-- --- gm数据更新 
local gmUpdateT = {}
function gameMapController:MSG_SC_ACTOR_GMDATA_UPDATE(msg)
    local msgLen = msg:GetDataLength()
    if msgLen <= 0 then
        return
    end
    local msgData = msg:GetBodyStr()
    local slices  = G_GetSplitArray(msgData, "|")
    local actorID = slices[1]
    local actor = global.actorManager:GetActor(actorID)
    if not actor or not (actor:IsPlayer() or actor:IsMonster()) then
        return
    end

    for i = 2, 6 do
        actor:SetGMData(tonumber(slices[i]), i - 1)
    end

    gmUpdateT.id = actorID
    gmUpdateT.data = actor:GetGMData()
    -- SL 广播
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_GMDATA_UPDATE, gmUpdateT)
end

--- BUFF
function gameMapController:handle_MSG_SC_ACTOR_BUFF_INIT(netPkg)
    global.BuffManager:handleBuffInit(netPkg)
end

function gameMapController:handle_MSG_SC_ACTOR_BUFF_ADD(netPkg)
    global.BuffManager:handleBuffAdd(netPkg)
end

function gameMapController:handle_MSG_SC_ACTOR_BUFF_RMV(netPkg)
    global.BuffManager:handleBuffRmv(netPkg)
end

function gameMapController:handle_MSG_SC_ACTOR_EFFECT_UPDATE(netPkg)
    global.ActorEffectManager:handle_ActorEffectUpdate(netPkg)
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
function gameMapController:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_CREATE_MAIN_PLAYER,         handler(self, self.handle_MSG_SC_CREATE_MAIN_PLAYER))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_IN_OF_VIEW,       handler(self, self.handle_MSG_SC_NET_ACTOR_IN_OF_VIEW))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_OUT_OF_VIEW,      handler(self, self.handle_MSG_SC_NET_ACTOR_OUT_OF_VIEW))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_FLY_IN,          handler(self, self.handle_MSG_SC_NET_PLAYER_FLY_IN))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_FLY_IN_2,        handler(self, self.handle_MSG_SC_NET_PLAYER_FLY_IN_2))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_BUFF_INIT,            handler(self, self.handle_MSG_SC_ACTOR_BUFF_INIT))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_BUFF_ADD,             handler(self, self.handle_MSG_SC_ACTOR_BUFF_ADD))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_BUFF_RMV,             handler(self, self.handle_MSG_SC_ACTOR_BUFF_RMV))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_EFFECT_UPDATE,        handler(self, self.handle_MSG_SC_ACTOR_EFFECT_UPDATE))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_PLAYER_FEATURE_CHANGED,     handler(self, self.handle_MSG_SC_PLAYER_FEATURE_CHANGED))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_PET_FEATURE_CHANGED,        handler(self, self.handle_MSG_SC_PET_FEATURE_CHANGED))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_MOVE,             handler(self, self.handle_MSG_SC_NET_ACTOR_MOVE)) 
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_RUN,              handler(self, self.handle_MSG_SC_NET_ACTOR_RUN)) 
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_RIDE_RUN,        handler(self, self.handle_MSG_SC_NET_PLAYER_RIDE_RUN)) 
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_TURN,             handler(self, self.handle_MSG_SC_NET_ACTOR_TURN)) 
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_WALKEX,                     handler(self, self.handle_MSG_SC_WALKEX))
    
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_UPDATE_ATTR,          handler(self, self.handle_MSG_SC_ACTOR_UPDATE_ATTR)) -- 更新属性
    --飘血
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_DAMAGE_HP,            handler(self, self.handle_MSG_SC_ACTOR_DAMAGE_HP)) 
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_MONSTER_BORN,           handler(self, self.handle_MSG_SC_NET_MONSTER_BORN))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_MONSTER_CAVE,           handler(self, self.handle_MSG_SC_NET_MONSTER_CAVE))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_NAME,                 handler(self, self.handle_MSG_SC_ACTOR_NAME))            -- 角色头顶数据(名子、称号等)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SELL_NOTICE,                handler(self, self.handle_MSG_SC_SELL_NOTICE))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTION_PICK_CORPSE,         handler(self, self.handle_MSG_SC_ACTION_PICK_CORPSE))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_DEATH_FALL_DOWN,  handler(self, self.handle_MSG_SC_NET_ACTOR_DEATH_FALL_DOWN))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_DEATH_SKELETON,   handler(self, self.handle_MSG_SC_NET_ACTOR_DEATH_SKELETON))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_ACTOR_REVIVE,           handler(self, self.handle_MSG_SC_NET_ACTOR_REVIVE))

    
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_FLY_OUT,         handler(self, self.handle_MSG_SC_NET_PLAYER_FLY_OUT))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_FLY_OUT_2,       handler(self, self.handle_MSG_SC_NET_PLAYER_FLY_OUT_2))


    
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_ICONS_UPDATE,         handler(self, self.handle_MSG_SC_ACTOR_ICONS_UPDATE))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_TITLE_UPDATE,         handler(self, self.handle_MSG_SC_ACTOR_TITLE_UPDATE))

    LuaRegisterMsgHandler(global.MsgType.MSG_SM_ACTOR_AUTO_MINING,          handler(self, self.handle_MSG_SM_ACTOR_AUTO_MINING))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_CAMP_CHANGE,          handler(self, self.handle_MSG_SC_ACTOR_CAMP_CHANGE))

    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_TEAM_CHANGE,          handler(self, self.handle_MSG_SC_ACTOR_TEAM_CHANGE))
    -----------------------------------------------------------------------------
    -- main player
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_ACTOR_CLEANUP,          handler(self, self.handle_MSG_SC_MAP_ACTOR_CLEANUP))
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- scene effect
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_ADD_SPECIAL_EFFECT,     handler(self, self.handle_MSG_SC_MAP_ADD_SPECIAL_EFFECT))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_RMV_SPECIAL_EFFECT,     handler(self, self.handle_MSG_SC_MAP_RMV_SPECIAL_EFFECT))
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- drop item
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_ITEM_DROP_BATCH,        handler(self, self.handle_MSG_SC_MAP_ITEM_DROP_BATCH))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_ITEM_REMOVE_BATCH,      handler(self, self.handle_MSG_SC_MAP_ITEM_REMOVE_BATCH))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAP_ITEM_REMOVE_BY_XY,      handler(self, self.handle_MSG_SC_MAP_ITEM_REMOVE_BY_XY))
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_OPEN_DOOR_NOTICE,           handler(self, self.handle_MSG_SC_OPEN_DOOR_NOTICE))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_CLOSE_DOOR_NOTICE,          handler(self, self.handle_MSG_SC_CLOSE_DOOR_NOTICE))
    -----------------------------------------------------------------------------
    -- LuaRegisterMsgHandler(global.MsgType.MSG_SC_OPENHEALTH,                 handler(self, self.handle_MSG_SC_OPENHEALTH))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_CLOSEHEALTH,                handler(self, self.handle_MSG_SC_CLOSEHEALTH))
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- 技能释放成功，进入释放动作
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS,handler(self, self.handle_MSG_SC_PLAYER_SKILL_LAUNCH_SUCCESS))
    -- 攻击成功，进入攻击动作+播放攻击特效
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_ATTACK,          handler(self, self.handle_MSG_SC_NET_PLAYER_ATTACK))
    -- 技能释放成功，播放释放特效
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS, handler(self, self.handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS_JSON, handler(self, self.handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS_JSON))

    -- 地图某个位置播放一个特效
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MAINPLAYER_MAGIC,           handler(self, self.handle_MSG_SC_MAINPLAYER_MAGIC))
    -----------------------------------------------------------------------------
    
    -----------------------------------------------------------------------------
    -- 移动特效、足迹
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_MOVE_EFF,             handler(self, self.handle_MSG_SC_ACTOR_MOVE_EFF))
    -----------------------------------------------------------------------------
    
    -----------------------------------------------------------------------------
    -- 强制移动
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_NET_PLAYER_MOVE_FORCE,      handler(self, self.handle_MSG_SC_NET_PLAYER_MOVE_FORCE))
    ------------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- gmdata 更新
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_ACTOR_GMDATA_UPDATE,        handler(self, self.MSG_SC_ACTOR_GMDATA_UPDATE))

    -- 通知反击 特殊
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_FIGHT_BACK_ID,               handler(self, self.handle_MSG_SC_FIGHT_BACK_ID))
    ------------------------------------------------------------------------------

end

return gameMapController
