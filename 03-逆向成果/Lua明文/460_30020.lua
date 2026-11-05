local RemoteProxy = requireProxy("RemoteProxy")
local JumpProxy = class("JumpProxy", RemoteProxy)
JumpProxy.NAME = global.ProxyTable.JumpProxy

function JumpProxy:ctor()
    JumpProxy.super.ctor(self)
    self._links = self:LoadDefine()
end

function JumpProxy:RegisterMsgHandler()
    JumpProxy.super.RegisterMsgHandler(self)
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_HYPERLINK_JUMP, handler(self, self.RespHyperlinkJump))
    LuaRegisterMsgHandler(global.MsgType.MSG_SC_OPENHYPERCHECK, handler(self, self.handler_MSG_SC_OPENHYPERCHECK))
end

--特殊界面需要用之前的方式
----------------------------------------------------------------------
local JumpMsg = {
    [UIConst.LayerTable.SettingBasic]             = {open = global.NoticeTable.Layer_SettingBasic_Open, close = global.NoticeTable.Layer_SettingBasic_Close},
    [UIConst.LayerTable.SettingWindowRange]       = {open = global.NoticeTable.Layer_SettingWindowRange_Open, close = global.NoticeTable.Layer_SettingWindowRange_Close},
    [UIConst.LayerTable.SettingFight]             = {open = global.NoticeTable.Layer_SettingLaunch_Open, close = global.NoticeTable.Layer_SettingLaunch_Close},
    [UIConst.LayerTable.SettingProtect]           = {open = global.NoticeTable.Layer_SettingProtect_Open, close = global.NoticeTable.Layer_SettingProtect_Close},
    [UIConst.LayerTable.SettingAuto]              = {open = global.NoticeTable.Layer_SettingAuto_Open, close = global.NoticeTable.Layer_SettingAuto_Close},
    [UIConst.LayerTable.SettingHelp]              = {open = global.NoticeTable.Layer_SettingHelp_Open, close = global.NoticeTable.Layer_SettingHelp_Close},
}

local function getCurPlayerMainWin(isHero)
    if isHero then
        return GUIDefineEx.IsMergeMode and GUI:GetWindow(nil, UIConst.LAYERID.MergePlayerMainGUI) or GUI:GetWindow(nil, UIConst.LAYERID.HeroMainGUI) 
    end
    return GUIDefineEx.IsMergeMode and GUI:GetWindow(nil, UIConst.LAYERID.MergePlayerMainGUI) or GUI:GetWindow(nil, UIConst.LAYERID.PlayerMainGUI) 
end
    
function JumpProxy:ClosePanelById(id)
    if not id then return end
    if JumpMsg[id] then
        global.Facade:sendNotification(JumpMsg[id].close)
    end
end

function JumpProxy:OpenPanelById(id, parent, extent)
    if not id then return end
    if JumpMsg[id] then
        global.Facade:sendNotification(JumpMsg[id].open, {parent = parent, extent = extent or JumpMsg[id].extent})
    end
