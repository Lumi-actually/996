local netActorController = require("logic/netActorController")
local netMonsterController = class("netMonsterController",netActorController)
netMonsterController.NAME = "netMonsterController"
local actorIDT = {}
local actorIDActT = {}
local actorIDActorT = {}
function netMonsterController:ctor()
    netMonsterController.super.ctor(self)
    
    self:RegisterMsgHandler()
end

function netMonsterController:destory()
    netMonsterController.super.destory(self)
end

function netMonsterController:create()
    local _this = netMonsterController.new()
    return _this
end

function netMonsterController:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_MONSTER_OWNER, handler(self, self.handle_MSG_SC_MONSTER_OWNER))
end

function netMonsterController:handle_MSG_SC_MONSTER_OWNER(netPkg)
    local actorID   = netPkg:GetP0Str()
    local ownerID   = netPkg:GetP1Str()
    local ownerName = SL:GBKToUTF8(netPkg:GetBodyLuaBuffer():ReadShortString(30))

    local actor = global.actorManager:GetActor(actorID)
    if not actor or not actor:IsMonster() then
        return false
    end

    actor:SetOwnerID(ownerID)
    actor:SetOwnerName(ownerName)
    actorIDT.actorID = actorID
    SLBridge:onLUAEvent(LUA_EVENT_ACTOR_OWNER_CHANGE, actorIDT)
end

local paramT = {clothID = 0}
function netMonsterController:AddNetMonsterToWorld(actorID, clothID)
    paramT.clothID = clothID
    local netMonster = global.actorManager:CreateActor( actorID, global.MMO.ACTOR_MONSTER, paramT)
    if nil == netMonster then
        return nil
    end

    -- bind handler
    netMonster:SetGameActorActionHandler( self )

    return netMonster
end

function netMonsterController:Cleanup()
    netMonsterController.super.Cleanup(self)
end

function netMonsterController:handleActionBegin( actor, act )
    netMonsterController.super.handleActionBegin(self, actor, act)

    actorIDActT.actorID = actor:GetID()
    actorIDActT.act = act
    SL:onLUAEvent(LUA_EVENT_MONSTER_ACTION_BEGIN, actorIDActT)

    -- monster audio
    local clothID = actor:GetAnimationID()
    if act == global.MMO.ACTION_DIE then
        -- global.Facade:sendNotification( global.NoticeTable.Audio_Play, {type=global.MMO.SND_TYPE_MON_DIE, index=clothID} )
    elseif act == global.MMO.ACTION_ATTACK then
        local slt = global.SLT.AudioPlayTable3
        slt.type = global.MMO.SND_TYPE_MON_ATTACK
        slt.index = clothID
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    elseif act == global.MMO.ACTION_WALK or act == global.MMO.ACTION_RUN then
        local slt = global.SLT.AudioPlayTable3
        slt.type = global.MMO.SND_TYPE_MON_MOVE
        slt.index = clothID
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    elseif act == global.MMO.ACTION_BORN then
        local slt = global.SLT.AudioPlayTable3
        slt.type = global.MMO.SND_TYPE_MON_BORN
        slt.index = clothID
        global.Facade:sendNotification(global.NoticeTable.Audio_Play, slt)
    end
end

function netMonsterController:handleActionCompleted(actor, act)
    netMonsterController.super.handleActionCompleted(self, actor, act)

    actorIDActT.actorID = actor:GetID()
    actorIDActT.act = act
    SL:onLUAEvent(LUA_EVENT_MONSTER_ACTION_COMPLETE, actorIDActT)

    -- 大刀坐标恢复
    if actor:GetRaceServer() == global.MMO.ACTOR_SERVER_RACE_KNIEF then
        local wX, wY = global.sceneManager:MapPos2WorldPos( actor:GetMapX(), actor:GetMapY(), true )
        local dir = G_ActorUtils.GetActorAttrByID(actor:GetID(), global.MMO.ACTOR_ATTR_DIR)
        actor:setPosition(wX, wY)
        actor:SetDirection(dir)
        actor:DirtyAnimFlag()
    end

    -- 出生完成，广播
    if act == global.MMO.ACTION_BORN then
        actorIDActorT.actorID = actor:GetID()
        actorIDActorT.actor = actor
        global.Facade:sendNotification(global.NoticeTable.ActorMonsterBirth, actorIDActorT)
        actorIDT.actorID = actor:GetID()
        SLBridge:onLUAEvent(LUA_EVENT_MONSTER_BIRTH, actorIDT)
    elseif act == global.MMO.ACTION_CAVE then
        if not actor:IsSleepInCave() then
            actor:SetSleepInCave(true)
            actor:SetKeyValue(global.MMO.Is_Cave, true)
            actorIDActorT.actorID = actor:GetID()
            actorIDActorT.actor = actor
            global.Facade:sendNotification(global.NoticeTable.ActorMonsterCaved, actorIDActorT)
            actorIDT.actorID = actor:GetID()
            SLBridge:onLUAEvent(LUA_EVENT_MONSTER_CAVED, actorIDT)
        end
    end
