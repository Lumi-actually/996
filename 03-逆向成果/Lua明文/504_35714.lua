local RemoteProxy = requireProxy("RemoteProxy")
local GuildProxy = class("GuildProxy" , RemoteProxy)
GuildProxy.NAME = global.ProxyTable.GuildProxy

local proxyUtils = requireUtil("proxyUtils")
local parseOneItemByJson = proxyUtils.parseOneItemByJson

local cjson = require("cjson")

GuildProxy.GuildPermission =
{
    SetRank         = 1,        -- 设置职位
    SetNotice       = 2,        -- 设置公告
    ApproveApply    = 3,        -- 允许入会
    RemoveMember    = 4,        -- 允许删除
}

-- 行会变更类型 [语音用]
GuildProxy.ChangeType = {
    DISMISS         = 0,        -- 解散
    JOIN_IN         = 1,        -- 加入
    LEAVE           = 2,        -- 离开
    CREATE          = 3         -- 创建
}

function GuildProxy:ctor()
    GuildProxy.super.ctor(self)

    self._isJoinGuild           = false -- 是否加入公会
    self._guildInfo             = {}
    self._guildList             = {}
    self._memberList            = {}
    self._applyGuildList        = {}    -- 申请入会成员列表
    self._worldGuild            = {}    -- 世界行会映射 key: guildID

    self._createAutoApply       = true  -- 创建行会后是否自动同意申请入会
    self._createAutoLevel       = 1     -- 创建行会后自动同意的等级
    self._guildTitle            = {}    -- 行会封号

    self._allyApplyList         = {}    -- 申请联盟列表

    self._guildWarList          = {}    -- 行会战斗列表
    self._guildAllyList         = {}    -- 行会联盟列表

    -- 语音
    self._firstVoiceInit        = false
    self._isBindPlayerFinish    = false
    self._isInitGuildDataFinish = false

    self._guildShaBaKeWarList   = {}    -- 行会宣战列表  沙巴克行会
    self._guildShaBaKeAllyList  = {}    -- 行会联盟列表  沙巴克行会
    self._guildShaBaKeID        = nil   -- 沙巴克行会ID

    self._rank_guild_name = nil --行会名txt数据

end

-- 初始化语音
function GuildProxy:VoiceInit()
    if not self._firstVoiceInit and self._isBindPlayerFinish and self._isInitGuildDataFinish then
        local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
        voiceManagerProxy:VoiceInit()
        self._firstVoiceInit = true
    end
end

-- 语音-创建行会
function GuildProxy:VoiceCreateGuild()
    local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    voiceManagerProxy:VoiceGuildChange({
        operatorType = self.ChangeType.CREATE
    })
end

-- 语音-加入行会
function GuildProxy:VoiceJoinGuild()
    local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    voiceManagerProxy:VoiceGuildChange({
        operatorType = self.ChangeType.JOIN_IN
    })
end

-- 语音-离开行会
function GuildProxy:VoiceLeaveGuild(lastGuildID)
    local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    voiceManagerProxy:VoiceGuildChange({
        operatorType = self.ChangeType.LEAVE,
        guildId = lastGuildID
    })
end

-- 语音-解散行会
function GuildProxy:VoiceDismissGuild(lastGuildID)
    local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    voiceManagerProxy:VoiceGuildChange({
        operatorType = self.ChangeType.DISMISS, 
        guildId = lastGuildID
    })
end

-- 语音-职位改变
function GuildProxy:VoiceRankChange()
    local voiceManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.VoiceManagerProxy)
    voiceManagerProxy:VoiceGuildRoleChange()
end

function GuildProxy:SetBindMainPlayerFininsh(isFinish)
    self._isBindPlayerFinish = isFinish
    self:VoiceInit()
end

function GuildProxy:SetInitDataFinish(isFinish)
    self._isInitGuildDataFinish = isFinish
    self:VoiceInit()
end

function GuildProxy:IsJoinGuild()
    return self._isJoinGuild
end

function GuildProxy:SetJoinGuild(status)
    local lastStatus = self._isJoinGuild
    self._isJoinGuild = status
    if lastStatus ~= self._isJoinGuild then
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_JOIN_STATE_CHANGE)
        global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor)
    end