end
----------------------------------------------------------------------------
function JumpProxy:LoadDefine()
    local LT = UIConst.LayerTable

    return {
        [SLDefine.HyperLinkID.Equip] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerEquip}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.State] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerBaseAtt}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.Attri] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerExtraAtt}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.Skill] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerSkill}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.Title] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerTitle}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.SuperEquip] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerSuperEquip}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.Buff] = {
            open  = function () UIOperator:OpenMyPlayerUI({page = LT.PlayerBuff}) end,
            close = function () UIOperator:CloseMyPlayerUI() end,
            hasLayer = function() return getCurPlayerMainWin() end,
        },
        [SLDefine.HyperLinkID.PlayerInternalState] = {
            open  = function () UIOperator:OpenMyPlayerUI({type = 2, page = LT.InternalState}) end, 
            close = function () UIOperator:CloseMyPlayerUI() end
        },
        [SLDefine.HyperLinkID.PlayerInternalSkill] = {
            open  = function () UIOperator:OpenMyPlayerUI({type = 2, page = LT.InternalSkill}) end,
            close = function () UIOperator:CloseMyPlayerUI() end
        },
        [SLDefine.HyperLinkID.PlayerInternalMeridian] = {
            open  = function () UIOperator:OpenMyPlayerUI({type = 2, page = LT.InternalMeridian}) end,
            close = function () UIOperator:CloseMyPlayerUI() end
        },
        [SLDefine.HyperLinkID.PlayerInternalCombo] = {
            open = function () UIOperator:OpenMyPlayerUI({type = 2, page = LT.InternalCombo}) end,
            close = function () UIOperator:CloseMyPlayerUI() end
        },
        [SLDefine.HyperLinkID.HeroInternalState] = {
            open  = function () UIOperator:OpenMyHeroUI({type = 2, page = LT.InternalState}) end, 
            close = function () UIOperator:CloseMyHeroUI() end
        },
        [SLDefine.HyperLinkID.HeroInternalSkill] = {
            open  = function () UIOperator:OpenMyHeroUI({type = 2, page = LT.InternalSkill}) end, 
            close = function () UIOperator:CloseMyHeroUI() end
        },
        [SLDefine.HyperLinkID.HeroInternalMeridian] = {
            open  = function () UIOperator:OpenMyHeroUI({type = 2, page = LT.InternalMeridian}) end, 
            close = function () UIOperator:CloseMyHeroUI() end
        },
        [SLDefine.HyperLinkID.HeroInternalCombo] = {
            open  = function () UIOperator:OpenMyHeroUI({type = 2, page = LT.InternalCombo}) end, 
            close = function () UIOperator:CloseMyHeroUI() end
        },
        [SLDefine.HyperLinkID.BestRing] = {
            open  = function () UIOperator:OpenBestRingBoxUI(GUIDefine.RoleUIType.PLAYER) end, 
            close = function () UIOperator:CloseBestRingBoxUI(GUIDefine.RoleUIType.PLAYER) end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.PlayerBestRingGUI) end,
        },
        [SLDefine.HyperLinkID.Bag] = {
            open  = function () UIOperator:OpenBagUI() end,                   
            close = function () UIOperator:CloseBagUI() end,
            hasLayer = function() 
                return GUIDefineEx.IsMergeMode and GUI:GetWindow(nil, UIConst.LAYERID.MergeBagLayerGUI) or GUI:GetWindow(nil, UIConst.LAYERID.BagLayerGUI) 
            end,
        },
        [SLDefine.HyperLinkID.Stall] = {
            open = function () UIOperator:OpenStallLayerUI() end,            
            close = function () UIOperator:CloseStallLayerUI() end
        },
        [SLDefine.HyperLinkID.StoreHot] = {
            open = function () UIOperator:OpenStoreFrameUI(1) end,                
            close = function () UIOperator:CloseStoreFrameUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.StoreFrameGUI) end
        },
        [SLDefine.HyperLinkID.StoreBeauty] = {
            open = function () UIOperator:OpenStoreFrameUI(2) end,                
            close = function () UIOperator:CloseStoreFrameUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.StoreFrameGUI) end
        },
        [SLDefine.HyperLinkID.StoreEngine] = {
            open = function () UIOperator:OpenStoreFrameUI(3) end,                
            close = function () UIOperator:CloseStoreFrameUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.StoreFrameGUI) end
        },
        [SLDefine.HyperLinkID.StoreFestival] = {
            open = function () UIOperator:OpenStoreFrameUI(4) end,                
            close = function () UIOperator:CloseStoreFrameUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.StoreFrameGUI) end
        },
        [SLDefine.HyperLinkID.StoreRecharge] = {
            open = function () UIOperator:OpenStoreFrameUI(5) end,                
            close = function () UIOperator:CloseStoreFrameUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.StoreFrameGUI) end
        },
        [SLDefine.HyperLinkID.CallPay] = {
            open = function () SL:OpenCallPayUI() end
        },
        [SLDefine.HyperLinkID.GuildMain] = {
            open = function () UIOperator:OpenGuildMainUI(1) end,            
            close = function () UIOperator:CloseGuildMainUI() end,
            hasLayer = function() return GuildMain and GuildMain._layer end
        },
        [SLDefine.HyperLinkID.GuildMember] = {
            open = function () UIOperator:OpenGuildMainUI(2) end,            
            close = function () UIOperator:CloseGuildMainUI() end,
            hasLayer = function() return GuildMember and GuildMember._layer end
        },
        [SLDefine.HyperLinkID.GuildList] = {
            open = function () UIOperator:OpenGuildMainUI(3) end,            
            close = function () UIOperator:CloseGuildMainUI() end,
            hasLayer = function() return GuildList and GuildList._layer end
        },
        [SLDefine.HyperLinkID.Guild] = {
            open = function () UIOperator:OpenGuildMainUI() end,             
            close = function () UIOperator:CloseGuildMainUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.GuildFrameGUI) end,
        },
        [SLDefine.HyperLinkID.GuildCreate] = {
            open = function () UIOperator:OpenGuildCreateUI() end,           
            close = function () UIOperator:CloseGuildCreateUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.GuildCreateGUI) end,
        },
        [SLDefine.HyperLinkID.NearPlayer] = {
            open = function () UIOperator:OpenSocialUI(1) end,               
            close = function () UIOperator:CloseSocialUI() end,
            hasLayer = function () 
                local socialLayer = GUI:GetWindow(nil, UIConst.LAYERID.SocialGUI)
                if socialLayer and SocialInfo and SocialInfo._ui and SocialInfo._ui.AttachLayout then 
                    return GUI:getChildByName(SocialInfo._ui.AttachLayout, "nearPlayerLayer")
                end
            end
        },
        [SLDefine.HyperLinkID.Team] = {
            open = function () UIOperator:OpenSocialUI(2) end,               
            close = function () UIOperator:CloseSocialUI() end,
            hasLayer = function () 
                local socialLayer = GUI:GetWindow(nil, UIConst.LAYERID.SocialGUI)
                if socialLayer and SocialInfo and SocialInfo._ui and SocialInfo._ui.AttachLayout then 
                    return GUI:getChildByName(SocialInfo._ui.AttachLayout, "teamLayer")
                end
            end
        },
        [SLDefine.HyperLinkID.Friend] = {
            open = function () UIOperator:OpenSocialUI(3) end,               
            close = function () UIOperator:CloseSocialUI() end,
            hasLayer = function () 
                local socialLayer = GUI:GetWindow(nil, UIConst.LAYERID.SocialGUI)
                if socialLayer and SocialInfo and SocialInfo._ui and SocialInfo._ui.AttachLayout then 
                    return GUI:getChildByName(SocialInfo._ui.AttachLayout, "friendLayer")
                end
            end 
        },
        [SLDefine.HyperLinkID.Mail] = {
            open = function () UIOperator:OpenSocialUI(4) end,               
            close = function () UIOperator:CloseSocialUI() end,
            hasLayer = function () 
                local socialLayer = GUI:GetWindow(nil, UIConst.LAYERID.SocialGUI)
                if socialLayer and SocialInfo and SocialInfo._ui and SocialInfo._ui.AttachLayout then 
                    return GUI:getChildByName(SocialInfo._ui.AttachLayout, "mailLayer")
                end
            end 
        },
        [SLDefine.HyperLinkID.Relation] = {
            open = function () UIOperator:OpenSocialUI(5) end,               
            close = function () UIOperator:CloseSocialUI() end,
            hasLayer = function () 
                local socialLayer = GUI:GetWindow(nil, UIConst.LAYERID.SocialGUI)
                if socialLayer and SocialInfo and SocialInfo._ui and SocialInfo._ui.AttachLayout then 
                    return GUI:getChildByName(SocialInfo._ui.AttachLayout, "relationLayer")
                end
            end 
        },
        [SLDefine.HyperLinkID.MiniMap] = {
            open = function () UIOperator:OpenMiniMap() end,                 
            close = function () UIOperator:CloseMiniMap() end,
            hasLayer = function () return GUI:GetWindow(nil, UIConst.LAYERID.MiniMapGUI) end 
        },
        [SLDefine.HyperLinkID.SkillSetting] = {
            open = function () UIOperator:OpenSkillSettingUI() end,          
            close = function () UIOperator:CloseSkillSettingUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.SkillSettingGUI) end,
        },
        [SLDefine.HyperLinkID.Auction] = {
            open = function () UIOperator:OpenAuctionUI() end,      
            close = function () UIOperator:CloseAuctionUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.AuctionMainGUI) end
        },
        [SLDefine.HyperLinkID.ExitToRole] = {
            open = function () SL:ExitToRoleUI() end
        },
        [SLDefine.HyperLinkID.ForceExitToRole] = {
            open = function () SL:ForceExitToRoleUI() end
        },
        [SLDefine.HyperLinkID.GuideEnter] = {
            open = function (param) SL:OpenGuideEnter(param) end,    
            close = function () SL:CloseGuideEnter() end,
        },
        [SLDefine.HyperLinkID.Rank] = {
            open = function(param) UIOperator:OpenRankUI(param) end, 
            close = function() UIOperator:CloseRankUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.RankGUI) end,
        },
        [SLDefine.HyperLinkID.Trade] = {
            open = function () SL:RequestTrade() end,                 
            close = function () SL:CloseTradeUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.TradeGUI) end
        },
        [SLDefine.HyperLinkID.TradingBank] = {
            open = function () UIOperator:OpenTradingBankUI() end,           
            close = function () UIOperator:CloseTradingBankUI() end,
            hasLayer = function ()
                local mediatorName = "TradingBankFrameMediator"
                if global.OtherTradingBank then -- 三方 交易行
                    mediatorName = "TradingBankFrameMediator_other"
                end
                local mediator = global.Facade:retrieveMediator("Box996MainLayerMediator") 
                return mediator and mediator._layer
            end 
        },
        [SLDefine.HyperLinkID.HeroEquip] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerEquip}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroState] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerBaseAtt}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroAttri] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerExtraAtt}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroSkill] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerSkill}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroTitle] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerTitle}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroSuperEquip] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerSuperEquip}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroBuff] = {
            open  = function () UIOperator:OpenMyHeroUI({page = LT.PlayerBuff}) end,
            close = function () UIOperator:CloseMyHeroUI() end,
            hasLayer = function() return getCurPlayerMainWin(true) end,
        },
        [SLDefine.HyperLinkID.HeroBestRing] = {
            open  = function () UIOperator:OpenBestRingBoxUI(GUIDefine.RoleUIType.HERO) end,          
            close = function () UIOperator:CloseBestRingBoxUI(GUIDefine.RoleUIType.HERO) end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.HeroBestRingGUI) end,
        },
        [SLDefine.HyperLinkID.HeroBag] = {
            open = function () UIOperator:OpenHeroBagUI() end,               
            close = function () UIOperator:CloseHeroBagUI() end,   
            hasLayer = function() 
                return GUIDefineEx.IsMergeMode and GUI:GetWindow(nil, UIConst.LAYERID.MergeBagLayerGUI) or GUI:GetWindow(nil, UIConst.LAYERID.HeroBagLayerGUI)
            end    
        },
        [SLDefine.HyperLinkID.ReinAttrPoint] = {
            open = function () UIOperator:OpenReinAttrUI() end,              
            close = function () UIOperator:CloseReinAttrUI() end,
            hasLayer = function () return GUI:GetWindow(nil, UIConst.LAYERID.ReinAttrGUI) end   
        },
        [SLDefine.HyperLinkID.Chat] = {
            open = function () UIOperator:OpenChatUI() end,          
            close = function () UIOperator:CloseChatUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.ChatGUI) end,    
        },
        [SLDefine.HyperLinkID.ChatExtendEmoj] = {
            open = function () UIOperator:OpenChatExtendUI({group = 2}) end,   
            close = function () UIOperator:CloseChatExtendUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.ChatExtendGUI) end,
        },
        [SLDefine.HyperLinkID.ChatExtendBag] = {
            open = function () UIOperator:OpenChatExtendUI({group = 3}) end,   
            close = function () UIOperator:CloseChatExtendUI() end
        },
        [SLDefine.HyperLinkID.MagicJointAttack] = {
            open = function () SL:RequestMagicJointAttack() end
        },
        [SLDefine.HyperLinkID.AssistChange] = {
            open = function () SL:OpenAssistUI() end,                
            close = function () SL:CloseAssistUI() end
        },
        [SLDefine.HyperLinkID.Box996] = {
            open = function(param) UIOperator:OpenBox996UI(param) end,       
            close = function () UIOperator:CloseBox996UI() end,         
            hasLayer = function () local mediator = global.Facade:retrieveMediator("Box996MainLayerMediator") return mediator and mediator._layer end
        },
        [SLDefine.HyperLinkID.MainMiniMapChange] = {
            open = function () SL:OpenMiniMapChangeUI() end,         
            close = function () SL:CloseMiniMapChangeUI() end
        },
        [SLDefine.HyperLinkID.PCResolution] = {
            open = function () UIOperator:OpenResolutionSetUI() end,         
            close = function () UIOperator:CloseResolutionSetUI() end
        },
        [SLDefine.HyperLinkID.MainNear] = {
            open = function () UIOperator:OpenMainNearUI() end,              
            close = function () UIOperator:CloseMainNearUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.MainNearGUI) end,       
        },
        [SLDefine.HyperLinkID.SettingBasic] = {
            open = function () UIOperator:OpenSettingUI(1) end,               
            close = function () UIOperator:CloseSettingUI() end,    
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingBasicMediator") return mediator and mediator._layer end   
        },
        [SLDefine.HyperLinkID.SettingWindowRange] = {
            open = function () UIOperator:OpenSettingUI(2) end,               
            close = function () UIOperator:CloseSettingUI() end,  
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingWindowRangeMediator") return mediator and mediator._layer end      
        },
        [SLDefine.HyperLinkID.SettingFight] = {
            open = function () UIOperator:OpenSettingUI(3) end,               
            close = function () UIOperator:CloseSettingUI() end,    
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingLaunchMediator") return mediator and mediator._layer end   
        },
        [SLDefine.HyperLinkID.SettingProtect] = {
            open = function () UIOperator:OpenSettingUI(4) end,               
            close = function () UIOperator:CloseSettingUI() end,  
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingProtectMediator") return mediator and mediator._layer end       
        },
        [SLDefine.HyperLinkID.SettingAuto] = {
            open = function () UIOperator:OpenSettingUI(5) end,               
            close = function () UIOperator:CloseSettingUI() end, 
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingAutoMediator") return mediator and mediator._layer end   
        },
        [SLDefine.HyperLinkID.SettingHelp] = {
            open = function () UIOperator:OpenSettingUI(6) end,               
            close = function () UIOperator:CloseSettingUI() end,
            hasLayer = function () local mediator = global.Facade:retrieveMediator("SettingHelpMediator") return mediator and mediator._layer end   
        },
        [SLDefine.HyperLinkID.SettingAutoPick] = {
            open = function () UIOperator:OpenPickSettingUI() end,            
            close = function () UIOperator:ClosePickSettingUI() end,
            hasLayer = function () return SettingPickSetting and SettingPickSetting._layer end  
        },
        [SLDefine.HyperLinkID.KeFu] = {
            open = function () UIOperator:OpenKefuUI() end
        },
        [SLDefine.HyperLinkID.PCPrivate] = {
            open = function() UIOperator:OpenPCPrivateUI() end,              
            close = function() UIOperator:ClosePCPrivateUI() end
        }, 
        [SLDefine.HyperLinkID.Compound] = {
            open = function(param) UIOperator:OpenCompoundItemUI(param) end,
            close = function() UIOperator:CloseCompoundItemUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.CompoundItemGUI) end,
        },
        [SLDefine.HyperLinkID.ReviewGift] = {
            open = function () UIOperator:OpenReviewGift() end
        },
        [SLDefine.HyperLinkID.Purchase] = {
            open = function () UIOperator:OpenPurchaseUI() end,              
            close = function () UIOperator:ClosePurchaseUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.PurchaseMainGUI) end
        },
        [SLDefine.HyperLinkID.Community] = {
            open = function () UIOperator:OpenCommunityUI() end, 
            close = function ()  UIOperator:CloseCommunityUI() end,
            hasLayer = function () local mediator = global.Facade:retrieveMediator("CommunityLayerMediator") return mediator and mediator._layer end   
        },
        [SLDefine.HyperLinkID.ManualService996] = {
            open = function () SL:RequestOpen996ManualService() end,
        },
        [SLDefine.HyperLinkID.Exchange] = {
            open = function () UIOperator:OpenExchangeUI() end,              
            close = function () UIOperator:CloseExchangeUI() end,
            hasLayer = function() return GUI:GetWindow(nil, UIConst.LAYERID.ExchangeMainGUI) end
        }
    }
