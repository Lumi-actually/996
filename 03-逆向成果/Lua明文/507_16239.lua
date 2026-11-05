local RemoteProxy = requireProxy("RemoteProxy")
local TeamProxy = class("TeamProxy", RemoteProxy)
TeamProxy.NAME = global.ProxyTable.TeamProxy

-- 0创建队伍 1解散队伍 2加入队伍 3离开队伍 4换队长
TeamProxy.ChangeType = {
    CREATE = 0,
    DISMISS = 1,
    JOIN_IN = 2,
    LEAVE = 3,
    UPDATE = 4,
}

function TeamProxy:ctor()
    TeamProxy.super.ctor(self)

    self._data        = {}
    self._memberMax    = 8          -- 人数上限
    self:Init()
end

function TeamProxy:Init()
    -- 自身的队伍数据
    self._data.selfItem = nil
    -- 我在队伍中职位 1队长 0队员
    self._data.myRank = 0
    -- 成员列表
    self._data.memberItems = {}
    -- 附近队伍列表
    self._data.nearTeamItems = {}
    -- 申请列表
    self._data.applyItems = {}
    -- 邀请列表
    self._data.inviteItems = {}
    -- 队伍id
    self._data.groupID = 0
    -- 队伍目标id
    self._data.targetID = nil

    self._exitTeamID = {}        -- 记录下退出队伍的id，语音请求时，升级为队长的人进行发送

    self._isTransferTeam = false -- 是否请求转移队长职位，语音需要请求者去发送消息
    self._memberMax = tonumber(SL:GetValue("GAME_DATA","team_num")) or self._memberMax
end

-- 语音-创建队伍
function TeamProxy:VoiceCreateTeam()
    local VoiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    VoiceManagerProxy:VoiceTeam({operateType = TeamProxy.ChangeType.CREATE})
end

-- 语音-加入队伍
function TeamProxy:VoiceJoinTeam()
    local VoiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    VoiceManagerProxy:VoiceTeam({operateType = self.ChangeType.JOIN_IN})
end

-- 语音-解散/离开队伍
function TeamProxy:VoiceExitTeam(isDismiss, lastTeamID)
    local VoiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    VoiceManagerProxy:VoiceTeam({
        operateType = isDismiss and self.ChangeType.DISMISS or self.ChangeType.LEAVE,
        teamId = lastTeamID
    })
end

-- 语音-变更队长
function TeamProxy:VoiceUpdateMater(myRank, masterID)
    local VoiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    VoiceManagerProxy:VoiceTeam({
        operateType = TeamProxy.ChangeType.UPDATE,
        myRank = myRank,
        teamUserId = masterID
    })
end

function TeamProxy:UpdateMemberMaxNum()
    self._memberMax = tonumber(SL:GetValue("GAME_DATA", "team_num")) or self._memberMax
end

function TeamProxy:ClearTeam()
    self:Init()

    self:ClearApplyItems()

    -- 刷新队伍
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE)
end

function TeamProxy:LeaveTeam()
    if self:GetMemberCount() <= 0 then
        return false
    end

    -- 清除队伍数据
    self:ClearTeam()
end

function TeamProxy:GetNearTeamItems()
    return self._data.nearTeamItems
end

function TeamProxy:ClearNearTeam()
    self._data.nearTeamItems = {}
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_NEAR_UPDATE)
end

function TeamProxy:GetTeamMember()
    return self._data.memberItems
end

function TeamProxy:DealTeam(userID, value)
    local myID = SL:GetValue("USER_ID")
    if myID == userID then
        return false
    end

    local actor = global.actorManager:GetActor(userID) 
    if not actor then
        return false
    end
    actor:SetCampValue("InTeam", value)
end

function TeamProxy:IsTeamMember(uid)
    if not uid then
        return self._data.selfItem ~= nil
    end
    for _, v in ipairs(self._data.memberItems) do
        if v.UserID and v.UserID == uid then
            return true
        end
    end
    return false
end

function TeamProxy:IsTeamLeader(uid)
    if not uid then
        return (self._data.selfItem and self._data.selfItem.Rank == 1)
    end
    for _, v in ipairs(self._data.memberItems) do
        if v.UserID == uid then
            return v.Rank == 1
        end
    end
    return false
end

function TeamProxy:GetMemberCount()
    if not self._data.memberItems then
        return 0
    end

    return #self._data.memberItems
end

function TeamProxy:GetMemberMax()
    return self._memberMax
end

function TeamProxy:GetMyRank()
    return self._data.myRank
end

function TeamProxy:GetTeamID()
    return self._data.groupID or 0
end

function TeamProxy:GetApplyItems()
    return self._data.applyItems
end

function TeamProxy:removeApplyItemById(id)
    if not self._data.applyItems then return end
    for index, v in pairs(self._data.applyItems) do
        if v.UserID == id then
            table.remove(self._data.applyItems, index)
            return
        end
    end
end

function TeamProxy:ClearApplyItems()
    self._data.applyItems = {}

    SLBridge:onLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE)