end

function GuildProxy:GetUserInfo()
    return self._guildInfo.UserInfo
end

function GuildProxy:GetUserRank()
    local userInfo = self:GetUserInfo()
    if not userInfo then
        return SLDefine.GuildRank.rank5
    end
    return userInfo.Ranks
end

function GuildProxy:IsGuildAdmin()
    return self:IsGuildChairman() or self:IsGuildViceChairman()
end

function GuildProxy:IsGuildChairman()
    if not self:IsJoinGuild() then
        return false
    end
    return self:GetUserRank() == SLDefine.GuildRank.Chairman
end

function GuildProxy:IsGuildViceChairman()
    if not self:IsJoinGuild() then
        return false
    end
    return self:GetUserRank() == SLDefine.GuildRank.ViceChairman
end

-- 获取世界行会列表
function GuildProxy:GetGuildList()
    return self._guildList
end

-- 获取单个世界行会数据
function GuildProxy:GetWorldGuildInfoByID(guildID)
    return self._worldGuild[guildID]
end

-- 行会随机名
function GuildProxy:GetRankGuildName()
    if not self._rank_guild_name then
        self._rank_guild_name = {}
        -- 自定义敏感字
        local filePath = "data_config/guild_name.txt"
        local text = ""
        if global.FileUtilCtl:isFileExist(filePath) then
            local function callback(dataTable)
                if dataTable[1] and dataTable[1] ~= "" then
                    text = string.trim(dataTable[1])
                    if text ~= "" then
                        self._rank_guild_name[#self._rank_guild_name + 1] = text
                    end
                end
            end
            LoadTxt(filePath, nil, callback)
        end
    end
    
    local random = Random(1, #self._rank_guild_name)

    return self._rank_guild_name[random] or ""
end

-- 获取行会成员列表
-- [{Job, Join, Level, Line, Rank, Sex, UserID, UserName, LastTime}, ...]
function GuildProxy:GetMemberList()
    return self._memberList
end

function GuildProxy:GetMemberCount()
    return self._memberList and #self._memberList or 0
end

function GuildProxy:CleaMemberList()
    self._memberList = {} 
end

function GuildProxy:GetGuildMemberInfoByID(uid)
    for index, info in pairs(self._memberList) do
        if info.UserID == tostring(uid) then
            return info
        end
    end
    return nil
end

-- 获取行会主信息
function GuildProxy:GetGuildInfo()
    return self._guildInfo
end

function GuildProxy:GetGuildLevel()
    return self._guildInfo.Level or 0
end

function GuildProxy:GetGuildMemberMax()
    return self._guildInfo.MaxMemCount or 100
end

function GuildProxy:GetGuildID()
    return self._guildInfo.GuildID
end

function GuildProxy:GetGuildName()
    return self._guildInfo.GuildName
end

function GuildProxy:GetGuildNumber()
    return self._guildInfo.GuildNum
end

function GuildProxy:GetGuildMasterID()
    return self._guildInfo.MasterID
end

function GuildProxy:GetGuildMasterName()
    return self._guildInfo.MasterName
end

function GuildProxy:GetAutoJoin()
    return self._guildInfo.AutoJoin == 1
end

function GuildProxy:GetJoinLevel()
    return self._guildInfo.JoinLevel or 0
end

function GuildProxy:GetJoinJob()
    return self._guildInfo.JoinJob or 0
end

function GuildProxy:GetGuildNotice()
    return self._guildInfo.Notice
end

function GuildProxy:GetGuildGold()
    return self._guildInfo.Gold or 0
end

function GuildProxy:ClearGuildInfo()
    self._guildInfo = {}
end

-- 创建行会是否可以自动加入
function GuildProxy:SetCreateAutoApply(value)
    self._createAutoApply = value
end

function GuildProxy:GetCreateAutoApply(value)
    return self._createAutoApply
end

function GuildProxy:SetCreateAutoLevel(value)
    self._createAutoLevel = value
end

function GuildProxy:GetCreateAutoLevel()
    return self._createAutoLevel
end

function GuildProxy:SetGuildTitle(data)
    self._guildTitle = {}
    for i = 0, 20 do
        local title = data["Ranks" .. i]
        if not title then
            break
        end
        self._guildTitle[i] = title
    end
end

function GuildProxy:GetGuildTitleNameByRank(rank)
    return self._guildTitle[rank]
end

function GuildProxy:GetGuildTitleList()
    local list = {}
    for i, title in pairs(self._guildTitle) do
        table.insert(list, {rank = i, title = title})
    end
    table.sort(list, function(a, b)
        return a.rank < b.rank
    end)
    return list
end

function GuildProxy:GetViceChairmanPermissionByID(id)
    if not self._guildInfo.State then
        return false
    end
    return self._guildInfo.State[id] == true
end

function GuildProxy:GetApplyGuildList()
    return self._applyGuildList or {}
end

function GuildProxy:GetAllyApplyList()
    return self._allyApplyList or {}
end

-- 是否是结盟行会
function GuildProxy:IsAllyGuild(guildID)
    local guildInfo = self:GetWorldGuildInfoByID(guildID)
    if guildInfo and guildInfo.AllyTime and guildInfo.AllyTime >= GetServerTime() then
        return true
    end
    return false
end

function GuildProxy:ClearData()
    self._guildInfo             = {}
    self._memberList            = {}
    self._guildList             = {}
    self._worldGuild            = {}
    self._allyApplyList         = {}
    self._guildWarList          = {}
    self._guildAllyList         = {}
end

----------------------------------------------------------------------------------------------------------------
-- 沙巴克行会关系  联盟
function GuildProxy:SetShaBaKeGuildAllyRelation(data, diffData)
    local temp = self._guildShaBaKeAllyList or {}
    self._guildShaBaKeAllyList = {}
    for k, v in pairs(data or {}) do
        if v and v then
            -- 新增
            if diffData and not temp[v] then
                diffData[v] = true
            end
            self._guildShaBaKeAllyList[v] = v
        end
    end

    if diffData then
        for k, v in pairs(temp) do
            -- 移除
            if k and not self._guildShaBaKeAllyList[k] then
                diffData[k] = true
            end
        end
    end
end

-- 沙巴克行会关系  宣战
function GuildProxy:SetShaBaKeGuildWarRelation(data, diffData)
    local temp = self._guildShaBaKeWarList
    self._guildShaBaKeWarList = {}
    for k, v in pairs(data or {}) do
        if v then
            if diffData and not temp[v] then
                diffData[v] = true
            end
            self._guildShaBaKeWarList[v] = v
        end
    end

    if diffData then
        for k, v in pairs(temp) do
            if k and not self._guildShaBaKeWarList[k] then
                diffData[k] = true
            end
        end
    end
end

---------------------
-- 沙巴克开启颜色
function GuildProxy:GetShaBaKeZoneNameColor(guildId)
    if not guildId or guildId == "" or guildId == 0 then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR)
    end
    
    local myGuildId = self:GetGuildID()
    if not myGuildId or myGuildId == "" or myGuildId == 0 then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR)
    end

    -- 前提：攻沙开启且在攻沙区域
    -- 自己行会没参加攻沙， 其它行会都是绿色
    if myGuildId ~= self._guildShaBaKeID and not self._guildShaBaKeWarList[myGuildId] and not self._guildShaBaKeAllyList[myGuildId] then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR)
    end

    -- 前提：攻沙开启且在攻沙区域
    -- 不参与攻沙的都是绿色
    if guildId ~= self._guildShaBaKeID and not self._guildShaBaKeWarList[guildId] and not self._guildShaBaKeAllyList[guildId] then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR)
    end

    -- 结盟颜色
    if myGuildId == guildId or self._guildAllyList[guildId] then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_ALLY_GUILD_NAME_COLOR)
    end

    -- 守城方都是结盟颜色
    if self._guildShaBaKeAllyList[myGuildId] and self._guildShaBaKeAllyList[guildId] then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_ALLY_GUILD_NAME_COLOR)
    end

    -- 其余参与攻沙的都是宣战颜色。
    return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_WAR_GUILD_NAME_COLOR)
