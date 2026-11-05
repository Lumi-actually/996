local actorSkillController = class("actorSkillController")
actorSkillController.NAME = "actorSkillController"

function actorSkillController:ctor()
    self._jointCache = {}
    self._klaunchQueue = {}

    self:RegisterMsgHandler()
end

function actorSkillController:destory()
end

function actorSkillController:create()
    local _this = actorSkillController.new()
    return _this
end

function actorSkillController:Cleanup()
end

function actorSkillController:GetHitMissUserID()
    return self._hitMissUserID
end

function actorSkillController:ResetHitMissUserID()
    self._hitMissUserID = nil
end

local launchJointSkillT = {}
function actorSkillController:LaunchJointSkill(jsonData)
    local actorID   = jsonData.userid
    local targetID  = jsonData.target or ""
    local srcX      = jsonData.x or 0
    local srcY      = jsonData.y or 0
    local hitX      = jsonData.tx or 0
    local hitY      = jsonData.ty or 0
    local dir       = jsonData.dir or 0
    local skillID   = jsonData.magicid

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    if not actor:IsPlayer() then
        return -1
    end
    
    -- 防止后退
    if actor:IsMainPlayer() then
        actor:SetDirection(dir)
        global.Facade:sendNotification(global.NoticeTable.InputIdle)
        -- 震动
        if CHECK_SETTING(global.MMO.SETTING_IDX_HERO_JOINT_SHAKE) == 1 then
            global.Facade:sendNotification(global.NoticeTable.ShakeScene)
        end
    else
        -- some property
        local wX, wY = global.sceneManager:MapPos2WorldPos(srcX, srcY, true)
        actor:SetDirection(dir)
        actor:setPosition(wX, wY)
        global.actorManager:SetActorMapXY(actor, srcX, srcY)
    end

    actor:StopAllAnimation()

    -- action
    local actorJob = actor:GetJobID()

    launchJointSkillT.skillID = skillID
    launchJointSkillT.actor = actor
    launchJointSkillT.dir = dir
    
    if GUIFunction:IsFighter(actorJob) then
        global.Facade:sendNotification(global.NoticeTable.ActorEnterAttackAction, launchJointSkillT)
    else
        global.Facade:sendNotification(global.NoticeTable.ActorEnterSkillAction, launchJointSkillT)
    end
    actor:SetConfirmed(true)

    local present       = 
    {
        skillID     = skillID,
        launchX     = actor:GetMapX(),
        launchY     = actor:GetMapY(),
        hitX        = hitX,
        hitY        = hitY,
        dir         = dir,
        param       = targetID,
        --launchOnly  = (not actor:IsHero()),
        skillStage  = (not actor:IsHero() and 1 or nil),
        needFly     = true,
        
        launcherID  = actorID,
    }
    global.Facade:sendNotification(global.NoticeTable.RequestSkillPresent, present)
end
function actorSkillController:CheckKLaunchAble()
    return #self._klaunchQueue > 0
end

local RequestLaunchServerSkillT = {}
function actorSkillController:RequestLaunchServerSkill()
    -- 特殊处理的服务器触发技能，真神奇
    if #self._klaunchQueue == 0 then
        return nil
    end

    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return nil
    end

    local sendData = table.remove(self._klaunchQueue, 1)
    SendTableToServer(global.MsgType.MSG_CS_SERVER_SKILL_LAUNCH, sendData)

    local skillID = sendData.MagId
    if not skillID then
        return nil
    end

    local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    local skillConfig = skillProxy:FindConfigBySkillID(skillID)
    if skillConfig then
        -- present
        local present =
        {
            skillID = skillProxy:GetSkillPresentReplaceID(skillID),
            launchX = mainPlayer:GetMapX(),
            launchY = mainPlayer:GetMapY(),
            dir     = mainPlayer:GetDirection(),
            skillStage = 1,
            launcherID = mainPlayer:GetID()
        }
        global.Facade:sendNotification(global.NoticeTable.RequestSkillPresent, present)

        -- action
        if sendData.Act == 1 then
            RequestLaunchServerSkillT.skillID = skillID
            RequestLaunchServerSkillT.actor = mainPlayer
            RequestLaunchServerSkillT.dir = mainPlayer:GetDirection()
            RequestLaunchServerSkillT.ActionId = sendData.ActionId or skillProxy:GetActionID(skillID)

            if skillConfig.action == 0 then
                -- 攻击
                global.Facade:sendNotification(global.NoticeTable.ActorEnterAttackAction, RequestLaunchServerSkillT)
                mainPlayer:SetConfirmed(true)
                
            elseif skillConfig.action == 1 then
                -- 施法
                global.Facade:sendNotification(global.NoticeTable.ActorEnterSkillAction, RequestLaunchServerSkillT)
                mainPlayer:SetConfirmed(true)
            end
        end

        -- 特殊 连击技能进CD
        if sendData.CD == 1 and skillProxy:IsComboSkill(skillID) then
            global.Facade:sendNotification(global.NoticeTable.ComboSkillEnterCD, skillID)
        end
    end