end

function TeamProxy:GetInviteItems()
    return self._data.inviteItems
end

function TeamProxy:GetInviteCount()
    local count = 0
    for _, v in pairs(self._data.inviteItems) do
        count = count + 1
    end
    return count
end

function TeamProxy:ClearInviteItems()
    self._data.inviteItems = {}

    SL:onLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE)
end

function TeamProxy:GetTeamTargetId()
    return self._data.targetID
end

-- 请求 创建队伍
function TeamProxy:RequestCreateTeam()
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 0, 0, 0, 0)
end

-- 请求 退出队伍
function TeamProxy:RequestLeaveTeam()
    -- print("退出队伍")
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 1, 0, 0, 0)
    self._exitTeamID = {}
end

function TeamProxy:RequestTeamMemberData()
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 2, 0, 0, 0)
end

-- 请求 附近队伍
function TeamProxy:RequestNearTeam()
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 9, 0, 0, 0)
end

-- 请求 邀请入队
function TeamProxy:RequestInvite(uid, name)
    local body = uid or name
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 3, 0, 0, 0, body)
end

-- 请求 申请入队
function TeamProxy:RequestApplyTeam(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 6, 0, 0, 0, uid)
end

-- 请求 申请列表
function TeamProxy:RequestApplyData()
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 5, 0, 0, 0)
end

-- 请求 同意申请
function TeamProxy:RequestApplyAgree(uid)
    if self:GetMemberCount() >= self:GetMemberMax() then
        global.Facade:sendNotification(global.NoticeTable.SystemTips, GET_STRING(40010013))
        return
    end
    self:removeApplyItemById(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 7, 0, 0, 0, uid)

    SLBridge:onLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE)
end

-- 请求 拒绝申请
function TeamProxy:RequestApplyRefuse(uid)
    self:removeApplyItemById(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 7, 1, 0, 0, uid)

    SLBridge:onLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE)
end

-- 请求 拒绝邀请
function TeamProxy:RequestInviteRefuse(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 4, 1, 0, 0, uid)
    self._data.inviteItems[uid] = nil
    SL:onLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE)
end

-- 请求 同意邀请
function TeamProxy:RequestInviteAgree(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 4, 0, 0, 0, uid)
    self._data.inviteItems[uid] = nil
    SL:onLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE)
end

-- 请求 T人
function TeamProxy:RequestSubMember(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 8, 0, 0, 0, uid)
end

-- 请求 移交队长
function TeamProxy:RequestTransferLeader(uid)
    self._isTransferTeam = true
    LuaSendMsg(global.MsgType.MSG_CS_GROUPOPERATE, 10, 0, 0, 0, uid)
end

function TeamProxy:handleNearTeam(header, netPkg)
    local jsonData = netPkg:GetJsonData()
    if not jsonData then return end

    -- dump(jsonData)
    local nearData = {}
    local idx = 1
    for _, v in pairs(jsonData) do
        -- v.MasterID = tonumber(v.MasterID)
        if v.GroupID ~= self._data.groupID then
            nearData[idx] = v
            idx = idx + 1
        end
    end

    -- 附近队伍
    self._data.nearTeamItems = nearData
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_NEAR_UPDATE)
end

function TeamProxy:handleTeamCreate(header, netPkg)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_CREATE)

    self:VoiceCreateTeam()
end

function TeamProxy:handleMemberUpdate(header, netPkg)
    local jsonData = netPkg:GetJsonData()
    if not jsonData then return end

    -- self:ClearInviteItems()

    local myUID = SL:GetValue("USER_ID")
    for _, member in pairs(jsonData.MemBer) do
        if member.UserID == myUID then
            self._data.selfItem = member
        end
    end
        
    dump(jsonData)

    local members = jsonData.MemBer
    -- 检测是否有成员退出
    for _, a in ipairs(self._data.memberItems) do
        if a then
            local isQuit = true
            for _,b in pairs(members) do
                if a.UserID == b.UserID then
                    isQuit = false
                    break
                end
            end
            if isQuit then
                self._exitTeamID[a.UserID] = true
                SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_OTHER_LEAVE, a.UserName)
                self:DealTeam(a.UserID, false)
                break
            end
        end
    end

    local masterID = jsonData.MasterID--队长id
    local hasJoin = false
    for _, a in ipairs(members) do
        if a then
            a.Rank = a.UserID == masterID and 1 or 0--更新队长标识
            -- 检查是否是新增
            local isJoin = true
            for _, b in ipairs(self._data.memberItems) do
                if a.UserID == b.UserID then
                    isJoin = false
                    break
                end
            end
            if isJoin then
                hasJoin = true
                SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_JOIN, a.UserName)
                self:DealTeam(a.UserID, true)
            end
        end
    end

    -- 上次组队
    local lastMemberCount = #self._data.memberItems or 0

    local myRank = masterID == myUID and 1 or 0 
    local lastMyRank = self._data.myRank
    local isUpdate = false -- 是否变更队长
    if self._data.myRank ~= myRank then
        self._data.myRank = myRank
        isUpdate = true
    end
    self._data.groupID = jsonData.GroupID
    self._data.memberItems = members
    -- 整理队伍信息，自己如果不是队长，放到第二位
    table.sort(self._data.memberItems, function(a, b)
        if a.UserID == masterID then return true end
        if b.UserID == masterID then return false end
        if a.UserID == myUID then return true end
        if b.UserID == myUID then return false end
        return false
    end)

    -- 广播组队
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE)

    if self._data.myRank == 0 then
        self:ClearApplyItems()
    end

    if hasJoin then
        self:VoiceJoinTeam()
    end

    if isUpdate then
        local isVoice = false
        if self._data.myRank == 1 then  -- 队长自己发
            isVoice = true
        end
        local newMyRank = self._data.myRank
        local newTeamUserId = nil
        if next(self._exitTeamID) then
            if self._exitTeamID[myUID] then
                isVoice = false
            end
        else
            if self._isTransferTeam and lastMyRank == 1 then     -- 原队长上次移交队长
                newMyRank = lastMyRank
                newTeamUserId = masterID
                isVoice = true
            end
        end

        if isVoice then
            self._exitTeamID = {}
            self:VoiceUpdateMater(newMyRank, newTeamUserId)
        end
    end
    self._isTransferTeam = false
