local proxyUtils = requireUtil("proxyUtils")

-- param: actor / actorID
local GetActor = function(param)
    local actor = global.actorManager:GetActor(param)
    if not actor then
        return nil
    end
    return actor
end

function GetScreenSize()
    -- for 减少获取游戏屏幕尺寸的次数
    if not G_GameScreenSize then
        G_GameScreenSize = global.Director:getVisibleSize()
    end
    return G_GameScreenSize
end

function GetDeviceUniqueID()
    if global.isWindows then
        if not G_MAC_ADDRESS then
            G_MAC_ADDRESS = getMac()
        end
        return G_MAC_ADDRESS
    end
    return nil
end

local loginConfirmContent = [[抵制不良游戏，拒绝盗版游戏。
注意自我保护，谨防受骗上当。
适度游戏益脑，沉迷游戏伤身。
合理安排时间，享受健康生活。]]

MetaValueGetDef = {
    -- 游戏基础信息
    ["SCREEN_WIDTH"] = function()
        return GetScreenSize().width
    end,
    ["SCREEN_HEIGHT"] = function()
        return GetScreenSize().height
    end,
    ["SCREEN_SIZE"] = function()
        return GetScreenSize()
    end,
    -- 刘海屏信息 返回参数1：是否是刘海屏 返回参数2：{x=坐标x,y=坐标y,width=刘海宽,height=刘海高}
    ["NOTCH_PHONE_INFO"] = function()
        return CheckNotchPhone()
    end,
    ["DEVICE_IS_NOTCH_PHONE"] = function()
        return CheckNotchPhone()
    end,
    ["DEVICE_UNIQUE_ID"] = function()
        return GetDeviceUniqueID()
    end,
    ["PLATFORM"] = function()
        return global.Platform
    end,
    ["PLATFORM_ANDROID"] = function()
        return global.isAndroid
    end,
    ["PLATFORM_OHOS"] = function()
        return global.isOHOS
    end,
    ["PLATFORM_IOS"] = function()
        return global.isIOS
    end,
    ["PLATFORM_WINDOWS"] = function()
        return global.isWindows
    end,
    ["PLATFORM_MOBILE"] = function()
        return global.isMobile
    end,
    ["IS_PC_OPER_MODE"] = function()
        return global.isWinPlayMode
    end,
    ["CURRENT_OPERMODE"] = function()
        return global.CURRENT_OPERMODE
    end,
    ["PC_DESIGN_SIZE"] = function()
        return global.DesignSize_Win
    end,
    ["GAME_ID"] = function()
        return global.L_ModuleManager:GetCurrentModule():GetOperID()
    end,
    ["CHANNEL_ID"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetChannelID()
    end,
    ["PROMOTE_ID"] = function()
        -- 推广员ID / 后台推广包ID
        return global.L_GameEnvManager:GetGMName()
    end,
    ["PACKAGE_NAME"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetAPKPackageName()
    end,
    ["VERSION_NAME"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetAPKVersionName()
    end,
    ["VERSION_CODE"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetAPKVersionCode()
    end,
    ["IS_EMULATOR"] = function()
        return global.L_GameEnvManager:IsEmulator()
    end,
    ["FPS"] = function()
        return global.Director:getFrameRate()
    end,
    ["REVIEW_STATUS"] = function ()
        return global.L_GameEnvManager:IsReview()
    end,
    ["NET_TYPE"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetNetType() == 0 and 0 or 1
    end,
    ["BATTERY"] = function()
        local envProxy = global.Facade:retrieveProxy(global.ProxyTable.GameEnvironmentProxy)
        return envProxy:GetBatteryLevel()
    end,
    ["LOCAL_RES_VERSION"] = function()
        local currModule = global.L_ModuleManager:GetCurrentModule()
        return currModule:GetOriginVersion()
    end,
    ["REMOTE_RES_VERSION"] = function()
        local currModule = global.L_ModuleManager:GetCurrentModule()
        return currModule:GetRemoteVersion()
    end,
    ["REMOTE_GM_RES_VERSION"] = function()
        local currModule = global.L_ModuleManager:GetCurrentModule()
        local currentSubMod = currModule:GetCurrentSubMod()
        local versionStr = currentSubMod.GetRemoteVersion and currentSubMod:GetRemoteVersion() or ""
        return versionStr
    end,
    ["BOX996_LOGIN"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("isBoxLogin") == 1
    end,
    ["BOX996_APPVERSION"] = function()
        local appVersion = tostring(global.L_GameEnvManager:GetEnvDataByKey("boxVersion"))
        if appVersion then
            local stringArr = G_GetSplitArray(appVersion, ".")
            if #stringArr >= 3 then
                return tostring(stringArr[1]) .. "." .. tostring(stringArr[2]) .. "." .. tostring(stringArr[3])
            end
        end
        return "0"
    end,
    ["BOX_TEST_PLAY"] = function()
        local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
        if shiwan and tonumber(shiwan) == 1 then
            return true
        end
        return false
    end,
    ["CLOUD996_DEVICE"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("isCloudLogin")
    end,
    ["YIDUN_DATA"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("yd_data")
    end,
    ["SERVER_OPTION"] = function(param)
        return CHECK_SERVER_OPTION(param)
    end,
    ["GAME_DATA"] = function(param)
        return global.ConstantConfig[param]
    end,
    ["IS_SDK_LOGIN"] = function()
        local loginData = global.L_ModuleManager:GetCurrentModule():GetGameEnv():GetLoginData()
        if loginData and loginData.username and loginData.password then
            return true
        end
        return false
    end,
    -- 是否接入三方SDK
    ["IS_SDK_PAY"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy:IsSDKPay()
    end,
    -- M2是否禁止说话
    ["M2_FORBID_SAY"] = function(param)
        return IsForbidSay(param)
    end,
    -- M2是否禁止自定义取名
    ["M2_FORBID_NAME"] = function(param)
        return IsForbidName(param)
    end,
    ["COLOR_BY_ID"] = function(param)
        return GET_COLOR_BYID(param)
    end,
    ["I18N_STRING"] = function(param)
        if not param then
            return "I18N_STRING ERROR"
        end
        return GET_STRING(param)
    end,
    -- 功能类
    ["JOB_NAME_BY_ID"] = function(job)
        return GUIFunction:GetJobNameByID(job)
    end,
    --NP反外挂
    ["PC_NP_STATUS"] = function ()
        if not global.isWindows then
            return false
        end
        if global.isDebugMode or global.isGMMode then
            return false
        end
        if not NPProtect or not NPProtect.Inst or not NPProtect.GetNp then
            return false
        end
        return NPProtect:Inst():GetNp() and NPProtect:Inst():GetNpStatusFromCmd()
    end,
    -- 是否登录状态
    ["GAME_IN_LOGIN_STATE"] = function()
        return GET_GAME_STATE() == global.MMO.GAME_STATE_LOGIN
    end,
    -- PCY轴适配
    ["PC_POS_Y"] = function()
        local visibleSize = global.Director:getVisibleSize()
        return visibleSize.height - ((visibleSize.height - 150) / 2)
    end,
    -- 是否开启996客服
    ["IS_SHOW_MAUNAL_SERVICE"] = function()
        local ManualService996Proxy = global.Facade:retrieveProxy(global.ProxyTable.ManualService996Proxy)
        return ManualService996Proxy:IsShow()
    end,
    -- GM缓存目录
    ["GM_CACHE_RES_PATH"] = function()
        local module = global.L_ModuleManager:GetCurrentModule()
        local modulePath = module:GetSubModPath()
        local gmCachePath = global.WritablePath .. modulePath
        return gmCachePath
    end,
    ----
    -- 获取剪贴板文本
    ["CLIPBOARD_TEXT"] = function()
        if global.isWindows then
            if Win32BridgeCtl then
                return Win32BridgeCtl:Inst():getTextFromClipboard()
            end
            return ""
        else
            local NativeBridgeProxy = global.Facade:retrieveProxy(global.ProxyTable.NativeBridgeProxy)
            return NativeBridgeProxy:GetClipboardText()
        end
    end,


    -----------------------------------------------------------------------------
    -- 条件检测
    ["CONDITION"] = function(conditionID)
        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        return ConditionProxy:CheckConditionByID(conditionID)
    end,
    ["CONDITION_BY_STRING"] = function(conditionStr)
        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        return ConditionProxy:CheckCondition(conditionStr)
    end,

    -----------------------------------------------------------------------------
    -- 服务器信息
    ["SERVER_ID"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetSelectedServerId()
    end,
    ["SERVER_NAME"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetSelectedServerName()
    end,
    ["MAIN_SERVER_ID"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetMainSelectedServerId()
    end,
    -- 在跨服状态
    ["KFSTATE"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:IsKFState()
    end,
    -- 
    ["SERVER_TIME"] = function()
        return GetServerTime()
    end,
    -- 开服天数
    ["KFDAY"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetOpenDay()
    end,
    -- 开服时间戳
    ["OPEN_SERVER_TIME"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetOpenTime()
    end,
    -- 开服天数
    ["OPEN_SERVER_DAY"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetOpenDay()
    end,
    -- 合服次数
    ["MERGE_SERVER_COUNT"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetMergeCount()
    end,
    -- 合服时间戳
    ["MERGE_SERVER_TIME"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetMergeTime()
    end,
    -- 合区天数
    ["MERGE_SERVER_DAY"] = function()
        local ServerTimeProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerTimeProxy)
        return ServerTimeProxy:GetMergeDay()
    end,
    ---


    -----------------------------------------------------------------------------
    -- 账户信息
    ["UID"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy:GetUID()
    end,
    -- 登录角色信息
    ["LOGIN_ROLE_DATAS"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetAllRoleInfo()
    end,
    -- 可恢复角色信息
    ["LOGIN_RESTORE_ROLES_DATA"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetRestoreRoleInfo()
    end,
    -- 当前选择角色信息
    ["LOGIN_SELECT_ROLE_DATA"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetSelectedRole()
    end,
    -- 当前选择角色ID
    ["LOGIN_SELECT_ROLE_ID"] = function()
        local LoginProxy    = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return LoginProxy:GetSelectedRoleID()
    end,
    -- 是否试玩模式
    ["IS_VISITOR_MODE"] = function()
        return global.IsVisitor
    end,
    -- 登录角色是否自动执行
    ["LOGIN_IS_AUTO_BOOT"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("isAutoBoot")
    end,
    -- 登录账号
    ["LOGIN_ACCOUNT"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy:GetUsername()
    end,
    -- 登录密码
    ["LOGIN_PASSWORD"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy:GetPassword()
    end,
    -- 登录-确认页公告内容
    ["LOGIN_CONFIRM_CONTENT"] = function()
        return loginConfirmContent
    end,

    -----------------------------------------------------------------------------
    -- 道具信息
    ["MONEY"] = function(param)
        local itemIndex = nil
        if not param then
            return "ERROR MONEY "
        end
        if not tonumber(param) and string.find(param, ",") then
            local indexList = G_GetSplitArray(param, ",")
            local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
            local totalCount = 0
            for _, index in ipairs(indexList) do
                if index and tonumber(index) then
                    totalCount = totalCount + PayProxy:GetItemCount(tonumber(index))
                end
            end
            return tostring(totalCount)
        end
        if not tonumber(param) then
            local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
            itemIndex = MoneyProxy:GetMoneyIdByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR MONEY " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex)
        return tostring(count)
    end,
    ["MONEYEX"] = function(param)
        local itemIndex = nil
        if not param then
            return "ERROR MONEYEX "
        end
        if not tonumber(param) and string.find(param, ",") then
            local indexList = G_GetSplitArray(param, ",")
            local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
            local totalCount = 0
            for _, index in ipairs(indexList) do
                if index and tonumber(index) then
                    totalCount = totalCount + PayProxy:GetItemCount(tonumber(index))
                end
            end
            return string.formatnumberthousands(totalCount)
        end
        if not tonumber(param) then
            local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
            itemIndex = MoneyProxy:GetMoneyIdByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR MONEYEX " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex)
        return string.formatnumberthousands(count)
    end,
    ["MONEY_ASSOCIATED"] = function(param)
        local itemIndex = nil
        if not param then
            return "ERROR MONEY "
        end
        if not tonumber(param) and string.find(param, ",") then
            local indexList = G_GetSplitArray(param, ",")
            local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
            local totalCount = 0
            for _, index in ipairs(indexList) do
                if index and tonumber(index) then
                    totalCount = totalCount + PayProxy:GetItemCount(tonumber(index), true)
                end
            end
            return tostring(totalCount)
        end
        if not tonumber(param) then
            local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
            itemIndex = MoneyProxy:GetMoneyIdByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR MONEY " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex, true)
        return tostring(count)
    end,
    ["STD_ITEMS"] = function()
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemGMConfigData()
    end,
    ["ITEM_DATA"] = function(param)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemDataByIndex(param)
    end,
    ["ITEM_RESERVED_BY_INDEX"] = function(param)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemReservedByIndex(param)
    end,
    -- 弃用 .暂留
    ["ITEM_ARTICLE"] = function(index, type)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemArticle(index, type)
    end,
    -- 道具框默认缩放
    ["ITEM_SCALE"] = function()
        return global.isWinPlayMode and global.MMO.GOODSITEM_SCALE_WIN or global.MMO.GOODSITEM_SCALE
    end,
    -- 脚本用
    ["ITEMCOUNT"] = function(param)
        local itemIndex = nil
        if not param then
            return "ERROR ITEM COUNT "
        end
        if not tonumber(param) then
            local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
            itemIndex = ItemConfigProxy:GetItemIndexByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR ITEM COUNT " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex)
        return tostring(count)
    end,
    ["ITEM_COUNT"] = function(param, param2)
        local itemIndex = nil
        if not tonumber(param) then
            local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
            itemIndex = ItemConfigProxy:GetItemIndexByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return 0
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        return PayProxy:GetItemCount(itemIndex, param2)
    end,
    ["ITEM_NAME"] = function(param)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local itemInfo = ItemConfigProxy:GetItemDataByIndex(tonumber(param))
        return itemInfo.Name or "ERROR_ITEM_NAME"
    end,
    ["ITEM_INDEX_BY_NAME"] = function(param)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemIndexByName(param)
    end,
    ["ITEM_NAME_COLOR"] = function(param)
        local itemIndex = tonumber(param)
        if not itemIndex then
            return "ERROR_ITEM_COLOR_INDEX"
        end
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local itemInfo = ItemConfigProxy:GetItemDataByIndex(itemIndex)
        if not itemInfo or not next(itemInfo) then
            return "ERROR_ITEM_NAME"
        end

        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local itemName = ItemConfigProxy:GetItemNameByIndex(itemIndex)
        local colorhex = ItemConfigProxy:GetItemNameColor(itemIndex)
        return "<font color ='" .. colorhex .. "'  >" .. itemName .. "</font>"
    end,
    --道具名字颜色
    ["ITEM_NAME_COLOR_VALUE"] = function(param)
        local itemIndex = tonumber(param)
        if not itemIndex then
            return "ERROR_ITEM_COLOR_INDEX"
        end
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        local itemInfo = ItemConfigProxy:GetItemDataByIndex(itemIndex)
        if not itemInfo or not next(itemInfo) then
            return "ERROR_ITEM_NAME"
        end
        return ItemConfigProxy:GetItemNameColor(itemIndex)
    end,
    ["ITEM_NAME_COLORID"] = function(param)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemNameColorId(tonumber(param))
    end,
    -- 检查物品是否绑定
    ["ITEM_IS_BIND"] = function(param1, param2)
        return CheckItemisBind(param1, param2)
    end,
    ["TMONEY"] = function(param)
        if not param then
            return "ERROR TMONEY "
        end
        if not tonumber(param) and string.find(param, ",") then
            local indexList = G_GetSplitArray(param, ",")
            local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
            local totalCount = 0
            for _, index in ipairs(indexList) do
                if index and tonumber(index) then
                    totalCount = totalCount + PayProxy:GetItemCount(tonumber(index))
                end
            end
            return tostring(totalCount)
        end
        local itemIndex = nil
        if not tonumber(param) then
            local MoneyProxy = global.Facade:retrieveProxy(global.ProxyTable.MoneyProxy)
            itemIndex = MoneyProxy:GetMoneyIdByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR TMONEY " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex)
        return tostring(count)
    end,
    ["TITEMCOUNT"] = function(param)
        if not param then
            return "ERROR TITEM COUNT "
        end
        local itemIndex = nil
        if not tonumber(param) then
            local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
            itemIndex = ItemConfigProxy:GetItemIndexByName(param)
        end
        if tonumber(param) then
            itemIndex = tonumber(param)
        end
        if not itemIndex then
            return "ERROR TITEM COUNT " .. param
        end
        local PayProxy = global.Facade:retrieveProxy(global.ProxyTable.PayProxy)
        local count    = PayProxy:GetItemCount(itemIndex)
        return tostring(count)
    end,
    -- 属性ID对应战力配置表
    ["ATTR_POWER_CONFIG"] = function()
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetAttPowerConfig()
    end,


    -----------------------------------------------------------------------------
    -- 角色信息
    ["MAIN_PLAYER_IS_VALID"] = function ()
        return global.gamePlayerController:GetMainPlayer() ~= nil
    end,
    ["USER_ID"] = function()
        return global.gamePlayerController:GetMainPlayerID()
    end,
    ["X"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return "invalid"
        end
        return player:GetMapX()
    end,
    ["Y"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return "invalid"
        end
        return player:GetMapY()
    end,
    ["PK_LV"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return "invalid"
        end
        return player:GetPKLv()
    end,
    -- 仇恨ID
    ["HATE_ID"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return nil
        end
        return player:GetHateID()
    end,
    --我自己的名字
    ["USER_NAME"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetName()
    end,
    ["JOB"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleJob()
    end,
    ["LEVEL"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleLevel()
    end,
    ["RELEVEL"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleReinLv()
    end,
    -- 获取职业名称
    ["JOB_NAME"] = function(job)
        if not job then
            local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
            return PlayerProperty:GetRoleJobName()
        end
        return GUIFunction:GetJobNameByID(tonumber(job))
    end,
    ["SEX"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleSex()
    end,
    --玩家真实名字
    ["REAL_USER_NAME"] = function()
        local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        return loginProxy:GetSelectedRoleName()
    end,
    --玩家名字颜色
    ["USER_NAME_COLOR"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetMainPlayerNameColor()
    end,
    -- 角色是否死亡
    ["USER_IS_DIE"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return not PlayerProperty:IsAlive()
    end,
    -- 角色是否能复活
    ["USER_IS_CANREVIVE"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:IsCanRevive()
    end,
    ["DIR"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return global.MMO.ORIENT_INVAILD
        end
        return player:GetDirection()
    end,
    ["POS"] = function()
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return cc.p(0, 0)
        end
        return player:getPosition()
    end,
    ["HP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleCurHP()
    end,
    ["MP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleCurMP()
    end,
    ["AC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Min_DEF)
        return value
    end,
    ["MAXAC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Max_DEF)
        return value
    end,
    ["MAC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Min_MDF)
        return value
    end,
    ["MAXMAC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Max_MDF)
        return value
    end,
    ["DC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Min_ATK)
        return value
    end,
    ["MAXDC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Max_ATK)
        return value
    end,
    ["MC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Min_MAT)
        return value
    end,
    ["MAXMC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Max_MAT)
        return value
    end,
    ["SC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Min_Daoshu)
        return value
    end,
    ["MAXSC"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Max_Daoshu)
        return value
    end,
    ["HIT"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Hit_Point)
        return value
    end,
    ["SPD"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Speed_Point)
        return value
    end,
    ["HITSPD"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Hit_Speed)
        return value
    end,
    ["BURST"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Double_Rate)
    end,
    ["BURST_DAM"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().Double_Damage)
    end,
    ["IMM_ATT"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().ATK_Defence)
    end,
    ["IMM_MAG"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleAttByAttType(GUIFunction:PShowAttType().MAT_Defence)
    end,
    ["MAXHP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local value = PlayerProperty:GetRoleMaxHP()
        return value
    end,
    ["MAXMP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local value = PlayerProperty:GetRoleMaxMP()
        return value
    end,
    ["EXP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local value = PlayerProperty:GetCurrExp()
        return value
    end,
    ["MAXEXP"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local value = PlayerProperty:GetNeedExp()
        return value
    end,
    ["HW"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Hand_Weight)
        return value
    end,
    ["MAXHW"] = function()
        return SL:GetValue("MAX_ABIL_BY_ID", GUIFunction:PShowAttType().Hand_Weight) or 0
    end,
    ["BW"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Weight)
        return value
    end,
    ["MAXBW"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetMaxAbilByID(AttrType.Weight)
        return value
    end,
    ["WW"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Wear_Weight)
        return value
    end,
    ["MAXWW"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetMaxAbilByID(AttrType.Wear_Weight)
        return value
    end,
    ["HUNGER"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Health_Recover)
        return value
    end,
    ["LUCK"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        local AttrType = GUIFunction:PShowAttType()
        local value    = PlayerProperty:GetRoleAttByAttType(AttrType.Lucky)
        return value
    end,
    ["ROLE_MP_PERCENT"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleMPPercent()
    end,
    ["ROLE_HP_PERCENT"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetRoleHPPercent()
    end,
    ["DRESS"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Dress)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["WEAPON"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Weapon)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["RIGHTHAND"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_RightHand)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["HELMET"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Helmet)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["NECKLACE"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Necklace)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["RINGR"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_RingR)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["RINGL"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_RingL)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["ARMRINGR"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_ArmRingR)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["ARMRINGL"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_ArmRingL)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["BUJUK"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Bujuk)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["BELT"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Belt)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["BOOTS"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Boots)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["CHARM"] = function()
        local edata = GUIFunction:GetEquipDataByPos(GUIDefine.EquipPosUI.Equip_Type_Charm)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["EQUIPBYPOS"] = function(param)
        if not param then
            return "ERROR EQUIP BY POS "
        end
        if not tonumber(param) then
            return "ERROR EQUIP BY POS " .. param
        end
        local pos = tonumber(param)

        local edata = GUIFunction:GetEquipDataByPos(pos)
        if not edata then
            return ""
        end
        return edata.Name
    end,
    ["ALL_EQUIP_DATAS"] = function()
        return clone(EquipData.GetEquipData())
    end,
    ["EQUIP_DATA"] = function(param1, param2)
        if not param1 then
            return
        end
        if tonumber(param1) then
            return GUIFunction:GetEquipDataByPos(param1, param2)
        else
            return GUIFunction:GetEquipDataByName(param1)
        end
    end,
    ["EQUIP_DATA_LIST"] = function(param1)
        if not param1 then
            return
        end
        return GUIFunction:GetEquipDataListByPos(param1, GUIDefine.EquipDataType.EQUIP)
    end,
    --外观
    ["FEATURE"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetFeature()
    end,
    --发型
    ["HAIR"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetFeature().hairID
    end,
    -- 判断加入国家
    ["NATION_IS_JOINED"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:IsJoinNation()
    end,
    -- PK点数
    ["PKPOINT"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetPKPoint()
    end,
    -- 消息提示前缀是否显示
    ["PROMPT_PREFIX_SHOW"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetPromptPrefixShow()
    end,


    -----------------------------------------------------------------------------
    --英雄名字颜色
    ["HERO_NAME_COLOR"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetHeroNameColor()
    end,
    ---

    -----------------------------------------------------------------------------
    -- 当前地图信息
    ["MAP_ID"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:GetMapID()
    end,
    --地图的名字
    ["MAP_NAME"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:GetMapName()
    end,
    -- 获取地图名字 通过地图ID param: 地图ID
    ["MAP_NAME_BY_ID"] = function(mapID)
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapID and mapProxy:GetMapNameByID(mapID)
    end,
    ["MAP_DATA_ID"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:GetMapDataID()
    end,
    ["MAP_IS_IN_SAFE_AREA"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:IsInSafeArea()
    end,
    -- 是否在攻城区域
    ["MAP_IS_IN_SIEGE_AREA"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:IsInSiegeArea()
    end,
    ["MAP_FORBID_LEVEL_AND_JOB"] = function()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:IsForbidLvJob()
    end,
    -- 是否禁止说话
    ["MAP_FORBID_SAY"] = function()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:IsForbidSay()
    end,
    -- 血量显示百分比
    ["MAP_SHOW_HPPER"] = function()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:IsHPPercent()
    end,
    -- 是否禁止查看
    ["MAP_FORBID_LOOK"] = function()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:IsForbidVisitPlayer()
    end,
    -- 是否禁止释放某技能
    ["MAP_FORBID_LAUNCH_SKILL"] = function(skillID)
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:IsForbidLaunchSkill(skillID)
    end,
    -- 地图 map 文件是否加载
    ["MAP_DATA_LOADED"] = function()
        local mapData = global.sceneManager:GetMapData2DPtr()
        return mapData ~= nil
    end,
    -- 地图横向格子数
    ["MAP_ROWS"] = function()
        local mapData = global.sceneManager:GetMapData2DPtr()
        if mapData then
            return mapData:getMapDataRows()
        end
    end,
    -- 地图纵向格子数
    ["MAP_COLS"] = function()
        local mapData = global.sceneManager:GetMapData2DPtr()
        if mapData then
            return mapData:getMapDataCols()
        end
    end,
    -- 地图获取宽度像素
    ["MAP_SIZE_WIDTH_PIXEL"] = function()
        return global.sceneManager:GetMapWidthInPixel()
    end,
    -- 地图获取高度像素
    ["MAP_SIZE_HEIGHT_PIXEL"] = function()
        return global.sceneManager:GetMapHeightInPixel()
    end,
    -- 地图格子是否是阻挡
    ["MAP_IS_OBSTACLE"] = function(mapX, mapY)
        if not mapX or not mapY then 
            return false
        end
        local mapData = global.sceneManager:GetMapData2DPtr()
        if mapData then
            return mapData:isObstacle(mapX, mapY) ~= 0
        end
    end,
    -- 地图计算起点到终点X或者Y 变化最大的差值
    ["MAP_PATH_SIZE"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetPathPointSize()
    end,
    -- 地图计算路径坐标 返回table
    ["MAP_PATH_POINTS"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetPathFindPoints() or {}
    end,
    -- 地图获取当前路径坐标index
    ["MAP_CURRENT_PATH_INDEX"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetCurrPathPoint()
    end,
    -- 获取地图连接点配置数据 param: 地图ID
    ["MAP_LINKS_BY_ID"] = function(mapID)
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapID and mapProxy:GetMapLinkPoints(mapID)
    end,
    -- 地图点是否存在火墙特效
    ["MAP_IS_EXIST_FIREWALL"] = function(mapX, mapY)
        if not mapX or not mapY then
            return nil
        end
        return global.sceneEffectManager:IsExistedFireInMapXY(mapX, mapY)
    end,
    ["MINIMAP_ID"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:GetMiniMapID()
    end,
    ["MINIMAP_ABLE"] = function()
        local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return MapProxy:CheckMiniMapAble()
    end,
    -- 获取地图文件
    ["MINIMAP_FILE"] = function()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:GetMiniMapFile()
    end,
    -- 获取小地图文件 通过地图ID  param: 地图ID
    ["MINIMAP_FILE_BY_ID"] = function(mapID)
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:GetMiniMapFileByID(mapID)
    end,
    -- 地图获取怪物
    ["MINIMAP_MONSTERS"] = function()
        local MiniMapProxy = global.Facade:retrieveProxy(global.ProxyTable.MiniMapProxy)
        return MiniMapProxy:getMonsters()
    end,
    -- 地图获取NPC坐标
    ["MINIMAP_PORTALS"] = function()
        return MiniMapData.GetPortals()
    end,
    -- 地图获取NPC坐标 通过地图ID  param: 地图ID
    ["MINIMAP_PORTALS_BY_ID"] = function(mapID)
        return MiniMapData.GetPortals(mapID)
    end,
    -- 地图获取组队成员坐标信息
    ["MINIMAP_TEAM_MEMBER"] = function()
        local MiniMapProxy = global.Facade:retrieveProxy(global.ProxyTable.MiniMapProxy)
        return MiniMapProxy:getTeams()
    end,

    -----------------------------------------------------------------------------
    -- 聊天
    -- 获取聊天显示的道具
    ["CHAT_SHOW_ITEMS"] = function()
        local items     = {}
        local equipData = EquipData.GetEquipData()
        for k, v in pairs(equipData) do
            if v.chatshow ~= 1 then
                local item = clone(v)
                item.wore  = true
                table.insert(items, item)
            end
        end

        local bagData = BagData.GetBagData()
        for k, v in pairs(bagData) do
            if v.chatshow ~= 1 then
                local item = clone(v)
                table.insert(items, item)
            end
        end

        return items
    end,
    --聊天 tips 使用的字体
    ["CHATANDTIPS_USE_FONT"] = function()
        return global.ChatAndTips_Use_Font
    end,
    -----------------------------------------------------------------------------
    ["REDKEY"] = function(param)
        if param and string.len(param) > 0 then
            local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
            local value = ConditionProxy:TransValueByKey(param)
            return value
        end
        return param
    end,

    -----------------------------------------------------------------------------
    -- 脚本拉杆组件提供
    ["SLIDERV"] = function(param)
        local SUIComponentProxy = global.Facade:retrieveProxy(global.ProxyTable.SUIComponentProxy)
        return SUIComponentProxy:GetSUISliderValueById(param)
    end,

    -----------------------------------------------------------------------------
    -- PK模式
    ["PKMODE"] = function()
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetPKMode()
    end,
    ["PKMODE_CAN_USE"] = function(param)
        if not param then
            return false
        end
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:IsShowCurMode(param)
    end,

    -- 宝宝模式
    ["PET_PKMODE"] = function()
        local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
        return SummonsProxy:GetMode()
    end,

    -- 宝宝模式
    ["PET_ALIVE"] = function()
        local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
        return SummonsProxy:IsAlived()
    end,

    ["PET_LOCK_ID"] = function()
        local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
        return SummonsProxy:GetLockTargetID()
    end,
    -- 自动召唤技能ID
    ["AUTO_SUMMON_SKILLID"] = function()
        local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
        return SummonsProxy:autoSummon()
    end,

    -----------------------------------------------------------------------------
    -- 是否开启英雄
    ["USEHERO"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:IsHeroOpen()
    end,
    -- 是否召唤英雄
    ["HERO_IS_ALIVE"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:HeroIsLogin()
    end,
    -- 是否激活英雄
    ["HERO_IS_ACTIVE"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetIsMakeHero()
    end,
    -- 英雄ID
    ["HERO_ID"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleUID()
    end,
    --英雄状态系统 能设置的值3个或四个
    ["HERO_STATES_SYS_VALUES"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getStatesSysSet()
    end,
    --英雄激活的状态列表
    ["HERO_ACTIVES_STATES"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getStates()
    end,
    --英雄状态
    ["HERO_STATE"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getHeroState()
    end,
    --英雄守护状态
    ["HERO_GUARDSTATE"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        local state = HeroPropertyProxy:getHeroGuardState()
        return tonumber(state) == 1
    end,
    --是否点击了英雄守护按钮 
    ["HERO_GUARD_ISCLICK"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getGuardBtnState()
    end,
    ["HERO_LOGIN_CD"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getCD()
    end,
    --是否能复活
    ["HERO_CAN_REVIVE"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:IsCanRevive()
    end,
    ["INTERNAL_SKILLS"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillsList()
    end,
    ["INTERNAL_SKILL_DATA"] = function(skillID, skillType)
        if not skillID or not skillType then
            return nil
        end
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillData(skillID, skillType)
    end,
    --获取内功技能等级熟练度数据
    ["INTERNAL_SKILL_TRAIN_DATA"] = function(skillID, skillType)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillTrainData(skillID, skillType)
    end,
    --获取内功技能开关
    ["INTERNAL_SKILL_ONOFF"] = function(skillID, skillType)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillOnOff(skillID, skillType)
    end,
    -- 内功技能矩形图标
    ["INTERNAL_SKILL_RECT_ICON_PATH"] = function(skillID, skillType)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGIconRectPath(skillID, skillType)
    end,
    -- 内功技能名字
    ["INTERNAL_SKILL_NAME"] = function(skillID, skillType)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillName(skillID, skillType) or ""
    end,
    -- 内功技能描述
    ["INTERNAL_SKILL_DESC"] = function(skillID, skillType)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetNGSkillDesc(skillID, skillType)
    end,
    -- 内功-经络(穴位描述)
    ["MERIDIAN_DESC"] = function()
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetTipsConfig()
    end,
    -- 内功- 经络 穴位是否激活列表
    ["MERIDIAN_AUCPOINT_STATE"] = function(param1)
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetAucPointStateByType(param1)
    end,
    -- 内功- 经络 各个开关状态列表
    ["MERIDIAN_OPEN_LIST"] = function()
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetMeridianOpenList()
    end,
    -- 内功- 经络 获取对应等级
    ["MERIDIAN_LV"] = function(type)
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetMeridianLvByType(type)
    end,
    -- 内功- 所有拥有连击技能
    ["HAVE_COMBO_SKILLS"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetComboSkills()
    end,
    -- 对应连击技能数据
    ["COMBO_SKILL_DATA"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetComboSkillByID(param1)
    end,
    -- 连击技能等级熟练度数据
    ["COMBO_SKILL_TRAIN_DATA"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetComboSkillTrainData(skillID)
    end,
    -- 内功- 设置连击技能
    ["SET_COMBO_SKILLS"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:haveSetComboSkill()
    end,
    ["OPEN_COMBO_NUM"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetComboOpenNum()
    end,
    -- 可释放连击状态
    ["CAN_LAUNCH_COMBO"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetlaunchComboStatus()
    end,
    -- 连击格子额外加暴击几率
    ["EXTRA_COMBO_BJRATE"] = function(index)
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetComboExtraBJRate(index)
    end,
    -- 玩家属性初始化完成
    ["PLAYER_INITED"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:IsInited()
    end,

    -- 英雄
    ["H.ATT_BY_TYPE"] = function(param)--根据类型获取属性值
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(param)
    end,
    -- 技能名字
    ["H.SKILL_NAME"] = function(param)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetSkillNameByID(param) or ""
    end,
    --获取技能等级熟练度数据
    ["H.SKILL_TRAIN_DATA"] = function(param1)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetSkillTrainData(param1)
    end,
    --已学技能(noBasicSkill, activeOnly)
    ["H.LEARNED_SKILLS"] = function(param1, param2)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetSkills(param1, param2)
    end,
    --获取技能数据
    ["H.SKILL_DATA"] = function(param1)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetSkillByID(param1)
    end,
    --获取技能快捷键
    ["H.SKILL_KEY"] = function(param1)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetSkillKey(param1)
    end,
    ["H.ANGER"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getCurAnger()
    end,
    ["H.MAXANGER"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getMaxAnger()
    end,
    ["H.USERNAME"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetName()
    end,
    ["H.LEVEL"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleLevel()
    end,
    ["H.RELEVEL"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleReinLv()
    end,
    ["H.EXP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetCurrExp()
    end,
    ["H.MAXEXP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetNeedExp()
    end,
    ["H.JOBNAME"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleJobName()
    end,
    ["H.JOB"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleJob()
    end,
    ["H.SEX"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleSex()
    end,
    ["H.HAIR"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetFeature().hairID
    end,
    ["H.MAXHP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleMaxHP()
    end,
    ["H.MAXMP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleMaxMP()
    end,
    ["H.HP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleCurHP()
    end,
    ["H.MP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleCurMP()
    end,
    ["H.HPPercent"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleHPPercent()
    end,
    ["H.MPPercent"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleMPPercent()
    end,
    ["H.EXPPercent"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleEXPPercent()
    end,
    ["H.MIN_ATK"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Min_ATK)
    end,
    ["H.MAX_ATK"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_ATK)
    end,
    ["H.MIN_MAT"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Min_MAT)
    end,
    ["H.MAX_MAT"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_MAT)
    end,
    ["H.MIN_DAO"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Min_Daoshu)
    end,
    ["H.MAX_DAO"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Max_Daoshu)
    end,
    ["H.MIN_DEF"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().MIN_DEF)
    end,
    ["H.MAX_DEF"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().MAX_DEF)
    end,
    ["H.MIN_MDF"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().MIN_MDF)
    end,
    ["H.MAX_MDF"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().MAX_MDF)
    end,
    ["H.HIT"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Hit_Point)
    end,
    ["H.HITSPD"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Hit_Speed)
    end,
    ["H.BURST"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Double_Rate)
    end,
    ["H.BURST_DAM"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Double_Damage)
    end,
    ["H.IMM_ATT"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().ATK_Defence)
    end,
    ["H.IMM_MAG"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().MAT_Defence)
    end,
    ["H.LUCK"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetHeroLuck()
    end,
    ["H.DROP"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Mon_Bj_Power_Rate)
    end,
    -- 腕力
    ["H.HW"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Hand_Weight)
    end,
    ["H.MAXHW"] = function()
        return SL:GetValue("H.MAX_ABIL_BY_ID", GUIFunction:PShowAttType().Hand_Weight) or 0
    end,
    ["H.BW"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Weight)
    end,
    ["H.MAXBW"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetMaxAbilByID(GUIFunction:PShowAttType().Weight)
    end,
    ["H.WW"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetRoleAttByAttType(GUIFunction:PShowAttType().Wear_Weight)
    end,
    ["H.MAXWW"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetMaxAbilByID(GUIFunction:PShowAttType().Wear_Weight)
    end,
    ["H.SHAN"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getShan()
    end,
    ["H.SPEED"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getSpeed()
    end,
    ["H.DELAYT"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getDelayTime()
    end,
    ["H.ALL_EQUIP_DATA"] = function()
        return clone(HeroEquipData.GetEquipData())
    end,
    ["H.EQUIP_DATA"] = function(param1, param2)
        if not param1 then
            return
        end
        if tonumber(param1) then
            return GUIFunction:GetEquipDataByPos(param1, param2, GUIDefine.EquipDataType.HEROEQUIP)
        else
            return GUIFunction:GetEquipDataByName(param1, GUIDefine.EquipDataType.HEROEQUIP)
        end
    end,
    ["H.EQUIP_DATA_LIST"] = function(param1)
        if not param1 then
            return
        end
        return GUIFunction:GetEquipDataListByPos(param1, GUIDefine.EquipDataType.HEROEQUIP)
    end,
    -- 英雄 技能图标
    ["H.SKILL_ICON_PATH"] = function(param, isCombo)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetIconPathByID(param, isCombo)
    end,
    -- 英雄技能矩形图标
    ["H.SKILL_RECT_ICON_PATH"] = function(skillID, isCombo)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetIconRectPathByID(skillID, isCombo)
    end,
    ["H.INTERNAL_SKILLS"] = function()
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillsList()
    end,
    ["H.INTERNAL_SKILL_DATA"] = function(skillID, skillType)
        if not skillID or not skillType then
            return nil
        end
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillData(skillID, skillType)
    end,
    --获取内功技能等级熟练度数据
    ["H.INTERNAL_SKILL_TRAIN_DATA"] = function(skillID, skillType)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillTrainData(skillID, skillType)
    end,
    --获取内功技能开关
    ["H.INTERNAL_SKILL_ONOFF"] = function(skillID, skillType)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillOnOff(skillID, skillType)
    end,
    -- 内功技能矩形图标
    ["H.INTERNAL_SKILL_RECT_ICON_PATH"] = function(skillID, skillType)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGIconRectPath(skillID, skillType)
    end,
    -- 内功技能名字
    ["H.INTERNAL_SKILL_NAME"] = function(skillID, skillType)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillName(skillID, skillType) or ""
    end,
    -- 内功技能描述
    ["H.INTERNAL_SKILL_DESC"] = function(skillID, skillType)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetNGSkillDesc(skillID, skillType)
    end,
    -- 内功- 经络 穴位是否激活列表
    ["H.MERIDIAN_AUCPOINT_STATE"] = function(param1)
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetAucPointStateByType(param1, true)
    end,
    -- 内功- 经络 各个开关状态列表
    ["H.MERIDIAN_OPEN_LIST"] = function()
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetMeridianOpenList(true)
    end,
    -- 内功- 经络 获取对应等级
    ["H.MERIDIAN_LV"] = function(type)
        local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
        return MeridianProxy:GetMeridianLvByType(type, true)
    end,
    -- 内功- 所有拥有连击技能
    ["H.HAVE_COMBO_SKILLS"] = function()
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetComboSkills()
    end,
    -- 对应连击技能数据
    ["H.COMBO_SKILL_DATA"] = function(param1)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetComboSkillByID(param1)
    end,
    -- 连击技能等级熟练度数据
    ["H.COMBO_SKILL_TRAIN_DATA"] = function(skillID)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetComboSkillTrainData(skillID)
    end,
    -- 内功- 设置连击技能
    ["H.SET_COMBO_SKILLS"] = function()
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:haveSetComboSkill()
    end,
    ["H.OPEN_COMBO_NUM"] = function()
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:GetComboOpenNum()
    end,
    -- 英雄锁定ACTORID
    ["H.LOCK_TARGET_ID"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:getLockID()
    end,
    -- 英雄属性初始化完成
    ["HERO_INITED"] = function()
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:IsInited()
    end,
    -----------------------------------------------------------------------------
    -- 组队
    -- 附近队伍列表
    ["TEAM_NEAR"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetNearTeamItems()
    end,
    -- 队伍成员列表
    ["TEAM_MEMBER_LIST"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetTeamMember()
    end,
    -- 队伍人数
    ["TEAM_MEMBER_COUNT"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetMemberCount()
    end,
    -- 队伍最大人数
    ["TEAM_MEMBER_MAX_COUNT"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetMemberMax()
    end,
    -- 是否是队伍成员
    ["TEAM_IS_MEMBER"] = function(uid)
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:IsTeamMember(uid)
    end,
    -- 是否队伍队长
    ["TEAM_IS_LEADER"] = function(uid)
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:IsTeamLeader(uid)
    end,
    -- 入队申请列表
    ["TEAM_APPLY"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetApplyItems()
    end,
    -- 队伍邀请数目
    ["TEAM_INVITE_COUNT"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetInviteCount()
    end,
    -- 队伍邀请数据
    ["TEAM_INVITE_DATA"] = function()
        local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
        return TeamProxy:GetInviteItems()
    end,

    -----------------------------------------------------------------------------
    -- 邮件
    -- 邮件列表
    ["MAIL_LIST"] = function()
        local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
        return MailProxy:GetMailList()
    end,
    -- 邮件id获取邮件
    ["MAIL_BY_ID"] = function(mailId)
        local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
        return MailProxy:GetMailByID(mailId)
    end,
    -----------------------------------------------------------------------------
    -- 商城
    -- 充值商品信息列表
    ["RECHARGE_PRODUCTS"] = function()
        local RechargeProxy = global.Facade:retrieveProxy(global.ProxyTable.RechargeProxy)
        local products = RechargeProxy:GetProducts() or {}
        return products
    end,
    -- 通过商品Id获取商品信息
    ["RECHARGE_PRODUCT_BY_ID"] = function(id)
        local RechargeProxy = global.Facade:retrieveProxy(global.ProxyTable.RechargeProxy)
        local product = RechargeProxy:GetProductByID(id) or nil
        return product
    end,

    -----------------------------------------------------------------------------
    -- 拍卖行
    -- 默认最低竞拍价
    ["AUCTION_BIDPRICE_MIN"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetLowBidPrice()
    end,
    -- 默认最高竞拍价
    ["AUCTION_BIDPRICE_MAX"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetHighBidPrice()
    end,
    -- 默认最低一口价
    ["AUCTION_BUYPRICE_MIN"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetLowBuyPrice()
    end,
    -- 默认最高一口价
    ["AUCTION_BUYPRICE_MAX"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetHighBuyPrice()
    end,
    -- 默认货架数量
    ["AUCTION_DEFAULT_SHELF"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetLimitShelf()
    end,
    -- 上架列表数量
    ["AUCTION_PUT_LIST_CNT"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetPutListCount()
    end,
    -- 拍卖行货币
    ["AUCTION_MONEY"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetCurrencies()
    end,
    -- 是否有我的竞拍物品
    ["AUCTION_HAVE_MY_BIDDING"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:IsExistAcquireItem()
    end,
    -- 拍卖行物品状态 返回参数1：状态 0.未知 2.竞拍中 3.已超时，参数2：剩余时间
    ["AUCTION_ITEM_STATE"] = function(item)
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:CalcItemStatus(item)
    end,
    -- 是否可竞价
    ["AUCTION_CAN_BID"] = function(item)
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:CheckBidAble(item)
    end,
    -- 是否可一口价
    ["AUCTION_CAN_BUY"] = function(item)
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:CheckBuyAble(item)
    end,
    -- 获取拍卖行我的展示可寄售道具
    ["AUCTION_MY_SHOW_LIST"] = function()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        return AuctionProxy:GetShowBagItems()
    end,
    -----------------------------------------------------------------------------
    -- 好友最大人数
    ["FRIEND_MAX_COUNT"] = function()
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetMaxNum()
    end,
    -- 好友信息，通过UID获取
    ["FRIEND_INFO_BY_UID"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetFriendDataByUserID(param)
    end,
    -- 好友信息，通过NAME获取
    ["FRIEND_INFO_BY_NAME"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetFriendDataByName(param)
    end,
    -- 是我的好友
    ["SOCIAL_IS_FRIEND_BY_NAME"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:IsFriendByName(param)
    end,
    -- 是我的好友
    ["SOCIAL_IS_FRIEND_BY_UID"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:IsFriendByUserID(param)
    end,
    -- 是黑名单
    ["SOCIAL_IS_BLACKLIST"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetBlackDataByName(param) ~= nil
    end,
    -- 是否在黑名单 通过uid 
    ["SOCIAL_IS_BLACKLIST_BY_UID"] = function(param)
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:IsInBlackList(param)
    end,
    -- 好友列表
    ["FRIEND_LIST"] = function()
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetFriendList()
    end,
    -- 黑名单
    ["FRIEND_BLACKLIST"] = function()
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetBlackList()
    end,
    -- 好友申请列表
    ["FRIEND_APPLYLIST"] = function()
        local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
        return FriendProxy:GetApplyList()
    end,
    -----------------------------------------------------------------------------
    -- 行会
    -- 行会成员列表
    ["GUILD_MEMBER_LIST"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetMemberList()
    end,
    -- 行会成员列表，排序过
    ["GUILD_MEMBER_LIST_SORT"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        local memberList = clone(GuildProxy:GetMemberList())
        table.sort(memberList, function(a, b)
            if a.Line ~= b.Line then
                return a.Line > b.Line
            end
    
            if a.Rank ~= b.Rank then
                return a.Rank < b.Rank
            end

            if a.Level ~= b.Level then
                return a.Level > b.Level
            end
    
            if a.LastTime ~= b.LastTime then
                return a.LastTime > b.LastTime
            end
    
            return a.UserName < b.UserName
        end)
        return memberList
    end,
    -- 行会成员信息 uid
    ["GUILD_MEMBER_INFO"] = function(uid)
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildMemberInfoByID(uid)
    end,
    -- 获取行会职位
    ["GUILD_OFFICIAL_NAME_BY_RANK"] = function(rank)
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildTitleNameByRank(rank)
    end,
    -- 获取行会职位列表 {[rank] = name, ...}
    ["GUILD_TIELE_LIST"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildTitleList()
    end,
    -- 获取世界行会列表
    ["GUILD_WORLD_LIST"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildList()
    end,
    -- 获取单个世界行会数据
    ["GUILD_WORLD_INFO_BY_GUILDID"] = function(guildId)
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetWorldGuildInfoByID(guildId)
    end,
    -- 是否已经加入行会
    ["GUILD_IS_JOINED"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:IsJoinGuild() == true
    end,
    -- 玩家行会ID
    ["GUILD_ID"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildID() or ""
    end,
    -- 玩家行会名
    ["GUILD_NAME"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildName() or ""
    end,
    -- 玩家行会编号
    ["GUILD_NUMBER"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildNumber() or ""
    end,
    -- 玩家行会会长ID
    ["GUILD_MASTER_ID"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildInfo().MasterID or ""
    end,
    -- 玩家行会会长名
    ["GUILD_MASTER_NAME"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildInfo().MasterName or ""
    end,
    -- 玩家行会公告
    ["GUILD_NOTICE"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildInfo().Notice or ""
    end,
    -- 玩家行会是否是会长
    ["GUILD_IS_CHAIRMAN"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:IsGuildChairman()
    end,
    -- 玩家行会是否是副会长
    ["GUILD_IS_VICECHAIRMAN"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:IsGuildViceChairman()
    end,
    -- 是否是行会管理员
    ["GUILD_IS_ADMIN"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:IsGuildAdmin()
    end,
    -- 是否有行会修改职位权限
    ["GUILD_CHECK_PERMISSION_SET_RANK"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        if GuildProxy:IsGuildChairman() then
            return true
        end
        if GuildProxy:IsGuildViceChairman() then
            return GuildProxy:GetViceChairmanPermissionByID(GuildProxy.GuildPermission.SetRank) == true
        end
        return false
    end,
    -- 是否有设置公告权限
    ["GUILD_CHECK_PERMISSION_SET_NOTICE"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        if GuildProxy:IsGuildChairman() then
            return true
        end
        if GuildProxy:IsGuildViceChairman() then
            return GuildProxy:GetViceChairmanPermissionByID(GuildProxy.GuildPermission.SetNotice) == true
        end
        return false
    end,
    -- 是否有行会审批权限
    ["GUILD_CHECK_PERMISSION_APPROVE_APPLY"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        if GuildProxy:IsGuildChairman() then
            return true
        end
        if GuildProxy:IsGuildViceChairman() then
            return GuildProxy:GetViceChairmanPermissionByID(GuildProxy.GuildPermission.ApproveApply) == true
        end
        return false
    end,
    -- 是否有踢人权限
    ["GUILD_CHECK_PERMISSION_REMOVE_MEMBER"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        if GuildProxy:IsGuildChairman() then
            return true
        end
        if GuildProxy:IsGuildViceChairman() then
            return GuildProxy:GetViceChairmanPermissionByID(GuildProxy.GuildPermission.RemoveMember) == true
        end
        return false
    end,
    -- 玩家行会等级
    ["GUILD_LEVEL"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildLevel()
    end,
    -- 行会在线人数
    ["GUILD_MEMBER_ONLINE_COUNT"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        local memberList = GuildProxy:GetMemberList()
        local count = 0
        for i, v in ipairs(memberList) do
            if v.Line == 1 then
                count = count + 1
            end
        end
        return count
    end,
    -- 行会人数
    ["GUILD_MEMBER_COUNT"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetMemberCount() or 0
    end,
    -- 行会最大人数
    ["GUILD_MEMBER_COUNT_MAX"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildMemberMax() or 0
    end,
    -- 行会资金
    ["GUILD_GOLD_NUM"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetGuildGold()
    end,
    -- 行会自动同意
    ["GUILD_AUTO_APPROVE_APPLY"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetAutoJoin()
    end,
    -- 行会自动加入等级
    ["GUILD_AUTO_APPROVE_LEVEL"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetJoinLevel()
    end,
    -- 行会自动同意最大等级 [服务端下发]
    ["GUILD_AUTO_APPROVE_MAX_LEVEL"] = function()
        local PlayerPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerPropertyProxy:GetMaxLevel()
    end,
    -- 行会管理权限
    ["GUILD_VICECHAIRMAN_PERMISSION_BY_ID"] = function(param)
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetViceChairmanPermissionByID(param)
    end,
    -- 我的行会信息
    ["GUILD_INFO"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        local data = {}
        data.rank = GuildProxy:GetUserRank()                            -- 职位
        data.isJoinGuild = GuildProxy:IsJoinGuild()                     -- 是否加入公会
        data.guildName = GuildProxy:GetGuildName()                      -- 行会名字
        data.guildId = GuildProxy:GetGuildID()                          -- 行会ID
        data.isChairMan = GuildProxy:IsGuildAdmin()                     -- 是否是会长或者副会长
        data.guildMaster = GuildProxy:GetGuildMasterName()              -- 行会会长
        data.notice = GuildProxy:GetGuildNotice()                       -- 行会公告
        return data
    end,
    -- 行会申请列表
    ["GUILD_APPLY_LIST"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetApplyGuildList()
    end,
    -- 行会结盟申请列表
    ["GUILD_ALLY_APPLY_LIST"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetAllyApplyList()
    end,

    -- 行会随即名
    ["GUILD_CREATE_RANK_NAME"] = function()
        local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
        return GuildProxy:GetRankGuildName()
    end,

    -----------------------------------------------------------------------------
    -- 对方：名字、等级、好友、公会 ID
    ["TRADE_TARGET_DATA"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetTrader()
    end,
    -- 对方：ID
    ["TRADE_TARGET_ID"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetTraderID()
    end,
    -- 对方：名字
    ["TRADE_TARGET_NAME"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetTraderName()
    end,
    -- 交易-自己锁定状态
    ["TRADE_MY_LOCK_STATUS"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetMySureLockState()
    end,
    -- 交易-对方锁定状态
    ["TRADE_TARGET_LOCK_STATUS"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetTargetSureLockState()
    end,
    -- 交易-自己装备的数量
    ["TRADE_MY_ITEM_NUM"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetSelfItemNum()
    end,
    -- 交易-是否处于交易状态
    ["TRADE_IS_TRADING"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:IsTrading()
    end,
    -- 交易-自己货架数据
    ["TRADE_MY_ITEMS"] = function()
        local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return TradeProxy:GetSelfItemData()
    end,
    --交易-对方放入物品信息
    ["TRADE_TARGET_ITEMS"] = function()
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return proxy:GetTargetItemData()
    end,
    --交易-获取邀请的数量
    ["TRADE_INVITE_COUNT"] = function()
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return proxy:GetInviteCount()
    end,
    --交易-获取邀请列表信息
    ["TRADE_INVITE_ITEMS"] = function()
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
        return proxy:GetInviteItems()
    end,
    -----------------------------------------------------------------------------

    -- 排行榜数据  param1: 1: 人物 2: 英雄
    ["RANK_DATA_BY_TYPE"] = function(param, param1)
        local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
        if param1 and param1 == 2 then
            return RankProxy:GetRankDataByID_hero(param) or {}
        else
            return RankProxy:GetRankDataByID(param) or {}
        end
    end,
    -- 排行榜配置
    ["RANK_CONFIG"] = function()
        local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
        return RankProxy:GetRankConfig()
    end,

    -----------------------------------------------------------------------------
    -- 任务排序
    ["MISSION_ITEM_ORDER"] = function(param)
        if not param then
            return 0
        end
        local MissionProxy = global.Facade:retrieveProxy(global.ProxyTable.MissionProxy)
        return MissionProxy:CalcMissionOrderByID(param)
    end,
    -- 任务数据
    ["MISSION_ITEM_BY_ID"] = function(param)
        if not param then
            return nil
        end
        local MissionProxy = global.Facade:retrieveProxy(global.ProxyTable.MissionProxy)
        return MissionProxy:GetMissionByID(param)
    end,

    -----------------------------------------------------------------------------
    ["SKILL_FIND_ROBOT_LAUNCH"] = function()
        return SkillUtils.FindRobotLaunchSkill()
    end,
    -- 筛选技能数据
    ["SKILL_INFO_FILTER"] = function(skilltype, filterJob, filterLearned, noBasic)
        return SkillUtils.FindSkills(skilltype, filterJob, filterLearned, noBasic)
    end,
    -- 技能名字
    ["SKILL_NAME"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkillNameByID(param) or ""
    end,
    -- 技能图标
    ["SKILL_ICON_PATH"] = function(param, isCombo)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetIconPathByID(param, isCombo)
    end,
    -- 技能矩形图标
    ["SKILL_RECT_ICON_PATH"] = function(param, isCombo)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetIconRectPathByID(param, isCombo)
    end,
    -- 是否可以开关技能
    ["SKILL_IS_ONOFF_SKILL"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsOnoffSkill(param)
    end,
    -- 技能是否开启
    ["SKILL_IS_ON_SKILL"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsOnSkill(param)
    end,
    -- 输入坐标型技能
    ["SKILL_IS_INPUT_POS_SKILL"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsInputDestSkill(param)
    end,
    -- 是否是增益技能
    ["SKILL_IS_ADDITION_SKILL"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsAdditionSkill(param)
    end,
    -- 是否直线攻击技能
    ["SKILL_IS_LINE_ATTACK"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsLineSlopeSkill(param)
    end,
    -- 施法是否需要检测距离
    ["SKILL_IS_FORCE_DISTANCE"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsForceDis(param)
    end,
    -- 是否魔法锁定技能
    ["SKILL_IS_MAGIC_LOCK"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsMagicLockSkill(param)
    end,
    -- 是否需要目标技能
    ["SKILL_IS_NEED_TARGET"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsNeedTarget(param)
    end,
    -- 已学技能(noBasicSkill, activeOnly, noAutoLaunch)
    ["LEARNED_SKILLS"] = function(param1, param2, param3)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkills(param1, param2, param3)
    end,
    -- 是否连击技能
    ["SKILL_IS_COMBO_SKILL"] = function(param)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsComboSkill(param)
    end,
    --是否主动技能
    ["SKILL_IS_ACTIVE"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsActiveSkill(param1)
    end,
    --获取技能数据
    ["SKILL_DATA"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkillByID(param1)
    end,
    --获取技能等级熟练度数据
    ["SKILL_TRAIN_DATA"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkillTrainData(param1)
    end,
    --获取技能配置
    ["SKILL_CONFIG"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:FindConfigBySkillID(param1)
    end,
    --获取技能快捷键
    ["SKILL_KEY"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkillKey(param1)
    end,
    --获取技能等级
    ["SKILL_LEVEL"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetLevel(param1)
    end,
    --能不能释放
    ["SKILL_CHECK_LAUNCH"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:CheckAbleToLaunch(param1)
    end,
    -- 技能是否已学习 param1: 技能ID
    ["SKILL_IS_LEARNED"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsLearned(param1)
    end,
    -- 技能优先级 param1: 技能ID
    ["SKILL_PRIORITY"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetPriorityBySkillID(param1)
    end,
    -- 技能本地优先级 param1: 技能ID
    ["SKILL_LOCAL_PRIORITY"] = function(param1)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetLocalPriorityBySkillID(param1)
    end,
    -- 锁定目标技能/持续攻击目标
    ["SKILL_IS_LOCK_TARGET"] = function(param1, param2)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsLockTargetSkill(param1, param2)
    end, 
    -- 技能能否召唤 param1: 技能ID
    ["SKILL_CAN_SUMMONS"] = function(param1)
        local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
        return SummonsProxy:canSummons(param1)
    end,
    -- 技能自定义数据 param1: 技能ID param2: 释放时间
    ["SKILL_CUSTOM_DATA"] = function(param1, param2)
        local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return skillProxy:GetSkillCustomData(param1)
    end,
    -- 是否CD中
    ["SKILL_IS_CDING"] = function (skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsInCD(skillID)
    end,
    -- 是否发送CD提示
    ["SKILL_NEED_CDHINT"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsCDHint(skillID)
    end,
    -- 是否满足技能耗蓝
    ["SKILL_IS_ENOUGH_MP"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsEnoughMana(skillID)
    end,
    -- 是否满足技能耗内力值
    ["SKILL_IS_ENOUGH_IV"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsEnoughIValue(skillID)
    end,
    -- 技能是否延迟释放
    ["SKILL_IS_DELAY_LAUNCH"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsDelayLaunch(skillID)
    end,
    -- 技能能否攻击怪物 param1: 技能ID param2: 怪物类型ID
    ["SKILL_CAN_ATTACK_MONSTER"] = function(skillID, monsterID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:CheckAbleToAttack(skillID, monsterID)
    end,
    ["IS_SKILL_IGNORE_MONSTER"] = function(skillID, monsterID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:CheckIgnoreMon(skillID, monsterID)
    end,

    -- 根据Key获取技能数据
    ["SKILL_DATA_BY_KEY"] = function (key)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSkillByKey(key)
    end,
    -- 自定义技能 table key-skillID value-skillID
    ["ALL_CUSTOM_SKILLS"] = function()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetAllCustomSkill()
    end,
    -- 对应职业所有配置技能 -- 3:所有职业
    ["SKILL_CONFIGS_BY_JOB"] = function(job)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:FindAllSkillsByJob(job)
    end,
    -- 是否释放衔接技能
    ["IS_LAUNCH_CONTINUE_SKILL"] = function(skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:IsLaunchContinueSkill(skillID)
    end,

    -------------------------------------------------------------------
    -- 骑马能否释放该技能
    ["HORSE_CAN_LAUNCH_SKILL"] = function(skillID)
        local HorseProxy = global.Facade:retrieveProxy( global.ProxyTable.HorseProxy)
        return HorseProxy:IsLaunch(skillID)
    end,
    -- 检查BUFF 技能能否释放
    ["BUFF_CHECK_SKILL_ENABLE"] = function(skillID)
        local buffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        return buffProxy:CheckSkillEnable(skillID)
    end,
    -- 手动释放时 目标是否有不能释放该技能BUFF
    ["TARGET_FORBID_SKILL_LAUNCH_BUFF"] = function(targetID, skillID)
        return global.BuffManager:CheckLaunchBuffBySkillID(targetID, skillID)
    end,
    -- 自动释放时 目标是否有不能释放该技能BUFF
    ["TARGET_FORBID_SKILL_AUTO_BUFF"] = function(targetID, skillID)
        return global.BuffManager:CheckAutoBuffBySkillID(targetID, skillID)
    end,
    -- 手动释放时 该BUFF不能释放技能时的提示
    ["BUFF_SKILL_UNABLE_TITLE"] = function(buffID)
        local buffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        return buffProxy:GetNoSkillBuffTitle(buffID)
    end,
    -----------------------------------------------------------------------------
    ["CHECK_AUTO_TRAIN_ABLE"] = function()
        local AssistProxy = global.Facade:retrieveProxy(global.ProxyTable.AssistProxy)
        return not AssistProxy:checkIsBusy()
    end,

    -----------------------------------------------------------------------------
    --背包红点数据
    ["BAG_RED_DOTS"] = function(param1)
        local RedDotProxy = global.Facade:retrieveProxy(global.ProxyTable.RedDotProxy)
        return RedDotProxy:GetBagRedDot()
    end,
    --回收的列表
    ["RETRIEVE_LIST"] = function()
        local EquipRetrieveProxy = global.Facade:retrieveProxy(global.ProxyTable.EquipRetrieveProxy)
        return EquipRetrieveProxy:GetRetrieveList()
    end,
    ["STORAGE_OPEN_SIZE"] = function()
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        return NPCStorageProxy:GetOpenSize()
    end,
    --仓库存储类型
    ["STORAGE_TOUCH_TYPE"] = function()
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        return NPCStorageProxy:GetTouchType()
    end,

    -----------------------------------------------------------------------------
    ----------- 内挂设置 ------------
    -- 设置是否生效
    ["SETTING_ENABLED"] = function(param1)
        return CHECK_SETTING(param1)
    end,
    -- 设置的数据
    ["SETTING_VALUE"] = function(param1)
        return GET_SETTING(param1)
    end,
    -- 设置的配置
    ["SETTING_CONFIG"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:GetConfigByID(param1)
    end,
    -- 获取拾取的设置值
    ["SETTING_PICK_VALUE"] = function(param1)
        return CHECK_SETTING_PICK(param1)
    end,
    -- 物品是否可以勾选
    ["SETTING_IS_ITEM_PICK_CAN_SET"] = function(param1)
        return CHECK_ITEM_PICK_CANSET(param1)
    end,
    -- 捡物品配置
    ["SETTING_PICK_CONFIG"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:GetPickConfig()
    end,
    --获取拾取组的数据
    ["SETTING_PICK_GROUP_VALUE"] = function(param1)
        return CHECK_GROUPSETTING_PICK(param1)
    end,
    --获取排序的设置相关数据,param1: ID
    ["SETTING_RANK_DATA"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:getRankData(param1)
    end,
    --获取boss提示类型
    ["SETTING_BOSS_REMIND_TYPE"] = function()
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:GetBossType()
    end,
    --获取boss提示值 
    ["SETTING_BOSS_REMIND_VALUE"] = function()
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:GetBossTipsValues()
    end,
    -- 通过值获取地图缩放对应百分比
    ["SETTING_MAPSCALE_PER"] = function(param1)
        if not param1 then
            return nil
        end
        return ((param1 - 0.7) / (2.3 - 0.7)) * 100
    end,
    -- 通过百分比获取地图缩放值
    ["SETTING_MAPSCALE_VALUE"] = function(param1)
        if not param1 then
            return nil
        end
        return 0.7 + (2.3 - 0.7) * (param1 / 100)
    end,
    -- 获取玩家名字颜色配置 
    ["SETTING_PLAYER_NAME_COLOR_VALUE"] = function()
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:GetPlayerNameColorValues()
    end,
    -------------------------------

    -----------------------------------------------------------------------------
    -- 物品类型枚举
    ["ITEMTYPE_ENUM"] = function()
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:GetItemSettingType()
    end,
    -- 物品类型
    ["ITEMTYPE"] = function(param1)
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:GetItemType(param1)
    end,
    -- 是否回城石
    ["ITEM_IS_CITY_STONE"] = function(itemIndex)
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:IsCityStoneByIndex(itemIndex)
    end,
    -- 是否随机石
    ["ITEM_IS_RAND_STONE"] = function(itemIndex)
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:IsRandStoneByIndex(itemIndex)
    end,
    -- 物品是GM特殊设定的回城/随机道具
    ["ITEM_IS_CUSTOM_CITY_OR_RAND"] = function(itemIndex)
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:IsCustomCityOrRandItemByIndex(itemIndex)
    end,

    --道具移动状态
    ["ITEM_MOVE_STATE"] = function()
        local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return ItemMoveProxy:GetMovingItemState()
    end,
    --移动的道具来源
    ["ITEM_MOVE_FROM"] = function()
        local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return ItemMoveProxy:GetItemMoveFrom()
    end,
    --移动的道具数据
    ["ITEM_MOVE_DATA"] = function()
        local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return ItemMoveProxy:GetMovingItemData()
    end,
    -- 上次移动穿戴的道具数据 MakeIndex
    ["LAST_MOVE_TAKEON_ITEM_MAKEINDEX"] = function()
        local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return ItemMoveProxy:GetLastMovingTakeOnItem()
    end,
    -- 物品自定义变量列表
    ["ITEM_CUSTOM_VARLIST"] = function(key)
        local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
        return MetaValueProxy:GetCustomVarByKey(key)
    end,
    -- 物品自定义变量 key: MakeIndex vName: 变量名
    ["ITEM_CUSTOM_VAR_BY_VNAME"] = function(key, vName)
        local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
        return MetaValueProxy:GetItemCustomVarByVName(key, vName)
    end,
    -- 物品自定义属性组对应Tips显示 key: MakeIndex  type: 自定义属性组id 0~99
    ["ITEM_CUSTOM_DIYSHOW_BY_TYPE"] = function(key, type)
        local MetaValueProxy = global.Facade:retrieveProxy(global.ProxyTable.MetaValueProxy)
        -- 服务端定义好的变量名： SYS_TIP0 ~ SYS_TIP99  PC端：SYS_PCTIP前缀
        local vName = global.isWinPlayMode and string.format("SYS_PCTIP%s", type) or string.format("SYS_TIP%s", type)
        local value = MetaValueProxy:GetItemCustomVarByVName(key, vName)
        if global.isWinPlayMode and not value then  -- PC变量没数据, 取移动端变量
            value = MetaValueProxy:GetItemCustomVarByVName(key, string.format("SYS_TIP%s", type))
        end
        return value
    end,
    -----------------------------------------------------------------------------
    -- 除装备Map 显示持久的stdmode
    ["EX_SHOWLAST_MAP"] = function()
        return GUIDefine.EquipMapExByStdmode
    end,
    -- 装备Map
    ["EQUIPMAP_BY_STDMODE"] = function()
        return GUIDefine.EquipMapByStdMode
    end,
    -- 获取装备对比属性
    ["EQUIP_COMPARISON"] = function(param1)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:GetItemComparison(param1)
    end,

    -- 通过stdmode获取TIP装备Pos列表
    ["TIP_POSLIST_BY_STDMODE"] = function(param1)
        return GUIDefine.TipsEquipPosByStdMode[param1] or GUIDefine.EquipPosByStdMode[param1]
    end,
    -- 装备战力(param1: equipData； param2: param; param3: isHero)
    ["EQUIP_POWER"] = function(param1, param2, param3)
        if GUIFunction.GetEquipPower then
            return GUIFunction:GetEquipPower(param1, param2, param3)
        end
        return 0
    end,
    -- 通过MakeIndex获取仓库数据
    ["STORAGE_DATA_BY_MAKEINDEX"] = function(param1)
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        local itemData = NPCStorageProxy:GetStorageDataByMakeIndex(param1)
        return clone(itemData)
    end,
    -- 能放在quickuse的道具
    ["CAN_USE_ITEMS_ON_QUICK"] = function()
        local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
        return AttrConfigProxy:GetItemsConfigQuickUsable()
    end,
    -- 通过MakeIndex获取查看他人装备数据
    ["LOOKPLAYER_DATA_BY_MAKEINDEX"] = function(param1)
        local itemData = LookPlayerData.GetEquipDataByMakeIndex(param1)
        return clone(itemData)
    end,
    -- 是否是该性别装备
    ["IS_SAMESEX_EQUIP"] = function(param1, param2, param3)
        return GUIFunction:CheckEquipNeedSex(param1, param2 and GUIDefine.EquipDataType.HEROEQUIP or GUIDefine.EquipDataType.EQUIP, param3)
    end,

    -----------------------------------------------------------------------------
    -- 根据属性 ID 获取属性配置(cfg_att_score表)
    ["ATTR_CONFIG"] = function(param1)
        if not param1 then
            return nil
        end
        local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
        local config = AttrConfigProxy:GetAttConfigByAttId(param1)
        return config
    end,
    -- 获取属性配置(cfg_att_score表)
    ["ATTR_CONFIGS"] = function()
        local AttrConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.AttrConfigProxy)
        return AttrConfigProxy:GetAttConfig()
    end,
    -- 自定义属性ID映射Map
    ["CUST_ABIL_MAP"] = function()
        local ItemTipsProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemTipsProxy)
        return ItemTipsProxy:GetCustAbilMap()
    end,
    -- 检查禁止使用物品buff 返回能否使用, buffID
    ["CHECK_USE_ITEM_BUFF"] = function(itemIndex)
        if not itemIndex then
            return false
        end
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        local ret, buffID = BuffProxy:CheckUseItemEnable(itemIndex)
        return ret, buffID
    end,
    -- 物品能否自动使用
    ["ITEM_CAN_AUTOUSE"] = function(item)
        local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
        return ItemConfigProxy:CheckItemAutoUse(item)
    end,
    -- 技能书能否使用
    ["SKILLBOOK_CAN_USE"] = function(itemName, isHero)
        local SkillProxy = isHero and global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy) or global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:CheckAbleToUseBookByName(itemName)
    end,
    -- 物品归属
    ["ITEM_BELONG_BY_MAKEINDEX"] = function(param1)
        if not param1 then
            return
        end
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        return ItemManagerProxy:GetItemBelong(param1)
    end,
    -- 检查物品是否在GUI ItemBox内, param1: makeIndex 物品唯一ID
    ["CHECK_ITEM_IN_GUIITEMBOX"] = function(makeIndex)
        return (global.SUIManager:GetGUIItemBoxIndexByMakeIndex(makeIndex) ~= nil)
    end,
    
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- 获取对应套装id配置（cfg_suitex表）
    ["SUITEX_CONFIG"] = function(param1)
        if not param1 then
            return nil
        end
        local ItemTipsProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemTipsProxy)
        return ItemTipsProxy:GetNewSuitConfigById(param1)
    end,
    -- 服务器开关
    ["SERVER_OPTIONS"] = function(key)
        local ServerOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerOptionsProxy)
        return ServerOptionsProxy:CheckOption(key)
    end,

    -----------------------------------------------------------------------------
    -- actor
    ["ACTOR_IS_VALID"] = function(param)
        local actor = GetActor(param)
        return actor ~= nil
    end,
    ["ACTOR_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        return actor:GetName()
    end,
    ["ACTOR_LEVEL"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetLevel()
    end,
    ["ACTOR_JOB_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not actor:IsPlayer() then
            return 0
        end
        return actor:GetJobID()
    end,
    ["ACTOR_SEX"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not actor:IsPlayer() then
            return 0
        end
        return actor:GetSexID()
    end,
    -- actor是 玩家
    ["ACTOR_IS_PLAYER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsPlayer()
    end,
    -- actor是 怪物
    ["ACTOR_IS_MONSTER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsMonster()
    end,
    -- actor是 NPC
    ["ACTOR_IS_NPC"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsNPC()
    end,
    -- actor是 掉落物
    ["ACTOR_IS_DROPITEM"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsDropItem()
    end,
    -- actor是 特效
    ["ACTOR_IS_EFFECT"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsSEffect()
    end,
    -- actor是 人形怪
    ["ACTOR_IS_HUMAN"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsHumanoid()
    end,
    -- actor是 英雄
    ["ACTOR_IS_HERO"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsHero()
    end,
    -- actor是 网络玩家
    ["ACTOR_IS_NETPLAYER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsNetPlayer()
    end,
    -- actor是 镖车
    ["ACTOR_IS_ESCORT"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsEscort()
    end,
    -- actor是 采集物
    ["ACTOR_IS_COLLECTION"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsCollection()
    end,
    -- actor是 守卫
    ["ACTOR_IS_DEFENDER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsDefender()
    end,
    -- actor是 捡物小精灵
    ["ACTOR_IS_PICKUPSPRITE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsPickUpSprite()
    end,
    -- actor是 宠物
    ["ACTOR_IS_PET"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsPet()
    end,
    -- actor是 沙巴克大门
    ["ACTOR_IS_GATE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsGate()
    end,
    -- actor是 沙巴克城墙
    ["ACTOR_IS_WALL"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsWall()
    end,
    -- actor BOSS怪
    ["ACTOR_IS_BOSS"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsBoss()
    end,
    -- actor 精灵怪
    ["ACTOR_IS_ELITE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsElite()
    end,
    -- actor 死亡
    ["ACTOR_IS_DIE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsDie()
    end,
    -- actor 骨头
    ["ACTOR_IS_DEATH"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsDeath()
    end,
    -- actor 出生
    ["ACTOR_IS_BORN"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsBorn()
    end,
    -- actor 钻回洞穴
    ["ACTOR_IS_CAVE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:IsCave()
    end,
    -- actor 被忽略
    ["ACTOR_IS_IGNORED"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        return actor:IsIgnored()
    end,
    ["ACTOR_IS_PAUSE_IGNORED"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        return actor:IsPauseIgnored()
    end,
    ["ACTOR_HP"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetHP()
    end,
    ["ACTOR_MAXHP"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetMaxHP()
    end,
    ["ACTOR_MP"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetMP()
    end,
    ["ACTOR_MAXMP"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetMaxMP()
    end,
    -- 当前内力值
    ["ACTOR_IFORCE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not actor:IsPlayer() then
            return 0
        end
        return actor:GetInternal()
    end,
    -- 最大内力值
    ["ACTOR_MAX_IFORCE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not actor:IsPlayer() then
            return 0
        end
        return actor:GetMaxInternal()
    end,
    ["ACTOR_HUD_HP_MP_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_HMPLabel_VISIBLE)
    end,
    ["ACTOR_HUD_MPBAR_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_MPBAR_VISIBLE)
    end,
    ["ACTOR_HUD_NAME_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_NAMELabel_VISIBLE)
    end,
    ["ACTOR_HUD_GUILD_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_GUILDLabel_VISIBLE)
    end,
    ["ACTOR_HUD_TITLE_LABEL_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_TITLELabel_VISIBLE)
    end,
    ["ACTOR_HUD_TITLE_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_TITLE_VISIBLE)
    end,
    ["ACTOR_HUD_PC_MOUSE_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_PC_MOUSE_SHOW)
    end,
    ["ACTOR_HUD_SNEAK_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_SNEAK)
    end,
    ["ACTOR_HUD_FULL_HP_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetValueByKey(global.MMO.HUD_BAR_SHOW_FULL_HP)
    end,
    -- actor归属ID
    ["ACTOR_OWNER_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsMonster() or actor:IsPlayer() or actor:IsNPC() or actor:IsDropItem()) then
            return nil
        end
        local ownerID = actor:GetOwnerID()
        if not ownerID or ownerID == "" or ownerID == -1 or ownerID == global.MMO.ACTOR_ID_INVALID then
            return nil
        end
        return ownerID
    end,
    -- actor归属名字
    ["ACTOR_OWNER_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        if not (actor:IsMonster() or actor:IsPlayer() or actor:IsNPC() or actor:IsDropItem()) then
            return nil
        end
        return actor:GetOwnerName()
    end,
    ["ACTOR_BIGICON_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsMonster() then
            return nil
        end
        return actor:GetBigTipIcon()
    end,
    -- 获取组队状态 返回 0未组队, 1组队中
    ["ACTOR_TEAM_STATE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetTeamState()
    end,
    -- 行会ID
    ["ACTOR_GUILD_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        return actor:GetGuildID()
    end,
    -- 行会名字
    ["ACTOR_GUILD_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        return actor:GetGuildName()
    end,
    -- typeIndex，对应怪物表/NPC表 ID
    ["ACTOR_TYPE_INDEX"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not (actor:IsMonster() or actor:IsNPC() or actor:IsHumanoid() or actor:IsDropItem()) then
            return 0
        end
        return actor:GetTypeIndex()
    end,
    -- 方向
    ["ACTOR_DIR"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetDirection()
    end,
    -- 地图坐标X
    ["ACTOR_MAP_X"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetMapX()
    end,
    -- 地图坐标Y
    ["ACTOR_MAP_Y"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetMapY()
    end,
    -- 世界坐标X
    ["ACTOR_POSITION_X"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:getPositionX()
    end,
    -- 世界坐标Y
    ["ACTOR_POSITION_Y"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:getPositionY()
    end,
    -- 上次地图坐标X
    ["ACTOR_LAST_MAP_X"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetLastMapX()
    end,
    -- 上次地图坐标Y
    ["ACTOR_LAST_MAP_Y"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        return actor:GetLastMapY()
    end,
    -- 主人ID
    ["ACTOR_MASTER_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return ""
        end
        return actor:GetMasterID()
    end,
    -- 有主人
    ["ACTOR_HAVE_MASTER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return false
        end
        return actor:IsHaveMaster()
    end,
    -- 阵营，大于0且相等是同阵营
    ["ACTOR_FACTION"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return 0
        end
        return actor:GetFaction()
    end,
    -- 是否在安全区
    ["ACTOR_IN_SAFE_ZONE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return false
        end
        return actor:GetInSafeZone()
    end,
    ["ACTOR_IS_WAR_ZONE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return false
        end
        return actor:IsWarZone()
    end,
    ["ACTOR_ORIGIN_NAME_STRING"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return actor:GetONameStr()
    end,
    -- NPC只显示气泡名内容
    ["ACTOR_ONLY_SHOW_BUBBLE_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsNPC() then
            return nil
        end
        return actor:GetOnlyShowBubbleName()
    end,
    -- 外观ID
    ["ACTOR_APPR_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return false
        end
        return actor:GetAnimationID()
    end,
    -- 武器ID
    ["ACTOR_WEAPON_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsPlayer() then
            return nil
        end
        return actor:GetAnimationWeaponID()
    end,
    -- 左手武器ID
    ["ACTOR_LEFT_WEAPON_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsPlayer() then
            return nil
        end
        return actor:GetAnimationLeftWeaponID()
    end,
    -- shield
    ["ACTOR_SHIELD_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsPlayer() then
            return nil
        end
        return actor:GetAnimationShieldID()
    end,
    -- wing
    ["ACTOR_WINGS_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsPlayer() then
            return nil
        end
        return actor:GetAnimationWingsID()
    end,
    -- hair
    ["ACTOR_HAIR_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not actor:IsPlayer() then
            return nil
        end
        return actor:GetAnimationHairID()
    end,
    -- actor挂接点
    ["ACTOR_MOUNT_NODE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC() or actor:IsDropItem()) then
            return false
        end
        return actor:GetMountNode()
    end,
    -- 英雄选中的目标是否能锁定
    ["ACTOR_CAN_LOCK_BY_HERO"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        return proxyUtils:CheckHeroLockTargetEnable(actor)
    end,
    -- 玩家关系类型
    ["ACTOR_RELATION_TAG"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return global.MMO.RS_NO
        end
        return proxyUtils.CheckEnemyTag(actor)
    end,
    -- player
    -- 红名灰名 白=0  咖啡=1  红=2  灰=3
    ["ACTOR_PKLV"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return 0
        end
        if not (actor:IsPlayer()) then
            return 0
        end
        return actor:GetPKLv()
    end,
    -- 区服ID，跨服时使用
    ["ACTOR_SERVER_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return ""
        end
        return actor:GetServerID()
    end,
    -- 是否在摆摊
    ["ACTOR_IS_IN_STALL"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsStallStatus()
    end,
    -- 摆摊名字
    ["ACTOR_STALL_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return ""
        end
        if not (actor:IsPlayer()) then
            return ""
        end
        return actor:GetStallName()
    end,
    -- 是否是离线状态玩家
    ["ACTOR_IS_OFFLINE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:GetIsOffLine()
    end,
    -- 是否是神秘人
    ["ACTOR_IS_MYSTERY_MAN"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsShenMiRen()
    end,
    -- 是否拥有护身
    ["ACTOR_IS_HUSHEN"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsHuShen()
    end,
    -- 是否是主玩家
    ["ACTOR_IS_MAINPLAYER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsMainPlayer()
    end,
    -- 是否是我的英雄
    ["ACTOR_IS_MAINHERO"] = function(param)
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return param == HeroPropertyProxy:GetRoleUID()
    end,
    -- 是否是骑马状态
    ["ACTOR_IS_HORSEBACK_RADING"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return global.BuffManager:IsHaveOneBuff(param, global.MMO.BUFF_ID_HORSE)
    end,
    -- 国家ID
    ["ACTOR_NATION_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return nil
        end
        return actor:GetNationID()
    end,
    -- 坐骑 主驾ID
    ["ACTOR_HORSE_MASTER_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetHorseMasterID()
    end,
    -- 坐骑 副驾ID
    ["ACTOR_HORSE_COPILOT_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetHorseCopilotID()
    end,
    -- 是否是坐骑 副驾
    ["ACTOR_IS_HORSE_COPILOT"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:IsHoreseCopilot()
    end,
    -- 是否是双人坐骑
    ["ACTOR_IS_DOUBLE_HORSE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsDoubleHorse()
    end,
    -- 是否是连体坐骑
    ["ACTOR_IS_BODY_HORSE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:IsBodyHorse()
    end,
    -- 足迹特效 脚印特效
    ["ACTOR_MOVE_EFFECT"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetMoveEff()
    end,
    -- 移动足迹特效 是否跳过一步 [服务端开关]
    ["ACTOR_MOVE_EFFECT_SKIP_WALK_SWITCH"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return (actor:GetEffSkipWalkSwitch() or 0) == 0
    end,
    -- 移动足迹特效 是否跳过一步走路 状态
    ["ACTOR_MOVE_EFFECT_SKIP_WALK_STATUS"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        return actor:GetMoveEffSkipWalk() == true
    end,
    -- 夫妻 ID
    ["ACTOR_DEAR_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetDearID()
    end,
    -- 师徒 ID
    ["ACTOR_MENTOR_ID"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetSiTuID()
    end,
    -- 对应类型关系网数据 string  param1: 关系网类型id param2: 下标 1-2 [同类型关系最多只能两个]
    ["ACTOR_JOIN_NET_TYPE_DATA"] = function(param, param1, param2)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:GetJoinNetTypeData(param1, param2)
    end,
    -- 是否在附近显示
    ["ACTOR_NEAR_SHOW"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return actor:IsNearShow()
    end,
    -- 是否移动状态
    ["ACTOR_IS_MOVE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer()) then
            return nil
        end
        return GUIFunction:IsMoveAction(actor:GetAction())
    end,
    -- 动作ID
    ["ACTOR_ACTION"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return nil
        end
        return actor:GetAction()
    end,
    -- 动画的动作ID
    ["ACTOR_ANIM_ACT"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return nil
        end
        return actor:GetAnimAct()
    end,
    -- 动画速度
    ["ACTOR_ANIM_SPEED"] =  function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return nil
        end
        local animation = actor:GetAnimation()
        if not animation then
            return nil
        end
        return animation:GetSpeed()
    end,
    -- monster
    -- 怪物 是否是石化状态
    ["ACTOR_STOME_MODE"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsMonster()) then
            return nil
        end
        return actor:GetStoneMode()
    end,
    -- 怪物 RACE SERVER
    ["ACTOR_RACE_SERVER"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsMonster()) then
            return nil
        end
        return actor:GetRaceServer()
    end,
    -- 怪物 RACEIMG
    ["ACTOR_RACE_IMG"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsMonster()) then
            return nil
        end
        return actor:GetRaceImg()
    end,
    -- 怪物 不显示名字
    ["ACTOR_HIDE_NAME"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsMonster()) then
            return false
        end
        return actor:IsNoShowName()
    end,
    -- 怪物 不显示血条
    ["ACTOR_HIDE_HP_BAR"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsMonster()) then
            return false
        end
        return actor:IsNoShowHPBar()
    end,
    -- 怪物 国家模式是否可被攻击
    ["ACTOR_NATION_ENEMY_PK"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsMonster()) then
            return false
        end
        return actor:IsNationEnemyPK()
    end,
    -- ACTOR GM数据
    ["ACTOR_GM_DATA"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return nil
        end
        return actor:GetGMData()
    end,
    -- ACTOR 外观数据
    ["ACTOR_FEATURE_DATA"] = function(param)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster() or actor:IsNPC()) then
            return false
        end
        return G_ActorUtils.GetFeatureByActorID(param)
    end,


    --------------------------------------------------------------------
    -- 当前选择ACTOR, 附近 人/怪/NPC 等
    ["SELECT_TARGET_ID"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if not PlayerInputProxy then
            return nil
        end
        return PlayerInputProxy:GetTargetID()
    end,

    ["TARGET_MOVE_POS"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if not PlayerInputProxy then
            return nil
        end
        return PlayerInputProxy:GetCurrMovePos()
    end,

    ["TARGET_ATTACK_ENABLE"] = function(value)
        if not value then
            return false
        end
        return proxyUtils.CheckLaunchTargetByID(value)
    end,
    ["SELECT_SHIFT_ATTACK_ID"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if not PlayerInputProxy then
            return nil
        end
        return PlayerInputProxy:GetAttackTargetID()
    end,
    -- 持续攻击状态 pc
    ["ATTACK_STATE"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        if not PlayerInputProxy then
            return nil
        end
        return PlayerInputProxy:IsAttackState()
    end,
    -- 按坐标选择Actor ID
    ["PICK_ACTORID_BY_POS"] = function(posX, posY)
        if not posX or not posY then
            return nil
        end
        local actor = global.actorPickerController:Pick(posX, posY)
        if not actor then
            return nil
        end
        return actor:GetID()
    end,
    -- 附近人
    ["FIND_IN_VIEW_PLAYER_LIST"] = function()
        if not global.playerManager then
            return {}, 0
        end
        local actors, num = global.playerManager:FindAllPlayerIDInCurrViewField()
        return actors, num
    end,
    ["FIND_IN_VIEW_HERO_LIST"] = function()
        if not global.playerManager then
            return {}, 0
        end
        local actors, num = global.playerManager:FindAllHeroIDInCurrViewField()
        return actors, num
    end,
    ["FIND_IN_VIEW_HUMANOID_LIST"] = function()
        if not global.playerManager then
            return {}
        end
        return global.playerManager:FindAllHumanoidIDInCurrViewField()
    end,
    -- 附近怪物, param1=noPetOfMainPlayer, param2=noPetOfNetPlayer
    ["FIND_IN_VIEW_MONSTER_LIST"] = function(param1, param2)
        if not global.monsterManager then
            return {}, 0
        end
        local actors, num = global.monsterManager:FindAllMonsterIDInCurrViewField(param1, param2)
        return actors, num
    end,
    -- 附近对应typeIndex怪物 param1= typeIndx(number/table)  param2=noPetOfMainPlayer, param3=noPetOfNetPlayer
    ["FIND_IN_VIEW_MONSTER_LIST_BY_TYPEINDEX"] = function(param1, param2, param3)
        if not global.monsterManager then
            return {}, 0
        end
        local actors, num = global.monsterManager:FindMonsterIDInCurrViewFieldByTypeIndex(param1, param2, param3)
        return actors, num
    end,
    ["FIND_IN_VIEW_NPC_LIST"] = function()
        if not global.npcManager then
            return {}, 0
        end
        local actors, num = global.npcManager:FindAllNpcIDInCurrViewField()
        return actors, num
    end,
    ["FIND_IN_VIEW_COLLECT_LIST"] = function()
        if not global.monsterManager then
            return {}, 0
        end
        local actors, num = global.monsterManager:FindMonsterIDInCurrViewFieldByRace(global.MMO.ACTOR_RACE_COLLECTION)
        return actors, num
    end,
    ["CURRENT_TALK_NPC_ID"] = function()
        local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        if not NPCProxy then
            return nil
        end
        return NPCProxy:GetCurrentNPCID()
    end,
    ["CURRENT_TALK_NPC_TYPEINDEX"] = function()
        local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        if not NPCProxy then
            return nil
        end
        return NPCProxy:GetCurrentNPCIndex()
    end,
    ["CURRENT_TALK_NPC_LAYER"] = function()
        local NPCLayerMediator = global.Facade:retrieveMediator("NPCLayerMediator")
        if not NPCLayerMediator._layer then
            return nil
        end
        return NPCLayerMediator._layer
    end,
    -- 地图坐标XY获取怪物 param1: mapX, param2: mapY, param3: 是否所有 boolean [所有返回table: 怪物ID列表, 否则单个怪物ID]
    ["MONSTER_BY_MAPXY"] = function(mapX, mapY, isAll)
        if not mapX or not mapY then
            return nil
        end
        return global.actorManager:GetMonsterActorIDByMapXY(mapX, mapY, isAll)
    end,
    -- 地图坐标XY获取玩家 参数同上
    ["PLAYER_BY_MAPXY"] = function(mapX, mapY, isAll)
        if not mapX or not mapY then
            return nil
        end
        return global.actorManager:GetPlayerActorIDByMapXY(mapX, mapY, isAll)
    end,
    -------------------------------------------------------------------------------------------------
    -- 获取buff数据; param1:目标UserID
    ["ACTOR_BUFF_DATA"] = function(param1)
        local targetID = param1
        if not targetID then
            targetID = global.gamePlayerController:GetMainPlayerID()
        end
        if not targetID then
            return {}
        end

        local Buff = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        local data, n = global.BuffManager:GetDataByUID(targetID)
        local items = {}
        for i = 1, n do
            local v = data[i]
            local config = Buff:GetConfigByID(v.id) or {}

            local item  = {}
            item.id         = v.id
            item.endTime    = v.endTime
            item.ol         = v.ol
            item.param      = v.param
            item.config     = config
            item.name       = config.name
            item.tips       = config.tips
            item.icon       = config.icon
            item.sort       = config.sort
            item.other_look = config.other_look
            items[i] = item
        end

        return items
    end,
    -- 主玩家是否拥有某BUFF param1: buffID
    ["MAIN_ACTOR_HAS_ONE_BUFF"] = function(param1)
        local targetID = global.gamePlayerController:GetMainPlayerID()
        if not targetID then
            return false
        end

        return global.BuffManager:IsHaveOneBuff(targetID, param1)
    end,
    -- 目标是否拥有某BUFF param1:目标UserID, param2: buffID
    ["ACTOR_HAS_ONE_BUFF"] = function(param1, param2)
        local targetID = param1
        if not targetID then
            targetID = global.gamePlayerController:GetMainPlayerID()
        end
        if not targetID then
            return false
        end

        return global.BuffManager:IsHaveOneBuff(targetID, param2)
    end,
    -- 获取对应buff数据; param1:目标UserID param2: buffID
    ["ACTOR_BUFF_DATA_BY_ID"] = function(param1, param2)
        local targetID = param1
        local buffID = param2
        if not targetID then
            targetID = global.gamePlayerController:GetMainPlayerID()
        end
        if not targetID or not buffID then
            return nil
        end

        local Buff = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        local item = global.BuffManager:GetItem(targetID, buffID)
        local config = Buff:GetConfigByID(buffID) or {}
        if item then
            local bdata     = item:GetData()
            local endTime   = item:GetEndTime()
            local ol        = item:GetOl()
            local param     = item:GetParam()

            local data      = {}
            data.id         = buffID
            data.endTime    = endTime
            data.ol         = ol
            data.config     = config
            data.name       = config.name
            data.tips       = config.tips
            data.icon       = config.icon
            data.sort       = config.sort
            data.other_look = config.other_look

            return data
        end

        return nil
    end,
    -- 获取BUFFID的配置数据
    ["BUFF_CONFIG"] = function(param1)
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        if param1 then
            return clone(BuffProxy:GetConfigByID(param1))
        end
        return clone(BuffProxy:GetConfig())
    end,
    -- 检查禁止聊天buff 返回能否聊天, 禁止聊天buffID
    ["BUFF_CHECK_CHAT_ENABLE"] = function()
        local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
        return BuffProxy:CheckChatEnable()
    end,


    -------------------------------------------------------------------------------------------------
    -- 战斗
    -- 是否自动挂机中
    ["BATTLE_IS_AFK"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:IsAFKState()
    end,
    -- 是否自动寻路中
    ["BATTLE_IS_AUTO_MOVE"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:IsAutoMoveState()
    end,
    -- 是否自动捡物
    ["BATTLE_IS_AUTO_PICK"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:IsPickState()
    end,
    ["BATTLE_IS_AUTO_FIGHT_STATE"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:IsAutoFightState()
    end,
    ["AUTO_TARGET"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:GetAutoTarget()
    end,
    -- 挂机目标死亡
    ["AFK_TARGET_DEATH"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:GetAFKTargetDeath()
    end,
    -- 黑夜状态
    ["DARK_STATE"] = function()
        local DarkLayerProxy = global.Facade:retrieveProxy(global.ProxyTable.DarkLayerProxy)
        local value = DarkLayerProxy:getCurState()
        return value
    end,
    -- 点击状态
    ["TOUCH_STATE"] = function()
        return global.userInputController:IsTouching()
    end,
    -- 鼠标位置
    ["MOUSE_MOVE_POS"] = function()
        return global.userInputController and global.userInputController:GetCursorPos()
    end,
    -- 是否按下SHIFT
    ["IS_PRESSED_SHIFT"] = function()
        return global.userInputController:IsPressedShift()
    end,
    -- 鼠标移入actorID
    ["MOUSE_INSIDE_ACTORID"] = function()
        return global.actorPickerController:GetLastMouseInsideActor()
    end,
    -- 鼠标对应方向
    ["MOUSE_WORLD_DIR"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetCursorWorldDirection()
    end, 


    ["BESTRONG_DATA"] = function()
        local RemindUpgradeProxy = global.Facade:retrieveProxy(global.ProxyTable.RemindUpgradeProxy)
        return RemindUpgradeProxy:GetButtonData()
    end,
    --掉落物 飞向的世界坐标 优先级比txt设置的高 
    ["DROPITEM_FLY_WORLD_POSITION"] = function()
        local PickupSpriteProxy = global.Facade:retrieveProxy(global.ProxyTable.PickupSpriteProxy)
        return PickupSpriteProxy:getMetaPositon()
    end,
    -- 拾取小精灵系统模式 = 新模式
    ["PICKUPSPRITE_IS_SYSTEM_MODE"] = function()
        local PickupSpriteProxy = global.Facade:retrieveProxy(global.ProxyTable.PickupSpriteProxy)
        return PickupSpriteProxy:IsPickUpNewType()
    end,
    -- 是否学习内功
    ["IS_LEARNED_INTERNAL"] = function()
        local level = SL:GetValue("CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_LEVEL)
        if level and level > 0 then
            return true
        end
        return false
    end,
    -- 英雄 是否学习内功
    ["H.IS_LEARNED_INTERNAL"] = function()
        local level = SL:GetValue("H.CUR_ABIL_BY_ID", GUIDefine.AttTypeTable.Internal_LEVEL)
        if level and level > 0 then
            return true
        end
        return false
    end,
    -- 交易行开启状态
    ["TRADINGBANK_OPENSTATUS"] = function()
        local TradingBankProxy = nil
        if global.OtherTradingBank then -- 三方 交易行
            TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
        else
            TradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.TradingBankProxy)
        end
        return TradingBankProxy:getOpenStatus()
    end,


    ----------------------------------------------------------
    -- 摆摊
    -- 购买摊位名字
    ["STALL_SELL_SHOW_NAME"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetShowStoreName()
    end,
    -- 购买摊位物品数据
    ["STALL_ONSELL_DATA"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetOnSellData()
    end,
    -- 我的摊位物品数据
    ["STALL_MYSELL_DATA"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetMySellData()
    end,
    -- 我的摆摊状态
    ["STALL_MY_TRADING_STATUS"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetMyTradingStatus()
    end,
    -- 我的摆摊是否已满
    ["STALL_IS_FULL"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:CheckListViewFull()
    end,
    -- 摆摊的货币
    ["STALL_MONEY"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetCurrencies()
    end,
    -- 摆摊的userid
    ["STALL_USER_ID"] = function()
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        return StallProxy:GetNowOpenStoreId()
    end,


    ----------------------------------------------------------
    -- 宝箱
    -- 检查是否还有重摇/开启次数
    ["HAVE_GOLDBOX_OPENTIME"] = function()
        local GoldBoxProxy = global.Facade:retrieveProxy(global.ProxyTable.GoldBoxProxy)
        return GoldBoxProxy:CheckHaveOpenTime()
    end,


    ----------------------------------------------------------
    -- MapPos 目标位置到初始位置 方向
    ["TARGET_MAPPOS_DIR"] = function(srcPos, destPos)
        if not srcPos or not destPos then 
            return 
        end
        return G_ActorUtils.CalcMapDirection(destPos.x, destPos.y, srcPos.x, srcPos.y)
    end,
    -- 跑步移动格数
    ["RUN_STEP"] = function()
        return G_ActorUtils.CheckRunStep()
    end,
    -- 能否跑
    ["CAN_RUN_ABLE"] = function()
        return G_ActorUtils.CheckRunAble()
    end,
    -- 是否可开门 通过方向和步数
    ["CAN_OPEN_DOOR_BY_DIR"] = function(moveDir, moveStep)
        return G_ActorUtils.CheckOpenDoorByDir(moveDir, moveStep)
    end,
    -- 主玩家目标位置 通过方向和步数
    -- 返回 x, y
    ["CALC_DEST_POS_BY_DIR"] = function(moveDir, moveStep)
        return G_ActorUtils.CalcDestPosByDir(moveDir, moveStep)
    end,
    -- CTRL键按下
    ["CTRL_PRESSED"] = function ()
        return global.userInputController:IsPressedCtrl()
    end,


    ----------------------------------------------------------
    -- 属性加点
    -- 是否启用新版属性加点
    ["IS_NEW_BOUNS"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:IsNewBouns()
    end,
    -- 新版属性加点配置数据
    ["NEW_BOUNS_CONFIG"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetConfig()
    end,
    -- 新版属性已加点数据
    ["NEW_BOUNS_ADD_DATA"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetNewAddData()
    end,
    --属性点
    ["BONUS_POINT"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetBonusPoint()
    end,
    -- 旧版数据
    ["BONUS_DATAS"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetData()
    end,
    --服务器传的已加点数
    ["BONUS_ABIL_DATA"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetBonusAbilData()
    end,
    --加点基底
    ["BONUS_TICK_DATA"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetBonusTickData()
    end,
    --用于计算五属性加值
    ["BONUS_NAKED_ABIL_DATA"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetNakedAbilData()
    end,
    --计算前的基础属性值
    ["BONUS_ADJUST_ABIL_DATA"] = function()
        local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
        return ReinAttrProxy:GetAdjustAbilData()
    end,
    ----------------------------------------------------------

    -------------------------------------------------------------------------------------------------
    --掉落物是否可拾取 param=掉落物    param1=归属id
    ["IS_PICKABLE_DROPITEM"] = function(param, param1)
        local dropItem = GetActor(param)
        if not dropItem then
            return false
        end

        if not dropItem:IsDropItem() then
            return false
        end

        if dropItem:IsIgnored() then
            return false
        end

        if BagData.isToBeFull() and dropItem:GetTypeIndex() ~= 0 then -- 背包满可以捡金币
            return false
        end

        -- check pick state
        if dropItem:GetPickState() >= 1 or dropItem:IsPickTimeout() then
            return false
        end

        -- check owner
        if not proxyUtils:AutoPickItemEnable( dropItem, param1 ) then
            return false
        end

        return true
    end,

    -- 掉落物是否极品装备
    ["DROPITEM_IS_QUALITY"] = function(param)
        local dropItem = GetActor(param)
        if not dropItem then
            return false
        end

        if not dropItem:IsDropItem() then
            return false
        end

        return dropItem:GetQualityState()
    end,

    ----------------------------------------------------------
    -- 求购
    -- 菜单列表
    ["PURCHASE_FILTER_LIST"] = function()
        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        return PurchaseProxy:GetFirstFilterItem()
    end,
    -- 对应ID 菜单栏配置
    ["PURCHASE_MENU_CONFIG_BY_ID"] = function(id)
        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        return PurchaseProxy:GetCTypeByID(id)
    end,
    -- 分类物品列表 key 一级菜单id_二级菜单id
    ["PURCHASE_ITEM_LIST_BY_TYPE"] = function(param1, param2)
        local key = string.format("%s_%s", param1, param2)
        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        return PurchaseProxy:GetItemListByType(key)
    end,
    ["PURCHASE_CURRENCIES"] = function()
        local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
        return clone(PurchaseProxy:GetCurrencies())
    end,


    ----------------------------------------------------------
    -- 其他玩家 查看玩家职业
    ["T.M.JOB"] = function ()
        return TradingBankLookPlayerData.GetPlayerJob()
    end,
    -- 其他玩家 通过部位获取装备列表信息
    ["T.M.EQUIP_DATA_LIST_BY_POS"] = function (pos)
        return GUIFunction:GetEquipDataListByPos(pos, GUIDefine.EquipDataType.TRADE_EQUIP)
    end,
    -- 其他玩家 通过部位获取装备信息
    ["T.M.EQUIP_DATA_BY_POS"] = function (pos)
        return TradingBankLookPlayerData.FindEquipDataByPos(pos)
    end,
    -- 英雄 通过部位获取装备列表信息
    ["T.H.EQUIP_DATA_LIST_BY_POS"] = function (pos)
        return GUIFunction:GetEquipDataListByPos(pos, GUIDefine.EquipDataType.TRADE_HEROEQUIP)
    end,
    -- 英雄 通过部位获取装备信息
    ["T.H.EQUIP_DATA_BY_POS"] = function (pos)
        return TradingBankLookPlayerData.FindHeroEquipDataByPos(pos)
    end,


    -----------------------------------------------------------------------------
    -- HUD飘字
    ["DAMAGE_TYPE_BY_ID"] = function(damageID)
        local DamageNumProxy = global.Facade:retrieveProxy(global.ProxyTable.DamageNumProxy)
        return DamageNumProxy:GetDamageType(damageID)
    end,

    -- 获取英雄合击技能ID
    ["HERO_JOINT_SKILL"] = function()
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:haveHeroSkill()
    end,

    -- 是否是合击技能
    ["IS_HERO_SKILL"] = function(skillID)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:isHeroSkill(skillID)
    end,

    ["SELECT_SKILL"] = function ()
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:GetSelectSkill()
    end,
    ["CLOUD_DATA_BY_KEY"] = function (key)
        return GET_CLOUD_DATA(key)
    end,
    -- 交易行是否打开
    ["TRADING_BANK_IS_OPEN"] = function ()
        local mediator = global.Facade:retrieveMediator("TradingBankFrameMediator")
        return mediator._layer ~= nil
    end,
    --移动action是否可释放野蛮
    ["MOVE_ACTION_FORBID_DASH"] = function ()
        local ServerOptionsProxy = global.Facade:retrieveProxy(global.ProxyTable.ServerOptionsProxy)
        return ServerOptionsProxy:GetMoveActionForbidDash() == 1
    end,

    -----------------------------------------------------------------------------
    -- 拍卖行
    -- 获取拍卖行职业过滤
    ["AUCTION_JOB_ABLE"] = function ()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        local value = AuctionProxy:GetJobAble();
        return value
    end,

    --获取拍卖行列表请求是否成功
    ["AUCTION_IS_COMPLETE"] = function ()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        local value = AuctionProxy:IsComplete();
        return value
    end,

    --获取拍卖行品阶
    ["AUCTION_QUALITIES"] = function ()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        local value = AuctionProxy:GetQualities();
        return value
    end,

    --获取拍卖行货币
    ["AUCTION_CURRENCIES"] = function ()
        local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
        local value = AuctionProxy:GetCurrencies();
        return value
    end,
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- 获取商店分页数据
    ["STORE_PAGE_DATA_BY_INDEX"] = function (param1)
        local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
        local value = PageStoreProxy:GetPageData(param1)
        return value
    end,
    -- 获取指定下标商品数据
    ["STORE_ITEM_DATA_BY_INDEX"] = function (param1)
        local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
        local value = PageStoreProxy:GetItemDataByStoreIndex(param1)
        return value
    end,
    -- 商品能否购买（未超出限制购买次数）
    ["STORE_ITEM_CAN_BUY"] = function (param1)
        local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
        local value = PageStoreProxy:CheckStoreLimitStatus(param1)
        return value
    end,
    -----------------------------------------------------------------------------

    -----------------------------------------------------------------------------
    -- 充值
    -- 充值提示
    ["RECHARGE_TIP"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("recharge_tip")
    end,

    -- 充值渠道
    ["PAY_CHANNEL"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_CHANNEL
    end,

    -- 支付宝
    ["PAY_CHANNEL_ALIPAY"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_CHANNEL.ALIPAY
    end,

    -- 花呗
    ["PAY_CHANNEL_HUABEI"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_CHANNEL.HUABEI
    end,

    -- 微信
    ["PAY_CHANNEL_WEIXIN"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_CHANNEL.WEIXIN
    end,

    -- 二维码
    ["PAY_TYPE_QRCODE"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_TYPE.QRCODE
    end,

    -- 原生
    ["PAY_TYPE_NATIVE"] = function()
        local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
        return AuthProxy.PAY_TYPE.NATIVE
    end,


    -----------------------------------------------------------------------------
    --移动方向
    ["MOVE_DIRECTION"] = function ()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetUserInputMoveDir()
    end,
    --移动步数
    ["MOVE_STEP"] = function ()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetUserInputMoveStep()
    end,
    ["FACE_DEST"] = function ()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetMainPlayerFaceDest()
    end,
    -- 寻路阻塞
    ["IS_MOVE_BLOCKED"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:IsMoveBlocked()
    end,
    -- 是否限制移动(与镖车距离超出限制距离)
    ["CHECK_OUT_ESCORT_LIMIT_MOVE"] = function(destMapX, destMapY)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:CheckEscortLimitMove(destMapX, destMapY)
    end,
    -- 上次远距离的施法移动位置
    ["LAST_LAUNCH_MOVE_FAR_POS"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLastLaunchMoveFarPos()
    end,

    ------------------------------------------------------------------------------
    -- npc点击间隔
    ["NPC_CLICK_SPEED"] = function ()
        local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
        return mapProxy:GetClickNpcSpeed()
    end,

    -- 仓库数据
    ["NPC_STORAGE_DATA"] = function ()
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        return NPCStorageProxy:GetStorageData()
    end,

    -- 通过page获取仓库数据
    ["NPC_STORAGE_DATA_BY_PAGE"] = function (data)
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        return NPCStorageProxy:GetStorageDataByPage(data)
    end,

    -- npc出售步骤
    ["NPC_SELLING_STEP"] = function ()
        local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
        return NPCSellProxy:GetSellingStep()
    end,

    -- NPC出售数据
    ["NPC_SELLING_DATA"] = function ()
        local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
        return NPCSellProxy:GetOnSellingData()
    end,

    -- NPC出售价格
    ["NPC_SELLING_PRICE"] = function ()
        local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
        return NPCSellProxy:GetSellingPrice()
    end,

    -- npc修理步骤
    ["NPC_REPAIRE_STEP"] = function ()
        local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
        return NPCRepaireProxy:GetRepaireStep()
    end,

    -- NPC修理数据
    ["NPC_REPAIRE_DATA"] = function ()
        local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
        return NPCRepaireProxy:GetOnRepairingData()
    end,

    -- NPC修理价格
    ["NPC_REPAIRE_PRICE"] = function ()
        local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
        return NPCRepaireProxy:GetRepairingPrice()
    end,

    -- NPC自定义数据
    ["NPC_DOSOMETHING_DATA"] = function ()
        local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
        return NPCDoSomethingProxy:GetonDoThingsData()
    end,

    -- NPC自定义步骤
    ["NPC_DOSOMETHING_STEP"] = function ()
        local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
        return NPCDoSomethingProxy:GetDoThingsStep()
    end,

    -- NPC 新类型步骤
    ["NPC_NEWTYPE_STEP"] = function ()
        local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
        return NPCNewTypeOkProxy:GetDoThingsStep()
    end,

    -- NPC 新类型数据
    ["NPC_NEWTYPE_DATA"] = function ()
        local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
        return NPCNewTypeOkProxy:GetonDoThingsData()
    end,
    ----------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------
    -- 采集物数量
    ["COLLECTION_NUMS"] = function ()
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return inputProxy:GetCollectCount()
    end,

    -- 设置怪物归属
    ["TARGET_OWNER_ID"] = function ()
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return inputProxy:GetOwnerPlayerID()
    end,
    -- 自动追踪归属玩家
    ["AUTO_TRACE_TARGET_OWNER"] = function ()
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return inputProxy:IsTraceOwnerPlayer()
    end,

    ----------------------------------------------------------------------------------
    --996盒子
    ["BOX996_LAYER"] = function ()
        local  Box996MainLayerMediator = global.Facade:retrieveMediator("Box996MainLayerMediator")
        return Box996MainLayerMediator._layer
    end,

    ["CUR_ABIL_BY_ID"] = function(param1)
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetCurAbilByID(tonumber(param1))
    end,
    ["MAX_ABIL_BY_ID"] = function(param1)
        local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
        return PlayerProperty:GetMaxAbilByID(tonumber(param1))
    end,
    ["H.CUR_ABIL_BY_ID"] = function(param1)
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetCurAbilByID(tonumber(param1))
    end,
    ["H.MAX_ABIL_BY_ID"] = function(param1)
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:GetMaxAbilByID(tonumber(param1))
    end,

    ----------------------------------------------------------------------------------
    -- 称号列表数据
    ["TITLES"] = function()
        return TitleData.GetTitleList(GUIDefine.TitleType.PLAYER)
    end,
    -- 激活的称号id
    ["TITLE_ACTIVATE_ID"] = function()
        return TitleData.GetActiveTitle(GUIDefine.TitleType.PLAYER)
    end,
    -- 英雄 称号列表数据
    ["H.TITLES"] = function()
        return TitleData.GetTitleList(GUIDefine.TitleType.HERO)
    end,
    -- 英雄 激活的称号id
    ["H.TITLE_ACTIVATE_ID"] = function()
        return TitleData.GetActiveTitle(GUIDefine.TitleType.HERO)
    end,

    -- 获取玩家称号数据 通过ID
    ["TITLE_DATA_BY_ID"] = function(id)
        if not id then
            return
        end
        return TitleData.GetTitleData(GUIDefine.TitleType.PLAYER)[id]
    end,
    -- 获取玩家法阵数据
    ["EQUIP_EMBATTLE"] = function ()
        return EquipData.GetEmbattle()
    end,
    ----------------------------------------------------------------------------------
    --当前查看玩家职业
    ["L.M.JOB"] = function ()
        return LookPlayerData.GetLookPlayerJob()
    end,
    --当前查看玩家发型
    ["L.M.HAIR"] = function ()
        return LookPlayerData.GetPlayerHair()
    end,
    --当前查看玩家等级
    ["L.M.LEVEL"] = function ()
        return LookPlayerData.GetPlayerLevel()
    end,
    --当前查看玩家性别
    ["L.M.SEX"] = function ()
        return LookPlayerData.GetPlayerSex()
    end,
    --当前查看玩家数据
    ["L.M.PLAYER_DATA"] = function ()
        return LookPlayerData.GetPlayerData()
    end,
    --当前查看玩家的行会信息
    ["L.M.GUILD_INFO"] = function ()
        local data = {}
        data.rankName = LookPlayerData.GetPlayerGuildRankName() -- 职位
        data.guildName = LookPlayerData.GetPlayerGuildName()    -- 行会名字
        return data
    end,
    --当前查看玩家法阵数据
    ["L.M.EMBATTLE"] = function ()
        return LookPlayerData.GetEmbattle()
    end,
    -- 获取当前查看玩家的装备位数据
    ["L.M.EQUIP_POS_DATAS"] = function()
        return LookPlayerData.GetEquipPosData()
    end, 
    --当前查看他人角色名字颜色ID
    ["LOOK_TARGET_NAME_COLOR"] = function ()
        return LookPlayerData.GetPlayerNameColor()
    end,
    --当前查看他人角色名字
    ["LOOK_TARGET_NAME"] = function ()
        return LookPlayerData.GetPlayerName()
    end,
    --当前查看他人角色ID
    ["LOOK_TARGET_ID"] = function ()
        return LookPlayerData.GetPlayerUID()
    end,
    -- 获取正在查看玩家的某一装备位数据
    ["L.M.EQUIP_DATA"] = function(param1, param2)
        if not param1 then
            return
        end
        if tonumber(param1) then
            return GUIFunction:GetEquipDataByPos(param1, param2, GUIDefine.EquipDataType.OTHER_EQUIP)
        else
            return GUIFunction:GetEquipDataByName(param1, GUIDefine.EquipDataType.OTHER_EQUIP)
        end
    end,
    ["L.M.EQUIP_DATA_LIST"] = function(param1)
        if not param1 then
            return
        end
        return GUIFunction:GetEquipDataListByPos(param1, GUIDefine.EquipDataType.OTHER_EQUIP)
    end,
    -- 获取当前查看玩家的称号
    ["L.M.TITLES"] = function()
        return LookPlayerData.GetTitle()
    end,
    -- 获取当前查看玩家激活的称号
    ["L.M.TITLE_ACTIVATE_ID"] = function ()
        return LookPlayerData.GetActiveTitle()
    end,
    

    ----------------------------------------------------------------------------------
    -- 背包所有物品
    ["BAG_DATA"] = function()
        return BagData.GetBagData()
    end,
    --背包已使用格子数
    ["BAG_USED_COUNT"] = function()
        return BagData.GetTotalItemCount()
    end,
    --背包剩余格子数
    ["BAG_REMAIN_COUNT"] = function()
        local bagItemNum = BagData.GetTotalItemCount()
        local maxBag = BagData.GetMaxBag()
        local remainCount = math.max(maxBag - bagItemNum, 0)
        return remainCount
    end,
    --背包是否满
    ["BAG_IS_FULL"] = function(tips)
        return BagData.isToBeFull(tips)
    end,
    -- 当前选中的背包页
    ["BAG_CUR_PAGE"] = function()
        return BagData.GetCurPage()
    end,
    -- 背包最大格子数量
    ["MAX_BAG"] = function()
        return BagData.GetMaxBag()
    end,
    --检测物品背包是否有富余格子数存放
    ["BAG_CHECK_NEED_SPACE"] = function(itemID, itemCount, tips)
        if not itemID or not itemCount then
            return true
        end
        return BagData.CheckNeedSpace(itemID, itemCount, tips)
    end,
    --获取背包物品唯一ID
    ["BAG_MAKEINDEX_BY_POS"] = function(pos)
        return BagData.GetMakeIndexByBagPos(pos)
    end,
    -- 通过MakeIndex获取背包数据 isHero:是否英雄
    ["ITEM_DATA_BY_MAKEINDEX"] = function(MakeIndex, isHero)
        if isHero then
            return clone(HeroBagData.GetItemDataByMakeIndex(MakeIndex))
        else
            return clone(BagData.GetItemDataByMakeIndex(MakeIndex))
        end
    end,
    -- 通过MakeIndex获取装备数据 isHero:是否英雄
    ["EQUIP_DATA_BY_MAKEINDEX"] = function(MakeIndex, isHero)
        if isHero then
            return clone(HeroEquipData.GetEquipDataByMakeIndex(MakeIndex))
        else
            return clone(EquipData.GetEquipDataByMakeIndex(MakeIndex))
        end
    end,

    ----------------------------------------------------------------------------------
    -- 英雄背包所有物品
    ["H.BAG_DATA"] = function()
        return HeroBagData.GetBagData()
    end,
    -- 英雄背包最大格子数量
    ["HERO_MAX_BAG"] = function()
        return HeroBagData.GetMaxBag()
    end,

    ----------------------------------------------------------------------------------
    -- 允许添加状态
    ["ADD_STATUS_PERMIT"] = function()
        return FuncDockData.GetAllowAddFriend()
    end,
    -- 允许组队状态
    ["TEAM_STATUS_PERMIT"] = function()
        return FuncDockData.GetAllowTeam()
    end,
    
    ----------------------------------------------------------------------------------
    --是否关闭假掉落
    ["CHAT_IS_CLOSE_FAKE_DROP"] = function()
        return ChatData.IsCloseFakeDrop()
    end,
    --获取当前聊天CD时间
    ["CHAT_CUR_CD_TIME"] = function()
        return ChatData.GetCurrCDTime()
    end,
    --获取聊天目标
    ["CHAT_TARGETS"] = function()
        return ChatData.GetTargets()
    end,
    --获取当前聊天频道
    ["CHAT_CUR_CHAT_CHANNEL"] = function()
        return ChatData.GetCurChannel()
    end,
    --是否接收该分类掉落信息
    ["CHAT_DROP_TYPE_IS_RECEIVE"] = function(type)
        if not type then
            return false
        end
        return ChatData.GetDropTypeSwitch(type)
    end,
    --当前频道是否接受聊天信息
    ["CHAT_CHANNEL_IS_RECEIVE"] = function(channel)
        return ChatData.IsReceiving(channel)
    end,
    --获取聊天输入历史记录缓存
    ["CHAT_INPUT_CACHE"] = function()
        return clone(ChatData.GetInputCache())
    end,
    --获取聊天表情包
    ["CHAT_EMOJI"] = function()
        return clone(ChatData.GetEmoji())
    end,
    --内观装备偏移配置
    ["UIMODEL_EQUIP_OFFSET"] = function()
        return EquipData.GetEquipModelOffSet()
    end,
    --内观头发偏移配置
    ["UIMODEL_HAIR_OFFSET"] = function()
        return EquipData.GetModelHairOffSet()
    end,

    -- 红点 服务器下发的变量
    ["SERVER_VALUE"] = function(param)
        if not param then
            return nil
        end
        local ConditionProxy = global.Facade:retrieveProxy(global.ProxyTable.ConditionProxy)
        local value = ConditionProxy:getOriginValueByKey(param)
        return value
    end,

    ----------------------------------------------------------
    -- 关系
    ["RELATION_TYPE_LIST"] = function()
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetTypeList()
    end,
    ["RELATION_TYPE_NAME"] = function(type)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetTypeName(type)
    end,
    ["RELATION_TYPE_FUNC_DESC"] = function(type)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetTypeFuncDesc(type)
    end,
    ["RELATION_TYPE_CONFIG"] = function(type)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetConfigByType(type)
    end,
    ["RELATION_TYPE_DATA"] = function(type)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetRelationDataByType(type)
    end,
    -- 我邀请建立的关系列表
    ["RELATION_MY_NETLIST"] = function()
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetMyRelationList()
    end,
    -- 允许被邀请建立关系状态 type: 关系类型ID
    ["RELATION_INVITED_PERMIT_BY_TYPE"] = function(type)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetAllowStatusByType(type)
    end,
    -- 设置是否允许关系召集
    ["RELATION_CALL_PERMIT_BY_TYPE"] = function(type, status)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        return RelationProxy:GetAllowCallStatusByType(type, status)
    end,

    ----------------------------------------------------------
    -- 飞行技能击中失败ActorID
    ["SKILL_HIT_MISS_ACTORID"] = function()
        return global.actorSkillController:GetHitMissUserID()
    end,
    -- 首发释放技能 return param1: 技能ID param2: 目标位置x param3: 目标位置Y param4: 时间
    ["AUTO_LAUNCH_FIRST_SKILL"] = function()
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return autoProxy:GetLaunchFirstSkill()
    end,
    -- 闪避技能释放时间戳
    ["AUTO_LAUNCH_AVOID_STAMP"] = function()
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return autoProxy:GetLaunchAvoidStamp()
    end,
    -- 锁定目标状态
    ["BATTLE_IS_AUTO_LOCK_STATE"] = function()
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return autoProxy:IsAutoLockState()
    end,
    ["AUTO_LOCK_SKILLID"] = function()
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return autoProxy:GetAutoLockSkillID()
    end,
    ["AUTO_COMBO_LAUNCH_SKILLID"] = function()
        local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return skillProxy:GetComboLanunchID()
    end,
    ["CHECK_SKILL_SDS_TIME"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:CheckDu()
    end,
    -- 自动挖矿数据, 返回 param1: dir方向 param2: pos位置 table
    ["AUTO_MINING_DATA"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        return AutoProxy:GetAutoMining() 
    end,
    ["INPUT_LAUNCH_SKILLID"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLaunchSkillID()
    end,
    ["INPUT_LAUNCH_TYPE"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLaunchType()
    end,
    ["INPUT_LAUNCH_PRIORITY"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLaunchPriority()
    end,
    -- return x, y
    ["INPUT_LAUNCH_TARGET_POS"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLaunchTargetPos()
    end,
    ["INPUT_LAUNCH_TARGET_ID"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetLaunchTargetID()
    end,
    ["INPUT_MOUSE_TOUCH_POS"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetMouseTouchPos()
    end,
    -- 鼠标点击方式 -1:鼠标右键 1:鼠标左键/单击
    ["INPUT_MOUSE_TOUCH_WAY"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:GetMouseTouchWay()
    end,

    ---------
    ["FIND_BEST_ATTACK_POS"] = function(srcX, srcY, dstX, dstY, maxLaunchDis, minLaunchDis)
        if not srcX or not srcY or not dstX or not dstY then
            return nil
        end
        return G_ActorUtils.FindBestAttackPos(srcX, srcY, dstX, dstY, maxLaunchDis, minLaunchDis)
    end,
    ["FIND_BEST_SKILL_POS"] = function(srcX, srcY, dstX, dstY, maxLaunchDis, minLaunchDis)
        if not srcX or not srcY or not dstX or not dstY then
            return nil
        end
        return G_ActorUtils.FindBestSkillPos(srcX, srcY, dstX, dstY, maxLaunchDis, minLaunchDis)
    end,
    ["FIND_DESTPOS_BY_PARAM"] = function(sX, sY, moveDir, moveStep)
        if not sX or not sY or not moveDir or not moveStep then
            return nil
        end
        return global.PathFindController:FindDestPosJoystick(sX, sY, moveDir, moveStep)
    end,
    ["IS_ACTOR_LIMIT_OBSTACLE"] = function(srcX, srcY, dstX, dstY)
        if not srcX or not srcY or not dstX or not dstY then
            return nil
        end
        return global.PathFindController:CheckActorLimitObstacle(srcX, srcY, dstX, dstY)
    end,

    -- 是否在引导中 [SGuide]
    ["CHECK_IN_GUIDE"] = function()
        return Guide and Guide.isActive()
    end,

    ["996_BOX_PLATFORM"] = function()
        return global.L_GameEnvManager:GetEnvDataByKey("device")
    end,

    --交易所
    -- 默认货架数量
    ["EXCHANGE_DEFAULT_SHELF"] = function()
        return ExchangeData.GetLimitShelf()
    end,

    -- 菜单列表
    ["EXCHANGE_FILTER_LIST"] = function()
        return ExchangeData.GetFirstFilterItem()
    end,
    -- 对应ID 菜单栏配置
    ["EXCHANGE_MENU_CONFIG_BY_ID"] = function(id)
        return ExchangeData.GetCTypeByID(id)
    end,
    ["EXCHANGE_CURRENCIES"] = function()
        return ExchangeData.GetCurrencies()
    end,

    ["EXCHANGE_MY_SHOW_LIST"] = function()
        return ExchangeData.GetShowBagItems()
    end,
    -- 交易所物品状态 返回参数1：状态 0.未知 2.竞拍中 3.已超时，参数2：剩余时间
    ["EXCHANGE_ITEM_STATE"] = function(item)
        return ExchangeData.CalcItemStatus(item)
    end,
    
    -- 雷电VIP
    ["LD_VIP_LEVEL"] = function()
        local levelData, isHave = global.L_NativeBridgeManager:GetVIPLevel()
        release_print("leidianstate", isHave, levelData)
        return isHave, levelData
    end,
}

if SL then
    for k, v in pairs(MetaValueGetDef) do
        local key = string.gsub(k, "%.", "_")
        SL[string.format("Get_%s", key)] = function(self, ...)
            return v(...)           
        end
    end
end