end

function JumpProxy:FindLinkByID(jumpID)
    -- 兼容老跳转id
    local map = {
        [20] = SLDefine.HyperLinkID.SettingProtect,
        [21] = SLDefine.HyperLinkID.SettingAutoPick,
        [22] = SLDefine.HyperLinkID.SettingFight,
        [23] = SLDefine.HyperLinkID.SettingBasic
    }
    if jumpID >= 20 and jumpID <= 23 then
        local key = map[jumpID]
        return self._links[key]
    end
    return self._links[jumpID]
end

function JumpProxy:ExecuteByParam(param, jumpID, destPos,isOpen)
    if not param then
        return nil
    end

    local slices = G_GetSplitArray(param, "#")
    local command = slices[1]

    if command == "find_point" then
        local movePos = 
        {
            mapID   = slices[2],
            x       = tonumber(slices[3]),
            y       = tonumber(slices[4]),
            autoMoveType = global.MMO.AUTO_MOVE_TYPE_CHAT
        }
        global.Facade:sendNotification(global.NoticeTable.AutoMoveBegin, movePos)
    
    elseif command == "item_tips" then
        self:JumpToItemTips(tonumber(slices[2]), destPos)
    end
end

function JumpProxy:JumpToItemTips(itemIndex, destPos)
    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    local itemInfo  = ItemConfigProxy:GetItemDataByIndex(itemIndex)
    local data      = {}
    data.itemData   = itemInfo
    data.pos        = destPos
    UIOperator:OpenItemTips(data)