end

function netMonsterController:handle_MSG_SC_PLAYER_SKILL_MAGIC_SUCCESS(actor, jsonData)
    -- 死亡状态无法切换
    if actor:IsDie() or actor:IsDeath() then
        return nil
    end

    if global.MMO.ACTION_IDLE == actor:GetAction() then
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        if jsonData.Hit == 1 then
            SkillProxy:actorEnterAction(jsonData, true)
            SkillProxy:requestSkillPresent(jsonData, 1)
        end
        SkillProxy:requestSkillPresent(jsonData, 2)

    elseif (global.MMO.ACTION_ATTACK == actor:GetAction() or global.MMO.ACTION_SKILL == actor:GetAction() or G_ActorUtils.CheckInSkillAction(actor:GetAction())) and actor.skillStage == 1 and actor.skillID == jsonData.MagicID then
        actor.skillStage = 2
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:requestSkillPresent(jsonData, 2)
    else
        -- Another action is running
        if self.mNextActionCache[actor:GetID()] == nil then
            self.mNextActionCache[actor:GetID()] = {}
        end

        if jsonData.ShowSkillMagic then -- 纯技能表现  不执行技能动作
            local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
            SkillProxy:requestSkillPresent(jsonData, 3)
        else
            local isAddAction = true
            for i, v in ipairs(self.mNextActionCache[actor:GetID()]) do
                if v.act == 5 and v.skillStage == 1 then
                    isAddAction = false
                    break
                end
            end

            if isAddAction then
                local netAct = {}
                netAct.act          = 5
                netAct.jsonData     = jsonData
                netAct.isMagic      = true
                netAct.skillStage   = 2
                table.insert(self.mNextActionCache[actor:GetID()], netAct)
            end
        end
    end
end

function netMonsterController:handle_Revive(actor, jsonData)
    netMonsterController.super.handle_Revive(self, actor, jsonData)

    if actor:IsGate() then
        local dir = jsonData.Dir or 0
        actor:SetGateOpenState(dir >= 3)
        actor:SetKeyValue(global.MMO.Is_Gate, true)

    elseif actor:IsWall() then
        local dir = jsonData.Dir or 0
        actor:SetKeyValue(global.MMO.Is_Wall, true)
        actor:StopAnimToFrame(dir + 1)
        actor:SetAction(global.MMO.ACTION_IDLE)
        actor:UpdateAnimation()
    end
end

function netMonsterController:handle_MSG_SC_NET_MONSTER_BORN(actor, msgHdr)
    self.mNextActionCache[actor:GetID()] = nil

    local dir = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y

    if actor:IsGate() then
        actor:SetGateOpenState(dir >= 3)
        actor:SetKeyValue(global.MMO.Is_Gate, true)

    elseif actor:IsWall() then
        actor:SetKeyValue(global.MMO.Is_Wall, true)
        actor:StopAnimToFrame(dir + 1)
        actor:SetAction(global.MMO.ACTION_IDLE)
        actor:UpdateAnimation()
    else
        global.actorManager:SetActorMapXY(actor, mapX, mapY)
        local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
        actor:setPosition(wX, wY)
        actor:SetDirection(dir)
        actor:StopAnimToFrame(nil)
        actor:SetStoneMode(false)
        actor:SetSleepInCave(false)
        actor:SetAction(global.MMO.ACTION_BORN)
        actor:SetKeyValue(global.MMO.Is_Cave, false)
        
        actorIDActorT.actorID = actor:GetID()
        actorIDActorT.actor = actor
        global.Facade:sendNotification(global.NoticeTable.ActorMonsterBorn, actorIDActorT)
    end
end

function netMonsterController:handle_MSG_SC_NET_MONSTER_CAVE(actor, msgHdr, msgData)
    self.mNextActionCache[actor:GetID()] = nil

    local dir = msgHdr.Dir
    local mapX = msgHdr.X
    local mapY = msgHdr.Y

    global.actorManager:SetActorMapXY(actor, mapX, mapY)
    local wX, wY = global.sceneManager:MapPos2WorldPos(mapX, mapY, true)
    actor:setPosition(wX, wY)
    actor:SetDirection(dir)
    
    if actor:IsGate() then
        actor:SetGateOpenState(dir >= 3)
        actor:SetAction(global.MMO.ACTION_BORN)
    elseif actor:IsFollowDog() then
        actor:SetAction(global.MMO.ACTION_CHANGESHAPE)
    else
        actor:SetAction(global.MMO.ACTION_CAVE)
        actorIDActorT.actorID = actor:GetID()
        actorIDActorT.actor = actor
        global.Facade:sendNotification(global.NoticeTable.ActorMonsterCave, actorIDActorT)
    end
end

return netMonsterController
