SL = SL or {}

-- 常用函数
---------------------------------------------------------------------------
-- 拉起充值面板(payChannel: 支付方式(微信/支付宝); currencyID: 货币ID; price: 支付金额; productIndex: 商品索引/商品ID
function SL:RequestPay(channel, currencyID, price, productIndex)
    if not channel then
        ErrorDebugPrint("[GUI ERROR] SL:RequestPay channel is empty")
        return nil
    end

    if not currencyID then
        ErrorDebugPrint("[GUI ERROR] SL:RequestPay currencyID is empty")
        return nil
    end

    -- 商品是否存在
    local RechargeProxy = global.Facade:retrieveProxy(global.ProxyTable.RechargeProxy)
    local product = RechargeProxy:GetProductByID(currencyID)
    if not product then
        ShowSystemTips("未找到商品: " .. (currencyID or ""))
        return nil
    end

    -- 支付宝/花呗/微信
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    local channels =     {
        AuthProxy.PAY_CHANNEL.ALIPAY,
        AuthProxy.PAY_CHANNEL.HUABEI,
        AuthProxy.PAY_CHANNEL.WEIXIN,
    }
    local payChannel = channels[channel]

    -- 二维码充值回调
    local function qrcodeCB(isOK, filename)
        if isOK then
            -- 二维码拉取成功
            local qrcode_data = {
                filename    = filename,
                channel    = payChannel,
            }
            -- global.Facade:sendNotification(global.NoticeTable.Layer_Recharge_QRCode_Open, qrcode_data)
            UIOperator:OpenRechargeQRCodeUI(qrcode_data)
        end
    end

    -- 支付
    local info =     {
        id        = product.currency_itemid,
        name        = product.currency_name,
        price        = price,
        productIndex = productIndex,
    }
    local paytype = global.isWindows and AuthProxy.PAY_TYPE.QRCODE or AuthProxy.PAY_TYPE.NATIVE
    if global.L_GameEnvManager:GetEnvDataByKey("platform") == "mac" then
        paytype = AuthProxy.PAY_TYPE.QRCODE
    end
    local payData = { paytype = paytype, channel = payChannel, product = info, qrcodeCB = qrcodeCB }
    global.Facade:sendNotification(global.NoticeTable.PayProductRequest, payData)
end

-- 兑换激活码
function SL:RequestCDK(cdk)
    local NoticeProxy = global.Facade:retrieveProxy(global.ProxyTable.NoticeProxy)
    NoticeProxy:RequestCDK(cdk)
end

-- 请求购买商品
function SL:RequestStoreBuy(index, count)
    local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
    PageStoreProxy:RequestBuy(index, count)
end

-- 请求改变PK模式
function SL:RequestChangePKMode(pkmode)
    local PlayerProperty = global.Facade:retrieveProxy(global.ProxyTable.PlayerPropertyProxy)
    PlayerProperty:RequestChangePKMode(pkmode)
end

-- 请求改变宠物战斗模式
function SL:RequestChangePetPKMode(pkmode)
    local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
    return SummonsProxy:RequestModeChange(pkmode)
end

---------------------------------------------------------------------------
-- 请求从仓库取出道具
function SL:RequestPutOutStorageData(data)
    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    return NPCStorageProxy:RequestPutOutStorageData(data.MakeIndex, data.Name)
end

-- 请求道具到仓库
function SL:RequestSaveItemToNpcStorage(data)
    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    NPCStorageProxy:RequestSaveToStorageAllPage(data.MakeIndex, data.Name)
end

-- 请求道具到仓库当前打开页
function SL:RequestSaveItemToNpcStorageCurPage(data)
    local NPCStorageProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCStorageProxy)
    NPCStorageProxy:RequestSaveToStorage(data.MakeIndex, data.Name)
end

function SL:RequestRefreshBagPos()
    ResetBagPos()
end

-- 请求使用准星道具
function SL:RequestUseCollimator(MakeIndex)
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
    BagProxy:RequestCollimator(MakeIndex)
end

-- 请求取消准星瞄准
function SL:RequestCancelCollimator()
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
    BagProxy:RequestCancelCollimator()
end

-- 请求拆分道具
function SL:RequestSplitItem(data, num)
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
    BagProxy:RequestCountItem(data.MakeIndex, num)
end

-- 拆分道具（英雄）
function SL:RequestSplitHeroItem(data, num)
    local HeroBagProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroBagProxy)
    HeroBagProxy:RequestCountItem(data.MakeIndex, num)
end

-- 批量勾选背包物品
function SL:RequestSetBagItemChoose(data)
    SL:onLUAEvent(LUA_EVENT_BAG_ITEM_CHOOSE_STATE, data)
end

-- 丢弃物品
function SL:RequestIntoDropBagItem(itemData)
    if not itemData or not next(itemData) then
        return 
    end
    global.Facade:sendNotification(global.NoticeTable.IntoDropItem, itemData)
end

-- 请求使用道具
function SL:RequestUseItem(itemData, autouse)
    local ItemUseProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemUseProxy)
    return ItemUseProxy:UseItem(itemData, autouse)
end

-- 请求使用英雄道具
function SL:RequestUseHeroItem(itemData, autouse)
    local ItemUseProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemUseProxy)
    ItemUseProxy:HeroUseItem(itemData, autouse)
end

-- 物品使用(通过Index)
function SL:RequestUseItemByIndex(Index)
    local item = nil
    local items = QuickUseData.GetQuickUseDataByIndex(Index)
    if items and next(items) then
        item = items[1]
    end

    if not item then
        local items = BagData.GetItemDataByItemIndex(Index)
        if items and next(items) then
            item = items[1]
        end
    end

    if item then
        SL:RequestUseItem(item)
        return true
    end
    
    return false
end