end

function actorSkillController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(msg)
    local msgHdr = msg:GetHeader11_Str()

    local actorID = msgHdr.t0
    local mapX    = msgHdr.t1
    local mapY    = msgHdr.t2

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    if actor:GetMapX() == mapX and actor:GetMapY() == mapY and not actor:IsPlayer() then
        return -1
    end

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(actor, msgHdr)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(actor, msgHdr)
        else
            global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_27_SUCCESS(actor, msgHdr)
        end
    end

    return 1
end

function actorSkillController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(msg)
    local msgHdr = msg:GetHeader11_Str()

    local actorID = msgHdr.t0
    local mapX    = msgHdr.t1
    local mapY    = msgHdr.t2

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end
    if actor:GetMapX() == mapX and actor:GetMapY() == mapY then
        return -1
    end

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(actor, msgHdr)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(actor, msgHdr)
        else
            global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP(actor, msgHdr)
        end
    end

    return 1
end

function actorSkillController:handle_MSG_SC_SKILL_HIT_MISS(msg)
    local msgLen = msg:GetDataLength()
    local dataString = msg:GetBodyStr()
    self._hitMissUserID = dataString
end

--十步一杀瞬移成功
function actorSkillController:handle_MSG_SC_PLAYER_SKILL_82_SUCCESS(msg)
    local msgHdr  = msg:GetHeader3_Str()

    local actorID = msgHdr.Id
    local mapX    = msgHdr.X
    local mapY    = msgHdr.Y

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    if not actor:IsPlayer() then
        return -1
    end

    if actor:IsMainPlayer() then
        global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_82_SUCCESS(actor, msgHdr)
    else
        global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_82_SUCCESS(actor, msgHdr)
    end

    return 1
end

-- 擒龙手瞬移
function actorSkillController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(msg)
    local msgHdr  = msg:GetHeader3_Str()

    local actorID = msgHdr.Id               -- 受击者
    local mapX    = msgHdr.X
    local mapY    = msgHdr.Y

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    if mapX == actor:GetMapX() and mapY == actor:GetMapY() then
        return -1
    end

    local buffer = msg:GetBodyLuaBuffer()
    local attackID = buffer:ReadInt64()     -- 施法者

    if actor:IsMonster() then
        global.netMonsterController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(actor,msgHdr)
    elseif actor:IsPlayer() then
        if actor:IsMainPlayer() then
            global.gamePlayerController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(actor, msgHdr)
        else
            global.netPlayerController:handle_MSG_SC_PLAYER_SKILL_71_SUCCESS(actor, msgHdr)
        end
    end

    if global.gamePlayerController:GetMainPlayerID() == attackID then
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:ClearMove()
    end
    
    return 1
end

function actorSkillController:handle_MSG_SC_JOINT_SKILL_PRESENT(msg)
    local header  = msg:GetHeader()
    local msgLen  = msg:GetDataLength()
    local actorID = ""
    local target  = ""
    if msgLen > 0 then
        local strs = msg:GetBodyStr()
        dump(strs,"strs____")
        local ss = G_GetSplitArray(strs,"#")
        actorID = ss[1]
        target = ss[2]
    end

    dump(header,"msgHdr____") 
    dump(actorID,"actorID")
    dump(target,"target___")

    local jsonData = {}
    jsonData.magicid = header.recog
    jsonData.userid  = actorID
    jsonData.x       = header.param1
    jsonData.y       = header.param2
    jsonData.dir     = header.param3
    jsonData.target  = target

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        print("joint skill launcher is Miss!!!!!!!")
        return -1
    end

    if not actor:IsPlayer() then
        return -1
    end

    if actor:IsMainPlayer() and (actor:GetAction() == global.MMO.ACTION_WALK or actor:GetAction() == global.MMO.ACTION_RUN) then
        -- 跑步/行走时强制停止移动，直接执行合击（不缓存）
        global.Facade:sendNotification(global.NoticeTable.ClearAllInputState)
        global.Facade:sendNotification(global.NoticeTable.InputIdle)
    end

    self:LaunchJointSkill(jsonData)
end

