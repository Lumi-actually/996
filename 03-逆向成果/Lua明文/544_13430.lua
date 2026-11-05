local RemoteProxy = requireProxy("RemoteProxy")
local RelationProxy = class("RelationProxy" , RemoteProxy)
RelationProxy.NAME = global.ProxyTable.RelationProxy

function RelationProxy:ctor()

    self._flagH             = 0         -- 允许被邀请标识   -- 高 32位
    self._flagL             = 0         -- 允许被邀请标识   -- 低 32位
    self._callFlagH         = 0         -- 允许被召集标识   -- 高 32位
    self._callFlagL         = 0         -- 允许被召集标识   -- 低 32位

    self._relationData      = {}

    self._relationConfig    = {}

    self._relationTypeList  = {}

    self._myRelationList    = {}

    self._allowSwitchType   = {}

    self:LoadConfig()

    RelationProxy.super.ctor(self)
end

function RelationProxy:LoadConfig()
    local filePath = "scripts/game_config/cfg_relation.lua"
    if SL:IsFileExist(filePath) then
        SL:Print("[Require game_config] ", "cfg_relation")
        local config = SL:RequireFile(filePath)
        local typeList = {}
        for id, data in pairs(config) do
            table.insert(typeList, id)
            if data.filter_name and string.len(data.filter_name) > 0 then
                local param = G_GetSplitArray(data.filter_name, "#")
                data.filterNameList = {}
                for i = 1, #param do
                    if string.len(param[i] or "") > 0 then
                        table.insert(data.filterNameList, param[i])
                    end
                end
            end
            if data.allowSwitch == 1 then
                table.insert(self._allowSwitchType, id)
            end
        end

        table.sort(typeList, function(a, b)
            return a < b
        end)
        self._relationTypeList = typeList

        table.sort(self._allowSwitchType, function(a, b)
            return a < b
        end)

        self._relationConfig = config
    end
end

function RelationProxy:ReloadConfig()
    self._allowSwitchType = {}
    self._relationTypeList = {}
    self._relationConfig = {}
    self:LoadConfig()
end

function RelationProxy:GetConfigByType(type)
    return self._relationConfig and self._relationConfig[type]
end

function RelationProxy:GetTypeList()
    return self._relationTypeList
end

function RelationProxy:GetMaxCount(type)
    if self._relationConfig and self._relationConfig[type] then
        return self._relationConfig[type].maxCount
    end
end

function RelationProxy:GetCallCD(type)
    if self._relationConfig and self._relationConfig[type] then
        return self._relationConfig[type].callCD
    end
end

function RelationProxy:GetTypeName(type)
    if self._relationConfig and self._relationConfig[type] then
        return self._relationConfig[type].type_name or ""
    end
    return ""
end

function RelationProxy:GetTypeFuncDesc(type)
    if self._relationConfig and self._relationConfig[type] then
        return self._relationConfig[type].func_desc or ""
    end
    return ""
end

--------------------------------------------------------------
function RelationProxy:GetRelationDataByType(type)
    return self._relationData[type] or {}
end

function RelationProxy:GetMyRelationList()
    return self._myRelationList
end

function RelationProxy:GetAllowStatusByType(type)
    local index = table.indexof(self._allowSwitchType, type)
    if not index then
        return false
    end
    return CheckBit(index > 32 and self._flagH or self._flagL, index - 1)
end

function RelationProxy:SetAllowStatusByType(type, status)
    local value = status and 1 or 0
    local index = table.indexof(self._allowSwitchType, type)
    if not index then
        return false
    end

    if index > 32 then
        self._flagH = SetBit(self._flagH, index - 1, value)
    else
        self._flagL = SetBit(self._flagL, index - 1, value)
    end
    self:RequestSetAllowFlag()
end

function RelationProxy:GetAllowCallStatusByType(type)
    local index = table.indexof(self._relationTypeList, type)
    if not index then
        return false
    end
    return CheckBit(index > 32 and self._callFlagH or self._callFlagL, index - 1)
end

