-- 一些废弃的SL方法、元变量，但是为了兼容老版本，将方法放到这里
--tip
local function deprecatedTip(old_name,new_name)
    if not SL._DEBUG then
        return nil
    end
    SL:Print("\n********************************* \n"..old_name.." was deprecated please use ".. new_name .. " instead.\n*********************************")
end

local function InitDeprecatedGetValue()
    MetaValueGetDef["MAIN_ACTOR_ID"] = function()
        deprecatedTip("MAIN_ACTOR_ID", "USER_ID")
        return MetaValueGetDef["USER_ID"]()
    end
    -- TXT $STM(...) 拆解元变量用
    MetaValueGetDef["USERNAME"] = function()
        return MetaValueGetDef["USER_NAME"]()
    end
    MetaValueGetDef["WINPLAYMODE"] = function()
        deprecatedTip("WINPLAYMODE", "IS_PC_OPER_MODE")
        return MetaValueGetDef["IS_PC_OPER_MODE"]()
    end
    MetaValueGetDef["IS_WIN_PLAY_MODE"] = function()
        deprecatedTip("IS_WIN_PLAY_MODE", "IS_PC_OPER_MODE")
        return MetaValueGetDef["IS_PC_OPER_MODE"]()
    end


    MetaValueGetDef["ATT_BY_TYPE"] = function(param)
        deprecatedTip("ATT_BY_TYPE", "CUR_ABIL_BY_ID")
        return MetaValueGetDef["CUR_ABIL_BY_ID"](param)
    end
    MetaValueGetDef["H.ATT_BY_TYPE"] = function(param)
        deprecatedTip("H.ATT_BY_TYPE", "H.CUR_ABIL_BY_ID")
        return MetaValueGetDef["H.CUR_ABIL_BY_ID"](param)
    end

    MetaValueGetDef["INTERNAL_FORCE"] = function()
        deprecatedTip("INTERNAL_FORCE", "SL:GetValue(\"CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_Value)")
        return SL:GetValue("CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_Value)
    end
    MetaValueGetDef["H.INTERNAL_FORCE"] = function()
        deprecatedTip("H.INTERNAL_FORCE", "SL:GetValue(\"H.CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_Value)")
        return SL:GetValue("H.CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_Value)
    end
    MetaValueGetDef["INTERNAL_MAXFORCE"] = function()
        deprecatedTip("INTERNAL_MAXFORCE", "SL:GetValue(\"MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_Value)")
        return SL:GetValue("MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_Value)
    end
    MetaValueGetDef["H.INTERNAL_MAXFORCE"] = function()
        deprecatedTip("H.INTERNAL_MAXFORCE", "SL:GetValue(\"H.MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_Value)")
        return SL:GetValue("H.MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_Value)
    end
    MetaValueGetDef["INTERNAL_EXP"] = function()
        deprecatedTip("INTERNAL_EXP", "SL:GetValue(\"CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_EXP)")
        return SL:GetValue("CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_EXP)
    end
    MetaValueGetDef["H.INTERNAL_EXP"] = function()
        deprecatedTip("H.INTERNAL_EXP", "SL:GetValue(\"H.CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_EXP)")
        return SL:GetValue("H.CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_EXP)
    end
    MetaValueGetDef["INTERNAL_MAXEXP"] = function()
        deprecatedTip("INTERNAL_MAXEXP", "SL:GetValue(\"MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_EXP)")
        return SL:GetValue("MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_EXP)
    end
    MetaValueGetDef["H.INTERNAL_MAXEXP"] = function()
        deprecatedTip("H.INTERNAL_MAXEXP", "SL:GetValue(\"H.MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_EXP)")
        return SL:GetValue("H.MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_EXP)
    end
    MetaValueGetDef["INTERNAL_DZ_CURVALUE"] = function()
        deprecatedTip("INTERNAL_DZ_CURVALUE", "SL:GetValue(\"CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_DZValue)")
        return SL:GetValue("CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_DZValue)
    end
    MetaValueGetDef["H.INTERNAL_DZ_CURVALUE"] = function()
        deprecatedTip("H.INTERNAL_DZ_CURVALUE", "SL:GetValue(\"H.CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_DZValue)")
        return SL:GetValue("H.CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_DZValue)
    end
    MetaValueGetDef["INTERNAL_DZ_MAXVALUE"] = function()
        deprecatedTip("INTERNAL_DZ_MAXVALUE", "SL:GetValue(\"MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_DZValue)")
        return SL:GetValue("MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_DZValue)
    end
    MetaValueGetDef["H.INTERNAL_DZ_MAXVALUE"] = function()
        deprecatedTip("H.INTERNAL_DZ_MAXVALUE", "SL:GetValue(\"H.MAX_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_DZValue)")
        return SL:GetValue("H.MAX_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_DZValue)
    end
    MetaValueGetDef["INTERNAL_LEVEL"] = function()
        deprecatedTip("INTERNAL_LEVEL", "SL:GetValue(\"CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_LEVEL)")
        return SL:GetValue("CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_LEVEL)
    end
    MetaValueGetDef["H.INTERNAL_LEVEL"] = function()
        deprecatedTip("H.INTERNAL_LEVEL", "SL:GetValue(\"H.CUR_ABIL_BY_ID\", GUIDefine.AttTypeTable.Internal_LEVEL)")
        return SL:GetValue("H.CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_LEVEL)
    end
    MetaValueGetDef["N_MAX_BAG"] = function()
        deprecatedTip("N_MAX_BAG", "STROAGE_OPEN_SIZE")
        return MetaValueGetDef["STROAGE_OPEN_SIZE"]()
    end
    MetaValueGetDef["CHAT_CHANNEL_ISRECEIVE"] = function(param)
        deprecatedTip("CHAT_CHANNEL_ISRECEIVE", "CHAT_CHANNEL_IS_RECEIVE")
        return MetaValueGetDef["CHAT_CHANNEL_IS_RECEIVE"](param)
    end
    MetaValueGetDef["DROP_TYPE_ISRECEIVE"] = function(param)
        deprecatedTip("DROP_TYPE_ISRECEIVE", "CHAT_DROP_TYPE_IS_RECEIVE")
        return MetaValueGetDef["CHAT_DROP_TYPE_IS_RECEIVE"](param)
    end
    MetaValueGetDef["TEAM_COUNT"] = function()
        deprecatedTip("TEAM_COUNT", "TEAM_MEMBER_COUNT")
        return MetaValueGetDef["TEAM_MEMBER_COUNT"]()
    end
    MetaValueGetDef["TEAM_MAC_COUNT"] = function()
        deprecatedTip("TEAM_MAC_COUNT", "TEAM_MEMBER_MAX_COUNT")
        return MetaValueGetDef["TEAM_MEMBER_MAX_COUNT"]()
    end
    MetaValueGetDef["H_MAX_BAG"] = function()
        deprecatedTip("H_MAX_BAG", "HERO_MAX_BAG")
        return MetaValueGetDef["HERO_MAX_BAG"]()
    end
    MetaValueGetDef["BAG_PAGE_CUR"] = function()
        deprecatedTip("BAG_PAGE_CUR", "BAG_CUR_PAGE")
        return MetaValueGetDef["BAG_CUR_PAGE"]()
    end
    MetaValueGetDef["ACTIVATE_TITLE"] = function()
        deprecatedTip("ACTIVATE_TITLE", "TITLE_ACTIVATE_ID")
        return MetaValueGetDef["TITLE_ACTIVATE_ID"]()
    end
    MetaValueGetDef["H.ACTIVATE_TITLE"] = function()
        deprecatedTip("H.ACTIVATE_TITLE", "H.TITLE_ACTIVATE_ID")
        return MetaValueGetDef["H.TITLE_ACTIVATE_ID"]()
    end
    MetaValueGetDef["L.M.ACTIVATE_TITLE"] = function()
        deprecatedTip("L.M.ACTIVATE_TITLE", "L.M.TITLE_ACTIVATE_ID")
        return MetaValueGetDef["L.M.TITLE_ACTIVATE_ID"]()
    end
    MetaValueGetDef["LOOK_USER_ID"] = function()
        deprecatedTip("LOOK_USER_ID", "LOOK_TARGET_ID")
        return MetaValueGetDef["LOOK_TARGET_ID"]()
    end
    MetaValueGetDef["LOOK_USER_NAME"] = function()
        deprecatedTip("LOOK_USER_NAME", "LOOK_TARGET_NAME")
        return MetaValueGetDef["LOOK_TARGET_NAME"]()
    end
    MetaValueGetDef["LOOK_USER_NAME_COLOR"] = function()
        deprecatedTip("LOOK_USER_NAME_COLOR", "LOOK_TARGET_NAME_COLOR")
        return MetaValueGetDef["LOOK_TARGET_NAME_COLOR"]()
    end
    MetaValueGetDef["STROAGE_OPEN_SIZE"] = function()
        deprecatedTip("STROAGE_OPEN_SIZE", "STORAGE_OPEN_SIZE")
        return MetaValueGetDef["STORAGE_OPEN_SIZE"]()
    end
    MetaValueGetDef["SOCIAL_IS_BLICKLIST"] = function(param)
        deprecatedTip("SOCIAL_IS_BLICKLIST", "SOCIAL_IS_BLACKLIST")
        return MetaValueGetDef["SOCIAL_IS_BLACKLIST"](param)
    end
    MetaValueGetDef["SOCIAL_IS_BLICKLIST_BY_UID"] = function(param)
        deprecatedTip("SOCIAL_IS_BLICKLIST_BY_UID", "SOCIAL_IS_BLACKLIST_BY_UID")
        return MetaValueGetDef["SOCIAL_IS_BLACKLIST_BY_UID"](param)
    end

end

local function InitDeprecatedSetValue()

    MetaValueSetDef["DROP_TYPE_ISRECEIVE"] = function(type, value)
        deprecatedTip("DROP_TYPE_ISRECEIVE", "CHAT_DROP_TYPE_IS_RECEIVE")
        return SL:SetValue("CHAT_DROP_TYPE_IS_RECEIVE", type, value)
    end

    MetaValueSetDef["BOS_REMIND_VALUE"] = function(param1)
        deprecatedTip("BOS_REMIND_VALUE", "SETTING_BOSS_REMIND_VALUE")
        return SL:SetValue("SETTING_BOSS_REMIND_VALUE", param1)
    end

    MetaValueSetDef["SUPEREQUIP_SHOW"] = function(allow)
        deprecatedTip("SUPEREQUIP_SHOW", "PLAYER_SUPEREQUIP_SHOW")
        return SL:SetValue("PLAYER_SUPEREQUIP_SHOW", allow)
    end
    
end

local function InitDeprecatedSLFunctions()
    function SL:OpenSelectListUI(...)
        deprecatedTip("SL:OpenSelectListUI", "UIOperator:OpenCommonSelectListUI")
        UIOperator:OpenCommonSelectListUI(...)
    end
    function SL:SendGMMsgToChat(...)
        deprecatedTip("SL:SendGMMsgToChat", "SL:RequestSendChatGMMsg")
        SL:RequestSendChatGMMsg(...)
    end

    function SL:SendSystemMsgToChat(data)
        deprecatedTip("SL:SendSystemMsgToChat(data)", "SL:ShowSystemChat(Msg, FColor, BColor)")
        SL:ShowSystemChat(data.Msg, data.FColor, data.BColor)
    end

    function SL:SendInputMsgToChat(str)
        deprecatedTip("SL:SendInputMsgToChat(str)", "SL:onLUAEvent(LUA_EVENT_CHAT_REPLACE_INPUT, str)")
        SL:onLUAEvent(LUA_EVENT_CHAT_REPLACE_INPUT, str)
    end

    function SL:PrivateChatWithTarget(targetId, targetName)
        if not targetId or not targetName then
            return
        end
        deprecatedTip("SL:PrivateChatWithTarget(targetId, targetName)", "SL:onLUAEvent(LUA_EVENT_CHAT_PRIVATE_TARGET, {name = targetName, uid = targetId}")
        SL:onLUAEvent(LUA_EVENT_CHAT_PRIVATE_TARGET, {name = targetName, uid = targetId})
    end

    function SL:RequestSetTeamPermitStatus(status)
        deprecatedTip("SL:RequestSetTeamPermitStatus(status)", "SL:SetValue(\"TEAM_STATUS_PERMIT\", status)")
        SL:SetValue("TEAM_STATUS_PERMIT", status)
    end

    function SL:RequestRefuseTeamInvite(...)
        deprecatedTip("SL:RequestRefuseTeamInvite", "SL:RequestTeamInviteRefuse")
        SL:RequestTeamInviteRefuse(...)
    end
    function SL:RequestAgreeTeamInvite(...)
        deprecatedTip("SL:RequestAgreeTeamInvite", "SL:RequestTeamInviteAgree")
        SL:RequestTeamInviteAgree(...)
    end
    function SL:RequestApplyRefuse(...)
        deprecatedTip("SL:RequestApplyRefuse", "SL:RequestTeamApplyRefuse")
        SL:RequestTeamApplyRefuse(...)
    end
    function SL:RequestApplyAgree(...)
        deprecatedTip("SL:RequestApplyAgree", "SL:RequestTeamApplyAgree")
        SL:RequestTeamApplyAgree(...)
    end
    function SL:RequestApplyData(...)
        deprecatedTip("SL:RequestApplyData", "SL:RequestTeamApplyData")
        SL:RequestTeamApplyData(...)
    end

    function SL:RequestAuctionPutin(...)
        deprecatedTip("SL:RequestAuctionPutin", "SL:RequestAuctionPutInItem")
        SL:RequestAuctionPutInItem(...)
    end
    function SL:RequestAuctionRePutin(...)
        deprecatedTip("SL:RequestAuctionRePutin", "SL:RequestAuctionRePutInItem")
        SL:RequestAuctionRePutInItem(...)
    end
    function SL:RequestAuctionPutout(...)
        deprecatedTip("SL:RequestAuctionPutout", "SL:RequestAuctionPutOutItem")
        SL:RequestAuctionPutOutItem(...)
    end

    function SL:RequestAucPointOpen(...)
        deprecatedTip("SL:RequestAucPointOpen", "SL:RequestMeridianAcuPointOpen")
        SL:RequestMeridianAcuPointOpen(...)
    end
    function SL:RequestNGHudShow(...)
        deprecatedTip("SL:RequestNGHudShow", "SL:RequestInternalHudShow")
        SL:RequestInternalHudShow(...)
    end
    function SL:ClearLaunchSkill(...)
        deprecatedTip("SL:ClearLaunchSkill", "SL:ClearLaunchFirstSkill")
        SL:ClearLaunchFirstSkill(...)
    end
    function SL:RequestPutInItem(...)
        deprecatedTip("SL:RequestPutInItem", "SL:RequestTradePutInItem")
        SL:RequestTradePutInItem(...)
    end

    function SL:GetMetaValue(...)
        return SL:GetValue(...)
    end
    function SL:SetMetaValue(...)
        return SL:SetValue(...)
    end
end

local function InitDeprecatedSLEvents()
    LUA_EVENT_LEVELCHANGE               = "LUA_EVENT_LEVEL_CHANGE"                  -- 等级改变
    LUA_EVENT_HERO_LEVELCHANGE          = "LUA_EVENT_HERO_LEVEL_CHANGE"             -- 英雄等级改变
    LUA_EVENT_REINLEVELCHANGE           = "LUA_EVENT_REINLEVEL_CHANGE"              -- 转生等级改变
    LUA_EVENT_HPMPCHANGE                = "LUA_EVENT_HPMP_CHANGE"                   -- HP/MP改变
    LUA_EVENT_HERO_HPMPCHANGE           = "LUA_EVENT_HERO_HPMPCHANGE"               -- 英雄HP/MP改变
    LUA_EVENT_EXPCHANGE                 = "LUA_EVENT_EXP_CHANGE"                    -- EXP改变
    LUA_EVENT_HERO_EXPCHANGE            = "LUA_EVENT_HERO_EXP_CHANGE"               -- 英雄EXP改变
    LUA_EVENT_BATTERYCHANGE             = "LUA_EVENT_BATTERY_CHANGE"                -- 电池电量改变
    LUA_EVENT_NETCHANGE                 = "LUA_EVENT_NET_CHANGE"                    -- 网络状态改变
    LUA_EVENT_WEIGHTCHANGE              = "LUA_EVENT_WEIGHT_CHANGE"                 -- 负重改变
    LUA_EVENT_PKMODECHANGE              = "LUA_EVENT_PKMODE_CHANGE"                 -- pk模式改变

    LUA_EVENT_MAPINFOCHANGE             = "LUA_EVENT_MAPINFOCHANGE"                 -- 切换地图(不同地图)
    LUA_EVENT_MAPINFOINIT               = "LUA_EVENT_MAPINFOINIT"                   -- 初始化地图

    LUA_EVENT_MONEYCHANGE               = "LUA_EVENT_MONEY_CHANGE"                  -- 货币变化时

    LUA_EVENT_ADDFIREND                 = "LUA_EVENT_SOCIAL_FRIEND_ADD_SUCCESS"     -- 添加好友
    LUA_EVENT_REMFIREND                 = "LUA_EVENT_SOCIAL_FRIEND_DEL_SUCCESS"     -- 删除好友

    LUA_EVENT_REF_ITEM_LIST             = "LUA_EVENT_BAG_ITEM_LIST_REFRESH"         -- 刷新背包道具列表
    LUA_EVENT_REF_HERO_ITEM_LIST        = "LUA_EVENT_HERO_BAG_ITEM_LIST_REFRESH"    -- 刷新英雄背包道具列表

    LUA_EVENT_SETTING_CAHNGE            = "LUA_EVENT_SETTING_CHANGE"                -- 设置项发生变化
    LUA_EVENT_TARGET_CAHNGE             = "LUA_EVENT_TARGET_CHANGE"                 -- 目标发生变化
    LUA_EVENT_HERO_ANGER_CAHNGE         = "LUA_EVENT_HERO_ANGER_CHANGE"             -- 英雄怒气改变


    LUA_EVENT_TRADE_MONEY_CHANGE        = "LUA_EVENT_TRADE_TARGET_MONEY_CHANGE"     -- 交易货币改变
    LUA_EVENT_TRADE_MY_MONEY_CHANGE     = "LUA_EVENT_TRADE_MYSELF_MONEY_CHANGE"     -- 交易自己货币改变
    
    LUA_EVENT_ASSIST_MISSION_TOP        = "LUA_EVENT_TASK_TO_TOP"                   -- 主界面-辅助-任务置顶
    LUA_EVENT_ASSIST_MISSION_ADD        = "LUA_EVENT_TASK_ADD"                      -- 主界面-辅助-任务增加
    LUA_EVENT_ASSIST_MISSION_CHANGE     = "LUA_EVENT_TASK_CHANGE"         			-- 主界面-辅助-任务改变
    LUA_EVENT_ASSIST_MISSION_REMOVE     = "LUA_EVENT_TASK_DEL"                      -- 主界面-辅助-任务移除

    LUA_EVENT_HERO_BAG_ITEM_CAHNGE      = "LUA_EVENT_HERO_BAG_ITEM_CHANGE"

    LUA_EVENT_GUILDE_ALLY_APPLY_UPDATE  = "LUA_EVENT_GUILD_APPLY_ALLY_LIST"
    LUA_EVENT_MAINBUFFUPDATE            = "LUA_EVENT_MAINPLAYER_BUFF_UPDATE"
    LUA_EVENT_BUFFUPDATE                = "LUA_EVENT_BUFF_UPDATE"
    LUA_EVENT_JOINTEAM                  = "LUA_EVENT_SOCIAL_TEAM_JOIN"
    LUA_EVENT_LEAVETEAM                 = "LUA_EVENT_SOCIAL_TEAM_LEAVE"     
    LUA_EVENT_HERO_LOGIN_OROUT          = "LUA_EVENT_HERO_LOGIN_OROUT"
    LUA_EVENT_PLAYER_TITLE_CHANGE       = "LUA_EVENT_TITLE_REFRESH"
    LUA_EVENT_SKILL_CD_TIME_CHANGE      = "LUA_EVENT_SKILL_CD_CHANGE"

    LUA_EVENT_TARDE_BUBBLE_TIPS_CHANGE  = "LUA_EVENT_TRADE_BUBBLE_TIPS_CHANGE"
    LUA_EVENT_TRADE_TRADER_TIEM_CHANGE  = "LUA_EVENT_TRADE_TRADER_ITEM_CHANGE"
    LUA_EVENT_TRADE_MYSEFL_ITEM_CHANGE  = "LUA_EVENT_TRADE_MYSELF_ITEM_CHANGE"
end

local function InitDeprecatedGUIFunctions()
    function GUI:ItemShow_setMoveEable(...)
        deprecatedTip("GUI:ItemShow_setMoveEable", "GUI:ItemShow_setMoveEnable")
        GUI:ItemShow_setMoveEnable(...)
    end

    function GUI:TimeLine_BezierTo(time, ...)
        deprecatedTip("GUI:TimeLine_BezierTo", "GUI:Timeline_BezierTo")
        return cc.BezierTo:create(time, { ... })
    end
end

InitDeprecatedGetValue()
InitDeprecatedSetValue()
InitDeprecatedSLFunctions()
InitDeprecatedSLEvents()
InitDeprecatedGUIFunctions()