-- 人物装备穿戴 isFromHero:是否来自英雄背包 
function SL:RequestPlayerTakeOnEquip(itemData, pos, isFromHero)
    local noticeName = isFromHero and global.NoticeTable.TakeOnRequestFromHeroBag or global.NoticeTable.TakeOnRequest
    global.Facade:sendNotification(noticeName,
    {
        itemData = itemData,
        pos = pos
    })
end

-- 人物装备脱下 isToHero:是否脱到英雄背包 
function SL:RequestPlayerTakeOffEquip(itemData, isToHero)
    local noticeName = isToHero and global.NoticeTable.TakeOffToHeroBagRequest or global.NoticeTable.TakeOffRequest 
    global.Facade:sendNotification(noticeName, itemData)
end

-- 英雄装备穿戴 isFromPlayer:是否来自人物背包
function SL:RequestHeroTakeOnEquip(itemData, pos, isFromPlayer)
    local noticeName = isFromPlayer and global.NoticeTable.HeroTakeOnRequestFromHumBag or global.NoticeTable.HeroTakeOnRequest 
    global.Facade:sendNotification(noticeName,
    {
        itemData = itemData,
        pos = pos
    })
end

-- 英雄装备脱下 isToPlayer:是否脱到人物背包
function SL:RequestHeroTakeOffEquipEx(itemData, isToPlayer)
    local noticeName = isToPlayer and global.NoticeTable.HeroTakeOffRequestToHumBag or global.NoticeTable.HeroTakeOffRequest 
    global.Facade:sendNotification(noticeName, itemData)
end

---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 请求玩家首饰盒状态
function SL:RequestOpenPlayerBestRings()
    local EquipProxy = global.Facade:retrieveProxy(global.ProxyTable.EquipProxy)
    EquipProxy:RequestBestRingsOpenState()
end

-- 请求英雄首饰盒状态
function SL:RequestOpenHeroBestRings()
    local HeroEquipProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroEquipProxy)
    HeroEquipProxy:RequestBestRingsOpenState()
end

-- 请求宠物锁定
function SL:RequestLockPetID(targetID)
    local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
    SummonsProxy:ReqLockActorByID(targetID)
end

-- 请求取消宠物锁定
function SL:RequestUnLockPetID(targetID)
    local SummonsProxy = global.Facade:retrieveProxy(global.ProxyTable.SummonsProxy)
    SummonsProxy:ReqUnLockActorByID(targetID)
end

---------------------------------------------------------------------------
-- 召唤英雄或收起
function SL:RequestCallOrOutHero()
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:RequestHeroInOrOut()
end

---------------------------------------------------------------------------
-- 释放技能
function SL:RequestLaunchSkill(skillID)
    local inputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    local destPosX, destPosY = inputProxy:GetCursorMapPosition()
    if global.isWinPlayMode then
        global.Facade:sendNotification(global.NoticeTable.UserInputLaunch, {skillID = skillID, destPosX = destPosX, destPosY = destPosY})
    else
        global.Facade:sendNotification(global.NoticeTable.UserInputLaunch, {skillID = skillID, priority = global.MMO.LAUNCH_PRIORITY_USER})
    end
end

-- 请求开关型技能开关
function SL:RequestOnOffSkill(skillID)
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:RequestSkillOnoff(skillID)
end

-- 请求施法合击
function SL:RequestMagicJointAttack()
    local HeroSkillProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroSkillProxy)
    local jointSkill     = HeroSkillProxy:haveHeroSkill()
    if not jointSkill then
        return ShowSystemTips("当前没有英雄技能")
    end

    -- 在闪的时候才能放合击
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    if HeroPropertyProxy:getShan()  then
        -- 请求合击
        HeroPropertyProxy:ReqJointAttack()
    end
end

function SL:RequestForceAttack()
    global.Facade:sendNotification(global.NoticeTable.LaunchAttackSkill)
end

-- 请求合击
function SL:RequestHeroJoinAttack()
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:ReqJointAttack()
end

-- 请求立即释放技能
function SL:RequestLaunchSkillImmediate(skillID)
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:RequestLaunchImmediate(skillID)
end

-- 请求获取信息
function SL:RequestMeridianInfo(isHero)
    local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
    MeridianProxy:RequestGetMeridianInfo(isHero)
end

---------------------------------------------------------------------------
-- 查看目标玩家信息
function SL:RequestLookPlayer(targetId, notForbid)
    local mapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    if not notForbid and mapProxy:IsForbidVisitPlayer() then
        ShowSystemChat(GET_STRING(30001071), 255, 249)
        return
    end

    local target = global.actorManager:GetActor(targetId)
    if target and target:IsHumanoid() then --人形怪
        local disHeadLookHumanoid = tonumber(SL:GetValue("GAME_DATA", "disHeadLookHumanoid")) == 1
        if disHeadLookHumanoid then
            ShowSystemTips(GET_STRING(50000269))
            return
        end
    end

    local LookPlayerProxy = global.Facade:retrieveProxy(global.ProxyTable.LookPlayerProxy)
    LookPlayerProxy:RequestPlayerData(targetId)
end
-- 常用函数
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 行会
-- 请求行会信息
function SL:RequestGuildInfo()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestGuildInfo()
end

-- 请求修改公告
function SL:RequestGuildEditNotice(notice)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestEditNotice(notice)
end

-- 请求行会成员列表
function SL:RequestGuildMemberList()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestMemberList()
end

-- 请求退出行会
function SL:RequestGuildQuit()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestLeaveGuild()
end

-- 请求解散行会
function SL:RequestGuildDissolve()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestDissolveGuild()
end

-- 请求世界行会列表
function SL:RequestGuildWorldList()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestGuildList()
end