function RelationProxy:SetAllowCallStatusByType(type, status)
    local value = status and 1 or 0
    local index = table.indexof(self._relationTypeList, type)
    if not index then
        return false
    end

    if index > 32 then
        self._callFlagH = SetBit(self._callFlagH, index - 1, value)
    else
        self._callFlagL = SetBit(self._callFlagL, index - 1, value)
    end
    self:RequestSetAllowFlag()
end

---------------------------------------------------------------
-- 邀请玩家建立关系网 p1: 关系网类型id p2: 邀请对象userid body: 邀请对象名字
function RelationProxy:RequestInvitePlayerIn(type, userID, userName)
    LuaSendMsg(global.MsgType.MSG_CS_RELATION_OPERATE, 1, type, userID, 0, userName)
end

-- 踢出关系网成员 (踢出自己等于解散) p1: 踢出对象userid body: 关系网id
function RelationProxy:RequestKickOutMember(userID, netID)
    LuaSendMsg(global.MsgType.MSG_CS_RELATION_OPERATE, 2, userID, 0, 0, tostring(netID))
end

-- 解散或退出 body: 关系网id
function RelationProxy:RequestDissolveOrExit(netID)
    LuaSendMsg(global.MsgType.MSG_CS_RELATION_OPERATE, 3, 0, 0, 0, tostring(netID))
end

-- 请求自身所在关系网信息 p1: 关系网类型id
function RelationProxy:RequestRelationData(type)
    LuaSendMsg(global.MsgType.MSG_CS_RELATION_OPERATE, 4, type, 0, 0)
end