end

function JumpProxy:JumpTo(jumpID, param, param1)
    print("+++++++++++++hyper link jump", jumpID, param, param1)
    local link  = self:FindLinkByID(tonumber(jumpID) or 0)
    local openLayer = function()
        if link and link.open then
            print("........open..........")
            link.open(param)           
        end
    end
    local closeLayer = function()
        if link and link.close then
            print("........close..........")
            link.close(param)
        end
    end
    local hasLayer = function ()
        if link and link.hasLayer then
            return link.hasLayer() 
        end
    end
    if not param1 or param1 == 0 then--0走打开 但是已经打开的有些layer会自己关闭
        -- 伸缩类型
        if jumpID == SLDefine.HyperLinkID.MainMiniMapChange then
            SL:onLUAEvent(LUA_EVENT_MAIN_MINIMAP_SHOW_STATUS, MainMiniMap._showState)
            return
        elseif jumpID == SLDefine.HyperLinkID.AssistChange then
            SL:SetTaskBarState({status = not MainAssist._hideAssist})
            return
        end
        if link and link.close and hasLayer() then
            closeLayer() 
        else
            openLayer()
        end
    else
        if param1 == 1 then -- 强制打开
            if link and hasLayer() then
                return 
            end
            openLayer()
        else --关闭
            closeLayer()
        end
    end