end

-- 行会战颜色 [指定地图]
function GuildProxy:IsGuildWar()
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    return MapProxy:IsMapWar()
end

-- 野外宣战
function GuildProxy:HasWarGuild()
    if next(self._guildWarList) then
        return true
    end
    return false
end

function GuildProxy:GetGuildWarNameColor(guildId)
    if not self:IsGuildWar() and not self:HasWarGuild() then
        return nil
    end

    -- 自己没行会时 行会战：看其他都为绿色
    local myGuildId = self:GetGuildID()
    if not myGuildId or myGuildId == "" or myGuildId == 0 then
        return self:IsGuildWar() and SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR) or nil
    end

    -- 自己有行会时 行会战：看没行会的为绿色
    if not guildId or guildId == "" or guildId == 0 then
        return self:IsGuildWar() and SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_SHABAKE_FREE_NAME_COLOR) or nil
    end

    -- 行会战/野外宣战：同盟、同行会时 互为蓝色
    if self._guildAllyList[guildId] or guildId == myGuildId then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_ALLY_GUILD_NAME_COLOR)
    end

    -- 行会战: 宣战/其他都为橙色 野外：仅宣战为橙色
    if self._guildWarList[guildId] then
        return SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_WAR_GUILD_NAME_COLOR)
    end

    return self:IsGuildWar() and SL:GetValue("SERVER_OPTIONS", global.MMO.SERVER_WAR_GUILD_NAME_COLOR) or nil
