local RemoteProxy = requireProxy("RemoteProxy")
local FriendProxy = class("FriendProxy", RemoteProxy)
FriendProxy.NAME = global.ProxyTable.FriendProxy

function FriendProxy:ctor()
    FriendProxy.super.ctor(self)

    self._maxFriend = 100            -- 最大好友人数
    self._friendList = {}           --好友列表
    self._blackList = {}            --黑名单列表[{uid,name}]
    self._applyList = {}            --好友申请列表[{uid,name}]
end

function FriendProxy:OnLogin()
    self:RequestFriendList()
    self:RequestBlackList()
end

-- 最大好友数量
function FriendProxy:GetMaxNum()
    return self._maxFriend
end

function FriendProxy:GetFriendList()
    return self._friendList
end

function FriendProxy:GetBlackList()
    return self._blackList
end

function FriendProxy:GetApplyList()
    return self._applyList
end

function FriendProxy:DelFriendApply(userID)
    if not userID then return end
    for k, data in pairs(self._applyList) do
        if data and data.UserID == userID then
            table.remove(self._applyList, k)
            SL:onLUAEvent(LUA_EVENT_FRIEND_APPLY)
            return
        end
    end
end

function FriendProxy:ClearFriendApply()
    self._applyList = {}
    SL:onLUAEvent(LUA_EVENT_FRIEND_APPLY)
end

function FriendProxy:GetFriendDataByName(name)
    for k, v in pairs(self._friendList) do
        if v.UserName == name then return v end
    end
    return nil
end

function FriendProxy:GetFriendDataByUserID(userID)
    for k, v in pairs(self._friendList) do
        if v.UserID == userID then return v end
    end
    return nil
end

function FriendProxy:IsFriendByUserID(userID)
    for k, v in pairs(self._friendList) do
        if v.UserID == userID then return true end
    end
    return false
end

function FriendProxy:IsFriendByName(name)
    for k, v in pairs(self._friendList) do
        if v.UserName == name then return true end
    end
    return false
end

function FriendProxy:IsInBlackList(userID)
    for k, v in pairs(self._blackList) do
        if v.UserID == userID then return true end
    end
    return false
end

function FriendProxy:GetBlackDataByUserID(userID)
    for k, v in pairs(self._blackList) do
        if v.UserID == userID then return v end
    end
    return nil
end

function FriendProxy:GetBlackDataByName(userID)
    for k, v in pairs(self._blackList) do
        if v.UserName == userID then return v end
    end
    return nil
end

-- 请求 好友列表
function FriendProxy:RequestFriendList()
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 0, 0, 0, 0)
end

-- 请求 黑名单列表
function FriendProxy:RequestBlackList()
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 0, 1, 0, 0)
end

-- 请求 申请好友
function FriendProxy:RequestAddFriend(name)
    if not name then return end
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 1, 0, 0, 0, name)
end

-- 请求 拒绝或同意好友申请
function FriendProxy:RequestDealFriendApply(isAgree, userID)
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 2, isAgree and 0 or 1, 0, 0, userID)
    self:DelFriendApply(userID)
end

-- 请求 增加黑名单
function FriendProxy:RequestAddBlack(userID, name)
    local body = userID
    local param = 0
    if name then 
        body = name
        param = 1
    end
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 3, param, 0, 0, body)
end

-- 请求 删除黑名单
function FriendProxy:RequestDelBlack(userID)
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 4, 0, 0, 0, userID)
end

-- 请求 删除好友
function FriendProxy:RequestDelFriend(userID)
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 5, 0, 0, 0, userID)
end

-- 请求 申请列表
function FriendProxy:RequestApplyList(userID)
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 6, 0, 0, 0, userID)
end

-- 请求 同意所有好友申请
function FriendProxy:RequestAgreeAllFriendApply()
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 7, 0, 0, 0, 0)
    self:ClearFriendApply()
end

-- 请求 拒绝所有好友申请
function FriendProxy:RequestDisAgreeAllFriendApply()
    LuaSendMsg(global.MsgType.MSG_CS_FRIENDOPERATE, 8, 0, 0, 0, 0)
    self:ClearFriendApply()
end