end

function JumpProxy:RespHyperlinkJump(msg)
    local header = msg:GetHeader()
    local jumpID = header.recog
    print("++++++++++++++++++++++++++++++ service jump", jumpID)
    
    local param1 = tonumber(header.param1) or 0--0走打开 但是已经打开的有些lyaer会自己关闭 1强制打开 2关闭;
    local param2 = header.param2 or 0
    self:JumpTo(jumpID, param2, param1)
end

function JUMPTO(id, param)
    local JumpProxy = global.Facade:retrieveProxy(global.ProxyTable.JumpProxy)
    JumpProxy:JumpTo(id, param)
end

function JumpProxy:SetLayerOpenParam(id, param)
    self._layerParam = self._layerParam or {}
    self._layerParam[id] = param
end
function JumpProxy:ReqOpenLayerCheck(id, calllback)
    self._calllback = calllback
    LuaSendMsg(global.MsgType.MSG_CS_OPENHYPERCHECK, id, 0, 0, 0)
end

function JumpProxy:handler_MSG_SC_OPENHYPERCHECK(msg)
    local header = msg:GetHeader()
    local openID = header.recog
    local isOpen = header.param1 == 1
    print("++++++++++++++++++++++++++++++ handler_MSG_SC_OPENHYPERCHECK", openID,isOpen)
    if isOpen then
        if self._calllback then
            self._calllback()
        else
            self:JumpTo(openID, self._layerParam[openID]) 
        end
    end

    self._calllback = nil
    self._layerParam[openID] = nil
end
--打开界面前通知服务器检测
function G_CheckOpenLayer(id, param, calllback)
    local JumpProxy = global.Facade:retrieveProxy(global.ProxyTable.JumpProxy)
    JumpProxy:SetLayerOpenParam(id, param)
    JumpProxy:ReqOpenLayerCheck(id, calllback)
end


return JumpProxy