end

-----------------------------------------------------消息收发----------------------------------------------------

-- 创建行会
function GuildProxy:RequestCreateGuild(guildName, autoJoinState, autoLevel, notice)
    local jsonData = 
    {
        GuildName = guildName,
        AutoJoin = autoJoinState and 1 or 0,
        Level = autoLevel,
        Notice = notice or "",
    }
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 0, 0, 0, 0, cjson.encode(jsonData))
end

-- 退出行会
function GuildProxy:RequestLeaveGuild()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 1, 0, 0, 0)
end

-- 解散行会
function GuildProxy:RequestDissolveGuild()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 1, 1, 0, 0)
end

-- 请求加入行会
function GuildProxy:RequestApplyGuild(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 2, 0, 0, 0, guildID)
end

-- 行会申请列表
function GuildProxy:RequestApplyGuildList()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 3)
end

-- 同意入会申请
function GuildProxy:RequestApproveUserApply(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 4, 0, 0, 0, tostring(uid))
end

-- 拒绝入会申请
function GuildProxy:RequestRejectUserApply(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 4, 1, 0, 0, tostring(uid))
end

-- 行会信息
function GuildProxy:RequestGuildInfo()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 5)
end

-- 邀请玩家入会
function GuildProxy:RequestInviteMember(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 6, 0, 0, 0, tostring(uid))
end

-- 同意入会邀请
function GuildProxy:RequestApproveUserInvite(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 7, 0, 0, 0, tostring(guildID))
end

-- 拒绝入会邀请
function GuildProxy:RequestRejectUserInvite(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 7, 1, 0, 0, tostring(guildID))
end

-- 踢出行会
function GuildProxy:RequestRemoveMember(uid)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 8, 0, 0, 0, tostring(uid))
end

--设置行会封号 
function GuildProxy:RequestSetGuildTitle(data)
    --[[
        掌门,副掌门,行会成员,行会成员,行会成员
    ]]
    local sendStr = table.concat(data, ",")
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 9, 0, 0, 0, sendStr)
end

-- 编辑公告
function GuildProxy:RequestEditNotice(notice)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 10, 0, 0, 0, notice)
end

-- 申请联盟 (单位：分钟)
function GuildProxy:RequestApplyAlliance(guildID, time)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 11, time, 0, 0, guildID)
end

-- 同意联盟申请
function GuildProxy:RequestApproveAllianceApply(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 12, 0, 0, 0, guildID)
end

-- 拒绝联盟申请
function GuildProxy:RequestRejectAllianceApply(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 12, 1, 0, 0, guildID)
end

-- 请求申请联盟列表
function GuildProxy:RequestAllianceApplyList()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 13, 0, 0, 0)
end

-- 请求联盟战争行会列表
function GuildProxy:RequestAllianceWarList()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 14, 0, 0, 0)
end