function FriendProxy:handleList(header, netPkg)
    local data = netPkg:GetJsonData()
    if not data then return end
    local p1 = netPkg:GetP1()
    if p1 == 0 then
        self._friendList = data.Member or {}
        table.sort(self._friendList, function(a, b)
			if b.Line == 1 then return false end
            if a.Line == 1 then return true end
            return false
        end)
        SL:onLUAEvent(LUA_EVENT_FRIEND_LIST_UPDATE)
    else
        self._blackList = data.Member or {}
        SL:onLUAEvent(LUA_EVENT_BLACK_LIST_UPDATE)
    end
end

function FriendProxy:handleApplyFriend(header, netPkg)
    local data = netPkg:GetJsonData()
    if not data then return end
    if self:IsInBlackList(data.UserID) then return end
    table.insert(self._applyList, data)
    SL:onLUAEvent(LUA_EVENT_FRIEND_APPLY)
end

--拒绝好友申请
function FriendProxy:handleRefuseFriend(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local splitPos = string.find(str, "&")
    if not splitPos then return end
    local name = string.sub(str, splitPos + 1)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_REFUSE_APPLY, name)
end

function FriendProxy:handleAddFriendSuccess(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local splitPos = string.find(str, "&")
    if not splitPos then return end

    local name = string.sub(str, splitPos + 1)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_ADD_SUCCESS, name)
    self:RequestFriendList()
end

function FriendProxy:handleAddBlackSuccess(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local splitPos = string.find(str, "&")
    if not splitPos then return end
    local name = string.sub(str, splitPos + 1)
    if name and name ~= "" then
        SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_ADD_BLACKLIST_SUCCESS, name)
    end
    self:RequestBlackList()
end

function FriendProxy:handleDelBlackSuccess(header, netPkg)
    local str = netPkg:GetBodyStr()
    if not str then return end
    local userID = str
    --删除黑名单数据中对应项
    for i, data in pairs(self._blackList) do
        if data and data.UserID == userID then
            table.remove(self._blackList, i)
            SL:onLUAEvent(LUA_EVENT_BLACK_LIST_UPDATE)
            SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_DEL_BLACKLIST_SUCCESS, data.UserName)
            break
        end
    end
end

function FriendProxy:handleDelFriendSuccess(header, netPkg)
    local userID = netPkg:GetBodyStr()
    if (not userID) or (userID == "")  then return end

    for i, data in pairs(self._friendList) do
        if data and data.UserID == userID then
            table.remove(self._friendList, i)
            SL:onLUAEvent(LUA_EVENT_FRIEND_LIST_UPDATE)
            SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_DEL_SUCCESS, data.UserName)
            break
        end
    end
end

-- function FriendProxy:handleSearchPlayer(header, netPkg)
--     local data = netPkg:GetJsonData()
--     if not data then return end
--     SLBridge:onLUAEvent(LUA_EVENT_FRIEND_SEARCH_UPDATE, data)
-- end

function FriendProxy:RespFriend(netPkg)
    local header = netPkg:GetHeader()
    local recog = header.recog
    SL:Print("=======================Friend recog:" .. recog)
    if recog == 0 then
        self:handleList(header, netPkg)
    elseif recog == 1 then
        self:handleApplyFriend(header, netPkg)
    elseif recog == 2 then
        self:handleRefuseFriend(header, netPkg)
    elseif recog == 3 then
        self:handleAddFriendSuccess(header, netPkg)
    elseif recog == 4 then
        self:handleAddBlackSuccess(header, netPkg)
    elseif recog == 5 then
        self:handleDelBlackSuccess(header, netPkg)
    elseif recog == 6 then
        self:handleDelFriendSuccess(header, netPkg)
    elseif recog == 7 then--获取好友申请列表

    elseif recog == 8 then--申请好友发送成功
        SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_APPLY_SUCCESS)
    -- elseif recog == 9 then
    --     self:handleSearchPlayer(header, netPkg)
    end
end

function FriendProxy:RespFriendError(netPkg)
    local header = netPkg:GetHeader()
    local recog = header.recog
    SL:Print("=======================Friend Error recog:" .. recog)
    SL:onLUAEvent(LUA_EVENT_SOCIAL_FRIEND_ERROR, recog)
end

function FriendProxy:RegisterMsgHandler()
    FriendProxy.super.RegisterMsgHandler(self)
    local msgType = global.MsgType

    LuaRegisterMsgHandler(msgType.MSG_SC_FRIENDMSG, handler(self, self.RespFriend))
    LuaRegisterMsgHandler(msgType.MSG_SC_FRIENDERRO, handler(self, self.RespFriendError))
end

return FriendProxy