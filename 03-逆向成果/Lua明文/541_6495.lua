local RemoteProxy = requireProxy("RemoteProxy")
local HorseProxy = class("HorseProxy", RemoteProxy)
HorseProxy.NAME = global.ProxyTable.HorseProxy

local optionsUtils = requireUtil("optionsUtils")

function HorseProxy:ctor()
    HorseProxy.super.ctor( self )
end

-- 是否能施法
function HorseProxy:IsLaunch( skillID )
    local player = global.gamePlayerController:GetMainPlayer()
    if player and player:GetHorseMasterID() then
        if SL:GetValue("GAME_DATA", "off_horse_launch") == 1 then
            return false
        end
        --魔法盾除外
        if skillID ~= 31 then
            return false
        end
    end
    return true
end

-- 请求下马
function HorseProxy:RequestHorseDown()
    if SL:GetValue("GAME_DATA", "horse_down") == 1 then
        LuaSendMsg(global.MsgType.MSG_CS_HROSEDOWN)
        return true
    end
    return false
end

-- 邀请上马
function HorseProxy:RequestHorseUpInvite(uid)
    LuaSendMsg(global.MsgType.MSG_CS_HORSE_INVITE,0,0,0,0,uid)
end

-- 同意上马邀请
function HorseProxy:RequestHorseUpInviteAgree(uid)
    LuaSendMsg( global.MsgType.MSG_CS_HORSE_AGREE,0,0,0,0,uid)
end

-- 显示气泡
function HorseProxy:ShowHorseInviteBubbleTips(isShow, uid)
    local callback = function()
        self:RequestHorseUpInviteAgree(uid)

        self:ShowHorseInviteBubbleTips(false)
    end

    if isShow then 
        SL:AddBubbleTips(GUIDefine.BubbleType.HORSE_INVITE, "res/private/main/bubble_tips/1900012607_1.png", callback)
    else 
        SL:DelBubbleTips(GUIDefine.BubbleType.HORSE_INVITE)
    end

end

--------------服务端返回的数据--------------------------------------
-- 邀请上马
function HorseProxy:handle_MSG_SC_HORSE_INVITE(netPkg)
    local actorID = netPkg:GetP0Str()
    if not actorID then
        return false
    end

    local actor = global.playerManager:FindOnePlayerInCurrViewFieldById(actorID)
    if actor then
        local str = string.format(GET_STRING(310000800), actor:GetName())
        ShowSystemTips(str)
    end
    self:ShowHorseInviteBubbleTips(true, actorID)
end

-- 上马  参数1：外观，参数2：特效，字符串：|分割，|前是马主，后面是副驾
function HorseProxy:handle_MSG_SC_HORSE_UP(netPkg)
    local length = netPkg:GetBodyLen()
    if length < 1 then
        return false
    end

    local strList      = string.split(netPkg:GetBodyStr(), "|") 
    local mainHorse    = strList[1]
    local copilotHorse = string.len(strList[2] or "") > 0 and strList[2] or nil

    local mountID    = netPkg:GetP0()
    local mountEff   = netPkg:GetP1()
    local isDouble   = netPkg:GetP2()
    local mountCloth = netPkg:GetP3()

    for _, ID in ipairs({mainHorse, copilotHorse}) do
        local actor = global.actorManager:GetActor(ID)
        if actor then
            actor:SetDoubleHorse(isDouble)
            actor:SetKeyValue(global.MMO.HORSE_MAIN, mainHorse)
            actor:SetKeyValue(global.MMO.HORSE_COPILOT, copilotHorse)
            
            local buffData = 
            {
                actorID = actor:GetID(),
                buffID  = global.MMO.BUFF_ID_HORSE,
                param   = {
                    feature = {
                        mountID     = mountID,
                        mountEff    = mountEff,
                        mountCloth  = mountCloth,
                        hairID      = actor:GetAppearByID(global.MMO.P_F_HAIR)
                    },
                }
            }

            global.Facade:sendNotification(global.NoticeTable.AddBuffEntity, buffData)
        end
    end

end

-- 下马  参数1：方向，参数2：坐标X，参数3：坐标Y,参数0，玩家id
function HorseProxy:handle_MSG_SC_HORSE_DOWN(netPkg)
    local actorID = netPkg:GetP0Str()
    if not actorID then
        return false
    end

    local actor = global.playerManager:FindOnePlayerInCurrViewFieldById(actorID)
    if not actor then
        return false
    end

    local Dir = netPkg:GetP1()
    local X   = netPkg:GetP2()
    local Y   = netPkg:GetP3()

    local mainHorse    = actor:GetHorseMasterID()
    local copilotHorse = actor:GetHorseCopilotID()
    local isMainHorse  = actorID == mainHorse

    for _, ID in ipairs({mainHorse, copilotHorse}) do
        local actor = ID and global.playerManager:FindOnePlayerInCurrViewFieldById(ID)
        if actor then
            local isExit = ID == actorID

            actor:SetKeyValue(global.MMO.HORSE_COPILOT, nil)

            if isMainHorse or isExit then
                actor:SetDoubleHorse()
                actor:SetKeyValue(global.MMO.HORSE_MAIN, nil)
            end

            if isExit then
                local wX, wY = global.sceneManager:MapPos2WorldPos(X, Y, true)
                if not actor:IsDie() and not actor:IsDeath() then
                    actor:SetAction(global.MMO.ACTION_IDLE, true)
                    global.actorManager:SetActorMapXY(actor, X, Y)
                    actor:SetDirection(Dir)
                    actor:setPosition(wX, wY)
                end
            end

            local buffData = 
            {
                actorID     = actor:GetID(),
                buffID      = global.MMO.BUFF_ID_HORSE,
                param       = {
                    isExit  = isExit,
                    feature = {
                        mountID     = actor:GetAppearByID(global.MMO.P_F_MONSTER),
                        mountEff    = actor:GetAppearByID(global.MMO.P_F_MONSTER_EFF),
                        mountCloth  = actor:GetAppearByID(global.MMO.P_F_MONSTER_CLOTH),
                        hairID      = actor:GetAppearByID(global.MMO.P_F_HAIR),
                        isDown      = copilotHorse and true or false
                    }
                }
            }

            global.Facade:sendNotification(global.NoticeTable.AddBuffEntity, buffData)
        end
    end
end

function HorseProxy:RegisterMsgHandler()
    HorseProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType
    
    LuaRegisterMsgHandler(msgType.MSG_SC_HORSE_UP, handler(self, self.handle_MSG_SC_HORSE_UP))
    LuaRegisterMsgHandler(msgType.MSG_SC_HORSE_DOWN, handler(self, self.handle_MSG_SC_HORSE_DOWN))
    LuaRegisterMsgHandler(msgType.MSG_SC_HORSE_INVITE, handler(self, self.handle_MSG_SC_HORSE_INVITE))
end

return HorseProxy