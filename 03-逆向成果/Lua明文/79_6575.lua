local ProxyTable =
{
    -- ++++++++++++++++++++++++ local ++++++++++++++++++++++++
    -- stringTable
    StringTableProxy        = "StringTableProxy",

    -- 敏感词配置
    SensitiveWordProxy      = "SensitiveWordProxy",

    -- audio
    AudioProxy              = "AudioProxy",

    -- model config
    ModelConfigProxy        = "ModelConfigProxy",

    -- color style
    ColorStyleProxy         = "ColorStyleProxy",

    -- ++++++++++++++++++++++++ remote ++++++++++++++++++++++++
    -- gameEnvironment
    GameEnvironmentProxy    = "GameEnvironmentProxy",

    -- login
    LoginProxy              = "LoginProxy",
    AuthProxy               = "AuthProxy",

    -- 角色属性
    PlayerPropertyProxy     = "PlayerPropertyProxy",

    -- 条件代理
    ConditionProxy          = "ConditionProxy",

    -- 技能数据(服务器下发)
    SkillProxy              = "SkillProxy",

    -- 游戏设置
    GameSettingProxy        = "GameSettingProxy",

    -- 服务器时间数据
    ServerTimeProxy         = "ServerTimeProxy",

    -- 付费proxy
    PayProxy                = "PayProxy",

    -- 地图
    MapProxy                = "MapProxy",

    -- 玩家的一些状态数据
    AutoProxy               = "AutoProxy",

    -- 游戏内挂
    AssistProxy             = "AssistProxy",

    -- NPC
    NPCProxy                = "NPCProxy",

    -- NPCRepaireProxy
    NPCRepaireProxy         = "NPCRepaireProxy",
    
    -- NPCSellProxy
    NPCSellProxy            = "NPCSellProxy",
    
    -- NPCStorageProxy
    NPCStorageProxy         = "NPCStorageProxy",
    --快捷栏
    QuickUseProxy           = "QuickUseProxy",

    NPCDoSomethingProxy     = "NPCDoSomethingProxy",

    -- buff
    BuffProxy               = "BuffProxy",

    -- 装备数据
    BagProxy                = "BagProxy",

    EquipProxy              = "EquipProxy",

    AttrConfigProxy         = "AttrConfigProxy",

    ItemConfigProxy         = "ItemConfigProxy",

    ItemManagerProxy        = "ItemManagerProxy",

    -- input proxy
    PlayerInputProxy        = "PlayerInputProxy",

    -- 消息栏
    NoticeProxy             = "NoticeProxy",

    --道具使用
    ItemUseProxy            = "ItemUseProxy",

    --道具移动
    ItemMoveProxy           = "ItemMoveProxy",

    MoneyProxy              = "MoneyProxy",

    LookPlayerProxy         = "LookPlayerProxy",

    AutoUseItemProxy        = "AutoUseItemProxy",

    PageStoreProxy          = "PageStoreProxy",

    RankProxy               = "RankProxy",

    -- dis connect  
    NetworkProxy            = "NetworkProxy",

    SceneOptionsProxy       = "SceneOptionsProxy",
    DamageNumProxy          = "DamageNumProxy",

    -- 
    ChatProxy               = "ChatProxy",
    TradeProxy              = "TradeProxy",
    TeamProxy               = "TeamProxy",              -- 队伍
    MetaValueProxy          = "MetaValueProxy",         -- 元变量
    BubbleTipsProxy         = "BubbleTipsProxy",        -- 气泡
    GameConfigMgrProxy      = "GameConfigMgrProxy",     -- 游戏配置
    RechargeProxy           = "RechargeProxy",          -- 充值
    SummonsProxy            = "SummonsProxy",           -- 召唤物
    SUIComponentProxy       = "SUIComponentProxy",      -- 自定义脚本附加
    CloudStorageProxy       = "CloudStorageProxy",      -- 云端存储
    MissionProxy            = "MissionProxy",           -- 任务系统
    AuctionProxy            = "AuctionProxy",           -- 拍卖行
    ServerOptionsProxy      = "ServerOptionsProxy",     -- 服务器开关
    JumpProxy               = "JumpProxy",              -- 超链跳转
    GuideProxy              = "GuideProxy",             -- 新手指引
    MiniMapProxy            = "MiniMapProxy",           -- 小地图

    GuildProxy              = "GuildProxy",
    ItemTipsProxy           = "ItemTipsProxy",
    MailProxy               = "MailProxy",
    FuncDockProxy           = "FuncDockProxy",
    FriendProxy             = "FriendProxy",            -- 好友
    StallProxy              = "StallProxy",             -- 摆摊

    TitleProxy              = "TitleProxy",       -- 称号
    GoldBoxProxy            = "GoldBoxProxy",

    EquipRetrieveProxy      = "EquipRetrieveProxy",     -- 装备回收

    -----zfs  begin---
    TradingBankProxy           = "TradingBankProxy", --交易行
    OtherTradingBankProxy      = "OtherTradingBankProxy", -- 三方 交易行 
    TradingBankLookPlayerProxy = "TradingBankLookPlayerProxy",--交易行 查看玩家信息
    RemindUpgradeProxy      = "RemindUpgradeProxy", --提升提示
    RedDotProxy             = "RedDotProxy", -- 红点提示
    HeroEquipProxy          = "HeroEquipProxy",-- 英雄装备
    HeroPropertyProxy       = "HeroPropertyProxy",--英雄属性
    HeroSkillProxy          = "HeroSkillProxy",--英雄技能
    HeroBagProxy            = "HeroBagProxy", -- 英雄背包
    PickupSpriteProxy       = "PickupSpriteProxy",--拾取小精灵
    DarkLayerProxy          = "DarkLayerProxy", --黑夜模式
    -----zfs  end----

    NPCNewTypeOkProxy       = "NPCNewTypeOkProxy",      -- OK框新类型
    ReinAttrProxy           = "ReinAttrProxy",          -- 转生属性点


    ItemCompoundProxy       = "ItemCompoundProxy",      -- 合成

    Box996Proxy             = "Box996Proxy",            -- 996传奇盒子  
    
    InformationProxy        = "InformationProxy",       -- 收集个人信息

    NativeBridgeProxy       = "NativeBridgeProxy",      -- 底层交互

    SceneEffectProxy        = "SceneEffectProxy",       -- 场景效果

    VoiceManagerProxy       = "VoiceManagerProxy",      -- 语音

    HorseProxy              = "HorseProxy",             -- 骑马

    BubbleProxy             = "BubbleProxy",            -- 气泡

    DataRePortProxy         = "DataRePortProxy",        -- 数据上报

    MeridianProxy           = "MeridianProxy",          -- 内功经络

    DataTrackProxy          = "DataTrackProxy",         -- 数据跟踪

    CodeDOMUIProxy          = "CodeDOMUIProxy",         -- GUI界面管理

    PurchaseProxy           = "PurchaseProxy",          -- 求购

    RelationProxy           = "RelationProxy",          -- 关系

    ManualService996Proxy   = "ManualService996Proxy",  -- 客服会话

    ExchangeProxy           = "ExchangeProxy",          -- 交易所
}

return ProxyTable