-- 请求行会成员列表
function GuildProxy:RequestMemberList()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 15)
end

-- 请求宣战 (时间：分钟)
function GuildProxy:RequestDeclareWar(guildID, time)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 16, time, 0, 0, guildID)
end

-- 取消联盟
function GuildProxy:RequestCancelAlliance(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 17, 0, 0, 0, guildID)
end

-- 取消宣战
function GuildProxy:RequestCancelWar(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 18, 0, 0, 0, guildID)
end

-- 世界行会列表
function GuildProxy:RequestGuildList()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 19, 0, 0, 0)
end

-- 请求拉取行会公告，通过行会id
function GuildProxy:RequestGuildNotice(guildID)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 20, 0, 0, 0, guildID)
end

-- 自动加入行会
function GuildProxy:RequestAutoJoinGuild()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 21)
end

-- 设置职位
function GuildProxy:RequestAppointRank(uid, rank)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 22, rank, 0, 0, tostring(uid))
end

-- 设置自动同意入会申请
function GuildProxy:RequestApproveAutoApply()
    local autoLevel = self:GetJoinLevel()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 23, 1, autoLevel, 0)
end

-- 取消自动同意入会申请
function GuildProxy:RequestRejectAutoApply()
    local autoLevel = self:GetJoinLevel()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 23, 0, autoLevel, 0)
end

-- 设置自动同意等级
function GuildProxy:RequestSetAutoJoinLevel(level)
    local autoJoin = self:GetGuildInfo().AutoJoin
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 23, autoJoin, level, 0)
end

-- 拉取权限状态
function GuildProxy:RequestPermissionInfo()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 24, 0, 0, 0)
end

-- 设置权限状态
function GuildProxy:RequestSetPermissionByID(permissionID, state)
    -- 25 设置管理状态 Param = Idx 0 设置职位 1 设置公告 2 允许入会 3 允许删除 nTag = 1 开启 0 关闭
    state = (state == true and 1 or 0)
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 25, permissionID - 1, state, 0)
end

-- 管理员一键通过入会申请
function GuildProxy:RequestApproveAllUsersApply()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 26, 0, 0, 0)
end

-- 管理员一键拒绝入会申请
function GuildProxy:RequestRejectAllUsersApply()
    LuaSendMsg(global.MsgType.MSG_CS_GUILD_OPERATE, 26, 1, 0, 0)
end

------------------------------------------
function GuildProxy:handle_MSG_SC_GUILD_OPERATE(netPkg)
    -- 操作行会错误或提示统一下发数据
    -- SM_GUILDOPERATE = 763; 
    -- 参数 Recog
    --    -1 名称为空
    --    -2 名字已经存在
    --    -3 没有准备好物品
    --    -4 缺少创建费用
    --    -5 你已经加入或拥有行会
    --    -6 对方已拥有行会
    --    -7 对方拒绝了你的申请
    --    -8 已经申请了 
    --    -9 已经联盟 
    --    -10 行会战争中
    --    -11 对方拒绝联盟 body = 拒绝行会GUID&拒绝行会名称
    --    -12 掌门禁止退出行会
    --    -13 职位数量超过上线
    --    -14 行会人数超过上线
    --    -15 设置职位错误
    --    -16 只能掌门或管理员操作
	--    -17 货币不足  Param = 0 联盟 Param = 1 战争

    releasePrint("handle_MSG_SC_GUILD_OPERATE  763", netPkg:GetP0())

    local recog = netPkg:GetP0()
    SLBridge:onLUAEvent(LUA_EVENT_GUILD_OPERATE_ERROR, recog)
end

