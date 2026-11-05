local proxyUtils = requireUtil("proxyUtils")
local optionsUtils = requireUtil("optionsUtils")

-- param: actorID
local GetActor = function(param)
    local actor = global.actorManager:GetActor(param)
    if not actor then
        return nil
    end
    return actor
end

local inputMoveT = {}

MetaValueSetDef = {
    -- 设置当前选中的背包页
    ["STORGE_PAGE_CUR"] = function(param1)
        local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        NPCStorageProxy:SetStoragePageIndex(param1)
    end,

    ["GAME_DATA"] = function(key, value)
        global.ConstantConfig[key] = value
    end,
    --------------------------------------------------- 
    -- 设置的数据 param1=设置ID  param2=设置值 table
    ["SETTING_VALUE"] = function(param1, param2)
        CHANGE_SETTING(param1, param2)
    end,
    -- 设置捡物品数据 param1=设置ID  param2=值
    ["SETTING_PICK_VALUE"] = function(param1, param2)
        CHANGE_SETTING_PICK(param1, param2)
    end,
    -- 设置捡物品 组 数据 param1=设置ID  param2=值
    ["SETTING_PICK_GROUP_VALUE"] = function(param1, param2)
        CHANGE_GROUPSETTING_PICK(param1, param2)
    end,
    --设置 排序的设置相关数据（param1: ID, param2: data）
    ["SETTING_RANK_DATA"] = function(param1, param2)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:setRankData(param1, param2)
    end,
    --设置boss提示类型
    ["SETTING_BOSS_REMIND_TYPE"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        return GameSettingProxy:SetBossType(param1)
    end,
    --设置boss提示值 
    ["SETTING_BOSS_REMIND_VALUE"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        GameSettingProxy:SetBossTipsValues(param1)
    end,
    -- 获取玩家名字颜色配置 
    ["SETTING_PLAYER_NAME_COLOR_VALUE"] = function(param1)
        local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
        GameSettingProxy:SetPlayerNameColorValues(param1)
    end,
    --技能快捷键
    ["SKILL_KEY"] = function(param1, param2)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:SetSkillKey(param1, param2)
    end,
    --是否点击了英雄守护按钮 
    ["HERO_GUARD_ISCLICK"] = function(param1)
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:setGuardBtnState(param1)
    end,
    --英雄激活的状态
    ["HERO_ACTIVES_STATES"] = function(param1)
        local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
        return HeroPropertyProxy:setStates(param1)
    end,
    --英雄设置技能快捷键
    ["H.SKILL_KEY"] = function(param1, param2)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:SetSkillKey(param1, param2)
    end,
    -- 开始自动挂机
    ["BATTLE_AFK_BEGIN"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        if AutoProxy:IsAFKState() then
            return
        end
        LuaSendMsg(global.MsgType.MSG_CS_AUTOPLAYGAME_REQUEST, 1)
        global.Facade:sendNotification(global.NoticeTable.AFKBegin)
    end,
    -- 结束自动挂机
    ["BATTLE_AFK_END"] = function()
        LuaSendMsg(global.MsgType.MSG_CS_AUTOPLAYGAME_REQUEST, 2)
        global.Facade:sendNotification(global.NoticeTable.AFKEnd)
    end,
    -- 开始自动捡物
    ["BATTLE_PICK_BEGIN"] = function()
        global.Facade:sendNotification(global.NoticeTable.AutoPickBegin)
    end,
    -- 结束自动捡物
    ["BATTLE_PICK_END"] = function()
        global.Facade:sendNotification(global.NoticeTable.AutoPickEnd)
    end,
    -- 开始自动寻路
    ["BATTLE_MOVE_BEGIN"] = function(mapID, mapX, mapY, target, type)
        local movePos =    {
            mapID = mapID,
            x    = mapX,
            y    = mapY,
            autoMoveType = type or global.MMO.AUTO_MOVE_TYPE_MINIMAP
        }
        global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, movePos)
    
        -- auto target
        if target then
            local targetType  = target.type == 0 and global.MMO.ACTOR_MONSTER or global.MMO.ACTOR_NPC
            local targetIndex = target.index
            local moveType    = global.MMO.AUTO_MOVE_TYPE_TARGET
            local autoTarget  =        
            {
                x             = mapX,
                y             = mapY,
                mapID         = mapID,
                targetType    = targetType,
                targetIndex   = targetIndex,
                priority      = global.MMO.INPUT_PRIORITY_USER,
                autoMoveType  = moveType
            }
            local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
            AutoProxy:SetAutoTarget(autoTarget)
        end
    end,
    -- 结束自动寻路
    ["BATTLE_MOVE_END"] = function()
        global.Facade:sendNotification(global.NoticeTable.AutoMoveEnd)
    end,
    -- 挂机目标死亡
    ["AFK_TARGET_DEATH"] = function(status)
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        AutoProxy:SetAFKTargetDeath(status)
    end,
    -- 挂机检测无目标移动
    ["AFK_CHECK_AIMLESS_MOVE"] = function()
        local AssistProxy = global.Facade:retrieveProxy(global.ProxyTable.AssistProxy)
        AssistProxy:CheckAimlessMove()
    end,
    -- 选择目标ID
    ["SELECT_TARGET_ID"] = function(targetID)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:SetTargetID(targetID)
    end,
    -- PC持续攻击目标
    ["SELECT_SHIFT_ATTACK_ID"] = function(attachID)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        return PlayerInputProxy:SetAttackTargetID(attachID)
    end,
    -- 设置战斗状态
    ["ATTACK_STATE"] = function(state)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:SetAttackState(state)
    end,
    -- 设置转向方向
    ["TURN_DIR"] = function(dir)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:SetMouseTurnDir(dir)
    end,
    -- 清除当前移动
    ["CLEAR_CUR_MOVE"] = function()
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:ClearMove()
    end,

    ["LAST_LAUNCH_MOVE_FAR_POS"] = function(x, y)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:SetLastLaunchMoveFarPos(x, y)
    end,

    -- 设置剪贴板文本
    ["CLIPBOARD_TEXT"] = function(str)
        if str then
            if global.isWindows then
                if Win32BridgeCtl then
                    Win32BridgeCtl:Inst():copyToClipboard(str)
                end
            else
                global.L_NativeBridgeManager:GN_setClipboardText(str)
            end
        end
    end,
    --掉落物 飞向的世界坐标 优先级比txt设置的高
    ["DROPITEM_FLY_WORLD_POSITION"] = function(x, y)
        local PickupSpriteProxy = global.Facade:retrieveProxy(global.ProxyTable.PickupSpriteProxy)
        PickupSpriteProxy:setMetaPositon(x, y)
    end,
    -- 内功技能开关
    ["INTERNAL_SKILL_ONOFF"] = function(param1, param2, param3)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return SkillProxy:SetNGSkillOnOff(param1, param2, param3)
    end,
    ["H.INTERNAL_SKILL_ONOFF"] = function(param1, param2, param3)
        local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
        return HeroSkillProxy:SetNGSkillOnOff(param1, param2, param3)
    end,
    -- 通知引导事件开始
    ["GUIDE_EVENT_BEGAN"] = function(guideID, needResetPos)
        local eventName = GUIDefine.GuideEvent[guideID] and GUIDefine.GuideEvent[guideID].start
        if eventName then
            SL:onLUAEvent(LUA_EVENT_GUIDE_EVENT_BEGAN, { name = eventName })
        end
    end,
    -- 通知引导事件结束
    ["GUIDE_EVENT_END"] = function(guideID)
        local eventName = GUIDefine.GuideEvent[guideID] and GUIDefine.GuideEvent[guideID].close
        if eventName then
            SL:onLUAEvent(LUA_EVENT_GUIDE_EVENT_ENDED, { name = eventName })
        end
    end,
    -- 修改屏幕分辨率，只能在PC端使用
    ["WIN_DEVICE_SIZE"] = function(width, height)
        if not global.isWinPlayMode then
            return
        end
        width                   = ConvertToEven(width)
        height                  = ConvertToEven(height)
        local designSize        = cc.size(width, height)

        local glview            = global.Director:getOpenGLView()
        glview:setFrameSize(designSize.width, designSize.height)

        local resolutionData    = {}
        resolutionData.rType    = global.DesignPolicy
        resolutionData.size     = designSize
        global.Facade:sendNotification(global.NoticeTable.ChangeResolution, resolutionData)
    end,
    ["ITEM_BELONG_BY_MAKEINDEX"] = function(MakeIndex, belong)
        local ItemManagerProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemManagerProxy)
        ItemManagerProxy:SetItemBelong(MakeIndex, belong)
    end,
    -- 设置连击技能状态
    ["COMBO_SKILL_STATE"] = function(state)
        local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        skillProxy:SetlaunchComboStatus(state)
    end,
    ------------------------------------
    ["SELECT_SKILL"] = function (skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        SkillProxy:SelectSkill(skillID)
    end,
    ["SKILL_SWITCH"] = function (skillID)
        local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        if SkillProxy:IsOnoffSkill(skillID) then
            return SkillProxy:RequestSkillOnoff(skillID)
        end
    end,
    ["CLOUD_DATA_BY_KEY"] = function (key, data)
        SET_CLOUD_DATA(key, data)
    end,
    -- 技能自定义数据 param1: 技能ID param2: 释放时间
    ["SKILL_CUSTOM_DATA"] = function(param1, param2)
        local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        return skillProxy:SetSkillCustomData(param1, param2)
    end,
    ["SKILL_ON"] = function(skillID, isOn)
        local skillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
        if isOn then
            skillProxy:SkillOn(skillID)
        else
            skillProxy:SkillOff(skillID)
        end
    end,

    ----------------------------------------------------
    -- 登录创角
    ["LOGIN_SELECT_ROLE_BY_INDEX"] = function(index)
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        LoginProxy:SetSelectedRoleByIndex(index)
    end,
    -- 登录-角色设置交易行相关参数
    ["LOGIN_SELECT_ROLE_TRADE_PARAM"] = function()
        local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local selectRoleInfo = LoginProxy:GetSelectedRole()
        if selectRoleInfo.LockChar and selectRoleInfo.LockChar == 4 then
            global.IsReceiveRole = true
            global.IsVisitor = true
        else
            global.IsReceiveRole = false
            local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
            if not shiwan or tonumber(shiwan) ~= 1 then
                global.IsVisitor = false
            end
        end 
    end,


    ----------------------------------------------------
    ["STALL_MY_TRADING_STATUS"] = function(status)
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        StallProxy:SetMyTradingStatus(status)
    end,

    --摆摊设置选中物品唯一ID
    ["STALL_SELECT_ID"] = function(itemIndex)
        local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
        StallProxy:SetSelectItem(itemIndex)
    end,
    ----------------------------------------------------
    --移动方向
    ["MOVE_DIRECTION"] = function (dir)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:SetUserInputMoveDir(dir)
    end,
    --移动步数
    ["MOVE_STEP"] = function (step)
        local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        PlayerInputProxy:SetUserInputMoveStep(step)
    end,
    -- 手动发起移动
    ["USER_TO_MOVE"] = function(destPosX, destPosY, moveType)
        inputMoveT.x = destPosX
        inputMoveT.y = destPosY
        inputMoveT.type = moveType
        global.Facade:sendNotification(global.NoticeTable.UserInputMove, inputMoveT)
        SLBridge:onLUAEvent(LUA_EVENT_USER_INPUT_MOVE, inputMoveT)
    end, 
    
    -----------------------------------------------------
    --npc聊天数据
    ["NPC_TALK_DATA"] = function (data)
        local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        npcProxy:SetCurrentNPCTalkData(data)
    end,
    
    --背景
    ["CURRENT_BACKGROUND"] = function (data)
        local npcProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
        npcProxy:SetCurrentBackground(data)
    end,

    --仓库界面index
    ["STORAGE_PAGE_INDEX"] = function (data)
        local storate = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        storate:SetStoragePageIndex(data)
    end,

    --仓库存取类型
    ["STORAGE_TOUCH_TYPE"] = function (data)
        local storate = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
        storate:SetTouchType(data)
    end,

    -- 设置怪物归属
    ["TARGET_OWNER_ID"] = function (actorID)
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        inputProxy:SetOwnerPlayerID(actorID)
    end,
    -- 自动追踪归属玩家
    ["AUTO_TRACE_TARGET_OWNER"] = function (state)
        local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
        inputProxy:SetTraceOwnerPlayerState(state)
    end,
    -----------------------------------------------------
    --移动的节点数据 不一定是道具
    ["ITEM_MOVE_DATA"] = function(itemData, from, skillId)
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return proxy:SetMoveItemData(itemData, from, skillId)
    end,
    --移动后事件处理
    ["ITEM_MOVE_LINK_FUNC"] = function(linkFunc)
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        return proxy:SetLinkFunc(linkFunc)
    end,
    -- 上次移动穿戴的道具数据 MakeIndex
    ["LAST_MOVE_TAKEON_ITEM_MAKEINDEX"] = function()
        local proxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        proxy:ClearLastMovingTakeOnItem()
    end,
    -----------------------------------------------------
    -- 设置 键盘能否响应 boolean
    ["KEY_BOARD_ABLE"] = function(value)
        global.userInputController:SetKeyboardAble(value)
    end,

    -----------------------------------------------------
    -- 自动使用弹窗 添加物品唯一ID type: 类型 1: 人物 2: 英雄 pos: 装备位 makeIndex
    ["AUTOUSE_MAKEINDEX_BY_POS"] = function(type, pos, makeIndex)
        AutoUseItemData.SetMakeIndexByPos(type, pos, makeIndex)
    end,

    -- 是否接收该分类掉落
    ["CHAT_DROP_TYPE_IS_RECEIVE"] = function(type, value)
        ChatData.SetDropTypeSwitch(type, value)
    end,

    -- 设置当前聊天频道
    ["CHAT_CUR_CHAT_CHANNEL"] = function(channel)
        ChatData.SetCurChannel(channel)
    end,

    -----------------------------------------------------
    --设置允许显示状态
    ["SHOW_STATUS_PERMIT"] = function(status)
        return FuncDockData.SetAllowShowForNear(status)
    end,
    --设置允许交易状态
    ["DEAL_STATUS_PERMIT"] = function(status)
        return FuncDockData.SetAllowTrade(status)
    end,
    --设置允许添加状态
    ["ADD_STATUS_PERMIT"] = function(status)
        return FuncDockData.SetAllowAddFriend(status)
    end,
    --设置允许组队状态
    ["TEAM_STATUS_PERMIT"] = function(status)
        FuncDockData.SetAllowTeam(status)
    end,
    --设置快捷栏个数
    ["QUICK_USE_NUM"] = function(num)
        QuickUseData.SetQuickUseSize(num)
    end,
    --设置功能菜单参数
    ["FUNCDOCK_PARAM"] = function(data)
        FuncDockData.SetParam(data)
    end,
    -- 设置是否允许被邀请建立关系状态
    ["RELATION_INVITED_PERMIT_BY_TYPE"] = function(type, status)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        RelationProxy:SetAllowStatusByType(type, status)
    end,
    -- 设置是否允许关系召集
    ["RELATION_CALL_PERMIT_BY_TYPE"] = function(type, status)
        local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
        RelationProxy:SetAllowCallStatusByType(type, status)
    end,

    -----------------------------------------------------
    --合成打开的ID
    ["COMPOUND_OPEN_ID"] = function(id)
        CompoundItemData.SetOnCompoundID(id)
    end,
    --英雄面板时装显示开关
    ["HERO_SUPEREQUIP_SHOW"] = function(allow)
        FuncDockData.SetAllowShowHeroFashion(allow)
    end,
    --角色面板时装显示开关
    ["PLAYER_SUPEREQUIP_SHOW"] = function(allow)
        FuncDockData.SetAllowShowFashion(allow)
    end,
    -- 设置当前开宝箱数据
    ["TREASUREBOX_ITEM_DATA"] = function(data)
        local GoldBoxProxy = global.Facade:retrieveProxy(global.ProxyTable.GoldBoxProxy)
        GoldBoxProxy:SetBoxItemData(data)
    end,
    -- 设置刷新开宝箱数据-新
    ["TREASUREBOX_REFRESH_ITEM_DATA"] = function(data)
        local GoldBoxProxy = global.Facade:retrieveProxy(global.ProxyTable.GoldBoxProxy)
        GoldBoxProxy:SetRefreshBoxItemData(data)
    end,

    -----------------------------------------------------
    -- 主玩家
    -- 仇恨 ID
    ["HATE_ID"] = function(actorID)
        local player = global.gamePlayerController:GetMainPlayer()
        if not player then
            return nil
        end
        player:SetHateID(actorID)
    end,
    -- Actor
    ["ACTOR_IS_IGNORED"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        return actor:IgnoreActor(state)
    end,
    ["ACTOR_IS_PAUSE_IGNORED"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        return actor:PauseIgnoredActor(state)
    end,
    ["ACTOR_NEED_CHECK_TO_AUTO_FIGHT"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return nil
        end
        actor:SetInViewCheckFlag(state)
    end,
    
    ["ACTOR_HIDE_HP_BAR"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsMonster()) then
            return false
        end
        actor:SetNoShowHPBar(state == true and 1 or 0)
        optionsUtils:InitHUDVisibleValue(actor, global.MMO.HUD_HPBAR_VISIBLE)
        optionsUtils:CheckHUDHpBarVisible(actor)
    end,
    -- 移动足迹特效 是否跳过一步走路 状态
    ["ACTOR_MOVE_EFFECT_SKIP_WALK_STATUS"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer()) then
            return false
        end
        actor:SetMoveEffSkipWalk(state == true)
    end,
    -- 控制Actor动画节点是否显示
    ["ACTOR_ANIMNODE_SHOW"] = function(param, state)
        local actor = GetActor(param)
        if not actor then
            return false
        end
        if not (actor:IsPlayer() or actor:IsMonster()) then
            return false
        end
        actor:SetAvatarChildNodeVisible(state)
    end,
    -----------------------------------------------------
    -- 重置飞行技能击中失败ActorID
    ["RESET_SKILL_HIT_MISS_ACTORID"] = function()
        global.actorSkillController:ResetHitMissUserID()
    end,
    -- 首发释放技能 return param1: 技能ID param2: 目标位置x param3: 目标位置Y
    ["AUTO_LAUNCH_FIRST_SKILL"] = function(skillID, destPosX, destPosY)
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:SetLaunchFirstSkill(skillID, destPosX, destPosY)
    end,
    -- 刷新施毒术时间
    ["UPDATE_SKILL_SDS_TIME"] = function()
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        AutoProxy:UpdateDuTime()
    end,
    -- 重置闪避技能释放时间戳 
    ["AUTO_LAUNCH_AVOID_STAMP"] = function()
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:ResetLaunchAvoidStamp()
    end,
    -- 自动挖矿数据 param1: dir方向 param2: pos目的位置X  param3: pos目的位置Y 
    ["AUTO_MINING_DATA"] = function(dir, dstX, dstY)
        local AutoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        AutoProxy:SetAutoMining(dir, dstX, dstY)
    end,
    -- 锁定目标状态
    ["BATTLE_IS_AUTO_LOCK_STATE"] = function(state)
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:SetIsAutoLockState(state)
    end,
    ["AUTO_LOCK_SKILLID"] = function(skillID)
        local autoProxy = global.Facade:retrieveProxy(global.ProxyTable.AutoProxy)
        autoProxy:SetAutoLockSkillID(skillID)
    end,

    ----------------------------------------------------------------------------------
    -- 背包
    -- 当前选中的背包页
    ["BAG_CUR_PAGE"] = function(page)
        if not page then
            return
        end
        BagData.SetCurPage(page)
    end
}

if SL then
    for k, v in pairs(MetaValueSetDef) do
        local key = string.gsub(k, "%.", "_")
        SL[string.format("Set_%s", key)] = function(self, ...)
            return v(...)
        end
    end
end