function actorSkillController:handle_MSG_SC_JOINT_SKILL_PRESENT_HIT(msg)
    local header  = msg:GetHeader()
    local msgLen  = msg:GetDataLength()
    local actorID = msgLen > 0 and msg:GetBodyStr() or ""

    dump(header,"handle_MSG_SC_JOINT_SKILL_PRESENT_HIT__")
    
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end
    local skillID = header.param1

    local root = global.sceneGraphCtl:GetSceneNode(global.MMO.NODE_SKILL)
    local skillData = global.skillManager:GetSkillConfigByID(skillID)
    local animID 
    local func = function(sender) sender:removeFromParent() end
    local anim

    repeat 
        animID = skillData and skillData.hitID
        anim = global.FrameAnimManager:CreateSkillEffAnim(animID)
        root:addChild(anim)
        anim:setPosition(actor:getPositionX() + global.MMO.PLAYER_AVATAR_OFFSET.x, actor:getPositionY() + global.MMO.PLAYER_AVATAR_OFFSET.y)
        anim:setLocalZOrder(animID)
        anim:Play(0, 0, true)
        anim:SetAnimEventCallback(func) 
        if skillData.linkSkill and skillData.linkSkill >= 1 then
            skillData = global.skillManager:GetSkillConfigByID(skillData.linkSkill)
        else
            skillData = nil
        end
    until not skillData
end

function actorSkillController:handle_MSG_SC_HERO_EFFECT(msg)
    local header  = msg:GetHeader()
    local msgLen  = msg:GetDataLength()
    local actorID = msgLen > 0 and msg:GetBodyStr() or ""

    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return -1
    end

    local animID = header.param1
    local anim = global.FrameAnimManager:CreateSFXAnim(animID)
    actor:GetNode():addChild(anim)
    anim:setLocalZOrder(animID)
    anim:Play(0, 0, true)
    anim:SetAnimEventCallback(function (sender)
        sender:removeFromParent()
    end) 
end

function actorSkillController:handle_MSG_SC_SERVER_SKILL_RESP(msg)
    local jsonData = msg:GetHeader14()
    if not jsonData then
        return nil
    end
    dump(jsonData)
    self._klaunchQueue[#self._klaunchQueue + 1] = jsonData
end

function actorSkillController:RegisterMsgHandler()
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_SKILL_27_SUCCESS,   handler(self, self.handle_MSG_SC_PLAYER_SKILL_27_SUCCESS))
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_SKILL_27_BACKSTEP,  handler(self, self.handle_MSG_SC_PLAYER_SKILL_27_BACKSTEP))
    LuaRegisterMsgHandler(msgType.MSG_SC_SKILL_HIT_MISS,            handler(self, self.handle_MSG_SC_SKILL_HIT_MISS))           -- 飞行技能命中失败
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_SKILL_82_SUCCESS,   handler(self, self.handle_MSG_SC_PLAYER_SKILL_82_SUCCESS))  -- 十步一杀瞬移成功 
    LuaRegisterMsgHandler(msgType.MSG_SC_PLAYER_SKILL_71_SUCCESS,   handler(self, self.handle_MSG_SC_PLAYER_SKILL_71_SUCCESS))  -- 擒龙手
    LuaRegisterMsgHandler(msgType.MSG_SC_JOINTATTACK_HERO,          handler(self, self.handle_MSG_SC_JOINT_SKILL_PRESENT))      -- 合击
    LuaRegisterMsgHandler(msgType.MSG_SC_EXTRA_EFFECT,              handler(self, self.handle_MSG_SC_JOINT_SKILL_PRESENT_HIT))  -- 合击击中特效
    LuaRegisterMsgHandler(msgType.MSG_SC_HERO_EFFECT,               handler(self, self.handle_MSG_SC_HERO_EFFECT))              -- 英雄专属特效
    LuaRegisterMsgHandler(msgType.MSG_SC_SERVER_SKILL_RESP,         handler(self, self.handle_MSG_SC_SERVER_SKILL_RESP))        -- 服务器触发的技能，牛逼

    local function ActCompleted(actor, act)
        if actor and (act == global.MMO.ACTION_WALK or act == global.MMO.ACTION_RUN) then
            for i = 1, #self._jointCache do
                local v = self._jointCache[i]
                if v and v.userid == actor:GetID() then
                    self:LaunchJointSkill(v)
                    table.remove(self._jointCache, i)
                    global.gamePlayerController.mInputEnable = false
                    break
                end
            end
        end
    end
    global.gamePlayerController:AddHandleOnActCompleted(ActCompleted)
end

return actorSkillController 