function GuildProxy:handle_MSG_SC_GUILD_MSG(netPkg)
    -- 行会统一下发数据
    -- SM_GUILDMSG = 762; 
    -- 参数 Recog
	-- 0 创建行会成功 
	-- 1 行会信息 JSON 
	-- 2 邀请信息 格式 邀请行会GUID&邀请者
	-- 3 加入行会成功
	-- 4 下发申请加入行会列表 JSON
	-- 5 下发行会成员列表 JSON
	-- 6 下发申请联盟列表 JSON
	-- 7 下发联盟战争列表 JSON
	-- 8 用户登录自动下发行会战争联盟简单列表 JSON
	-- 9 增加联盟或者战争 其中 Param = 0 联盟 1 = 战争 body = 行会GUID
	-- 10 删除联盟或者战争 其中 Param = 0 联盟 1 = 战争 body = 行会GUID
	-- 11 取消联盟成功
	-- 12 取消战争成功

    releasePrint("handle_MSG_SC_GUILD_MSG", netPkg:GetP0(), netPkg:GetBodyStr())
    local recog = netPkg:GetP0()
    if recog == 0 then
        -- 标记是否拥有行会
        self:SetJoinGuild(true)
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_CREATE_SUCCESS)

        -- 创建行会
        self._create = true

    elseif recog == 1 then
        -- 行会信息 JSON 
        local jsonData = netPkg:GetJsonData()
        local lastRank = self:GetUserRank()
        local lastGuildID = self:GetGuildID()
        local lastHaveGuild = self:IsJoinGuild()
        if jsonData then
            local isAble = next(jsonData) ~= nil

            -- 标记是否拥有行会
            self:SetJoinGuild(isAble)

            -- 队员称号
            self:SetGuildTitle(jsonData)

            -- 行会信息
            self._guildInfo = jsonData
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_MAIN_INFO)
        
            -- 
            self._memberList = jsonData.MemList or {}
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST)

            if not self._isInitGuildDataFinish then -- 语音初始化
                self:SetInitDataFinish(true)
            elseif self._create then
                self:VoiceCreateGuild()
            elseif self._joinSuccess then
                self:VoiceJoinGuild()
            else
                if lastHaveGuild and lastGuildID == self:GetGuildID() then
                    if lastRank ~= self:GetUserRank() then -- 职位改变
                        self:VoiceRankChange()
                    end
                end

                if lastHaveGuild and lastGuildID ~= self:GetGuildID() then
                    self:VoiceLeaveGuild(lastGuildID)
                end
            end
        end
        self._create = false
        self._joinSuccess = false

    elseif recog == 2 then
        -- 邀请信息 格式 邀请行会GUID&行会名&邀请者
        local slices = G_GetSplitArray(netPkg:GetBodyStr(), "&")
        local data = {}
        data.guildID = slices[1] or ""
        data.guildName = slices[2] or ""
        data.masterName = slices[3] or ""
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_JOIN_INVITE, data)

    elseif recog == 3 then
        -- 标记是否拥有行会
        self:SetJoinGuild(true)

        self._joinSuccess = true
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_JOIN_SUCCESS)

    elseif recog == 4 then
        -- 下发申请加入行会列表 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            self._applyGuildList = jsonData.List or {}
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_APPLYLIST, self._applyGuildList)
        end

    elseif recog == 5 then
        -- 5 下发行会成员列表 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            self._memberList = jsonData.MemList or {}
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_MEMBER_LIST)
        end

    elseif recog == 6 then 
        --  下发申请联盟列表 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            self._allyApplyList = jsonData.InviteList or {}
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_APPLY_ALLY_LIST)
            --{GuildID, GuildName, InviteTime}
        end

    elseif recog == 7 or recog == 8 then
        -- 7 下发联盟战争列表 JSON
        -- 8 用户登录自动下发行会战争联盟列表 JSON [增加也下发]
        self._guildWarList = {}
        self._guildWarList = {}
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            -- dump(jsonData, "==================联盟战争列表" .. recog)
            -- 战争列表
            local warList = jsonData.War or {}
            for _, info in ipairs(warList) do
                local guildID = info.GuildID
                if self._worldGuild and self._worldGuild[guildID] then
                    self._worldGuild[guildID].WarTick = info.WarAllyTick
                    self._worldGuild[guildID].WarTime = info.WarAllyTime
                
                    self._guildWarList[guildID] = self._worldGuild[guildID]
                else
                    self._guildWarList[guildID] = {WarTick = info.WarAllyTick, WarTime = info.WarAllyTime}
                end
            end

            -- 联盟列表
            local warList = jsonData.All or {}
            for _, info in ipairs(warList) do
                local guildID = info.GuildID
                if self._worldGuild and self._worldGuild[guildID] then
                    self._worldGuild[guildID].AllyTick = info.WarAllyTick
                    self._worldGuild[guildID].AllyTime = info.WarAllyTime

                    self._guildAllyList[guildID] = self._worldGuild[guildID]
                else
                    self._guildAllyList[guildID] = {AllyTick = info.WarAllyTick, AllyTime = info.WarAllyTime}
                end
            end

            SLBridge:onLUAEvent(LUA_EVENT_GUILD_ALLY_WAR_LIST)
            if self._addWarAllyGuildID then
                SLBridge:onLUAEvent(LUA_EVENT_GUILD_ALL_WAR_UPDATE, self._addWarAllyGuildID)

                local diffData = {[self._addWarAllyGuildID] = true}
                diffData[self:GetGuildID()] = true
                for guildID, data in pairs(self._guildAllyList) do
                    diffData[guildID] = true
                end
                global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, diffData)
                self._addWarAllyGuildID = nil
            end
        end

    elseif recog == 9 then
        -- 9 增加联盟或者战争 Param = 0 联盟 1 = 战争 body = 行会GUID
        local guildID = netPkg:GetBodyStr()
        releasePrint("9 增加联盟或者战争", guildID, netPkg:GetP1())
        local param = netPkg:GetP1()
        self._addWarAllyGuildID = guildID

    elseif recog == 10 then
        -- 10 删除联盟或者战争 Param = 0 联盟 1 = 战争 body = 行会GUID
        local guildID = netPkg:GetBodyStr()
        releasePrint("10 删除联盟或者战争", guildID, netPkg:GetP1())
        local param = netPkg:GetP1()
        if param == 1 then -- 战争
            if self._worldGuild and self._worldGuild[guildID] then
                self._worldGuild[guildID].WarTick = nil
                self._worldGuild[guildID].WarTime = nil
            end
            self._guildWarList[guildID] = nil
        elseif param == 0 then -- 联盟
            if self._worldGuild and self._worldGuild[guildID] then
                self._worldGuild[guildID].AllyTick = nil
                self._worldGuild[guildID].AllyTime = nil
            end
            self._guildAllyList[guildID] = nil
        end
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_ALLY_WAR_LIST)
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_ALL_WAR_UPDATE, guildID)

        local diffData = {[guildID] = true}
        diffData[self:GetGuildID()] = true
        if param == 1 then  -- 取消战争刷新同盟显示
            for guildID, data in pairs(self._guildAllyList) do
                diffData[guildID] = true
            end
        end
        global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, diffData)

    elseif recog == 11 then
        releasePrint("==取消联盟成功====================")
    elseif recog == 12 then
        releasePrint("==取消战争成功=====================")
    elseif recog == 13 then
        -- 13 删除成员成功  body = 成员名称
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_SUB_MEMBER_SUCCESS, netPkg:GetBodyStr())

    elseif recog == 14 then
        -- 14 下发全部行会 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            self._guildList = jsonData.List or {}
            self._worldGuild = {}
            if next(self._guildList) then
                for _, info in ipairs(self._guildList) do
                    local guildID = info.GuildID
                    if guildID then
                        self._worldGuild[guildID] = info

                        if self._guildWarList[guildID] then
                            self._worldGuild[guildID].WarTick = self._guildWarList[guildID].WarTick
                            self._worldGuild[guildID].WarTime = self._guildWarList[guildID].WarTime
                        end

                        if self._guildAllyList[guildID] then
                            self._worldGuild[guildID].AllyTick = self._guildAllyList[guildID].AllyTick
                            self._worldGuild[guildID].AllyTime = self._guildAllyList[guildID].AllyTime
                        end
                    end
                end
            end
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_WORLDLIST)
            -- dump(self._worldGuild, "世界行会列表+++++++++++++++")
        end

    elseif recog == 15 then
        -- 15 下发行会公告 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            -- SLBridge:onLUAEvent(LUA_EVENT_GUILD_QUERY_NOTICE, jsonData)
        end

    elseif recog == 16 then
        -- 16 下发申请加入行会信息  body = 申请人名称
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_MEMBER_APPLY, netPkg:GetBodyStr())

    elseif recog == 17 then
        -- 设置成员职位成功
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_APPOINT_RANK_SUCCESS)

    elseif recog == 18 then
        -- 18 被踢出行会

        local lastGuildID = self:GetGuildID()
        -- 标记是否拥有行会
        self:SetJoinGuild(false) 
        self:RequestGuildInfo()
        self:ClearData()
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_KICK_OUT)

        self:VoiceLeaveGuild(lastGuildID)

    elseif recog == 19 then
        -- 主动退出行会

        local lastGuildID = self:GetGuildID()
        -- 标记是否拥有行会
        self:SetJoinGuild(false) 
        self:RequestGuildInfo()
        self:ClearData()
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_QUIT_SUCCESS)

        self:VoiceLeaveGuild(lastGuildID)

    elseif recog == 20 then
        -- 20 返回自动加入行会标识 Param = 0 关闭 Param = 1 开启
        local p1 = netPkg:GetP1()
        self._guildInfo.AutoJoin = p1
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_AUTO_JOIN_STATE, self:GetAutoJoin())

    elseif recog == 21 then
        -- 21 返回管理状态 JSON
        local jsonData = netPkg:GetJsonData()
        if jsonData then
            self._guildInfo.State = jsonData
            SLBridge:onLUAEvent(LUA_EVENT_GUILD_PERMISSION, jsonData)
        end

    elseif recog == 22 then
        -- 22 返回设置管理状态 Param = Idx 0 设置职位 1 设置公告 2 允许入会 3 允许删除 nTag = 1 开启 0 关闭
        local p1 = netPkg:GetP1()
        local p2 = netPkg:GetP2()
        self._guildInfo.State = self._guildInfo.State or {}
        self._guildInfo.State[p1+1] = p2 == 1
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_PERMISSION, self._guildInfo.State)

    elseif recog == 23 then
        -- 23 公告内容编辑成功返回
        self._guildInfo.Notice = netPkg:GetBodyStr() or ""
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_NOTICE_UPDATE, self._guildInfo.Notice)

    elseif recog == 24 then
        -- 24 你所在的行会已经解散

        local lastGuildID = self:GetGuildID()
        -- 标记是否拥有行会
        self:SetJoinGuild(false)
        self:RequestGuildInfo()
        self:ClearData()
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_DISSOLVE)

        self:VoiceDismissGuild(lastGuildID)

    elseif recog == 25 then
        -- 24 申请联盟提示信息 格式 申请行会名称&申请行会ID&申请人名称&申请人ID Param = 时间
        local strList = G_GetSplitArray(netPkg:GetBodyStr(), "&")
        local data = {}
        data.guildName = strList[1]
        data.guildId = strList[2]
        data.allyTime = netPkg:GetP1()
        SLBridge:onLUAEvent(LUA_EVENT_GUILD_ALLY_APPLY, data)

    end
end

-- 沙巴克开启关闭 以及 沙巴克行会的关系列表
function GuildProxy:handle_MSG_SC_SHABAKEGUILD_INFO(msg)
    local param = msg:GetP0()
    local jsonData = msg:GetJsonData() or {}

    if self._guildShaBaKeID ~= jsonData.Castle then
        self._guildShaBaKeAllyList = {}
        self._guildShaBaKeWarList = {}
    end
    
    self._guildShaBaKeID = jsonData.Castle

    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    MapProxy:SetShaBaKeOpen(param == 1)

    local diffData = {}
    self:SetShaBaKeGuildAllyRelation(jsonData.GuildAllList, diffData)
    self:SetShaBaKeGuildWarRelation(jsonData.GuildWarList, diffData)

    global.Facade:sendNotification(global.NoticeTable.RefreshGuildActorColor, diffData)
end

function GuildProxy:RegisterMsgHandler()
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_GUILD_OPERATE, handler(self, self.handle_MSG_SC_GUILD_OPERATE))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_GUILD_MSG, handler(self, self.handle_MSG_SC_GUILD_MSG))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_SHABAKEGUILD_INFO,  handler(self, self.handle_MSG_SC_SHABAKEGUILD_INFO))
end

return GuildProxy
--endregion