end

function TeamProxy:handleLeaveTeam(header, netPkg)
    -- 踢出队伍的时候，参数是3. 离开队伍的时候，带的参数是2，这两个是有区别的
    -- dump(header)
    if header.param1 == 1 then
        -- 离开队伍
        SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_LEAVE)
    elseif header.param1 == 2 then
        -- 被踢出队伍
        SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_OUT)
    elseif header.param1 == 3 then
        -- 解散
        SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_DISMISS)
    end

    local lastTeamID = self._data.groupID
    -- 队伍职位变为队员
    self._data.myRank = 0
    self._data.groupID = 0
    
    self._data.selfItem = nil
    self._data.memberItems = {}

    -- 清空申请列表
    self:ClearApplyItems()

    -- 刷新队伍
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE)

    self:VoiceExitTeam(header.param1 == 3, lastTeamID)

    global.Facade:sendNotification(global.NoticeTable.MainActorChange_OwnSidePlayer, global.MMO.TYPE_TEAM)
end

function TeamProxy:handleRefuseInvite(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local splitPos = string.find(str, "&")
    if not splitPos then return end
    local name = string.sub(str, splitPos + 1)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_REFUSE_INVITE, name)
end

function TeamProxy:handleTeamApply(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end

    self:RequestApplyData()
end

function TeamProxy:handleRefuseApply(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local splitPos = string.find(str, "&")
    if not splitPos then return end
    local name = string.sub(str, splitPos + 1)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_REFUSE_APPLY, name)
end

function TeamProxy:handleApplyList(header, netPkg)
    local jsonData = netPkg:GetJsonData()
    if not jsonData then return end
    local JoinMem = jsonData.JoinMem or {}

    self._data.applyItems = JoinMem
    SL:onLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE)
end

--被邀请
function TeamProxy:handleTeamInvite(header, netPkg)
    local data = netPkg:GetJsonData()
    if (not data) or (not data.UserID) then return end
    self._data.inviteItems[data.UserID] = data
    SL:onLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE)
end

function TeamProxy:RespTeam(netPkg)
    local header = netPkg:GetHeader()
    local recog = header.recog
    SL:Print("=================team recog:" .. recog)
    if recog == 0 then
        --创建队伍成功
        self:handleTeamCreate(header, netPkg)
    elseif recog == 1 then
        --队伍解散或退出成功或被踢
        self:handleLeaveTeam(header, netPkg)
    elseif recog == 2 then
        --队伍成员信息
        self:handleMemberUpdate(header, netPkg)
    elseif recog == 3 then
        --邀请信息
        self:handleTeamInvite(header, netPkg)
    elseif recog == 4 then
        --拒绝邀请
        self:handleRefuseInvite(header, netPkg)
    elseif recog == 5 then
        --申请信息
        self:handleTeamApply(header, netPkg)
    elseif recog == 6 then
        --拒绝申请
        self:handleRefuseApply(header, netPkg)
    elseif recog == 7 then
        --附近队伍
        self:handleNearTeam(header, netPkg)
    elseif recog == 8 then
        --下发申请列表
        self:handleApplyList(header, netPkg)
    end
end

function TeamProxy:RespTeamError(netPkg)
    local header = netPkg:GetHeader()
    local recog = header.recog
    SL:Print("=================team Error recog:" .. recog)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_TEAM_ERROR, recog)
end

function TeamProxy:onRegister()
    TeamProxy.super.onRegister(self)
end

function TeamProxy:RegisterMsgHandler()
    TeamProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_GROUPMSG, handler(self, self.RespTeam))
    LuaRegisterMsgHandler(msgType.MSG_SC_GROUPMSG_FAIL, handler(self, self.RespTeamError))
end

return TeamProxy