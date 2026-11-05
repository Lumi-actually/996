local DebugProxy = requireProxy("DebugProxy")
local VoiceManagerProxy = class("VoiceManagerProxy", DebugProxy)
VoiceManagerProxy.NAME = global.ProxyTable.VoiceManagerProxy

VoiceManagerProxy.VOICE_TYPE = {
    INIT                    = 1,            --初始化
    GUILD_CHANGE            = 2,            --行会更变
    GUILD_ROLE_CHANGE       = 3,            --行会角色更变
    TEAM                    = 4,            --组队操作
    EXIT                    = 5,            --游戏退出
}

-- 游戏+区服唯一标识
local function GetUniqueId()
    local loginProxy    = global.Facade:retrieveProxy( global.ProxyTable.LoginProxy )
    local currModule    = global.L_ModuleManager:GetCurrentModule()
    local gameid        = currModule:GetOperID()
    local serverId      = loginProxy:GetSelectedServerId()
    return string.format("%s%s",gameid,serverId)
end

function VoiceManagerProxy:ctor()
    VoiceManagerProxy.super.ctor(self)
end

--[[
    GameInfo {
        // 游戏id
        var gameId: Int = 0
        // 游戏名称
        var gameName: String = ""
        // 区服名
        var gameServer: String = ""
        // 行会id
        var guildId: Int = 0
        // 行会名称
        var guildName: String = ""
        // 头像
        var headImg: String = ""
        // 角色id 0会长 1副会长 2其他
        var roleId: Int = 2
        // 区服id
        var serverId: Int = 0
        // 游戏+区服唯一标识
        var uniqueId: String = ""
        // 人员id
        var userId: Int = 0
        // 用户昵称
        var userName: String = ""
        // 组队角色id 0队长 2其他 非必传
        var teamRoleId: Int = 2
        // 组队id，非必传
        var teamId: Int = 0
    }
]]

function VoiceManagerProxy:VoiceInit(msgData)
    local data = {
        voiceType = VoiceManagerProxy.VOICE_TYPE.INIT         -- 初始化类型
    }

    local AuthProxy             = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local loginProxy            = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    local GuildProxy            = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    local propertyProxy         = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)

    local isBoxLogin    = global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") and global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1 --盒子登录
    data.enterType      = isBoxLogin and 1 or 0 -- 0 游戏   1 盒子
    -- data.emOptions      = nil  --环信初始化配置,非必传
    if isBoxLogin then
        data.boxUserId  = AuthProxy:GetUID()
    end

    local GameInfo      = {} --游戏相关信息  必传
    local currModule    = global.L_ModuleManager:GetCurrentModule()
    local gameid        = currModule:GetOperID() 
    GameInfo.gameId     = gameid
    GameInfo.gameName   = currModule:GetName()
    GameInfo.gameServer = loginProxy:GetSelectedServerName()
    GameInfo.guildId    = GuildProxy:GetGuildID()
    GameInfo.guildName  = GuildProxy:GetGuildName()
    GameInfo.headImg    = ""
    local guildJob      = GuildProxy:GetUserRank() or 0
    GameInfo.roleId     = not GuildProxy:IsGuildAdmin() and 2 or guildJob
    GameInfo.serverId   = loginProxy:GetSelectedServerId()
    GameInfo.uniqueId   = GetUniqueId()  -- 游戏+区服唯一标识
    GameInfo.userId     = global.gamePlayerController:GetMainPlayerID()
    GameInfo.userName   = propertyProxy:GetName()
    GameInfo.teamRoleId = ""
    GameInfo.teamId     = 0
    GameInfo.account    = AuthProxy:GetUID()
    GameInfo.guildNumber= GuildProxy:GetMemberCount()

    data.GameInfo       = GameInfo

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_Voice(data)
end

function VoiceManagerProxy:VoiceGuildChange(msgData)
    local data = {
        voiceType = VoiceManagerProxy.VOICE_TYPE.GUILD_CHANGE         -- 行会变更类型
    }
    
    local GuildProxy            = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)

    data.operatorType           = msgData.operatorType
    data.guildId                = msgData.guildId or GuildProxy:GetGuildID()
    data.uniqueId               = GetUniqueId()    -- 游戏+区服唯一标识
    data.userId                 = global.gamePlayerController:GetMainPlayerID()

    if msgData.operatorType == GuildProxy.ChangeType.CREATE then
        -- data.guildCreateTime = GuildProxy:GetGuildCreateTime()
        data.guildName       = GuildProxy:GetGuildName()
    end

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_Voice( data )
end

function VoiceManagerProxy:VoiceGuildRoleChange(msgData)
    local data = {
        voiceType = VoiceManagerProxy.VOICE_TYPE.GUILD_ROLE_CHANGE         -- 行会角色变更类型
    }

    local GuildProxy            = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)

    local guildJob              = GuildProxy:GetUserRank() or 0
    data.guildId                = GuildProxy:GetGuildID()
    data.roleId                 = not GuildProxy:IsGuildAdmin() and 2 or guildJob
    data.uniqueId               = GetUniqueId()   --游戏+区服唯一标识
    data.userId                 = global.gamePlayerController:GetMainPlayerID()

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_Voice(data)
end

function VoiceManagerProxy:VoiceTeam(msgData)
    local data = {
        voiceType = VoiceManagerProxy.VOICE_TYPE.TEAM         --组队操作
    }

    local TeamProxy             = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)

    data.guildId                = msgData.teamId or TeamProxy:GetTeamID() --队伍id
    data.operatorType           = msgData.operateType -- 0创建队伍  1解散队伍 2加入队伍 3离开队伍 4队长变更
    local job                   = msgData.myRank or TeamProxy:GetMyRank() --1 队长 0其它
    job                         = job == 1 and 0 or 2
    data.roleId                 = job --0队长 2其他
    data.uniqueId               = GetUniqueId() --游戏+区服唯一标识
    data.userId                 = msgData.teamUserId or global.gamePlayerController:GetMainPlayerID()

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_Voice(data)
end

function VoiceManagerProxy:VoiceExit(msgData)
    local data = {
        voiceType = VoiceManagerProxy.VOICE_TYPE.EXIT         --退出
    }

    local GuildProxy            = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    data.guildId                = GuildProxy:GetGuildID()
    data.uniqueId               = GetUniqueId() --游戏+区服唯一标识
    data.userId                 = global.gamePlayerController:GetMainPlayerID()

    local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
    NativeBridgeProxy:GN_Voice(data)
end

return VoiceManagerProxy