-- 设置勾选允许标记位 p1: 被邀请勾选项标记 (按表内配置开启允许勾选顺序 p2: 被召集勾选标记
function RelationProxy:RequestSetAllowFlag()
    -- print("RelationProxy:RequestSetAllowFlag()=====", self._flagH, self._flagL, self._callFlagH, self._callFlagL)
    LuaSendHeader7(global.MsgType.MSG_CS_RELATION_OPERATE, 5, self._flagL, self._flagH, self._callFlagL, self._callFlagH)
end

-- 发起召集 p1: 关系网类型id p2: 发起者在关系网中的身份(0邀请者 1被邀请者) body: 关系网id
function RelationProxy:RequestCallMember(type, netID, rank)
    LuaSendMsg(global.MsgType.MSG_CS_RELATION_OPERATE, 6, type, rank, 0, tostring(netID))
end

function RelationProxy:ClearRelationDataByType(type, netID)
    if not type or not netID then
        return
    end
    self._relationData[type][netID] = nil
    if self._myRelationList and self._myRelationList[type] and self._myRelationList[type].NetID == netID then
        self._myRelationList[type] = nil
    end
end

local operaNoticeTab = {}
function RelationProxy:handle_MSG_SC_RELATION_OPERATE(netPkg)
    -- print("handle_MSG_SC_RELATION_OPERATE  920   --- ", netPkg:GetP0(), netPkg:GetP1(), netPkg:GetP2())

    local p0 = netPkg:GetP0()
    local p1 = netPkg:GetP1()
    local p2 = netPkg:GetP2()
    if p0 == 1 then -- 邀请玩家建立关系网结果
        -- p1 0失败 1成功
        -- p2 错误码
        -- 0 其他错误  1 关系网类型id不存在  2 对方拒绝被邀请  3 该类型关系网数量达上限  4 关系网到达人数上限
		-- 5 对方该类型关系网数量达上限  6 对方已在其他人邀请的同类型关系网  7 性别不满足  8 不可重复邀请
        if p1 == 0 then
            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_INVITE_ERROR, p2)
        end

    elseif p0 == 2 then -- 踢出玩家
        -- p1 1踢出成功 2被踢出成功 3踢出失败 4 删除玩家成功-被踢出/退出 [后端lua操作无需提示]
        -- p2 关系网类型id
        -- body 关系网id
        if p1 == 2 or p1 == 4 then
            local type = p2
            local netID = netPkg:GetBodyStr()
            local data = self._relationData[type] and self._relationData[type][netID]
            local memberName = nil
            if data and next(data) then
                if data.MemList and next(data.MemList) then
                    for i, member in ipairs(data.MemList) do
                        if member.UserID == data.MasterID then
                            memberName = member.UserName
                            break
                        end
                    end
                end
            end
            self:ClearRelationDataByType(type, netID)
            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_DATA_REFRESH, type)
            
            if memberName and p1 == 2 then
                operaNoticeTab.type         = GUIDefine.RelationNoticeType.KICKED
                operaNoticeTab.member       = memberName
                operaNoticeTab.relationType = type
                SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_NOTICE, operaNoticeTab)
            end
        end

    elseif p0 == 3 then -- 解散或退出
        -- p1 1解散成功 2退出成功 3解散失败 4退出失败
        -- p2 关系网类型id
        -- body 关系网id
        if p1 == 1 or p1 == 2 then
            local type = p2
            local netID = netPkg:GetBodyStr()
            self:ClearRelationDataByType(type, netID)            
            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_DATA_REFRESH, type)
            if p1 == 1 then
                operaNoticeTab.type         = GUIDefine.RelationNoticeType.DISSOLVE
                operaNoticeTab.member       = nil
                operaNoticeTab.relationType = type
                SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_NOTICE, operaNoticeTab)
            end
        end

    
    elseif p0 == 4 then -- 关系网信息
        -- p1 0更新单个关系网信息 1同类型多条列表信息
        local data = netPkg:GetJsonData()
        if p1 == 0 then
            local type = data.TypeID
            local netID = data.NetID
            local config = self:GetConfigByType(type) or {}
            if not self._relationData[type] then
                self._relationData[type] = {}
            end
            self._relationData[type][netID] = data
            if data.MasterID == SL:GetValue("USER_ID") or config.multistage == 1 then
                self._myRelationList[type] = data
            end

            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_DATA_REFRESH, type)

            local memberName = data.NewMember or data.DelMember
            if memberName then
                operaNoticeTab.type         = data.DelMember and GUIDefine.RelationNoticeType.EXIT or GUIDefine.RelationNoticeType.JOIN
                operaNoticeTab.member       = memberName
                operaNoticeTab.relationType = type
                SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_NOTICE, operaNoticeTab) 
            end
            
        elseif p1 == 1 then
            local refreshAll = true
            local refreshType = nil
            for _, list in ipairs(data) do
                local type = list.TypeID
                local config = self:GetConfigByType(type) or {}
                if refreshAll then
                    self._relationData[type] = {}
                    refreshAll = false
                    refreshType = type
                end
                local netID = list.NetID
                self._relationData[type][netID] = list
                if list.MasterID == SL:GetValue("USER_ID") or config.multistage == 1 then
                    self._myRelationList[type] = list
                end
            end

            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_DATA_REFRESH, refreshType)

        elseif p1 == 2 then -- 初始化所有关系网数据
            self._relationData = {}
            for type, typeData in pairs(data) do
                local typeID = tonumber(type)
                local config = self:GetConfigByType(typeID) or {}
                self._relationData[typeID] = {}
                for _, list in ipairs(typeData) do
                    local netID = list.NetID
                    self._relationData[typeID][netID] = list
                    if list.MasterID == SL:GetValue("USER_ID") or config.multistage == 1 then -- 不允许多级时 不是我邀请的也无法再邀请, 记作自己关系
                        self._myRelationList[typeID] = list
                    end
                end
            end
            SLBridge:onLUAEvent(LUA_EVENT_SOCIAL_RELATION_DATA_INIT)
        end

    elseif p0 == 5 then -- 勾选允许标记位
        -- p1 被邀请勾选项标记(按位计算，64位)
        -- p2 被召集勾选项标记(按位计算，64位)
        self._flagL = netPkg:GetP1L32()
        self._flagH = netPkg:GetP1H32()
        self._callFlagL = netPkg:GetP2L32()
        self._callFlagH = netPkg:GetP2H32()

    elseif p0 == 7 then  -- 视野内玩家关系网变化id刷新
        local userID = netPkg:GetP1Str()
        local count = p2
        local netData = netPkg:GetBodyNetValues(count) or {}
        local actor = global.actorManager:GetActor(userID)
        if actor and actor.SetJoinNetData then
            actor:SetJoinNetData(netData)
        end
    end
    
end

function RelationProxy:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_RELATION_OPERATE, handler(self, self.handle_MSG_SC_RELATION_OPERATE))
end

return RelationProxy