local SUIComponentTable = 
{
    -- 游戏基本面板 1-999
    MainRootLT          = 101,      -- 主界面左上
    MainRootRT          = 102,      -- 主界面右上
    MainRootLB          = 103,      -- 主界面左下
    MainRootRB          = 104,      -- 主界面右下
    MainRootLM          = 105,      -- 主界面左中
    MainRootTM          = 106,      -- 主界面上中
    MainRootRM          = 107,      -- 主界面右中
    MainRootBM          = 108,      -- 主界面下中 （不跟随刘海屏变动）
    MainRootButton      = 109,      -- 主界面-按钮模块
    MainRootMission     = 110,      -- 主界面 任务
    MainRootAssist      = 111,
    PCMainPropertyFuncs = 112,      -- PC主界面聊天上方功能栏

    MainRootBottom_LT   = 1001,     -- 主界面最底左上
    MainRootBottom_RT   = 1002,     -- 主界面最底右上
    MainRootBottom_LB   = 1003,     -- 主界面最底左下
    MainRootBottom_RB   = 1004,     -- 主界面最底右下

    MainRootTop_LT      = 1101,     -- 主界面最顶左上
    MainRootTop_RT      = 1102,     -- 主界面最顶右上
    MainRootTop_LB      = 1103,     -- 主界面最顶左下
    MainRootTop_RB      = 1104,     -- 主界面最顶右下

    PlayerMain          = 2,        -- 角色面板 大面板
    PlayerMainO         = 201,      -- 角色面板 大面板 查看他人
    PlayerEquip         = 3,        -- 角色面板 装备
    PlayerEquipO        = 301,      -- 角色面板 装备 查看别人
    PlayerEquipB        = 3001,     -- 角色面板 装备 下层
    PlayerEquipBO       = 3002,     -- 角色面板 装备 下层 查看别人
    PlayerState         = 4,        -- 角色面板 状态
    PlayerAttr          = 5,        -- 角色面板 属性
    PlayerSkill         = 6,        -- 角色面板 技能
    PlayerSkillO        = 601,      -- 角色面板 技能 查看别人
    Bag                 = 7,        -- 背包面板
    BagPageBtn1         = 7001,     -- 背包分页按钮1
    BagPageBtn2         = 7002,     -- 背包分页按钮2
    BagPageBtn3         = 7003,     -- 背包分页按钮3
    BagPageBtn4         = 7004,     -- 背包分页按钮4
    MiniMap             = 8,        -- 小地图
    GuildList           = 9,        -- 行会 行会列表
    GuildCreate         = 10,       -- 行会 行会创建
    GuildMain           = 11,       -- 行会 主面板
    GuildMembers        = 12,       -- 行会 成员
    
    Mail                = 14,       -- 邮件 
    Friend              = 15,       -- 好友
    Storage             = 16,       -- 仓库

    PlayerBuff          = 17,       -- 角色面板 buff/天赋
    PlayerBuffO         = 1701,     -- 角色面板 buff/天赋 查看他人
    
    Title               = 23,       -- 角色面板 称号
    TitleO              = 2301,     -- 角色面板 称号  查看他人

    AuctionMain         = 29,       -- 拍卖行 主面板
    AuctionWorld        = 30,       -- 拍卖行 世界拍卖
    AuctionGuild        = 31,       -- 拍卖行 行会拍卖
    AuctionBidding      = 32,       -- 拍卖行 我的竞拍
    AuctionPutlist      = 33,       -- 拍卖行 我的上架
    AuctionBid          = 34,       -- 拍卖行 竞价
    AuctionBuy          = 35,       -- 拍卖行 一口价
    AuctionPutin        = 36,       -- 拍卖行 上架
    AuctionPutout       = 37,       -- 拍卖行 下架
    AuctionTimeout      = 38,       -- 拍卖行 超时
    PlayerSuperEquip    = 39,       -- 角色面板  时装
    PlayerSuperEquipO   = 3901,     -- 角色面板  时装  查看别人
    PlayerSuperEquipB   = 3902,     -- 角色面板  时装  下层
    PlayerSuperEquipBO  = 3903,     -- 角色面板  时装  下层 查看他人
    Recharge            = 40,       -- 充值
    PlayerBestRing      = 41,       -- 首饰盒
    PlayerBestRingO     = 4101,     -- 首饰盒  查看他人
    ItemCompound        = 42,       -- 合成
    MainTargetBigHp     = 43,       -- 怪物大血条
    Rank                = 45,       -- 排行榜
    SettingBasic        = 300,      -- 基础设置
    SettingWindowRange  = 305,      -- 视距
    SettingFight        = 302,      -- 战斗
    SettingProtect      = 303,      -- 保护
    SettingAuto         = 304,      -- 挂机
    GuildBg             = 1200,     -- 行会底背景 特殊处理

    PageStore1          = 701,      -- 商城页签1
    PageStore2          = 702,      -- 商城页签2
    PageStore3          = 703,      -- 商城页签3
    PageStore4          = 704,      -- 商城页签4

    PlayerInternalState         = 401,      -- 内功状态
    PlayerInternalSkill         = 402,      -- 内功技能
    PlayerInternalMeridian      = 403,      -- 内功经络
    PlayerInternalMeridian1     = 40305,    -- 经络-奇经
    PlayerInternalMeridian2     = 40301,    -- 经络-冲脉
    PlayerInternalMeridian3     = 40302,    -- 经络-阴跷
    PlayerInternalMeridian4     = 40303,    -- 经络-阴维
    PlayerInternalMeridian5     = 40304,    -- 经络-任脉
    PlayerInternalCombo         = 404,      -- 内功连击

    ExchangePulist      = 46,       -- 交易所 我的上架
    ExchangePutin       = 47,       -- 交易所 上架
    ExchangePutout      = 48,       -- 交易所 下架
    ----------------------HERO----------------------
    PlayerMain_hero          = 50002,       -- 角色面板 大面板
    PlayerEquip_hero         = 50003,       -- 角色面板 装备
    PlayerEquipO_hero        = 50301,       -- 角色面板 装备 查看别人
    PlayerEquipB_hero        = 53001,       -- 角色面板 装备 下层
    PlayerEquipBO_hero       = 53002,       -- 角色面板 装备 下层 查看别人
    PlayerState_hero         = 50004,       -- 角色面板 状态
    PlayerAttr_hero          = 50005,       -- 角色面板 属性
    PlayerSkill_hero         = 50006,       -- 角色面板 技能
    PlayerSkillO_hero        = 50601,       -- 角色面板 技能 查看别人
    Bag_hero                 = 50007,       -- 背包面板
    Title_hero               = 50023,       -- 角色面板 称号
    TitleO_hero              = 52301,       -- 角色面板 称号  查看他人
    PlayerSuperEquip_hero    = 50039,       -- 角色面板  时装
    PlayerSuperEquipO_hero   = 53901,       -- 角色面板  时装  查看别人
    PlayerBestRing_hero      = 50041,       -- 首饰盒
    PlayerBestRingO_hero     = 54101,       -- 首饰盒  查看他人

    HeroInternalState           = 501,      -- 内功状态
    HeroInternalSkill           = 502,      -- 内功技能
    HeroInternalMeridian        = 503,      -- 内功经络
    HeroInternalMeridian1       = 50305,    -- 经络-奇经
    HeroInternalMeridian2       = 50301,    -- 经络-冲脉
    HeroInternalMeridian3       = 50302,    -- 经络-阴跷
    HeroInternalMeridian4       = 50303,    -- 经络-阴维
    HeroInternalMeridian5       = 50304,    -- 经络-任脉
    HeroInternalCombo           = 504,      -- 内功连击

    -- 后端脚本自定义标签 1000-~
}

return SUIComponentTable