-- 请求加入行会
function SL:RequestGuildApplyJoin(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApplyGuild(guildID)
end

-- 请求创建行会
function SL:RequestGuildCreate(guildName, autoJoinState, autoLevel, notice)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestCreateGuild(guildName, autoJoinState, autoLevel, notice)
end

-- 请求是否自动同意入会申请 
function SL:RequestGuildAutoApply(bool)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    if bool then
        GuildProxy:RequestApproveAutoApply()
    else
        GuildProxy:RequestRejectAutoApply()
    end
end

-- 请求设置自动入会等级
function SL:RequestGuildSetAutoJoinLevel(level)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestSetAutoJoinLevel(level)
end

-- 请求行会申请列表
function SL:RequestGuildApplyList()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApplyGuildList()
end

-- 管理员同意玩家入会申请
function SL:RequestGuildApproveUserApply(uid)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApproveUserApply(uid)
end

-- 管理员拒绝玩家入会申请
function SL:RequestGuildRejectUserApply(uid)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestRejectUserApply(uid)
end

-- 管理员一键通过所有玩家入会申请
function SL:RequestGuildApproveAllUsersApply()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApproveAllUsersApply()
end

-- 管理员一键通过所有玩家入会申请
function SL:RequestGuildRejectAllUsersApply()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestRejectAllUsersApply()
end

-- 请求行会联盟申请列表
function SL:RequestGuildAllyApplyList()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestAllianceApplyList()
end

-- 申请行会结盟
function SL:RequestGuildAllyApply(guildID, time)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApplyAlliance(guildID, time)
end

-- 请求行会宣战
function SL:RequestGuildDeclareWar(guildID, time)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestDeclareWar(guildID, time)
end

-- 取消行会联盟
function SL:RequestGuildCancelAlly(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestCancelAlliance(guildID)
end

-- 取消行会宣战
function SL:RequestGuildCancelWar(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestCancelWar(guildID)
end

-- 同意行会结盟申请
function SL:RequestGuildApproveAllyApply(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApproveAllianceApply(guildID)
end

-- 拒绝行会结盟申请
function SL:RequestGuildRejectAllyApply(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestRejectAllianceApply(guildID)
end

-- 请求行会联盟战争列表
function SL:RequestGuildAllyWarList()
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestAllianceWarList()
end

-- 设置行会称谓
function SL:RequestGuildSetTitle(data)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestSetGuildTitle(data)
end

-- 任命行会职位
function SL:RequestGuildAppointRank(uid, rank)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestAppointRank(uid, rank)
end

-- 邀请入会
function SL:RequestGuildInviteMember(uid)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestInviteMember(uid)
end

-- 踢出行会
function SL:RequestSubGuildMember(uid)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestRemoveMember(uid)
end

-- 同意邀请
function SL:RequestGuildApproveUserInvite(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestApproveUserInvite(guildID)
end

-- 拒绝邀请
function SL:RequestGuildRejectUserInvite(guildID)
    local GuildProxy = global.Facade:retrieveProxy(global.ProxyTable.GuildProxy)
    GuildProxy:RequestRejectUserInvite(guildID)
end

-- 行会
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 组队
-- 请求创建队伍
function SL:RequestCreateTeam()
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestCreateTeam()
end

-- 邀请玩家入队
function SL:RequestInviteJoinTeam(uid, name)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestInvite(uid, name)
end

-- 拒绝组队邀请
function SL:RequestTeamInviteRefuse(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestInviteRefuse(uid)
end

-- 同意组队邀请
function SL:RequestTeamInviteAgree(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestInviteAgree(uid)
end
-- 拒绝申请入队
function SL:RequestTeamApplyRefuse(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestApplyRefuse(uid)
end

-- 同意申请入队
function SL:RequestTeamApplyAgree(memberUID)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestApplyAgree(memberUID)
end

-- 请求入队申请列表
function SL:RequestTeamApplyData()
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestApplyData()
end

-- 请求附近队伍
function SL:RequestNearTeam()
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestNearTeam()
end

-- 请求加入队伍 uid: 队长userID
function SL:RequestApplyJoinTeam(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestApplyTeam(uid)
end

-- 离开队伍
function SL:RequestLeaveTeam()
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestLeaveTeam()
end

-- 踢出队伍
function SL:RequestSubTeamMember(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestSubMember(uid)
end

-- 移交队长
function SL:RequestTransferTeamLeader(uid)
    local TeamProxy = global.Facade:retrieveProxy(global.ProxyTable.TeamProxy)
    TeamProxy:RequestTransferLeader(uid)
end
-- 组队
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 交易
-- 请求进行交易
function SL:RequestTrade(uid)
    local targetId = SL:GetValue("SELECT_TARGET_ID")
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    if uid then
        targetId = uid
    end
    TradeProxy:SendTradeRequest(targetId)
end
-- 请求放入物品
function SL:RequestTradePutInItem(itemID)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestPutInItem(itemID)
end
-- 请求取出物品
function SL:RequestTradePutOutItem(itemID)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestPutOutItem(itemID)
end
-- 请求取消交易
function SL:RequestTradeCancel()
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestCancel()
end
-- 主动请求改变自己锁定状态
function SL:RequestTradeChangeLock()
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestChangeLock()
end
-- 点击请求交易
function SL:RequestTradeEnd()
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestTradeEnd()
end
--  请求或同意和某人进行交易
function SL:RequestInfoTrade(uid, name, refuse)
    local TradeProxy = global.Facade:retrieveProxy(global.ProxyTable.TradeProxy)
    TradeProxy:RequestTrade(uid, name, refuse)
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 好友
-- 请求好友列表
function SL:RequestFriendList()
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestFriendList()
end

-- 添加好友
function SL:RequestAddFriend(uname)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestAddFriend(uname)
end

-- 删除好友
function SL:RequestDelFriend(uid)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestDelFriend(uid)
end

-- 好友加到黑名单
function SL:RequestAddBlacklistByName(uname)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestAddBlack(nil, uname)
end

-- 移出黑名单
function SL:RequestOutBlacklist(uid)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestDelBlack(uid)
end

-- 同意好友申请
function SL:RequestAgreeFriendApply(uid)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    FriendProxy:RequestDealFriendApply(true, uid)
end

-- 拒绝好友申请
function SL:RequestRefuseFriendApply(uid)
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    return FriendProxy:RequestDealFriendApply(false, uid)
end

-- 清空好友申请列表
function SL:RequestClearFriendApplyList()
    local FriendProxy = global.Facade:retrieveProxy(global.ProxyTable.FriendProxy)
    return FriendProxy:ClearFriendApply()
end
-- 好友
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 邮件
-- 请求获取邮件列表 一次十条
function SL:RequestMailList()
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    MailProxy:RequestMailList()
end

-- 删除已读邮件
function SL:RequestDelReadMail()
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    return MailProxy:RequestDeleteAllReadMail()
end

-- 读邮件
function SL:RequestReadMail(mailId)
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    return MailProxy:RequestReadMail(mailId)
end

-- 删除邮件
function SL:RequestDelMail(mailId)
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    return MailProxy:RequestDeleteMail(mailId)
end

-- 邮件全部提取
function SL:RequestGetAllMailItems()
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    return MailProxy:RequestGetAllMailIReward()
end

-- 邮件提取
function SL:RequestGetMailItems(mailId)
    local MailProxy = global.Facade:retrieveProxy(global.ProxyTable.MailProxy)
    return MailProxy:RequestGetMailRewardByID(mailId)
end

-- 邮件确定收货
function SL:RequestSureTake(layer, data, func)
    local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
    OtherTradingBankProxy:equipTakeSure(layer, data, func)
end
-- 邮件拒绝收货
function SL:RequestRefuseTake(layer, data, func)
    local OtherTradingBankProxy = global.Facade:retrieveProxy(global.ProxyTable.OtherTradingBankProxy)
    OtherTradingBankProxy:equipTakeRefuse(layer, data, func)
end
-- 邮件
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 拍卖行
-- 请求拍卖行上架列表 listType 1表示查询自己上架的物品，2表示查询参与过的
function SL:RequestAuctionPutList(listType)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    AuctionProxy:RequestItems(listType)
end

-- 拍卖行请求上架
function SL:RequestAuctionPutInItem(makeindex, count, bidPrice, buyPrice, currencyID, rebate)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    local submitData = {
        makeindex   = makeindex, 
        count       = count,
        price       = bidPrice,
        lastprice   = buyPrice,
        type        = currencyID,
        meguildRate = rebate
    }    
    AuctionProxy:RequestPutin(submitData)
end

-- 拍卖行请求重新上架
function SL:RequestAuctionRePutInItem(makeindex, count, bidPrice, buyPrice, currencyID, rebate)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    local submitData = {
        makeindex   = makeindex, 
        count       = count,
        price       = bidPrice,
        lastprice   = buyPrice,
        type        = currencyID,
        meguildRate = rebate
    }    
    AuctionProxy:RequestReputin(submitData)
end

-- 拍卖行请求下架
function SL:RequestAuctionPutOutItem(makeIndex)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    AuctionProxy:RequestPutout(makeIndex)
end

-- 拍卖行请求竞价
function SL:RequestAuctionBid(makeindex, price)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    local submitData = {
        price     = price,
        makeindex = makeindex,
    }    
    AuctionProxy:RequestBid(submitData)
end

-- 拍卖行请求领取竞拍成功物品
function SL:RequestAcquireBidItem(makeIndex)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy) 
    AuctionProxy:RequestAcquireItem(makeIndex)
end

-- 拍卖行
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 排行榜
-- 请求排行榜数据 (通过类别)
function SL:RequestRankData(type, selectType)
    local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
    RankProxy:RequestListData(type, selectType)
end

-- 请求玩家排行榜数据 1玩家 2英雄
function SL:RequestPlayerRankData(userID, type)
    type = type - 1
    local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
    RankProxy:RequestPlayerShowData(userID, type)
end

-- 通知服务端点击排行榜类型 1玩家 2英雄
function SL:RequestNotifyClickRankType(type)
    local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
    RankProxy:RequestNotifyClickRankType(type)
end

-- 通知服务端点击排行榜第几名
function SL:RequestNotifyClickRankValue(value)
    local RankProxy = global.Facade:retrieveProxy(global.ProxyTable.RankProxy)
    RankProxy:RequestNotifyClickRankValue(value)
end

-- 排行榜
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- 任务
-- 提交任务
function SL:RequestSubmitMission(missionID)
    if not missionID then
        ErrorDebugPrint("[GUI ERROR] SL:RequestSubmitMission missionID is empty")
        return
    end
    local MissionProxy = global.Facade:retrieveProxy(global.ProxyTable.MissionProxy)
    MissionProxy:RequestSubmitMission(missionID)
end
-- 任务
---------------------------------------------------------------------------


---------------------------------------------------------------------------
---玩家面板
--请求通知脚本查看uid的珍宝
function SL:RequestLookZhenBao(uid)
    local LookPlayerProxy = global.Facade:retrieveProxy(global.ProxyTable.LookPlayerProxy)
    LookPlayerProxy:RequestLookZhenBao(uid)--
end
--[[
    请求称号数据
]]
function SL:RequestTitleList()
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestTitleList(GUIDefine.TitleType.PLAYER)
end
--[[
    请求取下称号
]]
function SL:RequestDisboardTitle()
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestDisboardTitle(GUIDefine.TitleType.PLAYER)
end
--[[
    请求激活称号
]]
function SL:RequestActivateTitle(titleId)
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestActivateTitle(GUIDefine.TitleType.PLAYER, titleId)
end

--英雄
--切换英雄状态
function SL:RequestChangeHeroMode(type)
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:RequestChangeHeroMode(type)
end

--[[
    英雄请求称号数据
]]
function SL:RequestTitleList_Hero()
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestTitleList(GUIDefine.TitleType.HERO)
end
--[[
    英雄请求取下称号
]]
function SL:RequestDisboardTitle_Hero()
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestDisboardTitle(GUIDefine.TitleType.HERO)
end
--[[
    请求激活称号
]]
function SL:RequestActivateTitle_Hero(titleId)
    local TitleProxy = global.Facade:retrieveProxy(global.ProxyTable.TitleProxy)
    TitleProxy:ResquestActivateTitle(GUIDefine.TitleType.HERO, titleId)
end

-- 英雄请求锁定目标
function SL:RequestLockTargetByHero(actorID, isPlayer)
    if not actorID then
        return
    end
    local actor = global.actorManager:GetActor(actorID)
    if not actor then
        return
    end
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:RequestLockTarget(actor:GetID(), actor:GetMapX(), actor:GetMapY(), isPlayer)
end

-- 英雄取消锁定
function SL:RequestCancelLockByHero()
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:CancelLock()
end

-- 设置英雄守护位置
function SL:RequestHeroGuardPos(mapX, mapY)
    local HeroPropertyProxy = global.Facade:retrieveProxy(global.ProxyTable.HeroPropertyProxy)
    HeroPropertyProxy:RequestTargetXY(mapX, mapY)
end


---
---------------------------------------------------------------------------
--------------------------------------合成 begin---------------------------
--请求合成 -- param: 合成ID
function SL:ResquestCompoundItem(compoundID)
    local ItemCompoundProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemCompoundProxy)
    ItemCompoundProxy:RequestCompoundJson(compoundID)
end

-- 通知脚本打开不同合成 id:合成表id
function SL:RequestCompoundChangeJson(id)
    local ItemCompoundProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemCompoundProxy)
    ItemCompoundProxy:RequestCompoundChangeJson(id)
end
--------------------------------------合成   end---------------------------

---------------------------------------------------------------------------
--- 请求敏感词检测
function SL:RequestCheckSensitiveWord(str, type, callback, exUploadData)
    if not tonumber(type) then
        return
    end
    local SensitiveWordProxy = global.Facade:retrieveProxy(global.ProxyTable.SensitiveWordProxy)
    if type == 1 then   -- 昵称类
        SensitiveWordProxy:IsHaveSensitiveAddFilter(str, callback)
    elseif type == 2 then   -- 聊天
        local function handle_Func(state, str, risk_param, ex_param)
            -- if risk_param and risk_param ~= 0 then
            --     callback(false, false)
            -- else
                callback(state, str, risk_param, ex_param)
            -- end
        end
        SensitiveWordProxy:fixSensitiveTalkAddFilter(str, handle_Func, nil, exUploadData)
    elseif type == 3 then   -- 行会公告
        SensitiveWordProxy:fixSensitiveTalkAddFilter(str, callback, 1)
    end
end

-- 批量检测敏感字
function SL:RequestCheckSensitiveWordEx(strList, type, callback)
    if not strList or #strList <= 0 then
        return callback(false)
    end

    local SensitiveWordProxy = global.Facade:retrieveProxy(global.ProxyTable.SensitiveWordProxy)
    local idx = 1

    local function checkHaveSensitive(str)
        if type == 1 then
            SensitiveWordProxy:IsHaveSensitiveAddFilter(str, function(state) 
                -- 检测，不通过
                if not state then
                    return callback(false)
                end
    
                -- 检测，全部通过
                if idx == #strList then
                    return callback(true)
                end
    
                idx = idx + 1
                checkHaveSensitive(strList[idx])
            end)
        elseif type == 2 then
            SensitiveWordProxy:IsHaveSensitiveTalkAddFilter(str, function(state) 
                -- 检测，不通过
                if not state then
                    return callback(false)
                end
    
                -- 检测，全部通过
                if idx == #strList then
                    return callback(true)
                end
    
                idx = idx + 1
                checkHaveSensitive(strList[idx])
            end)
        end
    end
    checkHaveSensitive(strList[idx])
end

-- 检查聊天文本是否有敏感词
function SL:RequestCheckChatIsHaveSensitive(str, callFunc, ex_param)
    local SensitiveWordProxy = global.Facade:retrieveProxy(global.ProxyTable.SensitiveWordProxy)
    SensitiveWordProxy:IsHaveSensitiveTalkAddFilter(str, callFunc, ex_param)
end
----------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 邀请玩家上马
function SL:RequestInvitePlayerInHorse(uid)
    local HorseProxy = global.Facade:retrieveProxy( global.ProxyTable.HorseProxy )
    HorseProxy:RequestHorseUpInvite(uid)
end

-- 请求下马
function SL:RequestHorseDown()
    local HorseProxy = global.Facade:retrieveProxy( global.ProxyTable.HorseProxy )
    return HorseProxy:RequestHorseDown()
end

-- 拾取当前玩家位置掉落
function SL:RequestPickMainPlayerPosItem()
    global.dropItemController:PickMainPlayerPosItem()
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 交易行
-- 交易行外框按钮点击上报
function SL:RequestTradingBankBtnUpload(type)
    if not type then
        return
    end
    local Box996Proxy = global.Facade:retrieveProxy(global.ProxyTable.Box996Proxy)
    Box996Proxy:requestLogUp(Box996Proxy.OTHER_UP_EVEIT[100+type])
end

function SL:RequestSendItemMoveMsg()
    if not global.isWinPlayMode then
        local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL, {from = GUIDefine.ItemFrom.TRADE})
        SL:onLUAEvent(LUA_EVENT_LAYER_MOVED_CANCEL, {from = GUIDefine.ItemFrom.TRADE_GOLD})
    end
end
-- 交易行
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 服务端特殊记录
-- 通知服务端隐藏主界面聊天框
function SL:RequestNoticeChatVisible(state)
    LuaSendMsg(global.MsgType.MSG_CS_TELL_CHAT_VISIBLE, state and 1 or 0)
end

-- 发送GM命令到聊天
function SL:RequestSendChatGMMsg(msg)
    local input     = string.format("@%s", msg)
    local sendData  = {textType = GUIDefine.ChatTextType.NORMAL, msg = input, channel = GUIDefine.ChatChannel.SHOUT}
    GUIFunction:SendChatMsg(sendData)
end

-- 发送普通消息
function SL:RequestSendChatNormalMsg(msg, setChannel)
    local channel   = setChannel or ChatData.GetCurChannel()
    local sendData  = {textType = GUIDefine.ChatTextType.NORMAL, msg = msg, channel = channel}
    GUIFunction:SendChatMsg(sendData)
end

-- 发送装备
function SL:RequestSendChatEquipMsg(item, setChannel)
    local msg       = item
    local channel   = setChannel or ChatData.GetCurChannel()
    local sendData  = {mt = GUIDefine.ChatMsgType.EQUIP, msg = msg, channel = channel}
    GUIFunction:SendChatMsg(sendData)
end

-- 发送坐标
function SL:RequestSendChatPosMsg(setChannel)
    local mainPlayer = global.gamePlayerController:GetMainPlayer()
    if not mainPlayer then
        return nil
    end
    local MapProxy = global.Facade:retrieveProxy(global.ProxyTable.MapProxy)
    local msg = {
        mapID       = MapProxy:GetMapID(),
        mapName     = MapProxy:GetMapName(),
        mapX        = mainPlayer:GetMapX(),
        mapY        = mainPlayer:GetMapY()
    }
    local channel   = setChannel or ChatData.GetCurChannel()
    local sendData  = {mt = GUIDefine.ChatMsgType.POSITION, msg = msg, channel = channel}
    GUIFunction:SendChatMsg(sendData)
end

-- 请求发送聊天消息
function SL:RequestSendChatMsg(data)
    local ChatProxy = global.Facade:retrieveProxy(global.ProxyTable.ChatProxy)
    ChatProxy:SendMsg(data)
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 小地图
-- 请求组队成员数据
function SL:RequestMiniMapTeam()
    local MiniMapProxy = global.Facade:retrieveProxy(global.ProxyTable.MiniMapProxy)
    MiniMapProxy:RequestTeamMemberData()
end

-- 请求地图怪物数据
function SL:RequestMiniMapMonsters()
    local MiniMapProxy = global.Facade:retrieveProxy(global.ProxyTable.MiniMapProxy)
    MiniMapProxy:RequestMonsters()
end

-- 通知跨地图点击小地图坐标
function SL:RequestNotifyClickCrossMiniMap(mapX, mapY)
    local MiniMapProxy = global.Facade:retrieveProxy(global.ProxyTable.MiniMapProxy)
    MiniMapProxy:RequestNotifyCrossMapClickPos(mapX, mapY)
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 内功
-- 请求内功技能数据
function SL:RequestInternalSkillData(isHero)
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:RequestNGSkillData(isHero)
end

-- 请求经络穴位激活
function SL:RequestMeridianAcuPointOpen(typeID, aucPointID, isHero)
    local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
    MeridianProxy:RequestAucPointOpen(typeID, aucPointID, isHero)
end

-- 修炼经络
function SL:RequestMeridianLevelUp(typeID, isHero)
    local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
    MeridianProxy:RequestMeridianLevelUp(typeID, isHero)
end

-- 请求设置连击技能
function SL:RequestSetComboSkill(key, skillID, isHero)
    local SkillProxy = global.Facade:retrieveProxy(global.ProxyTable.SkillProxy)
    SkillProxy:RequestSetComboSkill(key, skillID, isHero)
end

-- 请求内功hud显示 (额外控制)
function SL:RequestInternalHudShow(show)
    if show == nil then
        show = true
    end
    local MeridianProxy = global.Facade:retrieveProxy(global.ProxyTable.MeridianProxy)
    MeridianProxy:SetExtraNGHudShow(show)
    MeridianProxy:OnRefreshNGHudShow()
end

-- 内功
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 宝箱
-- 请求获取宝箱奖励
function SL:RequestGetGoldBoxReward()
    local GoldBoxProxy = global.Facade:retrieveProxy(global.ProxyTable.GoldBoxProxy)
    GoldBoxProxy:RequsetGetBoxReward()
end

-- 请求再开启宝箱
function SL:RequestOpenGoldBox()
    local GoldBoxProxy = global.Facade:retrieveProxy(global.ProxyTable.GoldBoxProxy)
    GoldBoxProxy:RequsetOpenBoxAgain()
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 转生点加属性
-- 请求确认加属性点 [新版]
function SL:RequestAddReinAttrNew(data, bonusPoint)
    local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
    ReinAttrProxy:RequestAddReinAttrNew(data, bonusPoint)
end

function SL:RequestAddReinAttr(data, bonusPoint)
    local ReinAttrProxy = global.Facade:retrieveProxy(global.ProxyTable.ReinAttrProxy)
    ReinAttrProxy:RequestAddReinAttr(data, bonusPoint)
end

-- 转生点加属性
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 求购
-- 请求求购列表
function SL:RequestPurchaseItemList(data)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    PurchaseProxy:RequestItemList(data)
end

-- 求购 出售
function SL:RequestPurchaseSell(data)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    PurchaseProxy:RequestSell(data)
end

-- 求购 上架
function SL:RequestPurchasePutIn(data)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    PurchaseProxy:RequestPutIn(data)
end

-- 求购 下架
function SL:RequestPurchasePutOut(data)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    PurchaseProxy:RequestPutOut(data)
end

-- 求购 取出
function SL:RequestPurchaseTakeOut(data)
    local PurchaseProxy = global.Facade:retrieveProxy(global.ProxyTable.PurchaseProxy)
    PurchaseProxy:RequestTakeOut(data)
end

---------------------------------------------------------------------------
-- npc点击
function SL:RequestNPCTalk(npcID)
    if not npcID then
        return false
    end
    local NPCProxy = global.Facade:retrieveProxy( global.ProxyTable.NPCProxy )
    NPCProxy:CheckTalk( npcID )
end

---------------------------------------------------------------------------
--解锁背包
function SL:RequestUnlockBagSize()
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
    BagProxy:RequestUnlockBagSize()
end

-- 英雄背包到人物背包
function SL:RequestHeroBagToHumBag(itemData)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:HeroBagToHumBag(itemData)
end

-- 人物背包到英雄背包
function SL:RequestHumBagToHeroBag(itemData)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:HumBagToHeroBag(itemData)
end

-- 装备卸下
---@param data table {itemData:TakeOffEquipData}
function SL:RequestTakeOffEquip(data)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:TakeOffEquip(data)
end

-- 英雄装备卸下
---@param data table {itemData:TakeOffEquipData}
function SL:RequestHeroTakeOffEquip(data)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:TakeOffEquip_Hero(data)
end

function SL:RequestAddGoldToTrade(data)
    local ItemMoveProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemMoveProxy)
    ItemMoveProxy:AddGoldToTrade(data)
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 打开qq(移动端)
function SL:RequestOpenQQ()
    global.L_NativeBridgeManager:GN_startQQ()
end

-- 加qq(移动端)
function SL:RequestJoinQQ(id)
    global.L_NativeBridgeManager:GN_joinQQ({qqKey=id})
end

-- 加qq群(移动端)
function SL:RequestJoinQQGroup(id)
    global.L_NativeBridgeManager:GN_joinQQGroup({qqGroupKey=id})
end

-- 打开微信(移动端)
function SL:RequestOpenWX()
    global.L_NativeBridgeManager:GN_startWX()
end

-- 加微信公众号(移动端)
function SL:RequestJoinWXGroup(id)
    global.L_NativeBridgeManager:GN_joinWXGroup({wxGroupKey=id})
end
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 请求摆摊 
function SL:RequestAutoStall(name)
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    StallProxy:RequestAutoStall(name)
end

--请求取消摆摊 
function SL:RequestCancelAutoStall()
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    StallProxy:RequestAutoStall("", true)
end

--摆摊 请求购买
function SL:RequestStallBuyItem(makeindex)
    local StallProxy = global.Facade:retrieveProxy(global.ProxyTable.StallProxy)
    StallProxy:RequestBuyItem(makeindex)
end
--
---------------------------------------------------------------------------
-- 登录账号
-- 请求登录账号(账号密码)
function SL:RequestLoginAccount(username, password)
    local data = {}
    data.type = 1
    data.username = username
    data.password = password
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    if global.isDebugMode or global.isGMMode then
        AuthProxy:RequestLoginAdmin(data)
    else
        AuthProxy:RequestLogin(data)
    end
end

-- 请求登录(手机号验证码)
function SL:RequestLoginAccountByPhone(phoneId, authCode)
    local data = {}
    data.phoneId = phoneId
    data.authCode = authCode
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestLoginByPhone(data)
end

-- 请求手机验证码
function SL:RequestLoginPhoneAuthCode(phoneId)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestAuthCode(phoneId)
end

-- 请求注册账号
function SL:RequestLoginRegisterAccount(data)
    data = data or {}
    data.type = 1
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestRegister(data)
end

-- 请求修改密保问题
function SL:RequestLoginChangeMbQuestion(data)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestChangeMb(data)
end

-- 请求修改密码通过密保
function SL:RequestLoginChangePasswordByMb(data)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestChangePwdByMb(data)
end

-- 请求修改密码通过手机号
function SL:RequestLoginChangePasswordByPhone(data)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestChangePwdByPhone(data)
end

-- 请求绑定手机号通过密保
function SL:RequestLoginBindPhoneByMb(data)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestBindPhoneByMb(data)
end

-- 请求修改手机号
function SL:RequestLoginChangePhone(data)
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestChangePhone(data)
end

-- 请求身份认证
function SL:RequestLoginIdentifyIDCard(name, id)
    local data      = {} 
    data.name       = name
    data.IDNumber   = id
    local AuthProxy = global.Facade:retrieveProxy(global.ProxyTable.AuthProxy)
    AuthProxy:RequestIdentifyID(data)
end

-- 请求连接登录服务器
function SL:RequestLoginConnectServer()
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestConnectLoginServer()
end

-- 登录选角
-- 请求随机角色名
function SL:RequestLoginRandRoleName(job, sex)
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestRoleName(job, sex)
end

-- 请求创建角色
function SL:RequestLoginCreateRole(name, job, sex)
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestCreateRole(name, job, sex)
end

-- 请求进入游戏
function SL:RequestLoginEnterGame()
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    return LoginProxy:RequestEnterGame()
end

-- 请求删除角色
function SL:RequestLoginDeleteRole(uid)
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestDeleteRole(uid)
end

-- 请求恢复角色列表数据
function SL:RequestLoginRestoreRoleList()
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestRestoreRoleInfo()
end

-- 请求恢复角色 roleinfo
function SL:RequestLoginRestoreRole(uid, name)
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestRestoreRole(uid, name)
end

-- 请求角色数据
function SL:RequestLoginRoleInfo()
    local LoginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
    LoginProxy:RequestRoleInfo()
end
---------------------------------------------------------------------------
-- 拍卖行请求item列表
function SL:RequestItemList(data)
    local AuctionProxy = global.Facade:retrieveProxy(global.ProxyTable.AuctionProxy)
    AuctionProxy:RequestItemList(data)
end
---------------------------------------------------------------------------
--商城请求信息
function SL:RequestStorePageData(page)
    local PageStoreProxy = global.Facade:retrieveProxy(global.ProxyTable.PageStoreProxy)
    PageStoreProxy:RequestPageData(page)
end
---------------------------------------------------------------------------
--NPC商城请求信息
function SL:RequestNpcStoreItemList(data)
    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    NPCProxy:RequestNpcStoreItemList(data)
end

--NPC商城购买
function SL:RequestNpcStoreBuy(data)
    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    NPCProxy:RequestNpcStoreBuy(data)
end
---------------------------------------------------------------------------
-- npc
-- 炼药
function SL:RequestNpcMakeDrug(data)
    local NPCProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCProxy)
    NPCProxy:RequestNpcMakeDrug(data)
end

-- 采集完成
function SL:RequestCompletedCollect()
    local PlayerInputProxy = global.Facade:retrieveProxy(global.ProxyTable.PlayerInputProxy)
    PlayerInputProxy:CompletedCollect()
end

-- 最终修理道具
function SL:RequestNpcStoreRepaire()
    local NPCRepaireProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCRepaireProxy)
    NPCRepaireProxy:RequestNpcStoreRepaire()
end

-- 最终出售道具
function SL:RequestNpcStoreSell()
    local NPCSellProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCSellProxy)
    NPCSellProxy:RequestNpcStoreSell()
end

-- 自定义道具请求
function SL:RequestNpcDoSomething()
    local NPCDoSomethingProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCDoSomethingProxy)
    NPCDoSomethingProxy:RequestNpcDoSomething()
end

-- 新type请求
function SL:RequestNpcNewTypeOk()
    local NPCNewTypeOkProxy = global.Facade:retrieveProxy(global.ProxyTable.NPCNewTypeOkProxy)
    NPCNewTypeOkProxy:RequestNpcNewTypeOk()
end
------------------------------------------------------------------------------

------------------------------------------------------------------
-- FuncDock
-- 提交功能允许状态
function SL:RequestFuncDockPermit(data)
    local FuncDockProxy = global.Facade:retrieveProxy(global.ProxyTable.FuncDockProxy)
    FuncDockProxy:RequestPermit(data)
end

-- 请求玩家信息
function SL:RequestFuncDockLookPlayerInfo(uid, isHero)
    local FuncDockProxy = global.Facade:retrieveProxy(global.ProxyTable.FuncDockProxy)
    FuncDockProxy:RequestLookStatus(uid, isHero)
end

--------------------------------------------------------------------
-- 关系
-- 邀请玩家建立关系网请求
function SL:RequestRelationInviteJoin(type, userID, userName)
    local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
    RelationProxy:RequestInvitePlayerIn(type, userID, userName)
end

-- 发起召集请求
function SL:RequestRelationCallMember(type, netID, rank)
    local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
    RelationProxy:RequestCallMember(type, netID, rank)
end

-- 解散或退出
function SL:RequestRelationDissolveOrExit(netID)
    local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
    RelationProxy:RequestDissolveOrExit(netID)
end

-- 踢出关系网成员
function SL:RequestRelationKickOutMember(userID, netID)
    local RelationProxy = global.Facade:retrieveProxy(global.ProxyTable.RelationProxy)
    RelationProxy:RequestKickOutMember(userID, netID)
end

--------------------------------------------------------------------
-- 请求大血条头像点击
function SL:RequestBigHpClick(typeIndex, actorID)
    LuaSendMsg(global.MsgType.MSG_CS_BIGTIP_CLICK, typeIndex, 0, 0, 0, actorID, string.len(actorID))
end
-----------------------------------------------------------------
-- 同步配置数据到服务端
function SL:RequestSyncGameSetData()
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:SyncDataToServer()
end

-- 发送过滤挂机拾取物品IDX
function SL:RequestSendFilterAutoPickItem()
    local GameSettingProxy = global.Facade:retrieveProxy(global.ProxyTable.GameSettingProxy)
    GameSettingProxy:RequestSendFilterAutoPickItem()
end

-- 请求小退
function SL:RequestLeaveWorld()
    global.Facade:sendNotification(global.NoticeTable.RequestLeaveWorld)
end

---------------------------------------------------------------------------
-- 游戏内客服
function SL:RequestOpen996ManualService()
    local ManualService996Proxy = global.Facade:retrieveProxy(global.ProxyTable.ManualService996Proxy)
    ManualService996Proxy:RequestManualService()
end

--交易所
-- 请求交易所列表
function SL:RequestExchangeList(data)
    local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    ExchangeProxy:RequestItemList(data)
end
--请求交易所上架价格
function SL:RequestExchangePutInPrice(data)
    local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    ExchangeProxy:RequestPutInPrice(data)
end

-- 交易所请求上架
function SL:RequestExchangePutInItem(guid, count, price, currencyID)
    local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    local submitData = {
        qty       = count,
        price       = price,
        currency    = currencyID
    }    
    ExchangeProxy:RequestPutin(guid, submitData)
end

-- 交易所请求下架
function SL:RequestExchangePutOutItem(makeIndex)
    local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    ExchangeProxy:RequestPutout(makeIndex)
end

-- 交易所 购买
function SL:RequestExchangeBuy(data)
    local ExchangeProxy = global.Facade:retrieveProxy(global.ProxyTable.ExchangeProxy)
    ExchangeProxy:RequestBuy(data)
end

-- 更改地图格子宽高
function SL:SetMapGridSize(width, height)
    if global.sceneManager then
        width = tonumber(width) or global.MMO.MapGridWidth
        height = tonumber(height) or global.MMO.MapGridHeight
        if width <= 0 or height <= 0 then
            release_print("地图格子宽高必须大于0")
            return
        end
        global.MMO.MapGridWidth = width
        global.MMO.MapGridHeight = height
        global.sceneManager:SetMapGridSize(width, height)
    end
end
